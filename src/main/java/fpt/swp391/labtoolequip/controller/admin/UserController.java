package fpt.swp391.labtoolequip.controller.admin;

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

@WebServlet({"/admin/users", "/admin/users/view", "/admin/users/add", "/admin/users/edit", "/admin/users/toggle-status",
		"/admin/users/change-role"})
public class UserController extends HttpServlet {
	private static final Set<String> ROLES = Set.of("ADMIN", "LAB_MANAGER", "MENTOR", "INTERN");
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
				case "/admin/users/edit" -> showEditForm(request, response);
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
		user.setRole("INTERN");
		request.setAttribute("user", user);
		request.setAttribute("formMode", "add");
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
		String rawPassword = trim(request.getParameter("password"));

		List<String> errors = validate(user, true, rawPassword);

		if (!errors.isEmpty()) {
			forwardWithErrors(request, response, user, errors, "add");
			return;
		}

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

		// Quy tắc nghiệp vụ: INTERN và ADMIN không thể đổi sang vai trò khác
		if ("INTERN".equals(user.getRole()) || "ADMIN".equals(user.getRole())) {
			role = user.getRole();
		} else if ("MENTOR".equals(user.getRole()) || "LAB_MANAGER".equals(user.getRole())) {
			if (!"MENTOR".equals(role) && !"LAB_MANAGER".equals(role)) {
				role = user.getRole();
			}
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

		// Validate Email
		if (user.getEmail().isEmpty()) {
			errors.add("Email không được để trống.");
		} else {
			if ("INTERN".equals(user.getRole())) {
				if (!user.getEmail().toLowerCase().endsWith("@fpt.edu.vn")) {
					errors.add("Email của sinh viên thực tập (Intern) bắt buộc phải có định dạng @fpt.edu.vn.");
				}
			} else {
				// MENTOR / LAB_MANAGER / ADMIN: chấp nhận email thường (@gmail.com, v.v.)
				if (!user.getEmail().contains("@") || !user.getEmail().contains(".")) {
					errors.add("Email không đúng định dạng hợp lệ.");
				}
			}
		}

		if ("INTERN".equals(user.getRole()) && (user.getStudentCode() == null || user.getStudentCode().isEmpty())) {
			errors.add("Mã sinh viên là bắt buộc đối với sinh viên thực tập (Intern).");
		}

		// Validate Password khi tạo mới (Chỉ bắt buộc đối với Mentor và Lab Manager;
		// Intern đăng nhập qua Google OAuth)
		if (isAdd && !"INTERN".equals(user.getRole())) {
			if (rawPassword == null || rawPassword.trim().isEmpty()) {
				errors.add("Mật khẩu khởi tạo không được để trống đối với Giảng viên và Quản lý Lab.");
			} else if (rawPassword.trim().length() < 6) {
				errors.add("Mật khẩu phải có tối thiểu 6 ký tự.");
			}
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
