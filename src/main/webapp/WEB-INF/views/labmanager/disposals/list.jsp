<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Asset Disposal | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Asset Disposal</h1><p>Controlled asset retirement and history</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LAB MANAGER PORTAL</p><h2>Disposal Records</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/disposals/new"><svg><use href="#i-trash"/></svg>Create disposal</a></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/disposals"><div class="filter-group"><input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Search asset name or code" style="width:280px"><select class="form-control" name="status"><option value="">All statuses</option><option value="PENDING" ${param.status == 'PENDING' ? 'selected' : ''}>PENDING</option><option value="CANCELLED" ${param.status == 'CANCELLED' ? 'selected' : ''}>CANCELLED</option><option value="COMPLETED" ${param.status == 'COMPLETED' ? 'selected' : ''}>COMPLETED</option></select><button class="primary-button" type="submit">Filter</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Reset</a></div></form>
            <article class="panel"><c:choose><c:when test="${empty disposals}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-trash"/></svg></div><h3>No disposal records</h3><p>No records match the selected filters.</p></div></c:when><c:otherwise><div class="table-scroll"><table><thead><tr><th>Disposal ID</th><th>Asset</th><th>Quantity</th><th>Requested by</th><th>Requested at</th><th>Status</th><th>Action</th></tr></thead><tbody><c:forEach items="${disposals}" var="d"><tr><td>#DSP-${d.disposalId}</td><td><strong><c:out value="${d.assetName}"/></strong><br><small><c:out value="${d.assetCode}"/></small></td><td><c:out value="${d.quantity}"/></td><td><c:out value="${d.requesterName}"/></td><td><c:out value="${d.requestedAt}"/></td><td><span class="status ${d.status == 'PENDING' ? 'review' : d.status == 'COMPLETED' ? 'returned' : 'open'}"><c:out value="${d.status}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/lab-manager/disposals/${d.disposalId}">View</a></td></tr></c:forEach></tbody></table></div><div class="table-footer"><span>Showing ${disposals.size()} disposal record(s)</span></div></c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
