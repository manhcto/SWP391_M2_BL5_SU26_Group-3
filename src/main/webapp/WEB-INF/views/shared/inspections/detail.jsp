<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>

<!DOCTYPE html>
<html lang="vi">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Chi tiết kiểm tra | LAB Asset</title>

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
                        Kiểm tra #INS-${inspection.inspectionId}
                    </h1>

                    <p>
                        Xem thông tin chung và các thiết bị đã kiểm tra
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
                        <c:out value="${app:label(inspection.status)}"/>
                    </p>

                    <h2>
                        Chi tiết
                        <c:out value="${app:label(inspection.inspectionType)}"/>
                    </h2>

                </div>


                <div class="row-actions">

                    <a class="btn-secondary"
                       href="${pageContext.request.contextPath}${roleBase}/inspections">
                        Quay lại
                    </a>


                    <c:if test="${inspection.status == 'DRAFT'}">

                        <a class="primary-button"
                           href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}/edit">
                            Sửa bản nháp
                        </a>

                    </c:if>

                </div>

            </div>


            <article class="panel detail-panel">

                <div class="detail-grid compact-detail">

                    <div class="detail-item">
                        <dt>ID</dt>
                        <dd>#INS-${inspection.inspectionId}</dd>
                    </div>


                    <div class="detail-item">
                        <dt>Loại</dt>
                        <dd>
                            <c:out value="${app:label(inspection.inspectionType)}"/>
                        </dd>
                    </div>


                    <div class="detail-item">
                        <dt>Học kỳ</dt>
                        <dd>
                            <c:out value="${inspection.semesterCode}"/>
                            -
                            <c:out value="${inspection.semesterName}"/>
                        </dd>
                    </div>


                    <div class="detail-item">
                        <dt>Phạm vi</dt>
                        <dd>
                            <c:out value="${app:label(inspection.scope)}"/>
                        </dd>
                    </div>


                    <div class="detail-item">
                        <dt>Người kiểm tra</dt>
                        <dd>
                            <c:out value="${inspection.inspectorName}"/>
                        </dd>
                    </div>


                    <div class="detail-item">
                        <dt>Thời gian kiểm tra</dt>
                        <dd>
                            <c:out value="${app:dateTime(inspection.inspectionDate)}"/>
                        </dd>
                    </div>


                    <div class="detail-item">

                        <dt>Trạng thái</dt>

                        <dd>

                            <span class="status ${inspection.status == 'COMPLETED'
                                ? 'returned'
                                : 'review'}">

                                <c:out value="${app:label(inspection.status)}"/>

                            </span>

                        </dd>

                    </div>


                    <div class="detail-item">

                        <dt>Kết quả</dt>

                        <dd>

                            <c:choose>

                                <c:when test="${empty inspection.result}">
                                    -
                                </c:when>

                                <c:otherwise>

                                    <span class="status ${inspection.result == 'NORMAL'
                                        ? 'returned'
                                        : 'open'}">

                                        <c:out value="${app:label(inspection.result)}"/>

                                    </span>

                                </c:otherwise>

                            </c:choose>

                        </dd>

                    </div>


                    <div class="detail-item wide">

                        <dt>Ghi chú</dt>

                        <dd>
                            <c:out value="${inspection.note}" default="-"/>
                        </dd>

                    </div>

                </div>

            </article>


            <h3 class="section-title">
                Thiết bị kiểm tra
            </h3>


            <article class="panel">

                <div class="table-scroll inspection-table-scroll">

                    <table class="inspection-table inspection-detail-table">

                        <thead>

                        <tr>
                            <th>Thiết bị / Sản phẩm</th>
                            <th>Số lượng dự kiến</th>
                            <th>Số lượng thực tế</th>
                            <th>Tình trạng dự kiến</th>
                            <th>Tình trạng thực tế</th>
                            <th>Loại chênh lệch</th>
                            <th>Ghi chú chênh lệch</th>
                            <th>Sự cố</th>
                        </tr>

                        </thead>


                        <tbody>

                        <c:forEach var="item" items="${items}">

                            <c:set var="serialized"
                                   value="${not empty item.assetItemId}"/>

                            <tr>

                                <td class="asset-cell">

                                    <strong>

                                        <c:choose>

                                            <%-- Asset managed individually --%>
                                            <c:when test="${serialized && not empty item.itemCode}">
                                                <c:out value="${item.itemCode}"/>
                                            </c:when>

                                            <%-- Quantity-based asset --%>
                                            <c:otherwise>
                                                <c:out value="${item.assetCode}"/>
                                            </c:otherwise>

                                        </c:choose>

                                    </strong>


                                    <small>

                                        <c:out value="${item.assetName}"/>


                                        <c:choose>

                                            <c:when test="${serialized}">

                                                · Quản lý riêng lẻ

                                                <c:if test="${not empty item.assetCode}">
                                                    · Nhóm:
                                                    <c:out value="${item.assetCode}"/>
                                                </c:if>

                                                <c:if test="${not empty item.serialNumber}">
                                                    · Serial:
                                                    <c:out value="${item.serialNumber}"/>
                                                </c:if>

                                                <c:if test="${not empty item.assetItemStatus}">
                                                    ·
                                                    <c:out value="${app:label(item.assetItemStatus)}"/>
                                                </c:if>

                                            </c:when>


                                            <c:otherwise>
                                                · Theo số lượng
                                            </c:otherwise>

                                        </c:choose>

                                    </small>

                                </td>


                                <td>
                                    <c:out value="${item.expectedQuantity}"/>
                                </td>


                                <td>
                                    <c:out value="${item.actualQuantity}"/>
                                </td>


                                <td>
                                    <c:out value="${app:label(item.expectedCondition)}"/>
                                </td>


                                <td>
                                    <c:out value="${app:label(item.actualCondition)}"/>
                                </td>


                                <td>
                                    <c:out value="${item.discrepancyType}" default="-"/>
                                </td>


                                <td class="wrap-cell">
                                    <c:out value="${item.discrepancyNote}" default="-"/>
                                </td>


                                <td>

                                    <c:if test="${not empty item.assetItemId}">

                                        <a class="btn-action"
                                           href="${pageContext.request.contextPath}${roleBase}/assets/${item.assetItemId}/lifecycle">
                                            Xem vòng đời
                                        </a>

                                    </c:if>

                                    <c:if test="${inspection.status == 'COMPLETED' && item.abnormal}">

                                        <a class="btn-action"
                                           href="#">
                                            Báo cáo sự cố
                                        </a>

                                    </c:if>

                                </td>

                            </tr>

                        </c:forEach>

                        </tbody>

                    </table>

                </div>

            </article>

        </section>

    </main>

</div>

</body>

</html>
