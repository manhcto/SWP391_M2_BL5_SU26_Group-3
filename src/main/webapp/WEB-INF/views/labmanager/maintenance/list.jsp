<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Maintenance Management (FE-08) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-clipboard" viewBox="0 0 24 24"><rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2M9 9h6M9 13h6M9 17h4"/></symbol>
    <symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></symbol>
    <symbol id="i-box" viewBox="0 0 24 24"><path d="m21 8-9 5-9-5 9-5 9 5Z"/><path d="m3 8 9 5 9-5v9l-9 5-9-5V8Z"/><path d="M12 13v9"/></symbol>
    <symbol id="i-calendar" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/></symbol>
    <symbol id="i-inspect" viewBox="0 0 24 24"><path d="M9 5H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7M9 3h6v4H9zM8 11h4M8 15h3"/><circle cx="17" cy="16" r="4"/><path d="m20 19 2 2"/></symbol>
    <symbol id="i-alert" viewBox="0 0 24 24"><path d="M10.3 3.7 2.4 17.2A2 2 0 0 0 4.1 20h15.8a2 2 0 0 0 1.7-2.8L13.7 3.7a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/></symbol>
    <symbol id="i-list" viewBox="0 0 24 24"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-trash" viewBox="0 0 24 24"><path d="M3 6h18M8 6V3h8v3M19 6l-1 15H6L5 6M10 11v6M14 11v6"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-search" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></symbol>
    <symbol id="i-bell" viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></symbol>
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
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-clipboard"/></svg><span>Lab Requests</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-users"/></svg><span>Students</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-box"/></svg><span>Assets</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-calendar"/></svg><span>Asset Usage</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-inspect"/></svg><span>Inspections</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-alert"/></svg><span>Incidents</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-list"/></svg><span>Responsibilities</span></a>
            <a class="nav-link active" href="${pageContext.request.contextPath}/labmanager/maintenance" aria-current="page"><svg><use href="#i-wrench"/></svg><span>Maintenance</span><span class="nav-count">${records.size()}</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-trash"/></svg><span>Disposal</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/labmanager/dashboard"><svg><use href="#i-users"/></svg><span>My Profile</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">LM</div><div class="profile-copy"><strong>Pham Quang Dung</strong><span><i></i> Online (Staff)</span></div></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Maintenance & Repair Approvals (FE-08)</h1><p>Authorize repair proposals, cost estimates, technician dispatch</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Search maintenance..." aria-label="Search"></label>
                <button class="icon-button notification" type="button" aria-label="Notifications"><svg><use href="#i-bell"/></svg><span>3</span></button>
                <div class="top-profile"><div class="avatar">LM</div><span>Quang Dung</span></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">FE-08 MAINTENANCE</p><h2>Maintenance Requests List (${records.size()})</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/add"><svg><use href="#i-wrench"/></svg>+ Create Repair Ticket</a>
            </div>

            <c:if test="${param.success == 'created'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Phiếu bảo trì đã được tạo và lưu vào hệ thống!</div></c:if>
            <c:if test="${param.success == 'approved'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Quyết định phê duyệt/từ chối đã được xử lý!</div></c:if>
            <c:if test="${param.success == 'updated'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Cập nhật tiến độ kỹ thuật thành công!</div></c:if>

            <div class="filter-bar">
                <form method="get" action="${pageContext.request.contextPath}/labmanager/maintenance" class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Search asset or issue..." style="width: 240px;">
                    <select class="form-control" name="status">
                        <option value="">All Status</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>PENDING (Chờ duyệt)</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>APPROVED (Đã duyệt)</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>IN_PROGRESS (Đang sửa)</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>COMPLETED (Đã sửa xong)</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>REJECTED (Từ chối)</option>
                    </select>
                    <button class="primary-button" type="submit" style="height: 36px; padding: 0 16px;">Filter</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance" style="height: 36px;">Reset</a>
                </form>
            </div>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-wrench"/></svg></div>
                            <h3>Chưa có phiếu bảo trì nào</h3>
                            <p>Hiện chưa có yêu cầu sửa chữa hoặc bảo trì thiết bị nào được gửi trong hệ thống.</p>
                            <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/add">+ Tạo phiếu bảo trì ngay</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Ticket ID</th>
                                    <th>Asset Name / Code</th>
                                    <th>Requested By</th>
                                    <th>Description / Issue</th>
                                    <th>Requested Date</th>
                                    <th>Status</th>
                                    <th>Approver</th>
                                    <th style="text-align: right;">Actions</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="m" items="${records}">
                                    <tr>
                                        <td><strong>#MNT-${m.maintenanceId}</strong></td>
                                        <td><b><c:out value="${m.assetName}"/></b><br><small style="color:#8a938f;"><c:out value="${m.assetCode}"/></small></td>
                                        <td><c:out value="${m.requesterName}"/></td>
                                        <td><c:out value="${m.description}"/></td>
                                        <td><c:out value="${m.requestedAt}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${m.status == 'PENDING'}"><span class="status review">PENDING</span></c:when>
                                                <c:when test="${m.status == 'APPROVED'}"><span class="badge badge-gold">APPROVED</span></c:when>
                                                <c:when test="${m.status == 'IN_PROGRESS'}"><span class="badge badge-blue">IN_PROGRESS</span></c:when>
                                                <c:when test="${m.status == 'COMPLETED'}"><span class="status returned">COMPLETED</span></c:when>
                                                <c:otherwise><span class="badge badge-red"><c:out value="${m.status}"/></span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><c:out value="${m.approverName}" default="—"/></td>
                                        <td style="text-align: right;">
                                            <a class="btn-action" href="${pageContext.request.contextPath}/labmanager/maintenance/view?id=${m.maintenanceId}">View</a>
                                            <a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/labmanager/maintenance/edit?id=${m.maintenanceId}">Update / Approve</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <div class="page-size-selector"><span>Show</span><select class="form-control" style="width: auto; height: 28px;"><option value="10" selected>10</option><option value="25">25</option></select><span>records per page</span></div>
                            <span>Showing 1 to ${records.size()} of ${records.size()} records</span>
                            <div class="pagination-controls"><button class="page-btn" disabled>‹</button><button class="page-btn active">1</button><button class="page-btn">›</button></div>
                        </div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
