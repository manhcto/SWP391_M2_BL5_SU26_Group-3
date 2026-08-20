<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Yêu cầu thanh lý | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Yêu cầu thanh lý</h1><p>Theo dõi các đề xuất thanh lý thiết bị không còn phù hợp sử dụng</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG NGƯỜI HƯỚNG DẪN</p><h2>Hồ sơ thanh lý của tôi</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/mentor/disposals/new"><svg><use href="#i-plus"/></svg>Tạo yêu cầu</a></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/disposals"><div class="filter-group"><input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Tìm theo tên hoặc mã thiết bị" style="width:280px"><select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="PENDING" ${param.status == 'PENDING' ? 'selected' : ''}>Chờ xử lý</option><option value="APPROVED" ${param.status == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option><option value="REJECTED" ${param.status == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option><option value="COMPLETED" ${param.status == 'COMPLETED' ? 'selected' : ''}>Hoàn tất</option></select><button class="primary-button" type="submit">Lọc</button><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/disposals">Đặt lại</a></div></form>
            <article class="panel"><c:choose><c:when test="${empty disposals}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-trash"/></svg></div><h3>Chưa có yêu cầu thanh lý</h3><p>Không có bản ghi phù hợp với bộ lọc.</p></div></c:when><c:otherwise><div class="table-scroll"><table><thead><tr><th>Mã thanh lý</th><th>Thiết bị</th><th>Lý do</th><th>Thời gian yêu cầu</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach items="${disposals}" var="d"><tr><td>#DSP-${d.disposalId}</td><td><strong><c:out value="${d.assetName}"/></strong><br><small><c:out value="${d.assetCode}"/><c:if test="${not empty d.assetItemTag}"> · <c:out value="${d.assetItemTag}"/></c:if></small></td><td><c:out value="${d.reason}"/></td><td><c:out value="${app:dateTime(d.requestedAt)}"/></td><td><span class="status ${d.status == 'PENDING' ? 'review' : d.status == 'COMPLETED' ? 'returned' : 'open'}"><c:out value="${app:label(d.status)}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/disposals/${d.disposalId}">Xem</a></td></tr></c:forEach></tbody></table></div><div class="table-footer"><span>Hiển thị ${disposals.size()} yêu cầu thanh lý</span></div></c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
