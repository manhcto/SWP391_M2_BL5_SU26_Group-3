<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fn" uri="jakarta.tags.functions"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lab Usage Requests | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body>
<div class="app-shell">
    <c:set var="activeMenu" value="labRequests"/>
    <%@ include file="../includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Lab Usage Requests</h1><p>Manage weekly lab access requests for your student groups</p></div></div>
            <div class="top-profile"><div class="avatar">MA</div><span><c:out value="${sessionScope.currentUser.fullName}"/></span></div>
        </header>
        <section class="request-page">
            <div class="page-title-row"><div><h2>My requests</h2><p>Only pending requests can be edited or deleted.</p></div><a class="primary-button" href="${pageContext.request.contextPath}/mentor/lab-requests/add"><svg><use href="#i-plus"/></svg>Add request</a></div>

            <c:if test="${param.deleted == '1'}"><div class="notice">Lab Usage Request deleted successfully.</div></c:if>
            <c:if test="${param.error == 'delete'}"><div class="notice error">Could not delete this request.</div></c:if>

            <div class="request-card">
                <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/lab-requests">
                    <input type="search" name="keyword" value="${fn:escapeXml(keyword)}" placeholder="Search group or semester..." aria-label="Search requests">
                    <select name="status" aria-label="Status">
                        <option value="">All statuses</option>
                        <option value="PENDING" ${selectedStatus == 'PENDING' ? 'selected' : ''}>Pending</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Approved</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Rejected</option>
                    </select>
                    <select name="semesterId" aria-label="Semester">
                        <option value="">All open semesters</option>
                        <c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${selectedSemesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> — <c:out value="${semester.name}"/></option></c:forEach>
                    </select>
                    <div class="filter-actions"><button class="secondary-button" type="submit">Filter</button><a class="secondary-button" href="${pageContext.request.contextPath}/mentor/lab-requests">Clear</a></div>
                </form>
                <c:choose>
                    <c:when test="${empty requests}"><div class="empty-state"><p>No Lab Usage Requests found.</p><a class="primary-button" href="${pageContext.request.contextPath}/mentor/lab-requests/add">Create first request</a></div></c:when>
                    <c:otherwise>
                        <div class="request-table-wrap"><table class="request-table"><thead><tr><th>ID</th><th>Group / Semester</th><th>Weekly schedule</th><th>Students</th><th>Submitted</th><th>Status</th><th>Actions</th></tr></thead><tbody>
                        <c:forEach var="labRequest" items="${requests}"><tr>
                            <td>#<c:out value="${labRequest.requestId}"/></td>
                            <td class="group-cell"><strong><c:out value="${labRequest.groupName}"/></strong><small><c:out value="${labRequest.semesterCode}"/> · <c:out value="${labRequest.semesterName}"/></small></td>
                            <td class="schedule-cell" title="${fn:escapeXml(labRequest.scheduleSummary)}"><c:out value="${labRequest.scheduleSummary}"/></td>
                            <td><c:out value="${labRequest.studentCount}"/></td>
                            <td><c:out value="${labRequest.createdAt}"/></td>
                            <td><span class="request-status status-${labRequest.status}"><c:out value="${labRequest.status}"/></span></td>
                            <td><div class="row-actions">
                                <a class="action-link" href="${pageContext.request.contextPath}/mentor/lab-requests/view?id=${labRequest.requestId}">View</a>
                                <c:if test="${labRequest.status == 'PENDING'}">
                                    <a class="action-link" href="${pageContext.request.contextPath}/mentor/lab-requests/edit?id=${labRequest.requestId}">Edit</a>
                                    <form method="post" action="${pageContext.request.contextPath}/mentor/lab-requests/delete" onsubmit="return confirm('Delete this pending request?');"><input type="hidden" name="csrfToken" value="${csrfToken}"><input type="hidden" name="id" value="${labRequest.requestId}"><button class="danger-button" type="submit">Delete</button></form>
                                </c:if>
                            </div></td>
                        </tr></c:forEach>
                        </tbody></table></div>
                    </c:otherwise>
                </c:choose>
            </div>
        </section>
    </main>
</div>
</body>
</html>
