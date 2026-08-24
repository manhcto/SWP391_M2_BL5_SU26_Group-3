package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.AssetDAO;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.DisposalRecordDAO;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import fpt.swp391.labtoolequip.dao.InspectionDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;

@WebServlet("/lab-manager/dashboard")
public class LabManagerDashboardController extends HttpServlet {
	private final AssetDAO assetDAO = new AssetDAO();
	private final AssetUsageDAO assetUsageDAO = new AssetUsageDAO();
	private final InspectionDAO inspectionDAO = new InspectionDAO();
	private final IncidentDAO incidentDAO = new IncidentDAO();
	private final MaintenanceDAO maintenanceDAO = new MaintenanceDAO();
	private final DisposalRecordDAO disposalDAO = new DisposalRecordDAO();
	private final ResponsibilityDAO responsibilityDAO = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			var now = LocalDateTime.now();
			var assets = assetDAO.findAll();
			var usages = assetUsageDAO.findAll("", "");
			var inspections = inspectionDAO.findAll(null, "", "", "", "", "");
			var incidents = incidentDAO.findForLabManager("", "", "");
			var maintenance = maintenanceDAO.findAll("", "");
			var disposals = disposalDAO.findAll("", "");
			var responsibilities = responsibilityDAO.findAll("", "");
			long managedAssetCount = assets.stream().filter(item -> !"DISPOSED".equals(item.getStatus())).count();
			long availableAssetCount = assets.stream().filter(item -> "AVAILABLE".equals(item.getStatus())).count();
			long maintenanceAssetCount = assets.stream().filter(item -> "MAINTENANCE".equals(item.getStatus())).count();
			long unavailableAssetCount = assets.stream().filter(item -> "UNAVAILABLE".equals(item.getStatus())).count();
			long disposedAssetCount = assets.stream().filter(item -> "DISPOSED".equals(item.getStatus())).count();
			long overdueUsageCount = usages.stream().filter(item -> "IN_USE".equals(item.getStatus())
					&& item.getDueAt() != null && item.getDueAt().isBefore(now)).count();
			long openIncidentCount = incidents.stream()
					.filter(item -> "OPEN".equals(item.getStatus()) || "INVESTIGATING".equals(item.getStatus()))
					.count();
			long criticalIncidentCount = incidents.stream().filter(item -> "CRITICAL".equals(item.getSeverity())
					&& ("OPEN".equals(item.getStatus()) || "INVESTIGATING".equals(item.getStatus()))).count();
			long pendingResponsibilityCount = responsibilities.stream()
					.filter(item -> "PENDING_REVIEW".equals(item.getStatus())).count();
			request.setAttribute("assetCount", managedAssetCount);
			request.setAttribute("availableAssetCount", availableAssetCount);
			request.setAttribute("maintenanceAssetCount", maintenanceAssetCount);
			request.setAttribute("unavailableAssetCount", unavailableAssetCount);
			request.setAttribute("disposedAssetCount", disposedAssetCount);
			request.setAttribute("availableAssetPercent", percent(availableAssetCount, managedAssetCount));
			request.setAttribute("activeUsageCount",
					usages.stream().filter(item -> "IN_USE".equals(item.getStatus())).count());
			request.setAttribute("inspectionCount", inspections.size());
			request.setAttribute("incidentCount", incidents.size());
			request.setAttribute("openIncidentCount", openIncidentCount);
			request.setAttribute("criticalIncidentCount", criticalIncidentCount);
			request.setAttribute("overdueUsageCount", overdueUsageCount);
			request.setAttribute("recentIncidents", incidents);
			request.setAttribute("openMaintenanceCount",
					maintenance.stream().filter(
							item -> !"COMPLETED".equals(item.getStatus()) && !"REJECTED".equals(item.getStatus()))
							.count());
			request.setAttribute("pendingDisposalCount",
					disposals.stream().filter(item -> "PENDING".equals(item.getStatus())).count());
			request.setAttribute("responsibilityCount", responsibilities.size());
			request.setAttribute("pendingResponsibilityCount", pendingResponsibilityCount);
		} catch (Exception exception) {
			getServletContext().log("Could not load Lab Manager dashboard data", exception);
			request.setAttribute("assetCount", 0);
			request.setAttribute("availableAssetCount", 0);
			request.setAttribute("maintenanceAssetCount", 0);
			request.setAttribute("unavailableAssetCount", 0);
			request.setAttribute("disposedAssetCount", 0);
			request.setAttribute("availableAssetPercent", 0);
			request.setAttribute("activeUsageCount", 0);
			request.setAttribute("inspectionCount", 0);
			request.setAttribute("incidentCount", 0);
			request.setAttribute("openIncidentCount", 0);
			request.setAttribute("criticalIncidentCount", 0);
			request.setAttribute("overdueUsageCount", 0);
			request.setAttribute("recentIncidents", java.util.List.of());
			request.setAttribute("openMaintenanceCount", 0);
			request.setAttribute("pendingDisposalCount", 0);
			request.setAttribute("responsibilityCount", 0);
			request.setAttribute("pendingResponsibilityCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/labmanager/dashboard.jsp").forward(request, response);
	}

	private static long percent(long value, long total) {
		return total == 0 ? 0 : Math.round(value * 100.0 / total);
	}
}
