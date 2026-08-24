<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển quản trị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css?v=dashboard-20260824">
</head>
<body class="admin-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Bảng điều khiển quản trị</h1><p>Quản lý tài khoản thực tập sinh, người hướng dẫn, quản lý phòng LAB và danh sách thực tập sinh</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">AD</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG QUẢN TRỊ</p><h2>Quản lý người dùng và danh sách thực tập sinh</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/admin/interns"><svg><use href="#i-clipboard"/></svg>Duyệt danh sách thực tập sinh</a></div>
            <div class="stats-grid">
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/admin/users"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${accountCount}"/></strong><span>Tổng tài khoản</span><small>Tất cả tài khoản có quyền truy cập hệ thống</small></div></a>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/admin/users?status=ACTIVE"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${activeAccountCount}"/></strong><span>Tài khoản hoạt động</span><small>Đang có thể đăng nhập hệ thống</small></div></a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/admin/users?status=INACTIVE"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${inactiveAccountCount}"/></strong><span>Tài khoản tạm khóa</span><small>Cần quản trị viên kiểm tra trạng thái</small></div></a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/admin/interns?status=PENDING"><div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong><c:out value="${pendingInternListCount}"/></strong><span>Danh sách chờ duyệt</span><small>Phê duyệt hoặc từ chối danh sách do người hướng dẫn gửi</small></div></a>
            </div>
            <section class="analytics-grid" aria-label="Báo cáo thống kê tài khoản">
                <article class="panel analytics-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Tỷ lệ tài khoản hoạt động</h3></div><strong class="report-value"><c:out value="${activeAccountPercent}"/>%</strong></header>
                    <div class="ring-report">
                        <div class="percentage-ring green" style="--value: ${activeAccountPercent}%"><strong><c:out value="${activeAccountPercent}"/>%</strong><span>hoạt động</span></div>
                        <p><c:out value="${activeAccountCount}"/> trong <c:out value="${accountCount}"/> tài khoản có thể truy cập hệ thống.</p>
                    </div>
                </article>
                <article class="panel analytics-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Phân bổ theo vai trò</h3></div></header>
                    <div class="bar-report">
                        <div><span>Thực tập sinh</span><b><i class="bar-fill blue" style="--bar: ${internPercent}%"></i></b><strong><c:out value="${internCount}"/></strong></div>
                        <div><span>Người hướng dẫn</span><b><i class="bar-fill green" style="--bar: ${mentorPercent}%"></i></b><strong><c:out value="${mentorCount}"/></strong></div>
                        <div><span>Quản lý phòng LAB</span><b><i class="bar-fill purple" style="--bar: ${labManagerPercent}%"></i></b><strong><c:out value="${labManagerCount}"/></strong></div>
                    </div>
                </article>
            </section>
            <section class="dashboard-grid">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-clipboard"/></svg></span><h3>Danh sách thực tập sinh chờ duyệt</h3></div><a href="${pageContext.request.contextPath}/admin/interns?status=PENDING">Xem tất cả</a></header>
                    <div class="table-scroll"><table><thead><tr><th>Danh sách</th><th>Người hướng dẫn</th><th>Học kỳ</th><th>Thực tập sinh</th><th></th></tr></thead><tbody><c:choose><c:when test="${empty pendingInternLists}"><tr><td colspan="5">Không có danh sách thực tập sinh chờ duyệt.</td></tr></c:when><c:otherwise><c:forEach var="internList" items="${pendingInternLists}" end="4"><tr><td><strong><c:out value="${internList.groupName}"/></strong></td><td><c:out value="${internList.mentorName}"/></td><td><c:out value="${internList.semesterCode}"/></td><td><c:out value="${internList.studentCount}"/></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/admin/interns/view?id=${internList.requestId}">Xem</a></td></tr></c:forEach></c:otherwise></c:choose></tbody></table></div>
                </article>
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Thao tác nhanh</h3></div></header>
                    <div class="mentor-actions">
                        <a class="mentor-action" href="${pageContext.request.contextPath}/admin/users"><span class="mentor-action-icon"><svg><use href="#i-users"/></svg></span><span><strong>Quản lý người dùng</strong><small>Xem tài khoản và trạng thái truy cập</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/admin/users/add"><span class="mentor-action-icon"><svg><use href="#i-plus"/></svg></span><span><strong>Thêm người dùng</strong><small>Tạo tài khoản cho vai trò hệ thống</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/admin/interns?status=PENDING"><span class="mentor-action-icon gold"><svg><use href="#i-clipboard"/></svg></span><span><strong>Duyệt danh sách thực tập sinh</strong><small>Xem các danh sách đang chờ quyết định</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
