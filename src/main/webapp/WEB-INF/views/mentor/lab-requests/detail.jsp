<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Request #${labRequest.requestId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body>
<div class="app-shell">
    <c:set var="activeMenu" value="labRequests"/>
    <%@ include file="../includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Request #<c:out value="${labRequest.requestId}"/></h1><p>Review request information, schedule and students</p></div></div></header>
        <section class="request-page">
            <div class="page-title-row"><div><h2><c:out value="${labRequest.groupName}"/></h2><p><c:out value="${labRequest.semesterCode}"/> — <c:out value="${labRequest.semesterName}"/></p></div><div class="row-actions"><a class="secondary-button" href="${pageContext.request.contextPath}/mentor/lab-requests">Back</a><c:if test="${labRequest.status == 'PENDING'}"><a class="primary-button" href="${pageContext.request.contextPath}/mentor/lab-requests/edit?id=${labRequest.requestId}">Edit request</a></c:if></div></div>
            <c:if test="${param.created == '1'}"><div class="notice">Lab Usage Request submitted successfully.</div></c:if>
            <c:if test="${param.updated == '1'}"><div class="notice">Lab Usage Request updated successfully.</div></c:if>
            <div class="detail-grid">
                <div class="detail-item"><span>Status</span><strong><span class="request-status status-${labRequest.status}"><c:out value="${labRequest.status}"/></span></strong></div>
                <div class="detail-item"><span>Semester</span><strong><c:out value="${labRequest.semesterCode}"/></strong></div>
                <div class="detail-item"><span>Students</span><strong><c:out value="${labRequest.studentCount}"/></strong></div>
                <div class="detail-item"><span>Submitted</span><strong><c:out value="${labRequest.createdAt}"/></strong></div>
            </div>

            <section class="request-card detail-section"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Weekly schedule</h3></div></header><div class="request-table-wrap"><table class="detail-table weekly-schedule-table"><thead><tr><th>Day</th><th>Slots</th></tr></thead><tbody><c:forEach begin="2" end="7" var="day"><c:set var="hasSlot" value="false"/><c:forEach var="slot" items="${labRequest.slots}"><c:if test="${slot.dayOfWeek == day}"><c:set var="hasSlot" value="true"/></c:if></c:forEach><c:if test="${hasSlot}"><tr><td class="schedule-day">Thứ <c:out value="${day}"/></td><td><div class="weekly-slots"><c:forEach var="slot" items="${labRequest.slots}"><c:if test="${slot.dayOfWeek == day}"><span class="weekly-slot"><strong>Slot <c:out value="${slot.slotId}"/></strong><span><c:out value="${slot.timeLabel}"/></span></span></c:if></c:forEach></div></td></tr></c:if></c:forEach></tbody></table></div></section>
            <section class="request-card detail-section"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Student access list</h3></div></header><div class="request-table-wrap"><table class="detail-table"><thead><tr><th>#</th><th>Student code</th><th>Full name</th><th>Google email</th></tr></thead><tbody><c:forEach var="student" items="${labRequest.students}" varStatus="loop"><tr><td>${loop.count}</td><td><c:out value="${student.studentCode}"/></td><td><c:out value="${student.fullName}"/></td><td><c:out value="${student.email}"/></td></tr></c:forEach></tbody></table></div></section>
            <div class="approval-note"><h3>Request note</h3><p><c:out value="${labRequest.requestNote}" default="No note provided."/></p></div>
            <c:if test="${labRequest.status != 'PENDING'}"><div class="approval-note"><h3>Admin decision note</h3><p><c:out value="${labRequest.approvalNote}" default="No decision note provided."/></p></div></c:if>
        </section>
    </main>
</div>
</body>
</html>
