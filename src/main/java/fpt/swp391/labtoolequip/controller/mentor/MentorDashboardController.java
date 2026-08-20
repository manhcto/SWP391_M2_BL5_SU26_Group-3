package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
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
	private final AssetUsageDAO assetUsageDAO = new AssetUsageDAO();
	private final IncidentDAO incidentDAO = new IncidentDAO();
	private final MaintenanceDAO maintenanceDAO = new MaintenanceDAO();
	private final InternListDAO internListDAO = new InternListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		long userId = AuthSession.userId(request);
		try {
			request.setAttribute("approvedInternLists", internListDAO.findApprovedSchedule(userId));
		} catch (SQLException exception) {
			getServletContext().log("Approved Mentor schedule is unavailable.", exception);
			request.setAttribute("approvedInternLists", java.util.List.of());
		}
		try {
			var requests = internListDAO.findByMentor(userId, "", "", null);
			request.setAttribute("pendingInternListCount",
					requests.stream().filter(item -> "PENDING".equals(item.getStatus())).count());
			request.setAttribute("mentorUsageCount", assetUsageDAO.countForMentor(userId));
			request.setAttribute("reportedIncidentCount", incidentDAO.countForMentor(userId));
			request.setAttribute("maintenanceRequestCount", maintenanceDAO.findAll("", "").stream()
					.filter(item -> Long.valueOf(userId).equals(item.getRequestedBy())).count());
		} catch (SQLException exception) {
			getServletContext().log("Mentor dashboard summary is unavailable.", exception);
			request.setAttribute("pendingInternListCount", 0);
			request.setAttribute("mentorUsageCount", 0);
			request.setAttribute("reportedIncidentCount", 0);
			request.setAttribute("maintenanceRequestCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/mentor/dashboard.jsp").forward(request, response);
	}
}
