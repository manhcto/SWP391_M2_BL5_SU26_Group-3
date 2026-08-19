<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bảng điều khiển thực tập sinh | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Bảng điều khiển thực tập sinh</h1><p>Theo dõi thiết bị, việc trả thiết bị và hồ sơ trách nhiệm</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG THỰC TẬP SINH</p><h2>Xin chào, <c:out value="${currentUser.fullName}"/></h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/intern/usages/borrow"><svg><use href="#i-box"/></svg>Mượn thiết bị</a>
            </div>

            <section class="stats-grid" aria-label="Tổng quan hoạt động của tôi tại phòng LAB">
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-box"/></svg></div>
                    <div><strong><c:out value="${activeUsageCount}"/></strong><span>Thiết bị đang mượn</span><small>Thiết bị đang được sử dụng</small></div>
                </a>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-calendar"/></svg></div>
                    <div><strong><c:out value="${returnedUsageCount}"/></strong><span>Thiết bị đã trả</span><small>Các lượt trả đã hoàn tất</small></div>
                </a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/intern/responsibilities">
                    <div class="stat-icon"><svg><use href="#i-list"/></svg></div>
                    <div><strong><c:out value="${responsibilityCount}"/></strong><span>Trách nhiệm</span><small>Kết luận và quyết định của người hướng dẫn</small></div>
                </a>
                <div class="stat-card stat-purple">
                    <div class="stat-icon"><svg><use href="#i-alert"/></svg></div>
                    <div><strong><c:out value="${reportedIncidentCount}"/></strong><span>Sự cố đã báo cáo</span><small>Các sự cố lớn bạn đã gửi để xử lý</small></div>
                </div>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-grid"/></svg></div>
                    <div><strong><c:out value="${totalUsageCount}"/></strong><span>Tổng lượt sử dụng</span><small>Tất cả lịch sử mượn</small></div>
                </a>
            </section>

            <section class="dashboard-grid intern-dashboard-grid">
                <article class="panel">
                    <header class="panel-header">
                        <div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Sử dụng thiết bị gần đây</h3></div>
                        <a href="${pageContext.request.contextPath}/intern/usages">Xem tất cả</a>
                    </header>
                    <div class="table-scroll">
                        <table>
                            <thead><tr><th>Thiết bị</th><th>Số lượng</th><th>Thời gian mượn</th><th>Hạn trả</th><th>Trạng thái</th><th></th></tr></thead>
                            <tbody>
                            <c:choose>
                                <c:when test="${empty usages}"><tr><td colspan="6">Chưa có lịch sử sử dụng thiết bị.</td></tr></c:when>
                                <c:otherwise>
                                    <c:forEach var="usage" items="${usages}" end="4">
                                        <tr>
                                            <td><strong><c:out value="${usage.assetName}"/></strong><br><small><c:out value="${usage.assetCode}"/></small></td>
                                            <td><c:out value="${usage.quantity}"/></td>
                                            <td><c:out value="${app:dateTime(usage.borrowedAt)}"/></td>
                                            <td><c:out value="${app:dateTime(usage.dueAt)}"/></td>
                                            <td><span class="status ${usage.status == 'RETURNED' ? 'returned' : 'review'}"><c:out value="${app:label(usage.status)}"/></span></td>
                                            <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/usages/${usage.assetUsageId}">Xem</a></td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                            </tbody>
                        </table>
                    </div>
                </article>

                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Thao tác nhanh</h3></div></header>
                    <div class="intern-actions">
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/usages/borrow"><span class="intern-action-icon"><svg><use href="#i-box"/></svg></span><span><strong>Mượn thiết bị</strong><small>Chọn thiết bị đang sẵn sàng trong phòng LAB</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/usages"><span class="intern-action-icon blue"><svg><use href="#i-calendar"/></svg></span><span><strong>Lịch sử sử dụng</strong><small>Xem lịch sử mượn và trả</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/responsibilities"><span class="intern-action-icon gold"><svg><use href="#i-list"/></svg></span><span><strong>Trách nhiệm của tôi</strong><small>Xem kết luận và quyết định</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
