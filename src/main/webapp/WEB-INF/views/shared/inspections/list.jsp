<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Kiểm tra | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="inspection-page${roleBase == '/mentor' ? ' mentor-page' : ' lab-manager-page'}">
<c:set var="activeMenu" value="inspections" scope="request"/>
<div class="app-shell">
    <c:choose>
        <c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when>
        <c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise>
    </c:choose>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Kiểm tra thiết bị</h1><p>Quản lý kiểm tra và kiểm kê phòng LAB</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">${roleBase == '/mentor' ? 'ME' : 'LM'}</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">KHÔNG GIAN LÀM VIỆC · <c:out value="${roleName}"/></p><h2>Hồ sơ kiểm tra và kiểm kê (${inspections.size()})</h2></div><a class="primary-button" href="${pageContext.request.contextPath}${roleBase}/inspections/new">Tạo đợt kiểm tra</a></div>
            <form class="filter-bar inspection-filter" method="get" action="${pageContext.request.contextPath}${roleBase}/inspections">
                <div class="filter-group">
                    <select class="form-control" name="semesterId">
                        <option value="">Tất cả học kỳ</option>
                        <c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${selectedSemesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> - <c:out value="${semester.name}"/></option></c:forEach>
                    </select>
                    <select class="form-control" name="type"><option value="">Tất cả loại</option><option value="INSPECTION" ${selectedType == 'INSPECTION' ? 'selected' : ''}>Kiểm tra</option><option value="INVENTORY" ${selectedType == 'INVENTORY' ? 'selected' : ''}>Kiểm kê</option></select>
                    <select class="form-control" name="status"><option value="">Tất cả trạng thái</option><option value="DRAFT" ${selectedStatus == 'DRAFT' ? 'selected' : ''}>Bản nháp</option><option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>Hoàn tất</option></select>
                    <select class="form-control" name="result"><option value="">Tất cả kết quả</option><option value="NORMAL" ${selectedResult == 'NORMAL' ? 'selected' : ''}>Bình thường</option><option value="DISCREPANCY_FOUND" ${selectedResult == 'DISCREPANCY_FOUND' ? 'selected' : ''}>Có chênh lệch</option></select>
                    <input class="form-control" type="date" name="fromDate" value="<c:out value='${fromDate}'/>">
                    <input class="form-control" type="date" name="toDate" value="<c:out value='${toDate}'/>">
                    <button class="primary-button" type="submit">Lọc</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Đặt lại</a>
                </div>
            </form>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty inspections}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-inspect"/></svg></div><h3>Chưa có hồ sơ kiểm tra</h3><p>Tạo bản nháp kiểm tra cho toàn bộ phòng LAB hoặc các thiết bị chưa thanh lý được chọn.</p><a class="primary-button" href="${pageContext.request.contextPath}${roleBase}/inspections/new">Tạo đợt kiểm tra</a></div></c:when>
                    <c:otherwise>
                        <div class="table-scroll inspection-table-scroll"><table class="inspection-table inspection-list-table"><thead><tr><th>Mã kiểm tra</th><th>Loại</th><th>Học kỳ</th><th>Phạm vi</th><th>Thời gian kiểm tra</th><th>Người kiểm tra</th><th>Trạng thái</th><th>Kết quả</th><th>Thao tác</th></tr></thead><tbody>
                            <c:forEach var="inspection" items="${inspections}"><tr>
                                <td><strong>#INS-${inspection.inspectionId}</strong></td>
                                <td><span class="badge badge-blue"><c:out value="${app:label(inspection.inspectionType)}"/></span></td>
                                <td><c:out value="${inspection.semesterCode}"/></td>
                                <td><c:out value="${app:label(inspection.scope)}"/></td>
                                <td><c:out value="${app:dateTime(inspection.inspectionDate)}"/></td>
                                <td><span class="student"><i>${roleBase == '/mentor' ? 'ME' : 'LM'}</i><c:out value="${inspection.inspectorName}"/></span></td>
                                <td><span class="status ${inspection.status == 'COMPLETED' ? 'returned' : 'review'}"><c:out value="${app:label(inspection.status)}"/></span></td>
                                <td><c:choose><c:when test="${empty inspection.result}">-</c:when><c:otherwise><span class="status ${inspection.result == 'NORMAL' ? 'returned' : 'open'}"><c:out value="${app:label(inspection.result)}"/></span></c:otherwise></c:choose></td>
                                <td class="actions-cell"><a class="btn-action" href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}">Xem</a><c:if test="${inspection.status == 'DRAFT'}"><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}/edit">Sửa</a></c:if></td>
                            </tr></c:forEach>
                        </tbody></table></div>
                        <div class="table-footer"><span>Hiển thị ${inspections.size()} hồ sơ kiểm tra</span><div class="pagination-controls"><button class="page-btn" disabled>‹</button><button class="page-btn active" disabled>1</button><button class="page-btn" disabled>›</button></div></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
