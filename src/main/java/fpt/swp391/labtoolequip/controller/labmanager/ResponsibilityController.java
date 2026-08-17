package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/responsibilities/*")
public class ResponsibilityController extends HttpServlet {
	private final ResponsibilityDAO dao = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path == null || "/".equals(path)) {
				String keyword = request.getParameter("keyword");
				String status = request.getParameter("status");
				request.setAttribute("keyword", keyword);
				request.setAttribute("selectedStatus", status);
				request.setAttribute("responsibilities", dao.findAll(keyword, status));
				forward(request, response, "list.jsp");
				return;
			}
			if (path.matches("/\\d+")) {
				long id = Long.parseLong(path.substring(1));
				request.setAttribute("responsibility", dao.findById(id).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/responsibilities/" + view).forward(request, response);
	}
}
