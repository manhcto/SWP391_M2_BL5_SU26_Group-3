package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import fpt.swp391.labtoolequip.model.Responsibility;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/responsibilities/*")
public class ResponsibilityController extends HttpServlet {
	private final ResponsibilityDAO dao = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!Authorization.has(request, Permission.RESPONSIBILITY_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			String path = request.getPathInfo();
			if (path == null || "/".equals(path)) {
				showList(request, response);
				return;
			}
			if ("/new".equals(path)) {
				if (!Authorization.has(request, Permission.RESPONSIBILITY_ASSESS)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response, null);
				return;
			}
			if (path.matches("/\\d+/edit")) {
				if (!Authorization.has(request, Permission.RESPONSIBILITY_ASSESS)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response,
						dao.findByIdForMentorAssessment(idFrom(path), AuthSession.userId(request)).orElseThrow());
				return;
			}
			if (path.matches("/\\d+")) {
				request.setAttribute("responsibility",
						dao.findByIdForMentor(idFrom(path), AuthSession.userId(request)).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
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
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.RESPONSIBILITY_ASSESS)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		try {
			long id;
			switch (action == null ? "" : action) {
				case "create" -> id = dao.createAssessment(AuthSession.userId(request),
						requiredId(request, "incidentId", "Sự cố"), request.getParameter("responsibilityLevel"),
						optionalId(request, "relatedStudentId", "Thực tập sinh"),
						request.getParameter("evidenceSummary"), request.getParameter("responsibilityNote"),
						request.getParameter("handlingRecommendation"));
				case "update" -> {
					id = requiredId(request, "responsibilityId", "Hồ sơ trách nhiệm");
					dao.updateAssessment(AuthSession.userId(request), id, request.getParameter("responsibilityLevel"),
							optionalId(request, "relatedStudentId", "Thực tập sinh"),
							request.getParameter("evidenceSummary"), request.getParameter("responsibilityNote"),
							request.getParameter("handlingRecommendation"));
				}
				default -> {
					response.sendError(HttpServletResponse.SC_BAD_REQUEST);
					return;
				}
			}
			response.sendRedirect(request.getContextPath() + "/mentor/responsibilities/" + id + "?success=" + action);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				Responsibility record = formRecord(request, action);
				showForm(request, response, record);
			} catch (SQLException nested) {
				throw new ServletException(nested);
			} catch (RuntimeException nested) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			}
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = request.getParameter("keyword");
		String status = request.getParameter("status");
		request.setAttribute("keyword", keyword);
		request.setAttribute("selectedStatus", status);
		request.setAttribute("responsibilities", dao.findForMentor(AuthSession.userId(request), keyword, status));
		forward(request, response, "list.jsp");
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response, Responsibility record)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("responsibility", record);
		request.setAttribute("interns", dao.findSupervisedInterns(AuthSession.userId(request)));
		if (record == null || record.getResponsibilityId() == null)
			request.setAttribute("incidents", dao.findEligibleIncidents(AuthSession.userId(request)));
		forward(request, response, "form.jsp");
	}

	private Responsibility formRecord(HttpServletRequest request, String action) throws SQLException {
		Responsibility record = null;
		if ("update".equals(action)) {
			long id = requiredId(request, "responsibilityId", "Hồ sơ trách nhiệm");
			record = dao.findByIdForMentorAssessment(id, AuthSession.userId(request)).orElseThrow();
		} else if (request.getParameter("incidentId") != null) {
			record = new Responsibility();
			record.setIncidentId(requiredId(request, "incidentId", "Sự cố"));
		}
		if (record != null) {
			record.setInternId(optionalId(request, "relatedStudentId", "Thực tập sinh"));
			record.setResponsibilityLevel(request.getParameter("responsibilityLevel"));
			record.setEvidenceSummary(request.getParameter("evidenceSummary"));
			record.setResponsibilityNote(request.getParameter("responsibilityNote"));
			record.setHandlingRecommendation(request.getParameter("handlingRecommendation"));
		}
		return record;
	}

	private Long optionalId(HttpServletRequest request, String parameter, String label) {
		String value = request.getParameter(parameter);
		if (value == null || value.isBlank())
			return null;
		return requiredId(request, parameter, label);
	}

	private long requiredId(HttpServletRequest request, String parameter, String label) {
		try {
			long id = Long.parseLong(request.getParameter(parameter));
			if (id <= 0)
				throw new NumberFormatException();
			return id;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException(label + " không hợp lệ.");
		}
	}

	private long idFrom(String path) {
		return Long.parseLong(path.split("/")[1]);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/responsibilities/" + view).forward(request, response);
	}
}
