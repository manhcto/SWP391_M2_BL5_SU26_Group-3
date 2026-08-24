package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/incidents/*")
public class IncidentController extends HttpServlet {
	private final IncidentDAO dao = new IncidentDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!Authorization.has(request, Permission.INCIDENT_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("incident",
						dao.findByIdForLabManager(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			if (path != null && !"/".equals(path)) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			String keyword = request.getParameter("keyword");
			String status = request.getParameter("status");
			String severity = request.getParameter("severity");
			request.setAttribute("keyword", keyword);
			request.setAttribute("selectedStatus", status);
			request.setAttribute("selectedSeverity", severity);
			request.setAttribute("incidents", dao.findForLabManager(keyword, status, severity));
			forward(request, response, "list.jsp");
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
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.INCIDENT_RESOLVE)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		if (!"update".equals(action)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			long incidentId = incidentId(request);
			dao.updateByLabManager(incidentId, AuthSession.userId(request), request.getParameter("status"),
					request.getParameter("technicalCause"), request.getParameter("technicalSeverity"),
					request.getParameter("repairability"), request.getParameter("recommendedAction"),
					request.getParameter("technicalNote"), request.getParameter("handlingResult"));
			response.sendRedirect(request.getContextPath() + "/lab-manager/incidents/" + incidentId + "?updated=1");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		}
	}

	private long incidentId(HttpServletRequest request) {
		try {
			long value = Long.parseLong(request.getParameter("incidentId"));
			if (value <= 0) {
				throw new NumberFormatException();
			}
			return value;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Sự cố không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/incidents/" + view).forward(request, response);
	}
}
