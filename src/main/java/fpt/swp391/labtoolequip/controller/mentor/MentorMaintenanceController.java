package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
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
		try {
			String path = request.getPathInfo();

			// /mentor/maintenance/new -> Form tạo đề xuất bảo trì mới
			if ("/new".equals(path)) {
				request.setAttribute("assets", dao.findEligibleAssets());
				request.setAttribute("incidents", dao.findOpenIncidents());
				forward(request, response, "form.jsp");
				return;
			}

			// /mentor/maintenance/123 -> Xem chi tiết và tiến độ phiếu bảo trì
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("record", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}

			// /mentor/maintenance -> Danh sách phiếu bảo trì
			request.setAttribute("records",
					dao.findAll(request.getParameter("keyword"), request.getParameter("status")));
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
		try {
			String action = request.getParameter("action");

			if ("create".equals(action)) {
				String incidentParam = request.getParameter("incidentId");
				Long incidentId = (incidentParam == null || incidentParam.isBlank())
						? null
						: Long.parseLong(incidentParam);
				long id = dao.create(AuthSession.userId(request), Long.parseLong(request.getParameter("assetId")),
						incidentId, Integer.parseInt(request.getParameter("quantity")),
						request.getParameter("description"));
				response.sendRedirect(request.getContextPath() + "/mentor/maintenance/" + id);
				return;
			}

			response.sendError(HttpServletResponse.SC_BAD_REQUEST);

		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/maintenance/" + view).forward(request, response);
	}
}
