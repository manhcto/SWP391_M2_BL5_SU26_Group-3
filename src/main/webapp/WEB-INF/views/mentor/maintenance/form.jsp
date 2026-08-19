<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tạo đề xuất bảo trì mới | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Tạo đề xuất bảo trì mới</h1>
                    <p>Gửi yêu cầu sửa chữa thiết bị hỏng hóc lên Lab Manager phê duyệt</p>
                </div>
            </div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách</a>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty message}">
                <div class="error-message"><c:out value="${message}"/></div>
            </c:if>

            <article class="panel">
                <form method="post" action="${pageContext.request.contextPath}/mentor/maintenance" class="form-grid">
                    <input type="hidden" name="action" value="create">

                    <div class="form-group">
                        <label>Thiết bị cần bảo trì *</label>
                        <select class="form-control" name="assetId" required>
                            <option value="">-- Chọn thiết bị --</option>
                            <c:forEach var="a" items="${assets}">
                                <option value="${a.assetId}">
                                    <c:out value="${a.assetName}"/> (<c:out value="${a.assetCode}"/>)
                                    <c:if test="${not empty a.storageLocation}"> – <c:out value="${a.storageLocation}"/></c:if>
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Số lượng cần bảo trì *</label>
                        <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                    </div>

                    <div class="form-group full-width">
                        <label>Sự cố liên quan (nếu có)</label>
                        <select class="form-control" name="incidentId">
                            <option value="">-- Không có sự cố (bảo dưỡng định kỳ / trực tiếp) --</option>
                            <c:forEach var="inc" items="${incidents}">
                                <option value="${inc.incidentId}">
                                    #INC-<c:out value="${inc.incidentId}"/>
                                    – <c:out value="${inc.assetName}"/>:
                                    <c:out value="${inc.description}"/>
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group full-width">
                        <label>Mô tả chi tiết tình trạng hỏng hóc / Lý do cần bảo trì *</label>
                        <textarea class="form-control" name="description" rows="5" required
                                  placeholder="Mô tả cụ thể: hiện tượng lỗi, bộ phận bị hỏng, nguyên nhân nghi ngờ, yêu cầu sửa chữa cụ thể..."></textarea>
                    </div>

                    <div class="form-group full-width" style="display:flex;gap:10px;">
                        <button class="primary-button" type="submit">
                            <svg><use href="#i-wrench"/></svg> Gửi đề xuất bảo trì
                        </button>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Hủy</a>
                    </div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
