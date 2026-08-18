<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lab Manager Dashboard | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Lab Manager Dashboard</h1><p>Monitor laboratory assets and maintenance operations</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">LM</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">LAB MANAGER PORTAL</p><h2>Operations overview</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/usages"><svg><use href="#i-box"/></svg>Open Asset Usages</a></div>
            <div class="stats-grid">
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/usages"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>Asset usage</strong><span>Review borrowing and return records</span><small>Open asset usage</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/responsibilities"><div class="stat-icon"><svg><use href="#i-list"/></svg></div><div><strong>Responsibilities</strong><span>View Mentor findings and handling decisions</span><small>Open responsibility records</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/lab-manager/disposals"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>Disposal</strong><span>Review asset disposal requests</span><small>Open disposal management</small></div></a>
            </div>
        </section>
    </main>
</div>
</body>
</html>
