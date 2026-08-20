package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
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
	private final ResponsibilityDAO responsibilityDAO = new ResponsibilityDAO();

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
				request.setAttribute("incident", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
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
			request.setAttribute("incidents", dao.findAll(keyword, status, severity));
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
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.INCIDENT_REVIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		if (!"update".equals(action) && !"createResponsibility".equals(action)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			long incidentId = incidentId(request);
			dao.updateByLabManager(incidentId, request.getParameter("status"),
					request.getParameter("investigationNote"), request.getParameter("handlingResult"),
					request.getParameter("determinedCause"));
			if ("createResponsibility".equals(action)) {
				var incident = dao.findById(incidentId).orElseThrow();
				if (!"INTERN".equals(incident.getDeterminedCause()) || incident.getInternName() == null)
					throw new IllegalStateException(
							"Chỉ tạo trách nhiệm khi Lab Manager kết luận Intern gây ra và có Intern liên quan.");
				String conclusion = request.getParameter("investigationNote");
				if (conclusion == null || conclusion.isBlank())
					conclusion = "Lab Manager xác định thực tập sinh chịu trách nhiệm.";
				long responsibilityId = responsibilityDAO.create(AuthSession.userId(request), incidentId, conclusion,
						null, "CONFIRMED", null);
				response.sendRedirect(
						request.getContextPath() + "/lab-manager/responsibilities/" + responsibilityId + "/edit");
				return;
			}
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
