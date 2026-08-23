package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/maintenance/*")
public class LabManagerMaintenanceController extends HttpServlet {
	private final MaintenanceDAO dao = new MaintenanceDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();

			// /lab-manager/maintenance/new -> Lab Manager cũng có thể tạo phiếu bảo trì
			if ("/new".equals(path)) {
				showCreateForm(request, response);
				return;
			}

			// /lab-manager/maintenance/123/edit -> Cập nhật tiến độ / phê duyệt
			if (path != null && path.matches("/\\d+/edit")) {
				long id = Long.parseLong(path.substring(1, path.lastIndexOf('/')));
				request.setAttribute("record", dao.findById(id).orElseThrow());
				request.setAttribute("formMode", "edit");
				forward(request, response, "form.jsp");
				return;
			}

			// /lab-manager/maintenance/123 -> Chi tiết phiếu bảo trì
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("record", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}

			// /lab-manager/maintenance -> Danh sách toàn bộ phiếu bảo trì
			request.setAttribute("records",
					dao.findAll(request.getParameter("keyword"), request.getParameter("status")));
			request.setAttribute("summary", dao.findSummary());
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
		String action = request.getParameter("action");
		try {
			long id;

			switch (action == null ? "" : action) {
				// Lab Manager tạo phiếu bảo trì (trực tiếp IN_PROGRESS)
				case "create" -> {
					String incidentParam = request.getParameter("incidentId");
					Long incidentId = (incidentParam == null || incidentParam.isBlank())
							? null
							: Long.parseLong(incidentParam);
					id = dao.create(AuthSession.userId(request), Long.parseLong(request.getParameter("assetId")),
							incidentId, request.getParameter("approvalNote"), request.getParameter("note"),
							request.getParameter("providerPhone"), request.getParameter("providerAddress"),
							request.getParameter("description"), parseCost(request.getParameter("estimatedCost")));
				}
				// Lab Manager cập nhật tiến độ sửa chữa
				case "updateProgress" -> {
					id = Long.parseLong(request.getParameter("id"));
					dao.updateProgress(id, request.getParameter("status"), request.getParameter("approvalNote"),
							request.getParameter("note"), request.getParameter("providerPhone"),
							request.getParameter("providerAddress"), request.getParameter("repairResult"),
							parseCost(request.getParameter("actualCost")));
				}
				// Lab Manager xóa phiếu bảo trì (trả thiết bị về AVAILABLE)
				case "delete" -> {
					id = Long.parseLong(request.getParameter("id"));
					dao.delete(id);
					response.sendRedirect(request.getContextPath() + "/lab-manager/maintenance?success=deleted");
					return;
				}
				default -> {
					response.sendError(HttpServletResponse.SC_BAD_REQUEST);
					return;
				}
			}

			response.sendRedirect(request.getContextPath() + "/lab-manager/maintenance/" + id + "?success=saved");

		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			if ("create".equals(action)) {
				try {
					showCreateForm(request, response);
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
			} else {
				doGet(request, response);
			}
		}
	}

	private void showCreateForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("routineAssets", dao.findRoutineMaintenanceAssets());
		request.setAttribute("incidents", dao.findOpenIncidents());
		forward(request, response, "form.jsp");
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/maintenance/" + view).forward(request, response);
	}

	private Long parseCost(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			long cost = Long.parseLong(value.trim());
			return cost >= 0 ? cost : null;
		} catch (NumberFormatException exception) {
			return null;
		}
	}
}
