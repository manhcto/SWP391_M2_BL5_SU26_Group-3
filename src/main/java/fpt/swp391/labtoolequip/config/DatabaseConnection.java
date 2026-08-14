package fpt.swp391.labtoolequip.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/** Creates SQL Server connections from environment configuration. */
public final class DatabaseConnection {
	private DatabaseConnection() {
	}

	public static Connection open() throws SQLException {
		String url = required("DB_URL");
		String username = required("DB_USERNAME");
		String password = required("DB_PASSWORD");
		return DriverManager.getConnection(url, username, password);
	}

	private static String required(String key) throws SQLException {
		String value = AppConfig.get(key);
		if (value == null || value.isBlank()) {
			throw new SQLException("Missing required configuration: " + key);
		}
		return value;
	}
}
