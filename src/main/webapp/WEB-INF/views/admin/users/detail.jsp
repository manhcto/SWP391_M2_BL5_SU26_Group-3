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
<c:set var="activeMenu" value="users" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

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
