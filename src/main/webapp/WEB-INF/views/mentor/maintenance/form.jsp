<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tạo yêu cầu bảo trì | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Tạo yêu cầu bảo trì</h1><p>Yêu cầu chỉ áp dụng cho đúng một thiết bị theo mã riêng.</p></div></div>
            <div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Quay lại</a></div>
        </header>
        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty assetItems}"><div class="empty-box"><h3>Không có thiết bị đủ điều kiện</h3><p>Thiết bị đang sử dụng, bảo trì, thanh lý hoặc có yêu cầu mở không thể tạo thêm yêu cầu.</p></div></c:when>
                    <c:otherwise><form class="form-grid" method="post" action="${pageContext.request.contextPath}/mentor/maintenance">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="create">
                        <div class="form-group full-width"><label for="assetItemId">Thiết bị theo mã riêng *</label><select class="form-control" id="assetItemId" name="assetItemId" required><option value="">Chọn thiết bị</option><c:forEach var="item" items="${assetItems}"><option value="${item.assetItemId}" ${param.assetItemId == item.assetItemId ? 'selected' : ''}><c:out value="${item.itemCode}"/> · <c:out value="${item.assetName}"/> · <c:out value="${app:label(item.condition)}"/></option></c:forEach></select></div>
                        <div class="form-group"><label for="incidentId">Sự cố liên quan</label><select class="form-control" id="incidentId" name="incidentId"><option value="">Không liên kết sự cố</option><c:forEach var="incident" items="${incidents}"><option value="${incident.incidentId}" ${param.incidentId == incident.incidentId ? 'selected' : ''}>#INC-<c:out value="${incident.incidentId}"/> · <c:out value="${incident.assetItemCode}"/> · <c:out value="${incident.description}"/></option></c:forEach></select><small>Hệ thống kiểm tra sự cố phải thuộc đúng thiết bị đã chọn.</small></div>
                        <div class="form-group full-width"><label for="description">Mô tả yêu cầu sửa chữa *</label><textarea class="form-control" id="description" name="description" maxlength="2000" rows="6" required><c:out value="${param.description}"/></textarea></div>
                        <div class="form-actions"><button class="primary-button" type="submit">Gửi yêu cầu</button><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Hủy</a></div>
                    </form></c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
