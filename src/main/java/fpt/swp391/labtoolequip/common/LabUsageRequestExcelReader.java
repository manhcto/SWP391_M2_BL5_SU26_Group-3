package fpt.swp391.labtoolequip.common;

import fpt.swp391.labtoolequip.model.LabUsageRequestStudent;
import jakarta.servlet.http.Part;
import java.io.InputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

public final class LabUsageRequestExcelReader {
	private LabUsageRequestExcelReader() {
	}

	public static ImportData read(Part part) throws IOException {
		if (part == null || part.getSize() == 0) {
			return new ImportData(List.of());
		}
		return read(part.getInputStream(), part.getSubmittedFileName());
	}

	public static ImportData read(InputStream input, String fileName) throws IOException {
		if (fileName == null || !fileName.toLowerCase().endsWith(".xlsx")) {
			throw new IOException("File import phải có định dạng .xlsx.");
		}
		try (Workbook workbook = WorkbookFactory.create(input)) {
			Sheet internsSheet = workbook.getSheet("Interns");
			if (internsSheet == null) {
				internsSheet = workbook.getSheet("Students");
			}
			if (internsSheet == null) {
				throw new IOException("Excel phải có sheet tên Interns.");
			}
			return new ImportData(readStudents(internsSheet));
		} catch (RuntimeException exception) {
			throw new IOException("Không thể đọc file Excel.", exception);
		}
	}

	private static List<LabUsageRequestStudent> readStudents(Sheet sheet) throws IOException {
		DataFormatter formatter = new DataFormatter();
		List<LabUsageRequestStudent> students = new ArrayList<>();
		for (int index = 1; index <= sheet.getLastRowNum(); index++) {
			Row row = sheet.getRow(index);
			if (row == null) {
				continue;
			}
			String code = cell(formatter, row, 0);
			String name = cell(formatter, row, 1);
			String email = cell(formatter, row, 2);
			String cohort = cell(formatter, row, 3);
			if (code.isBlank() && name.isBlank() && email.isBlank() && cohort.isBlank()) {
				continue;
			}
			if (code.isBlank() || name.isBlank() || email.isBlank() || cohort.isBlank()) {
				throw new IOException("Sheet Interns thiếu dữ liệu tại dòng " + (index + 1) + ".");
			}
			LabUsageRequestStudent student = new LabUsageRequestStudent();
			student.setStudentCode(code);
			student.setFullName(name);
			student.setEmail(email);
			student.setCohort(cohort);
			students.add(student);
		}
		return students;
	}

	private static String cell(DataFormatter formatter, Row row, int index) {
		return formatter.formatCellValue(row.getCell(index)).trim();
	}

	public record ImportData(List<LabUsageRequestStudent> students) {
	}
}
