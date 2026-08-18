<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Asset Usage | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Asset Usage</h1><p>Lab-wide borrowing and return oversight</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LAB MANAGER PORTAL</p><h2>All Asset Usage</h2></div></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/usages"><div class="filter-group"><input class="form-control" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Search intern, asset name or code" style="width:280px"><select class="form-control" name="status"><option value="">All statuses</option><option value="IN_USE" ${param.status == 'IN_USE' ? 'selected' : ''}>IN_USE</option><option value="RETURNED" ${param.status == 'RETURNED' ? 'selected' : ''}>RETURNED</option></select><button class="primary-button" type="submit">Filter</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/usages">Reset</a></div></form>
            <article class="panel"><c:choose><c:when test="${empty usages}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-calendar"/></svg></div><h3>No usage records</h3><p>No records match the selected filters.</p></div></c:when><c:otherwise><div class="table-scroll"><table><thead><tr><th>Usage ID</th><th>Intern</th><th>Asset</th><th>Quantity</th><th>Borrowed</th><th>Due</th><th>Status</th><th>Action</th></tr></thead><tbody><c:forEach items="${usages}" var="u"><tr><td>#AU-${u.assetUsageId}</td><td><c:out value="${u.studentName}"/></td><td><strong><c:out value="${u.assetName}"/></strong><br><small><c:out value="${u.assetCode}"/></small></td><td><c:out value="${u.quantity}"/></td><td><c:out value="${u.borrowedAt}"/></td><td><c:out value="${u.dueAt}"/></td><td><span class="status ${u.status == 'IN_USE' ? 'in-use' : 'returned'}"><c:out value="${u.status}"/></span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/lab-manager/usages/${u.assetUsageId}">View</a></td></tr></c:forEach></tbody></table></div><div class="table-footer"><span>Showing ${usages.size()} usage record(s)</span></div></c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
