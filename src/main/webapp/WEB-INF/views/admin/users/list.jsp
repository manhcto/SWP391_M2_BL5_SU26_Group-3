<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>User Management | LAB Asset</title>
            <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
        </head>

        <body>
            <c:set var="activeMenu" value="users" scope="request" />
            <div class="app-shell">
                <%@ include file="../includes/sidebar.jspf" %>

                    <main class="main-content">
                        <header class="topbar">
                            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button"
                                    aria-label="Open navigation"><svg>
                                        <use href="#i-menu" />
                                    </svg></button>
                                <div>
                                    <h1>User Management (FE-01)</h1>
                                    <p>Create accounts, assign roles, activate approved intern lists</p>
                                </div>
                            </div>
                            <div class="topbar-actions">
                                <label class="search-box"><svg>
                                        <use href="#i-search" />
                                    </svg><input type="search" placeholder="Search users..."
                                        aria-label="Search"></label>
                                <button class="icon-button notification" type="button" aria-label="Notifications"><svg>
                                        <use href="#i-bell" />
                                    </svg><span>3</span></button>
                                <div class="top-profile">
                                    <div class="avatar">AD</div><span>
                                        <c:out value="${currentUser.fullName}" />
                                    </span>
                                </div>
                            </div>
                        </header>

                        <section class="content-area">
                            <div class="content-heading">
                                <div>
                                    <p class="eyebrow">DIRECTORY</p>
                                    <h2>All Managed Users (${users.size()})</h2>
                                </div>
                                <div style="display:flex; align-items: center; gap: 10px;">
                                    <a class="primary-button"
                                        href="${pageContext.request.contextPath}/admin/users/add"><svg>
                                            <use href="#i-plus" />
                                        </svg>Add New User</a>
                                </div>
                            </div>

                            <c:if test="${param.success == 'created'}">
                                <div
                                    style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">
                                    ✓ Người dùng đã được thêm mới thành công!</div>
                            </c:if>
                            <c:if test="${param.success == 'role_updated'}">
                                <div
                                    style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">
                                    ✓ Vai trò của người dùng đã được chuyển đổi thành công (Mentor ↔ Lab Manager)!</div>
                            </c:if>
                            <c:if test="${param.success == 'status_updated'}">
                                <div
                                    style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">
                                    ✓ Trạng thái tài khoản đã được chuyển đổi thành công!</div>
                            </c:if>
                            <c:if test="${param.success == 'imported'}">
                                <div
                                    style="padding: 12px 16px; background: #e5f3eb; color: #188255; border-radius: 6px; margin-bottom: 16px; font-size: 12px; font-weight: 600;">
                                    ✓ Đã import thành công ${param.count} tài khoản vào hệ thống!</div>
                            </c:if>

                            <div class="filter-bar">
                                <form method="get" action="${pageContext.request.contextPath}/admin/users"
                                    class="filter-group">
                                    <input class="form-control" type="search" name="keyword"
                                        value="<c:out value='${keyword}'/>" placeholder="Search name, roll, email..."
                                        style="width: 240px;">
                                    <select class="form-control" name="role">
                                        <option value="">All Roles (3)</option>
                                        <option value="INTERN" ${selectedRole=='INTERN' ? 'selected' : '' }>Intern
                                        </option>
                                        <option value="MENTOR" ${selectedRole=='MENTOR' ? 'selected' : '' }>Mentor (2)
                                        </option>
                                        <option value="LAB_MANAGER" ${selectedRole=='LAB_MANAGER' ? 'selected' : '' }>
                                            Lab Manager (3)</option>
                                    </select>
                                    <select class="form-control" name="status">
                                        <option value="">All Status</option>
                                        <option value="ACTIVE" ${selectedStatus=='ACTIVE' ? 'selected' : '' }>ACTIVE
                                        </option>
                                        <option value="INACTIVE" ${selectedStatus=='INACTIVE' ? 'selected' : '' }>
                                            INACTIVE</option>
                                    </select>
                                    <button class="primary-button" type="submit"
                                        style="height: 36px; padding: 0 16px;">Filter</button>
                                    <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users"
                                        style="height: 36px;">Reset</a>
                                </form>
                            </div>

                            <article class="panel">
                                <c:choose>
                                    <c:when test="${empty users}">
                                        <div class="empty-box">
                                            <div class="empty-box-icon"><svg>
                                                    <use href="#i-users" />
                                                </svg></div>
                                            <h3>Chưa có dữ liệu người dùng</h3>
                                            <p>Danh sách tài khoản sinh viên, mentor và quản lý lab đang trống.<br>Bạn
                                                có thể tạo tài khoản mới.</p>
                                            <div
                                                style="display:flex; align-items: center; justify-content: center; gap: 12px; margin-top: 4px;">
                                                <a class="primary-button"
                                                    href="${pageContext.request.contextPath}/admin/users/add"><svg>
                                                        <use href="#i-plus" />
                                                    </svg>Thêm Người Dùng</a>
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
                                                <tbody id="userTableBody">
                                                    <c:forEach var="u" items="${users}">
                                                        <tr>
                                                            <td><strong>#USR-${u.userId}</strong></td>
                                                            <td><span class="student"><i>${u.fullName.substring(0,
                                                                        1)}</i><b>
                                                                        <c:out value="${u.fullName}" />
                                                                    </b></span></td>
                                                            <td>
                                                                <c:out value="${u.email}" />
                                                            </td>
                                                            <td>
                                                                <c:choose>
                                                                    <c:when test="${u.role == 'INTERN'}">
                                                                        <span class="badge badge-green">INTERN</span>
                                                                    </c:when>
                                                                    <c:when test="${u.role == 'MENTOR'}">
                                                                        <span class="badge"
                                                                            style="background:#e0f2fe; color:#0369a1; font-weight:700;">MENTOR</span>
                                                                    </c:when>
                                                                    <c:when test="${u.role == 'LAB_MANAGER'}">
                                                                        <span class="badge"
                                                                            style="background:#f3e8ff; color:#7e22ce; font-weight:700;">LAB_MANAGER</span>
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        <span class="badge"
                                                                            style="background:#f1f5f9; color:#475569; font-weight:700;">ADMIN</span>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </td>
                                                            <td>
                                                                <c:choose>
                                                                    <c:when test="${not empty u.studentCode}">
                                                                        <c:out value="${u.studentCode}" /> ·
                                                                        <c:out value="${u.major}"
                                                                            default="Engineering" />
                                                                    </c:when>
                                                                    <c:otherwise>---</c:otherwise>
                                                                </c:choose>
                                                            </td>
                                                            <td>
                                                                <c:choose>
                                                                    <c:when test="${u.status == 'ACTIVE'}"><span
                                                                            class="status returned">ACTIVE</span>
                                                                    </c:when>
                                                                    <c:otherwise><span class="status review"
                                                                            style="color:#c63d3d; background:#fbeaea;">INACTIVE</span>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </td>
                                                            <td style="text-align: right;">
                                                                <a class="btn-action"
                                                                    href="${pageContext.request.contextPath}/admin/users/view?id=${u.userId}">View</a>
                                                                <a class="btn-action"
                                                                    href="${pageContext.request.contextPath}/admin/users/edit?id=${u.userId}"
                                                                    style="background:#e8f4ec; color:#188255; border-color:#bce1ce; font-weight:600;">Edit</a>
                                                            </td>
                                                        </tr>
                                                    </c:forEach>
                                                </tbody>
                                            </table>
                                        </div>
                                        <div class="table-footer">
                                            <div class="page-size-selector">
                                                <span>Show</span>
                                                <select class="form-control" id="pageSizeSelect"
                                                    style="width: auto; height: 28px;"
                                                    onchange="changePageSize(this.value)">
                                                    <option value="5">5</option>
                                                    <option value="10" selected>10</option>
                                                    <option value="25">25</option>
                                                    <option value="50">50</option>
                                                </select>
                                                <span>entries per page</span>
                                            </div>
                                            <span id="pageInfoText">Showing 1 to ${users.size()} of ${users.size()}
                                                users</span>
                                            <div class="pagination-controls" id="paginationControls"></div>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </article>
                        </section>
                    </main>
            </div>

            <script>
                let currentPage = 1;
                let pageSize = 10;

                function renderPagination() {
                    const rows = document.querySelectorAll('#userTableBody tr');
                    const totalRows = rows.length;
                    if (totalRows === 0) return;

                    const totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
                    if (currentPage > totalPages) currentPage = totalPages;

                    // Show/hide rows
                    const start = (currentPage - 1) * pageSize;
                    const end = Math.min(start + pageSize, totalRows);

                    rows.forEach((row, idx) => {
                        row.style.display = (idx >= start && idx < end) ? '' : 'none';
                    });

                    // Update info text
                    const info = document.getElementById('pageInfoText');
                    if (info) {
                        info.innerText = 'Showing ' + (start + 1) + ' to ' + end + ' of ' + totalRows + ' users';
                    }

                    // Render controls
                    const container = document.getElementById('paginationControls');
                    if (!container) return;
                    container.innerHTML = '';

                    // Prev btn
                    const prevBtn = document.createElement('button');
                    prevBtn.className = 'page-btn';
                    prevBtn.innerText = '‹';
                    prevBtn.disabled = (currentPage === 1);
                    prevBtn.onclick = () => { if (currentPage > 1) { currentPage--; renderPagination(); } };
                    container.appendChild(prevBtn);

                    // Page number buttons
                    for (let p = 1; p <= totalPages; p++) {
                        const pBtn = document.createElement('button');
                        pBtn.className = 'page-btn' + (p === currentPage ? ' active' : '');
                        pBtn.innerText = p;
                        pBtn.onclick = () => { currentPage = p; renderPagination(); };
                        container.appendChild(pBtn);
                    }

                    // Next btn
                    const nextBtn = document.createElement('button');
                    nextBtn.className = 'page-btn';
                    nextBtn.innerText = '›';
                    nextBtn.disabled = (currentPage === totalPages);
                    nextBtn.onclick = () => { if (currentPage < totalPages) { currentPage++; renderPagination(); } };
                    container.appendChild(nextBtn);
                }

                function changePageSize(val) {
                    pageSize = parseInt(val, 10) || 10;
                    currentPage = 1;
                    renderPagination();
                }

                document.addEventListener('DOMContentLoaded', renderPagination);
                renderPagination();
            </script>
        </body>

        </html>