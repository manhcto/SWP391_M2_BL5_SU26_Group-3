<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Borrow Asset | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="borrow" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Borrow an Asset</h1><p>Request equipment for your approved internship semester</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">INTERN PORTAL</p><h2>New Borrowing Request</h2></div><a class="btn-secondary" href="${pageContext.request.contextPath}/intern/usages">Back to history</a></div>
            <c:if test="${not empty message}"><p class="error-message"><c:out value="${message}"/></p></c:if>
            <article class="panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-box"/></svg></span><h3>Asset information</h3></div></header>
                <form method="post">
                    <input type="hidden" name="action" value="borrow">
                    <div class="form-grid">
                        <div class="form-group full-width"><label for="assetId">Asset</label><select class="form-control" id="assetId" name="assetId" required><c:forEach items="${assets}" var="a"><option value="${a.assetId}"><c:out value="${a.assetCode}"/> · <c:out value="${a.assetName}"/> · ${a.totalQuantity} total</option></c:forEach></select></div>
                        <div class="form-group"><label for="quantity">Quantity</label><input class="form-control" id="quantity" type="number" name="quantity" min="1" value="1" required></div>
                        <div class="form-group"><label>Due time</label><input class="form-control readonly-field" value="End of approved semester" readonly></div>
                        <div class="form-group full-width"><label for="note">Usage note</label><textarea class="form-control" id="note" name="note" placeholder="Purpose or handling note"></textarea></div>
                        <div class="form-group full-width form-actions"><button class="primary-button" type="submit" <c:if test="${empty assets}">disabled</c:if>><svg><use href="#i-box"/></svg>Confirm borrow</button></div>
                    </div>
                </form>
                <c:if test="${empty assets}"><div class="empty-box"><p>No eligible assets are available.</p></div></c:if>
            </article>
        </section>
    </main>
</div>
</body>
</html>
