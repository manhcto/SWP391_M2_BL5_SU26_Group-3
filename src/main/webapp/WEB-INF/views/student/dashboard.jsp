<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Intern Dashboard | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Intern Dashboard</h1><p>Track your lab assets, returns and responsibility records</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">INTERN PORTAL</p><h2>Welcome, <c:out value="${currentUser.fullName}"/></h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/intern/usages/borrow"><svg><use href="#i-box"/></svg>Borrow an asset</a>
            </div>

            <section class="stats-grid" aria-label="My lab activity summary">
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-box"/></svg></div>
                    <div><strong><c:out value="${activeUsageCount}"/></strong><span>Active loans</span><small>Assets currently in use</small></div>
                </a>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-calendar"/></svg></div>
                    <div><strong><c:out value="${returnedUsageCount}"/></strong><span>Returned assets</span><small>Completed return records</small></div>
                </a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/intern/responsibilities">
                    <div class="stat-icon"><svg><use href="#i-list"/></svg></div>
                    <div><strong><c:out value="${responsibilityCount}"/></strong><span>Responsibilities</span><small>Mentor findings and decisions</small></div>
                </a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/intern/usages">
                    <div class="stat-icon"><svg><use href="#i-grid"/></svg></div>
                    <div><strong><c:out value="${totalUsageCount}"/></strong><span>Total usage</span><small>All borrowing records</small></div>
                </a>
            </section>

            <section class="dashboard-grid intern-dashboard-grid">
                <article class="panel">
                    <header class="panel-header">
                        <div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Recent asset usage</h3></div>
                        <a href="${pageContext.request.contextPath}/intern/usages">View all</a>
                    </header>
                    <div class="table-scroll">
                        <table>
                            <thead><tr><th>Asset</th><th>Quantity</th><th>Borrowed</th><th>Due</th><th>Status</th><th></th></tr></thead>
                            <tbody>
                            <c:choose>
                                <c:when test="${empty usages}"><tr><td colspan="6">No asset usage records yet.</td></tr></c:when>
                                <c:otherwise>
                                    <c:forEach var="usage" items="${usages}" end="4">
                                        <tr>
                                            <td><strong><c:out value="${usage.assetName}"/></strong><br><small><c:out value="${usage.assetCode}"/></small></td>
                                            <td><c:out value="${usage.quantity}"/></td>
                                            <td><c:out value="${usage.borrowedAt}"/></td>
                                            <td><c:out value="${usage.dueAt}"/></td>
                                            <td><span class="status ${usage.status == 'RETURNED' ? 'returned' : 'review'}"><c:out value="${usage.status}"/></span></td>
                                            <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/usages/${usage.assetUsageId}">View</a></td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                            </tbody>
                        </table>
                    </div>
                </article>

                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Quick actions</h3></div></header>
                    <div class="intern-actions">
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/usages/borrow"><span class="intern-action-icon"><svg><use href="#i-box"/></svg></span><span><strong>Borrow an asset</strong><small>Choose an available lab asset</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/usages"><span class="intern-action-icon blue"><svg><use href="#i-calendar"/></svg></span><span><strong>Usage history</strong><small>Review loans and returns</small></span></a>
                        <a class="intern-action" href="${pageContext.request.contextPath}/intern/responsibilities"><span class="intern-action-icon gold"><svg><use href="#i-list"/></svg></span><span><strong>My responsibilities</strong><small>View findings and decisions</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
