<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${empty responsibility.responsibilityId ? 'Thêm' : 'Sửa'} trách nhiệm | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
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
                    <h1>${empty responsibility.responsibilityId ? 'Thêm đánh giá trách nhiệm' : 'Sửa đánh giá trách nhiệm'}</h1>
                    <p>Mentor ghi nhận đánh giá sau kết luận kỹ thuật của Lab Manager.</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <c:if test="${empty responsibility.responsibilityId && empty incidents}">
                <article class="panel">
                    <div class="empty-box">
                        <div class="empty-box-icon"><svg><use href="#i-alert"/></svg></div>
                        <h3>Không có sự cố đủ điều kiện</h3>
                        <p>Chỉ sự cố thuộc phạm vi phụ trách, chưa có hồ sơ và đã có kết luận kỹ thuật mới được đánh giá.</p>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">Quay lại</a>
                    </div>
                </article>
            </c:if>

            <c:if test="${not empty responsibility.responsibilityId || not empty incidents}">
                <article class="panel">
                    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/mentor/responsibilities">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="${empty responsibility.responsibilityId ? 'create' : 'update'}">
                        <c:if test="${not empty responsibility.responsibilityId}">
                            <input type="hidden" name="responsibilityId" value="${responsibility.responsibilityId}">
                        </c:if>

                        <div class="form-group full-width">
                            <label for="incidentId">Sự cố đã có kết luận kỹ thuật *</label>
                            <c:choose>
                                <c:when test="${empty responsibility.responsibilityId}">
                                    <select class="form-control" id="incidentId" name="incidentId" required>
                                        <option value="">Chọn sự cố đã được Lab Manager kết luận</option>
                                        <c:forEach var="i" items="${incidents}">
                                            <option value="${i.incidentId}" ${responsibility.incidentId == i.incidentId ? 'selected' : ''}>
                                                <c:out value="${i.incidentCode}"/> · <c:out value="${i.assetName}"/> · <c:out value="${app:label(i.technicalCause)}"/>
                                                <c:choose>
                                                    <c:when test="${not empty i.internId}"> · <c:out value="${i.internName}"/> (<c:out value="${i.internCode}"/>)</c:when>
                                                    <c:otherwise> · Không có Intern liên kết</c:otherwise>
                                                </c:choose>
                                            </option>
                                        </c:forEach>
                                    </select>
                                </c:when>
                                <c:otherwise>
                                    <input class="form-control readonly-field" value="<c:out value='${responsibility.incidentCode}'/> · <c:out value='${responsibility.assetName}'/> · <c:out value='${app:label(responsibility.determinedCause)}'/>" readonly>
                                </c:otherwise>
                            </c:choose>
                            <small>PARTIAL hoặc FULL chỉ hợp lệ khi sự cố có Intern liên quan. NONE và UNDETERMINED có thể không gán Intern.</small>
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
                            <label for="relatedStudentId">Intern liên quan</label>
                            <select class="form-control" id="relatedStudentId" name="relatedStudentId">
                                <option value="">Không gán Intern</option>
                                <c:forEach var="intern" items="${interns}">
                                    <option value="${intern.internId}" ${responsibility.internId == intern.internId ? 'selected' : ''}>
                                        <c:out value="${intern.internName}"/> (<c:out value="${intern.internCode}"/>)
                                    </option>
                                </c:forEach>
                            </select>
                            <small>PARTIAL hoặc FULL phải chọn Intern được Mentor phụ trách và có liên quan đến sự cố.</small>
                        </div>

                        <div class="form-group full-width">
                            <label for="evidenceSummary">Tóm tắt bằng chứng</label>
                            <textarea class="form-control" id="evidenceSummary" name="evidenceSummary" rows="4" placeholder="Nêu tài liệu, quan sát hoặc thông tin làm căn cứ đánh giá."><c:out value="${responsibility.evidenceSummary}"/></textarea>
                            <small>Bắt buộc với PARTIAL hoặc FULL.</small>
                        </div>

                        <div class="form-group full-width">
                            <label for="responsibilityNote">Lý do đánh giá trách nhiệm</label>
                            <textarea class="form-control" id="responsibilityNote" name="responsibilityNote" rows="4" placeholder="Giải thích mức trách nhiệm dựa trên kết luận kỹ thuật và bằng chứng."><c:out value="${responsibility.responsibilityNote}"/></textarea>
                            <small>Bắt buộc với PARTIAL hoặc FULL.</small>
                        </div>

                        <div class="form-group full-width">
                            <label for="handlingRecommendation">Khuyến nghị xử lý</label>
                            <textarea class="form-control" id="handlingRecommendation" name="handlingRecommendation" rows="4" placeholder="Khuyến nghị bồi thường, thay thế hoặc hướng xử lý. Đây không phải thao tác thực hiện."><c:out value="${responsibility.handlingRecommendation}"/></textarea>
                        </div>

                        <div class="form-group full-width form-actions">
                            <button class="primary-button" type="submit">${empty responsibility.responsibilityId ? 'Tạo đánh giá' : 'Lưu đánh giá'}</button>
                            <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/responsibilities">Hủy</a>
                        </div>
                    </form>
                </article>
            </c:if>
        </section>
    </main>
</div>
</body>
</html>
