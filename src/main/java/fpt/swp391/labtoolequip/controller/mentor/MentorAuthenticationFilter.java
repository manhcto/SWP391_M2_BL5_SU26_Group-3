package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

@WebFilter("/mentor/*")
public class MentorAuthenticationFilter implements Filter {
	private static final String DEMO_MENTOR_EMAIL = "minhanh@gmail.com";
	private final UserDAO userDAO = new UserDAO();

	@Override
	public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) servletRequest;
		HttpServletResponse response = (HttpServletResponse) servletResponse;
		HttpSession session = request.getSession(false);
		User user = session == null ? null : (User) session.getAttribute("currentUser");
		if (user == null) {
			try {
				user = userDAO.findByEmail(DEMO_MENTOR_EMAIL).orElse(null);
			} catch (SQLException exception) {
				throw new ServletException("Không thể tải tài khoản Mentor demo.", exception);
			}
			if (user == null) {
				response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
						"Chưa có tài khoản Mentor demo. Hãy chạy database/migrate_lab_usage_requests.sql.");
				return;
			}
			request.getSession(true).setAttribute("currentUser", user);
		}
		if (!"MENTOR".equals(user.getRole())) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		chain.doFilter(request, response);
	}
}
