<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Theo dõi bảo trì thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Theo dõi bảo trì thiết bị</h1><p>Xem danh sách và tiến độ các phiếu bảo trì thiết bị phòng lab.</p></div>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/maintenance">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Mã phiếu (#MNT-), tên/mã thiết bị, cá thể, thợ sửa..." style="width:360px;">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt, chờ bắt đầu</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa chữa</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>Đã sửa xong</option>
                    </select>
                    <button class="primary-button" type="submit">Tìm kiếm</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Đặt lại</a>
                </div>
            </form>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}"><div class="empty-box"><h3>Chưa có phiếu bảo trì nào</h3><p>Hiện tại chưa có phiếu bảo trì thiết bị nào được ghi nhận trong hệ thống.</p></div></c:when>
                    <c:otherwise><div class="table-scroll"><table>
                        <thead><tr><th>Mã phiếu</th><th>Thiết bị</th><th>Vị trí</th><th>Ngày tạo</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
                        <tbody><c:forEach var="record" items="${records}"><tr>
                            <td><strong>#MNT-<c:out value="${record.maintenanceId}"/></strong></td>
                            <td>
                                <strong><c:out value="${record.assetName}"/></strong>
                                <small style="display:block;color:#5a6662;"><c:out value="${not empty record.assetItemCode ? record.assetItemCode : record.assetCode}"/></small>
                            </td>
                            <td><c:out value="${not empty record.storageLocation ? record.storageLocation : '—'}"/></td>
                            <td><c:out value="${app:dateTime(record.requestedAt)}"/></td>
                            <td>
                                <c:choose>
                                    <c:when test="${record.status == 'COMPLETED'}">
                                        <c:choose>
                                            <c:when test="${record.assetStatus == 'UNAVAILABLE'}">
                                                <span class="status overdue">Sửa thất bại</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="status returned">Đã sửa xong</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </c:when>
                                    <c:when test="${record.status == 'IN_PROGRESS'}">
                                        <span class="status maintenance">Đang sửa chữa</span>
                                    </c:when>
                                    <c:when test="${record.status == 'PENDING'}"><span class="status">Chờ duyệt</span></c:when>
                                    <c:when test="${record.status == 'APPROVED'}"><span class="status">Đã duyệt, chờ bắt đầu</span></c:when>
                                    <c:when test="${record.status == 'REJECTED'}"><span class="status overdue">Đã từ chối</span></c:when>
                                    <c:otherwise>
                                        <span class="status"><c:out value="${record.status}"/></span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance/${record.maintenanceId}">Xem</a></td>
                        </tr></c:forEach></tbody>
                    </table></div></c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
