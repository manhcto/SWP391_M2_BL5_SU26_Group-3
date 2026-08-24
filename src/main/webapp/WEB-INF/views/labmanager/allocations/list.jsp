<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Duyệt cấp phát thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css?v=allocation-20260824">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/equipment-allocation.css?v=allocation-20260824">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="allocations" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Duyệt cấp phát thiết bị</h1><p>Đối chiếu nhu cầu của người hướng dẫn với thiết bị sẵn có trong kho</p></div></div></header>
        <section class="content-area allocation-list-page">
            <div class="allocation-list-intro"><div><span class="allocation-eyebrow">ĐIỀU PHỐI THIẾT BỊ</span><h2>Yêu cầu cấp phát</h2><p>Chọn đúng từng thiết bị vật lý trước khi bàn giao cho danh sách thực tập sinh.</p></div><div class="allocation-intro-icon"><svg><use href="#i-clipboard"/></svg></div></div>
            <c:if test="${not empty param.error}"><p class="error-message" role="alert"><c:out value="${param.error}"/></p></c:if>
            <c:if test="${param.success == '1'}"><p class="success-message" role="status">Đã cập nhật cấp phát thiết bị.</p></c:if>

            <article class="panel allocation-list-panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-clipboard"/></svg></span><div><h3>Yêu cầu đang chờ xử lý</h3><p>Kiểm tra số lượng và trạng thái trước khi duyệt.</p></div></div><span class="allocation-panel-note">Thiết bị được quản lý theo từng mã riêng</span></header>
                <div class="table-scroll allocation-table-scroll"><table><thead><tr><th>Hoạt động</th><th>Người hướng dẫn</th><th>Danh sách nhận</th><th>Thiết bị yêu cầu</th><th>Số lượng</th><th>Trạng thái</th><th class="table-action">Thao tác</th></tr></thead><tbody>
                    <c:choose><c:when test="${empty allocationRequests}"><tr><td class="empty-table" colspan="7">Hiện không có yêu cầu cấp phát nào cần duyệt.</td></tr></c:when><c:otherwise><c:forEach items="${allocationRequests}" var="request"><tr><td><strong class="allocation-activity"><c:out value="${request.activityName}"/></strong></td><td><span class="allocation-person"><svg><use href="#i-users"/></svg><c:out value="${request.mentorName}"/></span></td><td><c:out value="${request.targetName}"/></td><td><strong><c:out value="${request.assetName}"/></strong><small class="allocation-code"><c:out value="${request.assetCode}"/></small></td><td><span class="allocation-quantity"><c:out value="${request.requestedQuantity}"/></span></td><td><span class="allocation-status"><c:out value="${app:label(request.status)}"/></span></td><td class="table-action"><c:if test="${request.status == 'PENDING_APPROVAL'}"><a class="allocation-review-button" href="${pageContext.request.contextPath}/lab-manager/allocations/${request.allocationRequestId}">Duyệt yêu cầu <svg><use href="#i-chevron"/></svg></a></c:if></td></tr></c:forEach></c:otherwise></c:choose>
                </tbody></table></div>
            </article>

            <article class="panel allocation-list-panel allocation-recovery-panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon allocation-return-icon"><svg><use href="#i-box"/></svg></span><div><h3>Bàn giao và thu hồi</h3><p>Ghi nhận tình trạng thực tế của từng thiết bị khi kết thúc hoạt động.</p></div></div></header>
                <div class="table-scroll allocation-table-scroll"><table><thead><tr><th>Hoạt động</th><th>Đối tượng</th><th>Thiết bị</th><th>Trạng thái</th><th class="table-recovery">Thu hồi thiết bị</th></tr></thead><tbody>
                    <c:choose><c:when test="${empty allocations}"><tr><td class="empty-table" colspan="5">Chưa có thiết bị đang cần bàn giao hoặc thu hồi.</td></tr></c:when><c:otherwise><c:forEach items="${allocations}" var="allocation"><tr><td><strong class="allocation-activity"><c:out value="${allocation.activityName}"/></strong></td><td><c:out value="${allocation.targetName}"/></td><td><strong><c:out value="${allocation.assetName}"/></strong><small class="allocation-code"><c:out value="${allocation.itemCode}"/></small></td><td><span class="allocation-status allocation-status-active"><c:out value="${app:label(allocation.status)}"/></span></td><td class="table-recovery"><c:if test="${allocation.status == 'ACTIVE' || allocation.status == 'ISSUE_REPORTED'}"><form method="post" class="allocation-recovery-form"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="action" value="recover"><input type="hidden" name="allocationId" value="${allocation.allocationId}"><select class="form-control" name="returnCondition" aria-label="Tình trạng khi thu hồi"><option value="GOOD">Tốt</option><option value="FAIR">Khá</option><option value="DAMAGED">Hỏng</option><option value="BROKEN">Không dùng được</option></select><input class="form-control" name="returnNote" placeholder="Ghi chú khi thu hồi"><button class="primary-button" type="submit">Xác nhận thu hồi</button></form></c:if></td></tr></c:forEach></c:otherwise></c:choose>
                </tbody></table></div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
