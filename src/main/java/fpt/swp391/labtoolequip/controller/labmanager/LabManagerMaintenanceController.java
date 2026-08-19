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
				request.setAttribute("assets", dao.findEligibleAssets());
				request.setAttribute("incidents", dao.findOpenIncidents());
				forward(request, response, "form.jsp");
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
			long id;

			switch (action == null ? "" : action) {
				// Lab Manager tạo phiếu bảo trì
				case "create" -> {
					String incidentParam = request.getParameter("incidentId");
					Long incidentId = (incidentParam == null || incidentParam.isBlank())
							? null
							: Long.parseLong(incidentParam);
					id = dao.create(AuthSession.userId(request), Long.parseLong(request.getParameter("assetId")),
							incidentId, parseQuantity(request), request.getParameter("description"));
				}
				// Lab Manager phê duyệt hoặc từ chối
				case "decide" -> {
					id = Long.parseLong(request.getParameter("id"));
					String decision = request.getParameter("decision");
					String note = "REJECTED".equals(decision) ? null : request.getParameter("note");
					String approvalNote = "REJECTED".equals(decision)
							? request.getParameter("rejectReason")
							: request.getParameter("approvalNote");
					dao.decide(id, AuthSession.userId(request), decision, approvalNote, note);
				}
				// Lab Manager cập nhật tiến độ sửa chữa
				case "updateProgress" -> {
					id = Long.parseLong(request.getParameter("id"));
					dao.updateProgress(id, request.getParameter("status"), request.getParameter("approvalNote"),
							request.getParameter("note"), request.getParameter("repairResult"));
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
			doGet(request, response);
		}
	}

	private int parseQuantity(HttpServletRequest request) {
		String param = request.getParameter("quantity");
		if (param == null || param.isBlank()) {
			return 1;
		}
		try {
			int q = Integer.parseInt(param);
			return q < 1 ? 1 : q;
		} catch (NumberFormatException e) {
			return 1;
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/maintenance/" + view).forward(request, response);
	}
}
