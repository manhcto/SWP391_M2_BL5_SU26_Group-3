package fpt.swp391.labtoolequip.common;

import fpt.swp391.labtoolequip.model.MaintenanceSchedule;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

public final class MaintenanceScheduleExcelReader {
	private static final DateTimeFormatter DATE_FORMAT_1 = DateTimeFormatter.ofPattern("dd/MM/yyyy");
	private static final DateTimeFormatter DATE_FORMAT_2 = DateTimeFormatter.ofPattern("yyyy-MM-dd");

	private MaintenanceScheduleExcelReader() {
	}

	public static final class ReadResult {
		private final List<MaintenanceSchedule> schedules;
		private final int skippedDuplicatesCount;

		public ReadResult(List<MaintenanceSchedule> schedules, int skippedDuplicatesCount) {
			this.schedules = schedules;
			this.skippedDuplicatesCount = skippedDuplicatesCount;
		}

		public List<MaintenanceSchedule> getSchedules() {
			return schedules;
		}

		public int getSkippedDuplicatesCount() {
			return skippedDuplicatesCount;
		}
	}

	public static ReadResult read(Part part, Map<String, Long> assetCodeMap, java.util.Set<String> existingScheduleKeys,
			long userId) throws IOException {
		if (part == null || part.getSize() == 0) {
			return new ReadResult(List.of(), 0);
		}
		String fileName = part.getSubmittedFileName();
		if (fileName == null || !fileName.toLowerCase(Locale.ROOT).endsWith(".xlsx")) {
			throw new IOException("File import phải có định dạng .xlsx.");
		}
		return read(part.getInputStream(), assetCodeMap, existingScheduleKeys, userId);
	}

	public static ReadResult read(InputStream input, Map<String, Long> assetCodeMap,
			java.util.Set<String> existingScheduleKeys, long userId) throws IOException {
		try (Workbook workbook = WorkbookFactory.create(input)) {
			Sheet sheet = workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
			if (sheet == null) {
				throw new IOException("File Excel không có trang tính dữ liệu.");
			}

			DataFormatter formatter = new DataFormatter();
			List<MaintenanceSchedule> list = new ArrayList<>();
			java.util.Set<String> inMemoryKeys = new java.util.HashSet<>();
			int skippedDuplicatesCount = 0;

			for (int i = 1; i <= sheet.getLastRowNum(); i++) {
				Row row = sheet.getRow(i);
				if (row == null) {
					continue;
				}

				String assetCode = formatter.formatCellValue(row.getCell(0)).trim();
				String title = formatter.formatCellValue(row.getCell(1)).trim();
				String dateStr = formatter.formatCellValue(row.getCell(2)).trim();

				// Skip completely empty rows
				if (assetCode.isEmpty() && title.isEmpty() && dateStr.isEmpty()) {
					continue;
				}

				if (assetCode.isEmpty()) {
					throw new IOException("Dòng " + (i + 1) + ": Mã thiết bị không được để trống.");
				}
				if (!assetCodeMap.containsKey(assetCode.toUpperCase())) {
					throw new IOException(
							"Dòng " + (i + 1) + ": Mã thiết bị '" + assetCode + "' không tồn tại trong hệ thống.");
				}
				if (title.isEmpty()) {
					throw new IOException("Dòng " + (i + 1) + ": Tiêu đề đợt bảo trì không được để trống.");
				}
				if (title.length() > 255) {
					throw new IOException("Dòng " + (i + 1) + ": Tiêu đề đợt bảo trì không được vượt quá 255 ký tự.");
				}

				LocalDate scheduledDate = parseDate(row.getCell(2), dateStr, i + 1);

				String costStr = formatter.formatCellValue(row.getCell(3)).trim();
				Long estimatedCost = parseCost(costStr, i + 1);
				if (estimatedCost != null && (estimatedCost < 0 || estimatedCost > 1_000_000_000L)) {
					throw new IOException("Dòng " + (i + 1) + ": Dự toán kinh phí phải từ 0 đến 1.000.000.000 VNĐ.");
				}

				String providerName = formatter.formatCellValue(row.getCell(4)).trim();
				if (providerName.length() > 255) {
					throw new IOException(
							"Dòng " + (i + 1) + ": Tên đơn vị / KTV sửa chữa không được vượt quá 255 ký tự.");
				}

				String providerPhone = formatter.formatCellValue(row.getCell(5)).trim();
				if (!providerPhone.isEmpty()) {
					if (!providerPhone.matches("^(0|\\+84)[0-9.\\s-]{8,15}$")) {
						throw new IOException("Dòng " + (i + 1) + ": Số điện thoại '" + providerPhone
								+ "' không hợp lệ (phải gồm 10-11 chữ số bắt đầu bằng 0 hoặc +84).");
					}
					if (providerPhone.length() > 20) {
						throw new IOException("Dòng " + (i + 1) + ": Số điện thoại không được vượt quá 20 ký tự.");
					}
				}

				String note = formatter.formatCellValue(row.getCell(6)).trim();
				if (note.length() > 255) {
					throw new IOException("Dòng " + (i + 1) + ": Ghi chú không được vượt quá 255 ký tự.");
				}

				Long assetId = assetCodeMap.get(assetCode.toUpperCase());
				String key = fpt.swp391.labtoolequip.dao.MaintenanceScheduleDAO.buildScheduleKey(assetId, assetCode,
						scheduledDate);

				// Kiểm tra trùng lặp: Nếu trong cùng file hoặc đã có lịch cùng ngày trên hệ
				// thống
				if (inMemoryKeys.contains(key)
						|| (existingScheduleKeys != null && existingScheduleKeys.contains(key))) {
					skippedDuplicatesCount++;
					continue;
				}
				inMemoryKeys.add(key);

				MaintenanceSchedule s = new MaintenanceSchedule();
				s.setAssetId(assetId);
				s.setItemCode(assetCode);
				s.setTitle(title);
				s.setScheduledDate(scheduledDate);
				s.setEstimatedCost(estimatedCost);
				s.setProviderName(providerName.isEmpty() ? null : providerName);
				s.setProviderPhone(providerPhone.isEmpty() ? null : providerPhone);
				s.setNote(note.isEmpty() ? null : note);
				s.setCreatedBy(userId);
				s.setStatus("PENDING");

				list.add(s);
			}

			if (list.isEmpty()) {
				if (skippedDuplicatesCount > 0) {
					throw new IOException("Tất cả " + skippedDuplicatesCount
							+ " dòng trong file Excel đều bị trùng ngày với các lịch bảo trì đã có trên hệ thống.");
				}
				throw new IOException("File Excel không chứa bản ghi lịch bảo trì hợp lệ nào.");
			}

			return new ReadResult(list, skippedDuplicatesCount);
		} catch (RuntimeException e) {
			throw new IOException("Không thể đọc file Excel: " + e.getMessage(), e);
		}
	}

	private static LocalDate parseDate(Cell cell, String dateStr, int rowNum) throws IOException {
		if (cell != null && cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
			return cell.getLocalDateTimeCellValue().toLocalDate();
		}
		if (dateStr == null || dateStr.isEmpty()) {
			throw new IOException("Dòng " + rowNum + ": Ngày dự kiến không được để trống.");
		}
		try {
			return LocalDate.parse(dateStr, DATE_FORMAT_1);
		} catch (DateTimeParseException e) {
			try {
				return LocalDate.parse(dateStr, DATE_FORMAT_2);
			} catch (DateTimeParseException ex) {
				throw new IOException("Dòng " + rowNum + ": Ngày '" + dateStr + "' không đúng định dạng dd/MM/yyyy.");
			}
		}
	}

	private static Long parseCost(String costStr, int rowNum) throws IOException {
		if (costStr == null || costStr.isEmpty()) {
			return null;
		}
		try {
			String cleaned = costStr.replaceAll("[^0-9]", "");
			if (cleaned.isEmpty()) {
				return null;
			}
			return Long.parseLong(cleaned);
		} catch (NumberFormatException e) {
			throw new IOException("Dòng " + rowNum + ": Dự toán kinh phí không hợp lệ.");
		}
	}

	public static void downloadTemplate(HttpServletResponse response, List<String> sampleAssetCodes)
			throws IOException {
		response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		response.setHeader("Content-Disposition", "attachment; filename=mau_lich_bao_tri.xlsx");

		try (Workbook workbook = new XSSFWorkbook()) {
			Sheet sheet = workbook.createSheet("Lịch bảo trì định kỳ");

			// Header style
			CellStyle headerStyle = workbook.createCellStyle();
			Font font = workbook.createFont();
			font.setBold(true);
			font.setColor(IndexedColors.WHITE.getIndex());
			headerStyle.setFont(font);
			headerStyle.setFillForegroundColor(IndexedColors.ROYAL_BLUE.getIndex());
			headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
			headerStyle.setAlignment(HorizontalAlignment.CENTER);

			Row header = sheet.createRow(0);
			String[] headers = {"Mã thiết bị (*)", "Tiêu đề đợt bảo trì (*)", "Ngày dự kiến (dd/MM/yyyy) (*)",
					"Dự toán kinh phí (VNĐ)", "Đơn vị / Kỹ thuật viên", "SĐT đơn vị / kỹ thuật viên", "Ghi chú"};

			for (int i = 0; i < headers.length; i++) {
				Cell cell = header.createCell(i);
				cell.setCellValue(headers[i]);
				cell.setCellStyle(headerStyle);
			}

			// Sample rows
			String code1 = sampleAssetCodes != null && !sampleAssetCodes.isEmpty()
					? sampleAssetCodes.get(0)
					: "AST-001";
			String code2 = sampleAssetCodes != null && sampleAssetCodes.size() > 1 ? sampleAssetCodes.get(1) : code1;

			Row row1 = sheet.createRow(1);
			row1.createCell(0).setCellValue(code1);
			row1.createCell(1).setCellValue("Vệ sinh quạt tản nhiệt & tra keo tản nhiệt");
			row1.createCell(2).setCellValue(LocalDate.now().plusDays(7).format(DATE_FORMAT_1));
			row1.createCell(3).setCellValue(350000);
			row1.createCell(4).setCellValue("KTV FPT Services");
			row1.createCell(5).setCellValue("0988123456");
			row1.createCell(6).setCellValue("Kiểm tra lại toàn bộ giắc nguồn và quạt gió");

			Row row2 = sheet.createRow(2);
			row2.createCell(0).setCellValue(code2);
			row2.createCell(1).setCellValue("Bảo dưỡng màng lọc bụi & kiểm định bóng đèn");
			row2.createCell(2).setCellValue(LocalDate.now().plusDays(14).format(DATE_FORMAT_1));
			row2.createCell(3).setCellValue(500000);
			row2.createCell(4).setCellValue("Trung tâm bảo hành Tektronix");
			row2.createCell(5).setCellValue("0912345678");
			row2.createCell(6).setCellValue("Kiểm tra độ sáng và tuổi thọ bóng");

			for (int i = 0; i < headers.length; i++) {
				sheet.autoSizeColumn(i);
			}

			workbook.write(response.getOutputStream());
		}
	}
}