package util;

import io.github.cdimascio.dotenv.Dotenv;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class AppConfig {
	private static Dotenv dotenv;

	static {
		try {
			Path currentPath = Paths.get(AppConfig.class.getProtectionDomain().getCodeSource().getLocation().toURI());

			if (Files.isRegularFile(currentPath)) {
				currentPath = currentPath.getParent();
			}

			String envDir = null;
			while (currentPath != null) {
				if (Files.exists(currentPath.resolve(".env"))) {
					envDir = currentPath.toString();
					break;
				}
				currentPath = currentPath.getParent();
			}

			dotenv = Dotenv.configure().directory(envDir != null ? envDir : "./").ignoreIfMissing().load();
		} catch (RuntimeException | URISyntaxException exception) {
			System.err.println("WARNING: COULD NOT LOAD ENVIRONMENT VARIABLES!");
		}
	}

	private AppConfig() {
	}

	public static String get(String key) {
		return dotenv != null ? dotenv.get(key) : null;
	}

	public static String get(String key, String defaultValue) {
		return dotenv != null ? dotenv.get(key, defaultValue) : defaultValue;
	}
}
