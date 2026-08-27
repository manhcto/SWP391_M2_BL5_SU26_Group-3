<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Báo cáo sự cố | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>.incident-targets{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}.incident-target{display:inline-flex;align-items:center;gap:7px;padding:6px 9px;border:1px solid #cde3df;border-radius:999px;background:#eefaf7;font-size:12px}.incident-target button{border:0;background:transparent;color:#a12835;font-size:16px;cursor:pointer;line-height:1}.target-picker{display:flex;gap:8px}.target-picker select{flex:1}</style>
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Báo cáo sự cố</h1><p>Gửi báo cáo trực tiếp đến Lab Manager để điều tra</p></div></div>
            <div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/incidents">‹ Quay lại danh sách</a></div>
        </header>
        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <form class="form-grid" method="post" action="${pageContext.request.contextPath}/mentor/incidents">
                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                    <input type="hidden" name="action" value="create">
                    <div class="form-group full-width"><label for="targetPicker">Vật dụng hỏng *</label><div class="target-picker"><select class="form-control" id="targetPicker"><option value="">-- Chọn vật dụng --</option><c:if test="${not empty priorityUsages}"><optgroup label="Ưu tiên — thực tập sinh đã trả hỏng"><c:forEach var="usage" items="${priorityUsages}"><option value="usage:${usage.assetUsageId}"><c:out value="${usage.internName}"/> · <c:out value="${usage.assetName}"/> · Trả: <c:out value="${app:label(usage.conditionAfter)}"/></option></c:forEach></optgroup></c:if><optgroup label="Lượt sử dụng khác của thực tập sinh"><c:forEach var="usage" items="${otherUsages}"><option value="usage:${usage.assetUsageId}"><c:out value="${usage.internName}"/> · <c:out value="${usage.assetName}"/><c:if test="${not empty usage.assetItemTag}"> · <c:out value="${usage.assetItemTag}"/></c:if><c:if test="${usage.status == 'RETURNED'}"> · Trả: <c:out value="${app:label(usage.conditionAfter)}"/></c:if></option></c:forEach></optgroup><optgroup label="Vật dụng chưa gắn với lượt sử dụng"><c:forEach var="item" items="${assetItems}"><option value="item:${item.assetItemId}"><c:out value="${item.assetName}"/> · <c:out value="${item.itemCode}"/><c:if test="${not empty item.serialNumber}"> · <c:out value="${item.serialNumber}"/></c:if></option></c:forEach></optgroup></select><button class="btn-secondary" type="button" id="addTarget">Thêm</button></div><div class="incident-targets" id="selectedTargets" aria-live="polite"></div><small>Lượt trả hỏng được đưa lên đầu. Nếu thực tập sinh trả là Tốt nhưng Mentor kiểm tra thấy hỏng, chọn đúng lượt đó để Lab Manager điều tra trách nhiệm.</small></div>
                    <div class="form-group"><label for="incidentType">Loại sự cố *</label><select class="form-control" id="incidentType" name="incidentType" required><option value="DAMAGE" ${param.incidentType == 'DAMAGE' ? 'selected' : ''}>Hư hỏng</option><option value="MALFUNCTION" ${param.incidentType == 'MALFUNCTION' ? 'selected' : ''}>Trục trặc</option><option value="MISSING" ${param.incidentType == 'MISSING' ? 'selected' : ''}>Thiếu thiết bị</option><option value="LOSS" ${param.incidentType == 'LOSS' ? 'selected' : ''}>Mất thiết bị</option><option value="OTHER" ${param.incidentType == 'OTHER' ? 'selected' : ''}>Khác</option></select></div>
                    <div class="form-group"><label for="severity">Mức độ *</label><select class="form-control" id="severity" name="severity" required><option value="LOW" ${empty param.severity || param.severity == 'LOW' ? 'selected' : ''}>Thấp</option><option value="MEDIUM" ${param.severity == 'MEDIUM' ? 'selected' : ''}>Trung bình</option><option value="HIGH" ${param.severity == 'HIGH' ? 'selected' : ''}>Cao</option><option value="CRITICAL" ${param.severity == 'CRITICAL' ? 'selected' : ''}>Nghiêm trọng</option></select></div>
                    <div class="form-group full-width"><label for="reportedCause">Nhận định ban đầu của Mentor *</label><select class="form-control" id="reportedCause" name="reportedCause" required><option value="UNKNOWN" ${empty param.reportedCause || param.reportedCause == 'UNKNOWN' ? 'selected' : ''}>Chưa rõ, cần Lab Manager điều tra</option><option value="INTERN" ${param.reportedCause == 'INTERN' ? 'selected' : ''}>Có thông tin từ lượt sử dụng cần kiểm tra</option><option value="NATURAL" ${param.reportedCause == 'NATURAL' ? 'selected' : ''}>Dấu hiệu hao mòn hoặc lỗi thiết bị</option></select><small>Không phải kết luận trách nhiệm của Intern.</small></div>
                    <div class="form-group full-width"><label for="occurredAt">Thời điểm xảy ra</label><input class="form-control" id="occurredAt" type="datetime-local" name="occurredAt" value="<c:out value='${param.occurredAt}'/>"></div>
                    <div class="form-group full-width"><label for="description">Mô tả hỏng hóc *</label><textarea class="form-control" id="description" name="description" rows="5" maxlength="2000" required placeholder="Nêu hiện tượng, bộ phận bị hỏng, thông tin intern báo lại và mức độ ảnh hưởng."><c:out value="${param.description}"/></textarea></div>
                    <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Gửi Lab Manager</button><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/incidents">Hủy</a></div>
                </form>
            </article>
        </section>
    </main>
</div>
<script>
document.addEventListener('DOMContentLoaded', () => {
    const picker = document.getElementById('targetPicker'), selected = document.getElementById('selectedTargets');
    const addTarget = () => {
        const option = picker.options[picker.selectedIndex];
        if (!option || !option.value || [...selected.querySelectorAll('input[name="targets"]')].some(input => input.value === option.value)) return;
        const chip = document.createElement('span'); chip.className = 'incident-target'; chip.dataset.value = option.value;
        chip.append(document.createTextNode(option.text));
        const input = document.createElement('input'); input.type = 'hidden'; input.name = 'targets'; input.value = option.value; chip.append(input);
        const remove = document.createElement('button'); remove.type = 'button'; remove.textContent = '×'; remove.setAttribute('aria-label', 'Bỏ vật dụng'); remove.addEventListener('click', () => chip.remove()); chip.append(remove);
        selected.append(chip); picker.value = '';
    };
    document.getElementById('addTarget').addEventListener('click', addTarget);
    const preselected = '<c:out value="${preselectedTarget}"/>';
    if (preselected) { picker.value = preselected; addTarget(); }
    document.querySelector('form').addEventListener('submit', event => { if (!selected.querySelector('input[name="targets"]')) { event.preventDefault(); picker.focus(); } });
});
</script>
</body>
</html>
