package fpt.swp391.labtoolequip.common;

import java.text.Normalizer;

public final class EmailHelper {
	private EmailHelper() {
	}

	/**
	 * Tự động tạo Email chuẩn @fpt.edu.vn từ Họ Tên và Mã Sinh Viên / Mã Giảng Viên
	 * Ví dụ: "Nguyễn Minh Anh", "SE160123" -> anhnmse160123@fpt.edu.vn "Phạm Quang
	 * Dũng", "" (Mentor/Staff) -> dungpq@fpt.edu.vn
	 */
	public static String generateFptEmail(String fullName, String code, boolean isStudent) {
		if (fullName == null || fullName.trim().isEmpty()) {
			return "";
		}

		// 1. Chuyển tiếng Việt có dấu sang không dấu
		String normalized = Normalizer.normalize(fullName.trim().toLowerCase(), Normalizer.Form.NFD);
		String noDiacritics = normalized.replaceAll("\\p{InCombiningDiacriticalMarks}+", "").replaceAll("đ", "d")
				.replaceAll("[^a-z\\s]", "");

		String[] parts = noDiacritics.trim().split("\\s+");
		if (parts.length == 0 || parts[0].isEmpty()) {
			return "";
		}

		// 2. Tên chính (từ cuối cùng)
		String firstName = parts[parts.length - 1];

		// 3. Chữ cái đầu của họ và các tên đệm
		StringBuilder initials = new StringBuilder();
		for (int i = 0; i < parts.length - 1; i++) {
			if (!parts[i].isEmpty()) {
				initials.append(parts[i].charAt(0));
			}
		}

		// 4. Mã sinh viên (nếu là sinh viên)
		String cleanCode = (code != null && isStudent) ? code.trim().toLowerCase().replaceAll("[^a-z0-9]", "") : "";

		return firstName + initials + cleanCode + "@fpt.edu.vn";
	}
}
