package fpt.swp391.labtoolequip.controller.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ChangePasswordControllerTest {
	@Test
	void acceptsEightToSeventyTwoUtf8Bytes() {
		assertFalse(ChangePasswordController.validNewPassword("1234567"));
		assertTrue(ChangePasswordController.validNewPassword("12345678"));
		assertTrue(ChangePasswordController.validNewPassword("a".repeat(72)));
		assertFalse(ChangePasswordController.validNewPassword("a".repeat(73)));
		assertTrue(ChangePasswordController.validNewPassword("mật-khẩu"));
		assertFalse(ChangePasswordController.validNewPassword("ộ".repeat(37)));
	}
}
