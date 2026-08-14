package fpt.swp391.labtoolequip.service;

import fpt.swp391.labtoolequip.model.DatabaseStatus;
import fpt.swp391.labtoolequip.repository.DatabaseHealthRepository;
import java.sql.SQLException;

/**
 * Checks database availability without exposing credentials or driver errors.
 */
public class DatabaseHealthService {
	private final DatabaseHealthRepository repository = new DatabaseHealthRepository();

	public DatabaseStatus check() throws SQLException {
		boolean connected = repository.isConnected();
		return new DatabaseStatus(connected, connected ? "Kết nối database thành công." : "Kết nối database thất bại.");
	}
}
