<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Xử lý sự cố #INC-${incident.incidentId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Sự cố #INC-${incident.incidentId}</h1><p>Tiếp nhận, xác minh nguyên nhân và cập nhật kết quả xử lý</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/incidents">‹ Quay lại danh sách</a></div></header>
        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Thiết bị</dt><dd><strong><c:out value="${incident.assetName}"/></strong><br><c:out value="${empty incident.assetItemCode ? incident.assetCode : incident.assetItemCode}"/></dd></div><div class="detail-item"><dt>Người báo cáo</dt><dd><c:out value="${incident.reporterName}"/></dd></div><div class="detail-item"><dt>Thực tập sinh liên quan</dt><dd><c:out value="${empty incident.internName ? '—' : incident.internName}"/><c:if test="${not empty incident.internCode}"><br><small><c:out value="${incident.internCode}"/></small></c:if></dd></div><div class="detail-item"><dt>Loại / mức độ</dt><dd><c:out value="${app:label(incident.incidentType)}"/> · <c:out value="${app:label(incident.severity)}"/></dd></div><div class="detail-item"><dt>Mentor ghi nhận</dt><dd><c:out value="${app:label(incident.reportedCause)}"/></dd></div><div class="detail-item"><dt>Trạng thái</dt><dd><span class="status ${incident.status == 'OPEN' ? 'open' : incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></dd></div><div class="detail-item wide"><dt>Mô tả từ Mentor</dt><dd><c:out value="${incident.description}"/></dd></div></dl>
            <article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-alert"/></svg></span><h3>Cập nhật xử lý</h3></div></header>
                <form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/incidents/${incident.incidentId}">
                    <input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="incidentId" value="${incident.incidentId}">
                    <div class="form-group"><label for="status">Trạng thái *</label><select class="form-control" id="status" name="status" required><option value="OPEN" ${incident.status == 'OPEN' ? 'selected' : ''}>Chờ xử lý</option><option value="INVESTIGATING" ${incident.status == 'INVESTIGATING' ? 'selected' : ''}>Đang xử lý</option><option value="RESOLVED" ${incident.status == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option><option value="CLOSED" ${incident.status == 'CLOSED' ? 'selected' : ''}>Đã đóng</option></select></div>
                    <div class="form-group"><label for="determinedCause">Kết luận nguyên nhân</label><select class="form-control" id="determinedCause" name="determinedCause"><option value="" ${empty incident.determinedCause ? 'selected' : ''}>Chưa kết luận</option><option value="INTERN" ${incident.determinedCause == 'INTERN' ? 'selected' : ''}>Do thực tập sinh gây ra</option><option value="NATURAL" ${incident.determinedCause == 'NATURAL' ? 'selected' : ''}>Tự nhiên / không do thực tập sinh</option><option value="UNKNOWN" ${incident.determinedCause == 'UNKNOWN' ? 'selected' : ''}>Chưa rõ nguyên nhân</option></select></div>
                    <div class="form-group"><label>Liên kết tác vụ</label><div class="row-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Bảo trì</a><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities">Trách nhiệm</a></div></div>
                    <div class="form-group full-width"><label for="investigationNote">Ghi chú điều tra / xác định nguyên nhân</label><textarea class="form-control" id="investigationNote" name="investigationNote" rows="4" placeholder="Mô tả kết quả kiểm tra, nguyên nhân và hướng xử lý."><c:out value="${incident.investigationNote}"/></textarea></div>
                    <div class="form-group full-width"><label for="handlingResult">Kết quả xử lý</label><textarea class="form-control" id="handlingResult" name="handlingResult" rows="4" placeholder="Nêu phương án: tạo trách nhiệm/bồi thường, chuyển bảo trì hoặc thanh lý."><c:out value="${incident.handlingResult}"/></textarea></div>
                    <div class="form-group full-width form-actions"><button class="primary-button" type="submit" name="action" value="update">Lưu cập nhật</button><c:if test="${not empty incident.internName}"><button class="btn-secondary" type="submit" name="action" value="createResponsibility">Tạo trách nhiệm cho Intern</button></c:if></div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
