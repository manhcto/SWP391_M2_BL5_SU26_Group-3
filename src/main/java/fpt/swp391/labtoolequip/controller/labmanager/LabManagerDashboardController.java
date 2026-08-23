package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.AssetDAO;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import fpt.swp391.labtoolequip.dao.DisposalRecordDAO;
import fpt.swp391.labtoolequip.dao.IncidentDAO;
import fpt.swp391.labtoolequip.dao.InspectionDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/lab-manager/dashboard")
public class LabManagerDashboardController extends HttpServlet {
	private final AssetDAO assetDAO = new AssetDAO();
	private final AssetUsageDAO assetUsageDAO = new AssetUsageDAO();
	private final InspectionDAO inspectionDAO = new InspectionDAO();
	private final IncidentDAO incidentDAO = new IncidentDAO();
	private final MaintenanceDAO maintenanceDAO = new MaintenanceDAO();
	private final DisposalRecordDAO disposalDAO = new DisposalRecordDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			var assets = assetDAO.findAll();
			var usages = assetUsageDAO.findAll("", "");
			var inspections = inspectionDAO.findAll(null, "", "", "", "", "");
			var incidents = incidentDAO.findForLabManager("", "", "");
			var maintenance = maintenanceDAO.findAll("", "");
			var disposals = disposalDAO.findAll("", "");
			request.setAttribute("assetCount", assets.size());
			request.setAttribute("availableAssetCount",
					assets.stream().filter(item -> "AVAILABLE".equals(item.getStatus())).count());
			request.setAttribute("maintenanceAssetCount",
					maintenance.stream().filter(item -> "IN_PROGRESS".equals(item.getStatus())).count());
			request.setAttribute("activeUsageCount",
					usages.stream().filter(item -> "IN_USE".equals(item.getStatus())).count());
			request.setAttribute("inspectionCount", inspections.size());
			request.setAttribute("incidentCount", incidents.size());
			request.setAttribute("recentIncidents", incidents);
			request.setAttribute("openMaintenanceCount",
					maintenance.stream().filter(
							item -> !"COMPLETED".equals(item.getStatus()) && !"REJECTED".equals(item.getStatus()))
							.count());
			request.setAttribute("pendingDisposalCount",
					disposals.stream().filter(item -> "PENDING".equals(item.getStatus())).count());
		} catch (Exception exception) {
			getServletContext().log("Could not load Lab Manager dashboard data", exception);
			request.setAttribute("assetCount", 0);
			request.setAttribute("availableAssetCount", 0);
			request.setAttribute("maintenanceAssetCount", 0);
			request.setAttribute("activeUsageCount", 0);
			request.setAttribute("inspectionCount", 0);
			request.setAttribute("incidentCount", 0);
			request.setAttribute("recentIncidents", java.util.List.of());
			request.setAttribute("openMaintenanceCount", 0);
			request.setAttribute("pendingDisposalCount", 0);
		}
		request.getRequestDispatcher("/WEB-INF/views/labmanager/dashboard.jsp").forward(request, response);
	}
}
