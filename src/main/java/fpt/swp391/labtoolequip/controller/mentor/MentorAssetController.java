package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/assets/*")
public class MentorAssetController extends HttpServlet {
	private final AssetItemDAO dao = new AssetItemDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("assetBasePath", request.getContextPath() + "/mentor/assets");
			String path = request.getPathInfo();
			if (path != null && path.matches("/\\d+")) {
				var item = dao.findById(Long.parseLong(path.substring(1))).orElse(null);
				if (item == null || !"AVAILABLE".equals(item.getStatus())) {
					response.sendError(HttpServletResponse.SC_NOT_FOUND);
					return;
				}
				request.setAttribute("item", item);
				request.getRequestDispatcher("/WEB-INF/views/mentor/assets/detail.jsp").forward(request, response);
				return;
			}
			if (path != null && !path.equals("/") && !path.isBlank()) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			var assetItems = dao.findAll(request.getParameter("keyword"), "AVAILABLE", "", request.getParameter("category"));
			request.setAttribute("assetItems", assetItems);
			request.setAttribute("borrowableAssetCount",
					assetItems.stream().filter(item -> Boolean.TRUE.equals(item.getBorrowable())).count());
			request.setAttribute("fixedAssetCount",
					assetItems.stream().filter(item -> !Boolean.TRUE.equals(item.getBorrowable())).count());
			request.setAttribute("categories", dao.findCategories());
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
