<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:choose><c:when test="${formMode == 'edit'}">Sửa vai trò và trạng thái người dùng</c:when><c:otherwise>Thêm người dùng</c:otherwise></c:choose> | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .readonly-field { background: #f2f4f2 !important; border-color: #dbe0dc !important; color: #5a6662 !important; cursor: not-allowed; }
        .lock-badge { display: inline-flex; align-items: center; gap: 4px; font-size: 9.5px; color: #8a938f; font-weight: 600; }
    </style>
</head>
<body class="admin-page">
<c:set var="activeMenu" value="users" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button>
                <div>
                    <h1><c:choose><c:when test="${formMode == 'edit'}">Sửa vai trò và trạng thái người dùng (#USR-${user.userId})</c:when><c:otherwise>Thêm tài khoản mới</c:otherwise></c:choose></h1>
                    <p>Quản trị viên quản lý tài khoản thực tập sinh, người hướng dẫn và quản lý phòng LAB</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">‹ Quay lại danh sách người dùng</a>
                <div class="top-profile"><div class="avatar">AD</div><span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty errors}">
                <div style="padding: 12px 16px; background: #fbeaea; color: #c63d3d; border-radius: 6px; margin-bottom: 16px; font-size: 11.5px;">
                    <ul style="margin: 0; padding-left: 16px;">
                        <c:forEach var="err" items="${errors}">
                            <li>${err}</li>
                        </c:forEach>
                    </ul>
                </div>
            </c:if>

            <article class="panel">
                <c:choose>
                    <%-- CHẾ ĐỘ CHỈNH SỬA (EDIT USER) --%>
                    <c:when test="${formMode == 'edit'}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/edit" class="form-grid">
                            <input type="hidden" name="id" value="${user.userId}">

                            <div class="form-group full-width" style="padding: 10px 14px; background: #fafbf9; border: 1px dashed #d5dbd7; border-radius: 6px;">
                                <span style="font-size: 11.5px; color: #55605c;">✏️ <b>Cập nhật thông tin:</b> Quản trị viên có thể chỉnh sửa Họ tên, Mã sinh viên, Chuyên ngành, Khóa, Vai trò và Trạng thái. Email đăng nhập Google OAuth2 được giữ cố định.</span>
                            </div>

                            <div class="form-group">
                                <label>Họ và tên *</label>
                                <input class="form-control" type="text" name="fullName" value="<c:out value='${user.fullName}'/>" required placeholder="Nhập họ và tên...">
                            </div>

                            <div class="form-group">
                                <label>Email (Gmail / @fpt.edu.vn) *</label>
                                <input class="form-control" type="email" name="email" value="<c:out value='${user.email}'/>" required placeholder="Ví dụ: anhnm@fpt.edu.vn hoặc sinhvien@gmail.com">
                            </div>

                            <c:if test="${user.role == 'INTERN' || not empty user.studentCode}">
                                <div class="form-group">
                                    <label>Mã sinh viên *</label>
                                    <input class="form-control" type="text" name="studentCode" value="<c:out value='${user.studentCode}'/>" required placeholder="Ví dụ: SE160123">
                                </div>
                                <div class="form-group">
                                    <label>Chuyên ngành</label>
                                    <select class="form-control" name="majorId">
                                        <option value="">-- Chọn chuyên ngành --</option>
                                        <c:forEach var="major" items="${majors}">
                                            <option value="${major.majorId}" ${user.majorId == major.majorId ? 'selected' : ''}>
                                                <c:out value="${major.majorCode}"/> - <c:out value="${major.majorName}"/>
                                            </option>
                                        </c:forEach>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>Khóa</label>
                                    <input class="form-control" type="text" name="cohort" value="<c:out value='${user.cohort}'/>" placeholder="Ví dụ: K16">
                                </div>
                            </c:if>

                            <div class="form-group">
                                <label>Vai trò *</label>
                                <c:choose>
                                    <c:when test="${user.role == 'ADMIN'}">
                                        <input class="form-control readonly-field" type="text" value="Quản trị viên hệ thống (Cố định)" readonly disabled>
                                        <input type="hidden" name="role" value="ADMIN">
                                    </c:when>
                                    <c:when test="${user.role == 'INTERN'}">
                                        <input class="form-control readonly-field" type="text" value="Thực tập sinh (Cố định)" readonly disabled>
                                        <input type="hidden" name="role" value="INTERN">
                                    </c:when>
                                    <c:otherwise>
                                        <select class="form-control" name="role" style="border-color: #188255; font-weight: 600;">
                                            <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>Người hướng dẫn</option>
                                            <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>Quản lý phòng LAB</option>
                                        </select>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <div class="form-group">
                                <label>Trạng thái tài khoản * <small style="color:#188255; font-weight:600;">(Được phép khóa/mở)</small></label>
                                <select class="form-control" name="status" style="border-color: #188255; font-weight: 600;">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>Đang hoạt động</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>Khóa tài khoản</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 20px; padding-top: 16px; border-top: 1px solid #edf0ec; display: flex; flex-direction: row; justify-content: space-between; align-items: center;">
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users" style="height: 38px; padding: 0 18px; font-size: 12px;">‹ Hủy</a>
                                <button class="primary-button" type="submit" style="height: 38px; padding: 0 22px; font-size: 12px; cursor: pointer;">Lưu thay đổi</button>
                            </div>
                        </form>
                    </c:when>

                    <%-- CHẾ ĐỘ THÊM MỚI (ADD SINGLE USER) --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/add" class="form-grid">
                            <div class="form-group">
                                <label>Họ và tên *</label>
                                <input class="form-control" type="text" name="fullName" value="<c:out value='${user.fullName}'/>" required placeholder="Ví dụ: Nguyễn Minh Anh">
                            </div>

                            <div class="form-group">
                                <label>Vai trò cần tạo *</label>
                                <select class="form-control" name="role" id="roleSelect" onchange="toggleStudentFields()">
                                    <option value="INTERN" ${user.role == 'INTERN' ? 'selected' : ''}>Thực tập sinh</option>
                                    <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>Người hướng dẫn</option>
                                    <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>Quản lý phòng LAB</option>
                                </select>
                                <c:if test="${hasLabManager}">
                                    <small id="lmNotice" style="display:none; color:#0369a1; font-size:11.5px; margin-top:5px; line-height:1.4;">
                                        ℹ️ Hệ thống hiện có Quản lý phòng LAB (<b><c:out value="${currentLmName}"/></b>). Khi tạo tài khoản mới này, tài khoản Quản lý cũ sẽ tự động chuyển sang trạng thái <b>Khóa (INACTIVE)</b>.
                                    </small>
                                </c:if>
                            </div>

                            <div class="form-group" id="studentCodeGroup">
                                <label>Mã sinh viên *</label>
                                <input class="form-control" type="text" name="studentCode" id="studentCodeInput" value="<c:out value='${user.studentCode}'/>" placeholder="Ví dụ: SE160123">
                            </div>

                            <div class="form-group">
                                <label id="emailLabel">Email (Gmail / @fpt.edu.vn) *</label>
                                <input class="form-control" type="email" name="email" id="emailInput" value="<c:out value='${user.email}'/>" required placeholder="Ví dụ: anhnm@fpt.edu.vn hoặc sinhvien@gmail.com">
                            </div>

                            <div class="form-group" id="majorGroup">
                                <label>Chuyên ngành</label>
                                <select class="form-control" name="majorId" id="majorInput">
                                    <option value="">-- Chọn chuyên ngành --</option>
                                    <c:forEach var="major" items="${majors}">
                                        <option value="${major.majorId}" ${user.majorId == major.majorId ? 'selected' : ''}>
                                            <c:out value="${major.majorCode}"/> - <c:out value="${major.majorName}"/>
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="form-group" id="cohortGroup">
                                <label>Khóa</label>
                                <input class="form-control" type="text" name="cohort" value="<c:out value='${user.cohort}'/>" placeholder="Ví dụ: K16">
                            </div>

                            <div class="form-group">
                                <label>Trạng thái khởi tạo *</label>
                                <select class="form-control" name="status">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>Hoạt động ngay</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>Tạm khóa</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 20px; padding-top: 16px; border-top: 1px solid #edf0ec; display: flex; flex-direction: row; justify-content: space-between; align-items: center;">
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users" style="height: 38px; padding: 0 18px; font-size: 12px;">‹ Hủy</a>
                                <button class="primary-button" type="submit" style="height: 38px; padding: 0 22px; font-size: 12px; cursor: pointer;">Tạo tài khoản</button>
                            </div>
                        </form>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>

<script>
    function toggleStudentFields() {
        const roleSelect = document.getElementById('roleSelect');
        if (!roleSelect) return;
        const isIntern = roleSelect.value === 'INTERN';
        const scGroup = document.getElementById('studentCodeGroup');
        const mjGroup = document.getElementById('majorGroup');
        const chGroup = document.getElementById('cohortGroup');
        const emailLabel = document.getElementById('emailLabel');
        const emailInput = document.getElementById('emailInput');
        const lmNotice = document.getElementById('lmNotice');

        if (scGroup) scGroup.style.display = isIntern ? 'flex' : 'none';
        if (mjGroup) mjGroup.style.display = isIntern ? 'flex' : 'none';
        if (chGroup) chGroup.style.display = isIntern ? 'flex' : 'none';
        if (lmNotice) lmNotice.style.display = (roleSelect.value === 'LAB_MANAGER') ? 'block' : 'none';

        if (isIntern) {
            if (emailLabel) emailLabel.innerHTML = 'Email (Gmail / @fpt.edu.vn) * <span style="color:#0284c7; font-weight:normal;">(Dùng đăng nhập qua Google)</span>';
            if (emailInput) emailInput.placeholder = 'Ví dụ: anhnm@fpt.edu.vn hoặc sinhvien@gmail.com';
        } else if (roleSelect.value === 'MENTOR') {
            if (emailLabel) emailLabel.innerHTML = 'Email đăng nhập *';
            if (emailInput) emailInput.placeholder = 'Ví dụ: mentor@gmail.com hoặc mentor@fpt.edu.vn';
        } else {
            if (emailLabel) emailLabel.innerHTML = 'Email đăng nhập *';
            if (emailInput) emailInput.placeholder = 'Ví dụ: manager@gmail.com hoặc manager@fpt.edu.vn';
        }
    }
    toggleStudentFields();
</script>
</body>
</html>
