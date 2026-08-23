package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class MaintenanceDAOTest {
	@Test
	void requestRequiresOneExactAssetItem() {
		assertDoesNotThrow(() -> MaintenanceDAO.validateExactItemTarget(1L, 1));
		assertThrows(IllegalArgumentException.class, () -> MaintenanceDAO.validateExactItemTarget(null, 1));
		assertThrows(IllegalArgumentException.class, () -> MaintenanceDAO.validateExactItemTarget(1L, 2));
	}

	@Test
	void onlyAllowsDocumentedMaintenanceTransitions() {
		assertDoesNotThrow(() -> MaintenanceDAO.validateTransition("PENDING", "APPROVE"));
		assertDoesNotThrow(() -> MaintenanceDAO.validateTransition("PENDING", "REJECT"));
		assertDoesNotThrow(() -> MaintenanceDAO.validateTransition("APPROVED", "START"));
		assertDoesNotThrow(() -> MaintenanceDAO.validateTransition("IN_PROGRESS", "COMPLETE"));

		assertThrows(IllegalStateException.class, () -> MaintenanceDAO.validateTransition("PENDING", "START"));
		assertThrows(IllegalStateException.class, () -> MaintenanceDAO.validateTransition("APPROVED", "COMPLETE"));
		assertThrows(IllegalStateException.class, () -> MaintenanceDAO.validateTransition("COMPLETED", "START"));
	}

	@Test
	void completionMapsOnlyExplicitOutcomesToItemLifecycle() {
		assertEquals("AVAILABLE", MaintenanceDAO.completedItemStatus("SUCCESS"));
		assertEquals("UNAVAILABLE", MaintenanceDAO.completedItemStatus("FAILED"));
		assertThrows(IllegalArgumentException.class, () -> MaintenanceDAO.completedItemStatus("PENDING"));
		assertThrows(IllegalArgumentException.class, () -> MaintenanceDAO.completedItemStatus("UNKNOWN"));
	}
}
