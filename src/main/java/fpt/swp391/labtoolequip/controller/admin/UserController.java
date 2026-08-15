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

@WebServlet({"/admin/users", "/admin/users/view", "/admin/users/add", "/admin/users/edit"})
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
				case "/admin/users/edit" -> showEditForm(request, response);
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

	private void createUser(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		User user = readForm(request, null);
		String password = request.getParameter("password");
		List<String> errors = validate(user, password, true);
		if (!errors.isEmpty()) {
			forwardForm(request, response, user, "add", errors);
			return;
		}
		user.setPasswordHash(BCrypt.hashpw(password, BCrypt.gensalt()));
		long userId = userDAO.create(user);
		response.sendRedirect(request.getContextPath() + "/admin/users/view?id=" + userId + "&created=1");
	}

	private void updateUser(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		long userId = requireId(request, response);
		if (response.isCommitted()) {
			return;
		}
		User user = readForm(request, userId);
		String password = request.getParameter("password");
		List<String> errors = validate(user, password, false);
		if (!errors.isEmpty()) {
			forwardForm(request, response, user, "edit", errors);
			return;
		}
		if (password != null && !password.isBlank()) {
			user.setPasswordHash(BCrypt.hashpw(password, BCrypt.gensalt()));
		}
		if (!userDAO.update(user)) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		response.sendRedirect(request.getContextPath() + "/admin/users/view?id=" + userId + "&updated=1");
	}

	private User readForm(HttpServletRequest request, Long userId) {
		User user = new User();
		user.setUserId(userId);
		user.setFullName(trim(request.getParameter("fullName")));
		user.setEmail(trim(request.getParameter("email")).toLowerCase(Locale.ROOT));
		user.setRole(normalize(request.getParameter("role")));
		user.setStatus(normalize(request.getParameter("status")));
		user.setStudentCode(trim(request.getParameter("studentCode")));
		user.setMajor(trim(request.getParameter("major")));
		user.setCohort(trim(request.getParameter("cohort")));
		return user;
	}

	private List<String> validate(User user, String password, boolean creating) {
		List<String> errors = new ArrayList<>();
		if (user.getFullName().isBlank()) {
			errors.add("Full name is required.");
		}
		if (!user.getEmail().matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
			errors.add("A valid email is required.");
		}
		if (!ROLES.contains(user.getRole())) {
			errors.add("Role is invalid.");
		}
		if (!STATUSES.contains(user.getStatus())) {
			errors.add("Status is invalid.");
		}
		if (creating && (password == null || password.length() < 8)) {
			errors.add("Password must contain at least 8 characters.");
		}
		if (!creating && password != null && !password.isBlank() && password.length() < 8) {
			errors.add("New password must contain at least 8 characters.");
		}
		if ("STUDENT".equals(user.getRole()) && user.getStudentCode().isBlank()) {
			errors.add("Student code is required for the Student role.");
		}
		return errors;
	}

	private void forwardForm(HttpServletRequest request, HttpServletResponse response, User user, String mode,
			List<String> errors) throws ServletException, IOException {
		request.setAttribute("user", user);
		request.setAttribute("formMode", mode);
		request.setAttribute("errors", errors);
		request.getRequestDispatcher(FORM_VIEW).forward(request, response);
	}

	private long requireId(HttpServletRequest request, HttpServletResponse response) throws IOException {
		try {
			long id = Long.parseLong(request.getParameter("id"));
			if (id <= 0) {
				throw new NumberFormatException();
			}
			return id;
		} catch (NumberFormatException exception) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid user ID.");
			return 0;
		}
	}

	private void handleDatabaseError(HttpServletRequest request, HttpServletResponse response, SQLException exception)
			throws IOException {
		getServletContext().log("Loading users failed", exception);
		response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
				"Không thể tải dữ liệu người dùng từ database.");
	}

	private String trim(String value) {
		return value == null ? "" : value.trim();
	}

	private String normalize(String value) {
		return trim(value).toUpperCase(Locale.ROOT);
	}
}
