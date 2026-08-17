package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.common.LabUsageRequestExcelReader;
import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import fpt.swp391.labtoolequip.model.LabUsageRequestStudent;
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
		"/mentor/interns/delete", "/mentor/interns/template", "/mentor/lab-requests", "/mentor/lab-requests/view",
		"/mentor/lab-requests/add", "/mentor/lab-requests/edit", "/mentor/lab-requests/delete",
		"/mentor/lab-requests/template"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class MentorLabUsageRequestController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/mentor/lab-requests/list.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/mentor/lab-requests/form.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/mentor/lab-requests/detail.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (canonicalPath(request)) {
				case "/mentor/lab-requests/view" -> showDetail(request, response);
				case "/mentor/lab-requests/add" -> showAddForm(request, response);
				case "/mentor/lab-requests/edit" -> showEditForm(request, response);
				case "/mentor/lab-requests/template" -> downloadTemplate(response);
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
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
			return;
		}
		String path = canonicalPath(request);
		try {
			switch (path) {
				case "/mentor/lab-requests/add" -> create(request, response);
				case "/mentor/lab-requests/edit" -> update(request, response);
				case "/mentor/lab-requests/delete" -> delete(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Manage intern list failed", exception);
			request.setAttribute("databaseError", databaseMessage(exception));
			if ("/mentor/lab-requests/delete".equals(path)) {
				response.sendRedirect(request.getContextPath() + "/mentor/interns?error=delete");
			} else {
				LabUsageRequest labRequest = readFormWithoutExcel(request);
				labRequest.setRequestId(optionalId(request.getParameter("id")));
				try {
					forwardForm(request, response, labRequest,
							"/mentor/lab-requests/edit".equals(path) ? "edit" : "add", List.of());
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
		request.setAttribute("requests",
				requestDAO.findByMentor(AuthSession.userId(request), keyword, status, semesterId));
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
		LabUsageRequest labRequest = requestDAO.findByIdForMentor(requestId, mentorId(request)).orElse(null);
		if (labRequest == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("labRequest", labRequest);
		request.setAttribute("csrfToken", csrfToken(request));
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showAddForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		LabUsageRequest labRequest = new LabUsageRequest();
		labRequest.setStatus("PENDING");
		request.setAttribute("labRequest", labRequest);
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
		LabUsageRequest labRequest = requestDAO.findByIdForMentor(requestId, mentorId(request)).orElse(null);
		if (labRequest == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		if (!"PENDING".equals(labRequest.getStatus())) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ danh sách PENDING mới được chỉnh sửa.");
			return;
		}
		request.setAttribute("labRequest", labRequest);
		request.setAttribute("formMode", "edit");
		prepareForm(request);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void create(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		LabUsageRequest labRequest;
		try {
			labRequest = readForm(request, true);
		} catch (IOException exception) {
			forwardForm(request, response, readFormWithoutExcel(request), "add", List.of(exception.getMessage()));
			return;
		}
		labRequest.setMentorId(mentorId(request));
		List<String> errors = validate(labRequest);
		if (!errors.isEmpty()) {
			forwardForm(request, response, labRequest, "add", errors);
			return;
		}
		long requestId = requestDAO.create(labRequest);
		response.sendRedirect(request.getContextPath() + "/mentor/interns/view?id=" + requestId + "&created=1");
	}

	private void update(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		LabUsageRequest labRequest;
		try {
			labRequest = readForm(request, true);
		} catch (IOException exception) {
			labRequest = readFormWithoutExcel(request);
			labRequest.setRequestId(requestId);
			forwardForm(request, response, labRequest, "edit", List.of(exception.getMessage()));
			return;
		}
		labRequest.setRequestId(requestId);
		labRequest.setMentorId(mentorId(request));
		List<String> errors = validate(labRequest);
		if (!errors.isEmpty()) {
			forwardForm(request, response, labRequest, "edit", errors);
			return;
		}
		if (!requestDAO.updatePending(labRequest)) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Danh sách không còn ở trạng thái PENDING.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/interns/view?id=" + requestId + "&updated=1");
	}

	private void delete(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		if (!requestDAO.deletePending(requestId, mentorId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ danh sách PENDING mới được xóa.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/interns?deleted=1");
	}

	private LabUsageRequest readForm(HttpServletRequest request, boolean includeExcel)
			throws IOException, ServletException {
		LabUsageRequest labRequest = readFormWithoutExcel(request);
		if (includeExcel) {
			Part excel = request.getPart("excelFile");
			LabUsageRequestExcelReader.ImportData imported = LabUsageRequestExcelReader.read(excel);
			labRequest.setStudents(mergeStudents(labRequest.getStudents(), imported.students()));
		}
		return labRequest;
	}

	private LabUsageRequest readFormWithoutExcel(HttpServletRequest request) {
		LabUsageRequest labRequest = new LabUsageRequest();
		labRequest.setSemesterId(optionalId(request.getParameter("semesterId")));
		labRequest.setGroupName(trim(request.getParameter("groupName")));
		labRequest.setRequestNote(trim(request.getParameter("requestNote")));
		labRequest.setStudents(readManualStudents(request));
		return labRequest;
	}

	private List<LabUsageRequestStudent> readManualStudents(HttpServletRequest request) {
		String[] codes = parameters(request, "internCode", "studentCode");
		String[] names = parameters(request, "internName", "studentName");
		String[] emails = parameters(request, "internEmail", "studentEmail");
		String[] cohorts = parameters(request, "cohort", "studentCohort");
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
		return interns;
	}

	private List<LabUsageRequestStudent> mergeStudents(List<LabUsageRequestStudent> first,
			List<LabUsageRequestStudent> second) {
		List<LabUsageRequestStudent> merged = new ArrayList<>(first);
		Set<String> emails = new LinkedHashSet<>();
		for (LabUsageRequestStudent intern : first) {
			emails.add(intern.getEmail().toLowerCase(Locale.ROOT));
		}
		for (LabUsageRequestStudent intern : second) {
			intern.setEmail(intern.getEmail().toLowerCase(Locale.ROOT));
			if (emails.add(intern.getEmail())) {
				merged.add(intern);
			}
		}
		return merged;
	}

	private List<String> validate(LabUsageRequest request) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (request.getSemesterId() == null || requestDAO.findOpenSemesters().stream()
				.noneMatch(semester -> semester.getSemesterId().equals(request.getSemesterId()))) {
			errors.add("Vui lòng chọn học kỳ đang hoạt động hoặc sắp diễn ra.");
		}
		if (request.getGroupName() == null || request.getGroupName().isBlank()
				|| request.getGroupName().length() > 100) {
			errors.add("Tên danh sách là bắt buộc và không được vượt quá 100 ký tự.");
		}
		if (request.getStudents().isEmpty()) {
			errors.add("Vui lòng nhập hoặc import ít nhất một intern.");
		}
		Set<String> codes = new LinkedHashSet<>();
		Set<String> emails = new LinkedHashSet<>();
		for (LabUsageRequestStudent intern : request.getStudents()) {
			String code = trim(intern.getStudentCode()).toUpperCase(Locale.ROOT);
			String email = trim(intern.getEmail()).toLowerCase(Locale.ROOT);
			String cohort = trim(intern.getCohort());
			if (code.isBlank() || trim(intern.getFullName()).isBlank() || cohort.isBlank()
					|| !EMAIL.matcher(email).matches()) {
				errors.add("Mỗi intern phải có mã, họ tên, Gmail và khóa hợp lệ.");
				break;
			}
			if (!codes.add(code) || !emails.add(email)) {
				errors.add("Mã intern và Gmail không được trùng trong cùng danh sách.");
				break;
			}
			intern.setStudentCode(code);
			intern.setEmail(email);
			intern.setFullName(trim(intern.getFullName()));
			intern.setCohort(cohort);
		}
		return errors;
	}

	private void forwardForm(HttpServletRequest request, HttpServletResponse response, LabUsageRequest labRequest,
			String mode, List<String> errors) throws SQLException, ServletException, IOException {
		request.setAttribute("labRequest", labRequest);
		request.setAttribute("formMode", mode);
		request.setAttribute("errors", errors);
		prepareForm(request);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void prepareForm(HttpServletRequest request) throws SQLException {
		request.setAttribute("semesters", requestDAO.findOpenSemesters());
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
		return request.getServletPath().replace("/mentor/interns", "/mentor/lab-requests");
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
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid list ID.");
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
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải danh sách intern.");
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
