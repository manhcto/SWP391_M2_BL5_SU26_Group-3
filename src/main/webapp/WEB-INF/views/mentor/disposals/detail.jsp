<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Disposal Request</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<div class="app-shell">
    <c:set var="activeMenu" value="disposals"/>
    <%@ include file="../includes/sidebar.jspf" %>
    <div class="workspace">
        <main class="content">
            <div class="page-heading">
                <h1><c:out value="${disposal.assetName}"/> - ${disposal.status}</h1>
                <a class="button" href="${pageContext.request.contextPath}/mentor/disposals">Back</a>
            </div>
            <p class="alert"><c:out value="${message}"/></p>
            <dl class="card detail-grid">
                <div>
                    <dt>Asset code</dt>
                    <dd><c:out value="${disposal.assetCode}"/></dd>
                </div>
                <c:if test="${not empty disposal.assetItemTag}">
                    <div>
                        <dt>Item tag</dt>
                        <dd><c:out value="${disposal.assetItemTag}"/></dd>
                    </div>
                </c:if>
                <div>
                    <dt>Asset condition</dt>
                    <dd>${disposal.assetCondition}</dd>
                </div>
                <div>
                    <dt>Quantity</dt>
                    <dd>${disposal.quantity}</dd>
                </div>
                <div>
                    <dt>Requested by</dt>
                    <dd><c:out value="${disposal.requesterName}"/></dd>
                </div>
                <div>
                    <dt>Requested at</dt>
                    <dd>${disposal.requestedAt}</dd>
                </div>
                <div>
                    <dt>Reason</dt>
                    <dd><c:out value="${disposal.reason}"/></dd>
                </div>
                <div>
                    <dt>Reviewed by</dt>
                    <dd><c:out value="${disposal.approverName}"/></dd>
                </div>
                <div>
                    <dt>Reviewed at</dt>
                    <dd>${disposal.approvedAt}</dd>
                </div>
                <div>
                    <dt>Review note</dt>
                    <dd><c:out value="${disposal.approvalNote}"/></dd>
                </div>
                <div>
                    <dt>Completed at</dt>
                    <dd>${disposal.completedAt}</dd>
                </div>
                <div>
                    <dt>Disposal result</dt>
                    <dd><c:out value="${disposal.completionNote}"/></dd>
                </div>
            </dl>
        </main>
    </div>
</div>
</body>
</html>
