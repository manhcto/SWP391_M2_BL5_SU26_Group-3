package fpt.swp391.labtoolequip.controller.student;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

@WebServlet("/intern/dashboard")
public class StudentDashboardController extends HttpServlet {
	private final AssetUsageDAO assetUsageDAO = new AssetUsageDAO();
	private final IncidentDAO incidentDAO = new IncidentDAO();
	private final ResponsibilityDAO responsibilityDAO = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		long userId = AuthSession.userId(request);
		try {
			var usages = assetUsageDAO.findForStudent(userId);
			request.setAttribute("usages", usages);
			request.setAttribute("activeUsageCount",
					usages.stream().filter(usage -> "IN_USE".equals(usage.getStatus())).count());
			request.setAttribute("returnedUsageCount",
					usages.stream().filter(usage -> "RETURNED".equals(usage.getStatus())).count());
			request.setAttribute("totalUsageCount", usages.size());
		} catch (Exception exception) {
			getServletContext().log("Could not load Intern asset usage dashboard data", exception);
			request.setAttribute("usages", List.of());
			request.setAttribute("activeUsageCount", 0);
			request.setAttribute("returnedUsageCount", 0);
			request.setAttribute("totalUsageCount", 0);
		}
		try {
			var responsibilities = responsibilityDAO.findForIntern(userId, "", "");
			request.setAttribute("responsibilityCount", responsibilities.size());
		} catch (Exception exception) {
			getServletContext().log("Could not load Intern responsibility dashboard data", exception);
			request.setAttribute("responsibilityCount", 0);
		}
		try {
			request.setAttribute("reportedIncidentCount", incidentDAO.countForReporter(userId));
		} catch (Exception exception) {
			getServletContext().log("Could not load Intern incident dashboard data", exception);
			request.setAttribute("reportedIncidentCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/student/dashboard.jsp").forward(request, response);
	}
}
