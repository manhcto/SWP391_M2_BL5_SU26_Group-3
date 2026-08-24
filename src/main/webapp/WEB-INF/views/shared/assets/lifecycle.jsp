<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Vòng đời ${item.itemCode} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css?v=iter3">
    <style>.lifecycle{list-style:none;margin:0;padding:0}.lifecycle li{position:relative;margin-left:14px;padding:0 0 24px 32px;border-left:2px solid #dbe4ee}.lifecycle li:last-child{border-left-color:transparent;padding-bottom:0}.lifecycle li:before{content:"";position:absolute;left:-7px;top:4px;width:12px;height:12px;border-radius:50%;background:var(--primary);box-shadow:0 0 0 4px #eaf2ff}.lifecycle-time{display:block;color:var(--muted);font-size:12px;margin-bottom:5px}.lifecycle-head{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.lifecycle-head h3{margin:0}.lifecycle-meta{color:var(--muted);font-size:13px;margin:6px 0 0}.lifecycle-detail{margin:8px 0 0;white-space:pre-wrap}.scope-note{margin-top:8px;color:#8a5b00;font-size:12px}@media(max-width:640px){.lifecycle li{margin-left:5px;padding-left:24px}.lifecycle-head{align-items:flex-start;flex-direction:column}}</style>
</head>
<body class="${roleBase == '/mentor' ? 'mentor-page' : 'lab-manager-page'}">
<c:set var="activeMenu" value="assets" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when><c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Lịch sử vòng đời</h1><p>Theo dõi các sự kiện nghiệp vụ của một sản phẩm vật lý</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/assets/${item.assetItemId}">Quay lại chi tiết</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow"><c:out value="${item.assetCode}"/></p><h2><c:out value="${item.itemCode}"/> · <c:out value="${item.assetName}"/></h2></div><span class="status"><c:out value="${app:label(item.status)}"/></span></div>
            <article class="panel">
                <c:choose><c:when test="${empty events}"><div class="empty-box"><h3>Chưa có sự kiện vòng đời</h3></div></c:when><c:otherwise><ol class="lifecycle">
                    <c:forEach items="${events}" var="event"><li><time class="lifecycle-time"><c:out value="${app:dateTime(event.occurredAt)}"/></time><div class="lifecycle-head"><h3><c:out value="${event.eventLabel}"/></h3><c:if test="${not empty event.status}"><span class="status"><c:out value="${app:label(event.status)}"/></span></c:if></div><p class="lifecycle-meta"><c:out value="${empty event.actorName ? 'Hệ thống / không lưu người thực hiện' : event.actorName}"/> · <c:out value="${event.referenceType}"/> #<c:out value="${event.referenceId}"/></p><c:if test="${not empty event.detail}"><p class="lifecycle-detail"><c:out value="${event.detail}"/></p></c:if><c:if test="${event.scope == 'PARENT_ASSET'}"><p class="scope-note">Sự kiện kiểm tra áp dụng cho Asset cha, chưa phải xác nhận riêng cho sản phẩm này.</p></c:if></li></c:forEach>
                </ol></c:otherwise></c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
