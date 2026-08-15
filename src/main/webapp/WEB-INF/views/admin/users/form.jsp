<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<c:set var="editing" value="${formMode == 'edit'}"/>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${editing ? 'Edit User' : 'Add User'}</title>
</head>
<body>
<main>
    <h1>${editing ? 'Edit User' : 'Add User'}</h1>

    <c:if test="${not empty databaseError}"><p><c:out value="${databaseError}"/></p></c:if>
    <c:if test="${not empty errors}">
        <ul>
            <c:forEach var="error" items="${errors}"><li><c:out value="${error}"/></li></c:forEach>
        </ul>
    </c:if>

    <form method="post" action="${pageContext.request.contextPath}/admin/users/${editing ? 'edit' : 'add'}">
        <c:if test="${editing}"><input type="hidden" name="id" value="${user.userId}"></c:if>

        <p><label>Full name
            <input type="text" name="fullName" maxlength="100" required value="<c:out value='${user.fullName}'/>">
        </label></p>
        <p><label>Email
            <input type="email" name="email" maxlength="255" required value="<c:out value='${user.email}'/>">
        </label></p>
        <p><label>Password
            <input type="password" name="password" minlength="8" ${editing ? '' : 'required'}>
        </label> ${editing ? '(leave blank to keep the current password)' : ''}</p>
        <p><label>Role
            <select name="role" required>
                <option value="">Select role</option>
                <option value="ADMIN" ${user.role == 'ADMIN' ? 'selected' : ''}>Admin</option>
                <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>Lab Manager</option>
                <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>Mentor</option>
                <option value="STUDENT" ${user.role == 'STUDENT' ? 'selected' : ''}>Student</option>
            </select>
        </label></p>
        <p><label>Status
            <select name="status" required>
                <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>Active</option>
                <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>Inactive</option>
            </select>
        </label></p>

        <fieldset>
            <legend>Student information (required only for Student role)</legend>
            <p><label>Student code
                <input type="text" name="studentCode" maxlength="30" value="<c:out value='${user.studentCode}'/>">
            </label></p>
            <p><label>Major
                <input type="text" name="major" maxlength="100" value="<c:out value='${user.major}'/>">
            </label></p>
            <p><label>Cohort
                <input type="text" name="cohort" maxlength="30" value="<c:out value='${user.cohort}'/>">
            </label></p>
        </fieldset>

        <button type="submit">${editing ? 'Save Changes' : 'Create User'}</button>
        <a href="${pageContext.request.contextPath}/admin/users">Cancel</a>
    </form>
</main>
</body>
</html>
