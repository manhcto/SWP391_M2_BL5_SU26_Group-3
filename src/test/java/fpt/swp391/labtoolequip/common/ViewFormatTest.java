package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;

class ViewFormatTest {
	@Test
	void convertsUtcDatabaseTimeToVietnamTime() {
		Timestamp utc = Timestamp.valueOf("2026-08-18 00:00:00");

		LocalDateTime vietnamTime = ViewFormat.fromUtc(utc);

		assertEquals(LocalDateTime.of(2026, 8, 18, 7, 0), vietnamTime);
		assertEquals("18/08/2026 07:00", ViewFormat.dateTime(vietnamTime));
		assertEquals(utc, ViewFormat.toUtc(vietnamTime));
	}

	@Test
	void translatesStoredCodesWithoutChangingThem() {
		assertEquals("Đang sử dụng", ViewFormat.label("IN_USE"));
		assertEquals("Quản lý phòng LAB", ViewFormat.label("LAB_MANAGER"));
		assertEquals("Rác thải điện tử", ViewFormat.label("E_WASTE"));
		assertEquals("Phế liệu", ViewFormat.label("SCRAP"));
		assertEquals("Trả nhà cung cấp", ViewFormat.label("RETURN_TO_VENDOR"));
	}
}
