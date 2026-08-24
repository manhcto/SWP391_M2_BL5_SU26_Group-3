package fpt.swp391.labtoolequip.controller.auth;

import java.util.Iterator;
import java.util.LinkedHashMap;

final class AuthenticationThrottle {
	// ponytail: single-node remote-address limit; use a shared store with trusted
	// proxy identity when scaling out.
	static final int MAX_ENTRIES = 512;
	static final long ENTRY_TTL_MILLIS = 15 * 60 * 1000L;
	private static final int FREE_ATTEMPTS = 3;
	private static final int MAX_DELAY_EXPONENT = 6;
	private static final long MAX_DELAY_MILLIS = 60 * 1000L;

	private final LinkedHashMap<String, Entry> entries = new LinkedHashMap<>(16, 0.75f, true);

	synchronized boolean tryAcquire(String key) {
		return tryAcquire(key, System.currentTimeMillis());
	}

	synchronized boolean tryAcquire(String key, long now) {
		removeExpired(now);
		Entry entry = entries.get(key);
		if (entry != null && now < entry.nextAllowedAt)
			return false;
		if (entry == null) {
			if (entries.size() == MAX_ENTRIES)
				entries.remove(entries.keySet().iterator().next());
			entry = new Entry();
			entries.put(key, entry);
		}
		entry.attempts = Math.min(entry.attempts + 1, FREE_ATTEMPTS + MAX_DELAY_EXPONENT + 1);
		entry.lastAttemptAt = now;
		entry.nextAllowedAt = now + delay(entry.attempts);
		return true;
	}

	synchronized void reset(String key) {
		entries.remove(key);
	}

	synchronized int size() {
		return entries.size();
	}

	private void removeExpired(long now) {
		Iterator<Entry> iterator = entries.values().iterator();
		while (iterator.hasNext()) {
			if (now - iterator.next().lastAttemptAt >= ENTRY_TTL_MILLIS)
				iterator.remove();
		}
	}

	private long delay(int attempts) {
		int exponent = attempts - FREE_ATTEMPTS - 1;
		return exponent < 0 ? 0 : Math.min(1_000L << Math.min(exponent, MAX_DELAY_EXPONENT), MAX_DELAY_MILLIS);
	}

	private static final class Entry {
		private int attempts;
		private long lastAttemptAt;
		private long nextAllowedAt;
	}
}
