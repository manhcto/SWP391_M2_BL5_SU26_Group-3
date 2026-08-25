package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import fpt.swp391.labtoolequip.common.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class AssetUsageDAOIntegrationTest {
	private final DBConnection db = new DBConnection();
	private final AssetUsageDAO dao = new AssetUsageDAO();
	private final List<Long> assetIds = new ArrayList<>();
	private final List<Long> userIds = new ArrayList<>();
	private final List<Long> internIds = new ArrayList<>();

	@AfterEach
	void cleanUp() throws SQLException {
		try (Connection connection = db.getConnection()) {
			for (long assetId : assetIds) {
				execute(connection, "DELETE FROM dbo.asset_usages WHERE asset_id = ?", assetId);
				execute(connection, "DELETE FROM dbo.assets WHERE asset_id = ?", assetId);
			}
			for (long internId : internIds)
				execute(connection, "DELETE FROM dbo.lab_usage_request_students WHERE student_id = ?", internId);
			for (long userId : userIds) {
				execute(connection, """
						DELETE entry FROM dbo.lab_usage_request_student_entries entry
						JOIN dbo.users account ON LOWER(account.email) = LOWER(entry.email)
						WHERE account.user_id = ?
						""", userId);
				execute(connection, "DELETE FROM dbo.student_profiles WHERE user_id = ?", userId);
				execute(connection, "DELETE FROM dbo.users WHERE user_id = ?", userId);
			}
		}
	}

	@Test
	void approvedInternBorrowPersistsTraceableUsage() throws Exception {
		long userId = userId("intern@gmail.com");
		long assetId = createAsset("AVAILABLE", true, "GOOD", 1);

		long usageId = dao.borrow(userId, assetId, null, 1, "JUnit integration trace", validBorrowTime());

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT au.asset_id, ip.user_id, au.request_id, au.semester_id, au.status, au.note
				FROM dbo.asset_usages au JOIN dbo.intern_profiles ip ON ip.intern_id=au.student_id
				WHERE au.asset_usage_id=?
				""")) {
			statement.setLong(1, usageId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals(assetId, result.getLong("asset_id"));
				assertEquals(userId, result.getLong("user_id"));
				assertTrue(result.getLong("request_id") > 0);
				assertTrue(result.getLong("semester_id") > 0);
				assertEquals("IN_USE", result.getString("status"));
				assertEquals("JUnit integration trace", result.getString("note"));
			}
		}
	}

	@Test
	void activeAdminCreatedInternIsEnrolledAndCanBorrow() throws Exception {
		long userId = createUnapprovedIntern();
		long assetId = createAsset("AVAILABLE", true, "GOOD", 1);

		dao.borrow(userId, assetId, null, 1, null, validBorrowTime());

		assertEquals(1, usageCount(assetId));
		assertEquals(1, membershipCount(userId));
	}

	@Test
	void maintenanceAssetCannotCreateUsage() throws Exception {
		long userId = userId("intern@gmail.com");
		long maintenanceId = createAsset("MAINTENANCE", true, "DAMAGED", 1);

		assertThrows(IllegalStateException.class,
				() -> dao.borrow(userId, maintenanceId, null, 1, null, validBorrowTime()));
		assertEquals(0, usageCount(maintenanceId));
		List<Long> visibleAssetIds = dao.findBorrowableAssets().stream().map(asset -> asset.getAssetId()).toList();
		assertTrue(!visibleAssetIds.contains(maintenanceId));
	}

	@Test
	void nonBorrowableAssetCannotCreateUsage() throws Exception {
		long userId = userId("intern@gmail.com");
		long fixedId = createAsset("AVAILABLE", false, "GOOD", 1);

		assertThrows(IllegalStateException.class, () -> dao.borrow(userId, fixedId, null, 1, null, validBorrowTime()));
		assertEquals(0, usageCount(fixedId));
		List<Long> visibleAssetIds = dao.findBorrowableAssets().stream().map(asset -> asset.getAssetId()).toList();
		assertTrue(!visibleAssetIds.contains(fixedId));
	}

	@Test
	void disposedAssetCannotCreateUsage() throws Exception {
		long userId = userId("intern@gmail.com");
		long disposedId = createAsset("DISPOSED", false, "BROKEN", 1);

		assertThrows(IllegalStateException.class,
				() -> dao.borrow(userId, disposedId, null, 1, null, validBorrowTime()));
		assertEquals(0, usageCount(disposedId));
		List<Long> visibleAssetIds = dao.findBorrowableAssets().stream().map(asset -> asset.getAssetId()).toList();
		assertTrue(!visibleAssetIds.contains(disposedId));
	}

	@Test
	void concurrentBorrowAllowsOnlyOneInternForLastUnit() throws Exception {
		long firstUser = userId("intern@gmail.com");
		long secondUser = userId("intern2@gmail.com");
		long assetId = createAsset("AVAILABLE", true, "GOOD", 1);
		CountDownLatch start = new CountDownLatch(1);

		ExecutorService executor = Executors.newFixedThreadPool(2);
		try {
			LocalDateTime borrowedAt = validBorrowTime();
			Future<Boolean> first = executor.submit(() -> borrowAfter(start, firstUser, assetId, borrowedAt));
			Future<Boolean> second = executor.submit(() -> borrowAfter(start, secondUser, assetId, borrowedAt));
			start.countDown();

			assertEquals(1, (first.get() ? 1 : 0) + (second.get() ? 1 : 0));
			assertEquals(1, usageCount(assetId));
		} finally {
			executor.shutdownNow();
		}
	}

	@Test
	void firstReviewerWinsBetweenMentorAndLabManager() throws Exception {
		long userId = userId("intern@gmail.com");
		long assetId = createAsset("AVAILABLE", true, "GOOD", 1);
		long usageId = dao.borrow(userId, assetId, null, 1, "Return race", validBorrowTime());
		dao.requestReturn(usageId, userId, "GOOD", "Intern requested return");
		long mentorId = createActiveReviewer("MENTOR");
		long labManagerId = activeLabManagerId();
		CountDownLatch start = new CountDownLatch(1);
		assertTrue(dao.findForMentor(mentorId, "", "RETURN_PENDING").stream()
				.anyMatch(usage -> usage.getAssetUsageId() == usageId));

		ExecutorService executor = Executors.newFixedThreadPool(2);
		try {
			Future<Boolean> mentor = executor.submit(() -> confirmAfter(start, usageId, mentorId, false));
			Future<Boolean> labManager = executor.submit(() -> confirmAfter(start, usageId, labManagerId, true));
			start.countDown();

			assertEquals(1, (mentor.get() ? 1 : 0) + (labManager.get() ? 1 : 0));
			var usage = dao.findById(usageId, null).orElseThrow();
			assertEquals("RETURNED", usage.getStatus());
			assertTrue(List.of(mentorId, labManagerId).contains(usage.getReturnVerifiedBy()));
		} finally {
			executor.shutdownNow();
		}
	}

	private boolean borrowAfter(CountDownLatch start, long userId, long assetId, LocalDateTime borrowedAt)
			throws Exception {
		start.await();
		try {
			dao.borrow(userId, assetId, null, 1, "Concurrent test", borrowedAt);
			return true;
		} catch (IllegalStateException exception) {
			return false;
		}
	}

	private boolean confirmAfter(CountDownLatch start, long usageId, long reviewerId, boolean labManager)
			throws Exception {
		start.await();
		try {
			if (labManager)
				dao.confirmReturnAsLabManager(usageId, reviewerId, "GOOD", "Lab Manager confirmed");
			else
				dao.confirmReturn(usageId, reviewerId, "GOOD", "Mentor confirmed");
			return true;
		} catch (IllegalStateException exception) {
			return false;
		}
	}

	private long activeLabManagerId() throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"SELECT TOP 1 user_id FROM dbo.users WHERE role='LAB_MANAGER' AND status='ACTIVE' ORDER BY user_id");
				ResultSet result = statement.executeQuery()) {
			assertTrue(result.next(), "Database needs one active Lab Manager");
			return result.getLong(1);
		}
	}

	private long createActiveReviewer(String role) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"INSERT dbo.users(full_name,email,role,status) OUTPUT INSERTED.user_id VALUES('JUnit Reviewer',?,?,'ACTIVE')")) {
			statement.setString(1, "junit-reviewer-" + suffix + "@example.com");
			statement.setString(2, role);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				long userId = result.getLong(1);
				userIds.add(userId);
				return userId;
			}
		}
	}

	private LocalDateTime validBorrowTime() {
		LocalDateTime now = LocalDateTime.now();
		return now.toLocalTime().isBefore(LocalTime.of(17, 40))
				? now.minusMinutes(1)
				: now.withHour(14).withMinute(0).withSecond(0).withNano(0);
	}

	private long createAsset(String status, boolean borrowable, String condition, int quantity) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		String sql = """
				INSERT dbo.assets(asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
				 is_borrowable) OUTPUT INSERTED.asset_id
				SELECT ?, ?, MIN(category_id), ?, ?, ?, ?, ? FROM dbo.asset_categories
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, "JUNIT-" + suffix);
			statement.setString(2, "JUnit Asset " + suffix);
			statement.setString(3, "QUANTITY");
			statement.setInt(4, quantity);
			statement.setString(5, condition);
			statement.setString(6, status);
			statement.setBoolean(7, borrowable);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next(), "Database needs at least one asset category");
				long id = result.getLong(1);
				assetIds.add(id);
				return id;
			}
		}
	}

	private long createUnapprovedIntern() throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection()) {
			long userId;
			try (PreparedStatement statement = connection.prepareStatement("""
					INSERT dbo.users(full_name,email,role,status) OUTPUT INSERTED.user_id
					VALUES ('JUnit Unapproved Intern', ?, 'INTERN', 'ACTIVE')
					""")) {
				statement.setString(1, "junit-" + suffix + "@example.com");
				try (ResultSet result = statement.executeQuery()) {
					result.next();
					userId = result.getLong(1);
					userIds.add(userId);
				}
			}
			try (PreparedStatement statement = connection
					.prepareStatement("INSERT dbo.intern_profiles(user_id,intern_code,status) VALUES (?,?,'ACTIVE')")) {
				statement.setLong(1, userId);
				statement.setString(2, "JUNIT-" + suffix);
				statement.executeUpdate();
			}
			try (PreparedStatement statement = connection
					.prepareStatement("SELECT intern_id FROM dbo.intern_profiles WHERE user_id = ?")) {
				statement.setLong(1, userId);
				try (ResultSet result = statement.executeQuery()) {
					result.next();
					internIds.add(result.getLong(1));
				}
			}
			return userId;
		}
	}

	private long userId(String email) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement("SELECT user_id FROM dbo.users WHERE email=?")) {
			statement.setString(1, email);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next())
					return result.getLong(1);
			}
		}
		return createApprovedIntern();
	}

	private long createApprovedIntern() throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long userId;
				try (PreparedStatement statement = connection.prepareStatement(
						"INSERT dbo.users(full_name,email,role,status) OUTPUT INSERTED.user_id VALUES('JUnit Intern',?,'INTERN','ACTIVE')")) {
					statement.setString(1, "junit-approved-" + suffix + "@example.com");
					try (ResultSet result = statement.executeQuery()) {
						result.next();
						userId = result.getLong(1);
					}
				}
				long internId;
				try (PreparedStatement statement = connection.prepareStatement(
						"INSERT dbo.student_profiles(user_id,student_code,status) OUTPUT INSERTED.student_id VALUES(?,?,'ACTIVE')")) {
					statement.setLong(1, userId);
					statement.setString(2, "JUNIT-" + suffix);
					try (ResultSet result = statement.executeQuery()) {
						result.next();
						internId = result.getLong(1);
					}
				}
				try (PreparedStatement statement = connection.prepareStatement(
						"INSERT dbo.lab_usage_request_students(request_id,semester_id,student_id) SELECT TOP 1 request_id,semester_id,? FROM dbo.lab_usage_requests WHERE status='APPROVED' ORDER BY request_id DESC")) {
					statement.setLong(1, internId);
					if (statement.executeUpdate() != 1)
						throw new IllegalStateException("Database needs one approved usage request");
				}
				connection.commit();
				userIds.add(userId);
				internIds.add(internId);
				return userId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private int usageCount(long assetId) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement("SELECT COUNT(*) FROM dbo.asset_usages WHERE asset_id=?")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private int membershipCount(long userId) throws SQLException {
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT COUNT(*) FROM dbo.lab_usage_request_students membership
				JOIN dbo.student_profiles profile ON profile.student_id = membership.student_id
				WHERE profile.user_id = ?
				""")) {
			statement.setLong(1, userId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private void execute(Connection connection, String sql, long... values) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 0; index < values.length; index++) {
				statement.setLong(index + 1, values[index]);
			}
			statement.executeUpdate();
		}
	}
}
