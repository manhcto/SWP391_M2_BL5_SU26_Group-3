package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.InternListDAO;
import fpt.swp391.labtoolequip.model.InternList;
import fpt.swp391.labtoolequip.model.InternListStudent;
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
		"/admin/interns/decision"})
public class AdminInternListController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/admin/intern-lists/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/admin/intern-lists/detail.jsp";
	private static final String EDIT_VIEW = "/WEB-INF/views/admin/intern-lists/form.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private final InternListDAO internListDAO = new InternListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (canonicalPath(request)) {
				case "/admin/interns/view" -> showDetail(request, response);
				case "/admin/interns/edit" -> showEditForm(request, response);
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
		if (!Set.of("/admin/interns/decision", "/admin/interns/edit", "/admin/interns/delete").contains(path)) {
			response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			return;
		}
		if (!validCsrf(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Mã bảo vệ CSRF không hợp lệ.");
			return;
		}
		try {
			switch (path) {
				case "/admin/interns/decision" -> decide(request, response);
				case "/admin/interns/edit" -> update(request, response);
				case "/admin/interns/delete" -> delete(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Admin intern list operation failed", exception);
			if ("/admin/interns/decision".equals(path)) {
				request.setAttribute("decisionError", "Không thể cập nhật quyết định danh sách thực tập sinh.");
				try {
					showDetail(request, response);
				} catch (SQLException loadingException) {
					handleDatabaseError(response, loadingException);
				}
			} else if ("/admin/interns/delete".equals(path)) {
				response.sendRedirect(request.getContextPath() + "/admin/interns?error=delete");
			} else {
				InternList internList = readForm(request);
				internList.setRequestId(optionalId(request.getParameter("id")));
				try {
					forwardEditForm(request, response, internList, List.of("Không thể lưu danh sách thực tập sinh."));
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
		request.setAttribute("internLists", internListDAO.findAll(keyword, status, semesterId));
		request.setAttribute("semesters", internListDAO.findOpenSemesters());
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
		InternList internList = internListDAO.findById(requestId).orElse(null);
		if (internList == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("internList", internList);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showEditForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		InternList internList = internListDAO.findById(requestId).orElse(null);
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
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Quyết định phê duyệt không hợp lệ.");
			return;
		}
		if (!internListDAO.decidePending(requestId, AuthSession.userId(request), decision,
				trim(request.getParameter("approvalNote")))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn ở trạng thái chờ duyệt.");
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
		InternList internList = readForm(request);
		internList.setRequestId(requestId);
		List<String> errors = validate(internList);
		if (!errors.isEmpty()) {
			forwardEditForm(request, response, internList, errors);
			return;
		}
		if (!internListDAO.updateByAdmin(internList, AuthSession.userId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT,
					"Danh sách không còn tồn tại hoặc quản trị viên không hợp lệ.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/admin/interns/view?id=" + requestId + "&updated=1");
	}

	private void delete(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		if (!internListDAO.deleteByAdmin(requestId, AuthSession.userId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT,
					"Danh sách không còn tồn tại hoặc quản trị viên không hợp lệ.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/admin/interns?deleted=1");
	}

	private InternList readForm(HttpServletRequest request) {
		InternList internList = new InternList();
		internList.setSemesterId(optionalId(request.getParameter("semesterId")));
		internList.setGroupName(trim(request.getParameter("groupName")));
		internList.setRequestNote(trim(request.getParameter("requestNote")));
		String[] codes = request.getParameterValues("internCode");
		String[] names = request.getParameterValues("internName");
		String[] emails = request.getParameterValues("internEmail");
		String[] cohorts = request.getParameterValues("cohort");
		int size = Math.max(Math.max(length(codes), length(names)), Math.max(length(emails), length(cohorts)));
		List<InternListStudent> interns = new ArrayList<>();
		for (int index = 0; index < size; index++) {
			String code = valueAt(codes, index);
			String name = valueAt(names, index);
			String email = valueAt(emails, index).toLowerCase(Locale.ROOT);
			String cohort = valueAt(cohorts, index);
			if (code.isBlank() && name.isBlank() && email.isBlank() && cohort.isBlank()) {
				continue;
			}
			InternListStudent intern = new InternListStudent();
			intern.setStudentCode(code);
			intern.setFullName(name);
			intern.setEmail(email);
			intern.setCohort(cohort);
			interns.add(intern);
		}
		internList.setStudents(interns);
		return internList;
	}

	private List<String> validate(InternList internList) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (internList.getSemesterId() == null || internListDAO.findOpenSemesters().stream()
				.noneMatch(semester -> semester.getSemesterId().equals(internList.getSemesterId()))) {
			errors.add("Vui lòng chọn học kỳ đang hoạt động hoặc sắp diễn ra.");
		}
		if (internList.getGroupName().isBlank() || internList.getGroupName().length() > 100) {
			errors.add("Tên danh sách là bắt buộc và không được vượt quá 100 ký tự.");
		}
		if (internList.getStudents().isEmpty()) {
			errors.add("Danh sách phải có ít nhất một thực tập sinh.");
		}
		Set<String> codes = new LinkedHashSet<>();
		Set<String> emails = new LinkedHashSet<>();
		for (InternListStudent intern : internList.getStudents()) {
			String code = trim(intern.getStudentCode()).toUpperCase(Locale.ROOT);
			String email = trim(intern.getEmail()).toLowerCase(Locale.ROOT);
			if (code.isBlank() || trim(intern.getFullName()).isBlank() || trim(intern.getCohort()).isBlank()
					|| !EMAIL.matcher(email).matches()) {
				errors.add("Mỗi thực tập sinh phải có mã, họ tên, email và khóa hợp lệ.");
				break;
			}
			if (!codes.add(code) || !emails.add(email)) {
				errors.add("Mã thực tập sinh và email không được trùng trong cùng danh sách.");
				break;
			}
			intern.setStudentCode(code);
			intern.setFullName(trim(intern.getFullName()));
			intern.setEmail(email);
			intern.setCohort(trim(intern.getCohort()));
		}
		return errors;
	}

	private void forwardEditForm(HttpServletRequest request, HttpServletResponse response, InternList internList,
			List<String> errors) throws SQLException, ServletException, IOException {
		request.setAttribute("internList", internList);
		request.setAttribute("formMode", "edit");
		request.setAttribute("errors", errors);
		request.setAttribute("semesters", internListDAO.findOpenSemesters());
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(EDIT_VIEW).forward(request, response);
	}

	private String canonicalPath(HttpServletRequest request) {
		return request.getServletPath();
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
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã danh sách thực tập sinh không hợp lệ.");
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
		getServletContext().log("Loading Admin Intern Lists failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải danh sách thực tập sinh.");
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
