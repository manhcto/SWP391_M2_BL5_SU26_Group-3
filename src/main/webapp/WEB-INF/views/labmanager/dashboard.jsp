<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Lab Manager Dashboard</title></head>
<body>
<main>
    <h1>Lab Manager Dashboard</h1>
    <p>Review student lists and monitor assets, inspections, incidents, maintenance, and disposal.</p>
    <nav><a href="${pageContext.request.contextPath}/lab-manager/usages">Asset usage</a> | <a href="${pageContext.request.contextPath}/lab-manager/disposals">Asset disposal</a></nav>
    <form method="post" action="${pageContext.request.contextPath}/logout"><button>Logout</button></form>
</main>
</body>
</html>
