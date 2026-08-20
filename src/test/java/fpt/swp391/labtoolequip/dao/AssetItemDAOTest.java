package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.AssetItem;
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

		assertEquals("Sản phẩm hư hỏng nặng phải chuyển sang Đang bảo trì và được Mentor báo cáo Lab Manager.",
				exception.getMessage());
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
				() -> AssetItemDAO.validateDistinctSerials(List.of(item("GOOD", "AVAILABLE", "G102"),
						item("GOOD", "AVAILABLE", "g102"))));

		assertEquals("Serial g102 bị trùng trong danh sách nhập.", exception.getMessage());
	}

	private AssetItem item(String condition, String status, String serialNumber) {
		AssetItem item = new AssetItem();
		item.setCondition(condition);
		item.setStatus(status);
		item.setSerialNumber(serialNumber);
		return item;
	}
}
