package fpt.swp391.labtoolequip.controller.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import fpt.swp391.labtoolequip.common.AuthenticationSupport;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.util.Base64;
import java.util.Collections;
import java.util.Locale;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet({"/login", "/login/google"})
public class LoginController extends HttpServlet {
	private static final String LOGIN_VIEW = "/WEB-INF/views/auth/login.jsp";
	private static final String LOGIN_CSRF = "loginCsrfToken";
	private static final SecureRandom RANDOM = new SecureRandom();

	private final UserDAO userDAO = new UserDAO();
	private String googleClientId;
	private GoogleIdTokenVerifier googleVerifier;

	@Override
	public void init() throws ServletException {
		googleClientId = trim(getServletContext().getInitParameter("googleClientId"));
		if (googleClientId.isBlank()) {
			googleClientId = trim(System.getProperty("google.clientId"));
		}
		if (!googleClientId.isBlank()) {
			try {
				googleVerifier = new GoogleIdTokenVerifier.Builder(GoogleNetHttpTransport.newTrustedTransport(),
						GsonFactory.getDefaultInstance()).setAudience(Collections.singletonList(googleClientId))
						.build();
			} catch (GeneralSecurityException | IOException exception) {
				throw new ServletException("Không thể khởi tạo Google Authentication.", exception);
			}
		}
	}

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		User currentUser = AuthenticationSupport.currentUser(request);
		if (currentUser != null) {
			redirectToDashboard(request, response, currentUser);
			return;
		}
		renderLogin(request, response, null);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if ("/login/google".equals(request.getServletPath())) {
			loginWithGoogle(request, response);
		} else {
			loginWithPassword(request, response);
		}
	}

	private void loginWithPassword(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String email = trim(request.getParameter("email")).toLowerCase(Locale.ROOT);
		request.setAttribute("email", email);
		if (!validLoginCsrf(request)) {
			renderLogin(request, response, "Phiên đăng nhập đã hết hạn. Vui lòng thử lại.");
			return;
		}

		try {
			User user = userDAO.findByEmail(email).orElse(null);
			if (!canUsePassword(user, request.getParameter("password"))) {
				renderLogin(request, response, "Email hoặc mật khẩu không chính xác.");
				return;
			}
			authenticate(request, response, user);
		} catch (SQLException exception) {
			getServletContext().log("Password login failed", exception);
			renderLogin(request, response, "Không thể kết nối dữ liệu tài khoản. Vui lòng thử lại.");
		}
	}

	private void loginWithGoogle(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (googleVerifier == null) {
			renderLogin(request, response, "Google Authentication chưa được cấu hình Client ID.");
			return;
		}
		if (!validGoogleCsrf(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Google CSRF token không hợp lệ.");
			return;
		}

		GoogleIdToken idToken;
		try {
			idToken = googleVerifier.verify(trim(request.getParameter("credential")));
		} catch (GeneralSecurityException | IOException exception) {
			getServletContext().log("Google token verification failed", exception);
			renderLogin(request, response, "Không thể xác minh tài khoản Google. Vui lòng thử lại.");
			return;
		}
		if (idToken == null || !Boolean.TRUE.equals(idToken.getPayload().getEmailVerified())) {
			renderLogin(request, response, "Không xác minh được tài khoản Google.");
			return;
		}

		try {
			String email = trim(idToken.getPayload().getEmail()).toLowerCase(Locale.ROOT);
			String subject = trim(idToken.getPayload().getSubject());
			User user = userDAO.findByEmail(email).orElse(null);
			if (user == null || !"ACTIVE".equals(user.getStatus())) {
				renderLogin(request, response, "Email Google này chưa có trong danh sách được Admin cấp quyền.");
				return;
			}
			if (!userDAO.linkGoogleSubject(user.getUserId(), subject)) {
				renderLogin(request, response, "Email này đã liên kết với một tài khoản Google khác.");
				return;
			}
			authenticate(request, response, user);
		} catch (SQLException exception) {
			getServletContext().log("Google login failed", exception);
			renderLogin(request, response, "Không thể hoàn tất đăng nhập Google. Vui lòng thử lại.");
		}
	}

	private boolean canUsePassword(User user, String password) {
		if (user == null || !"ACTIVE".equals(user.getStatus()) || password == null || user.getPasswordHash() == null
				|| user.getPasswordHash().isBlank()) {
			return false;
		}
		try {
			return BCrypt.checkpw(password, user.getPasswordHash());
		} catch (IllegalArgumentException exception) {
			return false;
		}
	}

	private void authenticate(HttpServletRequest request, HttpServletResponse response, User user) throws IOException {
		HttpSession session = request.getSession();
		request.changeSessionId();
		session.setAttribute(AuthenticationSupport.SESSION_USER, AuthenticationSupport.sessionCopy(user));
		session.removeAttribute(LOGIN_CSRF);
		redirectToDashboard(request, response, user);
	}

	private void redirectToDashboard(HttpServletRequest request, HttpServletResponse response, User user)
			throws IOException {
		response.sendRedirect(request.getContextPath() + AuthenticationSupport.dashboardForRole(user.getRole()));
	}

	private void renderLogin(HttpServletRequest request, HttpServletResponse response, String error)
			throws ServletException, IOException {
		request.setAttribute("errorMessage", error);
		request.setAttribute("loginCsrfToken", loginCsrf(request));
		request.setAttribute("googleClientId", googleClientId);
		request.setAttribute("googleEnabled", !googleClientId.isBlank());
		request.setAttribute("googleLoginUri", absoluteUrl(request, "/login/google"));
		request.getRequestDispatcher(LOGIN_VIEW).forward(request, response);
	}

	private String loginCsrf(HttpServletRequest request) {
		HttpSession session = request.getSession();
		Object existing = session.getAttribute(LOGIN_CSRF);
		if (existing instanceof String token) {
			return token;
		}
		byte[] bytes = new byte[32];
		RANDOM.nextBytes(bytes);
		String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
		session.setAttribute(LOGIN_CSRF, token);
		return token;
	}

	private boolean validLoginCsrf(HttpServletRequest request) {
		HttpSession session = request.getSession(false);
		return session != null
				&& safeEquals((String) session.getAttribute(LOGIN_CSRF), request.getParameter("csrfToken"));
	}

	private boolean validGoogleCsrf(HttpServletRequest request) {
		String bodyToken = request.getParameter("g_csrf_token");
		String cookieToken = null;
		if (request.getCookies() != null) {
			for (Cookie cookie : request.getCookies()) {
				if ("g_csrf_token".equals(cookie.getName())) {
					cookieToken = cookie.getValue();
					break;
				}
			}
		}
		return safeEquals(cookieToken, bodyToken);
	}

	private boolean safeEquals(String first, String second) {
		return first != null && second != null && MessageDigest.isEqual(first.getBytes(StandardCharsets.UTF_8),
				second.getBytes(StandardCharsets.UTF_8));
	}

	private String absoluteUrl(HttpServletRequest request, String path) {
		return request.getScheme() + "://" + request.getServerName()
				+ ((request.getServerPort() == 80 || request.getServerPort() == 443)
						? ""
						: ":" + request.getServerPort())
				+ request.getContextPath() + path;
	}

	private String trim(String value) {
		return value == null ? "" : value.trim();
	}
}
