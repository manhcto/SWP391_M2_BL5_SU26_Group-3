<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Disposal Requests | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="../../includes/operations-sidebar.jspf" %>
    <div class="workspace">
        <main class="content">
            <div class="page-heading">
                <div>
                    <h1>My Disposal Requests</h1>
                    <p>Request disposal for assets no longer safe or effective.</p>
                </div>
                <div class="actions">
                    <a class="button" href="${pageContext.request.contextPath}/mentor/dashboard">Dashboard</a>
                    <a class="button primary" href="${pageContext.request.contextPath}/mentor/disposals/new">Create
                        request</a>
                </div>
            </div>
            <form class="card filter-bar">
                <input name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Asset">
                <select name="status">
                    <option value="">All statuses</option>
                    <option value="PENDING" ${param.status == 'PENDING' ? 'selected' : ''}>PENDING</option>
                    <option value="APPROVED" ${param.status == 'APPROVED' ? 'selected' : ''}>APPROVED</option>
                    <option value="REJECTED" ${param.status == 'REJECTED' ? 'selected' : ''}>REJECTED</option>
                    <option value="COMPLETED" ${param.status == 'COMPLETED' ? 'selected' : ''}>COMPLETED</option>
                </select>
                <button>Filter</button>
            </form>
            <section class="card table-card">
                <table>
                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>Asset</th>
                        <th>Reason</th>
                        <th>Status</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <c:forEach items="${disposals}" var="d">
                        <tr>
                            <td>#DSP-${d.disposalId}</td>
                            <td><c:out value="${d.assetName}"/><c:if test="${not empty d.assetItemTag}"><br><small>Item: <c:out
                                    value="${d.assetItemTag}"/></small></c:if></td>
                            <td><c:out value="${d.reason}"/></td>
                            <td>${d.status}</td>
                            <td><a href="${pageContext.request.contextPath}/mentor/disposals/${d.disposalId}">View</a>
                            </td>
                        </tr>
                    </c:forEach>
                    </tbody>
                </table>
            </section>
        </main>
    </div>
</div>
</body>
</html>
