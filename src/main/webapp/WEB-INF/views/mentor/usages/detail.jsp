<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Asset Usage Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="../../includes/operations-sidebar.jspf"%>
    <div class="workspace">
<main class="content">
    <div class="page-heading">
        <h1><c:out value="${usage.assetName}"/></h1>
        <a class="button" href="${pageContext.request.contextPath}/mentor/usages">Back</a>
    </div>
    <dl class="card detail-grid">
        <div>
            <dt>Intern</dt>
            <dd><c:out value="${usage.internName}"/></dd>
        </div>
        <div>
            <dt>Quantity</dt>
            <dd>${usage.quantity}</dd>
        </div>
        <c:if test="${not empty usage.assetItemTag}">
            <div>
                <dt>Item</dt>
                <dd><c:out value="${usage.assetItemTag}"/></dd>
            </div>
        </c:if>
        <div>
            <dt>Borrowed</dt>
            <dd>${usage.borrowedAt}</dd>
        </div>
        <div>
            <dt>Due</dt>
            <dd>${usage.dueAt}</dd>
        </div>
        <div>
            <dt>Status</dt>
            <dd>${usage.status}</dd>
        </div>
        <div>
            <dt>Returned</dt>
            <dd>${usage.returnedAt}</dd>
        </div>
        <div>
            <dt>Condition before</dt>
            <dd>${usage.conditionBefore}</dd>
        </div>
        <div>
            <dt>Condition after</dt>
            <dd>${usage.conditionAfter}</dd>
        </div>
        <div>
            <dt>Usage note</dt>
            <dd><c:out value="${usage.note}"/></dd>
        </div>
        <div>
            <dt>Return note</dt>
            <dd><c:out value="${usage.returnNote}"/></dd>
        </div>
    </dl>
</main>
    </div>
</div>
</body>
</html>
