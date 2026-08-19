<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển quản trị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
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
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/admin/users?role=INTERN"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${internCount}"/></strong><span>Thực tập sinh</span><small>Quản lý tài khoản thực tập sinh</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/admin/users?role=MENTOR"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${mentorCount}"/></strong><span>Người hướng dẫn</span><small>Quản lý tài khoản người hướng dẫn</small></div></a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/admin/users?role=LAB_MANAGER"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${labManagerCount}"/></strong><span>Quản lý phòng LAB</span><small>Quản lý tài khoản quản lý phòng LAB</small></div></a>
<a class="stat-card stat-gold" href="${pageContext.request.contextPath}/admin/interns?status=PENDING"><div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong><c:out value="${pendingInternListCount}"/></strong><span>Danh sách chờ duyệt</span><small>Phê duyệt hoặc từ chối danh sách do người hướng dẫn gửi</small></div></a>
            </div>
        </section>
    </main>
</div>
</body>
</html>
