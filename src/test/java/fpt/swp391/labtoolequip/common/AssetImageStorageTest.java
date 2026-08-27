package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AssetImageStorageTest {
	@Test
	void acceptsOnlyTheImageTypesExposedByTheForm() {
		assertTrue(AssetImageStorage.isSupported("device.PNG", "image/png"));
		assertTrue(AssetImageStorage.isSupported("device.webp", "image/webp"));
		assertFalse(AssetImageStorage.isSupported("device.svg", "image/svg+xml"));
		assertFalse(AssetImageStorage.isSupported("device.jpg", "text/plain"));
	}
}
