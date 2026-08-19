package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.AssetItem;
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
			SELECT au.*, a.asset_code, a.asset_name, ai.item_code, ai.serial_number AS item_serial_number,
			       u.full_name AS student_name
			FROM dbo.asset_usages au
			JOIN dbo.assets a ON a.asset_id = au.asset_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = au.asset_item_id
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
				WHERE (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR ai.item_code LIKE ?
				       OR ai.serial_number LIKE ? OR u.full_name LIKE ?)
				  AND (? = '' OR au.status = ?)
				ORDER BY au.borrowed_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, search);
			statement.setString(2, "%" + search + "%");
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, "%" + search + "%");
			statement.setString(6, "%" + search + "%");
			statement.setString(7, state);
			statement.setString(8, state);
			return readUsages(statement);
		}
	}

	public int countForMentor(long mentorId) throws SQLException {
		String sql = """
				SELECT COUNT(*)
				FROM dbo.asset_usages au
				JOIN dbo.lab_usage_requests r ON r.request_id = au.request_id
				WHERE r.mentor_id = ?
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
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

	public List<AssetItem> findBorrowableItems() throws SQLException {
		String sql = """
				SELECT i.asset_item_id, i.asset_id, i.item_code, i.serial_number, i.image_path,
				       i.condition, i.status, a.asset_code, a.asset_name, c.category_name
				FROM dbo.asset_items i
				JOIN dbo.assets a ON a.asset_id = i.asset_id
				JOIN dbo.asset_categories c ON c.category_id = a.category_id
				WHERE a.status = 'AVAILABLE' AND a.is_borrowable = 1 AND i.status = 'AVAILABLE'
				  AND i.condition IN ('GOOD', 'FAIR')
				  AND NOT EXISTS (SELECT 1 FROM dbo.disposal_records d WHERE d.asset_id = a.asset_id AND d.status = 'PENDING')
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setItemCode(result.getString("item_code"));
				item.setSerialNumber(result.getString("serial_number"));
				item.setImagePath(result.getString("image_path"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setCategoryName(result.getString("category_name"));
				items.add(item);
			}
			return items;
		}
	}

	public long borrow(long userId, long assetItemId, String note) throws SQLException {
		if (assetItemId <= 0)
			throw new IllegalArgumentException("Vui lòng chọn một sản phẩm hợp lệ.");
		ZonedDateTime now = ZonedDateTime.now(labZone);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				AssetItem item = lockBorrowableItem(connection, assetItemId);
				if (!"AVAILABLE".equals(item.getStatus()) || !Boolean.TRUE.equals(item.getBorrowable())
						|| requiresLabManagerReport(item.getCondition()))
					throw new IllegalStateException("Thiết bị hiện không thể cho mượn.");
				if (hasPendingDisposal(connection, item.getAssetId()))
					throw new IllegalStateException("Thiết bị đang có yêu cầu thanh lý chờ xử lý.");
				Membership membership = currentMembership(connection, userId, now);
				long id = insertUsage(connection, userId, item, note, membership);
				try (PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.asset_items SET status = 'UNAVAILABLE', updated_at = SYSUTCDATETIME() WHERE asset_item_id = ?")) {
					statement.setLong(1, assetItemId);
					statement.executeUpdate();
				}
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
			throw new IllegalArgumentException("Vui lòng chọn tình trạng hợp lệ khi trả thiết bị.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				Long assetItemId;
				long assetId;
				String lookup = """
						SELECT au.asset_item_id, au.asset_id
						FROM dbo.asset_usages au WITH (UPDLOCK, HOLDLOCK)
						JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
						WHERE au.asset_usage_id = ? AND sp.user_id = ? AND au.status = 'IN_USE' AND au.returned_at IS NULL
						""";
				try (PreparedStatement statement = connection.prepareStatement(lookup)) {
					statement.setLong(1, usageId);
					statement.setLong(2, userId);
					try (ResultSet result = statement.executeQuery()) {
						if (!result.next())
							throw new IllegalStateException("Không thể trả lượt mượn này hoặc lượt mượn không thuộc về bạn.");
						assetItemId = nullableLong(result, "asset_item_id");
						assetId = result.getLong("asset_id");
					}
				}
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.asset_usages
						SET returned_at = SYSUTCDATETIME(), condition_after = ?, note = ?, status = 'RETURNED', updated_at = SYSUTCDATETIME()
						WHERE asset_usage_id = ?
						""")) {
					statement.setString(1, conditionAfter);
					statement.setString(2, blankToNull(note));
					statement.setLong(3, usageId);
					statement.executeUpdate();
				}
				if (assetItemId != null) {
					String nextStatus = requiresLabManagerReport(conditionAfter) ? "MAINTENANCE" : "AVAILABLE";
					try (PreparedStatement statement = connection.prepareStatement("""
							UPDATE dbo.asset_items
							SET condition = ?, status = ?, updated_at = SYSUTCDATETIME()
							WHERE asset_item_id = ?
							""")) {
						statement.setString(1, conditionAfter);
						statement.setString(2, nextStatus);
						statement.setLong(3, assetItemId);
						statement.executeUpdate();
					}
					AssetItemDAO.refreshAssetCondition(connection, assetId);
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private AssetItem lockBorrowableItem(Connection connection, long assetItemId) throws SQLException {
		String sql = """
				SELECT i.asset_item_id, i.asset_id, i.condition, i.status,
				       a.status AS asset_status, a.is_borrowable
				FROM dbo.asset_items i WITH (UPDLOCK, HOLDLOCK)
				JOIN dbo.assets a WITH (UPDLOCK, HOLDLOCK) ON a.asset_id = i.asset_id
				WHERE i.asset_item_id = ?
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Không tìm thấy sản phẩm.");
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				if (!"AVAILABLE".equals(result.getString("asset_status")))
					item.setStatus("UNAVAILABLE");
				return item;
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
					throw new IllegalStateException(
							"Bạn chưa thuộc danh sách thực tập sinh được duyệt của học kỳ hiện tại.");
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

	private long insertUsage(Connection connection, long userId, AssetItem item, String note,
			Membership membership) throws SQLException {
		String sql = """
				INSERT dbo.asset_usages (request_id, semester_id, student_id, asset_id, asset_item_id, quantity, borrowed_at, due_at,
				 condition_before, status, note, created_by) OUTPUT INSERTED.asset_usage_id
				VALUES (?, ?, ?, ?, ?, 1, SYSUTCDATETIME(), ?, ?, 'IN_USE', ?, ?)
				""";
		Instant due = ZonedDateTime.of(membership.endDate(), java.time.LocalTime.of(23, 59, 59), labZone).toInstant();
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, membership.requestId());
			statement.setLong(2, membership.semesterId());
			statement.setLong(3, membership.studentId());
			statement.setLong(4, item.getAssetId());
			statement.setLong(5, item.getAssetItemId());
			statement.setTimestamp(6, Timestamp.valueOf(LocalDateTime.ofInstant(due, java.time.ZoneOffset.UTC)));
			statement.setString(7, item.getCondition());
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
				usage.setAssetItemId(nullableLong(result, "asset_item_id"));
				usage.setQuantity(result.getInt("quantity"));
				usage.setBorrowedAt(ViewFormat.fromUtc(result.getTimestamp("borrowed_at")));
				usage.setDueAt(ViewFormat.fromUtc(result.getTimestamp("due_at")));
				usage.setReturnedAt(ViewFormat.fromUtc(result.getTimestamp("returned_at")));
				usage.setConditionBefore(result.getString("condition_before"));
				usage.setConditionAfter(result.getString("condition_after"));
				usage.setStatus(result.getString("status"));
				usage.setNote(result.getString("note"));
				usage.setCreatedBy(result.getLong("created_by"));
				usage.setAssetCode(result.getString("asset_code"));
				usage.setAssetName(result.getString("asset_name"));
				usage.setItemCode(result.getString("item_code"));
				usage.setItemSerialNumber(result.getString("item_serial_number"));
				usage.setStudentName(result.getString("student_name"));
				usages.add(usage);
			}
			return usages;
		}
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private boolean requiresLabManagerReport(String condition) {
		return "DAMAGED".equals(condition) || "BROKEN".equals(condition);
	}

	private record Membership(long requestId, long semesterId, long studentId, LocalDate endDate) {
	}
}
