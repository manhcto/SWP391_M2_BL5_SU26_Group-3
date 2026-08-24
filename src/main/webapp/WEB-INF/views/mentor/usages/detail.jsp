<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Lượt sử dụng #${usage.assetUsageId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết sử dụng thiết bị</h1><p>Thông tin mượn, trả thiết bị của thực tập sinh</p></div></div><div class="topbar-actions"><c:if test="${not empty usage.assetItemId}"><a class="primary-button" href="${pageContext.request.contextPath}/mentor/assets/${usage.assetItemId}/lifecycle">Vòng đời sản phẩm</a></c:if><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/usages">Quay lại lịch sử</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LƯỢT SỬ DỤNG #AU-${usage.assetUsageId}</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'IN_USE' ? 'in-use' : (usage.status == 'MAINTENANCE' ? 'maintenance' : 'returned')}"><c:out value="${app:label(usage.status)}"/></span></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Mã thiết bị</dt><dd><c:out value="${usage.assetCode}"/></dd></div><div class="detail-item"><dt>Mã sản phẩm / Serial</dt><dd><c:out value="${empty usage.assetItemTag ? 'Theo thiết bị chung' : usage.assetItemTag}"/></dd></div><div class="detail-item"><dt>Thực tập sinh</dt><dd><c:out value="${usage.internName}"/></dd></div><div class="detail-item"><dt>Số lượng</dt><dd><c:out value="${usage.quantity}"/></dd></div><div class="detail-item"><dt>Mượn lúc</dt><dd><c:out value="${app:dateTime(usage.borrowedAt)}"/></dd></div><div class="detail-item"><dt>Yêu cầu trả lúc</dt><dd><c:out value="${app:dateTime(usage.returnRequestedAt)}"/></dd></div><div class="detail-item"><dt>Intern báo cáo</dt><dd><c:out value="${empty usage.reportedConditionAfter ? 'Chưa báo cáo' : app:label(usage.reportedConditionAfter)}"/></dd></div><div class="detail-item"><dt>Mentor xác minh</dt><dd><c:out value="${empty usage.verifiedConditionAfter ? 'Chưa xác minh' : app:label(usage.verifiedConditionAfter)}"/></dd></div><div class="detail-item"><dt>Trả lúc</dt><dd><c:out value="${empty usage.returnedAt ? 'Chưa trả' : app:dateTime(usage.returnedAt)}"/></dd></div><div class="detail-item wide"><dt>Ghi chú trả thiết bị</dt><dd><c:out value="${empty usage.returnNote ? 'Chưa có ghi chú trả thiết bị.' : usage.returnNote}"/></dd></div></dl>
            <c:if test="${usage.status == 'RETURN_PENDING'}"><article class="panel"><header class="panel-header"><div class="panel-title"><h3>Xác nhận trả thiết bị</h3></div></header><form method="post"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="action" value="confirmReturn"><input type="hidden" name="usageId" value="${usage.assetUsageId}"><div class="form-grid"><div class="form-group"><label for="verifiedCondition">Tình trạng xác minh *</label><select class="form-control" id="verifiedCondition" name="verifiedCondition" required><option value="GOOD">Tốt</option><option value="FAIR">Khá</option><option value="DAMAGED">Hư hỏng</option><option value="BROKEN">Không hoạt động</option></select></div><div class="form-group full-width"><label for="note">Ghi chú xác minh</label><textarea class="form-control" id="note" name="note"></textarea></div><button class="primary-button" type="submit">Xác nhận hoàn trả</button></div></form></article></c:if>
            <c:if test="${usage.status == 'RETURNED' && (usage.verifiedConditionAfter == 'DAMAGED' || usage.verifiedConditionAfter == 'BROKEN')}"><a class="primary-button" href="${pageContext.request.contextPath}/mentor/incidents/new?usageId=${usage.assetUsageId}">Tạo báo cáo sự cố</a></c:if>
        </section>
    </main>
</div>
</body>
</html>
