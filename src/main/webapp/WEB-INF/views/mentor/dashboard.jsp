<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-clipboard" viewBox="0 0 24 24"><rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2M9 9h6M9 13h6M9 17h4"/></symbol>
    <symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></symbol>
    <symbol id="i-box" viewBox="0 0 24 24"><path d="m21 8-9 5-9-5 9-5 9 5Z"/><path d="m3 8 9 5 9-5v9l-9 5-9-5V8Z"/><path d="M12 13v9"/></symbol>
    <symbol id="i-calendar" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/></symbol>
    <symbol id="i-inspect" viewBox="0 0 24 24"><path d="M9 5H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7M9 3h6v4H9zM8 11h4M8 15h3"/><circle cx="17" cy="16" r="4"/><path d="m20 19 2 2"/></symbol>
    <symbol id="i-alert" viewBox="0 0 24 24"><path d="M10.3 3.7 2.4 17.2A2 2 0 0 0 4.1 20h15.8a2 2 0 0 0 1.7-2.8L13.7 3.7a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/></symbol>
    <symbol id="i-list" viewBox="0 0 24 24"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-trash" viewBox="0 0 24 24"><path d="M3 6h18M8 6V3h8v3M19 6l-1 15H6L5 6M10 11v6M14 11v6"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-search" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></symbol>
    <symbol id="i-bell" viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></symbol>
    <symbol id="i-chevron" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></symbol>
    <symbol id="i-trend" viewBox="0 0 24 24"><path d="m3 17 6-6 4 4 8-8M15 7h6v6"/></symbol>
    <symbol id="i-clock" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></symbol>
    <symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16"/></symbol>
</svg>

<div class="app-shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="${pageContext.request.contextPath}/mentor/dashboard" aria-label="LAB Asset home">
            <span class="brand-mark"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"></span>
            <span><strong>LAB ASSET</strong><small>MENTOR PORTAL</small></span>
        </a>
        <nav class="side-nav" aria-label="Mentor navigation">
            <a class="nav-link active" href="${pageContext.request.contextPath}/mentor/dashboard" aria-current="page"><svg><use href="#i-grid"/></svg><span>Dashboard</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-clipboard"/></svg><span>Lab Requests</span><span class="nav-count">4</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-users"/></svg><span>Students</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-box"/></svg><span>Assets</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-calendar"/></svg><span>Asset Usage</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-inspect"/></svg><span>Inspections</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-alert"/></svg><span>Incidents</span><span class="nav-dot" aria-label="3 open incidents"></span></a>
            <a class="nav-link" href="#"><svg><use href="#i-list"/></svg><span>Responsibilities</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-wrench"/></svg><span>Maintenance</span></a>
            <a class="nav-link" href="#"><svg><use href="#i-trash"/></svg><span>Disposal</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">MA</div><div class="profile-copy"><strong>Nguyen Minh Anh</strong><span><i></i> Online</span></div><svg class="chevron-down" viewBox="0 0 24 24"><path d="m8 10 4 4 4-4"/></svg></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>
    <button class="sidebar-overlay" id="sidebarOverlay" type="button" aria-label="Close navigation"></button>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Good morning, Minh Anh</h1><p>Here is today&rsquo;s lab overview</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Search assets, students, requests..." aria-label="Search"></label>
                <button class="icon-button notification" type="button" aria-label="Notifications"><svg><use href="#i-bell"/></svg><span>3</span></button>
                <div class="top-profile"><div class="avatar">MA</div><span>Minh Anh</span><svg viewBox="0 0 24 24"><path d="m8 10 4 4 4-4"/></svg></div>
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
                    <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span><h3>Lab schedule</h3></div><div class="panel-tools"><button type="button">This week <span>⌄</span></button><button type="button" aria-label="Previous week">‹</button><button type="button" aria-label="Next week">›</button></div></header>
                    <div class="schedule">
                        <div class="day-head"><span></span><div><b>Mon</b><small>May 13</small></div><div><b>Tue</b><small>May 14</small></div><div class="today"><b>Wed</b><small>May 15</small></div><div><b>Thu</b><small>May 16</small></div><div><b>Fri</b><small>May 17</small></div></div>
                        <div class="schedule-body"><div class="time-rail"><span>09:00</span><span>10:00</span><span>11:00</span><span>12:00</span><span>13:00</span><span>14:00</span><span>15:00</span><span>16:00</span></div>
                            <div class="calendar-grid">
                                <div class="booking booking-green" style="--column: 1; --row: 1; --rows: 3"><b>09:00 – 11:00</b><span>AI Lab · Group 03</span><div class="avatar-stack"><i>HN</i><i>TN</i><i>QH</i><em>+2</em></div></div>
                                <div class="booking booking-blue" style="--column: 3; --row: 2; --rows: 3"><b>10:00 – 12:00</b><span>Network Lab · Group 07</span><div class="avatar-stack"><i>BT</i><i>KL</i><i>DV</i><em>+3</em></div></div>
                                <div class="booking booking-gold" style="--column: 4; --row: 6; --rows: 3"><b>14:00 – 16:00</b><span>IoT Lab · Group 02</span><div class="avatar-stack"><i>NA</i><i>PT</i><i>HT</i><em>+1</em></div></div>
                            </div>
                        </div>
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
<script>
    const menuButton = document.getElementById('menuButton');
    const overlay = document.getElementById('sidebarOverlay');
    const closeMenu = () => {
        document.body.classList.remove('nav-open');
        menuButton.setAttribute('aria-expanded', 'false');
    };
    menuButton.addEventListener('click', () => {
        const open = document.body.classList.toggle('nav-open');
        menuButton.setAttribute('aria-expanded', String(open));
    });
    overlay.addEventListener('click', closeMenu);
    document.addEventListener('keydown', event => { if (event.key === 'Escape') closeMenu(); });
</script>
</body>
</html>
