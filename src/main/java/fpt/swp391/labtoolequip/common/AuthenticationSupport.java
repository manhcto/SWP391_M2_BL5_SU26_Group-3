package fpt.swp391.labtoolequip.common;

import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

public final class AuthenticationSupport {
	public static final String SESSION_USER = "currentUser";

	private AuthenticationSupport() {
	}

	public static User currentUser(HttpServletRequest request) {
		HttpSession session = request.getSession(false);
		if (session == null) {
			return null;
		}
		Object value = session.getAttribute(SESSION_USER);
		return value instanceof User user ? user : null;
	}

	public static long currentUserId(HttpServletRequest request) {
		User user = currentUser(request);
		if (user == null || user.getUserId() == null) {
			throw new IllegalStateException("Authentication is required.");
		}
		return user.getUserId();
	}

	public static String dashboardForRole(String role) {
		return switch (role == null ? "" : role) {
			case "ADMIN" -> "/admin/dashboard";
			case "LAB_MANAGER" -> "/lab-manager/dashboard";
			case "STUDENT" -> "/student/dashboard";
			default -> "/mentor/dashboard";
		};
	}

	public static User sessionCopy(User source) {
		User user = new User();
		user.setUserId(source.getUserId());
		user.setFullName(source.getFullName());
		user.setEmail(source.getEmail());
		user.setRole(source.getRole());
		user.setStatus(source.getStatus());
		user.setStudentCode(source.getStudentCode());
		user.setMajor(source.getMajor());
		user.setCohort(source.getCohort());
		return user;
	}
}
