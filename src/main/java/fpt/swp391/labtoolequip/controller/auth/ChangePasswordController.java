package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.dao.PasswordResetRequestDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/change-password")
public class ChangePasswordController extends HttpServlet {
	private final UserDAO users = new UserDAO();
	private final PasswordResetRequestDAO resets = new PasswordResetRequestDAO();
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String role = AuthSession.role(request);
		if (role == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}
		if (!AuthSession.isInternalRole(role)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		request.setAttribute("csrfToken", Csrf.token(request));
		request.getRequestDispatcher("/WEB-INF/views/auth/change-password.jsp").forward(request, response);
	}
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String role = AuthSession.role(request);
		if (role == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}
		if (!AuthSession.isInternalRole(role)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request)) {
			response.sendError(403);
			return;
		}
		String current = request.getParameter("currentPassword"), password = request.getParameter("newPassword"),
				confirm = request.getParameter("confirmPassword");
		try {
			User user = users.findById(AuthSession.userId(request)).orElseThrow();
			if (!AuthSession.isInternalRole(user.getRole())) {
				response.sendError(HttpServletResponse.SC_FORBIDDEN);
				return;
			}
			if (user.isTemporaryPasswordExpired(ViewFormat.now()))
				throw new IllegalArgumentException("Temporary password has expired.");
			if (!LoginController.validPassword(user, current))
				throw new IllegalArgumentException("Current password is incorrect.");
			if (!validNewPassword(password) || !password.equals(confirm))
				throw new IllegalArgumentException("Mật khẩu mới phải khớp và có độ dài từ 8 đến 72 byte UTF-8.");
			if (!users.changePassword(user.getUserId(), BCrypt.hashpw(password, BCrypt.gensalt())))
				throw new IllegalStateException("Password could not be changed.");
			resets.consumeIssued(user.getUserId());
			user = users.findById(user.getUserId()).orElseThrow();
			AuthSession.login(request, user);
			response.sendRedirect(AuthSession.dashboard(request.getContextPath(), user.getRole()));
		} catch (SQLException e) {
			throw new ServletException(e);
		} catch (RuntimeException e) {
			request.setAttribute("message", e.getMessage());
			doGet(request, response);
		}
	}

	static boolean validNewPassword(String password) {
		if (password == null)
			return false;
		int bytes = password.getBytes(StandardCharsets.UTF_8).length;
		return bytes >= 8 && bytes <= 72;
	}
}
