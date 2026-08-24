package fpt.swp391.labtoolequip.controller.admin;

import fpt.swp391.labtoolequip.dao.MajorDAO;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.*;
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
	private final MajorDAO majorDAO = new MajorDAO();

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
		request.setAttribute("summary", userDAO.findSummary());

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
		Optional<User> activeLM = userDAO.findActiveLabManager();
		request.setAttribute("hasLabManager", activeLM.isPresent());
		request.setAttribute("currentLmName", activeLM.map(User::getFullName).orElse(""));
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
		request.setAttribute("majors", majorDAO.findActive());
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
		List<String> errors = validate(user, true);

		if (!errors.isEmpty()) {
			forwardWithErrors(request, response, user, errors, "add");
			return;
		}

		// Tự động cấp mật khẩu mặc định là 123 cho các tài khoản Cán bộ (Mentor, Lab
		// Manager, Admin)
		if (!"INTERN".equals(user.getRole())) {
			user.setPasswordHash(BCrypt.hashpw("123", BCrypt.gensalt()));
		}

		// Kiểm tra nếu tạo LAB_MANAGER mới khi đã có LAB_MANAGER cũ đang ACTIVE
		Optional<User> activeLM = ("LAB_MANAGER".equals(user.getRole()) && "ACTIVE".equals(user.getStatus()))
				? userDAO.findActiveLabManager()
				: Optional.empty();

		userDAO.create(user);

		if (activeLM.isPresent()) {
			String encodedName = java.net.URLEncoder.encode(activeLM.get().getFullName(),
					java.nio.charset.StandardCharsets.UTF_8);
			response.sendRedirect(request.getContextPath() + "/admin/users?success=lm_replaced&old_lm=" + encodedName);
		} else {
			response.sendRedirect(request.getContextPath() + "/admin/users?success=created");
		}
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

		String fullName = trim(request.getParameter("fullName"));
		String email = trim(request.getParameter("email"));
		String role = normalize(request.getParameter("role"));
		String status = normalize(request.getParameter("status"));
		String studentCode = trim(request.getParameter("studentCode"));
		Long majorId = optionalLong(request.getParameter("majorId"));
		String cohort = trim(request.getParameter("cohort"));

		// Quy tắc nghiệp vụ: INTERN và ADMIN không thể đổi sang vai trò khác
		if ("INTERN".equals(user.getRole()) || "ADMIN".equals(user.getRole())) {
			role = user.getRole();
		} else if ("MENTOR".equals(user.getRole()) || "LAB_MANAGER".equals(user.getRole())) {
			if (!"MENTOR".equals(role) && !"LAB_MANAGER".equals(role)) {
				role = user.getRole();
			}
		}

		user.setFullName(fullName);
		if (!email.isEmpty()) {
			user.setEmail(email);
		}
		user.setRole(role);
		user.setStatus(status);
		if ("INTERN".equals(user.getRole())) {
			user.setStudentCode(studentCode);
			user.setMajorId(majorId);
			user.setCohort(cohort);
		}

		List<String> errors = validate(user, false);
		if (!errors.isEmpty()) {
			forwardWithErrors(request, response, user, errors, "edit");
			return;
		}

		userDAO.update(user);
		response.sendRedirect(request.getContextPath() + "/admin/users?success=updated");
	}

	private void changeRole(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}

		String newRole = normalize(request.getParameter("role"));
		if ("LAB_MANAGER".equals(newRole)) {
			userDAO.appointLabManager(userId);
			response.sendRedirect(request.getContextPath() + "/admin/users?success=role_updated");
		} else if ("MENTOR".equals(newRole)) {
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

	private List<String> validate(User user, boolean isAdd) throws SQLException {
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

		// Mỗi tài khoản, gồm cả thực tập sinh, dùng một địa chỉ email hợp lệ và duy nhất.
		if (user.getEmail().isEmpty()) {
			errors.add("Email không được để trống.");
		} else if (!user.getEmail().contains("@") || !user.getEmail().contains(".")) {
			errors.add("Email không đúng định dạng hợp lệ.");
		} else {
			Optional<User> existingByEmail = userDAO.findByEmail(user.getEmail());
			if (existingByEmail.isPresent()) {
				if (isAdd || existingByEmail.get().getUserId() != user.getUserId()) {
					errors.add("Email này đã được sử dụng bởi người dùng khác.");
				}
			}
		}

		if ("INTERN".equals(user.getRole())) {
			if (user.getStudentCode() == null || user.getStudentCode().isEmpty()) {
				errors.add("Mã sinh viên là bắt buộc đối với thực tập sinh.");
			} else {
				Optional<User> existingStudent = userDAO.findByStudentCode(user.getStudentCode());
				if (existingStudent.isPresent()) {
					if (isAdd || existingStudent.get().getUserId() != user.getUserId()) {
						errors.add("Mã sinh viên này đã được sử dụng bởi người dùng khác.");
					}
				}
			}
			if (user.getMajorId() != null && !majorDAO.isActive(user.getMajorId())) {
				errors.add("Chuyên ngành không hợp lệ hoặc đã ngừng sử dụng.");
			}
		}

		return errors;
	}

	private void forwardWithErrors(HttpServletRequest request, HttpServletResponse response, User user,
			List<String> errors, String formMode) throws SQLException, ServletException, IOException {
		request.setAttribute("user", user);
		request.setAttribute("errors", errors);
		request.setAttribute("formMode", formMode);
		request.setAttribute("majors", majorDAO.findActive());
		Optional<User> activeLM = userDAO.findActiveLabManager();
		request.setAttribute("hasLabManager", activeLM.isPresent());
		request.setAttribute("currentLmName", activeLM.map(User::getFullName).orElse(""));
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

	private Long optionalLong(String value) {
		try {
			long parsed = Long.parseLong(trim(value));
			return parsed > 0 ? parsed : null;
		} catch (NumberFormatException exception) {
			return null;
		}
	}

	private String normalize(String value) {
		return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
	}
}
