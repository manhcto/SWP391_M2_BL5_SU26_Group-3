package fpt.swp391.labtoolequip.inspection;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class InspectionAssetItemContractTest {

	@Test
	void inspectionSelectionUsesExactAssetItems() throws IOException {
		String dao = read("src/main/java/fpt/swp391/labtoolequip/dao/InspectionDAO.java");
		String controller = read(
				"src/main/java/fpt/swp391/labtoolequip/controller/InspectionControllerSupport.java");
		String form = read("src/main/webapp/WEB-INF/views/shared/inspections/form.jsp");

		assertTrue(dao.contains("JOIN dbo.asset_items ai"));
		assertTrue(dao.contains("AND ai.asset_item_id = ?"));
		assertFalse(dao.contains("WHERE a.tracking_mode = 'QUANTITY'"));
		assertTrue(controller.contains("selectedTargetKey"));
		assertFalse(controller.contains("selectedAssetId"));
		assertTrue(form.contains("name=\"selectedTargetKey\""));
		assertFalse(form.contains("name=\"selectedAssetId\""));
	}

	private String read(String relativePath) throws IOException {
		return Files.readString(Path.of(relativePath));
	}
}
