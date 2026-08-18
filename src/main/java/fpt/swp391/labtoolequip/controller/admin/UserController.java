package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.common.EmailHelper;
import fpt.swp391.labtoolequip.dao.MajorDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.Major;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet({"/admin/users", "/admin/users/view", "/admin/users/add", "/admin/users/edit", "/admin/users/import",
		"/admin/users/toggle-status", "/admin/users/change-role"})
public class UserController extends HttpServlet {
	private static final Set<String> ROLES = Set.of("ADMIN", "LAB_MANAGER", "MENTOR", "INTERN");
	private static final Set<String> STATUSES = Set.of("ACTIVE", "INACTIVE");
	private static final String LIST_VIEW = "/WEB-INF/views/admin/users/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/admin/users/detail.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/admin/users/form.jsp";

	private final UserDAO userDAO = new UserDAO();
	private final MajorDAO majorDAO = new MajorDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (request.getServletPath()) {
				case "/admin/users/view" -> showDetail(request, response);
				case "/admin/users/add" -> showAddForm(request, response);
				case "/admin/users/edit" -> showEditForm(request, response);
				case "/admin/users/import" -> showImportForm(request, response);
				case "/admin/users/toggle-status" -> toggleStatus(request, response);
				case "/admin/users/change-role" -> changeRole(request, response);
				default -> showList(request, response);
			}
		} catch (SQLException exception) {
			handleDatabaseError(request, response, exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("UTF-8");
		try {
			switch (request.getServletPath()) {
				case "/admin/users/add" -> createUser(request, response);
				case "/admin/users/edit" -> updateUser(request, response);
				case "/admin/users/import" -> importBatchUsers(request, response);
				case "/admin/users/toggle-status" -> toggleStatus(request, response);
				default -> response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
			}
		} catch (SQLException exception) {
			getServletContext().log("Manage User failed", exception);
			request.setAttribute("databaseError",
					"Không thể lưu người dùng. Email hoặc mã sinh viên có thể đã tồn tại.");
			request.getRequestDispatcher(FORM_VIEW).forward(request, response);
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String keyword = trim(request.getParameter("keyword"));
		String role = normalize(request.getParameter("role"));
		String status = normalize(request.getParameter("status"));
		request.setAttribute("users", userDAO.findAll(keyword, role, status));
		request.setAttribute("keyword", keyword);
		request.setAttribute("selectedRole", role);
		request.setAttribute("selectedStatus", status);
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}

	private void showDetail(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		User user = userDAO.findById(userId).orElse(null);
		if (user == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("user", user);
		request.getRequestDispatcher(DETAIL_VIEW).forward(request, response);
	}

	private void showAddForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		User user = new User();
		user.setStatus("ACTIVE");
		user.setRole("INTERN");
		request.setAttribute("user", user);
		request.setAttribute("formMode", "add");
		request.setAttribute("majors", majorDAO.findActive());
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void showEditForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		User user = userDAO.findById(userId).orElse(null);
		if (user == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("user", user);
		request.setAttribute("formMode", "edit");
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void showImportForm(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setAttribute("formMode", "import");
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private void toggleStatus(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		userDAO.toggleStatus(userId);
		response.sendRedirect(request.getContextPath() + "/admin/users?success=status_updated");
	}

	private void createUser(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		User user = extractUser(request);
		if (user.getEmail().isBlank()) {
			user.setEmail(EmailHelper.generateFptEmail(user.getFullName(), user.getStudentCode(),
					"INTERN".equals(user.getRole())));
		}
		List<String> errors = validate(user);
		if (!errors.isEmpty()) {
			forwardWithErrors(request, response, user, errors, "add");
			return;
		}

		String rawPassword = trim(request.getParameter("password"));
		if (!rawPassword.isEmpty()) {
			user.setPasswordHash(BCrypt.hashpw(rawPassword, BCrypt.gensalt()));
		}
		userDAO.create(user);
		response.sendRedirect(request.getContextPath() + "/admin/users?success=created");
	}

	private void updateUser(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		User user = userDAO.findById(userId).orElse(null);
		if (user == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}

		String role = normalize(request.getParameter("role"));
		String status = normalize(request.getParameter("status"));
		if ("INTERN".equals(user.getRole()) || "ADMIN".equals(user.getRole())) {
			role = user.getRole();
		} else if (("MENTOR".equals(user.getRole()) || "LAB_MANAGER".equals(user.getRole()))
				&& !Set.of("MENTOR", "LAB_MANAGER").contains(role)) {
			role = user.getRole();
		}

		List<String> errors = new ArrayList<>();
		if (!ROLES.contains(role)) {
			errors.add("Vai trò không hợp lệ.");
		}
		if (!STATUSES.contains(status)) {
			errors.add("Trạng thái không hợp lệ.");
		}
		if (!errors.isEmpty()) {
			user.setRole(role);
			user.setStatus(status);
			forwardWithErrors(request, response, user, errors, "edit");
			return;
		}

		userDAO.updateRoleAndStatus(userId, role, status);
		response.sendRedirect(request.getContextPath() + "/admin/users?success=updated");
	}

	private void importBatchUsers(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String importData = request.getParameter("importData");
		String targetRole = normalize(request.getParameter("targetRole"));
		if (!Set.of("INTERN", "MENTOR", "LAB_MANAGER").contains(targetRole)) {
			targetRole = "INTERN";
		}
		if (importData == null || importData.isBlank()) {
			request.setAttribute("errors", List.of("Vui lòng nhập dữ liệu cần import."));
			request.setAttribute("formMode", "import");
			request.getRequestDispatcher(FORM_VIEW).forward(request, response);
			return;
		}

		List<Major> majors = majorDAO.findActive();
		List<User> users = new ArrayList<>();
		for (String line : importData.split("\\r?\\n")) {
			String[] values = line.trim().contains("\t") ? line.trim().split("\t") : line.trim().split("[,;]");
			if (line.isBlank() || line.trim().startsWith("#") || values.length == 0 || values[0].isBlank()) {
				continue;
			}
			String fullName = values[0].trim();
			String studentCode = "INTERN".equals(targetRole) && values.length > 1 ? values[1].trim() : "";
			String email = "";
			String major = "Software Engineering";
			String cohort = "K16";
			if ("INTERN".equals(targetRole)) {
				if (values.length > 2 && values[2].contains("@")) {
					email = values[2].trim().toLowerCase(Locale.ROOT);
					major = values.length > 3 ? values[3].trim() : major;
					cohort = values.length > 4 ? values[4].trim() : cohort;
				} else {
					major = values.length > 2 ? values[2].trim() : major;
					cohort = values.length > 3 ? values[3].trim() : cohort;
					email = values.length > 4 && values[4].contains("@")
							? values[4].trim().toLowerCase(Locale.ROOT)
							: EmailHelper.generateFptEmail(fullName, studentCode, true);
				}
			} else if (values.length > 1 && values[1].contains("@")) {
				email = values[1].trim().toLowerCase(Locale.ROOT);
			} else {
				email = values.length > 2 && values[2].contains("@")
						? values[2].trim().toLowerCase(Locale.ROOT)
						: EmailHelper.generateFptEmail(fullName, "", false);
			}

			User user = new User();
			user.setFullName(fullName);
			user.setStudentCode(studentCode.isEmpty() ? null : studentCode);
			user.setEmail(email);
			user.setMajorId("INTERN".equals(targetRole) ? matchingMajorId(majors, major) : null);
			user.setCohort("INTERN".equals(targetRole) ? cohort : null);
			user.setRole(targetRole);
			user.setStatus("ACTIVE");
			users.add(user);
		}

		int imported = userDAO.batchCreate(users);
		response.sendRedirect(request.getContextPath() + "/admin/users?success=imported&count=" + imported);
	}

	private void changeRole(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		String newRole = normalize(request.getParameter("role"));
		if ("MENTOR".equals(newRole) || "LAB_MANAGER".equals(newRole)) {
			userDAO.updateRole(userId, newRole);
			response.sendRedirect(request.getContextPath() + "/admin/users?success=role_updated");
		} else {
			response.sendRedirect(request.getContextPath() + "/admin/users");
		}
	}

	private User extractUser(HttpServletRequest request) {
		User user = new User();
		user.setFullName(trim(request.getParameter("fullName")));
		user.setEmail(trim(request.getParameter("email")));
		user.setRole(normalize(request.getParameter("role")));
		user.setStatus(normalize(request.getParameter("status")));
		user.setStudentCode(trim(request.getParameter("studentCode")));
		user.setMajorId(optionalLong(request.getParameter("majorId")));
		user.setCohort(trim(request.getParameter("cohort")));
		return user;
	}

	private List<String> validate(User user) throws SQLException {
		List<String> errors = new ArrayList<>();
		if (user.getFullName().isEmpty()) {
			errors.add("Họ và tên không được để trống.");
		}
		if (!ROLES.contains(user.getRole())) {
			errors.add("Vai trò không hợp lệ.");
		}
		if (!STATUSES.contains(user.getStatus())) {
			errors.add("Trạng thái không hợp lệ.");
		}
		if (user.getEmail().isEmpty()) {
			errors.add("Email không được để trống.");
		} else if ("INTERN".equals(user.getRole())) {
			if (!user.getEmail().toLowerCase(Locale.ROOT).endsWith("@fpt.edu.vn")) {
				errors.add("Email của thực tập sinh bắt buộc phải có đuôi @fpt.edu.vn.");
			}
		} else if (!user.getEmail().contains("@") || !user.getEmail().contains(".")) {
			errors.add("Email không đúng định dạng hợp lệ.");
		}
		if ("INTERN".equals(user.getRole()) && user.getStudentCode().isEmpty()) {
			errors.add("Mã sinh viên là bắt buộc đối với thực tập sinh.");
		}
		if ("INTERN".equals(user.getRole()) && user.getMajorId() != null && !majorDAO.isActive(user.getMajorId())) {
			errors.add("Chuyên ngành không hợp lệ hoặc đã ngừng sử dụng.");
		}
		return errors;
	}

	private void forwardWithErrors(HttpServletRequest request, HttpServletResponse response, User user,
			List<String> errors, String formMode) throws SQLException, ServletException, IOException {
		request.setAttribute("user", user);
		request.setAttribute("errors", errors);
		request.setAttribute("formMode", formMode);
		request.setAttribute("majors", majorDAO.findActive());
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private Long matchingMajorId(List<Major> majors, String value) {
		String major = trim(value);
		return majors.stream()
				.filter(candidate -> major.equalsIgnoreCase(candidate.getMajorCode())
						|| major.equalsIgnoreCase(candidate.getMajorName()))
				.map(Major::getMajorId).findFirst().orElse(null);
	}

	private long requireId(HttpServletRequest request, HttpServletResponse response) throws IOException {
		try {
			return Long.parseLong(request.getParameter("id"));
		} catch (NumberFormatException exception) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return -1;
		}
	}

	private void handleDatabaseError(HttpServletRequest request, HttpServletResponse response, SQLException exception)
			throws ServletException, IOException {
		getServletContext().log("Database error in UserController", exception);
		request.setAttribute("databaseError", "Lỗi truy vấn cơ sở dữ liệu: " + exception.getMessage());
		request.getRequestDispatcher(LIST_VIEW).forward(request, response);
	}

	private String trim(String value) {
		return value == null ? "" : value.trim();
	}

	private Long optionalLong(String value) {
		try {
			long parsed = Long.parseLong(trim(value));
			return parsed > 0 ? parsed : null;
		} catch (NumberFormatException exception) {
			return null;
		}
	}

	private String normalize(String value) {
		return trim(value).toUpperCase(Locale.ROOT);
	}
}
