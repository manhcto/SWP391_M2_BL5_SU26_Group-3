<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:choose><c:when test="${formMode == 'edit'}">Update Maintenance Ticket</c:when><c:otherwise>Create Maintenance Ticket</c:otherwise></c:choose> | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1><c:choose><c:when test="${formMode == 'edit'}">Update Ticket #MNT-${record.maintenanceId}</c:when><c:otherwise>Create Maintenance Ticket</c:otherwise></c:choose></h1><p>Authorize maintenance, dispatch technicians, log results</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance">‹ Back to List</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <c:choose>
                    <c:when test="${formMode == 'edit'}">
                        <div style="padding: 16px; border-bottom: 1px solid #edf0ec; background:#fafbf9; border-radius: 8px 8px 0 0;">
                            <strong>Chi tiết yêu cầu ban đầu:</strong>
                            <p style="margin: 6px 0 0; font-size: 12px; color:#5a6662;">
                                Thiết bị: <b><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</b> · Mô tả lỗi: <i><c:out value="${record.description}"/></i> · Người yêu cầu: <b><c:out value="${record.requesterName}"/></b>
                            </p>
                        </div>

                        <c:if test="${record.status == 'PENDING'}">
                            <form method="post" action="${pageContext.request.contextPath}/labmanager/maintenance/approve" class="form-grid" style="border-bottom: 2px dashed #edf0ec; padding-bottom: 20px;">
                                <input type="hidden" name="id" value="${record.maintenanceId}">
                                <div class="form-group full-width">
                                    <h3 style="margin:0 0 8px; font-size:13.5px; color:#137a4d;">1. Phê duyệt hoặc Từ chối yêu cầu bảo trì:</h3>
                                </div>
                                <div class="form-group">
                                    <label>Quyết định duyệt *</label>
                                    <select class="form-control" name="decision">
                                        <option value="APPROVED">APPROVED (Duyệt mang đi sửa chữa)</option>
                                        <option value="REJECTED">REJECTED (Từ chối yêu cầu)</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>Ghi chú phê duyệt / Kinh phí dự kiến</label>
                                    <input class="form-control" type="text" name="approvalNote" placeholder="e.g. Duyệt chi phí 650.000 VNĐ mang sang FPT Tech Service">
                                </div>
                                <div class="form-group full-width">
                                    <button class="primary-button" type="submit">Submit Approval Decision</button>
                                </div>
                            </form>
                        </c:if>

                        <form method="post" action="${pageContext.request.contextPath}/labmanager/maintenance/edit" class="form-grid">
                            <input type="hidden" name="id" value="${record.maintenanceId}">
                            <div class="form-group full-width">
                                <h3 style="margin:0 0 8px; font-size:13.5px; color:#2869b5;">2. Cập nhật tiến độ kỹ thuật & Kết quả sửa chữa:</h3>
                            </div>
                            <div class="form-group">
                                <label>Trạng thái tiến độ *</label>
                                <select class="form-control" name="status">
                                    <option value="APPROVED" ${record.status == 'APPROVED' ? 'selected' : ''}>APPROVED (Đã duyệt - Chờ xử lý)</option>
                                    <option value="IN_PROGRESS" ${record.status == 'IN_PROGRESS' ? 'selected' : ''}>IN_PROGRESS (Đang trong quá trình sửa chữa)</option>
                                    <option value="COMPLETED" ${record.status == 'COMPLETED' ? 'selected' : ''}>COMPLETED (Đã sửa xong - Nghiệm thu hoàn trả kho)</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                <input class="form-control" type="text" name="note" value="<c:out value='${record.note}'/>" placeholder="e.g. Kỹ thuật viên Tektronix VN / FPT Services">
                            </div>
                            <div class="form-group full-width">
                                <label>Kết quả sửa chữa / Linh kiện thay thế</label>
                                <textarea class="form-control" name="repairResult" placeholder="e.g. Đã thay thế vòi phun extruder và cân chỉnh nhiệt độ bàn in. Thiết bị hoạt động hoàn hảo."><c:out value="${record.repairResult}"/></textarea>
                            </div>
                            <div class="form-group full-width" style="display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Save Maintenance Progress</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance">Cancel</a>
                            </div>
                        </form>
                    </c:when>

                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/labmanager/maintenance/add" class="form-grid">
                            <div class="form-group">
                                <label>Thiết bị cần bảo trì *</label>
                                <select class="form-control" name="assetId" required>
                                    <c:forEach var="a" items="${assets}">
                                        <option value="${a.assetId}"><c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/> - <c:out value="${a.storageLocation}"/>)</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Số lượng (Quantity) *</label>
                                <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                            </div>
                            <div class="form-group full-width">
                                <label>Mô tả chi tiết tình trạng hỏng hóc & Yêu cầu sửa chữa *</label>
                                <textarea class="form-control" name="description" required placeholder="Mô tả cụ thể hiện tượng lỗi, nguyên nhân hoặc bộ phận cần thay thế..."></textarea>
                            </div>
                            <div class="form-group full-width" style="display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Create Maintenance Ticket</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance">Cancel</a>
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
