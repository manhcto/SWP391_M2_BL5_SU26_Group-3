<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Details (#USR-${user.userId}) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16"/></symbol>
</svg>
<div class="app-shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="${pageContext.request.contextPath}/admin/dashboard" aria-label="LAB Asset home">
            <span class="brand-mark"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"></span>
            <span><strong>LAB ASSET</strong><small>ADMIN PORTAL</small></span>
        </a>
        <nav class="side-nav">
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-grid"/></svg><span>Dashboard</span></a>
            <a class="nav-link active" href="${pageContext.request.contextPath}/admin/users" aria-current="page"><svg><use href="#i-users"/></svg><span>User Management</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-wrench"/></svg><span>Database Status</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-users"/></svg><span>My Profile</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">AD</div><div class="profile-copy"><strong>System Admin</strong><span><i></i> Online (Superuser)</span></div></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>User Profile: <c:out value="${user.fullName}"/></h1><p>Account details & authorization scope</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">‹ Back to Users</a>
                <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/edit?id=${user.userId}">Edit User</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>User ID</label><input class="form-control" type="text" value="#USR-${user.userId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Full Name</label><input class="form-control" type="text" value="<c:out value='${user.fullName}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Email Address (@fpt.edu.vn)</label><input class="form-control" type="text" value="<c:out value='${user.email}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Assigned Role</label><input class="form-control" type="text" value="<c:out value='${user.role}'/>" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <c:if test="${not empty user.studentCode}">
                        <div class="form-group"><label>Student Roll Code</label><input class="form-control" type="text" value="<c:out value='${user.studentCode}'/>" readonly style="background:#f4f6f4;"></div>
                        <div class="form-group"><label>Major & Cohort</label><input class="form-control" type="text" value="<c:out value='${user.major}' default='Software Engineering'/> (<c:out value='${user.cohort}' default='K16'/>)" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <div class="form-group"><label>Account Status</label><input class="form-control" type="text" value="<c:out value='${user.status}'/>" readonly style="background:#f4f6f4; color:${user.status == 'ACTIVE' ? '#188255' : '#c63d3d'}; font-weight:700;"></div>
                    <div class="form-group"><label>Created Date</label><input class="form-control" type="text" value="<c:out value='${user.createdAt}'/>" readonly style="background:#f4f6f4;"></div>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
