<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Trách nhiệm #${responsibility.responsibilityCode} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Chi tiết trách nhiệm</h1>
                    <p>Kết luận kỹ thuật, đánh giá của Mentor và khuyến nghị xử lý liên quan.</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">‹ Quay lại</a>
                <c:if test="${not empty responsibility.technicalAssessedAt}">
                    <a class="primary-button" href="${pageContext.request.contextPath}/mentor/responsibilities/${responsibility.responsibilityId}/edit">Sửa</a>
                </c:if>
            </div>
        </header>
        <section class="content-area">
            <c:if test="${not empty param.success}">
                <div class="success-message">Đã lưu đánh giá trách nhiệm.</div>
            </c:if>
            <%@ include file="../../shared/responsibility-detail.jspf" %>
        </section>
    </main>
</div>
</body>
</html>
