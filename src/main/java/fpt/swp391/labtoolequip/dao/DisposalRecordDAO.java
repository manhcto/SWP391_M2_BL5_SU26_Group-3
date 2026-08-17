package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.DisposalRecord;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.time.ZoneId;
import java.time.ZoneOffset;
import util.AppConfig;

public class DisposalRecordDAO {
	private static final String SELECT = """
			SELECT d.*, a.asset_code, a.asset_name, u.full_name AS requester_name
			FROM dbo.disposal_records d JOIN dbo.assets a ON a.asset_id = d.asset_id
			JOIN dbo.users u ON u.user_id = d.requested_by
			""";
	private final DBConnection db = new DBConnection();
	private final ZoneId labZone = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));

	public List<DisposalRecord> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT + """
				WHERE (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ?)
				AND (? = '' OR d.status = ?) ORDER BY d.requested_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			statement.setString(2, "%" + search + "%");
			statement.setString(3, "%" + search + "%");
			statement.setString(4, state);
			statement.setString(5, state);
			return read(statement);
		}
	}

	public Optional<DisposalRecord> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT + " WHERE d.disposal_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<Asset> findEligibleAssets() throws SQLException {
		String sql = """
				SELECT asset_id, asset_code, asset_name, total_quantity FROM dbo.assets a
				WHERE status <> 'DISPOSED' AND NOT EXISTS
				(SELECT 1 FROM dbo.disposal_records d WHERE d.asset_id = a.asset_id AND d.status = 'PENDING')
				ORDER BY asset_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Asset> assets = new ArrayList<>();
			while (result.next()) {
				Asset asset = new Asset();
				asset.setAssetId(result.getLong(1));
				asset.setAssetCode(result.getString(2));
				asset.setAssetName(result.getString(3));
				asset.setTotalQuantity(result.getInt(4));
				assets.add(asset);
			}
			return assets;
		}
	}

	public long create(long userId, long assetId, String reason) throws SQLException {
		if (reason == null || reason.isBlank())
			throw new IllegalArgumentException("Reason is required.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				Asset asset = lockAsset(connection, assetId);
				if ("DISPOSED".equals(asset.getStatus()))
					throw new IllegalStateException("Asset is already disposed.");
				String sql = """
						INSERT dbo.disposal_records (asset_id, quantity, requested_by, reason, status)
						OUTPUT INSERTED.disposal_id VALUES (?, ?, ?, ?, 'PENDING')
						""";
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, assetId);
					statement.setInt(2, asset.getTotalQuantity());
					statement.setLong(3, userId);
					statement.setString(4, reason.trim());
					try (ResultSet result = statement.executeQuery()) {
						result.next();
						long id = result.getLong(1);
						connection.commit();
						return id;
					}
				}
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updatePending(long id, String reason) throws SQLException {
		if (reason == null || reason.isBlank())
			throw new IllegalArgumentException("Reason is required.");
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.disposal_records SET reason = ?, updated_at = SYSUTCDATETIME() WHERE disposal_id = ? AND status = 'PENDING'")) {
			statement.setString(1, reason.trim());
			statement.setLong(2, id);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Only pending disposal can be edited.");
		}
	}

	public void cancel(long id, String note) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.disposal_records SET status = 'CANCELLED', completion_note = ?, updated_at = SYSUTCDATETIME() WHERE disposal_id = ? AND status = 'PENDING'")) {
			statement.setString(1, blankToNull(note));
			statement.setLong(2, id);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Only pending disposal can be cancelled.");
		}
	}

	public void complete(long id, String note) throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long assetId = disposalAssetId(connection, id, false);
				Asset asset = lockAsset(connection, assetId);
				disposalAssetId(connection, id, true);
				if ("DISPOSED".equals(asset.getStatus()))
					throw new IllegalStateException("Asset is already disposed.");
				if (hasActiveUsage(connection, assetId))
					throw new IllegalStateException("Return all active usages before disposal.");
				try (PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.disposal_records SET status = 'COMPLETED', completed_at = SYSUTCDATETIME(), completion_note = ?, updated_at = SYSUTCDATETIME() WHERE disposal_id = ? AND status = 'PENDING'")) {
					statement.setString(1, blankToNull(note));
					statement.setLong(2, id);
					if (statement.executeUpdate() != 1)
						throw new IllegalStateException("Only pending disposal can be completed.");
				}
				try (PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.assets SET status = 'DISPOSED', is_borrowable = 0, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
					statement.setLong(1, assetId);
					statement.executeUpdate();
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private long disposalAssetId(Connection connection, long id, boolean lock) throws SQLException {
		String hint = lock ? " WITH (UPDLOCK, HOLDLOCK)" : "";
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_id FROM dbo.disposal_records" + hint + " WHERE disposal_id = ? AND status = 'PENDING'")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("Only pending disposal can be completed.");
				return result.getLong(1);
			}
		}
	}

	private Asset lockAsset(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT asset_id, total_quantity, status FROM dbo.assets WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ?")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Asset not found.");
				Asset asset = new Asset();
				asset.setAssetId(result.getLong(1));
				asset.setTotalQuantity(result.getInt(2));
				asset.setStatus(result.getString(3));
				return asset;
			}
		}
	}

	private boolean hasActiveUsage(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT 1 FROM dbo.asset_usages WHERE asset_id = ? AND status = 'IN_USE'")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private List<DisposalRecord> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<DisposalRecord> records = new ArrayList<>();
			while (result.next()) {
				DisposalRecord record = new DisposalRecord();
				record.setDisposalId(result.getLong("disposal_id"));
				record.setAssetId(result.getLong("asset_id"));
				record.setQuantity(result.getInt("quantity"));
				record.setRequestedBy(result.getLong("requested_by"));
				record.setReason(result.getString("reason"));
				record.setRequestedAt(time(result.getTimestamp("requested_at")));
				record.setStatus(result.getString("status"));
				record.setCompletedAt(time(result.getTimestamp("completed_at")));
				record.setCompletionNote(result.getString("completion_note"));
				record.setAssetCode(result.getString("asset_code"));
				record.setAssetName(result.getString("asset_name"));
				record.setRequesterName(result.getString("requester_name"));
				records.add(record);
			}
			return records;
		}
	}

	private java.time.LocalDateTime time(Timestamp timestamp) {
		return timestamp == null
				? null
				: timestamp.toLocalDateTime().atZone(ZoneOffset.UTC).withZoneSameInstant(labZone).toLocalDateTime();
	}
	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
