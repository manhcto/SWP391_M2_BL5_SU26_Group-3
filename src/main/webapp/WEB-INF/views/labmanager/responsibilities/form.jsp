<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Sửa xử lý trách nhiệm | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page"><c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Cập nhật xử lý và bồi thường</h1><p>Lab Manager duyệt hoặc điều chỉnh quyết định xử lý sự cố lớn</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities/${responsibility.responsibilityId}">‹ Quay lại</a></div></header>
        <section class="content-area"><c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if><article class="panel"><form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/responsibilities"><input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}"><input type="hidden" name="action" value="update"><input type="hidden" name="responsibilityId" value="${responsibility.responsibilityId}">
            <div class="form-group full-width"><label>Sự cố / thực tập sinh liên quan</label><input class="form-control readonly-field" value="<c:out value='${responsibility.incidentCode}'/> · <c:out value='${responsibility.assetName}'/> · <c:out value='${responsibility.internName}'/>" readonly></div>
            <div class="form-group full-width"><label>Kết luận của Mentor</label><textarea class="form-control readonly-field" rows="4" readonly><c:out value="${responsibility.conclusion}"/></textarea></div>
            <div class="form-group full-width"><label>Quyết định xử lý / bồi thường</label><textarea class="form-control" name="decision" rows="4" placeholder="Xác nhận hoặc điều chỉnh phương án bồi thường"><c:out value="${responsibility.decision}"/></textarea></div>
            <div class="form-group"><label>Trạng thái *</label><select class="form-control" name="status" required><option value="APPROVED" ${responsibility.status == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option><option value="REJECTED" ${responsibility.status == 'REJECTED' ? 'selected' : ''}>Từ chối</option><option value="RESOLVED" ${responsibility.status == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option></select></div>
            <div class="form-group"><label>Ghi chú giải quyết</label><input class="form-control" name="resolutionNote" value="<c:out value='${responsibility.resolutionNote}'/>" placeholder="Kết quả xử lý cuối cùng"></div>
            <div class="form-group full-width"><label>Ghi chú của Lab Manager</label><textarea class="form-control" name="reviewNote" rows="4" placeholder="Lý do duyệt, từ chối hoặc điều chỉnh"><c:out value="${responsibility.reviewNote}"/></textarea></div>
            <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Lưu thay đổi</button><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities/${responsibility.responsibilityId}">Hủy</a></div>
        </form></article></section>
    </main>
</div>
</body></html>
