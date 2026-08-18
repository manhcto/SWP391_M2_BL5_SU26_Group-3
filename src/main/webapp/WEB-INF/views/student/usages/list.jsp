<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lịch sử sử dụng thiết bị của tôi | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Lịch sử sử dụng thiết bị của tôi</h1><p>Theo dõi thiết bị đang mượn và lịch sử trả</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG THỰC TẬP SINH</p><h2>Lịch sử sử dụng</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/intern/usages/borrow"><svg><use href="#i-box"/></svg>Mượn thiết bị</a>
            </div>
            <c:if test="${not empty message}"><p class="success-message"><c:out value="${message}"/></p></c:if>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty usages}">
                        <div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-calendar"/></svg></div><h3>Chưa có lịch sử sử dụng</h3><p>Mượn thiết bị trong học kỳ đã được phê duyệt.</p></div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead><tr><th>Mã lượt sử dụng</th><th>Thiết bị</th><th>Số lượng</th><th>Thời gian mượn</th><th>Hạn trả</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
                                <tbody><c:forEach items="${usages}" var="u"><tr>
                                    <td>#AU-${u.assetUsageId}</td>
                                    <td><strong><c:out value="${u.assetName}"/></strong><br><small><c:out value="${u.assetCode}"/></small></td>
                                    <td><c:out value="${u.quantity}"/></td><td><c:out value="${app:dateTime(u.borrowedAt)}"/></td><td><c:out value="${app:dateTime(u.dueAt)}"/></td>
                                    <td><span class="status ${u.status == 'RETURNED' ? 'returned' : 'in-use'}"><c:out value="${app:label(u.status)}"/></span></td>
                                    <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/usages/${u.assetUsageId}">Xem</a></td>
                                </tr></c:forEach></tbody>
                            </table>
                        </div>
                        <div class="table-footer"><span>Hiển thị ${usages.size()} lượt sử dụng</span></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
