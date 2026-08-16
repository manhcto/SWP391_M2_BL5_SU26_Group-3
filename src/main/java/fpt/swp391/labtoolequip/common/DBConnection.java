package fpt.swp391.labtoolequip.common;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

public class DBConnection {
	private static final Map<String, String> ENV_FILE_CACHE = new HashMap<>();

	static {
		try {
			Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
		} catch (ClassNotFoundException exception) {
			throw new ExceptionInInitializerError(exception);
		}
		loadDotEnv();
	}

	private final String url = getSetting("DB_URL",
			"jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true");
	private final String userId = getSetting("DB_USERNAME", "sa");
	private final String password = getSetting("DB_PASSWORD", "123456");

	public Connection getConnection() throws SQLException {
		return DriverManager.getConnection(url, userId, password);
	}

	private static void loadDotEnv() {
		File envFile = new File(".env");
		if (!envFile.exists()) {
			envFile = new File(System.getProperty("user.dir"), ".env");
		}
		if (envFile.exists()) {
			try (BufferedReader reader = new BufferedReader(new FileReader(envFile))) {
				String line;
				while ((line = reader.readLine()) != null) {
					line = line.trim();
					if (line.isEmpty() || line.startsWith("#"))
						continue;
					int eqIdx = line.indexOf('=');
					if (eqIdx > 0) {
						String k = line.substring(0, eqIdx).trim();
						String v = line.substring(eqIdx + 1).trim();
						ENV_FILE_CACHE.put(k, v);
					}
				}
			} catch (IOException ignored) {
			}
		}
	}

	private static String getSetting(String name, String defaultValue) {
		String value = System.getenv(name);
		if (value == null || value.isBlank()) {
			value = System.getProperty(name);
		}
		if (value == null || value.isBlank()) {
			value = ENV_FILE_CACHE.get(name);
		}
		if (value == null || value.isBlank()) {
			return defaultValue;
		}
		return value;
	}

	public static void main(String[] args) {
		try (Connection connection = new DBConnection().getConnection();
				Statement statement = connection.createStatement();
				ResultSet result = statement.executeQuery("SELECT 1")) {
			if (!result.next() || result.getInt(1) != 1) {
				throw new SQLException("Database không phản hồi truy vấn kiểm tra.");
			}
			System.out.println("Kết nối tới cơ sở dữ liệu LAB Asset THÀNH CÔNG!");
		} catch (Exception exception) {
			System.out.println("Kết nối THẤT BẠI: " + exception.getMessage());
		}
	}
}
