package fpt.swp391.labtoolequip.auth;

import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

public final class AuthSession {
	public static final String USER_ID = "userId";
	public static final String EMAIL = "email";
	public static final String FULL_NAME = "fullName";
	public static final String ROLE = "role";

	private AuthSession() {
	}

	public static void login(HttpServletRequest request, User user) {
		HttpSession oldSession = request.getSession(false);
		if (oldSession != null) {
			oldSession.invalidate();
		}
		HttpSession session = request.getSession(true);
		session.setAttribute(USER_ID, user.getUserId());
		session.setAttribute(EMAIL, user.getEmail());
		session.setAttribute(FULL_NAME, user.getFullName());
		session.setAttribute(ROLE, user.getRole());
		session.setAttribute("currentUser", user);
	}

	public static long userId(HttpServletRequest request) {
		return (Long) request.getSession(false).getAttribute(USER_ID);
	}

	public static String role(HttpServletRequest request) {
		HttpSession session = request.getSession(false);
		return session == null ? null : (String) session.getAttribute(ROLE);
	}

	public static String dashboard(String contextPath, String role) {
		return switch (role) {
			case "ADMIN" -> contextPath + "/admin/dashboard";
			case "LAB_MANAGER" -> contextPath + "/lab-manager/dashboard";
			case "MENTOR" -> contextPath + "/mentor/dashboard";
			case "INTERN" -> contextPath + "/intern/dashboard";
			default -> contextPath + "/login";
		};
	}
}
