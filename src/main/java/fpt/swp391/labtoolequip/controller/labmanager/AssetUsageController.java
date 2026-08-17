package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/usages/*")
public class AssetUsageController extends HttpServlet {
	private final AssetUsageDAO dao = new AssetUsageDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("usage", dao.findById(Long.parseLong(path.substring(1)), null).orElseThrow());
				request.getRequestDispatcher("/WEB-INF/views/labmanager/usages/detail.jsp").forward(request, response);
				return;
			}
			request.setAttribute("usages",
					dao.findAll(request.getParameter("keyword"), request.getParameter("status")));
			request.getRequestDispatcher("/WEB-INF/views/labmanager/usages/list.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}
}
