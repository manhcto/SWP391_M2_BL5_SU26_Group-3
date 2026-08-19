package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.InternListDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/dashboard")
public class MentorDashboardController extends HttpServlet {
	private final InternListDAO internListDAO = new InternListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("approvedInternLists",
					internListDAO.findApprovedSchedule(AuthSession.userId(request)));
		} catch (SQLException exception) {
			getServletContext().log("Approved Mentor schedule is unavailable.", exception);
			request.setAttribute("approvedInternLists", java.util.List.of());
		}
		request.getRequestDispatcher("/WEB-INF/views/mentor/dashboard.jsp").forward(request, response);
	}
}
