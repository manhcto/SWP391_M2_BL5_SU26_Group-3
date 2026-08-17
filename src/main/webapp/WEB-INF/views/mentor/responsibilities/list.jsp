<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Responsibilities | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Open navigation">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Intern Responsibility Assessment</h1>
                    <p>Manage investigation findings, waivers and compensation recommendations</p></div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">ME</div>
                    <span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">ASSESSMENT</p>
                    <h2>Liability & Findings Records (${responsibilities.size()})</h2></div>
                <a class="primary-button" href="${pageContext.request.contextPath}/mentor/responsibilities/new">+ Add
                    Responsibility</a></div>
            <c:if test="${param.success == 'deleted'}">
                <div class="success-message">Responsibility deleted successfully.</div>
            </c:if>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/mentor/responsibilities">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>"
                           placeholder="Search code, incident, intern or asset" style="width:280px">
                    <select class="form-control" name="status">
                        <option value="">All statuses</option>
                        <option value="CONFIRMED" ${selectedStatus == 'CONFIRMED' ? 'selected' : ''}>CONFIRMED</option>
                        <option value="PENDING_REVIEW" ${selectedStatus == 'PENDING_REVIEW' ? 'selected' : ''}>
                            PENDING_REVIEW
                        </option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>APPROVED</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>REJECTED</option>
                        <option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>RESOLVED</option>
                    </select>
                    <button class="primary-button" type="submit">Search</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">Reset</a>
                </div>
            </form>
            <article class="panel">
                <c:choose><c:when test="${empty responsibilities}">
                    <div class="empty-box">
                        <div class="empty-box-icon">
                            <svg>
                                <use href="#i-list"/>
                            </svg>
                        </div>
                        <h3>No responsibility records</h3>
                        <p>Create a record after an incident has been investigated and linked to an Intern's asset
                            usage.</p><a class="primary-button"
                                         href="${pageContext.request.contextPath}/mentor/responsibilities/new">+ Add
                        Responsibility</a></div>
                </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Resp ID</th>
                                    <th>Incident Ref</th>
                                    <th>Intern Involved</th>
                                    <th>Mentor Finding</th>
                                    <th>Recommendation</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="r" items="${responsibilities}">
                                    <tr>
                                        <td><strong>#<c:out value="${r.responsibilityCode}"/></strong></td>
                                        <td><c:out value="${r.incidentCode}"/></td>
                                        <td><span class="student"><i>IN</i><c:out
                                                value="${r.internName}"/></span><small><c:out
                                                value="${r.internCode}"/></small></td>
                                        <td class="wrap-cell"><c:out value="${r.conclusion}"/></td>
                                        <td class="wrap-cell"><c:out value="${r.decision}" default="—"/></td>
                                        <td><span
                                                class="status ${r.status == 'RESOLVED' || r.status == 'CONFIRMED' || r.status == 'APPROVED' ? 'returned' : 'review'}"><c:out
                                                value="${r.status}"/></span></td>
                                        <td class="actions-cell"><a class="btn-action"
                                                                    href="${pageContext.request.contextPath}/mentor/responsibilities/${r.responsibilityId}">View</a><a
                                                class="btn-action btn-action-primary"
                                                href="${pageContext.request.contextPath}/mentor/responsibilities/${r.responsibilityId}/edit">Edit</a>
                                            <form class="inline-form" method="post"
                                                  action="${pageContext.request.contextPath}/mentor/responsibilities"
                                                  onsubmit="return confirm('Delete this responsibility record?')"><input
                                                    type="hidden" name="action" value="delete"><input type="hidden"
                                                                                                      name="responsibilityId"
                                                                                                      value="${r.responsibilityId}">
                                                <button class="btn-action btn-action-danger" type="submit">Delete
                                                </button>
                                            </form>
                                        </td>
                                    </tr>
                                </c:forEach></tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <span>Showing ${responsibilities.size()} responsibility record(s)</span>
                            <div class="pagination-controls">
                                <button class="page-btn" disabled>‹</button>
                                <button class="page-btn active" disabled>1</button>
                                <button class="page-btn" disabled>›</button>
                            </div>
                        </div>
                    </c:otherwise></c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
