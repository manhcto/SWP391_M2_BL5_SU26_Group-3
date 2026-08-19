<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${formMode == 'edit'}">Chỉnh sửa đề xuất bảo trì #MNT-${record.maintenanceId}</c:when>
            <c:otherwise>Tạo đề xuất bảo trì mới</c:otherwise>
        </c:choose> | LAB Asset
    </title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
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
                    <h1>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Chỉnh sửa đề xuất bảo trì #MNT-${record.maintenanceId}</c:when>
                            <c:otherwise>Tạo đề xuất bảo trì mới</c:otherwise>
                        </c:choose>
                    </h1>
                    <p>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Cập nhật thông tin yêu cầu trước khi Lab Manager phê duyệt</c:when>
                            <c:otherwise>Gửi yêu cầu sửa chữa thiết bị hỏng hóc lên Lab Manager phê duyệt</c:otherwise>
                        </c:choose>
                    </p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <form method="post" action="${pageContext.request.contextPath}/mentor/maintenance" class="form-grid">
                    <c:choose>
                        <c:when test="${formMode == 'edit'}">
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" name="id" value="${record.maintenanceId}">
                        </c:when>
                        <c:otherwise>
                            <input type="hidden" name="action" value="create">
                        </c:otherwise>
                    </c:choose>

                    <div class="form-group">
                        <label>Thiết bị cần bảo trì *</label>
                        <select class="form-control" name="assetId" id="assetSelect" required>
                            <option value="">-- Chọn thiết bị --</option>
                            <c:forEach var="a" items="${assets}">
                                <option value="${a.assetId}" ${(formMode == 'edit' && record.assetId == a.assetId) ? 'selected' : ''}>
                                    <c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/>)
                                    <c:if test="${not empty a.storageLocation}"> – <c:out value="${a.storageLocation}"/></c:if>
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Số lượng cần bảo trì *</label>
                        <input class="form-control" type="number" name="quantity"
                               value="${formMode == 'edit' ? record.quantity : 1}" min="1" required>
                    </div>

                    <div class="form-group full-width">
                        <label>Sự cố liên quan (nếu có)</label>
                        <select class="form-control" name="incidentId" id="incidentSelect">
                            <option value="" data-asset-id="">-- Không có sự cố (bảo dưỡng định kỳ / trực tiếp) --</option>
                            <c:forEach var="inc" items="${incidents}">
                                <option value="${inc.incidentId}" data-asset-id="${inc.assetId}" ${(formMode == 'edit' && record.incidentId == inc.incidentId) ? 'selected' : ''}>
                                    #INC-<c:out value="${inc.incidentId}"/> – <c:out value="${inc.assetName}"/>: <c:out value="${inc.description}"/>
                                </option>
                            </c:forEach>
                        </select>
                        <small id="incidentCountNotice" style="display:block;margin-top:4px;font-size:12px;color:#5a6662;"></small>
                    </div>

                    <div class="form-group full-width">
                        <label>Mô tả chi tiết tình trạng hỏng hóc / Lý do cần bảo trì *</label>
                        <textarea class="form-control" name="description" rows="5" required
                                  placeholder="Mô tả cụ thể: hiện tượng lỗi, bộ phận bị hỏng, nguyên nhân nghi ngờ, yêu cầu sửa chữa cụ thể..."><c:if test="${formMode == 'edit'}"><c:out value="${record.description}"/></c:if></textarea>
                    </div>

                    <div class="form-group full-width" style="display: flex; gap: 10px; margin-top: 10px;">
                        <button class="primary-button" type="submit">
                            <c:choose>
                                <c:when test="${formMode == 'edit'}">Lưu thay đổi đề xuất</c:when>
                                <c:otherwise>Gửi đề xuất bảo trì</c:otherwise>
                            </c:choose>
                        </button>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Hủy</a>
                    </div>
                </form>
            </article>
        </section>
    </main>
</div>

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
                    // Thiết bị có sự cố mở -> BẮT BUỘC chọn sự cố, ẩn option không có sự cố
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
                            countNotice.textContent = 'ℹ️ Thiết bị này hiện không có sự cố nào. Bạn có thể gửi đề xuất bảo dưỡng định kỳ.';
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
</body>
</html>
