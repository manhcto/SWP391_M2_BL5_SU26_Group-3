<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sự cố | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="incidents" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Quản lý sự cố</h1>
                    <p>Theo dõi và phân loại các sự cố phát sinh trong phòng LAB</p>
                </div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG QUẢN LÝ PHÒNG LAB</p><h2>Danh sách sự cố (${incidents.size()})</h2></div>
            </div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/incidents">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>"
                           placeholder="Tìm theo mã, thiết bị hoặc người báo cáo" style="width:280px">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="OPEN" ${selectedStatus == 'OPEN' ? 'selected' : ''}>Đang mở</option>
                        <option value="INVESTIGATING" ${selectedStatus == 'INVESTIGATING' ? 'selected' : ''}>Đang xử lý</option>
                        <option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option>
                        <option value="CLOSED" ${selectedStatus == 'CLOSED' ? 'selected' : ''}>Đã đóng</option>
                    </select>
                    <select class="form-control" name="severity">
                        <option value="">Tất cả mức độ</option>
                        <option value="HIGH" ${selectedSeverity == 'HIGH' ? 'selected' : ''}>Cao</option>
                        <option value="CRITICAL" ${selectedSeverity == 'CRITICAL' ? 'selected' : ''}>Nghiêm trọng</option>
                    </select>
                    <button class="primary-button" type="submit">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/incidents">Đặt lại</a>
                </div>
            </form>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty incidents}">
                        <div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-alert"/></svg></div>
                            <h3>Chưa có sự cố</h3><p>Không có sự cố phù hợp với bộ lọc hiện tại.</p></div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead><tr><th>Mã sự cố</th><th>Thiết bị</th><th>Loại sự cố</th><th>Mức độ</th><th>Người báo cáo</th><th>Thời gian</th><th>Trạng thái</th><th>Mô tả</th><th>Thao tác</th></tr></thead>
                                <tbody>
                                <c:forEach var="incident" items="${incidents}">
                                    <tr>
                                        <td><strong>#INC-<c:out value="${incident.incidentId}"/></strong></td>
                                        <td><strong><c:out value="${incident.assetName}"/></strong><br><small><c:out value="${empty incident.assetItemCode ? incident.assetCode : incident.assetItemCode}"/></small></td>
                                        <td><c:out value="${app:label(incident.incidentType)}"/></td>
                                        <td><span class="status ${incident.severity == 'CRITICAL' || incident.severity == 'HIGH' ? 'open' : 'review'}"><c:out value="${app:label(incident.severity)}"/></span></td>
                                        <td><c:out value="${incident.reporterName}"/><c:if test="${not empty incident.internName}"><br><small>Thực tập sinh: <c:out value="${incident.internName}"/></small></c:if></td>
                                        <td><c:out value="${app:dateTime(incident.reportedAt)}"/></td>
                                        <td><span class="status ${incident.status == 'OPEN' ? 'open' : incident.status == 'RESOLVED' || incident.status == 'CLOSED' ? 'returned' : 'review'}"><c:out value="${app:label(incident.status)}"/></span></td>
                                        <td class="wrap-cell"><c:out value="${incident.description}"/></td>
                                        <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/lab-manager/incidents/${incident.incidentId}">${incident.status == 'OPEN' ? 'Xử lý' : 'Xem'}</a></td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer"><span>Hiển thị ${incidents.size()} sự cố</span></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
