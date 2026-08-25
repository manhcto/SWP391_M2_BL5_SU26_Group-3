package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class ResponsibilityDAOTest {
	@Test
	void permitsNoneAndUndeterminedWithoutAnIntern() {
		assertDoesNotThrow(() -> ResponsibilityDAO.validateAssessment("NONE", null, null, null));
		assertDoesNotThrow(() -> ResponsibilityDAO.validateAssessment("UNDETERMINED", null, "", ""));
	}

	@Test
	void requiresRelatedInternEvidenceAndRationaleForAccountableLevels() {
		assertDoesNotThrow(() -> ResponsibilityDAO.validateAssessment("PARTIAL", 12L, "Biên bản kiểm tra.",
				"Không tuân thủ quy trình."));
		assertDoesNotThrow(() -> ResponsibilityDAO.validateAssessment("FULL", 12L, "Video camera.",
				"Có đủ căn cứ xác định trách nhiệm."));

		assertThrows(IllegalArgumentException.class,
				() -> ResponsibilityDAO.validateAssessment("PARTIAL", null, "Biên bản kiểm tra.", "Có căn cứ."));
		assertThrows(IllegalArgumentException.class,
				() -> ResponsibilityDAO.validateAssessment("FULL", 12L, " ", "Có căn cứ."));
		assertThrows(IllegalArgumentException.class,
				() -> ResponsibilityDAO.validateAssessment("FULL", 12L, "Video camera.", " "));
	}

	@Test
	void rejectsUnknownResponsibilityLevels() {
		assertThrows(IllegalArgumentException.class,
				() -> ResponsibilityDAO.validateAssessment("ASSIGNED", 12L, "Bằng chứng.", "Lý do."));
	}

	@Test
	void labManagerMustChooseAnIntern() {
		assertDoesNotThrow(() -> ResponsibilityDAO.validateLabManagerAssignment("NONE", 12L, null, null));
		assertThrows(IllegalArgumentException.class,
				() -> ResponsibilityDAO.validateLabManagerAssignment("NONE", null, null, null));
	}
}
