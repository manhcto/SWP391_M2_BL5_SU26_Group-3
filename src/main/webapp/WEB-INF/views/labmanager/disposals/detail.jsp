<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Disposal #${disposal.disposalId} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="disposals" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Disposal Details</h1><p>Asset lifecycle and retirement record</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/disposals">Back to disposal</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">DISPOSAL #DSP-${disposal.disposalId}</p><h2><c:out value="${disposal.assetName}"/></h2></div><span class="status ${disposal.status == 'PENDING' ? 'review' : disposal.status == 'COMPLETED' ? 'returned' : 'open'}"><c:out value="${disposal.status}"/></span></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <dl class="panel detail-grid"><div class="detail-item"><dt>Asset code</dt><dd><c:out value="${disposal.assetCode}"/></dd></div><div class="detail-item"><dt>Quantity retired</dt><dd><c:out value="${disposal.quantity}"/></dd></div><div class="detail-item"><dt>Requested by</dt><dd><c:out value="${disposal.requesterName}"/></dd></div><div class="detail-item"><dt>Requested at</dt><dd><c:out value="${disposal.requestedAt}"/></dd></div><div class="detail-item"><dt>Completed at</dt><dd>${empty disposal.completedAt ? 'Not completed' : disposal.completedAt}</dd></div><div class="detail-item wide"><dt>Reason</dt><dd><c:out value="${disposal.reason}"/></dd></div><div class="detail-item wide"><dt>Process note</dt><dd><c:out value="${empty disposal.completionNote ? 'No process note.' : disposal.completionNote}"/></dd></div></dl>
            <c:if test="${disposal.status == 'PENDING'}"><div class="detail-columns"><article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-trash"/></svg></span><h3>Update reason</h3></div></header><form method="post" action="${pageContext.request.contextPath}/lab-manager/disposals"><input type="hidden" name="action" value="update"><input type="hidden" name="disposalId" value="${disposal.disposalId}"><div class="form-grid"><div class="form-group full-width"><label for="reason">Disposal reason</label><textarea class="form-control" id="reason" name="reason" required><c:out value="${disposal.reason}"/></textarea></div><div class="form-group full-width form-actions"><button class="primary-button" type="submit">Save reason</button></div></div></form></article><article class="panel"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-list"/></svg></span><h3>Finish process</h3></div></header><form method="post" action="${pageContext.request.contextPath}/lab-manager/disposals"><input type="hidden" name="disposalId" value="${disposal.disposalId}"><div class="form-grid"><div class="form-group full-width"><label for="note">Process note</label><textarea class="form-control" id="note" name="note" placeholder="Completion evidence or cancellation reason"></textarea></div><div class="form-group full-width form-actions"><button class="btn-danger" name="action" value="cancel">Cancel process</button><button class="primary-button" name="action" value="complete">Complete disposal</button></div></div></form></article></div></c:if>
        </section>
    </main>
</div>
</body>
</html>
