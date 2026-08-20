<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<c:set var="activeMenu" value="passwordResets" scope="request"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Yêu cầu đặt lại mật khẩu | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="admin-page">
<div class="app-shell">
<%@ include file="includes/sidebar.jspf" %>
<main class="main-content">
    <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Yêu cầu đặt lại mật khẩu</h1><p>Duyệt yêu cầu và cấp mật khẩu tạm thời dùng một lần</p></div></div></header>
    <section class="content-area">
    <c:if test="${not empty temporaryPassword}">
        <p class="success-message">Mật khẩu tạm thời: <strong><c:out value="${temporaryPassword}"/></strong>. Chỉ hiển thị một lần; hãy chuyển bằng kênh an toàn.</p>
    </c:if>
    <c:if test="${not empty message}"><p class="success-message"><c:out value="${message}"/></p></c:if>
    <article class="panel"><div class="table-scroll">
            <table>
                <thead>
                <tr>
                    <th>Người dùng</th><th>Vai trò</th><th>Thời gian gửi</th><th>Trạng thái</th><th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach items="${requests}" var="r">
                    <tr>
                        <td>
                            <c:out value="${r.userName()}"/><br>
                            <small><c:out value="${r.email()}"/></small>
                        </td>
                        <td>${r.role()}</td>
                        <td>${r.createdAt()}</td>
                        <td>${r.status()}</td>
                        <td>
                            <c:if test="${r.status() == 'PENDING'}">
                                <form method="post">
                                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                                    <input type="hidden" name="requestId" value="${r.id()}">
                                     <input class="form-control" type="password" name="temporaryPassword" minlength="8" maxlength="72" placeholder="Mật khẩu tạm tùy chọn">
                                     <button class="primary-button" name="action" value="resetCustom">Dùng mật khẩu đã nhập</button>
                                     <button class="btn-secondary" name="action" value="resetAutomatic">Tạo mật khẩu tự động</button>
                                     <button class="btn-secondary" name="action" value="reject">Từ chối</button>
                                </form>
                            </c:if>
                            <c:if test="${r.status() == 'APPROVED'}">
                                <form method="post">
                                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                                    <input type="hidden" name="requestId" value="${r.id()}">
                                     <button class="primary-button" name="action" value="issue">Cấp mật khẩu tạm thời</button>
                                </form>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div></article>
    </section>
</main>
</div>
</body>
</html>
