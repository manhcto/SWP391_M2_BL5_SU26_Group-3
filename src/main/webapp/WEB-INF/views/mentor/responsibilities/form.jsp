<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${empty responsibility.responsibilityId ? 'Thêm' : 'Sửa'} trách nhiệm | LAB Asset</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css"></head>
<body class="mentor-page"><c:set var="activeMenu" value="responsibilities" scope="request"/>
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
                <div><h1>${empty responsibility.responsibilityId ? 'Thêm trách nhiệm' : 'Sửa trách nhiệm'}</h1>
                    <p>Ghi nhận kết luận điều tra và đề xuất xử lý</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary"
                                           href="${pageContext.request.contextPath}/mentor/responsibilities">‹ Quay lại danh sách trách nhiệm</a></div>
        </header>
        <section class="content-area"><c:if test="${not empty message}">
            <div class="error-message"><c:out value="${message}"/></div>
        </c:if>
            <c:if test="${empty responsibility.responsibilityId && empty incidents}">
                <article class="panel">
                    <div class="empty-box">
                        <div class="empty-box-icon">
                            <svg>
                                <use href="#i-alert"/>
                            </svg>
                        </div>
                        <h3>Không có sự cố phù hợp</h3>
                        <p>Trách nhiệm phải gắn với sự cố có lượt sử dụng thiết bị của thực tập sinh và không được trùng hồ sơ hiện có.</p><a class="btn-secondary"
                                                              href="${pageContext.request.contextPath}/mentor/responsibilities">Quay lại</a>
                    </div>
                </article>
            </c:if>
            <c:if test="${not empty responsibility.responsibilityId || not empty incidents}">
                <article class="panel">
                    <form class="form-grid" method="post"
                          action="${pageContext.request.contextPath}/mentor/responsibilities">
                        <input type="hidden" name="action"
                               value="${empty responsibility.responsibilityId ? 'create' : 'update'}"><c:if
                            test="${not empty responsibility.responsibilityId}"><input type="hidden"
                                                                                       name="responsibilityId"
                                                                                       value="${responsibility.responsibilityId}"></c:if>
                        <div class="form-group full-width"><label>Sự cố / Thực tập sinh / Lượt sử dụng liên quan *</label>
                            <c:choose><c:when test="${empty responsibility.responsibilityId}"><select
                                    class="form-control" name="incidentId" required>
                                <option value="">Chọn sự cố đã được điều tra</option>
                                <c:forEach var="i" items="${incidents}">
                                    <option value="${i.incidentId}" ${responsibility.incidentId == i.incidentId ? 'selected' : ''}>
                                        <c:out value="${i.incidentCode}"/> · <c:out value="${i.assetName}"/> · <c:out
                                            value="${i.internName}"/> (<c:out value="${i.internCode}"/>) · <c:out
                                            value="${i.incidentSeverity}"/></option>
                                </c:forEach></select></c:when>
                                <c:otherwise><input class="form-control readonly-field"
                                                    value="<c:out value='${responsibility.incidentCode}'/> · <c:out value='${responsibility.assetName}'/> · <c:out value='${responsibility.internName}'/>"
                                                    readonly></c:otherwise></c:choose>
                            <small>Thực tập sinh được xác định từ lượt sử dụng thiết bị liên kết với sự cố.</small>
                        </div>
                        <div class="form-group full-width"><label>Kết luận của người hướng dẫn *</label><textarea class="form-control"
                                                                                                    name="conclusion"
                                                                                                    rows="5" required
                                                                                                    placeholder="Kết luận điều tra và xác định trách nhiệm"><c:out
                                value="${responsibility.conclusion}"/></textarea></div>
                        <div class="form-group full-width"><label>Đề xuất / Xử lý / Bồi thường</label><textarea class="form-control" name="decision" rows="4"
                                                          placeholder="Lý do miễn trách nhiệm, thay thế, xử phạt hoặc đề xuất bồi thường"><c:out
                                value="${responsibility.decision}"/></textarea></div>
                        <div class="form-group"><label>Trạng thái *</label><select class="form-control" name="status"
                                                                               required>
                            <option value="CONFIRMED" ${empty responsibility.status || responsibility.status == 'CONFIRMED' ? 'selected' : ''}>
                                Đã xác nhận
                            </option>
                            <option value="PENDING_REVIEW" ${responsibility.status == 'PENDING_REVIEW' ? 'selected' : ''}>
                                Chờ duyệt
                            </option>
                            <option value="RESOLVED" ${responsibility.status == 'RESOLVED' ? 'selected' : ''}>Đã giải quyết
                            </option>
                        </select></div>
                        <div class="form-group"><label>Ghi chú giải quyết</label><input class="form-control"
                                                                                     name="resolutionNote"
                                                                                     value="<c:out value='${responsibility.resolutionNote}'/>"
                                                                                     placeholder="Kết quả xử lý cuối cùng nếu có">
                        </div>
                        <div class="form-group full-width form-actions">
                            <button class="primary-button"
                                    type="submit">${empty responsibility.responsibilityId ? 'Tạo trách nhiệm' : 'Lưu thay đổi'}</button>
                            <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">Hủy</a>
                        </div>
                    </form>
                </article>
            </c:if></section>
    </main>
</div>
</body>
</html>
