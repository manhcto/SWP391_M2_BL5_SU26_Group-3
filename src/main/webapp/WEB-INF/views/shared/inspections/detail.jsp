<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Inspection Detail | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="inspection-page">
<c:set var="activeMenu" value="inspections" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${roleBase == '/mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf"%></c:when><c:otherwise><%@ include file="../../labmanager/includes/sidebar.jspf"%></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Inspection #INS-${inspection.inspectionId}</h1><p>Review header information and inspected asset items</p></div></div><div class="topbar-actions"><div class="top-profile"><div class="avatar">${roleBase == '/mentor' ? 'ME' : 'LM'}</div><span><c:out value="${currentUser.fullName}"/></span></div></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow"><c:out value="${inspection.status}"/></p><h2><c:out value="${inspection.inspectionType}"/> detail</h2></div><div class="row-actions"><a class="btn-secondary" href="${pageContext.request.contextPath}${roleBase}/inspections">Back</a><c:if test="${inspection.status == 'DRAFT'}"><a class="primary-button" href="${pageContext.request.contextPath}${roleBase}/inspections/${inspection.inspectionId}/edit">Edit Draft</a></c:if></div></div>
            <article class="panel detail-panel"><div class="detail-grid compact-detail">
                <div class="detail-item"><dt>ID</dt><dd>#INS-${inspection.inspectionId}</dd></div>
                <div class="detail-item"><dt>Type</dt><dd><c:out value="${inspection.inspectionType}"/></dd></div>
                <div class="detail-item"><dt>Semester</dt><dd><c:out value="${inspection.semesterCode}"/> - <c:out value="${inspection.semesterName}"/></dd></div>
                <div class="detail-item"><dt>Scope</dt><dd><c:out value="${inspection.scope}"/></dd></div>
                <div class="detail-item"><dt>Inspector</dt><dd><c:out value="${inspection.inspectorName}"/></dd></div>
                <div class="detail-item"><dt>Inspection date</dt><dd><c:out value="${inspection.inspectionDate}"/></dd></div>
                <div class="detail-item"><dt>Status</dt><dd><span class="status ${inspection.status == 'COMPLETED' ? 'returned' : 'review'}"><c:out value="${inspection.status}"/></span></dd></div>
                <div class="detail-item"><dt>Result</dt><dd><c:choose><c:when test="${empty inspection.result}">-</c:when><c:otherwise><span class="status ${inspection.result == 'NORMAL' ? 'returned' : 'open'}"><c:out value="${inspection.result}"/></span></c:otherwise></c:choose></dd></div>
                <div class="detail-item wide"><dt>Note</dt><dd><c:out value="${inspection.note}" default="-"/></dd></div>
            </div></article>
            <h3 class="section-title">Inspection items</h3>
            <article class="panel"><div class="table-scroll inspection-table-scroll"><table class="inspection-table inspection-detail-table"><thead><tr><th>Asset code/name</th><th>Expected qty</th><th>Actual qty</th><th>Expected condition</th><th>Actual condition</th><th>Discrepancy type</th><th>Discrepancy note</th><th>Incident</th></tr></thead><tbody>
                <c:forEach var="item" items="${items}"><tr>
                    <td class="asset-cell"><strong><c:out value="${item.assetCode}"/></strong><small><c:out value="${item.assetName}"/></small></td>
                    <td><c:out value="${item.expectedQuantity}"/></td><td><c:out value="${item.actualQuantity}"/></td>
                    <td><c:out value="${item.expectedCondition}" default="-"/></td><td><c:out value="${item.actualCondition}" default="-"/></td>
                    <td><c:out value="${item.discrepancyType}" default="-"/></td><td class="wrap-cell"><c:out value="${item.discrepancyNote}" default="-"/></td>
                    <td><c:if test="${inspection.status == 'COMPLETED' && item.abnormal}"><a class="btn-action" href="#">Report Incident</a></c:if></td>
                </tr></c:forEach>
            </tbody></table></div></article>
        </section>
    </main>
</div>
</body>
</html>
