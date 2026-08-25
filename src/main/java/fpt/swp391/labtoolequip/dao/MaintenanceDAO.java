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
	 * Tạo yêu cầu trong hàng chờ PENDING; chưa đổi trạng thái vòng đời thiết bị.
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
					if (hasOpenIncidentForTarget(connection, assetId, assetItemId)) {
						throw new IllegalArgumentException(
								"Thiết bị này đang có sự cố hỏng hóc chưa xử lý. Vui lòng chọn sự cố liên quan.");
					}
				} else {
					if (!isIncidentMatchingTarget(connection, incidentId, assetId, assetItemId)) {
						throw new IllegalArgumentException("Sự cố đã chọn không thuộc về thiết bị này.");
					}
				}
				if (assetItemId != null) {
					try (PreparedStatement itemCheckStmt = connection.prepareStatement("""
							SELECT status, asset_id FROM dbo.asset_items WITH (UPDLOCK,HOLDLOCK)
							WHERE asset_item_id = ?
							""")) {
						itemCheckStmt.setLong(1, assetItemId);
						try (ResultSet rs = itemCheckStmt.executeQuery()) {
							if (!rs.next() || rs.getLong("asset_id") != assetId)
								throw new IllegalArgumentException("Thiết bị được chọn không hợp lệ.");
							if (!List.of("AVAILABLE", "UNAVAILABLE").contains(rs.getString("status")))
								throw new IllegalArgumentException(
										"Chỉ thiết bị sẵn sàng hoặc đang ở hàng chờ xử lý mới được lập yêu cầu bảo trì.");
						}
					}
					if (hasActiveUsageOrAllocation(connection, assetItemId) || hasOpenDisposal(connection, assetItemId))
						throw new IllegalStateException(
								"Thiết bị đang được sử dụng, cấp phát hoặc nằm trong hàng chờ thanh lý.");
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

				startMaintenance(connection,
						new MaintenanceTarget(assetId, incidentId, assetItemId, scheduleId, "IN_PROGRESS"));

				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public List<MaintenanceRecord> findForRequester(long requesterId, String keyword, String status)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String clean = search.toUpperCase().replace("#MNT-", "").replace("MNT-", "").replace("#", "").trim();
		String sql = SELECT + """
				WHERE m.requested_by = ?
				  AND (? = '' OR CAST(m.maintenance_id AS varchar(30)) LIKE ?
				    OR a.asset_code LIKE ? OR a.asset_name LIKE ?
				    OR COALESCE(ai_direct.item_code, ai_incident.item_code) LIKE ?)
				  AND (? = '' OR m.status = ?)
				ORDER BY m.requested_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setLong(index++, requesterId);
			statement.setString(index++, search);
			statement.setString(index++, "%" + clean + "%");
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index, state);
			return read(statement);
		}
	}

	public Optional<MaintenanceRecord> findByIdForRequester(long id, long requesterId) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement(SELECT + " WHERE m.maintenance_id=? AND m.requested_by=?")) {
			statement.setLong(1, id);
			statement.setLong(2, requesterId);
			return read(statement).stream().findFirst();
		}
	}

	public void review(long id, long managerId, boolean approved, String note) throws SQLException {
		if (!approved && (note == null || note.isBlank()))
			throw new IllegalArgumentException("Vui lòng nhập lý do từ chối yêu cầu bảo trì.");
		String status = approved ? "APPROVED" : "REJECTED";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				UPDATE dbo.maintenance_records
				SET status=?, approved_by=?, approved_at=SYSUTCDATETIME(), approval_note=?, updated_at=SYSUTCDATETIME()
				WHERE maintenance_id=? AND status='PENDING'
				  AND EXISTS (SELECT 1 FROM dbo.users WHERE user_id=? AND role='LAB_MANAGER' AND status='ACTIVE')
				""")) {
			statement.setString(1, status);
			statement.setLong(2, managerId);
			statement.setString(3, blankToNull(note));
			statement.setLong(4, id);
			statement.setLong(5, managerId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Yêu cầu bảo trì không còn ở hàng chờ duyệt.");
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
		boolean isFailed = "COMPLETED_FAILED".equals(newStatus);
		String dbStatus = (isFailed || "COMPLETED_SUCCESS".equals(newStatus)) ? "COMPLETED" : newStatus;

		if (!"IN_PROGRESS".equals(dbStatus) && !"COMPLETED".equals(dbStatus)) {
			throw new IllegalArgumentException("Trạng thái tiến độ không hợp lệ.");
		}
		String expectedStatus = "IN_PROGRESS".equals(dbStatus) ? "APPROVED" : "IN_PROGRESS";
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
				MaintenanceTarget target = requireMaintenanceTarget(connection, id, dbStatus);
				if ("IN_PROGRESS".equals(dbStatus) && "APPROVED".equals(target.currentStatus())) {
					startMaintenance(connection, target);
				}

				if (linkedScheduleId != null && target.scheduleId() == null) {
					try (PreparedStatement updateSchedStmt = connection.prepareStatement(
							"UPDATE dbo.maintenance_records SET schedule_id = ?, updated_at = SYSUTCDATETIME() WHERE maintenance_id = ?")) {
						updateSchedStmt.setLong(1, linkedScheduleId);
						updateSchedStmt.setLong(2, id);
						updateSchedStmt.executeUpdate();
					}
				}

				String sql;
				if ("COMPLETED".equals(dbStatus)) {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'COMPLETED',
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    repair_completed_at = SYSUTCDATETIME(),
							    note = ?, provider_phone = ?, provider_address = ?,
							    image_url = COALESCE(?, image_url),
							    repair_result = ?, estimated_cost = ?, actual_cost = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ? AND status = 'IN_PROGRESS'
							""";
				} else if ("IN_PROGRESS".equals(dbStatus)) {
					sql = """
							UPDATE dbo.maintenance_records
							SET status = 'IN_PROGRESS',
							    repair_started_at = COALESCE(repair_started_at, SYSUTCDATETIME()),
							    note = ?, provider_phone = ?, provider_address = ?,
							    image_url = COALESCE(?, image_url),
							    repair_result = ?, estimated_cost = ?, actual_cost = ?,
							    updated_at = SYSUTCDATETIME()
							WHERE maintenance_id = ? AND status IN ('APPROVED', 'IN_PROGRESS')
							""";
				} else {
					throw new IllegalStateException("Không thể cập nhật trực tiếp sang trạng thái này.");
				}

				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setString(1, blankToNull(note));
					statement.setString(2, blankToNull(providerPhone));
					statement.setString(3, blankToNull(providerAddress));
					statement.setString(4, blankToNull(imageUrl));
					statement.setString(5, blankToNull(repairResult));
					setNullableLong(statement, 6, estimatedCost);
					setNullableLong(statement, 7, actualCost);
					statement.setLong(8, id);
					if (statement.executeUpdate() != 1)
						throw new IllegalStateException(
								"Phiếu bảo trì đã được người khác xử lý hoặc không còn ở đúng bước.");
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
									    WHERE i.asset_item_id = ai.asset_item_id
									      AND i.status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING')
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
									: "Sửa chữa không thành công. Thiết bị đã chuyển về hàng chờ để Lab Manager quyết định bước tiếp theo.";
							try (PreparedStatement incidentStmt = connection.prepareStatement("""
									UPDATE dbo.incidents
									SET status = 'INVESTIGATING', investigation_note = ?, updated_at = SYSUTCDATETIME()
									WHERE incident_id = ? AND status <> 'RESOLVED'
									""")) {
								incidentStmt.setString(1, failNote);
								incidentStmt.setLong(2, target.incidentId());
								incidentStmt.executeUpdate();
							}
						}
					} else {
						if (target.incidentId() != null) {
							setIncidentResolved(connection, target.incidentId(), repairResult);
						}
					}

					if (target.scheduleId() != null) {
						try (PreparedStatement schedStmt = connection.prepareStatement(
								"UPDATE dbo.maintenance_schedules SET status = 'COMPLETED', updated_at = SYSUTCDATETIME() WHERE schedule_id = ?")) {
							schedStmt.setLong(1, target.scheduleId());
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
	 * Cho phép xóa yêu cầu PENDING hoặc phiếu bảo trì IN_PROGRESS của Lab Manager.
	 * Khi xóa phiếu IN_PROGRESS: khôi phục lại trạng thái thiết bị về AVAILABLE.
	 */
	public void delete(long maintenanceId) throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				MaintenanceTarget target;
				try (PreparedStatement statement = connection.prepareStatement(
						"""
								SELECT m.asset_id, m.incident_id, m.schedule_id, m.status, COALESCE(m.asset_item_id, i.asset_item_id) AS asset_item_id
								FROM dbo.maintenance_records m
								LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
								WHERE m.maintenance_id = ? AND m.status IN ('PENDING', 'IN_PROGRESS', 'APPROVED')
								""")) {
					statement.setLong(1, maintenanceId);
					try (ResultSet rs = statement.executeQuery()) {
						if (!rs.next()) {
							throw new IllegalStateException("Chỉ phiếu bảo trì chưa hoàn thành mới có thể xóa.");
						}
						target = new MaintenanceTarget(rs.getLong("asset_id"), nullableLong(rs, "incident_id"),
								nullableLong(rs, "asset_item_id"), nullableLong(rs, "schedule_id"),
								rs.getString("status"));
					}
				}

				try (PreparedStatement delStmt = connection
						.prepareStatement("DELETE FROM dbo.maintenance_records WHERE maintenance_id = ?")) {
					delStmt.setLong(1, maintenanceId);
					delStmt.executeUpdate();
				}

				// Rollback asset status to AVAILABLE if it was in MAINTENANCE
				if ("IN_PROGRESS".equals(target.currentStatus())) {
					if (target.assetItemId() != null) {
						try (PreparedStatement itemStmt = connection.prepareStatement(
								"UPDATE dbo.asset_items SET status = 'AVAILABLE', updated_at = SYSUTCDATETIME() WHERE asset_item_id = ? AND status = 'MAINTENANCE'")) {
							itemStmt.setLong(1, target.assetItemId());
							itemStmt.executeUpdate();
						}
						syncParentAssetStatus(connection, target.assetId());
					} else {
						try (PreparedStatement assetStmt = connection.prepareStatement(
								"UPDATE dbo.assets SET status = 'AVAILABLE', updated_at = SYSUTCDATETIME() WHERE asset_id = ? AND status = 'MAINTENANCE'")) {
							assetStmt.setLong(1, target.assetId());
							assetStmt.executeUpdate();
						}
					}
				}

				connection.commit();
			} catch (SQLException | RuntimeException e) {
				connection.rollback();
				throw e;
			}
		}
	}

	// ─── PRIVATE HELPERS ────────────────────────────────────────────────────────

	private boolean isIncidentMatchingTarget(Connection connection, long incidentId, long assetId, Long assetItemId)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.incidents
				WHERE incident_id=? AND asset_id=? AND (? IS NULL OR asset_item_id=?)
				  AND status IN ('OPEN','REPORTED','FORWARDED','INVESTIGATING')
				""")) {
			statement.setLong(1, incidentId);
			statement.setLong(2, assetId);
			if (assetItemId == null) {
				statement.setNull(3, java.sql.Types.BIGINT);
				statement.setNull(4, java.sql.Types.BIGINT);
			} else {
				statement.setLong(3, assetItemId);
				statement.setLong(4, assetItemId);
			}
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

	private boolean hasOpenIncidentForTarget(Connection connection, long assetId, Long assetItemId)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1 FROM dbo.incidents
				WHERE asset_id=? AND status IN ('OPEN','REPORTED','FORWARDED','INVESTIGATING')
				  AND ((? IS NULL AND asset_item_id IS NULL) OR asset_item_id=?)
				""")) {
			statement.setLong(1, assetId);
			if (assetItemId == null) {
				statement.setNull(2, java.sql.Types.BIGINT);
				statement.setNull(3, java.sql.Types.BIGINT);
			} else {
				statement.setLong(2, assetItemId);
				statement.setLong(3, assetItemId);
			}
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

	private record MaintenanceTarget(long assetId, Long incidentId, Long assetItemId, Long scheduleId,
			String currentStatus) {
	}

	private MaintenanceTarget requireMaintenanceTarget(Connection connection, long id, String expectedStatus)
			throws SQLException {
		String statusCondition = "COMPLETED".equals(expectedStatus)
				? "m.status = 'IN_PROGRESS'"
				: "m.status IN ('APPROVED', 'IN_PROGRESS')";
		try (PreparedStatement statement = connection.prepareStatement(
				"""
						SELECT m.asset_id, m.incident_id, m.schedule_id, m.status, COALESCE(m.asset_item_id, i.asset_item_id) AS asset_item_id
						FROM dbo.maintenance_records m
						LEFT JOIN dbo.incidents i ON i.incident_id = m.incident_id
						WHERE m.maintenance_id = ? AND """
						+ statusCondition)) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException(
							"Phiếu bảo trì đã được người khác xử lý hoặc không còn ở đúng bước.");
				}
				long assetId = result.getLong("asset_id");
				Long incidentId = nullableLong(result, "incident_id");
				Long assetItemId = nullableLong(result, "asset_item_id");
				Long scheduleId = nullableLong(result, "schedule_id");
				String currentStatus = result.getString("status");
				return new MaintenanceTarget(assetId, incidentId, assetItemId, scheduleId, currentStatus);
			}
		}
	}

	private void startMaintenance(Connection connection, MaintenanceTarget target) throws SQLException {
		if (target.assetItemId() != null) {
			if (hasActiveUsageOrAllocation(connection, target.assetItemId())
					|| hasOpenDisposal(connection, target.assetItemId()))
				throw new IllegalStateException(
						"Thiết bị đang được sử dụng, cấp phát hoặc nằm trong hàng chờ thanh lý.");
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.asset_items SET status='MAINTENANCE', updated_at=SYSUTCDATETIME()
					WHERE asset_item_id=? AND status IN ('AVAILABLE','UNAVAILABLE')
					""")) {
				statement.setLong(1, target.assetItemId());
				if (statement.executeUpdate() != 1)
					throw new IllegalStateException("Thiết bị không còn ở hàng chờ hoặc trạng thái sẵn sàng.");
			}
			syncParentAssetStatus(connection, target.assetId());
		} else {
			try (PreparedStatement statement = connection.prepareStatement(
					"""
							UPDATE dbo.assets SET status='MAINTENANCE', updated_at=SYSUTCDATETIME()
							WHERE asset_id=? AND status IN ('AVAILABLE','UNAVAILABLE')
							  AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages u WHERE u.asset_id=? AND u.status IN ('IN_USE','RETURN_PENDING'))
							""")) {
				statement.setLong(1, target.assetId());
				statement.setLong(2, target.assetId());
				if (statement.executeUpdate() != 1)
					throw new IllegalStateException(
							"Nhóm thiết bị đang được sử dụng hoặc không còn sẵn sàng để bảo trì.");
			}
		}
	}

	private boolean hasActiveUsageOrAllocation(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"""
						SELECT 1
						WHERE EXISTS (SELECT 1 FROM dbo.asset_usages WHERE asset_item_id=? AND status IN ('IN_USE','RETURN_PENDING'))
						   OR EXISTS (SELECT 1 FROM dbo.equipment_allocations WHERE asset_item_id=? AND status IN ('READY_FOR_HANDOVER','ACTIVE','ISSUE_REPORTED'))
						""")) {
			statement.setLong(1, assetItemId);
			statement.setLong(2, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean hasOpenDisposal(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.disposal_records WHERE asset_item_id=? AND status IN ('PENDING','APPROVED')")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
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
