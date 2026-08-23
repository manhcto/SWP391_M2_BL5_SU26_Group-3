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

	@Test
	void retainsResponsibilityAssessmentFields() {
		Responsibility responsibility = new Responsibility();
		LocalDateTime assessedAt = LocalDateTime.of(2026, 8, 21, 10, 30);

		responsibility.setResponsibilityLevel("PARTIAL");
		responsibility.setEvidenceSummary("Camera và biên bản bàn giao.");
		responsibility.setResponsibilityNote("Không tuân thủ quy trình bảo quản.");
		responsibility.setHandlingRecommendation("Đề nghị bồi hoàn một phần.");
		responsibility.setResponsibilityAssessedBy(4L);
		responsibility.setResponsibilityAssessedAt(assessedAt);

		assertEquals("PARTIAL", responsibility.getResponsibilityLevel());
		assertEquals("Camera và biên bản bàn giao.", responsibility.getEvidenceSummary());
		assertEquals("Không tuân thủ quy trình bảo quản.", responsibility.getResponsibilityNote());
		assertEquals("Đề nghị bồi hoàn một phần.", responsibility.getHandlingRecommendation());
		assertEquals(4L, responsibility.getResponsibilityAssessedBy());
		assertEquals(assessedAt, responsibility.getResponsibilityAssessedAt());
	}
}
