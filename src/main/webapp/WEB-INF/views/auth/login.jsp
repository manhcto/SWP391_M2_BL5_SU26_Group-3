<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Đăng nhập | Hệ thống quản lý tài sản phòng LAB</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css?v=20260818-campus"></head>
<body class="login-page">
<main class="login-shell">
    <section class="login-panel">
        <div class="login-box">
            <div class="login-brand"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="Đại học FPT"><span>QUẢN LÝ TÀI SẢN PHÒNG LAB</span></div>
            <div class="login-welcome"><h1>Đăng nhập nội bộ Đại học FPT</h1><p>Vui lòng nhập thông tin đăng nhập.</p></div>
            <c:if test="${not empty message}"><p class="login-alert" role="alert"><c:out value="${message}"/></p></c:if>
            <c:if test="${devAuthEnabled}"><form class="login-form" method="post" action="${pageContext.request.contextPath}/login">
                <label class="login-field" for="email"><span>Địa chỉ email</span><input id="email" type="email" name="email" value="<c:out value='${email}'/>" autocomplete="username" placeholder="Nhập địa chỉ email" required><span class="field-icon">✉</span></label>
                <label class="login-field" for="password"><span>Mật khẩu</span><input id="password" type="password" name="password" autocomplete="current-password" placeholder="Nhập mật khẩu" required><button class="password-toggle" type="button" aria-label="Hiện mật khẩu">◉</button></label>
                <div class="login-options"><label><input type="checkbox" name="remember"> Ghi nhớ trong 30 ngày</label><a href="${pageContext.request.contextPath}/forgot-password">Quên mật khẩu?</a></div>
                <button class="login-submit" type="submit">Đăng nhập</button>
            </form>
            <div class="login-divider"><span>hoặc</span></div></c:if>
            <a class="google-button" href="${pageContext.request.contextPath}/oauth2/google"><span class="google-mark">G</span><span>Đăng nhập bằng Gmail</span></a>
        </div>
    </section>
    <aside class="login-visual" aria-label="Hệ thống quản lý tài sản phòng LAB"></aside>
</main>
<script>const password=document.getElementById('password');const toggle=document.querySelector('.password-toggle');if(toggle)toggle.addEventListener('click',()=>{const visible=password.type==='text';password.type=visible?'password':'text';toggle.setAttribute('aria-label',visible?'Hiện mật khẩu':'Ẩn mật khẩu');});</script>
</body>
</html>
