<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>My Responsibilities | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body><c:set var="activeMenu" value="responsibilities" scope="request"/>
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
                <div><h1>My Responsibility & Liability Records</h1>
                    <p>View Mentor investigation conclusions, findings and liability decisions</p></div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">IN</div>
                    <span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">LIABILITY</p>
                    <h2>My Responsibility Records (${responsibilities.size()})</h2></div>
            </div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/intern/responsibilities">
                <div class="filter-group"><input class="form-control" type="search" name="keyword"
                                                 value="<c:out value='${keyword}'/>"
                                                 placeholder="Search incident, asset or finding"
                                                 style="width:280px"><select class="form-control" name="status">
                    <option value="">All statuses</option>
                    <option value="CONFIRMED" ${selectedStatus == 'CONFIRMED' ? 'selected' : ''}>CONFIRMED</option>
                    <option value="PENDING_REVIEW" ${selectedStatus == 'PENDING_REVIEW' ? 'selected' : ''}>
                        PENDING_REVIEW
                    </option>
                    <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>APPROVED</option>
                    <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>REJECTED</option>
                    <option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>RESOLVED</option>
                </select>
                    <button class="primary-button">Search</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/intern/responsibilities">Reset</a>
                </div>
            </form>
            <article class="panel"><c:choose><c:when test="${empty responsibilities}">
                <div class="empty-box">
                    <div class="empty-box-icon">
                        <svg>
                            <use href="#i-list"/>
                        </svg>
                    </div>
                    <h3>No responsibility assigned to you</h3>
                    <p>Only responsibility records linked to your own Intern profile are visible here.</p></div>
            </c:when><c:otherwise>
                <div class="table-scroll">
                    <table>
                        <thead>
                        <tr>
                            <th>Resp Code</th>
                            <th>Incident ID</th>
                            <th>Asset</th>
                            <th>Mentor Finding</th>
                            <th>Severity</th>
                            <th>Action / Compensation</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:forEach var="r" items="${responsibilities}">
                            <tr>
                                <td><strong>#<c:out value="${r.responsibilityCode}"/></strong></td>
                                <td><c:out value="${r.incidentCode}"/></td>
                                <td><b><c:out value="${r.assetName}"/></b><br><small><c:out
                                        value="${r.assetCode}"/></small></td>
                                <td class="wrap-cell"><c:out value="${r.conclusion}"/></td>
                                <td><span class="severity ${r.incidentSeverity.toLowerCase()}"><c:out
                                        value="${r.incidentSeverity}"/></span></td>
                                <td class="wrap-cell"><c:out value="${r.decision}" default="—"/></td>
                                <td><span
                                        class="status ${r.status == 'RESOLVED' || r.status == 'CONFIRMED' || r.status == 'APPROVED' ? 'returned' : 'review'}"><c:out
                                        value="${r.status}"/></span></td>
                                <td><a class="btn-action btn-action-primary"
                                       href="${pageContext.request.contextPath}/intern/responsibilities/${r.responsibilityId}">View</a>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer"><span>Showing ${responsibilities.size()} responsibility record(s)</span>
                    <div class="pagination-controls">
                        <button class="page-btn" disabled>‹</button>
                        <button class="page-btn active" disabled>1</button>
                        <button class="page-btn" disabled>›</button>
                    </div>
                </div>
            </c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
