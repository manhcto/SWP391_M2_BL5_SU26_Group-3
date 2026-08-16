package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@WebServlet({"/admin/lab-requests", "/admin/lab-requests/view", "/admin/lab-requests/decision"})
public class AdminLabUsageRequestController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/admin/lab-requests/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/admin/lab-requests/detail.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");

	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();
	private final UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			if ("/admin/lab-requests/view".equals(request.getServletPath())) {
				showDetail(request, response);
			} else {
				showList(request, response);
			}
		} catch (SQLException exception) {
			handleDatabaseError(response, exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		if (!"/admin/lab-requests/decision".equals(request.getServletPath())) {
			response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			return;
		}
		if (!validCsrf(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
			return;
		}

		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		String decision = normalize(request.getParameter("decision"));
		if (!Set.of("APPROVED", "REJECTED").contains(decision)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid decision.");
			return;
		}

		try {
			long adminId = userDAO.findFirstActiveAdminId()
					.orElseThrow(() -> new SQLException("Chưa có tài khoản Admin ACTIVE để duyệt request."));
			if (!requestDAO.decidePending(requestId, adminId, decision, trim(request.getParameter("approvalNote")))) {
				response.sendError(HttpServletResponse.SC_CONFLICT, "Request không còn ở trạng thái PENDING.");
				return;
			}
			response.sendRedirect(
					request.getContextPath() + "/admin/lab-requests/view?id=" + requestId + "&decided=" + decision);
		} catch (SQLException exception) {
			getServletContext().log("Admin Lab Usage Request decision failed", exception);
			request.setAttribute("decisionError", exception.getMessage());
			try {
				showDetail(request, response);
			} catch (SQLException loadingException) {
				handleDatabaseError(response, loadingException);
			}
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = trim(request.getParameter("keyword"));
		String status = normalize(request.getParameter("status"));
		if (!status.isEmpty() && !STATUSES.contains(status)) {
			status = "";
		}
		Long semesterId = optionalId(request.getParameter("semesterId"));
		request.setAttribute("requests", requestDAO.findAll(keyword, status, semesterId));
		request.setAttribute("semesters", requestDAO.findOpenSemesters());
		request.setAttribute("keyword", keyword);
		request.setAttribute("selectedStatus", status);
		request.setAttribute("selectedSemesterId", semesterId);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}

	private void showDetail(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		LabUsageRequest labRequest = requestDAO.findById(requestId).orElse(null);
		if (labRequest == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("labRequest", labRequest);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private String csrfToken(HttpServletRequest request) {
		String token = (String) request.getSession().getAttribute("csrfToken");
		if (token == null) {
			token = UUID.randomUUID().toString();
			request.getSession().setAttribute("csrfToken", token);
		}
		return token;
	}

	private boolean validCsrf(HttpServletRequest request) {
		String expected = (String) request.getSession().getAttribute("csrfToken");
		return expected != null && expected.equals(request.getParameter("csrfToken"));
	}

	private long requireId(HttpServletRequest request, HttpServletResponse response) throws IOException {
		try {
			long id = Long.parseLong(request.getParameter("id"));
			if (id <= 0) {
				throw new NumberFormatException();
			}
			return id;
		} catch (NumberFormatException exception) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request ID.");
			return 0;
		}
	}

	private Long optionalId(String value) {
		try {
			long id = Long.parseLong(value);
			return id > 0 ? id : null;
		} catch (NumberFormatException exception) {
			return null;
		}
	}

	private void handleDatabaseError(HttpServletResponse response, SQLException exception) throws IOException {
		getServletContext().log("Loading Admin Lab Usage Requests failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải Lab Usage Requests.");
	}

	private String trim(String value) {
		return value == null ? "" : value.trim();
	}

	private String normalize(String value) {
		return trim(value).toUpperCase(Locale.ROOT);
	}
}
