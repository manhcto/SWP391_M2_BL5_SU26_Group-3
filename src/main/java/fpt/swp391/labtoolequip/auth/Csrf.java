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
		HttpSession session = request.getSession(true);
		String token = (String) session.getAttribute("csrfToken");
		if (token == null) {
			byte[] bytes = new byte[32];
			RANDOM.nextBytes(bytes);
			token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
			session.setAttribute("csrfToken", token);
		}
		return token;
	}

	public static boolean valid(HttpServletRequest request) {
		HttpSession session = request.getSession(false);
		String expected = session == null ? null : (String) session.getAttribute("csrfToken");
		if (expected == null) {
			return false;
		}
		String token = request.getParameter("csrfToken");
		if (token == null || token.isBlank()) {
			token = request.getHeader("X-CSRF-Token");
		}
		if (token == null && request.getContentType() != null
				&& request.getContentType().startsWith("multipart/form-data")) {
			try {
				jakarta.servlet.http.Part part = request.getPart("csrfToken");
				if (part != null) {
					token = new String(part.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8)
							.trim();
				}
			} catch (Exception ignored) {
			}
		}
		return expected.equals(token);
	}
}
