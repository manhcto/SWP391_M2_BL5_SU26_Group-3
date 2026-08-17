<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign in | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body class="login-page">
<main class="login-panel">
    <section class="login-box">
        <div class="login-brand"><span class="brand-mark">LA</span><div><strong>LAB ASSET</strong><small>FPT University</small></div></div>
        <p class="eyebrow">Authorized access</p>
        <h1>Welcome back.</h1>
        <p>Sign in with your authorized FPT Google account to manage laboratory assets safely.</p>
        <p class="alert" role="alert"><c:out value="${message}"/></p>
        <a class="google-button" href="${pageContext.request.contextPath}/oauth2/google"><span class="google-mark">G</span> Continue with FPT Google</a>
        <c:if test="${devAuthEnabled}">
            <form class="dev-login" method="post" action="${pageContext.request.contextPath}/login">
                <div class="mb-3"><label class="form-label" for="email">Local test account</label><input class="form-control" id="email" type="email" name="email" placeholder="student.test@fpt.edu.vn" required></div>
                <button class="btn btn-outline-dark" type="submit">Development sign in</button>
            </form>
        </c:if>
    </section>
</main>
<aside class="login-art"><div><p class="eyebrow">Laboratory operations</p><h2>Every asset.<br>Accounted for.</h2><p>Borrow with confidence. Return with a clear condition trail. Retire equipment without losing its history.</p></div></aside>
</body>
</html>
