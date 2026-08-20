package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
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

	@Test
	void importsVietnameseConditionStatusAndDates() throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		try (Workbook workbook = new XSSFWorkbook()) {
			var sheet = workbook.createSheet("Asset Items");
			sheet.createRow(0).createCell(0).setCellValue("Serial");
			var row = sheet.createRow(1);
			row.createCell(0).setCellValue("SN-002");
			row.createCell(2).setCellValue("Hư Hỏng");
			row.createCell(3).setCellValue("Đang bảo trì");
			row.createCell(4).setCellValue("20/08/2026");
			row.createCell(5).setCellValue("2027-08-20");
			workbook.write(output);
		}

		var item = AssetItemExcelReader.read(new ByteArrayInputStream(output.toByteArray()), "assets.xlsx").items()
				.get(0);

		assertEquals("DAMAGED", item.getCondition());
		assertEquals("MAINTENANCE", item.getStatus());
		assertEquals(LocalDate.of(2026, 8, 20), item.getPurchaseDate());
		assertEquals(LocalDate.of(2027, 8, 20), item.getWarrantyUntil());
	}

	@Test
	void rejectsExcelRowsWithUnknownCondition() throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		try (Workbook workbook = new XSSFWorkbook()) {
			var sheet = workbook.createSheet("Asset Items");
			sheet.createRow(0).createCell(0).setCellValue("Serial");
			var row = sheet.createRow(1);
			row.createCell(0).setCellValue("SN-003");
			row.createCell(2).setCellValue("Không rõ");
			workbook.write(output);
		}

		IOException exception = assertThrows(IOException.class,
				() -> AssetItemExcelReader.read(new ByteArrayInputStream(output.toByteArray()), "assets.xlsx"));

		assertEquals("Tình trạng không hợp lệ trong file Excel: Không rõ", exception.getMessage());
	}
}
