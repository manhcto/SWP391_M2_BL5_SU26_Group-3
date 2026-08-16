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
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

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
