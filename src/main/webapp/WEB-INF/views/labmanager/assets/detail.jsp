<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết sản phẩm | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>.asset-readonly{display:grid;grid-template-columns:150px 1fr;gap:10px 16px;margin-top:18px;font-size:12px}.asset-readonly dt{color:var(--muted)}.asset-readonly dd{margin:0;font-weight:600;color:var(--ink)}.asset-readonly .form-actions{grid-column:1/-1;margin-top:12px}</style>
</head>
<body class="${assetRole == 'mentor' ? 'mentor-page' : 'lab-manager-page'}">
<c:set var="activeMenu" value="assets" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${assetRole == 'mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf" %></c:when><c:otherwise><%@ include file="../includes/sidebar.jspf" %></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>${editMode ? 'Sửa sản phẩm' : 'Chi tiết sản phẩm'}</h1><p>${editMode ? 'Cập nhật riêng trạng thái và thông tin của từng thiết bị' : 'Xem thông tin riêng của từng sản phẩm'}</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${assetBasePath}">Quay lại danh sách</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">SẢN PHẨM ĐƠN</p><h2><c:out value="${item.itemCode}"/></h2></div></div>
            <c:if test="${param.updated == '1'}"><div class="success-message">Đã cập nhật thông tin sản phẩm.</div></c:if>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <article class="panel">
                <div class="asset-detail">
                    <div class="asset-detail-image"><c:choose><c:when test="${not empty item.imagePath}"><img src="${pageContext.request.contextPath}${item.imagePath}" alt="Ảnh ${item.itemCode}"></c:when><c:otherwise><svg><use href="#i-box"/></svg></c:otherwise></c:choose></div>
                    <div class="asset-info">
                        <h3><c:out value="${item.assetName}"/></h3>
                        <p><c:out value="${item.assetCode}"/> · <c:out value="${item.categoryName}"/></p>
                        <c:choose><c:when test="${editMode}"><form method="post" enctype="multipart/form-data" action="${assetBasePath}/${item.assetItemId}" style="margin-top:16px"><input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                            <div class="form-grid">
                                <div class="form-group"><label for="serialNumber">Serial</label><input class="form-control" id="serialNumber" name="serialNumber" maxlength="100" value="<c:out value='${item.serialNumber}'/>" placeholder="Serial sản phẩm"></div>
                                <div class="form-group"><label for="itemImageFile">Thay ảnh thiết bị</label><input type="hidden" name="imagePath" value="<c:out value='${item.imagePath}'/>"><input class="form-control" id="itemImageFile" name="itemImageFile" type="file" accept="image/jpeg,image/png,image/webp"><small>JPG, PNG hoặc WebP, tối đa 5 MB. Bỏ trống để giữ ảnh hiện tại.</small></div>
                                <div class="form-group"><label for="condition">Tình trạng</label><select class="form-control" id="condition" name="condition"><option value="GOOD" ${item.condition == 'GOOD' ? 'selected' : ''}>Tốt</option><option value="FAIR" ${item.condition == 'FAIR' ? 'selected' : ''}>Khá</option><option value="DAMAGED" ${item.condition == 'DAMAGED' ? 'selected' : ''}>Hư hỏng</option><option value="BROKEN" ${item.condition == 'BROKEN' ? 'selected' : ''}>Hỏng</option></select></div>
                                <div class="form-group"><label>Trạng thái vòng đời</label><input class="form-control" value="${app:label(item.status)}" readonly><small>Trạng thái chỉ thay đổi tại màn mượn/trả, sự cố, bảo trì hoặc thanh lý.</small></div>
                                <div class="form-group full-width"><label for="note">Ghi chú</label><textarea class="form-control" id="note" name="note" maxlength="500" placeholder="Ghi chú riêng cho sản phẩm"><c:out value="${item.note}"/></textarea></div>
                                <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Lưu thay đổi</button><a class="btn-secondary" href="${assetBasePath}">Hủy</a></div>
                            </div>
                        </form></c:when><c:otherwise><dl class="asset-readonly"><dt>Serial</dt><dd><c:out value="${empty item.serialNumber ? 'Chưa nhập' : item.serialNumber}"/></dd><dt>Tình trạng</dt><dd><c:out value="${app:label(item.condition)}"/></dd><dt>Trạng thái</dt><dd><c:out value="${app:label(item.status)}"/></dd><dt>Ghi chú</dt><dd><c:out value="${empty item.note ? 'Không có' : item.note}"/></dd><div class="form-actions"><a class="btn-secondary" href="${assetBasePath}/${item.assetItemId}/lifecycle">Lịch sử vòng đời</a><a class="primary-button" href="${assetBasePath}/${item.assetItemId}/edit">Sửa</a><form method="post" action="${assetBasePath}/${item.assetItemId}/delete" onsubmit="return confirm('Xóa sản phẩm này? Nếu sản phẩm đã có lịch sử sử dụng, hệ thống sẽ từ chối.');"><input type="hidden" name="csrfToken" value="${csrfToken}"><button class="btn-action btn-action-danger" type="submit">Xóa</button></form></div></dl></c:otherwise></c:choose>
                    </div>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
