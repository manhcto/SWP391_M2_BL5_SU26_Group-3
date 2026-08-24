package fpt.swp391.labtoolequip.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.security.SecureRandom;
import java.util.Base64;

public final class Csrf {
	private static final SecureRandom RANDOM = new SecureRandom();

	private Csrf() {
	}

	public static String token(HttpServletRequest request) {
		String token = (String) request.getSession().getAttribute("csrfToken");
		if (token == null) {
			byte[] bytes = new byte[32];
			RANDOM.nextBytes(bytes);
			token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
			request.getSession().setAttribute("csrfToken", token);
		}
		return token;
	}

	public static boolean valid(HttpServletRequest request) {
		HttpSession session = request.getSession(false);
		String expected = session == null ? null : (String) session.getAttribute("csrfToken");
		return expected != null && expected.equals(request.getParameter("csrfToken"));
	}
}
