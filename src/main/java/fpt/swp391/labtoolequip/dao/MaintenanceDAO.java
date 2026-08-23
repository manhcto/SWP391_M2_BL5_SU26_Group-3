package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.Incident;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class MaintenanceDAO {
	private static final String SELECT = """
			SELECT m.*, a.asset_code, a.asset_name, a.storage_location, a.status AS asset_status,
			       ai.item_code AS asset_item_code,
			       COALESCE(NULLIF(ai.serial_number, ''), ai.item_code,
			                CONCAT(a.asset_code, ' / item #', ai.asset_item_id)) AS asset_item_tag,
			       ai.status AS asset_item_status, ai.condition AS asset_item_condition,
			       requester.full_name AS requester_name,
			       approver.full_name AS approver_name,
			       i.description AS incident_description
			FROM dbo.maintenance_records m
			JOIN dbo.assets a ON a.asset_id = m.asset_id
			LEFT JOIN dbo.asset_items ai
			  ON ai.asset_item_id = m.asset_item_id AND ai.asset_id = m.asset_id
			JOIN dbo.users requester ON requester.user_id = m.requested_by
			LEFT JOIN dbo.users approver ON approver.user_id = m.approved_by
			LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
			""";

	private final DBConnection db = new DBConnection();

	public List<MaintenanceRecord> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT + """
				WHERE (? = '' OR CAST(m.maintenance_id AS varchar(30)) LIKE ?
				    OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR ai.item_code LIKE ?
				    OR m.description LIKE ? OR requester.full_name LIKE ?)
				  AND (? = '' OR m.status = ?)
				ORDER BY m.requested_at DESC, m.maintenance_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 6; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index, state);
			return read(statement);
		}
	}

	public List<MaintenanceRecord> findForMentor(long mentorId, String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT + """
				WHERE m.requested_by = ?
				  AND (? = '' OR CAST(m.maintenance_id AS varchar(30)) LIKE ?
				    OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR m.description LIKE ?)
				  AND (? = '' OR m.status = ?)
				ORDER BY m.requested_at DESC, m.maintenance_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setLong(index++, mentorId);
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index, state);
			return read(statement);
		}
	}

	public Optional<MaintenanceRecord> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT + " WHERE m.maintenance_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public Optional<MaintenanceRecord> findByIdForMentor(long id, long mentorId) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement(SELECT + " WHERE m.maintenance_id = ? AND m.requested_by = ?")) {
			statement.setLong(1, id);
			statement.setLong(2, mentorId);
			return read(statement).stream().findFirst();
		}
	}

	public List<AssetItem> findRequestableAssetItems() throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, ai.asset_id, ai.item_code, ai.serial_number, ai.condition, ai.status,
				       ai.is_borrowable, a.asset_code, a.asset_name, a.storage_location
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.status <> 'DISPOSED'
				  AND ai.status NOT IN ('DISPOSED', 'IN_USE', 'MAINTENANCE')
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.asset_usages au
					WHERE au.asset_item_id = ai.asset_item_id
					  AND au.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.maintenance_records m
					WHERE m.asset_item_id = ai.asset_item_id
					  AND m.status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.disposal_records d
					WHERE d.asset_item_id = ai.asset_item_id
					  AND d.status IN ('PENDING', 'APPROVED')
				  )
				ORDER BY a.asset_name, ai.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setItemCode(result.getString("item_code"));
				item.setSerialNumber(result.getString("serial_number"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setStorageLocation(result.getString("storage_location"));
				items.add(item);
			}
			return items;
		}
	}

	public List<Incident> findOpenItemIncidents() throws SQLException {
		return findOpenItemIncidentsForMentor(null);
	}

	public List<Incident> findOpenItemIncidentsForMentor(Long mentorId) throws SQLException {
		String sql = """
				SELECT i.incident_id, i.asset_id, i.asset_item_id, i.description, a.asset_code, a.asset_name,
				       ai.item_code AS asset_item_code
				FROM dbo.incidents i
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				JOIN dbo.asset_items ai ON ai.asset_item_id = i.asset_item_id AND ai.asset_id = i.asset_id
				WHERE i.asset_item_id IS NOT NULL
				  AND i.status IN ('FORWARDED', 'INVESTIGATING', 'OPEN')
				  AND ai.status <> 'DISPOSED'
				  AND (? IS NULL OR i.reported_by = ? OR EXISTS (
				      SELECT 1 FROM dbo.asset_usages usage
				      JOIN dbo.lab_usage_requests request ON request.request_id = usage.request_id
				       AND request.semester_id = usage.semester_id
				      WHERE usage.asset_usage_id = i.asset_usage_id AND request.mentor_id = ?
				       AND request.status = 'APPROVED'))
				ORDER BY i.reported_at DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			if (mentorId == null) {
				statement.setNull(1, Types.BIGINT);
				statement.setNull(2, Types.BIGINT);
				statement.setNull(3, Types.BIGINT);
			} else {
				statement.setLong(1, mentorId);
				statement.setLong(2, mentorId);
				statement.setLong(3, mentorId);
			}
			try (ResultSet result = statement.executeQuery()) {
				List<Incident> incidents = new ArrayList<>();
				while (result.next()) {
					Incident incident = new Incident();
					incident.setIncidentId(result.getLong("incident_id"));
					incident.setAssetId(result.getLong("asset_id"));
					incident.setAssetItemId(result.getLong("asset_item_id"));
					incident.setDescription(result.getString("description"));
					incident.setAssetCode(result.getString("asset_code"));
					incident.setAssetName(result.getString("asset_name"));
					incident.setAssetItemCode(result.getString("asset_item_code"));
					incidents.add(incident);
				}
				return incidents;
			}
		}
	}

	public long createRequest(long mentorId, long assetItemId, Long incidentId, Long assessmentId, String description)
			throws SQLException {
		validateExactItemTarget(assetItemId, 1);
		validateDescription(description);
		validateOptionalId(incidentId, "Sự cố được chọn không hợp lệ.");
		validateOptionalId(assessmentId, "Đánh giá kỹ thuật được chọn không hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				AssetItem item = lockAssetItem(connection, assetItemId);
				ensureRequestableItem(connection, item);
				requireParentAssetNotDisposed(connection, item.getAssetId());
				if (hasActiveMaintenance(connection, assetItemId)) {
					throw new IllegalStateException("Thiết bị theo mã riêng đã có yêu cầu bảo trì đang xử lý.");
				}
				if (incidentId != null
						&& !isIncidentMatchingItem(connection, incidentId, item.getAssetId(), assetItemId)) {
					throw new IllegalArgumentException("Sự cố được chọn không thuộc đúng thiết bị theo mã riêng.");
				}
				String sql = """
						INSERT dbo.maintenance_records
						(asset_id, asset_item_id, incident_id, assessment_id, quantity, requested_by, description, status, repair_outcome)
						OUTPUT INSERTED.maintenance_id
						SELECT ?, ?, ?, ?, 1, ?, ?, 'PENDING', 'PENDING'
						WHERE EXISTS (
							SELECT 1 FROM dbo.users WHERE user_id = ? AND role = 'MENTOR' AND status = 'ACTIVE'
						)
						""";
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, item.getAssetId());
					statement.setLong(2, assetItemId);
					setNullableLong(statement, 3, incidentId);
					setNullableLong(statement, 4, assessmentId);
					statement.setLong(5, mentorId);
					statement.setString(6, description.trim());
					statement.setLong(7, mentorId);
					try (ResultSet result = statement.executeQuery()) {
						if (!result.next()) {
							throw new IllegalStateException(
									"Chỉ Mentor đang hoạt động mới có thể tạo yêu cầu bảo trì.");
						}
						long id = result.getLong(1);
						connection.commit();
						return id;
					}
				}
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void approve(long maintenanceId, long managerId, String approvalNote) throws SQLException {
		changePendingRequest(maintenanceId, managerId, "APPROVE", approvalNote);
	}

	public void reject(long maintenanceId, long managerId, String approvalNote) throws SQLException {
		changePendingRequest(maintenanceId, managerId, "REJECT", approvalNote);
	}

	public void start(long maintenanceId, long managerId, String note) throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				MaintenanceTarget target = lockMaintenanceTarget(connection, maintenanceId, "APPROVED");
				validateTransition("APPROVED", "START");
				AssetItem item = lockAssetItem(connection, target.assetItemId());
				ensureItemCanEnterMaintenance(connection, item);
				requireParentAssetNotDisposed(connection, item.getAssetId());
				updateMaintenanceStatus(connection, maintenanceId, managerId, "IN_PROGRESS", note, null, null);
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.asset_items
						SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
						WHERE asset_item_id = ? AND status IN ('AVAILABLE', 'UNAVAILABLE')
						""")) {
					statement.setLong(1, target.assetItemId());
					if (statement.executeUpdate() != 1) {
						throw new IllegalStateException("Thiết bị theo mã riêng không thể bắt đầu bảo trì.");
					}
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void complete(long maintenanceId, long managerId, String repairOutcome, String repairResult, String note)
			throws SQLException {
		String itemStatus = completedItemStatus(repairOutcome);
		validateDescription(repairResult);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				MaintenanceTarget target = lockMaintenanceTarget(connection, maintenanceId, "IN_PROGRESS");
				validateTransition("IN_PROGRESS", "COMPLETE");
				AssetItem item = lockAssetItem(connection, target.assetItemId());
				requireParentAssetNotDisposed(connection, item.getAssetId());
				if ("DISPOSED".equals(item.getStatus())) {
					throw new IllegalStateException("Thiết bị theo mã riêng đã thanh lý không thể hoàn tất bảo trì.");
				}
				if (!"MAINTENANCE".equals(item.getStatus())) {
					throw new IllegalStateException("Thiết bị theo mã riêng không còn ở trạng thái bảo trì.");
				}
				updateMaintenanceStatus(connection, maintenanceId, managerId, "COMPLETED", note, repairOutcome,
						repairResult);
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.asset_items
						SET status = ?, condition = CASE WHEN ? = 'SUCCESS' THEN 'GOOD' ELSE condition END,
						    is_borrowable = CASE
								WHEN ? = 'SUCCESS' AND EXISTS (
									SELECT 1 FROM dbo.assets a WHERE a.asset_id = dbo.asset_items.asset_id
									  AND a.is_borrowable = 1
								) THEN 1
								ELSE 0
							END,
						    updated_at = SYSUTCDATETIME()
						WHERE asset_item_id = ? AND status = 'MAINTENANCE'
						""")) {
					statement.setString(1, itemStatus);
					statement.setString(2, repairOutcome);
					statement.setString(3, repairOutcome);
					statement.setLong(4, target.assetItemId());
					if (statement.executeUpdate() != 1) {
						throw new IllegalStateException("Không thể cập nhật kết quả cho thiết bị theo mã riêng.");
					}
				}
				if ("SUCCESS".equals(repairOutcome) && target.incidentId() != null) {
					resolveIncidentAfterSuccessfulRepair(connection, target.incidentId(), repairResult);
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	static void validateExactItemTarget(Long assetItemId, int quantity) {
		if (assetItemId == null || assetItemId <= 0 || quantity != 1) {
			throw new IllegalArgumentException("Yêu cầu bảo trì phải chọn đúng một thiết bị theo mã riêng.");
		}
	}

	static void validateTransition(String currentStatus, String action) {
		boolean allowed = ("PENDING".equals(currentStatus) && ("APPROVE".equals(action) || "REJECT".equals(action)))
				|| ("APPROVED".equals(currentStatus) && "START".equals(action))
				|| ("IN_PROGRESS".equals(currentStatus) && "COMPLETE".equals(action));
		if (!allowed) {
			throw new IllegalStateException("Chuyển trạng thái bảo trì không hợp lệ.");
		}
	}

	static String completedItemStatus(String repairOutcome) {
		return switch (repairOutcome == null ? "" : repairOutcome) {
			case "SUCCESS" -> "AVAILABLE";
			case "FAILED" -> "UNAVAILABLE";
			default -> throw new IllegalArgumentException("Kết quả sửa chữa phải là SUCCESS hoặc FAILED.");
		};
	}

	private void changePendingRequest(long maintenanceId, long managerId, String action, String approvalNote)
			throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				MaintenanceTarget target = lockMaintenanceTarget(connection, maintenanceId, "PENDING");
				validateTransition("PENDING", action);
				AssetItem item = lockAssetItem(connection, target.assetItemId());
				if ("DISPOSED".equals(item.getStatus()) && "APPROVE".equals(action)) {
					throw new IllegalStateException("Thiết bị theo mã riêng đã thanh lý không thể được duyệt bảo trì.");
				}
				String status = "APPROVE".equals(action) ? "APPROVED" : "REJECTED";
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.maintenance_records
						SET status = ?, approved_by = ?, approved_at = SYSUTCDATETIME(), approval_note = ?,
						    updated_at = SYSUTCDATETIME()
						WHERE maintenance_id = ? AND status = 'PENDING'
						  AND EXISTS (
							SELECT 1 FROM dbo.users WHERE user_id = ? AND role = 'LAB_MANAGER' AND status = 'ACTIVE'
						  )
						""")) {
					statement.setString(1, status);
					statement.setLong(2, managerId);
					statement.setString(3, blankToNull(approvalNote));
					statement.setLong(4, maintenanceId);
					statement.setLong(5, managerId);
					if (statement.executeUpdate() != 1) {
						throw new IllegalStateException(
								"Chỉ Lab Manager đang hoạt động có thể xử lý yêu cầu đang chờ.");
					}
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private void updateMaintenanceStatus(Connection connection, long maintenanceId, long managerId, String status,
			String note, String repairOutcome, String repairResult) throws SQLException {
		String sql = "COMPLETED".equals(status) ? """
				UPDATE dbo.maintenance_records
				SET status = 'COMPLETED', repair_completed_at = SYSUTCDATETIME(), repair_outcome = ?,
				    repair_result = ?, note = COALESCE(?, note), updated_at = SYSUTCDATETIME()
				WHERE maintenance_id = ? AND status = 'IN_PROGRESS'
				  AND EXISTS (
					SELECT 1 FROM dbo.users WHERE user_id = ? AND role = 'LAB_MANAGER' AND status = 'ACTIVE'
				  )
				""" : """
				UPDATE dbo.maintenance_records
				SET status = 'IN_PROGRESS', repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
				    note = COALESCE(?, note), updated_at = SYSUTCDATETIME()
				WHERE maintenance_id = ? AND status = 'APPROVED'
				  AND EXISTS (
					SELECT 1 FROM dbo.users WHERE user_id = ? AND role = 'LAB_MANAGER' AND status = 'ACTIVE'
				  )
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			if ("COMPLETED".equals(status)) {
				statement.setString(1, repairOutcome);
				statement.setString(2, repairResult.trim());
				statement.setString(3, blankToNull(note));
				statement.setLong(4, maintenanceId);
				statement.setLong(5, managerId);
			} else {
				statement.setString(1, blankToNull(note));
				statement.setLong(2, maintenanceId);
				statement.setLong(3, managerId);
			}
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể cập nhật phiếu bảo trì ở trạng thái hiện tại.");
			}
		}
	}

	private MaintenanceTarget lockMaintenanceTarget(Connection connection, long maintenanceId, String status)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT asset_id, asset_item_id, incident_id
				FROM dbo.maintenance_records WITH (UPDLOCK, HOLDLOCK)
				WHERE maintenance_id = ? AND status = ?
				""")) {
			statement.setLong(1, maintenanceId);
			statement.setString(2, status);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Phiếu bảo trì không còn ở trạng thái có thể xử lý.");
				}
				Long assetItemId = nullableLong(result, "asset_item_id");
				if (assetItemId == null) {
					throw new IllegalStateException(
							"Phiếu bảo trì lịch sử không có mã thiết bị riêng, không thể xử lý theo luồng mới.");
				}
				return new MaintenanceTarget(result.getLong("asset_id"), assetItemId,
						nullableLong(result, "incident_id"));
			}
		}
	}

	private AssetItem lockAssetItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT asset_item_id, asset_id, condition, status, is_borrowable
				FROM dbo.asset_items WITH (UPDLOCK, HOLDLOCK)
				WHERE asset_item_id = ?
				""")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalArgumentException("Không tìm thấy thiết bị theo mã riêng.");
				}
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

	private void ensureRequestableItem(Connection connection, AssetItem item) throws SQLException {
		if ("DISPOSED".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đã thanh lý.");
		}
		if ("IN_USE".equals(item.getStatus()) || hasActiveUsageForItem(connection, item.getAssetItemId())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang được sử dụng.");
		}
		if ("MAINTENANCE".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang bảo trì.");
		}
		if (hasOpenDisposalForItem(connection, item.getAssetItemId())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang có yêu cầu thanh lý chờ xử lý.");
		}
	}

	private void ensureItemCanEnterMaintenance(Connection connection, AssetItem item) throws SQLException {
		if ("DISPOSED".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đã thanh lý không thể bắt đầu bảo trì.");
		}
		if ("IN_USE".equals(item.getStatus()) || hasActiveUsageForItem(connection, item.getAssetItemId())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang được sử dụng.");
		}
		if ("MAINTENANCE".equals(item.getStatus())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đã ở trạng thái bảo trì.");
		}
		if (hasOpenDisposalForItem(connection, item.getAssetItemId())) {
			throw new IllegalStateException("Thiết bị theo mã riêng đang có yêu cầu thanh lý chờ xử lý.");
		}
	}

	private void requireParentAssetNotDisposed(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.assets WITH (UPDLOCK, HOLDLOCK)
				WHERE asset_id = ? AND status <> 'DISPOSED'
				""")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Thiết bị cha đã thanh lý hoặc không còn tồn tại.");
				}
			}
		}
	}

	private boolean isIncidentMatchingItem(Connection connection, long incidentId, long assetId, long assetItemId)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.incidents
				WHERE incident_id = ? AND asset_id = ? AND asset_item_id = ?
				""")) {
			statement.setLong(1, incidentId);
			statement.setLong(2, assetId);
			statement.setLong(3, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasActiveMaintenance(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.maintenance_records WITH (UPDLOCK, HOLDLOCK)
				WHERE asset_item_id = ? AND status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
				""")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasActiveUsageForItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.asset_usages
				WHERE asset_item_id = ? AND status IN ('IN_USE', 'RETURN_PENDING')
				""")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasOpenDisposalForItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.disposal_records WITH (UPDLOCK, HOLDLOCK)
				WHERE asset_item_id = ? AND status IN ('PENDING', 'APPROVED')
				""")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private void resolveIncidentAfterSuccessfulRepair(Connection connection, long incidentId, String repairResult)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				UPDATE dbo.incidents
				SET status = 'RESOLVED', handling_result = COALESCE(?, handling_result),
				    updated_at = SYSUTCDATETIME()
				WHERE incident_id = ? AND status IN ('OPEN', 'INVESTIGATING')
				""")) {
			statement.setString(1, repairResult.trim());
			statement.setLong(2, incidentId);
			statement.executeUpdate();
		}
	}

	private List<MaintenanceRecord> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<MaintenanceRecord> records = new ArrayList<>();
			while (result.next()) {
				MaintenanceRecord record = new MaintenanceRecord();
				record.setMaintenanceId(result.getLong("maintenance_id"));
				record.setAssetId(result.getLong("asset_id"));
				record.setAssetItemId(nullableLong(result, "asset_item_id"));
				record.setIncidentId(nullableLong(result, "incident_id"));
				record.setAssessmentId(nullableLong(result, "assessment_id"));
				record.setQuantity(result.getInt("quantity"));
				record.setRequestedBy(result.getLong("requested_by"));
				record.setDescription(result.getString("description"));
				record.setRequestedAt(ViewFormat.fromUtc(result.getTimestamp("requested_at")));
				record.setStatus(result.getString("status"));
				record.setApprovedBy(nullableLong(result, "approved_by"));
				record.setApprovedAt(ViewFormat.fromUtc(result.getTimestamp("approved_at")));
				record.setApprovalNote(result.getString("approval_note"));
				record.setRepairStartedAt(ViewFormat.fromUtc(result.getTimestamp("repair_started_at")));
				record.setRepairCompletedAt(ViewFormat.fromUtc(result.getTimestamp("repair_completed_at")));
				record.setRepairResult(result.getString("repair_result"));
				record.setRepairOutcome(result.getString("repair_outcome"));
				record.setNote(result.getString("note"));
				record.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				record.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setAssetStatus(result.getString("asset_status"));
				record.setAssetItemCode(result.getString("asset_item_code"));
				record.setAssetItemTag(result.getString("asset_item_tag"));
				record.setAssetItemStatus(result.getString("asset_item_status"));
				record.setAssetItemCondition(result.getString("asset_item_condition"));
				record.setStorageLocation(result.getString("storage_location"));
				record.setRequesterName(result.getString("requester_name"));
				record.setApproverName(result.getString("approver_name"));
				record.setIncidentDescription(result.getString("incident_description"));
				records.add(record);
			}
			return records;
		}
	}

	private static void validateDescription(String value) {
		if (value == null || value.isBlank() || value.trim().length() > 2000) {
			throw new IllegalArgumentException("Mô tả hoặc kết quả sửa chữa phải có từ 1 đến 2000 ký tự.");
		}
	}

	private static void validateOptionalId(Long value, String message) {
		if (value != null && value <= 0) {
			throw new IllegalArgumentException(message);
		}
	}

	private static Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private static void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) {
			statement.setNull(index, Types.BIGINT);
		} else {
			statement.setLong(index, value);
		}
	}

	private static String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	private record MaintenanceTarget(long assetId, long assetItemId, Long incidentId) {
	}
}
