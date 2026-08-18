<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển người hướng dẫn | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<c:set var="totalInterns" value="0"/>
<c:forEach var="internList" items="${approvedRequests}"><c:set var="totalInterns" value="${totalInterns + internList.studentCount}"/></c:forEach>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Bảng điều khiển người hướng dẫn</h1><p>Quản lý danh sách thực tập sinh, kiểm tra và hồ sơ thiết bị phòng LAB</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG NGƯỜI HƯỚNG DẪN</p><h2>Xin chào, <c:out value="${currentUser.fullName}"/></h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns"><svg><use href="#i-clipboard"/></svg>Quản lý danh sách thực tập sinh</a>
            </div>

            <section class="stats-grid" aria-label="Tổng quan công việc của người hướng dẫn">
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/mentor/interns">
                    <div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong><c:out value="${approvedRequests.size()}"/></strong><span>Danh sách đã duyệt</span><small>Danh sách học kỳ đã được phê duyệt</small></div>
                </a>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/mentor/interns">
                    <div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${totalInterns}"/></strong><span>Thực tập sinh đang hoạt động</span><small>Trong các danh sách đã duyệt</small></div>
                </a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/mentor/inspections">
                    <div class="stat-icon"><svg><use href="#i-inspect"/></svg></div><div><strong>Rà soát</strong><span>Kiểm tra</span><small>Kiểm tra hồ sơ tài sản phòng LAB</small></div>
                </a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/mentor/maintenance">
                    <div class="stat-icon"><svg><use href="#i-wrench"/></svg></div><div><strong>Track</strong><span>Bảo trì</span><small>Theo dõi đề xuất thiết bị</small></div>
                </a>
            </section>

            <section class="dashboard-grid mentor-dashboard-grid">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Danh sách thực tập sinh đã duyệt</h3></div><a href="${pageContext.request.contextPath}/mentor/interns">Xem tất cả</a></header>
                    <c:choose>
                        <c:when test="${empty approvedRequests}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-clipboard"/></svg></div><h3>Chưa có danh sách thực tập sinh được duyệt</h3><p>Tạo danh sách thực tập sinh và gửi quản trị viên phê duyệt.</p><a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns/add">Tạo danh sách thực tập sinh</a></div></c:when>
                        <c:otherwise><div class="table-scroll"><table><thead><tr><th>Danh sách</th><th>Học kỳ</th><th>Thực tập sinh</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach var="internList" items="${approvedRequests}"><tr><td><strong><c:out value="${internList.groupName}"/></strong></td><td><c:out value="${internList.semesterCode}"/></td><td><c:out value="${internList.studentCount}"/></td><td><span class="status returned">Đã duyệt</span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/interns/view?id=${internList.requestId}">Xem</a></td></tr></c:forEach></tbody></table></div></c:otherwise>
                    </c:choose>
                </article>

                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Thao tác nhanh</h3></div></header>
                    <div class="mentor-actions">
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/interns/add"><span class="mentor-action-icon"><svg><use href="#i-plus"/></svg></span><span><strong>Tạo danh sách thực tập sinh</strong><small>Chuẩn bị danh sách cho học kỳ</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/inspections/new"><span class="mentor-action-icon gold"><svg><use href="#i-inspect"/></svg></span><span><strong>Tạo đợt kiểm tra</strong><small>Kiểm tra thiết bị và số lượng trong phòng LAB</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/maintenance/add"><span class="mentor-action-icon rose"><svg><use href="#i-wrench"/></svg></span><span><strong>Đề xuất bảo trì</strong><small>Gửi yêu cầu bảo trì thiết bị</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/responsibilities"><span class="mentor-action-icon"><svg><use href="#i-list"/></svg></span><span><strong>Trách nhiệm</strong><small>Xem kết luận và quyết định</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
