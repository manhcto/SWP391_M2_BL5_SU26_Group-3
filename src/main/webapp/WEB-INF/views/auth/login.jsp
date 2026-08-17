<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Login | LAB ASSET MANAGEMENT</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css?v=20260817-login"></head>
<body class="login-page">
<main class="login-shell">
    <section class="login-panel">
        <div class="login-box">
            <div class="login-brand"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"><span>LAB ASSET MANAGEMENT</span></div>
            <div class="login-welcome"><div class="welcome-icon" aria-hidden="true">⌂</div><h1>Welcome home</h1><p>Please enter your details.</p></div>
            <c:if test="${not empty message}"><p class="login-alert" role="alert"><c:out value="${message}"/></p></c:if>
            <form class="login-form" method="post" action="${pageContext.request.contextPath}/login">
                <label class="login-field" for="email"><span>Email</span><input id="email" type="email" name="email" value="<c:out value='${email}'/>" autocomplete="username" placeholder="Enter your email" required><span class="field-icon">✉</span></label>
                <label class="login-field" for="password"><span>Password</span><input id="password" type="password" name="password" autocomplete="current-password" placeholder="Enter your password" required><button class="password-toggle" type="button" aria-label="Show password">◉</button></label>
                <div class="login-options"><label><input type="checkbox" name="remember"> Remember for 30 days</label><span>Forgot password?</span></div>
                <button class="login-submit" type="submit">Login</button>
            </form>
            <div class="login-divider"><span>or</span></div>
            <a class="google-button" href="${pageContext.request.contextPath}/oauth2/google"><span class="google-mark">G</span><span>Sign in with Gmail</span></a>
        </div>
    </section>
    <aside class="login-visual" aria-label="LAB Asset Management"></aside>
</main>
<script>const password=document.getElementById('password');const toggle=document.querySelector('.password-toggle');if(toggle)toggle.addEventListener('click',()=>{const visible=password.type==='text';password.type=visible?'password':'text';toggle.setAttribute('aria-label',visible?'Show password':'Hide password');});</script>
</body>
</html>
