<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Báo cáo sự cố | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../../student/includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Báo cáo sự cố</h1><p>Gửi sự cố về thiết bị trong lượt sử dụng của bạn</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/incidents">‹ Quay lại danh sách</a></div></header>
        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <form class="form-grid" method="post" action="${pageContext.request.contextPath}/intern/incidents">
                    <input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="action" value="create">
                    <div class="form-group full-width"><label for="usageId">Lượt sử dụng liên quan *</label><select class="form-control" id="usageId" name="usageId" required><option value="">-- Chọn thiết bị bạn đã sử dụng --</option><c:forEach var="usage" items="${usages}"><option value="${usage.assetUsageId}" ${param.usageId == usage.assetUsageId ? 'selected' : ''}><c:out value="${usage.assetName}"/> · <c:out value="${usage.assetCode}"/><c:if test="${not empty usage.assetItemTag}"> · <c:out value="${usage.assetItemTag}"/></c:if> · <c:out value="${usage.status}"/></option></c:forEach></select><small>Thiết bị, vật dụng và quan hệ sử dụng được kiểm tra lại trên máy chủ.</small></div>
                    <div class="form-group"><label for="incidentType">Loại sự cố *</label><select class="form-control" id="incidentType" name="incidentType" required><option value="DAMAGE" ${param.incidentType == 'DAMAGE' ? 'selected' : ''}>Hư hỏng</option><option value="MALFUNCTION" ${param.incidentType == 'MALFUNCTION' ? 'selected' : ''}>Trục trặc</option><option value="MISSING" ${param.incidentType == 'MISSING' ? 'selected' : ''}>Thiếu thiết bị</option><option value="LOSS" ${param.incidentType == 'LOSS' ? 'selected' : ''}>Mất thiết bị</option><option value="OTHER" ${param.incidentType == 'OTHER' ? 'selected' : ''}>Khác</option></select></div>
                    <div class="form-group"><label for="severity">Mức độ *</label><select class="form-control" id="severity" name="severity" required><option value="LOW" ${empty param.severity || param.severity == 'LOW' ? 'selected' : ''}>Thấp</option><option value="MEDIUM" ${param.severity == 'MEDIUM' ? 'selected' : ''}>Trung bình</option><option value="HIGH" ${param.severity == 'HIGH' ? 'selected' : ''}>Cao</option><option value="CRITICAL" ${param.severity == 'CRITICAL' ? 'selected' : ''}>Nghiêm trọng</option></select></div>
                    <div class="form-group full-width"><label for="occurredAt">Thời điểm xảy ra</label><input class="form-control" id="occurredAt" type="datetime-local" name="occurredAt" value="<c:out value='${param.occurredAt}'/>"></div>
                    <div class="form-group full-width"><label for="description">Mô tả sự cố *</label><textarea class="form-control" id="description" name="description" rows="5" maxlength="2000" required placeholder="Mô tả hiện tượng, thời điểm và ảnh hưởng tới việc sử dụng."><c:out value="${param.description}"/></textarea></div>
                    <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Gửi Mentor duyệt</button><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/incidents">Hủy</a></div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
