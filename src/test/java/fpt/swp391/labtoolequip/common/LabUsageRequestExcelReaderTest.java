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
	void readsStudentsAndRecurringSlots() throws Exception {
		byte[] file;
		try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
			Sheet students = workbook.createSheet("Students");
			students.createRow(0);
			Row student = students.createRow(1);
			student.createCell(0).setCellValue("SE123456");
			student.createCell(1).setCellValue("Student One");
			student.createCell(2).setCellValue("student@example.com");

			Sheet slots = workbook.createSheet("Slots");
			slots.createRow(0);
			Row slot = slots.createRow(1);
			slot.createCell(0).setCellValue("Thứ 2");
			slot.createCell(1).setCellValue("Slot 3");
			workbook.write(output);
			file = output.toByteArray();
		}

		LabUsageRequestExcelReader.ImportData imported = LabUsageRequestExcelReader.read(new ByteArrayInputStream(file),
				"request.xlsx");

		assertEquals(1, imported.students().size());
		assertEquals("student@example.com", imported.students().get(0).getEmail());
		assertEquals(2, imported.slots().get(0).getDayOfWeek());
		assertEquals(3, imported.slots().get(0).getSlotId());
	}
}
