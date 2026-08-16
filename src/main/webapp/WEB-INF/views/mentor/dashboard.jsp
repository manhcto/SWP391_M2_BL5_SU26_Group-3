<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Mentor dashboard for the LAB Asset Management System">
    <title>Mentor Dashboard | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<div class="app-shell">
    <c:set var="activeMenu" value="dashboard"/>
    <%@ include file="includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Mentor Dashboard</h1><p>Manage lab schedules, students and usage requests</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Search assets, students, requests..." aria-label="Search"></label>
                <button class="icon-button notification" type="button" aria-label="Notifications"><svg><use href="#i-bell"/></svg><span>3</span></button>
                <div class="top-profile"><div class="avatar">ME</div><span><c:out value="${currentUser.fullName}"/></span><svg viewBox="0 0 24 24"><path d="m8 10 4 4 4-4"/></svg></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">Sunday, 16 August</p><h2>Mentor overview</h2></div><a class="primary-button" href="#attention"><svg><use href="#i-clipboard"/></svg>Review requests</a></div>
            <section class="stats-grid" aria-label="Overview statistics">
                <article class="stat-card stat-green"><div class="stat-icon"><svg><use href="#i-users"/></svg></div><div><strong>12</strong><span>Active students</span><small><svg><use href="#i-trend"/></svg>2 from yesterday</small></div></article>
                <article class="stat-card stat-gold"><div class="stat-icon"><svg><use href="#i-clipboard"/></svg></div><div><strong>4</strong><span>Pending requests</span><small><svg><use href="#i-clock"/></svg>Needs review</small></div></article>
                <article class="stat-card stat-blue"><div class="stat-icon"><svg><use href="#i-box"/></svg></div><div><strong>86</strong><span>Assets in use</span><small><svg><use href="#i-trend"/></svg>5 from yesterday</small></div></article>
                <article class="stat-card stat-red"><div class="stat-icon"><svg><use href="#i-alert"/></svg></div><div><strong>3</strong><span>Open incidents</span><small><i></i>High priority</small></div></article>
            </section>

            <section class="dashboard-grid">
                <article class="panel schedule-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Lab schedule</h3></div><div class="panel-tools"><button type="button">Approved weekly schedule</button></div></header>
                    <div class="schedule">
                        <c:choose>
                            <c:when test="${empty approvedRequests}"><div class="schedule-empty"><span class="schedule-empty-icon"><svg><use href="#i-calendar"/></svg></span><div><strong>No approved schedule yet</strong><p>Approved Lab Usage Requests in the active semester will appear here.</p></div><a href="${pageContext.request.contextPath}/mentor/lab-requests">View requests</a></div></c:when>
                            <c:otherwise><div class="schedule-scroll"><div class="schedule-matrix"><div class="schedule-corner"><span>Weekly</span><strong>Time slots</strong></div><div class="schedule-day-head"><strong>T2</strong><small>Monday</small></div><div class="schedule-day-head"><strong>T3</strong><small>Tuesday</small></div><div class="schedule-day-head"><strong>T4</strong><small>Wednesday</small></div><div class="schedule-day-head"><strong>T5</strong><small>Thursday</small></div><div class="schedule-day-head"><strong>T6</strong><small>Friday</small></div><div class="schedule-day-head"><strong>T7</strong><small>Saturday</small></div><c:forEach begin="1" end="4" var="slotNumber"><div class="schedule-slot-label"><strong>Slot <c:out value="${slotNumber}"/></strong><small><c:choose><c:when test="${slotNumber == 1}">07:30–09:50</c:when><c:when test="${slotNumber == 2}">10:00–12:20</c:when><c:when test="${slotNumber == 3}">12:50–15:10</c:when><c:otherwise>15:20–17:30</c:otherwise></c:choose></small></div><c:forEach begin="2" end="7" var="day"><div class="schedule-cell"><c:forEach var="approvedRequest" items="${approvedRequests}" varStatus="requestLoop"><c:forEach var="approvedSlot" items="${approvedRequest.slots}"><c:if test="${approvedSlot.dayOfWeek == day && approvedSlot.slotId == slotNumber}"><a class="booking booking-${requestLoop.index % 3 == 0 ? 'green' : (requestLoop.index % 3 == 1 ? 'blue' : 'gold')}" href="${pageContext.request.contextPath}/mentor/lab-requests/view?id=${approvedRequest.requestId}"><b><c:out value="${approvedSlot.timeLabel}"/></b><span><c:out value="${approvedRequest.groupName}"/></span><small><c:out value="${approvedRequest.studentCount}"/> students</small></a></c:if></c:forEach></c:forEach></div></c:forEach></c:forEach></div></div></c:otherwise>
                        </c:choose>
                    </div>
                </article>

                <article class="panel attention-panel" id="attention">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-bell"/></svg></span><h3>Needs attention</h3></div><a href="#">View all</a></header>
                    <div class="attention-list">
                        <a href="#" class="attention-item"><span class="attention-icon gold"><svg><use href="#i-clipboard"/></svg></span><span class="attention-copy"><b>2 requests awaiting review</b><small>Submitted in the last 24 hours</small></span><span class="severity medium">Medium</span><svg class="item-arrow"><use href="#i-chevron"/></svg></a>
                        <a href="#" class="attention-item"><span class="attention-icon orange"><svg><use href="#i-clock"/></svg></span><span class="attention-copy"><b>3 overdue asset returns</b><small>Overdue by 1–3 days</small></span><span class="severity high">High</span><svg class="item-arrow"><use href="#i-chevron"/></svg></a>
                        <a href="#" class="attention-item"><span class="attention-icon red"><svg><use href="#i-alert"/></svg></span><span class="attention-copy"><b>1 incident needs assignment</b><small>Reported 2 hours ago</small></span><span class="severity high">High</span><svg class="item-arrow"><use href="#i-chevron"/></svg></a>
                        <a href="#" class="attention-item"><span class="attention-icon blue"><svg><use href="#i-wrench"/></svg></span><span class="attention-copy"><b>2 maintenance updates</b><small>Progress updates available</small></span><span class="severity low">Low</span><svg class="item-arrow"><use href="#i-chevron"/></svg></a>
                    </div>
                </article>
            </section>

            <section class="bottom-grid">
                <article class="panel health-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-clock"/></svg></span><h3>Asset health</h3></div></header>
                    <div class="health-content"><div class="donut"><div><strong>82%</strong><span>Healthy</span></div></div><dl class="health-legend"><div><dt><i class="healthy"></i>Healthy</dt><dd>82</dd></div><div><dt><i class="maintenance"></i>Maintenance</dt><dd>11</dd></div><div><dt><i class="incident"></i>Incident</dt><dd>7</dd></div></dl></div>
                </article>
                <article class="panel activity-panel">
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-clock"/></svg></span><h3>Recent activity</h3></div><a href="#">View all <svg><use href="#i-chevron"/></svg></a></header>
                    <div class="table-scroll"><table><thead><tr><th>Student</th><th>Activity</th><th>Asset</th><th>Time</th><th>Status</th></tr></thead><tbody>
                        <tr><td><span class="student"><i>HN</i>Le Hoang Nam</span></td><td>Returned asset</td><td>Oscilloscope TBS1202B</td><td>Today, 08:45</td><td><span class="status returned">Returned</span></td></tr>
                        <tr><td><span class="student"><i>BN</i>Tran Bao Ngoc</span></td><td>Checked out asset</td><td>Raspberry Pi 4 Model B</td><td>Today, 08:30</td><td><span class="status in-use">In use</span></td></tr>
                        <tr><td><span class="student"><i>QH</i>Pham Quang Huy</span></td><td>Request submitted</td><td>3D Printer Ender 3</td><td>Yesterday, 16:10</td><td><span class="status review">Review</span></td></tr>
                        <tr><td><span class="student"><i>TT</i>Doan Thu Trang</span></td><td>Incident reported</td><td>Multimeter Fluke 117</td><td>Yesterday, 14:25</td><td><span class="status review">Review</span></td></tr>
                    </tbody></table></div>
                </article>
            </section>
        </section>
    </main>
</div>
</body>
</html>
