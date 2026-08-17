<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Maintenance Ticket Details | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Ticket Details: <c:out value="${record.assetName}"/></h1><p>Proposal tracking and resolution status</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Back to Proposals</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <div class="form-grid">
                    <div class="form-group"><label>Ticket ID</label><input class="form-control" type="text" value="#MNT-${record.maintenanceId}" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Asset Details</label><input class="form-control" type="text" value="<c:out value='${record.assetName}'/> (<c:out value='${record.assetCode}'/>)" readonly style="background:#f4f6f4; font-weight:700;"></div>
                    <div class="form-group"><label>Submitted Date</label><input class="form-control" type="text" value="<c:out value='${record.requestedAt}'/>" readonly style="background:#f4f6f4;"></div>
                    <div class="form-group"><label>Current Progress Status</label><input class="form-control" type="text" value="<c:out value='${record.status}'/>" readonly style="background:#f4f6f4; font-weight:700; color:#188255;"></div>
                    <div class="form-group full-width"><label>Reported Issue Description</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.description}"/></textarea></div>
                    <div class="form-group"><label>Approved By</label><input class="form-control" type="text" value="<c:out value='${record.approverName}' default='Pending review by Lab Manager'/>" readonly style="background:#f4f6f4;"></div>
                    <c:if test="${not empty record.approvalNote}">
                        <div class="form-group"><label>Manager Approval Note</label><input class="form-control" type="text" value="<c:out value='${record.approvalNote}'/>" readonly style="background:#f4f6f4;"></div>
                    </c:if>
                    <c:if test="${not empty record.repairResult}">
                        <div class="form-group full-width"><label>Repair Outcome & Findings</label><textarea class="form-control" readonly style="background:#f4f6f4;"><c:out value="${record.repairResult}"/></textarea></div>
                    </c:if>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
