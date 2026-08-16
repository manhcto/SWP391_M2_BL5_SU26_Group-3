package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Asset;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class AssetDAO {
	private final DBConnection dbConnection = new DBConnection();

	public List<Asset> findAll() throws SQLException {
		String sql = "SELECT asset_id, asset_code, asset_name, category_id, serial_number, status, storage_location FROM dbo.assets ORDER BY asset_name ASC";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Asset> list = new ArrayList<>();
			while (result.next()) {
				Asset a = new Asset();
				a.setAssetId(result.getLong("asset_id"));
				a.setAssetCode(result.getString("asset_code"));
				a.setAssetName(result.getString("asset_name"));
				a.setCategoryId(result.getLong("category_id"));
				a.setSerialNumber(result.getString("serial_number"));
				a.setStatus(result.getString("status"));
				a.setStorageLocation(result.getString("storage_location"));
				list.add(a);
			}
			return list;
		}
	}

	public Optional<Asset> findById(long assetId) throws SQLException {
		String sql = "SELECT asset_id, asset_code, asset_name, category_id, serial_number, status, storage_location FROM dbo.assets WHERE asset_id = ?";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next()) {
					Asset a = new Asset();
					a.setAssetId(result.getLong("asset_id"));
					a.setAssetCode(result.getString("asset_code"));
					a.setAssetName(result.getString("asset_name"));
					a.setCategoryId(result.getLong("category_id"));
					a.setSerialNumber(result.getString("serial_number"));
					a.setStatus(result.getString("status"));
					a.setStorageLocation(result.getString("storage_location"));
					return Optional.of(a);
				}
				return Optional.empty();
			}
		}
	}

	public boolean updateStatus(long assetId, String status) throws SQLException {
		String sql = "UPDATE dbo.assets SET status = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status);
			statement.setLong(2, assetId);
			return statement.executeUpdate() == 1;
		}
	}
}
