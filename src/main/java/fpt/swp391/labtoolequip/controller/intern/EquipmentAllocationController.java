package fpt.swp391.labtoolequip.controller.intern;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.EquipmentAllocationDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.SQLException;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@WebServlet("/intern/allocations/*")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 6 * 1024 * 1024)
public class EquipmentAllocationController extends HttpServlet {
    private static final Set<String> IMAGE_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp");
    private final EquipmentAllocationDAO dao = new EquipmentAllocationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            request.setAttribute("allocations", dao.findAllocationsForIntern(AuthSession.userId(request)));
            request.setAttribute("activities", dao.findActivitiesForIntern(AuthSession.userId(request)));
            request.setAttribute("csrfToken", Csrf.token(request));
            request.getRequestDispatcher("/WEB-INF/views/intern/allocations/list.jsp").forward(request, response);
        } catch (SQLException exception) { throw new ServletException(exception); }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        if (!Csrf.valid(request)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        try {
            long allocationId = id(request, "allocationId");
            if ("receive".equals(request.getParameter("action"))) dao.confirmReceipt(allocationId, AuthSession.userId(request));
            else if ("reportIssue".equals(request.getParameter("action"))) dao.reportIssue(allocationId, AuthSession.userId(request), request.getParameter("issueType"), request.getParameter("description"), saveImage(request));
            else { response.sendError(HttpServletResponse.SC_BAD_REQUEST); return; }
            response.sendRedirect(request.getContextPath() + "/intern/allocations?success=1");
        } catch (IllegalArgumentException | SQLException exception) {
            response.sendRedirect(request.getContextPath() + "/intern/allocations?error=" + URLEncoder.encode(exception.getMessage(), StandardCharsets.UTF_8));
        }
    }

    private String saveImage(HttpServletRequest request) throws IOException, ServletException {
        Part image = request.getPart("image");
        if (image == null || image.getSize() == 0) return null;
        String submittedName = Path.of(image.getSubmittedFileName()).getFileName().toString();
        int dot = submittedName.lastIndexOf('.');
        String extension = dot < 0 ? "" : submittedName.substring(dot + 1).toLowerCase(Locale.ROOT);
        if (!IMAGE_EXTENSIONS.contains(extension)) throw new IllegalArgumentException("Ảnh chỉ hỗ trợ JPG, PNG hoặc WEBP.");
        String filename = UUID.randomUUID() + "." + extension;
        Path directory = Path.of(getServletContext().getRealPath("/uploads/allocation-issues"));
        Files.createDirectories(directory);
        try (var input = image.getInputStream()) { Files.copy(input, directory.resolve(filename), StandardCopyOption.REPLACE_EXISTING); }
        return "/uploads/allocation-issues/" + filename;
    }

    private long id(HttpServletRequest request, String name) {
        try { long value = Long.parseLong(request.getParameter(name)); if (value > 0) return value; }
        catch (NumberFormatException ignored) { }
        throw new IllegalArgumentException("Dữ liệu gửi lên không hợp lệ.");
    }
}
