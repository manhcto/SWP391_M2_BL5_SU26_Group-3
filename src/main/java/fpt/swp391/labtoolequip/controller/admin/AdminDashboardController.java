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
			request.setAttribute("internCount", userDAO.findAll("", "INTERN", "").size());
			request.setAttribute("mentorCount", userDAO.findAll("", "MENTOR", "").size());
			request.setAttribute("labManagerCount", userDAO.findAll("", "LAB_MANAGER", "").size());
		} catch (Exception exception) {
			getServletContext().log("Could not load admin user counts", exception);
			request.setAttribute("internCount", 0);
			request.setAttribute("mentorCount", 0);
			request.setAttribute("labManagerCount", 0);
		}
		try {
			request.setAttribute("pendingInternListCount", internListDAO.countByStatus("PENDING"));
		} catch (Exception exception) {
			getServletContext().log("Could not load pending Intern List count", exception);
			request.setAttribute("pendingInternListCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
	}
}
