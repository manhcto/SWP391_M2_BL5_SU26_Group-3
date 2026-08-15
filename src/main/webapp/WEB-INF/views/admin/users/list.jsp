<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Manage Users</title>
</head>
<body>
<main>
    <h1>Manage Users</h1>
    <nav>
        <a href="${pageContext.request.contextPath}/admin/users/add">Add User</a> ·
        <a href="${pageContext.request.contextPath}/admin/dashboard">Admin Dashboard</a>
    </nav>

    <form method="get" action="${pageContext.request.contextPath}/admin/users">
        <label>Search
            <input type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Name or email">
        </label>
        <label>Role
            <select name="role">
                <option value="">All roles</option>
                <option value="ADMIN" ${selectedRole == 'ADMIN' ? 'selected' : ''}>Admin</option>
                <option value="LAB_MANAGER" ${selectedRole == 'LAB_MANAGER' ? 'selected' : ''}>Lab Manager</option>
                <option value="MENTOR" ${selectedRole == 'MENTOR' ? 'selected' : ''}>Mentor</option>
                <option value="STUDENT" ${selectedRole == 'STUDENT' ? 'selected' : ''}>Student</option>
            </select>
        </label>
        <label>Status
            <select name="status">
                <option value="">All statuses</option>
                <option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>Active</option>
                <option value="INACTIVE" ${selectedStatus == 'INACTIVE' ? 'selected' : ''}>Inactive</option>
            </select>
        </label>
        <button type="submit">Filter</button>
        <a href="${pageContext.request.contextPath}/admin/users">Clear</a>
    </form>

    <c:choose>
        <c:when test="${empty users}">
            <p>No users found.</p>
        </c:when>
        <c:otherwise>
            <table border="1" cellpadding="6">
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Full name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Student code</th>
                    <th>Actions</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="user" items="${users}">
                    <tr>
                        <td><c:out value="${user.userId}"/></td>
                        <td><c:out value="${user.fullName}"/></td>
                        <td><c:out value="${user.email}"/></td>
                        <td><c:out value="${user.role}"/></td>
                        <td><c:out value="${user.status}"/></td>
                        <td><c:out value="${user.studentCode}" default="—"/></td>
                        <td>
                            <a href="${pageContext.request.contextPath}/admin/users/view?id=${user.userId}">View</a> ·
                            <a href="${pageContext.request.contextPath}/admin/users/edit?id=${user.userId}">Edit</a>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>
</main>
</body>
</html>
