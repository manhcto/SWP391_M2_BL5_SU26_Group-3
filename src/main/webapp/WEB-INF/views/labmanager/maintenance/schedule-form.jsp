<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${formMode == 'edit' ? 'Chỉnh sửa lịch bảo trì' : 'Lên lịch bảo trì định kỳ'} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .form-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 24px; max-width: 800px; margin: 0 auto; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-top: 16px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group.full-width { grid-column: 1 / -1; }
        .form-group label { font-size: 13px; font-weight: 600; color: #374151; }
        .form-group label .required { color: #dc2626; }
        .form-control { width: 100%; padding: 9px 13px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; box-sizing: border-box; }
        .form-control:focus { outline: none; border-color: #2563eb; ring: 2px solid #93c5fd; }
        .form-actions { display: flex; justify-content: flex-end; gap: 12px; margin-top: 24px; padding-top: 18px; border-top: 1px solid #f3f4f6; }
    </style>
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>${formMode == 'edit' ? 'Chỉnh sửa lịch bảo trì' : 'Lên lịch bảo trì định kỳ mới'}</h1>
                    <p>Lập kế hoạch bảo dưỡng định kỳ để đảm bảo thiết bị phòng lab luôn hoạt động ổn định</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=schedules">
                    ← Quay lại danh sách lịch
                </a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message" style="margin-bottom: 20px;"><c:out value="${message}"/></div>
            </c:if>

            <div class="form-card">
                <div style="margin-bottom: 20px; border-bottom: 1px solid #f3f4f6; padding-bottom: 12px;">
                    <h3 style="margin: 0; font-size: 18px; color: #111827;">
                        ${formMode == 'edit' ? 'Cập nhật thông tin lịch bảo trì' : 'Thông tin kế hoạch bảo trì định kỳ'}
                    </h3>
                    <p style="margin: 4px 0 0 0; font-size: 13px; color: #6b7280;">
                        Điền đầy đủ thông tin thiết bị và ngày dự kiến thực hiện. Hệ thống sẽ tự động nhắc nhở khi đến hạn.
                    </p>
                </div>

                <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance">
                    <input type="hidden" name="action" value="${formMode == 'edit' ? 'updateSchedule' : 'createSchedule'}">
                    <c:if test="${formMode == 'edit'}">
                        <input type="hidden" name="scheduleId" value="${schedule.scheduleId}">
                    </c:if>

                    <div class="form-grid">
                        <div class="form-group full-width">
                            <label>Tiêu đề đợt bảo trì <span class="required">*</span></label>
                            <input class="form-control" type="text" name="title" required maxlength="255"
                                   value="<c:out value='${schedule.title}'/>"
                                   placeholder="Ví dụ: Vệ sinh quạt tản nhiệt và màng lọc bụi máy chiếu hè 2026">
                        </div>

                        <div class="form-group full-width">
                            <label>Thiết bị cần bảo trì <span class="required">*</span></label>
                            <select class="form-control" name="assetTarget" required>
                                <option value="">-- Chọn cá thể thiết bị trong phòng lab --</option>
                                <c:forEach var="a" items="${schedulableAssets}">
                                    <c:set var="targetVal" value="${a.assetId}:${not empty a.itemCode ? a.itemCode : ''}" />
                                    <c:set var="isSelected" value="${not empty schedule and schedule.assetId == a.assetId and (empty schedule.itemCode or empty a.itemCode or schedule.itemCode == a.itemCode)}" />
                                    <option value="${targetVal}" ${isSelected ? 'selected' : ''}>
                                        <c:out value="${a.assetName}"/> (<c:out value="${not empty a.itemCode ? a.itemCode : a.assetCode}"/>)
                                        <c:if test="${not empty a.storageLocation}">
                                            — Vị trí: <c:out value="${a.storageLocation}"/>
                                        </c:if>
                                    </option>
                                </c:forEach>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Ngày dự kiến thực hiện <span class="required">*</span></label>
                            <input class="form-control" type="date" name="scheduledDate" required
                                   value="${schedule.scheduledDate}">
                        </div>

                        <div class="form-group">
                            <label>Dự toán kinh phí (VNĐ) (Tùy chọn)</label>
                            <input class="form-control" type="number" name="estimatedCost" min="0" max="1000000000" step="1000"
                                   value="${schedule.estimatedCost}"
                                   placeholder="Ví dụ: 300000">
                        </div>

                        <div class="form-group">
                            <label>Đơn vị / Kỹ thuật viên dự kiến (Tùy chọn)</label>
                            <input class="form-control" type="text" name="providerName" maxlength="255"
                                   value="<c:out value='${schedule.providerName}'/>"
                                   placeholder="Ví dụ: FPT Service / KTV Tektronix">
                        </div>

                        <div class="form-group">
                            <label>SĐT liên hệ kỹ thuật viên (Tùy chọn)</label>
                            <input class="form-control" type="tel" name="providerPhone" maxlength="20"
                                   pattern="^(0|\+84)[0-9.\s-]{8,15}$"
                                   title="Số điện thoại hợp lệ bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số"
                                   value="<c:out value='${schedule.providerPhone}'/>"
                                   placeholder="Ví dụ: 0988.123.456">
                        </div>

                        <div class="form-group full-width">
                            <label>Ghi chú / Nội dung công việc cần kiểm tra (Tùy chọn)</label>
                            <textarea class="form-control" name="note" rows="3" maxlength="1000"
                                      placeholder="Ví dụ: Kiểm tra lại toàn bộ giắc cắm nguồn, thay keo tản nhiệt, vệ sinh quạt gió..."><c:out value="${schedule.note}"/></textarea>
                        </div>
                    </div>

                    <div class="form-actions">
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=schedules">
                            Hủy bỏ
                        </a>
                        <button class="primary-button" type="submit">
                            ${formMode == 'edit' ? 'Cập nhật lịch bảo trì' : 'Lưu lịch bảo trì'}
                        </button>
                    </div>
                </form>
            </div>
        </section>
    </main>
</div>
</body>
</html>
