package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Authorization;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.auth.Permission;
import fpt.swp391.labtoolequip.dao.DisposalRecordDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/disposals/*")
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
				response.sendError(HttpServletResponse.SC_FORBIDDEN);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("disposal", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			if (path != null && !"/".equals(path)) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			request.setAttribute("disposals",
					dao.findAll(request.getParameter("keyword"), request.getParameter("status")));
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
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String action = request.getParameter("action");
		Permission permission = switch (action == null ? "" : action) {
			case "approve", "reject" -> Permission.DISPOSAL_REVIEW;
			case "complete" -> Permission.DISPOSAL_COMPLETE;
			case "create", "update", "cancel" -> null;
			default -> null;
		};
		if (permission == null || !Authorization.has(request, permission)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		try {
			long id = disposalId(request);
			switch (action == null ? "" : action) {
				case "approve" -> dao.review(id, AuthSession.userId(request), true, request.getParameter("reviewNote"));
				case "reject" -> dao.review(id, AuthSession.userId(request), false, request.getParameter("reviewNote"));
				case "complete" -> {
					dao.complete(id, AuthSession.userId(request), request.getParameter("disposalMethod"),
							request.getParameter("completionNote"));
				}
				default -> {
					response.sendError(HttpServletResponse.SC_BAD_REQUEST);
					return;
				}
			}
			response.sendRedirect(request.getContextPath() + "/lab-manager/disposals/" + id);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		}
	}

	private long disposalId(HttpServletRequest request) {
		try {
			long id = Long.parseLong(request.getParameter("disposalId"));
			if (id <= 0)
				throw new NumberFormatException();
			return id;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Yêu cầu thanh lý không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/disposals/" + view).forward(request, response);
	}
}
