<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sự cố của tôi | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../../student/includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Sự cố của tôi</h1><p>Theo dõi các báo cáo từ thiết bị bạn đã sử dụng</p></div></div>
            <div class="topbar-actions"><a class="primary-button" href="${pageContext.request.contextPath}/intern/incidents/new"><svg><use href="#i-alert"/></svg>Báo cáo sự cố</a></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG THỰC TẬP SINH</p><h2>Danh sách sự cố (${incidents.size()})</h2></div></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/intern/incidents">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Tìm theo mã hoặc thiết bị" style="width:280px">
                    <select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="REPORTED" ${selectedStatus == 'REPORTED' ? 'selected' : ''}>Chờ Mentor duyệt</option><option value="FORWARDED" ${selectedStatus == 'FORWARDED' ? 'selected' : ''}>Đã chuyển Lab Manager</option><option value="INVESTIGATING" ${selectedStatus == 'INVESTIGATING' ? 'selected' : ''}>Đang xử lý</option><option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option><option value="CLOSED" ${selectedStatus == 'CLOSED' ? 'selected' : ''}>Đã kết thúc</option><option value="OPEN" ${selectedStatus == 'OPEN' ? 'selected' : ''}>Mở (lịch sử)</option></select>
                    <select class="form-control" name="severity"><option value="">Tất cả mức độ</option><option value="LOW" ${selectedSeverity == 'LOW' ? 'selected' : ''}>Thấp</option><option value="MEDIUM" ${selectedSeverity == 'MEDIUM' ? 'selected' : ''}>Trung bình</option><option value="HIGH" ${selectedSeverity == 'HIGH' ? 'selected' : ''}>Cao</option><option value="CRITICAL" ${selectedSeverity == 'CRITICAL' ? 'selected' : ''}>Nghiêm trọng</option></select>
                    <button class="primary-button" type="submit">Lọc</button><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/incidents">Đặt lại</a>
                </div>
            </form>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty incidents}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-alert"/></svg></div><h3>Chưa có sự cố</h3><p>Chọn một lượt sử dụng của bạn để gửi báo cáo khi phát hiện bất thường.</p><a class="primary-button" href="${pageContext.request.contextPath}/intern/incidents/new">Báo cáo sự cố</a></div></c:when>
                    <c:otherwise><div class="table-scroll"><table><thead><tr><th>Mã sự cố</th><th>Thiết bị</th><th>Loại / mức độ</th><th>Thời gian</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach var="incident" items="${incidents}"><tr><td><strong>#INC-<c:out value="${incident.incidentId}"/></strong></td><td><strong><c:out value="${incident.assetName}"/></strong><br><small><c:out value="${empty incident.assetItemCode ? incident.assetCode : incident.assetItemCode}"/></small></td><td><c:out value="${app:label(incident.incidentType)}"/> · <c:out value="${app:label(incident.severity)}"/></td><td><c:out value="${app:dateTime(incident.reportedAt)}"/></td><td><span class="status ${incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : incident.status == 'REPORTED' ? 'open' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/incidents/${incident.incidentId}">Xem</a></td></tr></c:forEach></tbody></table></div><div class="table-footer"><span>Hiển thị ${incidents.size()} sự cố</span></div></c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
