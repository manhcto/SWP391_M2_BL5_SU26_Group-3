package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Responsibility;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import util.AppConfig;

public class ResponsibilityDAO {
	private static final Set<String> MENTOR_STATUSES = Set.of("CONFIRMED", "PENDING_REVIEW", "RESOLVED");
	private static final String SELECT = """
			SELECT r.*, i.asset_id, i.asset_usage_id, i.incident_type, i.description AS incident_description,
			       i.severity AS incident_severity, i.status AS incident_status, i.occurred_at, i.reported_at,
			       i.investigation_note, i.handling_result, sp.student_code AS intern_code,
			       intern.full_name AS intern_name, intern.email AS intern_email, mentor.full_name AS mentor_name,
			       reviewer.full_name AS reviewer_name, a.asset_code, a.asset_name, au.status AS usage_status,
			       au.borrowed_at, au.due_at, au.returned_at
			FROM dbo.responsibilities r
			JOIN dbo.incidents i ON i.incident_id = r.incident_id
			JOIN dbo.student_profiles sp ON sp.student_id = r.student_id
			JOIN dbo.users intern ON intern.user_id = sp.user_id
			JOIN dbo.users mentor ON mentor.user_id = r.determined_by
			LEFT JOIN dbo.users reviewer ON reviewer.user_id = r.reviewed_by
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
			""";
	private final DBConnection db = new DBConnection();
	private final ZoneId labZone = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));

	public List<Responsibility> findAll(String keyword, String status) throws SQLException {
		String sql = SELECT + searchWhere("") + " ORDER BY r.determined_at DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			bindSearch(statement, keyword, status, 1);
			return read(statement);
		}
	}

	public List<Responsibility> findForIntern(long userId, String keyword, String status) throws SQLException {
		String sql = SELECT + searchWhere("sp.user_id = ? AND ") + " ORDER BY r.determined_at DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			bindSearch(statement, keyword, status, 2);
			return read(statement);
		}
	}

	public Optional<Responsibility> findById(long id) throws SQLException {
		return findOne(SELECT + " WHERE r.responsibility_id = ?", id, null);
	}

	public Optional<Responsibility> findByIdForIntern(long id, long userId) throws SQLException {
		return findOne(SELECT + " WHERE r.responsibility_id = ? AND sp.user_id = ?", id, userId);
	}

	public List<Responsibility> findEligibleIncidents() throws SQLException {
		String sql = """
				SELECT i.incident_id, i.reported_at, i.incident_type, i.severity AS incident_severity,
				       i.status AS incident_status, i.description AS incident_description, i.asset_id,
				       i.asset_usage_id, a.asset_code, a.asset_name, au.student_id,
				       sp.student_code AS intern_code, u.full_name AS intern_name, u.email AS intern_email
				FROM dbo.incidents i
				JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
				JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
				JOIN dbo.users u ON u.user_id = sp.user_id
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				WHERE NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				ORDER BY i.reported_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Responsibility> incidents = new ArrayList<>();
			while (result.next()) {
				Responsibility item = new Responsibility();
				item.setIncidentId(result.getLong("incident_id"));
				item.setReportedAt(local(result.getTimestamp("reported_at")));
				item.setIncidentType(result.getString("incident_type"));
				item.setIncidentSeverity(result.getString("incident_severity"));
				item.setIncidentStatus(result.getString("incident_status"));
				item.setIncidentDescription(result.getString("incident_description"));
				item.setAssetId(result.getLong("asset_id"));
				item.setAssetUsageId(result.getLong("asset_usage_id"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setInternId(result.getLong("student_id"));
				item.setInternCode(result.getString("intern_code"));
				item.setInternName(result.getString("intern_name"));
				item.setInternEmail(result.getString("intern_email"));
				incidents.add(item);
			}
			return incidents;
		}
	}

	public long create(long mentorUserId, long incidentId, String conclusion, String decision, String status,
			String resolutionNote) throws SQLException {
		validate(conclusion, status);
		String sql = """
				INSERT dbo.responsibilities
				    (incident_id, student_id, determined_by, conclusion, decision, status, resolution_note, resolved_at)
				OUTPUT INSERTED.responsibility_id
				SELECT i.incident_id, au.student_id, ?, ?, ?, ?, ?,
				       CASE WHEN ? = 'RESOLVED' THEN SYSUTCDATETIME() ELSE NULL END
				FROM dbo.incidents i
				JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
				WHERE i.incident_id = ?
				  AND NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorUserId);
			statement.setString(2, conclusion.trim());
			statement.setString(3, blankToNull(decision));
			statement.setString(4, status);
			statement.setString(5, blankToNull(resolutionNote));
			statement.setString(6, status);
			statement.setLong(7, incidentId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException(
							"Incident must have a related asset usage and no responsibility yet.");
				return result.getLong(1);
			}
		}
	}

	public void update(long mentorUserId, long id, String conclusion, String decision, String status,
			String resolutionNote) throws SQLException {
		validate(conclusion, status);
		String sql = """
				UPDATE dbo.responsibilities
				SET conclusion = ?, decision = ?, status = ?, resolution_note = ?,
				    resolved_at = CASE WHEN ? = 'RESOLVED' THEN COALESCE(resolved_at, SYSUTCDATETIME()) ELSE NULL END,
				    updated_at = SYSUTCDATETIME()
				WHERE responsibility_id = ? AND determined_by = ?
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, conclusion.trim());
			statement.setString(2, blankToNull(decision));
			statement.setString(3, status);
			statement.setString(4, blankToNull(resolutionNote));
			statement.setString(5, status);
			statement.setLong(6, id);
			statement.setLong(7, mentorUserId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Responsibility not found or cannot be edited by this Mentor.");
		}
	}

	public void delete(long mentorUserId, long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"DELETE FROM dbo.responsibilities WHERE responsibility_id = ? AND determined_by = ?")) {
			statement.setLong(1, id);
			statement.setLong(2, mentorUserId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Responsibility not found or cannot be deleted by this Mentor.");
		}
	}

	private String searchWhere(String prefix) {
		return """
				 WHERE %s(? = '' OR CAST(r.responsibility_id AS varchar(30)) LIKE ?
				    OR CAST(r.incident_id AS varchar(30)) LIKE ? OR intern.full_name LIKE ?
				    OR sp.student_code LIKE ? OR a.asset_code LIKE ? OR a.asset_name LIKE ?
				    OR r.conclusion LIKE ? OR r.decision LIKE ?)
				 AND (? = '' OR r.status = ?)
				""".formatted(prefix);
	}

	private void bindSearch(PreparedStatement statement, String keyword, String status, int start) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String pattern = "%" + search + "%";
		String state = status == null ? "" : status.trim();
		int index = start;
		statement.setString(index++, search);
		for (int count = 0; count < 8; count++)
			statement.setString(index++, pattern);
		statement.setString(index++, state);
		statement.setString(index, state);
	}

	private Optional<Responsibility> findOne(String sql, long id, Long userId) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			if (userId != null)
				statement.setLong(2, userId);
			return read(statement).stream().findFirst();
		}
	}

	private List<Responsibility> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<Responsibility> records = new ArrayList<>();
			while (result.next()) {
				Responsibility record = new Responsibility();
				record.setResponsibilityId(result.getLong("responsibility_id"));
				record.setIncidentId(result.getLong("incident_id"));
				record.setInternId(result.getLong("student_id"));
				record.setDeterminedBy(result.getLong("determined_by"));
				record.setConclusion(result.getString("conclusion"));
				record.setDecision(result.getString("decision"));
				record.setStatus(result.getString("status"));
				record.setReviewedBy(nullableLong(result, "reviewed_by"));
				record.setReviewedAt(local(result.getTimestamp("reviewed_at")));
				record.setReviewNote(result.getString("review_note"));
				record.setResolutionNote(result.getString("resolution_note"));
				record.setDeterminedAt(local(result.getTimestamp("determined_at")));
				record.setResolvedAt(local(result.getTimestamp("resolved_at")));
				record.setCreatedAt(local(result.getTimestamp("created_at")));
				record.setUpdatedAt(local(result.getTimestamp("updated_at")));
				record.setInternCode(result.getString("intern_code"));
				record.setInternName(result.getString("intern_name"));
				record.setInternEmail(result.getString("intern_email"));
				record.setMentorName(result.getString("mentor_name"));
				record.setReviewerName(result.getString("reviewer_name"));
				record.setIncidentType(result.getString("incident_type"));
				record.setIncidentDescription(result.getString("incident_description"));
				record.setIncidentSeverity(result.getString("incident_severity"));
				record.setIncidentStatus(result.getString("incident_status"));
				record.setInvestigationNote(result.getString("investigation_note"));
				record.setHandlingResult(result.getString("handling_result"));
				record.setOccurredAt(local(result.getTimestamp("occurred_at")));
				record.setReportedAt(local(result.getTimestamp("reported_at")));
				record.setAssetId(result.getLong("asset_id"));
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setAssetUsageId(nullableLong(result, "asset_usage_id"));
				record.setUsageStatus(result.getString("usage_status"));
				record.setBorrowedAt(local(result.getTimestamp("borrowed_at")));
				record.setDueAt(local(result.getTimestamp("due_at")));
				record.setReturnedAt(local(result.getTimestamp("returned_at")));
				records.add(record);
			}
			return records;
		}
	}

	private void validate(String conclusion, String status) {
		if (conclusion == null || conclusion.isBlank())
			throw new IllegalArgumentException("Mentor finding is required.");
		if (!MENTOR_STATUSES.contains(status))
			throw new IllegalArgumentException("Invalid responsibility status.");
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private LocalDateTime local(Timestamp value) {
		return value == null
				? null
				: value.toLocalDateTime().atZone(ZoneOffset.UTC).withZoneSameInstant(labZone).toLocalDateTime();
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
