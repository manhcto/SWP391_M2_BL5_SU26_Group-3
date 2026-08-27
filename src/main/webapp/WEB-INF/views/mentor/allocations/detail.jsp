<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:out value="${activity.activityName}"/> | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/equipment-allocation.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="allocations" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1><c:out value="${activity.activityName}"/></h1><p><c:out value="${activity.internListName}"/> · <c:out value="${app:date(activity.startDate)}"/> - <c:out value="${app:date(activity.endDate)}"/></p></div></div></header>
        <section class="content-area allocation-detail-page">
            <a class="allocation-back-link" href="${pageContext.request.contextPath}/mentor/allocations">Quay lại danh sách</a>
            <c:if test="${not empty param.error}"><p class="error-message" role="alert"><c:out value="${param.error}"/></p></c:if>
            <c:if test="${param.success == '1'}"><p class="success-message" role="status">Đã tạo yêu cầu và gửi danh sách tài sản cho Lab Manager.</p></c:if>
            <article class="panel allocation-detail-panel">
                <header class="panel-header"><div class="panel-title"><div><h3>Tài sản đã yêu cầu cho lớp</h3><p>Lab Manager sẽ kiểm tra tồn kho và gán từng thiết bị vật lý khi duyệt.</p></div></div></header>
                <div class="table-scroll"><table><thead><tr><th>Tài sản</th><th>Số lượng</th><th>Trạng thái</th><th>Ghi chú</th></tr></thead><tbody>
                <c:forEach items="${allocationRequests}" var="item"><c:if test="${item.activityId == activity.activityId}"><tr><td><strong><c:out value="${item.assetName}"/></strong><br><small><c:out value="${item.assetCode}"/></small></td><td><c:out value="${item.requestedQuantity}"/></td><td><span class="status"><c:out value="${app:label(item.status)}"/></span></td><td><c:out value="${item.note}"/></td></tr></c:if></c:forEach>
                </tbody></table></div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
