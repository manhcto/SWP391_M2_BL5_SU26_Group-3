<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Maintenance Ticket #MNT-${record.maintenanceId} | LAB Asset</title>
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
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Ticket #MNT-${record.maintenanceId}: <c:out value="${record.assetName}"/></h1><p>Comprehensive maintenance lifecycle record</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/labmanager/maintenance">‹ Back to List</a>
                <a class="primary-button" href="${pageContext.request.contextPath}/labmanager/maintenance/edit?id=${record.maintenanceId}">Update / Approve Ticket</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>Ticket ID</label><input class="form-control" type="text" value="#MNT-${record.maintenanceId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Asset Name & Code</label><input class="form-control" type="text" value="<c:out value='${record.assetName}'/> (<c:out value='${record.assetCode}'/>)" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <div class="form-group"><label>Requested By</label><input class="form-control" type="text" value="<c:out value='${record.requesterName}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Requested Time</label><input class="form-control" type="text" value="<c:out value='${record.requestedAt}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group full-width"><label>Issue Description</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.description}"/></textarea></div>
                    
                    <div class="form-group"><label>Current Status</label><input class="form-control" type="text" value="<c:out value='${record.status}'/>" readonly style="background:#f4f6f4; font-weight:700; color:#188255;"></div>
                    <div class="form-group"><label>Approved By</label><input class="form-control" type="text" value="<c:out value='${record.approverName}' default='—'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.approvalNote}">
                        <div class="form-group full-width"><label>Approval Note & Cost</label><input class="form-control" type="text" value="<c:out value='${record.approvalNote}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <div class="form-group"><label>Repair Started At</label><input class="form-control" type="text" value="<c:out value='${record.repairStartedAt}' default='—'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Repair Completed At</label><input class="form-control" type="text" value="<c:out value='${record.repairCompletedAt}' default='—'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.repairResult}">
                        <div class="form-group full-width"><label>Repair Result & Inspection</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.repairResult}"/></textarea></div>
                    </c:if>
                    <c:if test="${not empty record.note}">
                        <div class="form-group full-width"><label>Servicing Technician Note</label><input class="form-control" type="text" value="<c:out value='${record.note}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
