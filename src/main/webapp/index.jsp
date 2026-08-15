<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>LAB Asset Management System</title>
</head>
<body>
<main>
    <h1>LAB Asset Management System</h1>
    <p>Hệ thống quản lý sinh viên thực tập và vòng đời tài sản phòng LAB.</p>
    <p><a href="${pageContext.request.contextPath}/login">Login</a></p>

    <h2>Role dashboards</h2>
    <ul>
        <li><a href="${pageContext.request.contextPath}/admin/dashboard">Admin Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/lab-manager/dashboard">Lab Manager Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/mentor/dashboard">Mentor Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/student/dashboard">Student Dashboard</a></li>
    </ul>
</main>
</body>
</html>
