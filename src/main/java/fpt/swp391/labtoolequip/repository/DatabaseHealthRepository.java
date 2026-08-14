package fpt.swp391.labtoolequip.repository;

import fpt.swp391.labtoolequip.config.DatabaseConnection;
import java.sql.Connection;
import java.sql.SQLException;

/** Performs the smallest possible database connectivity check. */
public class DatabaseHealthRepository {
	public boolean isConnected() throws SQLException {
		try (Connection connection = DatabaseConnection.open()) {
			return connection.isValid(5);
		}
	}
}
