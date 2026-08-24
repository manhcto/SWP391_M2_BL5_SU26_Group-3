<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${formMode == 'edit' ? 'Chỉnh sửa' : 'Thêm'} yêu cầu cấp phát | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/equipment-allocation.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="allocations" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>${formMode == 'edit' ? 'Chỉnh sửa yêu cầu' : 'Thêm yêu cầu'}</h1><p>Đề xuất tài sản cố định sử dụng xuyên suốt cho một lớp Intern</p></div></div></header>
        <section class="content-area allocation-form-page">
            <a class="allocation-back-link" href="${pageContext.request.contextPath}/mentor/allocations">Quay lại danh sách</a>
            <c:if test="${not empty param.error}"><p class="error-message" role="alert"><c:out value="${param.error}"/></p></c:if>
            <article class="panel allocation-create-panel">
                <header class="panel-header"><div class="panel-title"><svg aria-hidden="true"><use href="#i-clipboard"/></svg><div><h3>${formMode == 'edit' ? 'Thông tin yêu cầu' : 'Yêu cầu mới'}</h3><p>Mỗi yêu cầu được gắn với một lớp Intern đã được duyệt.</p></div></div></header>
                <form id="activityForm" method="post" class="allocation-activity-form" novalidate>
                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                    <input type="hidden" name="action" value="${formMode == 'edit' ? 'updateActivity' : 'createActivity'}">
                    <c:if test="${formMode == 'edit'}"><input type="hidden" name="activityId" value="${activity.activityId}"></c:if>
                    <div class="allocation-form-grid">
                        <label class="allocation-field"><span>Danh sách Intern <b>*</b></span>
                            <c:choose><c:when test="${formMode == 'edit'}"><input type="hidden" name="internListId" value="${activity.internListId}"><input class="form-control readonly-field" value="<c:out value='${activity.internListName}'/>" readonly><small>Danh sách đã gắn không thể thay đổi sau khi tạo hoạt động.</small></c:when><c:otherwise><select class="form-control" name="internListId" required aria-describedby="internListId-error"><option value="">Chọn danh sách đã duyệt</option><c:forEach items="${internLists}" var="list"><option value="${list.requestId}"><c:out value="${list.groupName}"/> - <c:out value="${list.semesterCode}"/></option></c:forEach></select><small>Chỉ hiển thị danh sách thuộc quyền của bạn đã được Admin duyệt.</small><p class="field-error" id="internListId-error" aria-live="polite"></p></c:otherwise></c:choose>
                        </label>
                        <label class="allocation-field"><span>Tên yêu cầu <b>*</b></span><input class="form-control" type="text" name="activityName" minlength="3" maxlength="150" required value="<c:out value='${activity.activityName}'/>" placeholder="Ví dụ: Thiết bị cố định lớp FA26" aria-describedby="activityName-error"><small>Từ 3 đến 150 ký tự.</small><p class="field-error" id="activityName-error" aria-live="polite"></p></label>
                        <label class="allocation-field"><span>Ngày bắt đầu <b>*</b></span><input class="form-control" type="date" name="startDate" required value="${activity.startDate}" aria-describedby="startDate-error"><p class="field-error" id="startDate-error" aria-live="polite"></p></label>
                        <label class="allocation-field"><span>Ngày kết thúc <b>*</b></span><input class="form-control" type="date" name="endDate" required value="${activity.endDate}" aria-describedby="endDate-error"><p class="field-error" id="endDate-error" aria-live="polite"></p></label>
                        <label class="allocation-field wide"><span>Mô tả</span><textarea class="form-control" name="description" rows="3" maxlength="500" placeholder="Mục đích sử dụng tài sản cố định cho cả lớp"><c:out value="${activity.description}"/></textarea><small>Tối đa 500 ký tự.</small></label>
                    </div>
                    <c:if test="${formMode != 'edit'}">
                        <section class="allocation-inline-assets" aria-labelledby="assetSectionTitle">
                            <div class="allocation-inline-heading"><div><h3 id="assetSectionTitle">Tài sản yêu cầu</h3><p>Thêm các loại tài sản cố định dùng chung cho cả lớp.</p></div><button class="btn-secondary" id="addAsset" type="button"><svg aria-hidden="true"><use href="#i-plus"/></svg>Thêm tài sản</button></div>
                            <div class="table-scroll allocation-asset-editor"><table><thead><tr><th>Loại tài sản</th><th>Số lượng cần</th><th>Ghi chú</th><th></th></tr></thead><tbody id="assetRows">
                            <tr data-asset-row><td><select class="form-control" name="assetId" required><option value="">Chọn tài sản đang khả dụng</option><c:forEach items="${assets}" var="asset"><option value="${asset.assetId}"><c:out value="${asset.assetName}"/> (<c:out value="${asset.assetCode}"/>) - còn <c:out value="${asset.totalQuantity}"/></option></c:forEach></select></td><td><input class="form-control row-quantity" type="number" name="requestedQuantity" min="1" max="999" step="1" value="1" required></td><td><textarea class="form-control" name="note" maxlength="500" rows="2" placeholder="Mục đích sử dụng"></textarea></td><td class="row-action"><button class="btn-action btn-action-danger remove-asset" type="button">Xóa</button></td></tr>
                            </tbody></table></div>
                            <p class="field-error allocation-asset-error" id="assetRowsError" role="alert"></p>
                        </section>
                    </c:if>
                    <div class="allocation-form-footer"><p><b>*</b> Trường bắt buộc</p><button class="primary-button" type="submit">${formMode == 'edit' ? 'Lưu thay đổi' : 'Gửi yêu cầu'}</button></div>
                </form>
            </article>
        </section>
    </main>
</div>
<c:if test="${formMode != 'edit'}"><template id="assetRowTemplate"><tr data-asset-row><td><select class="form-control" name="assetId" required><option value="">Chọn tài sản đang khả dụng</option><c:forEach items="${assets}" var="asset"><option value="${asset.assetId}"><c:out value="${asset.assetName}"/> (<c:out value="${asset.assetCode}"/>) - còn <c:out value="${asset.totalQuantity}"/></option></c:forEach></select></td><td><input class="form-control row-quantity" type="number" name="requestedQuantity" min="1" max="999" step="1" value="1" required></td><td><textarea class="form-control" name="note" maxlength="500" rows="2" placeholder="Mục đích sử dụng"></textarea></td><td class="row-action"><button class="btn-action btn-action-danger remove-asset" type="button">Xóa</button></td></tr></template></c:if>
<script>
    const activityForm = document.getElementById('activityForm');
    const clearError = field => { field.removeAttribute('aria-invalid'); const error = document.getElementById(`${field.name}-error`); if (error) { error.textContent = ''; error.classList.remove('visible'); } };
    const showError = (field, message) => { field.setAttribute('aria-invalid', 'true'); const error = document.getElementById(`${field.name}-error`); if (error) { error.textContent = message; error.classList.add('visible'); } };
    const assetRows = document.getElementById('assetRows');
    const assetRowsError = document.getElementById('assetRowsError');
    const clearAssetError = () => { if (!assetRows) return; assetRowsError.textContent = ''; assetRowsError.classList.remove('visible'); assetRows.querySelectorAll('[aria-invalid="true"]').forEach(field => field.removeAttribute('aria-invalid')); };
    const syncAssetOptions = () => {
        if (!assetRows) return;
        const selects = [...assetRows.querySelectorAll('[name="assetId"]')];
        const selected = new Set(selects.map(select => select.value).filter(Boolean));
        selects.forEach(select => [...select.options].forEach(option => { option.disabled = option.value && option.value !== select.value && selected.has(option.value); }));
    };
    document.getElementById('addAsset')?.addEventListener('click', () => { assetRows.append(document.getElementById('assetRowTemplate').content.cloneNode(true)); clearAssetError(); syncAssetOptions(); });
    assetRows?.addEventListener('click', event => { if (event.target.classList.contains('remove-asset')) { const row = event.target.closest('[data-asset-row]'); if (assetRows.children.length > 1) row.remove(); else { row.querySelector('select').value = ''; row.querySelector('[name="requestedQuantity"]').value = '1'; row.querySelector('[name="note"]').value = ''; } clearAssetError(); syncAssetOptions(); } });
    assetRows?.addEventListener('input', clearAssetError);
    assetRows?.addEventListener('change', () => { clearAssetError(); syncAssetOptions(); });
    activityForm.addEventListener('submit', event => {
        const name = activityForm.elements.activityName; const start = activityForm.elements.startDate; const end = activityForm.elements.endDate; const list = activityForm.elements.internListId;
        [name, start, end, list].forEach(clearError); name.value = name.value.trim(); let valid = true;
        if (!list.value) { showError(list, 'Hãy chọn danh sách Intern đã được duyệt.'); valid = false; }
        if (name.value.length < 3) { showError(name, 'Tên hoạt động cần có ít nhất 3 ký tự.'); valid = false; }
        if (!start.value) { showError(start, 'Hãy chọn ngày bắt đầu.'); valid = false; }
        if (!end.value) { showError(end, 'Hãy chọn ngày kết thúc.'); valid = false; }
        if (start.value && end.value && end.value < start.value) { showError(end, 'Ngày kết thúc phải bằng hoặc sau ngày bắt đầu.'); valid = false; }
        clearAssetError(); const selectedAssets = new Set();
        assetRows?.querySelectorAll('[data-asset-row]').forEach((row, index) => {
            const asset = row.querySelector('[name="assetId"]'); const quantity = row.querySelector('[name="requestedQuantity"]'); const value = Number(quantity.value);
            if (!asset.value) { asset.setAttribute('aria-invalid', 'true'); valid = false; }
            if (!Number.isInteger(value) || value < 1 || value > 999) { quantity.setAttribute('aria-invalid', 'true'); valid = false; }
            if (asset.value && selectedAssets.has(asset.value)) { asset.setAttribute('aria-invalid', 'true'); assetRowsError.textContent = `Tài sản ở dòng ${index + 1} đã được chọn trước đó.`; valid = false; }
            if (asset.value) selectedAssets.add(asset.value);
        });
        if (assetRows && assetRows.querySelector('[aria-invalid="true"]')) { if (!assetRowsError.textContent) assetRowsError.textContent = 'Mỗi dòng cần một tài sản riêng và số lượng từ 1 đến 999.'; assetRowsError.classList.add('visible'); }
        if (!valid) { event.preventDefault(); activityForm.querySelector('[aria-invalid="true"]')?.focus(); return; }
        const submit = activityForm.querySelector('[type="submit"]'); submit.disabled = true; submit.textContent = 'Đang gửi...';
    });
    activityForm.querySelectorAll('input, select, textarea').forEach(field => { field.addEventListener('input', () => clearError(field)); field.addEventListener('change', () => clearError(field)); });
</script>
</body>
</html>
