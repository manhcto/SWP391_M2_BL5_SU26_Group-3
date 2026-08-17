<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Responsibility #${responsibility.responsibilityCode} | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
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
                <div><h1>Responsibility Details</h1>
                    <p>Related incident, Intern, asset usage, evidence and handling result</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary"
                                           href="${pageContext.request.contextPath}/mentor/responsibilities">‹
                Back</a><a class="primary-button"
                           href="${pageContext.request.contextPath}/mentor/responsibilities/${responsibility.responsibilityId}/edit">Edit</a>
            </div>
        </header>
        <section class="content-area"><c:if test="${not empty param.success}">
            <div class="success-message">Responsibility saved successfully.</div>
        </c:if>
            <%@ include file="../../shared/responsibility-detail.jspf" %>
        </section>
    </main>
</div>
</body>
</html>
