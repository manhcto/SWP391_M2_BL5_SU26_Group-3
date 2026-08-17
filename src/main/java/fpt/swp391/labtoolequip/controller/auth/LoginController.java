package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.AuthSession;
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
import util.AppConfig;

@WebServlet("/login")
public class LoginController extends HttpServlet {
	private final UserDAO userDAO = new UserDAO();
	private final SecureRandom random = new SecureRandom();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String role = AuthSession.role(request);
		if (role != null) {
			response.sendRedirect(AuthSession.dashboard(request.getContextPath(), role));
			return;
		}
		request.setAttribute("devAuthEnabled", Boolean.parseBoolean(AppConfig.get("DEV_AUTH_ENABLED", "false")));
		request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!Boolean.parseBoolean(AppConfig.get("DEV_AUTH_ENABLED", "false"))) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		try {
			Optional<User> found = userDAO.findByEmail(request.getParameter("email"));
			if (found.isEmpty() || !"ACTIVE".equals(found.get().getStatus())) {
				request.setAttribute("message", "Access denied: active authorized account required.");
				doGet(request, response);
				return;
			}
			AuthSession.login(request, found.get());
			response.sendRedirect(AuthSession.dashboard(request.getContextPath(), found.get().getRole()));
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	String newState() {
		byte[] bytes = new byte[32];
		random.nextBytes(bytes);
		return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
	}
}
