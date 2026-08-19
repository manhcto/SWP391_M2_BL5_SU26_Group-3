package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.Incident;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class MaintenanceDAO {
	private static final String SELECT = """
			SELECT m.*, a.asset_code, a.asset_name, a.storage_location,
			       requester.full_name AS requester_name,
			       approver.full_name AS approver_name,
			       i.description AS incident_description
			FROM dbo.maintenance_records m
			JOIN dbo.assets a ON a.asset_id = m.asset_id
			JOIN dbo.users requester ON requester.user_id = m.requested_by
			LEFT JOIN dbo.users approver ON approver.user_id = m.approved_by
			LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
			""";

	private final DBConnection db = new DBConnection();

	// ─── QUERIES ────────────────────────────────────────────────────────────────

	public List<MaintenanceRecord> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT + """
				WHERE (? = '' OR CAST(m.maintenance_id AS varchar(30)) LIKE ?
				    OR a.asset_code LIKE ? OR a.asset_name LIKE ?
				    OR m.description LIKE ? OR requester.full_name LIKE ?)
				  AND (? = '' OR m.status = ?)
				ORDER BY m.requested_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++) {
				statement.setString(index++, pattern);
			}
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

	/**
	 * Danh sách thiết bị đang hoạt động (chưa bị thanh lý) để chọn khi tạo phiếu
	 * bảo trì.
	 */
	public List<Asset> findEligibleAssets() throws SQLException {
		String sql = """
				SELECT asset_id, asset_code, asset_name, storage_location
				FROM dbo.assets
				WHERE status <> 'DISPOSED'
				ORDER BY asset_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Asset> assets = new ArrayList<>();
			while (result.next()) {
				Asset asset = new Asset();
				asset.setAssetId(result.getLong("asset_id"));
				asset.setAssetCode(result.getString("asset_code"));
				asset.setAssetName(result.getString("asset_name"));
				asset.setStorageLocation(result.getString("storage_location"));
				assets.add(asset);
			}
			return assets;
		}
	}

	/** Danh sách sự cố còn mở để liên kết tùy chọn khi tạo phiếu bảo trì. */
	public List<Incident> findOpenIncidents() throws SQLException {
		String sql = """
				SELECT i.incident_id, i.description, a.asset_name, a.asset_code
				FROM dbo.incidents i
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				WHERE i.status IN ('OPEN', 'INVESTIGATING')
				ORDER BY i.reported_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Incident> incidents = new ArrayList<>();
			while (result.next()) {
				Incident incident = new Incident();
				incident.setIncidentId(result.getLong("incident_id"));
				incident.setDescription(result.getString("description"));
				incident.setAssetName(result.getString("asset_name"));
				incident.setAssetCode(result.getString("asset_code"));
				incidents.add(incident);
			}
			return incidents;
		}
	}

	// ─── WRITES ─────────────────────────────────────────────────────────────────

	/**
	 * Mentor tạo phiếu đề xuất bảo trì mới (trạng thái PENDING). Cập nhật trạng
	 * thái tài sản sang MAINTENANCE trong cùng giao dịch.
	 */
	public long create(long userId, long assetId, Long incidentId, int quantity, String description)
			throws SQLException {
		if (description == null || description.isBlank()) {
			throw new IllegalArgumentException("Vui lòng mô tả chi tiết tình trạng hỏng hóc.");
		}
		if (quantity < 1) {
			throw new IllegalArgumentException("Số lượng phải lớn hơn 0.");
		}
		String sql = """
				INSERT INTO dbo.maintenance_records (asset_id, incident_id, quantity, requested_by, description, status)
				OUTPUT INSERTED.maintenance_id
				VALUES (?, ?, ?, ?, ?, 'PENDING')
				""";
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, assetId);
					setNullableLong(statement, 2, incidentId);
					statement.setInt(3, quantity);
					statement.setLong(4, userId);
					statement.setString(5, description.trim());
					try (ResultSet result = statement.executeQuery()) {
						result.next();
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

	/**
	 * Mentor sửa đề xuất bảo trì khi và chỉ khi còn ở trạng thái PENDING.
	 */
	public void updatePending(long id, long userId, long assetId, Long incidentId, int quantity, String description)
			throws SQLException {
		if (description == null || description.isBlank()) {
			throw new IllegalArgumentException("Vui lòng mô tả chi tiết tình trạng hỏng hóc.");
		}
		if (quantity < 1) {
			throw new IllegalArgumentException("Số lượng phải lớn hơn 0.");
		}
		String sql = """
				UPDATE dbo.maintenance_records
				SET asset_id = ?, incident_id = ?, quantity = ?, description = ?, updated_at = SYSUTCDATETIME()
				WHERE maintenance_id = ? AND requested_by = ? AND status = 'PENDING'
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			setNullableLong(statement, 2, incidentId);
			statement.setInt(3, quantity);
			statement.setString(4, description.trim());
			statement.setLong(5, id);
			statement.setLong(6, userId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Chỉ có thể sửa yêu cầu bảo trì đang chờ phê duyệt của chính bạn.");
			}
		}
	}

	/**
	 * Mentor hủy / xóa đề xuất bảo trì khi và chỉ khi còn ở trạng thái PENDING.
	 */
	public void deletePending(long id, long userId) throws SQLException {
		String sql = "DELETE FROM dbo.maintenance_records WHERE maintenance_id = ? AND requested_by = ? AND status = 'PENDING'";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			statement.setLong(2, userId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Chỉ có thể xóa yêu cầu bảo trì đang chờ phê duyệt của chính bạn.");
			}
		}
	}

	/**
	 * Lab Manager phê duyệt hoặc từ chối yêu cầu bảo trì (chỉ khi PENDING). Khi
	 * APPROVED: đổi trạng thái thiết bị sang MAINTENANCE.
	 */
	public void decide(long id, long approverId, String decision, String approvalNote) throws SQLException {
		if (!"APPROVED".equals(decision) && !"REJECTED".equals(decision)) {
			throw new IllegalArgumentException("Quyết định không hợp lệ.");
		}
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				// Lấy asset_id và kiểm tra trạng thái phiếu
				long assetId = requirePending(connection, id);

				// Cập nhật trạng thái phiếu
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.maintenance_records
						SET status = ?, approved_by = ?, approved_at = SYSUTCDATETIME(),
						    approval_note = ?, updated_at = SYSUTCDATETIME()
						WHERE maintenance_id = ? AND status = 'PENDING'
						""")) {
					statement.setString(1, decision);
					statement.setLong(2, approverId);
					statement.setString(3, blankToNull(approvalNote));
					statement.setLong(4, id);
					statement.executeUpdate();
				}

				// Nếu duyệt -> đổi trạng thái thiết bị sang MAINTENANCE
				if ("APPROVED".equals(decision)) {
					setAssetStatus(connection, assetId, "MAINTENANCE");
				}

				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	/**
	 * Lab Manager hoặc Mentor cập nhật tiến độ sửa chữa (chỉ khi APPROVED /
	 * IN_PROGRESS). Khi COMPLETED: đổi trạng thái thiết bị về AVAILABLE.
	 */
	public void updateProgress(long id, String newStatus, String note, String repairResult) throws SQLException {
		if (!"IN_PROGRESS".equals(newStatus) && !"COMPLETED".equals(newStatus)) {
			throw new IllegalArgumentException("Trạng thái tiến độ không hợp lệ.");
		}
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				// Lấy asset_id và kiểm tra phiếu phải đang ở APPROVED hoặc IN_PROGRESS
				long assetId = requireApprovedOrInProgress(connection, id);

				String sql;
				if ("COMPLETED".equals(newStatus)) {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'COMPLETED',
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    repair_completed_at = SYSUTCDATETIME(),
							    note = ?, repair_result = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ?
							""";
				} else {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'IN_PROGRESS',
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    note = ?, repair_result = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ?
							""";
				}

				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setString(1, blankToNull(note));
					statement.setString(2, blankToNull(repairResult));
					statement.setLong(3, id);
					statement.executeUpdate();
				}

				// Nếu hoàn thành -> trả thiết bị về AVAILABLE
				if ("COMPLETED".equals(newStatus)) {
					setAssetStatus(connection, assetId, "AVAILABLE");
				}

				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	// ─── PRIVATE HELPERS ────────────────────────────────────────────────────────

	private long requirePending(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_id FROM dbo.maintenance_records WHERE maintenance_id = ? AND status = 'PENDING'")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Phiếu bảo trì không ở trạng thái chờ duyệt.");
				}
				return result.getLong(1);
			}
		}
	}

	private long requireApprovedOrInProgress(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_id FROM dbo.maintenance_records WHERE maintenance_id = ? AND status IN ('APPROVED','IN_PROGRESS')")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Chỉ có thể cập nhật tiến độ phiếu đã duyệt hoặc đang sửa chữa.");
				}
				return result.getLong(1);
			}
		}
	}

	private void setAssetStatus(Connection connection, long assetId, String status) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.assets SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
			statement.setString(1, status);
			statement.setLong(2, assetId);
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
				record.setIncidentId(nullableLong(result, "incident_id"));
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
				record.setNote(result.getString("note"));
				record.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				record.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				// Joined fields
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setStorageLocation(result.getString("storage_location"));
				record.setRequesterName(result.getString("requester_name"));
				record.setApproverName(result.getString("approver_name"));
				record.setIncidentDescription(result.getString("incident_description"));
				records.add(record);
			}
			return records;
		}
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) {
			statement.setNull(index, java.sql.Types.BIGINT);
		} else {
			statement.setLong(index, value);
		}
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
