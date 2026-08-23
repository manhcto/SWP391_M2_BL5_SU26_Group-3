package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.util.Base64;
import java.util.Optional;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/login")
public class LoginController extends HttpServlet {
	private static final AuthenticationThrottle THROTTLE = new AuthenticationThrottle();
	private final UserDAO userDAO = new UserDAO();
	private final SecureRandom random = new SecureRandom();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (AuthSession.mustChangePassword(request)) {
			response.sendRedirect(request.getContextPath() + "/change-password");
			return;
		}
		String role = AuthSession.role(request);
		if (role != null) {
			response.sendRedirect(AuthSession.dashboard(request.getContextPath(), role));
			return;
		}
		request.setAttribute("csrfToken", Csrf.token(request));
		request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		String email = request.getParameter("email");
		String password = request.getParameter("password");
		request.setAttribute("email", email);
		if (!THROTTLE.tryAcquire(request.getRemoteAddr())) {
			request.setAttribute("message", "Email hoặc mật khẩu không chính xác.");
			doGet(request, response);
			return;
		}
		try {
			Optional<User> found = userDAO.findByEmail(email);
			if (found.isEmpty() || !validInternalPassword(found.get(), password)) {
				request.setAttribute("message", "Email hoặc mật khẩu không chính xác.");
				doGet(request, response);
				return;
			}
			THROTTLE.reset(request.getRemoteAddr());
			AuthSession.login(request, found.get());
			response.sendRedirect(AuthSession.mustChangePassword(request)
					? request.getContextPath() + "/change-password"
					: AuthSession.dashboard(request.getContextPath(), found.get().getRole()));
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	static boolean validPassword(User user, String password) {
		if (user == null || password == null || !"ACTIVE".equals(user.getStatus()) || user.getPasswordHash() == null
				|| user.getPasswordHash().isBlank()) {
			return false;
		}
		try {
			return BCrypt.checkpw(password, user.getPasswordHash());
		} catch (IllegalArgumentException exception) {
			return false;
		}
	}

	static boolean validInternalPassword(User user, String password) {
		return user != null && AuthSession.isInternalRole(user.getRole()) && validPassword(user, password)
				&& !user.isTemporaryPasswordExpired(ViewFormat.now());
	}

	String newState() {
		byte[] bytes = new byte[32];
		random.nextBytes(bytes);
		return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
	}
}
