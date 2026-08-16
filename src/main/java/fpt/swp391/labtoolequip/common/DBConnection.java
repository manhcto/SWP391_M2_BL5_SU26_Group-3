package fpt.swp391.labtoolequip.common;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

	private static final String URL = "jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true";
	private static final String USERNAME = "minhanh";
	private static final String PASSWORD = "123";

	static {
		try {
			Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
		} catch (ClassNotFoundException exception) {
			throw new ExceptionInInitializerError(exception);
		}
	}

	public Connection getConnection() throws SQLException {
		return DriverManager.getConnection(URL, USERNAME, PASSWORD);
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
