package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/admin/dashboard")
public class AdminDashboardController extends HttpServlet {
	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();
	private final UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			var users = userDAO.findAll("", "", "");
			request.setAttribute("accountCount", users.size());
			request.setAttribute("activeAccountCount",
					users.stream().filter(user -> "ACTIVE".equals(user.getStatus())).count());
			request.setAttribute("inactiveAccountCount",
					users.stream().filter(user -> "INACTIVE".equals(user.getStatus())).count());
			request.setAttribute("internCount", users.stream().filter(user -> "INTERN".equals(user.getRole())).count());
		} catch (Exception exception) {
			getServletContext().log("Could not load admin user counts", exception);
			request.setAttribute("accountCount", 0);
			request.setAttribute("activeAccountCount", 0);
			request.setAttribute("inactiveAccountCount", 0);
			request.setAttribute("internCount", 0);
		}
		try {
			var pendingRequests = requestDAO.findAll("", "PENDING", null);
			request.setAttribute("pendingLabRequestCount", pendingRequests.size());
			request.setAttribute("pendingLabRequests", pendingRequests);
		} catch (Exception exception) {
			getServletContext().log("Could not load pending Lab Usage Request count", exception);
			request.setAttribute("pendingLabRequestCount", 0);
			request.setAttribute("pendingLabRequests", java.util.List.of());
		}
		request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
	}
}
