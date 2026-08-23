package fpt.swp391.labtoolequip.controller.intern;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.dao.AssetUsageDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;

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
				dao.borrow(AuthSession.userId(request), nullableLong(request, "assetId"),
						nullableLong(request, "assetItemId"), Integer.parseInt(request.getParameter("quantity")),
						request.getParameter("note"), borrowedAt(request));
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

	private Long nullableLong(HttpServletRequest request, String name) {
		String value = request.getParameter(name);
		return value == null || value.isBlank() ? null : Long.valueOf(value);
	}

	private void showBorrow(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("csrfToken", Csrf.token(request));
		request.setAttribute("defaultBorrowedAt", ViewFormat.dateTimeInput(ViewFormat.now()));
		request.setAttribute("assets", dao.findBorrowableAssets());
		request.setAttribute("assetItems", dao.findBorrowableAssetItems());
		forward(request, response, "borrow.jsp");
	}

	private LocalDateTime borrowedAt(HttpServletRequest request) {
		String value = request.getParameter("borrowedAt");
		if (value == null || value.isBlank()) {
			throw new IllegalArgumentException("Vui lòng chọn ngày và giờ mượn.");
		}
		try {
			return LocalDateTime.parse(value);
		} catch (RuntimeException exception) {
			throw new IllegalArgumentException("Ngày và giờ mượn không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/intern/usages/" + view).forward(request, response);
	}
}
