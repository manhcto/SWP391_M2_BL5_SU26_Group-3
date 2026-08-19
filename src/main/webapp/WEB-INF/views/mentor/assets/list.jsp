<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Trang thiết bị phòng lab | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-catalog.css">
</head>
<body class="mentor-page">
<c:set var="activeMenu" value="assets" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false">
                    <svg><use href="#i-menu"/></svg>
                </button>
                <div>
                    <h1>Trang thiết bị phòng lab</h1>
                    <p>Theo dõi tài sản cố định, thiết bị cho mượn và trạng thái từng sản phẩm</p>
                </div>
            </div>
        </header>

        <section class="content-area asset-catalog">
            <form class="asset-catalog-filter" method="get" action="${assetBasePath}">
                <label class="asset-search-field" for="keyword">
                    <svg aria-hidden="true"><use href="#i-search"/></svg>
                    <input id="keyword" type="search" name="keyword" value="<c:out value='${param.keyword}'/>" placeholder="Tìm theo tên hoặc mã sản phẩm">
                </label>
                <label class="asset-category-field" for="category">
                    <select id="category" name="category" aria-label="Tên danh mục" onchange="this.form.submit()">
                        <option value="">Tất cả danh mục</option>
                        <c:forEach items="${categories}" var="category">
                            <option value="<c:out value='${category.categoryName}'/>" <c:if test="${param.category == category.categoryName}">selected</c:if>><c:out value="${category.categoryName}"/></option>
                        </c:forEach>
                    </select>
                </label>
            </form>

            <div class="asset-catalog-summary">
                <span><strong>${fixedAssetCount}</strong> tài sản cố định · <strong>${borrowableAssetCount}</strong> thiết bị có thể mượn</span>
                <span>Hiển thị ${assetItems.size()} sản phẩm</span>
            </div>

            <c:choose>
                <c:when test="${empty assetItems}">
                    <div class="empty-box asset-catalog-empty">
                        <div class="empty-box-icon"><svg><use href="#i-box"/></svg></div>
                        <h3>Không có thiết bị phù hợp</h3>
                        <p>Hãy thử thay đổi từ khóa hoặc tên danh mục.</p>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="asset-grid">
                        <c:forEach items="${assetItems}" var="item">
                            <article class="asset-card">
                                <div class="asset-card-image">
                                    <c:choose>
                                        <c:when test="${not empty item.imagePath}">
                                            <img src="${pageContext.request.contextPath}${item.imagePath}" alt="Ảnh ${item.itemCode}">
                                        </c:when>
                                        <c:otherwise>
                                            <svg aria-hidden="true"><use href="#i-box"/></svg>
                                        </c:otherwise>
                                    </c:choose>
                                    <span class="asset-card-state status-${item.status}"><c:out value="${app:label(item.status)}"/></span>
                                </div>
                                <div class="asset-card-body">
                                    <h2><c:out value="${item.assetName}"/></h2>
                                    <span class="asset-card-code"><c:out value="${item.itemCode}"/></span>
                                    <span class="asset-card-type ${item.borrowable ? 'borrowable' : 'fixed'}"><c:out value="${item.borrowable ? 'Có thể mượn' : 'Tài sản cố định'}"/></span>
                                    <div class="asset-card-footer">
                                        <span class="asset-card-condition"><svg aria-hidden="true"><use href="#i-grid"/></svg><c:out value="${app:label(item.condition)}"/></span>
                                        <a href="${assetBasePath}/${item.assetItemId}">Xem chi tiết</a>
                                    </div>
                                </div>
                            </article>
                        </c:forEach>
                    </div>
                </c:otherwise>
            </c:choose>
        </section>
    </main>
</div>
</body>
</html>
