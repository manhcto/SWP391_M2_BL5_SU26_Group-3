package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.InternListDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
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
			request.setAttribute("mentorCount", users.stream().filter(user -> "MENTOR".equals(user.getRole())).count());
			request.setAttribute("labManagerCount",
					users.stream().filter(user -> "LAB_MANAGER".equals(user.getRole())).count());
			request.setAttribute("activeAccountPercent",
					percent(users.stream().filter(user -> "ACTIVE".equals(user.getStatus())).count(), users.size()));
			request.setAttribute("internPercent",
					percent(users.stream().filter(user -> "INTERN".equals(user.getRole())).count(), users.size()));
			request.setAttribute("mentorPercent",
					percent(users.stream().filter(user -> "MENTOR".equals(user.getRole())).count(), users.size()));
			request.setAttribute("labManagerPercent",
					percent(users.stream().filter(user -> "LAB_MANAGER".equals(user.getRole())).count(), users.size()));
		} catch (Exception exception) {
			getServletContext().log("Could not load admin user counts", exception);
			request.setAttribute("accountCount", 0);
			request.setAttribute("activeAccountCount", 0);
			request.setAttribute("inactiveAccountCount", 0);
			request.setAttribute("internCount", 0);
			request.setAttribute("mentorCount", 0);
			request.setAttribute("labManagerCount", 0);
			request.setAttribute("activeAccountPercent", 0);
			request.setAttribute("internPercent", 0);
			request.setAttribute("mentorPercent", 0);
			request.setAttribute("labManagerPercent", 0);
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

	private static long percent(long value, long total) {
		return total == 0 ? 0 : Math.round(value * 100.0 / total);
	}
}
