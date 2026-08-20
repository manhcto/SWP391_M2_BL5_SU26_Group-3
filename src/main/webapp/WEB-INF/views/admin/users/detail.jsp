<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết người dùng (#USR-${user.userId}) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="admin-page">
<c:set var="activeMenu" value="users" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Hồ sơ người dùng: <c:out value="${user.fullName}"/></h1><p>Thông tin tài khoản và phạm vi phân quyền</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">‹ Quay lại danh sách người dùng</a>
                <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/edit?id=${user.userId}">Sửa người dùng</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>Mã người dùng</label><input class="form-control" type="text" value="#USR-${user.userId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Họ và tên</label><input class="form-control" type="text" value="<c:out value='${user.fullName}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Địa chỉ email</label><input class="form-control" type="text" value="<c:out value='${user.email}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Vai trò được cấp</label><input class="form-control" type="text" value="<c:out value='${app:label(user.role)}'/>" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <c:if test="${not empty user.studentCode}">
                        <div class="form-group"><label>Mã sinh viên</label><input class="form-control" type="text" value="<c:out value='${user.studentCode}'/>" readonly style="background:#f4f6f4;"></div>
                        <div class="form-group"><label>Chuyên ngành và khóa</label><input class="form-control" type="text" value="<c:out value='${user.major}' default='Software Engineering'/> (<c:out value='${user.cohort}' default='K16'/>)" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <div class="form-group"><label>Trạng thái tài khoản</label><input class="form-control" type="text" value="<c:out value='${app:label(user.status)}'/>" readonly style="background:#f4f6f4; color:${user.status == 'ACTIVE' ? '#188255' : '#c63d3d'}; font-weight:700;"></div>
                    <div class="form-group"><label>Ngày tạo</label><input class="form-control" type="text" value="<c:out value='${app:dateTime(user.createdAt)}'/>" readonly style="background:#f4f6f4;"></div>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
