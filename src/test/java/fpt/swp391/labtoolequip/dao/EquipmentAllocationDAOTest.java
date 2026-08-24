package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.EquipmentAllocationRequest;
import java.util.List;
import org.junit.jupiter.api.Test;

class EquipmentAllocationDAOTest {
	@Test
	void requestRowsRequireDistinctAssetsAndPracticalQuantities() {
		assertDoesNotThrow(() -> EquipmentAllocationDAO.validateRequestRows(List.of(row(1, 10), row(2, 1))));
		assertThrows(IllegalArgumentException.class,
				() -> EquipmentAllocationDAO.validateRequestRows(List.of(row(1, 2), row(1, 3))));
		assertThrows(IllegalArgumentException.class,
				() -> EquipmentAllocationDAO.validateRequestRows(List.of(row(1, 1000))));
	}

	@Test
	void approvalRequiresExactlyDistinctPhysicalItems() {
		assertEquals(10, EquipmentAllocationDAO
				.selectedItemIds(new String[]{"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}, 10).size());
		assertThrows(IllegalArgumentException.class,
				() -> EquipmentAllocationDAO.selectedItemIds(new String[]{"1", "2"}, 3));
		assertThrows(IllegalArgumentException.class,
				() -> EquipmentAllocationDAO.selectedItemIds(new String[]{"1", "1"}, 2));
	}

	private EquipmentAllocationRequest row(long assetId, int quantity) {
		EquipmentAllocationRequest request = new EquipmentAllocationRequest();
		request.setAssetId(assetId);
		request.setRequestedQuantity(quantity);
		return request;
	}
}
