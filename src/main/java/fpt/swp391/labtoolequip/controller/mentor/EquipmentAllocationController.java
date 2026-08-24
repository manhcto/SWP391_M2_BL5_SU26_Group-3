package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.EquipmentAllocationDAO;
import fpt.swp391.labtoolequip.model.EquipmentActivity;
import fpt.swp391.labtoolequip.model.EquipmentAllocationRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

@WebServlet("/mentor/allocations/*")
public class EquipmentAllocationController extends HttpServlet {
    private final EquipmentAllocationDAO dao = new EquipmentAllocationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String path = request.getPathInfo();
            if ("/add".equals(path)) {
                showActivityForm(request, response, new EquipmentActivity(), "add");
                return;
            }
            if (path != null && path.matches("/\\d+/edit")) {
                long activityId = Long.parseLong(path.substring(1, path.indexOf('/', 1)));
                EquipmentActivity activity = dao.findActivity(activityId, AuthSession.userId(request));
                if (activity == null) { response.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
                showActivityForm(request, response, activity, "edit");
                return;
            }
            if (path != null && path.matches("/\\d+")) {
                showActivity(request, response, Long.parseLong(path.substring(1)));
                return;
            }
            String status = request.getParameter("status");
            long mentorId = AuthSession.userId(request);
            request.setAttribute("activities", dao.findActivitiesForMentor(mentorId, request.getParameter("keyword"), status, optionalDate(request.getParameter("fromDate")), optionalDate(request.getParameter("toDate"))));
            request.setAttribute("issues", dao.findIssuesForMentor(mentorId));
            request.setAttribute("selectedStatus", status);
            request.setAttribute("csrfToken", Csrf.token(request));
            request.getRequestDispatcher("/WEB-INF/views/mentor/allocations/list.jsp").forward(request, response);
        } catch (SQLException exception) {
            throw new ServletException(exception);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        if (!Csrf.valid(request)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        long mentorId = AuthSession.userId(request);
        String action = request.getParameter("action");
        String redirect = request.getContextPath() + "/mentor/allocations";
        try {
            switch (action) {
                case "createActivity" -> {
                    EquipmentActivity activity = new EquipmentActivity();
                    activity.setInternListId(id(request, "internListId"));
                    activity.setActivityName(request.getParameter("activityName"));
                    activity.setDescription(request.getParameter("description"));
                    activity.setStartDate(date(request, "startDate", "Vui lòng chọn ngày bắt đầu."));
                    activity.setEndDate(date(request, "endDate", "Vui lòng chọn ngày kết thúc."));
                    long activityId = dao.createActivityWithRequests(mentorId, activity, classRequestRows(request));
                    redirect += "/" + activityId;
                }
                case "updateActivity" -> {
                    EquipmentActivity activity = new EquipmentActivity();
                    activity.setActivityId(id(request, "activityId"));
                    activity.setInternListId(id(request, "internListId"));
                    activity.setActivityName(request.getParameter("activityName"));
                    activity.setDescription(request.getParameter("description"));
                    activity.setStartDate(date(request, "startDate", "Vui lòng chọn ngày bắt đầu."));
                    activity.setEndDate(date(request, "endDate", "Vui lòng chọn ngày kết thúc."));
                    dao.updateActivity(mentorId, activity);
                }
                case "reviewIssue" -> {
                    String decision = request.getParameter("decision");
                    if (!"VERIFIED".equals(decision) && !"REJECTED".equals(decision)) throw new IllegalArgumentException("Quyết định xử lý sự cố không hợp lệ.");
                    dao.reviewIssue(id(request, "issueId"), mentorId, "VERIFIED".equals(decision), request.getParameter("mentorNote"));
                }
                default -> { response.sendError(HttpServletResponse.SC_BAD_REQUEST); return; }
            }
            response.sendRedirect(redirect + "?success=1");
        } catch (IllegalArgumentException | SQLException exception) {
            if ("createActivity".equals(action)) redirect += "/add";
            response.sendRedirect(redirect + "?error=" + URLEncoder.encode(message(exception), StandardCharsets.UTF_8));
        }
    }

    private void showActivity(HttpServletRequest request, HttpServletResponse response, long activityId) throws SQLException, ServletException, IOException {
        EquipmentActivity activity = dao.findActivity(activityId, AuthSession.userId(request));
        if (activity == null) { response.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
        request.setAttribute("activity", activity);
        request.setAttribute("allocationRequests", dao.findRequestsForMentor(AuthSession.userId(request)));
        request.setAttribute("csrfToken", Csrf.token(request));
        request.getRequestDispatcher("/WEB-INF/views/mentor/allocations/detail.jsp").forward(request, response);
    }

    private void showActivityForm(HttpServletRequest request, HttpServletResponse response, EquipmentActivity activity, String formMode) throws SQLException, ServletException, IOException {
        request.setAttribute("activity", activity);
        request.setAttribute("formMode", formMode);
        request.setAttribute("internLists", dao.findApprovedInternLists(AuthSession.userId(request)));
        request.setAttribute("assets", dao.findRequestableAssets());
        request.setAttribute("csrfToken", Csrf.token(request));
        request.getRequestDispatcher("/WEB-INF/views/mentor/allocations/form.jsp").forward(request, response);
    }

    private long id(HttpServletRequest request, String name) {
        try { long value = Long.parseLong(request.getParameter(name)); if (value > 0) return value; }
        catch (NumberFormatException ignored) { }
        throw new IllegalArgumentException("Dữ liệu gửi lên không hợp lệ.");
    }

    private LocalDate date(HttpServletRequest request, String name, String errorMessage) {
        try { return LocalDate.parse(request.getParameter(name)); }
        catch (RuntimeException exception) { throw new IllegalArgumentException(errorMessage); }
    }

    private List<EquipmentAllocationRequest> classRequestRows(HttpServletRequest request) {
        String[] assetIds = request.getParameterValues("assetId");
        String[] quantities = request.getParameterValues("requestedQuantity");
        String[] notes = request.getParameterValues("note");
        if (assetIds == null || quantities == null || assetIds.length == 0 || assetIds.length != quantities.length) throw new IllegalArgumentException("Danh sách tài sản không hợp lệ.");
        List<EquipmentAllocationRequest> rows = new java.util.ArrayList<>();
        for (int index = 0; index < assetIds.length; index++) {
            EquipmentAllocationRequest row = new EquipmentAllocationRequest();
            try {
                long assetId = Long.parseLong(assetIds[index]);
                int quantity = Integer.parseInt(quantities[index]);
                if (assetId <= 0 || quantity <= 0) throw new NumberFormatException();
                row.setAssetId(assetId); row.setRequestedQuantity(quantity);
            } catch (NumberFormatException exception) { throw new IllegalArgumentException("Tài sản và số lượng phải hợp lệ."); }
            row.setNote(notes != null && index < notes.length ? notes[index] : null);
            rows.add(row);
        }
        return rows;
    }

    private LocalDate optionalDate(String value) {
        try { return value == null || value.isBlank() ? null : LocalDate.parse(value); }
        catch (RuntimeException exception) { return null; }
    }

    private String message(Exception exception) { return exception.getMessage() == null ? "Không thể thực hiện thao tác." : exception.getMessage(); }
}
