package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import fpt.swp391.labtoolequip.model.LabUsageRequestStudent;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

@WebServlet({"/admin/interns", "/admin/interns/view", "/admin/interns/edit", "/admin/interns/delete",
		"/admin/interns/decision", "/admin/lab-requests", "/admin/lab-requests/view", "/admin/lab-requests/edit",
		"/admin/lab-requests/delete", "/admin/lab-requests/decision"})
public class AdminLabUsageRequestController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/admin/lab-requests/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/admin/lab-requests/detail.jsp";
	private static final String EDIT_VIEW = "/WEB-INF/views/admin/lab-requests/form.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (canonicalPath(request)) {
				case "/admin/lab-requests/view" -> showDetail(request, response);
				case "/admin/lab-requests/edit" -> showEditForm(request, response);
				default -> showList(request, response);
			}
		} catch (SQLException exception) {
			handleDatabaseError(response, exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		String path = canonicalPath(request);
		if (!Set.of("/admin/lab-requests/decision", "/admin/lab-requests/edit", "/admin/lab-requests/delete")
				.contains(path)) {
			response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			return;
		}
		if (!validCsrf(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
			return;
		}
		try {
			switch (path) {
				case "/admin/lab-requests/decision" -> decide(request, response);
				case "/admin/lab-requests/edit" -> update(request, response);
				case "/admin/lab-requests/delete" -> delete(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Admin intern list operation failed", exception);
			if ("/admin/lab-requests/decision".equals(path)) {
				request.setAttribute("decisionError", exception.getMessage());
				try {
					showDetail(request, response);
				} catch (SQLException loadingException) {
					handleDatabaseError(response, loadingException);
				}
			} else if ("/admin/lab-requests/delete".equals(path)) {
				response.sendRedirect(request.getContextPath() + "/admin/interns?error=delete");
			} else {
				LabUsageRequest internList = readForm(request);
				internList.setRequestId(optionalId(request.getParameter("id")));
				try {
					forwardEditForm(request, response, internList, List.of(databaseMessage(exception)));
				} catch (SQLException loadingException) {
					handleDatabaseError(response, loadingException);
				}
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
		LabUsageRequest internList = requestDAO.findById(requestId).orElse(null);
		if (internList == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("labRequest", internList);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showEditForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		LabUsageRequest internList = requestDAO.findById(requestId).orElse(null);
		if (internList == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		forwardEditForm(request, response, internList, List.of());
	}

	private void decide(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		String decision = normalize(request.getParameter("decision"));
		if (!Set.of("APPROVED", "REJECTED").contains(decision)) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid decision.");
			return;
		}
		if (!requestDAO.decidePending(requestId, AuthSession.userId(request), decision,
				trim(request.getParameter("approvalNote")))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn ở trạng thái PENDING.");
			return;
		}
		response.sendRedirect(
				request.getContextPath() + "/admin/interns/view?id=" + requestId + "&decided=" + decision);
	}

	private void update(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		LabUsageRequest internList = readForm(request);
		internList.setRequestId(requestId);
		List<String> errors = validate(internList);
		if (!errors.isEmpty()) {
			forwardEditForm(request, response, internList, errors);
			return;
		}
		if (!requestDAO.updateByAdmin(internList, AuthSession.userId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn tồn tại hoặc Admin không hợp lệ.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/admin/interns/view?id=" + requestId + "&updated=1");
	}

	private void delete(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		if (!requestDAO.deleteByAdmin(requestId, AuthSession.userId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn tồn tại hoặc Admin không hợp lệ.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/admin/interns?deleted=1");
	}

	private LabUsageRequest readForm(HttpServletRequest request) {
		LabUsageRequest internList = new LabUsageRequest();
		internList.setSemesterId(optionalId(request.getParameter("semesterId")));
		internList.setGroupName(trim(request.getParameter("groupName")));
		internList.setRequestNote(trim(request.getParameter("requestNote")));
		String[] codes = request.getParameterValues("internCode");
		String[] names = request.getParameterValues("internName");
		String[] emails = request.getParameterValues("internEmail");
		String[] cohorts = request.getParameterValues("cohort");
		int size = Math.max(Math.max(length(codes), length(names)), Math.max(length(emails), length(cohorts)));
		List<LabUsageRequestStudent> interns = new ArrayList<>();
		for (int index = 0; index < size; index++) {
			String code = valueAt(codes, index);
			String name = valueAt(names, index);
			String email = valueAt(emails, index).toLowerCase(Locale.ROOT);
			String cohort = valueAt(cohorts, index);
			if (code.isBlank() && name.isBlank() && email.isBlank() && cohort.isBlank()) {
				continue;
			}
			LabUsageRequestStudent intern = new LabUsageRequestStudent();
			intern.setStudentCode(code);
			intern.setFullName(name);
			intern.setEmail(email);
			intern.setCohort(cohort);
			interns.add(intern);
		}
		internList.setStudents(interns);
		return internList;
	}

	private List<String> validate(LabUsageRequest internList) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (internList.getSemesterId() == null || requestDAO.findOpenSemesters().stream()
				.noneMatch(semester -> semester.getSemesterId().equals(internList.getSemesterId()))) {
			errors.add("Vui lòng chọn học kỳ đang hoạt động hoặc sắp diễn ra.");
		}
		if (internList.getGroupName().isBlank() || internList.getGroupName().length() > 100) {
			errors.add("Tên danh sách là bắt buộc và không được vượt quá 100 ký tự.");
		}
		if (internList.getStudents().isEmpty()) {
			errors.add("Danh sách phải có ít nhất một intern.");
		}
		Set<String> codes = new LinkedHashSet<>();
		Set<String> emails = new LinkedHashSet<>();
		for (LabUsageRequestStudent intern : internList.getStudents()) {
			String code = trim(intern.getStudentCode()).toUpperCase(Locale.ROOT);
			String email = trim(intern.getEmail()).toLowerCase(Locale.ROOT);
			if (code.isBlank() || trim(intern.getFullName()).isBlank() || trim(intern.getCohort()).isBlank()
					|| !EMAIL.matcher(email).matches()) {
				errors.add("Mỗi intern phải có mã, họ tên, Gmail và khóa hợp lệ.");
				break;
			}
			if (!codes.add(code) || !emails.add(email)) {
				errors.add("Mã intern và Gmail không được trùng trong cùng danh sách.");
				break;
			}
			intern.setStudentCode(code);
			intern.setFullName(trim(intern.getFullName()));
			intern.setEmail(email);
			intern.setCohort(trim(intern.getCohort()));
		}
		return errors;
	}

	private void forwardEditForm(HttpServletRequest request, HttpServletResponse response, LabUsageRequest internList,
			List<String> errors) throws SQLException, ServletException, IOException {
		request.setAttribute("labRequest", internList);
		request.setAttribute("formMode", "edit");
		request.setAttribute("errors", errors);
		request.setAttribute("semesters", requestDAO.findOpenSemesters());
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(EDIT_VIEW).forward(request, response);
	}

	private String canonicalPath(HttpServletRequest request) {
		return request.getServletPath().replace("/admin/interns", "/admin/lab-requests");
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
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid intern list ID.");
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

	private String databaseMessage(SQLException exception) {
		String message = exception.getMessage();
		return message == null || message.isBlank()
				? "Không thể lưu danh sách intern."
				: "Không thể lưu danh sách intern: " + message;
	}

	private void handleDatabaseError(HttpServletResponse response, SQLException exception) throws IOException {
		getServletContext().log("Loading Admin Intern Lists failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải danh sách intern.");
	}

	private int length(String[] values) {
		return values == null ? 0 : values.length;
	}

	private String valueAt(String[] values, int index) {
		return values == null || index >= values.length ? "" : trim(values[index]);
	}

	private String trim(String value) {
		return value == null ? "" : value.trim();
	}

	private String normalize(String value) {
		return trim(value).toUpperCase(Locale.ROOT);
	}
}
