package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/maintenance/*")
public class MentorMaintenanceController extends HttpServlet {
	private final MaintenanceDAO dao = new MaintenanceDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!Authorization.has(request, Permission.MAINTENANCE_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if ("/new".equals(path) || "/add".equals(path)) {
				if (!Authorization.has(request, Permission.MAINTENANCE_REQUEST)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showNewForm(request, response);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("record",
						dao.findByIdForMentor(Long.parseLong(path.substring(1)), AuthSession.userId(request))
								.orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			if (path != null && !"/".equals(path)) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			request.setAttribute("records", dao.findForMentor(AuthSession.userId(request),
					request.getParameter("keyword"), request.getParameter("status")));
			request.setAttribute("keyword", request.getParameter("keyword"));
			request.setAttribute("selectedStatus", request.getParameter("status"));
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
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.MAINTENANCE_REQUEST)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		if (!"create".equals(request.getParameter("action"))) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			long id = dao.createRequest(AuthSession.userId(request), requiredId(request, "assetItemId"),
					optionalId(request, "incidentId"), null, request.getParameter("description"));
			response.sendRedirect(request.getContextPath() + "/mentor/maintenance/" + id + "?success=created");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				showNewForm(request, response);
			} catch (SQLException sqlException) {
				throw new ServletException(sqlException);
			}
		}
	}

	private void showNewForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("assetItems", dao.findRequestableAssetItems());
		request.setAttribute("incidents", dao.findOpenItemIncidentsForMentor(AuthSession.userId(request)));
		forward(request, response, "form.jsp");
	}

	private long requiredId(HttpServletRequest request, String name) {
		Long value = optionalId(request, name);
		if (value == null) {
			throw new IllegalArgumentException("Thiết bị theo mã riêng là bắt buộc.");
		}
		return value;
	}

	private Long optionalId(HttpServletRequest request, String name) {
		String value = request.getParameter(name);
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			long id = Long.parseLong(value);
			if (id <= 0) {
				throw new NumberFormatException();
			}
			return id;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Mã tham chiếu không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/maintenance/" + view).forward(request, response);
	}
}
