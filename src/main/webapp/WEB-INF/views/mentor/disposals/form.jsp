<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Create Disposal Request</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="../../includes/operations-sidebar.jspf" %>
    <div class="workspace">
        <main class="content">
            <div class="page-heading">
                <h1>Create Disposal Request</h1>
                <a class="button" href="${pageContext.request.contextPath}/mentor/disposals">Back</a>
            </div>
            <p class="alert"><c:out value="${message}"/></p>
            <c:if test="${empty quantityAssets and empty assetItems}">
                <section class="card"><p>No eligible disposal targets are available.</p></section>
            </c:if>
            <c:if test="${not empty quantityAssets}">
                <section class="card form-card">
                    <h2>Quantity-tracked asset</h2>
                    <p>Requests retire the aggregate asset and its recorded quantity. No physical item identity is implied.</p>
                    <form method="post">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="create">
                        <label>
                            Asset
                            <select name="assetId" required>
                                <option value="">Select an asset</option>
                                <c:forEach items="${quantityAssets}" var="a">
                                    <option value="${a.assetId}" ${param.assetId == a.assetId ? 'selected' : ''}><c:out
                                            value="${a.assetCode}"/> - <c:out value="${a.assetName}"/> (${a.totalQuantity} units)</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label>
                            Reason
                            <textarea name="reason" required><c:out value="${param.reason}"/></textarea>
                        </label>
                        <button class="button primary">Submit aggregate request</button>
                    </form>
                </section>
            </c:if>
            <c:if test="${not empty assetItems}">
                <section class="card form-card">
                    <h2>Serialized asset item</h2>
                    <p>Select the exact item tag. Only unavailable, damaged, or broken items are listed.</p>
                    <form method="post">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="create">
                        <label>
                            Item tag
                            <select name="assetItemId" required>
                                <option value="">Select an item</option>
                                <c:forEach items="${assetItems}" var="item">
                                    <option value="${item.assetItemId}" ${param.assetItemId == item.assetItemId ? 'selected' : ''}><c:out
                                            value="${item.itemTag}"/> - <c:out value="${item.assetName}"/> (${item.condition})</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label>
                            Reason
                            <textarea name="reason" required><c:out value="${param.reason}"/></textarea>
                        </label>
                        <button class="button primary">Submit item request</button>
                    </form>
                </section>
            </c:if>
        </main>
    </div>
</div>
</body>
</html>
