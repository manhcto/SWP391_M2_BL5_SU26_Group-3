<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Phiếu bảo trì #MNT-${record.maintenanceId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px;padding:18px}.info-item label{display:block;color:#5a6662;font-size:11px;font-weight:600;text-transform:uppercase}.info-item p{margin:4px 0 0;white-space:pre-line}</style>
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Phiếu bảo trì #MNT-<c:out value="${record.maintenanceId}"/></h1><p>Theo dõi yêu cầu bảo trì thiết bị theo mã riêng.</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Quay lại</a></div></header>
        <section class="content-area">
            <c:if test="${param.success == 'created'}"><div class="success-message">Đã gửi yêu cầu bảo trì.</div></c:if>
            <article class="panel"><div class="info-grid">
                <div class="info-item"><label>Trạng thái</label><p><c:choose><c:when test="${record.status == 'COMPLETED' && record.repairOutcome == 'SUCCESS'}"><span class="status returned">Sửa thành công</span></c:when><c:when test="${record.status == 'COMPLETED' && record.repairOutcome == 'FAILED'}"><span class="status overdue">Sửa thất bại</span></c:when><c:otherwise><span class="status"><c:out value="${app:label(record.status)}"/></span></c:otherwise></c:choose></p></div>
                <div class="info-item"><label>Ngày gửi</label><p><c:out value="${app:dateTime(record.requestedAt)}"/></p></div>
                <div class="info-item"><label>Thiết bị chính xác</label><p><c:choose><c:when test="${not empty record.assetItemId}"><strong><c:out value="${record.assetItemTag}"/></strong><br><small><c:out value="${app:label(record.assetItemCondition)}"/> · <c:out value="${app:label(record.assetItemStatus)}"/></small></c:when><c:otherwise>Hồ sơ lịch sử không có mã Item</c:otherwise></c:choose></p></div>
                <div class="info-item"><label>Thiết bị cha</label><p><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</p></div>
                <c:if test="${not empty record.incidentId}"><div class="info-item"><label>Sự cố liên quan</label><p>#INC-<c:out value="${record.incidentId}"/><c:if test="${not empty record.incidentDescription}"> · <c:out value="${record.incidentDescription}"/></c:if></p></div></c:if>
                <c:if test="${not empty record.assessmentId}"><div class="info-item"><label>Đánh giá kỹ thuật</label><p>#ASM-<c:out value="${record.assessmentId}"/></p></div></c:if>
                <div class="info-item" style="grid-column:1/-1"><label>Mô tả yêu cầu</label><p><c:out value="${record.description}"/></p></div>
                <c:if test="${not empty record.approvalNote}"><div class="info-item" style="grid-column:1/-1"><label>Ghi chú Lab Manager</label><p><c:out value="${record.approvalNote}"/></p></div></c:if>
            </div></article>
            <c:if test="${record.status == 'IN_PROGRESS' || record.status == 'COMPLETED'}"><article class="panel"><div class="info-grid">
                <div class="info-item"><label>Bắt đầu sửa</label><p><c:out value="${app:dateTime(record.repairStartedAt)}"/></p></div>
                <div class="info-item"><label>Hoàn tất</label><p><c:out value="${app:dateTime(record.repairCompletedAt)}"/></p></div>
                <div class="info-item"><label>Kết quả</label><p><c:out value="${empty record.repairOutcome ? 'PENDING' : record.repairOutcome}"/></p></div>
                <div class="info-item"><label>Kỹ thuật viên / ghi chú</label><p><c:out value="${empty record.note ? 'Không có' : record.note}"/></p></div>
                <c:if test="${not empty record.repairResult}"><div class="info-item" style="grid-column:1/-1"><label>Chi tiết kết quả sửa chữa</label><p><c:out value="${record.repairResult}"/></p></div></c:if>
            </div></article></c:if>
        </section>
    </main>
</div>
</body>
</html>
