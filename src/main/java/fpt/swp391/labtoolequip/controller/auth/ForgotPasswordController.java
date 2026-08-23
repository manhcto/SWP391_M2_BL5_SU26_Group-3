package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.PasswordResetRequestDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/forgot-password")
public class ForgotPasswordController extends HttpServlet {
	private static final String REQUEST_ACCEPTED = "Nếu tài khoản hợp lệ và chưa có yêu cầu đang xử lý, yêu cầu đã được gửi đến quản trị viên.";
	private static final AuthenticationThrottle THROTTLE = new AuthenticationThrottle();
	private final PasswordResetRequestDAO dao = new PasswordResetRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.getRequestDispatcher("/WEB-INF/views/auth/forgot-password.jsp").forward(request, response);
	}
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request)) {
			response.sendError(403);
			return;
		}
		String email = request.getParameter("email");
		String note = request.getParameter("note");
		if (email == null || !email.trim().matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$") || email.trim().length() > 255
				|| note != null && note.length() > 500) {
			request.setAttribute("message", "Vui lòng nhập địa chỉ email hợp lệ.");
			doGet(request, response);
			return;
		}
		if (!THROTTLE.tryAcquire(request.getRemoteAddr())) {
			request.setAttribute("success", REQUEST_ACCEPTED);
			doGet(request, response);
			return;
		}
		try {
			dao.create(email.trim(), note);
			request.setAttribute("success", REQUEST_ACCEPTED);
		} catch (SQLException e) {
			getServletContext().log("Could not create password reset request", e);
			request.setAttribute("message", "Không thể gửi yêu cầu lúc này. Vui lòng thử lại sau.");
		}
		doGet(request, response);
	}
}
