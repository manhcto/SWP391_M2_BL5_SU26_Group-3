<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Propose Asset Maintenance | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16"/></symbol>
</svg>
<div class="app-shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="${pageContext.request.contextPath}/mentor/dashboard" aria-label="LAB Asset home">
            <span class="brand-mark"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"></span>
            <span><strong>LAB ASSET</strong><small>MENTOR PORTAL</small></span>
        </a>
        <nav class="side-nav">
            <a class="nav-link" href="${pageContext.request.contextPath}/mentor/dashboard"><svg><use href="#i-grid"/></svg><span>Dashboard</span></a>
            <a class="nav-link active" href="${pageContext.request.contextPath}/mentor/maintenance" aria-current="page"><svg><use href="#i-wrench"/></svg><span>Maintenance</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">MA</div><div class="profile-copy"><strong>Nguyen Minh Anh</strong><span><i></i> Online (Faculty)</span></div></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>Propose Equipment Maintenance</h1><p>Submit repair request to Lab Manager for authorization</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Back to Proposals</a>
            </div>
        </header>

        <section class="content-area">
            <article class="panel">
                <form method="post" action="${pageContext.request.contextPath}/mentor/maintenance/add" class="form-grid">
                    <div class="form-group">
                        <label>Thiết bị cần đề xuất bảo trì *</label>
                        <select class="form-control" name="assetId" required>
                            <c:forEach var="a" items="${assets}">
                                <option value="${a.assetId}"><c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/> - <c:out value="${a.storageLocation}"/>)</option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Số lượng (Quantity) *</label>
                        <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                    </div>

                    <div class="form-group full-width">
                        <label>Mô tả chi tiết sự cố hỏng hóc & Lý do đề xuất sửa chữa *</label>
                        <textarea class="form-control" name="description" required placeholder="Ví dụ: Thiết bị gặp lỗi chập mạch nhiệt độ hoặc vỡ nút bấm sau phiên thực hành của sinh viên..."></textarea>
                    </div>

                    <div class="form-group full-width" style="display: flex; gap: 10px; margin-top: 10px;">
                        <button class="primary-button" type="submit">Submit Maintenance Proposal</button>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Cancel</a>
                    </div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
