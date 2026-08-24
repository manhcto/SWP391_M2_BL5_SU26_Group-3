<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Xử lý bảo trì #MNT-${record.maintenanceId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Xử lý phiếu #MNT-<c:out value="${record.maintenanceId}"/></h1><p>Chỉ thay đổi đúng thiết bị theo mã riêng của phiếu.</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance/${record.maintenanceId}">Quay lại</a></div></header>
        <section class="content-area">
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <div class="form-grid" style="padding:18px">
                    <div class="form-group"><label>Thiết bị chính xác</label><input class="form-control" readonly value="<c:out value='${record.assetItemTag}'/> (${record.assetItemId})"></div>
                    <div class="form-group"><label>Trạng thái Item</label><input class="form-control" readonly value="<c:out value='${app:label(record.assetItemStatus)}'/> · <c:out value='${app:label(record.assetItemCondition)}'/>"></div>
                    <div class="form-group full-width"><label>Mô tả yêu cầu</label><textarea class="form-control" readonly rows="4"><c:out value="${record.description}"/></textarea></div>
                </div>

                <c:choose>
                    <c:when test="${record.status == 'PENDING'}"><form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" style="padding:18px;border-top:1px solid #edf0ec"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="id" value="${record.maintenanceId}"><div class="form-group full-width"><label for="approvalNote">Ghi chú duyệt hoặc từ chối</label><textarea class="form-control" id="approvalNote" name="approvalNote" maxlength="2000" rows="4"><c:out value="${record.approvalNote}"/></textarea></div><div class="form-actions"><button class="danger-button" type="submit" name="action" value="reject">Từ chối</button><button class="primary-button" type="submit" name="action" value="approve">Duyệt yêu cầu</button></div></form></c:when>
                    <c:when test="${record.status == 'APPROVED'}"><form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" style="padding:18px;border-top:1px solid #edf0ec"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="id" value="${record.maintenanceId}"><div class="form-group full-width"><label for="note">Kỹ thuật viên hoặc ghi chú bắt đầu</label><textarea class="form-control" id="note" name="note" maxlength="2000" rows="4"><c:out value="${record.note}"/></textarea></div><div class="form-actions"><button class="primary-button" type="submit" name="action" value="start">Bắt đầu sửa chữa</button></div></form></c:when>
                    <c:when test="${record.status == 'IN_PROGRESS'}"><form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" style="padding:18px;border-top:1px solid #edf0ec"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="id" value="${record.maintenanceId}"><div class="form-group"><label for="repairOutcome">Kết quả sửa chữa *</label><select class="form-control" id="repairOutcome" name="repairOutcome" required><option value="SUCCESS">Thành công, Item về AVAILABLE</option><option value="FAILED">Thất bại, Item về UNAVAILABLE</option></select></div><div class="form-group"><label for="note">Kỹ thuật viên hoặc ghi chú</label><input class="form-control" id="note" name="note" maxlength="2000" value="<c:out value='${record.note}'/>"></div><div class="form-group full-width"><label for="repairResult">Chi tiết kết quả sửa chữa *</label><textarea class="form-control" id="repairResult" name="repairResult" maxlength="2000" rows="5" required><c:out value="${record.repairResult}"/></textarea><small>Sửa thất bại không tự đóng sự cố liên quan.</small></div><div class="form-actions"><button class="primary-button" type="submit" name="action" value="complete">Hoàn tất sửa chữa</button></div></form></c:when>
                    <c:otherwise><div class="empty-box"><h3>Phiếu không còn cần xử lý</h3><p><c:out value="${app:label(record.status)}"/></p></div></c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
