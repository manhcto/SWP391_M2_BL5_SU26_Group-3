package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import fpt.swp391.labtoolequip.model.AssetItem;
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
	private final AssetItemDAO assetItemDAO = new AssetItemDAO();

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
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("record", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			if (path != null && !"/".equals(path)) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
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
		request.setCharacterEncoding("UTF-8");
		if (!Authorization.has(request, Permission.MAINTENANCE_REQUEST)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		if (!Csrf.valid(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		if (!"create".equals(request.getParameter("action"))) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			long itemId = positiveLong(request.getParameter("assetItemId"), "Thiết bị");
			AssetItem item = assetItemDAO.findById(itemId)
					.orElseThrow(() -> new IllegalArgumentException("Thiết bị không tồn tại."));
			Long incidentId = optionalLong(request.getParameter("incidentId"));
			long id = dao.create(AuthSession.userId(request), item.getAssetId(), itemId, incidentId, null, null, null,
					null, null, request.getParameter("description"), null);
			response.sendRedirect(request.getContextPath() + "/mentor/maintenance/" + id + "?success=created");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				showForm(request, response);
			} catch (SQLException nested) {
				throw new ServletException(nested);
			}
		}
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("assetItems", dao.findRoutineMaintenanceAssets().stream()
				.filter(item -> item.getAssetItemId() != null && !"IN_USE".equals(item.getStatus())).toList());
		request.setAttribute("incidents", dao.findOpenIncidents());
		forward(request, response, "form.jsp");
	}

	private long positiveLong(String value, String field) {
		try {
			long parsed = Long.parseLong(value);
			if (parsed <= 0)
				throw new NumberFormatException();
			return parsed;
		} catch (RuntimeException exception) {
			throw new IllegalArgumentException(field + " không hợp lệ.");
		}
	}

	private Long optionalLong(String value) {
		return value == null || value.isBlank() ? null : positiveLong(value, "Sự cố");
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/mentor/maintenance/" + view).forward(request, response);
	}
}
