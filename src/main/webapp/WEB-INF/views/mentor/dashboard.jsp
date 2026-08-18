<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mentor Dashboard | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<c:set var="totalInterns" value="0"/>
<c:forEach var="internList" items="${approvedRequests}"><c:set var="totalInterns" value="${totalInterns + internList.studentCount}"/></c:forEach>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Mentor Dashboard</h1><p>Manage intern lists, inspections and lab asset records</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">MENTOR PORTAL</p><h2>Welcome, <c:out value="${currentUser.fullName}"/></h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns"><svg><use href="#i-clipboard"/></svg>Manage intern lists</a>
            </div>

            <section class="stats-grid" aria-label="Mentor workspace summary">
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/mentor/interns">
                    <div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong><c:out value="${approvedRequests.size()}"/></strong><span>Approved lists</span><small>Approved semester records</small></div>
                </a>
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/mentor/interns">
                    <div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${totalInterns}"/></strong><span>Active interns</span><small>Across approved lists</small></div>
                </a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/mentor/inspections">
                    <div class="stat-icon"><svg><use href="#i-inspect"/></svg></div><div><strong>Review</strong><span>Inspections</span><small>Check lab inventory records</small></div>
                </a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/mentor/maintenance">
                    <div class="stat-icon"><svg><use href="#i-wrench"/></svg></div><div><strong>Track</strong><span>Maintenance</span><small>Follow asset proposals</small></div>
                </a>
            </section>

            <section class="dashboard-grid mentor-dashboard-grid">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Approved intern lists</h3></div><a href="${pageContext.request.contextPath}/mentor/interns">View all</a></header>
                    <c:choose>
                        <c:when test="${empty approvedRequests}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-clipboard"/></svg></div><h3>No approved intern list yet</h3><p>Create an intern list and submit it for Admin approval.</p><a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns/add">Create intern list</a></div></c:when>
                        <c:otherwise><div class="table-scroll"><table><thead><tr><th>List</th><th>Semester</th><th>Interns</th><th>Status</th><th>Action</th></tr></thead><tbody><c:forEach var="internList" items="${approvedRequests}"><tr><td><strong><c:out value="${internList.groupName}"/></strong></td><td><c:out value="${internList.semesterCode}"/></td><td><c:out value="${internList.studentCount}"/></td><td><span class="status returned">APPROVED</span></td><td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/interns/view?id=${internList.requestId}">View</a></td></tr></c:forEach></tbody></table></div></c:otherwise>
                    </c:choose>
                </article>

                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Quick actions</h3></div></header>
                    <div class="mentor-actions">
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/interns/add"><span class="mentor-action-icon"><svg><use href="#i-plus"/></svg></span><span><strong>Create intern list</strong><small>Prepare a semester access list</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/inspections/new"><span class="mentor-action-icon gold"><svg><use href="#i-inspect"/></svg></span><span><strong>Create inspection</strong><small>Inspect lab assets and inventory</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/maintenance/add"><span class="mentor-action-icon rose"><svg><use href="#i-wrench"/></svg></span><span><strong>Propose maintenance</strong><small>Submit an asset maintenance request</small></span></a>
                        <a class="mentor-action" href="${pageContext.request.contextPath}/mentor/responsibilities"><span class="mentor-action-icon"><svg><use href="#i-list"/></svg></span><span><strong>Responsibilities</strong><small>Review findings and decisions</small></span></a>
                    </div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
