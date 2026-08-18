<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Usage #${usage.assetUsageId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Asset Usage Details</h1><p>Review borrowing information and return status</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Back to history</a></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">INTERN PORTAL</p><h2><c:out value="${usage.assetName}"/></h2></div><span class="status ${usage.status == 'RETURNED' ? 'returned' : 'in-use'}"><c:out value="${usage.status}"/></span></div>
            <dl class="panel detail-grid">
                <div class="detail-item"><dt>Asset code</dt><dd><c:out value="${usage.assetCode}"/></dd></div>
                <div class="detail-item"><dt>Quantity</dt><dd><c:out value="${usage.quantity}"/></dd></div>
                <div class="detail-item"><dt>Status</dt><dd><c:out value="${usage.status}"/></dd></div>
                <div class="detail-item"><dt>Borrowed at</dt><dd><c:out value="${usage.borrowedAt}"/></dd></div>
                <div class="detail-item"><dt>Due at</dt><dd><c:out value="${usage.dueAt}"/></dd></div>
            </dl>
            <c:if test="${usage.status == 'IN_USE'}">
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Return this asset</h3></div></header>
                    <form method="post" action="${pageContext.request.contextPath}/intern/usages">
                        <input type="hidden" name="action" value="return"><input type="hidden" name="usageId" value="${usage.assetUsageId}">
                        <div class="form-grid">
                            <div class="form-group"><label for="conditionAfter">Condition after use</label><select class="form-control" id="conditionAfter" name="conditionAfter" required><option>GOOD</option><option>FAIR</option><option>DAMAGED</option><option>BROKEN</option></select></div>
                            <div class="form-group full-width"><label for="note">Return note</label><textarea class="form-control" id="note" name="note"></textarea></div>
                            <div class="form-group full-width form-actions"><button class="primary-button" type="submit">Confirm return</button></div>
                        </div>
                    </form>
                </article>
            </c:if>
        </section>
    </main>
</div>
</body>
</html>
