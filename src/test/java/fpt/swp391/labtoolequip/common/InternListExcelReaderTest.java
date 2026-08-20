package fpt.swp391.labtoolequip.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import fpt.swp391.labtoolequip.model.InternListStudent;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

class InternListExcelReaderTest {
	@Test
	void readsInternsSheetAndSkipsEmptyRows() throws IOException {
		byte[] file = workbook("Interns",
				List.<String[]>of(new String[]{"SE180001", "Nguyễn An", "an@fpt.edu.vn", "K18"}));

		List<InternListStudent> students = InternListExcelReader.read(new ByteArrayInputStream(file), "interns.xlsx")
				.students();

		assertEquals(1, students.size());
		assertEquals("SE180001", students.get(0).getStudentCode());
		assertEquals("Nguyễn An", students.get(0).getFullName());
	}

	@Test
	void supportsStudentsSheetAndRejectsInvalidInput() throws IOException {
		byte[] file = workbook("Students",
				List.<String[]>of(new String[]{"SE180002", "Trần Bình", "binh@fpt.edu.vn", "K18"}));

		assertEquals(1, InternListExcelReader.read(new ByteArrayInputStream(file), "students.xlsx").students().size());
		assertThrows(IOException.class,
				() -> InternListExcelReader.read(new ByteArrayInputStream(file), "students.csv"));
		assertThrows(IOException.class,
				() -> InternListExcelReader.read(new ByteArrayInputStream(workbook("Other", List.of())), "other.xlsx"));
	}

	@Test
	void rejectsRowWithRequiredDataMissing() throws IOException {
		byte[] file = workbook("Interns", List.<String[]>of(new String[]{"SE180003", "", "missing@fpt.edu.vn", "K18"}));

		assertThrows(IOException.class,
				() -> InternListExcelReader.read(new ByteArrayInputStream(file), "interns.xlsx"));
	}

	private byte[] workbook(String sheetName, List<String[]> students) throws IOException {
		try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
			XSSFSheet sheet = workbook.createSheet(sheetName);
			sheet.createRow(0).createCell(0).setCellValue("Code");
			for (int rowIndex = 0; rowIndex < students.size(); rowIndex++) {
				var row = sheet.createRow(rowIndex + 1);
				String[] student = students.get(rowIndex);
				for (int column = 0; column < student.length; column++) {
					row.createCell(column).setCellValue(student[column]);
				}
			}
			workbook.write(output);
			return output.toByteArray();
		}
	}
}
