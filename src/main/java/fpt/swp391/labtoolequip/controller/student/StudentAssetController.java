package fpt.swp391.labtoolequip.controller.student;

import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import fpt.swp391.labtoolequip.model.AssetItem;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/intern/assets/*")
public class StudentAssetController extends HttpServlet {
	private final AssetItemDAO dao = new AssetItemDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setAttribute("activeMenu", "assets");
		request.setAttribute("assetBasePath", request.getContextPath() + "/intern/assets");
		try {
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				AssetItem item = dao.findBorrowableById(Long.parseLong(path.substring(1))).orElse(null);
				if (item == null) {
					response.sendError(HttpServletResponse.SC_NOT_FOUND);
					return;
				}
				request.setAttribute("item", item);
				forward(request, response, "detail.jsp");
				return;
			}
			if (path != null && !path.equals("/") && !path.isBlank()) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			request.setAttribute("assetItems", dao.findBorrowable(request.getParameter("keyword")));
			forward(request, response, "list.jsp");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws IOException {
		response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/student/assets/" + view).forward(request, response);
	}
}
