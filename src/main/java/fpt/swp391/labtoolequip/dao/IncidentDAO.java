package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Incident;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public class IncidentDAO {
	private static final Set<String> SEVERITIES = Set.of("LOW", "MEDIUM", "HIGH", "CRITICAL");
	private static final Set<String> TECHNICAL_CAUSES = Set.of("NATURAL_WEAR", "EQUIPMENT_FAILURE", "ACCIDENTAL_DAMAGE",
			"MISUSE", "PROCEDURE_VIOLATION", "LOSS", "UNKNOWN");
	private static final Set<String> TECHNICAL_SEVERITIES = Set.of("MINOR", "MODERATE", "MAJOR", "CRITICAL");
	private static final Set<String> REPAIRABILITIES = Set.of("PENDING", "REPAIRABLE", "NOT_REPAIRABLE",
			"NOT_APPLICABLE");
	private static final Set<String> RECOMMENDED_ACTIONS = Set.of("CONTINUE_USE", "MONITOR", "MAINTENANCE",
			"REMOVE_FROM_USE", "DISPOSAL_REVIEW");
	private static final String SELECT = """
			SELECT i.*, a.asset_code, a.asset_name, reporter.full_name AS reporter_name, reporter.role AS reporter_role,
			       ai.item_code AS asset_item_code,
			       sp.student_code AS intern_code, intern.full_name AS intern_name,
			       reviewer.full_name AS reviewer_name, assessor.full_name AS technical_assessor_name
			FROM dbo.incidents i
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			JOIN dbo.users reporter ON reporter.user_id = i.reported_by
			LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = COALESCE(i.asset_item_id, au.asset_item_id)
			LEFT JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
			LEFT JOIN dbo.users intern ON intern.user_id = sp.user_id
			LEFT JOIN dbo.users reviewer ON reviewer.user_id = i.reviewed_by
			LEFT JOIN dbo.users assessor ON assessor.user_id = i.technical_assessed_by
			""";
	private final DBConnection db = new DBConnection();

	public List<Incident> findAll(String keyword, String status, String severity) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?
				       OR reporter.full_name LIKE ? OR COALESCE(intern.full_name, '') LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 7; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public List<Incident> findForIntern(long internUserId, String keyword, String status, String severity)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE (i.reported_by = ? OR EXISTS (
					SELECT 1 FROM dbo.asset_usages related_usage
					JOIN dbo.intern_profiles related_intern ON related_intern.intern_id = related_usage.student_id
					WHERE related_usage.asset_usage_id = i.asset_usage_id AND related_intern.user_id = ?
				))
				  AND (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setLong(index++, internUserId);
			statement.setLong(index++, internUserId);
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public List<Incident> findForMentor(long mentorId, String keyword, String status, String severity)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE (i.reported_by = ? OR EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests request
					WHERE request.request_id = au.request_id
					  AND request.semester_id = au.semester_id
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				))
				  AND (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setLong(index++, mentorId);
			statement.setLong(index++, mentorId);
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public List<Incident> findForLabManager(String keyword, String status, String severity) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE i.status IN ('FORWARDED', 'INVESTIGATING', 'RESOLVED', 'CLOSED', 'OPEN')
				  AND (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?
				       OR reporter.full_name LIKE ? OR COALESCE(intern.full_name, '') LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 7; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public Optional<Incident> findById(long incidentId) throws SQLException {
		String sql = SELECT + " WHERE i.incident_id = ?";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			return read(statement).stream().findFirst();
		}
	}

	public Optional<Incident> findByIdForIntern(long incidentId, long internUserId) throws SQLException {
		String sql = SELECT + """
				WHERE i.incident_id = ? AND (i.reported_by = ? OR EXISTS (
					SELECT 1 FROM dbo.asset_usages related_usage
					JOIN dbo.intern_profiles related_intern ON related_intern.intern_id = related_usage.student_id
					WHERE related_usage.asset_usage_id = i.asset_usage_id AND related_intern.user_id = ?
				))
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			statement.setLong(2, internUserId);
			statement.setLong(3, internUserId);
			return read(statement).stream().findFirst();
		}
	}

	public Optional<Incident> findByIdForMentor(long incidentId, long mentorId) throws SQLException {
		String sql = SELECT + """
				WHERE i.incident_id = ? AND (i.reported_by = ? OR EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests request
					WHERE request.request_id = au.request_id
					  AND request.semester_id = au.semester_id
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				))
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			statement.setLong(2, mentorId);
			statement.setLong(3, mentorId);
			return read(statement).stream().findFirst();
		}
	}

	public Optional<Incident> findByIdForLabManager(long incidentId) throws SQLException {
		String sql = SELECT + """
				WHERE i.incident_id = ? AND i.status IN ('FORWARDED', 'INVESTIGATING', 'RESOLVED', 'CLOSED', 'OPEN')
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			return read(statement).stream().findFirst();
		}
	}

	public long createForIntern(long internUserId, long usageId, String incidentType, String severity,
			LocalDateTime occurredAt, String description) throws SQLException {
		validateReport(incidentType, severity, description, occurredAt);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				IncidentTarget target = resolveInternUsageTarget(connection, usageId, internUserId);
				if (hasActiveIncident(connection, target))
					throw new IllegalStateException("Thiết bị này đã có sự cố đang được xử lý.");
				long incidentId = insertIncident(connection, target, internUserId, incidentType, severity, occurredAt,
						description, "REPORTED", "UNKNOWN", false);
				quarantineAvailableItem(connection, target.assetItemId());
				connection.commit();
				return incidentId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public long createForMentor(long mentorId, long usageId, String incidentType, String severity,
			LocalDateTime occurredAt, String description) throws SQLException {
		return createForMentor(mentorId, new String[]{"usage:" + usageId}, incidentType, severity, occurredAt,
				description, "UNKNOWN").get(0);
	}

	public List<Long> createForMentor(long mentorId, String[] targetValues, String incidentType, String severity,
			LocalDateTime occurredAt, String description, String reportedCause) throws SQLException {
		validateReport(incidentType, severity, description, occurredAt);
		reportedCause = normalizeReportedCause(reportedCause);
		if (targetValues == null || targetValues.length == 0)
			throw new IllegalArgumentException("Vui lòng chọn ít nhất một vật dụng gặp sự cố.");
		LinkedHashSet<String> uniqueTargets = new LinkedHashSet<>();
		for (String value : targetValues) {
			if (value != null && !value.isBlank())
				uniqueTargets.add(value);
		}
		if (uniqueTargets.isEmpty())
			throw new IllegalArgumentException("Vui lòng chọn ít nhất một vật dụng gặp sự cố.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				List<Long> incidentIds = new ArrayList<>();
				for (String value : uniqueTargets) {
					IncidentTarget target = resolveMentorTarget(connection, value, mentorId);
					if (hasActiveIncident(connection, target))
						throw new IllegalStateException("Vật dụng đã có sự cố đang được xử lý.");
					incidentIds.add(insertIncident(connection, target, mentorId, incidentType, severity, occurredAt,
							description, "FORWARDED", reportedCause, true));
					quarantineAvailableItem(connection, target.assetItemId());
				}
				connection.commit();
				return incidentIds;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void reviewAndForward(long incidentId, long mentorId, String mentorReviewNote) throws SQLException {
		validateMentorReviewNote(mentorReviewNote);
		String sql = """
				UPDATE incident
				SET status = 'FORWARDED', reviewed_by = ?, reviewed_at = SYSUTCDATETIME(),
				    mentor_review_note = ?, forwarded_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
				FROM dbo.incidents incident
				WHERE incident.incident_id = ? AND incident.status = 'REPORTED'
				  AND EXISTS (
					SELECT 1 FROM dbo.asset_usages usage
					JOIN dbo.intern_profiles intern ON intern.intern_id = usage.student_id
					JOIN dbo.lab_usage_requests request
					  ON request.request_id = usage.request_id AND request.semester_id = usage.semester_id
					WHERE usage.asset_usage_id = incident.asset_usage_id
					  AND intern.user_id = incident.reported_by
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				  )
				  AND EXISTS (
					SELECT 1 FROM dbo.users mentor
					WHERE mentor.user_id = ? AND mentor.role = 'MENTOR' AND mentor.status = 'ACTIVE'
				  )
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			connection.setAutoCommit(false);
			try {
				statement.setLong(1, mentorId);
				statement.setString(2, mentorReviewNote.trim());
				statement.setLong(3, incidentId);
				statement.setLong(4, mentorId);
				statement.setLong(5, mentorId);
				if (statement.executeUpdate() != 1)
					throw new IllegalStateException(
							"Sự cố không còn chờ bạn duyệt hoặc không thuộc phạm vi phụ trách.");
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updateByLabManager(long incidentId, long managerId, String nextStatus, String technicalCause,
			String technicalSeverity, String repairability, String recommendedAction, String technicalNote,
			String handlingResult) throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				IncidentTechnicalState current = lockTechnicalState(connection, incidentId, managerId);
				validateLabManagerTransition(current.status(), nextStatus);
				if ("RESOLVED".equals(nextStatus)) {
					validateTechnicalAssessment(nextStatus, technicalCause, technicalSeverity, repairability,
							recommendedAction, technicalNote, handlingResult);
					updateResolvedIncident(connection, incidentId, managerId, technicalCause, technicalSeverity,
							repairability, recommendedAction, technicalNote, handlingResult);
				} else {
					updateIncidentStatus(connection, incidentId, current.status(), nextStatus);
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	static void validateReport(String incidentType, String severity, String description, LocalDateTime occurredAt) {
		if (incidentType == null || !Set.of("DAMAGE", "MISSING", "LOSS", "MALFUNCTION", "OTHER").contains(incidentType))
			throw new IllegalArgumentException("Loại sự cố không hợp lệ.");
		if (!SEVERITIES.contains(severity))
			throw new IllegalArgumentException("Mức độ sự cố không hợp lệ.");
		if (description == null || description.isBlank() || description.trim().length() > 2000)
			throw new IllegalArgumentException("Mô tả sự cố phải có từ 1 đến 2000 ký tự.");
		if (occurredAt != null && occurredAt.isAfter(ViewFormat.now()))
			throw new IllegalArgumentException("Thời điểm xảy ra không được ở tương lai.");
	}

	private void quarantineAvailableItem(Connection connection, Long assetItemId) throws SQLException {
		if (assetItemId == null)
			return;
		try (PreparedStatement statement = connection.prepareStatement("""
				UPDATE dbo.asset_items
				SET status='UNAVAILABLE', updated_at=SYSUTCDATETIME()
				WHERE asset_item_id=? AND status='AVAILABLE'
				""")) {
			statement.setLong(1, assetItemId);
			statement.executeUpdate();
		}
	}

	static void validateMentorReviewNote(String mentorReviewNote) {
		if (mentorReviewNote == null || mentorReviewNote.isBlank() || mentorReviewNote.trim().length() > 2000)
			throw new IllegalArgumentException("Ghi chú duyệt của Mentor phải có từ 1 đến 2000 ký tự.");
	}

	static String nextLabManagerStatus(String currentStatus) {
		return switch (currentStatus) {
			case "FORWARDED" -> "INVESTIGATING";
			case "INVESTIGATING" -> "RESOLVED";
			case "RESOLVED" -> "CLOSED";
			default -> null;
		};
	}

	static void validateLabManagerTransition(String currentStatus, String nextStatus) {
		if (!java.util.Objects.equals(nextStatus, nextLabManagerStatus(currentStatus)))
			throw new IllegalArgumentException("Chuyển trạng thái xử lý sự cố không hợp lệ.");
	}

	static void validateTechnicalAssessment(String nextStatus, String technicalCause, String technicalSeverity,
			String repairability, String recommendedAction, String technicalNote, String handlingResult) {
		if (!"RESOLVED".equals(nextStatus))
			return;
		if (!TECHNICAL_CAUSES.contains(technicalCause))
			throw new IllegalArgumentException("Nguyên nhân kỹ thuật không hợp lệ.");
		if (!TECHNICAL_SEVERITIES.contains(technicalSeverity))
			throw new IllegalArgumentException("Mức độ kỹ thuật không hợp lệ.");
		if (!REPAIRABILITIES.contains(repairability) || "PENDING".equals(repairability))
			throw new IllegalArgumentException("Khả năng sửa chữa không hợp lệ khi giải quyết sự cố.");
		if (!RECOMMENDED_ACTIONS.contains(recommendedAction))
			throw new IllegalArgumentException("Hướng xử lý kỹ thuật không hợp lệ.");
		validateRequiredText(technicalNote, "Ghi chú kỹ thuật");
		validateRequiredText(handlingResult, "Kết quả xử lý");
	}

	private IncidentTarget resolveInternUsageTarget(Connection connection, long usageId, long internUserId)
			throws SQLException {
		String sql = """
				SELECT usage.asset_id, usage.asset_item_id, usage.quantity, usage.asset_usage_id
				FROM dbo.asset_usages usage WITH (UPDLOCK, HOLDLOCK)
				JOIN dbo.intern_profiles intern ON intern.intern_id = usage.student_id
				JOIN dbo.users reporter ON reporter.user_id = intern.user_id
				WHERE usage.asset_usage_id = ? AND intern.user_id = ?
				  AND usage.status IN ('IN_USE', 'RETURN_PENDING', 'RETURNED')
				  AND reporter.role = 'INTERN' AND reporter.status = 'ACTIVE'
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			statement.setLong(2, internUserId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException(
							"Lượt sử dụng không thuộc về bạn hoặc không còn đủ điều kiện báo sự cố.");
				return incidentTarget(result);
			}
		}
	}

	private IncidentTarget resolveMentorTarget(Connection connection, String value, long mentorId) throws SQLException {
		boolean usage = value.startsWith("usage:");
		boolean item = value.startsWith("item:");
		if (!usage && !item)
			throw new IllegalArgumentException("Vật dụng được chọn không hợp lệ.");
		long id;
		try {
			id = Long.parseLong(value.substring(value.indexOf(':') + 1));
		} catch (RuntimeException exception) {
			throw new IllegalArgumentException("Vật dụng được chọn không hợp lệ.");
		}
		String sql = usage ? """
				SELECT usage.asset_id, usage.asset_item_id, usage.quantity, usage.asset_usage_id
				FROM dbo.asset_usages usage WITH (UPDLOCK, HOLDLOCK)
				WHERE usage.asset_usage_id = ? AND usage.status IN ('IN_USE', 'RETURN_PENDING', 'RETURNED')
				  AND EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests request
					WHERE request.request_id = usage.request_id AND request.semester_id = usage.semester_id
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				  )
				""" : """
				SELECT item.asset_id, item.asset_item_id, 1 AS quantity, CAST(NULL AS bigint) AS asset_usage_id
				FROM dbo.asset_items item WITH (UPDLOCK, HOLDLOCK)
				JOIN dbo.assets asset ON asset.asset_id = item.asset_id
				WHERE item.asset_item_id = ? AND item.status <> 'DISPOSED' AND asset.status <> 'DISPOSED'
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.asset_usages usage
					WHERE usage.asset_item_id = item.asset_item_id
					  AND usage.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			if (usage)
				statement.setLong(2, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Vật dụng không còn đủ điều kiện để báo sự cố.");
				return incidentTarget(result);
			}
		}
	}

	private long insertIncident(Connection connection, IncidentTarget target, long reporterId, String incidentType,
			String severity, LocalDateTime occurredAt, String description, String status, String reportedCause,
			boolean forwarded) throws SQLException {
		String sql = """
				INSERT dbo.incidents
				(asset_id, asset_item_id, asset_usage_id, reported_by, affected_quantity, incident_type, description,
				 severity, status, occurred_at, reported_cause, forwarded_at)
				OUTPUT INSERTED.incident_id
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CASE WHEN ? = 1 THEN SYSUTCDATETIME() ELSE NULL END)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, target.assetId());
			setNullableLong(statement, 2, target.assetItemId());
			setNullableLong(statement, 3, target.usageId());
			statement.setLong(4, reporterId);
			statement.setInt(5, target.quantity());
			statement.setString(6, incidentType);
			statement.setString(7, description.trim());
			statement.setString(8, severity);
			statement.setString(9, status);
			if (occurredAt == null)
				statement.setNull(10, Types.TIMESTAMP);
			else
				statement.setTimestamp(10, ViewFormat.toUtc(occurredAt));
			statement.setString(11, reportedCause);
			statement.setBoolean(12, forwarded);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
		}
	}

	private boolean hasActiveIncident(Connection connection, IncidentTarget target) throws SQLException {
		String sql = """
				SELECT 1 FROM dbo.incidents WITH (UPDLOCK, HOLDLOCK)
				WHERE status IN ('REPORTED', 'FORWARDED', 'INVESTIGATING', 'OPEN')
				  AND (asset_usage_id = ? OR (? IS NOT NULL AND asset_item_id = ?))
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			setNullableLong(statement, 1, target.usageId());
			setNullableLong(statement, 2, target.assetItemId());
			setNullableLong(statement, 3, target.assetItemId());
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private IncidentTechnicalState lockTechnicalState(Connection connection, long incidentId, long managerId)
			throws SQLException {
		String sql = """
				SELECT status FROM dbo.incidents WITH (UPDLOCK, HOLDLOCK)
				WHERE incident_id = ? AND status IN ('FORWARDED', 'INVESTIGATING', 'RESOLVED')
				  AND EXISTS (
					SELECT 1 FROM dbo.users manager
					WHERE manager.user_id = ? AND manager.role = 'LAB_MANAGER' AND manager.status = 'ACTIVE'
				  )
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			statement.setLong(2, managerId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("Sự cố chưa được Mentor chuyển tiếp hoặc không còn có thể xử lý.");
				return new IncidentTechnicalState(result.getString("status"));
			}
		}
	}

	private void updateIncidentStatus(Connection connection, long incidentId, String currentStatus, String nextStatus)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				UPDATE dbo.incidents SET status = ?, updated_at = SYSUTCDATETIME()
				WHERE incident_id = ? AND status = ?
				""")) {
			statement.setString(1, nextStatus);
			statement.setLong(2, incidentId);
			statement.setString(3, currentStatus);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Sự cố đã được cập nhật bởi người dùng khác.");
		}
	}

	private void updateResolvedIncident(Connection connection, long incidentId, long managerId, String technicalCause,
			String technicalSeverity, String repairability, String recommendedAction, String technicalNote,
			String handlingResult) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				UPDATE dbo.incidents
				SET status = 'RESOLVED', technical_cause = ?, technical_severity = ?, repairability = ?,
				    recommended_action = ?, technical_note = ?, handling_result = ?, technical_assessed_by = ?,
				    technical_assessed_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
				WHERE incident_id = ? AND status = 'INVESTIGATING'
				""")) {
			statement.setString(1, technicalCause);
			statement.setString(2, technicalSeverity);
			statement.setString(3, repairability);
			statement.setString(4, recommendedAction);
			statement.setString(5, technicalNote.trim());
			statement.setString(6, handlingResult.trim());
			statement.setLong(7, managerId);
			statement.setLong(8, incidentId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Sự cố đã được cập nhật bởi người dùng khác.");
		}
	}

	private IncidentTarget incidentTarget(ResultSet result) throws SQLException {
		return new IncidentTarget(result.getLong("asset_id"), nullableLong(result, "asset_item_id"),
				nullableLong(result, "asset_usage_id"), result.getInt("quantity"));
	}

	private String normalizeReportedCause(String value) {
		if (value == null || value.isBlank())
			return "UNKNOWN";
		if (!Set.of("INTERN", "NATURAL", "UNKNOWN").contains(value))
			throw new IllegalArgumentException("Ghi nhận nguyên nhân không hợp lệ.");
		return value;
	}

	private static void validateRequiredText(String value, String fieldName) {
		if (value == null || value.isBlank() || value.trim().length() > 2000)
			throw new IllegalArgumentException(fieldName + " phải có từ 1 đến 2000 ký tự.");
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null)
			statement.setNull(index, Types.BIGINT);
		else
			statement.setLong(index, value);
	}

	private record IncidentTarget(long assetId, Long assetItemId, Long usageId, int quantity) {
	}

	private record IncidentTechnicalState(String status) {
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	public int countForReporter(long userId) throws SQLException {
		return count("""
				SELECT COUNT(*) FROM dbo.incidents
				WHERE reported_by = ?
				""", userId);
	}

	public int countForMentor(long mentorId) throws SQLException {
		return count("""
				SELECT COUNT(*)
				FROM dbo.incidents i
				LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
				LEFT JOIN dbo.lab_usage_requests r ON r.request_id = au.request_id AND r.semester_id = au.semester_id
				WHERE i.reported_by = ? OR r.mentor_id = ?
				""", mentorId, mentorId);
	}

	private int count(String sql, long... userIds) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 0; index < userIds.length; index++)
				statement.setLong(index + 1, userIds[index]);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private List<Incident> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<Incident> incidents = new ArrayList<>();
			while (result.next()) {
				Incident incident = new Incident();
				incident.setIncidentId(result.getLong("incident_id"));
				incident.setAssetId(result.getLong("asset_id"));
				incident.setAssetUsageId(nullableLong(result, "asset_usage_id"));
				incident.setAssetItemId(nullableLong(result, "asset_item_id"));
				incident.setInspectionItemId(nullableLong(result, "inspection_item_id"));
				incident.setReportedBy(result.getLong("reported_by"));
				incident.setAffectedQuantity(result.getInt("affected_quantity"));
				incident.setIncidentType(result.getString("incident_type"));
				incident.setDescription(result.getString("description"));
				incident.setSeverity(result.getString("severity"));
				incident.setStatus(result.getString("status"));
				incident.setOccurredAt(ViewFormat.fromUtc(result.getTimestamp("occurred_at")));
				incident.setReportedAt(ViewFormat.fromUtc(result.getTimestamp("reported_at")));
				incident.setInvestigationNote(result.getString("investigation_note"));
				incident.setHandlingResult(result.getString("handling_result"));
				incident.setReportedCause(result.getString("reported_cause"));
				incident.setDeterminedCause(result.getString("determined_cause"));
				incident.setReviewedBy(nullableLong(result, "reviewed_by"));
				incident.setReviewedAt(ViewFormat.fromUtc(result.getTimestamp("reviewed_at")));
				incident.setMentorReviewNote(result.getString("mentor_review_note"));
				incident.setForwardedAt(ViewFormat.fromUtc(result.getTimestamp("forwarded_at")));
				incident.setTechnicalCause(result.getString("technical_cause"));
				incident.setTechnicalSeverity(result.getString("technical_severity"));
				incident.setRepairability(result.getString("repairability"));
				incident.setRecommendedAction(result.getString("recommended_action"));
				incident.setTechnicalNote(result.getString("technical_note"));
				incident.setTechnicalAssessedBy(nullableLong(result, "technical_assessed_by"));
				incident.setTechnicalAssessedAt(ViewFormat.fromUtc(result.getTimestamp("technical_assessed_at")));
				incident.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				incident.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				incident.setAssetCode(result.getString("asset_code"));
				incident.setAssetName(result.getString("asset_name"));
				incident.setAssetItemCode(result.getString("asset_item_code"));
				incident.setReporterName(result.getString("reporter_name"));
				incident.setReporterRole(result.getString("reporter_role"));
				incident.setInternCode(result.getString("intern_code"));
				incident.setInternName(result.getString("intern_name"));
				incident.setReviewerName(result.getString("reviewer_name"));
				incident.setTechnicalAssessorName(result.getString("technical_assessor_name"));
				incidents.add(incident);
			}
			return incidents;
		}
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}
}
