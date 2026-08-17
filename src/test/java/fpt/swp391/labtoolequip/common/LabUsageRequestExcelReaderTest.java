package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

class LabUsageRequestExcelReaderTest {
	@Test
	void readsInternsWithoutSchedule() throws Exception {
		byte[] file;
		try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
			Sheet interns = workbook.createSheet("Interns");
			interns.createRow(0);
			Row intern = interns.createRow(1);
			intern.createCell(0).setCellValue("INTERN001");
			intern.createCell(1).setCellValue("Intern One");
			intern.createCell(2).setCellValue("intern@example.com");
			intern.createCell(3).setCellValue("K17");
			workbook.write(output);
			file = output.toByteArray();
		}

		LabUsageRequestExcelReader.ImportData imported = LabUsageRequestExcelReader.read(new ByteArrayInputStream(file),
				"request.xlsx");

		assertEquals(1, imported.students().size());
		assertEquals("intern@example.com", imported.students().get(0).getEmail());
		assertEquals("K17", imported.students().get(0).getCohort());
	}
}
