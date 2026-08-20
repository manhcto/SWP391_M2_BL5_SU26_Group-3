package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.Csrf;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/logout")
public class LogoutController extends HttpServlet {
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
		if (request.getSession(false) == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}
		if (!Csrf.valid(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		request.getSession(false).invalidate();
		response.sendRedirect(request.getContextPath() + "/login");
	}
}
