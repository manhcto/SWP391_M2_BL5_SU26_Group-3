package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.common.EmailHelper;
import fpt.swp391.labtoolequip.dao.UserDAO;
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

@WebServlet({"/admin/users", "/admin/users/view", "/admin/users/add", "/admin/users/import",
		"/admin/users/toggle-status", "/admin/users/change-role"})
public class UserController extends HttpServlet {
	private static final Set<String> ROLES = Set.of("ADMIN", "LAB_MANAGER", "MENTOR", "STUDENT");
	private static final Set<String> STATUSES = Set.of("ACTIVE", "INACTIVE");
	private static final String LIST_VIEW = "/WEB-INF/views/admin/users/list.jsp";
	private static final String DETAIL_VIEW = "/WEB-INF/views/admin/users/detail.jsp";
	private static final String FORM_VIEW = "/WEB-INF/views/admin/users/form.jsp";

	private final UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			switch (request.getServletPath()) {
				case "/admin/users/view" -> showDetail(request, response);
				case "/admin/users/add" -> showAddForm(request, response);
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
			throws ServletException, IOException {
		User user = new User();
		user.setStatus("ACTIVE");
		user.setRole("STUDENT");
		request.setAttribute("user", user);
		request.setAttribute("formMode", "add");
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
		List<String> errors = validate(user, true, request.getParameter("password"));

		// Tự động sinh Email FPT nếu người dùng chưa nhập
		if (user.getEmail() == null || user.getEmail().isBlank()) {
			boolean isStudent = "STUDENT".equals(user.getRole());
			String autoEmail = EmailHelper.generateFptEmail(user.getFullName(), user.getStudentCode(), isStudent);
			user.setEmail(autoEmail);
		}

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

	private void importBatchUsers(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		String importData = request.getParameter("importData");
		String targetRoleParam = normalize(request.getParameter("targetRole"));
		String selectedRole = Set.of("STUDENT", "MENTOR", "LAB_MANAGER").contains(targetRoleParam)
				? targetRoleParam
				: "STUDENT";

		if (importData == null || importData.isBlank()) {
			request.setAttribute("errors", List.of("Vui lòng nhập dữ liệu cần import."));
			request.setAttribute("formMode", "import");
			request.getRequestDispatcher(FORM_VIEW).forward(request, response);
			return;
		}

		String[] lines = importData.split("\\r?\\n");
		List<User> batchList = new ArrayList<>();
		for (String line : lines) {
			String trimmed = line.trim();
			if (trimmed.isEmpty() || trimmed.startsWith("#"))
				continue;

			String[] tokens = trimmed.contains("\t") ? trimmed.split("\t") : trimmed.split("[,;]");
			if (tokens.length >= 1) {
				String fullName = tokens[0].trim();
				if (fullName.isEmpty())
					continue;

				String role = selectedRole;
				String email = "";
				String code = "";
				String major = "Software Engineering";
				String cohort = "K16";

				if ("STUDENT".equals(role)) {
					String col1 = tokens.length > 1 ? tokens[1].trim() : "";
					if (col1.contains("@")) {
						// Người dùng tải file 2 cột (Tên, Email) vào tab Sinh viên
						email = col1.toLowerCase();
						code = "";
						major = tokens.length > 2 ? tokens[2].trim() : "Software Engineering";
						cohort = tokens.length > 3 ? tokens[3].trim() : "K16";
					} else {
						code = col1;
						if (tokens.length > 2 && tokens[2].contains("@")) {
							email = tokens[2].trim().toLowerCase();
							major = tokens.length > 3 ? tokens[3].trim() : "Software Engineering";
							cohort = tokens.length > 4 ? tokens[4].trim() : "K16";
						} else {
							major = tokens.length > 2 ? tokens[2].trim() : "Software Engineering";
							cohort = tokens.length > 3 ? tokens[3].trim() : "K16";
							email = (tokens.length > 4 && tokens[4].contains("@"))
									? tokens[4].trim().toLowerCase()
									: EmailHelper.generateFptEmail(fullName, code, true);
						}
					}
					if (email.isEmpty()) {
						email = EmailHelper.generateFptEmail(fullName, code, true);
					}
				} else {
					// Thứ tự cột Mentor / Lab Manager: Họ và tên, Gmail (@fpt.edu.vn), Bộ môn /
					// Phòng phụ trách
					if (tokens.length > 1 && tokens[1].contains("@")) {
						email = tokens[1].trim().toLowerCase();
						major = tokens.length > 2 ? tokens[2].trim() : "";
					} else {
						major = tokens.length > 1 ? tokens[1].trim() : "";
						email = (tokens.length > 2 && tokens[2].contains("@"))
								? tokens[2].trim().toLowerCase()
								: EmailHelper.generateFptEmail(fullName, "", false);
					}
					if (email.isEmpty()) {
						email = EmailHelper.generateFptEmail(fullName, "", false);
					}
				}

				User u = new User();
				u.setFullName(fullName);
				u.setStudentCode("STUDENT".equals(role) && !code.isEmpty() ? code : null);
				u.setEmail(email);
				u.setMajor("STUDENT".equals(role) ? major : null);
				u.setCohort("STUDENT".equals(role) ? cohort : null);
				u.setRole(role);
				u.setStatus("ACTIVE");

				batchList.add(u);
			}
		}

		int imported = userDAO.batchCreate(batchList);
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
		user.setMajor(trim(request.getParameter("major")));
		user.setCohort(trim(request.getParameter("cohort")));
		return user;
	}

	private List<String> validate(User user, boolean isAdd, String rawPassword) {
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
		if ("STUDENT".equals(user.getRole()) && (user.getStudentCode() == null || user.getStudentCode().isEmpty())) {
			errors.add("Mã sinh viên là bắt buộc đối với sinh viên.");
		}
		return errors;
	}

	private void forwardWithErrors(HttpServletRequest request, HttpServletResponse response, User user,
			List<String> errors, String formMode) throws ServletException, IOException {
		request.setAttribute("user", user);
		request.setAttribute("errors", errors);
		request.setAttribute("formMode", formMode);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
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

	private String normalize(String value) {
		return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
	}
}
