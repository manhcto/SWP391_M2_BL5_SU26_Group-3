<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${empty responsibility.responsibilityId ? 'Tạo mới' : 'Cập nhật'} trách nhiệm | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="lab-manager-page">
<c:set var="activeMenu" value="responsibilities" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>${empty responsibility.responsibilityId ? 'Tạo mới trách nhiệm' : 'Cập nhật trách nhiệm'}</h1>
                    <p>Lab Manager chủ động chọn sự cố, gán Intern và nhập toàn bộ nội dung đánh giá.</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <form class="form-grid" method="post" action="${pageContext.request.contextPath}/lab-manager/responsibilities">
                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                    <input type="hidden" name="action" value="${empty responsibility.responsibilityId ? 'create' : 'assign'}">
                    <c:if test="${not empty responsibility.responsibilityId}">
                        <input type="hidden" name="responsibilityId" value="${responsibility.responsibilityId}">
                    </c:if>

                    <div class="form-group full-width">
                        <label for="incidentId">Sự cố *</label>
                        <c:choose>
                            <c:when test="${empty responsibility.responsibilityId}">
                                <select class="form-control" id="incidentId" name="incidentId" required>
                                    <option value="">Chọn sự cố để tạo hồ sơ trách nhiệm</option>
                                    <c:forEach var="incident" items="${incidents}">
                                        <option value="${incident.incidentId}" ${responsibility.incidentId == incident.incidentId ? 'selected' : ''}>
                                            <c:out value="${incident.incidentCode}"/> · <c:out value="${incident.assetCode}"/> · <c:out value="${incident.assetName}"/>
                                        </option>
                                    </c:forEach>
                                </select>
                                <small>Lab Manager tự chọn sự cố; hệ thống không tự tạo hồ sơ từ màn khác.</small>
                            </c:when>
                            <c:otherwise>
                                <input class="form-control readonly-field" value="<c:out value='${responsibility.incidentCode}'/> · <c:out value='${responsibility.assetCode}'/> · <c:out value='${responsibility.assetName}'/>" readonly>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <div class="form-group">
                        <label for="responsibilityLevel">Mức trách nhiệm *</label>
                        <select class="form-control" id="responsibilityLevel" name="responsibilityLevel" required>
                            <option value="UNDETERMINED" ${empty responsibility.responsibilityLevel || responsibility.responsibilityLevel == 'UNDETERMINED' ? 'selected' : ''}>Chưa xác định</option>
                            <option value="NONE" ${responsibility.responsibilityLevel == 'NONE' ? 'selected' : ''}>Không có trách nhiệm</option>
                            <option value="PARTIAL" ${responsibility.responsibilityLevel == 'PARTIAL' ? 'selected' : ''}>Trách nhiệm một phần</option>
                            <option value="FULL" ${responsibility.responsibilityLevel == 'FULL' ? 'selected' : ''}>Hoàn toàn chịu trách nhiệm</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="relatedStudentId">Intern được gán *</label>
                        <select class="form-control" id="relatedStudentId" name="relatedStudentId" required>
                            <option value="">Chọn Intern</option>
                            <c:forEach var="intern" items="${interns}">
                                <option value="${intern.internId}" ${responsibility.internId == intern.internId ? 'selected' : ''}>
                                    <c:out value="${intern.internName}"/> (<c:out value="${intern.internCode}"/>)
                                </option>
                            </c:forEach>
                        </select>
                        <small>Lab Manager chủ động chọn một Intern đang hoạt động.</small>
                    </div>

                    <c:if test="${empty interns}">
                        <div class="form-group full-width">
                            <div class="error-message">Hiện không có Intern đang hoạt động để gán trách nhiệm.</div>
                        </div>
                    </c:if>

                    <c:if test="${empty responsibility.responsibilityId && empty incidents}">
                        <div class="form-group full-width">
                            <div class="error-message">Không còn sự cố nào chưa có hồ sơ trách nhiệm.</div>
                        </div>
                    </c:if>

                    <div class="form-group full-width">
                        <label for="evidenceSummary">Tóm tắt bằng chứng</label>
                        <textarea class="form-control" id="evidenceSummary" name="evidenceSummary" rows="4" placeholder="Nêu tài liệu, quan sát hoặc thông tin làm căn cứ gán trách nhiệm."><c:out value="${responsibility.evidenceSummary}"/></textarea>
                        <small>Bắt buộc khi chọn trách nhiệm một phần hoặc hoàn toàn.</small>
                    </div>

                    <div class="form-group full-width">
                        <label for="responsibilityNote">Lý do gán trách nhiệm</label>
                        <textarea class="form-control" id="responsibilityNote" name="responsibilityNote" rows="4" placeholder="Giải thích mức trách nhiệm dựa trên kết luận kỹ thuật và bằng chứng."><c:out value="${responsibility.responsibilityNote}"/></textarea>
                        <small>Bắt buộc khi chọn trách nhiệm một phần hoặc hoàn toàn.</small>
                    </div>

                    <div class="form-group full-width">
                        <label for="handlingRecommendation">Khuyến nghị xử lý</label>
                        <textarea class="form-control" id="handlingRecommendation" name="handlingRecommendation" rows="4" placeholder="Khuyến nghị bồi thường, thay thế hoặc hướng xử lý."><c:out value="${responsibility.handlingRecommendation}"/></textarea>
                    </div>

                    <div class="form-group full-width form-actions">
                        <button class="primary-button" type="submit" <c:if test="${empty responsibility.responsibilityId && empty incidents}">disabled</c:if>>${empty responsibility.responsibilityId ? 'Tạo và gán trách nhiệm' : 'Lưu cập nhật'}</button>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/lab-manager/responsibilities">Hủy</a>
                    </div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
