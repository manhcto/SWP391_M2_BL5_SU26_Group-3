package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.common.ViewFormat;
import org.junit.jupiter.api.Test;

class IncidentDAOTest {
	@Test
	void acceptsReportedSeverityWithDescription() {
		assertDoesNotThrow(() -> IncidentDAO.validateReport("DAMAGE", "LOW", "Thiết bị có dấu hiệu bất thường.",
				ViewFormat.now().minusMinutes(1)));
		assertDoesNotThrow(() -> IncidentDAO.validateReport("DAMAGE", "HIGH", "Thiết bị không thể hoạt động.",
				ViewFormat.now().minusMinutes(1)));
		assertDoesNotThrow(() -> IncidentDAO.validateReport("LOSS", "CRITICAL", "Không tìm thấy thiết bị.", null));
	}

	@Test
	void rejectsUnknownReportedSeverity() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> IncidentDAO.validateReport("DAMAGE", "URGENT", "Lỏng giắc cắm.", null));

		assertEquals("Mức độ sự cố không hợp lệ.", exception.getMessage());
	}

	@Test
	void rejectsBlankDescriptionsAndFutureOccurrenceTime() {
		assertThrows(IllegalArgumentException.class, () -> IncidentDAO.validateReport("DAMAGE", "HIGH", " ", null));
		assertThrows(IllegalArgumentException.class,
				() -> IncidentDAO.validateReport("DAMAGE", "HIGH", "Mô tả hợp lệ.", ViewFormat.now().plusMinutes(1)));
	}

	@Test
	void permitsOnlyOrderedLabManagerTransitions() {
		assertEquals("INVESTIGATING", IncidentDAO.nextLabManagerStatus("FORWARDED"));
		assertEquals("RESOLVED", IncidentDAO.nextLabManagerStatus("INVESTIGATING"));
		assertEquals("CLOSED", IncidentDAO.nextLabManagerStatus("RESOLVED"));
		assertNull(IncidentDAO.nextLabManagerStatus("REPORTED"));
		assertNull(IncidentDAO.nextLabManagerStatus("OPEN"));
		assertThrows(IllegalArgumentException.class,
				() -> IncidentDAO.validateLabManagerTransition("FORWARDED", "RESOLVED"));
	}

	@Test
	void requiresReviewNoteAndCompleteTechnicalResolution() {
		assertThrows(IllegalArgumentException.class, () -> IncidentDAO.validateMentorReviewNote(" "));
		assertThrows(IllegalArgumentException.class, () -> IncidentDAO.validateTechnicalAssessment("RESOLVED",
				"EQUIPMENT_FAILURE", "MAJOR", "REPAIRABLE", "MAINTENANCE", " ", "Đã thay linh kiện."));
		assertDoesNotThrow(() -> IncidentDAO.validateTechnicalAssessment("RESOLVED", "EQUIPMENT_FAILURE", "MAJOR",
				"REPAIRABLE", "MAINTENANCE", "Bo nguồn hỏng, cần thay thế.", "Đã thay linh kiện."));
	}
}
