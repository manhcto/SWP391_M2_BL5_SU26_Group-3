<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Usage #${usage.assetUsageId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Asset Usage Details</h1><p>Read-only borrowing transaction</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/usages">Back to usage</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">USAGE #AU-${usage.assetUsageId}</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'IN_USE' ? 'in-use' : 'returned'}"><c:out value="${usage.status}"/></span></div>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Asset code</dt><dd><c:out value="${usage.assetCode}"/></dd></div><div class="detail-item"><dt>Intern</dt><dd><c:out value="${usage.studentName}"/></dd></div><div class="detail-item"><dt>Quantity</dt><dd><c:out value="${usage.quantity}"/></dd></div><div class="detail-item"><dt>Borrowed at</dt><dd><c:out value="${usage.borrowedAt}"/></dd></div><div class="detail-item"><dt>Due at</dt><dd><c:out value="${usage.dueAt}"/></dd></div><div class="detail-item"><dt>Returned at</dt><dd>${empty usage.returnedAt ? 'Not returned' : usage.returnedAt}</dd></div><div class="detail-item"><dt>Condition before</dt><dd><c:out value="${usage.conditionBefore}"/></dd></div><div class="detail-item"><dt>Condition after</dt><dd>${empty usage.conditionAfter ? 'Pending return' : usage.conditionAfter}</dd></div><div class="detail-item"><dt>Approved request</dt><dd>#REQ-${usage.requestId}</dd></div><div class="detail-item wide"><dt>Note</dt><dd><c:out value="${empty usage.note ? 'No note recorded.' : usage.note}"/></dd></div></dl>
        </section>
    </main>
</div>
</body>
</html>
