<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Danh sách thực tập sinh | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body class="mentor-page">
<div class="app-shell"><c:set var="activeMenu" value="labRequests"/>
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
                <div><h1>Quản lý danh sách thực tập sinh</h1>
                    <p>Mỗi học kỳ có một danh sách do người hướng dẫn quản lý</p></div>
            </div>
        </header>
        <section class="request-page">
            <div class="page-title-row">
                <div><h2>Danh sách thực tập sinh</h2>
                    <p>Danh sách chờ duyệt có thể sửa hoặc xóa. Danh sách đã duyệt sẽ bị khóa.</p></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/interns/add">＋ Thêm danh sách
                    thực tập sinh</a></div>
            <c:if test="${param.deleted == '1'}">
                <div class="notice">Đã xóa danh sách thực tập sinh.</div>
            </c:if><c:if test="${param.error == 'delete'}">
            <div class="notice error">Không thể xóa danh sách thực tập sinh này.</div>
        </c:if>
            <div class="request-card">
                <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/interns"><input
                        type="search" name="keyword" value="${fn:escapeXml(keyword)}"
                        placeholder="Tìm theo danh sách hoặc học kỳ..." aria-label="Tìm danh sách"><select name="status"
                                                                                                           aria-label="Trạng thái">
                    <option value="">Tất cả trạng thái</option>
                    <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Chờ duyệt</option>
                    <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                    <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                </select><select name="semesterId" aria-label="Học kỳ">
                    <option value="">Tất cả học kỳ đang mở</option>
                    <c:forEach var="semester" items="${semesters}">
                        <option value="${semester.semesterId}" ${selectedSemesterId == semester.semesterId ? 'selected' : ''}>
                            <c:out value="${semester.code}"/> — <c:out value="${semester.name}"/></option>
                    </c:forEach></select>
                    <div class="filter-actions">
                        <button class="secondary-button" type="submit">Lọc</button>
                        <a class="secondary-button" href="${pageContext.request.contextPath}/mentor/interns">Xóa lọc</a>
                    </div>
                </form>
                <c:choose><c:when test="${empty requests}">
                    <div class="empty-state"><p>Không tìm thấy danh sách thực tập sinh.</p><a class="primary-button"
                                                                                              href="${pageContext.request.contextPath}/mentor/interns/add">Tạo
                        danh sách đầu tiên</a></div>
                </c:when><c:otherwise>
                    <div class="request-table-wrap">
                        <table class="request-table">
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Danh sách / Học kỳ</th>
                                <th>Thực tập sinh</th>
                                <th>Ngày gửi</th>
                                <th>Trạng thái</th>
                                <th>Thao tác</th>
                            </tr>
                            </thead>
                            <tbody><c:forEach var="internList" items="${requests}">
                                <tr>
                                    <td>#<c:out value="${internList.requestId}"/></td>
                                    <td class="group-cell"><strong><c:out
                                            value="${internList.groupName}"/></strong><small><c:out
                                            value="${internList.semesterCode}"/> · <c:out
                                            value="${internList.semesterName}"/></small></td>
                                    <td><c:out value="${internList.studentCount}"/></td>
                                    <td><c:out value="${app:dateTime(internList.createdAt)}"/></td>
                                    <td><span class="request-status status-${internList.status}"><c:out
                                            value="${app:label(internList.status)}"/></span></td>
                                    <td>
                                        <div class="row-actions"><a class="action-link"
                                                                    href="${pageContext.request.contextPath}/mentor/interns/view?id=${internList.requestId}">Xem</a><c:if
                                                test="${internList.status == 'PENDING'}"><a class="action-link"
                                                                                            href="${pageContext.request.contextPath}/mentor/interns/edit?id=${internList.requestId}">Sửa</a>
                                            <form method="post"
                                                  action="${pageContext.request.contextPath}/mentor/interns/delete"
                                                  onsubmit="return confirm('Xóa danh sách đang chờ duyệt này?');"><input
                                                    type="hidden" name="csrfToken" value="${csrfToken}"><input
                                                    type="hidden" name="id" value="${internList.requestId}">
                                                <button class="danger-button" type="submit">Xóa</button>
                                            </form>
                                        </c:if></div>
                                    </td>
                                </tr>
                            </c:forEach></tbody>
                        </table>
                    </div>
                </c:otherwise></c:choose>
            </div>
        </section>
    </main>
</div>
</body>
</html>
