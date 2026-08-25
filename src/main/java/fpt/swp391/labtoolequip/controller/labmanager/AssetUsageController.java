package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/usages/*")
public class AssetUsageController extends HttpServlet {
	private final AssetUsageDAO dao = new AssetUsageDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("usage", dao.findById(Long.parseLong(path.substring(1)), null).orElseThrow());
				request.getRequestDispatcher("/WEB-INF/views/labmanager/usages/detail.jsp").forward(request, response);
				return;
			}
			request.setAttribute("usages", dao.findAll(request.getParameter("keyword"), request.getParameter("status"),
					request.getParameter("fromDate"), request.getParameter("toDate")));
			request.getRequestDispatcher("/WEB-INF/views/labmanager/usages/list.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.ASSET_USAGE_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			if (!"confirmReturn".equals(request.getParameter("action"))) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			long usageId = Long.parseLong(request.getParameter("usageId"));
			dao.confirmReturnAsLabManager(usageId, AuthSession.userId(request),
					request.getParameter("verifiedCondition"), request.getParameter("note"));
			response.sendRedirect(request.getContextPath() + "/lab-manager/usages/" + usageId);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		}
	}
}
