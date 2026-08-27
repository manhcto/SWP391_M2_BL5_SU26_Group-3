<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mượn thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="borrow" scope="request"/>
<div class="app-shell">
    <%@ include file="../../student/includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"
                        aria-controls="sidebar" aria-expanded="false">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Mượn thiết bị</h1>
                    <p>Khai báo sử dụng thiết bị trong học kỳ thực tập đã được phê duyệt</p></div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">IN</div>
                    <span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG INTERN</p>
                    <h2>Yêu cầu mượn mới</h2></div>
                <a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Quay lại lịch sử</a>
            </div>
            <c:if test="${not empty message}"><p class="error-message"><c:out value="${message}"/></p></c:if>
            <c:if test="${not empty assetItems}">
                <article class="panel">
                    <header class="panel-header">
                        <div class="panel-title"><span class="title-icon"><svg><use href="#i-box"/></svg></span>
                            <h3>Chọn sản phẩm để mượn</h3></div>
                    </header>
                    <form method="post" action="${pageContext.request.contextPath}/intern/usages/borrow">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="borrow">
                        <div class="form-grid">
                            <div class="form-group full-width"><label for="assetItemId">Sản phẩm cụ thể</label><select
                                    class="form-control" id="assetItemId" name="assetItemId" required>
                                <option value="">Chọn mã thiết bị</option>
                                <c:forEach items="${assetItems}" var="item">
                                    <option value="${item.assetItemId}" ${param.assetItemId == item.assetItemId ? 'selected' : ''}><c:out
                                            value="${item.itemCode}"/> · <c:out value="${item.assetName}"/><c:if test="${not empty item.serialNumber}"> · Serial <c:out value="${item.serialNumber}"/></c:if></option>
                                </c:forEach>
                            </select></div>
                            <div class="form-group"><label>Số lượng</label><input class="form-control readonly-field" value="1" readonly></div>
                            <div class="form-group"><label>Hạn trả</label><input class="form-control readonly-field" value="Trước 17:40 hôm nay" readonly></div>
                            <div class="form-group full-width"><small>Thời điểm mượn được ghi nhận khi bạn xác nhận. Mỗi lượt mượn chỉ gắn với một mã sản phẩm riêng.</small></div>
                            <div class="form-group full-width"><label for="serializedNote">Ghi chú sử dụng</label><textarea
                                    class="form-control" id="serializedNote" name="note"
                                    placeholder="Mục đích hoặc lưu ý sử dụng"><c:out value="${param.note}"/></textarea></div>
                            <div class="form-group full-width form-actions">
                                <button class="primary-button" type="submit"><svg><use href="#i-box"/></svg>Xác nhận mượn</button>
                            </div>
                        </div>
                    </form>
                </article>
            </c:if>
            <c:if test="${empty assetItems}">
                <article class="panel"><div class="empty-box"><p>Không có thiết bị đủ điều kiện để mượn.</p></div></article>
            </c:if>
        </section>
    </main>
</div>
</body>
</html>
