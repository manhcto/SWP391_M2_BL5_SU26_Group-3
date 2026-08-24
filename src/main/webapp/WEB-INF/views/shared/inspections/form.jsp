<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Biểu mẫu kiểm tra | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="inspection-page${roleBase == '/mentor' ? ' mentor-page' : ' lab-manager-page'}">
<c:set var="activeMenu" value="inspections" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when><c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>${empty inspection.inspectionId ? 'Tạo đợt kiểm tra' : 'Sửa bản nháp kiểm tra'}</h1><p>Kiểm tra toàn bộ phòng LAB hoặc các thiết bị chưa thanh lý được chọn</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">${roleBase == '/mentor' ? 'ME' : 'LM'}</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">QUY TRÌNH BẢN NHÁP</p><h2>${empty inspection.inspectionId ? 'Hồ sơ kiểm tra mới' : 'Cập nhật hồ sơ kiểm tra'}</h2></div><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Hủy</a></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
			<form class="inspection-form" method="post" action="${pageContext.request.contextPath}${roleBase}/inspections">
				<input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <input type="hidden" name="inspectionId" value="<c:out value='${inspection.inspectionId}'/>">
                <article class="panel inspection-form-panel">
                    <div class="form-grid">
                        <div class="form-group"><label for="semesterId">Học kỳ</label><select class="form-control" id="semesterId" name="semesterId" required><option value="">Chọn học kỳ</option><c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${inspection.semesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> - <c:out value="${semester.name}"/></option></c:forEach></select></div>
                        <div class="form-group"><label for="inspectionType">Loại kiểm tra</label><select class="form-control" id="inspectionType" name="inspectionType" required><option value="INSPECTION" ${inspection.inspectionType == 'INSPECTION' ? 'selected' : ''}>Kiểm tra</option><option value="INVENTORY" ${inspection.inspectionType == 'INVENTORY' ? 'selected' : ''}>Kiểm kê</option></select></div>
                        <div class="form-group"><label for="scope">Phạm vi</label><select class="form-control" id="scope" name="scope" required><option value="WHOLE_LAB" ${inspection.scope == 'WHOLE_LAB' || empty inspection.scope ? 'selected' : ''}>Toàn bộ phòng LAB</option><option value="SELECTED_ASSETS" ${inspection.scope == 'SELECTED_ASSETS' ? 'selected' : ''}>Thiết bị được chọn</option></select></div>
                        <div class="form-group"><label for="inspectionDate">Thời gian kiểm tra</label><input class="form-control" id="inspectionDate" type="datetime-local" name="inspectionDate" value="${app:dateTimeInput(inspection.inspectionDate)}" required></div>
                        <div class="form-group full-width"><label for="note">Ghi chú</label><textarea class="form-control" id="note" name="note" placeholder="Ghi chú kiểm tra tùy chọn"><c:out value="${inspection.note}"/></textarea></div>
                    </div>
                </article>
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-inspect"/></svg></span><h3>Sản phẩm kiểm tra</h3></div><span class="hint">Mỗi dòng là một AssetItem có mã riêng; hãy chọn ít nhất một sản phẩm.</span></header>
                    <div class="table-scroll inspection-form-scroll"><table class="inspection-table inspection-item-table"><thead><tr><th>Chọn</th><th>Sản phẩm</th><th>Serial</th><th>Dự kiến có mặt</th><th>Thực tế có mặt</th><th>Tình trạng dự kiến</th><th>Tình trạng thực tế</th><th>Loại chênh lệch</th><th>Ghi chú chênh lệch</th></tr></thead><tbody>
                        <c:forEach var="assetItem" items="${assetItems}">
                            <c:set var="item" value="${inspectionByAssetItem[assetItem.assetItemId]}"/>
                            <c:set var="checked" value="${inspection.scope == 'WHOLE_LAB' || not empty item}"/>
                            <tr>
                                <td><input class="asset-check" type="checkbox" name="selectedAssetItemId" value="${assetItem.assetItemId}" ${checked ? 'checked' : ''}><input type="hidden" name="assetItemId" value="${assetItem.assetItemId}"><input type="hidden" name="assetId_${assetItem.assetItemId}" value="${assetItem.assetId}"></td>
                                <td class="asset-cell"><strong><c:out value="${assetItem.itemCode}"/></strong><small><c:out value="${assetItem.assetName}"/> · <c:out value="${app:label(assetItem.status)}"/></small></td>
                                <td><c:out value="${empty assetItem.serialNumber ? 'Chưa nhập' : assetItem.serialNumber}"/></td>
                                <td><input class="form-control compact-input" type="number" min="0" max="1" name="expectedQuantity_${assetItem.assetItemId}" value="${empty item ? 1 : item.expectedQuantity}"></td>
                                <td><input class="form-control compact-input" type="number" min="0" max="1" name="actualQuantity_${assetItem.assetItemId}" value="${empty item ? 1 : item.actualQuantity}"></td>
                                <td><select class="form-control" name="expectedCondition_${assetItem.assetItemId}"><option value="">-</option><option value="GOOD" ${(empty item && assetItem.condition == 'GOOD') || item.expectedCondition == 'GOOD' ? 'selected' : ''}>Tốt</option><option value="FAIR" ${(empty item && assetItem.condition == 'FAIR') || item.expectedCondition == 'FAIR' ? 'selected' : ''}>Khá</option><option value="DAMAGED" ${(empty item && assetItem.condition == 'DAMAGED') || item.expectedCondition == 'DAMAGED' ? 'selected' : ''}>Hư hỏng</option><option value="BROKEN" ${(empty item && assetItem.condition == 'BROKEN') || item.expectedCondition == 'BROKEN' ? 'selected' : ''}>Không hoạt động</option></select></td>
                                <td><select class="form-control" name="actualCondition_${assetItem.assetItemId}"><option value="">-</option><option value="GOOD" ${(empty item && assetItem.condition == 'GOOD') || item.actualCondition == 'GOOD' ? 'selected' : ''}>Tốt</option><option value="FAIR" ${(empty item && assetItem.condition == 'FAIR') || item.actualCondition == 'FAIR' ? 'selected' : ''}>Khá</option><option value="DAMAGED" ${(empty item && assetItem.condition == 'DAMAGED') || item.actualCondition == 'DAMAGED' ? 'selected' : ''}>Hư hỏng</option><option value="BROKEN" ${(empty item && assetItem.condition == 'BROKEN') || item.actualCondition == 'BROKEN' ? 'selected' : ''}>Không hoạt động</option></select></td>
                                <td><input class="form-control" name="discrepancyType_${assetItem.assetItemId}" value="<c:out value='${item.discrepancyType}'/>" placeholder="Thiếu, hư hỏng..."></td>
                                <td><input class="form-control" name="discrepancyNote_${assetItem.assetItemId}" value="<c:out value='${item.discrepancyNote}'/>" placeholder="Ghi chú tùy chọn"></td>
                            </tr>
                        </c:forEach>
                    </tbody></table></div>
                    <div class="table-footer"><span>Không hiển thị sản phẩm đã thanh lý.</span><div class="actions"><button class="btn-secondary" type="submit" name="action" value="draft">Lưu bản nháp</button><button class="primary-button" type="submit" name="action" value="complete">Hoàn tất kiểm tra</button><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Hủy</a></div></div>
                </article>
            </form>
        </section>
    </main>
</div>
</body>
</html>
