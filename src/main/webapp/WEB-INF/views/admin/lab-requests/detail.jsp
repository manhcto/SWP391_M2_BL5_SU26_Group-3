<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Review Request #${labRequest.requestId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body>
<c:set var="activeMenu" value="labRequests" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Review Request #<c:out value="${labRequest.requestId}"/></h1><p>Approve the complete schedule and student list</p></div></div></header>
        <section class="request-page">
            <div class="page-title-row"><div><h2><c:out value="${labRequest.groupName}"/></h2><p>Submitted by <c:out value="${labRequest.mentorName}"/> · <c:out value="${labRequest.mentorEmail}"/></p></div><a class="secondary-button" href="${pageContext.request.contextPath}/admin/lab-requests">Back to queue</a></div>

            <c:if test="${param.decided == 'APPROVED'}"><div class="notice">Request approved. Student accounts are now available in Manage Users.</div></c:if>
            <c:if test="${param.decided == 'REJECTED'}"><div class="notice">Request rejected. No student account was added.</div></c:if>
            <c:if test="${not empty decisionError}"><div class="notice error"><c:out value="${decisionError}"/></div></c:if>

            <div class="detail-grid">
                <div class="detail-item"><span>Status</span><strong><span class="request-status status-${labRequest.status}"><c:out value="${labRequest.status}"/></span></strong></div>
                <div class="detail-item"><span>Semester</span><strong><c:out value="${labRequest.semesterCode}"/></strong></div>
                <div class="detail-item"><span>Students</span><strong><c:out value="${labRequest.studentCount}"/></strong></div>
                <div class="detail-item"><span>Submitted</span><strong><c:out value="${labRequest.createdAt}"/></strong></div>
            </div>

            <section class="request-card detail-section"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Weekly schedule</h3></div></header><div class="request-table-wrap"><table class="detail-table weekly-schedule-table"><thead><tr><th>Day</th><th>Slots</th></tr></thead><tbody><c:forEach begin="2" end="7" var="day"><c:set var="hasSlot" value="false"/><c:forEach var="slot" items="${labRequest.slots}"><c:if test="${slot.dayOfWeek == day}"><c:set var="hasSlot" value="true"/></c:if></c:forEach><c:if test="${hasSlot}"><tr><td class="schedule-day">Thứ <c:out value="${day}"/></td><td><div class="weekly-slots"><c:forEach var="slot" items="${labRequest.slots}"><c:if test="${slot.dayOfWeek == day}"><span class="weekly-slot"><strong>Slot <c:out value="${slot.slotId}"/></strong><span><c:out value="${slot.timeLabel}"/></span></span></c:if></c:forEach></div></td></tr></c:if></c:forEach></tbody></table></div></section>

            <section class="request-card detail-section"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Student access list</h3></div></header><div class="request-table-wrap"><table class="detail-table"><thead><tr><th>#</th><th>Student code</th><th>Full name</th><th>Google email</th><th>Account</th></tr></thead><tbody><c:forEach var="student" items="${labRequest.students}" varStatus="loop"><tr><td>${loop.count}</td><td><c:out value="${student.studentCode}"/></td><td><c:out value="${student.fullName}"/></td><td><c:out value="${student.email}"/></td><td><c:choose><c:when test="${not empty student.studentId}"><span class="badge badge-green">ACTIVE</span></c:when><c:otherwise><span class="badge badge-gray">NOT CREATED</span></c:otherwise></c:choose></td></tr></c:forEach></tbody></table></div></section>

            <div class="approval-note"><h3>Mentor note</h3><p><c:out value="${labRequest.requestNote}" default="No note provided."/></p></div>

            <c:choose>
                <c:when test="${labRequest.status == 'PENDING'}">
                    <form class="form-section detail-section" method="post" action="${pageContext.request.contextPath}/admin/lab-requests/decision">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="id" value="${labRequest.requestId}">
                        <label class="field"><span>Decision note</span><textarea name="approvalNote" maxlength="2000" placeholder="Optional note for the Mentor..."></textarea></label>
                        <div class="form-actions"><button class="danger-button" type="submit" name="decision" value="REJECTED" onclick="return confirm('Reject this request? No student account will be created.');">Reject</button><button class="primary-button" type="submit" name="decision" value="APPROVED" onclick="return confirm('Approve this request and activate all listed students?');">Approve & activate students</button></div>
                    </form>
                </c:when>
                <c:otherwise><div class="approval-note"><h3>Admin decision note</h3><p><c:out value="${labRequest.approvalNote}" default="No decision note provided."/></p></div></c:otherwise>
            </c:choose>
        </section>
    </main>
</div>
</body>
</html>
