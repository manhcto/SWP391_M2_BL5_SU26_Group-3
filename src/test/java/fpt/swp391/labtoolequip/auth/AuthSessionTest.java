package fpt.swp391.labtoolequip.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AuthSessionTest {
	@Test
	void mapsEachRoleToItsDashboard() {
		assertEquals("/app/admin/dashboard", AuthSession.dashboard("/app", "ADMIN"));
		assertEquals("/app/lab-manager/dashboard", AuthSession.dashboard("/app", "LAB_MANAGER"));
		assertEquals("/app/mentor/dashboard", AuthSession.dashboard("/app", "MENTOR"));
		assertEquals("/app/intern/dashboard", AuthSession.dashboard("/app", "INTERN"));
	}

	@Test
	void sendsUnknownRoleToLogin() {
		assertEquals("/app/login", AuthSession.dashboard("/app", "VISITOR"));
		assertEquals("/app/login", AuthSession.dashboard("/app", null));
	}

	@Test
	void authorizesInternForInternRoutes() {
		assertTrue(AuthorizationFilter.isAuthorized(Permission.DASHBOARD_INTERN, "INTERN"));
	}
}
