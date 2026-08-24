package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.MaintenanceSchedule;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class MaintenanceScheduleDAO {
	private static final String SELECT = """
			SELECT s.*, a.asset_code, a.asset_name, a.storage_location, u.full_name AS creator_name,
			       COALESCE(ai.status, a.status) AS target_asset_status
			FROM dbo.maintenance_schedules s
			JOIN dbo.assets a ON a.asset_id = s.asset_id
			JOIN dbo.users u ON u.user_id = s.created_by
			LEFT JOIN dbo.asset_items ai ON ai.asset_id = s.asset_id AND (s.item_code IS NOT NULL AND ai.item_code = s.item_code)
			""";

	private final DBConnection db = new DBConnection();

	public List<MaintenanceSchedule> findAll(String keyword, String status) throws SQLException {
		StringBuilder sql = new StringBuilder(SELECT).append(" WHERE 1=1 ");
		List<Object> params = new ArrayList<>();

		if (status != null && !status.isBlank()) {
			sql.append(" AND s.status = ? ");
			params.add(status.trim().toUpperCase());
		}

		if (keyword != null && !keyword.isBlank()) {
			sql.append(
					" AND (s.title LIKE ? OR a.asset_code LIKE ? OR a.asset_name LIKE ? OR s.provider_name LIKE ?) ");
			String pattern = "%" + keyword.trim() + "%";
			params.add(pattern);
			params.add(pattern);
			params.add(pattern);
			params.add(pattern);
		}

		sql.append("""
				ORDER BY
				    CASE WHEN s.status = 'PENDING' THEN 0 ELSE 1 END,
				    s.scheduled_date ASC,
				    s.schedule_id DESC
				""");

		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql.toString())) {
			for (int i = 0; i < params.size(); i++) {
				statement.setObject(i + 1, params.get(i));
			}
			try (ResultSet result = statement.executeQuery()) {
				List<MaintenanceSchedule> list = new ArrayList<>();
				while (result.next()) {
					list.add(mapRow(result));
				}
				return list;
			}
		}
	}

	/**
	 * Lấy danh sách lịch bảo trì PENDING đến hạn (trong N ngày tới hoặc đã quá
	 * hạn).
	 */
	public List<MaintenanceSchedule> findDueSchedules(int daysAhead) throws SQLException {
		String sql = SELECT + """
				WHERE s.status = 'PENDING'
				  AND s.scheduled_date <= DATEADD(day, ?, CAST(SYSUTCDATETIME() AS DATE))
				ORDER BY s.scheduled_date ASC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setInt(1, daysAhead);
			try (ResultSet result = statement.executeQuery()) {
				List<MaintenanceSchedule> list = new ArrayList<>();
				while (result.next()) {
					list.add(mapRow(result));
				}
				return list;
			}
		}
	}

	/**
	 * Đếm số lượng lịch bảo trì PENDING đến hạn (trong N ngày tới hoặc đã quá hạn).
	 */
	public int countDueSchedules(int daysAhead) throws SQLException {
		String sql = """
				SELECT COUNT(*) FROM dbo.maintenance_schedules
				WHERE status = 'PENDING'
				  AND scheduled_date <= DATEADD(day, ?, CAST(SYSUTCDATETIME() AS DATE))
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setInt(1, daysAhead);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next()) {
					return result.getInt(1);
				}
				return 0;
			}
		}
	}

	public Optional<MaintenanceSchedule> findById(long id) throws SQLException {
		String sql = SELECT + " WHERE s.schedule_id = ? ";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (result.next()) {
					return Optional.of(mapRow(result));
				}
				return Optional.empty();
			}
		}
	}

	public long create(MaintenanceSchedule schedule) throws SQLException {
		String sql = """
				INSERT INTO dbo.maintenance_schedules
				    (title, asset_id, item_code, scheduled_date, estimated_cost, provider_name, provider_phone, note, status, created_by, created_at)
				OUTPUT INSERTED.schedule_id
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?, SYSUTCDATETIME())
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, schedule.getTitle().trim());
			statement.setLong(2, schedule.getAssetId());
			statement.setString(3, blankToNull(schedule.getItemCode()));
			statement.setDate(4, Date.valueOf(schedule.getScheduledDate()));
			setNullableLong(statement, 5, schedule.getEstimatedCost());
			statement.setString(6, blankToNull(schedule.getProviderName()));
			statement.setString(7, blankToNull(schedule.getProviderPhone()));
			statement.setString(8, blankToNull(schedule.getNote()));
			statement.setLong(9, schedule.getCreatedBy());

			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
		}
	}

	public void update(MaintenanceSchedule schedule) throws SQLException {
		String sql = """
				UPDATE dbo.maintenance_schedules
				SET title = ?, asset_id = ?, item_code = ?, scheduled_date = ?, estimated_cost = ?,
				    provider_name = ?, provider_phone = ?, note = ?, updated_at = SYSUTCDATETIME()
				WHERE schedule_id = ?
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, schedule.getTitle().trim());
			statement.setLong(2, schedule.getAssetId());
			statement.setString(3, blankToNull(schedule.getItemCode()));
			statement.setDate(4, Date.valueOf(schedule.getScheduledDate()));
			setNullableLong(statement, 5, schedule.getEstimatedCost());
			statement.setString(6, blankToNull(schedule.getProviderName()));
			statement.setString(7, blankToNull(schedule.getProviderPhone()));
			statement.setString(8, blankToNull(schedule.getNote()));
			statement.setLong(9, schedule.getScheduleId());
			statement.executeUpdate();
		}
	}

	public void updateStatus(long id, String status) throws SQLException {
		String sql = "UPDATE dbo.maintenance_schedules SET status = ?, updated_at = SYSUTCDATETIME() WHERE schedule_id = ?";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status.trim().toUpperCase());
			statement.setLong(2, id);
			statement.executeUpdate();
		}
	}

	public void delete(long id) throws SQLException {
		String sql = "DELETE FROM dbo.maintenance_schedules WHERE schedule_id = ?";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			statement.executeUpdate();
		}
	}

	/**
	 * Cập nhật trạng thái hàng loạt các lịch bảo trì được chọn (ví dụ: CANCELLED,
	 * COMPLETED).
	 */
	public void batchUpdateStatus(List<Long> ids, String status) throws SQLException {
		if (ids == null || ids.isEmpty()) {
			return;
		}
		String placeholders = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
		String sql = "UPDATE dbo.maintenance_schedules SET status = ?, updated_at = SYSUTCDATETIME() WHERE schedule_id IN ("
				+ placeholders + ")";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status.trim().toUpperCase());
			for (int i = 0; i < ids.size(); i++) {
				statement.setLong(i + 2, ids.get(i));
			}
			statement.executeUpdate();
		}
	}

	/** Xóa hàng loạt các lịch bảo trì được chọn khỏi cơ sở dữ liệu. */
	public void batchDelete(List<Long> ids) throws SQLException {
		if (ids == null || ids.isEmpty()) {
			return;
		}
		String placeholders = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
		String sql = "DELETE FROM dbo.maintenance_schedules WHERE schedule_id IN (" + placeholders + ")";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int i = 0; i < ids.size(); i++) {
				statement.setLong(i + 1, ids.get(i));
			}
			statement.executeUpdate();
		}
	}

	/** Lấy danh sách cá thể thiết bị (AssetItem) khả dụng để lên lịch bảo trì. */
	public List<fpt.swp391.labtoolequip.model.AssetItem> findSchedulableAssets() throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, a.asset_id,
				       ai.item_code, a.asset_code, a.asset_name,
				       COALESCE(ai.storage_location, a.storage_location) AS storage_location,
				       ai.status
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.status <> 'DISPOSED' AND ai.status <> 'DISPOSED'
				UNION ALL
				SELECT NULL AS asset_item_id, a.asset_id,
				       a.asset_code AS item_code, a.asset_code, a.asset_name,
				       a.storage_location,
				       a.status
				FROM dbo.assets a
				WHERE a.status <> 'DISPOSED'
				  AND NOT EXISTS (SELECT 1 FROM dbo.asset_items ai WHERE ai.asset_id = a.asset_id)
				ORDER BY asset_name, item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<fpt.swp391.labtoolequip.model.AssetItem> items = new ArrayList<>();
			while (result.next()) {
				fpt.swp391.labtoolequip.model.AssetItem item = new fpt.swp391.labtoolequip.model.AssetItem();
				item.setAssetItemId((Long) result.getObject("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setItemCode(result.getString("item_code"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setStorageLocation(result.getString("storage_location"));
				item.setStatus(result.getString("status"));
				items.add(item);
			}
			return items;
		}
	}

	/**
	 * Kiểm tra xem thiết bị đã có lịch bảo trì (PENDING hoặc COMPLETED) cùng ngày
	 * chưa.
	 */
	public boolean isDuplicateSchedule(long assetId, String itemCode, java.time.LocalDate date, Long excludeScheduleId)
			throws SQLException {
		String sql = """
				SELECT 1 FROM dbo.maintenance_schedules
				WHERE asset_id = ?
				  AND (item_code = ? OR (item_code IS NULL AND ? IS NULL) OR (? = '' AND (item_code IS NULL OR item_code = '')))
				  AND scheduled_date = ?
				  AND status IN ('PENDING', 'COMPLETED')
				  AND (? IS NULL OR schedule_id <> ?)
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			statement.setString(2, itemCode);
			statement.setString(3, itemCode);
			statement.setString(4, itemCode == null ? "" : itemCode);
			statement.setDate(5, Date.valueOf(date));
			setNullableLong(statement, 6, excludeScheduleId);
			setNullableLong(statement, 7, excludeScheduleId);
			try (ResultSet rs = statement.executeQuery()) {
				return rs.next();
			}
		}
	}

	/** Lấy bản đồ ánh xạ từ Mã thiết bị / Mã cá thể (UPPERCASE) -> Asset ID. */
	public java.util.Map<String, Long> getAssetCodeToIdMap() throws SQLException {
		String sql = """
				SELECT asset_id, asset_code FROM dbo.assets WHERE status <> 'DISPOSED'
				UNION
				SELECT asset_id, item_code AS asset_code FROM dbo.asset_items WHERE status <> 'DISPOSED'
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			java.util.Map<String, Long> map = new java.util.HashMap<>();
			while (result.next()) {
				String code = result.getString("asset_code");
				if (code != null && !code.isBlank()) {
					map.put(code.trim().toUpperCase(), result.getLong("asset_id"));
				}
			}
			return map;
		}
	}

	/** Tạo khóa duy nhất nhận diện một lịch theo thiết bị và ngày dự kiến. */
	public static String buildScheduleKey(long assetId, String itemCode, java.time.LocalDate date) {
		return assetId + "#" + (itemCode == null ? "" : itemCode.trim().toUpperCase()) + "#"
				+ (date == null ? "" : date.toString());
	}

	/**
	 * Lấy danh sách các khóa lịch đã tồn tại (PENDING hoặc COMPLETED) để chống
	 * trùng lặp ngày khi import.
	 */
	public java.util.Set<String> getExistingScheduleKeys() throws SQLException {
		String sql = "SELECT asset_id, ISNULL(item_code, '') AS item_code, scheduled_date FROM dbo.maintenance_schedules WHERE status IN ('PENDING', 'COMPLETED')";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			java.util.Set<String> set = new java.util.HashSet<>();
			while (result.next()) {
				long assetId = result.getLong("asset_id");
				String itemCode = result.getString("item_code");
				Date sDate = result.getDate("scheduled_date");
				if (sDate != null) {
					set.add(buildScheduleKey(assetId, itemCode, sDate.toLocalDate()));
				}
			}
			return set;
		}
	}

	/** Lấy một vài mã thiết bị mẫu cho template Excel. */
	public List<String> getSampleAssetCodes(int limit) throws SQLException {
		String sql = "SELECT TOP (?) asset_code FROM dbo.assets WHERE status <> 'DISPOSED' ORDER BY asset_id ASC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setInt(1, limit);
			try (ResultSet result = statement.executeQuery()) {
				List<String> list = new ArrayList<>();
				while (result.next()) {
					list.add(result.getString("asset_code"));
				}
				return list;
			}
		}
	}

	/**
	 * Lưu danh sách lịch bảo trì từ import Excel vào database trong cùng giao dịch.
	 */
	public int createBatch(List<MaintenanceSchedule> schedules) throws SQLException {
		if (schedules == null || schedules.isEmpty()) {
			return 0;
		}
		String sql = """
				INSERT INTO dbo.maintenance_schedules
				    (title, asset_id, item_code, scheduled_date, estimated_cost, provider_name, provider_phone, note, status, created_by, created_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?, SYSUTCDATETIME())
				""";
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try (PreparedStatement statement = connection.prepareStatement(sql)) {
				for (MaintenanceSchedule s : schedules) {
					statement.setString(1, s.getTitle().trim());
					statement.setLong(2, s.getAssetId());
					statement.setString(3, blankToNull(s.getItemCode()));
					statement.setDate(4, Date.valueOf(s.getScheduledDate()));
					setNullableLong(statement, 5, s.getEstimatedCost());
					statement.setString(6, blankToNull(s.getProviderName()));
					statement.setString(7, blankToNull(s.getProviderPhone()));
					statement.setString(8, blankToNull(s.getNote()));
					statement.setLong(9, s.getCreatedBy());
					statement.addBatch();
				}
				int[] results = statement.executeBatch();
				connection.commit();
				return results.length;
			} catch (SQLException e) {
				connection.rollback();
				throw e;
			}
		}
	}

	private MaintenanceSchedule mapRow(ResultSet result) throws SQLException {
		MaintenanceSchedule s = new MaintenanceSchedule();
		s.setScheduleId(result.getLong("schedule_id"));
		s.setTitle(result.getString("title"));
		s.setAssetId(result.getLong("asset_id"));
		s.setItemCode(result.getString("item_code"));

		Date schedDate = result.getDate("scheduled_date");
		if (schedDate != null) {
			s.setScheduledDate(schedDate.toLocalDate());
		}

		s.setEstimatedCost(nullableLong(result, "estimated_cost"));
		s.setProviderName(result.getString("provider_name"));
		s.setProviderPhone(result.getString("provider_phone"));
		s.setNote(result.getString("note"));
		s.setStatus(result.getString("status"));
		s.setCreatedBy(result.getLong("created_by"));

		s.setCreatedAt(toLocalDateTime(result.getTimestamp("created_at")));
		s.setUpdatedAt(toLocalDateTime(result.getTimestamp("updated_at")));

		s.setAssetCode(result.getString("asset_code"));
		s.setAssetName(result.getString("asset_name"));
		s.setStorageLocation(result.getString("storage_location"));
		s.setCreatorName(result.getString("creator_name"));
		s.setTargetAssetStatus(result.getString("target_asset_status"));
		return s;
	}

	private static Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}

	private static void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) {
			statement.setNull(index, java.sql.Types.BIGINT);
		} else {
			statement.setLong(index, value);
		}
	}

	private static String blankToNull(String value) {
		return value == null || value.trim().isEmpty() ? null : value.trim();
	}

	private static LocalDateTime toLocalDateTime(Timestamp ts) {
		return ts == null ? null : ts.toLocalDateTime();
	}
}
