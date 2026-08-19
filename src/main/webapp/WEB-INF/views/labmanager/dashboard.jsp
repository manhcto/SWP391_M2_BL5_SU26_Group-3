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
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/assets"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong><c:out value="${assetCount}"/></strong><span>Tài sản phòng LAB</span><small><c:out value="${availableAssetCount}"/> thiết bị đang sẵn sàng</small></div></a>
                <div class="stat-card stat-gold"><div class="stat-icon"><svg><use href="#i-wrench"/></svg></div><div><strong><c:out value="${maintenanceAssetCount}"/></strong><span>Thiết bị đang bảo trì</span><small>Theo tình trạng tài sản hiện tại</small></div></div>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/lab-manager/usages"><div class="stat-icon"><svg><use href="#i-calendar"/></svg></div><div><strong><c:out value="${activeUsageCount}"/></strong><span>Lượt sử dụng đang mở</span><small>Thiết bị chưa được trả</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/inspections"><div class="stat-icon"><svg><use href="#i-inspect"/></svg></div><div><strong><c:out value="${inspectionCount}"/></strong><span>Kiểm tra và kiểm kê</span><small>Tất cả đợt kiểm tra đã ghi nhận</small></div></a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/lab-manager/incidents"><div class="stat-icon"><svg><use href="#i-alert"/></svg></div><div><strong><c:out value="${incidentCount}"/></strong><span>Sự cố lớn</span><small>Cần Lab Manager theo dõi xử lý</small></div></a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/labmanager/maintenance"><div class="stat-icon"><svg><use href="#i-wrench"/></svg></div><div><strong><c:out value="${openMaintenanceCount}"/></strong><span>Phiếu bảo trì đang mở</span><small>Chưa hoàn tất hoặc từ chối</small></div></a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/lab-manager/disposals"><div class="stat-icon"><svg><use href="#i-trash"/></svg></div><div><strong><c:out value="${pendingDisposalCount}"/></strong><span>Yêu cầu thanh lý chờ xử lý</span><small>Cần xác nhận trước khi hoàn tất</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/responsibilities"><div class="stat-icon"><svg><use href="#i-list"/></svg></div><div><strong>Trách nhiệm</strong><span>Xem kết luận và quyết định xử lý của người hướng dẫn</span><small>Mở hồ sơ trách nhiệm</small></div></a>
            </div>
            <section class="dashboard-grid">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-alert"/></svg></span><h3>Sự cố lớn gần đây</h3></div><a href="${pageContext.request.contextPath}/lab-manager/incidents">Xem tất cả</a></header>
                    <div class="table-scroll"><table><thead><tr><th>Mã sự cố</th><th>Thiết bị</th><th>Mức độ</th><th>Trạng thái</th><th></th></tr></thead><tbody><c:choose><c:when test="${empty recentIncidents}"><tr><td colspan="5">Chưa có sự cố lớn cần theo dõi.</td></tr></c:when><c:otherwise><c:forEach var="incident" items="${recentIncidents}" end="4"><tr><td><strong>#INC-<c:out value="${incident.incidentId}"/></strong></td><td><c:out value="${incident.assetName}"/><br><small><c:out value="${incident.assetCode}"/></small></td><td><span class="severity ${incident.severity.toLowerCase()}"><c:out value="${app:label(incident.severity)}"/></span></td><td><span class="status ${incident.status == 'OPEN' ? 'open' : incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/lab-manager/incidents">Xem</a></td></tr></c:forEach></c:otherwise></c:choose></tbody></table></div>
                </article>
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Thao tác nhanh</h3></div></header>
                    <div class="intern-actions">
                        <a class="intern-action" href="${pageContext.request.contextPath}/lab-manager/usages"><span class="intern-action-icon"><svg><use href="#i-calendar"/></svg></span><span><strong>Sử dụng thiết bị</strong><small>Xem toàn bộ lượt mượn và trả</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/lab-manager/assets"><span class="intern-action-icon blue"><svg><use href="#i-box"/></svg></span><span><strong>Quản lý thiết bị</strong><small>Quản lý từng sản phẩm và mã riêng</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/lab-manager/inspections"><span class="intern-action-icon blue"><svg><use href="#i-inspect"/></svg></span><span><strong>Kiểm tra và kiểm kê</strong><small>Mở danh sách các đợt kiểm tra</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/lab-manager/incidents"><span class="intern-action-icon blue"><svg><use href="#i-alert"/></svg></span><span><strong>Sự cố</strong><small>Theo dõi các sự cố lớn</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/labmanager/maintenance"><span class="intern-action-icon gold"><svg><use href="#i-wrench"/></svg></span><span><strong>Bảo trì</strong><small>Duyệt và cập nhật phiếu sửa chữa</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/lab-manager/disposals"><span class="intern-action-icon"><svg><use href="#i-trash"/></svg></span><span><strong>Thanh lý</strong><small>Xử lý yêu cầu thanh lý thiết bị</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
