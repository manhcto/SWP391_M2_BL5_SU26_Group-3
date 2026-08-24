package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.EquipmentAllocationDAO;
import fpt.swp391.labtoolequip.model.EquipmentAllocationRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;

@WebServlet("/lab-manager/allocations/*")
public class EquipmentAllocationController extends HttpServlet {
	private final EquipmentAllocationDAO dao = new EquipmentAllocationDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				EquipmentAllocationRequest allocationRequest = dao.findRequest(Long.parseLong(path.substring(1)));
				if (allocationRequest == null) {
					response.sendError(HttpServletResponse.SC_NOT_FOUND);
					return;
				}
				request.setAttribute("allocationRequest", allocationRequest);
				request.setAttribute("availableItems", dao.findAvailableItems(allocationRequest.getAssetId()));
				request.setAttribute("csrfToken", Csrf.token(request));
				request.getRequestDispatcher("/WEB-INF/views/labmanager/allocations/detail.jsp").forward(request,
						response);
				return;
			}
			request.setAttribute("allocationRequests", dao.findRequestsForManager());
			request.setAttribute("allocations", dao.findAllocationsForManager());
			request.setAttribute("csrfToken", Csrf.token(request));
			request.getRequestDispatcher("/WEB-INF/views/labmanager/allocations/list.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String redirect = request.getContextPath() + "/lab-manager/allocations";
		try {
			if ("approve".equals(request.getParameter("action"))) {
				long requestId = id(request, "requestId");
				dao.approveRequest(requestId, AuthSession.userId(request), request.getParameterValues("assetItemId"),
						request.getParameter("reviewNote"));
				redirect += "/" + requestId;
			} else if ("recover".equals(request.getParameter("action"))) {
				dao.recoverAllocation(id(request, "allocationId"), AuthSession.userId(request),
						request.getParameter("returnCondition"), request.getParameter("returnNote"));
			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			response.sendRedirect(redirect + "?success=1");
		} catch (IllegalArgumentException | SQLException exception) {
			response.sendRedirect(
					redirect + "?error=" + URLEncoder.encode(exception.getMessage(), StandardCharsets.UTF_8));
		}
	}

	private long id(HttpServletRequest request, String name) {
		try {
			long value = Long.parseLong(request.getParameter(name));
			if (value > 0)
				return value;
		} catch (NumberFormatException ignored) {
		}
		throw new IllegalArgumentException("Dữ liệu gửi lên không hợp lệ.");
	}
}
