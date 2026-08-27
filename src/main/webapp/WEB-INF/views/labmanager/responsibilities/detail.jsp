<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trách nhiệm #${responsibility.responsibilityCode} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page"><c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Chi tiết trách nhiệm</h1>
                    <p>Xem Intern được gán, mức trách nhiệm và căn cứ xử lý</p></div>
            </div>
            <div class="topbar-actions">
                <a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/responsibilities/${responsibility.responsibilityId}/edit">Gán / cập nhật trách nhiệm</a>
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities">‹ Quay lại danh sách trách nhiệm</a>
            </div>
        </header>
        <section class="content-area">
            <c:if test="${param.success == 'assign' || param.success == 'create'}">
                <div class="success-message"><c:choose><c:when test="${param.success == 'create'}">Đã tạo và gán trách nhiệm cho Intern thành công.</c:when><c:otherwise>Đã cập nhật trách nhiệm của Intern thành công.</c:otherwise></c:choose></div>
            </c:if>
            <%@ include file="../../shared/responsibility-detail.jspf" %>
        </section>
    </main>
</div>
</body>
</html>
