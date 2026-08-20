<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Chi tiết sử dụng thiết bị | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết sử dụng thiết bị</h1><p>Thông tin mượn, trả và tình trạng thiết bị</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/usages">Quay lại danh sách</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LƯỢT SỬ DỤNG #${usage.assetUsageId}</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'RETURNED' ? 'returned' : 'in-use'}"><c:out value="${app:label(usage.status)}"/></span></div>
            <article class="panel"><div class="detail-grid"><div><dt>Thực tập sinh</dt><dd><c:out value="${usage.internName}"/></dd></div><div><dt>Số lượng</dt><dd><c:out value="${usage.quantity}"/></dd></div><c:if test="${not empty usage.assetItemTag}"><div><dt>Mã thiết bị</dt><dd><c:out value="${usage.assetItemTag}"/></dd></div></c:if><div><dt>Thời gian mượn</dt><dd><c:out value="${app:dateTime(usage.borrowedAt)}"/></dd></div><div><dt>Hạn trả</dt><dd><c:out value="${app:dateTime(usage.dueAt)}"/></dd></div><div><dt>Thời gian trả</dt><dd><c:out value="${app:dateTime(usage.returnedAt)}"/></dd></div><div><dt>Tình trạng trước khi dùng</dt><dd><c:out value="${app:label(usage.conditionBefore)}"/></dd></div><div><dt>Tình trạng sau khi trả</dt><dd><c:out value="${app:label(usage.conditionAfter)}"/></dd></div><div><dt>Ghi chú sử dụng</dt><dd><c:out value="${empty usage.note ? 'Không có' : usage.note}"/></dd></div><div><dt>Ghi chú trả</dt><dd><c:out value="${empty usage.returnNote ? 'Không có' : usage.returnNote}"/></dd></div></div></article>
        </section>
    </main>
</div>
</body>
</html>
