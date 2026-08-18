<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Dashboard | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="admin-page">
<c:set var="activeMenu" value="dashboard" scope="request"/>
<div class="app-shell">
    <%@ include file="includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Admin Dashboard</h1><p>Manage Intern, Mentor, Lab Manager accounts and intern lists</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">AD</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">ADMIN PORTAL</p><h2>User and intern list management</h2></div><a class="primary-button" href="${pageContext.request.contextPath}/admin/interns"><svg><use href="#i-clipboard"/></svg>Review intern lists</a></div>
            <div class="stats-grid">
                <a class="stat-card stat-green" href="${pageContext.request.contextPath}/admin/users?role=INTERN"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${internCount}"/></strong><span>Interns</span><small>Manage intern accounts</small></div></a>
                <a class="stat-card stat-blue" href="${pageContext.request.contextPath}/admin/users?role=MENTOR"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${mentorCount}"/></strong><span>Mentors</span><small>Manage mentor accounts</small></div></a>
                <a class="stat-card stat-purple" href="${pageContext.request.contextPath}/admin/users?role=LAB_MANAGER"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong><c:out value="${labManagerCount}"/></strong><span>Lab Managers</span><small>Manage lab manager accounts</small></div></a>
                <a class="stat-card stat-gold" href="${pageContext.request.contextPath}/admin/interns?status=PENDING"><div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong><c:out value="${pendingLabRequestCount}"/></strong><span>Pending intern lists</span><small>Approve or reject Mentor submissions</small></div></a>
            </div>
        </section>
    </main>
</div>
</body>
</html>
