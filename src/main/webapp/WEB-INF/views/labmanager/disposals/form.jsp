<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Create Disposal | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Create Disposal</h1><p>Start a controlled asset retirement process</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Back to disposal</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">NEW DISPOSAL PROCESS</p><h2>Retire an Asset</h2></div></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-trash"/></svg></span><h3>Disposal information</h3></div></header><form method="post"><input type="hidden" name="action" value="create"><div class="form-grid"><div class="form-group full-width"><label for="assetId">Eligible asset</label><select class="form-control" id="assetId" name="assetId" required><c:forEach items="${assets}" var="a"><option value="${a.assetId}"><c:out value="${a.assetCode}"/> · <c:out value="${a.assetName}"/> · full quantity ${a.totalQuantity}</option></c:forEach></select><small>Disposed assets and assets with a pending disposal are excluded.</small></div><div class="form-group full-width"><label for="reason">Reason for disposal</label><textarea class="form-control" id="reason" name="reason" placeholder="Explain why this asset can no longer be safely or effectively used" required></textarea></div><div class="form-group full-width form-actions"><button class="primary-button" type="submit" <c:if test="${empty assets}">disabled</c:if>>Create pending disposal</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Cancel</a></div></div></form><c:if test="${empty assets}"><div class="empty-box"><p>No assets are currently eligible for disposal.</p></div></c:if></article>
        </section>
    </main>
</div>
</body>
</html>
