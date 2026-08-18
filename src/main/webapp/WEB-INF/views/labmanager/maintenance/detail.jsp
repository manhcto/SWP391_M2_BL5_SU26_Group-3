<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Phiếu bảo trì #MNT-${record.maintenanceId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Phiếu #MNT-${record.maintenanceId}: <c:out value="${record.assetName}"/></h1><p>Hồ sơ toàn bộ vòng đời bảo trì</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance">‹ Quay lại danh sách</a>
                <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/edit?id=${record.maintenanceId}">Cập nhật / Phê duyệt phiếu</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>Mã phiếu</label><input class="form-control" type="text" value="#MNT-${record.maintenanceId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Tên và mã thiết bị</label><input class="form-control" type="text" value="<c:out value='${record.assetName}'/> (<c:out value='${record.assetCode}'/>)" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <div class="form-group"><label>Người yêu cầu</label><input class="form-control" type="text" value="<c:out value='${record.requesterName}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Thời gian yêu cầu</label><input class="form-control" type="text" value="<c:out value='${app:dateTime(record.requestedAt)}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group full-width"><label>Mô tả sự cố</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.description}"/></textarea></div>
                    
                    <div class="form-group"><label>Trạng thái hiện tại</label><input class="form-control" type="text" value="<c:out value='${app:label(record.status)}'/>" readonly style="background:#f4f6f4; font-weight:700; color:#188255;"></div>
                    <div class="form-group"><label>Người phê duyệt</label><input class="form-control" type="text" value="<c:out value='${record.approverName}' default='—'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.approvalNote}">
                        <div class="form-group full-width"><label>Ghi chú phê duyệt và chi phí</label><input class="form-control" type="text" value="<c:out value='${record.approvalNote}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <div class="form-group"><label>Bắt đầu sửa lúc</label><input class="form-control" type="text" value="<c:out value='${app:dateTime(record.repairStartedAt)}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Hoàn tất sửa lúc</label><input class="form-control" type="text" value="<c:out value='${app:dateTime(record.repairCompletedAt)}'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.repairResult}">
                        <div class="form-group full-width"><label>Kết quả sửa chữa và kiểm tra</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.repairResult}"/></textarea></div>
                    </c:if>
                    <c:if test="${not empty record.note}">
                        <div class="form-group full-width"><label>Ghi chú của kỹ thuật viên</label><input class="form-control" type="text" value="<c:out value='${record.note}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
