<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Chi tiết yêu cầu thanh lý | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết yêu cầu thanh lý</h1><p>Theo dõi kết quả xem xét và hoàn tất thanh lý</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/disposals">Quay lại danh sách</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">YÊU CẦU #DSP-${disposal.disposalId}</p><h2><c:out value="${disposal.assetName}"/></h2></div><span class="status ${disposal.status == 'PENDING' ? 'review' : disposal.status == 'COMPLETED' ? 'returned' : 'open'}"><c:out value="${app:label(disposal.status)}"/></span></div>
            <c:if test="${not empty message}"><p class="error-message"><c:out value="${message}"/></p></c:if>
            <article class="panel"><div class="detail-grid"><div><dt>Mã tài sản</dt><dd><c:out value="${disposal.assetCode}"/></dd></div><c:if test="${not empty disposal.assetItemTag}"><div><dt>Mã thiết bị</dt><dd><c:out value="${disposal.assetItemTag}"/></dd></div></c:if><div><dt>Tình trạng tài sản</dt><dd><c:out value="${app:label(disposal.assetCondition)}"/></dd></div><div><dt>Số lượng</dt><dd><c:out value="${disposal.quantity}"/></dd></div><div><dt>Người yêu cầu</dt><dd><c:out value="${disposal.requesterName}"/></dd></div><div><dt>Thời gian yêu cầu</dt><dd><c:out value="${app:dateTime(disposal.requestedAt)}"/></dd></div><div><dt>Lý do</dt><dd><c:out value="${disposal.reason}"/></dd></div><div><dt>Người duyệt</dt><dd><c:out value="${empty disposal.approverName ? 'Chưa duyệt' : disposal.approverName}"/></dd></div><div><dt>Thời gian duyệt</dt><dd><c:out value="${app:dateTime(disposal.approvedAt)}"/></dd></div><div><dt>Ghi chú duyệt</dt><dd><c:out value="${empty disposal.approvalNote ? 'Không có' : disposal.approvalNote}"/></dd></div><div><dt>Thời gian hoàn tất</dt><dd><c:out value="${app:dateTime(disposal.completedAt)}"/></dd></div><div><dt>Kết quả thanh lý</dt><dd><c:out value="${empty disposal.completionNote ? 'Chưa có' : disposal.completionNote}"/></dd></div></div></article>
        </section>
    </main>
</div>
</body>
</html>
