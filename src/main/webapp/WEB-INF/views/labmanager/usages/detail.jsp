<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Lượt sử dụng #${usage.assetUsageId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết sử dụng thiết bị</h1><p>Thông tin giao dịch mượn chỉ đọc</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/usages">Quay lại lịch sử sử dụng</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LƯỢT SỬ DỤNG #AU-${usage.assetUsageId}</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'IN_USE' ? 'in-use' : 'returned'}"><c:out value="${app:label(usage.status)}"/></span></div>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Mã thiết bị</dt><dd><c:out value="${usage.assetCode}"/></dd></div><div class="detail-item"><dt>Thực tập sinh</dt><dd><c:out value="${usage.studentName}"/></dd></div><div class="detail-item"><dt>Số lượng</dt><dd><c:out value="${usage.quantity}"/></dd></div><div class="detail-item"><dt>Mượn lúc</dt><dd><c:out value="${app:dateTime(usage.borrowedAt)}"/></dd></div><div class="detail-item"><dt>Hạn trả</dt><dd><c:out value="${app:dateTime(usage.dueAt)}"/></dd></div><div class="detail-item"><dt>Trả lúc</dt><dd><c:out value="${empty usage.returnedAt ? 'Chưa trả' : app:dateTime(usage.returnedAt)}"/></dd></div><div class="detail-item"><dt>Tình trạng trước khi mượn</dt><dd><c:out value="${app:label(usage.conditionBefore)}"/></dd></div><div class="detail-item"><dt>Tình trạng sau khi trả</dt><dd><c:out value="${empty usage.conditionAfter ? 'Chờ trả' : app:label(usage.conditionAfter)}"/></dd></div><div class="detail-item"><dt>Yêu cầu đã duyệt</dt><dd>#REQ-${usage.requestId}</dd></div><div class="detail-item wide"><dt>Ghi chú</dt><dd><c:out value="${empty usage.note ? 'Không có ghi chú.' : usage.note}"/></dd></div></dl>
        </section>
    </main>
</div>
</body>
</html>
