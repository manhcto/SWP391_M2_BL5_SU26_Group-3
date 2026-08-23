package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
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
		if (!Authorization.has(request, Permission.MAINTENANCE_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if ("/new".equals(path)) {
				response.sendError(HttpServletResponse.SC_FORBIDDEN,
						"Mentor tạo yêu cầu bảo trì; Lab Manager chỉ xử lý yêu cầu đã gửi.");
				return;
			}
			if (path != null && path.matches("/\\d+/edit")) {
				if (!Authorization.has(request, Permission.MAINTENANCE_PROCESS)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showProcessForm(request, response, Long.parseLong(path.substring(1, path.lastIndexOf('/'))));
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
		if (!Csrf.valid(request) || !Authorization.has(request, Permission.MAINTENANCE_PROCESS)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		if (!"approve".equals(action) && !"reject".equals(action) && !"start".equals(action)
				&& !"complete".equals(action)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		long id;
		try {
			id = requiredId(request, "id");
		} catch (IllegalArgumentException exception) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, exception.getMessage());
			return;
		}
		try {
			long managerId = AuthSession.userId(request);
			switch (action) {
				case "approve" -> dao.approve(id, managerId, request.getParameter("approvalNote"));
				case "reject" -> dao.reject(id, managerId, request.getParameter("approvalNote"));
				case "start" -> dao.start(id, managerId, request.getParameter("note"));
				case "complete" -> dao.complete(id, managerId, request.getParameter("repairOutcome"),
						request.getParameter("repairResult"), request.getParameter("note"));
				default -> throw new IllegalStateException("Thao tác bảo trì không hợp lệ.");
			}
			response.sendRedirect(request.getContextPath() + "/lab-manager/maintenance/" + id + "?success=" + action);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				showProcessForm(request, response, id);
			} catch (SQLException sqlException) {
				throw new ServletException(sqlException);
			}
		}
	}

	private void showDetail(HttpServletRequest request, HttpServletResponse response, long id)
			throws SQLException, ServletException, IOException {
		MaintenanceRecord record = dao.findById(id).orElse(null);
		if (record == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("record", record);
		forward(request, response, "detail.jsp");
	}

	private void showProcessForm(HttpServletRequest request, HttpServletResponse response, long id)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		MaintenanceRecord record = dao.findById(id).orElse(null);
		if (record == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("record", record);
		forward(request, response, "form.jsp");
	}

	private long requiredId(HttpServletRequest request, String name) {
		try {
			long id = Long.parseLong(request.getParameter(name));
			if (id <= 0) {
				throw new NumberFormatException();
			}
			return id;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Mã phiếu bảo trì không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/maintenance/" + view).forward(request, response);
	}
}
