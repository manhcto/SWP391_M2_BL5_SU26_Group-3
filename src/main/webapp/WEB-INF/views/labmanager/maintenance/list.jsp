<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Quản lý bảo trì (FE-08) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Phê duyệt bảo trì và sửa chữa (FE-08)</h1><p>Phê duyệt đề xuất sửa chữa, dự toán chi phí và phân công kỹ thuật viên</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Tìm phiếu bảo trì..." aria-label="Tìm kiếm"></label>
                <button class="icon-button notification" type="button" aria-label="Thông báo"><svg><use href="#i-bell"/></svg><span>3</span></button>
                <div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">FE-08 BẢO TRÌ</p><h2>Danh sách yêu cầu bảo trì (${records.size()})</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/add"><svg><use href="#i-wrench"/></svg>+ Tạo phiếu sửa chữa</a>
            </div>

            <c:if test="${param.success == 'created'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Phiếu bảo trì đã được tạo và lưu vào hệ thống!</div></c:if>
            <c:if test="${param.success == 'approved'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Quyết định phê duyệt/từ chối đã được xử lý!</div></c:if>
            <c:if test="${param.success == 'updated'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Cập nhật tiến độ kỹ thuật thành công!</div></c:if>

            <div class="filter-bar">
                <form method="get" action="${pageContext.request.contextPath}/labmanager/maintenance" class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Tìm thiết bị hoặc sự cố..." style="width: 240px;">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa chữa</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>Đã sửa xong</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                    </select>
                    <button class="primary-button" type="submit" style="height: 36px; padding: 0 16px;">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance" style="height: 36px;">Đặt lại</a>
                </form>
            </div>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-wrench"/></svg></div>
                            <h3>Chưa có phiếu bảo trì nào</h3>
                            <p>Hiện chưa có yêu cầu sửa chữa hoặc bảo trì thiết bị nào được gửi trong hệ thống.</p>
                            <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/add">+ Tạo phiếu bảo trì ngay</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Mã phiếu</th>
                                    <th>Tên / Mã thiết bị</th>
                                    <th>Người yêu cầu</th>
                                    <th>Mô tả / Sự cố</th>
                                    <th>Ngày yêu cầu</th>
                                    <th>Trạng thái</th>
                                    <th>Người phê duyệt</th>
                                    <th style="text-align: right;">Thao tác</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="m" items="${records}">
                                    <tr>
                                        <td><strong>#MNT-${m.maintenanceId}</strong></td>
                                        <td><b><c:out value="${m.assetName}"/></b><br><small style="color:#8a938f;"><c:out value="${m.assetCode}"/></small></td>
                                        <td><c:out value="${m.requesterName}"/></td>
                                        <td><c:out value="${m.description}"/></td>
                                        <td><c:out value="${app:dateTime(m.requestedAt)}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${m.status == 'PENDING'}"><span class="status review">Chờ duyệt</span></c:when>
                                                <c:when test="${m.status == 'APPROVED'}"><span class="badge badge-gold">Đã duyệt</span></c:when>
                                                <c:when test="${m.status == 'IN_PROGRESS'}"><span class="badge badge-blue">Đang sửa chữa</span></c:when>
                                                <c:when test="${m.status == 'COMPLETED'}"><span class="status returned">Hoàn tất</span></c:when>
                                                <c:otherwise><span class="badge badge-red"><c:out value="${app:label(m.status)}"/></span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><c:out value="${m.approverName}" default="—"/></td>
                                        <td style="text-align: right;">
                                            <a class="btn-action" href="${pageContext.request.contextPath}/labmanager/maintenance/view?id=${m.maintenanceId}">Xem</a>
                                            <a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/labmanager/maintenance/edit?id=${m.maintenanceId}">Cập nhật / Phê duyệt</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <div class="page-size-selector"><span>Hiển thị</span><select class="form-control" style="width: auto; height: 28px;"><option value="10" selected>10</option><option value="25">25</option></select><span>bản ghi mỗi trang</span></div>
                            <span>Hiển thị 1 đến ${records.size()} trong tổng số ${records.size()} bản ghi</span>
                            <div class="pagination-controls"><button class="page-btn" disabled>‹</button><button class="page-btn active">1</button><button class="page-btn">›</button></div>
                        </div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
