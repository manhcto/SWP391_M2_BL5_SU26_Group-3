package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;

@WebServlet("/mentor/incidents/*")
public class MentorIncidentController extends HttpServlet {
	private final IncidentDAO incidentDAO = new IncidentDAO();
	private final AssetUsageDAO usageDAO = new AssetUsageDAO();
	private final AssetItemDAO assetItemDAO = new AssetItemDAO();

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
			if ("/new".equals(path)) {
				if (!Authorization.has(request, Permission.INCIDENT_REPORT)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				showDetail(request, response, Long.parseLong(path.substring(1)));
				return;
			}
			if (path != null && !"/".equals(path)) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			request.setAttribute("keyword", request.getParameter("keyword"));
			request.setAttribute("selectedStatus", request.getParameter("status"));
			request.setAttribute("selectedSeverity", request.getParameter("severity"));
			request.setAttribute("incidents", incidentDAO.findForMentor(AuthSession.userId(request),
					request.getParameter("keyword"), request.getParameter("status"), request.getParameter("severity")));
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
		if (!Csrf.valid(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		if (!"create".equals(action) && !"forward".equals(action)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			if ("create".equals(action)) {
				if (!Authorization.has(request, Permission.INCIDENT_REPORT)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				var incidentIds = incidentDAO.createForMentor(AuthSession.userId(request),
						request.getParameterValues("targets"), request.getParameter("incidentType"),
						request.getParameter("severity"), occurredAt(request), request.getParameter("description"),
						request.getParameter("reportedCause"));
				response.sendRedirect(request.getContextPath() + "/mentor/incidents?created=" + incidentIds.size());
				return;
			}
			if (!Authorization.has(request, Permission.INCIDENT_REVIEW)) {
				response.sendError(HttpServletResponse.SC_FORBIDDEN);
				return;
			}
			long incidentId = incidentId(request);
			incidentDAO.reviewAndForward(incidentId, AuthSession.userId(request),
					request.getParameter("mentorReviewNote"));
			response.sendRedirect(request.getContextPath() + "/mentor/incidents/" + incidentId + "?forwarded=1");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				if ("create".equals(action))
					showForm(request, response);
				else
					showDetail(request, response, incidentId(request));
			} catch (SQLException nested) {
				throw new ServletException(nested);
			}
		}
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		var usages = usageDAO.findForMentor(AuthSession.userId(request), "", "");
		request.setAttribute("usages", usages);
		String usageId = request.getParameter("usageId");
		if (usageId != null && usageId.matches("\\d+")
				&& usages.stream().anyMatch(usage -> usage.getAssetUsageId().toString().equals(usageId)))
			request.setAttribute("preselectedTarget", "usage:" + usageId);
		request.setAttribute("assetItems", assetItemDAO.findReportableItems());
		forward(request, response, "form.jsp");
	}

	private void showDetail(HttpServletRequest request, HttpServletResponse response, long incidentId)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("incident",
				incidentDAO.findByIdForMentor(incidentId, AuthSession.userId(request)).orElseThrow());
		forward(request, response, "detail.jsp");
	}

	private long incidentId(HttpServletRequest request) {
		try {
			long value = Long.parseLong(request.getParameter("incidentId"));
			if (value <= 0)
				throw new NumberFormatException();
			return value;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Sự cố không hợp lệ.");
		}
	}

	private LocalDateTime occurredAt(HttpServletRequest request) {
		String value = request.getParameter("occurredAt");
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			return LocalDateTime.parse(value);
		} catch (RuntimeException exception) {
			throw new IllegalArgumentException("Thời điểm xảy ra không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/incidents/" + view).forward(request, response);
	}
}
