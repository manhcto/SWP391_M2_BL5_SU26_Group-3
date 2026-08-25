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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

public class MaintenanceDAO {
	private static final String SELECT = """
			SELECT m.*, a.asset_code, a.asset_name, a.storage_location,
			       COALESCE(ai_direct.status, ai_incident.status, a.status) AS asset_status,
			       requester.full_name AS requester_name,
			       approver.full_name AS approver_name,
			       i.description AS incident_description,
			       COALESCE(ai_direct.item_code, ai_incident.item_code) AS asset_item_code,
			       s.title AS schedule_title, s.scheduled_date
			FROM dbo.maintenance_records m
			JOIN dbo.assets a ON a.asset_id = m.asset_id
			JOIN dbo.users requester ON requester.user_id = m.requested_by
			LEFT JOIN dbo.users approver ON approver.user_id = m.approved_by
			LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
			LEFT JOIN dbo.asset_items ai_incident ON ai_incident.asset_item_id = i.asset_item_id
			LEFT JOIN dbo.asset_items ai_direct ON ai_direct.asset_item_id = m.asset_item_id
			LEFT JOIN dbo.maintenance_schedules s ON s.schedule_id = m.schedule_id
			""";

	/** Tổng hợp thống kê tài chính bảo trì cho trang danh sách. */
	public record MaintenanceSummary(int totalRecords, int inProgressCount, int completedCount, long totalEstimatedCost,
			long totalActualCost) {
	}

	private static final Pattern PHONE_PATTERN = Pattern.compile("^(0|\\+84)[0-9]{9,10}$");
	private static final long MAX_COST = 1_000_000_000L;

	private final DBConnection db = new DBConnection();

	// ─── QUERIES ────────────────────────────────────────────────────────────────

	public List<MaintenanceRecord> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String clean = search.toUpperCase().replace("#MNT-", "").replace("MNT-", "").replace("#", "").trim();
		String sql = SELECT + """
				WHERE (? = '' OR CAST(m.maintenance_id AS varchar(30)) LIKE ?
				    OR a.asset_code LIKE ? OR a.asset_name LIKE ?
				    OR COALESCE(ai_direct.item_code, ai_incident.item_code) LIKE ?
				    OR m.description LIKE ? OR requester.full_name LIKE ?
				    OR m.note LIKE ? OR m.provider_phone LIKE ?)
				  AND (? = '' OR m.status = ?)
				ORDER BY m.requested_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			String idPattern = "%" + clean + "%";
			int index = 1;
			statement.setString(index++, search);
			statement.setString(index++, idPattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
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

	/** Thống kê tổng hợp tài chính bảo trì. */
	public MaintenanceSummary findSummary() throws SQLException {
		String sql = """
				SELECT COUNT(*) AS total_records,
				       SUM(CASE WHEN status = 'IN_PROGRESS' THEN 1 ELSE 0 END) AS in_progress_count,
				       SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_count,
				       COALESCE(SUM(estimated_cost), 0) AS total_estimated_cost,
				       COALESCE(SUM(actual_cost), 0) AS total_actual_cost
				FROM dbo.maintenance_records
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			result.next();
			return new MaintenanceSummary(result.getInt("total_records"), result.getInt("in_progress_count"),
					result.getInt("completed_count"), result.getLong("total_estimated_cost"),
					result.getLong("total_actual_cost"));
		}
	}

	/**
	 * Tài sản không có sự cố mở, dùng cho bảo dưỡng định kỳ hoặc trực tiếp (kèm
	 * trạng thái mượn nếu có).
	 */
	public List<AssetItem> findRoutineMaintenanceAssets() throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, a.asset_id,
				       ai.item_code, a.asset_code, a.asset_name,
				       COALESCE(ai.storage_location, a.storage_location) AS storage_location,
				       CASE
				           WHEN ai.status = 'IN_USE' OR EXISTS (SELECT 1 FROM dbo.asset_usages u WHERE u.asset_item_id = ai.asset_item_id AND u.status = 'IN_USE') THEN 'IN_USE'
				           WHEN ai.status = 'UNAVAILABLE' THEN 'UNAVAILABLE'
				           ELSE 'AVAILABLE'
				       END AS status
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.status <> 'DISPOSED'
				  AND ai.status <> 'DISPOSED'
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.incidents i
					WHERE i.asset_item_id = ai.asset_item_id AND i.status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.maintenance_records m
					WHERE m.asset_item_id = ai.asset_item_id AND m.status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
				  )
				UNION ALL
				SELECT NULL AS asset_item_id, a.asset_id,
				       a.asset_code AS item_code, a.asset_code, a.asset_name,
				       a.storage_location,
				       CASE
				           WHEN (a.total_quantity - COALESCE((SELECT SUM(u.quantity) FROM dbo.asset_usages u WHERE u.asset_id = a.asset_id AND u.status = 'IN_USE'), 0)) <= 0 THEN 'IN_USE'
				           WHEN a.status = 'UNAVAILABLE' THEN 'UNAVAILABLE'
				           ELSE 'AVAILABLE'
				       END AS status
				FROM dbo.assets a
				WHERE a.status <> 'DISPOSED'
				  AND NOT EXISTS (SELECT 1 FROM dbo.asset_items ai WHERE ai.asset_id = a.asset_id)
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.incidents i
					WHERE i.asset_id = a.asset_id AND i.status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.maintenance_records m
					WHERE m.asset_id = a.asset_id AND m.status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
				  )
				ORDER BY status ASC, asset_name, item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(nullableLong(result, "asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setItemCode(result.getString("item_code"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setStorageLocation(result.getString("storage_location"));
				item.setStatus(result.getString("status"));
				items.add(item);
			}
			return items;
		}
	}

	/** Danh sách sự cố đang xử lý nhưng chưa có phiếu bảo trì đang chạy. */
	public List<Incident> findOpenIncidents() throws SQLException {
		String sql = """
				SELECT i.incident_id, i.asset_id, i.asset_item_id, i.description, a.asset_name, a.asset_code,
				       ai.item_code AS asset_item_code
				FROM dbo.incidents i
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = i.asset_item_id
				WHERE i.status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.maintenance_records m
					WHERE m.incident_id = i.incident_id AND m.status IN ('PENDING', 'APPROVED', 'IN_PROGRESS')
				  )
				ORDER BY i.reported_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Incident> incidents = new ArrayList<>();
			while (result.next()) {
				Incident incident = new Incident();
				incident.setIncidentId(result.getLong("incident_id"));
				incident.setAssetId(result.getLong("asset_id"));
				incident.setAssetItemId(nullableLong(result, "asset_item_id"));
				incident.setDescription(result.getString("description"));
				incident.setAssetName(result.getString("asset_name"));
				incident.setAssetCode(result.getString("asset_code"));
				incident.setAssetItemCode(result.getString("asset_item_code"));
				incidents.add(incident);
			}
			return incidents;
		}
	}

	// ─── WRITES ─────────────────────────────────────────────────────────────────

	/**
	 * Lab Manager tạo phiếu bảo trì mới (trực tiếp IN_PROGRESS). Cập nhật trạng
	 * thái tài sản sang MAINTENANCE trong cùng giao dịch.
	 */
	public long create(long userId, long assetId, Long assetItemId, Long incidentId, Long scheduleId, String note,
			String providerPhone, String providerAddress, String imageUrl, String description, Long estimatedCost)
			throws SQLException {
		validateCommonFields(note, providerPhone, providerAddress, description, estimatedCost);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				// Kiểm tra thiết bị đã có phiếu bảo trì đang xử lý chưa
				if (hasActiveMaintenance(connection, assetId, assetItemId, incidentId)) {
					throw new IllegalStateException(
							"Mục này đã có phiếu bảo trì đang được xử lý. Không thể tạo thêm phiếu mới.");
				}

				// Kiểm tra sự cố theo Phương án B: nếu thiết bị có sự cố mở -> bắt buộc phải
				// chọn sự cố
				if (incidentId == null) {
					if (hasOpenIncidentForAsset(connection, assetId)) {
						throw new IllegalArgumentException(
								"Thiết bị này đang có sự cố hỏng hóc chưa xử lý. Vui lòng chọn sự cố liên quan.");
					}
				} else {
					if (!isIncidentMatchingAsset(connection, incidentId, assetId)) {
						throw new IllegalArgumentException("Sự cố đã chọn không thuộc về thiết bị này.");
					}
				}
				// Kiểm tra thiết bị có đang DISPOSED hoặc UNAVAILABLE không
				if (assetItemId != null) {
					try (PreparedStatement itemCheckStmt = connection
							.prepareStatement("SELECT status FROM dbo.asset_items WHERE asset_item_id = ?")) {
						itemCheckStmt.setLong(1, assetItemId);
						try (ResultSet rs = itemCheckStmt.executeQuery()) {
							if (rs.next()) {
								String st = rs.getString("status");
								if ("DISPOSED".equals(st)) {
									throw new IllegalArgumentException(
											"Thiết bị này đã thanh lý, không thể lập phiếu bảo trì.");
								}
								if ("UNAVAILABLE".equals(st) && incidentId == null) {
									throw new IllegalArgumentException(
											"Thiết bị này đang ở trạng thái Không khả dụng, không thể lập phiếu bảo trì định kỳ.");
								}
							}
						}
					}
				}

				String sql = """
						INSERT INTO dbo.maintenance_records
						    (asset_id, asset_item_id, incident_id, schedule_id, quantity, requested_by, approved_by, approved_at, repair_started_at, note, provider_phone, provider_address, image_url, description, estimated_cost, status)
						OUTPUT INSERTED.maintenance_id
						VALUES (?, ?, ?, ?, 1, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME(), ?, ?, ?, ?, ?, ?, 'IN_PROGRESS')
						""";
				long id;
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, assetId);
					setNullableLong(statement, 2, assetItemId);
					setNullableLong(statement, 3, incidentId);
					setNullableLong(statement, 4, scheduleId);
					statement.setLong(5, userId);
					statement.setLong(6, userId);
					statement.setString(7, blankToNull(note));
					statement.setString(8, blankToNull(providerPhone));
					statement.setString(9, blankToNull(providerAddress));
					statement.setString(10, blankToNull(imageUrl));
					statement.setString(11, description.trim());
					setNullableLong(statement, 12, estimatedCost);
					try (ResultSet result = statement.executeQuery()) {
						result.next();
						id = result.getLong(1);
					}
				}

				// Tự động chuyển trạng thái cá thể thiết bị sang MAINTENANCE và sự cố sang
				// INVESTIGATING
				if (incidentId != null) {
					try (PreparedStatement incStmt = connection.prepareStatement(
							"UPDATE dbo.incidents SET status = 'INVESTIGATING', updated_at = SYSUTCDATETIME() WHERE incident_id = ? AND status IN ('OPEN', 'REPORTED', 'FORWARDED')")) {
						incStmt.setLong(1, incidentId);
						incStmt.executeUpdate();
					}
					try (PreparedStatement itemStmt = connection.prepareStatement("""
							UPDATE ai
							SET ai.status = 'MAINTENANCE', ai.updated_at = SYSUTCDATETIME()
							FROM dbo.asset_items ai
							JOIN dbo.incidents i ON i.asset_item_id = ai.asset_item_id
							WHERE i.incident_id = ? AND ai.status <> 'DISPOSED'
							""")) {
						itemStmt.setLong(1, incidentId);
						itemStmt.executeUpdate();
					}
					syncParentAssetStatus(connection, assetId);
				} else if (assetItemId != null) {
					try (PreparedStatement itemStmt = connection.prepareStatement("""
							UPDATE dbo.asset_items
							SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
							WHERE asset_item_id = ? AND status <> 'DISPOSED'
							""")) {
						itemStmt.setLong(1, assetItemId);
						itemStmt.executeUpdate();
					}
					syncParentAssetStatus(connection, assetId);
				} else {
					setAssetStatus(connection, assetId, "MAINTENANCE");
				}

				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	/**
	 * Lab Manager cập nhật tiến độ sửa chữa (chỉ khi APPROVED / IN_PROGRESS). Khi
	 * COMPLETED: đổi trạng thái thiết bị về AVAILABLE hoặc UNAVAILABLE.
	 */
	public void updateProgress(long id, String newStatus, String note, String providerPhone, String providerAddress,
			String imageUrl, String repairResult, Long estimatedCost, Long actualCost) throws SQLException {
		updateProgress(id, newStatus, note, providerPhone, providerAddress, imageUrl, repairResult, estimatedCost,
				actualCost, null);
	}

	public void updateProgress(long id, String newStatus, String note, String providerPhone, String providerAddress,
			String imageUrl, String repairResult, Long estimatedCost, Long actualCost, Long linkedScheduleId)
			throws SQLException {
		boolean isFailed = "COMPLETED_FAILED".equals(newStatus) || "FAILED".equals(newStatus);
		String dbStatus = (isFailed || "COMPLETED".equals(newStatus) || "COMPLETED_SUCCESS".equals(newStatus))
				? "COMPLETED"
				: newStatus;

		if (!"APPROVED".equals(dbStatus) && !"IN_PROGRESS".equals(dbStatus) && !"COMPLETED".equals(dbStatus)) {
			throw new IllegalArgumentException("Trạng thái tiến độ không hợp lệ.");
		}
		if ("COMPLETED".equals(dbStatus)) {
			if (actualCost == null) {
				throw new IllegalArgumentException("Vui lòng nhập chi phí thực tế.");
			}
			if (repairResult == null || repairResult.isBlank()) {
				throw new IllegalArgumentException(
						"Vui lòng mô tả kết quả sửa chữa / linh kiện thay thế khi hoàn tất nghiệm thu.");
			}
			if (note == null || note.isBlank()) {
				throw new IllegalArgumentException(
						"Vui lòng nhập tên đơn vị hoặc kỹ thuật viên thực hiện sửa chữa khi hoàn tất nghiệm thu.");
			}
		}
		if (repairResult != null && repairResult.trim().length() > 1000) {
			throw new IllegalArgumentException("Kết quả sửa chữa không được vượt quá 1000 ký tự.");
		}
		if (note != null && note.trim().length() > 255) {
			throw new IllegalArgumentException("Tên đơn vị/kỹ thuật viên sửa chữa không được vượt quá 255 ký tự.");
		}
		if (providerAddress != null && providerAddress.trim().length() > 255) {
			throw new IllegalArgumentException("Địa chỉ đơn vị sửa chữa không được vượt quá 255 ký tự.");
		}
		validatePhone(providerPhone);
		validateCost(estimatedCost, "Dự toán kinh phí");
		validateCost(actualCost, "Chi phí thực tế");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				// Lấy asset_id, incident_id và kiểm tra phiếu phải đang ở APPROVED hoặc
				// IN_PROGRESS
				MaintenanceTarget target = requireApprovedOrInProgress(connection, id);

				if (linkedScheduleId != null && target.scheduleId() == null) {
					try (PreparedStatement updateSchedStmt = connection.prepareStatement(
							"UPDATE dbo.maintenance_records SET schedule_id = ?, updated_at = SYSUTCDATETIME() WHERE maintenance_id = ?")) {
						updateSchedStmt.setLong(1, linkedScheduleId);
						updateSchedStmt.setLong(2, id);
						updateSchedStmt.executeUpdate();
					}
				}

				String outcome = "COMPLETED".equals(dbStatus) ? (isFailed ? "FAILED" : "SUCCESS") : "PENDING";
				String sql;
				if ("COMPLETED".equals(dbStatus)) {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'COMPLETED',
							    repair_outcome = ?,
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    repair_completed_at = SYSUTCDATETIME(),
							    note = ?, provider_phone = ?, provider_address = ?,
							    image_url = COALESCE(?, image_url),
							    repair_result = ?, estimated_cost = ?, actual_cost = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ?
							""";
				} else if ("IN_PROGRESS".equals(dbStatus)) {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'IN_PROGRESS',
							    repair_outcome = ?,
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    note = ?, provider_phone = ?, provider_address = ?,
							    image_url = COALESCE(?, image_url),
							    repair_result = ?, estimated_cost = ?, actual_cost = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ?
							""";
				} else {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'APPROVED',
							    repair_outcome = ?,
							    note = ?, provider_phone = ?, provider_address = ?,
							    image_url = COALESCE(?, image_url),
							    repair_result = ?, estimated_cost = ?, actual_cost = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ?
							""";
				}

				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setString(1, outcome);
					statement.setString(2, blankToNull(note));
					statement.setString(3, blankToNull(providerPhone));
					statement.setString(4, blankToNull(providerAddress));
					statement.setString(5, blankToNull(imageUrl));
					statement.setString(6, blankToNull(repairResult));
					setNullableLong(statement, 7, estimatedCost);
					setNullableLong(statement, 8, actualCost);
					statement.setLong(9, id);
					statement.executeUpdate();
				}

				// Cập nhật trạng thái thiết bị và sự cố theo kết quả sửa
				if ("COMPLETED".equals(dbStatus)) {
					String itemStatus = isFailed ? "UNAVAILABLE" : "AVAILABLE";
					if (target.assetItemId() != null) {
						// CHỈ cập nhật đúng cá thể thiết bị con đang bảo trì này!
						try (PreparedStatement itemStmt = connection.prepareStatement(
								"UPDATE dbo.asset_items SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_item_id = ?")) {
							itemStmt.setString(1, itemStatus);
							itemStmt.setLong(2, target.assetItemId());
							itemStmt.executeUpdate();
						}
						syncParentAssetStatus(connection, target.assetId());
					} else {
						// Bảo trì cấp Asset (toàn bộ thiết bị định kỳ)
						try (PreparedStatement assetStmt = connection.prepareStatement(
								"UPDATE dbo.assets SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
							assetStmt.setString(1, itemStatus);
							assetStmt.setLong(2, target.assetId());
							assetStmt.executeUpdate();
						}
						try (PreparedStatement itemStmt = connection.prepareStatement("""
								UPDATE ai
								SET ai.status = ?, ai.updated_at = SYSUTCDATETIME()
								FROM dbo.asset_items ai
								WHERE ai.asset_id = ? AND ai.status <> 'DISPOSED'
								  AND NOT EXISTS (
								    SELECT 1 FROM dbo.incidents i
								    WHERE i.asset_item_id = ai.asset_item_id AND i.status IN ('OPEN', 'INVESTIGATING')
								  )
								""")) {
							itemStmt.setString(1, itemStatus);
							itemStmt.setLong(2, target.assetId());
							itemStmt.executeUpdate();
						}
					}

					if (isFailed) {
						if (target.incidentId() != null) {
							String failNote = blankToNull(repairResult) != null
									? repairResult
									: "Sửa chữa không thành công (hư hỏng nặng). Thiết bị đã chuyển sang trạng thái Không khả dụng để chờ thanh lý.";
							setIncidentResolved(connection, target.incidentId(), failNote);
						}
					} else {
						if (target.incidentId() != null) {
							setIncidentResolved(connection, target.incidentId(), repairResult);
						}
					}

					// Nếu phiếu bảo trì này được liên kết với lịch bảo trì định kỳ cụ thể (LM chọn
					// hoàn tất lịch),
					// cập nhật trạng thái lịch bảo trì đó sang COMPLETED
					Long finalScheduleId = target.scheduleId() != null ? target.scheduleId() : linkedScheduleId;
					if (finalScheduleId != null) {
						try (PreparedStatement schedStmt = connection.prepareStatement("""
								UPDATE dbo.maintenance_schedules
								SET status = 'COMPLETED', updated_at = SYSUTCDATETIME()
								WHERE schedule_id = ? AND status = 'PENDING'
								""")) {
							schedStmt.setLong(1, finalScheduleId);
							schedStmt.executeUpdate();
						}
					}
				}

				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	/**
	 * Lab Manager xóa phiếu bảo trì và hoàn trả trạng thái thiết bị về AVAILABLE.
	 */
	public void delete(long maintenanceId) throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long assetId = -1;
				Long assetItemId = null;
				Long linkedIncidentId = null;
				try (PreparedStatement checkStmt = connection.prepareStatement("""
						SELECT m.asset_id, COALESCE(m.asset_item_id, i.asset_item_id) AS asset_item_id, m.incident_id
						FROM dbo.maintenance_records m
						LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
						WHERE m.maintenance_id = ?
						""")) {
					checkStmt.setLong(1, maintenanceId);
					try (ResultSet rs = checkStmt.executeQuery()) {
						if (!rs.next()) {
							throw new IllegalStateException("Không tìm thấy phiếu bảo trì cần xóa.");
						}
						assetId = rs.getLong("asset_id");
						assetItemId = nullableLong(rs, "asset_item_id");
						linkedIncidentId = nullableLong(rs, "incident_id");
					}
				}

				try (PreparedStatement delStmt = connection
						.prepareStatement("DELETE FROM dbo.maintenance_records WHERE maintenance_id = ?")) {
					delStmt.setLong(1, maintenanceId);
					delStmt.executeUpdate();
				}

				if (linkedIncidentId != null) {
					try (PreparedStatement incStmt = connection.prepareStatement(
							"UPDATE dbo.incidents SET status = 'FORWARDED', updated_at = SYSUTCDATETIME() WHERE incident_id = ? AND status = 'INVESTIGATING'")) {
						incStmt.setLong(1, linkedIncidentId);
						incStmt.executeUpdate();
					}
				}

				if (assetItemId != null) {
					// Chỉ hoàn trả cá thể này về AVAILABLE nếu không còn sự cố mở
					try (PreparedStatement itemStmt = connection.prepareStatement(
							"""
									UPDATE dbo.asset_items
									SET status = 'AVAILABLE', updated_at = SYSUTCDATETIME()
									WHERE asset_item_id = ? AND status = 'MAINTENANCE'
									  AND NOT EXISTS (SELECT 1 FROM dbo.incidents WHERE asset_item_id = ? AND status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING'))
									""")) {
						itemStmt.setLong(1, assetItemId);
						itemStmt.setLong(2, assetItemId);
						itemStmt.executeUpdate();
					}
					syncParentAssetStatus(connection, assetId);
				} else {
					if (!hasOpenIncidentForAsset(connection, assetId)) {
						try (PreparedStatement assetStmt = connection.prepareStatement(
								"UPDATE dbo.assets SET status = 'AVAILABLE', updated_at = SYSUTCDATETIME() WHERE asset_id = ? AND status = 'MAINTENANCE'")) {
							assetStmt.setLong(1, assetId);
							assetStmt.executeUpdate();
						}
						try (PreparedStatement itemStmt = connection.prepareStatement(
								"""
										UPDATE ai
										SET ai.status = 'AVAILABLE', ai.updated_at = SYSUTCDATETIME()
										FROM dbo.asset_items ai
										WHERE ai.asset_id = ? AND ai.status = 'MAINTENANCE'
										  AND NOT EXISTS (SELECT 1 FROM dbo.incidents i WHERE i.asset_item_id = ai.asset_item_id AND i.status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING'))
										""")) {
							itemStmt.setLong(1, assetId);
							itemStmt.executeUpdate();
						}
					}
				}

				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	// ─── PRIVATE HELPERS ────────────────────────────────────────────────────────

	private boolean isIncidentMatchingAsset(Connection connection, long incidentId, long assetId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT 1 FROM dbo.incidents WHERE incident_id = ? AND asset_id = ?")) {
			statement.setLong(1, incidentId);
			statement.setLong(2, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private void validateCommonFields(String note, String providerPhone, String providerAddress, String description,
			Long estimatedCost) {
		if (description == null || description.trim().isBlank()) {
			throw new IllegalArgumentException("Mô tả tình trạng hỏng hóc và yêu cầu sửa chữa không được để trống.");
		}
		if (description.trim().length() > 1000) {
			throw new IllegalArgumentException("Mô tả tình trạng hỏng hóc không được vượt quá 1000 ký tự.");
		}
		if (note != null && note.trim().length() > 255) {
			throw new IllegalArgumentException("Tên đơn vị/kỹ thuật viên sửa chữa không được vượt quá 255 ký tự.");
		}
		if (providerAddress != null && providerAddress.trim().length() > 255) {
			throw new IllegalArgumentException("Địa chỉ đơn vị sửa chữa không được vượt quá 255 ký tự.");
		}
		validatePhone(providerPhone);
		validateCost(estimatedCost, "Dự toán kinh phí");
	}

	private void validatePhone(String phone) {
		if (phone == null || phone.isBlank()) {
			return;
		}
		String cleanPhone = phone.trim().replaceAll("[.\\s-]", "");
		if (!PHONE_PATTERN.matcher(cleanPhone).matches()) {
			throw new IllegalArgumentException(
					"Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số).");
		}
		if (phone.trim().length() > 30) {
			throw new IllegalArgumentException("Số điện thoại không được vượt quá 30 ký tự.");
		}
	}

	private void validateCost(Long cost, String fieldName) {
		if (cost != null && (cost < 0 || cost > MAX_COST)) {
			throw new IllegalArgumentException(fieldName + " phải nằm trong khoảng từ 0 đến 1.000.000.000 VNĐ.");
		}
	}

	private boolean hasOpenIncidentForAsset(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.incidents WHERE asset_id = ? AND status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasActiveMaintenance(Connection connection, long assetId, Long assetItemId, Long incidentId)
			throws SQLException {
		if (incidentId != null) {
			try (PreparedStatement statement = connection.prepareStatement(
					"SELECT 1 FROM dbo.maintenance_records WHERE incident_id = ? AND status IN ('PENDING','APPROVED','IN_PROGRESS')")) {
				statement.setLong(1, incidentId);
				try (ResultSet result = statement.executeQuery()) {
					return result.next();
				}
			}
		}
		if (assetItemId != null) {
			try (PreparedStatement statement = connection.prepareStatement(
					"SELECT 1 FROM dbo.maintenance_records WHERE asset_item_id = ? AND status IN ('PENDING','APPROVED','IN_PROGRESS')")) {
				statement.setLong(1, assetItemId);
				try (ResultSet result = statement.executeQuery()) {
					return result.next();
				}
			}
		}
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.maintenance_records WHERE asset_id = ? AND asset_item_id IS NULL AND incident_id IS NULL AND status IN ('PENDING','APPROVED','IN_PROGRESS')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private record MaintenanceTarget(long assetId, Long incidentId, Long assetItemId, Long scheduleId) {
	}

	private MaintenanceTarget requireApprovedOrInProgress(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"""
						SELECT m.asset_id, m.incident_id, m.schedule_id, COALESCE(m.asset_item_id, i.asset_item_id) AS asset_item_id
						FROM dbo.maintenance_records m
						LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
						WHERE m.maintenance_id = ? AND m.status IN ('APPROVED','IN_PROGRESS','COMPLETED')
						""")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException(
							"Không tìm thấy phiếu bảo trì hoặc phiếu không hợp lệ để chỉnh sửa.");
				}
				long assetId = result.getLong("asset_id");
				Long incidentId = nullableLong(result, "incident_id");
				Long assetItemId = nullableLong(result, "asset_item_id");
				Long scheduleId = nullableLong(result, "schedule_id");
				return new MaintenanceTarget(assetId, incidentId, assetItemId, scheduleId);
			}
		}
	}

	private void syncParentAssetStatus(Connection connection, long assetId) throws SQLException {
		String sql = """
				UPDATE dbo.assets
				SET status = CASE
				    WHEN EXISTS (SELECT 1 FROM dbo.asset_items WHERE asset_id = ? AND status = 'AVAILABLE') THEN 'AVAILABLE'
				    WHEN EXISTS (SELECT 1 FROM dbo.asset_items WHERE asset_id = ? AND status = 'MAINTENANCE') THEN 'MAINTENANCE'
				    ELSE 'UNAVAILABLE'
				END,
				updated_at = SYSUTCDATETIME()
				WHERE asset_id = ? AND status <> 'DISPOSED'
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			statement.setLong(2, assetId);
			statement.setLong(3, assetId);
			statement.executeUpdate();
		}
	}

	private void setIncidentResolved(Connection connection, long incidentId, String repairResult) throws SQLException {
		String sql = """
				UPDATE dbo.incidents
				SET status = 'RESOLVED',
				    handling_result = COALESCE(?, handling_result, N'Đã hoàn tất bảo trì sửa chữa thiết bị.'),
				    updated_at = SYSUTCDATETIME()
				WHERE incident_id = ? AND status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, blankToNull(repairResult));
			statement.setLong(2, incidentId);
			statement.executeUpdate();
		}
	}

	private void setAssetStatus(Connection connection, long assetId, String status) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.assets SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
			statement.setString(1, status);
			statement.setLong(2, assetId);
			statement.executeUpdate();
		}
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.asset_items SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ? AND status <> 'DISPOSED'")) {
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
				record.setAssetItemId(nullableLong(result, "asset_item_id"));
				record.setIncidentId(nullableLong(result, "incident_id"));
				record.setScheduleId(nullableLong(result, "schedule_id"));
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
				record.setEstimatedCost(nullableLong(result, "estimated_cost"));
				record.setActualCost(nullableLong(result, "actual_cost"));
				record.setNote(result.getString("note"));
				record.setProviderPhone(result.getString("provider_phone"));
				record.setProviderAddress(result.getString("provider_address"));
				record.setImageUrl(result.getString("image_url"));
				record.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				record.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				// Joined fields
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setAssetStatus(result.getString("asset_status"));
				record.setStorageLocation(result.getString("storage_location"));
				record.setRequesterName(result.getString("requester_name"));
				record.setApproverName(result.getString("approver_name"));
				record.setIncidentDescription(result.getString("incident_description"));
				record.setAssetItemCode(result.getString("asset_item_code"));
				record.setScheduleTitle(result.getString("schedule_title"));
				java.sql.Date schedDate = result.getDate("scheduled_date");
				record.setScheduledDate(schedDate == null ? null : schedDate.toLocalDate());
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
