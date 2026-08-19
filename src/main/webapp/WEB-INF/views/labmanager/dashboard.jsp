<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển quản lý phòng LAB | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Bảng điều khiển quản lý phòng LAB</h1><p>Theo dõi thiết bị và hoạt động bảo trì của phòng LAB</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG QUẢN LÝ PHÒNG LAB</p><h2>Tổng quan vận hành</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/assets"><svg><use href="#i-box"/></svg>Quản lý thiết bị</a></div>
            <div class="stats-grid">
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/lab-manager/assets"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>Thiết bị</strong><span>Quản lý từng sản phẩm và mã riêng</span><small>Mở danh sách thiết bị</small></div></a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/labmanager/maintenance"><div class="stat-icon"><svg><use href="#i-wrench"/></svg></div><div><strong>Bảo trì</strong><span>Duyệt và cập nhật phiếu sửa chữa</span><small>Mở quản lý bảo trì</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/usages"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>Sử dụng thiết bị</strong><span>Xem lịch sử mượn và trả thiết bị</span><small>Mở lịch sử sử dụng thiết bị</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/responsibilities"><div class="stat-icon"><svg><use href="#i-list"/></svg></div><div><strong>Trách nhiệm</strong><span>Xem kết luận và quyết định xử lý của người hướng dẫn</span><small>Mở hồ sơ trách nhiệm</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/disposals"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>Thanh lý</strong><span>Xem yêu cầu thanh lý thiết bị</span><small>Mở quản lý thanh lý</small></div></a>
            </div>
        </section>
    </main>
</div>
</body>
</html>
