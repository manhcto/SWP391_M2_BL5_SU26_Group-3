package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.AssetItem;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import org.junit.jupiter.api.Test;

class AssetUsageDAOTest {
	@Test
	void setsTheDueTimeToTheEndOfTheBorrowDay() {
		ZonedDateTime borrowedAt = ZonedDateTime.of(2026, 8, 21, 14, 30, 0, 0, ZoneId.of("Asia/Ho_Chi_Minh"));

		assertEquals(Instant.parse("2026-08-21T10:40:00Z"), AssetUsageDAO.dueAtEndOfBorrowDay(borrowedAt));
	}

	@Test
	void onlyAllowsBorrowingBeforeTheDailyReturnDeadline() {
		ZoneId zone = ZoneId.of("Asia/Ho_Chi_Minh");
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowTime(ZonedDateTime.of(2026, 8, 21, 17, 39, 59, 0, zone)));
		assertThrows(IllegalArgumentException.class,
				() -> AssetUsageDAO.validateBorrowTime(ZonedDateTime.of(2026, 8, 21, 17, 40, 0, 0, zone)));
	}

	@Test
	void acceptsAvailableBorrowableAsset() {
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowable(asset("AVAILABLE", true, "GOOD")));
	}

	@Test
	void rejectsUnderMaintenanceDisposedAndNonBorrowableAssets() {
		assertThrows(IllegalStateException.class,
				() -> AssetUsageDAO.validateBorrowable(asset("UNDER_MAINTENANCE", true, "GOOD")));
		assertThrows(IllegalStateException.class,
				() -> AssetUsageDAO.validateBorrowable(asset("DISPOSED", true, "GOOD")));
		assertThrows(IllegalStateException.class,
				() -> AssetUsageDAO.validateBorrowable(asset("AVAILABLE", false, "GOOD")));
	}

	@Test
	void rejectsInvalidOrUnavailableQuantity() {
		assertThrows(IllegalArgumentException.class, () -> AssetUsageDAO.validateQuantity(0));
		assertDoesNotThrow(() -> AssetUsageDAO.validateAvailableQuantity(1, 2, 3));
		assertThrows(IllegalStateException.class, () -> AssetUsageDAO.validateAvailableQuantity(2, 2, 3));
		assertThrows(IllegalStateException.class,
				() -> AssetUsageDAO.validateAvailableQuantity(Integer.MAX_VALUE, 1, Integer.MAX_VALUE));
	}

	@Test
	void keepsSerializedAndQuantityBorrowInputsSeparate() {
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowRequest("SERIALIZED", null, 10L, 1));
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowRequest("QUANTITY", null, 10L, 1));
		assertThrows(IllegalArgumentException.class,
				() -> AssetUsageDAO.validateBorrowRequest("SERIALIZED", 1L, null, 1));
		assertThrows(IllegalArgumentException.class,
				() -> AssetUsageDAO.validateBorrowRequest("SERIALIZED", null, 10L, 2));
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowRequest("QUANTITY", 1L, null, 2));
		assertThrows(IllegalArgumentException.class, () -> AssetUsageDAO.validateBorrowRequest("QUANTITY", 1L, 10L, 1));
	}

	@Test
	void rejectsItemAlreadyInUseAndMapsReturnConditionToStatus() {
		assertDoesNotThrow(() -> AssetUsageDAO.validateBorrowableItem(assetItem("AVAILABLE", true, "GOOD")));
		assertThrows(IllegalStateException.class,
				() -> AssetUsageDAO.validateBorrowableItem(assetItem("IN_USE", true, "GOOD")));
		assertEquals("AVAILABLE", AssetUsageDAO.returnedAssetItemStatus("GOOD"));
		assertEquals("AVAILABLE", AssetUsageDAO.returnedAssetItemStatus("FAIR"));
		assertEquals("UNAVAILABLE", AssetUsageDAO.returnedAssetItemStatus("DAMAGED"));
		assertEquals("UNAVAILABLE", AssetUsageDAO.returnedAssetItemStatus("BROKEN"));
		assertEquals(true, AssetUsageDAO.requiresQuarantine("DAMAGED"));
		assertEquals(true, AssetUsageDAO.requiresQuarantine("BROKEN"));
		assertEquals(false, AssetUsageDAO.requiresQuarantine("GOOD"));
	}

	private Asset asset(String status, boolean borrowable, String condition) {
		Asset asset = new Asset();
		asset.setStatus(status);
		asset.setBorrowable(borrowable);
		asset.setCondition(condition);
		return asset;
	}

	private AssetItem assetItem(String status, boolean borrowable, String condition) {
		AssetItem item = new AssetItem();
		item.setStatus(status);
		item.setBorrowable(borrowable);
		item.setCondition(condition);
		return item;
	}
}
