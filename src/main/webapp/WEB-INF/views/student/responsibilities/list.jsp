<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Trách nhiệm của tôi | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div><h1>Đánh giá trách nhiệm của tôi</h1><p>Xem đánh giá, bằng chứng và khuyến nghị liên quan đến bạn.</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">IN</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">RESPONSIBILITY</p><h2>Hồ sơ của tôi (${responsibilities.size()})</h2></div></div>
            <form class="filter-bar" method="get" action="${pageContext.request.contextPath}/intern/responsibilities">
                <div class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Tìm theo sự cố, thiết bị hoặc đánh giá" style="width:280px">
                    <select class="form-control" name="status">
                        <option value="">Tất cả trạng thái lưu vết</option>
                        <option value="CONFIRMED" ${selectedStatus == 'CONFIRMED' ? 'selected' : ''}>Đã xác nhận</option>
                        <option value="PENDING_REVIEW" ${selectedStatus == 'PENDING_REVIEW' ? 'selected' : ''}>Chờ duyệt</option>
                        <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                        <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                        <option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option>
                    </select>
                    <button class="primary-button" type="submit">Tìm kiếm</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/intern/responsibilities">Đặt lại</a>
                </div>
            </form>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty responsibilities}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-list"/></svg></div>
                            <h3>Bạn chưa có hồ sơ trách nhiệm</h3>
                            <p>Chỉ hồ sơ có gán thông tin thực tập sinh của bạn mới hiển thị tại đây.</p>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>Mã hồ sơ / Sự cố</th>
                                    <th>Thiết bị</th>
                                    <th>Mức trách nhiệm</th>
                                    <th>Bằng chứng / Lý do</th>
                                    <th>Khuyến nghị xử lý</th>
                                    <th>Trạng thái lưu vết</th>
                                    <th>Thao tác</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="r" items="${responsibilities}">
                                    <tr>
                                        <td><strong>#<c:out value="${r.responsibilityCode}"/></strong><br><small><c:out value="${r.incidentCode}"/> · <c:out value="${app:label(r.technicalCause)}"/></small></td>
                                        <td><b><c:out value="${r.assetName}"/></b><br><small><c:out value="${r.assetCode}"/></small></td>
                                        <td><c:choose><c:when test="${not empty r.responsibilityLevel}"><c:out value="${app:label(r.responsibilityLevel)}"/></c:when><c:otherwise>Hồ sơ cũ</c:otherwise></c:choose></td>
                                        <td class="wrap-cell"><c:choose><c:when test="${not empty r.evidenceSummary}"><c:out value="${r.evidenceSummary}"/></c:when><c:otherwise><c:out value="${r.conclusion}" default="—"/></c:otherwise></c:choose><c:if test="${not empty r.responsibilityNote}"><br><small><c:out value="${r.responsibilityNote}"/></small></c:if></td>
                                        <td class="wrap-cell"><c:choose><c:when test="${not empty r.handlingRecommendation}"><c:out value="${r.handlingRecommendation}"/></c:when><c:otherwise><c:out value="${r.decision}" default="—"/></c:otherwise></c:choose></td>
                                        <td><span class="status ${r.status == 'RESOLVED' || r.status == 'CONFIRMED' || r.status == 'APPROVED' ? 'returned' : 'review'}"><c:out value="${app:label(r.status)}"/></span></td>
                                        <td><a class="btn-action btn-action-primary" href="${pageContext.request.contextPath}/intern/responsibilities/${r.responsibilityId}">Xem</a></td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer"><span>Hiển thị ${responsibilities.size()} hồ sơ trách nhiệm</span></div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
