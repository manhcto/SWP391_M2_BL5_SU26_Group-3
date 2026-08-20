<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Sự cố #INC-${incident.incidentId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Sự cố #INC-${incident.incidentId}</h1><p>Theo dõi tiến trình xử lý từ Quản lý phòng LAB</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/incidents">‹ Quay lại danh sách</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">BÁO CÁO SỰ CỐ</p><h2><c:out value="${incident.assetName}"/></h2></div><span class="status ${incident.status == 'OPEN' ? 'open' : incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></div>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Thiết bị</dt><dd><c:out value="${incident.assetCode}"/><c:if test="${not empty incident.assetItemCode}"><br><small><c:out value="${incident.assetItemCode}"/></small></c:if></dd></div><div class="detail-item"><dt>Thực tập sinh liên quan</dt><dd><c:out value="${empty incident.internName ? '—' : incident.internName}"/></dd></div><div class="detail-item"><dt>Loại / mức độ</dt><dd><c:out value="${app:label(incident.incidentType)}"/> · <c:out value="${app:label(incident.severity)}"/></dd></div><div class="detail-item"><dt>Thời điểm xảy ra</dt><dd><c:out value="${app:dateTime(incident.occurredAt)}"/></dd></div><div class="detail-item wide"><dt>Mô tả đã gửi</dt><dd><c:out value="${incident.description}"/></dd></div><div class="detail-item wide"><dt>Ghi chú điều tra</dt><dd><c:out value="${empty incident.investigationNote ? 'Quản lý phòng LAB chưa cập nhật.' : incident.investigationNote}"/></dd></div><div class="detail-item wide"><dt>Kết quả xử lý</dt><dd><c:out value="${empty incident.handlingResult ? 'Chưa có kết quả xử lý.' : incident.handlingResult}"/></dd></div></dl>
        </section>
    </main>
</div>
</body>
</html>
