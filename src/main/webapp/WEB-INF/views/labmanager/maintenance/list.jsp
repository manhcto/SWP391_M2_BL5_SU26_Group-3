<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Quản lý bảo trì thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Phê duyệt &amp; Giám sát bảo trì</h1>
                    <p>Duyệt yêu cầu bảo trì, giám sát tiến độ sửa chữa và nghiệm thu kết quả</p>
                </div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">LM</div>
                    <span><c:out value="${currentUser.fullName}"/></span>
                </div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div>
                    <p class="eyebrow">FE-08 BẢO TRÌ</p>
                    <h2>Quản lý bảo trì thiết bị (${records.size()})</h2>
                </div>
                <a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/maintenance/new">
                    <svg><use href="#i-wrench"/></svg>+ Tạo phiếu bảo trì
                </a>
            </div>

            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>
            <c:if test="${param.success == 'saved'}">
                <div class="success-message">Đã lưu thông tin phiếu bảo trì thành công.</div>
            </c:if>
            <c:if test="${param.success == 'deleted'}">
                <div class="success-message">Đã xóa phiếu bảo trì thành công. Thiết bị đã được hoàn trả về trạng thái Sẵn sàng (AVAILABLE).</div>
            </c:if>

            <%-- THỐNG KÊ TÀI CHÍNH BẢO TRÌ --%>
            <c:if test="${not empty summary}">
            <div style="display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:20px;">
                <div style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                    <div style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">🔧 Tổng phiếu</div>
                    <div style="font-size:28px; font-weight:700; color:#1e293b; margin-top:4px;">${summary.totalRecords()}</div>
                </div>
                <div style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                    <div style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">⏳ Đang sửa chữa</div>
                    <div style="font-size:28px; font-weight:700; color:#f59e0b; margin-top:4px;">${summary.inProgressCount()}</div>
                </div>
                <div style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                    <div style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">✅ Đã hoàn thành</div>
                    <div style="font-size:28px; font-weight:700; color:#10b981; margin-top:4px;">${summary.completedCount()}</div>
                </div>
                <div style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                    <div style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">💰 Tổng chi phí thực tế đã chi trả</div>
                    <div style="font-size:28px; font-weight:700; color:#2563eb; margin-top:4px;">
                        <fmt:formatNumber value="${summary.totalActualCost()}" type="number" groupingUsed="true"/> <span style="font-size:14px; font-weight:500;">VNĐ</span>
                    </div>
                </div>
            </div>
            </c:if>

            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/lab-manager/maintenance">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword"
                           value="<c:out value='${keyword}'/>"
                           placeholder="Tìm theo mã phiếu, tên thiết bị, thợ sửa..." style="width:300px">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái</option>
                        <option value="IN_PROGRESS"  ${selectedStatus == 'IN_PROGRESS'  ? 'selected' : ''}>Đang sửa chữa</option>
                        <option value="COMPLETED"    ${selectedStatus == 'COMPLETED'    ? 'selected' : ''}>Hoàn tất</option>
                    </select>
                    <button class="primary-button" type="submit">Tìm kiếm</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Đặt lại</a>
                </div>
            </form>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-wrench"/></svg></div>
                            <h3>Chưa có phiếu bảo trì nào</h3>
                            <p>Bấm vào nút bên dưới để tạo phiếu bảo trì và đưa thiết bị đi sửa chữa.</p>
                            <a class="primary-button" href="${pageContext.request.contextPath}/lab-manager/maintenance/new">+ Tạo phiếu bảo trì</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Mã phiếu</th>
                                    <th>Thiết bị</th>
                                    <th>SL</th>
                                    <th>Mô tả yêu cầu sửa chữa</th>
                                    <th>Kinh phí</th>
                                    <th>Ngày tạo</th>
                                    <th>Trạng thái</th>
                                    <th>Thao tác</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="r" items="${records}">
                                    <tr>
                                        <td><strong>#MNT-<c:out value="${r.maintenanceId}"/></strong></td>
                                        <td>
                                            <c:out value="${r.assetName}"/>
                                            <small style="display:block;color:#5a6662"><c:out value="${not empty r.assetItemCode ? r.assetItemCode : r.assetCode}"/></small>
                                        </td>
                                        <td><c:out value="${r.quantity}"/></td>
                                        <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                                            <c:out value="${r.description}"/>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty r.actualCost}">
                                                    <strong style="color:#2563eb;"><fmt:formatNumber value="${r.actualCost}" type="number" groupingUsed="true"/> VNĐ</strong>
                                                </c:when>
                                                <c:when test="${not empty r.estimatedCost}">
                                                    <small style="color:#6b7280;">Dự toán:<br><strong><fmt:formatNumber value="${r.estimatedCost}" type="number" groupingUsed="true"/> VNĐ</strong></small>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="color:#9ca3af;">—</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><c:out value="${app:dateTime(r.requestedAt)}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${r.status == 'IN_PROGRESS'}">
                                                    <span class="status maintenance">Đang sửa chữa</span>
                                                </c:when>
                                                <c:when test="${r.status == 'COMPLETED'}">
                                                     <c:choose>
                                                         <c:when test="${r.assetStatus == 'UNAVAILABLE'}">
                                                             <span class="status overdue">Sửa thất bại</span>
                                                         </c:when>
                                                         <c:otherwise>
                                                             <span class="status returned">Đã sửa xong</span>
                                                         </c:otherwise>
                                                     </c:choose>
                                                 </c:when>
                                                <c:otherwise>
                                                    <span class="status"><c:out value="${r.status}"/></span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td style="white-space:nowrap;">
                                            <a class="btn-secondary" style="height:24px;padding:0 8px;font-size:11px"
                                               href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}">Xem</a>
                                            <c:if test="${r.status == 'IN_PROGRESS'}">
                                                <a class="btn-secondary" style="height:24px;padding:0 8px;font-size:11px;background:#e8f0fe;color:#1a73e8;border-color:#aecbfa;font-weight:600;"
                                                   href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}/edit">
                                                    ✏️ Tiến độ
                                                </a>
                                                <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance"
                                                      onsubmit="return confirm('Bạn có chắc chắn muốn xóa phiếu bảo trì #MNT-${r.maintenanceId}? Thiết bị sẽ được trả về trạng thái Sẵn sàng.');"
                                                      style="display:inline;margin:0;">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="id" value="${r.maintenanceId}">
                                                    <button class="btn-secondary" type="submit"
                                                            style="height:24px;padding:0 8px;font-size:11px;background:#fde8e8;color:#c62828;border-color:#f8b4b4;font-weight:600;cursor:pointer;">
                                                        Xóa
                                                    </button>
                                                </form>
                                            </c:if>
                                            <c:if test="${r.status == 'COMPLETED'}">
                                                <a class="btn-secondary" style="height:24px;padding:0 8px;font-size:11px;background:#f3f4f6;color:#374151;border-color:#d1d5db;font-weight:500;"
                                                   href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}/edit">
                                                    ✏️ Sửa
                                                </a>
                                            </c:if>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
