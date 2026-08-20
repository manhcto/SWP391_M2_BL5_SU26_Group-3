package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import fpt.swp391.labtoolequip.common.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class DisposalRecordDAOIntegrationTest {
	private final DBConnection db = new DBConnection();
	private final DisposalRecordDAO dao = new DisposalRecordDAO();
	private final List<Long> assetIds = new ArrayList<>();
	private final List<Long> itemIds = new ArrayList<>();
	private final List<Long> disposalIds = new ArrayList<>();
	private final List<Long> usageIds = new ArrayList<>();

	@AfterEach
	void cleanUp() throws SQLException {
		try (Connection connection = db.getConnection()) {
			for (long usageId : usageIds)
				execute(connection, "DELETE FROM dbo.asset_usages WHERE asset_usage_id = ?", usageId);
			for (long disposalId : disposalIds)
				execute(connection, "DELETE FROM dbo.disposal_records WHERE disposal_id = ?", disposalId);
			for (long itemId : itemIds)
				execute(connection, "DELETE FROM dbo.asset_items WHERE asset_item_id = ?", itemId);
			for (long assetId : assetIds)
				execute(connection, "DELETE FROM dbo.assets WHERE asset_id = ?", assetId);
		}
	}

	@Test
	void serializedCompletionDisposesOnlyTheSelectedItem() throws Exception {
		long assetId = createAsset("SERIALIZED", 2);
		long itemId = createItem(assetId, "BROKEN", "UNAVAILABLE", false);
		createItem(assetId, "GOOD", "AVAILABLE", true);
		long disposalId = requestAndApprove(null, itemId);

		dao.complete(disposalId, "Disposed item test");

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT d.status AS disposal_status, d.asset_item_id, d.quantity,
				       a.status AS asset_status, a.is_borrowable AS asset_borrowable, a.total_quantity,
				       ai.status AS item_status, ai.is_borrowable AS item_borrowable
				FROM dbo.disposal_records d
				JOIN dbo.assets a ON a.asset_id = d.asset_id
				JOIN dbo.asset_items ai ON ai.asset_item_id = d.asset_item_id
				WHERE d.disposal_id = ?
				""")) {
			statement.setLong(1, disposalId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals("COMPLETED", result.getString("disposal_status"));
				assertEquals(itemId, result.getLong("asset_item_id"));
				assertEquals(1, result.getInt("quantity"));
				assertEquals("AVAILABLE", result.getString("asset_status"));
				assertTrue(result.getBoolean("asset_borrowable"));
				assertEquals(1, result.getInt("total_quantity"));
				assertEquals("DISPOSED", result.getString("item_status"));
				assertFalse(result.getBoolean("item_borrowable"));
			}
		}
	}

	@Test
	void quantityCompletionKeepsTheAggregateDisposalBehavior() throws Exception {
		long assetId = createAsset("QUANTITY", 2);
		long disposalId = requestAndApprove(assetId, null);

		dao.complete(disposalId, "Disposed aggregate test");

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT d.status AS disposal_status, d.asset_item_id, d.quantity,
				       a.status AS asset_status, a.is_borrowable AS asset_borrowable
				FROM dbo.disposal_records d
				JOIN dbo.assets a ON a.asset_id = d.asset_id
				WHERE d.disposal_id = ?
				""")) {
			statement.setLong(1, disposalId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals("COMPLETED", result.getString("disposal_status"));
				assertNull(nullableLong(result, "asset_item_id"));
				assertEquals(2, result.getInt("quantity"));
				assertEquals("DISPOSED", result.getString("asset_status"));
				assertFalse(result.getBoolean("asset_borrowable"));
			}
		}
	}

	@Test
	void activeUsageOfTheSelectedItemRollsBackCompletion() throws Exception {
		long assetId = createAsset("SERIALIZED", 1);
		long itemId = createItem(assetId, "BROKEN", "UNAVAILABLE", false);
		long disposalId = requestAndApprove(null, itemId);
		createActiveUsage(assetId, itemId);

		assertThrows(IllegalStateException.class, () -> dao.complete(disposalId, "Must not complete"));

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT d.status AS disposal_status, ai.status AS item_status, ai.is_borrowable AS item_borrowable
				FROM dbo.disposal_records d
				JOIN dbo.asset_items ai ON ai.asset_item_id = d.asset_item_id
				WHERE d.disposal_id = ?
				""")) {
			statement.setLong(1, disposalId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals("APPROVED", result.getString("disposal_status"));
				assertEquals("IN_USE", result.getString("item_status"));
				assertFalse(result.getBoolean("item_borrowable"));
			}
		}
	}

	private long requestAndApprove(Long assetId, Long itemId) throws SQLException {
		long disposalId = dao.create(userId("mentor@gmail.com"), assetId, itemId, "JUnit disposal request");
		disposalIds.add(disposalId);
		dao.review(disposalId, userId("manager@gmail.com"), true, "JUnit approved");
		return disposalId;
	}

	private long createAsset(String trackingMode, int quantity) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		String sql = """
				INSERT dbo.assets(asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
				 is_borrowable) OUTPUT INSERTED.asset_id
				SELECT ?, ?, MIN(category_id), ?, ?, 'GOOD', 'AVAILABLE', 1 FROM dbo.asset_categories
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, "JUNIT-DISPOSAL-" + suffix);
			statement.setString(2, "JUnit Disposal Asset " + suffix);
			statement.setString(3, trackingMode);
			statement.setInt(4, quantity);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next(), "Database needs at least one asset category");
				long assetId = result.getLong(1);
				assetIds.add(assetId);
				return assetId;
			}
		}
	}

	private long createItem(long assetId, String condition, String status, boolean borrowable) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		String sql = """
				INSERT dbo.asset_items(asset_id, item_code, serial_number, condition, status, is_borrowable)
				OUTPUT INSERTED.asset_item_id VALUES (?, ?, ?, ?, ?, ?)
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			statement.setString(2, "JUNIT-ITEM-" + suffix);
			statement.setString(3, "JUNIT-SERIAL-" + suffix);
			statement.setString(4, condition);
			statement.setString(5, status);
			statement.setBoolean(6, borrowable);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				long itemId = result.getLong(1);
				itemIds.add(itemId);
				return itemId;
			}
		}
	}

	private void createActiveUsage(long assetId, long itemId) throws SQLException {
		try (Connection connection = db.getConnection()) {
			Membership membership = membership(connection, userId("intern@gmail.com"));
			try (PreparedStatement statement = connection.prepareStatement(
					"""
							INSERT dbo.asset_usages(request_id, semester_id, intern_id, asset_id, asset_item_id, quantity,
							 borrowed_at, due_at, condition_before, status, created_by)
							OUTPUT INSERTED.asset_usage_id
							VALUES (?, ?, ?, ?, ?, 1, SYSUTCDATETIME(), DATEADD(day, 1, SYSUTCDATETIME()), 'BROKEN', 'IN_USE', ?)
							""")) {
				statement.setLong(1, membership.requestId());
				statement.setLong(2, membership.semesterId());
				statement.setLong(3, membership.internId());
				statement.setLong(4, assetId);
				statement.setLong(5, itemId);
				statement.setLong(6, membership.userId());
				try (ResultSet result = statement.executeQuery()) {
					assertTrue(result.next());
					usageIds.add(result.getLong(1));
				}
			}
			try (PreparedStatement statement = connection.prepareStatement(
					"UPDATE dbo.asset_items SET status = 'IN_USE', updated_at = SYSUTCDATETIME() WHERE asset_item_id = ?")) {
				statement.setLong(1, itemId);
				assertEquals(1, statement.executeUpdate());
			}
		}
	}

	private Membership membership(Connection connection, long userId) throws SQLException {
		String sql = """
				SELECT TOP 1 luri.request_id, luri.semester_id, luri.intern_id
				FROM dbo.intern_profiles ip
				JOIN dbo.lab_usage_request_interns luri ON luri.intern_id = ip.intern_id
				JOIN dbo.lab_usage_requests lur
				  ON lur.request_id = luri.request_id AND lur.semester_id = luri.semester_id
				JOIN dbo.semesters s ON s.semester_id = lur.semester_id
				WHERE ip.user_id = ? AND lur.status = 'APPROVED' AND s.status = 'ACTIVE'
				ORDER BY s.end_date
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next(), "Missing approved demo membership for intern@gmail.com");
				return new Membership(result.getLong(1), result.getLong(2), result.getLong(3), userId);
			}
		}
	}

	private long userId(String email) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement("SELECT user_id FROM dbo.users WHERE email = ?")) {
			statement.setString(1, email);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next(), "Missing demo account " + email);
				return result.getLong(1);
			}
		}
	}

	private void execute(Connection connection, String sql, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			statement.executeUpdate();
		}
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private record Membership(long requestId, long semesterId, long internId, long userId) {
	}
}
