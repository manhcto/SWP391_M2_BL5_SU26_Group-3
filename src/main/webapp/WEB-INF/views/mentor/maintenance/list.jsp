<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Đề xuất bảo trì (FE-08) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Đề xuất bảo trì (FE-08)</h1><p>Gửi đề xuất sửa chữa và theo dõi tiến độ</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Tìm đề xuất..." aria-label="Tìm kiếm"></label>
                <button class="icon-button notification" type="button" aria-label="Thông báo"><svg><use href="#i-bell"/></svg><span>2</span></button>
                <div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">FE-08 BẢO TRÌ</p><h2>Đề xuất đã gửi (${records.size()})</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/maintenance/add"><svg><use href="#i-wrench"/></svg>+ Đề xuất bảo trì</a>
            </div>

            <c:if test="${param.success == 'submitted'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Đề xuất bảo trì của bạn đã được gửi cho quản lý phòng LAB phê duyệt!</div></c:if>

            <div class="filter-bar">
                <form method="get" action="${pageContext.request.contextPath}/mentor/maintenance" class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Tìm thiết bị hoặc sự cố..." style="width: 240px;">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa chữa</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>Đã sửa xong</option>
                    </select>
                    <button class="primary-button" type="submit" style="height: 36px; padding: 0 16px;">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance" style="height: 36px;">Đặt lại</a>
                </form>
            </div>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-wrench"/></svg></div>
                            <h3>Bạn chưa gửi đề xuất bảo trì nào</h3>
                            <p>Khi phát hiện thiết bị thí nghiệm gặp sự cố, bạn có thể tạo đề xuất để quản lý phòng LAB xử lý.</p>
                            <a class="primary-button" href="${pageContext.request.contextPath}/mentor/maintenance/add">+ Gửi đề xuất bảo trì mới</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Mã phiếu</th>
                                    <th>Tên / Mã thiết bị</th>
                                    <th>Tóm tắt sự cố</th>
                                    <th>Ngày gửi</th>
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
                                        <td><c:out value="${m.description}"/></td>
                                        <td><c:out value="${app:dateTime(m.requestedAt)}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${m.status == 'PENDING'}"><span class="status review">CHỜ PHÊ DUYỆT</span></c:when>
                                                <c:when test="${m.status == 'APPROVED'}"><span class="badge badge-gold">Đã duyệt</span></c:when>
                                                <c:when test="${m.status == 'IN_PROGRESS'}"><span class="badge badge-blue">ĐANG SỬA CHỮA</span></c:when>
                                                <c:when test="${m.status == 'COMPLETED'}"><span class="status returned">Hoàn tất</span></c:when>
                                                <c:otherwise><span class="badge badge-red"><c:out value="${app:label(m.status)}"/></span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><c:out value="${m.approverName}" default="Chờ xem xét"/></td>
                                        <td style="text-align: right;">
                                            <a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/maintenance/view?id=${m.maintenanceId}">Xem chi tiết</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <div class="page-size-selector"><span>Hiển thị</span><select class="form-control" style="width: auto; height: 28px;"><option value="10" selected>10</option><option value="25">25</option></select><span>đề xuất mỗi trang</span></div>
                            <span>Hiển thị 1 đến ${records.size()} trong tổng số ${records.size()} đề xuất</span>
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
