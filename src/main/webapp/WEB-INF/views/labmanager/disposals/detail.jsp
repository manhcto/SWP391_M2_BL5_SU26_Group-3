<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Thanh lý #${disposal.disposalId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết thanh lý</h1><p>Vòng đời thiết bị và hồ sơ thanh lý</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Quay lại danh sách thanh lý</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">THANH LÝ #DSP-${disposal.disposalId}</p><h2><c:out value="${disposal.assetName}"/></h2></div><span class="status ${disposal.status == 'PENDING' ? 'review' : disposal.status == 'COMPLETED' ? 'returned' : 'open'}"><c:out value="${app:label(disposal.status)}"/></span></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Mã thiết bị</dt><dd><c:out value="${disposal.assetCode}"/></dd></div><div class="detail-item"><dt>Số lượng thanh lý</dt><dd><c:out value="${disposal.quantity}"/></dd></div><div class="detail-item"><dt>Người yêu cầu</dt><dd><c:out value="${disposal.requesterName}"/></dd></div><div class="detail-item"><dt>Thời gian yêu cầu</dt><dd><c:out value="${app:dateTime(disposal.requestedAt)}"/></dd></div><div class="detail-item"><dt>Hoàn tất lúc</dt><dd><c:out value="${empty disposal.completedAt ? 'Chưa hoàn tất' : app:dateTime(disposal.completedAt)}"/></dd></div><div class="detail-item wide"><dt>Lý do</dt><dd><c:out value="${disposal.reason}"/></dd></div><div class="detail-item wide"><dt>Ghi chú xử lý</dt><dd><c:out value="${empty disposal.completionNote ? 'Không có ghi chú xử lý.' : disposal.completionNote}"/></dd></div></dl>
            <c:if test="${disposal.status == 'PENDING'}"><div class="detail-columns"><article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-trash"/></svg></span><h3>Cập nhật lý do</h3></div></header><form method="post" action="${pageContext.request.contextPath}/lab-manager/disposals"><input type="hidden" name="action" value="update"><input type="hidden" name="disposalId" value="${disposal.disposalId}"><div class="form-grid"><div class="form-group full-width"><label for="reason">Lý do thanh lý</label><textarea class="form-control" id="reason" name="reason" required><c:out value="${disposal.reason}"/></textarea></div><div class="form-group full-width form-actions"><button class="primary-button" type="submit">Lưu lý do</button></div></div></form></article><article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-list"/></svg></span><h3>Hoàn tất quy trình</h3></div></header><form method="post" action="${pageContext.request.contextPath}/lab-manager/disposals"><input type="hidden" name="disposalId" value="${disposal.disposalId}"><div class="form-grid"><div class="form-group full-width"><label for="note">Ghi chú xử lý</label><textarea class="form-control" id="note" name="note" placeholder="Minh chứng hoàn tất hoặc lý do hủy"></textarea></div><div class="form-group full-width form-actions"><button class="btn-danger" name="action" value="cancel">Hủy quy trình</button><button class="primary-button" name="action" value="complete">Hoàn tất thanh lý</button></div></div></form></article></div></c:if>
        </section>
    </main>
</div>
</body>
</html>
