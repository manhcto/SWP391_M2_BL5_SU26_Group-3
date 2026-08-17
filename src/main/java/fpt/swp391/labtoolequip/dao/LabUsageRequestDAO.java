package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import fpt.swp391.labtoolequip.model.LabUsageRequestStudent;
import fpt.swp391.labtoolequip.model.Semester;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

public class LabUsageRequestDAO {
	private static final String SELECT_REQUEST = """
			SELECT r.request_id, r.semester_id, r.mentor_id, r.group_name, r.status,
			       r.request_note, r.approved_by, r.approved_at, r.approval_note,
			       r.created_at, r.updated_at, se.code AS semester_code, se.name AS semester_name,
			       mentor.full_name AS mentor_name, mentor.email AS mentor_email,
			       (SELECT COUNT(*) FROM dbo.lab_usage_request_student_entries e
			        WHERE e.request_id = r.request_id) AS student_count
			FROM dbo.lab_usage_requests r
			JOIN dbo.semesters se ON se.semester_id = r.semester_id
			JOIN dbo.users mentor ON mentor.user_id = r.mentor_id
			""";

	private final DBConnection dbConnection = new DBConnection();

	public List<LabUsageRequest> findByMentor(long mentorId, String keyword, String status, Long semesterId)
			throws SQLException {
		String sql = SELECT_REQUEST + """
				WHERE r.mentor_id = ?
				  AND (? = '' OR r.group_name LIKE ? OR se.code LIKE ? OR se.name LIKE ?)
				  AND (? = '' OR r.status = ?)
				  AND (? IS NULL OR r.semester_id = ?)
				ORDER BY r.created_at DESC, r.request_id DESC
				""";
		String search = valueOrEmpty(keyword);
		String statusFilter = valueOrEmpty(status).toUpperCase();
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			statement.setString(2, search);
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, "%" + search + "%");
			statement.setString(6, statusFilter);
			statement.setString(7, statusFilter);
			setNullableLong(statement, 8, semesterId);
			setNullableLong(statement, 9, semesterId);
			return readRequests(statement);
		}
	}

	public List<LabUsageRequest> findAll(String keyword, String status, Long semesterId) throws SQLException {
		String sql = SELECT_REQUEST + """
				WHERE (? = '' OR r.group_name LIKE ? OR se.code LIKE ? OR se.name LIKE ?
				       OR mentor.full_name LIKE ? OR mentor.email LIKE ?)
				  AND (? = '' OR r.status = ?)
				  AND (? IS NULL OR r.semester_id = ?)
				ORDER BY CASE WHEN r.status = 'PENDING' THEN 0 ELSE 1 END,
				         r.created_at DESC, r.request_id DESC
				""";
		String search = valueOrEmpty(keyword);
		String statusFilter = valueOrEmpty(status).toUpperCase();
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			for (int index = 2; index <= 6; index++) {
				statement.setString(index, "%" + search + "%");
			}
			statement.setString(7, statusFilter);
			statement.setString(8, statusFilter);
			setNullableLong(statement, 9, semesterId);
			setNullableLong(statement, 10, semesterId);
			return readRequests(statement);
		}
	}

	public Optional<LabUsageRequest> findById(long requestId) throws SQLException {
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT_REQUEST + "WHERE r.request_id = ?")) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					return Optional.empty();
				}
				LabUsageRequest request = mapRequest(result);
				request.setStudents(findStudents(connection, requestId));
				return Optional.of(request);
			}
		}
	}

	public int countByStatus(String status) throws SQLException {
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"SELECT COUNT(*) FROM dbo.lab_usage_requests WHERE status = ?")) {
			statement.setString(1, status);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	public List<LabUsageRequest> findApprovedSchedule() throws SQLException {
		return findApproved(null);
	}

	public List<LabUsageRequest> findApprovedSchedule(long mentorId) throws SQLException {
		return findApproved(mentorId);
	}

	private List<LabUsageRequest> findApproved(Long mentorId) throws SQLException {
		String sql = SELECT_REQUEST + "WHERE r.status = 'APPROVED' AND se.status = 'ACTIVE'"
				+ (mentorId == null ? "" : " AND r.mentor_id = ?") + " ORDER BY r.request_id";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			if (mentorId != null) {
				statement.setLong(1, mentorId);
			}
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequest> requests = new ArrayList<>();
				while (result.next()) {
					LabUsageRequest request = mapRequest(result);
					request.setStudents(findStudents(connection, request.getRequestId()));
					requests.add(request);
				}
				return requests;
			}
		}
	}

	public Optional<LabUsageRequest> findByIdForMentor(long requestId, long mentorId) throws SQLException {
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						SELECT_REQUEST + "WHERE r.request_id = ? AND r.mentor_id = ?")) {
			statement.setLong(1, requestId);
			statement.setLong(2, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					return Optional.empty();
				}
				LabUsageRequest request = mapRequest(result);
				request.setStudents(findStudents(connection, requestId));
				return Optional.of(request);
			}
		}
	}

	public List<Semester> findOpenSemesters() throws SQLException {
		String sql = """
				SELECT semester_id, code, name, start_date, end_date, status, created_at, updated_at
				FROM dbo.semesters
				WHERE status IN ('UPCOMING', 'ACTIVE')
				ORDER BY start_date DESC
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Semester> semesters = new ArrayList<>();
			while (result.next()) {
				Semester semester = new Semester();
				semester.setSemesterId(result.getLong("semester_id"));
				semester.setCode(result.getString("code"));
				semester.setName(result.getString("name"));
				semester.setStartDate(result.getDate("start_date").toLocalDate());
				semester.setEndDate(result.getDate("end_date").toLocalDate());
				semester.setStatus(result.getString("status"));
				semester.setCreatedAt(toLocalDateTime(result.getTimestamp("created_at")));
				semester.setUpdatedAt(toLocalDateTime(result.getTimestamp("updated_at")));
				semesters.add(semester);
			}
			return semesters;
		}
	}

	public long create(LabUsageRequest request) throws SQLException {
		String sql = """
				INSERT dbo.lab_usage_requests (semester_id, mentor_id, group_name, status, request_note)
				VALUES (?, ?, ?, 'PENDING', ?)
				""";
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long requestId;
				try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
					statement.setLong(1, request.getSemesterId());
					statement.setLong(2, request.getMentorId());
					statement.setString(3, request.getGroupName());
					statement.setString(4, emptyToNull(request.getRequestNote()));
					statement.executeUpdate();
					try (ResultSet keys = statement.getGeneratedKeys()) {
						if (!keys.next()) {
							throw new SQLException("Không lấy được mã danh sách intern.");
						}
						requestId = keys.getLong(1);
					}
				}
				insertStudents(connection, requestId, request.getSemesterId(), request.getStudents());
				connection.commit();
				return requestId;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public boolean updatePending(LabUsageRequest request) throws SQLException {
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!lockPending(connection, request.getRequestId(), request.getMentorId())) {
					connection.rollback();
					return false;
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.lab_usage_requests
						SET semester_id = ?, group_name = ?, request_note = ?, updated_at = SYSUTCDATETIME()
						WHERE request_id = ? AND mentor_id = ? AND status = 'PENDING'
						""")) {
					statement.setLong(1, request.getSemesterId());
					statement.setString(2, request.getGroupName());
					statement.setString(3, emptyToNull(request.getRequestNote()));
					statement.setLong(4, request.getRequestId());
					statement.setLong(5, request.getMentorId());
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement(
						"DELETE dbo.lab_usage_request_student_entries WHERE request_id = ?")) {
					statement.setLong(1, request.getRequestId());
					statement.executeUpdate();
				}
				insertStudents(connection, request.getRequestId(), request.getSemesterId(), request.getStudents());
				connection.commit();
				return true;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public boolean deletePending(long requestId, long mentorId) throws SQLException {
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!lockPending(connection, requestId, mentorId)) {
					connection.rollback();
					return false;
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						DELETE FROM dbo.lab_usage_requests
						WHERE request_id = ? AND mentor_id = ? AND status = 'PENDING'
						""")) {
					statement.setLong(1, requestId);
					statement.setLong(2, mentorId);
					boolean deleted = statement.executeUpdate() == 1;
					connection.commit();
					return deleted;
				}
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public boolean updateByAdmin(LabUsageRequest request, long adminId) throws SQLException {
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!isActiveAdmin(connection, adminId) || !lockForAdmin(connection, request.getRequestId())) {
					connection.rollback();
					return false;
				}
				String status;
				long currentSemesterId;
				try (PreparedStatement stateStatement = connection.prepareStatement(
						"SELECT status, semester_id FROM dbo.lab_usage_requests WHERE request_id = ?")) {
					stateStatement.setLong(1, request.getRequestId());
					try (ResultSet result = stateStatement.executeQuery()) {
						if (!result.next()) {
							connection.rollback();
							return false;
						}
						status = result.getString("status");
						currentSemesterId = result.getLong("semester_id");
					}
				}
				if ("APPROVED".equals(status) && currentSemesterId != request.getSemesterId()) {
					throw new SQLException("Không thể đổi học kỳ của danh sách đã APPROVED.");
				}
				if ("APPROVED".equals(status)) {
					synchronizeApprovedMemberships(connection, request);
				}
				try (PreparedStatement entries = connection.prepareStatement(
						"DELETE dbo.lab_usage_request_student_entries WHERE request_id = ?")) {
					entries.setLong(1, request.getRequestId());
					entries.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.lab_usage_requests
						SET semester_id = ?, group_name = ?, request_note = ?, updated_at = SYSUTCDATETIME()
						WHERE request_id = ?
						""")) {
					statement.setLong(1, request.getSemesterId());
					statement.setString(2, request.getGroupName());
					statement.setString(3, emptyToNull(request.getRequestNote()));
					statement.setLong(4, request.getRequestId());
					statement.executeUpdate();
				}
				insertStudents(connection, request.getRequestId(), request.getSemesterId(), request.getStudents());
				connection.commit();
				return true;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public boolean deleteByAdmin(long requestId, long adminId) throws SQLException {
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!isActiveAdmin(connection, adminId) || !lockForAdmin(connection, requestId)) {
					connection.rollback();
					return false;
				}
				if (hasAssetUsage(connection, requestId)) {
					throw new SQLException("Không thể xóa danh sách đã có lịch sử sử dụng tài sản.");
				}
				Map<Long, Long> internAccounts = findInternAccounts(connection, requestId);
				try (PreparedStatement memberships = connection.prepareStatement(
						"DELETE dbo.lab_usage_request_students WHERE request_id = ?")) {
					memberships.setLong(1, requestId);
					memberships.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						DELETE FROM dbo.lab_usage_requests
						WHERE request_id = ?
					""")) {
					statement.setLong(1, requestId);
					boolean deleted = statement.executeUpdate() == 1;
					if (deleted) {
						deleteOrphanedInternAccounts(connection, requestId, internAccounts);
					}
					connection.commit();
					return deleted;
				}
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private void synchronizeApprovedMemberships(Connection connection, LabUsageRequest request) throws SQLException {
		Set<Long> previousStudentIds = findMembershipStudentIds(connection, request.getRequestId());
		Set<Long> currentStudentIds = new HashSet<>();
		for (LabUsageRequestStudent intern : request.getStudents()) {
			intern.setRequestId(request.getRequestId());
			intern.setSemesterId(request.getSemesterId());
			long studentId = activateIntern(connection, intern);
			currentStudentIds.add(studentId);
			insertMembership(connection, intern, studentId);
		}
		for (Long studentId : previousStudentIds) {
			if (!currentStudentIds.contains(studentId)) {
				try (PreparedStatement statement = connection.prepareStatement(
						"DELETE dbo.lab_usage_request_students WHERE request_id = ? AND student_id = ?")) {
					statement.setLong(1, request.getRequestId());
					statement.setLong(2, studentId);
					statement.executeUpdate();
				}
			}
		}
	}

	private Set<Long> findMembershipStudentIds(Connection connection, long requestId) throws SQLException {
		Set<Long> studentIds = new HashSet<>();
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT student_id FROM dbo.lab_usage_request_students WHERE request_id = ?")) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				while (result.next()) {
					studentIds.add(result.getLong("student_id"));
				}
			}
		}
		return studentIds;
	}

	private boolean hasAssetUsage(Connection connection, long requestId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.asset_usages WHERE request_id = ?")) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private Map<Long, Long> findInternAccounts(Connection connection, long requestId) throws SQLException {
		Map<Long, Long> accounts = new java.util.LinkedHashMap<>();
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT DISTINCT u.user_id, sp.student_id
				FROM dbo.users u
				JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				WHERE u.role = 'INTERN'
				  AND (EXISTS (
						SELECT 1 FROM dbo.lab_usage_request_student_entries e
						WHERE e.request_id = ? AND LOWER(e.email) = LOWER(u.email)
					)
					OR EXISTS (
						SELECT 1 FROM dbo.lab_usage_request_students m
						WHERE m.request_id = ? AND m.student_id = sp.student_id
					))
				""")) {
			statement.setLong(1, requestId);
			statement.setLong(2, requestId);
			try (ResultSet result = statement.executeQuery()) {
				while (result.next()) {
					accounts.put(result.getLong("user_id"), result.getLong("student_id"));
				}
			}
		}
		return accounts;
	}

	private void deleteOrphanedInternAccounts(Connection connection, long requestId, Map<Long, Long> accounts)
			throws SQLException {
		for (Map.Entry<Long, Long> account : accounts.entrySet()) {
			long userId = account.getKey();
			long studentId = account.getValue();
			if (hasOtherInternReferences(connection, requestId, userId, studentId)) {
				continue;
			}
			try (PreparedStatement profile = connection.prepareStatement(
					"DELETE dbo.student_profiles WHERE student_id = ?")) {
				profile.setLong(1, studentId);
				profile.executeUpdate();
			}
			try (PreparedStatement user = connection.prepareStatement(
					"DELETE dbo.users WHERE user_id = ? AND role = 'INTERN'")) {
				user.setLong(1, userId);
				user.executeUpdate();
			}
		}
	}

	private boolean hasOtherInternReferences(Connection connection, long requestId, long userId, long studentId)
			throws SQLException {
		if (exists(connection,
				"SELECT 1 FROM dbo.lab_usage_request_student_entries e JOIN dbo.users u ON LOWER(u.email) = LOWER(e.email) "
						+ "WHERE e.request_id <> ? AND u.user_id = ?", requestId, userId)
				|| exists(connection,
						"SELECT 1 FROM dbo.lab_usage_request_students WHERE request_id <> ? AND student_id = ?", requestId,
						studentId)
				|| exists(connection, "SELECT 1 FROM dbo.asset_usages WHERE student_id = ?", studentId)
				|| exists(connection, "SELECT 1 FROM dbo.responsibilities WHERE student_id = ?", studentId)) {
			return true;
		}
		return exists(connection, "SELECT 1 FROM dbo.lab_usage_requests WHERE mentor_id = ? OR approved_by = ?", userId,
				userId)
				|| exists(connection, "SELECT 1 FROM dbo.asset_usages WHERE created_by = ?", userId)
				|| exists(connection, "SELECT 1 FROM dbo.inspection_records WHERE inspected_by = ?", userId)
				|| exists(connection, "SELECT 1 FROM dbo.incidents WHERE reported_by = ?", userId)
				|| exists(connection, "SELECT 1 FROM dbo.responsibilities WHERE determined_by = ? OR reviewed_by = ?", userId,
						userId)
				|| exists(connection, "SELECT 1 FROM dbo.maintenance_records WHERE requested_by = ? OR approved_by = ?", userId,
						userId)
				|| exists(connection, "SELECT 1 FROM dbo.disposal_records WHERE requested_by = ? OR approved_by = ?", userId,
						userId);
	}

	private boolean exists(Connection connection, String sql, long... parameters) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 0; index < parameters.length; index++) {
				statement.setLong(index + 1, parameters[index]);
			}
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	public boolean decidePending(long requestId, long adminId, String decision, String approvalNote)
			throws SQLException {
		if (!"APPROVED".equals(decision) && !"REJECTED".equals(decision)) {
			throw new SQLException("Quyết định duyệt không hợp lệ.");
		}
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!isActiveAdmin(connection, adminId)) {
					throw new SQLException("Tài khoản Admin không hợp lệ.");
				}
				if (!lockPendingForDecision(connection, requestId)) {
					connection.rollback();
					return false;
				}
				if ("APPROVED".equals(decision)) {
					for (LabUsageRequestStudent intern : findStudents(connection, requestId)) {
						long studentId = activateIntern(connection, intern);
						insertMembership(connection, intern, studentId);
					}
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.lab_usage_requests
						SET status = ?, approved_by = ?, approved_at = SYSUTCDATETIME(),
						    approval_note = ?, updated_at = SYSUTCDATETIME()
						WHERE request_id = ? AND status = 'PENDING'
						""")) {
					statement.setString(1, decision);
					statement.setLong(2, adminId);
					statement.setString(3, emptyToNull(approvalNote));
					statement.setLong(4, requestId);
					if (statement.executeUpdate() != 1) {
						throw new SQLException("Danh sách không còn ở trạng thái PENDING.");
					}
				}
				connection.commit();
				return true;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private List<LabUsageRequest> readRequests(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<LabUsageRequest> requests = new ArrayList<>();
			while (result.next()) {
				requests.add(mapRequest(result));
			}
			return requests;
		}
	}

	private void insertStudents(Connection connection, long requestId, long semesterId,
			List<LabUsageRequestStudent> students) throws SQLException {
		String sql = """
				INSERT dbo.lab_usage_request_student_entries
				       (request_id, semester_id, student_code, full_name, email, cohort)
				VALUES (?, ?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (LabUsageRequestStudent intern : students) {
				statement.setLong(1, requestId);
				statement.setLong(2, semesterId);
				statement.setString(3, intern.getStudentCode().trim());
				statement.setString(4, intern.getFullName().trim());
				statement.setString(5, intern.getEmail().trim().toLowerCase());
				statement.setString(6, intern.getCohort().trim());
				statement.addBatch();
			}
			statement.executeBatch();
		}
	}

	private long activateIntern(Connection connection, LabUsageRequestStudent intern) throws SQLException {
		Long userId = null;
		Long studentId = null;
		String existingCode = null;
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT u.user_id, u.role, sp.student_id, sp.student_code
				FROM dbo.users u WITH (UPDLOCK, HOLDLOCK)
				LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				WHERE LOWER(u.email) = LOWER(?)
				""")) {
			statement.setString(1, intern.getEmail());
			try (ResultSet result = statement.executeQuery()) {
				if (result.next()) {
					if (!"INTERN".equals(result.getString("role"))) {
						throw new SQLException("Email " + intern.getEmail() + " đã thuộc vai trò khác.");
					}
					userId = result.getLong("user_id");
					studentId = nullableLong(result, "student_id");
					existingCode = result.getString("student_code");
				}
			}
		}

		if (studentId != null && !intern.getStudentCode().equalsIgnoreCase(existingCode)) {
			throw new SQLException("Gmail " + intern.getEmail() + " không khớp mã intern hiện có.");
		}
		ensureInternCodeAvailable(connection, intern.getStudentCode(), userId);

		if (userId == null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					INSERT dbo.users (full_name, email, role, status)
					VALUES (?, ?, 'INTERN', 'ACTIVE')
					""", Statement.RETURN_GENERATED_KEYS)) {
				statement.setString(1, intern.getFullName());
				statement.setString(2, intern.getEmail().toLowerCase());
				statement.executeUpdate();
				try (ResultSet keys = statement.getGeneratedKeys()) {
					if (!keys.next()) {
						throw new SQLException("Không tạo được tài khoản intern.");
					}
					userId = keys.getLong(1);
				}
			}
		} else {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.users
					SET full_name = ?, role = 'INTERN', status = 'ACTIVE', updated_at = SYSUTCDATETIME()
					WHERE user_id = ?
					""")) {
				statement.setString(1, intern.getFullName());
				statement.setLong(2, userId);
				statement.executeUpdate();
			}
		}

		if (studentId == null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					INSERT dbo.student_profiles (user_id, student_code, major, cohort, status)
					VALUES (?, ?, NULL, ?, 'ACTIVE')
					""", Statement.RETURN_GENERATED_KEYS)) {
				statement.setLong(1, userId);
				statement.setString(2, intern.getStudentCode());
				statement.setString(3, intern.getCohort());
				statement.executeUpdate();
				try (ResultSet keys = statement.getGeneratedKeys()) {
					if (!keys.next()) {
						throw new SQLException("Không tạo được hồ sơ intern.");
					}
					studentId = keys.getLong(1);
				}
			}
		} else {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.student_profiles
					SET cohort = ?, status = 'ACTIVE', updated_at = SYSUTCDATETIME()
					WHERE student_id = ?
					""")) {
				statement.setString(1, intern.getCohort());
				statement.setLong(2, studentId);
				statement.executeUpdate();
			}
		}
		return studentId;
	}

	private void insertMembership(Connection connection, LabUsageRequestStudent intern, long studentId)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
				SELECT ?, ?, ?
				WHERE NOT EXISTS (
				    SELECT 1 FROM dbo.lab_usage_request_students
				    WHERE semester_id = ? AND student_id = ?
				)
				""")) {
			statement.setLong(1, intern.getRequestId());
			statement.setLong(2, intern.getSemesterId());
			statement.setLong(3, studentId);
			statement.setLong(4, intern.getSemesterId());
			statement.setLong(5, studentId);
			statement.executeUpdate();
		}
	}

	private void ensureInternCodeAvailable(Connection connection, String code, Long userId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT user_id FROM dbo.student_profiles WITH (UPDLOCK, HOLDLOCK)
				WHERE UPPER(student_code) = UPPER(?)
				""")) {
			statement.setString(1, code);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next() && (userId == null || result.getLong("user_id") != userId.longValue())) {
					throw new SQLException("Mã intern " + code + " đã thuộc tài khoản khác.");
				}
			}
		}
	}

	private boolean isActiveAdmin(Connection connection, long adminId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.users WHERE user_id = ? AND role = 'ADMIN' AND status = 'ACTIVE'")) {
			statement.setLong(1, adminId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean lockPendingForDecision(Connection connection, long requestId) throws SQLException {
		return lock(connection, "SELECT request_id FROM dbo.lab_usage_requests WITH (UPDLOCK, HOLDLOCK) "
				+ "WHERE request_id = ? AND status = 'PENDING'", requestId, null);
	}

	private boolean lockPending(Connection connection, long requestId, long mentorId) throws SQLException {
		return lock(connection, "SELECT request_id FROM dbo.lab_usage_requests WITH (UPDLOCK, HOLDLOCK) "
				+ "WHERE request_id = ? AND mentor_id = ? AND status = 'PENDING'", requestId, mentorId);
	}

	private boolean lockForAdmin(Connection connection, long requestId) throws SQLException {
		return lock(connection, "SELECT request_id FROM dbo.lab_usage_requests WITH (UPDLOCK, HOLDLOCK) "
				+ "WHERE request_id = ?", requestId, null);
	}

	private boolean lock(Connection connection, String sql, long first, Long second) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, first);
			if (second != null) {
				statement.setLong(2, second);
			}
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private List<LabUsageRequestStudent> findStudents(Connection connection, long requestId) throws SQLException {
		String sql = """
				SELECT e.request_id, e.semester_id, approved.student_id, e.added_at,
				       e.student_code, e.full_name, e.email, e.cohort
				FROM dbo.lab_usage_request_student_entries e
				LEFT JOIN dbo.users u ON LOWER(u.email) = LOWER(e.email) AND u.role = 'INTERN'
				LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				LEFT JOIN dbo.lab_usage_request_students approved
				       ON approved.request_id = e.request_id AND approved.student_id = sp.student_id
				WHERE e.request_id = ?
				ORDER BY e.student_code
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequestStudent> students = new ArrayList<>();
				while (result.next()) {
					LabUsageRequestStudent intern = new LabUsageRequestStudent();
					intern.setRequestId(result.getLong("request_id"));
					intern.setSemesterId(result.getLong("semester_id"));
					intern.setStudentId(nullableLong(result, "student_id"));
					intern.setStudentCode(result.getString("student_code"));
					intern.setFullName(result.getString("full_name"));
					intern.setEmail(result.getString("email"));
					intern.setCohort(result.getString("cohort"));
					intern.setAddedAt(toLocalDateTime(result.getTimestamp("added_at")));
					students.add(intern);
				}
				return students;
			}
		}
	}

	private LabUsageRequest mapRequest(ResultSet result) throws SQLException {
		LabUsageRequest request = new LabUsageRequest();
		request.setRequestId(result.getLong("request_id"));
		request.setSemesterId(result.getLong("semester_id"));
		request.setMentorId(result.getLong("mentor_id"));
		request.setGroupName(result.getString("group_name"));
		request.setStatus(result.getString("status"));
		request.setRequestNote(result.getString("request_note"));
		request.setApprovedBy(nullableLong(result, "approved_by"));
		request.setApprovedAt(toLocalDateTime(result.getTimestamp("approved_at")));
		request.setApprovalNote(result.getString("approval_note"));
		request.setCreatedAt(toLocalDateTime(result.getTimestamp("created_at")));
		request.setUpdatedAt(toLocalDateTime(result.getTimestamp("updated_at")));
		request.setSemesterCode(result.getString("semester_code"));
		request.setSemesterName(result.getString("semester_name"));
		request.setMentorName(result.getString("mentor_name"));
		request.setMentorEmail(result.getString("mentor_email"));
		request.setStudentCount(result.getInt("student_count"));
		return request;
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) {
			statement.setNull(index, Types.BIGINT);
		} else {
			statement.setLong(index, value);
		}
	}

	private LocalDateTime toLocalDateTime(Timestamp timestamp) {
		return timestamp == null ? null : timestamp.toLocalDateTime();
	}

	private String valueOrEmpty(String value) {
		return value == null ? "" : value.trim();
	}

	private String emptyToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
