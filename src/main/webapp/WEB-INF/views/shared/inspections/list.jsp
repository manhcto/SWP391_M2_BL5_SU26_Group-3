<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Inspections | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="inspection-page">
<c:set var="activeMenu" value="inspections" scope="request"/>
<div class="app-shell">
    <c:choose>
        <c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when>
        <c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise>
    </c:choose>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Asset Inspections</h1><p>Manage LAB inspections and inventories</p></div></div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">${roleBase == '/mentor' ? 'ME' : 'LM'}</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow"><c:out value="${roleName}"/> workspace</p><h2>Inspection & inventory records (${inspections.size()})</h2></div><a class="primary-button" href="${pageContext.request.contextPath}${roleBase}/inspections/new">Create Inspection</a></div>
            <form class="filter-bar inspection-filter" method="get" action="${pageContext.request.contextPath}${roleBase}/inspections">
                <div class="filter-group">
                    <select class="form-control" name="semesterId">
                        <option value="">All semesters</option>
                        <c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${selectedSemesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> - <c:out value="${semester.name}"/></option></c:forEach>
                    </select>
                    <select class="form-control" name="type"><option value="">All types</option><option value="INSPECTION" ${selectedType == 'INSPECTION' ? 'selected' : ''}>INSPECTION</option><option value="INVENTORY" ${selectedType == 'INVENTORY' ? 'selected' : ''}>INVENTORY</option></select>
                    <select class="form-control" name="status"><option value="">All statuses</option><option value="DRAFT" ${selectedStatus == 'DRAFT' ? 'selected' : ''}>DRAFT</option><option value="COMPLETED" ${selectedStatus == 'COMPLETED' ? 'selected' : ''}>COMPLETED</option></select>
                    <select class="form-control" name="result"><option value="">All results</option><option value="NORMAL" ${selectedResult == 'NORMAL' ? 'selected' : ''}>NORMAL</option><option value="DISCREPANCY_FOUND" ${selectedResult == 'DISCREPANCY_FOUND' ? 'selected' : ''}>DISCREPANCY_FOUND</option></select>
                    <input class="form-control" type="date" name="fromDate" value="<c:out value='${fromDate}'/>">
                    <input class="form-control" type="date" name="toDate" value="<c:out value='${toDate}'/>">
                    <button class="primary-button" type="submit">Filter</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Reset</a>
                </div>
            </form>
            <article class="panel">
                <c:choose>
                    <c:when test="${empty inspections}"><div class="empty-box"><div class="empty-box-icon"><svg><use href="#i-inspect"/></svg></div><h3>No inspection records</h3><p>Create a draft inspection for the whole LAB or selected non-disposed assets.</p><a class="primary-button" href="${pageContext.request.contextPath}${roleBase}/inspections/new">Create Inspection</a></div></c:when>
                    <c:otherwise>
                        <div class="table-scroll inspection-table-scroll"><table class="inspection-table inspection-list-table"><thead><tr><th>Inspection ID</th><th>Type</th><th>Semester</th><th>Scope</th><th>Inspection date</th><th>Inspector</th><th>Status</th><th>Result</th><th>Actions</th></tr></thead><tbody>
                            <c:forEach var="inspection" items="${inspections}"><tr>
                                <td><strong>#INS-${inspection.inspectionId}</strong></td>
                                <td><span class="badge badge-blue"><c:out value="${inspection.inspectionType}"/></span></td>
                                <td><c:out value="${inspection.semesterCode}"/></td>
                                <td><c:out value="${inspection.scope}"/></td>
                                <td><c:out value="${inspection.inspectionDate}"/></td>
                                <td><span class="student"><i>${roleBase == '/mentor' ? 'ME' : 'LM'}</i><c:out value="${inspection.inspectorName}"/></span></td>
                                <td><span class="status ${inspection.status == 'COMPLETED' ? 'returned' : 'review'}"><c:out value="${inspection.status}"/></span></td>
                                <td><c:choose><c:when test="${empty inspection.result}">-</c:when><c:otherwise><span class="status ${inspection.result == 'NORMAL' ? 'returned' : 'open'}"><c:out value="${inspection.result}"/></span></c:otherwise></c:choose></td>
                                <td class="actions-cell"><a class="btn-action" href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}">View</a><c:if test="${inspection.status == 'DRAFT'}"><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}/edit">Edit</a></c:if></td>
                            </tr></c:forEach>
                        </tbody></table></div>
                        <div class="table-footer"><span>Showing ${inspections.size()} inspection record(s)</span><div class="pagination-controls"><button class="page-btn" disabled>‹</button><button class="page-btn active" disabled>1</button><button class="page-btn" disabled>›</button></div></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
