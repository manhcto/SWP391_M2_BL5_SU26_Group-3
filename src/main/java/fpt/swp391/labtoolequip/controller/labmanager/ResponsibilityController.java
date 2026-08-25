package fpt.swp391.labtoolequip.controller.labmanager;

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

@WebServlet("/lab-manager/responsibilities/*")
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
				String keyword = request.getParameter("keyword");
				String status = request.getParameter("status");
				request.setAttribute("keyword", keyword);
				request.setAttribute("selectedStatus", status);
				request.setAttribute("responsibilities", dao.findAll(keyword, status));
				forward(request, response, "list.jsp");
				return;
			}
			if ("/new".equals(path)) {
				if (!Authorization.has(request, Permission.RESPONSIBILITY_ASSESS)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response, new Responsibility());
				return;
			}
			if (path.matches("/\\d+/edit")) {
				if (!Authorization.has(request, Permission.RESPONSIBILITY_ASSESS)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response, dao.findById(idFrom(path)).orElseThrow());
				return;
			}
			if (path.matches("/\\d+")) {
				request.setAttribute("responsibility", dao.findById(idFrom(path)).orElseThrow());
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
			if ("create".equals(action)) {
				id = dao.createByLabManager(AuthSession.userId(request), requiredId(request, "incidentId", "Sự cố"),
						request.getParameter("responsibilityLevel"),
						optionalId(request, "relatedStudentId", "Thực tập sinh"),
						request.getParameter("evidenceSummary"), request.getParameter("responsibilityNote"),
						request.getParameter("handlingRecommendation"));
			} else if ("assign".equals(action)) {
				id = requiredId(request, "responsibilityId", "Hồ sơ trách nhiệm");
				dao.assignByLabManager(AuthSession.userId(request), id, request.getParameter("responsibilityLevel"),
						optionalId(request, "relatedStudentId", "Thực tập sinh"),
						request.getParameter("evidenceSummary"), request.getParameter("responsibilityNote"),
						request.getParameter("handlingRecommendation"));
			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			response.sendRedirect(request.getContextPath() + "/lab-manager/responsibilities/" + id
					+ "?success=" + action);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				Responsibility record;
				if ("create".equals(action)) {
					record = new Responsibility();
					record.setIncidentId(requiredId(request, "incidentId", "Sự cố"));
				} else {
					record = dao.findById(requiredId(request, "responsibilityId", "Hồ sơ trách nhiệm"))
							.orElseThrow();
				}
				record.setInternId(optionalId(request, "relatedStudentId", "Thực tập sinh"));
				record.setResponsibilityLevel(request.getParameter("responsibilityLevel"));
				record.setEvidenceSummary(request.getParameter("evidenceSummary"));
				record.setResponsibilityNote(request.getParameter("responsibilityNote"));
				record.setHandlingRecommendation(request.getParameter("handlingRecommendation"));
				showForm(request, response, record);
			} catch (SQLException nested) {
				throw new ServletException(nested);
			} catch (RuntimeException nested) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			}
		}
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response, Responsibility record)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("responsibility", record);
		request.setAttribute("interns", dao.findActiveInterns());
		if (record.getResponsibilityId() == null)
			request.setAttribute("incidents", dao.findUnassignedIncidents());
		forward(request, response, "form.jsp");
	}

	private Long optionalId(HttpServletRequest request, String parameter, String label) {
		String value = request.getParameter(parameter);
		return value == null || value.isBlank() ? null : requiredId(request, parameter, label);
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
		request.getRequestDispatcher("/WEB-INF/views/labmanager/responsibilities/" + view).forward(request, response);
	}
}
