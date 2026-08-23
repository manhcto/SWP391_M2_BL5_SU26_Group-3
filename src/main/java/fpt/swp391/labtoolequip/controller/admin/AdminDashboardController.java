package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.InternListDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.dao.PasswordResetRequestDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/admin/dashboard")
public class AdminDashboardController extends HttpServlet {
	private final InternListDAO internListDAO = new InternListDAO();
	private final UserDAO userDAO = new UserDAO();
	private final PasswordResetRequestDAO passwordResetDAO = new PasswordResetRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("pendingPasswordResetCount", passwordResetDAO.countPending());
		} catch (Exception exception) {
			getServletContext().log("Could not load pending password reset count", exception);
			request.setAttribute("pendingPasswordResetCount", 0);
		}
		try {
			var users = userDAO.findAll("", "", "");
			request.setAttribute("accountCount", users.size());
			request.setAttribute("activeAccountCount",
					users.stream().filter(user -> "ACTIVE".equals(user.getStatus())).count());
			request.setAttribute("inactiveAccountCount",
					users.stream().filter(user -> "INACTIVE".equals(user.getStatus())).count());
			request.setAttribute("internCount", users.stream().filter(user -> "INTERN".equals(user.getRole())).count());
			request.setAttribute("mentorCount", users.stream().filter(user -> "MENTOR".equals(user.getRole())).count());
			request.setAttribute("labManagerCount",
					users.stream().filter(user -> "LAB_MANAGER".equals(user.getRole())).count());
		} catch (Exception exception) {
			getServletContext().log("Could not load admin user counts", exception);
			request.setAttribute("accountCount", 0);
			request.setAttribute("activeAccountCount", 0);
			request.setAttribute("inactiveAccountCount", 0);
			request.setAttribute("internCount", 0);
			request.setAttribute("mentorCount", 0);
			request.setAttribute("labManagerCount", 0);
		}
		try {
			var pendingInternLists = internListDAO.findAll("", "PENDING", null);
			request.setAttribute("pendingInternListCount", pendingInternLists.size());
			request.setAttribute("pendingInternLists", pendingInternLists);
		} catch (Exception exception) {
			getServletContext().log("Could not load pending Intern List count", exception);
			request.setAttribute("pendingInternListCount", 0);
			request.setAttribute("pendingInternLists", java.util.List.of());
		}
		request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
	}
}
