package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class EmailHelperTest {
	@Test
	void createsStudentEmailWithoutVietnameseDiacritics() {
		assertEquals("anhnmse160123@fpt.edu.vn", EmailHelper.generateFptEmail("Nguyễn Minh Anh", "SE-160123", true));
	}

	@Test
	void omitsCodeForMentorAndHandlesBlankName() {
		assertEquals("dungpq@fpt.edu.vn", EmailHelper.generateFptEmail("Phạm Quang Dũng", "ME-01", false));
		assertEquals("", EmailHelper.generateFptEmail("   ", "SE160123", true));
		assertEquals("", EmailHelper.generateFptEmail(null, "SE160123", true));
	}
}
