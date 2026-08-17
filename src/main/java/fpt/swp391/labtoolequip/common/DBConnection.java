package fpt.swp391.labtoolequip.common;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import util.AppConfig;

public class DBConnection {
	static {
		try {
			Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
		} catch (ClassNotFoundException exception) {
			throw new ExceptionInInitializerError(exception);
		}
	}

	private final String url = requiredSetting("DB_URL");
	private final String userId = requiredSetting("DB_USERNAME");
	private final String password = requiredSetting("DB_PASSWORD");

	public Connection getConnection() throws SQLException {
		return DriverManager.getConnection(url, userId, password);
	}

	private static String requiredSetting(String name) {
		String value = AppConfig.get(name);
		if (value == null || value.isBlank()) {
			throw new IllegalStateException("Thiếu cấu hình " + name + ".");
		}
		return value;
	}

	public static void main(String[] args) {
		try (Connection connection = new DBConnection().getConnection()) {
			System.out.println("Kết nối tới cơ sở dữ liệu LAB Asset THÀNH CÔNG!");
		} catch (Exception exception) {
			System.out.println("Kết nối THẤT BẠI: " + exception.getMessage());
		}
	}
}
