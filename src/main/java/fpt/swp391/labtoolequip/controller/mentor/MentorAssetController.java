package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/assets")
public class MentorAssetController extends HttpServlet {
	private final AssetItemDAO dao = new AssetItemDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("assetItems", dao.findAll(request.getParameter("keyword"), "AVAILABLE", ""));
			request.getRequestDispatcher("/WEB-INF/views/mentor/assets/list.jsp").forward(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
		response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
	}
}
