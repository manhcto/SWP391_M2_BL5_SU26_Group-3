<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết phiếu bảo trì | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Chi tiết phiếu: <c:out value="${record.assetName}"/></h1><p>Theo dõi đề xuất và trạng thái xử lý</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách đề xuất</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>Mã phiếu</label><input class="form-control" type="text" value="#MNT-${record.maintenanceId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Thông tin thiết bị</label><input class="form-control" type="text" value="<c:out value='${record.assetName}'/> (<c:out value='${record.assetCode}'/>)" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <div class="form-group"><label>Ngày gửi</label><input class="form-control" type="text" value="<c:out value='${app:dateTime(record.requestedAt)}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Trạng thái tiến độ hiện tại</label><input class="form-control" type="text" value="<c:out value='${app:label(record.status)}'/>" readonly style="background:#f4f6f4; font-weight:700; color:#188255;"></div>
                    <div class="form-group full-width"><label>Mô tả sự cố đã báo cáo</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.description}"/></textarea></div>
                    <div class="form-group"><label>Người phê duyệt</label><input class="form-control" type="text" value="<c:out value='${record.approverName}' default='Chờ quản lý phòng LAB xem xét'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.approvalNote}">
                        <div class="form-group"><label>Ghi chú phê duyệt của quản lý</label><input class="form-control" type="text" value="<c:out value='${record.approvalNote}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <c:if test="${not empty record.repairResult}">
                        <div class="form-group full-width"><label>Kết quả sửa chữa và đánh giá</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.repairResult}"/></textarea></div>
                    </c:if>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
