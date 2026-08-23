<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lượt sử dụng #${usage.assetUsageId} | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="intern-dashboard-page">
<c:set var="activeMenu" value="usages" scope="request"/>
<div class="app-shell">
    <%@ include file="../../student/includes/sidebar.jspf" %>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng"
                        aria-controls="sidebar" aria-expanded="false">
                    <svg>
                        <use href="#i-menu"/>
                    </svg>
                </button>
                <div><h1>Chi tiết sử dụng thiết bị</h1>
                    <p>Xem thông tin mượn và trạng thái trả</p></div>
            </div>
            <div class="topbar-actions"><a class="btn-secondary"
                                           href="${pageContext.request.contextPath}/intern/usages">Quay lại lịch sử</a>
            </div>
        </header>
        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">CỔNG INTERN</p>
                    <h2><c:out value="${usage.assetName}"/></h2></div>
                <span class="status ${usage.status == 'RETURNED' ? 'returned' : (usage.status == 'RETURN_PENDING' ? 'review' : 'in-use')}"><c:out
                        value="${app:label(usage.status)}"/></span></div>
            <dl class="panel detail-grid">
                <div class="detail-item">
                    <dt>Mã thiết bị</dt>
                    <dd><c:out value="${usage.assetCode}"/></dd>
                </div>
                <c:if test="${not empty usage.assetItemTag}">
                    <div class="detail-item">
                        <dt>Mã riêng</dt>
                        <dd><c:out value="${usage.assetItemTag}"/></dd>
                    </div>
                </c:if>
                <div class="detail-item">
                    <dt>Số lượng</dt>
                    <dd><c:out value="${usage.quantity}"/></dd>
                </div>
                <div class="detail-item">
                    <dt>Trạng thái</dt>
                    <dd><c:out value="${app:label(usage.status)}"/></dd>
                </div>
                <div class="detail-item">
                    <dt>Mượn lúc</dt>
                    <dd><c:out value="${app:dateTime(usage.borrowedAt)}"/></dd>
                </div>
                <div class="detail-item">
                    <dt>Hạn trả</dt>
                    <dd><c:out value="${app:dateTime(usage.dueAt)}"/></dd>
                </div>
                <div class="detail-item">
                    <dt>Trả lúc</dt>
                    <dd><c:out value="${empty usage.returnedAt ? 'Chưa trả' : app:dateTime(usage.returnedAt)}"/></dd>
                </div>
                <div class="detail-item">
                    <dt>Tình trạng trước khi mượn</dt>
                    <dd><c:out
                            value="${empty usage.conditionBefore ? 'Chưa ghi nhận' : app:label(usage.conditionBefore)}"/></dd>
                </div>
                <div class="detail-item">
                        <dt>Tình trạng Intern báo cáo</dt>
                        <dd><c:out
                                value="${empty usage.reportedConditionAfter ? 'Chưa yêu cầu trả' : app:label(usage.reportedConditionAfter)}"/></dd>
                    </div>
                <div class="detail-item"><dt>Tình trạng Mentor xác minh</dt><dd><c:out value="${empty usage.verifiedConditionAfter ? 'Chưa xác minh' : app:label(usage.verifiedConditionAfter)}"/></dd></div>
                <div class="detail-item wide">
                    <dt>Ghi chú sử dụng</dt>
                    <dd><c:out value="${empty usage.note ? 'Không có ghi chú.' : usage.note}"/></dd>
                </div>
                <div class="detail-item wide">
                    <dt>Ghi chú trả thiết bị</dt>
                    <dd><c:out
                            value="${empty usage.returnNote ? 'Chưa có ghi chú trả thiết bị.' : usage.returnNote}"/></dd>
                </div>
            </dl>
            <c:if test="${usage.status == 'IN_USE' && permissions.allows('ASSET_USAGE_RETURN')}">
                <article class="panel">
                    <header class="panel-header">
                        <div class="panel-title"><span class="title-icon"><svg><use href="#i-calendar"/></svg></span>
                            <h3>Yêu cầu trả thiết bị</h3></div>
                    </header>
                    <form method="post" action="${pageContext.request.contextPath}/intern/usages">
                        <input type="hidden" name="csrfToken" value="${csrfToken}">
                        <input type="hidden" name="action" value="return">
                        <input type="hidden" name="usageId" value="${usage.assetUsageId}">
                        <div class="form-grid">
                            <div class="form-group"><label for="conditionAfter">Tình trạng sau khi sử
                                dụng</label><select class="form-control" id="conditionAfter" name="conditionAfter"
                                                    required>
                                <option value="GOOD">Tốt</option>
                                <option value="FAIR">Khá</option>
                                <option value="DAMAGED">Hư hỏng</option>
                                <option value="BROKEN">Không hoạt động</option>
                            </select></div>
                            <div class="form-group full-width"><label for="note">Ghi chú trả thiết bị</label><textarea
                                    class="form-control" id="note" name="note"></textarea></div>
                            <div class="form-group full-width form-actions">
                                <button class="primary-button" type="submit">Gửi yêu cầu trả</button>
                            </div>
                        </div>
                    </form>
                </article>
            </c:if>
        </section>
    </main>
</div>
</body>
</html>
