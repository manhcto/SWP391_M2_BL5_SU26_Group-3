package fpt.swp391.labtoolequip.model;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;

class ResponsibilityTest {
	@Test
	void formatsResponsibilityAndIncidentCodesFromDatabaseIdsAndDates() {
		Responsibility responsibility = new Responsibility();
		responsibility.setResponsibilityId(8L);
		responsibility.setDeterminedAt(LocalDateTime.of(2026, 8, 17, 9, 0));
		responsibility.setIncidentId(15L);
		responsibility.setReportedAt(LocalDateTime.of(2026, 8, 16, 15, 5));

		assertEquals("RES-2026-008", responsibility.getResponsibilityCode());
		assertEquals("INC-2026-015", responsibility.getIncidentCode());
	}
}
