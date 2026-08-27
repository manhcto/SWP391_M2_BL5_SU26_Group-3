<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển người hướng dẫn | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css?v=dashboard-20260824">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<c:set var="totalInterns" value="0"/>
<c:forEach var="internList" items="${approvedInternLists}"><c:set var="totalInterns" value="${totalInterns + internList.studentCount}"/></c:forEach>
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

            <section class="stats-grid dashboard-kpi-grid" aria-label="Chỉ số cần theo dõi">
                <div class="stat-card stat-blue"><div class="stat-icon"><svg><use href="#i-calendar"/></svg></div><div><strong><c:out value="${activeUsageCount}"/></strong><span>Thiết bị đang được mượn</span><small>Trong các nhóm thực tập sinh bạn phụ trách</small></div></div>
                <div class="stat-card stat-gold"><div class="stat-icon"><svg><use href="#i-calendar"/></svg></div><div><strong><c:out value="${overdueUsageCount}"/></strong><span>Lượt sử dụng quá hạn</span><small>Cần nhắc thực tập sinh trả thiết bị</small></div></div>
                <div class="stat-card stat-purple"><div class="stat-icon"><svg><use href="#i-alert"/></svg></div><div><strong><c:out value="${damagedReturnCount}"/></strong><span>Lượt trả có ghi nhận hỏng</span><small>Ưu tiên kiểm tra và xử lý theo quy định</small></div></div>
                <div class="stat-card stat-gold"><div class="stat-icon"><svg><use href="#i-alert"/></svg></div><div><strong><c:out value="${openIncidentCount}"/></strong><span>Sự cố lớn đang xử lý</span><small>Đã gửi Lab Manager tiếp nhận</small></div></div>
            </section>
            <section class="analytics-grid mentor-analytics" aria-label="Báo cáo nhóm thực tập sinh">
                <article class="panel analytics-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Tiến độ sử dụng thiết bị</h3></div></header>
                    <div class="bar-report">
                        <div><span>Đang sử dụng</span><b><i class="bar-fill blue" style="--bar: ${mentorUsageCount == 0 ? 0 : activeUsageCount * 100 / mentorUsageCount}%"></i></b><strong><c:out value="${activeUsageCount}"/></strong></div>
                        <div><span>Đã trả</span><b><i class="bar-fill green" style="--bar: ${mentorUsageCount == 0 ? 0 : returnedUsageCount * 100 / mentorUsageCount}%"></i></b><strong><c:out value="${returnedUsageCount}"/></strong></div>
                        <div><span>Trả có ghi nhận hỏng</span><b><i class="bar-fill red" style="--bar: ${mentorUsageCount == 0 ? 0 : damagedReturnCount * 100 / mentorUsageCount}%"></i></b><strong><c:out value="${damagedReturnCount}"/></strong></div>
                    </div>
                </article>
                <article class="panel analytics-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Tỷ lệ trả đúng hạn</h3></div><strong class="report-value"><c:out value="${returnedOnTimePercent}"/>%</strong></header>
                    <div class="ring-report">
                        <div class="percentage-ring green" style="--value: ${returnedOnTimePercent}%"><strong><c:out value="${returnedOnTimePercent}"/>%</strong><span>đúng hạn</span></div>
                        <p>Được tính trên các lượt đã trả của thực tập sinh trong nhóm bạn phụ trách.</p>
                    </div>
                </article>
                <article class="panel analytics-panel report-alerts">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-alert"/></svg></span><h3>Ưu tiên hôm nay</h3></div></header>
                    <div class="report-alert-list">
                        <div><span>Lượt sử dụng quá hạn</span><strong><c:out value="${overdueUsageCount}"/></strong></div>
                        <div><span>Sự cố lớn đang xử lý</span><strong><c:out value="${openIncidentCount}"/></strong></div>
                        <div><span>Danh sách chờ duyệt</span><strong><c:out value="${pendingInternListCount}"/></strong></div>
                    </div>
                </article>
            </section>
            <section class="dashboard-grid mentor-dashboard-grid">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Danh sách thực tập sinh đã duyệt</h3></div><a href="${pageContext.request.contextPath}/mentor/interns">Xem tất cả</a></header>
                    <c:choose>
                        <c:when test="${empty approvedInternLists}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-clipboard"/></svg></div><h3>Chưa có danh sách thực tập sinh được duyệt</h3><p>Tạo danh sách thực tập sinh và gửi quản trị viên phê duyệt.</p><a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns/add">Tạo danh sách thực tập sinh</a></div></c:when>
                        <c:otherwise><div class="table-scroll"><table><thead><tr><th>Danh sách</th><th>Học kỳ</th><th>Thực tập sinh</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach var="internList" items="${approvedInternLists}"><tr><td><strong><c:out value="${internList.groupName}"/></strong></td><td><c:out value="${internList.semesterCode}"/></td><td><c:out value="${internList.studentCount}"/></td><td><span class="status returned">Đã duyệt</span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/interns/view?id=${internList.requestId}">Xem</a></td></tr></c:forEach></tbody></table></div></c:otherwise>
                    </c:choose>
                </article>

                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Thao tác nhanh</h3></div></header>
                    <div class="mentor-actions">
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/interns/add"><span class="mentor-action-icon"><svg><use href="#i-plus"/></svg></span><span><strong>Tạo danh sách thực tập sinh</strong><small>Chuẩn bị danh sách cho học kỳ</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/inspections/new"><span class="mentor-action-icon gold"><svg><use href="#i-inspect"/></svg></span><span><strong>Tạo đợt kiểm tra</strong><small>Kiểm tra thiết bị và số lượng trong phòng LAB</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/maintenance/add"><span class="mentor-action-icon rose"><svg><use href="#i-wrench"/></svg></span><span><strong>Đề xuất bảo trì</strong><small>Gửi yêu cầu bảo trì thiết bị</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/incidents/new"><span class="mentor-action-icon rose"><svg><use href="#i-alert"/></svg></span><span><strong>Báo cáo sự cố lớn</strong><small>Gửi Lab Manager tiếp nhận và xử lý</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/responsibilities"><span class="mentor-action-icon"><svg><use href="#i-list"/></svg></span><span><strong>Trách nhiệm</strong><small>Xem kết luận và quyết định</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/maintenance"><span class="mentor-action-icon rose"><svg><use href="#i-wrench"/></svg></span><span><strong>Theo dõi bảo trì</strong><small>Xem tiến độ các phiếu bảo trì</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
