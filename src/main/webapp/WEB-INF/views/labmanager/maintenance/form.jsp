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
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16"/></symbol>
</svg>
<div class="app-shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="${pageContext.request.contextPath}/labmanager/dashboard" aria-label="LAB Asset home">
            <span class="brand-mark"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"></span>
            <span><strong>LAB ASSET</strong><small>LAB MANAGER PORTAL</small></span>
        </a>
        <nav class="side-nav">
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-grid"/></svg><span>Dashboard</span></a>
            <a class="nav-link active" href="${pageContext.request.contextPath}/labmanager/maintenance" aria-current="page"><svg><use href="#i-wrench"/></svg><span>Maintenance</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">LM</div><div class="profile-copy"><strong>Pham Quang Dung</strong><span><i></i> Online (Staff)</span></div></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>

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
