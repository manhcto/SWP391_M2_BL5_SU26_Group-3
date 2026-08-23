package fpt.swp391.labtoolequip.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class MaintenanceAuthorizationTest {
	@Test
	void grantsMaintenanceRequestToMentorAndProcessingToLabManagerOnly() {
		assertTrue(Authorization.has("MENTOR", Permission.MAINTENANCE_VIEW));
		assertTrue(Authorization.has("MENTOR", Permission.MAINTENANCE_REQUEST));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.MAINTENANCE_VIEW));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.MAINTENANCE_PROCESS));

		assertFalse(Authorization.has("LAB_MANAGER", Permission.MAINTENANCE_REQUEST));
		assertFalse(Authorization.has("MENTOR", Permission.MAINTENANCE_PROCESS));
		assertFalse(Authorization.has("ADMIN", Permission.MAINTENANCE_PROCESS));
		assertFalse(Authorization.has("INTERN", Permission.MAINTENANCE_REQUEST));
	}
}
