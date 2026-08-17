<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:choose><c:when test="${formMode == 'edit'}">Edit User Role & Status</c:when><c:otherwise>Add New User</c:otherwise></c:choose> | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .readonly-field { background: #f2f4f2 !important; border-color: #dbe0dc !important; color: #5a6662 !important; cursor: not-allowed; }
        .lock-badge { display: inline-flex; align-items: center; gap: 4px; font-size: 9.5px; color: #8a938f; font-weight: 600; }
    </style>
</head>
<body>
<c:set var="activeMenu" value="users" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button>
                <div>
                    <h1><c:choose><c:when test="${formMode == 'edit'}">Edit User Role & Status (#USR-${user.userId})</c:when><c:otherwise>Add New User Account</c:otherwise></c:choose></h1>
                    <p>Admin manages accounts for Student, Mentor, and Lab Manager</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">‹ Back to Users List</a>
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
                    <%-- CHẾ ĐỘ CHỈNH SỬA (EDIT): CHỈ CHO ĐỔI ROLE VÀ STATUS, KHÓA TOÀN BỘ THÔNG TIN ĐỊNH DANH --%>
                    <c:when test="${formMode == 'edit'}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/edit" class="form-grid">
                            <input type="hidden" name="id" value="${user.userId}">

                            <div class="form-group full-width" style="padding: 10px 14px; background: #fafbf9; border: 1px dashed #d5dbd7; border-radius: 6px;">
                                <span style="font-size: 11.5px; color: #55605c;">🔒 <b>Quy tắc nghiệp vụ:</b> Admin chỉ có quyền chuyển đổi vai trò (Role) và trạng thái (Status). Các thông tin định danh cá nhân không được phép chỉnh sửa.</span>
                            </div>

                            <div class="form-group">
                                <label>Họ và tên <span class="lock-badge">🔒 Cố định</span></label>
                                <input class="form-control readonly-field" type="text" value="<c:out value='${user.fullName}'/>" readonly disabled>
                            </div>

                            <div class="form-group">
                                <label>Email (@fpt.edu.vn) <span class="lock-badge">🔒 Cố định</span></label>
                                <input class="form-control readonly-field" type="email" value="<c:out value='${user.email}'/>" readonly disabled>
                            </div>

                            <c:if test="${not empty user.studentCode}">
                                <div class="form-group">
                                    <label>Mã sinh viên (Roll Number) <span class="lock-badge">🔒 Cố định</span></label>
                                    <input class="form-control readonly-field" type="text" value="<c:out value='${user.studentCode}'/>" readonly disabled>
                                </div>
                                <div class="form-group">
                                    <label>Chuyên ngành & Khóa <span class="lock-badge">🔒 Cố định</span></label>
                                    <input class="form-control readonly-field" type="text" value="<c:out value='${user.major}' default='Software Engineering'/> (<c:out value='${user.cohort}' default='K16'/>)" readonly disabled>
                                </div>
                            </c:if>

                            <div class="form-group">
                                <label>Vai trò (Role) *</label>
                                <c:choose>
                                    <c:when test="${user.role == 'ADMIN'}">
                                        <input class="form-control readonly-field" type="text" value="ADMIN - Quản trị viên hệ thống (Cố định)" readonly disabled>
                                        <input type="hidden" name="role" value="ADMIN">
                                    </c:when>
                                    <c:when test="${user.role == 'INTERN'}">
                                        <input class="form-control readonly-field" type="text" value="INTERN - Sinh viên thực tập (Cố định)" readonly disabled>
                                        <input type="hidden" name="role" value="INTERN">
                                    </c:when>
                                    <c:otherwise>
                                        <select class="form-control" name="role" style="border-color: #188255; font-weight: 600;">
                                            <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>MENTOR - Giảng viên hướng dẫn</option>
                                            <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>LAB_MANAGER - Quản lý Lab</option>
                                        </select>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <div class="form-group">
                                <label>Trạng thái tài khoản (Status) * <small style="color:#188255; font-weight:600;">(Được phép khóa/mở)</small></label>
                                <select class="form-control" name="status" style="border-color: #188255; font-weight: 600;">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>ACTIVE (Đang hoạt động)</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>INACTIVE (Khóa tài khoản)</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 14px; display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Save Changes</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">Cancel</a>
                            </div>
                        </form>
                    </c:when>

                    <%-- CHẾ ĐỘ THÊM MỚI (ADD SINGLE USER) --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/add" class="form-grid">
                            <div class="form-group">
                                <label>Họ và tên *</label>
                                <input class="form-control" type="text" name="fullName" value="<c:out value='${user.fullName}'/>" required placeholder="e.g. Nguyễn Minh Anh">
                            </div>

                            <div class="form-group">
                                <label>Vai trò cần tạo (Role) *</label>
                                <select class="form-control" name="role" id="roleSelect" onchange="toggleStudentFields()">
                                    <option value="INTERN" ${user.role == 'INTERN' ? 'selected' : ''}>INTERN - Sinh viên thực tập</option>
                                    <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>MENTOR - Giảng viên hướng dẫn</option>
                                    <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>LAB_MANAGER - Quản lý Lab</option>
                                </select>
                            </div>

                            <div class="form-group" id="studentCodeGroup">
                                <label>Mã sinh viên (Roll Number) *</label>
                                <input class="form-control" type="text" name="studentCode" id="studentCodeInput" value="<c:out value='${user.studentCode}'/>" placeholder="e.g. SE160123">
                            </div>

                            <div class="form-group">
                                <label id="emailLabel">Email (@fpt.edu.vn) <small style="color:#8a938f">(Để trống sẽ tự sinh theo Họ tên)</small></label>
                                <input class="form-control" type="email" name="email" id="emailInput" value="<c:out value='${user.email}'/>" placeholder="e.g. anhnmse160123@fpt.edu.vn">
                            </div>

                            <div class="form-group" id="passwordGroup">
                                <label>Mật khẩu khởi tạo (Password) *</label>
                                <input class="form-control" type="password" name="password" id="passwordInput" placeholder="Nhập mật khẩu (tối thiểu 6 ký tự)...">
                            </div>

                            <div class="form-group" id="majorGroup">
                                <label>Chuyên ngành (Major)</label>
                                <input class="form-control" type="text" name="major" value="<c:out value='${user.major}'/>" placeholder="e.g. Software Engineering">
                            </div>

                            <div class="form-group" id="cohortGroup">
                                <label>Khóa (Cohort)</label>
                                <input class="form-control" type="text" name="cohort" value="<c:out value='${user.cohort}'/>" placeholder="e.g. K16">
                            </div>

                            <div class="form-group">
                                <label>Trạng thái khởi tạo *</label>
                                <select class="form-control" name="status">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>ACTIVE (Hoạt động ngay)</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>INACTIVE (Tạm khóa)</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 14px; display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Create User Account</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">Cancel</a>
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
        const pwdGroup = document.getElementById('passwordGroup');
        const pwdInput = document.getElementById('passwordInput');

        if (scGroup) scGroup.style.display = isIntern ? 'flex' : 'none';
        if (mjGroup) mjGroup.style.display = isIntern ? 'flex' : 'none';
        if (chGroup) chGroup.style.display = isIntern ? 'flex' : 'none';

        if (pwdGroup) pwdGroup.style.display = isIntern ? 'none' : 'flex';
        if (pwdInput) {
            pwdInput.required = !isIntern;
            if (isIntern) pwdInput.value = '';
        }

        if (isIntern) {
            if (emailLabel) emailLabel.innerHTML = 'Email (@fpt.edu.vn) <small style="color:#8a938f">(Để trống sẽ tự sinh theo Họ tên + Mã SV)</small>';
            if (emailInput) emailInput.placeholder = 'e.g. anhnmse160123@fpt.edu.vn';
        } else {
            if (emailLabel) emailLabel.innerHTML = 'Email (@gmail.com / Email đăng nhập) *';
            if (emailInput) emailInput.placeholder = 'e.g. mentor@gmail.com hoặc manager@gmail.com';
        }
    }
    toggleStudentFields();
</script>
</body>
</html>
