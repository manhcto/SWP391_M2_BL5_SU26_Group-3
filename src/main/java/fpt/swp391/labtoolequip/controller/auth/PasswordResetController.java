package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.PasswordResetRequestDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/password-reset")
public class PasswordResetController extends HttpServlet {
	private final PasswordResetRequestDAO dao = new PasswordResetRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.getRequestDispatcher("/WEB-INF/views/auth/password-reset.jsp").forward(request, response);
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
			dao.create(request.getParameter("email"), request.getParameter("note"));
			request.setAttribute("message", "Request submitted for Admin review.");
		} catch (SQLException | RuntimeException e) {
			request.setAttribute("message", e.getMessage());
		}
		doGet(request, response);
	}
}
