<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Biểu mẫu kiểm tra | LAB Asset</title>

    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>

<body class="inspection-page${roleBase == '/mentor' ? ' mentor-page' : ' lab-manager-page'}">

<c:set var="activeMenu" value="inspections" scope="request"/>

<div class="app-shell">

    <c:choose>
        <c:when test="${roleBase == '/mentor'}">
            <%@ include file="../../mentor/includes/sidebar.jspf"%>
        </c:when>

        <c:otherwise>
            <%@ include file="../../labmanager/includes/sidebar.jspf"%>
        </c:otherwise>
    </c:choose>

    <main class="main-content">

        <header class="topbar">
            <div class="heading-wrap">

                <button class="menu-button"
                        id="menuButton"
                        type="button"
                        aria-label="Mở thanh điều hướng">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>

                <div>
                    <h1>
                        ${empty inspection.inspectionId
                                ? 'Tạo đợt kiểm tra'
                                : 'Sửa bản nháp kiểm tra'}
                    </h1>

                    <p>
                        Kiểm tra toàn bộ phòng LAB hoặc các thiết bị chưa thanh lý được chọn
                    </p>
                </div>
            </div>

            <div class="topbar-actions">
                <div class="top-profile">

                    <div class="avatar">
                        ${roleBase == '/mentor' ? 'ME' : 'LM'}
                    </div>

                    <span>
                        <c:out value="${currentUser.fullName}"/>
                    </span>
                </div>
            </div>
        </header>

        <section class="content-area">

            <div class="content-heading">

                <div>
                    <p class="eyebrow">
                        QUY TRÌNH BẢN NHÁP
                    </p>

                    <h2>
                        ${empty inspection.inspectionId
                                ? 'Hồ sơ kiểm tra mới'
                                : 'Cập nhật hồ sơ kiểm tra'}
                    </h2>
                </div>

                <a class="btn-secondary"
                   href="${pageContext.request.contextPath}${roleBase}/inspections">
                    Hủy
                </a>
            </div>

            <c:if test="${not empty message}">
                <div class="error-message">
                    <c:out value="${message}"/>
                </div>
            </c:if>

            <form class="inspection-form"
                  method="post"
                  action="${pageContext.request.contextPath}${roleBase}/inspections">

                <%-- CSRF token supplied by InspectionControllerSupport.forward() --%>
                <input type="hidden"
                       name="csrfToken"
                       value="${csrfToken}">

                <input type="hidden"
                       name="inspectionId"
                       value="<c:out value='${inspection.inspectionId}'/>">

                <article class="panel inspection-form-panel">

                    <div class="form-grid">

                        <div class="form-group">

                            <label for="semesterId">
                                Học kỳ
                            </label>

                            <select class="form-control"
                                    id="semesterId"
                                    name="semesterId"
                                    required>

                                <option value="">
                                    Chọn học kỳ
                                </option>

                                <c:forEach var="semester"
                                           items="${semesters}">

                                    <option value="${semester.semesterId}"
                                        ${inspection.semesterId == semester.semesterId
                                                ? 'selected'
                                                : ''}>

                                        <c:out value="${semester.code}"/>
                                        -
                                        <c:out value="${semester.name}"/>

                                    </option>
                                </c:forEach>

                            </select>
                        </div>

                        <div class="form-group">

                            <label for="inspectionType">
                                Loại kiểm tra
                            </label>

                            <select class="form-control"
                                    id="inspectionType"
                                    name="inspectionType"
                                    required>

                                <option value="INSPECTION"
                                ${inspection.inspectionType == 'INSPECTION'
                                        ? 'selected'
                                        : ''}>
                                    Kiểm tra
                                </option>

                                <option value="INVENTORY"
                                ${inspection.inspectionType == 'INVENTORY'
                                        ? 'selected'
                                        : ''}>
                                    Kiểm kê
                                </option>

                            </select>
                        </div>

                        <div class="form-group">

                            <label for="scope">
                                Phạm vi
                            </label>

                            <select class="form-control"
                                    id="scope"
                                    name="scope"
                                    required>

                                <option value="WHOLE_LAB"
                                ${inspection.scope == 'WHOLE_LAB'
                                        || empty inspection.scope
                                        ? 'selected'
                                        : ''}>
                                    Toàn bộ phòng LAB
                                </option>

                                <option value="SELECTED_ASSETS"
                                ${inspection.scope == 'SELECTED_ASSETS'
                                        ? 'selected'
                                        : ''}>
                                    Thiết bị được chọn
                                </option>

                            </select>

                            <small id="scopeHelp">
                                Tất cả thiết bị chưa thanh lý sẽ được đưa vào đợt kiểm tra.
                            </small>
                        </div>

                        <div class="form-group">

                            <label for="inspectionDate">
                                Thời gian kiểm tra
                            </label>

                            <input class="form-control"
                                   id="inspectionDate"
                                   type="datetime-local"
                                   name="inspectionDate"
                                   value="${app:dateTimeInput(inspection.inspectionDate)}"
                                   required>
                        </div>

                        <div class="form-group full-width">

                            <label for="note">
                                Ghi chú
                            </label>

                            <textarea class="form-control"
                                      id="note"
                                      name="note"
                                      placeholder="Ghi chú kiểm tra tùy chọn"><c:out value="${inspection.note}"/></textarea>
                        </div>

                    </div>
                </article>


                <article class="panel">

                    <header class="panel-header">

                        <div class="panel-title">

                            <span class="title-icon">
                                <svg>
                                    <use href="#i-inspect"/>
                                </svg>
                            </span>

                            <h3>
                                Thiết bị kiểm tra
                            </h3>
                        </div>

                        <span class="hint"
                              id="assetSelectionHint">
                            Tất cả thiết bị chưa thanh lý sẽ được đưa vào đợt kiểm tra.
                        </span>

                    </header>


                    <div class="table-scroll inspection-form-scroll">

                        <table class="inspection-table inspection-item-table">

                            <thead>
                            <tr>
                                <th>Chọn</th>
                                <th>Thiết bị / Sản phẩm</th>
                                <th>Số lượng dự kiến</th>
                                <th>Số lượng thực tế</th>
                                <th>Tình trạng dự kiến</th>
                                <th>Tình trạng thực tế</th>
                                <th>Loại chênh lệch</th>
                                <th>Ghi chú chênh lệch</th>
                            </tr>
                            </thead>

                            <tbody>

                            <c:forEach var="asset"
                                       items="${assets}">

                                <%--
                                    rowKey:
                                    QUANTITY    -> assetId
                                    SERIALIZED  -> item_<assetItemId>
                                --%>
                                <c:set var="rowKey"
                                       value="${asset.rowKey}"/>

                                <c:set var="item"
                                       value="${itemByTarget[rowKey]}"/>

                                <c:set var="checked"
                                       value="${inspection.scope == 'WHOLE_LAB'
                                           || not empty item}"/>

                                <c:set var="serialized"
                                       value="${not empty asset.assetItemId}"/>


                                <tr data-tracking-mode="${asset.trackingMode}">

                                    <td>

                                        <input class="asset-check"
                                               type="checkbox"
                                               name="selectedAssetId"
                                               value="${asset.assetId}"
                                            ${checked ? 'checked' : ''}>

                                        <input type="hidden"
                                               name="targetKey"
                                               value="${rowKey}">

                                        <input type="hidden"
                                               name="assetId_${rowKey}"
                                               value="${asset.assetId}">

                                        <input type="hidden"
                                               name="assetItemId_${rowKey}"
                                               value="${asset.assetItemId}">

                                    </td>


                                    <td class="asset-cell">

                                        <strong>
                                            <c:choose>

                                                <c:when test="${serialized && not empty asset.itemCode}">
                                                    <c:out value="${asset.itemCode}"/>
                                                </c:when>

                                                <c:otherwise>
                                                    <c:out value="${asset.assetCode}"/>
                                                </c:otherwise>

                                            </c:choose>
                                        </strong>

                                        <small>

                                            <c:out value="${asset.assetName}"/>

                                            ·

                                            <c:out value="${serialized
                                                ? 'Quản lý riêng lẻ'
                                                : 'Theo số lượng'}"/>


                                            <c:if test="${serialized && not empty asset.assetCode}">
                                                · Nhóm:
                                                <c:out value="${asset.assetCode}"/>
                                            </c:if>


                                            <c:if test="${serialized && not empty asset.serialNumber}">
                                                · Serial:
                                                <c:out value="${asset.serialNumber}"/>
                                            </c:if>


                                            <c:if test="${serialized && not empty asset.assetItemStatus}">
                                                ·
                                                <c:out value="${app:label(asset.assetItemStatus)}"/>
                                            </c:if>

                                        </small>

                                    </td>


                                    <td>

                                        <input class="form-control compact-input"
                                               type="number"
                                               min="${serialized ? 1 : 0}"
                                               max="${serialized ? 1 : ''}"
                                               name="expectedQuantity_${rowKey}"
                                               value="${serialized
                                                   ? 1
                                                   : (empty item
                                                       ? asset.expectedQuantity
                                                       : item.expectedQuantity)}"
                                            ${serialized ? 'readonly' : ''}>

                                    </td>


                                    <td>

                                        <input class="form-control compact-input"
                                               type="number"
                                               min="0"
                                               max="${serialized ? 1 : ''}"
                                               name="actualQuantity_${rowKey}"
                                               value="${serialized
                                                   ? (empty item
                                                       ? 1
                                                       : item.actualQuantity)
                                                   : (empty item
                                                       ? asset.actualQuantity
                                                       : item.actualQuantity)}">

                                    </td>


                                    <td>

                                        <select class="form-control"
                                                name="expectedCondition_${rowKey}">

                                            <option value="">
                                                -
                                            </option>

                                            <option value="GOOD"
                                                ${(empty item
                                                        && asset.expectedCondition == 'GOOD')
                                                        || item.expectedCondition == 'GOOD'
                                                        ? 'selected'
                                                        : ''}>
                                                Tốt
                                            </option>

                                            <option value="FAIR"
                                                ${(empty item
                                                        && asset.expectedCondition == 'FAIR')
                                                        || item.expectedCondition == 'FAIR'
                                                        ? 'selected'
                                                        : ''}>
                                                Khá
                                            </option>

                                            <option value="DAMAGED"
                                                ${(empty item
                                                        && asset.expectedCondition == 'DAMAGED')
                                                        || item.expectedCondition == 'DAMAGED'
                                                        ? 'selected'
                                                        : ''}>
                                                Hư hỏng
                                            </option>

                                            <option value="BROKEN"
                                                ${(empty item
                                                        && asset.expectedCondition == 'BROKEN')
                                                        || item.expectedCondition == 'BROKEN'
                                                        ? 'selected'
                                                        : ''}>
                                                Không hoạt động
                                            </option>

                                        </select>

                                    </td>


                                    <td>

                                        <select class="form-control"
                                                name="actualCondition_${rowKey}">

                                            <option value="">
                                                -
                                            </option>

                                            <option value="GOOD"
                                                ${(empty item
                                                        && asset.actualCondition == 'GOOD')
                                                        || item.actualCondition == 'GOOD'
                                                        ? 'selected'
                                                        : ''}>
                                                Tốt
                                            </option>

                                            <option value="FAIR"
                                                ${(empty item
                                                        && asset.actualCondition == 'FAIR')
                                                        || item.actualCondition == 'FAIR'
                                                        ? 'selected'
                                                        : ''}>
                                                Khá
                                            </option>

                                            <option value="DAMAGED"
                                                ${(empty item
                                                        && asset.actualCondition == 'DAMAGED')
                                                        || item.actualCondition == 'DAMAGED'
                                                        ? 'selected'
                                                        : ''}>
                                                Hư hỏng
                                            </option>

                                            <option value="BROKEN"
                                                ${(empty item
                                                        && asset.actualCondition == 'BROKEN')
                                                        || item.actualCondition == 'BROKEN'
                                                        ? 'selected'
                                                        : ''}>
                                                Không hoạt động
                                            </option>

                                        </select>

                                    </td>


                                    <td>

                                        <input class="form-control"
                                               name="discrepancyType_${rowKey}"
                                               value="<c:out value='${item.discrepancyType}'/>"
                                               placeholder="Thiếu, hư hỏng...">

                                    </td>


                                    <td>

                                        <input class="form-control"
                                               name="discrepancyNote_${rowKey}"
                                               value="<c:out value='${item.discrepancyNote}'/>"
                                               placeholder="Ghi chú tùy chọn">

                                    </td>

                                </tr>

                            </c:forEach>

                            </tbody>

                        </table>

                    </div>


                    <div class="table-footer">

                        <span>
                            Không hiển thị thiết bị hoặc sản phẩm đã thanh lý.
                        </span>

                        <div class="actions">

                            <button class="btn-secondary"
                                    type="submit"
                                    name="action"
                                    value="draft">
                                Lưu bản nháp
                            </button>

                            <button class="primary-button"
                                    type="submit"
                                    name="action"
                                    value="complete">
                                Hoàn tất kiểm tra
                            </button>

                            <a class="btn-secondary"
                               href="${pageContext.request.contextPath}${roleBase}/inspections">
                                Hủy
                            </a>

                        </div>

                    </div>

                </article>

            </form>

        </section>

    </main>

</div>


<script>
    document.addEventListener('DOMContentLoaded', () => {

        const scope =
            document.getElementById('scope');

        const hint =
            document.getElementById('assetSelectionHint');

        const help =
            document.getElementById('scopeHelp');

        const checks =
            Array.from(
                document.querySelectorAll('.asset-check')
            );

        const wholeText =
            'Tất cả thiết bị chưa thanh lý sẽ được đưa vào đợt kiểm tra.';

        const selectedText =
            'Chọn ít nhất một thiết bị. Thiết bị quản lý riêng lẻ sẽ được kiểm tra theo từng serial.';


        const syncScope = () => {

            const wholeLab =
                scope.value === 'WHOLE_LAB';

            checks.forEach(check => {

                check.disabled = wholeLab;

                if (wholeLab) {
                    check.checked = true;
                }

            });

            if (hint) {
                hint.textContent =
                    wholeLab
                        ? wholeText
                        : selectedText;
            }

            if (help) {
                help.textContent =
                    wholeLab
                        ? wholeText
                        : selectedText;
            }

            document.body.classList.toggle(
                'whole-lab-scope',
                wholeLab
            );
        };


        scope.addEventListener(
            'change',
            syncScope
        );

        syncScope();
    });
</script>

</body>
</html>