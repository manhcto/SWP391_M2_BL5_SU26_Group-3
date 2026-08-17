package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
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
		try {
			String path = request.getPathInfo();
			if (path == null || "/".equals(path)) {
				showList(request, response);
				return;
			}
			if ("/new".equals(path)) {
				showForm(request, response, null);
				return;
			}
			if (path.matches("/\\d+/edit")) {
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
		String action = request.getParameter("action");
		try {
			long id;
			switch (action == null ? "" : action) {
				case "create" ->
					id = dao.create(AuthSession.userId(request), Long.parseLong(request.getParameter("incidentId")),
							request.getParameter("conclusion"), request.getParameter("decision"),
							request.getParameter("status"), request.getParameter("resolutionNote"));
				case "update" -> {
					id = Long.parseLong(request.getParameter("responsibilityId"));
					dao.update(AuthSession.userId(request), id, request.getParameter("conclusion"),
							request.getParameter("decision"), request.getParameter("status"),
							request.getParameter("resolutionNote"));
				}
				case "delete" -> {
					id = Long.parseLong(request.getParameter("responsibilityId"));
					dao.delete(AuthSession.userId(request), id);
					response.sendRedirect(request.getContextPath() + "/mentor/responsibilities?success=deleted");
					return;
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
			}
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = request.getParameter("keyword");
		String status = request.getParameter("status");
		request.setAttribute("keyword", keyword);
		request.setAttribute("selectedStatus", status);
		request.setAttribute("responsibilities", dao.findAll(keyword, status));
		forward(request, response, "list.jsp");
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response, Responsibility record)
			throws SQLException, ServletException, IOException {
		request.setAttribute("responsibility", record);
		if (record == null || record.getResponsibilityId() == null)
			request.setAttribute("incidents", dao.findEligibleIncidents());
		forward(request, response, "form.jsp");
	}

	private Responsibility formRecord(HttpServletRequest request, String action) throws SQLException {
		Responsibility record = null;
		if ("update".equals(action)) {
			long id = Long.parseLong(request.getParameter("responsibilityId"));
			record = dao.findById(id).orElseThrow();
		} else if (request.getParameter("incidentId") != null) {
			record = new Responsibility();
			record.setIncidentId(Long.parseLong(request.getParameter("incidentId")));
		}
		if (record != null) {
			record.setConclusion(request.getParameter("conclusion"));
			record.setDecision(request.getParameter("decision"));
			record.setStatus(request.getParameter("status"));
			record.setResolutionNote(request.getParameter("resolutionNote"));
		}
		return record;
	}

	private long idFrom(String path) {
		return Long.parseLong(path.split("/")[1]);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/responsibilities/" + view).forward(request, response);
	}
}
