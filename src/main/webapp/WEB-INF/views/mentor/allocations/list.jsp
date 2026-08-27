<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Yêu cầu cấp phát thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/equipment-allocation.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="allocations" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Yêu cầu cấp phát thiết bị</h1><p>Theo dõi tài sản cố định được đề xuất cho từng lớp Intern</p></div></div></header>
        <section class="content-area allocation-page">
            <c:if test="${not empty param.error}"><p class="error-message" role="alert"><c:out value="${param.error}"/></p></c:if>
            <c:if test="${param.success == '1'}"><p class="success-message" role="status">Đã cập nhật yêu cầu cấp phát.</p></c:if>
            <div class="content-heading"><div><span class="allocation-eyebrow">CỔNG NGƯỜI HƯỚNG DẪN</span><h2>Danh sách yêu cầu cấp phát</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/mentor/allocations/add">Thêm yêu cầu</a></div>
            <form class="filter-bar" method="get">
                <div class="filter-group"><input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Tìm theo lớp hoặc tên yêu cầu"><select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>Hoạt động</option><option value="CLOSED" ${selectedStatus == 'CLOSED' ? 'selected' : ''}>Đã kết thúc</option><option value="CANCELLED" ${selectedStatus == 'CANCELLED' ? 'selected' : ''}>Đã hủy</option></select><input class="form-control" type="date" name="fromDate" value="<c:out value='${param.fromDate}'/>" aria-label="Từ ngày"><input class="form-control" type="date" name="toDate" value="<c:out value='${param.toDate}'/>" aria-label="Đến ngày"></div>
                <div class="filter-group"><button class="primary-button" type="submit">Lọc</button><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/allocations">Đặt lại</a></div>
            </form>
            <article class="panel allocation-table-panel allocation-requests-panel">
                <div class="table-scroll"><table><thead><tr><th>Lớp Intern</th><th>Tên yêu cầu</th><th>Thời gian sử dụng</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>
                <c:choose><c:when test="${empty activities}"><tr><td class="empty-table" colspan="5">Chưa có yêu cầu cấp phát nào.</td></tr></c:when><c:otherwise><c:forEach items="${activities}" var="activity"><tr><td><strong><c:out value="${activity.internListName}"/></strong><br><small><c:out value="${activity.semesterCode}"/></small></td><td><strong><c:out value="${activity.activityName}"/></strong><br><small><c:out value="${activity.description}"/></small></td><td><c:out value="${app:date(activity.startDate)}"/> - <c:out value="${app:date(activity.endDate)}"/></td><td><span class="status"><c:out value="${app:label(activity.status)}"/></span></td><td><div class="allocation-row-actions"><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/allocations/${activity.activityId}">Xem</a><a class="btn-action" href="${pageContext.request.contextPath}/mentor/allocations/${activity.activityId}/edit">Chỉnh sửa</a></div></td></tr></c:forEach></c:otherwise></c:choose>
                </tbody></table></div>
                <div class="table-footer"><span>Hiển thị ${activities.size()} yêu cầu</span></div>
            </article>
            <article class="panel allocation-table-panel allocation-issues-panel">
                <div class="allocation-panel-heading"><h3>Báo cáo sự cố thiết bị</h3></div>
                <div class="table-scroll"><table><thead><tr><th>Hoạt động</th><th>Thiết bị</th><th>Người báo</th><th>Sự cố</th><th>Trạng thái</th><th>Xử lý</th></tr></thead><tbody>
                <c:choose><c:when test="${empty issues}"><tr><td class="empty-table" colspan="6">Chưa có báo cáo sự cố thiết bị.</td></tr></c:when><c:otherwise><c:forEach items="${issues}" var="issue"><tr><td><strong><c:out value="${issue.activityName}"/></strong><br><small><c:out value="${app:dateTime(issue.createdAt)}"/></small></td><td><c:out value="${issue.itemCode}"/></td><td><c:out value="${issue.reporterName}"/></td><td><strong><c:out value="${app:label(issue.issueType)}"/></strong><br><small><c:out value="${issue.description}"/></small><c:if test="${not empty issue.imagePath}"><br><a class="btn-action" href="${pageContext.request.contextPath}${issue.imagePath}" target="_blank" rel="noopener">Xem ảnh</a></c:if></td><td><span class="status"><c:out value="${app:label(issue.status)}"/></span><c:if test="${not empty issue.mentorNote}"><br><small><c:out value="${issue.mentorNote}"/></small></c:if></td><td><c:if test="${issue.status == 'PENDING_MENTOR'}"><form class="filter-group" method="post"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="action" value="reviewIssue"><input type="hidden" name="issueId" value="${issue.issueReportId}"><input class="form-control" name="mentorNote" maxlength="500" placeholder="Ghi chú xác minh"><button class="btn-action btn-action-primary" type="submit" name="decision" value="VERIFIED">Xác nhận</button><button class="btn-action" type="submit" name="decision" value="REJECTED">Từ chối</button></form></c:if></td></tr></c:forEach></c:otherwise></c:choose>
                </tbody></table></div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
