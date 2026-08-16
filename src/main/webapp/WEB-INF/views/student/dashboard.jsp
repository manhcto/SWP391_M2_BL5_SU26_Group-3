<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Student Dashboard</title></head>
<body>
<main>
    <h1>Student Dashboard</h1>
    <p>Signed in as <strong><c:out value="${currentUser.fullName}"/></strong> (<c:out value="${currentUser.email}"/>).</p>
    <p>Borrow assets and view your usage history, reported incidents, and responsibility records.</p>
    <nav><a href="${pageContext.request.contextPath}/mentor/dashboard">Open Mentor UI</a> · <a href="${pageContext.request.contextPath}/admin/dashboard">Open Admin UI</a> · <a href="${pageContext.request.contextPath}/lab-manager/dashboard">Open Lab Manager UI</a></nav>
    <form method="post" action="${pageContext.request.contextPath}/logout"><button type="submit">Log out</button></form>
</main>
</body>
</html>
