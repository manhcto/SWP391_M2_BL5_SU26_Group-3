package fpt.swp391.labtoolequip.auth;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebFilter("/*")
public class AuthorizationFilter implements Filter {
	@Override
	public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) servletRequest;
		HttpServletResponse response = (HttpServletResponse) servletResponse;
		String path = request.getRequestURI().substring(request.getContextPath().length());
		String requiredRole = requiredRole(path);
		if (requiredRole == null) {
			chain.doFilter(request, response);
			return;
		}

		String role = AuthSession.role(request);
		if (role == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}
		if (!requiredRole.equals(role)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		chain.doFilter(request, response);
	}

	private String requiredRole(String path) {
		if (path.startsWith("/admin/"))
			return "ADMIN";
		if (path.startsWith("/lab-manager/"))
			return "LAB_MANAGER";
		if (path.startsWith("/mentor/"))
			return "MENTOR";
		if (path.startsWith("/intern/") || path.startsWith("/student/"))
			return "INTERN";
		return null;
	}
}
