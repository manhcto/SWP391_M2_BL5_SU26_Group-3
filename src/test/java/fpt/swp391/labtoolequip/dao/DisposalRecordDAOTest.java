package fpt.swp391.labtoolequip.dao;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.AssetItem;
import org.junit.jupiter.api.Test;

class DisposalRecordDAOTest {
	@Test
	void serializedDisposalRequiresTheExactItem() {
		assertDoesNotThrow(() -> DisposalRecordDAO.validateDisposalTarget("SERIALIZED", 1L, 2L, 1));
		assertThrows(IllegalArgumentException.class,
				() -> DisposalRecordDAO.validateDisposalTarget("SERIALIZED", 1L, null, 1));
		assertThrows(IllegalArgumentException.class,
				() -> DisposalRecordDAO.validateDisposalTarget("SERIALIZED", null, 2L, 1));
		assertThrows(IllegalArgumentException.class,
				() -> DisposalRecordDAO.validateDisposalTarget("SERIALIZED", 1L, 2L, 2));
	}

	@Test
	void quantityDisposalRemainsAnAggregateTarget() {
		assertDoesNotThrow(() -> DisposalRecordDAO.validateDisposalTarget("QUANTITY", 1L, null, 3));
		assertThrows(IllegalArgumentException.class,
				() -> DisposalRecordDAO.validateDisposalTarget("QUANTITY", 1L, 2L, 1));
		assertThrows(IllegalArgumentException.class,
				() -> DisposalRecordDAO.validateDisposalTarget("QUANTITY", 1L, null, 0));
	}

	@Test
	void serializedDisposalRequiresAnUnsafeItem() {
		assertDoesNotThrow(() -> DisposalRecordDAO.validateSerializedDisposalEligibility(item("UNAVAILABLE", "GOOD")));
		assertDoesNotThrow(() -> DisposalRecordDAO.validateSerializedDisposalEligibility(item("AVAILABLE", "DAMAGED")));
		assertThrows(IllegalStateException.class,
				() -> DisposalRecordDAO.validateSerializedDisposalEligibility(item("MAINTENANCE", "BROKEN")));
		assertThrows(IllegalStateException.class,
				() -> DisposalRecordDAO.validateSerializedDisposalEligibility(item("AVAILABLE", "GOOD")));
	}

	@Test
	void serializedDisposalRejectsAnItemInUseEvenWhenBroken() {
		assertThrows(IllegalStateException.class,
				() -> DisposalRecordDAO.validateSerializedDisposalEligibility(item("IN_USE", "BROKEN")));
	}

	private AssetItem item(String status, String condition) {
		AssetItem item = new AssetItem();
		item.setStatus(status);
		item.setCondition(condition);
		return item;
	}
}
