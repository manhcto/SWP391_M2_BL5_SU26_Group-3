package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
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
		try {
			String path = request.getPathInfo();
			if ("/new".equals(path)) {
				request.setAttribute("assets", dao.findEligibleAssets());
				forward(request, response, "form.jsp");
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("disposal", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
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
		try {
			String action = request.getParameter("action");
			long id;
			switch (action == null ? "" : action) {
				case "create" -> id = dao.create(AuthSession.userId(request),
						Long.parseLong(request.getParameter("assetId")), request.getParameter("reason"));
				case "update" -> {
					id = Long.parseLong(request.getParameter("disposalId"));
					dao.updatePending(id, request.getParameter("reason"));
				}
				case "cancel" -> {
					id = Long.parseLong(request.getParameter("disposalId"));
					dao.cancel(id, request.getParameter("note"));
				}
				case "complete" -> {
					id = Long.parseLong(request.getParameter("disposalId"));
					dao.complete(id, request.getParameter("note"));
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

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/disposals/" + view).forward(request, response);
	}
}
