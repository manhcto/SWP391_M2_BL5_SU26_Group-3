<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Đề xuất bảo trì thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="maintenance" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"><svg><use href="#i-menu"/></svg></button><div><h1>Đề xuất bảo trì thiết bị</h1><p>Gửi yêu cầu sửa chữa để quản lý phòng LAB phê duyệt</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">‹ Quay lại danh sách đề xuất</a>
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
                        <label>Số lượng *</label>
                        <input class="form-control" type="number" name="quantity" value="1" min="1" required>
                    </div>

                    <div class="form-group full-width">
                        <label>Mô tả chi tiết sự cố hỏng hóc & Lý do đề xuất sửa chữa *</label>
                        <textarea class="form-control" name="description" required placeholder="Ví dụ: Thiết bị gặp lỗi chập mạch nhiệt độ hoặc vỡ nút bấm sau phiên thực hành của sinh viên..."></textarea>
                    </div>

                    <div class="form-group full-width" style="display: flex; gap: 10px; margin-top: 10px;">
                        <button class="primary-button" type="submit">Gửi đề xuất bảo trì</button>
                        <a class="btn-secondary" href="${pageContext.request.contextPath}/mentor/maintenance">Hủy</a>
                    </div>
                </form>
            </article>
        </section>
    </main>
</div>
</body>
</html>
