<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Quên mật khẩu | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
    <style>
        .forgot-page{min-height:100vh;display:grid;place-items:center;padding:24px;background:radial-gradient(circle at 15% 15%,#dbeafe 0,transparent 28%),linear-gradient(135deg,#eef6ff,#f7f3ff)}
        .forgot-shell{width:min(520px,100%);padding:34px;border:1px solid #dbe4f0;border-radius:22px;background:#fff;box-shadow:0 24px 70px rgba(30,64,175,.13)}
        .forgot-brand{display:flex;align-items:center;gap:12px;margin-bottom:28px}.forgot-brand img{width:72px}.forgot-brand strong{color:#172554;font-size:16px}.forgot-brand span{display:block;margin-top:3px;color:#64748b;font-size:11px}
        .forgot-shell h1{margin:0;color:#172554;font-size:28px}.forgot-shell>p{margin:8px 0 24px;color:#64748b;line-height:1.6}.forgot-form{display:grid;gap:16px}.forgot-field{display:grid;gap:7px}.forgot-field span{font-weight:700;color:#334155}.forgot-field input,.forgot-field textarea{width:100%;padding:12px;border:1px solid #cbd5e1;border-radius:10px;outline:none}.forgot-field textarea{min-height:90px;resize:vertical}.forgot-field input:focus,.forgot-field textarea:focus{border-color:#4f46e5;box-shadow:0 0 0 3px rgba(79,70,229,.12)}
        .forgot-submit{min-height:44px;border:0;border-radius:10px;color:#fff;background:linear-gradient(135deg,#2563eb,#4f46e5);font-weight:700;cursor:pointer}.forgot-back{display:block;margin-top:18px;color:#475569;text-align:center}.forgot-alert{padding:11px 13px;border-radius:9px;color:#166534;background:#dcfce7}.forgot-error{color:#991b1b;background:#fee2e2}
    </style>
</head>
<body class="forgot-page">
<main class="forgot-shell">
    <div class="forgot-brand"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="Đại học FPT"><div><strong>LAB ASSET</strong><span>Khôi phục tài khoản nội bộ</span></div></div>
    <h1>Quên mật khẩu?</h1>
    <p>Dành cho Người hướng dẫn và Quản lý phòng LAB. Nhập email tài khoản để gửi yêu cầu đến quản trị viên.</p>
    <c:if test="${not empty success}"><p class="forgot-alert" role="status"><c:out value="${success}"/></p></c:if>
    <c:if test="${not empty message}"><p class="forgot-alert forgot-error" role="alert"><c:out value="${message}"/></p></c:if>
    <form class="forgot-form" method="post">
        <input type="hidden" name="csrfToken" value="${csrfToken}">
        <label class="forgot-field" for="email"><span>Địa chỉ email</span><input id="email" type="email" name="email" value="<c:out value='${param.email}'/>" autocomplete="username" required maxlength="255" placeholder="mentor@gmail.com"></label>
        <label class="forgot-field" for="note"><span>Lý do</span><textarea id="note" name="note" maxlength="500" placeholder="Mô tả ngắn lý do cần đặt lại mật khẩu"></textarea></label>
        <button class="forgot-submit" type="submit">Gửi yêu cầu</button>
    </form>
    <a class="forgot-back" href="${pageContext.request.contextPath}/login">Quay lại đăng nhập</a>
</main>
</body>
</html>
