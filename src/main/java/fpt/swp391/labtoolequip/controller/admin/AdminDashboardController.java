package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/admin/dashboard")
public class AdminDashboardController extends HttpServlet {
	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("pendingLabRequestCount", requestDAO.countByStatus("PENDING"));
		} catch (Exception exception) {
			getServletContext().log("Could not load pending Lab Usage Request count", exception);
			request.setAttribute("pendingLabRequestCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
	}
}
