<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
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
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"
                        aria-controls="sidebar" aria-expanded="false">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Lịch sử sử dụng thiết bị của tôi</h1>
                    <p>Theo dõi thiết bị đang mượn và lịch sử trả</p></div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">IN</div>
                    <span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG INTERN</p>
                    <h2>Lịch sử sử dụng</h2></div>
                <c:if test="${permissions.allows('ASSET_USAGE_BORROW')}"><a class="primary-button"
                                                                            href="${pageContext.request.contextPath}/intern/usages/borrow">
                    <svg>
                        <use href="#i-box"/>
                    </svg>
                    Mượn thiết bị</a></c:if></div>
            <c:if test="${not empty message}"><p class="error-message"><c:out value="${message}"/></p></c:if>
            <form class="filter-bar" method="get">
                <div class="filter-group"><input class="form-control" name="keyword"
                                                  value="<c:out value='${param.keyword}'/>"
                                                  placeholder="Tìm theo tên hoặc mã thiết bị"><select
                        class="form-control" name="status">
                    <option value="">Tất cả trạng thái</option>
                    <option value="IN_USE" ${param.status == 'IN_USE' ? 'selected' : ''}>Đang sử dụng</option>
                    <option value="RETURNED" ${param.status == 'RETURNED' ? 'selected' : ''}>Đã trả</option>
                </select><input class="form-control" type="date" name="fromDate" value="<c:out value='${param.fromDate}'/>"
                               aria-label="Từ ngày mượn"><input class="form-control" type="date" name="toDate"
                               value="<c:out value='${param.toDate}'/>" aria-label="Đến ngày mượn"></div>
                <div class="filter-group">
                    <button class="primary-button" type="submit">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Đặt lại</a></div>
            </form>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty usages}">
                        <div class="empty-box">
                            <div class="empty-box-icon">
                                <svg>
                                    <use href="#i-calendar"/>
                                </svg>
                            </div>
                            <h3>Không có lượt sử dụng phù hợp</h3>
                            <p>Điều chỉnh bộ lọc hoặc mượn thiết bị trong học kỳ đã được phê duyệt.</p></div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Mã lượt sử dụng</th>
                                    <th>Thiết bị</th>
                                    <th>Số lượng</th>
                                    <th>Thời gian mượn</th>
                                    <th>Hạn trả</th>
                                    <th>Trạng thái</th>
                                    <th>Thao tác</th>
                                </tr>
                                </thead>
                                <tbody><c:forEach items="${usages}" var="usage">
                                    <tr>
                                        <td>#AU-${usage.assetUsageId}</td>
                                        <td><strong><c:out value="${usage.assetName}"/></strong><br><small><c:out
                                                value="${usage.assetCode}"/></small><c:if test="${not empty usage.assetItemTag}"><br><small>Mã riêng: <c:out
                                                value="${usage.assetItemTag}"/></small></c:if></td>
                                        <td><c:out value="${usage.quantity}"/></td>
                                        <td><c:out value="${app:dateTime(usage.borrowedAt)}"/></td>
                                        <td><c:out value="${app:dateTime(usage.dueAt)}"/></td>
                                        <td><span
                                                class="status ${usage.status == 'RETURNED' ? 'returned' : 'in-use'}"><c:out
                                                value="${app:label(usage.status)}"/></span></td>
                                        <td><a class="btn-action btn-action-primary"
                                               href="${pageContext.request.contextPath}/intern/usages/${usage.assetUsageId}">Xem</a>
                                        </td>
                                    </tr>
                                </c:forEach></tbody>
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
