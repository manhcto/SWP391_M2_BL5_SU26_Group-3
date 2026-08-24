package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.dao.MaintenanceDAO;
import fpt.swp391.labtoolequip.dao.MaintenanceScheduleDAO;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
import fpt.swp391.labtoolequip.model.MaintenanceSchedule;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import util.CloudinaryUtil;

@WebServlet("/lab-manager/maintenance/*")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class LabManagerMaintenanceController extends HttpServlet {
	private final MaintenanceDAO dao = new MaintenanceDAO();
	private final MaintenanceScheduleDAO scheduleDAO = new MaintenanceScheduleDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();

			// ─── LỊCH BẢO TRÌ (SCHEDULES) ───
			if ("/schedules/template".equals(path)) {
				fpt.swp391.labtoolequip.common.MaintenanceScheduleExcelReader.downloadTemplate(response,
						scheduleDAO.getSampleAssetCodes(3));
				return;
			}

			if ("/schedules/new".equals(path)) {
				request.setAttribute("formMode", "create");
				request.setAttribute("schedulableAssets", scheduleDAO.findSchedulableAssets());
				forward(request, response, "schedule-form.jsp");
				return;
			}

			if (path != null && path.matches("/schedules/\\d+/edit")) {
				long id = Long.parseLong(path.substring("/schedules/".length(), path.lastIndexOf('/')));
				request.setAttribute("schedule", scheduleDAO.findById(id).orElseThrow());
				request.setAttribute("formMode", "edit");
				request.setAttribute("schedulableAssets", scheduleDAO.findSchedulableAssets());
				forward(request, response, "schedule-form.jsp");
				return;
			}

			// ─── PHIẾU BẢO TRÌ (TICKETS) ───
			// /lab-manager/maintenance/new -> Tạo phiếu bảo trì mới
			if ("/new".equals(path)) {
				showCreateForm(request, response);
				return;
			}

			// /lab-manager/maintenance/123/edit -> Cập nhật tiến độ / phê duyệt
			if (path != null && path.matches("/\\d+/edit")) {
				long id = Long.parseLong(path.substring(1, path.lastIndexOf('/')));
				MaintenanceRecord record = dao.findById(id).orElseThrow();
				request.setAttribute("record", record);
				request.setAttribute("formMode", "edit");
				request.setAttribute("pendingSchedules", scheduleDAO.findAll(null, "PENDING"));
				if (record.getScheduleId() != null) {
					scheduleDAO.findById(record.getScheduleId())
							.ifPresent(s -> request.setAttribute("linkedSchedule", s));
				}
				forward(request, response, "form.jsp");
				return;
			}

			// /lab-manager/maintenance/123 -> Chi tiết phiếu bảo trì
			if (path != null && path.matches("/\\d+")) {
				request.setAttribute("record", dao.findById(Long.parseLong(path.substring(1))).orElseThrow());
				forward(request, response, "detail.jsp");
				return;
			}

			// ─── TRANG DANH SÁCH CHÍNH (LIST / TABS) ───
			String tab = request.getParameter("tab");
			if (tab == null || tab.isBlank()) {
				tab = "tickets";
			}
			request.setAttribute("activeTab", tab);

			// Luôn nạp thông tin cảnh báo đến hạn cho Banner và Badge trên Tab
			request.setAttribute("dueSchedules", scheduleDAO.findDueSchedules(7));
			request.setAttribute("dueSchedulesCount", scheduleDAO.countDueSchedules(7));

			if ("schedules".equals(tab)) {
				request.setAttribute("schedules",
						scheduleDAO.findAll(request.getParameter("keyword"), request.getParameter("status")));
			} else {
				request.setAttribute("records",
						dao.findAll(request.getParameter("keyword"), request.getParameter("status")));
				request.setAttribute("summary", dao.findSummary());
			}

			request.setAttribute("keyword", request.getParameter("keyword"));
			request.setAttribute("selectedStatus", request.getParameter("status"));
			forward(request, response, "list.jsp");

		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String action = request.getParameter("action");
		try {
			long id;

			switch (action == null ? "" : action) {
				// ─── TICKET ACTIONS ───
				// Lab Manager tạo phiếu bảo trì (trực tiếp IN_PROGRESS)
				case "create" -> {
					String incidentParam = request.getParameter("incidentId");
					Long incidentId = (incidentParam == null || incidentParam.isBlank())
							? null
							: Long.parseLong(incidentParam);
					String assetItemParam = request.getParameter("assetItemId");
					Long assetItemId = (assetItemParam == null || assetItemParam.isBlank())
							? null
							: Long.parseLong(assetItemParam);
					String scheduleParam = request.getParameter("scheduleId");
					if (scheduleParam == null || scheduleParam.isBlank()) {
						scheduleParam = request.getParameter("linkedScheduleId");
					}
					Long scheduleId = (scheduleParam == null || scheduleParam.isBlank())
							? null
							: Long.parseLong(scheduleParam);
					Part imagePart = request.getPart("imageFile");
					String imageUrl = CloudinaryUtil.uploadImage(imagePart, "labtoolequip/maintenance");
					id = dao.create(AuthSession.userId(request), Long.parseLong(request.getParameter("assetId")),
							assetItemId, incidentId, scheduleId, request.getParameter("note"),
							request.getParameter("providerPhone"), request.getParameter("providerAddress"), imageUrl,
							request.getParameter("description"), parseCost(request.getParameter("estimatedCost")));
					response.sendRedirect(
							request.getContextPath() + "/lab-manager/maintenance/" + id + "?success=saved");
					return;
				}
				// Lab Manager cập nhật tiến độ sửa chữa
				case "updateProgress" -> {
					id = Long.parseLong(request.getParameter("id"));
					Part imagePart = request.getPart("imageFile");
					String imageUrl = CloudinaryUtil.uploadImage(imagePart, "labtoolequip/maintenance");
					String scheduleParam = request.getParameter("linkedScheduleId");
					Long linkedScheduleId = (scheduleParam == null || scheduleParam.isBlank())
							? null
							: Long.parseLong(scheduleParam);
					dao.updateProgress(id, request.getParameter("status"), request.getParameter("note"),
							request.getParameter("providerPhone"), request.getParameter("providerAddress"), imageUrl,
							request.getParameter("repairResult"), parseCost(request.getParameter("estimatedCost")),
							parseCost(request.getParameter("actualCost")), linkedScheduleId);
					response.sendRedirect(
							request.getContextPath() + "/lab-manager/maintenance/" + id + "?success=saved");
					return;
				}
				// Lab Manager xóa phiếu bảo trì (trả thiết bị về AVAILABLE)
				case "delete" -> {
					id = Long.parseLong(request.getParameter("id"));
					dao.delete(id);
					response.sendRedirect(request.getContextPath() + "/lab-manager/maintenance?success=deleted");
					return;
				}

				// ─── SCHEDULE ACTIONS ───
				case "createSchedule" -> {
					String assetTarget = request.getParameter("assetTarget");
					if (assetTarget == null || assetTarget.isBlank()) {
						throw new IllegalArgumentException("Vui lòng chọn thiết bị cần lên lịch.");
					}
					String[] parts = assetTarget.split(":", 2);
					long assetId = Long.parseLong(parts[0]);
					String itemCode = (parts.length > 1 && !parts[1].isBlank()) ? parts[1].trim() : null;

					MaintenanceSchedule s = new MaintenanceSchedule();
					s.setTitle(request.getParameter("title"));
					s.setAssetId(assetId);
					s.setItemCode(itemCode);
					String dateStr = request.getParameter("scheduledDate");
					s.setScheduledDate(dateStr != null && !dateStr.isBlank() ? LocalDate.parse(dateStr) : null);
					s.setEstimatedCost(parseCost(request.getParameter("estimatedCost")));
					s.setProviderName(request.getParameter("providerName"));
					s.setProviderPhone(request.getParameter("providerPhone"));
					s.setNote(request.getParameter("note"));
					s.setCreatedBy(AuthSession.userId(request));

					validateSchedule(s, null);
					scheduleDAO.create(s);
					response.sendRedirect(request.getContextPath()
							+ "/lab-manager/maintenance?tab=schedules&success=schedule_created");
					return;
				}
				case "updateSchedule" -> {
					long scheduleId = Long.parseLong(request.getParameter("scheduleId"));
					String assetTarget = request.getParameter("assetTarget");
					if (assetTarget == null || assetTarget.isBlank()) {
						throw new IllegalArgumentException("Vui lòng chọn thiết bị cần lên lịch.");
					}
					String[] parts = assetTarget.split(":", 2);
					long assetId = Long.parseLong(parts[0]);
					String itemCode = (parts.length > 1 && !parts[1].isBlank()) ? parts[1].trim() : null;

					MaintenanceSchedule s = new MaintenanceSchedule();
					s.setScheduleId(scheduleId);
					s.setTitle(request.getParameter("title"));
					s.setAssetId(assetId);
					s.setItemCode(itemCode);
					String dateStr = request.getParameter("scheduledDate");
					s.setScheduledDate(dateStr != null && !dateStr.isBlank() ? LocalDate.parse(dateStr) : null);
					s.setEstimatedCost(parseCost(request.getParameter("estimatedCost")));
					s.setProviderName(request.getParameter("providerName"));
					s.setProviderPhone(request.getParameter("providerPhone"));
					s.setNote(request.getParameter("note"));

					validateSchedule(s, scheduleId);
					scheduleDAO.update(s);
					response.sendRedirect(request.getContextPath()
							+ "/lab-manager/maintenance?tab=schedules&success=schedule_updated");
					return;
				}
				case "updateScheduleStatus" -> {
					long scheduleId = Long.parseLong(request.getParameter("scheduleId"));
					String status = request.getParameter("status");
					scheduleDAO.updateStatus(scheduleId, status);
					response.sendRedirect(
							request.getContextPath() + "/lab-manager/maintenance?tab=schedules&success=status_updated");
					return;
				}
				case "deleteSchedule" -> {
					long scheduleId = Long.parseLong(request.getParameter("scheduleId"));
					scheduleDAO.delete(scheduleId);
					response.sendRedirect(request.getContextPath()
							+ "/lab-manager/maintenance?tab=schedules&success=schedule_deleted");
					return;
				}
				case "batchCancelSchedules" -> {
					String[] ids = request.getParameterValues("selectedScheduleIds");
					if (ids != null && ids.length > 0) {
						List<Long> idList = java.util.Arrays.stream(ids).map(Long::parseLong).toList();
						scheduleDAO.batchUpdateStatus(idList, "CANCELLED");
					}
					response.sendRedirect(request.getContextPath()
							+ "/lab-manager/maintenance?tab=schedules&success=batch_cancelled");
					return;
				}
				case "batchDeleteSchedules" -> {
					String[] ids = request.getParameterValues("selectedScheduleIds");
					if (ids != null && ids.length > 0) {
						List<Long> idList = java.util.Arrays.stream(ids).map(Long::parseLong).toList();
						scheduleDAO.batchDelete(idList);
					}
					response.sendRedirect(
							request.getContextPath() + "/lab-manager/maintenance?tab=schedules&success=batch_deleted");
					return;
				}
				case "importSchedules" -> {
					Part excelPart = request.getPart("excelFile");
					var assetMap = scheduleDAO.getAssetCodeToIdMap();
					var existingKeys = scheduleDAO.getExistingScheduleKeys();
					var readResult = fpt.swp391.labtoolequip.common.MaintenanceScheduleExcelReader.read(excelPart,
							assetMap, existingKeys, AuthSession.userId(request));
					int count = scheduleDAO.createBatch(readResult.getSchedules());
					response.sendRedirect(
							request.getContextPath() + "/lab-manager/maintenance?tab=schedules&success=imported&count="
									+ count + "&skipped=" + readResult.getSkippedDuplicatesCount());
					return;
				}
				default -> {
					response.sendError(HttpServletResponse.SC_BAD_REQUEST);
					return;
				}
			}

		} catch (SQLException | IOException exception) {
			request.setAttribute("message", exception.getMessage());
			doGet(request, response);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			if ("createSchedule".equals(action) || "updateSchedule".equals(action)) {
				try {
					request.setAttribute("formMode", "createSchedule".equals(action) ? "create" : "edit");
					request.setAttribute("schedulableAssets", scheduleDAO.findSchedulableAssets());
					forward(request, response, "schedule-form.jsp");
					return;
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
			} else if ("create".equals(action)) {
				try {
					showCreateForm(request, response);
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
			} else {
				doGet(request, response);
			}
		}
	}

	private void validateSchedule(MaintenanceSchedule s, Long excludeId) throws SQLException {
		if (s.getTitle() == null || s.getTitle().isBlank()) {
			throw new IllegalArgumentException("Tiêu đề đợt bảo trì không được để trống.");
		}
		if (s.getTitle().trim().length() > 255) {
			throw new IllegalArgumentException("Tiêu đề đợt bảo trì không được vượt quá 255 ký tự.");
		}
		if (s.getScheduledDate() == null) {
			throw new IllegalArgumentException("Ngày dự kiến thực hiện không được để trống.");
		}
		if (s.getEstimatedCost() != null && (s.getEstimatedCost() < 0 || s.getEstimatedCost() > 1_000_000_000L)) {
			throw new IllegalArgumentException("Dự toán kinh phí phải từ 0 đến 1.000.000.000 VNĐ.");
		}
		if (s.getProviderPhone() != null && !s.getProviderPhone().isBlank()) {
			String phone = s.getProviderPhone().trim();
			if (!phone.matches("^(0|\\+84)[0-9.\\s-]{8,15}$")) {
				throw new IllegalArgumentException(
						"Số điện thoại kỹ thuật viên không hợp lệ (phải gồm 10-11 chữ số, bắt đầu bằng 0 hoặc +84).");
			}
			if (phone.length() > 20) {
				throw new IllegalArgumentException("Số điện thoại không được vượt quá 20 ký tự.");
			}
		}
		if (s.getProviderName() != null && s.getProviderName().trim().length() > 255) {
			throw new IllegalArgumentException("Tên đơn vị/kỹ thuật viên không được vượt quá 255 ký tự.");
		}
		if (s.getNote() != null && s.getNote().trim().length() > 1000) {
			throw new IllegalArgumentException("Ghi chú nội dung công việc không được vượt quá 1000 ký tự.");
		}
		if (scheduleDAO.isDuplicateSchedule(s.getAssetId(), s.getItemCode(), s.getScheduledDate(), excludeId)) {
			throw new IllegalArgumentException("Thiết bị này đã có lịch bảo trì vào ngày "
					+ ViewFormat.date(s.getScheduledDate()) + " trên hệ thống. Vui lòng chọn ngày khác.");
		}
	}

	private void showCreateForm(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("formMode", "create");
		request.setAttribute("routineAssets", dao.findRoutineMaintenanceAssets());
		request.setAttribute("incidents", dao.findOpenIncidents());
		request.setAttribute("pendingSchedules", scheduleDAO.findAll(null, "PENDING"));
		forward(request, response, "form.jsp");
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/maintenance/" + view).forward(request, response);
	}

	private Long parseCost(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			long cost = Long.parseLong(value.trim());
			if (cost < 0 || cost > 1_000_000_000L) {
				throw new IllegalArgumentException("Chi phí phải nằm trong khoảng từ 0 đến 1.000.000.000 VNĐ.");
			}
			return cost;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Chi phí không hợp lệ. Vui lòng chỉ nhập số nguyên.");
		}
	}
}
