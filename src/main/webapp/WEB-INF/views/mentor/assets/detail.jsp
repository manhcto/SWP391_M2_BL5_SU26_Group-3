<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết ${item.itemCode} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-catalog.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="assets" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Chi tiết thiết bị</h1>
                    <p>Thông tin trạng thái của từng sản phẩm trong phòng LAB</p>
                </div>
            </div>
        </header>

        <section class="content-area mentor-asset-detail">
            <article class="mentor-asset-detail-panel">
                <div class="mentor-asset-detail-image">
                    <c:choose>
                        <c:when test="${not empty item.imagePath}">
                            <img src="${pageContext.request.contextPath}${item.imagePath}" alt="Ảnh đầy đủ ${item.itemCode}">
                        </c:when>
                        <c:otherwise>
                            <svg aria-label="Chưa có ảnh"><use href="#i-box"/></svg>
                        </c:otherwise>
                    </c:choose>
                </div>
                <div class="mentor-asset-detail-copy">
                    <span class="asset-card-type ${item.borrowable ? 'borrowable' : 'fixed'}"><c:out value="${item.borrowable ? 'Có thể mượn' : 'Tài sản cố định'}"/></span>
                    <h2><c:out value="${item.assetName}"/></h2>
                    <p><c:out value="${item.itemCode}"/> · <c:out value="${item.categoryName}"/></p>
                    <dl>
                        <dt>Mã thiết bị</dt><dd><c:out value="${item.assetCode}"/></dd>
                        <dt>Serial</dt><dd><c:out value="${empty item.serialNumber ? 'Chưa nhập' : item.serialNumber}"/></dd>
                        <dt>Tình trạng</dt><dd><c:out value="${app:label(item.condition)}"/></dd>
                        <dt>Trạng thái</dt><dd><c:out value="${app:label(item.status)}"/></dd>
                        <dt>Ghi chú</dt><dd><c:out value="${empty item.note ? 'Không có' : item.note}"/></dd>
                    </dl>
                    <div class="row-actions"><a class="btn-secondary" href="${assetBasePath}">Quay lại danh sách</a><a class="primary-button" href="${assetBasePath}/${item.assetItemId}/lifecycle">Lịch sử vòng đời</a></div>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
