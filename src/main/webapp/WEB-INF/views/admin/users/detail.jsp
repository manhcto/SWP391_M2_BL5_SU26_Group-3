<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Details</title>
</head>
<body>
<main>
    <h1>User Details</h1>
    <c:if test="${param.created == '1'}"><p>User created successfully.</p></c:if>
    <c:if test="${param.updated == '1'}"><p>User updated successfully.</p></c:if>

    <dl>
        <dt>ID</dt><dd><c:out value="${user.userId}"/></dd>
        <dt>Full name</dt><dd><c:out value="${user.fullName}"/></dd>
        <dt>Email</dt><dd><c:out value="${user.email}"/></dd>
        <dt>Role</dt><dd><c:out value="${user.role}"/></dd>
        <dt>Status</dt><dd><c:out value="${user.status}"/></dd>
        <dt>Authentication</dt>
        <dd>${empty user.googleSubject ? 'Local account' : 'Google account linked'}</dd>
        <c:if test="${user.role == 'STUDENT'}">
            <dt>Student code</dt><dd><c:out value="${user.studentCode}"/></dd>
            <dt>Major</dt><dd><c:out value="${user.major}" default="—"/></dd>
            <dt>Cohort</dt><dd><c:out value="${user.cohort}" default="—"/></dd>
        </c:if>
        <dt>Created at</dt><dd><c:out value="${user.createdAt}"/></dd>
        <dt>Updated at</dt><dd><c:out value="${user.updatedAt}"/></dd>
    </dl>

    <nav>
        <a href="${pageContext.request.contextPath}/admin/users/edit?id=${user.userId}">Edit User</a> ·
        <a href="${pageContext.request.contextPath}/admin/users">Back to Users</a>
    </nav>
</main>
</body>
</html>
