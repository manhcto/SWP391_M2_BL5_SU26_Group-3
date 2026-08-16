package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/dashboard")
public class MentorDashboardController extends HttpServlet {
	private final LabUsageRequestDAO labUsageRequestDAO = new LabUsageRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		User mentor = (User) request.getSession().getAttribute("currentUser");
		try {
			request.setAttribute("approvedRequests",
					labUsageRequestDAO.findApprovedScheduleByMentor(mentor.getUserId()));
			request.getRequestDispatcher("/WEB-INF/views/mentor/dashboard.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException("Không thể tải lịch Lab đã được duyệt.", exception);
		}
	}
}
