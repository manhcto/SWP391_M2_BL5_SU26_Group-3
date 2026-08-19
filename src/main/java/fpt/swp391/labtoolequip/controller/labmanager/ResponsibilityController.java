package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.ResponsibilityDAO;
import fpt.swp391.labtoolequip.model.Responsibility;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/lab-manager/responsibilities/*")
public class ResponsibilityController extends HttpServlet {
	private final ResponsibilityDAO dao = new ResponsibilityDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path == null || "/".equals(path)) {
				String keyword = request.getParameter("keyword");
				String status = request.getParameter("status");
				request.setAttribute("keyword", keyword);
				request.setAttribute("selectedStatus", status);
				request.setAttribute("responsibilities", dao.findAll(keyword, status));
				forward(request, response, "list.jsp");
				return;
			}
			if (path.matches("/\\d+")) {
				long id = Long.parseLong(path.substring(1));
				request.setAttribute("responsibility", dao.findById(id).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}
			if (path.matches("/\\d+/edit")) {
				request.setAttribute("responsibility", dao.findById(idFrom(path)).orElseThrow());
				forward(request, response, "form.jsp");
				return;
			}
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
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
		if (!"update".equals(request.getParameter("action"))) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			long id = Long.parseLong(request.getParameter("responsibilityId"));
			dao.updateByLabManager(AuthSession.userId(request), id, request.getParameter("decision"),
					request.getParameter("status"), request.getParameter("reviewNote"),
					request.getParameter("resolutionNote"));
			response.sendRedirect(
					request.getContextPath() + "/lab-manager/responsibilities/" + id + "?success=updated");
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			try {
				Responsibility record = dao.findById(Long.parseLong(request.getParameter("responsibilityId")))
						.orElseThrow();
				record.setDecision(request.getParameter("decision"));
				record.setStatus(request.getParameter("status"));
				record.setReviewNote(request.getParameter("reviewNote"));
				record.setResolutionNote(request.getParameter("resolutionNote"));
				request.setAttribute("responsibility", record);
				request.setAttribute("message", exception.getMessage());
				forward(request, response, "form.jsp");
			} catch (SQLException | RuntimeException nested) {
				throw new ServletException(nested);
			}
		}
	}

	private long idFrom(String path) {
		return Long.parseLong(path.split("/")[1]);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/responsibilities/" + view).forward(request, response);
	}
}
