package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.IncidentDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/incidents")
public class IncidentController extends HttpServlet {
	private final IncidentDAO dao = new IncidentDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String keyword = request.getParameter("keyword");
			String status = request.getParameter("status");
			String severity = request.getParameter("severity");
			request.setAttribute("keyword", keyword);
			request.setAttribute("selectedStatus", status);
			request.setAttribute("selectedSeverity", severity);
			request.setAttribute("incidents", dao.findAll(keyword, status, severity));
			request.getRequestDispatcher("/WEB-INF/views/labmanager/incidents/list.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}
}
