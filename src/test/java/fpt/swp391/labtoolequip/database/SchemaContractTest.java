package fpt.swp391.labtoolequip.database;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class SchemaContractTest {
	@Test
	void assetUsageBootstrapUsesCanonicalLifecycleColumns() throws IOException {
		String schema = Files.readString(Path.of("database", "lab_asset_management_full.sql"));
		String assetUsages = schema.substring(schema.indexOf("CREATE TABLE dbo.asset_usages"),
				schema.indexOf("CREATE TABLE dbo.inspection_records"));

		assertTrue(assetUsages.contains("student_id bigint NOT NULL"));
		assertFalse(assetUsages.contains("intern_id"));
		assertTrue(assetUsages.contains("'RETURN_PENDING'"));
		assertFalse(assetUsages.contains("'MAINTENANCE'"));
	}

	@Test
	void lifecycleBootstrapContainsIncidentResponsibilityAndMaintenanceContracts() throws IOException {
		String schema = Files.readString(Path.of("database", "lab_asset_management_full.sql"));
		assertTrue(schema.contains("reviewed_by bigint NULL"));
		assertTrue(schema.contains("technical_cause varchar(30) NULL"));
		assertTrue(schema.contains("responsibility_level varchar(15) NULL"));
		assertTrue(schema.contains("repair_outcome varchar(10) NOT NULL"));
		assertTrue(schema.contains("UX_maintenance_records_active_asset_item"));
	}
}
