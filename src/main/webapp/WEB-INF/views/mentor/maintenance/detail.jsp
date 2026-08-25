<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết phiếu bảo trì #MNT-${record.maintenanceId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .timeline { padding: 20px 0; }
        .timeline-item { display: flex; gap: 16px; margin-bottom: 20px; }
        .timeline-dot { width: 14px; height: 14px; border-radius: 50%; background: #188255; flex-shrink: 0; margin-top: 3px; }
        .timeline-dot.pending { background: #e2aa3d; }
        .timeline-dot.rejected { background: #c62828; }
        .timeline-dot.completed { background: #188255; }
        .timeline-content { flex: 1; }
        .timeline-content small { font-size: 11px; color: #5a6662; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; padding: 20px; }
        .info-item label { font-size: 11px; text-transform: uppercase; color: #5a6662; font-weight: 600; display: block; margin-bottom: 4px; }
        .info-item p { margin: 0; font-size: 14px; }
    </style>
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
                    <h1>Phiếu bảo trì #MNT-<c:out value="${record.maintenanceId}"/></h1>
                    <p>Chi tiết hồ sơ sửa chữa và trạng thái xử lý</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${param.success == 'created'}">
                <div class="success-message">Đã tạo đề xuất bảo trì thành công. Chờ Lab Manager phê duyệt.</div>
            </c:if>
            <c:if test="${param.success == 'updated'}">
                <div class="success-message">Đã cập nhật thông tin đề xuất bảo trì thành công.</div>
            </c:if>

            <div style="display:grid;grid-template-columns:1fr 360px;gap:20px;">

                <%-- THÔNG TIN CHÍNH --%>
                <div>
                    <article class="panel" style="margin-bottom:20px;">
                        <div style="padding:16px 20px;border-bottom:1px solid #edf0ec;display:flex;justify-content:space-between;align-items:center;">
                            <strong>Thông tin phiếu bảo trì</strong>
                            <c:choose>
                                <c:when test="${record.status == 'IN_PROGRESS'}">
                                    <span class="status maintenance">Đang sửa chữa</span>
                                </c:when>
                                <c:when test="${record.status == 'PENDING'}"><span class="status">Chờ Lab Manager duyệt</span></c:when>
                                <c:when test="${record.status == 'APPROVED'}"><span class="status">Đã duyệt, chờ bắt đầu</span></c:when>
                                <c:when test="${record.status == 'REJECTED'}"><span class="status overdue">Đã từ chối</span></c:when>
                                <c:when test="${record.status == 'COMPLETED'}">
                                    <c:choose>
                                        <c:when test="${record.assetStatus == 'UNAVAILABLE'}">
                                            <span class="status overdue">Sửa thất bại</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="status returned">Đã sửa xong</span>
                                        </c:otherwise>
                                    </c:choose>
                                </c:when>
                                <c:otherwise>
                                    <span class="status"><c:out value="${record.status}"/></span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <div class="info-grid">
                            <div class="info-item">
                                <label>Mã phiếu</label>
                                <p><strong>#MNT-<c:out value="${record.maintenanceId}"/></strong></p>
                            </div>
                            <div class="info-item">
                                <label>Ngày tạo phiếu</label>
                                <p><c:out value="${app:dateTime(record.requestedAt)}"/></p>
                            </div>
                            <div class="info-item">
                                <label>Thiết bị</label>
                                <p><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</p>
                            </div>
                            <div class="info-item">
                                <label>Số lượng bảo trì</label>
                                <p><c:out value="${record.quantity}"/></p>
                            </div>
                            <c:if test="${not empty record.storageLocation}">
                                <div class="info-item">
                                    <label>Vị trí lưu trữ</label>
                                    <p><c:out value="${record.storageLocation}"/></p>
                                </div>
                            </c:if>
                            <div class="info-item">
                                <label>Người đề xuất</label>
                                <p><c:out value="${record.requesterName}"/></p>
                            </div>
                            <c:if test="${not empty record.incidentId}">
                                <div class="info-item full-width" style="grid-column:1/-1;">
                                    <label>Sự cố liên quan</label>
                                    <p>#INC-<c:out value="${record.incidentId}"/>
                                        <c:if test="${not empty record.incidentDescription}">
                                            – <c:out value="${record.incidentDescription}"/>
                                        </c:if>
                                    </p>
                                </div>
                            </c:if>
                            <div class="info-item full-width" style="grid-column:1/-1;">
                                <label>Mô tả tình trạng hỏng hóc</label>
                                <p style="white-space:pre-line"><c:out value="${record.description}"/></p>
                            </div>
                            <c:if test="${record.status == 'REJECTED'}">
                                <div class="info-item full-width" style="grid-column:1/-1;background:#fdf2f2;padding:12px 14px;border-radius:6px;border:1px solid #f8b4b4;">
                                    <label style="color:#c62828;font-weight:700;">Lý do từ chối yêu cầu bảo trì</label>
                                    <p style="color:#c62828;margin-top:4px;">
                                        <c:choose>
                                            <c:when test="${not empty record.approvalNote}">
                                                <c:out value="${record.approvalNote}"/>
                                            </c:when>
                                            <c:otherwise>
                                                <i>(Lab Manager không để lại lý do cụ thể)</i>
                                            </c:otherwise>
                                        </c:choose>
                                    </p>
                                </div>
                            </c:if>
                            <c:if test="${not empty record.estimatedCost}">
                                <div class="info-item">
                                    <label>Dự toán kinh phí</label>
                                    <p><strong><fmt:formatNumber value="${record.estimatedCost}" type="number" groupingUsed="true"/> VNĐ</strong></p>
                                </div>
                            </c:if>
                        </div>
                    </article>

                    <%-- KẾT QUẢ SỬA CHỮA --%>
                    <c:if test="${record.status == 'IN_PROGRESS' || record.status == 'COMPLETED'}">
                        <article class="panel">
                            <div style="padding:14px 18px;border-bottom:1px solid #edf0ec;">
                                <strong>Tiến độ &amp; Kết quả sửa chữa</strong>
                            </div>
                            <div style="padding:18px; display:flex; flex-direction:row; gap:24px; align-items:flex-start; justify-content:space-between; flex-wrap:wrap;">
                                <div class="info-grid" style="flex:1; min-width:280px; padding:0;">
                                    <div class="info-item">
                                        <label>Trạng thái sửa chữa</label>
                                        <p>
                                            <c:choose>
                                                 <c:when test="${record.status == 'COMPLETED'}">
                                                     <c:choose>
                                                         <c:when test="${record.assetStatus == 'UNAVAILABLE'}">
                                                             <span class="status overdue" style="font-size:13.5px;padding:4px 10px;font-weight:600;display:inline-block;">❌ Sửa thất bại</span>
                                                         </c:when>
                                                         <c:otherwise>
                                                             <span class="status returned" style="font-size:13.5px;padding:4px 10px;font-weight:600;display:inline-block;">✅ Sửa thành công</span>
                                                         </c:otherwise>
                                                     </c:choose>
                                                 </c:when>
                                                 <c:when test="${record.status == 'IN_PROGRESS'}">
                                                     <span class="status maintenance" style="font-size:13.5px;padding:4px 10px;font-weight:600;display:inline-block;">⏳ Đang sửa chữa</span>
                                                 </c:when>
                                                 <c:otherwise>
                                                     <span class="status in-use" style="font-size:13.5px;padding:4px 10px;font-weight:600;display:inline-block;">Đã duyệt – Chờ sửa</span>
                                                 </c:otherwise>
                                             </c:choose>
                                        </p>
                                    </div>
                                    <div class="info-item">
                                        <label>Đơn vị / Kỹ thuật viên</label>
                                        <p><c:choose>
                                            <c:when test="${not empty record.note}"><c:out value="${record.note}"/></c:when>
                                            <c:otherwise>—</c:otherwise>
                                        </c:choose></p>
                                    </div>
                                    <div class="info-item">
                                        <label>SĐT đơn vị / kỹ thuật viên</label>
                                        <p><c:choose>
                                            <c:when test="${not empty record.providerPhone}">
                                                <a href="tel:${record.providerPhone}" style="color:#2563eb;font-weight:600;"><c:out value="${record.providerPhone}"/></a>
                                            </c:when>
                                            <c:otherwise>—</c:otherwise>
                                        </c:choose></p>
                                    </div>
                                    <c:if test="${not empty record.providerAddress}">
                                        <div class="info-item">
                                            <label>Địa chỉ đơn vị sửa chữa</label>
                                            <p><c:out value="${record.providerAddress}"/></p>
                                        </div>
                                    </c:if>
                                    <div class="info-item">
                                        <label>Ngày bắt đầu sửa</label>
                                        <p><c:out value="${app:dateTime(record.repairStartedAt)}"/></p>
                                    </div>
                                    <c:if test="${record.status == 'COMPLETED'}">
                                        <div class="info-item">
                                            <label>Ngày hoàn thành</label>
                                            <p><c:out value="${app:dateTime(record.repairCompletedAt)}"/></p>
                                        </div>
                                    </c:if>
                                    <c:if test="${not empty record.actualCost}">
                                        <div class="info-item">
                                            <label>Chi phí thực tế</label>
                                            <p style="color:#2563eb;font-weight:700;font-size:15px;">
                                                <fmt:formatNumber value="${record.actualCost}" type="number" groupingUsed="true"/> VNĐ
                                            </p>
                                        </div>
                                    </c:if>
                                    <c:if test="${not empty record.repairResult}">
                                        <div class="info-item full-width" style="grid-column:1/-1;">
                                            <label>Kết quả sửa chữa</label>
                                            <p style="white-space:pre-line"><c:out value="${record.repairResult}"/></p>
                                        </div>
                                    </c:if>
                                </div>

                                <c:if test="${not empty record.imageUrl}">
                                    <div style="width:230px; flex-shrink:0; text-align:center;">
                                        <label style="display:block; font-size:11.5px; font-weight:700; color:#64748b; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:8px; text-align:left;">Ảnh đính kèm</label>
                                        <a href="<c:out value='${record.imageUrl}'/>" target="_blank" title="Nhấp để xem ảnh kích thước lớn" style="display:block; border-radius:8px; overflow:hidden; border:1px solid #cbd5e1; box-shadow:0 1px 4px rgba(0,0,0,0.08); background:#fff;">
                                            <img src="<c:out value='${record.imageUrl}'/>" alt="Ảnh đính kèm" style="width:100%; max-height:180px; object-fit:cover; display:block;">
                                        </a>
                                        <div style="margin-top:8px;">
                                            <a href="<c:out value='${record.imageUrl}'/>" target="_blank" style="font-size:12px; color:#2563eb; font-weight:600; text-decoration:none; display:inline-flex; align-items:center; gap:4px;">
                                                🔍 Xem ảnh gốc
                                            </a>
                                        </div>
                                    </div>
                                </c:if>
                            </div>
                        </article>
                    </c:if>
                </div>

                <%-- DÒNG THỜI GIAN (TIMELINE) --%>
                <div>
                    <article class="panel">
                        <div style="padding:16px 20px;border-bottom:1px solid #edf0ec;">
                            <strong>Lịch sử xử lý</strong>
                        </div>
                        <div style="padding:20px;">
                            <div class="timeline">
                                <div class="timeline-item">
                                    <div class="timeline-dot pending"></div>
                                    <div class="timeline-content">
                                        <b>Đề xuất bảo trì được tạo</b>
                                        <br><small><c:out value="${app:dateTime(record.requestedAt)}"/> – <c:out value="${record.requesterName}"/></small>
                                    </div>
                                </div>

                                <c:if test="${not empty record.approvedAt}">
                                    <div class="timeline-item">
                                        <div class="timeline-dot ${record.status == 'REJECTED' ? 'rejected' : 'completed'}"></div>
                                        <div class="timeline-content">
                                            <b>
                                                <c:choose>
                                                    <c:when test="${record.status == 'REJECTED'}">Yêu cầu bị từ chối</c:when>
                                                    <c:otherwise>Lab Manager đã phê duyệt</c:otherwise>
                                                </c:choose>
                                            </b>
                                            <br><small><c:out value="${app:dateTime(record.approvedAt)}"/> – <c:out value="${record.approverName}"/></small>
                                            <c:if test="${not empty record.approvalNote}">
                                                <br><small style="font-style:italic;color:${record.status == 'REJECTED' ? '#c62828' : '#5a6662'};">
                                                    <c:choose>
                                                        <c:when test="${record.status == 'REJECTED'}">Lý do: <c:out value="${record.approvalNote}"/></c:when>
                                                        <c:otherwise><c:out value="${record.approvalNote}"/></c:otherwise>
                                                    </c:choose>
                                                </small>
                                            </c:if>
                                        </div>
                                    </div>
                                </c:if>

                                <c:if test="${not empty record.repairStartedAt}">
                                    <div class="timeline-item">
                                        <div class="timeline-dot pending"></div>
                                        <div class="timeline-content">
                                            <b>Bắt đầu sửa chữa</b>
                                            <br><small><c:out value="${app:dateTime(record.repairStartedAt)}"/></small>
                                            <c:if test="${not empty record.note}">
                                                <br><small><c:out value="${record.note}"/></small>
                                            </c:if>
                                        </div>
                                    </div>
                                </c:if>

                                <c:if test="${not empty record.repairCompletedAt}">
                                    <div class="timeline-item">
                                        <div class="timeline-dot ${record.assetStatus == 'UNAVAILABLE' ? 'rejected' : 'completed'}"></div>
                                        <div class="timeline-content">
                                            <c:choose>
                                                <c:when test="${record.assetStatus == 'UNAVAILABLE'}">
                                                    <b style="color:#c62828;">Hoàn tất – Sửa thất bại (Thiết bị chuyển UNAVAILABLE)</b>
                                                </c:when>
                                                <c:otherwise>
                                                    <b>Hoàn tất sửa chữa – Thiết bị về AVAILABLE</b>
                                                </c:otherwise>
                                            </c:choose>
                                            <br><small><c:out value="${app:dateTime(record.repairCompletedAt)}"/></small>
                                            <c:if test="${not empty record.repairResult}">
                                                <br><small style="font-style:italic"><c:out value="${record.repairResult}"/></small>
                                            </c:if>
                                        </div>
                                    </div>
                                </c:if>
                            </div>
                        </div>
                    </article>
                </div>
            </div>
        </section>
    </main>
</div>
</body>
</html>
