package fpt.swp391.labtoolequip.controller.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AuthenticationThrottleTest {
	@Test
	void appliesExponentialBackoffAndClearsItAfterSuccess() {
		AuthenticationThrottle throttle = new AuthenticationThrottle();

		assertTrue(throttle.tryAcquire("127.0.0.1", 0));
		assertTrue(throttle.tryAcquire("127.0.0.1", 0));
		assertTrue(throttle.tryAcquire("127.0.0.1", 0));
		assertTrue(throttle.tryAcquire("127.0.0.1", 0));
		assertFalse(throttle.tryAcquire("127.0.0.1", 999));
		assertTrue(throttle.tryAcquire("127.0.0.1", 1_000));
		assertFalse(throttle.tryAcquire("127.0.0.1", 2_999));

		throttle.reset("127.0.0.1");
		assertTrue(throttle.tryAcquire("127.0.0.1", 2_999));
	}

	@Test
	void boundsEntriesAndExpiresIdleClients() {
		AuthenticationThrottle throttle = new AuthenticationThrottle();

		for (int i = 0; i <= AuthenticationThrottle.MAX_ENTRIES; i++)
			assertTrue(throttle.tryAcquire("client-" + i, 0));
		assertEquals(AuthenticationThrottle.MAX_ENTRIES, throttle.size());

		assertTrue(throttle.tryAcquire("new-client", AuthenticationThrottle.ENTRY_TTL_MILLIS));
		assertEquals(1, throttle.size());
	}
}
