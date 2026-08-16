<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Maintenance Proposals (FE-08) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Maintenance Proposals (FE-08)</h1><p>Submit repair proposals and track progress</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Search proposals..." aria-label="Search"></label>
                <button class="icon-button notification" type="button" aria-label="Notifications"><svg><use href="#i-bell"/></svg><span>2</span></button>
                <div class="top-profile"><div class="avatar">ME</div><span>Mentor Preview</span></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">FE-08 MAINTENANCE</p><h2>My Submitted Proposals (${records.size()})</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/maintenance/add"><svg><use href="#i-wrench"/></svg>+ Propose Maintenance</a>
            </div>

            <c:if test="${param.success == 'submitted'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Đề xuất bảo trì của bạn đã được gửi cho Lab Manager phê duyệt!</div></c:if>

            <div class="filter-bar">
                <form method="get" action="${pageContext.request.contextPath}/mentor/maintenance" class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Search equipment or issue..." style="width: 240px;">
                    <select class="form-control" name="status">
                        <option value="">All Status</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>PENDING (Chờ duyệt)</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>APPROVED (Đã duyệt)</option>
                        <option value="IN_PROGRESS" ${selectedStatus == 'IN_PROGRESS' ? 'selected' : ''}>IN_PROGRESS (Đang sửa)</option>
                        <option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>COMPLETED (Đã sửa xong)</option>
                    </select>
                    <button class="primary-button" type="submit" style="height: 36px; padding: 0 16px;">Filter</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance" style="height: 36px;">Reset</a>
                </form>
            </div>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty records}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-wrench"/></svg></div>
                            <h3>Bạn chưa gửi đề xuất bảo trì nào</h3>
                            <p>Khi phát hiện thiết bị thí nghiệm gặp sự cố, bạn có thể tạo đề xuất để Lab Manager xử lý.</p>
                            <a class="primary-button" href="${pageContext.request.contextPath}/mentor/maintenance/add">+ Gửi đề xuất bảo trì mới</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Ticket ID</th>
                                    <th>Asset Name / Code</th>
                                    <th>Issue Summary</th>
                                    <th>Submitted Date</th>
                                    <th>Status</th>
                                    <th>Approved By</th>
                                    <th style="text-align: right;">Action</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="m" items="${records}">
                                    <tr>
                                        <td><strong>#MNT-${m.maintenanceId}</strong></td>
                                        <td><b><c:out value="${m.assetName}"/></b><br><small style="color:#8a938f;"><c:out value="${m.assetCode}"/></small></td>
                                        <td><c:out value="${m.description}"/></td>
                                        <td><c:out value="${m.requestedAt}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${m.status == 'PENDING'}"><span class="status review">PENDING APPROVAL</span></c:when>
                                                <c:when test="${m.status == 'APPROVED'}"><span class="badge badge-gold">APPROVED</span></c:when>
                                                <c:when test="${m.status == 'IN_PROGRESS'}"><span class="badge badge-blue">IN REPAIR</span></c:when>
                                                <c:when test="${m.status == 'COMPLETED'}"><span class="status returned">COMPLETED</span></c:when>
                                                <c:otherwise><span class="badge badge-red"><c:out value="${m.status}"/></span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><c:out value="${m.approverName}" default="Awaiting Review"/></td>
                                        <td style="text-align: right;">
                                            <a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/mentor/maintenance/view?id=${m.maintenanceId}">View Details</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <div class="page-size-selector"><span>Show</span><select class="form-control" style="width: auto; height: 28px;"><option value="10" selected>10</option><option value="25">25</option></select><span>proposals per page</span></div>
                            <span>Showing 1 to ${records.size()} of ${records.size()} proposals</span>
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
