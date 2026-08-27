package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.AssetItem;
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
				SELECT ii.*,
				       a.asset_code,
				       a.asset_name,
				       a.tracking_mode,
				       ai.item_code,
				       ai.serial_number,
				       ai.status AS asset_item_status
				FROM dbo.inspection_items ii
				JOIN dbo.assets a
				    ON a.asset_id = ii.asset_id
				LEFT JOIN dbo.asset_items ai
				    ON ai.asset_item_id = ii.asset_item_id
				   AND ai.asset_id = ii.asset_id
				WHERE ii.inspection_id = ?
				ORDER BY a.asset_name, ai.item_code, ii.inspection_item_id
				""";

		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {

			statement.setLong(1, inspectionId);
			return readItems(statement);
		}
	}

	public List<Semester> findSemesters() throws SQLException {

		String sql = """
				SELECT semester_id, code, name, start_date, end_date, status
				FROM dbo.semesters
				ORDER BY start_date DESC
				""";

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

	/*
	 * Kept from latest main for compatibility with code that directly requests
	 * physical asset items.
	 */
	public List<AssetItem> findInspectableItems() throws SQLException {

		String sql = """
				SELECT ai.asset_item_id,
				       ai.asset_id,
				       a.asset_code,
				       a.asset_name,
				       ai.item_code,
				       ai.serial_number,
				       ai.condition,
				       ai.status
				FROM dbo.asset_items ai
				JOIN dbo.assets a ON a.asset_id = ai.asset_id
				WHERE a.status <> 'DISPOSED'
				  AND ai.status <> 'DISPOSED'
				ORDER BY a.asset_name, ai.item_code
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
				item.setItemCode(result.getString("item_code"));
				item.setSerialNumber(result.getString("serial_number"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));

				items.add(item);
			}

			return items;
		}
	}

	/*
	 * Every inspection target is one physical AssetItem, regardless of the parent
	 * asset's tracking mode.
	 */
	public List<InspectionItem> findInspectableTargets() throws SQLException {
		try (Connection connection = db.getConnection()) {
			return findInspectableTargets(connection);
		}
	}

	public long create(long userId, InspectionRecord record, List<InspectionItem> items, boolean complete)
			throws SQLException {

		validateRecord(record);

		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);

			try {
				items = normalizeItems(connection, record.getScope(), items);

				validateItems(items, complete);
				validateAssets(connection, items);

				String status = complete ? "COMPLETED" : "DRAFT";
				String finalResult = complete ? resultFor(items) : null;

				String sql = """
						INSERT dbo.inspection_records
						    (semester_id, inspected_by, inspection_type, scope,
						     inspection_date, status, result, note)
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

		validateRecord(record);

		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);

			try {
				if (!isDraft(connection, id)) {
					throw new IllegalStateException("Chỉ có thể sửa đợt kiểm tra ở trạng thái bản nháp.");
				}

				items = normalizeItems(connection, record.getScope(), items);

				validateItems(items, complete);
				validateAssets(connection, items);

				String status = complete ? "COMPLETED" : "DRAFT";
				String finalResult = complete ? resultFor(items) : null;

				try (PreparedStatement statement = connection.prepareStatement("""
						UPDATE dbo.inspection_records
						SET semester_id = ?,
						    inspection_type = ?,
						    scope = ?,
						    inspection_date = ?,
						    status = ?,
						    result = ?,
						    note = ?,
						    updated_at = SYSUTCDATETIME()
						WHERE inspection_id = ?
						  AND status = 'DRAFT'
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
						throw new IllegalStateException("Chỉ có thể sửa đợt kiểm tra ở trạng thái bản nháp.");
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

	private void validateRecord(InspectionRecord record) {

		if (record.getSemesterId() == null) {
			throw new IllegalArgumentException("Vui lòng chọn học kỳ.");
		}

		if (!TYPES.contains(record.getInspectionType())) {
			throw new IllegalArgumentException("Loại kiểm tra không hợp lệ.");
		}

		if (!SCOPES.contains(record.getScope())) {
			throw new IllegalArgumentException("Phạm vi kiểm tra không hợp lệ.");
		}

		if (record.getInspectionDate() == null) {
			throw new IllegalArgumentException("Vui lòng nhập thời gian kiểm tra.");
		}
	}

	private List<InspectionItem> normalizeItems(Connection connection, String scope,
			List<InspectionItem> submittedItems) throws SQLException {

		if ("WHOLE_LAB".equals(scope)) {
			return wholeLabItems(connection, submittedItems);
		}

		return selectedAssetItems(connection, submittedItems);
	}

	private List<InspectionItem> wholeLabItems(Connection connection, List<InspectionItem> submittedItems)
			throws SQLException {

		List<InspectionItem> targets = findInspectableTargets(connection);
		List<InspectionItem> items = new ArrayList<>();

		for (InspectionItem target : targets) {
			InspectionItem submitted = findSubmittedItem(submittedItems, target);

			items.add(inspectionItemFor(target, submitted));
		}

		return items;
	}

	private List<InspectionItem> selectedAssetItems(Connection connection, List<InspectionItem> submittedItems)
			throws SQLException {

		Set<Long> selectedAssetItemIds = new HashSet<>();

		for (InspectionItem submitted : submittedItems) {
			if (submitted.getAssetItemId() == null) {
				throw new IllegalArgumentException("Vui lòng chọn một sản phẩm cụ thể để kiểm tra.");
			}
			selectedAssetItemIds.add(submitted.getAssetItemId());
		}

		List<InspectionItem> targets = findInspectableTargets(connection, selectedAssetItemIds);

		List<InspectionItem> items = new ArrayList<>();

		for (InspectionItem target : targets) {
			InspectionItem submitted = findSubmittedItem(submittedItems, target);

			items.add(inspectionItemFor(target, submitted));
		}

		return items;
	}

	private void validateItems(List<InspectionItem> items, boolean complete) {

		if (items == null || items.isEmpty()) {
			throw new IllegalArgumentException("Vui lòng chọn ít nhất một thiết bị để kiểm tra.");
		}

		Set<Long> quantityAssets = new HashSet<>();
		Set<Long> assetItems = new HashSet<>();

		for (InspectionItem item : items) {

			if (item.getAssetId() == null) {
				throw new IllegalArgumentException("Thiết bị đã chọn không tồn tại.");
			}

			if (item.getAssetItemId() == null) {
				if (!quantityAssets.add(item.getAssetId())) {
					throw new IllegalArgumentException(
							"Một thiết bị không được xuất hiện hai lần trong cùng đợt kiểm tra.");
				}
			} else {
				if (!assetItems.add(item.getAssetItemId())) {
					throw new IllegalArgumentException(
							"Một sản phẩm không được xuất hiện hai lần trong cùng đợt kiểm tra.");
				}
			}

			if (item.getExpectedQuantity() == null || item.getActualQuantity() == null || item.getExpectedQuantity() < 0
					|| item.getActualQuantity() < 0) {

				throw new IllegalArgumentException("Số lượng không được là số âm.");
			}

			if (!validCondition(item.getExpectedCondition()) || !validCondition(item.getActualCondition())) {

				throw new IllegalArgumentException("Tình trạng thiết bị không hợp lệ.");
			}

			if (item.getAssetItemId() != null || "SERIALIZED".equals(item.getTrackingMode())) {

				if (item.getExpectedQuantity() != 1) {
					throw new IllegalArgumentException("Thiết bị quản lý riêng lẻ phải có số lượng dự kiến bằng 1.");
				}

				if (item.getActualQuantity() != 0 && item.getActualQuantity() != 1) {

					throw new IllegalArgumentException(
							"Thiết bị quản lý riêng lẻ chỉ cho phép số lượng thực tế là 0 hoặc 1.");
				}
			}
		}

		if (!STATUSES.contains(complete ? "COMPLETED" : "DRAFT")) {
			throw new IllegalArgumentException("Trạng thái kiểm tra không hợp lệ.");
		}
	}

	private List<InspectionItem> findInspectableTargets(Connection connection) throws SQLException {

		return findInspectableTargets(connection, null);
	}

	private List<InspectionItem> findInspectableTargets(Connection connection, Set<Long> selectedAssetItemIds)
			throws SQLException {

		String filter = selectedAssetItemIds == null ? "" : " AND ai.asset_item_id = ?";

		String sql = """
				SELECT
				    a.asset_id,
				    ai.asset_item_id,
				    a.asset_code,
				    a.asset_name,
				    a.tracking_mode,
				    1 AS total_quantity,
				    ai.condition,
				    a.status,
				    ai.item_code,
				    ai.serial_number,
				    ai.status AS asset_item_status
				FROM dbo.assets a WITH (UPDLOCK, HOLDLOCK)
				JOIN dbo.asset_items ai WITH (UPDLOCK, HOLDLOCK)
				    ON ai.asset_id = a.asset_id
				WHERE a.status <> 'DISPOSED'
				  AND ai.status <> 'DISPOSED'
				""" + filter + """

				ORDER BY asset_name, item_code, asset_code
				""";

		List<InspectionItem> items = new ArrayList<>();

		if (selectedAssetItemIds == null) {
			try (PreparedStatement statement = connection.prepareStatement(sql);
					ResultSet result = statement.executeQuery()) {

				while (result.next()) {
					items.add(readInspectableTarget(result));
				}
			}

			return items;
		}

		for (Long assetItemId : selectedAssetItemIds) {
			try (PreparedStatement statement = connection.prepareStatement(sql)) {

				statement.setLong(1, assetItemId);

				try (ResultSet result = statement.executeQuery()) {
					while (result.next()) {
						items.add(readInspectableTarget(result));
					}
				}
			}
		}

		return items;
	}

	private InspectionItem readInspectableTarget(ResultSet result) throws SQLException {

		InspectionItem item = new InspectionItem();

		item.setAssetId(result.getLong("asset_id"));
		item.setAssetItemId(nullableLong(result, "asset_item_id"));

		item.setAssetCode(result.getString("asset_code"));

		item.setAssetName(result.getString("asset_name"));

		item.setTrackingMode(result.getString("tracking_mode"));

		item.setExpectedQuantity(result.getInt("total_quantity"));

		item.setActualQuantity(result.getInt("total_quantity"));

		item.setExpectedCondition(result.getString("condition"));

		item.setActualCondition(result.getString("condition"));

		item.setItemCode(result.getString("item_code"));

		item.setSerialNumber(result.getString("serial_number"));

		item.setAssetItemStatus(result.getString("asset_item_status"));

		return item;
	}

	private InspectionItem inspectionItemFor(InspectionItem target, InspectionItem submitted) {

		InspectionItem item = new InspectionItem();

		item.setAssetId(target.getAssetId());
		item.setAssetItemId(target.getAssetItemId());
		item.setTrackingMode(target.getTrackingMode());

		item.setAssetCode(target.getAssetCode());
		item.setAssetName(target.getAssetName());

		item.setItemCode(target.getItemCode());
		item.setSerialNumber(target.getSerialNumber());
		item.setAssetItemStatus(target.getAssetItemStatus());

		item.setExpectedQuantity(target.getAssetItemId() != null
				? 1
				: positiveOrDefault(submitted == null ? null : submitted.getExpectedQuantity(),
						target.getExpectedQuantity()));

		item.setActualQuantity(target.getAssetItemId() != null
				? serializedActual(submitted == null ? null : submitted.getActualQuantity())
				: nonNegativeOrDefault(submitted == null ? null : submitted.getActualQuantity(),
						target.getActualQuantity()));

		item.setExpectedCondition(firstNonBlank(submitted == null ? null : submitted.getExpectedCondition(),
				target.getExpectedCondition()));

		item.setActualCondition(
				firstNonBlank(submitted == null ? null : submitted.getActualCondition(), target.getActualCondition()));

		item.setDiscrepancyType(submitted == null ? null : submitted.getDiscrepancyType());

		item.setDiscrepancyNote(submitted == null ? null : submitted.getDiscrepancyNote());

		return item;
	}

	private InspectionItem findSubmittedItem(List<InspectionItem> items, InspectionItem target) {

		for (InspectionItem item : items) {

			if (target.getAssetItemId() != null && target.getAssetItemId().equals(item.getAssetItemId())) {

				return item;
			}

			if (target.getAssetItemId() == null && item.getAssetItemId() == null
					&& target.getAssetId().equals(item.getAssetId())) {

				return item;
			}
		}

		return null;
	}

	private int serializedActual(Integer value) {
		return value == null ? 1 : value;
	}

	private int positiveOrDefault(Integer value, Integer defaultValue) {

		return value == null ? defaultValue : value;
	}

	private int nonNegativeOrDefault(Integer value, Integer defaultValue) {

		return value == null ? defaultValue : value;
	}

	private String firstNonBlank(String value, String fallback) {

		return value == null || value.isBlank() ? fallback : value;
	}

	private void validateAssets(Connection connection, List<InspectionItem> items) throws SQLException {

		for (InspectionItem item : items) {

			try (PreparedStatement statement = connection.prepareStatement("""
					SELECT
					    a.status AS asset_status,
					    ai.status AS asset_item_status
					FROM dbo.assets a WITH (UPDLOCK, HOLDLOCK)
					LEFT JOIN dbo.asset_items ai WITH (UPDLOCK, HOLDLOCK)
					    ON ai.asset_item_id = ?
					   AND ai.asset_id = a.asset_id
					WHERE a.asset_id = ?
					""")) {

				setNullableLong(statement, 1, item.getAssetItemId());

				statement.setLong(2, item.getAssetId());

				try (ResultSet result = statement.executeQuery()) {

					if (!result.next()) {
						throw new IllegalArgumentException("Thiết bị đã chọn không tồn tại.");
					}

					if ("DISPOSED".equals(result.getString("asset_status"))) {

						throw new IllegalStateException("Không thể chọn thiết bị đã thanh lý làm đối tượng kiểm tra.");
					}

					if (item.getAssetItemId() != null && result.getString("asset_item_status") == null) {

						throw new IllegalArgumentException(
								"Sản phẩm đã chọn không tồn tại hoặc không thuộc thiết bị này.");
					}

					if ("DISPOSED".equals(result.getString("asset_item_status"))) {

						throw new IllegalStateException(
								"Không thể chọn thiết bị riêng lẻ đã thanh lý làm đối tượng kiểm tra.");
					}
				}
			}
		}
	}

	private void insertItems(Connection connection, long inspectionId, List<InspectionItem> items) throws SQLException {

		String sql = """
				INSERT dbo.inspection_items
				    (inspection_id,
				     asset_id,
				     asset_item_id,
				     expected_quantity,
				     actual_quantity,
				     expected_condition,
				     actual_condition,
				     discrepancy_type,
				     discrepancy_note)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
				""";

		try (PreparedStatement statement = connection.prepareStatement(sql)) {

			for (InspectionItem item : items) {

				statement.setLong(1, inspectionId);

				statement.setLong(2, item.getAssetId());

				setNullableLong(statement, 3, item.getAssetItemId());

				statement.setInt(4, item.getExpectedQuantity());

				statement.setInt(5, item.getActualQuantity());

				statement.setString(6, blankToNull(item.getExpectedCondition()));

				statement.setString(7, blankToNull(item.getActualCondition()));

				statement.setString(8, blankToNull(item.getDiscrepancyType()));

				statement.setString(9, blankToNull(item.getDiscrepancyNote()));

				statement.addBatch();
			}

			statement.executeBatch();
		}
	}

	private boolean isDraft(Connection connection, long id) throws SQLException {

		try (PreparedStatement statement = connection.prepareStatement("""
				SELECT 1
				FROM dbo.inspection_records
				    WITH (UPDLOCK, HOLDLOCK)
				WHERE inspection_id = ?
				  AND status = 'DRAFT'
				""")) {

			statement.setLong(1, id);

			try (ResultSet result = statement.executeQuery()) {

				return result.next();
			}
		}
	}

	private String resultFor(List<InspectionItem> items) {

		String value = items.stream().anyMatch(InspectionItem::isAbnormal) ? "DISCREPANCY_FOUND" : "NORMAL";

		if (!RESULTS.contains(value)) {
			throw new IllegalStateException("Kết quả kiểm tra không hợp lệ.");
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

				record.setInspectionDate(ViewFormat.fromUtc(result.getTimestamp("inspection_date")));

				record.setStatus(result.getString("status"));

				record.setResult(result.getString("result"));

				record.setNote(result.getString("note"));

				record.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));

				record.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));

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

				item.setAssetItemId(nullableLong(result, "asset_item_id"));

				item.setExpectedQuantity(result.getInt("expected_quantity"));

				item.setActualQuantity(result.getInt("actual_quantity"));

				item.setExpectedCondition(result.getString("expected_condition"));

				item.setActualCondition(result.getString("actual_condition"));

				item.setDiscrepancyType(result.getString("discrepancy_type"));

				item.setDiscrepancyNote(result.getString("discrepancy_note"));

				item.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));

				item.setAssetCode(result.getString("asset_code"));

				item.setAssetName(result.getString("asset_name"));

				item.setTrackingMode(result.getString("tracking_mode"));

				item.setItemCode(result.getString("item_code"));

				item.setSerialNumber(result.getString("serial_number"));

				item.setAssetItemStatus(result.getString("asset_item_status"));

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
		return ViewFormat.toUtc(value);
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

	private Long nullableLong(ResultSet result, String column) throws SQLException {

		long value = result.getLong(column);

		return result.wasNull() ? null : value;
	}

	private String clean(String value) {
		return value == null ? "" : value.trim();
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
