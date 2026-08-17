<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>My Responsibility #${responsibility.responsibilityCode} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
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
                <div><h1>My Responsibility Details</h1>
                    <p>Mentor finding, related incident and handling result assigned to you</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary"
                                           href="${pageContext.request.contextPath}/intern/responsibilities">‹ Back to
                My Responsibilities</a></div>
        </header>
        <section class="content-area">
            <%@ include file="../../shared/responsibility-detail.jspf" %>
        </section>
    </main>
</div>
</body>
</html>
