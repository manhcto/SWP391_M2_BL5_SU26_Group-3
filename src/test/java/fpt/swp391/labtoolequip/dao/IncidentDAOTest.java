package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.common.ViewFormat;
import org.junit.jupiter.api.Test;

class IncidentDAOTest {
	@Test
	void acceptsHighOrCriticalReportsWithDescription() {
		assertDoesNotThrow(() -> IncidentDAO.validateReport("DAMAGE", "HIGH", "Thiết bị không thể hoạt động.",
				ViewFormat.now().minusMinutes(1)));
		assertDoesNotThrow(() -> IncidentDAO.validateReport("LOSS", "CRITICAL", "Không tìm thấy thiết bị.", null));
	}

	@Test
	void rejectsMinorReportsBecauseMentorHandlesThemDirectly() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> IncidentDAO.validateReport("DAMAGE", "LOW", "Lỏng giắc cắm.", null));

		assertEquals("Chỉ gửi báo cáo sự cố mức cao hoặc nghiêm trọng cho Lab Manager.", exception.getMessage());
	}

	@Test
	void rejectsBlankDescriptionsAndFutureOccurrenceTime() {
		assertThrows(IllegalArgumentException.class,
				() -> IncidentDAO.validateReport("DAMAGE", "HIGH", " ", null));
		assertThrows(IllegalArgumentException.class, () -> IncidentDAO.validateReport("DAMAGE", "HIGH", "Mô tả hợp lệ.",
				ViewFormat.now().plusMinutes(1)));
	}
}
