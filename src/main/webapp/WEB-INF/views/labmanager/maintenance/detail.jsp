<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chi tiết phiếu bảo trì #MNT-${record.maintenanceId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .timeline-item { display: flex; gap: 14px; margin-bottom: 18px; }
        .timeline-dot { width: 13px; height: 13px; border-radius: 50%; background: #188255; flex-shrink: 0; margin-top: 3px; }
        .timeline-dot.pending { background: #e2aa3d; }
        .timeline-dot.rejected { background: #c62828; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; padding: 18px; }
        .info-item label { font-size: 11px; text-transform: uppercase; color: #5a6662; font-weight: 600; display: block; margin-bottom: 3px; }
        .info-item p { margin: 0; font-size: 14px; }
    </style>
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
                    <h1>Phiếu bảo trì #MNT-<c:out value="${record.maintenanceId}"/></h1>
                    <p>Chi tiết yêu cầu sửa chữa thiết bị và tiến trình xử lý</p>
                </div>
            </div>
            <div class="topbar-actions">
                <c:if test="${record.status == 'PENDING' || record.status == 'APPROVED' || record.status == 'IN_PROGRESS'}">
                    <a class="primary-button"
                       href="${pageContext.request.contextPath}/lab-manager/maintenance/${record.maintenanceId}/edit">
                        <svg><use href="#i-wrench"/></svg>
                        <c:choose>
                            <c:when test="${record.status == 'PENDING'}">Phê duyệt</c:when>
                            <c:otherwise>Cập nhật tiến độ</c:otherwise>
                        </c:choose>
                    </a>
                </c:if>
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/maintenance">‹ Quay lại</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <div style="display:grid;grid-template-columns:1fr 340px;gap:20px;">

                <%-- THÔNG TIN CHÍNH --%>
                <div>
                    <article class="panel" style="margin-bottom:20px;">
                        <div style="padding:14px 18px;border-bottom:1px solid #edf0ec;display:flex;justify-content:space-between;align-items:center;">
                            <strong>Thông tin phiếu bảo trì</strong>
                            <c:choose>
                                <c:when test="${record.status == 'PENDING'}">
                                    <span class="status review">Chờ duyệt</span>
                                </c:when>
                                <c:when test="${record.status == 'APPROVED'}">
                                    <span class="status in-use">Đã duyệt</span>
                                </c:when>
                                <c:when test="${record.status == 'IN_PROGRESS'}">
                                    <span class="status maintenance">Đang sửa</span>
                                </c:when>
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
                                <c:when test="${record.status == 'REJECTED'}">
                                    <span class="status overdue">Bị từ chối</span>
                                </c:when>
                            </c:choose>
                        </div>
                        <div class="info-grid">
                            <div class="info-item">
                                <label>Mã phiếu</label>
                                <p><strong>#MNT-<c:out value="${record.maintenanceId}"/></strong></p>
                            </div>
                            <div class="info-item">
                                <label>Ngày đề xuất</label>
                                <p><c:out value="${app:dateTime(record.requestedAt)}"/></p>
                            </div>
                            <div class="info-item">
                                <label>Thiết bị</label>
                                <p><c:out value="${record.assetName}"/> (<c:out value="${record.assetCode}"/>)</p>
                            </div>
                            <div class="info-item">
                                <label>Số lượng</label>
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
                                <div class="info-item" style="grid-column:1/-1;">
                                    <label>Sự cố liên quan</label>
                                    <p>#INC-<c:out value="${record.incidentId}"/>
                                        <c:if test="${not empty record.incidentDescription}">
                                            – <c:out value="${record.incidentDescription}"/>
                                        </c:if>
                                    </p>
                                </div>
                            </c:if>
                            <div class="info-item" style="grid-column:1/-1;">
                                <label>Mô tả tình trạng hỏng hóc</label>
                                <p style="white-space:pre-line"><c:out value="${record.description}"/></p>
                            </div>
                        </div>
                    </article>

                    <%-- KẾT QUẢ SỬA CHỮA --%>
                    <c:if test="${record.status == 'IN_PROGRESS' || record.status == 'COMPLETED'}">
                        <article class="panel">
                            <div style="padding:14px 18px;border-bottom:1px solid #edf0ec;">
                                <strong>Tiến độ &amp; Kết quả sửa chữa</strong>
                            </div>
                            <div class="info-grid">
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
                                    <label>Ngày bắt đầu sửa</label>
                                    <p><c:out value="${app:dateTime(record.repairStartedAt)}"/></p>
                                </div>
                                <c:if test="${record.status == 'COMPLETED'}">
                                    <div class="info-item">
                                        <label>Ngày hoàn thành</label>
                                        <p><c:out value="${app:dateTime(record.repairCompletedAt)}"/></p>
                                    </div>
                                </c:if>
                                <c:if test="${not empty record.repairResult}">
                                    <div class="info-item" style="grid-column:1/-1;">
                                        <label>Kết quả sửa chữa</label>
                                        <p style="white-space:pre-line"><c:out value="${record.repairResult}"/></p>
                                    </div>
                                </c:if>
                            </div>
                        </article>
                    </c:if>
                </div>

                <%-- CỘT PHẢI: TIMELINE + KHUNG DUYỆT --%>
                <div>
                    <%-- KHUNG PHÊ DUYỆT (chỉ hiển thị khi PENDING) --%>
                    <c:if test="${record.status == 'PENDING'}">
                        <article class="panel" style="margin-bottom:16px;border:2px solid #bce1ce;">
                            <div style="padding:14px 18px;border-bottom:1px solid #edf0ec;background:#e5f3eb;border-radius:8px 8px 0 0;">
                                <strong style="color:#137a4d;">⚡ Yêu cầu cần phê duyệt</strong>
                            </div>
                            <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance" style="padding:16px;display:flex;flex-direction:column;gap:12px;">
                                <input type="hidden" name="action" value="decide">
                                <input type="hidden" name="id" value="${record.maintenanceId}">
                                <div>
                                    <label class="form-label">Quyết định *</label>
                                    <select class="form-control" name="decision">
                                        <option value="APPROVED">✅ Duyệt – Cho phép sửa chữa</option>
                                        <option value="REJECTED">❌ Từ chối yêu cầu</option>
                                    </select>
                                </div>
                                <div>
                                    <label class="form-label">Ghi chú phê duyệt / Dự toán kinh phí</label>
                                    <input class="form-control" type="text" name="approvalNote"
                                           placeholder="VD: Duyệt chi phí 650.000 VNĐ">
                                </div>
                                <div>
                                    <label class="form-label">Đơn vị / Kỹ thuật viên sửa chữa</label>
                                    <input class="form-control" type="text" name="note"
                                           placeholder="VD: FPT Tech Services">
                                </div>
                                <button class="primary-button" type="submit">Gửi quyết định phê duyệt</button>
                            </form>
                        </article>
                    </c:if>

                    <%-- TIMELINE --%>
                    <article class="panel">
                        <div style="padding:14px 18px;border-bottom:1px solid #edf0ec;">
                            <strong>Lịch sử xử lý</strong>
                        </div>
                        <div style="padding:18px;">
                            <div class="timeline-item">
                                <div class="timeline-dot pending"></div>
                                <div>
                                    <b>Đề xuất bảo trì được tạo</b>
                                    <br><small style="color:#5a6662"><c:out value="${app:dateTime(record.requestedAt)}"/> – <c:out value="${record.requesterName}"/></small>
                                </div>
                            </div>
                            <c:if test="${not empty record.approvedAt}">
                                <div class="timeline-item">
                                    <div class="timeline-dot ${record.status == 'REJECTED' ? 'rejected' : ''}"></div>
                                    <div>
                                        <b>
                                            <c:choose>
                                                <c:when test="${record.status == 'REJECTED'}">Yêu cầu bị từ chối</c:when>
                                                <c:otherwise>Đã phê duyệt</c:otherwise>
                                            </c:choose>
                                        </b>
                                        <br><small style="color:#5a6662"><c:out value="${app:dateTime(record.approvedAt)}"/> – <c:out value="${record.approverName}"/></small>
                                        <c:if test="${not empty record.approvalNote}">
                                            <br><small style="font-style:italic"><c:out value="${record.approvalNote}"/></small>
                                        </c:if>
                                    </div>
                                </div>
                            </c:if>
                            <c:if test="${not empty record.repairStartedAt}">
                                <div class="timeline-item">
                                    <div class="timeline-dot pending"></div>
                                    <div>
                                        <b>Bắt đầu sửa chữa</b>
                                        <br><small style="color:#5a6662"><c:out value="${app:dateTime(record.repairStartedAt)}"/></small>
                                        <c:if test="${not empty record.note}">
                                            <br><small><c:out value="${record.note}"/></small>
                                        </c:if>
                                    </div>
                                </div>
                            </c:if>
                            <c:if test="${not empty record.repairCompletedAt}">
                                <div class="timeline-item">
                                    <div class="timeline-dot ${record.assetStatus == 'UNAVAILABLE' ? 'rejected' : ''}"></div>
                                    <div>
                                        <c:choose>
                                            <c:when test="${record.assetStatus == 'UNAVAILABLE'}">
                                                <b style="color:#c62828;">Hoàn tất – Sửa thất bại (Thiết bị chuyển UNAVAILABLE chờ thanh lý)</b>
                                            </c:when>
                                            <c:otherwise>
                                                <b>Hoàn tất – Sửa thành công (Thiết bị về AVAILABLE)</b>
                                            </c:otherwise>
                                        </c:choose>
                                        <br><small style="color:#5a6662"><c:out value="${app:dateTime(record.repairCompletedAt)}"/></small>
                                        <c:if test="${not empty record.repairResult}">
                                            <br><small style="font-style:italic"><c:out value="${record.repairResult}"/></small>
                                        </c:if>
                                    </div>
                                </div>
                            </c:if>
                        </div>
                    </article>
                </div>
            </div>
        </section>
    </main>
</div>
</body>
</html>
