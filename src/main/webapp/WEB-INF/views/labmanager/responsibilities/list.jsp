<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trách nhiệm | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="lab-manager-page"><c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Hồ sơ trách nhiệm và bồi thường</h1>
                    <p>Xem kết luận, bồi thường và quyết định xử lý của người hướng dẫn</p></div>
            </div>
            <div class="topbar-actions">
                <div class="top-profile">
                    <div class="avatar">LM</div>
                    <span><c:out value="${currentUser.fullName}"/></span></div>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">LIABILITY</p>
                    <h2>Hồ sơ trách nhiệm (${responsibilities.size()})</h2></div>
            </div>
            <form class="filter-bar" method="get"
                  action="${pageContext.request.contextPath}/lab-manager/responsibilities">
                <div class="filter-group"><input class="form-control" type="search" name="keyword"
                                                 value="<c:out value='${keyword}'/>"
                                                 placeholder="Tìm theo hồ sơ, thực tập sinh, sự cố hoặc thiết bị"
                                                 style="width:280px"><select class="form-control" name="status">
                    <option value="">Tất cả trạng thái</option>
                    <option value="CONFIRMED" ${selectedStatus == 'CONFIRMED' ? 'selected' : ''}>Đã xác nhận</option>
                    <option value="PENDING_REVIEW" ${selectedStatus == 'PENDING_REVIEW' ? 'selected' : ''}>
                        Chờ duyệt
                    </option>
                    <option value="APPROVED" ${selectedStatus == 'APPROVED' ? 'selected' : ''}>Đã duyệt</option>
                    <option value="REJECTED" ${selectedStatus == 'REJECTED' ? 'selected' : ''}>Đã từ chối</option>
                    <option value="RESOLVED" ${selectedStatus == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết</option>
                </select>
                    <button class="primary-button">Tìm kiếm</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities">Đặt lại</a>
                </div>
            </form>
            <article class="panel"><c:choose><c:when test="${empty responsibilities}">
                <div class="empty-box">
                    <div class="empty-box-icon">
                        <svg>
                            <use href="#i-list"/>
                        </svg>
                    </div>
                    <h3>Chưa có hồ sơ trách nhiệm</h3>
                    <p>Hồ sơ trách nhiệm do người hướng dẫn tạo sẽ xuất hiện tại đây để quản lý xem.</p></div>
            </c:when><c:otherwise>
                <div class="table-scroll">
                    <table>
                        <thead>
                        <tr>
                            <th>Mã hồ sơ</th>
                            <th>Mã sự cố</th>
                            <th>Thực tập sinh liên quan</th>
                            <th>Kết luận của người hướng dẫn</th>
                            <th>Quyết định của quản lý</th>
                            <th>Xử lý / Bồi thường</th>
                            <th>Trạng thái</th>
                            <th>Thao tác</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:forEach var="r" items="${responsibilities}">
                            <tr>
                                <td><strong>#<c:out value="${r.responsibilityCode}"/></strong></td>
                                <td><c:out value="${r.incidentCode}"/></td>
                                <td><span class="student"><i>IN</i><c:out value="${r.internName}"/></span><small><c:out
                                        value="${r.internCode}"/></small></td>
                                <td class="wrap-cell"><c:out value="${r.conclusion}"/></td>
                                <td class="wrap-cell"><c:out value="${r.reviewNote}"
                                                             default="Đang chờ / Không yêu cầu"/></td>
                                <td class="wrap-cell"><c:out value="${r.decision}" default="—"/></td>
                                <td><span
                                        class="status ${r.status == 'RESOLVED' || r.status == 'CONFIRMED' || r.status == 'APPROVED' ? 'returned' : 'review'}"><c:out
                                        value="${app:label(r.status)}"/></span></td>
                                <td><a class="btn-action"
                                       href="${pageContext.request.contextPath}/lab-manager/responsibilities/${r.responsibilityId}">Xem</a><a class="btn-action btn-action-primary"
                                       href="${pageContext.request.contextPath}/lab-manager/responsibilities/${r.responsibilityId}/edit">Sửa</a>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer"><span>Hiển thị ${responsibilities.size()} hồ sơ trách nhiệm</span>
                    <div class="pagination-controls">
                        <button class="page-btn" disabled>‹</button>
                        <button class="page-btn active" disabled>1</button>
                        <button class="page-btn" disabled>›</button>
                    </div>
                </div>
            </c:otherwise></c:choose></article>
        </section>
    </main>
</div>
</body>
</html>
