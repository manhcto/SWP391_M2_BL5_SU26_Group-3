package fpt.swp391.labtoolequip.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AuthorizationTest {
	@Test
	void followsBusinessPermissionMatrix() {
		assertTrue(Authorization.has("ADMIN", Permission.USER_MANAGE));
		assertTrue(Authorization.has("MENTOR", Permission.DISPOSAL_REQUEST));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.ASSET_MANAGE));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.DISPOSAL_REVIEW));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.DISPOSAL_COMPLETE));
		assertTrue(Authorization.has("INTERN", Permission.ASSET_USAGE_BORROW));
		assertTrue(Authorization.has("INTERN", Permission.INCIDENT_REPORT));
		assertTrue(Authorization.has("MENTOR", Permission.INCIDENT_REVIEW));
		assertTrue(Authorization.has("MENTOR", Permission.RESPONSIBILITY_ASSESS));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.RESPONSIBILITY_ASSESS));
		assertTrue(Authorization.has("LAB_MANAGER", Permission.INCIDENT_RESOLVE));

		assertFalse(Authorization.has("ADMIN", Permission.DISPOSAL_REVIEW));
		assertFalse(Authorization.has("MENTOR", Permission.ASSET_MANAGE));
		assertFalse(Authorization.has("MENTOR", Permission.DISPOSAL_REVIEW));
		assertFalse(Authorization.has("MENTOR", Permission.DISPOSAL_COMPLETE));
		assertFalse(Authorization.has("LAB_MANAGER", Permission.DISPOSAL_REQUEST));
		assertFalse(Authorization.has("INTERN", Permission.USER_MANAGE));
	}

	@Test
	void dashboardPermissionsDoNotCrossRoles() {
		assertTrue(Authorization.has("ADMIN", Permission.DASHBOARD_ADMIN));
		assertFalse(Authorization.has("MENTOR", Permission.DASHBOARD_ADMIN));
		assertFalse(Authorization.has("LAB_MANAGER", Permission.DASHBOARD_MENTOR));
	}

	@Test
	void protectsEveryUnsafeMethodWithCsrf() {
		assertFalse(AuthorizationFilter.isUnsafe("GET"));
		assertFalse(AuthorizationFilter.isUnsafe("HEAD"));
		assertFalse(AuthorizationFilter.isUnsafe("OPTIONS"));
		assertTrue(AuthorizationFilter.isUnsafe("POST"));
		assertTrue(AuthorizationFilter.isUnsafe("PUT"));
		assertTrue(AuthorizationFilter.isUnsafe("PATCH"));
		assertTrue(AuthorizationFilter.isUnsafe("DELETE"));
	}

	@Test
	void temporaryPasswordSessionCanOnlyChangePasswordOrLogout() {
		assertTrue(AuthorizationFilter.allowsPasswordChange("/change-password"));
		assertTrue(AuthorizationFilter.allowsPasswordChange("/logout"));
		assertFalse(AuthorizationFilter.allowsPasswordChange("/password-reset"));
		assertFalse(AuthorizationFilter.allowsPasswordChange("/admin/dashboard"));
	}
}
