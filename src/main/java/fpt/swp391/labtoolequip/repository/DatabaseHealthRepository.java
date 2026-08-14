package fpt.swp391.labtoolequip.repository;

import fpt.swp391.labtoolequip.config.DatabaseConnection;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/** Performs the smallest possible database connectivity check. */
public class DatabaseHealthRepository {
	public boolean isConnected() throws SQLException {
		try (Connection connection = DatabaseConnection.open();
				Statement statement = connection.createStatement();
				ResultSet result = statement.executeQuery("SELECT 1")) {
			return result.next() && result.getInt(1) == 1;
		}
	}
}
