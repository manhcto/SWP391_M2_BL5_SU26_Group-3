<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>My Asset Usage | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>My Asset Usage</h1><p>Track active loans and return history</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">INTERN PORTAL</p><h2>Usage History</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/intern/usages/borrow"><svg><use href="#i-box"/></svg>Borrow an asset</a>
            </div>
            <c:if test="${not empty message}"><p class="success-message"><c:out value="${message}"/></p></c:if>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty usages}">
                        <div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-calendar"/></svg></div><h3>No usage records yet</h3><p>Borrow an asset during your approved semester.</p></div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead><tr><th>Usage ID</th><th>Asset</th><th>Quantity</th><th>Borrowed</th><th>Due</th><th>Status</th><th>Action</th></tr></thead>
                                <tbody><c:forEach items="${usages}" var="u"><tr>
                                    <td>#AU-${u.assetUsageId}</td>
                                    <td><strong><c:out value="${u.assetName}"/></strong><br><small><c:out value="${u.assetCode}"/></small></td>
                                    <td><c:out value="${u.quantity}"/></td><td><c:out value="${u.borrowedAt}"/></td><td><c:out value="${u.dueAt}"/></td>
                                    <td><span class="status ${u.status == 'RETURNED' ? 'returned' : 'in-use'}"><c:out value="${u.status}"/></span></td>
                                    <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/usages/${u.assetUsageId}">View</a></td>
                                </tr></c:forEach></tbody>
                            </table>
                        </div>
                        <div class="table-footer"><span>Showing ${usages.size()} usage record(s)</span></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
