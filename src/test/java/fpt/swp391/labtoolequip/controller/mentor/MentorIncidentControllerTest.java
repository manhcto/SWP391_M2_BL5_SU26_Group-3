package fpt.swp391.labtoolequip.controller.mentor;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import fpt.swp391.labtoolequip.model.AssetUsage;
import org.junit.jupiter.api.Test;

class MentorIncidentControllerTest {
	@Test
	void prioritizesOnlyDamagedReturnedUsages() {
		assertTrue(MentorIncidentController.shouldPrioritizeReturnedDamage(usage("RETURNED", "DAMAGED")));
		assertTrue(MentorIncidentController.shouldPrioritizeReturnedDamage(usage("RETURNED", "BROKEN")));
		assertFalse(MentorIncidentController.shouldPrioritizeReturnedDamage(usage("RETURNED", "GOOD")));
		assertFalse(MentorIncidentController.shouldPrioritizeReturnedDamage(usage("IN_USE", "DAMAGED")));
	}

	private AssetUsage usage(String status, String conditionAfter) {
		AssetUsage usage = new AssetUsage();
		usage.setStatus(status);
		usage.setConditionAfter(conditionAfter);
		return usage;
	}
}
