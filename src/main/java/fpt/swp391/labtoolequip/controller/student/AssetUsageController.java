package fpt.swp391.labtoolequip.controller.student;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet({"/intern/usages/*", "/student/usages/*"})
public class AssetUsageController extends HttpServlet {
	private final AssetUsageDAO dao = new AssetUsageDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if ("/borrow".equals(path)) {
				request.setAttribute("assets", dao.findBorrowableAssets());
				forward(request, response, "borrow.jsp");
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				long id = Long.parseLong(path.substring(1));
				request.setAttribute("usage", dao.findById(id, AuthSession.userId(request)).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			request.setAttribute("usages", dao.findForStudent(AuthSession.userId(request)));
			forward(request, response, "list.jsp");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			if ("borrow".equals(request.getParameter("action"))) {
				dao.borrow(AuthSession.userId(request), Long.parseLong(request.getParameter("assetId")),
						Integer.parseInt(request.getParameter("quantity")), request.getParameter("note"));
			} else if ("return".equals(request.getParameter("action"))) {
				dao.returnUsage(AuthSession.userId(request), Long.parseLong(request.getParameter("usageId")),
						request.getParameter("conditionAfter"), request.getParameter("note"));
			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			String basePath = request.getServletPath().startsWith("/intern/") ? "/intern/usages" : "/student/usages";
			response.sendRedirect(request.getContextPath() + basePath);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/student/usages/" + view).forward(request, response);
	}
}
