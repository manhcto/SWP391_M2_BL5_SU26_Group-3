package fpt.swp391.labtoolequip.controller.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.User;
import org.junit.jupiter.api.Test;

class LoginControllerTest {
	private static final String PASSWORD_HASH = "$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C";

	@Test
	void acceptsOnlyTheCorrectPasswordForAnActiveAccount() {
		User user = new User();
		user.setStatus("ACTIVE");
		user.setPasswordHash(PASSWORD_HASH);

		assertTrue(LoginController.validPassword(user, "123"));
		assertFalse(LoginController.validPassword(user, "wrong"));

		user.setStatus("INACTIVE");
		assertFalse(LoginController.validPassword(user, "123"));
	}

	@Test
	void rejectsInternAndExpiredTemporaryPasswordForInternalLogin() {
		User user = new User();
		user.setStatus("ACTIVE");
		user.setPasswordHash(PASSWORD_HASH);
		user.setRole("INTERN");
		assertFalse(LoginController.validInternalPassword(user, "123"));

		user.setRole("MENTOR");
		user.setMustChangePassword(true);
		user.setPasswordExpiresAt(ViewFormat.now().minusMinutes(1));
		assertFalse(LoginController.validInternalPassword(user, "123"));

		user.setPasswordExpiresAt(ViewFormat.now().plusMinutes(1));
		assertTrue(LoginController.validInternalPassword(user, "123"));
	}
}
