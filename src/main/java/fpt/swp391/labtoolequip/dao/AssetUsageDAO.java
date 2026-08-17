package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.AssetUsage;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import util.AppConfig;

public class AssetUsageDAO {
	private static final String SELECT_USAGE = """
			SELECT au.*, a.asset_code, a.asset_name, u.full_name AS student_name
			FROM dbo.asset_usages au
			JOIN dbo.assets a ON a.asset_id = au.asset_id
			JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
			JOIN dbo.users u ON u.user_id = sp.user_id
			""";
	private final DBConnection db = new DBConnection();
	private final ZoneId labZone = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));

	public List<AssetUsage> findForStudent(long userId) throws SQLException {
		return find(SELECT_USAGE + " WHERE sp.user_id = ? ORDER BY au.borrowed_at DESC", userId);
	}

	public List<AssetUsage> findAll(String keyword, String status) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT_USAGE + """
				WHERE (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR u.full_name LIKE ?)
				  AND (? = '' OR au.status = ?)
				ORDER BY au.borrowed_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			statement.setString(2, "%" + search + "%");
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, state);
			statement.setString(6, state);
			return readUsages(statement);
		}
	}

	public Optional<AssetUsage> findById(long usageId, Long ownerUserId) throws SQLException {
		String sql = SELECT_USAGE + " WHERE au.asset_usage_id = ?" + (ownerUserId == null ? "" : " AND sp.user_id = ?");
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			if (ownerUserId != null)
				statement.setLong(2, ownerUserId);
			List<AssetUsage> usages = readUsages(statement);
			return usages.stream().findFirst();
		}
	}

	public List<Asset> findBorrowableAssets() throws SQLException {
		String sql = """
				SELECT a.asset_id, a.asset_code, a.asset_name, a.total_quantity, a.condition
				FROM dbo.assets a
				WHERE a.status = 'AVAILABLE' AND a.is_borrowable = 1
				  AND NOT EXISTS (SELECT 1 FROM dbo.disposal_records d WHERE d.asset_id = a.asset_id AND d.status = 'PENDING')
				ORDER BY a.asset_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Asset> assets = new ArrayList<>();
			while (result.next()) {
				Asset asset = new Asset();
				asset.setAssetId(result.getLong("asset_id"));
				asset.setAssetCode(result.getString("asset_code"));
				asset.setAssetName(result.getString("asset_name"));
				asset.setTotalQuantity(result.getInt("total_quantity"));
				asset.setCondition(result.getString("condition"));
				assets.add(asset);
			}
			return assets;
		}
	}

	public long borrow(long userId, long assetId, int quantity, String note) throws SQLException {
		if (quantity <= 0)
			throw new IllegalArgumentException("Quantity must be greater than zero.");
		ZonedDateTime now = ZonedDateTime.now(labZone);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				Asset asset = lockAsset(connection, assetId);
				if (!"AVAILABLE".equals(asset.getStatus()) || !Boolean.TRUE.equals(asset.getBorrowable()))
					throw new IllegalStateException("Asset is not available for borrowing.");
				if (hasPendingDisposal(connection, assetId))
					throw new IllegalStateException("Asset has a pending disposal.");
				Membership membership = currentMembership(connection, userId, now);
				int active = activeQuantity(connection, assetId);
				if (active + quantity > asset.getTotalQuantity())
					throw new IllegalStateException("Insufficient available quantity.");
				long id = insertUsage(connection, userId, asset, quantity, note, membership, now);
				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void returnUsage(long userId, long usageId, String conditionAfter, String note) throws SQLException {
		if (!List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(conditionAfter))
			throw new IllegalArgumentException("A valid return condition is required.");
		String sql = """
				UPDATE au WITH (UPDLOCK, ROWLOCK)
				SET returned_at = SYSUTCDATETIME(), condition_after = ?, note = ?, status = 'RETURNED', updated_at = SYSUTCDATETIME()
				FROM dbo.asset_usages au
				JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
				WHERE au.asset_usage_id = ? AND sp.user_id = ? AND au.status = 'IN_USE' AND au.returned_at IS NULL
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, conditionAfter);
			statement.setString(2, blankToNull(note));
			statement.setLong(3, usageId);
			statement.setLong(4, userId);
			if (statement.executeUpdate() != 1)
				throw new IllegalStateException("Usage cannot be returned or is not yours.");
		}
	}

	private Asset lockAsset(Connection connection, long assetId) throws SQLException {
		String sql = "SELECT asset_id, total_quantity, condition, status, is_borrowable FROM dbo.assets WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ?";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Asset not found.");
				Asset asset = new Asset();
				asset.setAssetId(result.getLong("asset_id"));
				asset.setTotalQuantity(result.getInt("total_quantity"));
				asset.setCondition(result.getString("condition"));
				asset.setStatus(result.getString("status"));
				asset.setBorrowable(result.getBoolean("is_borrowable"));
				return asset;
			}
		}
	}

	private Membership currentMembership(Connection connection, long userId, ZonedDateTime now) throws SQLException {
		String sql = """
				SELECT TOP 1 lurs.request_id, lurs.semester_id, lurs.student_id, s.end_date
				FROM dbo.users u
				JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
				JOIN dbo.lab_usage_request_students lurs ON lurs.student_id = sp.student_id
				JOIN dbo.lab_usage_requests lur ON lur.request_id = lurs.request_id AND lur.semester_id = lurs.semester_id
				JOIN dbo.semesters s ON s.semester_id = lur.semester_id
				WHERE u.user_id = ? AND u.role = 'INTERN' AND u.status = 'ACTIVE' AND sp.status = 'ACTIVE'
				  AND lur.status = 'APPROVED' AND s.status = 'ACTIVE' AND ? BETWEEN s.start_date AND s.end_date
				ORDER BY s.end_date
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			statement.setDate(2, java.sql.Date.valueOf(now.toLocalDate()));
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("No approved intern list for the current semester.");
				return new Membership(result.getLong(1), result.getLong(2), result.getLong(3),
					result.getDate(4).toLocalDate());
			}
		}
	}

	private boolean hasPendingDisposal(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.disposal_records WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ? AND status = 'PENDING'")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private int activeQuantity(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT COALESCE(SUM(quantity), 0) FROM dbo.asset_usages WHERE asset_id = ? AND status = 'IN_USE'")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private long insertUsage(Connection connection, long userId, Asset asset, int quantity, String note,
			Membership membership, ZonedDateTime now) throws SQLException {
		String sql = """
				INSERT dbo.asset_usages (request_id, semester_id, student_id, asset_id, quantity, borrowed_at, due_at,
				 condition_before, status, note, created_by) OUTPUT INSERTED.asset_usage_id
				VALUES (?, ?, ?, ?, ?, SYSUTCDATETIME(), ?, ?, 'IN_USE', ?, ?)
				""";
		Instant due = ZonedDateTime.of(membership.endDate(), java.time.LocalTime.of(23, 59, 59), labZone).toInstant();
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, membership.requestId());
			statement.setLong(2, membership.semesterId());
			statement.setLong(3, membership.studentId());
			statement.setLong(4, asset.getAssetId());
			statement.setInt(5, quantity);
			statement.setTimestamp(6, Timestamp.valueOf(LocalDateTime.ofInstant(due, java.time.ZoneOffset.UTC)));
			statement.setString(7, asset.getCondition());
			statement.setString(8, blankToNull(note));
			statement.setLong(9, userId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
		}
	}

	private List<AssetUsage> find(String sql, long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			return readUsages(statement);
		}
	}

	private List<AssetUsage> readUsages(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<AssetUsage> usages = new ArrayList<>();
			while (result.next()) {
				AssetUsage usage = new AssetUsage();
				usage.setAssetUsageId(result.getLong("asset_usage_id"));
				usage.setRequestId(result.getLong("request_id"));
				usage.setSemesterId(result.getLong("semester_id"));
				usage.setStudentId(result.getLong("student_id"));
				usage.setAssetId(result.getLong("asset_id"));
				usage.setQuantity(result.getInt("quantity"));
				usage.setBorrowedAt(local(result.getTimestamp("borrowed_at")));
				usage.setDueAt(local(result.getTimestamp("due_at")));
				usage.setReturnedAt(local(result.getTimestamp("returned_at")));
				usage.setConditionBefore(result.getString("condition_before"));
				usage.setConditionAfter(result.getString("condition_after"));
				usage.setStatus(result.getString("status"));
				usage.setNote(result.getString("note"));
				usage.setCreatedBy(result.getLong("created_by"));
				usage.setAssetCode(result.getString("asset_code"));
				usage.setAssetName(result.getString("asset_name"));
				usage.setStudentName(result.getString("student_name"));
				usages.add(usage);
			}
			return usages;
		}
	}

	private LocalDateTime local(Timestamp value) {
		return value == null
				? null
				: value.toLocalDateTime().atZone(java.time.ZoneOffset.UTC).withZoneSameInstant(labZone)
						.toLocalDateTime();
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
	private record Membership(long requestId, long semesterId, long studentId, LocalDate endDate) {
	}
}
