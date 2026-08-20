<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Sử dụng thiết bị | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Sử dụng thiết bị</h1><p>Theo dõi hoạt động mượn và trả trong toàn phòng LAB</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG QUẢN LÝ PHÒNG LAB</p><h2>Toàn bộ lịch sử sử dụng thiết bị</h2></div></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/usages"><div class="filter-group"><input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Tìm theo thực tập sinh, tên hoặc mã thiết bị" style="width:280px"><select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="IN_USE" ${param.status == 'IN_USE' ? 'selected' : ''}>Đang sử dụng</option><option value="MAINTENANCE" ${param.status == 'MAINTENANCE' ? 'selected' : ''}>Đang bảo trì</option><option value="RETURNED" ${param.status == 'RETURNED' ? 'selected' : ''}>Đã trả</option></select><input class="form-control" type="date" name="fromDate" value="<c:out value='${param.fromDate}'/>" aria-label="Từ ngày mượn"><input class="form-control" type="date" name="toDate" value="<c:out value='${param.toDate}'/>" aria-label="Đến ngày mượn"><button class="primary-button" type="submit">Lọc</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/usages">Đặt lại</a></div></form>
            <article class="panel"><c:choose><c:when test="${empty usages}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-calendar"/></svg></div><h3>Chưa có lịch sử sử dụng</h3><p>Không có bản ghi phù hợp với bộ lọc.</p></div></c:when><c:otherwise><div class="table-scroll"><table><thead><tr><th>Mã lượt sử dụng</th><th>Thực tập sinh</th><th>Thiết bị / sản phẩm</th><th>Số lượng</th><th>Thời gian mượn</th><th>Hạn trả</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach items="${usages}" var="u"><tr><td>#AU-${u.assetUsageId}</td><td><c:out value="${u.internName}"/></td><td><strong><c:out value="${u.assetName}"/></strong><br><small><c:out value="${empty u.assetItemTag ? u.assetCode : u.assetItemTag}"/></small></td><td><c:out value="${u.quantity}"/></td><td><c:out value="${app:dateTime(u.borrowedAt)}"/></td><td><c:out value="${app:dateTime(u.dueAt)}"/></td><td><span class="status ${u.status == 'IN_USE' ? 'in-use' : (u.status == 'MAINTENANCE' ? 'maintenance' : 'returned')}"><c:out value="${app:label(u.status)}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/lab-manager/usages/${u.assetUsageId}">Xem</a></td></tr></c:forEach></tbody></table></div><div class="table-footer"><span>Hiển thị ${usages.size()} lượt sử dụng</span></div></c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
