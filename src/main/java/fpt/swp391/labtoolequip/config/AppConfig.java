package fpt.swp391.labtoolequip.config;

import io.github.cdimascio.dotenv.Dotenv;

/** Reads configuration from OS environment variables or a local .env file. */
public final class AppConfig {
	private static final Dotenv DOTENV = Dotenv.configure().ignoreIfMissing().load();

	private AppConfig() {
	}

	public static String get(String key) {
		return DOTENV.get(key);
	}

	public static String get(String key, String defaultValue) {
		return DOTENV.get(key, defaultValue);
	}
}
