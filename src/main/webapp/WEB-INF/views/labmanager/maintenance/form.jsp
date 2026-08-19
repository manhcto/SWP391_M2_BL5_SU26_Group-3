<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${formMode == 'edit' && record.status == 'PENDING'}">Phê duyệt yêu cầu bảo trì #MNT-${record.maintenanceId}</c:when>
            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ bảo trì #MNT-${record.maintenanceId}</c:when>
            <c:otherwise>Tạo phiếu bảo trì</c:otherwise>
        </c:choose> | LAB Asset
    </title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button>
                <div>
                    <h1>
                        <c:choose>
                            <c:when test="${formMode == 'edit' && record.status == 'PENDING'}">Phê duyệt yêu cầu bảo trì #MNT-${record.maintenanceId}</c:when>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa #MNT-${record.maintenanceId}</c:when>
                            <c:otherwise>Tạo phiếu bảo trì</c:otherwise>
                        </c:choose>
                    </h1>
                    <p>
                        <c:choose>
                            <c:when test="${formMode == 'edit' && record.status == 'PENDING'}">Xem xét đề xuất từ Mentor và đưa ra quyết định phê duyệt</c:when>
                            <c:when test="${formMode == 'edit'}">Cập nhật tiến độ sửa chữa, điều chỉnh kinh phí và ghi nhận kết quả nghiệm thu</c:when>
                            <c:otherwise>Tạo phiếu bảo trì thiết bị trong phòng LAB</c:otherwise>
                        </c:choose>
                    </p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <c:choose>
                    <%-- BƯỚC 1: PHÊ DUYỆT (KHI ĐANG PENDING) --%>
                    <c:when test="${formMode == 'edit' && record.status == 'PENDING'}">
                        <div style="padding: 16px; border-bottom: 1px solid #edf0ec; background:#fafbf9; border-radius: 8px 8px 0 0;">
                            <strong>Chi tiết đề xuất từ Mentor:</strong>
                            <p style="margin: 6px 0 0; font-size: 13px; color:#5a6662;">
                                Thiết bị: <b><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</b> &nbsp;·&nbsp;
                                Số lượng: <b><c:out value="${record.quantity}"/></b> &nbsp;·&nbsp;
                                Người đề xuất: <b><c:out value="${record.requesterName}"/></b>
                            </p>
                            <p style="margin: 6px 0 0; font-size: 13px; color:#333;">
                                Mô tả tình trạng hỏng hóc: <i>"<c:out value="${record.description}"/>"</i>
                            </p>
                        </div>

                        <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="decide">
                            <input type="hidden" name="id" value="${record.maintenanceId}">

                            <div class="form-group full-width">
                                <label>Quyết định phê duyệt *</label>
                                <select class="form-control" name="decision" required>
                                    <option value="APPROVED">✅ Duyệt sửa chữa (Chuyển thiết bị sang Đang bảo trì)</option>
                                    <option value="REJECTED">❌ Từ chối yêu cầu bảo trì</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Ghi chú phê duyệt / Dự toán kinh phí dự kiến</label>
                                <input class="form-control" type="text" name="approvalNote"
                                       value="<c:out value='${record.approvalNote}'/>"
                                       placeholder="Ví dụ: Duyệt chi phí 650.000 VNĐ mang sang FPT Tech Service">
                            </div>

                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa (chỉ định nếu có)</label>
                                <input class="form-control" type="text" name="note"
                                       value="<c:out value='${record.note}'/>"
                                       placeholder="Ví dụ: FPT Tech Services / Kỹ thuật viên nội bộ">
                            </div>

                            <div class="form-group full-width" style="display: flex; gap: 10px; margin-top: 10px;">
                                <button class="primary-button" type="submit">Gửi quyết định phê duyệt</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Hủy</a>
                            </div>
                        </form>
                    </c:when>

                    <%-- BƯỚC 2: CẬP NHẬT TIẾN ĐỘ & KẾT QUẢ SỬA CHỮA (KHI ĐÃ APPROVED / IN_PROGRESS) --%>
                    <c:when test="${formMode == 'edit'}">
                        <div style="padding: 16px; border-bottom: 1px solid #edf0ec; background:#fafbf9; border-radius: 8px 8px 0 0;">
                            <strong>Thông tin phiếu bảo trì:</strong>
                            <p style="margin: 6px 0 0; font-size: 13px; color:#5a6662;">
                                Thiết bị: <b><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</b> &nbsp;·&nbsp;
                                Người đề xuất: <b><c:out value="${record.requesterName}"/></b> &nbsp;·&nbsp;
                                Người duyệt: <b><c:out value="${record.approverName}"/></b>
                            </p>
                        </div>

                        <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="updateProgress">
                            <input type="hidden" name="id" value="${record.maintenanceId}">

                            <div class="form-group full-width">
                                <label>Trạng thái tiến độ *</label>
                                <select class="form-control" name="status" required>
                                    <option value="APPROVED" ${record.status == 'APPROVED' ? 'selected' : ''}>Đã duyệt – Chờ đưa đi sửa</option>
                                    <option value="IN_PROGRESS" ${record.status == 'IN_PROGRESS' ? 'selected' : ''}>Đang sửa chữa</option>
                                    <option value="COMPLETED_SUCCESS" ${record.status == 'COMPLETED' ? 'selected' : ''}>✅ Đã sửa xong – Hoàn tất thành công (Thiết bị về Sẵn sàng AVAILABLE)</option>
                                    <option value="COMPLETED_FAILED">❌ Sửa thất bại – Không thể phục hồi (Thiết bị chuyển UNAVAILABLE chờ thanh lý)</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Ghi chú phê duyệt / Kinh phí sửa chữa</label>
                                <input class="form-control" type="text" name="approvalNote"
                                       value="<c:out value='${record.approvalNote}'/>"
                                       placeholder="Ví dụ: Chi phí thực tế 650.000 VNĐ">
                            </div>

                            <div class="form-group">
                                <label>Đơn vị / Kỹ thuật viên sửa chữa</label>
                                <input class="form-control" type="text" name="note"
                                       value="<c:out value='${record.note}'/>"
                                       placeholder="Ví dụ: Kỹ thuật viên Tektronix VN / FPT Services">
                            </div>

                            <div class="form-group full-width">
                                <label>Kết quả sửa chữa / Linh kiện thay thế</label>
                                <textarea class="form-control" name="repairResult" rows="4"
                                          placeholder="Ví dụ: Đã thay thế vòi phun extruder và cân chỉnh nhiệt độ bàn in. Thiết bị hoạt động hoàn hảo."><c:out value="${record.repairResult}"/></textarea>
                            </div>

                            <div class="form-group full-width" style="display: flex; gap: 10px; margin-top: 10px;">
                                <button class="primary-button" type="submit">Lưu tiến độ bảo trì</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Hủy</a>
                            </div>
                        </form>
                    </c:when>

                    <%-- FORM TẠO MỚI PHIẾU BẢO TRÌ --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" class="form-grid">
                            <input type="hidden" name="action" value="create">
                            <div class="form-group">
                                <label>Thiết bị cần bảo trì *</label>
                                <select class="form-control" name="assetId" required>
                                    <c:forEach var="a" items="${assets}">
                                        <option value="${a.assetId}"><c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/> - <c:out value="${a.storageLocation}"/>)</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Số lượng *</label>
                                <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                            </div>
                            <div class="form-group full-width">
                                <label>Mô tả chi tiết tình trạng hỏng hóc &amp; Yêu cầu sửa chữa *</label>
                                <textarea class="form-control" name="description" rows="5" required placeholder="Mô tả cụ thể hiện tượng lỗi, nguyên nhân hoặc bộ phận cần thay thế..."></textarea>
                            </div>
                            <div class="form-group full-width" style="display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Tạo phiếu bảo trì</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">Hủy</a>
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
