package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/usages/*")
public class AssetUsageController extends HttpServlet {
	private final AssetUsageDAO dao = new AssetUsageDAO();
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("usage",
						dao.findByIdForMentor(Long.parseLong(path.substring(1)), AuthSession.userId(request))
								.orElseThrow());
				request.getRequestDispatcher("/WEB-INF/views/mentor/usages/detail.jsp").forward(request, response);
				return;
			}
			request.setAttribute("usages",
					dao.findForMentor(AuthSession.userId(request), request.getParameter("keyword"),
							request.getParameter("status"), request.getParameter("fromDate"),
							request.getParameter("toDate")));
			request.getRequestDispatcher("/WEB-INF/views/mentor/usages/list.jsp").forward(request, response);
		} catch (SQLException e) {
			throw new ServletException(e);
		} catch (RuntimeException e) {
			response.sendError(404);
		}
	}
}
