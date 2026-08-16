package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import fpt.swp391.labtoolequip.model.LabUsageRequestSlot;
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
import java.util.List;
import java.util.Optional;

public class LabUsageRequestDAO {
	private static final String SELECT_REQUEST = """
			SELECT r.request_id, r.semester_id, r.mentor_id, r.group_name, r.status,
			       r.request_note, r.approved_by, r.approved_at, r.approval_note,
			       r.created_at, r.updated_at, se.code AS semester_code, se.name AS semester_name,
			       mentor.full_name AS mentor_name, mentor.email AS mentor_email,
			       (SELECT COUNT(*) FROM dbo.lab_usage_request_student_entries rs
			        WHERE rs.request_id = r.request_id) AS student_count,
			       COALESCE((
			           SELECT STRING_AGG(CONCAT(N'Thứ ', x.day_of_week, N' · Slot ', x.slot_id), N', ')
			                  WITHIN GROUP (ORDER BY x.day_of_week, x.slot_id)
			           FROM dbo.lab_usage_request_slots x
			           WHERE x.request_id = r.request_id
			       ), N'—') AS schedule_summary
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
		String search = keyword == null ? "" : keyword.trim();
		String statusFilter = status == null ? "" : status.trim().toUpperCase();
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
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequest> requests = new ArrayList<>();
				while (result.next()) {
					requests.add(mapRequest(result));
				}
				return requests;
			}
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
		String search = keyword == null ? "" : keyword.trim();
		String statusFilter = status == null ? "" : status.trim().toUpperCase();
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
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequest> requests = new ArrayList<>();
				while (result.next()) {
					requests.add(mapRequest(result));
				}
				return requests;
			}
		}
	}

	public Optional<LabUsageRequest> findById(long requestId) throws SQLException {
		String sql = SELECT_REQUEST + "WHERE r.request_id = ?";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					return Optional.empty();
				}
				LabUsageRequest request = mapRequest(result);
				request.setSlots(findSlots(connection, requestId));
				request.setStudents(findStudents(connection, requestId));
				return Optional.of(request);
			}
		}
	}

	public int countByStatus(String status) throws SQLException {
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection
						.prepareStatement("SELECT COUNT(*) FROM dbo.lab_usage_requests WHERE status = ?")) {
			statement.setString(1, status);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	public List<LabUsageRequest> findApprovedSchedule() throws SQLException {
		String sql = SELECT_REQUEST + """
				WHERE r.status = 'APPROVED' AND se.status = 'ACTIVE'
				ORDER BY r.request_id
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequest> requests = new ArrayList<>();
				while (result.next()) {
					LabUsageRequest request = mapRequest(result);
					request.setSlots(findSlots(connection, request.getRequestId()));
					requests.add(request);
				}
				return requests;
			}
		}
	}

	public Optional<LabUsageRequest> findByIdForMentor(long requestId, long mentorId) throws SQLException {
		String sql = SELECT_REQUEST + "WHERE r.request_id = ? AND r.mentor_id = ?";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, requestId);
			statement.setLong(2, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					return Optional.empty();
				}
				LabUsageRequest request = mapRequest(result);
				request.setSlots(findSlots(connection, requestId));
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
							throw new SQLException("Không lấy được mã Lab Usage Request.");
						}
						requestId = keys.getLong(1);
					}
				}
				insertSlots(connection, requestId, request.getSlots());
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
		String sql = """
				UPDATE dbo.lab_usage_requests
				SET semester_id = ?, group_name = ?, request_note = ?, updated_at = SYSUTCDATETIME()
				WHERE request_id = ? AND mentor_id = ? AND status = 'PENDING'
				""";
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!lockPending(connection, request.getRequestId(), request.getMentorId())) {
					connection.rollback();
					return false;
				}
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE dbo.lab_usage_request_student_entries WHERE request_id = ?")) {
					statement.setLong(1, request.getRequestId());
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE dbo.lab_usage_request_students WHERE request_id = ?")) {
					statement.setLong(1, request.getRequestId());
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, request.getSemesterId());
					statement.setString(2, request.getGroupName());
					statement.setString(3, emptyToNull(request.getRequestNote()));
					statement.setLong(4, request.getRequestId());
					statement.setLong(5, request.getMentorId());
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE dbo.lab_usage_request_slots WHERE request_id = ?")) {
					statement.setLong(1, request.getRequestId());
					statement.executeUpdate();
				}
				insertSlots(connection, request.getRequestId(), request.getSlots());
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
				String deleteStudents = """
						DELETE rs FROM dbo.lab_usage_request_student_entries rs
						JOIN dbo.lab_usage_requests r ON r.request_id = rs.request_id
						WHERE r.request_id = ? AND r.mentor_id = ? AND r.status = 'PENDING'
						""";
				try (PreparedStatement statement = connection.prepareStatement(deleteStudents)) {
					statement.setLong(1, requestId);
					statement.setLong(2, mentorId);
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						DELETE approved FROM dbo.lab_usage_request_students approved
						JOIN dbo.lab_usage_requests r ON r.request_id = approved.request_id
						WHERE r.request_id = ? AND r.mentor_id = ? AND r.status = 'PENDING'
						""")) {
					statement.setLong(1, requestId);
					statement.setLong(2, mentorId);
					statement.executeUpdate();
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						DELETE dbo.lab_usage_requests
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

	public boolean decidePending(long requestId, long adminId, String decision, String approvalNote)
			throws SQLException {
		if (!"APPROVED".equals(decision) && !"REJECTED".equals(decision)) {
			throw new SQLException("Quyết định duyệt không hợp lệ.");
		}
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!isActiveAdmin(connection, adminId)) {
					throw new SQLException("Không có tài khoản Admin ACTIVE để duyệt request.");
				}
				if (!lockPendingForDecision(connection, requestId)) {
					connection.rollback();
					return false;
				}
				if ("APPROVED".equals(decision)) {
					for (LabUsageRequestStudent student : findStudents(connection, requestId)) {
						long studentId = activateStudent(connection, student);
						try (PreparedStatement statement = connection.prepareStatement("""
								INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
								SELECT ?, ?, ?
								WHERE NOT EXISTS (
								    SELECT 1 FROM dbo.lab_usage_request_students
								    WHERE request_id = ? AND student_id = ?
								)
								""")) {
							statement.setLong(1, requestId);
							statement.setLong(2, student.getSemesterId());
							statement.setLong(3, studentId);
							statement.setLong(4, requestId);
							statement.setLong(5, studentId);
							statement.executeUpdate();
						}
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
						throw new SQLException("Request không còn ở trạng thái PENDING.");
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
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT request_id
				FROM dbo.lab_usage_requests WITH (UPDLOCK, HOLDLOCK)
				WHERE request_id = ? AND status = 'PENDING'
				""")) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private boolean lockPending(Connection connection, long requestId, long mentorId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT request_id
				FROM dbo.lab_usage_requests WITH (UPDLOCK, HOLDLOCK)
				WHERE request_id = ? AND mentor_id = ? AND status = 'PENDING'
				""")) {
			statement.setLong(1, requestId);
			statement.setLong(2, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private void insertSlots(Connection connection, long requestId, List<LabUsageRequestSlot> slots)
			throws SQLException {
		String sql = "INSERT dbo.lab_usage_request_slots (request_id, day_of_week, slot_id) VALUES (?, ?, ?)";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (LabUsageRequestSlot slot : slots) {
				statement.setLong(1, requestId);
				statement.setInt(2, slot.getDayOfWeek());
				statement.setInt(3, slot.getSlotId());
				statement.addBatch();
			}
			statement.executeBatch();
		}
	}

	private void insertStudents(Connection connection, long requestId, long semesterId,
			List<LabUsageRequestStudent> students) throws SQLException {
		String sql = """
				INSERT dbo.lab_usage_request_student_entries
				       (request_id, semester_id, student_code, full_name, email)
				VALUES (?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (LabUsageRequestStudent student : students) {
				statement.setLong(1, requestId);
				statement.setLong(2, semesterId);
				statement.setString(3, student.getStudentCode().trim());
				statement.setString(4, student.getFullName().trim());
				statement.setString(5, student.getEmail().trim().toLowerCase());
				statement.addBatch();
			}
			statement.executeBatch();
		}
	}

	private long activateStudent(Connection connection, LabUsageRequestStudent student) throws SQLException {
		Long userId = null;
		Long studentId = null;
		String existingCode = null;
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT u.user_id, u.role, sp.student_id, sp.student_code
				FROM dbo.users u WITH (UPDLOCK, HOLDLOCK)
				LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				WHERE LOWER(u.email) = LOWER(?)
				""")) {
			statement.setString(1, student.getEmail());
			try (ResultSet result = statement.executeQuery()) {
				if (result.next()) {
					if (!"STUDENT".equals(result.getString("role"))) {
						throw new SQLException("Email " + student.getEmail() + " đã thuộc một vai trò khác.");
					}
					userId = result.getLong("user_id");
					studentId = nullableLong(result, "student_id");
					existingCode = result.getString("student_code");
				}
			}
		}

		if (studentId != null && !student.getStudentCode().equalsIgnoreCase(existingCode)) {
			throw new SQLException("Email " + student.getEmail() + " không khớp mã sinh viên hiện có.");
		}
		ensureStudentCodeAvailable(connection, student.getStudentCode(), userId);

		if (userId == null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					INSERT dbo.users (full_name, email, role, status)
					VALUES (?, ?, 'STUDENT', 'ACTIVE')
					""", Statement.RETURN_GENERATED_KEYS)) {
				statement.setString(1, student.getFullName());
				statement.setString(2, student.getEmail().toLowerCase());
				statement.executeUpdate();
				try (ResultSet keys = statement.getGeneratedKeys()) {
					if (!keys.next()) {
						throw new SQLException("Không tạo được tài khoản sinh viên.");
					}
					userId = keys.getLong(1);
				}
			}
		} else {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.users
					SET full_name = ?, status = 'ACTIVE', updated_at = SYSUTCDATETIME()
					WHERE user_id = ?
					""")) {
				statement.setString(1, student.getFullName());
				statement.setLong(2, userId);
				statement.executeUpdate();
			}
		}

		if (studentId == null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					INSERT dbo.student_profiles (user_id, student_code, status)
					VALUES (?, ?, 'ACTIVE')
					""", Statement.RETURN_GENERATED_KEYS)) {
				statement.setLong(1, userId);
				statement.setString(2, student.getStudentCode());
				statement.executeUpdate();
				try (ResultSet keys = statement.getGeneratedKeys()) {
					if (!keys.next()) {
						throw new SQLException("Không tạo được hồ sơ sinh viên.");
					}
					studentId = keys.getLong(1);
				}
			}
		} else {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.student_profiles
					SET status = 'ACTIVE', updated_at = SYSUTCDATETIME()
					WHERE student_id = ?
					""")) {
				statement.setLong(1, studentId);
				statement.executeUpdate();
			}
		}
		return studentId;
	}

	private void ensureStudentCodeAvailable(Connection connection, String studentCode, Long userId)
			throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT sp.user_id
				FROM dbo.student_profiles sp WITH (UPDLOCK, HOLDLOCK)
				WHERE UPPER(sp.student_code) = UPPER(?)
				""")) {
			statement.setString(1, studentCode);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next() && (userId == null || result.getLong("user_id") != userId)) {
					throw new SQLException("Mã sinh viên " + studentCode + " đã thuộc tài khoản khác.");
				}
			}
		}
	}

	private List<LabUsageRequestSlot> findSlots(Connection connection, long requestId) throws SQLException {
		String sql = """
				SELECT rs.request_id, rs.day_of_week, rs.slot_id, ts.start_time, ts.end_time
				FROM dbo.lab_usage_request_slots rs
				JOIN dbo.lab_time_slots ts ON ts.slot_id = rs.slot_id
				WHERE rs.request_id = ?
				ORDER BY rs.day_of_week, rs.slot_id
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequestSlot> slots = new ArrayList<>();
				while (result.next()) {
					LabUsageRequestSlot slot = new LabUsageRequestSlot();
					slot.setRequestId(result.getLong("request_id"));
					slot.setDayOfWeek(result.getInt("day_of_week"));
					slot.setSlotId(result.getInt("slot_id"));
					slot.setStartTime(result.getTime("start_time").toLocalTime());
					slot.setEndTime(result.getTime("end_time").toLocalTime());
					slots.add(slot);
				}
				return slots;
			}
		}
	}

	private List<LabUsageRequestStudent> findStudents(Connection connection, long requestId) throws SQLException {
		String sql = """
				SELECT rs.request_id, rs.semester_id, approved.student_id, rs.added_at,
				       rs.student_code, rs.full_name, rs.email
				FROM dbo.lab_usage_request_student_entries rs
				LEFT JOIN dbo.users u ON LOWER(u.email) = LOWER(rs.email) AND u.role = 'STUDENT'
				LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				LEFT JOIN dbo.lab_usage_request_students approved
				       ON approved.request_id = rs.request_id AND approved.student_id = sp.student_id
				WHERE rs.request_id = ?
				ORDER BY rs.student_code
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, requestId);
			try (ResultSet result = statement.executeQuery()) {
				List<LabUsageRequestStudent> students = new ArrayList<>();
				while (result.next()) {
					LabUsageRequestStudent student = new LabUsageRequestStudent();
					student.setRequestId(result.getLong("request_id"));
					student.setSemesterId(result.getLong("semester_id"));
					student.setStudentId(nullableLong(result, "student_id"));
					student.setStudentCode(result.getString("student_code"));
					student.setFullName(result.getString("full_name"));
					student.setEmail(result.getString("email"));
					student.setAddedAt(toLocalDateTime(result.getTimestamp("added_at")));
					students.add(student);
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
		request.setScheduleSummary(result.getString("schedule_summary"));
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

	private String emptyToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
