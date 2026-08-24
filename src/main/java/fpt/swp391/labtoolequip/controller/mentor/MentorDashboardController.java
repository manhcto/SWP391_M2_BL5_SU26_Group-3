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
import java.time.LocalDateTime;

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
			var now = LocalDateTime.now();
			var requests = internListDAO.findByMentor(userId, "", "", null);
			var usages = assetUsageDAO.findForMentor(userId, "", "");
			var incidents = incidentDAO.findForMentor(userId, "", "", "");
			long returnedUsageCount = usages.stream().filter(item -> "RETURNED".equals(item.getStatus())).count();
			long returnedOnTimeCount = usages.stream()
					.filter(item -> "RETURNED".equals(item.getStatus()) && item.getReturnedAt() != null
							&& item.getDueAt() != null && !item.getReturnedAt().isAfter(item.getDueAt()))
					.count();
			request.setAttribute("pendingInternListCount",
					requests.stream().filter(item -> "PENDING".equals(item.getStatus())).count());
			request.setAttribute("mentorUsageCount", usages.size());
			request.setAttribute("activeUsageCount",
					usages.stream().filter(item -> "IN_USE".equals(item.getStatus())).count());
			request.setAttribute("overdueUsageCount", usages.stream().filter(item -> "IN_USE".equals(item.getStatus())
					&& item.getDueAt() != null && item.getDueAt().isBefore(now)).count());
			request.setAttribute("returnedUsageCount", returnedUsageCount);
			request.setAttribute("damagedReturnCount", usages.stream().filter(item -> "RETURNED"
					.equals(item.getStatus())
					&& ("DAMAGED".equals(item.getConditionAfter()) || "BROKEN".equals(item.getConditionAfter())))
					.count());
			request.setAttribute("returnedOnTimePercent", percent(returnedOnTimeCount, returnedUsageCount));
			request.setAttribute("reportedIncidentCount", incidents.size());
			request.setAttribute("openIncidentCount",
					incidents.stream()
							.filter(item -> "OPEN".equals(item.getStatus()) || "INVESTIGATING".equals(item.getStatus()))
							.count());
			request.setAttribute("maintenanceRequestCount", maintenanceDAO.findAll("", "").stream()
					.filter(item -> Long.valueOf(userId).equals(item.getRequestedBy())).count());
		} catch (SQLException exception) {
			getServletContext().log("Mentor dashboard summary is unavailable.", exception);
			request.setAttribute("pendingInternListCount", 0);
			request.setAttribute("mentorUsageCount", 0);
			request.setAttribute("activeUsageCount", 0);
			request.setAttribute("overdueUsageCount", 0);
			request.setAttribute("returnedUsageCount", 0);
			request.setAttribute("damagedReturnCount", 0);
			request.setAttribute("returnedOnTimePercent", 0);
			request.setAttribute("reportedIncidentCount", 0);
			request.setAttribute("openIncidentCount", 0);
			request.setAttribute("maintenanceRequestCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/mentor/dashboard.jsp").forward(request, response);
	}

	private static long percent(long value, long total) {
		return total == 0 ? 0 : Math.round(value * 100.0 / total);
	}
}
