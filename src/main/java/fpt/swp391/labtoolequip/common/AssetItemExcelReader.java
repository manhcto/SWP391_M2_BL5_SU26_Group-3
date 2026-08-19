package fpt.swp391.labtoolequip.common;

import fpt.swp391.labtoolequip.model.AssetItem;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

public final class AssetItemExcelReader {
	private static final DateTimeFormatter VIETNAMESE_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

	private AssetItemExcelReader() {
	}

	public static ImportData read(Part part) throws IOException {
		if (part == null || part.getSize() == 0) {
			return new ImportData(List.of());
		}
		return read(part.getInputStream(), part.getSubmittedFileName());
	}

	public static ImportData read(InputStream input, String fileName) throws IOException {
		if (fileName == null || !fileName.toLowerCase(Locale.ROOT).endsWith(".xlsx")) {
			throw new IOException("File import phải có định dạng .xlsx.");
		}
		try (Workbook workbook = WorkbookFactory.create(input)) {
			Sheet sheet = workbook.getSheet("Asset Items");
			if (sheet == null) {
				sheet = workbook.getSheet("Assets");
			}
			if (sheet == null && workbook.getNumberOfSheets() > 0) {
				sheet = workbook.getSheetAt(0);
			}
			if (sheet == null) {
				throw new IOException("Excel chưa có trang tính dữ liệu thiết bị.");
			}
			return new ImportData(readItems(sheet));
		} catch (RuntimeException exception) {
			throw new IOException("Không thể đọc file Excel.", exception);
		}
	}

	private static List<AssetItem> readItems(Sheet sheet) throws IOException {
		DataFormatter formatter = new DataFormatter();
		List<AssetItem> items = new ArrayList<>();
		for (int index = 1; index <= sheet.getLastRowNum(); index++) {
			Row row = sheet.getRow(index);
			if (row == null) {
				continue;
			}
			String serial = cell(formatter, row, 0);
			String image = cell(formatter, row, 1);
			String condition = condition(cell(formatter, row, 2));
			String status = status(cell(formatter, row, 3));
			String purchaseDate = cell(formatter, row, 4);
			String warrantyUntil = cell(formatter, row, 5);
			String note = cell(formatter, row, 6);
			if (serial.isBlank() && image.isBlank() && condition.isBlank() && status.isBlank()
					&& purchaseDate.isBlank() && warrantyUntil.isBlank() && note.isBlank()) {
				continue;
			}
			if (serial.length() > 100 || image.length() > 500 || note.length() > 500) {
				throw new IOException("Dòng " + (index + 1) + " vượt quá độ dài cho phép.");
			}
			AssetItem item = new AssetItem();
			item.setSerialNumber(serial.isBlank() ? null : serial);
			item.setImagePath(image.isBlank() ? null : image);
			item.setCondition(condition.isBlank() ? "GOOD" : condition);
			item.setStatus(status.isBlank() ? "AVAILABLE" : status);
			item.setPurchaseDate(parseDate(purchaseDate, index + 1));
			item.setWarrantyUntil(parseDate(warrantyUntil, index + 1));
			item.setNote(note.isBlank() ? null : note);
			items.add(item);
		}
		if (items.isEmpty()) {
			throw new IOException("Excel chưa có dòng sản phẩm nào.");
		}
		return items;
	}

	private static String condition(String value) throws IOException {
		String normalized = value.trim().toUpperCase(Locale.ROOT);
		return switch (normalized) {
			case "" -> "";
			case "GOOD", "TỐT" -> "GOOD";
			case "FAIR", "KHÁ" -> "FAIR";
			case "DAMAGED", "HƯ HỎNG" -> "DAMAGED";
			case "BROKEN", "HỎNG" -> "BROKEN";
			default -> throw new IOException("Tình trạng không hợp lệ trong file Excel: " + value);
		};
	}

	private static String status(String value) throws IOException {
		String normalized = value.trim().toUpperCase(Locale.ROOT);
		return switch (normalized) {
			case "" -> "";
			case "AVAILABLE", "SẴN SÀNG" -> "AVAILABLE";
			case "MAINTENANCE", "ĐANG BẢO TRÌ" -> "MAINTENANCE";
			case "UNAVAILABLE", "KHÔNG KHẢ DỤNG" -> "UNAVAILABLE";
			case "DISPOSED", "ĐÃ THANH LÝ" -> "DISPOSED";
			default -> throw new IOException("Trạng thái không hợp lệ trong file Excel: " + value);
		};
	}

	private static LocalDate parseDate(String value, int row) throws IOException {
		if (value.isBlank()) {
			return null;
		}
		try {
			return LocalDate.parse(value);
		} catch (DateTimeParseException ignored) {
			try {
				return LocalDate.parse(value, VIETNAMESE_DATE);
			} catch (DateTimeParseException exception) {
				throw new IOException("Ngày tại dòng " + row + " phải có dạng yyyy-MM-dd hoặc dd/MM/yyyy.");
			}
		}
	}

	private static String cell(DataFormatter formatter, Row row, int index) {
		Cell cell = row.getCell(index);
		if (cell == null) {
			return "";
		}
		if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
			return cell.getLocalDateTimeCellValue().toLocalDate().toString();
		}
		return formatter.formatCellValue(cell).trim();
	}

	public record ImportData(List<AssetItem> items) {
	}
}
