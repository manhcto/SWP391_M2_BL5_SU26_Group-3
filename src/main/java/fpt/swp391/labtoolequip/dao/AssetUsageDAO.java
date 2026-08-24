package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.AssetUsage;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import util.AppConfig;

public class AssetUsageDAO {
	private static final LocalTime DAILY_RETURN_DEADLINE = LocalTime.of(17, 40);
	private static final String SELECT_USAGE = """
			SELECT au.*, a.asset_code, a.asset_name,
			       CASE WHEN au.asset_item_id IS NULL THEN NULL
			            ELSE COALESCE(NULLIF(ai.item_code, ''), NULLIF(ai.serial_number, ''),
			                         CONCAT(a.asset_code, ' / item #', ai.asset_item_id))
			       END AS asset_item_tag,
			       u.full_name AS intern_name
			FROM dbo.asset_usages au
			JOIN dbo.assets a ON a.asset_id = au.asset_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = au.asset_item_id AND ai.asset_id = au.asset_id
			JOIN dbo.intern_profiles ip ON ip.intern_id = au.student_id
			JOIN dbo.users u ON u.user_id = ip.user_id
			""";
	private final DBConnection db = new DBConnection();
	private final ZoneId labZone = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));

	public List<AssetUsage> findForIntern(long userId, String keyword, String status) throws SQLException {
		return findForIntern(userId, keyword, status, null, null);
	}

	public List<AssetUsage> findForIntern(long userId, String keyword, String status, String fromDate, String toDate)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT_USAGE + """
				WHERE ip.user_id = ?
				  AND (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ?)
				  AND (? = '' OR au.status = ?)
				  AND (? IS NULL OR au.borrowed_at >= ?)
				  AND (? IS NULL OR au.borrowed_at < ?)
				ORDER BY au.borrowed_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			statement.setString(2, search);
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, state);
			statement.setString(6, state);
			bindBorrowedAtRange(statement, 7, fromDate, toDate);
			return readUsages(statement);
		}
	}

	public List<AssetUsage> findForMentor(long mentorId, String keyword, String status) throws SQLException {
		return findForMentor(mentorId, keyword, status, null, null);
	}

	public List<AssetUsage> findForMentor(long mentorId, String keyword, String status, String fromDate, String toDate)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT_USAGE + """
				WHERE EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests lur
					WHERE lur.request_id = au.request_id
					  AND lur.semester_id = au.semester_id
					  AND lur.mentor_id = ?
					  AND lur.status = 'APPROVED'
				)
				AND (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR u.full_name LIKE ?)
				AND (? = '' OR au.status = ?)
				AND (? IS NULL OR au.borrowed_at >= ?)
				AND (? IS NULL OR au.borrowed_at < ?)
				ORDER BY au.borrowed_at DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			statement.setString(2, search);
			statement.setString(3, "%" + search + "%");
			statement.setString(4, "%" + search + "%");
			statement.setString(5, "%" + search + "%");
			statement.setString(6, state);
			statement.setString(7, state);
			bindBorrowedAtRange(statement, 8, fromDate, toDate);
			return readUsages(statement);
		}
	}

	public Optional<AssetUsage> findByIdForMentor(long usageId, long mentorId) throws SQLException {
		String sql = SELECT_USAGE + """
				WHERE au.asset_usage_id = ?
				  AND EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests lur
					WHERE lur.request_id = au.request_id
					  AND lur.semester_id = au.semester_id
					  AND lur.mentor_id = ?
					  AND lur.status = 'APPROVED'
				)
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			statement.setLong(2, mentorId);
			return readUsages(statement).stream().findFirst();
		}
	}

	public List<AssetUsage> findAll(String keyword, String status) throws SQLException {
		return findAll(keyword, status, null, null);
	}

	public List<AssetUsage> findAll(String keyword, String status, String fromDate, String toDate) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String sql = SELECT_USAGE + """
				WHERE (? = '' OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR u.full_name LIKE ?)
				  AND (? = '' OR au.status = ?)
				  AND (? IS NULL OR au.borrowed_at >= ?)
				  AND (? IS NULL OR au.borrowed_at < ?)
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
			bindBorrowedAtRange(statement, 7, fromDate, toDate);
			return readUsages(statement);
		}
	}

	public Optional<AssetUsage> findById(long usageId, Long ownerUserId) throws SQLException {
		String sql = SELECT_USAGE + " WHERE au.asset_usage_id = ?" + (ownerUserId == null ? "" : " AND ip.user_id = ?");
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			if (ownerUserId != null) {
				statement.setLong(2, ownerUserId);
			}
			return readUsages(statement).stream().findFirst();
		}
	}

	public List<Asset> findBorrowableAssets() throws SQLException {
		String sql = """
				SELECT a.asset_id, a.asset_code, a.asset_name, a.tracking_mode, a.total_quantity, a.condition
				FROM dbo.assets a
				WHERE a.tracking_mode = 'QUANTITY' AND a.status = 'AVAILABLE' AND a.is_borrowable = 1
				  AND a.condition IN ('GOOD', 'FAIR')
				  AND a.total_quantity > (
					SELECT COALESCE(SUM(au.quantity), 0)
					FROM dbo.asset_usages au
					WHERE au.asset_id = a.asset_id AND au.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.disposal_records d
					WHERE d.asset_id = a.asset_id AND d.asset_item_id IS NULL AND d.status IN ('PENDING', 'APPROVED')
				  )
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
				asset.setTrackingMode(result.getString("tracking_mode"));
				asset.setTotalQuantity(result.getInt("total_quantity"));
				asset.setCondition(result.getString("condition"));
				assets.add(asset);
			}
			return assets;
		}
	}

	public List<AssetUsage> findForStudent(long userId) throws SQLException {
		return findForIntern(userId, "", "");
	}

	public int countForMentor(long mentorId) throws SQLException {
		return findForMentor(mentorId, "", "").size();
	}

	public List<AssetItem> findBorrowableAssetItems() throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, ai.asset_id, a.asset_code, a.asset_name,
				       COALESCE(NULLIF(ai.serial_number, ''), CONCAT(a.asset_code, ' / item #', ai.asset_item_id)) AS item_tag,
				       ai.condition, ai.status, ai.is_borrowable
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.tracking_mode = 'SERIALIZED' AND a.status = 'AVAILABLE' AND a.is_borrowable = 1
				  AND ai.status = 'AVAILABLE' AND ai.is_borrowable = 1
				  AND ai.condition IN ('GOOD', 'FAIR')
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.asset_usages au
					WHERE au.asset_item_id = ai.asset_item_id AND au.status IN ('IN_USE', 'RETURN_PENDING')
				  )
				  AND NOT EXISTS (
					SELECT 1 FROM dbo.disposal_records d
					WHERE d.asset_item_id = ai.asset_item_id AND d.status IN ('PENDING', 'APPROVED')
				  )
				ORDER BY a.asset_name, ai.asset_item_id
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setItemTag(result.getString("item_tag"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				items.add(item);
			}
			return items;
		}
	}

	public List<AssetUsage> findIncidentReportableForMentor(long mentorId) throws SQLException {
		String sql = SELECT_USAGE + """
				WHERE au.status IN ('IN_USE', 'RETURNED')
				  AND EXISTS (
					SELECT 1 FROM dbo.lab_usage_requests request
					WHERE request.request_id = au.request_id AND request.semester_id = au.semester_id
					  AND request.mentor_id = ? AND request.status = 'APPROVED'
				  )
				ORDER BY CASE WHEN au.status = 'RETURNED' AND au.condition_after IN ('DAMAGED', 'BROKEN') THEN 0
				              WHEN au.status = 'IN_USE' THEN 1 ELSE 2 END,
				         COALESCE(au.returned_at, au.borrowed_at) DESC, au.asset_usage_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			return readUsages(statement);
		}
	}

	public long borrowItem(long userId, long assetItemId, String note) throws SQLException {
		return borrow(userId, null, assetItemId, 1, note);
	}

	public long borrow(long userId, long assetId, int quantity, String note) throws SQLException {
		return borrow(userId, assetId, null, quantity, note);
	}

	public long borrow(long userId, Long assetId, Long assetItemId, int quantity, String note) throws SQLException {
		return borrow(userId, assetId, assetItemId, quantity, note, null);
	}

	public long borrow(long userId, Long assetId, Long assetItemId, int quantity, String note, LocalDateTime borrowedAt)
			throws SQLException {
		ZonedDateTime borrowTime = borrowedAt == null ? ZonedDateTime.now(labZone) : borrowedAt.atZone(labZone);
		if (borrowTime.isAfter(ZonedDateTime.now(labZone))) {
			throw new IllegalArgumentException("Ngày và giờ mượn không được ở tương lai.");
		}
		if (assetItemId != null) {
			if (assetId != null) {
				throw new IllegalArgumentException("Chỉ chọn một thiết bị theo mã riêng hoặc theo số lượng.");
			}
			return borrowSerialized(userId, assetItemId, quantity, note, borrowTime);
		}
		if (assetId == null) {
			throw new IllegalArgumentException("Vui lòng chọn thiết bị để mượn.");
		}
		return borrowQuantity(userId, assetId, quantity, note, borrowTime);
	}

	private long borrowQuantity(long userId, long assetId, int quantity, String note, ZonedDateTime borrowedAt)
			throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				Asset asset = lockAsset(connection, assetId);
				validateBorrowRequest(asset.getTrackingMode(), assetId, null, quantity);
				validateBorrowable(asset);
				if (hasPendingDisposal(connection, assetId, null)) {
					throw new IllegalStateException("Thiết bị đang có yêu cầu thanh lý chờ xử lý.");
				}
				Membership membership = currentMembership(connection, userId, borrowedAt);
				validateAvailableQuantity(activeQuantity(connection, assetId), quantity, asset.getTotalQuantity());
				long id = insertUsage(connection, userId, asset.getAssetId(), null, quantity, asset.getCondition(),
						note, membership, borrowedAt);
				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private long borrowSerialized(long userId, long assetItemId, int quantity, String note, ZonedDateTime borrowedAt)
			throws SQLException {
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				AssetItem item = lockAssetItem(connection, assetItemId);
				Asset asset = lockAsset(connection, item.getAssetId());
				validateBorrowRequest(asset.getTrackingMode(), null, assetItemId, quantity);
				validateSerializedAsset(asset);
				validateBorrowableItem(item);
				if (hasPendingDisposal(connection, asset.getAssetId(), assetItemId)) {
					throw new IllegalStateException("Thiết bị đang có yêu cầu thanh lý chờ xử lý.");
				}
				Membership membership = currentMembership(connection, userId, borrowedAt);
				if (hasActiveUsageForItem(connection, assetItemId)) {
					throw new IllegalStateException("Thiết bị theo mã riêng đang được sử dụng.");
				}
				markAssetItemInUse(connection, assetItemId);
				long id = insertUsage(connection, userId, asset.getAssetId(), assetItemId, 1, item.getCondition(), note,
						membership, borrowedAt);
				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	static void validateQuantity(int quantity) {
		if (quantity <= 0) {
			throw new IllegalArgumentException("Số lượng phải lớn hơn 0.");
		}
	}

	static void validateBorrowRequest(String trackingMode, Long assetId, Long assetItemId, int quantity) {
		if ("SERIALIZED".equals(trackingMode)) {
			if (assetId != null || assetItemId == null || quantity != 1) {
				throw new IllegalArgumentException("Thiết bị theo mã riêng phải chọn đúng một mã thiết bị.");
			}
			return;
		}
		if ("QUANTITY".equals(trackingMode)) {
			if (assetId == null || assetItemId != null) {
				throw new IllegalArgumentException("Thiết bị theo số lượng không dùng mã thiết bị riêng.");
			}
			validateQuantity(quantity);
			return;
		}
		throw new IllegalStateException("Kiểu theo dõi thiết bị không hợp lệ.");
	}

	static void validateBorrowable(Asset asset) {
		if (!"AVAILABLE".equals(asset.getStatus()) || !Boolean.TRUE.equals(asset.getBorrowable())
				|| !("GOOD".equals(asset.getCondition()) || "FAIR".equals(asset.getCondition()))) {
			throw new IllegalStateException("Thiết bị hiện không thể cho mượn.");
		}
	}

	static void validateBorrowableItem(AssetItem item) {
		if (!"AVAILABLE".equals(item.getStatus()) || !Boolean.TRUE.equals(item.getBorrowable())
				|| !("GOOD".equals(item.getCondition()) || "FAIR".equals(item.getCondition()))) {
			throw new IllegalStateException("Thiết bị theo mã riêng hiện không thể cho mượn.");
		}
	}

	static void validateSerializedAsset(Asset asset) {
		if (!"AVAILABLE".equals(asset.getStatus()) || !Boolean.TRUE.equals(asset.getBorrowable())) {
			throw new IllegalStateException("Thiết bị hiện không thể cho mượn.");
		}
	}

	static String returnedAssetItemStatus(String conditionAfter) {
		return "GOOD".equals(conditionAfter) || "FAIR".equals(conditionAfter) ? "AVAILABLE" : "UNAVAILABLE";
	}

	static void validateAvailableQuantity(int active, int requested, int total) {
		if ((long) active + requested > total) {
			throw new IllegalStateException("Số lượng thiết bị khả dụng không đủ.");
		}
	}

	static boolean requiresQuarantine(String conditionAfter) {
		return "DAMAGED".equals(conditionAfter) || "BROKEN".equals(conditionAfter);
	}

	public void requestReturn(long usageId, long userId, String reportedCondition, String note) throws SQLException {
		if (reportedCondition == null || !List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(reportedCondition)) {
			throw new IllegalArgumentException("Vui lòng chọn tình trạng hợp lệ khi trả thiết bị.");
		}
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				lockUsageForReturn(connection, userId, usageId);
				try (PreparedStatement statement = connection.prepareStatement(
						"""
								UPDATE au SET status='RETURN_PENDING', reported_condition_after=?, return_requested_at=SYSUTCDATETIME(),
								return_note=?, updated_at=SYSUTCDATETIME()
								FROM dbo.asset_usages au JOIN dbo.intern_profiles ip ON ip.intern_id=au.student_id
								WHERE au.asset_usage_id=? AND ip.user_id=? AND au.status='IN_USE' AND au.returned_at IS NULL
								""")) {
					statement.setString(1, reportedCondition);
					statement.setString(2, blankToNull(note));
					statement.setLong(3, usageId);
					statement.setLong(4, userId);
					if (statement.executeUpdate() != 1)
						throw new IllegalStateException("Không thể yêu cầu trả lượt mượn này.");
				}
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void confirmReturn(long usageId, long mentorId, String verifiedCondition, String note) throws SQLException {
		if (verifiedCondition == null || !List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(verifiedCondition))
			throw new IllegalArgumentException("Vui lòng chọn tình trạng xác minh hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				ReturnTarget target = lockPendingReturnForMentor(connection, usageId, mentorId);
				if (target.assetItemId() != null)
					lockAssetItem(connection, target.assetItemId());
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.asset_usages SET status='RETURNED', returned_at=SYSUTCDATETIME(),
						verified_condition_after=?, condition_after=?, return_verified_at=SYSUTCDATETIME(),
						return_verified_by=?, return_note=COALESCE(?, return_note), updated_at=SYSUTCDATETIME()
						WHERE asset_usage_id=? AND status='RETURN_PENDING'
						""")) {
					statement.setString(1, verifiedCondition);
					statement.setString(2, verifiedCondition);
					statement.setLong(3, mentorId);
					statement.setString(4, blankToNull(note));
					statement.setLong(5, usageId);
					if (statement.executeUpdate() != 1)
						throw new IllegalStateException("Yêu cầu trả đã được xử lý.");
				}
				if (target.assetItemId() != null)
					updateReturnedAssetItem(connection, target.assetItemId(), verifiedCondition);
				else if (requiresQuarantine(verifiedCondition))
					updateReturnedQuantityAsset(connection, target.assetId(), verifiedCondition);
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private ReturnTarget lockPendingReturnForMentor(Connection connection, long usageId, long mentorId)
			throws SQLException {
		String sql = """
				SELECT au.asset_id, au.asset_item_id FROM dbo.asset_usages au WITH (UPDLOCK, HOLDLOCK)
				WHERE au.asset_usage_id=? AND au.status='RETURN_PENDING' AND EXISTS (
				 SELECT 1 FROM dbo.lab_usage_requests lur WHERE lur.request_id=au.request_id
				 AND lur.semester_id=au.semester_id AND lur.mentor_id=? AND lur.status='APPROVED')
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			statement.setLong(2, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalStateException("Yêu cầu trả không thuộc phạm vi xác nhận của bạn.");
				return new ReturnTarget(result.getLong(1), nullableLong(result, "asset_item_id"));
			}
		}
	}

	private ReturnTarget findReturnTarget(Connection connection, long userId, long usageId) throws SQLException {
		String sql = """
				SELECT au.asset_id, au.asset_item_id
				FROM dbo.asset_usages au
				JOIN dbo.intern_profiles ip ON ip.intern_id = au.student_id
				WHERE au.asset_usage_id = ? AND ip.user_id = ? AND au.status = 'IN_USE' AND au.returned_at IS NULL
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			statement.setLong(2, userId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Không thể trả lượt mượn này hoặc lượt mượn không thuộc về bạn.");
				}
				return new ReturnTarget(result.getLong("asset_id"), nullableLong(result, "asset_item_id"));
			}
		}
	}

	private ReturnTarget lockUsageForReturn(Connection connection, long userId, long usageId) throws SQLException {
		String sql = """
				SELECT au.asset_id, au.asset_item_id
				FROM dbo.asset_usages au WITH (UPDLOCK, HOLDLOCK)
				JOIN dbo.intern_profiles ip ON ip.intern_id = au.student_id
				WHERE au.asset_usage_id = ? AND ip.user_id = ? AND au.status = 'IN_USE' AND au.returned_at IS NULL
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, usageId);
			statement.setLong(2, userId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException("Không thể trả lượt mượn này hoặc lượt mượn không thuộc về bạn.");
				}
				return new ReturnTarget(result.getLong("asset_id"), nullableLong(result, "asset_item_id"));
			}
		}
	}

	private void updateReturnedUsage(Connection connection, long userId, long usageId, String conditionAfter,
			String note) throws SQLException {
		String sql = """
				UPDATE au
				SET returned_at = SYSUTCDATETIME(), condition_after = ?, return_note = ?, status = 'RETURNED',
				    updated_at = SYSUTCDATETIME()
				FROM dbo.asset_usages au
				JOIN dbo.intern_profiles ip ON ip.intern_id = au.student_id
				WHERE au.asset_usage_id = ? AND ip.user_id = ? AND au.status = 'IN_USE' AND au.returned_at IS NULL
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, conditionAfter);
			statement.setString(2, blankToNull(note));
			statement.setLong(3, usageId);
			statement.setLong(4, userId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể trả lượt mượn này hoặc lượt mượn không thuộc về bạn.");
			}
		}
	}

	private Asset lockAsset(Connection connection, long assetId) throws SQLException {
		String sql = "SELECT asset_id, tracking_mode, total_quantity, condition, status, is_borrowable FROM dbo.assets "
				+ "WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ?";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalArgumentException("Không tìm thấy thiết bị.");
				}
				Asset asset = new Asset();
				asset.setAssetId(result.getLong("asset_id"));
				asset.setTrackingMode(result.getString("tracking_mode"));
				asset.setTotalQuantity(result.getInt("total_quantity"));
				asset.setCondition(result.getString("condition"));
				asset.setStatus(result.getString("status"));
				asset.setBorrowable(result.getBoolean("is_borrowable"));
				return asset;
			}
		}
	}

	private AssetItem lockAssetItem(Connection connection, long assetItemId) throws SQLException {
		String sql = "SELECT asset_item_id, asset_id, condition, status, is_borrowable FROM dbo.asset_items "
				+ "WITH (UPDLOCK, HOLDLOCK) WHERE asset_item_id = ?";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalArgumentException("Không tìm thấy thiết bị theo mã riêng.");
				}
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				return item;
			}
		}
	}

	private void updateReturnedAssetItem(Connection connection, long assetItemId, String conditionAfter)
			throws SQLException {
		String sql = "UPDATE dbo.asset_items SET condition = ?, status = ?, updated_at = SYSUTCDATETIME() "
				+ "WHERE asset_item_id = ? AND status = 'IN_USE'";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, conditionAfter);
			statement.setString(2, returnedAssetItemStatus(conditionAfter));
			statement.setLong(3, assetItemId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể cập nhật thiết bị theo mã riêng khi trả.");
			}
		}
	}

	private void updateReturnedQuantityAsset(Connection connection, long assetId, String conditionAfter)
			throws SQLException {
		String sql = """
				UPDATE dbo.assets
				SET condition = ?, status = CASE WHEN status = 'AVAILABLE' THEN 'UNAVAILABLE' ELSE status END,
				    updated_at = SYSUTCDATETIME()
				WHERE asset_id = ?
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, conditionAfter);
			statement.setLong(2, assetId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không thể cập nhật thiết bị theo số lượng khi trả.");
			}
		}
	}

	private void markAssetItemInUse(Connection connection, long assetItemId) throws SQLException {
		String sql = "UPDATE dbo.asset_items SET status = 'IN_USE', updated_at = SYSUTCDATETIME() "
				+ "WHERE asset_item_id = ? AND status = 'AVAILABLE'";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetItemId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Thiết bị theo mã riêng hiện không thể cho mượn.");
			}
		}
	}

	private Membership currentMembership(Connection connection, long userId, ZonedDateTime now) throws SQLException {
		String sql = """
				SELECT TOP 1 luri.request_id, luri.semester_id, luri.intern_id, s.end_date
				FROM dbo.users u
				JOIN dbo.intern_profiles ip ON ip.user_id = u.user_id
				JOIN dbo.lab_usage_request_interns luri ON luri.intern_id = ip.intern_id
				JOIN dbo.lab_usage_requests lur
				  ON lur.request_id = luri.request_id AND lur.semester_id = luri.semester_id
				JOIN dbo.semesters s ON s.semester_id = lur.semester_id
				WHERE u.user_id = ? AND u.role = 'INTERN' AND u.status = 'ACTIVE' AND ip.status = 'ACTIVE'
				  AND lur.status = 'APPROVED' AND s.status = 'ACTIVE' AND ? BETWEEN s.start_date AND s.end_date
				ORDER BY s.end_date
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			statement.setDate(2, java.sql.Date.valueOf(now.toLocalDate()));
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) {
					throw new IllegalStateException(
							"Bạn chưa thuộc danh sách thực tập sinh được duyệt của học kỳ hiện tại.");
				}
				return new Membership(result.getLong(1), result.getLong(2), result.getLong(3),
						result.getDate(4).toLocalDate());
			}
		}
	}

	private boolean hasPendingDisposal(Connection connection, long assetId, Long assetItemId) throws SQLException {
		String sql = """
				SELECT 1 FROM dbo.disposal_records WITH (UPDLOCK, HOLDLOCK)
				WHERE asset_id = ? AND status IN ('PENDING', 'APPROVED')
				  AND (asset_item_id IS NULL OR asset_item_id = ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			if (assetItemId == null) {
				statement.setNull(2, Types.BIGINT);
			} else {
				statement.setLong(2, assetItemId);
			}
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private int activeQuantity(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT COALESCE(SUM(quantity), 0) FROM dbo.asset_usages WHERE asset_id = ? AND status IN ('IN_USE', 'RETURN_PENDING')")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private long insertUsage(Connection connection, long userId, long assetId, Long assetItemId, int quantity,
			String conditionBefore, String note, Membership membership, ZonedDateTime borrowedAt) throws SQLException {
		String sql = """
				INSERT dbo.asset_usages (request_id, semester_id, student_id, asset_id, asset_item_id, quantity, borrowed_at,
				 due_at, condition_before, status, note, created_by) OUTPUT INSERTED.asset_usage_id
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'IN_USE', ?, ?)
				""";
		Instant due = dueAtEndOfBorrowDay(borrowedAt);
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, membership.requestId());
			statement.setLong(2, membership.semesterId());
			statement.setLong(3, membership.internId());
			statement.setLong(4, assetId);
			if (assetItemId == null) {
				statement.setNull(5, Types.BIGINT);
			} else {
				statement.setLong(5, assetItemId);
			}
			statement.setInt(6, quantity);
			statement.setTimestamp(7,
					Timestamp.valueOf(LocalDateTime.ofInstant(borrowedAt.toInstant(), java.time.ZoneOffset.UTC)));
			statement.setTimestamp(8, Timestamp.valueOf(LocalDateTime.ofInstant(due, java.time.ZoneOffset.UTC)));
			statement.setString(9, conditionBefore);
			statement.setString(10, blankToNull(note));
			statement.setLong(11, userId);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
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
				usage.setInternId(result.getLong("student_id"));
				usage.setAssetId(result.getLong("asset_id"));
				usage.setAssetItemId(nullableLong(result, "asset_item_id"));
				usage.setQuantity(result.getInt("quantity"));
				usage.setBorrowedAt(ViewFormat.fromUtc(result.getTimestamp("borrowed_at")));
				usage.setDueAt(ViewFormat.fromUtc(result.getTimestamp("due_at")));
				usage.setReturnedAt(ViewFormat.fromUtc(result.getTimestamp("returned_at")));
				usage.setConditionBefore(result.getString("condition_before"));
				usage.setConditionAfter(result.getString("condition_after"));
				usage.setReportedConditionAfter(result.getString("reported_condition_after"));
				usage.setReturnRequestedAt(ViewFormat.fromUtc(result.getTimestamp("return_requested_at")));
				usage.setVerifiedConditionAfter(result.getString("verified_condition_after"));
				usage.setReturnVerifiedAt(ViewFormat.fromUtc(result.getTimestamp("return_verified_at")));
				usage.setReturnVerifiedBy(nullableLong(result, "return_verified_by"));
				usage.setStatus(result.getString("status"));
				usage.setNote(result.getString("note"));
				usage.setReturnNote(result.getString("return_note"));
				usage.setCreatedBy(result.getLong("created_by"));
				usage.setAssetCode(result.getString("asset_code"));
				usage.setAssetName(result.getString("asset_name"));
				usage.setAssetItemTag(result.getString("asset_item_tag"));
				usage.setInternName(result.getString("intern_name"));
				usages.add(usage);
			}
			return usages;
		}
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	private void bindBorrowedAtRange(PreparedStatement statement, int index, String fromDate, String toDate)
			throws SQLException {
		LocalDate from = optionalDate(fromDate);
		LocalDate to = optionalDate(toDate);
		if (from != null && to != null && from.isAfter(to)) {
			throw new IllegalArgumentException("Ngày bắt đầu không được sau ngày kết thúc.");
		}
		bindTimestamp(statement, index, from == null ? null : startOfDayUtc(from));
		bindTimestamp(statement, index + 2, to == null ? null : startOfDayUtc(to.plusDays(1)));
	}

	private LocalDate optionalDate(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			return LocalDate.parse(value);
		} catch (RuntimeException exception) {
			throw new IllegalArgumentException("Ngày lọc không hợp lệ.");
		}
	}

	private Timestamp startOfDayUtc(LocalDate date) {
		return Timestamp
				.valueOf(date.atStartOfDay(labZone).withZoneSameInstant(java.time.ZoneOffset.UTC).toLocalDateTime());
	}

	private void bindTimestamp(PreparedStatement statement, int index, Timestamp value) throws SQLException {
		if (value == null) {
			statement.setNull(index, Types.TIMESTAMP);
			statement.setNull(index + 1, Types.TIMESTAMP);
		} else {
			statement.setTimestamp(index, value);
			statement.setTimestamp(index + 1, value);
		}
	}

	private boolean hasActiveUsageForItem(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.asset_usages WHERE asset_item_id = ? AND status IN ('IN_USE', 'RETURN_PENDING')")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private record ReturnTarget(long assetId, Long assetItemId) {
	}

	static Instant dueAtEndOfBorrowDay(ZonedDateTime borrowedAt) {
		return borrowedAt.toLocalDate().atTime(DAILY_RETURN_DEADLINE).atZone(borrowedAt.getZone()).toInstant();
	}

	private record Membership(long requestId, long semesterId, long internId, LocalDate endDate) {
	}
}
