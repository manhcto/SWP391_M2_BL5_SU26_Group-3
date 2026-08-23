package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class MaintenanceDAOIntegrationTest {
	private MaintenanceDAO dao;
	private DBConnection db;
	private final List<Long> maintenanceIds = new ArrayList<>();
	private final List<Long> incidentIds = new ArrayList<>();
	private final List<Long> itemIds = new ArrayList<>();
	private final List<Long> assetIds = new ArrayList<>();
	private final List<Long> userIds = new ArrayList<>();

	@BeforeEach
	void requireFe08Schema() throws SQLException {
		try {
			db = new DBConnection();
			dao = new MaintenanceDAO();
			try (Connection connection = db.getConnection()) {
				Assumptions.assumeTrue(hasFe08Columns(connection),
						"FE-08 maintenance schema columns are not applied to this database.");
			}
		} catch (RuntimeException | SQLException exception) {
			db = null;
			Assumptions.abort("FE-08 integration database is unavailable: " + exception.getMessage());
		}
	}

	@AfterEach
	void cleanUp() throws SQLException {
		if (db == null) {
			return;
		}
		try (Connection connection = db.getConnection()) {
			for (long maintenanceId : maintenanceIds)
				execute(connection, "DELETE FROM dbo.maintenance_records WHERE maintenance_id = ?", maintenanceId);
			for (long incidentId : incidentIds)
				execute(connection, "DELETE FROM dbo.incidents WHERE incident_id = ?", incidentId);
			for (long itemId : itemIds)
				execute(connection, "DELETE FROM dbo.asset_items WHERE asset_item_id = ?", itemId);
			for (long assetId : assetIds)
				execute(connection, "DELETE FROM dbo.assets WHERE asset_id = ?", assetId);
			for (long userId : userIds)
				execute(connection, "DELETE FROM dbo.users WHERE user_id = ?", userId);
		}
	}

	@Test
	void successfulRepairChangesOnlyTargetItemAndPreservesHistory() throws Exception {
		Actors actors = createActors();
		long assetId = createAsset();
		long targetItemId = createItem(assetId, "BROKEN", "UNAVAILABLE");
		long siblingItemId = createItem(assetId, "GOOD", "AVAILABLE");
		long incidentId = createIncident(assetId, targetItemId, actors.mentorId());

		long maintenanceId = dao.createRequest(actors.mentorId(), targetItemId, incidentId, null,
				"Replace damaged part");
		maintenanceIds.add(maintenanceId);
		dao.approve(maintenanceId, actors.managerId(), "Repair approved");
		dao.start(maintenanceId, actors.managerId(), "Technician assigned");
		dao.complete(maintenanceId, actors.managerId(), "SUCCESS", "Part replaced and test passed",
				"Vendor technician");

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT m.status AS maintenance_status, m.repair_outcome, i.status AS incident_status,
				       target.status AS target_status, target.condition AS target_condition,
				       target.is_borrowable AS target_borrowable,
				       sibling.status AS sibling_status, sibling.condition AS sibling_condition,
				       a.status AS asset_status
				FROM dbo.maintenance_records m
				JOIN dbo.incidents i ON i.incident_id = m.incident_id
				JOIN dbo.asset_items target ON target.asset_item_id = m.asset_item_id
				JOIN dbo.asset_items sibling ON sibling.asset_item_id = ?
				JOIN dbo.assets a ON a.asset_id = m.asset_id
				WHERE m.maintenance_id = ?
				""")) {
			statement.setLong(1, siblingItemId);
			statement.setLong(2, maintenanceId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals("COMPLETED", result.getString("maintenance_status"));
				assertEquals("SUCCESS", result.getString("repair_outcome"));
				assertEquals("RESOLVED", result.getString("incident_status"));
				assertEquals("AVAILABLE", result.getString("target_status"));
				assertEquals("GOOD", result.getString("target_condition"));
				assertTrue(result.getBoolean("target_borrowable"));
				assertEquals("AVAILABLE", result.getString("sibling_status"));
				assertEquals("GOOD", result.getString("sibling_condition"));
				assertEquals("AVAILABLE", result.getString("asset_status"));
			}
		}
	}

	@Test
	void failedRepairLeavesIncidentOpenAndSiblingUntouched() throws Exception {
		Actors actors = createActors();
		long assetId = createAsset();
		long targetItemId = createItem(assetId, "BROKEN", "UNAVAILABLE");
		long siblingItemId = createItem(assetId, "GOOD", "AVAILABLE");
		long incidentId = createIncident(assetId, targetItemId, actors.mentorId());

		long maintenanceId = dao.createRequest(actors.mentorId(), targetItemId, incidentId, null, "Diagnose fault");
		maintenanceIds.add(maintenanceId);
		dao.approve(maintenanceId, actors.managerId(), "Repair approved");
		dao.start(maintenanceId, actors.managerId(), null);
		dao.complete(maintenanceId, actors.managerId(), "FAILED", "Board cannot be repaired", null);

		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				SELECT m.status AS maintenance_status, m.repair_outcome, i.status AS incident_status,
				       target.status AS target_status, target.condition AS target_condition,
				       target.is_borrowable AS target_borrowable,
				       sibling.status AS sibling_status, a.status AS asset_status
				FROM dbo.maintenance_records m
				JOIN dbo.incidents i ON i.incident_id = m.incident_id
				JOIN dbo.asset_items target ON target.asset_item_id = m.asset_item_id
				JOIN dbo.asset_items sibling ON sibling.asset_item_id = ?
				JOIN dbo.assets a ON a.asset_id = m.asset_id
				WHERE m.maintenance_id = ?
				""")) {
			statement.setLong(1, siblingItemId);
			statement.setLong(2, maintenanceId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				assertEquals("COMPLETED", result.getString("maintenance_status"));
				assertEquals("FAILED", result.getString("repair_outcome"));
				assertEquals("OPEN", result.getString("incident_status"));
				assertEquals("UNAVAILABLE", result.getString("target_status"));
				assertEquals("BROKEN", result.getString("target_condition"));
				assertTrue(!result.getBoolean("target_borrowable"));
				assertEquals("AVAILABLE", result.getString("sibling_status"));
				assertEquals("AVAILABLE", result.getString("asset_status"));
			}
		}
	}

	@Test
	void disposedTargetCannotEnterMaintenance() throws Exception {
		Actors actors = createActors();
		long assetId = createAsset();
		long targetItemId = createItem(assetId, "BROKEN", "UNAVAILABLE");
		long maintenanceId = dao.createRequest(actors.mentorId(), targetItemId, null, null, "Inspect target");
		maintenanceIds.add(maintenanceId);
		setItemStatus(targetItemId, "DISPOSED");

		assertThrows(IllegalStateException.class, () -> dao.approve(maintenanceId, actors.managerId(), "Approved"));
		assertEquals("PENDING", maintenanceStatus(maintenanceId));
		assertEquals("DISPOSED", itemStatus(targetItemId));
	}

	private Actors createActors() throws SQLException {
		return new Actors(createUser("MENTOR"), createUser("LAB_MANAGER"));
	}

	private long createUser(String role) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				INSERT dbo.users(full_name, email, role, status)
				OUTPUT INSERTED.user_id VALUES (?, ?, ?, 'ACTIVE')
				""")) {
			statement.setString(1, "JUnit " + role + " " + suffix);
			statement.setString(2, "junit-maintenance-" + role.toLowerCase() + "-" + suffix + "@example.test");
			statement.setString(3, role);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				long userId = result.getLong(1);
				userIds.add(userId);
				return userId;
			}
		}
	}

	private long createAsset() throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"""
								INSERT dbo.assets(asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status, is_borrowable)
								OUTPUT INSERTED.asset_id
								SELECT ?, ?, MIN(category_id), 'QUANTITY', 2, 'GOOD', 'AVAILABLE', 1 FROM dbo.asset_categories
								""")) {
			statement.setString(1, "JUNIT-MAINT-" + suffix);
			statement.setString(2, "JUnit Maintenance " + suffix);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next(), "Database needs at least one asset category");
				long assetId = result.getLong(1);
				assetIds.add(assetId);
				return assetId;
			}
		}
	}

	private long createItem(long assetId, String condition, String status) throws SQLException {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement("""
				INSERT dbo.asset_items(asset_id, item_code, serial_number, condition, status, is_borrowable)
				OUTPUT INSERTED.asset_item_id VALUES (?, ?, ?, ?, ?, 1)
				""")) {
			statement.setLong(1, assetId);
			statement.setString(2, "JUNIT-MAINT-ITEM-" + suffix);
			statement.setString(3, "JUNIT-MAINT-SERIAL-" + suffix);
			statement.setString(4, condition);
			statement.setString(5, status);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				long itemId = result.getLong(1);
				itemIds.add(itemId);
				return itemId;
			}
		}
	}

	private long createIncident(long assetId, long itemId, long reporterId) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"""
								INSERT dbo.incidents(asset_id, asset_item_id, reported_by, affected_quantity, incident_type, description, severity,
								 status, reported_cause)
								OUTPUT INSERTED.incident_id VALUES (?, ?, ?, 1, 'MALFUNCTION', 'JUnit maintenance incident', 'HIGH', 'OPEN', 'UNKNOWN')
								""")) {
			statement.setLong(1, assetId);
			statement.setLong(2, itemId);
			statement.setLong(3, reporterId);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				long incidentId = result.getLong(1);
				incidentIds.add(incidentId);
				return incidentId;
			}
		}
	}

	private void setItemStatus(long itemId, String status) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.asset_items SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_item_id = ?")) {
			statement.setString(1, status);
			statement.setLong(2, itemId);
			assertEquals(1, statement.executeUpdate());
		}
	}

	private String maintenanceStatus(long maintenanceId) throws SQLException {
		return scalar("SELECT status FROM dbo.maintenance_records WHERE maintenance_id = ?", maintenanceId);
	}

	private String itemStatus(long itemId) throws SQLException {
		return scalar("SELECT status FROM dbo.asset_items WHERE asset_item_id = ?", itemId);
	}

	private String scalar(String sql, long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				assertTrue(result.next());
				return result.getString(1);
			}
		}
	}

	private void execute(Connection connection, String sql, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			statement.executeUpdate();
		}
	}

	private boolean hasFe08Columns(Connection connection) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT CASE WHEN COL_LENGTH('dbo.maintenance_records', 'asset_item_id') IS NOT NULL
				                  AND COL_LENGTH('dbo.maintenance_records', 'assessment_id') IS NOT NULL
				                  AND COL_LENGTH('dbo.maintenance_records', 'repair_outcome') IS NOT NULL
				            THEN 1 ELSE 0 END
				""")) {
			try (ResultSet result = statement.executeQuery()) {
				return result.next() && result.getInt(1) == 1;
			}
		}
	}

	private record Actors(long mentorId, long managerId) {
	}
}
