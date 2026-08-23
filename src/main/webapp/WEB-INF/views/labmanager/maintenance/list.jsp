<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Quản lý bảo trì | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Xử lý bảo trì</h1><p>Duyệt, bắt đầu, hoàn tất yêu cầu cho đúng thiết bị theo mã riêng.</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <c:if test="${param.success == 'approve'}"><div class="success-message">Đã duyệt yêu cầu bảo trì.</div></c:if>
            <c:if test="${param.success == 'reject'}"><div class="success-message">Đã từ chối yêu cầu bảo trì.</div></c:if>
            <c:if test="${param.success == 'start'}"><div class="success-message">Thiết bị chính xác đã chuyển sang bảo trì.</div></c:if>
            <c:if test="${param.success == 'complete'}"><div class="success-message">Đã lưu kết quả sửa chữa.</div></c:if>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/maintenance">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Mã phiếu, Item, thiết bị, mô tả">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>Hoàn tất</option>
                    </select>
                    <button class="primary-button" type="submit">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Đặt lại</a>
                </div>
            </form>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}"><div class="empty-box"><h3>Chưa có yêu cầu bảo trì</h3><p>Mentor gửi yêu cầu trước khi Lab Manager xử lý.</p></div></c:when>
                    <c:otherwise><div class="table-scroll"><table>
                        <thead><tr><th>Phiếu</th><th>Thiết bị chính xác</th><th>Thiết bị cha</th><th>Người gửi</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
                        <tbody><c:forEach var="record" items="${records}"><tr>
                            <td><strong>#MNT-<c:out value="${record.maintenanceId}"/></strong><small style="display:block"><c:out value="${app:dateTime(record.requestedAt)}"/></small></td>
                            <td><c:choose><c:when test="${not empty record.assetItemId}"><strong><c:out value="${record.assetItemTag}"/></strong><small style="display:block"><c:out value="${app:label(record.assetItemStatus)}"/> · <c:out value="${app:label(record.assetItemCondition)}"/></small></c:when><c:otherwise>Hồ sơ lịch sử</c:otherwise></c:choose></td>
                            <td><c:out value="${record.assetName}"/><small style="display:block"><c:out value="${record.assetCode}"/></small></td>
                            <td><c:out value="${record.requesterName}"/></td>
                            <td><c:choose><c:when test="${record.status == 'COMPLETED' && record.repairOutcome == 'SUCCESS'}"><span class="status returned">Sửa thành công</span></c:when><c:when test="${record.status == 'COMPLETED' && record.repairOutcome == 'FAILED'}"><span class="status overdue">Sửa thất bại</span></c:when><c:when test="${record.status == 'IN_PROGRESS'}"><span class="status maintenance">Đang sửa</span></c:when><c:otherwise><span class="status"><c:out value="${app:label(record.status)}"/></span></c:otherwise></c:choose></td>
                            <td><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance/${record.maintenanceId}">Xem</a><c:if test="${record.status == 'PENDING' || record.status == 'APPROVED' || record.status == 'IN_PROGRESS'}"><a class="primary-button" style="margin-left:4px" href="${pageContext.request.contextPath}/lab-manager/maintenance/${record.maintenanceId}/edit">Xử lý</a></c:if></td>
                        </tr></c:forEach></tbody>
                    </table></div></c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
