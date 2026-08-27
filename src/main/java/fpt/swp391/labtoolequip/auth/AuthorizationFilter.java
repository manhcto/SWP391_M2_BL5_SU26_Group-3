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
	static boolean isAuthorized(Permission permission, String role) {
		return Authorization.has(role, permission);
	}

	@Override
	public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) servletRequest;
		HttpServletResponse response = (HttpServletResponse) servletResponse;
		Csrf.token(request);
		String path = request.getRequestURI().substring(request.getContextPath().length());
		if ("/password-reset".equals(path))
			response.setHeader("Cache-Control", "no-store");
		String role = AuthSession.role(request);
		if (role != null && AuthSession.mustChangePassword(request) && !allowsPasswordChange(path)) {
			response.sendRedirect(request.getContextPath() + "/change-password");
			return;
		}
		if (isUnsafe(request.getMethod()) && !Csrf.valid(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String requiredRole = requiredRole(path);
		if (requiredRole == null) {
			chain.doFilter(request, response);
			return;
		}

		if (role == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}
		if (!requiredRole.equals(role)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		request.setAttribute("permissions", Authorization.view(role));
		chain.doFilter(request, response);
	}

	static boolean isUnsafe(String method) {
		return !"GET".equals(method) && !"HEAD".equals(method) && !"OPTIONS".equals(method);
	}

	static boolean allowsPasswordChange(String path) {
		return "/change-password".equals(path) || "/logout".equals(path);
	}

	private String requiredRole(String path) {
		if (path.startsWith("/admin/"))
			return "ADMIN";
		if (path.startsWith("/lab-manager/"))
			return "LAB_MANAGER";
		if (path.startsWith("/mentor/"))
			return "MENTOR";
		if (path.startsWith("/intern/"))
			return "INTERN";
		return null;
	}
}
