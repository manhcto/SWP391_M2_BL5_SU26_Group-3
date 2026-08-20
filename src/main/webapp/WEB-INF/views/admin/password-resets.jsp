<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Password Resets | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/asset-operations.css">
</head>
<body>
<main class="content">
    <div class="page-heading">
        <div>
            <h1>Password reset requests</h1>
            <p>Review requests, then issue a one-time temporary password.</p>
        </div>
        <a class="button" href="${pageContext.request.contextPath}/admin/dashboard">Dashboard</a>
    </div>
    <c:if test="${not empty temporaryPassword}">
        <p class="alert">Temporary password: <strong><c:out value="${temporaryPassword}"/></strong>. Deliver securely;
            it is shown once.</p>
    </c:if>
    <p class="alert"><c:out value="${message}"/></p>
    <section class="card table-card">
        <div class="table-responsive">
            <table>
                <thead>
                <tr>
                    <th>User</th>
                    <th>Role</th>
                    <th>Requested</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach items="${requests}" var="r">
                    <tr>
                        <td>
                            <c:out value="${r.userName()}"/><br>
                            <small><c:out value="${r.email()}"/></small>
                        </td>
                        <td>${r.role()}</td>
                        <td>${r.createdAt()}</td>
                        <td>${r.status()}</td>
                        <td>
                            <c:if test="${r.status() == 'PENDING'}">
                                <form method="post">
                                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                                    <input type="hidden" name="requestId" value="${r.id()}">
                                    <input name="note" placeholder="Review note">
                                    <button name="action" value="approve">Approve</button>
                                    <button name="action" value="reject">Reject</button>
                                </form>
                            </c:if>
                            <c:if test="${r.status() == 'APPROVED'}">
                                <form method="post">
                                    <input type="hidden" name="csrfToken" value="${csrfToken}">
                                    <input type="hidden" name="requestId" value="${r.id()}">
                                    <button name="action" value="issue">Issue temporary password</button>
                                </form>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
    </section>
</main>
</body>
</html>
