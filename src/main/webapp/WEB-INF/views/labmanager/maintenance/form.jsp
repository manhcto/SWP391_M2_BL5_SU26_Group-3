<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
                <!DOCTYPE html>
                <html lang="vi">

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ bảo trì #MNT-${record.maintenanceId}
                            </c:when>
                            <c:otherwise>Tạo phiếu bảo trì</c:otherwise>
                        </c:choose> | LAB Asset
                    </title>
                    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
                </head>

                <body class="lab-manager-page">
                    <c:set var="activeMenu" value="maintenance" scope="request" />
                    <div class="app-shell">
                        <%@ include file="../includes/sidebar.jspf" %>

                            <main class="main-content">
                                <header class="topbar">
                                    <div class="heading-wrap">
                                        <button class="menu-button" id="menuButton" type="button"
                                            aria-label="Mở thanh điều hướng"><svg>
                                                <use href="#i-menu" />
                                            </svg></button>
                                        <div>
                                            <h1>
                                                <c:choose>
                                                    <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa
                                                        #MNT-${record.maintenanceId}</c:when>
                                                    <c:otherwise>Tạo phiếu bảo trì thiết bị</c:otherwise>
                                                </c:choose>
                                            </h1>
                                            <p>
                                                <c:choose>
                                                    <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa, điều
                                                        chỉnh kinh phí và ghi nhận kết quả nghiệm thu</c:when>
                                                    <c:otherwise>Lập phiếu bảo trì, dự toán kinh phí và đưa thiết bị đi
                                                        sửa
                                                        chữa</c:otherwise>
                                                </c:choose>
                                            </p>
                                        </div>
                                    </div>
                                    <div class="topbar-actions">
                                        <a class="btn-secondary"
                                            href="${pageContext.request.contextPath}/lab-manager/maintenance">‹ Quay lại
                                            danh sách</a>
                                    </div>
                                </header>

                                <section class="content-area">
                                    <c:if test="${not empty message}">
                                        <div class="error-message">
                                            <c:out value="${message}" />
                                        </div>
                                    </c:if>

                                    <article class="panel">
                                        <c:choose>
                                            <%-- CHẾ ĐỘ 1: CẬP NHẬT TIẾN ĐỘ & KẾT QUẢ SỬA CHỮA --%>
                                                <c:when test="${formMode == 'edit'}">
                                                    <form method="post"
                                                        action="${pageContext.request.contextPath}/lab-manager/maintenance?csrfToken=${sessionScope.csrfToken}"
                                                        enctype="multipart/form-data" class="form-grid">
                                                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                        <input type="hidden" name="action" value="updateProgress">
                                                        <input type="hidden" name="id" value="${record.maintenanceId}">

                                                        <div class="form-group">
                                                            <label>Thiết bị cần bảo trì</label>
                                                            <input class="form-control" type="text"
                                                                value="<c:out value='${record.assetName}'/> (<c:out value='${not empty record.assetItemCode ? record.assetItemCode : record.assetCode}'/>)"
                                                                readonly
                                                                style="background:#f8fafc; color:#334155; font-weight:550; cursor:not-allowed; border-color:#d1d5db;">
                                                        </div>

                                                        <div class="form-group">
                                                            <label>Sự cố liên quan</label>
                                                            <input class="form-control" type="text"
                                                                value="<c:choose><c:when test='${not empty record.incidentId}'>#INC-${record.incidentId}: <c:out value='${record.incidentDescription}'/></c:when><c:otherwise>Không có (Bảo dưỡng định kỳ / Trực tiếp)</c:otherwise></c:choose>"
                                                                readonly
                                                                style="background:#f8fafc; color:#334155; font-weight:550; cursor:not-allowed; border-color:#d1d5db;">
                                                        </div>

                                                        <div class="form-group full-width">
                                                            <label>Trạng thái tiến độ *</label>
                                                            <select class="form-control" name="status"
                                                                id="progressStatusSelect" required>
                                                                <c:if test="${record.status == 'APPROVED'}">
                                                                    <option value="IN_PROGRESS">Bắt đầu bảo trì</option>
                                                                </c:if>
                                                                <c:if test="${record.status == 'IN_PROGRESS'}">
                                                                    <option value="IN_PROGRESS" selected>Đang sửa chữa (Cập nhật thông tin / chi phí / thợ sửa)</option>
                                                                    <option value="COMPLETED_SUCCESS">Đã sửa xong – Hoàn tất thành công (Thiết bị về Sẵn sàng AVAILABLE)</option>
                                                                    <option value="COMPLETED_FAILED">Sửa thất bại – Thiết bị về hàng chờ quyết định tiếp theo</option>
                                                                </c:if>
                                                            </select>
                                                        </div>

                                                        <c:set var="editMatchedSched" value="${null}" />
                                                        <c:forEach var="ps" items="${pendingSchedules}">
                                                            <c:if
                                                                test="${empty editMatchedSched and ps.assetId == record.assetId and (empty ps.itemCode or empty record.assetItemCode or ps.itemCode == record.assetItemCode)}">
                                                                <c:set var="editMatchedSched" value="${ps}" />
                                                            </c:if>
                                                        </c:forEach>

                                                        <c:if
                                                            test="${not empty linkedSchedule or not empty record.scheduleId}">
                                                            <div class="form-group full-width"
                                                                style="padding: 12px 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;">
                                                                <div
                                                                    style="font-size: 13px; color: #166534; font-weight: 600;">
                                                                    💡 Phiếu bảo trì này đã liên kết với lịch: <strong>
                                                                        <c:out
                                                                            value="${not empty linkedSchedule ? linkedSchedule.title : 'Lịch bảo dưỡng định kỳ'}" />
                                                                    </strong>
                                                                    <c:if
                                                                        test="${not empty linkedSchedule and not empty linkedSchedule.scheduledDate}">
                                                                        (ngày ${linkedSchedule.scheduledDate})</c:if>.
                                                                    Khi bạn lưu trạng thái "Đã sửa xong", lịch sẽ tự
                                                                    động được đánh dấu là Đã hoàn tất.
                                                                </div>
                                                            </div>
                                                        </c:if>

                                                        <c:if
                                                            test="${empty record.scheduleId and not empty editMatchedSched}">
                                                            <div class="form-group full-width"
                                                                style="padding: 12px 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;">
                                                                <div
                                                                    style="font-size: 13px; color: #166534; font-weight: 600; margin-bottom: 6px;">
                                                                    💡 Thiết bị này đang có lịch bảo dưỡng định kỳ vào
                                                                    ngày
                                                                    <strong>${editMatchedSched.scheduledDate}</strong>:
                                                                    <em>
                                                                        <c:out value="${editMatchedSched.title}" />
                                                                    </em>
                                                                </div>
                                                                <label
                                                                    style="display: flex; align-items: center; gap: 8px; font-size: 13px; color: #15803d; cursor: pointer; font-weight: 500; margin: 0;">
                                                                    <input type="checkbox" name="linkedScheduleId"
                                                                        id="editLinkedScheduleCheckbox"
                                                                        value="${editMatchedSched.scheduleId}"
                                                                        style="width: 16px; height: 16px; accent-color: #16a34a; cursor: pointer;">
                                                                    <span>Đồng thời hoàn tất lịch bảo trì định kỳ này
                                                                        sau khi sửa chữa xong</span>
                                                                </label>
                                                                <c:if
                                                                    test="${not empty editMatchedSched and not empty editMatchedSched.estimatedCost and editMatchedSched.estimatedCost > 0}">
                                                                    <div id="editCostScheduleHint"
                                                                        style="display: none; margin-top: 6px; font-size: 12px; color: #166534; line-height: 1.4;">
                                                                        💡 Dự toán kế hoạch định kỳ là
                                                                        <strong>${editMatchedSched.estimatedCost}
                                                                            VNĐ</strong>. Hãy nhập Tổng chi phí (bao gồm
                                                                        cả tiền sửa sự cố).
                                                                    </div>
                                                                </c:if>
                                                            </div>
                                                        </c:if>

                                                        <div class="form-group">
                                                            <label>Dự toán kinh phí (VNĐ)</label>
                                                            <input class="form-control" type="number"
                                                                name="estimatedCost" min="0" max="1000000000"
                                                                step="1000"
                                                                value="<c:out value='${record.estimatedCost}'/>"
                                                                placeholder="Nhập dự toán kinh phí nếu có (VNĐ)">
                                                        </div>

                                                        <div class="form-group">
                                                            <label id="providerLabel">Đơn vị / Kỹ thuật viên sửa
                                                                chữa</label>
                                                            <input class="form-control" type="text" name="note"
                                                                id="providerInput" maxlength="255"
                                                                value="<c:out value='${record.note}'/>"
                                                                placeholder="Ví dụ: Kỹ thuật viên Tektronix VN / FPT Services">
                                                        </div>

                                                        <div class="form-group">
                                                            <label>SĐT đơn vị / kỹ thuật viên (Tùy chọn)</label>
                                                            <input class="form-control" type="tel" name="providerPhone"
                                                                maxlength="20" pattern="^(0|\+84)[0-9.\s-]{8,15}$"
                                                                title="Số điện thoại hợp lệ bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số"
                                                                value="<c:out value='${record.providerPhone}'/>"
                                                                placeholder="Ví dụ: 0988.123.456">
                                                        </div>

                                                        <div class="form-group full-width">
                                                            <label>Địa chỉ đơn vị sửa chữa (Tùy chọn)</label>
                                                            <input class="form-control" type="text"
                                                                name="providerAddress" maxlength="255"
                                                                value="<c:out value='${record.providerAddress}'/>"
                                                                placeholder="Ví dụ: 123 Cầu Giấy, Hà Nội hoặc Phòng Kỹ thuật Tòa Alpha">
                                                        </div>

                                                        <div class="form-group full-width">
                                                            <label>Ảnh đính kèm</label>
                                                            <input class="form-control" type="file" name="imageFile"
                                                                accept="image/*" id="editImageFile">
                                                            <small
                                                                style="color: #64748b; font-size: 12px; margin-top: 4px; display: block;">Hỗ
                                                                trợ ảnh PNG, JPG, JPEG, WEBP (Tối đa 10MB). Tự động tối
                                                                ưu hóa lưu trên Cloudinary.</small>
                                                            <c:if test="${not empty record.imageUrl}">
                                                                <div
                                                                    style="margin-top: 8px; display: flex; align-items: center; gap: 12px;">
                                                                    <img src="<c:out value='${record.imageUrl}'/>"
                                                                        alt="Ảnh hiện tại"
                                                                        style="max-height: 80px; border-radius: 6px; border: 1px solid #cbd5e1; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                                                                    <span style="font-size: 13px; color: #475569;">Ảnh
                                                                        đã lưu trước đó (Chọn file mới nếu muốn thay
                                                                        thế).</span>
                                                                </div>
                                                            </c:if>
                                                        </div>

                                                        <div class="form-group full-width" id="actualCostField"
                                                            style="display: none; grid-column: span 2;">
                                                            <label style="font-weight: 650; margin-bottom: 4px;">Chi phí
                                                                thực tế (VNĐ) *</label>
                                                            <input class="form-control" type="number" name="actualCost"
                                                                id="actualCostInput" min="0" max="1000000000"
                                                                step="1000"
                                                                value="<c:out value='${record.actualCost}'/>"
                                                                placeholder="Nhập số tiền thực tế đã thanh toán (VNĐ)">
                                                        </div>

                                                        <div class="form-group full-width" id="repairResultField"
                                                            style="display: none; grid-column: span 2;">
                                                            <label style="font-weight: 650; margin-bottom: 4px;">Kết quả
                                                                sửa
                                                                chữa / Linh kiện thay thế *</label>
                                                            <textarea class="form-control" name="repairResult"
                                                                id="repairResultInput" rows="4" maxlength="1000"
                                                                style="width: 100%; min-height: 90px; box-sizing: border-box;"
                                                                placeholder="Ví dụ: Đã thay thế vòi phun extruder và cân chỉnh nhiệt độ bàn in. Thiết bị hoạt động hoàn hảo."><c:out value="${record.repairResult}"/></textarea>
                                                        </div>

                                                        <div
                                                            style="display: flex; flex-direction: row; gap: 10px; margin-top: 10px; grid-column: span 2;">
                                                            <button class="primary-button" type="submit"
                                                                style="width: auto; padding: 8px 24px;">Lưu tiến độ bảo
                                                                trì</button>
                                                            <a class="btn-secondary"
                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance"
                                                                style="width: auto; padding: 8px 20px;">Hủy</a>
                                                        </div>
                                                    </form>

                                                    <script>
                                                        document.addEventListener('DOMContentLoaded', function () {
                                                            const progressStatusSelect = document.getElementById('progressStatusSelect');
                                                            const providerLabel = document.getElementById('providerLabel');
                                                            const providerInput = document.getElementById('providerInput');
                                                            const repairResultField = document.getElementById('repairResultField');
                                                            const repairResultInput = document.getElementById('repairResultInput');
                                                            const actualCostField = document.getElementById('actualCostField');
                                                            const actualCostInput = document.getElementById('actualCostInput');
                                                            if (progressStatusSelect) {
                                                                function toggleCompletionFields() {
                                                                    const val = progressStatusSelect.value;
                                                                    const isCompleted = (val === 'COMPLETED_SUCCESS' || val === 'COMPLETED_FAILED');
                                                                    if (providerInput) {
                                                                        providerInput.required = isCompleted;
                                                                    }
                                                                    if (providerLabel) {
                                                                        providerLabel.textContent = isCompleted ? 'Đơn vị / Kỹ thuật viên sửa chữa *' : 'Đơn vị / Kỹ thuật viên sửa chữa';
                                                                    }
                                                                    if (repairResultField) {
                                                                        repairResultField.style.display = isCompleted ? 'flex' : 'none';
                                                                    }
                                                                    if (repairResultInput) {
                                                                        repairResultInput.required = isCompleted;
                                                                    }
                                                                    if (actualCostField) {
                                                                        actualCostField.style.display = isCompleted ? 'flex' : 'none';
                                                                    }
                                                                    if (actualCostInput) {
                                                                        actualCostInput.required = isCompleted;
                                                                    }
                                                                }
                                                                progressStatusSelect.addEventListener('change', toggleCompletionFields);
                                                                toggleCompletionFields();
                                                            }

                                                            const editLinkedCheckbox = document.getElementById('editLinkedScheduleCheckbox');
                                                            const editCostHint = document.getElementById('editCostScheduleHint');
                                                            if (editLinkedCheckbox && editCostHint) {
                                                                editLinkedCheckbox.addEventListener('change', function () {
                                                                    editCostHint.style.display = this.checked ? 'block' : 'none';
                                                                });
                                                            }
                                                        });
                                                    </script>
                                                </c:when>

                                                <%-- CHẾ ĐỘ 2: TẠO MỚI PHIẾU BẢO TRÌ (TRỰC TIẾP APPROVED) --%>
                                                    <c:otherwise>
                                                        <form method="post"
                                                            action="${pageContext.request.contextPath}/lab-manager/maintenance?csrfToken=${sessionScope.csrfToken}"
                                                            enctype="multipart/form-data" class="form-grid">
                                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                            <input type="hidden" name="action" value="create">

                                                            <div class="form-group full-width">
                                                                <label>Thiết bị cần bảo trì *</label>
                                                                <select class="form-control" name="assetId"
                                                                    id="assetSelect" required>
                                                                    <option value="">-- Chọn thiết bị --</option>
                                                                    <c:if test="${not empty incidents}">
                                                                        <optgroup label="Sự cố đang xử lý">
                                                                            <c:forEach var="inc" items="${incidents}">
                                                                                <c:set var="matchedSched"
                                                                                    value="${null}" />
                                                                                <c:forEach var="ps"
                                                                                    items="${pendingSchedules}">
                                                                                    <c:if
                                                                                        test="${empty matchedSched and ps.assetId == inc.assetId and (empty ps.itemCode or empty inc.assetItemCode or ps.itemCode == inc.assetItemCode)}">
                                                                                        <c:set var="matchedSched"
                                                                                            value="${ps}" />
                                                                                    </c:if>
                                                                                </c:forEach>
                                                                                <option value="${inc.assetId}"
                                                                                    data-incident-id="${inc.incidentId}"
                                                                                    data-asset-item-id="${inc.assetItemId}"
                                                                                    data-schedule-id="${matchedSched.scheduleId}"
                                                                                    data-schedule-title="<c:out value='${matchedSched.title}'/>"
                                                                                    data-schedule-date="${matchedSched.scheduledDate}"
                                                                                    data-schedule-cost="${matchedSched.estimatedCost}"
                                                                                    data-schedule-provider="<c:out value='${matchedSched.providerName}'/>"
                                                                                    data-schedule-phone="<c:out value='${matchedSched.providerPhone}'/>">
                                                                                    #INC-
                                                                                    <c:out value="${inc.incidentId}" />
                                                                                    ·
                                                                                    <c:out value="${inc.assetName}" /> (
                                                                                    <c:out
                                                                                        value="${not empty inc.assetItemCode ? inc.assetItemCode : inc.assetCode}" />
                                                                                    ) —
                                                                                    <c:out value="${inc.description}" />
                                                                                </option>
                                                                            </c:forEach>
                                                                        </optgroup>
                                                                    </c:if>
                                                                    <c:if test="${not empty routineAssets}">
                                                                        <optgroup
                                                                            label="Bảo trì định kỳ / tài sản còn lại">
                                                                            <c:forEach var="a" items="${routineAssets}">
                                                                                <c:set var="matchedSched"
                                                                                    value="${null}" />
                                                                                <c:forEach var="ps"
                                                                                    items="${pendingSchedules}">
                                                                                    <c:if
                                                                                        test="${empty matchedSched and ps.assetId == a.assetId and (empty ps.itemCode or empty a.itemCode or ps.itemCode == a.itemCode)}">
                                                                                        <c:set var="matchedSched"
                                                                                            value="${ps}" />
                                                                                    </c:if>
                                                                                </c:forEach>
                                                                                <option value="${a.assetId}"
                                                                                    data-incident-id=""
                                                                                    data-asset-item-id="${a.assetItemId}"
                                                                                    data-schedule-id="${matchedSched.scheduleId}"
                                                                                    data-schedule-title="<c:out value='${matchedSched.title}'/>"
                                                                                    data-schedule-date="${matchedSched.scheduledDate}"
                                                                                    data-schedule-cost="${matchedSched.estimatedCost}"
                                                                                    data-schedule-provider="<c:out value='${matchedSched.providerName}'/>"
                                                                                    data-schedule-phone="<c:out value='${matchedSched.providerPhone}'/>"
                                                                                    ${(a.status=='IN_USE' or a.status=='UNAVAILABLE')
                                                                                    ? 'disabled style="color:#94a3b8;background:#f8fafc;"'
                                                                                    : '' } ${(not empty param.itemCode
                                                                                    and param.itemCode==a.itemCode) or
                                                                                    (empty param.itemCode and
                                                                                    param.assetId==a.assetId)
                                                                                    ? 'selected' : '' }>
                                                                                    <c:out value="${a.assetName}" /> (
                                                                                    <c:out
                                                                                        value="${not empty a.itemCode ? a.itemCode : a.assetCode}" />
                                                                                    )
                                                                                    <c:choose>
                                                                                        <c:when
                                                                                            test="${a.status == 'IN_USE'}">
                                                                                            — [Đang được mượn sử dụng -
                                                                                            Không thể chọn]</c:when>
                                                                                        <c:when
                                                                                            test="${a.status == 'UNAVAILABLE'}">
                                                                                            — [Không khả dụng, đang ở hàng chờ -
                                                                                            Không thể chọn]</c:when>
                                                                                        <c:when
                                                                                            test="${not empty a.storageLocation}">
                                                                                            –
                                                                                            <c:out
                                                                                                value="${a.storageLocation}" />
                                                                                        </c:when>
                                                                                    </c:choose>
                                                                                </option>
                                                                            </c:forEach>
                                                                        </optgroup>
                                                                    </c:if>
                                                                </select>
                                                                <small id="maintenanceTargetNotice"
                                                                    style="display:block;margin-top:4px;font-size:12px;color:#5a6662;">Chọn
                                                                    sự cố để sửa chữa, hoặc chọn tài sản còn lại cho bảo
                                                                    trì
                                                                    định kỳ.</small>

                                                                <%-- Hộp nhắc nhở: Tự động liên kết khi chọn Bảo trì
                                                                    định kỳ (không cần checkbox) --%>
                                                                    <div id="routineScheduleNoticeBox"
                                                                        style="display: none; margin-top: 10px; padding: 12px 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;">
                                                                        <div
                                                                            style="font-size: 13px; color: #166534; font-weight: 600;">
                                                                            💡 Phiếu bảo trì này được liên kết với kế
                                                                            hoạch: <strong
                                                                                id="routineScheduleTitleText"></strong>
                                                                            (ngày <span id="routineScheduleDateText"
                                                                                style="color: #15803d; font-weight: 700;"></span>)
                                                                            và sẽ tự động hoàn tất lịch khi bảo dưỡng
                                                                            xong.
                                                                        </div>
                                                                    </div>

                                                                    <%-- Hộp nhắc nhở: Ô tích chọn tùy chọn khi chọn Sự
                                                                        cố (#INC) --%>
                                                                        <div id="incidentScheduleReminderBox"
                                                                            style="display: none; margin-top: 10px; padding: 12px 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;">
                                                                            <div
                                                                                style="font-size: 13px; color: #166534; font-weight: 600; margin-bottom: 6px;">
                                                                                💡 Thiết bị này đang có lịch bảo dưỡng
                                                                                định kỳ vào ngày <span
                                                                                    id="incidentReminderDateText"
                                                                                    style="color: #15803d; font-weight: 700;"></span>:
                                                                                <span id="incidentReminderTitleText"
                                                                                    style="color: #14532d; font-weight: 600;"></span>
                                                                            </div>
                                                                            <label
                                                                                style="display: flex; align-items: center; gap: 8px; font-size: 13px; color: #1e293b; cursor: pointer; font-weight: 500; user-select: none;">
                                                                                <input type="checkbox"
                                                                                    name="linkedScheduleId"
                                                                                    id="incidentLinkedScheduleCheckbox"
                                                                                    value=""
                                                                                    style="width: 16px; height: 16px; cursor: pointer; accent-color: #16a34a;">
                                                                                <span>Đồng thời hoàn tất lịch bảo trì
                                                                                    định kỳ này sau khi sửa chữa
                                                                                    xong</span>
                                                                            </label>
                                                                        </div>
                                                            </div>
                                                            <input type="hidden" name="incidentId" id="incidentId">
                                                            <input type="hidden" name="assetItemId" id="assetItemId">
                                                            <input type="hidden" name="scheduleId" id="scheduleIdInput">

                                                            <div class="form-group">
                                                                <label>Dự toán kinh phí sửa chữa (VNĐ)</label>
                                                                <input class="form-control" type="number"
                                                                    id="createEstimatedCostInput" name="estimatedCost"
                                                                    min="0" max="1000000000" step="1000"
                                                                    placeholder="Ví dụ: 650000">
                                                                <small id="costScheduleHint"
                                                                    style="display: none; margin-top: 5px; font-size: 12px; color: #166534; line-height: 1.4;">
                                                                    💡 Dự toán kế hoạch định kỳ là <strong
                                                                        id="hintScheduleCostText"
                                                                        style="color: #15803d;"></strong>. Hãy nhập Tổng
                                                                    chi phí dự toán (bao gồm cả tiền sửa sự cố).
                                                                </small>
                                                            </div>

                                                            <div class="form-group">
                                                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                                                <input class="form-control" type="text" name="note"
                                                                    id="createNoteInput" maxlength="255"
                                                                    placeholder="Ví dụ: FPT Tech Services / Kỹ thuật viên Tektronix">
                                                            </div>

                                                            <div class="form-group">
                                                                <label>SĐT đơn vị / kỹ thuật viên (Tùy chọn)</label>
                                                                <input class="form-control" type="tel"
                                                                    id="createPhoneInput" name="providerPhone"
                                                                    maxlength="20" pattern="^(0|\+84)[0-9.\s-]{8,15}$"
                                                                    title="Số điện thoại hợp lệ bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số"
                                                                    placeholder="Ví dụ: 0988.123.456">
                                                            </div>

                                                            <div class="form-group full-width">
                                                                <label>Địa chỉ đơn vị sửa chữa (Tùy chọn)</label>
                                                                <input class="form-control" type="text"
                                                                    id="createAddressInput" name="providerAddress"
                                                                    maxlength="255"
                                                                    placeholder="Ví dụ: 123 Cầu Giấy, Hà Nội hoặc Phòng Kỹ thuật Tòa Alpha">
                                                            </div>

                                                            <div class="form-group full-width">
                                                                <label>Ảnh đính kèm (Tùy chọn)</label>
                                                                <input class="form-control" type="file" name="imageFile"
                                                                    accept="image/*">
                                                                <small
                                                                    style="color: #64748b; font-size: 12px; margin-top: 4px; display: block;">Hỗ
                                                                    trợ ảnh PNG, JPG, JPEG, WEBP (Tối đa 10MB). Tự động
                                                                    tối ưu hóa lưu trên Cloudinary.</small>
                                                            </div>

                                                            <div class="form-group full-width">
                                                                <label>Mô tả chi tiết tình trạng hỏng hóc &amp; Yêu cầu
                                                                    sửa
                                                                    chữa *</label>
                                                                <textarea class="form-control" name="description"
                                                                    rows="4" maxlength="1000" required
                                                                    placeholder="Mô tả cụ thể hiện tượng lỗi, bộ phận hỏng, nguyên nhân nghi ngờ, yêu cầu thay thế..."></textarea>
                                                            </div>

                                                            <div
                                                                style="display: flex; flex-direction: row; gap: 10px; margin-top: 10px; grid-column: span 2;">
                                                                <button class="primary-button" type="submit"
                                                                    style="width: auto; padding: 8px 24px;">Tạo phiếu
                                                                    bảo
                                                                    trì</button>
                                                                <a class="btn-secondary"
                                                                    href="${pageContext.request.contextPath}/lab-manager/maintenance"
                                                                    style="width: auto; padding: 8px 20px;">Hủy</a>
                                                            </div>
                                                        </form>

                                                        <script>
                                                            document.addEventListener('DOMContentLoaded', function () {
                                                                const assetSelect = document.getElementById('assetSelect');
                                                                const incidentId = document.getElementById('incidentId');
                                                                const assetItemId = document.getElementById('assetItemId');
                                                                const scheduleIdInput = document.getElementById('scheduleIdInput');
                                                                const targetNotice = document.getElementById('maintenanceTargetNotice');

                                                                const estimatedCostInput = document.getElementById('createEstimatedCostInput');
                                                                const noteInput = document.getElementById('createNoteInput');
                                                                const phoneInput = document.getElementById('createPhoneInput');
                                                                const addressInput = document.getElementById('createAddressInput');
                                                                const costScheduleHint = document.getElementById('costScheduleHint');
                                                                const hintScheduleCostText = document.getElementById('hintScheduleCostText');

                                                                const routineNoticeBox = document.getElementById('routineScheduleNoticeBox');
                                                                const routineTitleText = document.getElementById('routineScheduleTitleText');
                                                                const routineDateText = document.getElementById('routineScheduleDateText');

                                                                const incidentReminderBox = document.getElementById('incidentScheduleReminderBox');
                                                                const incidentReminderDateText = document.getElementById('incidentReminderDateText');
                                                                const incidentReminderTitleText = document.getElementById('incidentReminderTitleText');
                                                                const incidentLinkedCheckbox = document.getElementById('incidentLinkedScheduleCheckbox');

                                                                function formatScheduleDate(dateStr) {
                                                                    if (!dateStr) return '';
                                                                    const parts = String(dateStr).split('-');
                                                                    if (parts.length === 3) {
                                                                        return parts[2] + '/' + parts[1] + '/' + parts[0];
                                                                    }
                                                                    return dateStr;
                                                                }

                                                                function updateCostHint(isChecked, costVal) {
                                                                    if (!costScheduleHint || !hintScheduleCostText) return;
                                                                    if (isChecked && costVal && Number(costVal) > 0) {
                                                                        hintScheduleCostText.textContent = Number(costVal).toLocaleString('vi-VN') + ' VNĐ';
                                                                        costScheduleHint.style.display = 'block';
                                                                    } else {
                                                                        costScheduleHint.style.display = 'none';
                                                                    }
                                                                }

                                                                if (assetSelect && incidentId) {
                                                                    function syncTarget() {
                                                                        const option = assetSelect.options[assetSelect.selectedIndex];
                                                                        const linkedIncident = option ? option.getAttribute('data-incident-id') : '';
                                                                        const linkedAssetItem = option ? option.getAttribute('data-asset-item-id') : '';
                                                                        const schedId = option ? option.getAttribute('data-schedule-id') : '';
                                                                        const schedTitle = option ? option.getAttribute('data-schedule-title') : '';
                                                                        const schedDate = option ? option.getAttribute('data-schedule-date') : '';
                                                                        const schedCost = option ? option.getAttribute('data-schedule-cost') : '';
                                                                        const schedProvider = option ? option.getAttribute('data-schedule-provider') : '';
                                                                        const schedPhone = option ? option.getAttribute('data-schedule-phone') : '';

                                                                        incidentId.value = linkedIncident || '';
                                                                        if (assetItemId) {
                                                                            assetItemId.value = linkedAssetItem || '';
                                                                        }
                                                                        if (targetNotice) {
                                                                            targetNotice.textContent = linkedIncident
                                                                                ? 'Sự cố được liên kết tự động với phiếu bảo trì này.'
                                                                                : 'Bảo trì định kỳ: không liên kết sự cố.';
                                                                            targetNotice.style.color = linkedIncident ? '#c62828' : '#137a4d';
                                                                        }

                                                                        // 1. Trường hợp: Chọn thiết bị từ nhóm "Bảo trì định kỳ / tài sản còn lại" (Không có incident)
                                                                        if (!linkedIncident || linkedIncident.trim() === '') {
                                                                            if (incidentReminderBox) incidentReminderBox.style.display = 'none';
                                                                            if (incidentLinkedCheckbox) {
                                                                                incidentLinkedCheckbox.checked = false;
                                                                                incidentLinkedCheckbox.value = '';
                                                                            }
                                                                            updateCostHint(false, '');

                                                                            if (schedId && schedId.trim() !== '') {
                                                                                if (routineTitleText) routineTitleText.textContent = schedTitle || '';
                                                                                if (routineDateText) routineDateText.textContent = formatScheduleDate(schedDate);
                                                                                if (routineNoticeBox) routineNoticeBox.style.display = 'block';
                                                                                if (scheduleIdInput) scheduleIdInput.value = schedId;

                                                                                // Gợi ý tự động điền sẵn nếu trường còn trống
                                                                                if (estimatedCostInput && !estimatedCostInput.value && schedCost && Number(schedCost) > 0) {
                                                                                    estimatedCostInput.value = schedCost;
                                                                                }
                                                                                if (noteInput && !noteInput.value && schedProvider) {
                                                                                    noteInput.value = schedProvider;
                                                                                }
                                                                                if (phoneInput && !phoneInput.value && schedPhone) {
                                                                                    phoneInput.value = schedPhone;
                                                                                }
                                                                            } else {
                                                                                if (routineNoticeBox) routineNoticeBox.style.display = 'none';
                                                                                if (scheduleIdInput) scheduleIdInput.value = '';
                                                                            }
                                                                        }
                                                                        // 2. Trường hợp: Chọn thiết bị từ nhóm "Sự cố đang xử lý" (Có incident)
                                                                        else {
                                                                            if (routineNoticeBox) routineNoticeBox.style.display = 'none';
                                                                            if (scheduleIdInput) scheduleIdInput.value = '';

                                                                            if (schedId && schedId.trim() !== '') {
                                                                                if (incidentReminderDateText) incidentReminderDateText.textContent = formatScheduleDate(schedDate);
                                                                                if (incidentReminderTitleText) incidentReminderTitleText.textContent = schedTitle || '';
                                                                                if (incidentReminderBox) incidentReminderBox.style.display = 'block';
                                                                                if (incidentLinkedCheckbox) {
                                                                                    incidentLinkedCheckbox.value = incidentLinkedCheckbox.checked ? schedId : '';
                                                                                    updateCostHint(incidentLinkedCheckbox.checked, schedCost);
                                                                                }
                                                                            } else {
                                                                                if (incidentReminderBox) incidentReminderBox.style.display = 'none';
                                                                                if (incidentLinkedCheckbox) {
                                                                                    incidentLinkedCheckbox.checked = false;
                                                                                    incidentLinkedCheckbox.value = '';
                                                                                }
                                                                                updateCostHint(false, '');
                                                                            }
                                                                        }
                                                                    }

                                                                    assetSelect.addEventListener('change', syncTarget);
                                                                    syncTarget();

                                                                    if (incidentLinkedCheckbox) {
                                                                        incidentLinkedCheckbox.addEventListener('change', function () {
                                                                            const option = assetSelect.options[assetSelect.selectedIndex];
                                                                            const schedId = option ? option.getAttribute('data-schedule-id') : '';
                                                                            const schedCost = option ? option.getAttribute('data-schedule-cost') : '';
                                                                            this.value = this.checked ? schedId : '';
                                                                            updateCostHint(this.checked, schedCost);
                                                                        });
                                                                    }
                                                                }
                                                            });
                                                        </script>
                                                    </c:otherwise>
                                        </c:choose>
                                    </article>
                                </section>
                            </main>
                    </div>
                </body>

                </html>
