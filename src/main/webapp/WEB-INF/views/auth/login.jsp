<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Đăng nhập hệ thống quản lý tài sản phòng LAB FPT University">
    <title>Đăng nhập | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/auth-login.css">
    <c:if test="${googleEnabled}"><script src="https://accounts.google.com/gsi/client" async defer></script></c:if>
</head>
<body>
<main class="login-page">
    <section class="login-card" aria-labelledby="login-title">
        <div class="login-form-panel">
            <div class="login-form-wrap">
                <a class="login-brand" href="${pageContext.request.contextPath}/login" aria-label="LAB Asset login">
                    <img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University">
                    <span><strong>LAB ASSET</strong><small>FPT UNIVERSITY</small></span>
                </a>

                <div class="login-heading">
                    <p class="eyebrow">WELCOME BACK</p>
                    <h1 id="login-title">Chào mừng trở lại</h1>
                    <p>Đăng nhập để tiếp tục quản lý phòng LAB.</p>
                </div>

                <c:if test="${not empty errorMessage}">
                    <div class="login-message error" role="alert"><span>!</span><c:out value="${errorMessage}"/></div>
                </c:if>
                <c:if test="${param.loggedOut == '1'}">
                    <div class="login-message success" role="status"><span>✓</span>Bạn đã đăng xuất thành công.</div>
                </c:if>

                <form class="login-form" method="post" action="${pageContext.request.contextPath}/login">
                    <input type="hidden" name="csrfToken" value="${loginCsrfToken}">
                    <label class="field-label" for="email">Email</label>
                    <div class="input-wrap">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16v12H4zM4 7l8 6 8-6"/></svg>
                        <input id="email" type="email" name="email" value="<c:out value='${email}'/>" placeholder="name@example.com" autocomplete="username" required autofocus>
                    </div>

                    <label class="field-label" for="password">Mật khẩu</label>
                    <div class="input-wrap">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
                        <input id="password" type="password" name="password" placeholder="Nhập mật khẩu" autocomplete="current-password" required>
                        <button class="password-toggle" id="passwordToggle" type="button" aria-label="Hiện mật khẩu" aria-pressed="false">
                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="2.5"/></svg>
                        </button>
                    </div>

                    <button class="login-submit" type="submit">Đăng nhập</button>
                </form>

                <div class="login-divider"><span>Hoặc tiếp tục với</span></div>

                <c:choose>
                    <c:when test="${googleEnabled}">
                        <div id="g_id_onload"
                             data-client_id="${googleClientId}"
                             data-login_uri="${googleLoginUri}"
                             data-auto_prompt="false"></div>
                        <div class="google-button-wrap">
                            <div class="g_id_signin"
                                 data-type="standard"
                                 data-shape="rectangular"
                                 data-theme="outline"
                                 data-text="continue_with"
                                 data-size="large"
                                 data-logo_alignment="left"
                                 data-width="360"></div>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <button class="google-disabled" type="button" disabled>
                            <span class="google-g">G</span> Google Authentication chưa cấu hình
                        </button>
                    </c:otherwise>
                </c:choose>

                <p class="login-note">Chỉ tài khoản đang hoạt động và có trong danh sách hệ thống mới đăng nhập được.</p>
            </div>
        </div>

        <div class="login-image-panel">
            <img src="${pageContext.request.contextPath}/assets/images/fpt-campus-login.png" alt="Khuôn viên FPT University">
            <div class="image-overlay"></div>
            <div class="image-copy">
                <span>LAB ASSET MANAGEMENT</span>
                <h2>Quản lý tài sản phòng LAB rõ ràng và hiệu quả.</h2>
                <p>Một nền tảng chung cho Admin, Lab Manager, Mentor và Student.</p>
            </div>
        </div>
    </section>
</main>
<script>
    const toggle = document.getElementById('passwordToggle');
    const password = document.getElementById('password');
    toggle.addEventListener('click', () => {
        const show = password.type === 'password';
        password.type = show ? 'text' : 'password';
        toggle.setAttribute('aria-label', show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu');
        toggle.setAttribute('aria-pressed', String(show));
    });
</script>
</body>
</html>
