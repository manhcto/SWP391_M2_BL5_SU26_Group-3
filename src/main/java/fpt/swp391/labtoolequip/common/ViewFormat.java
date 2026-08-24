package fpt.swp391.labtoolequip.common;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import util.AppConfig;

public final class ViewFormat {
	private static final ZoneId LAB_ZONE = ZoneId.of(AppConfig.get("LAB_TIMEZONE", "Asia/Ho_Chi_Minh"));
	private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
	private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
	private static final DateTimeFormatter DATE_TIME_INPUT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");

	private ViewFormat() {
	}

	public static LocalDateTime fromUtc(Timestamp value) {
		return value == null
				? null
				: value.toLocalDateTime().atZone(ZoneOffset.UTC).withZoneSameInstant(LAB_ZONE).toLocalDateTime();
	}

	public static Timestamp toUtc(LocalDateTime value) {
		return value == null
				? null
				: Timestamp.valueOf(value.atZone(LAB_ZONE).withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime());
	}

	public static LocalDateTime now() {
		return LocalDateTime.now(LAB_ZONE);
	}

	public static String date(LocalDate value) {
		return value == null ? "—" : value.format(DATE);
	}

	public static String dateTime(LocalDateTime value) {
		return value == null ? "—" : value.format(DATE_TIME);
	}

	public static String dateTimeInput(LocalDateTime value) {
		return value == null ? "" : value.format(DATE_TIME_INPUT);
	}

	public static String label(String value) {
		if (value == null || value.isBlank())
			return "—";
		return switch (value) {
			case "ADMIN" -> "Quản trị viên";
			case "INTERN" -> "Thực tập sinh";
			case "NATURAL" -> "Tự nhiên / không do thực tập sinh";
			case "UNKNOWN" -> "Chưa rõ nguyên nhân";
			case "MENTOR" -> "Người hướng dẫn";
			case "LAB_MANAGER" -> "Quản lý phòng LAB";
			case "ACTIVE" -> "Hoạt động";
			case "INACTIVE" -> "Tạm khóa";
			case "UPCOMING" -> "Sắp diễn ra";
			case "CLOSED" -> "Đã kết thúc";
			case "PENDING", "PENDING_REVIEW" -> "Chờ duyệt";
			case "APPROVED" -> "Đã duyệt";
			case "REJECTED" -> "Đã từ chối";
			case "CONFIRMED" -> "Đã xác nhận";
			case "RESOLVED" -> "Đã giải quyết";
			case "IN_PROGRESS", "INVESTIGATING" -> "Đang xử lý";
			case "REPORTED" -> "Chờ Mentor duyệt";
			case "FORWARDED" -> "Đã chuyển Lab Manager";
			case "COMPLETED" -> "Hoàn tất";
			case "CANCELLED" -> "Đã hủy";
			case "AVAILABLE" -> "Sẵn sàng";
			case "MAINTENANCE" -> "Đang bảo trì";
			case "UNAVAILABLE" -> "Không khả dụng";
			case "DISPOSED" -> "Đã thanh lý";
			case "IN_USE" -> "Đang sử dụng";
			case "RETURNED" -> "Đã trả";
			case "GOOD" -> "Tốt";
			case "FAIR" -> "Khá";
			case "DAMAGED" -> "Hư hỏng";
			case "BROKEN" -> "Không hoạt động";
			case "DRAFT" -> "Bản nháp";
			case "NORMAL" -> "Bình thường";
			case "DISCREPANCY_FOUND" -> "Có chênh lệch";
			case "INSPECTION" -> "Kiểm tra";
			case "INVENTORY" -> "Kiểm kê";
			case "WHOLE_LAB" -> "Toàn bộ phòng LAB";
			case "SELECTED_ASSETS" -> "Thiết bị được chọn";
			case "DAMAGE" -> "Hư hỏng";
			case "MISSING" -> "Thiếu thiết bị";
			case "LOSS" -> "Mất thiết bị";
			case "MALFUNCTION" -> "Trục trặc";
			case "OTHER" -> "Khác";
			case "LOW" -> "Thấp";
			case "MEDIUM" -> "Trung bình";
			case "HIGH" -> "Cao";
			case "CRITICAL" -> "Nghiêm trọng";
			case "OPEN" -> "Đang mở";
			case "MINOR" -> "Nhẹ";
			case "MODERATE" -> "Trung bình";
			case "MAJOR" -> "Nghiêm trọng";
			case "NATURAL_WEAR" -> "Hao mòn tự nhiên";
			case "EQUIPMENT_FAILURE" -> "Lỗi thiết bị";
			case "ACCIDENTAL_DAMAGE" -> "Hư hỏng ngoài ý muốn";
			case "MISUSE" -> "Sử dụng sai cách";
			case "PROCEDURE_VIOLATION" -> "Vi phạm quy trình";
			case "REPAIRABLE" -> "Có thể sửa chữa";
			case "NOT_REPAIRABLE" -> "Không thể sửa chữa";
			case "NOT_APPLICABLE" -> "Không áp dụng";
			case "CONTINUE_USE" -> "Tiếp tục sử dụng";
			case "MONITOR" -> "Theo dõi";
			case "REMOVE_FROM_USE" -> "Ngừng sử dụng";
			case "DISPOSAL_REVIEW" -> "Xem xét thanh lý";
			case "UNDETERMINED" -> "Chưa xác định";
			case "NONE" -> "Không có trách nhiệm";
			case "PARTIAL" -> "Trách nhiệm một phần";
			case "FULL" -> "Hoàn toàn chịu trách nhiệm";
			default -> value.replace('_', ' ');
		};
	}
}
