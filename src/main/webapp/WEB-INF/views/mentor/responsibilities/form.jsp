<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${empty responsibility.responsibilityId ? 'Add' : 'Edit'} Responsibility | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
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
                <div><h1>${empty responsibility.responsibilityId ? 'Add Responsibility' : 'Edit Responsibility'}</h1>
                    <p>Record the investigation conclusion and handling recommendation</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary"
                                           href="${pageContext.request.contextPath}/mentor/responsibilities">‹ Back to
                Responsibilities</a></div>
        </header>
        <section class="content-area"><c:if test="${not empty message}">
            <div class="error-message"><c:out value="${message}"/></div>
        </c:if>
            <c:if test="${empty responsibility.responsibilityId && empty incidents}">
                <article class="panel">
                    <div class="empty-box">
                        <div class="empty-box-icon">
                            <svg>
                                <use href="#i-alert"/>
                            </svg>
                        </div>
                        <h3>No eligible incident</h3>
                        <p>A responsibility requires an incident linked to an Intern's asset usage and cannot duplicate
                            an existing responsibility.</p><a class="btn-secondary"
                                                              href="${pageContext.request.contextPath}/mentor/responsibilities">Back</a>
                    </div>
                </article>
            </c:if>
            <c:if test="${not empty responsibility.responsibilityId || not empty incidents}">
                <article class="panel">
                    <form class="form-grid" method="post"
                          action="${pageContext.request.contextPath}/mentor/responsibilities">
                        <input type="hidden" name="action"
                               value="${empty responsibility.responsibilityId ? 'create' : 'update'}"><c:if
                            test="${not empty responsibility.responsibilityId}"><input type="hidden"
                                                                                       name="responsibilityId"
                                                                                       value="${responsibility.responsibilityId}"></c:if>
                        <div class="form-group full-width"><label>Related Incident / Intern / Asset Usage *</label>
                            <c:choose><c:when test="${empty responsibility.responsibilityId}"><select
                                    class="form-control" name="incidentId" required>
                                <option value="">Select an investigated incident</option>
                                <c:forEach var="i" items="${incidents}">
                                    <option value="${i.incidentId}" ${responsibility.incidentId == i.incidentId ? 'selected' : ''}>
                                        <c:out value="${i.incidentCode}"/> · <c:out value="${i.assetName}"/> · <c:out
                                            value="${i.internName}"/> (<c:out value="${i.internCode}"/>) · <c:out
                                            value="${i.incidentSeverity}"/></option>
                                </c:forEach></select></c:when>
                                <c:otherwise><input class="form-control readonly-field"
                                                    value="<c:out value='${responsibility.incidentCode}'/> · <c:out value='${responsibility.assetName}'/> · <c:out value='${responsibility.internName}'/>"
                                                    readonly></c:otherwise></c:choose>
                            <small>The Intern is derived from the asset usage linked to the incident.</small>
                        </div>
                        <div class="form-group full-width"><label>Mentor Finding *</label><textarea class="form-control"
                                                                                                    name="conclusion"
                                                                                                    rows="5" required
                                                                                                    placeholder="Investigation conclusion and responsibility finding"><c:out
                                value="${responsibility.conclusion}"/></textarea></div>
                        <div class="form-group full-width"><label>Recommendation / Action /
                            Compensation</label><textarea class="form-control" name="decision" rows="4"
                                                          placeholder="Waiver reason, replacement, penalty or compensation recommendation"><c:out
                                value="${responsibility.decision}"/></textarea></div>
                        <div class="form-group"><label>Status *</label><select class="form-control" name="status"
                                                                               required>
                            <option value="CONFIRMED" ${empty responsibility.status || responsibility.status == 'CONFIRMED' ? 'selected' : ''}>
                                CONFIRMED
                            </option>
                            <option value="PENDING_REVIEW" ${responsibility.status == 'PENDING_REVIEW' ? 'selected' : ''}>
                                PENDING_REVIEW
                            </option>
                            <option value="RESOLVED" ${responsibility.status == 'RESOLVED' ? 'selected' : ''}>RESOLVED
                            </option>
                        </select></div>
                        <div class="form-group"><label>Resolution Note</label><input class="form-control"
                                                                                     name="resolutionNote"
                                                                                     value="<c:out value='${responsibility.resolutionNote}'/>"
                                                                                     placeholder="Final handling result, if available">
                        </div>
                        <div class="form-group full-width form-actions">
                            <button class="primary-button"
                                    type="submit">${empty responsibility.responsibilityId ? 'Create Responsibility' : 'Save Changes'}</button>
                            <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">Cancel</a>
                        </div>
                    </form>
                </article>
            </c:if></section>
    </main>
</div>
</body>
</html>
