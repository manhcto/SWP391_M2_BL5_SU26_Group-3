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
                                                <c:otherwise>Lập phiếu bảo trì, dự toán kinh phí và đưa thiết bị đi sửa
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
                                                    action="${pageContext.request.contextPath}/lab-manager/maintenance"
                                                    class="form-grid">
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
                                                            <option value="IN_PROGRESS" ${record.status=='IN_PROGRESS'
                                                                ? 'selected' : '' }>⏳ Đang sửa chữa (Đang tiến hành sửa
                                                                chữa, thay linh kiện)</option>
                                                            <option value="COMPLETED_SUCCESS"
                                                                ${record.status=='COMPLETED' && record.assetStatus
                                                                !='UNAVAILABLE' ? 'selected' : '' }>✅ Đã sửa xong – Hoàn
                                                                tất thành công (Thiết bị về Sẵn sàng AVAILABLE)</option>
                                                            <option value="COMPLETED_FAILED"
                                                                ${record.status=='COMPLETED' &&
                                                                record.assetStatus=='UNAVAILABLE' ? 'selected' : '' }>❌
                                                                Sửa thất bại – Không thể phục hồi (Thiết bị chuyển
                                                                UNAVAILABLE chờ thanh lý)</option>
                                                        </select>
                                                    </div>

                                                    <div class="form-group">
                                                        <label>Dự toán kinh phí (VNĐ)</label>
                                                        <input class="form-control" type="number" name="estimatedCost" min="0" max="1000000000" step="1000"
                                                            value="<c:out value='${record.estimatedCost}'/>"
                                                            placeholder="Nhập dự toán kinh phí nếu có (VNĐ)">
                                                    </div>

                                                    <div class="form-group">
                                                        <label id="providerLabel">Đơn vị / Kỹ thuật viên sửa chữa</label>
                                                        <input class="form-control" type="text" name="note" id="providerInput" maxlength="255"
                                                            value="<c:out value='${record.note}'/>"
                                                            placeholder="Ví dụ: Kỹ thuật viên Tektronix VN / FPT Services">
                                                    </div>

                                                    <div class="form-group">
                                                        <label>SĐT đơn vị / kỹ thuật viên</label>
                                                        <input class="form-control" type="tel" name="providerPhone" maxlength="20"
                                                            pattern="^(0|\+84)[0-9.\s-]{8,15}$"
                                                            title="Số điện thoại hợp lệ bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số"
                                                            value="<c:out value='${record.providerPhone}'/>"
                                                            placeholder="Ví dụ: 0988.123.456">
                                                    </div>

                                                    <div class="form-group full-width">
                                                        <label>Địa chỉ đơn vị sửa chữa</label>
                                                        <input class="form-control" type="text" name="providerAddress" maxlength="255"
                                                            value="<c:out value='${record.providerAddress}'/>"
                                                            placeholder="Ví dụ: 123 Cầu Giấy, Hà Nội hoặc Phòng Kỹ thuật Tòa Alpha">
                                                    </div>


                                                    <div class="form-group full-width" id="actualCostField"
                                                        style="display: none; grid-column: span 2;">
                                                        <label style="font-weight: 650; margin-bottom: 4px;">Chi phí thực tế (VNĐ) *</label>
                                                        <input class="form-control" type="number" name="actualCost" id="actualCostInput"
                                                            min="0" max="1000000000" step="1000"
                                                            value="<c:out value='${record.actualCost}'/>"
                                                            placeholder="Nhập số tiền thực tế đã thanh toán (VNĐ)">
                                                    </div>

                                                    <div class="form-group full-width" id="repairResultField"
                                                        style="display: none; grid-column: span 2;">
                                                        <label style="font-weight: 650; margin-bottom: 4px;">Kết quả sửa
                                                            chữa / Linh kiện thay thế *</label>
                                                        <textarea class="form-control" name="repairResult" id="repairResultInput" rows="4" maxlength="1000"
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
                                                    });
                                                </script>
                                            </c:when>

                                            <%-- CHẾ ĐỘ 2: TẠO MỚI PHIẾU BẢO TRÌ (TRỰC TIẾP APPROVED) --%>
                                                <c:otherwise>
                                                    <form method="post"
                                                        action="${pageContext.request.contextPath}/lab-manager/maintenance"
                                                        class="form-grid">
                                                        <input type="hidden" name="action" value="create">

                                                        <div class="form-group full-width">
                                                            <label>Thiết bị cần bảo trì *</label>
                                                            <select class="form-control" name="assetId" id="assetSelect"
                                                                required>
                                                                <option value="">-- Chọn thiết bị --</option>
                                                                <c:if test="${not empty incidents}">
                                                                    <optgroup label="Sự cố đang xử lý">
                                                                        <c:forEach var="inc" items="${incidents}">
                                                                            <option value="${inc.assetId}"
                                                                                data-incident-id="${inc.incidentId}">
                                                                                #INC-
                                                                                <c:out value="${inc.incidentId}" /> ·
                                                                                <c:out value="${inc.assetName}" /> (
                                                                                <c:out value="${not empty inc.assetItemCode ? inc.assetItemCode : inc.assetCode}" />) —
                                                                                <c:out value="${inc.description}" />
                                                                            </option>
                                                                        </c:forEach>
                                                                    </optgroup>
                                                                </c:if>
                                                                <c:if test="${not empty routineAssets}">
                                                                    <optgroup label="Bảo trì định kỳ / tài sản còn lại">
                                                                        <c:forEach var="a" items="${routineAssets}">
                                                                            <option value="${a.assetId}"
                                                                                data-incident-id="">
                                                                                <c:out value="${a.assetName}" /> (
                                                                                <c:out value="${not empty a.itemCode ? a.itemCode : a.assetCode}" />)
                                                                                <c:if
                                                                                    test="${not empty a.storageLocation}">
                                                                                    –
                                                                                    <c:out
                                                                                        value="${a.storageLocation}" />
                                                                                </c:if>
                                                                            </option>
                                                                        </c:forEach>
                                                                    </optgroup>
                                                                </c:if>
                                                            </select>
                                                            <small id="maintenanceTargetNotice"
                                                                style="display:block;margin-top:4px;font-size:12px;color:#5a6662;">Chọn
                                                                sự cố để sửa chữa, hoặc chọn tài sản còn lại cho bảo trì
                                                                định kỳ.</small>
                                                        </div>
                                                        <input type="hidden" name="incidentId" id="incidentId">

                                                        <div class="form-group">
                                                            <label>Dự toán kinh phí sửa chữa (VNĐ)</label>
                                                            <input class="form-control" type="number"
                                                                name="estimatedCost" min="0" max="1000000000" step="1000"
                                                                placeholder="Ví dụ: 650000">
                                                        </div>

                                                        <div class="form-group">
                                                            <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                                            <input class="form-control" type="text" name="note" maxlength="255"
                                                                placeholder="Ví dụ: FPT Tech Services / Kỹ thuật viên Tektronix">
                                                        </div>

                                                        <div class="form-group">
                                                            <label>SĐT đơn vị / kỹ thuật viên</label>
                                                            <input class="form-control" type="tel" name="providerPhone" maxlength="20"
                                                                pattern="^(0|\+84)[0-9.\s-]{8,15}$"
                                                                title="Số điện thoại hợp lệ bắt đầu bằng 0 hoặc +84 và gồm 10-11 chữ số"
                                                                placeholder="Ví dụ: 0988.123.456">
                                                        </div>

                                                        <div class="form-group full-width">
                                                            <label>Địa chỉ đơn vị sửa chữa</label>
                                                            <input class="form-control" type="text" name="providerAddress" maxlength="255"
                                                                placeholder="Ví dụ: 123 Cầu Giấy, Hà Nội hoặc Phòng Kỹ thuật Tòa Alpha">
                                                        </div>

                                                        <div class="form-group full-width">
                                                            <label>Mô tả chi tiết tình trạng hỏng hóc &amp; Yêu cầu sửa
                                                                chữa *</label>
                                                            <textarea class="form-control" name="description" rows="4" maxlength="1000"
                                                                required
                                                                placeholder="Mô tả cụ thể hiện tượng lỗi, bộ phận hỏng, nguyên nhân nghi ngờ, yêu cầu thay thế..."></textarea>
                                                        </div>

                                                        <div
                                                            style="display: flex; flex-direction: row; gap: 10px; margin-top: 10px; grid-column: span 2;">
                                                            <button class="primary-button" type="submit"
                                                                style="width: auto; padding: 8px 24px;">Tạo phiếu bảo
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
                                                            const targetNotice = document.getElementById('maintenanceTargetNotice');

                                                            if (assetSelect && incidentId) {
                                                                function syncTarget() {
                                                                    const option = assetSelect.options[assetSelect.selectedIndex];
                                                                    const linkedIncident = option ? option.getAttribute('data-incident-id') : '';
                                                                    incidentId.value = linkedIncident || '';
                                                                    if (targetNotice) {
                                                                        targetNotice.textContent = linkedIncident
                                                                            ? 'Sự cố được liên kết tự động với phiếu bảo trì này.'
                                                                            : 'Bảo trì định kỳ: không liên kết sự cố.';
                                                                        targetNotice.style.color = linkedIncident ? '#c62828' : '#137a4d';
                                                                    }
                                                                }

                                                                assetSelect.addEventListener('change', syncTarget);
                                                                syncTarget();
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