package fpt.swp391.labtoolequip.controller.intern;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/intern/usages/*")
public class AssetUsageController extends HttpServlet {
	private final AssetUsageDAO dao = new AssetUsageDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if ("/borrow".equals(path)) {
				showBorrow(request, response);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				long id = Long.parseLong(path.substring(1));
				request.setAttribute("usage", dao.findById(id, AuthSession.userId(request)).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			request.setAttribute("usages",
					dao.findForIntern(AuthSession.userId(request), request.getParameter("keyword"),
							request.getParameter("status"), request.getParameter("fromDate"),
							request.getParameter("toDate")));
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
		request.setCharacterEncoding("UTF-8");
		if (!Csrf.valid(request)) {
			response.sendError(403);
			return;
		}
		try {
			String action = request.getParameter("action");
			if ("borrow".equals(action)) {
				if (!Authorization.has(request, Permission.ASSET_USAGE_BORROW)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				dao.borrowItem(AuthSession.userId(request), requiredId(request, "assetItemId"),
						request.getParameter("note"));
			} else if ("return".equals(action)) {
				if (!Authorization.has(request, Permission.ASSET_USAGE_RETURN)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				dao.requestReturn(Long.parseLong(request.getParameter("usageId")), AuthSession.userId(request),
						request.getParameter("conditionAfter"), request.getParameter("note"));
			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			response.sendRedirect(request.getContextPath() + "/intern/usages");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			if ("borrow".equals(request.getParameter("action"))) {
				try {
					showBorrow(request, response);
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
			} else {
				doGet(request, response);
			}
		}
	}

	private void showBorrow(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("assetItems", dao.findBorrowableAssetItems());
		forward(request, response, "borrow.jsp");
	}

	private long requiredId(HttpServletRequest request, String name) {
		try {
			long value = Long.parseLong(request.getParameter(name));
			if (value <= 0) {
				throw new NumberFormatException();
			}
			return value;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Vui lòng chọn một sản phẩm cụ thể để mượn.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/intern/usages/" + view).forward(request, response);
	}
}
