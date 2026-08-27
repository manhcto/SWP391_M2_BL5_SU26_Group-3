<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sử dụng thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css?v=iter3">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Sử dụng thiết bị</h1><p>Theo dõi danh sách phụ trách và cùng Quản lý phòng LAB xác nhận yêu cầu trả đang chờ</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG NGƯỜI HƯỚNG DẪN</p><h2>Lịch sử sử dụng thiết bị</h2></div></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/usages">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Tìm thực tập sinh hoặc thiết bị" style="width:280px">
                    <select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="IN_USE" ${param.status == 'IN_USE' ? 'selected' : ''}>Đang sử dụng</option><option value="RETURN_PENDING" ${param.status == 'RETURN_PENDING' ? 'selected' : ''}>Chờ xác nhận trả</option><option value="RETURNED" ${param.status == 'RETURNED' ? 'selected' : ''}>Đã trả</option></select>
                    <input class="form-control" type="date" name="fromDate" value="<c:out value='${param.fromDate}'/>" aria-label="Từ ngày mượn">
                    <input class="form-control" type="date" name="toDate" value="<c:out value='${param.toDate}'/>" aria-label="Đến ngày mượn">
                    <button class="primary-button" type="submit">Lọc</button><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/usages">Đặt lại</a>
                </div>
            </form>
            <c:if test="${not empty param.confirmed}"><div class="success-message">Đã xác nhận <c:out value="${param.confirmed}"/> yêu cầu trả thiết bị.</div></c:if>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <c:choose><c:when test="${empty usages}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-calendar"/></svg></div><h3>Chưa có lịch sử sử dụng</h3><p>Không có bản ghi phù hợp với bộ lọc.</p></div></c:when><c:otherwise>
                    <form method="post" action="${pageContext.request.contextPath}/mentor/usages">
                        <input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="action" value="bulkConfirmReturn">
                        <div class="table-scroll"><table><thead><tr><th><span class="sr-only">Chọn</span></th><th>Thực tập sinh</th><th>Thiết bị / sản phẩm</th><th>Yêu cầu trả</th><th>Intern báo cáo</th><th>Tình trạng thực tế</th><th>Ghi chú</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody><c:forEach items="${usages}" var="u"><c:set var="bulkEligible" value="${u.status == 'RETURN_PENDING' && not empty u.assetItemId}"/><tr><td><c:if test="${bulkEligible}"><input type="checkbox" name="selectedUsageId" value="${u.assetUsageId}" aria-label="Chọn yêu cầu trả của ${u.internName}"></c:if></td><td><c:out value="${u.internName}"/></td><td><strong><c:out value="${u.assetName}"/></strong><br><small><c:out value="${empty u.assetItemTag ? u.assetCode : u.assetItemTag}"/></small></td><td><c:out value="${empty u.returnRequestedAt ? 'Chưa yêu cầu' : app:dateTime(u.returnRequestedAt)}"/></td><td><c:out value="${empty u.reportedConditionAfter ? '-' : app:label(u.reportedConditionAfter)}"/></td><td><c:choose><c:when test="${bulkEligible}"><select class="form-control" name="verifiedCondition_${u.assetUsageId}" aria-label="Tình trạng thực tế ${u.assetItemTag}"><option value="GOOD">Tốt</option><option value="FAIR">Khá</option><option value="DAMAGED">Hư hỏng</option><option value="BROKEN">Không hoạt động</option></select></c:when><c:otherwise>-</c:otherwise></c:choose></td><td><c:choose><c:when test="${bulkEligible}"><input class="form-control" name="note_${u.assetUsageId}" maxlength="500" placeholder="Tùy chọn" aria-label="Ghi chú xác minh ${u.assetItemTag}"></c:when><c:otherwise>-</c:otherwise></c:choose></td><td><span class="status"><c:out value="${app:label(u.status)}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/usages/${u.assetUsageId}">${u.status == 'RETURN_PENDING' ? 'Xác nhận' : 'Xem'}</a></td></tr></c:forEach></tbody></table></div>
                        <div class="table-footer"><span>Hiển thị ${usages.size()} lượt sử dụng</span><button class="primary-button" type="submit">Xác nhận các mục đã chọn</button></div>
                    </form>
                </c:otherwise></c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
