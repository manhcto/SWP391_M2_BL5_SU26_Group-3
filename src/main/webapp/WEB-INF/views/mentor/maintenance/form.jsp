<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ bảo trì #MNT-${record.maintenanceId}</c:when>
            <c:otherwise>Tạo đề xuất bảo trì mới</c:otherwise>
        </c:choose> | LAB Asset
    </title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
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
                    <h1>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa #MNT-${record.maintenanceId}</c:when>
                            <c:otherwise>Tạo đề xuất bảo trì mới</c:otherwise>
                        </c:choose>
                    </h1>
                    <p>
                        <c:choose>
                            <c:when test="${formMode == 'edit'}">Ghi nhận tiến độ sửa chữa và kết quả nghiệm thu thiết bị</c:when>
                            <c:otherwise>Gửi yêu cầu sửa chữa thiết bị hỏng hóc lên Lab Manager phê duyệt</c:otherwise>
                        </c:choose>
                    </p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <c:choose>
                    <%-- CHẾ ĐỘ CẬP NHẬT TIẾN ĐỘ SỬA CHỮA --%>
                    <c:when test="${formMode == 'edit'}">
                        <div style="padding:16px;border-bottom:1px solid #edf0ec;background:#fafbf9;border-radius:8px 8px 0 0;">
                            <strong>Thông tin phiếu bảo trì gốc:</strong>
                            <p style="margin:6px 0 0;font-size:12px;color:#5a6662;">
                                Thiết bị: <b><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</b>
                                &nbsp;·&nbsp; Trạng thái hiện tại: <b><c:out value="${app:label(record.status)}"/></b>
                                &nbsp;·&nbsp; Mô tả lỗi: <i><c:out value="${record.description}"/></i>
                                &nbsp;·&nbsp; Người yêu cầu: <b><c:out value="${record.requesterName}"/></b>
                                <c:if test="${not empty record.approvalNote}">
                                    &nbsp;·&nbsp; Ghi chú duyệt: <i><c:out value="${record.approvalNote}"/></i>
                                </c:if>
                            </p>
                        </div>

                        <form method="post" action="${pageContext.request.contextPath}/mentor/maintenance/${record.maintenanceId}" class="form-grid">
                            <input type="hidden" name="action" value="updateProgress">
                            <input type="hidden" name="id" value="${record.maintenanceId}">

                            <div class="form-group">
                                <label>Trạng thái tiến độ *</label>
                                <select class="form-control" name="status" required>
                                    <option value="IN_PROGRESS" ${record.status == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa chữa</option>
                                    <option value="COMPLETED" ${record.status == 'COMPLETED' ? 'selected' : ''}>Đã sửa xong – Hoàn tất</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                <input class="form-control" type="text" name="note"
                                       value="<c:out value='${record.note}'/>"
                                       placeholder="Ví dụ: FPT Tech Services / Kỹ thuật viên nội bộ">
                            </div>

                            <div class="form-group full-width">
                                <label>Kết quả sửa chữa / Linh kiện thay thế</label>
                                <textarea class="form-control" name="repairResult" rows="4"
                                          placeholder="Ví dụ: Đã thay extruder và cân chỉnh nhiệt độ. Thiết bị hoạt động hoàn hảo."><c:out value="${record.repairResult}"/></textarea>
                            </div>

                            <div class="form-group full-width" style="display:flex;gap:10px;">
                                <button class="primary-button" type="submit">Lưu cập nhật tiến độ</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance/${record.maintenanceId}">Hủy</a>
                            </div>
                        </form>
                    </c:when>

                    <%-- CHẾ ĐỘ TẠO ĐỀ XUẤT BẢO TRÌ MỚI --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/mentor/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="create">

                            <div class="form-group">
                                <label>Thiết bị cần bảo trì *</label>
                                <select class="form-control" name="assetId" required>
                                    <option value="">-- Chọn thiết bị --</option>
                                    <c:forEach var="a" items="${assets}">
                                        <option value="${a.assetId}">
                                            <c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/>)
                                            <c:if test="${not empty a.storageLocation}"> – <c:out value="${a.storageLocation}"/></c:if>
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Số lượng cần bảo trì *</label>
                                <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                            </div>

                            <div class="form-group full-width">
                                <label>Sự cố liên quan (nếu có)</label>
                                <select class="form-control" name="incidentId">
                                    <option value="">-- Không có sự cố (bảo dưỡng định kỳ) --</option>
                                    <c:forEach var="inc" items="${incidents}">
                                        <option value="${inc.incidentId}">
                                            #INC-<c:out value="${inc.incidentId}"/>
                                            – <c:out value="${inc.assetName}"/>:
                                            <c:out value="${inc.description}"/>
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="form-group full-width">
                                <label>Mô tả chi tiết tình trạng hỏng hóc / Lý do cần bảo trì *</label>
                                <textarea class="form-control" name="description" rows="5" required
                                          placeholder="Mô tả cụ thể: hiện tượng lỗi, bộ phận bị hỏng, nguyên nhân nghi ngờ, yêu cầu sửa chữa cụ thể..."></textarea>
                            </div>

                            <div class="form-group full-width" style="display:flex;gap:10px;">
                                <button class="primary-button" type="submit">
                                    <svg><use href="#i-wrench"/></svg> Gửi đề xuất bảo trì
                                </button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Hủy</a>
                            </div>
                        </form>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
