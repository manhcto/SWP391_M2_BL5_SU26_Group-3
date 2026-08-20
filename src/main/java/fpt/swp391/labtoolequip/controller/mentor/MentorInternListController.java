package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.common.InternListExcelReader;
import fpt.swp391.labtoolequip.dao.InternListDAO;
import fpt.swp391.labtoolequip.model.InternList;
import fpt.swp391.labtoolequip.model.InternListStudent;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

@WebServlet({"/mentor/interns", "/mentor/interns/view", "/mentor/interns/add", "/mentor/interns/edit",
		"/mentor/interns/delete", "/mentor/interns/template"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class MentorInternListController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/mentor/intern-lists/list.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/mentor/intern-lists/form.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/mentor/intern-lists/detail.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private final InternListDAO internListDAO = new InternListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (canonicalPath(request)) {
				case "/mentor/interns/view" -> showDetail(request, response);
				case "/mentor/interns/add" -> showAddForm(request, response);
				case "/mentor/interns/edit" -> showEditForm(request, response);
				case "/mentor/interns/template" -> downloadTemplate(response);
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
		if (!validCsrf(request)) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Mã bảo vệ CSRF không hợp lệ.");
			return;
		}
		String path = canonicalPath(request);
		try {
			switch (path) {
				case "/mentor/interns/add" -> create(request, response);
				case "/mentor/interns/edit" -> update(request, response);
				case "/mentor/interns/delete" -> delete(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Manage intern list failed", exception);
			request.setAttribute("databaseError", databaseMessage(exception));
			if ("/mentor/interns/delete".equals(path)) {
				response.sendRedirect(request.getContextPath() + "/mentor/interns?error=delete");
			} else {
				InternList internList = readFormWithoutExcel(request);
				internList.setRequestId(optionalId(request.getParameter("id")));
				try {
					forwardForm(request, response, internList, "/mentor/interns/edit".equals(path) ? "edit" : "add",
							List.of());
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
		request.setAttribute("internLists",
				internListDAO.findByMentor(AuthSession.userId(request), keyword, status, semesterId));
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
		InternList internList = internListDAO.findByIdForMentor(requestId, mentorId(request)).orElse(null);
		if (internList == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("internList", internList);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showAddForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		InternList internList = new InternList();
		internList.setStatus("PENDING");
		request.setAttribute("internList", internList);
		request.setAttribute("formMode", "add");
		prepareForm(request);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void showEditForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		InternList internList = internListDAO.findByIdForMentor(requestId, mentorId(request)).orElse(null);
		if (internList == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		if (!"PENDING".equals(internList.getStatus())) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ danh sách chờ duyệt mới được chỉnh sửa.");
			return;
		}
		request.setAttribute("internList", internList);
		request.setAttribute("formMode", "edit");
		prepareForm(request);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void create(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		InternList internList;
		try {
			internList = readForm(request, true);
		} catch (IOException exception) {
			forwardForm(request, response, readFormWithoutExcel(request), "add", List.of(exception.getMessage()));
			return;
		}
		internList.setMentorId(mentorId(request));
		List<String> errors = validate(internList);
		if (!errors.isEmpty()) {
			forwardForm(request, response, internList, "add", errors);
			return;
		}
		long requestId = internListDAO.create(internList);
		response.sendRedirect(request.getContextPath() + "/mentor/interns/view?id=" + requestId + "&created=1");
	}

	private void update(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		InternList internList;
		try {
			internList = readForm(request, true);
		} catch (IOException exception) {
			internList = readFormWithoutExcel(request);
			internList.setRequestId(requestId);
			forwardForm(request, response, internList, "edit", List.of(exception.getMessage()));
			return;
		}
		internList.setRequestId(requestId);
		internList.setMentorId(mentorId(request));
		List<String> errors = validate(internList);
		if (!errors.isEmpty()) {
			forwardForm(request, response, internList, "edit", errors);
			return;
		}
		if (!internListDAO.updatePending(internList)) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn ở trạng thái chờ duyệt.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/interns/view?id=" + requestId + "&updated=1");
	}

	private void delete(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		if (!internListDAO.deletePending(requestId, mentorId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ danh sách chờ duyệt mới được xóa.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/interns?deleted=1");
	}

	private InternList readForm(HttpServletRequest request, boolean includeExcel) throws IOException, ServletException {
		InternList internList = readFormWithoutExcel(request);
		if (includeExcel) {
			Part excel = request.getPart("excelFile");
			InternListExcelReader.ImportData imported = InternListExcelReader.read(excel);
			internList.setStudents(mergeStudents(internList.getStudents(), imported.students()));
		}
		return internList;
	}

	private InternList readFormWithoutExcel(HttpServletRequest request) {
		InternList internList = new InternList();
		internList.setSemesterId(optionalId(request.getParameter("semesterId")));
		internList.setGroupName(trim(request.getParameter("groupName")));
		internList.setRequestNote(trim(request.getParameter("requestNote")));
		internList.setStudents(readManualStudents(request));
		return internList;
	}

	private List<InternListStudent> readManualStudents(HttpServletRequest request) {
		String[] codes = parameters(request, "internCode", "studentCode");
		String[] names = parameters(request, "internName", "studentName");
		String[] emails = parameters(request, "internEmail", "studentEmail");
		String[] cohorts = parameters(request, "cohort", "studentCohort");
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
		return interns;
	}

	private List<InternListStudent> mergeStudents(List<InternListStudent> first, List<InternListStudent> second) {
		List<InternListStudent> merged = new ArrayList<>(first);
		Set<String> emails = new LinkedHashSet<>();
		for (InternListStudent intern : first) {
			emails.add(intern.getEmail().toLowerCase(Locale.ROOT));
		}
		for (InternListStudent intern : second) {
			intern.setEmail(intern.getEmail().toLowerCase(Locale.ROOT));
			if (emails.add(intern.getEmail())) {
				merged.add(intern);
			}
		}
		return merged;
	}

	private List<String> validate(InternList request) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (request.getSemesterId() == null || internListDAO.findOpenSemesters().stream()
				.noneMatch(semester -> semester.getSemesterId().equals(request.getSemesterId()))) {
			errors.add("Vui lòng chọn học kỳ đang hoạt động hoặc sắp diễn ra.");
		}
		if (request.getGroupName() == null || request.getGroupName().isBlank()
				|| request.getGroupName().length() > 100) {
			errors.add("Tên danh sách là bắt buộc và không được vượt quá 100 ký tự.");
		}
		if (request.getStudents().isEmpty()) {
			errors.add("Vui lòng nhập trực tiếp hoặc nhập từ tệp ít nhất một thực tập sinh.");
		}
		Set<String> codes = new LinkedHashSet<>();
		Set<String> emails = new LinkedHashSet<>();
		for (InternListStudent intern : request.getStudents()) {
			String code = trim(intern.getStudentCode()).toUpperCase(Locale.ROOT);
			String email = trim(intern.getEmail()).toLowerCase(Locale.ROOT);
			String cohort = trim(intern.getCohort());
			if (code.isBlank() || trim(intern.getFullName()).isBlank() || cohort.isBlank()
					|| !EMAIL.matcher(email).matches()) {
				errors.add("Mỗi thực tập sinh phải có mã, họ tên, Gmail và khóa hợp lệ.");
				break;
			}
			if (!codes.add(code) || !emails.add(email)) {
				errors.add("Mã thực tập sinh và Gmail không được trùng trong cùng danh sách.");
				break;
			}
			intern.setStudentCode(code);
			intern.setEmail(email);
			intern.setFullName(trim(intern.getFullName()));
			intern.setCohort(cohort);
		}
		return errors;
	}

	private void forwardForm(HttpServletRequest request, HttpServletResponse response, InternList internList,
			String mode, List<String> errors) throws SQLException, ServletException, IOException {
		request.setAttribute("internList", internList);
		request.setAttribute("formMode", mode);
		request.setAttribute("errors", errors);
		prepareForm(request);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void prepareForm(HttpServletRequest request) throws SQLException {
		request.setAttribute("semesters", internListDAO.findOpenSemesters());
		request.setAttribute("csrfToken", csrfToken(request));
	}

	private void downloadTemplate(HttpServletResponse response) throws IOException {
		response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		response.setHeader("Content-Disposition", "attachment; filename=intern-list-template.xlsx");
		try (Workbook workbook = new XSSFWorkbook()) {
			Sheet interns = workbook.createSheet("Interns");
			Row header = interns.createRow(0);
			header.createCell(0).setCellValue("Intern Code");
			header.createCell(1).setCellValue("Full Name");
			header.createCell(2).setCellValue("Gmail");
			header.createCell(3).setCellValue("Cohort");
			workbook.write(response.getOutputStream());
		}
	}

	private String canonicalPath(HttpServletRequest request) {
		return request.getServletPath();
	}

	private long mentorId(HttpServletRequest request) {
		return AuthSession.userId(request);
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
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã danh sách không hợp lệ.");
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
		if (message != null
				&& (message.contains("Email ") || message.contains("Gmail ") || message.contains("Mã intern"))) {
			return message;
		}
		return "Không thể lưu danh sách. Học kỳ có thể đã có danh sách hoặc dữ liệu bị trùng.";
	}

	private void handleDatabaseError(HttpServletResponse response, SQLException exception) throws IOException {
		getServletContext().log("Loading intern lists failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải danh sách thực tập sinh.");
	}

	private String[] parameters(HttpServletRequest request, String primary, String fallback) {
		String[] values = request.getParameterValues(primary);
		return values == null ? request.getParameterValues(fallback) : values;
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
