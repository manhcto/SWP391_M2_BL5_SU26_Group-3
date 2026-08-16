<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Login</title></head>
<body>
<main>
    <h1>Login</h1>
    <p>${message}</p>
    <p><small>Authentication will be connected in a later phase.</small></p>
    <form method="post" action="${pageContext.request.contextPath}/login">
        <p><label>Email<br><input type="email" name="email" value="${email}" autocomplete="username" required></label></p>
        <p><label>Password<br><input type="password" name="password" autocomplete="current-password" required></label></p>
        <button type="submit">Login</button>
    </form>
    <p><a href="${pageContext.request.contextPath}/">Home</a></p>
</main>
</body>
</html>
