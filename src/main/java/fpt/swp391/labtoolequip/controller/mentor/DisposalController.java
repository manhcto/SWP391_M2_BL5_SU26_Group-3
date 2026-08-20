package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.DisposalRecordDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mentor/disposals/*")
public class DisposalController extends HttpServlet {
	private final DisposalRecordDAO dao = new DisposalRecordDAO();
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!Authorization.has(request, Permission.DISPOSAL_VIEW)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			String path = request.getPathInfo();
			if ("/new".equals(path)) {
				if (!Authorization.has(request, Permission.DISPOSAL_REQUEST)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showNewForm(request, response);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("disposal",
						dao.findByIdForMentor(Long.parseLong(path.substring(1)), AuthSession.userId(request))
								.orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			request.setAttribute("disposals", dao.findForMentor(AuthSession.userId(request),
					request.getParameter("keyword"), request.getParameter("status")));
			forward(request, response, "list.jsp");
		} catch (SQLException e) {
			throw new ServletException(e);
		} catch (RuntimeException e) {
			response.sendError(404);
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
		if (!Authorization.has(request, Permission.DISPOSAL_REQUEST)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		try {
			if (!"create".equals(action)) {
				response.sendError(400);
				return;
			}
			long id = dao.create(AuthSession.userId(request), optionalId(request, "assetId"),
					optionalId(request, "assetItemId"), request.getParameter("reason"));
			response.sendRedirect(request.getContextPath() + "/mentor/disposals/" + id);
		} catch (SQLException e) {
			throw new ServletException(e);
		} catch (RuntimeException e) {
			request.setAttribute("message", e.getMessage());
			showNewForm(request, response);
		}
	}

	private void showNewForm(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("csrfToken", Csrf.token(request));
			request.setAttribute("quantityAssets", dao.findEligibleQuantityAssets());
			request.setAttribute("assetItems", dao.findEligibleAssetItems());
			forward(request, response, "form.jsp");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	private Long optionalId(HttpServletRequest request, String name) {
		String value = request.getParameter(name);
		if (value == null || value.isBlank())
			return null;
		try {
			long id = Long.parseLong(value);
			if (id <= 0)
				throw new NumberFormatException();
			return id;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Thiết bị được chọn không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest r, HttpServletResponse s, String view)
			throws ServletException, IOException {
		r.getRequestDispatcher("/WEB-INF/views/mentor/disposals/" + view).forward(r, s);
	}
}
