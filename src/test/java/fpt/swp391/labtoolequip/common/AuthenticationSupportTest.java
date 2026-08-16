package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import fpt.swp391.labtoolequip.model.User;
import org.junit.jupiter.api.Test;

class AuthenticationSupportTest {
	@Test
	void redirectsEachRoleToItsOwnStartingDashboard() {
		assertEquals("/admin/dashboard", AuthenticationSupport.dashboardForRole("ADMIN"));
		assertEquals("/lab-manager/dashboard", AuthenticationSupport.dashboardForRole("LAB_MANAGER"));
		assertEquals("/mentor/dashboard", AuthenticationSupport.dashboardForRole("MENTOR"));
		assertEquals("/student/dashboard", AuthenticationSupport.dashboardForRole("STUDENT"));
	}

	@Test
	void unknownRoleFallsBackWithoutPuttingCredentialsInSession() {
		User databaseUser = new User();
		databaseUser.setUserId(12L);
		databaseUser.setEmail("mentor@example.com");
		databaseUser.setRole("UNKNOWN");
		databaseUser.setPasswordHash("secret-hash");
		databaseUser.setGoogleSubject("google-subject");

		User sessionUser = AuthenticationSupport.sessionCopy(databaseUser);

		assertEquals("/mentor/dashboard", AuthenticationSupport.dashboardForRole(databaseUser.getRole()));
		assertEquals("mentor@example.com", sessionUser.getEmail());
		assertNull(sessionUser.getPasswordHash());
		assertNull(sessionUser.getGoogleSubject());
	}
}
