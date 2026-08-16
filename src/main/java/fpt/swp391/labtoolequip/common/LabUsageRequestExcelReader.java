package fpt.swp391.labtoolequip.common;

import fpt.swp391.labtoolequip.model.LabUsageRequestSlot;
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
			return new ImportData(List.of(), List.of());
		}
		return read(part.getInputStream(), part.getSubmittedFileName());
	}

	public static ImportData read(InputStream input, String fileName) throws IOException {
		if (fileName == null || !fileName.toLowerCase().endsWith(".xlsx")) {
			throw new IOException("File import phải có định dạng .xlsx.");
		}
		try (Workbook workbook = WorkbookFactory.create(input)) {
			Sheet studentsSheet = workbook.getSheet("Students");
			Sheet slotsSheet = workbook.getSheet("Slots");
			if (studentsSheet == null || slotsSheet == null) {
				throw new IOException("Excel phải có hai sheet tên Students và Slots.");
			}
			return new ImportData(readStudents(studentsSheet), readSlots(slotsSheet));
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
			if (code.isBlank() && name.isBlank() && email.isBlank()) {
				continue;
			}
			if (code.isBlank() || name.isBlank() || email.isBlank()) {
				throw new IOException("Sheet Students thiếu dữ liệu tại dòng " + (index + 1) + ".");
			}
			LabUsageRequestStudent student = new LabUsageRequestStudent();
			student.setStudentCode(code);
			student.setFullName(name);
			student.setEmail(email);
			students.add(student);
		}
		return students;
	}

	private static List<LabUsageRequestSlot> readSlots(Sheet sheet) throws IOException {
		DataFormatter formatter = new DataFormatter();
		List<LabUsageRequestSlot> slots = new ArrayList<>();
		for (int index = 1; index <= sheet.getLastRowNum(); index++) {
			Row row = sheet.getRow(index);
			if (row == null) {
				continue;
			}
			String dayText = cell(formatter, row, 0);
			String slotText = cell(formatter, row, 1);
			if (dayText.isBlank() && slotText.isBlank()) {
				continue;
			}
			int day = numberIn(dayText);
			int slotId = numberIn(slotText);
			if (day < 2 || day > 7 || slotId < 1 || slotId > 4) {
				throw new IOException("Sheet Slots không hợp lệ tại dòng " + (index + 1) + ".");
			}
			LabUsageRequestSlot slot = new LabUsageRequestSlot();
			slot.setDayOfWeek(day);
			slot.setSlotId(slotId);
			slots.add(slot);
		}
		return slots;
	}

	private static String cell(DataFormatter formatter, Row row, int index) {
		return formatter.formatCellValue(row.getCell(index)).trim();
	}

	private static int numberIn(String value) {
		String digits = value.replaceAll("\\D+", "");
		try {
			return digits.isEmpty() ? -1 : Integer.parseInt(digits);
		} catch (NumberFormatException exception) {
			return -1;
		}
	}

	public record ImportData(List<LabUsageRequestStudent> students, List<LabUsageRequestSlot> slots) {
	}
}
