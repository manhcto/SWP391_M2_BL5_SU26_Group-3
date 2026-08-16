package fpt.swp391.labtoolequip.controller.auth;

import fpt.swp391.labtoolequip.common.AuthenticationSupport;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebFilter(urlPatterns = {"/admin/*", "/mentor/*", "/lab-manager/*", "/labmanager/*", "/student/*"})
public class AuthenticationFilter implements Filter {
	@Override
	public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) servletRequest;
		HttpServletResponse response = (HttpServletResponse) servletResponse;
		User user = AuthenticationSupport.currentUser(request);
		if (user == null) {
			response.sendRedirect(request.getContextPath() + "/login");
			return;
		}

		response.setHeader("Cache-Control", "no-store");
		request.setAttribute(AuthenticationSupport.SESSION_USER, user);
		chain.doFilter(request, response);
	}
}
