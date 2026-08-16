package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.common.LabUsageRequestExcelReader;
import fpt.swp391.labtoolequip.dao.LabUsageRequestDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.LabUsageRequest;
import fpt.swp391.labtoolequip.model.LabUsageRequestSlot;
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
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

@WebServlet({"/mentor/lab-requests", "/mentor/lab-requests/view", "/mentor/lab-requests/add",
		"/mentor/lab-requests/edit", "/mentor/lab-requests/delete", "/mentor/lab-requests/template"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class MentorLabUsageRequestController extends HttpServlet {
	private static final String LIST_VIEW = "/WEB-INF/views/mentor/lab-requests/list.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/mentor/lab-requests/form.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/mentor/lab-requests/detail.jsp";
	private static final Set<String> STATUSES = Set.of("PENDING", "APPROVED", "REJECTED");
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private final LabUsageRequestDAO requestDAO = new LabUsageRequestDAO();
	private final UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (request.getServletPath()) {
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
		try {
			switch (request.getServletPath()) {
				case "/mentor/lab-requests/add" -> create(request, response);
				case "/mentor/lab-requests/edit" -> update(request, response);
				case "/mentor/lab-requests/delete" -> delete(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Manage Lab Usage Request failed", exception);
			request.setAttribute("databaseError", databaseMessage(exception));
			if ("/mentor/lab-requests/delete".equals(request.getServletPath())) {
				response.sendRedirect(request.getContextPath() + "/mentor/lab-requests?error=delete");
			} else {
				LabUsageRequest labRequest = readFormWithoutExcel(request);
				String mode = "/mentor/lab-requests/edit".equals(request.getServletPath()) ? "edit" : "add";
				labRequest.setRequestId(optionalId(request.getParameter("id")));
				try {
					forwardForm(request, response, labRequest, mode, List.of());
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
		var previewMentorId = userDAO.findFirstActiveMentorId();
		request.setAttribute("requests",
				previewMentorId.isPresent()
						? requestDAO.findByMentor(previewMentorId.getAsLong(), keyword, status, semesterId)
						: List.of());
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
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ request PENDING mới được chỉnh sửa.");
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
		response.sendRedirect(request.getContextPath() + "/mentor/lab-requests/view?id=" + requestId + "&created=1");
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
			response.sendError(HttpServletResponse.SC_CONFLICT, "Request không còn ở trạng thái PENDING.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/lab-requests/view?id=" + requestId + "&updated=1");
	}

	private void delete(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long requestId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		if (!requestDAO.deletePending(requestId, mentorId(request))) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "Chỉ request PENDING mới được xóa.");
			return;
		}
		response.sendRedirect(request.getContextPath() + "/mentor/lab-requests?deleted=1");
	}

	private LabUsageRequest readForm(HttpServletRequest request, boolean includeExcel)
			throws IOException, ServletException {
		LabUsageRequest labRequest = readFormWithoutExcel(request);
		if (includeExcel) {
			Part excel = request.getPart("excelFile");
			LabUsageRequestExcelReader.ImportData imported = LabUsageRequestExcelReader.read(excel);
			labRequest.setStudents(mergeStudents(labRequest.getStudents(), imported.students()));
			labRequest.setSlots(mergeSlots(labRequest.getSlots(), imported.slots()));
		}
		return labRequest;
	}

	private LabUsageRequest readFormWithoutExcel(HttpServletRequest request) {
		LabUsageRequest labRequest = new LabUsageRequest();
		labRequest.setSemesterId(optionalId(request.getParameter("semesterId")));
		labRequest.setGroupName(trim(request.getParameter("groupName")));
		labRequest.setRequestNote(trim(request.getParameter("requestNote")));
		labRequest.setStudents(readManualStudents(request));
		labRequest.setSlots(readSelectedSlots(request));
		return labRequest;
	}

	private List<LabUsageRequestStudent> readManualStudents(HttpServletRequest request) {
		String[] codes = request.getParameterValues("studentCode");
		String[] names = request.getParameterValues("studentName");
		String[] emails = request.getParameterValues("studentEmail");
		int size = Math.max(length(codes), Math.max(length(names), length(emails)));
		List<LabUsageRequestStudent> students = new ArrayList<>();
		for (int index = 0; index < size; index++) {
			String code = valueAt(codes, index);
			String name = valueAt(names, index);
			String email = valueAt(emails, index).toLowerCase(Locale.ROOT);
			if (code.isBlank() && name.isBlank() && email.isBlank()) {
				continue;
			}
			LabUsageRequestStudent student = new LabUsageRequestStudent();
			student.setStudentCode(code);
			student.setFullName(name);
			student.setEmail(email);
			students.add(student);
		}
		return students;
	}

	private List<LabUsageRequestSlot> readSelectedSlots(HttpServletRequest request) {
		String[] selected = request.getParameterValues("slots");
		List<LabUsageRequestSlot> slots = new ArrayList<>();
		if (selected == null) {
			return slots;
		}
		for (String value : selected) {
			String[] parts = value.split("-");
			if (parts.length != 2) {
				continue;
			}
			try {
				LabUsageRequestSlot slot = new LabUsageRequestSlot();
				slot.setDayOfWeek(Integer.parseInt(parts[0]));
				slot.setSlotId(Integer.parseInt(parts[1]));
				slots.add(slot);
			} catch (NumberFormatException ignored) {
				// Validation below rejects an empty/invalid schedule.
			}
		}
		return mergeSlots(List.of(), slots);
	}

	private List<LabUsageRequestStudent> mergeStudents(List<LabUsageRequestStudent> first,
			List<LabUsageRequestStudent> second) {
		Map<String, LabUsageRequestStudent> merged = new LinkedHashMap<>();
		for (LabUsageRequestStudent student : first) {
			merged.put(student.getEmail().toLowerCase(Locale.ROOT), student);
		}
		for (LabUsageRequestStudent student : second) {
			student.setEmail(student.getEmail().toLowerCase(Locale.ROOT));
			merged.putIfAbsent(student.getEmail(), student);
		}
		return new ArrayList<>(merged.values());
	}

	private List<LabUsageRequestSlot> mergeSlots(List<LabUsageRequestSlot> first, List<LabUsageRequestSlot> second) {
		Map<String, LabUsageRequestSlot> merged = new LinkedHashMap<>();
		for (LabUsageRequestSlot slot : first) {
			merged.put(slot.getKey(), slot);
		}
		for (LabUsageRequestSlot slot : second) {
			merged.putIfAbsent(slot.getKey(), slot);
		}
		return new ArrayList<>(merged.values());
	}

	private List<String> validate(LabUsageRequest request) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (request.getSemesterId() == null || requestDAO.findOpenSemesters().stream()
				.noneMatch(s -> s.getSemesterId().equals(request.getSemesterId()))) {
			errors.add("Vui lòng chọn học kỳ đang hoạt động hoặc sắp diễn ra.");
		}
		if (request.getGroupName().isBlank() || request.getGroupName().length() > 100) {
			errors.add("Tên nhóm là bắt buộc và không được vượt quá 100 ký tự.");
		}
		if (request.getSlots().isEmpty()) {
			errors.add("Vui lòng chọn ít nhất một slot học.");
		}
		if (request.getStudents().isEmpty()) {
			errors.add("Vui lòng nhập hoặc import ít nhất một sinh viên.");
		}
		Set<String> codes = new LinkedHashSet<>();
		Set<String> emails = new LinkedHashSet<>();
		for (LabUsageRequestStudent student : request.getStudents()) {
			if (student.getStudentCode().isBlank() || student.getFullName().isBlank()
					|| !EMAIL.matcher(student.getEmail()).matches()) {
				errors.add("Mỗi sinh viên phải có mã, họ tên và email hợp lệ.");
				break;
			}
			if (!codes.add(student.getStudentCode().toUpperCase(Locale.ROOT)) || !emails.add(student.getEmail())) {
				errors.add("Mã sinh viên và email không được trùng trong cùng request.");
				break;
			}
		}
		for (LabUsageRequestSlot slot : request.getSlots()) {
			if (slot.getDayOfWeek() < 2 || slot.getDayOfWeek() > 7 || slot.getSlotId() < 1 || slot.getSlotId() > 4) {
				errors.add("Lịch học chứa thứ hoặc slot không hợp lệ.");
				break;
			}
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
		LabUsageRequest labRequest = (LabUsageRequest) request.getAttribute("labRequest");
		Set<String> selectedSlots = new LinkedHashSet<>();
		for (LabUsageRequestSlot slot : labRequest.getSlots()) {
			selectedSlots.add(slot.getKey());
		}
		request.setAttribute("selectedSlots", selectedSlots);
		request.setAttribute("semesters", requestDAO.findOpenSemesters());
		request.setAttribute("csrfToken", csrfToken(request));
	}

	private void downloadTemplate(HttpServletResponse response) throws IOException {
		response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		response.setHeader("Content-Disposition", "attachment; filename=lab-usage-request-template.xlsx");
		try (Workbook workbook = new XSSFWorkbook()) {
			Sheet students = workbook.createSheet("Students");
			Row studentHeader = students.createRow(0);
			studentHeader.createCell(0).setCellValue("Student Code");
			studentHeader.createCell(1).setCellValue("Full Name");
			studentHeader.createCell(2).setCellValue("Email");
			Sheet slots = workbook.createSheet("Slots");
			Row slotHeader = slots.createRow(0);
			slotHeader.createCell(0).setCellValue("Day Of Week");
			slotHeader.createCell(1).setCellValue("Slot Number");
			workbook.write(response.getOutputStream());
		}
	}

	private long mentorId(HttpServletRequest request) throws SQLException {
		return userDAO.findFirstActiveMentorId()
				.orElseThrow(() -> new SQLException("Chưa có tài khoản Mentor ACTIVE để sở hữu request."));
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

	private String databaseMessage(SQLException exception) {
		String message = exception.getMessage();
		if (message != null && (message.contains("Email ") || message.contains("mã sinh viên"))) {
			return message;
		}
		return "Không thể lưu request. Email hoặc mã sinh viên có thể đã tồn tại.";
	}

	private void handleDatabaseError(HttpServletResponse response, SQLException exception) throws IOException {
		getServletContext().log("Loading Lab Usage Requests failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải Lab Usage Requests.");
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
