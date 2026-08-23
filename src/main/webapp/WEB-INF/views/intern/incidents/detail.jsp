<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Sự cố #INC-${incident.incidentId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../../student/includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Sự cố #INC-${incident.incidentId}</h1><p>Theo dõi quá trình Mentor và Lab Manager xử lý</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/incidents">‹ Quay lại danh sách</a></div></header>
        <section class="content-area">
            <c:if test="${param.created == '1'}"><div class="success-message">Đã gửi sự cố. Mentor sẽ xem xét trước khi chuyển Lab Manager.</div></c:if>
            <div class="content-heading"><div><p class="eyebrow">BÁO CÁO SỰ CỐ</p><h2><c:out value="${incident.assetName}"/></h2></div><span class="status ${incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : incident.status == 'REPORTED' ? 'open' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></div>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Thiết bị</dt><dd><c:out value="${incident.assetCode}"/><c:if test="${not empty incident.assetItemCode}"><br><small><c:out value="${incident.assetItemCode}"/></small></c:if></dd></div><div class="detail-item"><dt>Mã lượt sử dụng</dt><dd><c:out value="${empty incident.assetUsageId ? 'Không liên kết' : incident.assetUsageId}"/></dd></div><div class="detail-item"><dt>Loại / mức độ</dt><dd><c:out value="${app:label(incident.incidentType)}"/> · <c:out value="${app:label(incident.severity)}"/></dd></div><div class="detail-item"><dt>Thời điểm báo</dt><dd><c:out value="${app:dateTime(incident.reportedAt)}"/></dd></div><div class="detail-item wide"><dt>Mô tả đã gửi</dt><dd><c:out value="${incident.description}"/></dd></div><div class="detail-item wide"><dt>Ghi chú Mentor</dt><dd><c:out value="${empty incident.mentorReviewNote ? 'Mentor chưa duyệt báo cáo.' : incident.mentorReviewNote}"/></dd></div><c:if test="${not empty incident.forwardedAt}"><div class="detail-item"><dt>Đã chuyển Lab Manager</dt><dd><c:out value="${app:dateTime(incident.forwardedAt)}"/></dd></div></c:if><c:if test="${not empty incident.technicalAssessedAt}"><div class="detail-item"><dt>Đánh giá kỹ thuật</dt><dd><c:out value="${app:dateTime(incident.technicalAssessedAt)}"/></dd></div></c:if><c:if test="${not empty incident.technicalCause}"><div class="detail-item"><dt>Nguyên nhân kỹ thuật</dt><dd><c:out value="${app:label(incident.technicalCause)}"/></dd></div><div class="detail-item"><dt>Mức độ / khả năng sửa</dt><dd><c:out value="${app:label(incident.technicalSeverity)}"/> · <c:out value="${app:label(incident.repairability)}"/></dd></div><div class="detail-item"><dt>Hướng xử lý</dt><dd><c:out value="${app:label(incident.recommendedAction)}"/></dd></div><div class="detail-item wide"><dt>Ghi chú kỹ thuật</dt><dd><c:out value="${incident.technicalNote}"/></dd></div></c:if><div class="detail-item wide"><dt>Kết quả xử lý</dt><dd><c:out value="${empty incident.handlingResult ? 'Chưa có kết quả xử lý.' : incident.handlingResult}"/></dd></div></dl>
        </section>
    </main>
</div>
</body>
</html>
