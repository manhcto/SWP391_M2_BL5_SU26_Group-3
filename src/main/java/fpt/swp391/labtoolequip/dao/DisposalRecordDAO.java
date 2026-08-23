package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.DisposalRecord;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class DisposalRecordDAO {
	private static final String SELECT = """
			SELECT d.*, a.asset_code, a.asset_name, COALESCE(ai.condition, a.condition) AS asset_condition,
			       CASE WHEN ai.asset_item_id IS NULL THEN NULL
			            ELSE COALESCE(NULLIF(ai.serial_number, ''), CONCAT(a.asset_code, ' / item #', ai.asset_item_id)) END AS asset_item_tag,
			       u.full_name AS requester_name, reviewer.full_name AS approver_name
			FROM dbo.disposal_records d JOIN dbo.assets a ON a.asset_id = d.asset_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = d.asset_item_id AND ai.asset_id = d.asset_id
			JOIN dbo.users u ON u.user_id = d.requested_by
			LEFT JOIN dbo.users reviewer ON reviewer.user_id = d.approved_by
			""";
	private final DBConnection db = new DBConnection();

	public List<DisposalRecord> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT + """
				WHERE (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ?)
				AND (? = '' OR d.status = ?) ORDER BY d.requested_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			statement.setString(2, "%" + search + "%");
			statement.setString(3, "%" + search + "%");
			statement.setString(4, state);
			statement.setString(5, state);
			return read(statement);
		}
	}

	public Optional<DisposalRecord> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT + " WHERE d.disposal_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<DisposalRecord> findForMentor(long mentorId, String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT
				+ " WHERE d.requested_by=? AND (?='' OR a.asset_code LIKE ? OR a.asset_name LIKE ?) AND (?='' OR d.status=?) ORDER BY d.requested_at DESC";
		try (Connection c = db.getConnection(); PreparedStatement s = c.prepareStatement(sql)) {
			s.setLong(1, mentorId);
			s.setString(2, search);
			s.setString(3, "%" + search + "%");
			s.setString(4, "%" + search + "%");
			s.setString(5, state);
			s.setString(6, state);
			return read(s);
		}
	}

	public Optional<DisposalRecord> findByIdForMentor(long id, long mentorId) throws SQLException {
		try (Connection c = db.getConnection();
				PreparedStatement s = c.prepareStatement(SELECT + " WHERE d.disposal_id=? AND d.requested_by=?")) {
			s.setLong(1, id);
			s.setLong(2, mentorId);
			return read(s).stream().findFirst();
		}
	}

	public List<Asset> findEligibleAssets() throws SQLException {
		return findEligibleQuantityAssets();
	}

	public List<Asset> findEligibleQuantityAssets() throws SQLException {
		String sql = """
				SELECT asset_id, asset_code, asset_name, total_quantity FROM dbo.assets a
				WHERE tracking_mode = 'QUANTITY' AND status <> 'DISPOSED' AND NOT EXISTS
				(SELECT 1 FROM dbo.disposal_records d WHERE d.asset_id = a.asset_id AND d.asset_item_id IS NULL
				 AND d.status IN ('PENDING','APPROVED'))
				ORDER BY asset_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Asset> assets = new ArrayList<>();
			while (result.next()) {
				Asset asset = new Asset();
				asset.setAssetId(result.getLong(1));
				asset.setAssetCode(result.getString(2));
				asset.setAssetName(result.getString(3));
				asset.setTotalQuantity(result.getInt(4));
				assets.add(asset);
			}
			return assets;
		}
	}

	public List<AssetItem> findEligibleAssetItems() throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, ai.asset_id, a.asset_code, a.asset_name,
				       COALESCE(NULLIF(ai.serial_number, ''), CONCAT(a.asset_code, ' / item #', ai.asset_item_id)) AS item_tag,
				       ai.condition, ai.status, ai.is_borrowable
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.tracking_mode = 'SERIALIZED' AND a.status <> 'DISPOSED'
				  AND ai.status NOT IN ('DISPOSED', 'IN_USE', 'MAINTENANCE')
				  AND (ai.status = 'UNAVAILABLE' OR ai.condition IN ('DAMAGED', 'BROKEN'))
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.asset_usages au
					WHERE au.asset_item_id = ai.asset_item_id AND au.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.disposal_records d
					WHERE d.asset_item_id = ai.asset_item_id AND d.status IN ('PENDING', 'APPROVED')
				  )
				ORDER BY a.asset_name, item_tag
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setItemTag(result.getString("item_tag"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				item.setDisposalEligible(true);
				items.add(item);
			}
			return items;
		}
	}

	public long create(long userId, long assetId, String reasonCode, String reason) throws SQLException {
		return create(userId, assetId, null, reasonCode, reason);
	}

	public long create(long userId, Long assetId, Long assetItemId, String reasonCode, String reason)
			throws SQLException {
		if (reason == null || reason.isBlank())
			throw new IllegalArgumentException("Vui lòng nhập lý do thanh lý.");
		validateReasonCode(reasonCode);
		if (assetId == null && assetItemId == null)
			throw new IllegalArgumentException("Vui lòng chọn thiết bị cần thanh lý.");
		if (assetId != null && assetItemId != null)
			throw new IllegalArgumentException(
					"Yêu cầu thanh lý chỉ được nhắm tới một thiết bị theo mã riêng hoặc theo số lượng.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long disposalId = assetItemId == null
						? createQuantityDisposal(connection, userId, assetId, reasonCode, reason)
						: createSerializedDisposal(connection, userId, assetItemId, reasonCode, reason);
				connection.commit();
				return disposalId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void review(long id, long managerId, boolean approve, String note) throws SQLException {
		if (approve && (note == null || note.isBlank()))
			throw new IllegalArgumentException("Ghi chú đánh giá kỹ thuật là bắt buộc khi duyệt.");
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"UPDATE d SET status=?,approved_by=?,approved_at=SYSUTCDATETIME(),approval_note=?,technical_review_note=?,updated_at=SYSUTCDATETIME() FROM dbo.disposal_records d LEFT JOIN dbo.asset_items ai ON ai.asset_item_id=d.asset_item_id WHERE d.disposal_id=? AND d.status='PENDING' AND (d.asset_item_id IS NULL OR ai.status<>'DISPOSED') AND EXISTS(SELECT 1 FROM dbo.users WHERE user_id=? AND role='LAB_MANAGER' AND status='ACTIVE')")) {
			statement.setString(1, approve ? "APPROVED" : "REJECTED");
			statement.setLong(2, managerId);
			statement.setString(3, blankToNull(note));
			statement.setString(4, approve ? note.trim() : null);
			statement.setLong(5, id);
			statement.setLong(6, managerId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Chỉ có thể duyệt hoặc từ chối yêu cầu thanh lý đang chờ xử lý.");
			}
		}
	}

	public void complete(long id, long managerId, String method, String note) throws SQLException {
		if (!List.of("E_WASTE", "SCRAP", "RETURN_TO_VENDOR", "OTHER").contains(method))
			throw new IllegalArgumentException("Vui lòng chọn phương thức thanh lý hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				DisposalTarget target = approvedDisposalTarget(connection, id, false);
				if (target.assetItemId() == null) {
					completeQuantityDisposal(connection, id, target.assetId(), managerId, method, note);
				} else {
					completeSerializedDisposal(connection, id, target.assetId(), target.assetItemId(), managerId,
							method, note);
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private long createQuantityDisposal(Connection connection, long userId, long assetId, String reasonCode,
			String reason) throws SQLException {
		Asset asset = lockAsset(connection, assetId);
		validateDisposalTarget(asset.getTrackingMode(), asset.getAssetId(), null, asset.getTotalQuantity());
		if ("DISPOSED".equals(asset.getStatus())) {
			throw new IllegalStateException("Thiết bị đã được thanh lý.");
		}
		if (hasOpenQuantityDisposal(connection, assetId)) {
			throw new IllegalStateException("Thiết bị đang có yêu cầu thanh lý chờ xử lý.");
		}
		return insertDisposal(connection, userId, assetId, null, asset.getTotalQuantity(), reasonCode, reason);
	}

	private long createSerializedDisposal(Connection connection, long userId, long assetItemId, String reasonCode,
			String reason) throws SQLException {
		AssetItem item = lockAssetItem(connection, assetItemId);
		Asset asset = lockAsset(connection, item.getAssetId());
		validateDisposalTarget(asset.getTrackingMode(), asset.getAssetId(), assetItemId, 1);
		if ("DISPOSED".equals(asset.getStatus()) || "DISPOSED".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị đã được thanh lý.");
		}
		validateSerializedDisposalEligibility(item);
		if (hasActiveUsageForItem(connection, assetItemId)) {
			throw new IllegalStateException(
					"Không thể tạo yêu cầu thanh lý khi thiết bị theo mã riêng đang được sử dụng.");
		}
		if (hasOpenItemDisposal(connection, assetItemId)) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang có yêu cầu thanh lý chờ xử lý.");
		}
		return insertDisposal(connection, userId, asset.getAssetId(), assetItemId, 1, reasonCode, reason);
	}

	private long insertDisposal(Connection connection, long userId, long assetId, Long assetItemId, int quantity,
			String reasonCode, String reason) throws SQLException {
		String sql = """
				INSERT dbo.disposal_records (asset_id, asset_item_id, quantity, requested_by, reason_code, reason, status)
				OUTPUT INSERTED.disposal_id SELECT ?, ?, ?, ?, ?, ?, 'PENDING'
				WHERE EXISTS(SELECT 1 FROM dbo.users WHERE user_id=? AND role='MENTOR' AND status='ACTIVE')
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			if (assetItemId == null) {
				statement.setNull(2, Types.BIGINT);
			} else {
				statement.setLong(2, assetItemId);
			}
			statement.setInt(3, quantity);
			statement.setLong(4, userId);
			statement.setString(5, reasonCode);
			statement.setString(6, reason.trim());
			statement.setLong(7, userId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("Only an active Mentor can request disposal.");
				return result.getLong(1);
			}
		}
	}

	private void completeQuantityDisposal(Connection connection, long disposalId, long assetId, long managerId,
			String method, String note) throws SQLException {
		Asset asset = lockAsset(connection, assetId);
		DisposalTarget target = approvedDisposalTarget(connection, disposalId, true);
		if (target.assetItemId() != null || target.assetId() != assetId) {
			throw new IllegalStateException("Yêu cầu thanh lý đã thay đổi.");
		}
		if ("DISPOSED".equals(asset.getStatus()))
			throw new IllegalStateException("Thiết bị đã được thanh lý.");
		if (hasActiveUsage(connection, assetId))
			throw new IllegalStateException("Phải hoàn trả tất cả lượt mượn đang hoạt động trước khi thanh lý.");
		if (hasActiveMaintenanceForAsset(connection, assetId))
			throw new IllegalStateException("Phải hoàn tất các phiếu bảo trì đang hoạt động trước khi thanh lý.");
		markDisposalCompleted(connection, disposalId, managerId, method, note);
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.assets SET status = 'DISPOSED', is_borrowable = 0, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
			statement.setLong(1, assetId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể cập nhật thiết bị đã thanh lý.");
			}
		}
	}

	private void completeSerializedDisposal(Connection connection, long disposalId, long assetId, long assetItemId,
			long managerId, String method, String note) throws SQLException {
		AssetItem item = lockAssetItem(connection, assetItemId);
		DisposalTarget target = approvedDisposalTarget(connection, disposalId, true);
		if (target.assetItemId() == null || target.assetItemId() != assetItemId || target.assetId() != assetId
				|| !item.getAssetId().equals(assetId)) {
			throw new IllegalStateException("Yêu cầu thanh lý đã thay đổi.");
		}
		if ("DISPOSED".equals(item.getStatus()))
			throw new IllegalStateException("Thiết bị theo mã riêng đã được thanh lý.");
		if ("IN_USE".equals(item.getStatus()) || "MAINTENANCE".equals(item.getStatus())
				|| hasActiveUsageForItem(connection, assetItemId)
				|| hasActiveMaintenanceForItem(connection, assetItemId))
			throw new IllegalStateException(
					"Thiết bị theo mã riêng phải không còn lượt mượn hoặc phiếu bảo trì đang hoạt động trước khi thanh lý.");
		markDisposalCompleted(connection, disposalId, managerId, method, note);
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.asset_items SET status = 'DISPOSED', is_borrowable = 0, updated_at = SYSUTCDATETIME() "
						+ "WHERE asset_item_id = ? AND status <> 'DISPOSED'")) {
			statement.setLong(1, assetItemId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể cập nhật thiết bị theo mã riêng đã thanh lý.");
			}
		}
	}

	private void markDisposalCompleted(Connection connection, long disposalId, long managerId, String method,
			String note) throws SQLException {
		if (note == null || note.isBlank()) {
			throw new IllegalArgumentException("Kết quả thanh lý là bắt buộc.");
		}
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.disposal_records SET status='COMPLETED',completed_at=SYSUTCDATETIME(),disposal_method=?,completion_note=?,completed_by=?,updated_at=SYSUTCDATETIME() WHERE disposal_id=? AND status='APPROVED' AND technical_review_note IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.users WHERE user_id=? AND role='LAB_MANAGER' AND status='ACTIVE')")) {
			statement.setString(1, method);
			statement.setString(2, blankToNull(note));
			statement.setLong(3, managerId);
			statement.setLong(4, disposalId);
			statement.setLong(5, managerId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Chỉ có thể hoàn tất yêu cầu thanh lý đã được duyệt.");
			}
		}
	}

	private DisposalTarget approvedDisposalTarget(Connection connection, long id, boolean lock) throws SQLException {
		String hint = lock ? " WITH (UPDLOCK, HOLDLOCK)" : "";
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT asset_id, asset_item_id FROM dbo.disposal_records" + hint
						+ " WHERE disposal_id = ? AND status = 'APPROVED'")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Chỉ có thể hoàn tất yêu cầu thanh lý đã được duyệt.");
				}
				return new DisposalTarget(result.getLong("asset_id"), nullableLong(result, "asset_item_id"));
			}
		}
	}

	private Asset lockAsset(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_id, tracking_mode, total_quantity, status FROM dbo.assets WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ?")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Không tìm thấy thiết bị.");
				Asset asset = new Asset();
				asset.setAssetId(result.getLong(1));
				asset.setTrackingMode(result.getString(2));
				asset.setTotalQuantity(result.getInt(3));
				asset.setStatus(result.getString(4));
				return asset;
			}
		}
	}

	private boolean hasActiveUsage(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.asset_usages WHERE asset_id = ? AND status IN ('IN_USE', 'RETURN_PENDING')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasActiveUsageForItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.asset_usages WHERE asset_item_id = ? AND status IN ('IN_USE', 'RETURN_PENDING')")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private AssetItem lockAssetItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_item_id, asset_id, condition, status, is_borrowable FROM dbo.asset_items "
						+ "WITH (UPDLOCK, HOLDLOCK) WHERE asset_item_id = ?")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Không tìm thấy thiết bị theo mã riêng.");
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				return item;
			}
		}
	}

	private boolean hasOpenQuantityDisposal(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.disposal_records WITH (UPDLOCK, HOLDLOCK) WHERE asset_id=? AND asset_item_id IS NULL "
						+ "AND status IN ('PENDING','APPROVED')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasOpenItemDisposal(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT 1 FROM dbo.disposal_records WITH (UPDLOCK, HOLDLOCK) WHERE asset_item_id=? "
						+ "AND status IN ('PENDING','APPROVED')")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private List<DisposalRecord> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<DisposalRecord> records = new ArrayList<>();
			while (result.next()) {
				DisposalRecord record = new DisposalRecord();
				record.setDisposalId(result.getLong("disposal_id"));
				record.setAssetId(result.getLong("asset_id"));
				record.setAssetItemId(nullableLong(result, "asset_item_id"));
				record.setMaintenanceId(nullableLong(result, "maintenance_id"));
				record.setQuantity(result.getInt("quantity"));
				record.setRequestedBy(result.getLong("requested_by"));
				record.setReason(result.getString("reason"));
				record.setReasonCode(result.getString("reason_code"));
				record.setRequestedAt(ViewFormat.fromUtc(result.getTimestamp("requested_at")));
				record.setStatus(result.getString("status"));
				record.setApprovedBy(nullableLong(result, "approved_by"));
				record.setApprovedAt(ViewFormat.fromUtc(result.getTimestamp("approved_at")));
				record.setApprovalNote(result.getString("approval_note"));
				record.setTechnicalReviewNote(result.getString("technical_review_note"));
				record.setCompletedAt(ViewFormat.fromUtc(result.getTimestamp("completed_at")));
				record.setDisposalMethod(result.getString("disposal_method"));
				record.setCompletionNote(result.getString("completion_note"));
				record.setCompletedBy(nullableLong(result, "completed_by"));
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setAssetItemTag(result.getString("asset_item_tag"));
				record.setAssetCondition(result.getString("asset_condition"));
				record.setRequesterName(result.getString("requester_name"));
				record.setApproverName(result.getString("approver_name"));
				records.add(record);
			}
			return records;
		}
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	static void validateDisposalTarget(String trackingMode, Long assetId, Long assetItemId, int quantity) {
		if ("SERIALIZED".equals(trackingMode)) {
			if (assetId == null || assetItemId == null || quantity != 1) {
				throw new IllegalArgumentException("Thiết bị theo mã riêng phải chọn đúng một mã thiết bị.");
			}
			return;
		}
		if ("QUANTITY".equals(trackingMode)) {
			if (assetId == null || assetItemId != null || quantity <= 0) {
				throw new IllegalArgumentException("Thiết bị theo số lượng không dùng mã thiết bị riêng.");
			}
			return;
		}
		throw new IllegalStateException("Kiểu theo dõi thiết bị không hợp lệ.");
	}

	static void validateSerializedDisposalEligibility(AssetItem item) {
		if ("IN_USE".equals(item.getStatus()) || "MAINTENANCE".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang được sử dụng hoặc bảo trì.");
		}
		if (!"UNAVAILABLE".equals(item.getStatus()) && !"DAMAGED".equals(item.getCondition())
				&& !"BROKEN".equals(item.getCondition())) {
			throw new IllegalStateException(
					"Chỉ thiết bị theo mã riêng không khả dụng, hư hỏng hoặc vỡ mới đủ điều kiện thanh lý.");
		}
		// ponytail: maintenance has no structured failed result; use one here when
		// FE-08 exposes it.
	}

	private boolean hasActiveMaintenanceForItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.maintenance_records WITH (UPDLOCK, HOLDLOCK) WHERE asset_item_id = ? AND status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasActiveMaintenanceForAsset(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.maintenance_records WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ? AND status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	static void validateReasonCode(String reasonCode) {
		if (!List.of("NOT_REPAIRABLE", "UNSAFE", "OBSOLETE", "REPAIR_NOT_ECONOMICAL", "OTHER").contains(reasonCode))
			throw new IllegalArgumentException("Vui lòng chọn mã lý do thanh lý hợp lệ.");
	}

	private record DisposalTarget(long assetId, Long assetItemId) {
	}
}
