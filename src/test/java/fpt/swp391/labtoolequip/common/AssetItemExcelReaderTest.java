package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

class AssetItemExcelReaderTest {
	@Test
	void readsAssetRowsWithoutStorageLocation() throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		try (Workbook workbook = new XSSFWorkbook()) {
			var sheet = workbook.createSheet("Asset Items");
			sheet.createRow(0).createCell(0).setCellValue("Serial");
			var row = sheet.createRow(1);
			row.createCell(0).setCellValue("SN-001");
			row.createCell(2).setCellValue("Tốt");
			row.createCell(3).setCellValue("Sẵn sàng");
			workbook.write(output);
		}

		var result = AssetItemExcelReader.read(new ByteArrayInputStream(output.toByteArray()), "assets.xlsx");
		assertEquals(1, result.items().size());
		assertEquals("SN-001", result.items().get(0).getSerialNumber());
		assertEquals("GOOD", result.items().get(0).getCondition());
		assertEquals("AVAILABLE", result.items().get(0).getStatus());
	}
}
