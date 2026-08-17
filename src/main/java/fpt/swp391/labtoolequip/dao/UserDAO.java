package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.User;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class UserDAO {
	private static final String SELECT_USER = """
			SELECT u.user_id, u.full_name, u.email, u.password_hash, u.google_subject,
			       u.role, u.status, u.created_at, u.updated_at,
			       sp.student_code, sp.major, sp.cohort
			FROM dbo.users u
			LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
			""";

	private final DBConnection dbConnection = new DBConnection();

	public List<User> findAll(String keyword, String role, String status) throws SQLException {
		String sql = SELECT_USER + """
				WHERE u.role != 'ADMIN'
				  AND (? = '' OR u.full_name LIKE ? OR u.email LIKE ? OR sp.student_code LIKE ?)
				  AND (? = '' OR u.role = ?)
				  AND (? = '' OR u.status = ?)
				ORDER BY u.created_at DESC, u.user_id DESC
				""";
		String search = valueOrEmpty(keyword);
		String roleFilter = valueOrEmpty(role);
		String statusFilter = valueOrEmpty(status);

		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			statement.setString(2, "%" + search + "%");
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, roleFilter);
			statement.setString(6, roleFilter);
			statement.setString(7, statusFilter);
			statement.setString(8, statusFilter);

			try (ResultSet result = statement.executeQuery()) {
				List<User> users = new ArrayList<>();
				while (result.next()) {
					users.add(mapUser(result));
				}
				return users;
			}
		}
	}

	public Optional<User> findById(long userId) throws SQLException {
		String sql = SELECT_USER + "WHERE u.user_id = ?";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next() ? Optional.of(mapUser(result)) : Optional.empty();
			}
		}
	}

	public Optional<User> findByEmail(String email) throws SQLException {
		String sql = SELECT_USER + "WHERE LOWER(u.email) = LOWER(?)";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, valueOrEmpty(email));
			try (ResultSet result = statement.executeQuery()) {
				return result.next() ? Optional.of(mapUser(result)) : Optional.empty();
			}
		}
	}

	public boolean linkGoogleSubject(long userId, String googleSubject) throws SQLException {
		String sql = """
				UPDATE dbo.users
				SET google_subject = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ? AND (google_subject IS NULL OR google_subject = ?)
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, googleSubject);
			statement.setLong(2, userId);
			statement.setString(3, googleSubject);
			return statement.executeUpdate() == 1;
		}
	}

	public boolean bindGoogleSubject(long userId, String googleSubject) throws SQLException {
		return linkGoogleSubject(userId, googleSubject);
	}

	public long create(User user) throws SQLException {
		String insertUser = """
				INSERT INTO dbo.users (full_name, email, password_hash, role, status)
				VALUES (?, ?, ?, ?, ?)
				""";
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long userId;
				try (PreparedStatement statement = connection.prepareStatement(insertUser,
						Statement.RETURN_GENERATED_KEYS)) {
					statement.setString(1, user.getFullName());
					statement.setString(2, user.getEmail());
					statement.setString(3, user.getPasswordHash());
					statement.setString(4, user.getRole());
					statement.setString(5, user.getStatus());
					statement.executeUpdate();
					try (ResultSet keys = statement.getGeneratedKeys()) {
						if (!keys.next()) {
							throw new SQLException("Creating user failed: no generated ID.");
						}
						userId = keys.getLong(1);
					}
				}

				if ("INTERN".equals(user.getRole())) {
					insertStudentProfile(connection, userId, user);
				}
				connection.commit();
				return userId;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public int batchCreate(List<User> users) throws SQLException {
		int createdCount = 0;
		for (User u : users) {
			try {
				if (findByEmail(u.getEmail()).isEmpty()) {
					create(u);
					createdCount++;
				}
			} catch (SQLException ex) {
				// Skip duplicates or log
			}
		}
		return createdCount;
	}

	public boolean toggleStatus(long userId) throws SQLException {
		String sql = """
				UPDATE dbo.users
				SET status = CASE WHEN status = 'ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END,
				    updated_at = SYSUTCDATETIME()
				WHERE user_id = ?
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			return statement.executeUpdate() == 1;
		}
	}

	public boolean updateRole(long userId, String newRole) throws SQLException {
		String sql = """
				UPDATE dbo.users
				SET role = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ? AND role IN ('MENTOR', 'LAB_MANAGER')
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, newRole);
			statement.setLong(2, userId);
			return statement.executeUpdate() == 1;
		}
	}

	public boolean updateRoleAndStatus(long userId, String role, String status) throws SQLException {
		String sql = """
				UPDATE dbo.users
				SET role = ?, status = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ?
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, role);
			statement.setString(2, status);
			statement.setLong(3, userId);
			return statement.executeUpdate() == 1;
		}
	}

	public boolean update(User user) throws SQLException {
		try (Connection connection = dbConnection.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!"INTERN".equals(user.getRole())) {
					deleteStudentProfile(connection, user.getUserId());
				}

				boolean updated = updateUser(connection, user);
				if (!updated) {
					connection.rollback();
					return false;
				}

				if ("INTERN".equals(user.getRole())) {
					upsertStudentProfile(connection, user);
				}
				connection.commit();
				return true;
			} catch (SQLException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private boolean updateUser(Connection connection, User user) throws SQLException {
		boolean changePassword = user.getPasswordHash() != null && !user.getPasswordHash().isBlank();
		String sql = changePassword ? """
				UPDATE dbo.users
				SET full_name = ?, email = ?, password_hash = ?, role = ?, status = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ?
				""" : """
				UPDATE dbo.users
				SET full_name = ?, email = ?, role = ?, status = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ?
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			int index = 1;
			statement.setString(index++, user.getFullName());
			statement.setString(index++, user.getEmail());
			if (changePassword) {
				statement.setString(index++, user.getPasswordHash());
			}
			statement.setString(index++, user.getRole());
			statement.setString(index++, user.getStatus());
			statement.setLong(index, user.getUserId());
			return statement.executeUpdate() == 1;
		}
	}

	private void insertStudentProfile(Connection connection, long userId, User user) throws SQLException {
		String sql = """
				INSERT INTO dbo.student_profiles (user_id, student_code, major, cohort, status)
				VALUES (?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			statement.setString(2, user.getStudentCode());
			statement.setString(3, emptyToNull(user.getMajor()));
			statement.setString(4, emptyToNull(user.getCohort()));
			statement.setString(5, user.getStatus());
			statement.executeUpdate();
		}
	}

	private void upsertStudentProfile(Connection connection, User user) throws SQLException {
		String update = """
				UPDATE dbo.student_profiles
				SET student_code = ?, major = ?, cohort = ?, status = ?, updated_at = SYSUTCDATETIME()
				WHERE user_id = ?
				""";
		try (PreparedStatement statement = connection.prepareStatement(update)) {
			statement.setString(1, user.getStudentCode());
			statement.setString(2, emptyToNull(user.getMajor()));
			statement.setString(3, emptyToNull(user.getCohort()));
			statement.setString(4, user.getStatus());
			statement.setLong(5, user.getUserId());
			if (statement.executeUpdate() == 0) {
				insertStudentProfile(connection, user.getUserId(), user);
			}
		}
	}

	private void deleteStudentProfile(Connection connection, long userId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("DELETE FROM dbo.student_profiles WHERE user_id = ?")) {
			statement.setLong(1, userId);
			statement.executeUpdate();
		}
	}

	private User mapUser(ResultSet result) throws SQLException {
		User user = new User();
		user.setUserId(result.getLong("user_id"));
		user.setFullName(result.getString("full_name"));
		user.setEmail(result.getString("email"));
		user.setPasswordHash(result.getString("password_hash"));
		user.setGoogleSubject(result.getString("google_subject"));
		user.setRole(result.getString("role"));
		user.setStatus(result.getString("status"));
		user.setStudentCode(result.getString("student_code"));
		user.setMajor(result.getString("major"));
		user.setCohort(result.getString("cohort"));
		user.setCreatedAt(toLocalDateTime(result.getTimestamp("created_at")));
		user.setUpdatedAt(toLocalDateTime(result.getTimestamp("updated_at")));
		return user;
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
