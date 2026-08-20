<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Supervised Asset Usage</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="../../includes/operations-sidebar.jspf"%>
    <div class="workspace">
<main class="content">
    <div class="page-heading">
        <div>
            <h1>Supervised Asset Usage</h1>
            <p>Usage records for interns in your approved lists.</p>
        </div>
        <a class="button" href="${pageContext.request.contextPath}/mentor/dashboard">Dashboard</a>
    </div>
    <form class="card filter-bar">
        <input name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Intern or asset">
        <select name="status">
            <option value="">All statuses</option>
            <option value="IN_USE" ${param.status == 'IN_USE' ? 'selected' : ''}>In use</option>
            <option value="RETURNED" ${param.status == 'RETURNED' ? 'selected' : ''}>Returned</option>
        </select>
        <input type="date" name="fromDate" value="<c:out value='${param.fromDate}'/>" aria-label="Borrowed from">
        <input type="date" name="toDate" value="<c:out value='${param.toDate}'/>" aria-label="Borrowed to">
        <button class="button primary" type="submit">Filter</button>
        <a class="button" href="${pageContext.request.contextPath}/mentor/usages">Reset</a>
    </form>
    <section class="card table-card">
        <table>
            <thead>
            <tr>
                <th>Intern</th>
                <th>Asset</th>
                <th>Borrowed</th>
                <th>Status</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <c:forEach items="${usages}" var="u">
                <tr>
                    <td><c:out value="${u.internName}"/></td>
                    <td><c:out value="${u.assetName}"/><c:if test="${not empty u.assetItemTag}"><br><small>Item: <c:out value="${u.assetItemTag}"/></small></c:if></td>
                    <td>${u.borrowedAt}</td>
                    <td>${u.status}</td>
                    <td><a href="${pageContext.request.contextPath}/mentor/usages/${u.assetUsageId}">View</a></td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
        <c:if test="${empty usages}"><div class="empty-state">No supervised usage records match this filter.</div></c:if>
    </section>
</main>
    </div>
</div>
</body>
</html>
