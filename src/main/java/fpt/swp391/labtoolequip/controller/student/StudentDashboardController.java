package fpt.swp391.labtoolequip.controller.student;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.AssetDAO;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@WebServlet("/intern/dashboard")
public class StudentDashboardController extends HttpServlet {
	private final AssetUsageDAO assetUsageDAO = new AssetUsageDAO();
	private final AssetDAO assetDAO = new AssetDAO();
	private final ResponsibilityDAO responsibilityDAO = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		long userId = AuthSession.userId(request);
		try {
			var now = LocalDateTime.now();
			var usages = assetUsageDAO.findForStudent(userId);
			long returnedUsageCount = usages.stream().filter(usage -> "RETURNED".equals(usage.getStatus())).count();
			long returnedOnTimeCount = usages.stream()
					.filter(usage -> "RETURNED".equals(usage.getStatus()) && usage.getReturnedAt() != null
							&& usage.getDueAt() != null && !usage.getReturnedAt().isAfter(usage.getDueAt()))
					.count();
			request.setAttribute("usages", usages);
			request.setAttribute("activeUsageCount",
					usages.stream().filter(usage -> "IN_USE".equals(usage.getStatus())).count());
			request.setAttribute("returnedUsageCount", returnedUsageCount);
			request.setAttribute("overdueUsageCount", usages.stream().filter(usage -> "IN_USE".equals(usage.getStatus())
					&& usage.getDueAt() != null && usage.getDueAt().isBefore(now)).count());
			request.setAttribute("dueSoonUsageCount",
					usages.stream()
							.filter(usage -> "IN_USE".equals(usage.getStatus()) && usage.getDueAt() != null
									&& !usage.getDueAt().isBefore(now) && !usage.getDueAt().isAfter(now.plusDays(3)))
							.count());
			request.setAttribute("returnedOnTimePercent", percent(returnedOnTimeCount, returnedUsageCount));
		} catch (Exception exception) {
			getServletContext().log("Could not load Intern asset usage dashboard data", exception);
			request.setAttribute("usages", List.of());
			request.setAttribute("activeUsageCount", 0);
			request.setAttribute("returnedUsageCount", 0);
			request.setAttribute("overdueUsageCount", 0);
			request.setAttribute("dueSoonUsageCount", 0);
			request.setAttribute("returnedOnTimePercent", 0);
		}
		try {
			var responsibilities = responsibilityDAO.findForIntern(userId, "", "");
			request.setAttribute("responsibilityCount", responsibilities.size());
		} catch (Exception exception) {
			getServletContext().log("Could not load Intern responsibility dashboard data", exception);
			request.setAttribute("responsibilityCount", 0);
		}
		try {
			var thirtyDaysAgo = LocalDateTime.now().minusDays(30);
			request.setAttribute(
					"newAvailableAssetCount", assetDAO
							.findAll().stream().filter(asset -> "AVAILABLE".equals(asset.getStatus())
									&& asset.getCreatedAt() != null && !asset.getCreatedAt().isBefore(thirtyDaysAgo))
							.count());
		} catch (Exception exception) {
			getServletContext().log("Could not load newly available assets", exception);
			request.setAttribute("newAvailableAssetCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/student/dashboard.jsp").forward(request, response);
	}

	private static long percent(long value, long total) {
		return total == 0 ? 0 : Math.round(value * 100.0 / total);
	}
}
