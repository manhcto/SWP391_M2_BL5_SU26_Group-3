<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ bảo trì #MNT-${record.maintenanceId}</c:when>
            <c:otherwise>Tạo phiếu bảo trì</c:otherwise>
        </c:choose> | LAB Asset
    </title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button>
                <div>
                    <h1>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa #MNT-${record.maintenanceId}</c:when>
                            <c:otherwise>Tạo phiếu bảo trì thiết bị</c:otherwise>
                        </c:choose>
                    </h1>
                    <p>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa, điều chỉnh kinh phí và ghi nhận kết quả nghiệm thu</c:when>
                            <c:otherwise>Lập phiếu bảo trì, dự toán kinh phí và đưa thiết bị đi sửa chữa</c:otherwise>
                        </c:choose>
                    </p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <c:choose>
                    <%-- CHẾ ĐỘ 1: CẬP NHẬT TIẾN ĐỘ & KẾT QUẢ SỬA CHỮA --%>
                    <c:when test="${formMode == 'edit'}">
                        <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="updateProgress">
                            <input type="hidden" name="id" value="${record.maintenanceId}">

                            <div class="form-group">
                                <label>Thiết bị cần bảo trì</label>
                                <input class="form-control" type="text"
                                       value="<c:out value='${record.assetName}'/> (<c:out value='${record.assetCode}'/>)"
                                       readonly style="background:#f8fafc; color:#334155; font-weight:550; cursor:not-allowed; border-color:#d1d5db;">
                            </div>

                            <div class="form-group">
                                <label>Sự cố liên quan</label>
                                <input class="form-control" type="text"
                                       value="<c:choose><c:when test='${not empty record.incidentId}'>#INC-${record.incidentId}: <c:out value='${record.incidentDescription}'/></c:when><c:otherwise>Không có (Bảo dưỡng định kỳ / Trực tiếp)</c:otherwise></c:choose>"
                                       readonly style="background:#f8fafc; color:#334155; font-weight:550; cursor:not-allowed; border-color:#d1d5db;">
                            </div>

                            <div class="form-group full-width">
                                <label>Trạng thái tiến độ *</label>
                                <select class="form-control" name="status" id="progressStatusSelect" required>
                                    <option value="IN_PROGRESS" ${record.status == 'IN_PROGRESS' ? 'selected' : ''}>⏳ Đang sửa chữa (Đang tiến hành sửa chữa, thay linh kiện)</option>
                                    <option value="COMPLETED_SUCCESS" ${record.status == 'COMPLETED' && record.assetStatus != 'UNAVAILABLE' ? 'selected' : ''}>✅ Đã sửa xong – Hoàn tất thành công (Thiết bị về Sẵn sàng AVAILABLE)</option>
                                    <option value="COMPLETED_FAILED" ${record.status == 'COMPLETED' && record.assetStatus == 'UNAVAILABLE' ? 'selected' : ''}>❌ Sửa thất bại – Không thể phục hồi (Thiết bị chuyển UNAVAILABLE chờ thanh lý)</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Ghi chú phê duyệt / Kinh phí sửa chữa</label>
                                <input class="form-control" type="text" name="approvalNote"
                                       value="<c:out value='${record.approvalNote}'/>"
                                       placeholder="Ví dụ: Chi phí thực tế 650.000 VNĐ">
                            </div>

                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                <input class="form-control" type="text" name="note"
                                       value="<c:out value='${record.note}'/>"
                                       placeholder="Ví dụ: Kỹ thuật viên Tektronix VN / FPT Services">
                            </div>

                            <div class="form-group full-width" id="repairResultField" style="display: none; grid-column: span 2;">
                                <label style="font-weight: 650; margin-bottom: 4px;">Kết quả sửa chữa / Linh kiện thay thế</label>
                                <textarea class="form-control" name="repairResult" rows="4" style="width: 100%; min-height: 90px; box-sizing: border-box;"
                                          placeholder="Ví dụ: Đã thay thế vòi phun extruder và cân chỉnh nhiệt độ bàn in. Thiết bị hoạt động hoàn hảo."><c:out value="${record.repairResult}"/></textarea>
                            </div>

                            <div style="display: flex; flex-direction: row; gap: 10px; margin-top: 10px; grid-column: span 2;">
                                <button class="primary-button" type="submit" style="width: auto; padding: 8px 24px;">Lưu tiến độ bảo trì</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance" style="width: auto; padding: 8px 20px;">Hủy</a>
                            </div>
                        </form>

                        <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const progressStatusSelect = document.getElementById('progressStatusSelect');
                                const repairResultField = document.getElementById('repairResultField');
                                if (progressStatusSelect && repairResultField) {
                                    function toggleRepairResult() {
                                        const val = progressStatusSelect.value;
                                        if (val === 'COMPLETED_SUCCESS' || val === 'COMPLETED_FAILED') {
                                            repairResultField.style.display = 'flex';
                                        } else {
                                            repairResultField.style.display = 'none';
                                        }
                                    }
                                    progressStatusSelect.addEventListener('change', toggleRepairResult);
                                    toggleRepairResult();
                                }
                            });
                        </script>
                    </c:when>

                    <%-- CHẾ ĐỘ 2: TẠO MỚI PHIẾU BẢO TRÌ (TRỰC TIẾP APPROVED) --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="create">

                            <div class="form-group full-width">
                                <label>Thiết bị cần bảo trì *</label>
                                <select class="form-control" name="assetId" id="assetSelect" required>
                                    <option value="">-- Chọn thiết bị --</option>
                                    <c:forEach var="a" items="${assets}">
                                        <option value="${a.assetId}">
                                            <c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/>)
                                            <c:if test="${not empty a.storageLocation}"> – <c:out value="${a.storageLocation}"/></c:if>
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="form-group full-width">
                                <label>Sự cố liên quan (nếu có)</label>
                                <select class="form-control" name="incidentId" id="incidentSelect">
                                    <option value="" data-asset-id="">-- Không có sự cố (bảo dưỡng định kỳ / trực tiếp) --</option>
                                    <c:forEach var="inc" items="${incidents}">
                                        <option value="${inc.incidentId}" data-asset-id="${inc.assetId}">
                                            #INC-<c:out value="${inc.incidentId}"/> – <c:out value="${inc.assetName}"/>: <c:out value="${inc.description}"/>
                                        </option>
                                    </c:forEach>
                                </select>
                                <small id="incidentCountNotice" style="display:block;margin-top:4px;font-size:12px;color:#5a6662;"></small>
                            </div>

                            <div class="form-group">
                                <label>Dự toán kinh phí sửa chữa</label>
                                <input class="form-control" type="text" name="approvalNote"
                                       placeholder="Ví dụ: Dự toán 650.000 VNĐ">
                            </div>

                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                <input class="form-control" type="text" name="note"
                                       placeholder="Ví dụ: FPT Tech Services / Kỹ thuật viên Tektronix">
                            </div>

                            <div class="form-group full-width">
                                <label>Mô tả chi tiết tình trạng hỏng hóc &amp; Yêu cầu sửa chữa *</label>
                                <textarea class="form-control" name="description" rows="4" required
                                          placeholder="Mô tả cụ thể hiện tượng lỗi, bộ phận hỏng, nguyên nhân nghi ngờ, yêu cầu thay thế..."></textarea>
                            </div>

                            <div style="display: flex; flex-direction: row; gap: 10px; margin-top: 10px; grid-column: span 2;">
                                <button class="primary-button" type="submit" style="width: auto; padding: 8px 24px;">Tạo phiếu bảo trì</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance" style="width: auto; padding: 8px 20px;">Hủy</a>
                            </div>
                        </form>

                        <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const assetSelect = document.getElementById('assetSelect');
                                const incidentSelect = document.getElementById('incidentSelect');
                                const countNotice = document.getElementById('incidentCountNotice');

                                if (assetSelect && incidentSelect) {
                                    function filterIncidents() {
                                        const selectedAssetId = assetSelect.value;
                                        const currentIncidentVal = incidentSelect.value;
                                        let matchingCount = 0;
                                        let firstMatchingVal = '';
                                        let isCurrentStillValid = false;

                                        Array.from(incidentSelect.options).forEach(function(opt, index) {
                                            if (index === 0) return;

                                            const optAssetId = opt.getAttribute('data-asset-id');
                                            if (selectedAssetId && optAssetId === selectedAssetId) {
                                                opt.hidden = false;
                                                opt.disabled = false;
                                                matchingCount++;
                                                if (!firstMatchingVal) {
                                                    firstMatchingVal = opt.value;
                                                }
                                                if (opt.value === currentIncidentVal) {
                                                    isCurrentStillValid = true;
                                                }
                                            } else {
                                                opt.hidden = true;
                                                opt.disabled = true;
                                            }
                                        });

                                        const noneOption = incidentSelect.options[0];

                                        if (matchingCount > 0) {
                                            // Thiết bị có sự cố mở -> Bắt buộc chọn sự cố
                                            noneOption.hidden = true;
                                            noneOption.disabled = true;
                                            incidentSelect.required = true;

                                            if (!isCurrentStillValid) {
                                                incidentSelect.value = firstMatchingVal;
                                            }

                                            if (countNotice) {
                                                countNotice.innerHTML = '⚠️ Thiết bị này đang có <b>' + matchingCount + '</b> sự cố hỏng hóc chưa xử lý. Hệ thống đã tự động chọn sự cố cần khắc phục.';
                                                countNotice.style.color = '#c62828';
                                            }
                                        } else {
                                            // Thiết bị không có sự cố -> Cho phép chọn "Không có sự cố (bảo dưỡng định kỳ)"
                                            noneOption.hidden = false;
                                            noneOption.disabled = false;
                                            incidentSelect.required = false;
                                            incidentSelect.value = '';

                                            if (countNotice) {
                                                if (!selectedAssetId) {
                                                    countNotice.textContent = 'Vui lòng chọn thiết bị ở trên để xem danh sách sự cố tương ứng.';
                                                    countNotice.style.color = '#5a6662';
                                                } else {
                                                    countNotice.textContent = 'ℹ️ Thiết bị này hiện không có sự cố nào. Bạn có thể tạo phiếu bảo dưỡng định kỳ.';
                                                    countNotice.style.color = '#137a4d';
                                                }
                                            }
                                        }
                                    }

                                    assetSelect.addEventListener('change', filterIncidents);
                                    filterIncidents();
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
