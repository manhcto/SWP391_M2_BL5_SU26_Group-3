package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.AssetCategory;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.AssetItemLifecycleEvent;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public class AssetItemDAO {
	private static final String SELECT = """
			SELECT i.*, a.asset_code, a.asset_name, a.is_borrowable, c.category_name
			FROM dbo.asset_items i
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			JOIN dbo.asset_categories c ON c.category_id = a.category_id
			""";
	private static final String BORROWABLE_CONDITIONS = """
			WHERE a.status = 'AVAILABLE' AND a.is_borrowable = 1
			  AND i.status = 'AVAILABLE' AND i.is_borrowable = 1
			  AND i.condition IN ('GOOD', 'FAIR')
			  AND NOT EXISTS (
				SELECT 1 FROM dbo.asset_usages usage
				WHERE usage.asset_item_id = i.asset_item_id AND usage.status IN ('IN_USE', 'RETURN_PENDING')
			  )
			  AND NOT EXISTS (
				SELECT 1 FROM dbo.equipment_allocations allocation
				WHERE allocation.asset_item_id = i.asset_item_id
				  AND allocation.status IN ('READY_FOR_HANDOVER', 'ACTIVE', 'ISSUE_REPORTED')
			  )
			  AND NOT EXISTS (
				SELECT 1 FROM dbo.disposal_records disposal
				WHERE disposal.asset_id = a.asset_id AND disposal.status IN ('PENDING', 'APPROVED')
			  )
			  AND NOT EXISTS (
				SELECT 1 FROM dbo.maintenance_records maintenance
				WHERE maintenance.asset_item_id = i.asset_item_id
				  AND maintenance.status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
			  )
			""";
	private final DBConnection db = new DBConnection();

	public List<AssetItem> findAll(String keyword, String status, String condition) throws SQLException {
		return findAll(keyword, status, condition, "");
	}

	public List<AssetItem> findAll(String keyword, String status, String condition, String categoryName)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String quality = condition == null ? "" : condition.trim();
		String category = categoryName == null ? "" : categoryName.trim();
		String sql = SELECT + """
				WHERE (? = '' OR i.item_code LIKE ? OR i.serial_number LIKE ? OR a.asset_name LIKE ?
				       OR a.asset_code LIKE ? OR c.category_name LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.condition = ?)
				  AND (? = '' OR c.category_name = ?)
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, quality);
			statement.setString(index++, quality);
			statement.setString(index++, category);
			statement.setString(index, category);
			return read(statement);
		}
	}

	public Optional<AssetItem> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT + " WHERE i.asset_item_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<AssetItemLifecycleEvent> findLifecycle(long assetItemId) throws SQLException {
		String sql = """
				SELECT event_time, event_type, event_label, detail, event_status, actor_name, reference_type,
				       reference_id, event_scope
				FROM (
				 SELECT i.created_at, 'REGISTRATION', N'Đăng ký sản phẩm', i.note, i.status, NULL,
				        'ASSET_ITEM', i.asset_item_id, 'ITEM', 10 FROM dbo.asset_items i WHERE i.asset_item_id=?
				 UNION ALL
				 SELECT event.event_time, event.event_type, event.event_label, event.detail, allocation.status,
				        event.actor_name, 'ALLOCATION', allocation.allocation_id, 'ITEM', event.sort_order
				 FROM dbo.equipment_allocations allocation
				 LEFT JOIN dbo.users handover ON handover.user_id=allocation.handed_over_by
				 LEFT JOIN dbo.users recovery ON recovery.user_id=allocation.recovered_by
				 CROSS APPLY (VALUES
				   (allocation.handed_over_at,'ALLOCATION_HANDOVER',N'Bàn giao theo cấp phát',CAST(NULL AS nvarchar(max)),handover.full_name,20),
				   (allocation.received_at,'ALLOCATION_RECEIVED',N'Xác nhận nhận cấp phát',CAST(NULL AS nvarchar(max)),CAST(NULL AS nvarchar(100)),21),
				   (allocation.recovered_at,'ALLOCATION_RECOVERED',N'Thu hồi cấp phát',allocation.return_note,recovery.full_name,22)
				 ) event(event_time,event_type,event_label,detail,actor_name,sort_order)
				 WHERE allocation.asset_item_id=? AND event.event_time IS NOT NULL
				 UNION ALL
				 SELECT event.event_time,event.event_type,event.event_label,event.detail,usage.status,event.actor_name,
				        'ASSET_USAGE',usage.asset_usage_id,'ITEM',event.sort_order
				 FROM dbo.asset_usages usage
				 JOIN dbo.student_profiles profile ON profile.student_id=usage.student_id
				 JOIN dbo.users intern ON intern.user_id=profile.user_id
				 LEFT JOIN dbo.users verifier ON verifier.user_id=usage.return_verified_by
				 CROSS APPLY (VALUES
				   (usage.borrowed_at,'USAGE_BORROWED',N'Bắt đầu sử dụng',usage.note,intern.full_name,30),
				   (usage.return_requested_at,'RETURN_REQUESTED',N'Yêu cầu trả thiết bị',usage.return_note,intern.full_name,31),
				   (COALESCE(usage.return_verified_at,usage.returned_at),'RETURN_CONFIRMED',N'Xác nhận hoàn trả',usage.return_note,verifier.full_name,32)
				 ) event(event_time,event_type,event_label,detail,actor_name,sort_order)
				 WHERE usage.asset_item_id=? AND event.event_time IS NOT NULL
				 UNION ALL
				 SELECT event.event_time,event.event_type,event.event_label,event.detail,incident.status,actor.full_name,
				        'INCIDENT',incident.incident_id,'ITEM',event.sort_order
				 FROM dbo.incidents incident LEFT JOIN dbo.asset_usages usage ON usage.asset_usage_id=incident.asset_usage_id
				 CROSS APPLY (VALUES
				   (incident.reported_at,'INCIDENT_REPORTED',N'Báo cáo sự cố',incident.description,incident.reported_by,40),
				   (incident.forwarded_at,'INCIDENT_FORWARDED',N'Chuyển sự cố để xử lý',incident.mentor_review_note,incident.reviewed_by,41),
				   (incident.technical_assessed_at,'INCIDENT_ASSESSED',N'Đánh giá kỹ thuật',incident.technical_note,incident.technical_assessed_by,42)
				 ) event(event_time,event_type,event_label,detail,actor_id,sort_order)
				 LEFT JOIN dbo.users actor ON actor.user_id=event.actor_id
				 WHERE (incident.asset_item_id=? OR (incident.asset_item_id IS NULL AND usage.asset_item_id=?)) AND event.event_time IS NOT NULL
				 UNION ALL
				 SELECT event.event_time,event.event_type,event.event_label,event.detail,maintenance.status,actor.full_name,
				        'MAINTENANCE',maintenance.maintenance_id,'ITEM',event.sort_order
				 FROM dbo.maintenance_records maintenance
				 CROSS APPLY (VALUES
				   (maintenance.requested_at,'MAINTENANCE_REQUESTED',N'Tạo phiếu bảo trì',maintenance.description,maintenance.requested_by,50),
				   (maintenance.approved_at,'MAINTENANCE_REVIEWED',N'Duyệt bảo trì',maintenance.approval_note,maintenance.approved_by,51),
				   (maintenance.repair_started_at,'MAINTENANCE_STARTED',N'Bắt đầu bảo trì',maintenance.note,maintenance.approved_by,52),
				   (maintenance.repair_completed_at,'MAINTENANCE_COMPLETED',N'Hoàn tất bảo trì',maintenance.repair_result,maintenance.approved_by,53)
				 ) event(event_time,event_type,event_label,detail,actor_id,sort_order)
				 LEFT JOIN dbo.users actor ON actor.user_id=event.actor_id
				 WHERE maintenance.asset_item_id=? AND event.event_time IS NOT NULL
				 UNION ALL
				 SELECT event.event_time,event.event_type,event.event_label,event.detail,disposal.status,actor.full_name,
				        'DISPOSAL',disposal.disposal_id,'ITEM',event.sort_order
				 FROM dbo.disposal_records disposal
				 CROSS APPLY (VALUES
				   (disposal.requested_at,'DISPOSAL_REQUESTED',N'Yêu cầu thanh lý',disposal.reason,disposal.requested_by,60),
				   (disposal.approved_at,'DISPOSAL_REVIEWED',N'Duyệt thanh lý',disposal.approval_note,disposal.approved_by,61),
				   (disposal.completed_at,'DISPOSAL_COMPLETED',N'Hoàn tất thanh lý',disposal.completion_note,disposal.completed_by,62)
				 ) event(event_time,event_type,event_label,detail,actor_id,sort_order)
				 LEFT JOIN dbo.users actor ON actor.user_id=event.actor_id
				 WHERE disposal.asset_item_id=? AND event.event_time IS NOT NULL
				 UNION ALL
				 SELECT record.inspection_date,'PARENT_INSPECTION',N'Kiểm tra Asset cha',item.discrepancy_note,
				        record.status,actor.full_name,'INSPECTION',record.inspection_id,'PARENT_ASSET',70
				 FROM dbo.asset_items physical
				 JOIN dbo.inspection_items item ON item.asset_id=physical.asset_id
				 JOIN dbo.inspection_records record ON record.inspection_id=item.inspection_id
				 JOIN dbo.users actor ON actor.user_id=record.inspected_by WHERE physical.asset_item_id=?
				) events(event_time,event_type,event_label,detail,event_status,actor_name,reference_type,reference_id,event_scope,sort_order)
				ORDER BY event_time, sort_order, reference_id
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 1; index <= 8; index++)
				statement.setLong(index, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				List<AssetItemLifecycleEvent> events = new ArrayList<>();
				while (result.next())
					events.add(new AssetItemLifecycleEvent(ViewFormat.fromUtc(result.getTimestamp("event_time")),
							result.getString("event_type"), result.getString("event_label"), result.getString("detail"),
							result.getString("event_status"), result.getString("actor_name"),
							result.getString("reference_type"), result.getLong("reference_id"),
							result.getString("event_scope")));
				return events;
			}
		}
	}

	public List<AssetItem> findBorrowable(String keyword) throws SQLException {
		return findBorrowable(keyword, "");
	}

	public List<AssetItem> findBorrowable(String keyword, String categoryName) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String category = categoryName == null ? "" : categoryName.trim();
		String sql = SELECT + BORROWABLE_CONDITIONS + """
				  AND (? = '' OR i.item_code LIKE ? OR i.serial_number LIKE ? OR a.asset_name LIKE ?
				       OR a.asset_code LIKE ? OR c.category_name LIKE ?)
				  AND (? = '' OR c.category_name = ?)
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, category);
			statement.setString(index, category);
			return read(statement);
		}
	}

	public Optional<AssetItem> findBorrowableById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement(SELECT + BORROWABLE_CONDITIONS + " AND i.asset_item_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<AssetItem> findReportableItems() throws SQLException {
		String sql = SELECT + """
				WHERE i.status <> 'DISPOSED' AND a.status <> 'DISPOSED'
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.asset_usages usage
					WHERE usage.asset_item_id = i.asset_item_id AND usage.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			return read(statement);
		}
	}

	public List<AssetCategory> findCategories() throws SQLException {
		String sql = "SELECT category_id, category_name FROM dbo.asset_categories WHERE status = 'ACTIVE' ORDER BY category_name";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetCategory> categories = new ArrayList<>();
			while (result.next()) {
				AssetCategory category = new AssetCategory();
				category.setCategoryId(result.getLong("category_id"));
				category.setCategoryName(result.getString("category_name"));
				categories.add(category);
			}
			return categories;
		}
	}

	public List<AssetCategory> findBorrowableCategories() throws SQLException {
		String sql = """
				SELECT DISTINCT c.category_id, c.category_name
				FROM dbo.asset_categories c
				JOIN dbo.assets a ON a.category_id = c.category_id
				JOIN dbo.asset_items i ON i.asset_id = a.asset_id
				""" + BORROWABLE_CONDITIONS + """
				  AND c.status = 'ACTIVE'
				ORDER BY c.category_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetCategory> categories = new ArrayList<>();
			while (result.next()) {
				AssetCategory category = new AssetCategory();
				category.setCategoryId(result.getLong("category_id"));
				category.setCategoryName(result.getString("category_name"));
				categories.add(category);
			}
			return categories;
		}
	}

	public long createBundle(String assetCode, String assetName, long categoryId, boolean borrowable,
			String description, List<AssetItem> items) throws SQLException {
		if (assetCode == null || assetCode.isBlank() || assetName == null || assetName.isBlank() || items == null
				|| items.isEmpty())
			throw new IllegalArgumentException("Vui lòng nhập mã, tên và số lượng sản phẩm lớn hơn 0.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				validateSerialsAvailable(connection, items);
				long assetId = insertAsset(connection, assetCode.trim(), assetName.trim(), categoryId, borrowable,
						description, items.size());
				for (int index = 0; index < items.size(); index++)
					insertItem(connection, assetId, assetCode.trim(), index + 1, items.get(index));
				refreshAssetCondition(connection, assetId);
				connection.commit();
				return assetId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				if (exception instanceof SQLException sqlException && isDuplicateSerial(sqlException))
					throw new IllegalArgumentException("Serial đã tồn tại. Vui lòng nhập serial khác.");
				throw exception;
			}
		}
	}

	public void updateItem(AssetItem item) throws SQLException {
		if (item == null || item.getAssetItemId() == null)
			throw new IllegalArgumentException("Không tìm thấy sản phẩm cần cập nhật.");
		validateEditableItem(item);
		String sql = """
				UPDATE dbo.asset_items
				SET serial_number = ?, image_path = ?, condition = ?,
				    status = CASE
				        WHEN status = 'AVAILABLE' AND ? IN ('DAMAGED', 'BROKEN') THEN 'UNAVAILABLE'
				        ELSE status
				    END,
				    purchase_date = ?, warranty_until = ?, note = ?, updated_at = SYSUTCDATETIME()
				WHERE asset_item_id = ? AND status IN ('AVAILABLE', 'UNAVAILABLE')
				""";
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				validateSerialAvailable(connection, item.getSerialNumber(), item.getAssetItemId());
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					setNullableString(statement, 1, item.getSerialNumber());
					setNullableString(statement, 2, item.getImagePath());
					statement.setString(3, item.getCondition());
					statement.setString(4, item.getCondition());
					setNullableDate(statement, 5, item.getPurchaseDate());
					setNullableDate(statement, 6, item.getWarrantyUntil());
					setNullableString(statement, 7, item.getNote());
					statement.setLong(8, item.getAssetItemId());
					if (statement.executeUpdate() == 0)
						throw new IllegalArgumentException(
								"Chỉ có thể sửa thông tin sản phẩm đang sẵn sàng hoặc đang ở hàng chờ xử lý.");
				}
				refreshAssetCondition(connection, assetIdOf(connection, item.getAssetItemId()));
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				try {
					connection.rollback();
				} catch (SQLException rollbackException) {
					exception.addSuppressed(rollbackException);
				}
				if (exception instanceof SQLException sqlException && isDuplicateSerial(sqlException))
					throw new IllegalArgumentException("Serial đã tồn tại. Vui lòng nhập serial khác.");
				throw exception;
			}
		}
	}

	public void deleteItem(long assetItemId) throws SQLException {
		if (assetItemId <= 0)
			throw new IllegalArgumentException("Mã sản phẩm không hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long assetId;
				int totalQuantity;
				String lookup = """
						SELECT i.asset_id, a.total_quantity
						FROM dbo.asset_items i WITH (UPDLOCK, HOLDLOCK)
						JOIN dbo.assets a WITH (UPDLOCK, HOLDLOCK) ON a.asset_id = i.asset_id
						WHERE i.asset_item_id = ?
						""";
				try (PreparedStatement statement = connection.prepareStatement(lookup)) {
					statement.setLong(1, assetItemId);
					try (ResultSet result = statement.executeQuery()) {
						if (!result.next())
							throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
						assetId = result.getLong("asset_id");
						totalQuantity = result.getInt("total_quantity");
					}
				}
				if (totalQuantity <= 1)
					throw new IllegalArgumentException("Không thể xóa sản phẩm cuối cùng của thiết bị.");
				if (hasUsageHistory(connection, assetId))
					throw new IllegalArgumentException("Không thể xóa sản phẩm đã có lịch sử sử dụng.");
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE FROM dbo.asset_items WHERE asset_item_id = ?")) {
					statement.setLong(1, assetItemId);
					if (statement.executeUpdate() == 0)
						throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
				}
				try (PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.assets SET total_quantity = total_quantity - 1, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
					statement.setLong(1, assetId);
					statement.executeUpdate();
				}
				refreshAssetCondition(connection, assetId);
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private long assetIdOf(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT asset_id FROM dbo.asset_items WHERE asset_item_id = ?")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
				return result.getLong(1);
			}
		}
	}

	private void validateSerialsAvailable(Connection connection, List<AssetItem> items) throws SQLException {
		validateDistinctSerials(items);
		for (AssetItem item : items)
			validateSerialAvailable(connection, item.getSerialNumber(), null);
	}

	static void validateDistinctSerials(List<AssetItem> items) {
		Set<String> serials = new HashSet<>();
		for (AssetItem item : items) {
			String serial = normalizedSerial(item == null ? null : item.getSerialNumber());
			if (serial != null && !serials.add(serial.toLowerCase(java.util.Locale.ROOT)))
				throw new IllegalArgumentException("Serial " + serial + " bị trùng trong danh sách nhập.");
		}
	}

	private void validateSerialAvailable(Connection connection, String serial, Long excludedItemId)
			throws SQLException {
		serial = normalizedSerial(serial);
		if (serial == null)
			return;
		String sql = "SELECT 1 FROM dbo.asset_items WHERE serial_number = ?"
				+ (excludedItemId == null ? "" : " AND asset_item_id <> ?");
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, serial);
			if (excludedItemId != null)
				statement.setLong(2, excludedItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next())
					throw new IllegalArgumentException("Serial " + serial + " đã tồn tại.");
			}
		}
	}

	private static String normalizedSerial(String serial) {
		return serial == null || serial.isBlank() ? null : serial.trim();
	}

	private static boolean isDuplicateSerial(SQLException exception) {
		return (exception.getErrorCode() == 2601 || exception.getErrorCode() == 2627)
				&& exception.getMessage().contains("UX_asset_items_serial");
	}

	private boolean hasUsageHistory(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT 1 FROM dbo.asset_usages WHERE asset_id = ?")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	static void refreshAssetCondition(Connection connection, long assetId) throws SQLException {
		String condition = "GOOD";
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT condition FROM dbo.asset_items WHERE asset_id = ?")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				int worst = 0;
				while (result.next()) {
					String value = result.getString(1);
					if (value == null || value.isBlank())
						continue;
					int rank = conditionRank(value);
					if (rank > worst) {
						worst = rank;
						condition = value;
					}
				}
			}
		}
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.assets SET condition = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
			statement.setString(1, condition);
			statement.setLong(2, assetId);
			statement.executeUpdate();
		}
	}

	private static int conditionRank(String condition) {
		return switch (condition) {
			case "BROKEN" -> 4;
			case "DAMAGED" -> 3;
			case "FAIR" -> 2;
			default -> 1;
		};
	}

	private long insertAsset(Connection connection, String code, String name, long categoryId, boolean borrowable,
			String description, int quantity) throws SQLException {
		String sql = """
				INSERT dbo.assets (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
				                  is_borrowable, description)
				OUTPUT INSERTED.asset_id
				VALUES (?, ?, ?, 'SERIALIZED', ?, 'GOOD', 'AVAILABLE', ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, code);
			statement.setString(2, name);
			statement.setLong(3, categoryId);
			statement.setInt(4, quantity);
			statement.setBoolean(5, borrowable);
			setNullableString(statement, 6, description);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
		}
	}

	private void insertItem(Connection connection, long assetId, String baseCode, int sequence, AssetItem item)
			throws SQLException {
		validateItem(item);
		String sql = """
				INSERT dbo.asset_items (asset_id, item_code, serial_number, image_path, condition, status,
				                       storage_location, purchase_date, warranty_until, note)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			statement.setString(2, baseCode + "-" + String.format("%04d", sequence));
			setNullableString(statement, 3, item.getSerialNumber());
			setNullableString(statement, 4, item.getImagePath());
			statement.setString(5, item.getCondition());
			statement.setString(6, item.getStatus());
			setNullableString(statement, 7, item.getStorageLocation());
			setNullableDate(statement, 8, item.getPurchaseDate());
			setNullableDate(statement, 9, item.getWarrantyUntil());
			setNullableString(statement, 10, item.getNote());
			statement.executeUpdate();
		}
	}

	private List<AssetItem> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				item.setCategoryName(result.getString("category_name"));
				item.setItemCode(result.getString("item_code"));
				item.setSerialNumber(result.getString("serial_number"));
				item.setImagePath(result.getString("image_path"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setStorageLocation(result.getString("storage_location"));
				item.setPurchaseDate(nullableDate(result, "purchase_date"));
				item.setWarrantyUntil(nullableDate(result, "warranty_until"));
				item.setNote(result.getString("note"));
				item.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				item.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				items.add(item);
			}
			return items;
		}
	}

	static void validateItem(AssetItem item) {
		if (item == null)
			throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ.");
		if (!List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(item.getCondition()))
			throw new IllegalArgumentException("Tình trạng sản phẩm không hợp lệ.");
		if (!List.of("AVAILABLE", "MAINTENANCE", "UNAVAILABLE", "DISPOSED").contains(item.getStatus()))
			throw new IllegalArgumentException("Trạng thái sản phẩm không hợp lệ.");
		if (("DAMAGED".equals(item.getCondition()) || "BROKEN".equals(item.getCondition()))
				&& !List.of("MAINTENANCE", "UNAVAILABLE", "DISPOSED").contains(item.getStatus()))
			throw new IllegalArgumentException("Sản phẩm hư hỏng nặng phải được đưa ra khỏi trạng thái sẵn sàng.");
		if (item.getSerialNumber() != null && item.getSerialNumber().length() > 100)
			throw new IllegalArgumentException("Serial không được dài quá 100 ký tự.");
		String imagePath = item.getImagePath();
		if (imagePath != null && !imagePath.isBlank()
				&& (!imagePath.matches("/(uploads|assets)/[A-Za-z0-9_./-]+") || imagePath.contains("..")))
			throw new IllegalArgumentException("Đường dẫn ảnh phải là đường dẫn nội bộ hợp lệ.");
	}

	private static void validateEditableItem(AssetItem item) {
		if (item == null || !List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(item.getCondition()))
			throw new IllegalArgumentException("Tình trạng sản phẩm không hợp lệ.");
		if (item.getSerialNumber() != null && item.getSerialNumber().length() > 100)
			throw new IllegalArgumentException("Serial không được dài quá 100 ký tự.");
		String imagePath = item.getImagePath();
		if (imagePath != null && !imagePath.isBlank()
				&& (!imagePath.matches("/(uploads|assets)/[A-Za-z0-9_./-]+") || imagePath.contains("..")))
			throw new IllegalArgumentException("Đường dẫn ảnh phải là đường dẫn nội bộ hợp lệ.");
	}

	private void setNullableString(PreparedStatement statement, int index, String value) throws SQLException {
		if (value == null || value.isBlank())
			statement.setNull(index, Types.NVARCHAR);
		else
			statement.setString(index, value.trim());
	}

	private void setNullableDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
		if (value == null)
			statement.setNull(index, Types.DATE);
		else
			statement.setObject(index, value);
	}

	private LocalDate nullableDate(ResultSet result, String column) throws SQLException {
		java.sql.Date value = result.getDate(column);
		return value == null ? null : value.toLocalDate();
	}
}
