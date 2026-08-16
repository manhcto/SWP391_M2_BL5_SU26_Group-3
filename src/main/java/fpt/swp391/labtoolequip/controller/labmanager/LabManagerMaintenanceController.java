package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.AssetDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

@WebServlet({"/labmanager/maintenance", "/labmanager/maintenance/view", "/labmanager/maintenance/add",
		"/labmanager/maintenance/approve", "/labmanager/maintenance/edit"})
public class LabManagerMaintenanceController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/labmanager/maintenance/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/labmanager/maintenance/detail.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/labmanager/maintenance/form.jsp";

	private final MaintenanceDAO maintenanceDAO = new MaintenanceDAO();
	private final AssetDAO assetDAO = new AssetDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (request.getServletPath()) {
				case "/labmanager/maintenance/view" -> showDetail(request, response);
				case "/labmanager/maintenance/add" -> showAddForm(request, response);
				case "/labmanager/maintenance/edit" -> showEditForm(request, response);
				default -> showList(request, response);
			}
		} catch (SQLException ex) {
			handleError(request, response, ex);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		try {
			switch (request.getServletPath()) {
				case "/labmanager/maintenance/add" -> createRecord(request, response);
				case "/labmanager/maintenance/approve" -> processApproval(request, response);
				case "/labmanager/maintenance/edit" -> updateProgress(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException ex) {
			handleError(request, response, ex);
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = request.getParameter("keyword");
		String status = request.getParameter("status");
		List<MaintenanceRecord> records = maintenanceDAO.findAll(keyword, status, null);
		request.setAttribute("records", records);
		request.setAttribute("keyword", keyword);
		request.setAttribute("selectedStatus", status);
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}

	private void showDetail(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long id = requireId(request, response);
		if (response.isCommitted())
			return;

		MaintenanceRecord record = maintenanceDAO.findById(id).orElse(null);
		if (record == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("record", record);
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showAddForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("assets", assetDAO.findAll());
		request.setAttribute("formMode", "add");
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void showEditForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long id = requireId(request, response);
		if (response.isCommitted())
			return;

		MaintenanceRecord record = maintenanceDAO.findById(id).orElse(null);
		if (record == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("record", record);
		request.setAttribute("formMode", "edit");
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void createRecord(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, IOException {
		long assetId = Long.parseLong(request.getParameter("assetId"));
		String description = request.getParameter("description");
		int quantity = Integer.parseInt(request.getParameter("quantity"));

		MaintenanceRecord m = new MaintenanceRecord();
		m.setAssetId(assetId);
		m.setDescription(description);
		m.setQuantity(quantity);
		m.setRequestedBy(3L); // Default Lab Manager user ID for now

		long createdId = maintenanceDAO.create(m);
		// Update asset status to MAINTENANCE
		assetDAO.updateStatus(assetId, "MAINTENANCE");

		response.sendRedirect(request.getContextPath() + "/labmanager/maintenance?success=created");
	}

	private void processApproval(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, IOException {
		long id = Long.parseLong(request.getParameter("id"));
		String decision = request.getParameter("decision"); // APPROVED or REJECTED
		String note = request.getParameter("approvalNote");

		maintenanceDAO.approveOrReject(id, decision, 3L, note);

		if ("APPROVED".equals(decision)) {
			// Find asset to set to MAINTENANCE status
			maintenanceDAO.findById(id).ifPresent(m -> {
				try {
					assetDAO.updateStatus(m.getAssetId(), "MAINTENANCE");
				} catch (SQLException ignored) {
				}
			});
		}

		response.sendRedirect(request.getContextPath() + "/labmanager/maintenance?success=approved");
	}

	private void updateProgress(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, IOException {
		long id = Long.parseLong(request.getParameter("id"));
		String status = request.getParameter("status"); // IN_PROGRESS or COMPLETED
		String repairResult = request.getParameter("repairResult");
		String note = request.getParameter("note");

		LocalDateTime startedAt = "IN_PROGRESS".equals(status) || "COMPLETED".equals(status)
				? LocalDateTime.now()
				: null;
		LocalDateTime completedAt = "COMPLETED".equals(status) ? LocalDateTime.now() : null;

		maintenanceDAO.updateProgress(id, status, startedAt, completedAt, repairResult, note);

		if ("COMPLETED".equals(status)) {
			// Asset is repaired and back in service
			maintenanceDAO.findById(id).ifPresent(m -> {
				try {
					assetDAO.updateStatus(m.getAssetId(), "AVAILABLE");
				} catch (SQLException ignored) {
				}
			});
		}

		response.sendRedirect(request.getContextPath() + "/labmanager/maintenance?success=updated");
	}

	private long requireId(HttpServletRequest request, HttpServletResponse response) throws IOException {
		try {
			return Long.parseLong(request.getParameter("id"));
		} catch (Exception e) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return -1;
		}
	}

	private void handleError(HttpServletRequest request, HttpServletResponse response, SQLException ex)
			throws ServletException, IOException {
		getServletContext().log("LabManagerMaintenanceController error", ex);
		request.setAttribute("errorMessage", "Database error: " + ex.getMessage());
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}
}
