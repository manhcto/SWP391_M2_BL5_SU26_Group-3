package fpt.swp391.labtoolequip.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AuthSessionTest {
	@Test
	void mapsInternToItsDashboard() {
		assertEquals("/app/intern/dashboard", AuthSession.dashboard("/app", "INTERN"));
	}

	@Test
	void authorizesInternForInternRoutes() {
		assertTrue(AuthorizationFilter.isAuthorized(Permission.DASHBOARD_INTERN, "INTERN"));
	}
}
