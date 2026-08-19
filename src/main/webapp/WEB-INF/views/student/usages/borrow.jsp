<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mượn thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="borrow" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Mượn thiết bị</h1><p>Yêu cầu thiết bị trong học kỳ thực tập đã được phê duyệt</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG THỰC TẬP SINH</p><h2>Yêu cầu mượn mới</h2></div><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Quay lại lịch sử</a></div>
            <c:if test="${not empty message}"><p class="error-message"><c:out value="${message}"/></p></c:if>
            <article class="panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-box"/></svg></span><h3>Thông tin thiết bị</h3></div></header>
                <form method="post">
                    <input type="hidden" name="action" value="borrow">
                    <div class="form-grid">
                        <div class="form-group full-width"><label for="assetId">Thiết bị</label><select class="form-control" id="assetId" name="assetId" required><c:forEach items="${assets}" var="a"><option value="${a.assetId}"><c:out value="${a.assetCode}"/> · <c:out value="${a.assetName}"/> · ${a.totalQuantity} tổng cộng</option></c:forEach></select></div>
                        <div class="form-group"><label for="quantity">Số lượng</label><input class="form-control" id="quantity" type="number" name="quantity" min="1" value="1" required></div>
                        <div class="form-group"><label>Hạn trả</label><input class="form-control readonly-field" value="Kết thúc học kỳ đã được phê duyệt" readonly></div>
                        <div class="form-group full-width"><label for="note">Ghi chú sử dụng</label><textarea class="form-control" id="note" name="note" placeholder="Mục đích hoặc lưu ý sử dụng"></textarea></div>
                        <div class="form-group full-width form-actions"><button class="primary-button" type="submit" <c:if test="${empty assets}">disabled</c:if>><svg><use href="#i-box"/></svg>Xác nhận mượn</button></div>
                    </div>
                </form>
                <c:if test="${empty assets}"><div class="empty-box"><p>Không có thiết bị đủ điều kiện để mượn.</p></div></c:if>
            </article>
        </section>
    </main>
</div>
</body>
</html>
