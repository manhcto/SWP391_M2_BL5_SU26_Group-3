package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.InspectionItem;
import fpt.swp391.labtoolequip.model.InspectionRecord;
import fpt.swp391.labtoolequip.model.Semester;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import util.AppConfig;

public class InspectionDAO {
	private static final Set<String> TYPES = Set.of("INSPECTION", "INVENTORY");
	private static final Set<String> SCOPES = Set.of("WHOLE_LAB", "SELECTED_ASSETS");
	private static final Set<String> STATUSES = Set.of("DRAFT", "COMPLETED");
	private static final Set<String> RESULTS = Set.of("NORMAL", "DISCREPANCY_FOUND");
	private static final Set<String> CONDITIONS = Set.of("GOOD", "FAIR", "DAMAGED", "BROKEN");
	private static final String SELECT_RECORD = """
			SELECT ir.*, s.code AS semester_code, s.name AS semester_name,
			       u.full_name AS inspector_name, u.email AS inspector_email
			FROM dbo.inspection_records ir
			JOIN dbo.semesters s ON s.semester_id = ir.semester_id
			JOIN dbo.users u ON u.user_id = ir.inspected_by
			""";
	private final DBConnection db = new DBConnection();
	private final ZoneId labZone = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));

	public List<InspectionRecord> findAll(String semesterId, String type, String status, String result, String fromDate,
			String toDate) throws SQLException {
		String sql = SELECT_RECORD + """
				WHERE (? IS NULL OR ir.semester_id = ?)
				  AND (? = '' OR ir.inspection_type = ?)
				  AND (? = '' OR ir.status = ?)
				  AND (? = '' OR ir.result = ?)
				  AND (? IS NULL OR ir.inspection_date >= ?)
				  AND (? IS NULL OR ir.inspection_date <= ?)
				ORDER BY ir.inspection_date DESC, ir.inspection_id DESC
				""";
		Long semester = parseLongOrNull(semesterId);
		String selectedType = clean(type);
		String selectedStatus = clean(status);
		String selectedResult = clean(result);
		Timestamp from = startOfDay(fromDate);
		Timestamp to = endOfDay(toDate);
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			setNullableLong(statement, 1, semester);
			setNullableLong(statement, 2, semester);
			statement.setString(3, selectedType);
			statement.setString(4, selectedType);
			statement.setString(5, selectedStatus);
			statement.setString(6, selectedStatus);
			statement.setString(7, selectedResult);
			statement.setString(8, selectedResult);
			statement.setTimestamp(9, from);
			statement.setTimestamp(10, from);
			statement.setTimestamp(11, to);
			statement.setTimestamp(12, to);
			return readRecords(statement);
		}
	}

	public Optional<InspectionRecord> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection
						.prepareStatement(SELECT_RECORD + " WHERE ir.inspection_id = ?")) {
			statement.setLong(1, id);
			return readRecords(statement).stream().findFirst();
		}
	}

	public List<InspectionItem> findItems(long inspectionId) throws SQLException {
		String sql = """
				SELECT ii.*, a.asset_code, a.asset_name
				FROM dbo.inspection_items ii
				JOIN dbo.assets a ON a.asset_id = ii.asset_id
				WHERE ii.inspection_id = ?
				ORDER BY a.asset_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, inspectionId);
			return readItems(statement);
		}
	}

	public List<Semester> findSemesters() throws SQLException {
		String sql = "SELECT semester_id, code, name, start_date, end_date, status FROM dbo.semesters ORDER BY start_date DESC";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<Semester> semesters = new ArrayList<>();
			while (result.next()) {
				Semester semester = new Semester();
				semester.setSemesterId(result.getLong("semester_id"));
				semester.setCode(result.getString("code"));
				semester.setName(result.getString("name"));
				semester.setStartDate(result.getDate("start_date").toLocalDate());
				semester.setEndDate(result.getDate("end_date").toLocalDate());
				semester.setStatus(result.getString("status"));
				semesters.add(semester);
			}
			return semesters;
		}
	}

	public List<Asset> findInspectableAssets() throws SQLException {
		String sql = """
				SELECT asset_id, asset_code, asset_name, total_quantity, condition, status, storage_location
				FROM dbo.assets
				WHERE status <> 'DISPOSED'
				ORDER BY asset_name
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
				asset.setStatus(result.getString("status"));
				asset.setStorageLocation(result.getString("storage_location"));
				assets.add(asset);
			}
			return assets;
		}
	}

	public long create(long userId, InspectionRecord record, List<InspectionItem> items, boolean complete)
			throws SQLException {
		validate(record, items, complete);
		String status = complete ? "COMPLETED" : "DRAFT";
		String finalResult = complete ? resultFor(items) : null;
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				validateAssets(connection, items);
				String sql = """
						INSERT dbo.inspection_records
						    (semester_id, inspected_by, inspection_type, scope, inspection_date, status, result, note)
						OUTPUT INSERTED.inspection_id
						VALUES (?, ?, ?, ?, ?, ?, ?, ?)
						""";
				long id;
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					statement.setLong(1, record.getSemesterId());
					statement.setLong(2, userId);
					statement.setString(3, record.getInspectionType());
					statement.setString(4, record.getScope());
					statement.setTimestamp(5, utc(record.getInspectionDate()));
					statement.setString(6, status);
					statement.setString(7, finalResult);
					statement.setString(8, blankToNull(record.getNote()));
					try (ResultSet result = statement.executeQuery()) {
						result.next();
						id = result.getLong(1);
					}
				}
				insertItems(connection, id, items);
				connection.commit();
				return id;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updateDraft(long id, InspectionRecord record, List<InspectionItem> items, boolean complete)
			throws SQLException {
		validate(record, items, complete);
		String status = complete ? "COMPLETED" : "DRAFT";
		String finalResult = complete ? resultFor(items) : null;
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				if (!isDraft(connection, id)) {
					throw new IllegalStateException("Only draft inspections can be edited.");
				}
				validateAssets(connection, items);
				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.inspection_records
						SET semester_id = ?, inspection_type = ?, scope = ?, inspection_date = ?, status = ?,
						    result = ?, note = ?, updated_at = SYSUTCDATETIME()
						WHERE inspection_id = ? AND status = 'DRAFT'
						""")) {
					statement.setLong(1, record.getSemesterId());
					statement.setString(2, record.getInspectionType());
					statement.setString(3, record.getScope());
					statement.setTimestamp(4, utc(record.getInspectionDate()));
					statement.setString(5, status);
					statement.setString(6, finalResult);
					statement.setString(7, blankToNull(record.getNote()));
					statement.setLong(8, id);
					if (statement.executeUpdate() != 1) {
						throw new IllegalStateException("Only draft inspections can be edited.");
					}
				}
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE FROM dbo.inspection_items WHERE inspection_id = ?")) {
					statement.setLong(1, id);
					statement.executeUpdate();
				}
				insertItems(connection, id, items);
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private void validate(InspectionRecord record, List<InspectionItem> items, boolean complete) {
		if (record.getSemesterId() == null) {
			throw new IllegalArgumentException("Semester is required.");
		}
		if (!TYPES.contains(record.getInspectionType())) {
			throw new IllegalArgumentException("Inspection type is invalid.");
		}
		if (!SCOPES.contains(record.getScope())) {
			throw new IllegalArgumentException("Inspection scope is invalid.");
		}
		if (record.getInspectionDate() == null) {
			throw new IllegalArgumentException("Inspection date is required.");
		}
		if (items.isEmpty()) {
			throw new IllegalArgumentException("Select at least one asset for inspection.");
		}
		Set<Long> assets = new HashSet<>();
		for (InspectionItem item : items) {
			if (item.getAssetId() == null || !assets.add(item.getAssetId())) {
				throw new IllegalArgumentException("An asset must not appear twice in one inspection.");
			}
			if (item.getExpectedQuantity() == null || item.getActualQuantity() == null || item.getExpectedQuantity() < 0
					|| item.getActualQuantity() < 0) {
				throw new IllegalArgumentException("Quantities must not be negative.");
			}
			if (!validCondition(item.getExpectedCondition()) || !validCondition(item.getActualCondition())) {
				throw new IllegalArgumentException("Asset condition value is invalid.");
			}
		}
		if (!STATUSES.contains(complete ? "COMPLETED" : "DRAFT")) {
			throw new IllegalArgumentException("Inspection status is invalid.");
		}
	}

	private void validateAssets(Connection connection, List<InspectionItem> items) throws SQLException {
		for (InspectionItem item : items) {
			try (PreparedStatement statement = connection
					.prepareStatement("SELECT status FROM dbo.assets WITH (UPDLOCK, HOLDLOCK) WHERE asset_id = ?")) {
				statement.setLong(1, item.getAssetId());
				try (ResultSet result = statement.executeQuery()) {
					if (!result.next()) {
						throw new IllegalArgumentException("Selected asset does not exist.");
					}
					if ("DISPOSED".equals(result.getString("status"))) {
						throw new IllegalStateException("Disposed assets cannot be inspected as active targets.");
					}
				}
			}
		}
	}

	private void insertItems(Connection connection, long inspectionId, List<InspectionItem> items) throws SQLException {
		String sql = """
				INSERT dbo.inspection_items
				    (inspection_id, asset_id, expected_quantity, actual_quantity, expected_condition,
				     actual_condition, discrepancy_type, discrepancy_note)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			for (InspectionItem item : items) {
				statement.setLong(1, inspectionId);
				statement.setLong(2, item.getAssetId());
				statement.setInt(3, item.getExpectedQuantity());
				statement.setInt(4, item.getActualQuantity());
				statement.setString(5, blankToNull(item.getExpectedCondition()));
				statement.setString(6, blankToNull(item.getActualCondition()));
				statement.setString(7, blankToNull(item.getDiscrepancyType()));
				statement.setString(8, blankToNull(item.getDiscrepancyNote()));
				statement.addBatch();
			}
			statement.executeBatch();
		}
	}

	private boolean isDraft(Connection connection, long id) throws SQLException {
		try (PreparedStatement statement = connection.prepareStatement(
				"SELECT 1 FROM dbo.inspection_records WITH (UPDLOCK, HOLDLOCK) WHERE inspection_id = ? AND status = 'DRAFT'")) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	private String resultFor(List<InspectionItem> items) {
		String value = items.stream().anyMatch(InspectionItem::isAbnormal) ? "DISCREPANCY_FOUND" : "NORMAL";
		if (!RESULTS.contains(value)) {
			throw new IllegalStateException("Inspection result is invalid.");
		}
		return value;
	}

	private boolean validCondition(String condition) {
		return condition == null || condition.isBlank() || CONDITIONS.contains(condition);
	}

	private List<InspectionRecord> readRecords(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<InspectionRecord> records = new ArrayList<>();
			while (result.next()) {
				InspectionRecord record = new InspectionRecord();
				record.setInspectionId(result.getLong("inspection_id"));
				record.setSemesterId(result.getLong("semester_id"));
				record.setInspectedBy(result.getLong("inspected_by"));
				record.setInspectionType(result.getString("inspection_type"));
				record.setScope(result.getString("scope"));
				record.setInspectionDate(local(result.getTimestamp("inspection_date")));
				record.setStatus(result.getString("status"));
				record.setResult(result.getString("result"));
				record.setNote(result.getString("note"));
				record.setCreatedAt(local(result.getTimestamp("created_at")));
				record.setUpdatedAt(local(result.getTimestamp("updated_at")));
				record.setSemesterCode(result.getString("semester_code"));
				record.setSemesterName(result.getString("semester_name"));
				record.setInspectorName(result.getString("inspector_name"));
				record.setInspectorEmail(result.getString("inspector_email"));
				records.add(record);
			}
			return records;
		}
	}

	private List<InspectionItem> readItems(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<InspectionItem> items = new ArrayList<>();
			while (result.next()) {
				InspectionItem item = new InspectionItem();
				item.setInspectionItemId(result.getLong("inspection_item_id"));
				item.setInspectionId(result.getLong("inspection_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setExpectedQuantity(result.getInt("expected_quantity"));
				item.setActualQuantity(result.getInt("actual_quantity"));
				item.setExpectedCondition(result.getString("expected_condition"));
				item.setActualCondition(result.getString("actual_condition"));
				item.setDiscrepancyType(result.getString("discrepancy_type"));
				item.setDiscrepancyNote(result.getString("discrepancy_note"));
				item.setCreatedAt(local(result.getTimestamp("created_at")));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				items.add(item);
			}
			return items;
		}
	}

	private Timestamp startOfDay(String value) {
		return value == null || value.isBlank() ? null : utc(LocalDate.parse(value).atStartOfDay());
	}

	private Timestamp endOfDay(String value) {
		return value == null || value.isBlank() ? null : utc(LocalDate.parse(value).atTime(LocalTime.MAX.withNano(0)));
	}

	private Timestamp utc(LocalDateTime value) {
		return Timestamp.valueOf(value.atZone(labZone).withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime());
	}

	private LocalDateTime local(Timestamp value) {
		return value == null
				? null
				: value.toLocalDateTime().atZone(ZoneOffset.UTC).withZoneSameInstant(labZone).toLocalDateTime();
	}

	private Long parseLongOrNull(String value) {
		return value == null || value.isBlank() ? null : Long.parseLong(value);
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) {
			statement.setObject(index, null);
		} else {
			statement.setLong(index, value);
		}
	}

	private String clean(String value) {
		return value == null ? "" : value.trim();
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
