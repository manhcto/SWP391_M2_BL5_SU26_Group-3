<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${formMode == 'edit' ? 'Sửa' : 'Thêm'} danh sách thực tập sinh | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body class="mentor-page">
<div class="app-shell">
    <c:set var="activeMenu" value="labRequests"/>
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"
                        aria-controls="sidebar" aria-expanded="false">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>${formMode == 'edit' ? 'Sửa danh sách thực tập sinh' : 'Thêm danh sách thực tập sinh'}</h1>
                    <p>Gửi một danh sách thực tập sinh cho một học kỳ</p></div>
            </div>
        </header>
        <section class="request-page">
            <div class="page-title-row">
                <div><h2>${formMode == 'edit' ? 'Cập nhật danh sách thực tập sinh' : 'Danh sách thực tập sinh mới'}</h2>
                    <p>Quản trị viên phê duyệt toàn bộ danh sách một lần. Không quản lý phòng, ca hoặc lịch.</p></div>
                <a class="secondary-button" href="${pageContext.request.contextPath}/mentor/interns">Quay lại danh
                    sách</a></div>
            <c:if test="${not empty errors}">
                <ul class="error-list"><c:forEach var="error" items="${errors}">
                    <li><c:out value="${error}"/></li>
                </c:forEach></ul>
            </c:if>
            <c:if test="${not empty databaseError}">
                <div class="notice error"><c:out value="${databaseError}"/></div>
            </c:if>

            <form class="form-shell" method="post" enctype="multipart/form-data"
                  action="${pageContext.request.contextPath}/mentor/interns/${formMode == 'edit' ? 'edit' : 'add'}">
                <input type="hidden" name="csrfToken" value="${csrfToken}">
                <c:if test="${formMode == 'edit'}"><input type="hidden" name="id"
                                                          value="${labRequest.requestId}"></c:if>
                <section class="form-section"><h3>Thông tin danh sách</h3>
                    <div class="form-grid">
                        <label class="field"><span>Học kỳ *</span><select name="semesterId" required>
                            <option value="">Chọn học kỳ</option>
                            <c:forEach var="semester" items="${semesters}">
                                <option value="${semester.semesterId}" ${labRequest.semesterId == semester.semesterId ? 'selected' : ''}>
                                    <c:out value="${semester.code}"/> — <c:out value="${semester.name}"/></option>
                            </c:forEach></select></label>
                        <label class="field"><span>Tên danh sách *</span><input type="text" name="groupName"
                                                                                maxlength="100"
                                                                                value="<c:out value='${labRequest.groupName}'/>"
                                                                                placeholder="Ví dụ: Danh sách thực tập sinh FA26"
                                                                                required></label>
                        <label class="field wide"><span>Ghi chú của người hướng dẫn</span><textarea name="requestNote"
                                                                                                    placeholder="Thêm thông tin cho quản trị viên..."><c:out
                                value="${labRequest.requestNote}"/></textarea></label>
                    </div>
                </section>

                <section class="form-section">
                    <div class="section-tools">
                        <div><h3>Thực tập sinh</h3><span
                                class="section-label">Mã thực tập sinh, họ tên, Gmail và khóa</span></div>
                        <button class="secondary-button" id="addIntern" type="button">Thêm thực tập sinh</button>
                    </div>
                    <div class="scroll-box">
                        <table class="student-editor">
                            <thead>
                            <tr>
                                <th>Mã thực tập sinh</th>
                                <th>Họ và tên</th>
                                <th>Địa chỉ email</th>
                                <th>Khóa</th>
                                <th></th>
                            </tr>
                            </thead>
                            <tbody id="internRows">
                            <c:choose><c:when test="${empty labRequest.students}">
                                <tr>
                                    <td><input name="internCode" placeholder="TTS001" required></td>
                                    <td><input name="internName" placeholder="Nguyễn Văn A" required></td>
                                    <td><input type="email" name="internEmail" placeholder="thuctapsinh@gmail.com"
                                               required></td>
                                    <td><input name="cohort" placeholder="K17" required></td>
                                    <td>
                                        <button class="danger-button remove-intern" type="button">Xóa</button>
                                    </td>
                                </tr>
                            </c:when><c:otherwise><c:forEach var="intern" items="${labRequest.students}">
                                <tr>
                                    <td><input name="internCode" value="<c:out value='${intern.studentCode}'/>"
                                               required></td>
                                    <td><input name="internName" value="<c:out value='${intern.fullName}'/>" required>
                                    </td>
                                    <td><input type="email" name="internEmail" value="<c:out value='${intern.email}'/>"
                                               required></td>
                                    <td><input name="cohort" value="<c:out value='${intern.cohort}'/>" required></td>
                                    <td>
                                        <button class="danger-button remove-intern" type="button">Xóa</button>
                                    </td>
                                </tr>
                            </c:forEach></c:otherwise></c:choose>
                            </tbody>
                        </table>
                    </div>
                    <div class="import-box"><label class="field"><span>Hoặc nhập từ Excel (.xlsx)</span><input
                            type="file" name="excelFile"
                            accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"></label><a
                            class="secondary-button" href="${pageContext.request.contextPath}/mentor/interns/template">Tải
                        tệp mẫu</a><small>Trang tính: Thực tập sinh. Các cột: Mã thực tập sinh, Họ tên, Gmail,
                        Khóa.</small></div>
                </section>
                <div class="form-actions"><a class="secondary-button"
                                             href="${pageContext.request.contextPath}/mentor/interns">Hủy</a>
                    <button class="primary-button"
                            type="submit">${formMode == 'edit' ? 'Lưu thay đổi' : 'Gửi danh sách thực tập sinh'}</button>
                </div>
            </form>
        </section>
    </main>
</div>
<template id="internRowTemplate">
    <tr>
        <td><input name="internCode" placeholder="TTS001" required></td>
        <td><input name="internName" placeholder="Nguyễn Văn A" required></td>
        <td><input type="email" name="internEmail" placeholder="thuctapsinh@gmail.com" required></td>
        <td><input name="cohort" placeholder="K17" required></td>
        <td>
            <button class="danger-button remove-intern" type="button">Xóa</button>
        </td>
    </tr>
</template>
<script>
    const rows = document.getElementById('internRows');
    document.getElementById('addIntern').addEventListener('click', () => rows.append(document.getElementById('internRowTemplate').content.cloneNode(true)));
    rows.addEventListener('click', event => {
        if (event.target.classList.contains('remove-intern')) event.target.closest('tr').remove();
    });
</script>
</body>
</html>
