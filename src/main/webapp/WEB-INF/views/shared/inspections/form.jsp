<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Inspection Form | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="inspection-page">
<c:set var="activeMenu" value="inspections" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when><c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>${empty inspection.inspectionId ? 'Create Inspection' : 'Edit Inspection Draft'}</h1><p>Inspect the whole LAB or selected non-disposed assets</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">${roleBase == '/mentor' ? 'ME' : 'LM'}</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">DRAFT WORKFLOW</p><h2>${empty inspection.inspectionId ? 'New inspection record' : 'Update inspection record'}</h2></div><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Cancel</a></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <form class="inspection-form" method="post" action="${pageContext.request.contextPath}${roleBase}/inspections">
                <input type="hidden" name="inspectionId" value="<c:out value='${inspection.inspectionId}'/>">
                <article class="panel inspection-form-panel">
                    <div class="form-grid">
                        <div class="form-group"><label for="semesterId">Semester</label><select class="form-control" id="semesterId" name="semesterId" required><option value="">Select semester</option><c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${inspection.semesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> - <c:out value="${semester.name}"/></option></c:forEach></select></div>
                        <div class="form-group"><label for="inspectionType">Inspection Type</label><select class="form-control" id="inspectionType" name="inspectionType" required><option value="INSPECTION" ${inspection.inspectionType == 'INSPECTION' ? 'selected' : ''}>INSPECTION</option><option value="INVENTORY" ${inspection.inspectionType == 'INVENTORY' ? 'selected' : ''}>INVENTORY</option></select></div>
                        <div class="form-group"><label for="scope">Scope</label><select class="form-control" id="scope" name="scope" required><option value="WHOLE_LAB" ${inspection.scope == 'WHOLE_LAB' || empty inspection.scope ? 'selected' : ''}>WHOLE_LAB</option><option value="SELECTED_ASSETS" ${inspection.scope == 'SELECTED_ASSETS' ? 'selected' : ''}>SELECTED_ASSETS</option></select></div>
                        <div class="form-group"><label for="inspectionDate">Inspection Date</label><input class="form-control" id="inspectionDate" type="datetime-local" name="inspectionDate" value="${inspection.inspectionDate}" required></div>
                        <div class="form-group full-width"><label for="note">Note</label><textarea class="form-control" id="note" name="note" placeholder="Optional inspection note"><c:out value="${inspection.note}"/></textarea></div>
                    </div>
                </article>
                <article class="panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-inspect"/></svg></span><h3>Inspection items</h3></div><span class="hint">For selected-assets scope, tick one or more assets.</span></header>
                    <div class="table-scroll inspection-form-scroll"><table class="inspection-table inspection-item-table"><thead><tr><th>Select</th><th>Asset</th><th>Expected qty</th><th>Actual qty</th><th>Expected condition</th><th>Actual condition</th><th>Discrepancy type</th><th>Discrepancy note</th></tr></thead><tbody>
                        <c:forEach var="asset" items="${assets}">
                            <c:set var="item" value="${itemByAsset[asset.assetId]}"/>
                            <c:set var="checked" value="${inspection.scope == 'WHOLE_LAB' || not empty item}"/>
                            <tr>
                                <td><input class="asset-check" type="checkbox" name="selectedAssetId" value="${asset.assetId}" ${checked ? 'checked' : ''}><input type="hidden" name="assetId" value="${asset.assetId}"></td>
                                <td class="asset-cell"><strong><c:out value="${asset.assetCode}"/></strong><small><c:out value="${asset.assetName}"/> · <c:out value="${asset.status}"/></small></td>
                                <td><input class="form-control compact-input" type="number" min="0" name="expectedQuantity_${asset.assetId}" value="${empty item ? asset.totalQuantity : item.expectedQuantity}"></td>
                                <td><input class="form-control compact-input" type="number" min="0" name="actualQuantity_${asset.assetId}" value="${empty item ? asset.totalQuantity : item.actualQuantity}"></td>
                                <td><select class="form-control" name="expectedCondition_${asset.assetId}"><option value="">-</option><option value="GOOD" ${(empty item && asset.condition == 'GOOD') || item.expectedCondition == 'GOOD' ? 'selected' : ''}>GOOD</option><option value="FAIR" ${(empty item && asset.condition == 'FAIR') || item.expectedCondition == 'FAIR' ? 'selected' : ''}>FAIR</option><option value="DAMAGED" ${(empty item && asset.condition == 'DAMAGED') || item.expectedCondition == 'DAMAGED' ? 'selected' : ''}>DAMAGED</option><option value="BROKEN" ${(empty item && asset.condition == 'BROKEN') || item.expectedCondition == 'BROKEN' ? 'selected' : ''}>BROKEN</option></select></td>
                                <td><select class="form-control" name="actualCondition_${asset.assetId}"><option value="">-</option><option value="GOOD" ${(empty item && asset.condition == 'GOOD') || item.actualCondition == 'GOOD' ? 'selected' : ''}>GOOD</option><option value="FAIR" ${(empty item && asset.condition == 'FAIR') || item.actualCondition == 'FAIR' ? 'selected' : ''}>FAIR</option><option value="DAMAGED" ${(empty item && asset.condition == 'DAMAGED') || item.actualCondition == 'DAMAGED' ? 'selected' : ''}>DAMAGED</option><option value="BROKEN" ${(empty item && asset.condition == 'BROKEN') || item.actualCondition == 'BROKEN' ? 'selected' : ''}>BROKEN</option></select></td>
                                <td><input class="form-control" name="discrepancyType_${asset.assetId}" value="<c:out value='${item.discrepancyType}'/>" placeholder="Missing, damaged..."></td>
                                <td><input class="form-control" name="discrepancyNote_${asset.assetId}" value="<c:out value='${item.discrepancyNote}'/>" placeholder="Optional note"></td>
                            </tr>
                        </c:forEach>
                    </tbody></table></div>
                    <div class="table-footer"><span>Disposed assets are excluded.</span><div class="actions"><button class="btn-secondary" type="submit" name="action" value="draft">Save Draft</button><button class="primary-button" type="submit" name="action" value="complete">Complete Inspection</button><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Cancel</a></div></div>
                </article>
            </form>
        </section>
    </main>
</div>
</body>
</html>
