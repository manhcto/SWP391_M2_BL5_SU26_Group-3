package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.AssetCategory;
import fpt.swp391.labtoolequip.model.AssetItem;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class AssetItemDAO {
	private static final String SELECT = """
			SELECT i.*, a.asset_code, a.asset_name, a.is_borrowable, c.category_name
			FROM dbo.asset_items i
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			JOIN dbo.asset_categories c ON c.category_id = a.category_id
			""";
	private final DBConnection db = new DBConnection();

	public List<AssetItem> findAll(String keyword, String status, String condition) throws SQLException {
		return findAll(keyword, status, condition, "");
	}

	public List<AssetItem> findAll(String keyword, String status, String condition, String categoryName)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String quality = condition == null ? "" : condition.trim();
		String category = categoryName == null ? "" : categoryName.trim();
		String sql = SELECT + """
				WHERE (? = '' OR i.item_code LIKE ? OR i.serial_number LIKE ? OR a.asset_name LIKE ?
				       OR a.asset_code LIKE ? OR c.category_name LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.condition = ?)
				  AND (? = '' OR c.category_name = ?)
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, quality);
			statement.setString(index++, quality);
			statement.setString(index++, category);
			statement.setString(index, category);
			return read(statement);
		}
	}

	public Optional<AssetItem> findById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT + " WHERE i.asset_item_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<AssetItem> findBorrowable(String keyword) throws SQLException {
		return findBorrowable(keyword, "");
	}

	public List<AssetItem> findBorrowable(String keyword, String categoryName) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String category = categoryName == null ? "" : categoryName.trim();
		String sql = SELECT + """
				WHERE a.is_borrowable = 1 AND i.status = 'AVAILABLE' AND i.condition IN ('GOOD', 'FAIR')
				  AND (? = '' OR i.item_code LIKE ? OR i.serial_number LIKE ? OR a.asset_name LIKE ?
				       OR a.asset_code LIKE ? OR c.category_name LIKE ?)
				  AND (? = '' OR c.category_name = ?)
				ORDER BY a.asset_name, i.item_code
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, category);
			statement.setString(index, category);
			return read(statement);
		}
	}

	public Optional<AssetItem> findBorrowableById(long id) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(SELECT
						+ " WHERE a.is_borrowable = 1 AND i.status = 'AVAILABLE' AND i.condition IN ('GOOD', 'FAIR') AND i.asset_item_id = ?")) {
			statement.setLong(1, id);
			return read(statement).stream().findFirst();
		}
	}

	public List<AssetCategory> findCategories() throws SQLException {
		String sql = "SELECT category_id, category_name FROM dbo.asset_categories WHERE status = 'ACTIVE' ORDER BY category_name";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetCategory> categories = new ArrayList<>();
			while (result.next()) {
				AssetCategory category = new AssetCategory();
				category.setCategoryId(result.getLong("category_id"));
				category.setCategoryName(result.getString("category_name"));
				categories.add(category);
			}
			return categories;
		}
	}

	public List<AssetCategory> findBorrowableCategories() throws SQLException {
		String sql = """
				SELECT DISTINCT c.category_id, c.category_name
				FROM dbo.asset_categories c
				JOIN dbo.assets a ON a.category_id = c.category_id
				JOIN dbo.asset_items i ON i.asset_id = a.asset_id
				WHERE c.status = 'ACTIVE' AND a.is_borrowable = 1
				  AND i.status = 'AVAILABLE' AND i.condition IN ('GOOD', 'FAIR')
				ORDER BY c.category_name
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql);
				ResultSet result = statement.executeQuery()) {
			List<AssetCategory> categories = new ArrayList<>();
			while (result.next()) {
				AssetCategory category = new AssetCategory();
				category.setCategoryId(result.getLong("category_id"));
				category.setCategoryName(result.getString("category_name"));
				categories.add(category);
			}
			return categories;
		}
	}

	public long createBundle(String assetCode, String assetName, long categoryId, boolean borrowable,
			String description, List<AssetItem> items) throws SQLException {
		if (assetCode == null || assetCode.isBlank() || assetName == null || assetName.isBlank() || items == null
				|| items.isEmpty())
			throw new IllegalArgumentException("Vui lòng nhập mã, tên và số lượng sản phẩm lớn hơn 0.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long assetId = insertAsset(connection, assetCode.trim(), assetName.trim(), categoryId, borrowable,
						description, items.size());
				for (int index = 0; index < items.size(); index++)
					insertItem(connection, assetId, assetCode.trim(), index + 1, items.get(index));
				refreshAssetCondition(connection, assetId);
				connection.commit();
				return assetId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updateItem(AssetItem item) throws SQLException {
		if (item == null || item.getAssetItemId() == null)
			throw new IllegalArgumentException("Không tìm thấy sản phẩm cần cập nhật.");
		validateItem(item);
		String sql = """
				UPDATE dbo.asset_items
				SET serial_number = ?, image_path = ?, condition = ?, status = ?,
				    purchase_date = ?, warranty_until = ?, note = ?, updated_at = SYSUTCDATETIME()
				WHERE asset_item_id = ?
				""";
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				try (PreparedStatement statement = connection.prepareStatement(sql)) {
					setNullableString(statement, 1, item.getSerialNumber());
					setNullableString(statement, 2, item.getImagePath());
					statement.setString(3, item.getCondition());
					statement.setString(4, item.getStatus());
					setNullableDate(statement, 5, item.getPurchaseDate());
					setNullableDate(statement, 6, item.getWarrantyUntil());
					setNullableString(statement, 7, item.getNote());
					statement.setLong(8, item.getAssetItemId());
					if (statement.executeUpdate() == 0)
						throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
				}
				refreshAssetCondition(connection, assetIdOf(connection, item.getAssetItemId()));
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				try {
					connection.rollback();
				} catch (SQLException rollbackException) {
					exception.addSuppressed(rollbackException);
				}
				throw exception;
			}
		}
	}

	public void deleteItem(long assetItemId) throws SQLException {
		if (assetItemId <= 0)
			throw new IllegalArgumentException("Mã sản phẩm không hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				long assetId;
				int totalQuantity;
				String lookup = """
						SELECT i.asset_id, a.total_quantity
						FROM dbo.asset_items i WITH (UPDLOCK, HOLDLOCK)
						JOIN dbo.assets a WITH (UPDLOCK, HOLDLOCK) ON a.asset_id = i.asset_id
						WHERE i.asset_item_id = ?
						""";
				try (PreparedStatement statement = connection.prepareStatement(lookup)) {
					statement.setLong(1, assetItemId);
					try (ResultSet result = statement.executeQuery()) {
						if (!result.next())
							throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
						assetId = result.getLong("asset_id");
						totalQuantity = result.getInt("total_quantity");
					}
				}
				if (totalQuantity <= 1)
					throw new IllegalArgumentException("Không thể xóa sản phẩm cuối cùng của thiết bị.");
				if (hasUsageHistory(connection, assetId))
					throw new IllegalArgumentException("Không thể xóa sản phẩm đã có lịch sử sử dụng.");
				try (PreparedStatement statement = connection
						.prepareStatement("DELETE FROM dbo.asset_items WHERE asset_item_id = ?")) {
					statement.setLong(1, assetItemId);
					if (statement.executeUpdate() == 0)
						throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
				}
				try (PreparedStatement statement = connection.prepareStatement(
						"UPDATE dbo.assets SET total_quantity = total_quantity - 1, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
					statement.setLong(1, assetId);
					statement.executeUpdate();
				}
				refreshAssetCondition(connection, assetId);
				connection.commit();
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	private long assetIdOf(Connection connection, long assetItemId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT asset_id FROM dbo.asset_items WHERE asset_item_id = ?")) {
			statement.setLong(1, assetItemId);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next())
					throw new IllegalArgumentException("Sản phẩm không còn tồn tại.");
				return result.getLong(1);
			}
		}
	}

	private boolean hasUsageHistory(Connection connection, long assetId) throws SQLException {
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT 1 FROM dbo.asset_usages WHERE asset_id = ?")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				return result.next();
			}
		}
	}

	static void refreshAssetCondition(Connection connection, long assetId) throws SQLException {
		String condition = "GOOD";
		try (PreparedStatement statement = connection
				.prepareStatement("SELECT condition FROM dbo.asset_items WHERE asset_id = ?")) {
			statement.setLong(1, assetId);
			try (ResultSet result = statement.executeQuery()) {
				int worst = 0;
				while (result.next()) {
					String value = result.getString(1);
					if (value == null || value.isBlank())
						continue;
					int rank = conditionRank(value);
					if (rank > worst) {
						worst = rank;
						condition = value;
					}
				}
			}
		}
		try (PreparedStatement statement = connection.prepareStatement(
				"UPDATE dbo.assets SET condition = ?, updated_at = SYSUTCDATETIME() WHERE asset_id = ?")) {
			statement.setString(1, condition);
			statement.setLong(2, assetId);
			statement.executeUpdate();
		}
	}

	private static int conditionRank(String condition) {
		return switch (condition) {
			case "BROKEN" -> 4;
			case "DAMAGED" -> 3;
			case "FAIR" -> 2;
			default -> 1;
		};
	}

	private long insertAsset(Connection connection, String code, String name, long categoryId, boolean borrowable,
			String description, int quantity) throws SQLException {
		String sql = """
				INSERT dbo.assets (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
				                  is_borrowable, description)
				OUTPUT INSERTED.asset_id
				VALUES (?, ?, ?, 'QUANTITY', ?, 'GOOD', 'AVAILABLE', ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, code);
			statement.setString(2, name);
			statement.setLong(3, categoryId);
			statement.setInt(4, quantity);
			statement.setBoolean(5, borrowable);
			setNullableString(statement, 6, description);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getLong(1);
			}
		}
	}

	private void insertItem(Connection connection, long assetId, String baseCode, int sequence, AssetItem item)
			throws SQLException {
		validateItem(item);
		String sql = """
				INSERT dbo.asset_items (asset_id, item_code, serial_number, image_path, condition, status,
				                       storage_location, purchase_date, warranty_until, note)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				""";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, assetId);
			statement.setString(2, baseCode + "-" + String.format("%04d", sequence));
			setNullableString(statement, 3, item.getSerialNumber());
			setNullableString(statement, 4, item.getImagePath());
			statement.setString(5, item.getCondition());
			statement.setString(6, item.getStatus());
			setNullableString(statement, 7, item.getStorageLocation());
			setNullableDate(statement, 8, item.getPurchaseDate());
			setNullableDate(statement, 9, item.getWarrantyUntil());
			setNullableString(statement, 10, item.getNote());
			statement.executeUpdate();
		}
	}

	private List<AssetItem> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<AssetItem> items = new ArrayList<>();
			while (result.next()) {
				AssetItem item = new AssetItem();
				item.setAssetItemId(result.getLong("asset_item_id"));
				item.setAssetId(result.getLong("asset_id"));
				item.setAssetCode(result.getString("asset_code"));
				item.setAssetName(result.getString("asset_name"));
				item.setBorrowable(result.getBoolean("is_borrowable"));
				item.setCategoryName(result.getString("category_name"));
				item.setItemCode(result.getString("item_code"));
				item.setSerialNumber(result.getString("serial_number"));
				item.setImagePath(result.getString("image_path"));
				item.setCondition(result.getString("condition"));
				item.setStatus(result.getString("status"));
				item.setStorageLocation(result.getString("storage_location"));
				item.setPurchaseDate(nullableDate(result, "purchase_date"));
				item.setWarrantyUntil(nullableDate(result, "warranty_until"));
				item.setNote(result.getString("note"));
				item.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				item.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				items.add(item);
			}
			return items;
		}
	}

	private void validateItem(AssetItem item) {
		if (item == null)
			throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ.");
		if (!List.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(item.getCondition()))
			throw new IllegalArgumentException("Tình trạng sản phẩm không hợp lệ.");
		if (!List.of("AVAILABLE", "MAINTENANCE", "UNAVAILABLE", "DISPOSED").contains(item.getStatus()))
			throw new IllegalArgumentException("Trạng thái sản phẩm không hợp lệ.");
		if (("DAMAGED".equals(item.getCondition()) || "BROKEN".equals(item.getCondition()))
				&& !List.of("MAINTENANCE", "DISPOSED").contains(item.getStatus()))
			throw new IllegalArgumentException(
					"Sản phẩm hư hỏng nặng phải chuyển sang Đang bảo trì và được Mentor báo cáo Lab Manager.");
		if (item.getSerialNumber() != null && item.getSerialNumber().length() > 100)
			throw new IllegalArgumentException("Serial không được dài quá 100 ký tự.");
	}

	private void setNullableString(PreparedStatement statement, int index, String value) throws SQLException {
		if (value == null || value.isBlank())
			statement.setNull(index, Types.NVARCHAR);
		else
			statement.setString(index, value.trim());
	}

	private void setNullableDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
		if (value == null)
			statement.setNull(index, Types.DATE);
		else
			statement.setObject(index, value);
	}

	private LocalDate nullableDate(ResultSet result, String column) throws SQLException {
		java.sql.Date value = result.getDate(column);
		return value == null ? null : value.toLocalDate();
	}
}
