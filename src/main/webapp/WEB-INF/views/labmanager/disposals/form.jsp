<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Tạo yêu cầu thanh lý | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Tạo yêu cầu thanh lý</h1><p>Bắt đầu quy trình thanh lý thiết bị có kiểm soát</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Quay lại danh sách thanh lý</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">QUY TRÌNH THANH LÝ MỚI</p><h2>Thanh lý thiết bị</h2></div></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-trash"/></svg></span><h3>Thông tin thanh lý</h3></div></header><form method="post"><input type="hidden" name="action" value="create"><div class="form-grid"><div class="form-group full-width"><label for="assetId">Thiết bị đủ điều kiện</label><select class="form-control" id="assetId" name="assetId" required><c:forEach items="${assets}" var="a"><option value="${a.assetId}"><c:out value="${a.assetCode}"/> · <c:out value="${a.assetName}"/> · tổng số lượng ${a.totalQuantity}</option></c:forEach></select><small>Không hiển thị thiết bị đã thanh lý hoặc đang có yêu cầu thanh lý.</small></div><div class="form-group full-width"><label for="reason">Lý do thanh lý</label><textarea class="form-control" id="reason" name="reason" placeholder="Giải thích lý do thiết bị không còn an toàn hoặc hiệu quả để sử dụng" required></textarea></div><div class="form-group full-width form-actions"><button class="primary-button" type="submit" <c:if test="${empty assets}">disabled</c:if>>Tạo yêu cầu chờ xử lý</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Hủy</a></div></div></form><c:if test="${empty assets}"><div class="empty-box"><p>Hiện không có thiết bị đủ điều kiện thanh lý.</p></div></c:if></article>
        </section>
    </main>
</div>
</body>
</html>
