<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lượt sử dụng #${usage.assetUsageId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Chi tiết sử dụng thiết bị</h1><p>Xem thông tin mượn và trạng thái trả</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Quay lại lịch sử</a></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">CỔNG THỰC TẬP SINH</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'RETURNED' ? 'returned' : (usage.status == 'MAINTENANCE' ? 'maintenance' : 'in-use')}"><c:out value="${app:label(usage.status)}"/></span></div>
            <dl class="panel detail-grid">
                <div class="detail-item"><dt>Mã thiết bị</dt><dd><c:out value="${usage.assetCode}"/></dd></div>
                <div class="detail-item"><dt>Mã sản phẩm</dt><dd><c:out value="${empty usage.itemCode ? 'Theo thiết bị chung' : usage.itemCode}"/></dd></div>
                <div class="detail-item"><dt>Serial</dt><dd><c:out value="${empty usage.itemSerialNumber ? 'Chưa nhập' : usage.itemSerialNumber}"/></dd></div>
                <div class="detail-item"><dt>Số lượng</dt><dd><c:out value="${usage.quantity}"/></dd></div>
                <div class="detail-item"><dt>Trạng thái</dt><dd><c:out value="${app:label(usage.status)}"/></dd></div>
                <div class="detail-item"><dt>Mượn lúc</dt><dd><c:out value="${app:dateTime(usage.borrowedAt)}"/></dd></div>
                <div class="detail-item"><dt>Hạn trả</dt><dd><c:out value="${app:dateTime(usage.dueAt)}"/></dd></div>
            </dl>
            <c:if test="${usage.status == 'IN_USE'}">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Trả thiết bị này</h3></div></header>
					<form method="post" action="${pageContext.request.contextPath}/intern/usages">
						<input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        <input type="hidden" name="action" value="return"><input type="hidden" name="usageId" value="${usage.assetUsageId}">
                        <div class="form-grid">
                            <div class="form-group"><label for="conditionAfter">Tình trạng sau khi sử dụng</label><select class="form-control" id="conditionAfter" name="conditionAfter" required><option value="GOOD">Tốt</option><option value="FAIR">Khá — Mentor có thể tự xử lý</option><option value="DAMAGED">Hư hỏng — cần báo cáo</option><option value="BROKEN">Không hoạt động — cần báo cáo</option></select><small>Nếu chỉ lỗi nhẹ như lỏng giắc cắm, chọn Khá; không tạo báo cáo Lab Manager.</small></div>
                            <div class="form-group full-width"><label for="note">Ghi chú trả thiết bị</label><textarea class="form-control" id="note" name="note"></textarea></div>
                            <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Xác nhận trả</button></div>
                        </div>
                    </form>
                </article>
            </c:if>
        </section>
    </main>
</div>
</body>
</html>
