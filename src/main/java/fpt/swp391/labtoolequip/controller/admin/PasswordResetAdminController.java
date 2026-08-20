package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.PasswordResetRequestDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.util.Base64;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/admin/password-resets")
public class PasswordResetAdminController extends HttpServlet {
	private final PasswordResetRequestDAO dao = new PasswordResetRequestDAO();
	private final SecureRandom random = new SecureRandom();
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("requests", dao.findAll());
			request.setAttribute("csrfToken", Csrf.token(request));
			request.getRequestDispatcher("/WEB-INF/views/admin/password-resets.jsp").forward(request, response);
		} catch (SQLException e) {
			throw new ServletException(e);
		}
	}
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request)) {
			response.sendError(403);
			return;
		}
		try {
			long id = Long.parseLong(request.getParameter("requestId"));
			String action = request.getParameter("action");
			if ("approve".equals(action) || "reject".equals(action))
				dao.review(id, AuthSession.userId(request), "approve".equals(action), request.getParameter("note"));
			else if ("issue".equals(action)) {
				byte[] bytes = new byte[12];
				random.nextBytes(bytes);
				String temporary = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
				dao.issue(id, AuthSession.userId(request), BCrypt.hashpw(temporary, BCrypt.gensalt()));
				request.setAttribute("temporaryPassword", temporary);
			} else {
				response.sendError(400);
				return;
			}
			request.setAttribute("message", "Request updated.");
			doGet(request, response);
		} catch (SQLException e) {
			throw new ServletException(e);
		} catch (RuntimeException e) {
			request.setAttribute("message", e.getMessage());
			doGet(request, response);
		}
	}
}
