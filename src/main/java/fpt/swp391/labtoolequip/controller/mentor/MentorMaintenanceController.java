package fpt.swp391.labtoolequip.controller.mentor;

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
import java.util.List;

@WebServlet({"/mentor/maintenance", "/mentor/maintenance/view", "/mentor/maintenance/add"})
public class MentorMaintenanceController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/mentor/maintenance/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/mentor/maintenance/detail.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/mentor/maintenance/form.jsp";

	private final MaintenanceDAO maintenanceDAO = new MaintenanceDAO();
	private final AssetDAO assetDAO = new AssetDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (request.getServletPath()) {
				case "/mentor/maintenance/view" -> showDetail(request, response);
				case "/mentor/maintenance/add" -> showAddForm(request, response);
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
			if ("/mentor/maintenance/add".equals(request.getServletPath())) {
				createProposal(request, response);
			} else {
				response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException ex) {
			handleError(request, response, ex);
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = request.getParameter("keyword");
		String status = request.getParameter("status");
		long mentorId = 2L; // Default Mentor user ID for demo/mentor session
		List<MaintenanceRecord> records = maintenanceDAO.findByRequester(mentorId, keyword, status);
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
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void createProposal(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, IOException {
		long assetId = Long.parseLong(request.getParameter("assetId"));
		String description = request.getParameter("description");
		int quantity = Integer.parseInt(request.getParameter("quantity"));

		MaintenanceRecord m = new MaintenanceRecord();
		m.setAssetId(assetId);
		m.setDescription(description);
		m.setQuantity(quantity);
		m.setRequestedBy(2L); // Mentor user ID

		maintenanceDAO.create(m);
		response.sendRedirect(request.getContextPath() + "/mentor/maintenance?success=submitted");
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
		getServletContext().log("MentorMaintenanceController error", ex);
		request.setAttribute("errorMessage", "Database error: " + ex.getMessage());
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}
}
