<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Database Status</title></head>
<body>
<main>
    <h1>Database Connection</h1>
    <p>Status: <strong>${databaseStatus.connected ? 'Connected' : 'Disconnected'}</strong></p>
    <p>${databaseStatus.message}</p>
    <p><a href="${pageContext.request.contextPath}/system/database-status">Check again</a> · <a href="${pageContext.request.contextPath}/">Home</a></p>
</main>
</body>
</html>
