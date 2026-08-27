package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.AssetItem;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;

class AssetItemDAOTest {
	@Test
	void acceptsAvailableAssetItemsInUsableConditions() {
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(item("GOOD", "AVAILABLE", "SN-001")));
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(item("FAIR", "AVAILABLE", "SN-002")));
	}

	@Test
	void acceptsDamagedOrBrokenItemsOnlyWhenRemovedFromUse() {
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(item("DAMAGED", "MAINTENANCE", "SN-003")));
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(item("BROKEN", "UNAVAILABLE", "SN-003A")));
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(item("BROKEN", "DISPOSED", "SN-004")));
	}

	@Test
	void rejectsUnknownCondition() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> AssetItemDAO.validateItem(item("NEW", "AVAILABLE", "SN-005")));

		assertEquals("Tình trạng sản phẩm không hợp lệ.", exception.getMessage());
	}

	@Test
	void rejectsUnknownStatus() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> AssetItemDAO.validateItem(item("GOOD", "BORROWED", "SN-006")));

		assertEquals("Trạng thái sản phẩm không hợp lệ.", exception.getMessage());
	}

	@Test
	void rejectsDamagedItemsThatAreStillAvailable() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> AssetItemDAO.validateItem(item("DAMAGED", "AVAILABLE", "SN-007")));

		assertEquals("Sản phẩm hư hỏng nặng phải được đưa ra khỏi trạng thái sẵn sàng.", exception.getMessage());
	}

	@Test
	void rejectsSerialNumbersLongerThanOneHundredCharacters() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> AssetItemDAO.validateItem(item("GOOD", "AVAILABLE", "S".repeat(101))));

		assertEquals("Serial không được dài quá 100 ký tự.", exception.getMessage());
	}

	@Test
	void rejectsDuplicateSerialsInOneAssetSubmission() {
		IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
				() -> AssetItemDAO.validateDistinctSerials(
						List.of(item("GOOD", "AVAILABLE", "G102"), item("GOOD", "AVAILABLE", "g102"))));

		assertEquals("Serial g102 bị trùng trong danh sách nhập.", exception.getMessage());
	}

	@Test
	void rejectsExternalOrInjectableImagePaths() {
		AssetItem valid = item("GOOD", "AVAILABLE", "SN-008");
		valid.setImagePath("/uploads/assets/laptop-01.jpg");
		assertDoesNotThrow(() -> AssetItemDAO.validateItem(valid));

		AssetItem external = item("GOOD", "AVAILABLE", "SN-009");
		external.setImagePath("https://example.com/image.jpg");
		assertThrows(IllegalArgumentException.class, () -> AssetItemDAO.validateItem(external));

		AssetItem injected = item("GOOD", "AVAILABLE", "SN-010");
		injected.setImagePath("/uploads/x.jpg\" onerror=alert(1)");
		assertThrows(IllegalArgumentException.class, () -> AssetItemDAO.validateItem(injected));
	}

	@Test
	void lifecycleInspectionQuerySeparatesItemAndParentInspectionRows() throws IOException {
		String source = Files.readString(
				Path.of("src", "main", "java", "fpt", "swp391", "labtoolequip", "dao", "AssetItemDAO.java"));

		assertTrue(source.contains("'ITEM_INSPECTION'"));
		assertTrue(source.contains("WHERE item.asset_item_id=?"));
		assertTrue(source.contains("'PARENT_INSPECTION'"));
		assertTrue(source.contains("item.asset_item_id IS NULL"));
		assertTrue(source.contains("event_result"));
		assertTrue(source.contains("record.result"));
		assertTrue(source.contains("N' → '"));
	}

	private AssetItem item(String condition, String status, String serialNumber) {
		AssetItem item = new AssetItem();
		item.setCondition(condition);
		item.setStatus(status);
		item.setSerialNumber(serialNumber);
		return item;
	}
}
