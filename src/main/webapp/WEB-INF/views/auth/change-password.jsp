<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Change Password | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body class="login-page">
<main class="login-shell">
    <section class="login-panel">
        <div class="login-box">
            <div class="login-brand">
                <img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png"
                     alt="FPT University">
                <span>LAB ASSET MANAGEMENT</span>
            </div>
            <div class="login-welcome">
                <div class="welcome-icon" aria-hidden="true">*</div>
                <h1>Change password</h1>
                <p>${sessionScope.mustChangePassword ? 'A new password is required before continuing.' : 'Keep your internal account secure.'}</p>
            </div>
            <c:if test="${not empty message}">
                <p class="login-alert"><c:out value="${message}"/></p>
            </c:if>
            <form class="login-form" method="post">
                <input type="hidden" name="csrfToken" value="${csrfToken}">
                <label class="login-field">
                    <span>Current or temporary password</span>
                    <input type="password" name="currentPassword" required>
                </label>
                <label class="login-field">
                    <span>New password</span>
                    <input type="password" name="newPassword" minlength="8" required>
                </label>
                <label class="login-field">
                    <span>Confirm password</span>
                    <input type="password" name="confirmPassword" minlength="8" required>
                </label>
                <button class="login-submit">Change password</button>
            </form>
        </div>
    </section>
    <aside class="login-visual" aria-label="LAB Asset Management"></aside>
</main>
</body>
</html>
