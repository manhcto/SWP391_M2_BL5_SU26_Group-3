<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:choose><c:when test="${formMode == 'import'}">Batch Import Accounts from Excel</c:when><c:when test="${formMode == 'edit'}">Edit User Role & Status</c:when><c:otherwise>Add New User</c:otherwise></c:choose> | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .readonly-field { background: #f2f4f2 !important; border-color: #dbe0dc !important; color: #5a6662 !important; cursor: not-allowed; }
        .lock-badge { display: inline-flex; align-items: center; gap: 4px; font-size: 9.5px; color: #8a938f; font-weight: 600; }
        .upload-dropzone {
            border: 2px dashed #c4d7cc;
            border-radius: 8px;
            background: #f8faf8;
            padding: 30px 20px;
            text-align: center;
            cursor: pointer;
            transition: all .2s ease;
        }
        .upload-dropzone:hover {
            border-color: var(--emerald);
            background: #eef6f1;
        }
        .preview-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 14px;
            font-size: 11px;
        }
        .preview-table th { background: #f0f4f1; padding: 8px 10px; border-bottom: 1px solid #d5ded7; text-align: left; font-size: 9.5px; }
        .preview-table td { padding: 8px 10px; border-bottom: 1px solid #edf0ec; }
        .role-pill-group { display: flex; gap: 10px; margin-bottom: 16px; }
        .role-pill {
            flex: 1;
            padding: 10px 14px;
            border: 1.5px solid #dbe0dc;
            border-radius: 6px;
            background: #fff;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            font-weight: 600;
            color: #404c47;
            transition: all .15s ease;
        }
        .role-pill input { accent-color: var(--emerald); }
        .role-pill.active {
            border-color: var(--emerald);
            background: #f0f7f3;
            color: #126340;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
</head>
<body>
<svg class="svg-sprite" aria-hidden="true">
    <symbol id="i-grid" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></symbol>
    <symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></symbol>
    <symbol id="i-wrench" viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0-5-5L12 3.6 9.6 6 7.3 3.7a4 4 0 0 0 5 5L4 17l3 3 7.7-8.3a4 4 0 0 0 5-5L17.4 9 15 6.6l2.3-2.3a4 4 0 0 0-2.6 2Z"/></symbol>
    <symbol id="i-logout" viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/></symbol>
    <symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16"/></symbol>
    <symbol id="i-upload" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/></symbol>
    <symbol id="i-file-excel" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="17"/><line x1="16" y1="13" x2="8" y2="17"/></symbol>
</svg>
<div class="app-shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="${pageContext.request.contextPath}/admin/dashboard" aria-label="LAB Asset home">
            <span class="brand-mark"><img src="${pageContext.request.contextPath}/assets/images/fpt-university-logo.png" alt="FPT University"></span>
            <span><strong>LAB ASSET</strong><small>ADMIN PORTAL</small></span>
        </a>
        <nav class="side-nav">
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-grid"/></svg><span>Dashboard</span></a>
            <a class="nav-link active" href="${pageContext.request.contextPath}/admin/users" aria-current="page"><svg><use href="#i-users"/></svg><span>User Management</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-wrench"/></svg><span>Database Status</span></a>
            <a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard"><svg><use href="#i-users"/></svg><span>My Profile</span></a>
        </nav>
        <div class="sidebar-footer">
            <div class="profile-card"><div class="avatar avatar-lg">AD</div><div class="profile-copy"><strong>System Admin</strong><span><i></i> Online (Superuser)</span></div></div>
            <a class="sign-out" href="${pageContext.request.contextPath}/login"><svg><use href="#i-logout"/></svg><span>Sign out</span></a>
        </div>
    </aside>
    <button class="sidebar-overlay" id="sidebarOverlay" type="button" aria-label="Close navigation"></button>

    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation"><svg><use href="#i-menu"/></svg></button><div><h1><c:choose><c:when test="${formMode == 'import'}">Batch Import Accounts from Excel</c:when><c:when test="${formMode == 'edit'}">Edit User Role & Status (#USR-${user.userId})</c:when><c:otherwise>Add New User Account</c:otherwise></c:choose></h1><p>Admin manages accounts for Student, Mentor, and Lab Manager</p></div></div>
            <div class="topbar-actions">
                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">‹ Back to Users List</a>
                <div class="top-profile"><div class="avatar">AD</div><span>Administrator</span></div>
            </div>
        </header>

        <section class="content-area">
            <c:if test="${not empty errors}">
                <div style="padding: 12px 16px; background: #fbeaea; color: #c63d3d; border-radius: 6px; margin-bottom: 16px; font-size: 11.5px;">
                    <ul style="margin: 0; padding-left: 16px;">
                        <c:forEach var="err" items="${errors}">
                            <li>${err}</li>
                        </c:forEach>
                    </ul>
                </div>
            </c:if>

            <article class="panel">
                <c:choose>
                    <%-- CHẾ ĐỘ IMPORT FILE EXCEL THEO ROLE ĐƯỢC CHỌN --%>
                    <c:when test="${formMode == 'import'}">
                        <div style="padding: 24px;">
                            <div style="margin-bottom: 16px;">
                                <label style="font-size:12px; font-weight:700; color:#1a2521; display:block; margin-bottom:8px;">1. Chọn loại tài khoản cần Import từ Excel:</label>
                                <div class="role-pill-group">
                                    <label class="role-pill active" id="pill-STUDENT" onclick="selectImportRole('STUDENT')">
                                        <input type="radio" name="importRoleRadio" value="STUDENT" checked>
                                        <div>
                                            <div>🎓 Sinh viên (Student)</div>
                                            <small style="font-size:10px; color:#68736f; font-weight:400;">4 cột: Họ tên, Mã SV, Ngành, Khóa</small>
                                        </div>
                                    </label>
                                    <label class="role-pill" id="pill-MENTOR" onclick="selectImportRole('MENTOR')">
                                        <input type="radio" name="importRoleRadio" value="MENTOR">
                                        <div>
                                            <div>👨‍🏫 Giảng viên (Mentor)</div>
                                            <small style="font-size:10px; color:#68736f; font-weight:400;">2 cột: Họ tên, Bộ môn / Khoa</small>
                                        </div>
                                    </label>
                                    <label class="role-pill" id="pill-LAB_MANAGER" onclick="selectImportRole('LAB_MANAGER')">
                                        <input type="radio" name="importRoleRadio" value="LAB_MANAGER">
                                        <div>
                                            <div>🛠️ Quản lý Lab (Lab Manager)</div>
                                            <small style="font-size:10px; color:#68736f; font-weight:400;">2 cột: Họ tên, Phòng Lab phụ trách</small>
                                        </div>
                                    </label>
                                </div>
                            </div>

                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                                <label style="font-size:12px; font-weight:700; color:#1a2521; margin:0;" id="step2Label">2. Tải lên file Excel danh sách Sinh viên:</label>
                                <button class="btn-secondary" type="button" onclick="downloadSampleExcel()" style="color:#188255; border-color:#bce1ce; background:#f4f9f6;">
                                    <svg style="width:14px; height:14px; fill:none; stroke:currentColor; stroke-width:2;"><use href="#i-file-excel"/></svg>
                                    <span id="btnDownloadText">Tải file Excel mẫu Sinh viên (.csv)</span>
                                </button>
                            </div>

                            <input type="file" id="excelFileInput" accept=".xlsx, .xls, .csv" style="display:none;" onchange="handleExcelUpload(event)">
                            
                            <div class="upload-dropzone" onclick="document.getElementById('excelFileInput').click()" ondragover="event.preventDefault()" ondrop="handleDrop(event)">
                                <div style="display:grid; place-items:center; width:48px; height:48px; border-radius:50%; background:#e5f3eb; color:#188255; margin:0 auto 10px;">
                                    <svg style="width:24px; height:24px; fill:none; stroke:currentColor; stroke-width:2;"><use href="#i-upload"/></svg>
                                </div>
                                <strong style="font-size:13px; color:#1e2824; display:block;">Click để chọn file Excel (.xlsx / .csv) hoặc kéo thả file vào đây</strong>
                                <span style="font-size:11px; color:#8a938f; margin-top:4px; display:block;" id="dropzoneHint">Hệ thống sẽ tự động quét Họ tên + Mã SV và sinh email FPT tương ứng</span>
                            </div>

                            <div id="importErrorAlert" style="display:none; padding: 14px 18px; background: #fdf2f2; border: 1.5px solid #f5c2c2; color: #c63d3d; border-radius: 8px; margin-top: 16px; font-size: 12px; font-weight: 600; line-height: 1.5;">
                                <div style="display: flex; align-items: flex-start; gap: 10px;">
                                    <span style="font-size: 18px; line-height: 1;">⚠️</span>
                                    <div id="importErrorMsg">Dữ liệu trong file không phù hợp! Vui lòng chọn file khác.</div>
                                </div>
                            </div>

                            <form id="importForm" method="post" action="${pageContext.request.contextPath}/admin/users/import" style="display:none; margin-top:20px;">
                                <input type="hidden" name="targetRole" id="targetRoleInput" value="STUDENT">
                                <textarea name="importData" id="importDataText" style="display:none;"></textarea>
                                
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                    <h4 style="margin:0; font-size:13px; color:#188255;" id="previewCountBadge">✓ Đã tìm thấy tài khoản trong file</h4>
                                    <button class="primary-button" type="submit" id="btnConfirmImport">Xác nhận Import vào Database</button>
                                </div>

                                <div class="table-scroll" style="max-height: 320px; border:1px solid #dfe5e1; border-radius:6px;">
                                    <table class="preview-table">
                                        <thead id="previewThead">
                                        <tr>
                                            <th>STT</th>
                                            <th>Họ và tên</th>
                                            <th>Mã SV</th>
                                            <th>Chuyên ngành</th>
                                            <th>Khóa</th>
                                            <th>Email FPT tự sinh</th>
                                        </tr>
                                        </thead>
                                        <tbody id="previewTableBody"></tbody>
                                    </table>
                                </div>
                            </form>
                        </div>
                    </c:when>

                    <%-- CHẾ ĐỘ CHỈNH SỬA (EDIT): CHỈ CHO ĐỔI ROLE VÀ STATUS, KHÓA TOÀN BỘ THÔNG TIN ĐỊNH DANH --%>
                    <c:when test="${formMode == 'edit'}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/edit" class="form-grid">
                            <input type="hidden" name="id" value="${user.userId}">

                            <div class="form-group full-width" style="padding: 10px 14px; background: #fafbf9; border: 1px dashed #d5dbd7; border-radius: 6px;">
                                <span style="font-size: 11.5px; color: #55605c;">🔒 <b>Quy tắc nghiệp vụ:</b> Admin chỉ có quyền chuyển đổi vai trò (Role) và trạng thái (Status). Các thông tin định danh cá nhân không được phép chỉnh sửa.</span>
                            </div>

                            <div class="form-group">
                                <label>Họ và tên <span class="lock-badge">🔒 Cố định</span></label>
                                <input class="form-control readonly-field" type="text" value="<c:out value='${user.fullName}'/>" readonly disabled>
                            </div>

                            <div class="form-group">
                                <label>Email (@fpt.edu.vn) <span class="lock-badge">🔒 Cố định</span></label>
                                <input class="form-control readonly-field" type="email" value="<c:out value='${user.email}'/>" readonly disabled>
                            </div>

                            <c:if test="${not empty user.studentCode}">
                                <div class="form-group">
                                    <label>Mã sinh viên (Roll Number) <span class="lock-badge">🔒 Cố định</span></label>
                                    <input class="form-control readonly-field" type="text" value="<c:out value='${user.studentCode}'/>" readonly disabled>
                                </div>
                                <div class="form-group">
                                    <label>Chuyên ngành & Khóa <span class="lock-badge">🔒 Cố định</span></label>
                                    <input class="form-control readonly-field" type="text" value="<c:out value='${user.major}' default='Software Engineering'/> (<c:out value='${user.cohort}' default='K16'/>)" readonly disabled>
                                </div>
                            </c:if>

                            <div class="form-group">
                                <label>Vai trò (Role) * <small style="color:#188255; font-weight:600;">(Được phép đổi quyền)</small></label>
                                <c:choose>
                                    <c:when test="${user.role == 'ADMIN'}">
                                        <input class="form-control readonly-field" type="text" value="ADMIN (4) - Tài khoản Quản trị viên duy nhất" readonly disabled>
                                        <input type="hidden" name="role" value="ADMIN">
                                    </c:when>
                                    <c:otherwise>
                                        <select class="form-control" name="role" style="border-color: #188255; font-weight: 600;">
                                            <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>MENTOR (2) - Giảng viên hướng dẫn</option>
                                            <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>LAB_MANAGER (3) - Cán bộ quản lý Lab</option>
                                            <option value="STUDENT" ${user.role == 'STUDENT' ? 'selected' : ''}>STUDENT (1) - Sinh viên</option>
                                        </select>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <div class="form-group">
                                <label>Trạng thái tài khoản (Status) * <small style="color:#188255; font-weight:600;">(Được phép khóa/mở)</small></label>
                                <select class="form-control" name="status" style="border-color: #188255; font-weight: 600;">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>ACTIVE (Đang hoạt động)</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>INACTIVE (Khóa tài khoản)</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 14px; display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Save Changes</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">Cancel</a>
                            </div>
                        </form>
                    </c:when>

                    <%-- CHẾ ĐỘ THÊM MỚI (ADD SINGLE USER) --%>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/admin/users/add" class="form-grid">
                            <div class="form-group">
                                <label>Họ và tên *</label>
                                <input class="form-control" type="text" name="fullName" value="<c:out value='${user.fullName}'/>" required placeholder="e.g. Nguyễn Minh Anh">
                            </div>

                            <div class="form-group">
                                <label>Vai trò cần tạo (Role) *</label>
                                <select class="form-control" name="role" id="roleSelect" onchange="toggleStudentFields()">
                                    <option value="STUDENT" ${user.role == 'STUDENT' ? 'selected' : ''}>STUDENT (1) - Sinh viên</option>
                                    <option value="MENTOR" ${user.role == 'MENTOR' ? 'selected' : ''}>MENTOR (2) - Giảng viên hướng dẫn</option>
                                    <option value="LAB_MANAGER" ${user.role == 'LAB_MANAGER' ? 'selected' : ''}>LAB_MANAGER (3) - Cán bộ quản lý Lab</option>
                                </select>
                            </div>

                            <div class="form-group" id="studentCodeGroup">
                                <label>Mã sinh viên (Roll Number) *</label>
                                <input class="form-control" type="text" name="studentCode" id="studentCodeInput" value="<c:out value='${user.studentCode}'/>" placeholder="e.g. SE160123">
                            </div>

                            <div class="form-group">
                                <label>Email (@fpt.edu.vn) <small style="color:#8a938f">(Để trống sẽ tự sinh theo Họ tên)</small></label>
                                <input class="form-control" type="email" name="email" value="<c:out value='${user.email}'/>" placeholder="e.g. anhnmse160123@fpt.edu.vn">
                            </div>

                            <div class="form-group" id="majorGroup">
                                <label>Chuyên ngành (Major)</label>
                                <input class="form-control" type="text" name="major" value="<c:out value='${user.major}'/>" placeholder="e.g. Software Engineering">
                            </div>

                            <div class="form-group" id="cohortGroup">
                                <label>Khóa (Cohort)</label>
                                <input class="form-control" type="text" name="cohort" value="<c:out value='${user.cohort}'/>" placeholder="e.g. K16">
                            </div>

                            <div class="form-group">
                                <label>Trạng thái khởi tạo *</label>
                                <select class="form-control" name="status">
                                    <option value="ACTIVE" ${user.status == 'ACTIVE' ? 'selected' : ''}>ACTIVE (Hoạt động ngay)</option>
                                    <option value="INACTIVE" ${user.status == 'INACTIVE' ? 'selected' : ''}>INACTIVE (Tạm khóa)</option>
                                </select>
                            </div>

                            <div class="form-group full-width" style="margin-top: 14px; display: flex; gap: 10px;">
                                <button class="primary-button" type="submit">Create User Account</button>
                                <a class="btn-secondary" href="${pageContext.request.contextPath}/admin/users">Cancel</a>
                            </div>
                        </form>
                    </c:otherwise>
                </c:choose>
            </article>
        </section>
    </main>
</div>

<script>
    function showImportError(msg) {
        document.getElementById('importErrorMsg').innerText = msg;
        document.getElementById('importErrorAlert').style.display = 'block';
        document.getElementById('importForm').style.display = 'none';
        document.getElementById('excelFileInput').value = '';
    }

    function hideImportError() {
        document.getElementById('importErrorAlert').style.display = 'none';
    }

    function selectImportRole(role) {
        hideImportError();
        currentSelectedRole = role;
        document.querySelectorAll('.role-pill').forEach(el => el.classList.remove('active'));
        const activePill = document.getElementById('pill-' + role);
        if (activePill) {
            activePill.classList.add('active');
            activePill.querySelector('input').checked = true;
        }
        document.getElementById('targetRoleInput').value = role;

        const roleNames = {
            'STUDENT': 'Sinh viên',
            'MENTOR': 'Giảng viên (Mentor)',
            'LAB_MANAGER': 'Quản lý Lab (Lab Manager)'
        };
        const roleHints = {
            'STUDENT': 'Hệ thống sẽ tự động quét Họ tên, Mã SV, Email FPT, Chuyên ngành và Khóa',
            'MENTOR': 'Hệ thống sẽ tự động quét Họ tên, Email FPT và Bộ môn / Khoa',
            'LAB_MANAGER': 'Hệ thống sẽ tự động quét Họ tên và Email FPT của Quản lý Lab'
        };

        document.getElementById('step2Label').innerText = '2. Tải lên file Excel danh sách ' + roleNames[role] + ':';
        document.getElementById('btnDownloadText').innerText = 'Tải file Excel mẫu ' + roleNames[role] + ' (.csv)';
        document.getElementById('dropzoneHint').innerText = roleHints[role];

        // Reset file and preview
        document.getElementById('excelFileInput').value = '';
        document.getElementById('importForm').style.display = 'none';
    }

    function generateFptEmail(fullName, code, isStudent) {
        if (!fullName) return "";
        let clean = fullName.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase().trim();
        let words = clean.split(/\s+/);
        if (words.length === 0) return "";
        let firstName = words[words.length - 1];
        let initials = "";
        for (let i = 0; i < words.length - 1; i++) {
            initials += words[i].charAt(0);
        }
        if (isStudent && code) {
            return firstName + initials + code.trim().toLowerCase() + "@fpt.edu.vn";
        }
        return firstName + initials + "@fpt.edu.vn";
    }

    function handleDrop(e) {
        e.preventDefault();
        hideImportError();
        if (e.dataTransfer.files.length > 0) {
            parseExcelFile(e.dataTransfer.files[0]);
        }
    }

    function handleExcelUpload(e) {
        hideImportError();
        if (e.target.files.length > 0) {
            parseExcelFile(e.target.files[0]);
        }
    }

    function parseExcelFile(file) {
        hideImportError();
        const reader = new FileReader();
        const isCsv = file.name.endsWith('.csv');

        reader.onload = function(e) {
            let rows = [];
            if (isCsv) {
                const text = e.target.result;
                const lines = text.split(/\r?\n/);
                lines.forEach(line => {
                    if (line.trim()) {
                        const parts = line.split(/[,;\t]/);
                        if (parts.length >= 1) rows.push(parts.map(p => p.trim()));
                    }
                });
            } else {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, {type: 'array'});
                const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
                rows = XLSX.utils.sheet_to_json(firstSheet, {header: 1});
            }

            let parsedUsers = [];
            let linesForServer = [];
            const isStudent = (currentSelectedRole === 'STUDENT');

            for (let i = 0; i < rows.length; i++) {
                let row = rows[i];
                if (!row || row.length === 0) continue;
                let col0 = String(row[0] || '').trim();
                let col1 = String(row[1] || '').trim();
                if (col0.toLowerCase().includes('họ') || col0.toLowerCase().includes('name') || col1.toLowerCase().includes('mã')) {
                    continue; // Header
                }
                if (!col0) continue;

                let fullName = col0;
                let code = "";
                let email = "";
                let major = "";
                let cohort = "";

                if (isStudent) {
                    // Kiểm tra nếu ném nhầm file Quản lý Lab / Giảng viên (chỉ có Họ tên và Email, không có Mã SV)
                    if (col1.includes('@')) {
                        let foundCode = '';
                        for (let c = 2; c < row.length; c++) {
                            let val = String(row[c] || '').trim();
                            if (val && !val.includes('@') && /^[A-Za-z]{2}[0-9]{4,8}$/i.test(val)) {
                                foundCode = val;
                                break;
                            }
                        }
                        if (!foundCode) {
                            showImportError('⚠️ Dữ liệu không phù hợp! File bạn tải lên dường như là danh sách Quản lý Lab / Giảng viên (chỉ gồm Họ tên và Email, thiếu cột Mã sinh viên). Vui lòng chọn lại đúng file danh sách Sinh viên hoặc chuyển sang tab loại tài khoản tương ứng.');
                            return;
                        } else {
                            code = foundCode;
                            email = col1;
                        }
                    } else {
                        code = col1;
                        let col2 = String(row[2] || '').trim();
                        if (col2.includes('@')) {
                            email = col2;
                            major = String(row[3] || 'Software Engineering').trim();
                            cohort = String(row[4] || 'K16').trim();
                        } else {
                            major = col2 || 'Software Engineering';
                            cohort = String(row[3] || 'K16').trim();
                            let col4 = String(row[4] || '').trim();
                            email = col4.includes('@') ? col4 : generateFptEmail(fullName, code, true);
                        }
                    }
                    if (!email) email = generateFptEmail(fullName, code, true);
                    parsedUsers.push({ fullName, code, email, major, cohort });
                    linesForServer.push(fullName + ',' + code + ',' + email + ',' + major + ',' + cohort + ',' + currentSelectedRole);
                } else if (currentSelectedRole === 'MENTOR') {
                    // Kiểm tra nếu ném nhầm file Sinh viên vào mục Mentor
                    let hasEmail = (col1.includes('@') || String(row[2] || '').includes('@'));
                    if (!hasEmail && /^[A-Za-z]{2}[0-9]{4,8}$/i.test(col1)) {
                        showImportError('⚠️ Dữ liệu không phù hợp! File bạn tải lên là danh sách Sinh viên (có chứa Mã sinh viên) thay vì danh sách Giảng viên (Mentor). Vui lòng chuyển sang tab Sinh viên để Import.');
                        return;
                    }

                    let col1Text = col1;
                    if (col1Text.includes('@')) {
                        email = col1Text;
                        major = String(row[2] || 'Software Engineering').trim();
                    } else {
                        major = col1Text || 'Software Engineering';
                        let col2Text = String(row[2] || '').trim();
                        email = col2Text.includes('@') ? col2Text : generateFptEmail(fullName, '', false);
                    }
                    if (!email) email = generateFptEmail(fullName, '', false);
                    parsedUsers.push({ fullName, code: '', email, major, cohort: '' });
                    linesForServer.push(fullName + ',' + email + ',' + major + ',,' + currentSelectedRole);
                } else {
                    // LAB_MANAGER: Chỉ cần Họ tên & Email FPT
                    // Kiểm tra nếu ném nhầm file Sinh viên vào mục Lab Manager
                    let hasEmail = (col1.includes('@') || String(row[2] || '').includes('@'));
                    if (!hasEmail && /^[A-Za-z]{2}[0-9]{4,8}$/i.test(col1)) {
                        showImportError('⚠️ Dữ liệu không phù hợp! File bạn tải lên là danh sách Sinh viên (có chứa Mã sinh viên) thay vì danh sách Quản lý Lab. Vui lòng chuyển sang tab Sinh viên để Import.');
                        return;
                    }

                    if (col1.includes('@')) {
                        email = col1;
                    } else {
                        let col2Text = String(row[2] || '').trim();
                        email = col2Text.includes('@') ? col2Text : generateFptEmail(fullName, '', false);
                    }
                    if (!email) email = generateFptEmail(fullName, '', false);
                    parsedUsers.push({ fullName, code: '', email, major: '', cohort: '' });
                    linesForServer.push(fullName + ',' + email + ',,,' + currentSelectedRole);
                }
            }

            if (parsedUsers.length === 0) {
                showImportError('⚠️ Không tìm thấy dữ liệu hợp lệ trong file Excel. Vui lòng kiểm tra lại file của bạn.');
                return;
            }

            // Update Thead
            const thead = document.getElementById('previewThead');
            if (isStudent) {
                thead.innerHTML = '<tr><th>STT</th><th>Họ và tên</th><th>Mã SV</th><th>Email FPT (từ file)</th><th>Chuyên ngành</th><th>Khóa</th></tr>';
            } else if (currentSelectedRole === 'MENTOR') {
                thead.innerHTML = '<tr><th>STT</th><th>Họ và tên</th><th>Email FPT (từ file)</th><th>Bộ môn / Khoa</th><th>Vai trò</th></tr>';
            } else {
                thead.innerHTML = '<tr><th>STT</th><th>Họ và tên</th><th>Email FPT (từ file)</th><th>Vai trò</th></tr>';
            }

            // Render Preview Tbody
            const tbody = document.getElementById('previewTableBody');
            tbody.innerHTML = '';
            parsedUsers.forEach((u, idx) => {
                const tr = document.createElement('tr');
                if (isStudent) {
                    tr.innerHTML = '<td>' + (idx + 1) + '</td>' +
                        '<td><b>' + u.fullName + '</b></td>' +
                        '<td>' + u.code + '</td>' +
                        '<td><span style="color:#188255; font-weight:600;">' + u.email + '</span></td>' +
                        '<td>' + u.major + '</td>' +
                        '<td>' + u.cohort + '</td>';
                } else if (currentSelectedRole === 'MENTOR') {
                    tr.innerHTML = '<td>' + (idx + 1) + '</td>' +
                        '<td><b>' + u.fullName + '</b></td>' +
                        '<td><span style="color:#188255; font-weight:600;">' + u.email + '</span></td>' +
                        '<td>' + (u.major || 'Software Engineering') + '</td>' +
                        '<td><span class="badge" style="background:#e8f4ec; color:#188255; font-weight:700;">MENTOR</span></td>';
                } else {
                    tr.innerHTML = '<td>' + (idx + 1) + '</td>' +
                        '<td><b>' + u.fullName + '</b></td>' +
                        '<td><span style="color:#188255; font-weight:600;">' + u.email + '</span></td>' +
                        '<td><span class="badge" style="background:#e8f4ec; color:#188255; font-weight:700;">LAB_MANAGER</span></td>';
                }
                tbody.appendChild(tr);
            });

            document.getElementById('importDataText').value = linesForServer.join('\n');
            document.getElementById('previewCountBadge').innerText = '✓ Đã quét thành công ' + parsedUsers.length + ' tài khoản từ file: ' + file.name;
            document.getElementById('btnConfirmImport').innerText = 'Xác nhận Import ' + parsedUsers.length + ' tài khoản vào Database';
            document.getElementById('importForm').style.display = 'block';
        };

        if (isCsv) {
            reader.readAsText(file, 'UTF-8');
        } else {
            reader.readAsArrayBuffer(file);
        }
    }

    function downloadSampleExcel() {
        let csvContent = "";
        let fileName = "";
        if (currentSelectedRole === 'STUDENT') {
            csvContent = "Họ và tên,Mã sinh viên,Email FPT,Chuyên ngành,Khóa\n" +
                "Lê Hoàng Nam,SE160123,namlhse160123@fpt.edu.vn,Software Engineering,K16\n" +
                "Trần Bảo Ngọc,HE150442,ngoctbhe150442@fpt.edu.vn,IoT Embedded Systems,K15\n" +
                "Phạm Quang Huy,QE160890,huyqpqe160890@fpt.edu.vn,Information Assurance,K16\n" +
                "Vương Văn Hải,SE170012,haivvse170012@fpt.edu.vn,Artificial Intelligence,K17";
            fileName = "danh_sach_sinh_vien_mau.csv";
        } else if (currentSelectedRole === 'MENTOR') {
            csvContent = "Họ và tên,Email FPT,Bộ môn / Khoa\n" +
                "Nguyễn Minh Anh,anhnm@fpt.edu.vn,Software Engineering\n" +
                "Vũ Thị Thu Hằng,hangvtt@fpt.edu.vn,Computer Science\n" +
                "Trần Văn Đức,ductv@fpt.edu.vn,Information Assurance";
            fileName = "danh_sach_giang_vien_mentor_mau.csv";
        } else {
            csvContent = "Họ và tên,Email FPT\n" +
                "Phạm Quang Dung,dungpq@fpt.edu.vn\n" +
                "Hoàng Văn Tuấn,tuanhv@fpt.edu.vn";
            fileName = "danh_sach_quan_ly_lab_mau.csv";
        }
        
        const blob = new Blob(["\uFEFF" + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.setAttribute("download", fileName);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    function toggleStudentFields() {
        const roleSelect = document.getElementById('roleSelect');
        if (!roleSelect) return;
        const isStudent = roleSelect.value === 'STUDENT';
        const scGroup = document.getElementById('studentCodeGroup');
        const mjGroup = document.getElementById('majorGroup');
        const chGroup = document.getElementById('cohortGroup');
        if (scGroup) scGroup.style.display = isStudent ? 'flex' : 'none';
        if (mjGroup) mjGroup.style.display = isStudent ? 'flex' : 'none';
        if (chGroup) chGroup.style.display = isStudent ? 'flex' : 'none';
    }
    toggleStudentFields();
</script>
</body>
</html>
