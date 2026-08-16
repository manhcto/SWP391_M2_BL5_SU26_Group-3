<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Management (FE-01) | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body>
<c:set var="activeMenu" value="users" scope="request"/>
<div class="app-shell">
    <%@ include file="../includes/sidebar.jspf"%>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1>User Management (FE-01)</h1><p>Create accounts, assign roles, activate approved student lists</p></div></div>
            <div class="topbar-actions">
                <label class="search-box"><svg><use href="#i-search"/></svg><input type="search" placeholder="Search users..." aria-label="Search"></label>
                <button class="icon-button notification" type="button" aria-label="Notifications"><svg><use href="#i-bell"/></svg><span>3</span></button>
                <div class="top-profile"><div class="avatar">AD</div><span>Administrator</span></div>
            </div>
        </header>

        <section class="content-area">
            <div class="content-heading">
                <div><p class="eyebrow">DIRECTORY</p><h2>All Managed Users (${users.size()})</h2></div>
                <div style="display:flex; align-items: center; gap: 10px;">
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users/import"><svg style="width:14px; height:14px; fill:none; stroke:currentColor; stroke-width:2;"><use href="#i-upload"/></svg>+ Batch Import Students</a>
                    <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/add"><svg><use href="#i-plus"/></svg>+ Add New User</a>
                </div>
            </div>

            <c:if test="${param.success == 'created'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Người dùng đã được thêm mới thành công!</div></c:if>
            <c:if test="${param.success == 'role_updated'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Vai trò của người dùng đã được chuyển đổi thành công (Mentor ↔ Lab Manager)!</div></c:if>
            <c:if test="${param.success == 'status_updated'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Trạng thái tài khoản đã được chuyển đổi thành công!</div></c:if>
            <c:if test="${param.success == 'imported'}"><div style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">✓ Đã import thành công ${param.count} tài khoản vào hệ thống!</div></c:if>

            <div class="filter-bar">
                <form method="get" action="${pageContext.request.contextPath}/admin/users" class="filter-group">
                    <input class="form-control" type="search" name="keyword" value="<c:out value='${keyword}'/>" placeholder="Search name, roll, email..." style="width: 240px;">
                    <select class="form-control" name="role">
                        <option value="">All Roles (3)</option>
                        <option value="STUDENT" ${selectedRole == 'STUDENT' ? 'selected' : ''}>Student (1)</option>
                        <option value="MENTOR" ${selectedRole == 'MENTOR' ? 'selected' : ''}>Mentor (2)</option>
                        <option value="LAB_MANAGER" ${selectedRole == 'LAB_MANAGER' ? 'selected' : ''}>Lab Manager (3)</option>
                    </select>
                    <select class="form-control" name="status">
                        <option value="">All Status</option>
                        <option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>ACTIVE</option>
                        <option value="INACTIVE" ${selectedStatus == 'INACTIVE' ? 'selected' : ''}>INACTIVE</option>
                    </select>
                    <button class="primary-button" type="submit" style="height: 36px; padding: 0 16px;">Filter</button>
                    <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users" style="height: 36px;">Reset</a>
                </form>
            </div>

            <article class="panel">
                <c:choose>
                    <c:when test="${empty users}">
                        <div class="empty-box">
                            <div class="empty-box-icon"><svg><use href="#i-users"/></svg></div>
                            <h3>Chưa có dữ liệu người dùng</h3>
                            <p>Danh sách tài khoản sinh viên, mentor và quản lý lab đang trống.<br>Bạn có thể tải lên danh sách từ file Excel hoặc tạo tài khoản mới.</p>
                            <div style="display:flex; align-items: center; justify-content: center; gap: 12px; margin-top: 4px;">
                                <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/import"><svg style="width:14px; height:14px; fill:none; stroke:currentColor; stroke-width:2;"><use href="#i-upload"/></svg>+ Batch Import Excel</a>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users/add"><svg style="width:14px; height:14px; fill:none; stroke:currentColor; stroke-width:2;"><use href="#i-plus"/></svg>+ Thêm Người Dùng</a>
                            </div>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-scroll">
                            <table>
                                <thead>
                                <tr>
                                    <th>User ID</th>
                                    <th>Full Name</th>
                                    <th>Email (@fpt.edu.vn)</th>
                                    <th>Role</th>
                                    <th>Student Code / Scope</th>
                                    <th>Status</th>
                                    <th style="text-align: right;">Actions</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach var="u" items="${users}">
                                    <tr>
                                        <td><strong>#USR-${u.userId}</strong></td>
                                        <td><span class="student"><i>${u.fullName.substring(0, 1)}</i><b><c:out value="${u.fullName}"/></b></span></td>
                                        <td><c:out value="${u.email}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${u.role == 'STUDENT'}">
                                                    <span class="badge badge-green">STUDENT</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <select class="form-control" style="height: 28px; font-size: 11px; padding: 0 8px; width: 140px; font-weight: 700; border-color: #bce1ce; background: #f4f9f6; color: #188255; cursor: pointer;" onchange="if(confirm('Chuyển đổi vai trò của người dùng sang ' + this.value + '?')) { location.href='${pageContext.request.contextPath}/admin/users/change-role?id=${u.userId}&role=' + this.value; } else { this.value='${u.role}'; }">
                                                        <option value="MENTOR" ${u.role == 'MENTOR' ? 'selected' : ''}>MENTOR</option>
                                                        <option value="LAB_MANAGER" ${u.role == 'LAB_MANAGER' ? 'selected' : ''}>LAB_MANAGER</option>
                                                    </select>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty u.studentCode}"><c:out value="${u.studentCode}"/> · <c:out value="${u.major}" default="Engineering"/></c:when>
                                                <c:otherwise>Faculty / Staff</c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${u.status == 'ACTIVE'}"><span class="status returned">ACTIVE</span></c:when>
                                                <c:otherwise><span class="status review" style="color:#c63d3d; background:#fbeaea;">INACTIVE</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td style="text-align: right;">
                                            <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/view?id=${u.userId}">View</a>
                                            <a class="btn-action ${u.status == 'ACTIVE' ? 'btn-action-danger' : 'btn-action'}" href="${pageContext.request.contextPath}/admin/users/toggle-status?id=${u.userId}" onclick="return confirm('Bạn có chắc muốn đổi trạng thái tài khoản này?');">
                                                <c:choose>
                                                    <c:when test="${u.status == 'ACTIVE'}">Lock</c:when>
                                                    <c:otherwise>Unlock</c:otherwise>
                                                </c:choose>
                                            </a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div class="table-footer">
                            <div class="page-size-selector"><span>Show</span><select class="form-control" style="width: auto; height: 28px;"><option value="10" selected>10</option><option value="25">25</option><option value="50">50</option></select><span>entries per page</span></div>
                            <span>Showing 1 to ${users.size()} of ${users.size()} users</span>
                            <div class="pagination-controls"><button class="page-btn" disabled>‹</button><button class="page-btn active">1</button><button class="page-btn">2</button><button class="page-btn">›</button></div>
                        </div>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>
</body>
</html>
