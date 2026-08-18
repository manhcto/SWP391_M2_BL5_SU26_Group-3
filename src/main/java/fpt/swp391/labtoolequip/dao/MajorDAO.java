package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Major;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class MajorDAO {
	private final DBConnection dbConnection = new DBConnection();

	public List<Major> findActive() throws SQLException {
		String sql = """
				SELECT major_id, major_code, major_name, status, display_order
				FROM dbo.majors
				WHERE status = 'ACTIVE'
				ORDER BY display_order, major_name
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Major> majors = new ArrayList<>();
			while (result.next()) {
				Major major = new Major();
				major.setMajorId(result.getLong("major_id"));
				major.setMajorCode(result.getString("major_code"));
				major.setMajorName(result.getString("major_name"));
				major.setStatus(result.getString("status"));
				major.setDisplayOrder(result.getInt("display_order"));
				majors.add(major);
			}
			return majors;
		}
	}

	public boolean isActive(long majorId) throws SQLException {
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection
						.prepareStatement("SELECT 1 FROM dbo.majors WHERE major_id = ? AND status = 'ACTIVE'")) {
			statement.setLong(1, majorId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}
}
