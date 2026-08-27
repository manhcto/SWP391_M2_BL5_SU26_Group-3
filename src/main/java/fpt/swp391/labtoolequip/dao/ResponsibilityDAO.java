package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Responsibility;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public class ResponsibilityDAO {
	private static final Set<String> RESPONSIBILITY_LEVELS = Set.of("UNDETERMINED", "NONE", "PARTIAL", "FULL");
	private static final Set<String> ACCOUNTABLE_LEVELS = Set.of("PARTIAL", "FULL");
	private static final String TECHNICAL_FINDINGS = """
			i.technical_assessed_by IS NOT NULL
			AND i.technical_assessed_at IS NOT NULL
			AND i.technical_cause IS NOT NULL
			AND i.technical_severity IS NOT NULL
			AND i.repairability IS NOT NULL
			AND i.recommended_action IS NOT NULL
			AND NULLIF(LTRIM(RTRIM(i.technical_note)), '') IS NOT NULL
			AND EXISTS (SELECT 1 FROM dbo.users technical_manager
			           WHERE technical_manager.user_id = i.technical_assessed_by
			             AND technical_manager.role = 'LAB_MANAGER')
			""";
	private static final String SELECT = """
			SELECT r.*, i.asset_id, i.asset_usage_id, i.incident_type, i.description AS incident_description,
			       i.severity AS incident_severity, i.status AS incident_status, i.occurred_at, i.reported_at,
			       i.investigation_note, i.handling_result, i.determined_cause, i.technical_cause,
			       i.technical_severity, i.repairability, i.recommended_action, i.technical_note,
			       i.technical_assessed_by, i.technical_assessed_at,
			       sp.student_code AS intern_code, intern.full_name AS intern_name, intern.email AS intern_email,
			       mentor.full_name AS mentor_name, assessor.full_name AS responsibility_assessor_name,
			       technical_assessor.full_name AS technical_assessor_name, reviewer.full_name AS reviewer_name,
			       a.asset_code, a.asset_name, au.status AS usage_status,
			       au.borrowed_at, au.due_at, au.returned_at
			FROM dbo.responsibilities r
			JOIN dbo.incidents i ON i.incident_id = r.incident_id
			LEFT JOIN dbo.student_profiles sp ON sp.student_id = r.student_id
			LEFT JOIN dbo.users intern ON intern.user_id = sp.user_id
			LEFT JOIN dbo.users mentor ON mentor.user_id = r.determined_by
			LEFT JOIN dbo.users assessor ON assessor.user_id = r.responsibility_assessed_by
			LEFT JOIN dbo.users technical_assessor ON technical_assessor.user_id = i.technical_assessed_by
			LEFT JOIN dbo.users reviewer ON reviewer.user_id = r.reviewed_by
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
			""";
	private final DBConnection db = new DBConnection();

	public List<Responsibility> findAll(String keyword, String status) throws SQLException {
		String sql = SELECT + searchWhere("")
				+ " ORDER BY COALESCE(r.responsibility_assessed_at, r.determined_at) DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			bindSearch(statement, keyword, status, 1);
			return read(statement);
		}
	}

	public List<Responsibility> findForIntern(long userId, String keyword, String status) throws SQLException {
		String sql = SELECT + searchWhere("sp.user_id = ? AND ")
				+ " ORDER BY COALESCE(r.responsibility_assessed_at, r.determined_at) DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			bindSearch(statement, keyword, status, 2);
			return read(statement);
		}
	}

	public List<Responsibility> findForMentor(long mentorId, String keyword, String status) throws SQLException {
		String sql = SELECT + searchWhere(mentorScope() + " AND ")
				+ " ORDER BY COALESCE(r.responsibility_assessed_at, r.determined_at) DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			bindMentorScope(statement, 1, mentorId);
			bindSearch(statement, keyword, status, 3);
			return read(statement);
		}
	}

	public Optional<Responsibility> findById(long id) throws SQLException {
		return findOne(SELECT + " WHERE r.responsibility_id = ?", id);
	}

	public Optional<Responsibility> findByIdForIntern(long id, long userId) throws SQLException {
		return findOne(SELECT + " WHERE r.responsibility_id = ? AND sp.user_id = ?", id, userId);
	}

	public Optional<Responsibility> findByIdForMentor(long id, long mentorId) throws SQLException {
		return findOne(SELECT + " WHERE r.responsibility_id = ? AND " + mentorScope(), id, mentorId, mentorId);
	}

	public Optional<Responsibility> findByIdForMentorAssessment(long id, long mentorId) throws SQLException {
		String sql = SELECT + """
				WHERE r.responsibility_id = ?
				  AND (r.responsibility_assessed_by = ?
				       OR (r.responsibility_assessed_by IS NULL AND r.determined_by = ?))
				  AND %s
				  AND """ + mentorScope();
		return findOne(sql.formatted(TECHNICAL_FINDINGS), id, mentorId, mentorId, mentorId, mentorId);
	}

	public List<Responsibility> findEligibleIncidents(long mentorId) throws SQLException {
		String sql = """
				SELECT i.incident_id, i.reported_at, i.incident_type, i.severity AS incident_severity,
				       i.status AS incident_status, i.description AS incident_description, i.asset_id,
				       i.asset_usage_id, i.technical_cause, i.technical_severity, i.repairability,
				       i.recommended_action, i.technical_note, i.technical_assessed_by, i.technical_assessed_at,
				       a.asset_code, a.asset_name, au.student_id,
				       sp.student_code AS intern_code, u.full_name AS intern_name, u.email AS intern_email
				FROM dbo.incidents i
				LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
				LEFT JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
				LEFT JOIN dbo.users u ON u.user_id = sp.user_id
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				WHERE NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				  AND %s
				  AND %s
				ORDER BY i.reported_at DESC
				""".formatted(TECHNICAL_FINDINGS, mentorScope());
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			bindMentorScope(statement, 1, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				List<Responsibility> incidents = new ArrayList<>();
				while (result.next()) {
					Responsibility item = new Responsibility();
					item.setIncidentId(result.getLong("incident_id"));
					item.setReportedAt(ViewFormat.fromUtc(result.getTimestamp("reported_at")));
					item.setIncidentType(result.getString("incident_type"));
					item.setIncidentSeverity(result.getString("incident_severity"));
					item.setIncidentStatus(result.getString("incident_status"));
					item.setIncidentDescription(result.getString("incident_description"));
					item.setTechnicalCause(result.getString("technical_cause"));
					item.setTechnicalSeverity(result.getString("technical_severity"));
					item.setRepairability(result.getString("repairability"));
					item.setRecommendedAction(result.getString("recommended_action"));
					item.setTechnicalNote(result.getString("technical_note"));
					item.setTechnicalAssessedBy(nullableLong(result, "technical_assessed_by"));
					item.setTechnicalAssessedAt(ViewFormat.fromUtc(result.getTimestamp("technical_assessed_at")));
					item.setAssetId(result.getLong("asset_id"));
					item.setAssetUsageId(nullableLong(result, "asset_usage_id"));
					item.setAssetCode(result.getString("asset_code"));
					item.setAssetName(result.getString("asset_name"));
					item.setInternId(nullableLong(result, "student_id"));
					item.setInternCode(result.getString("intern_code"));
					item.setInternName(result.getString("intern_name"));
					item.setInternEmail(result.getString("intern_email"));
					incidents.add(item);
				}
				return incidents;
			}
		}
	}

	public List<Responsibility> findSupervisedInterns(long mentorId) throws SQLException {
		String sql = """
				SELECT DISTINCT sp.student_id, sp.student_code AS intern_code, u.full_name AS intern_name,
				       u.email AS intern_email
				FROM dbo.lab_usage_requests request
				JOIN dbo.lab_usage_request_students membership
				  ON membership.request_id = request.request_id
				 AND membership.semester_id = request.semester_id
				JOIN dbo.student_profiles sp ON sp.student_id = membership.student_id
				JOIN dbo.users u ON u.user_id = sp.user_id
				WHERE request.mentor_id = ? AND request.status = 'APPROVED'
				  AND sp.status = 'ACTIVE' AND u.role = 'INTERN' AND u.status = 'ACTIVE'
				ORDER BY u.full_name, sp.student_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				List<Responsibility> interns = new ArrayList<>();
				while (result.next()) {
					Responsibility intern = new Responsibility();
					intern.setInternId(result.getLong("student_id"));
					intern.setInternCode(result.getString("intern_code"));
					intern.setInternName(result.getString("intern_name"));
					intern.setInternEmail(result.getString("intern_email"));
					interns.add(intern);
				}
				return interns;
			}
		}
	}

	public List<Responsibility> findActiveInterns() throws SQLException {
		String sql = """
				SELECT sp.student_id, sp.student_code AS intern_code, u.full_name AS intern_name,
				       u.email AS intern_email
				FROM dbo.student_profiles sp
				JOIN dbo.users u ON u.user_id = sp.user_id
				WHERE sp.status = 'ACTIVE' AND u.role = 'INTERN' AND u.status = 'ACTIVE'
				ORDER BY u.full_name, sp.student_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			try (ResultSet result = statement.executeQuery()) {
				List<Responsibility> interns = new ArrayList<>();
				while (result.next()) {
					Responsibility intern = new Responsibility();
					intern.setInternId(result.getLong("student_id"));
					intern.setInternCode(result.getString("intern_code"));
					intern.setInternName(result.getString("intern_name"));
					intern.setInternEmail(result.getString("intern_email"));
					interns.add(intern);
				}
				return interns;
			}
		}
	}

	public List<Responsibility> findUnassignedIncidents() throws SQLException {
		String sql = """
				SELECT i.incident_id, i.reported_at, i.incident_type, i.description AS incident_description,
				       i.severity AS incident_severity, i.status AS incident_status,
				       a.asset_id, a.asset_code, a.asset_name
				FROM dbo.incidents i
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				WHERE NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				ORDER BY i.reported_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Responsibility> incidents = new ArrayList<>();
			while (result.next()) {
				Responsibility incident = new Responsibility();
				incident.setIncidentId(result.getLong("incident_id"));
				incident.setReportedAt(ViewFormat.fromUtc(result.getTimestamp("reported_at")));
				incident.setIncidentType(result.getString("incident_type"));
				incident.setIncidentDescription(result.getString("incident_description"));
				incident.setIncidentSeverity(result.getString("incident_severity"));
				incident.setIncidentStatus(result.getString("incident_status"));
				incident.setAssetId(result.getLong("asset_id"));
				incident.setAssetCode(result.getString("asset_code"));
				incident.setAssetName(result.getString("asset_name"));
				incidents.add(incident);
			}
			return incidents;
		}
	}

	public long createByLabManager(long managerUserId, long incidentId, String responsibilityLevel,
			Long relatedStudentId, String evidenceSummary, String responsibilityNote, String handlingRecommendation)
			throws SQLException {
		String level = normalizeLevel(responsibilityLevel);
		String evidence = blankToNull(evidenceSummary);
		String note = blankToNull(responsibilityNote);
		String recommendation = blankToNull(handlingRecommendation);
		validateLabManagerAssignment(level, relatedStudentId, evidence, note);
		String sql = """
				INSERT dbo.responsibilities
				    (incident_id, student_id, determined_by, conclusion, decision, status, responsibility_level,
				     evidence_summary, responsibility_note, handling_recommendation, responsibility_assessed_by,
				     responsibility_assessed_at)
				OUTPUT INSERTED.responsibility_id
				SELECT i.incident_id, ?, ?, ?, ?, 'CONFIRMED', ?, ?, ?, ?, ?, SYSUTCDATETIME()
				FROM dbo.incidents i
				WHERE i.incident_id = ?
				  AND NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				  AND EXISTS (SELECT 1 FROM dbo.users manager
				              WHERE manager.user_id = ? AND manager.role = 'LAB_MANAGER' AND manager.status = 'ACTIVE')
				  AND (? IS NULL OR EXISTS (
				      SELECT 1 FROM dbo.student_profiles selected_student
				      JOIN dbo.users intern_account ON intern_account.user_id = selected_student.user_id
				      WHERE selected_student.student_id = ? AND selected_student.status = 'ACTIVE'
				        AND intern_account.role = 'INTERN' AND intern_account.status = 'ACTIVE'))
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			int index = 1;
			setNullableLong(statement, index++, relatedStudentId);
			statement.setLong(index++, managerUserId);
			statement.setString(index++, legacyConclusion(level, evidence, note));
			statement.setString(index++, recommendation);
			statement.setString(index++, level);
			statement.setString(index++, evidence);
			statement.setString(index++, note);
			statement.setString(index++, recommendation);
			statement.setLong(index++, managerUserId);
			statement.setLong(index++, incidentId);
			statement.setLong(index++, managerUserId);
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index, relatedStudentId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("Sự cố đã có hồ sơ, hoặc dữ liệu Lab Manager/Intern không hợp lệ.");
				return result.getLong(1);
			}
		}
	}

	public long createAssessment(long mentorUserId, long incidentId, String responsibilityLevel, Long relatedStudentId,
			String evidenceSummary, String responsibilityNote, String handlingRecommendation) throws SQLException {
		String level = normalizeLevel(responsibilityLevel);
		String evidence = blankToNull(evidenceSummary);
		String note = blankToNull(responsibilityNote);
		String recommendation = blankToNull(handlingRecommendation);
		validateAssessment(level, relatedStudentId, evidence, note);
		String sql = """
				INSERT dbo.responsibilities
				    (incident_id, student_id, determined_by, conclusion, decision, status, responsibility_level,
				     evidence_summary, responsibility_note, handling_recommendation, responsibility_assessed_by,
				     responsibility_assessed_at)
				OUTPUT INSERTED.responsibility_id
				SELECT i.incident_id, ?,
				       ?, ?, ?, 'CONFIRMED', ?, ?, ?, ?, ?, SYSUTCDATETIME()
				FROM dbo.incidents i
				LEFT JOIN dbo.asset_usages related_usage ON related_usage.asset_usage_id = i.asset_usage_id
				WHERE i.incident_id = ?
				  AND %s
				  AND %s
				  AND (? IS NULL OR ((related_usage.student_id = ?
				       OR EXISTS (SELECT 1 FROM dbo.student_profiles reported_student
				                  WHERE reported_student.student_id = ? AND reported_student.user_id = i.reported_by))
				       AND %s))
				  AND NOT EXISTS (SELECT 1 FROM dbo.responsibilities r WHERE r.incident_id = i.incident_id)
				  AND EXISTS (SELECT 1 FROM dbo.users account
				              WHERE account.user_id = ? AND account.role = 'MENTOR' AND account.status = 'ACTIVE')
				""".formatted(TECHNICAL_FINDINGS, mentorScope(), mentorStudentScope());
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			int index = 1;
			setNullableLong(statement, index++, relatedStudentId);
			statement.setLong(index++, mentorUserId);
			statement.setString(index++, legacyConclusion(level, evidence, note));
			statement.setString(index++, recommendation);
			statement.setString(index++, level);
			statement.setString(index++, evidence);
			statement.setString(index++, note);
			statement.setString(index++, recommendation);
			statement.setLong(index++, mentorUserId);
			statement.setLong(index++, incidentId);
			bindMentorScope(statement, index, mentorUserId);
			index += 2;
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index++, relatedStudentId);
			bindMentorStudentScope(statement, index, mentorUserId, relatedStudentId);
			index += 2;
			statement.setLong(index, mentorUserId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException(
							"Sự cố phải có kết luận kỹ thuật, thuộc phạm vi Mentor và chưa có hồ sơ trách nhiệm.");
				return result.getLong(1);
			}
		}
	}

	public void updateAssessment(long mentorUserId, long id, String responsibilityLevel, Long relatedStudentId,
			String evidenceSummary, String responsibilityNote, String handlingRecommendation) throws SQLException {
		String level = normalizeLevel(responsibilityLevel);
		String evidence = blankToNull(evidenceSummary);
		String note = blankToNull(responsibilityNote);
		String recommendation = blankToNull(handlingRecommendation);
		validateAssessment(level, relatedStudentId, evidence, note);
		String sql = """
				UPDATE r
				SET student_id = ?,
				    responsibility_level = ?, evidence_summary = ?, responsibility_note = ?,
				    handling_recommendation = ?, responsibility_assessed_by = ?,
				    responsibility_assessed_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
				FROM dbo.responsibilities r
				JOIN dbo.incidents i ON i.incident_id = r.incident_id
				LEFT JOIN dbo.asset_usages related_usage ON related_usage.asset_usage_id = i.asset_usage_id
				WHERE r.responsibility_id = ?
				  AND (r.responsibility_assessed_by = ?
				       OR (r.responsibility_assessed_by IS NULL AND r.determined_by = ?))
				  AND %s
				  AND %s
				  AND (? IS NULL OR ((related_usage.student_id = ?
				       OR EXISTS (SELECT 1 FROM dbo.student_profiles reported_student
				                  WHERE reported_student.student_id = ? AND reported_student.user_id = i.reported_by))
				       AND %s))
				  AND EXISTS (SELECT 1 FROM dbo.users account
				              WHERE account.user_id = ? AND account.role = 'MENTOR' AND account.status = 'ACTIVE')
				""".formatted(TECHNICAL_FINDINGS, mentorScope(), mentorStudentScope());
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			int index = 1;
			setNullableLong(statement, index++, relatedStudentId);
			statement.setString(index++, level);
			statement.setString(index++, evidence);
			statement.setString(index++, note);
			statement.setString(index++, recommendation);
			statement.setLong(index++, mentorUserId);
			statement.setLong(index++, id);
			statement.setLong(index++, mentorUserId);
			statement.setLong(index++, mentorUserId);
			bindMentorScope(statement, index, mentorUserId);
			index += 2;
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index++, relatedStudentId);
			bindMentorStudentScope(statement, index, mentorUserId, relatedStudentId);
			index += 2;
			statement.setLong(index, mentorUserId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException(
						"Không tìm thấy hồ sơ phù hợp, hoặc sự cố chưa có kết luận kỹ thuật đầy đủ.");
		}
	}

	public void assignByLabManager(long managerUserId, long id, String responsibilityLevel, Long relatedStudentId,
			String evidenceSummary, String responsibilityNote, String handlingRecommendation) throws SQLException {
		String level = normalizeLevel(responsibilityLevel);
		String evidence = blankToNull(evidenceSummary);
		String note = blankToNull(responsibilityNote);
		String recommendation = blankToNull(handlingRecommendation);
		validateLabManagerAssignment(level, relatedStudentId, evidence, note);
		String sql = """
				UPDATE r
				SET student_id = ?, responsibility_level = ?, evidence_summary = ?, responsibility_note = ?,
				    handling_recommendation = ?, responsibility_assessed_by = ?,
				    responsibility_assessed_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
				FROM dbo.responsibilities r
				WHERE r.responsibility_id = ?
				  AND EXISTS (SELECT 1 FROM dbo.users manager
				              WHERE manager.user_id = ? AND manager.role = 'LAB_MANAGER' AND manager.status = 'ACTIVE')
				  AND (? IS NULL OR EXISTS (
				      SELECT 1
				      FROM dbo.student_profiles selected_student
				      JOIN dbo.users intern_account ON intern_account.user_id = selected_student.user_id
				      WHERE selected_student.student_id = ?
				        AND selected_student.status = 'ACTIVE'
				        AND intern_account.role = 'INTERN' AND intern_account.status = 'ACTIVE'))
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			int index = 1;
			setNullableLong(statement, index++, relatedStudentId);
			statement.setString(index++, level);
			statement.setString(index++, evidence);
			statement.setString(index++, note);
			statement.setString(index++, recommendation);
			statement.setLong(index++, managerUserId);
			statement.setLong(index++, id);
			statement.setLong(index++, managerUserId);
			setNullableLong(statement, index++, relatedStudentId);
			setNullableLong(statement, index, relatedStudentId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Không tìm thấy hồ sơ hoặc dữ liệu Lab Manager/Intern không hợp lệ.");
		}
	}

	static void validateAssessment(String responsibilityLevel, Long relatedStudentId, String evidenceSummary,
			String responsibilityNote) {
		if (!RESPONSIBILITY_LEVELS.contains(responsibilityLevel))
			throw new IllegalArgumentException("Mức trách nhiệm không hợp lệ.");
		if (!ACCOUNTABLE_LEVELS.contains(responsibilityLevel))
			return;
		if (relatedStudentId == null || relatedStudentId <= 0)
			throw new IllegalArgumentException("PARTIAL hoặc FULL phải có thực tập sinh liên quan.");
		if (evidenceSummary == null || evidenceSummary.isBlank())
			throw new IllegalArgumentException("PARTIAL hoặc FULL phải có tóm tắt bằng chứng.");
		if (responsibilityNote == null || responsibilityNote.isBlank())
			throw new IllegalArgumentException("PARTIAL hoặc FULL phải có lý do đánh giá.");
	}

	static void validateLabManagerAssignment(String responsibilityLevel, Long relatedStudentId, String evidenceSummary,
			String responsibilityNote) {
		if (relatedStudentId == null || relatedStudentId <= 0)
			throw new IllegalArgumentException("Lab Manager phải chọn Intern để gán trách nhiệm.");
		validateAssessment(responsibilityLevel, relatedStudentId, evidenceSummary, responsibilityNote);
	}

	private String searchWhere(String prefix) {
		return """
				 WHERE %s(? = '' OR CAST(r.responsibility_id AS varchar(30)) LIKE ?
				    OR CAST(r.incident_id AS varchar(30)) LIKE ? OR intern.full_name LIKE ?
				    OR sp.student_code LIKE ? OR a.asset_code LIKE ? OR a.asset_name LIKE ?
				    OR r.responsibility_level LIKE ? OR r.evidence_summary LIKE ? OR r.responsibility_note LIKE ?
				    OR r.handling_recommendation LIKE ? OR r.conclusion LIKE ? OR r.decision LIKE ?)
				 AND (? = '' OR r.status = ?)
				""".formatted(prefix);
	}

	private void bindSearch(PreparedStatement statement, String keyword, String status, int start) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String pattern = "%" + search + "%";
		String state = status == null ? "" : status.trim();
		int index = start;
		statement.setString(index++, search);
		for (int count = 0; count < 12; count++)
			statement.setString(index++, pattern);
		statement.setString(index++, state);
		statement.setString(index, state);
	}

	private String mentorScope() {
		return """
				(i.reported_by = ? OR EXISTS (
					SELECT 1
					FROM dbo.asset_usages scope_usage
					JOIN dbo.lab_usage_requests request
					  ON request.request_id = scope_usage.request_id
					 AND request.semester_id = scope_usage.semester_id
					WHERE scope_usage.asset_usage_id = i.asset_usage_id
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				))
				""";
	}

	private void bindMentorScope(PreparedStatement statement, int start, long mentorId) throws SQLException {
		statement.setLong(start, mentorId);
		statement.setLong(start + 1, mentorId);
	}

	private String mentorStudentScope() {
		return """
				EXISTS (
					SELECT 1
					FROM dbo.lab_usage_requests request
					JOIN dbo.lab_usage_request_students membership
					  ON membership.request_id = request.request_id
					 AND membership.semester_id = request.semester_id
					JOIN dbo.student_profiles student ON student.student_id = membership.student_id
					JOIN dbo.users intern_account ON intern_account.user_id = student.user_id
					WHERE request.mentor_id = ? AND request.status = 'APPROVED'
					  AND membership.student_id = ?
					  AND student.status = 'ACTIVE' AND intern_account.role = 'INTERN' AND intern_account.status = 'ACTIVE'
				)
				""";
	}

	private void bindMentorStudentScope(PreparedStatement statement, int start, long mentorId, Long studentId)
			throws SQLException {
		statement.setLong(start, mentorId);
		setNullableLong(statement, start + 1, studentId);
	}

	private Optional<Responsibility> findOne(String sql, long... values) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 0; index < values.length; index++)
				statement.setLong(index + 1, values[index]);
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
				record.setInternId(nullableLong(result, "student_id"));
				record.setResponsibilityLevel(result.getString("responsibility_level"));
				record.setEvidenceSummary(result.getString("evidence_summary"));
				record.setResponsibilityNote(result.getString("responsibility_note"));
				record.setHandlingRecommendation(result.getString("handling_recommendation"));
				record.setResponsibilityAssessedBy(nullableLong(result, "responsibility_assessed_by"));
				record.setResponsibilityAssessedAt(
						ViewFormat.fromUtc(result.getTimestamp("responsibility_assessed_at")));
				record.setDeterminedBy(nullableLong(result, "determined_by"));
				record.setConclusion(result.getString("conclusion"));
				record.setDecision(result.getString("decision"));
				record.setStatus(result.getString("status"));
				record.setReviewedBy(nullableLong(result, "reviewed_by"));
				record.setReviewedAt(ViewFormat.fromUtc(result.getTimestamp("reviewed_at")));
				record.setReviewNote(result.getString("review_note"));
				record.setResolutionNote(result.getString("resolution_note"));
				record.setDeterminedAt(ViewFormat.fromUtc(result.getTimestamp("determined_at")));
				record.setResolvedAt(ViewFormat.fromUtc(result.getTimestamp("resolved_at")));
				record.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				record.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				record.setInternCode(result.getString("intern_code"));
				record.setInternName(result.getString("intern_name"));
				record.setInternEmail(result.getString("intern_email"));
				record.setMentorName(result.getString("mentor_name"));
				record.setResponsibilityAssessorName(result.getString("responsibility_assessor_name"));
				record.setReviewerName(result.getString("reviewer_name"));
				record.setIncidentType(result.getString("incident_type"));
				record.setIncidentDescription(result.getString("incident_description"));
				record.setIncidentSeverity(result.getString("incident_severity"));
				record.setIncidentStatus(result.getString("incident_status"));
				record.setInvestigationNote(result.getString("investigation_note"));
				record.setHandlingResult(result.getString("handling_result"));
				record.setDeterminedCause(result.getString("determined_cause"));
				record.setTechnicalCause(result.getString("technical_cause"));
				record.setTechnicalSeverity(result.getString("technical_severity"));
				record.setRepairability(result.getString("repairability"));
				record.setRecommendedAction(result.getString("recommended_action"));
				record.setTechnicalNote(result.getString("technical_note"));
				record.setTechnicalAssessedBy(nullableLong(result, "technical_assessed_by"));
				record.setTechnicalAssessedAt(ViewFormat.fromUtc(result.getTimestamp("technical_assessed_at")));
				record.setTechnicalAssessorName(result.getString("technical_assessor_name"));
				record.setOccurredAt(ViewFormat.fromUtc(result.getTimestamp("occurred_at")));
				record.setReportedAt(ViewFormat.fromUtc(result.getTimestamp("reported_at")));
				record.setAssetId(result.getLong("asset_id"));
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setAssetUsageId(nullableLong(result, "asset_usage_id"));
				record.setUsageStatus(result.getString("usage_status"));
				record.setBorrowedAt(ViewFormat.fromUtc(result.getTimestamp("borrowed_at")));
				record.setDueAt(ViewFormat.fromUtc(result.getTimestamp("due_at")));
				record.setReturnedAt(ViewFormat.fromUtc(result.getTimestamp("returned_at")));
				records.add(record);
			}
			return records;
		}
	}

	private String normalizeLevel(String value) {
		return value == null ? "" : value.trim();
	}

	private String legacyConclusion(String level, String evidence, String note) {
		if (note != null)
			return note;
		if (evidence != null)
			return evidence;
		return "Đánh giá trách nhiệm: " + level + ".";
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null)
			statement.setNull(index, Types.BIGINT);
		else
			statement.setLong(index, value);
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
