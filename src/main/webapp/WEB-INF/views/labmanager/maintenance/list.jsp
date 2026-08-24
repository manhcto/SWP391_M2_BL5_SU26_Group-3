<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="app" uri="/WEB-INF/app.tld" %>
                <!DOCTYPE html>
                <html lang="vi">

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>Quản lý bảo trì thiết bị | LAB Asset</title>
                    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
                    <style>
                        .alert-banner {
                            background: #fffbeb;
                            border: 1px solid #fde68a;
                            border-left: 5px solid #f59e0b;
                            border-radius: 10px;
                            padding: 16px 20px;
                            margin-bottom: 22px;
                            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
                        }

                        .alert-banner-header {
                            display: flex;
                            align-items: center;
                            justify-content: space-between;
                            gap: 12px;
                            flex-wrap: wrap;
                            margin-bottom: 8px;
                        }

                        .alert-badge {
                            background: #ef4444;
                            color: #fff;
                            font-size: 11.5px;
                            padding: 2px 8px;
                            border-radius: 12px;
                            font-weight: 700;
                        }

                        .nav-tabs {
                            display: flex;
                            gap: 8px;
                            margin-bottom: 20px;
                            border-bottom: 2px solid #e5e7eb;
                        }

                        .nav-tab-item {
                            padding: 10px 18px;
                            font-size: 14.5px;
                            font-weight: 600;
                            text-decoration: none;
                            display: inline-flex;
                            align-items: center;
                            gap: 8px;
                            border-bottom: 3px solid transparent;
                            color: #64748b;
                            margin-bottom: -2px;
                            transition: all .15s ease;
                        }

                        .nav-tab-item:hover {
                            color: #1e293b;
                        }

                        .nav-tab-item.active {
                            border-bottom-color: #2563eb;
                            color: #2563eb;
                            font-weight: 700;
                        }

                        .tab-badge {
                            background: #ef4444;
                            color: #fff;
                            font-size: 11.5px;
                            padding: 2px 7px;
                            border-radius: 10px;
                            font-weight: 700;
                        }

                        .schedule-badge-overdue {
                            background: #fee2e2;
                            color: #b91c1c;
                            border: 1px solid #fecaca;
                            font-weight: 700;
                            padding: 3px 8px;
                            border-radius: 4px;
                            font-size: 11.5px;
                            display: inline-block;
                        }

                        .schedule-badge-duesoon {
                            background: #fef3c7;
                            color: #b45309;
                            border: 1px solid #fde68a;
                            font-weight: 700;
                            padding: 3px 8px;
                            border-radius: 4px;
                            font-size: 11.5px;
                            display: inline-block;
                        }

                        .schedule-badge-pending {
                            background: #e0f2fe;
                            color: #0369a1;
                            border: 1px solid #bae6fd;
                            font-weight: 600;
                            padding: 3px 8px;
                            border-radius: 4px;
                            font-size: 11.5px;
                            display: inline-block;
                        }

                        .schedule-badge-completed {
                            background: #dcfce7;
                            color: #15803d;
                            border: 1px solid #bbf7d0;
                            font-weight: 600;
                            padding: 3px 8px;
                            border-radius: 4px;
                            font-size: 11.5px;
                            display: inline-block;
                        }

                        .schedule-badge-cancelled {
                            background: #f3f4f6;
                            color: #6b7280;
                            border: 1px solid #e5e7eb;
                            font-weight: 500;
                            padding: 3px 8px;
                            border-radius: 4px;
                            font-size: 11.5px;
                            display: inline-block;
                        }

                        .pagination-controls {
                            display: flex;
                            gap: 4px;
                            align-items: center;
                        }

                        .page-btn {
                            min-width: 32px;
                            height: 32px;
                            padding: 0 8px;
                            border: 1px solid #d1d5db;
                            background: #fff;
                            color: #374151;
                            border-radius: 6px;
                            font-size: 13px;
                            font-weight: 500;
                            cursor: pointer;
                            display: inline-flex;
                            align-items: center;
                            justify-content: center;
                            transition: all .15s ease;
                        }

                        .page-btn:hover:not(:disabled) {
                            background: #f3f4f6;
                            border-color: #9ca3af;
                        }

                        .page-btn.active {
                            background: #2563eb;
                            color: #fff;
                            border-color: #2563eb;
                            font-weight: 700;
                        }

                        .page-btn:disabled {
                            opacity: 0.45;
                            cursor: not-allowed;
                        }
                    </style>
                </head>

                <body class="lab-manager-page">
                    <c:set var="activeMenu" value="maintenance" scope="request" />
                    <div class="app-shell">
                        <%@ include file="../includes/sidebar.jspf" %>
                            <main class="main-content">
                                <header class="topbar">
                                    <div class="heading-wrap">
                                        <button class="menu-button" id="menuButton" type="button"
                                            aria-label="Mở thanh điều hướng">
                                            <svg>
                                                <use href="#i-menu" />
                                            </svg>
                                        </button>
                                        <div>
                                            <h1>Quản lý &amp; Giám sát bảo trì</h1>
                                            <p>Theo dõi tiến độ sửa chữa thiết bị hỏng và quản lý kế hoạch bảo dưỡng
                                                định kỳ phòng lab</p>
                                        </div>
                                    </div>
                                    <div class="topbar-actions">
                                        <div class="top-profile">
                                            <div class="avatar">LM</div>
                                            <span>
                                                <c:out value="${currentUser.fullName}" />
                                            </span>
                                        </div>
                                    </div>
                                </header>

                                <section class="content-area">
                                    <%-- CẢNH BÁO LỊCH BẢO TRÌ ĐẾN HẠN / QUÁ HẠN (ALERT BANNER) --%>
                                        <c:if test="${not empty dueSchedules}">
                                            <div class="alert-banner">
                                                <div class="alert-banner-header">
                                                    <div
                                                        style="font-size: 14.5px; font-weight: 700; color: #92400e; display: flex; align-items: center; gap: 8px;">
                                                        <span>NHẮC NHỞ LỊCH BẢO TRÌ ĐỊNH KỲ</span>
                                                        <span class="alert-badge">${dueSchedules.size()} lịch cần thực
                                                            hiện</span>
                                                    </div>
                                                    <c:if test="${activeTab != 'schedules'}">
                                                        <a href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=schedules"
                                                            class="primary-button"
                                                            style="background: #d97706; font-size: 12.5px; padding: 6px 12px; height: auto; text-decoration: none;">
                                                            Xem chi tiết lịch bảo trì →
                                                        </a>
                                                    </c:if>
                                                </div>
                                                <div style="font-size: 13.5px; color: #78350f; line-height: 1.5;">
                                                    Phát hiện <b>${dueSchedules.size()}</b> thiết bị đến hạn bảo dưỡng
                                                    trong tuần này hoặc đã quá hạn:
                                                    <ul style="margin: 6px 0 0 20px; padding: 0;">
                                                        <c:forEach var="ds" items="${dueSchedules}" varStatus="status">
                                                            <c:if test="${status.index < 3}">
                                                                <li style="margin-bottom: 3px;">
                                                                    <b>
                                                                        <c:out value="${ds.title}" />
                                                                    </b> —
                                                                    <c:out value="${ds.assetName}" /> (
                                                                    <c:out
                                                                        value="${not empty ds.itemCode ? ds.itemCode : ds.assetCode}" />
                                                                    )
                                                                    <c:choose>
                                                                        <c:when test="${ds.overdue}">
                                                                            <span
                                                                                style="color: #dc2626; font-weight: 700;">(Đã
                                                                                quá hạn ${ds.daysDiff * -1} ngày)</span>
                                                                        </c:when>
                                                                        <c:when test="${ds.daysDiff == 0}">
                                                                            <span
                                                                                style="color: #ea580c; font-weight: 700;">(Đến
                                                                                hạn hôm nay!)</span>
                                                                        </c:when>
                                                                        <c:otherwise>
                                                                            <span
                                                                                style="color: #b45309; font-weight: 600;">(Hạn:
                                                                                ${app:date(ds.scheduledDate)} - Còn
                                                                                ${ds.daysDiff} ngày)</span>
                                                                        </c:otherwise>
                                                                    </c:choose>
                                                                </li>
                                                            </c:if>
                                                        </c:forEach>
                                                        <c:if test="${dueSchedules.size() > 3}">
                                                            <li><em>Và ${dueSchedules.size() - 3} thiết bị khác trong
                                                                    danh sách lịch...</em></li>
                                                        </c:if>
                                                    </ul>
                                                </div>
                                            </div>
                                        </c:if>

                                        <div class="content-heading">
                                            <div>
                                                <p class="eyebrow">FE-08 BẢO TRÌ &amp; BẢO DƯỠNG</p>
                                                <h2>
                                                    ${activeTab == 'schedules' ? 'Kế hoạch bảo trì định kỳ' : 'Danh sách
                                                    phiếu bảo trì'}
                                                    (${activeTab == 'schedules' ? schedules.size() : records.size()})
                                                </h2>
                                            </div>
                                            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                                                <c:choose>
                                                    <c:when test="${activeTab == 'schedules'}">
                                                        <a class="btn-secondary"
                                                            style="height: 38px; padding: 0 14px; font-size: 13px; display: inline-flex; align-items: center; gap: 6px; text-decoration: none;"
                                                            href="${pageContext.request.contextPath}/lab-manager/maintenance/schedules/template"
                                                            title="Tải file Excel mẫu để điền danh sách bảo trì">
                                                            Tải file mẫu Excel
                                                        </a>
                                                        <button class="btn-secondary" type="button"
                                                            style="height: 38px; padding: 0 14px; font-size: 13px; display: inline-flex; align-items: center; gap: 6px; cursor: pointer;"
                                                            onclick="document.getElementById('importScheduleModal').style.display='flex'">
                                                            Import Excel
                                                        </button>
                                                        <a class="primary-button"
                                                            href="${pageContext.request.contextPath}/lab-manager/maintenance/schedules/new">
                                                            <svg>
                                                                <use href="#i-plus" />
                                                            </svg>+ Lên lịch bảo trì mới
                                                        </a>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <a class="primary-button"
                                                            href="${pageContext.request.contextPath}/lab-manager/maintenance/new">
                                                            <svg>
                                                                <use href="#i-wrench" />
                                                            </svg>+ Tạo phiếu bảo trì
                                                        </a>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                        </div>

                                        <%-- THÔNG BÁO TRẠNG THÁI SUCCESS / ERROR --%>
                                            <c:if test="${not empty message}">
                                                <div class="error-message">
                                                    <c:out value="${message}" />
                                                </div>
                                            </c:if>
                                            <c:if test="${param.success == 'saved'}">
                                                <div class="success-message">Đã lưu thông tin phiếu bảo trì thành công.
                                                </div>
                                            </c:if>
                                            <c:if test="${param.success == 'deleted'}">
                                                <div class="success-message">Đã xóa phiếu bảo trì thành công. Thiết bị
                                                    đã được hoàn trả về trạng thái Sẵn sàng (AVAILABLE).</div>
                                            </c:if>
                                            <c:if test="${param.success == 'schedule_created'}">
                                                <div class="success-message">Đã tạo lịch bảo trì định kỳ mới thành công.
                                                </div>
                                            </c:if>
                                            <c:if test="${param.success == 'schedule_updated'}">
                                                <div class="success-message">Đã cập nhật thông tin lịch bảo trì thành
                                                    công.</div>
                                            </c:if>
                                            <c:if test="${param.success == 'status_updated'}">
                                                <div class="success-message">Đã cập nhật trạng thái lịch bảo trì thành
                                                    công.</div>
                                            </c:if>
                                            <c:if test="${param.success == 'schedule_deleted'}">
                                                <div class="success-message">Đã xóa lịch bảo trì định kỳ thành công.
                                                </div>
                                            </c:if>
                                            <c:if test="${param.success == 'batch_cancelled'}">
                                                <div class="success-message">Đã hủy các lịch bảo trì đã chọn thành công.
                                                </div>
                                            </c:if>
                                            <c:if test="${param.success == 'batch_deleted'}">
                                                <div class="success-message">Đã xóa các lịch bảo trì đã chọn khỏi hệ
                                                    thống thành công.</div>
                                            </c:if>
                                            <c:if test="${param.success == 'imported'}">
                                                <div class="success-message">
                                                    Đã nhập thành công <b>${param.count}</b> lịch bảo trì định kỳ từ
                                                    file Excel!
                                                    <c:if test="${not empty param.skipped and param.skipped > 0}">
                                                        <span
                                                            style="color: #92400e; font-weight: 500; margin-left: 6px;">(Đã
                                                            tự động bỏ qua <b>${param.skipped}</b> dòng bị trùng ngày
                                                            với lịch đã có trên hệ thống).</span>
                                                    </c:if>
                                                </div>
                                            </c:if>

                                            <%-- THANH CHUYỂN TAB --%>
                                                <div class="nav-tabs">
                                                    <a class="nav-tab-item ${activeTab != 'schedules' ? 'active' : ''}"
                                                        href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=tickets">
                                                        Phiếu sửa chữa &amp; Bảo trì
                                                        <c:if test="${not empty records}">
                                                            <span
                                                                style="background: #e2e8f0; color: #475569; font-size: 11.5px; padding: 2px 7px; border-radius: 10px;">${records.size()}</span>
                                                        </c:if>
                                                    </a>
                                                    <a class="nav-tab-item ${activeTab == 'schedules' ? 'active' : ''}"
                                                        href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=schedules">
                                                        Lịch bảo trì định kỳ
                                                        <c:if test="${dueSchedulesCount > 0}">
                                                            <span class="tab-badge">${dueSchedulesCount}</span>
                                                        </c:if>
                                                    </a>
                                                </div>

                                                <c:choose>
                                                    <%-- ══════════════════════════════════════════════════════════════════
                                                        TAB 2: LỊCH BẢO TRÌ ĐỊNH KỲ (SCHEDULES)
                                                        ══════════════════════════════════════════════════════════════════
                                                        --%>
                                                        <c:when test="${activeTab == 'schedules'}">
                                                            <form class="filter-bar" method="get"
                                                                action="${pageContext.request.contextPath}/lab-manager/maintenance">
                                                                <input type="hidden" name="tab" value="schedules">
                                                                <div class="filter-group">
                                                                    <input class="form-control" type="search"
                                                                        name="keyword"
                                                                        value="<c:out value='${keyword}'/>"
                                                                        placeholder="Tìm theo tiêu đề, tên thiết bị, kỹ thuật viên..."
                                                                        style="width:320px">
                                                                    <select class="form-control" name="status">
                                                                        <option value="">Tất cả trạng thái</option>
                                                                        <option value="PENDING"
                                                                            ${selectedStatus=='PENDING' ? 'selected'
                                                                            : '' }>Đang chờ thực hiện</option>
                                                                        <option value="COMPLETED"
                                                                            ${selectedStatus=='COMPLETED' ? 'selected'
                                                                            : '' }>Đã hoàn tất</option>
                                                                        <option value="CANCELLED"
                                                                            ${selectedStatus=='CANCELLED' ? 'selected'
                                                                            : '' }>Đã hủy</option>
                                                                    </select>
                                                                    <button class="primary-button" type="submit">Tìm
                                                                        kiếm</button>
                                                                    <a class="btn-secondary"
                                                                        href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=schedules">Đặt
                                                                        lại</a>
                                                                </div>
                                                            </form>

                                                            <article class="panel">
                                                                <c:choose>
                                                                    <c:when test="${empty schedules}">
                                                                        <div class="empty-box">
                                                                            <div class="empty-box-icon"><svg>
                                                                                    <use href="#i-calendar" />
                                                                                </svg></div>
                                                                            <h3>Chưa có lịch bảo trì định kỳ nào</h3>
                                                                            <p>Hãy lên kế hoạch bảo dưỡng định kỳ trước
                                                                                cho các thiết bị phòng lab để luôn sẵn
                                                                                sàng hoạt động.</p>
                                                                            <a class="primary-button"
                                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance/schedules/new">+
                                                                                Lên lịch bảo trì mới</a>
                                                                        </div>
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        <form id="batchScheduleForm" method="post"
                                                                            action="${pageContext.request.contextPath}/lab-manager/maintenance?csrfToken=${sessionScope.csrfToken}"
                                                                            style="margin:0;">
                                                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                                            <%-- THANH THAO TÁC HÀNG LOẠT (BATCH ACTION
                                                                                BAR) --%>
                                                                                <div id="batchActionBar"
                                                                                    style="display:none; background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; padding:10px 16px; margin-bottom:14px; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px;">
                                                                                    <div
                                                                                        style="font-size:13.5px; font-weight:600; color:#166534; display:flex; align-items:center; gap:8px;">
                                                                                        <span>Đã chọn <b
                                                                                                id="selectedCount"
                                                                                                style="color:#15803d; font-size:15px;">0</b>
                                                                                            lịch bảo trì</span>
                                                                                    </div>
                                                                                    <div
                                                                                        style="display:flex; gap:8px; align-items:center;">
                                                                                        <button type="submit"
                                                                                            name="action"
                                                                                            value="batchDeleteSchedules"
                                                                                            class="btn-secondary"
                                                                                            style="height:30px; padding:0 12px; font-size:12px; background:#fef2f2; color:#dc2626; border-color:#fecaca; cursor:pointer;"
                                                                                            onclick="return confirm('Bạn có chắc chắn muốn XÓA VĨNH VIỄN các lịch bảo trì đã chọn?');">
                                                                                            Xóa các lịch đã chọn
                                                                                        </button>
                                                                                        <button type="button"
                                                                                            class="btn-secondary"
                                                                                            style="height:30px; padding:0 10px; font-size:12px;"
                                                                                            onclick="clearAllSelections()">
                                                                                            Bỏ chọn
                                                                                        </button>
                                                                                    </div>
                                                                                </div>

                                                                                <div class="table-scroll">
                                                                                    <table>
                                                                                        <thead>
                                                                                            <tr>
                                                                                                <th
                                                                                                    style="width:40px; text-align:center;">
                                                                                                    <input
                                                                                                        type="checkbox"
                                                                                                        id="selectAllSchedules"
                                                                                                        onclick="toggleSelectAll(this)"
                                                                                                        title="Chọn tất cả"
                                                                                                        style="cursor:pointer; width:15px; height:15px; vertical-align:middle;">
                                                                                                </th>
                                                                                                <th>Mã lịch</th>
                                                                                                <th>Tiêu đề đợt bảo trì
                                                                                                </th>
                                                                                                <th>Thiết bị &amp; Vị
                                                                                                    trí</th>
                                                                                                <th>Ngày dự kiến</th>
                                                                                                <th>Đơn vị / Kỹ thuật
                                                                                                    viên</th>
                                                                                                <th>Dự toán</th>
                                                                                                <th>Trạng thái</th>
                                                                                                <th
                                                                                                    style="text-align:right;">
                                                                                                    Thao tác</th>
                                                                                            </tr>
                                                                                        </thead>
                                                                                        <tbody id="scheduleTableBody">
                                                                                            <c:forEach var="s"
                                                                                                items="${schedules}">
                                                                                                <tr
                                                                                                    style="${s.overdue ? 'background:#fff5f5;' : (s.dueSoon ? 'background:#fffdf5;' : '')}">
                                                                                                    <td
                                                                                                        style="text-align:center;">
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${s.status == 'COMPLETED'}">
                                                                                                                <span
                                                                                                                    style="color:#cbd5e1; font-size:15px; font-weight:bold;"
                                                                                                                    title="Lịch đã hoàn tất (Không thể thao tác/xóa)">—</span>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <input
                                                                                                                    type="checkbox"
                                                                                                                    name="selectedScheduleIds"
                                                                                                                    value="${s.scheduleId}"
                                                                                                                    class="schedule-checkbox"
                                                                                                                    onchange="onCheckboxChange()"
                                                                                                                    style="cursor:pointer; width:15px; height:15px; vertical-align:middle;">
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td><strong>#SCH-
                                                                                                            <c:out
                                                                                                                value="${s.scheduleId}" />
                                                                                                        </strong></td>
                                                                                                    <td>
                                                                                                        <strong>
                                                                                                            <c:out
                                                                                                                value="${s.title}" />
                                                                                                        </strong>
                                                                                                        <c:if
                                                                                                            test="${not empty s.note}">
                                                                                                            <small
                                                                                                                style="display:block;color:#64748b;margin-top:2px;">
                                                                                                                <c:out
                                                                                                                    value="${s.note}" />
                                                                                                            </small>
                                                                                                        </c:if>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:out
                                                                                                            value="${s.assetName}" />
                                                                                                        <small
                                                                                                            style="display:block;color:#5a6662">
                                                                                                            Mã:
                                                                                                            <c:out
                                                                                                                value="${not empty s.itemCode ? s.itemCode : s.assetCode}" />
                                                                                                            <c:if
                                                                                                                test="${not empty s.storageLocation}">
                                                                                                                • Vị
                                                                                                                trí:
                                                                                                                <c:out
                                                                                                                    value="${s.storageLocation}" />
                                                                                                            </c:if>
                                                                                                        </small>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <strong>${app:date(s.scheduledDate)}</strong>
                                                                                                        <c:if
                                                                                                            test="${s.status == 'PENDING'}">
                                                                                                            <c:choose>
                                                                                                                <c:when
                                                                                                                    test="${s.overdue}">
                                                                                                                    <small
                                                                                                                        style="display:block;color:#dc2626;font-weight:700;">Quá
                                                                                                                        hạn
                                                                                                                        ${s.daysDiff
                                                                                                                        *
                                                                                                                        -1}
                                                                                                                        ngày</small>
                                                                                                                </c:when>
                                                                                                                <c:when
                                                                                                                    test="${s.daysDiff == 0}">
                                                                                                                    <small
                                                                                                                        style="display:block;color:#ea580c;font-weight:700;">Đến
                                                                                                                        hạn
                                                                                                                        hôm
                                                                                                                        nay</small>
                                                                                                                </c:when>
                                                                                                                <c:otherwise>
                                                                                                                    <small
                                                                                                                        style="display:block;color:#64748b;">Còn
                                                                                                                        ${s.daysDiff}
                                                                                                                        ngày</small>
                                                                                                                </c:otherwise>
                                                                                                            </c:choose>
                                                                                                        </c:if>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${not empty s.providerName}">
                                                                                                                <c:out
                                                                                                                    value="${s.providerName}" />
                                                                                                                <c:if
                                                                                                                    test="${not empty s.providerPhone}">
                                                                                                                    <small
                                                                                                                        style="display:block;color:#2563eb;">
                                                                                                                        <c:out
                                                                                                                            value="${s.providerPhone}" />
                                                                                                                    </small>
                                                                                                                </c:if>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    style="color:#9ca3af;">—</span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${not empty s.estimatedCost}">
                                                                                                                <strong
                                                                                                                    style="color:#2563eb;">
                                                                                                                    <fmt:formatNumber
                                                                                                                        value="${s.estimatedCost}"
                                                                                                                        type="number"
                                                                                                                        groupingUsed="true" />
                                                                                                                    VNĐ
                                                                                                                </strong>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    style="color:#9ca3af;">—</span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${s.status == 'COMPLETED'}">
                                                                                                                <span
                                                                                                                    class="schedule-badge-completed">Đã
                                                                                                                    hoàn
                                                                                                                    tất</span>
                                                                                                            </c:when>
                                                                                                            <c:when
                                                                                                                test="${s.status == 'CANCELLED'}">
                                                                                                                <span
                                                                                                                    class="schedule-badge-cancelled">Đã
                                                                                                                    hủy</span>
                                                                                                            </c:when>
                                                                                                            <c:when
                                                                                                                test="${s.overdue}">
                                                                                                                <span
                                                                                                                    class="schedule-badge-overdue">Quá
                                                                                                                    hạn</span>
                                                                                                            </c:when>
                                                                                                            <c:when
                                                                                                                test="${s.dueSoon}">
                                                                                                                <span
                                                                                                                    class="schedule-badge-duesoon">Sắp
                                                                                                                    đến
                                                                                                                    hạn</span>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    class="schedule-badge-pending">Đang
                                                                                                                    chờ</span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td
                                                                                                        style="text-align:right;white-space:nowrap;">
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${s.status == 'PENDING'}">
                                                                                                                <div class="single-row-actions"
                                                                                                                    style="display:inline-flex; gap:6px;">
                                                                                                                    <%-- Nút
                                                                                                                        tạo
                                                                                                                        phiếu
                                                                                                                        bảo
                                                                                                                        trì
                                                                                                                        nhanh
                                                                                                                        từ
                                                                                                                        lịch
                                                                                                                        --%>
                                                                                                                        <a class="btn-secondary"
                                                                                                                            style="height:24px;padding:0 8px;font-size:11px;background:#e0f2fe;color:#0284c7;border-color:#bae6fd;font-weight:600;"
                                                                                                                            href="${pageContext.request.contextPath}/lab-manager/maintenance/new?assetId=${s.assetId}&itemCode=${s.itemCode}&scheduleId=${s.scheduleId}&note=${s.providerName}&providerPhone=${s.providerPhone}&estimatedCost=${s.estimatedCost}&description=${s.title}"
                                                                                                                            title="Tạo phiếu bảo trì cho thiết bị này">
                                                                                                                            +
                                                                                                                            Tạo
                                                                                                                            phiếu
                                                                                                                        </a>

                                                                                                                        <%-- Chỉnh
                                                                                                                            sửa
                                                                                                                            lịch
                                                                                                                            --%>
                                                                                                                            <a class="btn-secondary"
                                                                                                                                style="height:24px;padding:0 8px;font-size:11px;"
                                                                                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance/schedules/${s.scheduleId}/edit">
                                                                                                                                Sửa
                                                                                                                            </a>
                                                                                                                </div>
                                                                                                                <span
                                                                                                                    class="batch-mode-dash"
                                                                                                                    style="display:none; color:#cbd5e1; font-size:15px; font-weight:bold;">—</span>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    style="color:#9ca3af;font-size:12px;">—</span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                </tr>
                                                                                            </c:forEach>
                                                                                        </tbody>
                                                                                    </table>
                                                                                </div>

                                                                                <%-- THANH PHÂN TRANG (PAGINATION) --%>
                                                                                    <div class="table-footer"
                                                                                        style="display:flex; align-items:center; justify-content:space-between; padding:12px 18px; border-top:1px solid #edf0ec; font-size:13px; color:#68736f; flex-wrap:wrap; gap:12px;">
                                                                                        <div
                                                                                            style="display:flex; align-items:center; gap:8px;">
                                                                                            <span>Hiển thị</span>
                                                                                            <select
                                                                                                id="schedulePageSizeSelect"
                                                                                                class="form-control"
                                                                                                style="width:auto; height:32px; padding:4px 8px; font-size:13px;"
                                                                                                onchange="changeSchedulePageSize(this.value)">
                                                                                                <option value="5">5
                                                                                                </option>
                                                                                                <option value="10"
                                                                                                    selected>10</option>
                                                                                                <option value="20">20
                                                                                                </option>
                                                                                                <option value="50">50
                                                                                                </option>
                                                                                            </select>
                                                                                            <span>lịch bảo trì mỗi
                                                                                                trang</span>
                                                                                        </div>
                                                                                        <span
                                                                                            id="schedulePageInfoText">Hiển
                                                                                            thị 1 đến
                                                                                            ${schedules.size()} trong
                                                                                            tổng số ${schedules.size()}
                                                                                            lịch bảo trì</span>
                                                                                        <div class="pagination-controls"
                                                                                            id="schedulePaginationControls">
                                                                                        </div>
                                                                                    </div>
                                                                        </form>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </article>
                                                        </c:when>

                                                        <%-- ══════════════════════════════════════════════════════════════════
                                                            TAB 1: PHIẾU BẢO TRÌ (TICKETS) - MẶC ĐỊNH
                                                            ══════════════════════════════════════════════════════════════════
                                                            --%>
                                                            <c:otherwise>
                                                                <%-- THỐNG KÊ TÀI CHÍNH BẢO TRÌ --%>
                                                                    <c:if test="${not empty summary}">
                                                                        <div
                                                                            style="display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:20px;">
                                                                            <div
                                                                                style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                                                                                <div
                                                                                    style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">
                                                                                    Tổng phiếu</div>
                                                                                <div
                                                                                    style="font-size:28px; font-weight:700; color:#1e293b; margin-top:4px;">
                                                                                    ${summary.totalRecords()}</div>
                                                                            </div>
                                                                            <div
                                                                                style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                                                                                <div
                                                                                    style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">
                                                                                    Đang sửa chữa</div>
                                                                                <div
                                                                                    style="font-size:28px; font-weight:700; color:#f59e0b; margin-top:4px;">
                                                                                    ${summary.inProgressCount()}</div>
                                                                            </div>
                                                                            <div
                                                                                style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                                                                                <div
                                                                                    style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">
                                                                                    Đã hoàn thành</div>
                                                                                <div
                                                                                    style="font-size:28px; font-weight:700; color:#10b981; margin-top:4px;">
                                                                                    ${summary.completedCount()}</div>
                                                                            </div>
                                                                            <div
                                                                                style="background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:18px 20px;">
                                                                                <div
                                                                                    style="font-size:12px; color:#6b7280; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">
                                                                                    Tổng chi phí đã chi</div>
                                                                                <div
                                                                                    style="font-size:28px; font-weight:700; color:#2563eb; margin-top:4px;">
                                                                                    <fmt:formatNumber
                                                                                        value="${summary.totalActualCost()}"
                                                                                        type="number"
                                                                                        groupingUsed="true" /> <span
                                                                                        style="font-size:14px; font-weight:500;">VNĐ</span>
                                                                                </div>
                                                                            </div>
                                                                        </div>
                                                                    </c:if>

                                                                    <form class="filter-bar" method="get"
                                                                        action="${pageContext.request.contextPath}/lab-manager/maintenance">
                                                                        <input type="hidden" name="tab" value="tickets">
                                                                        <div class="filter-group">
                                                                            <input class="form-control" type="search"
                                                                                name="keyword"
                                                                                value="<c:out value='${keyword}'/>"
                                                                                placeholder="Tìm theo mã phiếu, tên thiết bị, thợ sửa..."
                                                                                style="width:300px">
                                                                            <select class="form-control" name="status">
                                                                                <option value="">Tất cả trạng thái
                                                                                </option>
                                                                                <option value="IN_PROGRESS"
                                                                                    ${selectedStatus=='IN_PROGRESS'
                                                                                    ? 'selected' : '' }>Đang sửa chữa
                                                                                </option>
                                                                                <option value="COMPLETED"
                                                                                    ${selectedStatus=='COMPLETED'
                                                                                    ? 'selected' : '' }>Hoàn tất
                                                                                </option>
                                                                            </select>
                                                                            <button class="primary-button"
                                                                                type="submit">Tìm kiếm</button>
                                                                            <a class="btn-secondary"
                                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance?tab=tickets">Đặt
                                                                                lại</a>
                                                                        </div>
                                                                    </form>

                                                                    <article class="panel">
                                                                        <c:choose>
                                                                            <c:when test="${empty records}">
                                                                                <div class="empty-box">
                                                                                    <div class="empty-box-icon"><svg>
                                                                                            <use href="#i-wrench" />
                                                                                        </svg></div>
                                                                                    <h3>Chưa có phiếu bảo trì nào</h3>
                                                                                    <p>Bấm vào nút bên dưới để tạo phiếu
                                                                                        bảo trì và đưa thiết bị đi sửa
                                                                                        chữa.</p>
                                                                                    <a class="primary-button"
                                                                                        href="${pageContext.request.contextPath}/lab-manager/maintenance/new">+
                                                                                        Tạo phiếu bảo trì</a>
                                                                                </div>
                                                                            </c:when>
                                                                            <c:otherwise>
                                                                                <div class="table-scroll">
                                                                                    <table>
                                                                                        <thead>
                                                                                            <tr>
                                                                                                <th>Mã phiếu</th>
                                                                                                <th>Thiết bị</th>
                                                                                                <th>SL</th>
                                                                                                <th>Mô tả yêu cầu sửa
                                                                                                    chữa</th>
                                                                                                <th>Kinh phí</th>
                                                                                                <th>Ngày tạo</th>
                                                                                                <th>Trạng thái</th>
                                                                                                <th>Thao tác</th>
                                                                                            </tr>
                                                                                        </thead>
                                                                                        <tbody>
                                                                                            <c:forEach var="r"
                                                                                                items="${records}">
                                                                                                <tr>
                                                                                                    <td><strong>#MNT-
                                                                                                            <c:out
                                                                                                                value="${r.maintenanceId}" />
                                                                                                        </strong></td>
                                                                                                    <td>
                                                                                                        <c:out
                                                                                                            value="${r.assetName}" />
                                                                                                        <small
                                                                                                            style="display:block;color:#5a6662">
                                                                                                            <c:out
                                                                                                                value="${not empty r.assetItemCode ? r.assetItemCode : r.assetCode}" />
                                                                                                        </small>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:out
                                                                                                            value="${r.quantity}" />
                                                                                                    </td>
                                                                                                    <td
                                                                                                        style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                                                                                                        <c:out
                                                                                                            value="${r.description}" />
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${not empty r.actualCost}">
                                                                                                                <strong
                                                                                                                    style="color:#2563eb;">
                                                                                                                    <fmt:formatNumber
                                                                                                                        value="${r.actualCost}"
                                                                                                                        type="number"
                                                                                                                        groupingUsed="true" />
                                                                                                                    VNĐ
                                                                                                                </strong>
                                                                                                            </c:when>
                                                                                                            <c:when
                                                                                                                test="${not empty r.estimatedCost}">
                                                                                                                <small
                                                                                                                    style="color:#6b7280;">Dự
                                                                                                                    toán:<br><strong>
                                                                                                                        <fmt:formatNumber
                                                                                                                            value="${r.estimatedCost}"
                                                                                                                            type="number"
                                                                                                                            groupingUsed="true" />
                                                                                                                        VNĐ
                                                                                                                    </strong></small>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    style="color:#9ca3af;">—</span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:out
                                                                                                            value="${app:dateTime(r.requestedAt)}" />
                                                                                                    </td>
                                                                                                    <td>
                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${r.status == 'IN_PROGRESS'}">
                                                                                                                <span
                                                                                                                    class="status maintenance">Đang
                                                                                                                    sửa
                                                                                                                    chữa</span>
                                                                                                            </c:when>
                                                                                                            <c:when
                                                                                                                test="${r.status == 'COMPLETED'}">
                                                                                                                <c:choose>
                                                                                                                    <c:when
                                                                                                                        test="${r.assetStatus == 'UNAVAILABLE'}">
                                                                                                                        <span
                                                                                                                            class="status overdue">Sửa
                                                                                                                            thất
                                                                                                                            bại</span>
                                                                                                                    </c:when>
                                                                                                                    <c:otherwise>
                                                                                                                        <span
                                                                                                                            class="status returned">Đã
                                                                                                                            sửa
                                                                                                                            xong</span>
                                                                                                                    </c:otherwise>
                                                                                                                </c:choose>
                                                                                                            </c:when>
                                                                                                            <c:otherwise>
                                                                                                                <span
                                                                                                                    class="status">
                                                                                                                    <c:out
                                                                                                                        value="${r.status}" />
                                                                                                                </span>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </td>
                                                                                                    <td
                                                                                                        style="white-space:nowrap;">
                                                                                                        <a class="btn-secondary"
                                                                                                            style="height:24px;padding:0 8px;font-size:11px"
                                                                                                            href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}">Xem</a>
                                                                                                        <c:if
                                                                                                            test="${r.status == 'IN_PROGRESS'}">
                                                                                                            <a class="btn-secondary"
                                                                                                                style="height:24px;padding:0 8px;font-size:11px;background:#e8f0fe;color:#1a73e8;border-color:#aecbfa;font-weight:600;"
                                                                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}/edit">
                                                                                                                Tiến độ
                                                                                                            </a>
                                                                                                            <form
                                                                                                                method="post"
                                                                                                                action="${pageContext.request.contextPath}/lab-manager/maintenance?csrfToken=${sessionScope.csrfToken}"
                                                                                                                onsubmit="return confirm('Bạn có chắc chắn muốn xóa phiếu bảo trì #MNT-${r.maintenanceId}? Thiết bị sẽ được trả về trạng thái Sẵn sàng.');"
                                                                                                                style="display:inline;margin:0;">
                                                                                                                <input
                                                                                                                    type="hidden"
                                                                                                                    name="csrfToken"
                                                                                                                    value="${sessionScope.csrfToken}">
                                                                                                                <input
                                                                                                                    type="hidden"
                                                                                                                    name="action"
                                                                                                                    value="delete">
                                                                                                                <input
                                                                                                                    type="hidden"
                                                                                                                    name="id"
                                                                                                                    value="${r.maintenanceId}">
                                                                                                                <button
                                                                                                                    class="btn-secondary"
                                                                                                                    type="submit"
                                                                                                                    style="height:24px;padding:0 8px;font-size:11px;background:#fde8e8;color:#c62828;border-color:#f8b4b4;font-weight:600;cursor:pointer;">
                                                                                                                    Xóa
                                                                                                                </button>
                                                                                                            </form>
                                                                                                        </c:if>
                                                                                                        <c:if
                                                                                                            test="${r.status == 'COMPLETED'}">
                                                                                                            <a class="btn-secondary"
                                                                                                                style="height:24px;padding:0 8px;font-size:11px;background:#f3f4f6;color:#374151;border-color:#d1d5db;font-weight:500;"
                                                                                                                href="${pageContext.request.contextPath}/lab-manager/maintenance/${r.maintenanceId}/edit">
                                                                                                                Sửa
                                                                                                            </a>
                                                                                                        </c:if>
                                                                                                    </td>
                                                                                                </tr>
                                                                                            </c:forEach>
                                                                                        </tbody>
                                                                                    </table>
                                                                                </div>
                                                                            </c:otherwise>
                                                                        </c:choose>
                                                                    </article>
                                                            </c:otherwise>
                                                </c:choose>
                                </section>
                            </main>
                    </div>

                    <%-- MODAL IMPORT EXCEL --%>
                        <div id="importScheduleModal"
                            style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(15,23,42,0.6); backdrop-filter:blur(2px); z-index:9999; align-items:center; justify-content:center;">
                            <div
                                style="background:#fff; border-radius:12px; width:100%; max-width:520px; box-shadow:0 20px 25px -5px rgba(0,0,0,0.2); overflow:hidden; animation: fadeIn .15s ease;">
                                <div
                                    style="padding:18px 24px; border-bottom:1px solid #f1f5f9; display:flex; justify-content:space-between; align-items:center;">
                                    <h3
                                        style="margin:0; font-size:17px; font-weight:700; color:#1e293b; display:flex; align-items:center; gap:8px;">
                                        Nhập lịch bảo trì từ File Excel
                                    </h3>
                                    <button type="button"
                                        onclick="document.getElementById('importScheduleModal').style.display='none'"
                                        style="background:none; border:none; font-size:20px; cursor:pointer; color:#94a3b8;">✕</button>
                                </div>
                                <form method="post" action="${pageContext.request.contextPath}/lab-manager/maintenance?csrfToken=${sessionScope.csrfToken}"
                                    enctype="multipart/form-data" style="margin:0;">
                                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                    <input type="hidden" name="action" value="importSchedules">
                                    <div style="padding:24px;">
                                        <p style="margin:0 0 16px 0; font-size:13.5px; color:#64748b; line-height:1.5;">
                                            Chọn tệp tin định dạng <code>.xlsx</code> chứa danh sách kế hoạch bảo trì.
                                            Nếu bạn chưa có file mẫu chuẩn, vui lòng tải file mẫu bên dưới.
                                        </p>
                                        <div
                                            style="margin-bottom:18px; padding:12px 16px; background:#eff6ff; border:1px solid #bfdbfe; border-radius:8px; display:flex; justify-content:space-between; align-items:center;">
                                            <span style="font-size:13px; color:#1e40af; font-weight:600;">File mẫu có
                                                sẵn cột &amp; mã máy:</span>
                                            <a href="${pageContext.request.contextPath}/lab-manager/maintenance/schedules/template"
                                                style="font-size:12.5px; color:#2563eb; font-weight:700; text-decoration:none;">
                                                Tải file mẫu .xlsx
                                            </a>
                                        </div>
                                        <div
                                            style="border:2px dashed #cbd5e1; border-radius:8px; padding:24px 16px; text-align:center; background:#f8fafc;">
                                            <input type="file" name="excelFile"
                                                accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                                                required style="font-size:13.5px; color:#334155;">
                                            <small
                                                style="display:block; margin-top:8px; font-size:12px; color:#94a3b8;">Hỗ
                                                trợ Microsoft Excel (.xlsx)</small>
                                        </div>
                                    </div>
                                    <div
                                        style="padding:14px 24px; background:#f8fafc; border-top:1px solid #f1f5f9; display:flex; justify-content:flex-end; gap:10px;">
                                        <button type="button" class="btn-secondary"
                                            onclick="document.getElementById('importScheduleModal').style.display='none'"
                                            style="height:36px; padding:0 16px;">Hủy</button>
                                        <button type="submit" class="primary-button"
                                            style="height:36px; padding:0 18px;">Bắt đầu nạp dữ liệu</button>
                                    </div>
                                </form>
                            </div>
                        </div>

                        <script>
                            function toggleSelectAll(master) {
                                const checkboxes = document.querySelectorAll('.schedule-checkbox');
                                checkboxes.forEach(cb => cb.checked = master.checked);
                                updateBatchBar();
                            }

                            function onCheckboxChange() {
                                const checkboxes = document.querySelectorAll('.schedule-checkbox');
                                const master = document.getElementById('selectAllSchedules');
                                const checkedCount = document.querySelectorAll('.schedule-checkbox:checked').length;
                                if (master) master.checked = (checkedCount > 0 && checkedCount === checkboxes.length);
                                updateBatchBar();
                            }

                            function updateBatchBar() {
                                const checkedCount = document.querySelectorAll('.schedule-checkbox:checked').length;
                                const bar = document.getElementById('batchActionBar');
                                const countSpan = document.getElementById('selectedCount');
                                if (bar && countSpan) {
                                    countSpan.textContent = checkedCount;
                                    bar.style.display = checkedCount > 0 ? 'flex' : 'none';
                                }

                                // Smart UI: Ẩn các nút thao tác đơn lẻ khi đang tích chọn hàng loạt để tránh hiểu lầm
                                const isBatchActive = (checkedCount > 0);
                                document.querySelectorAll('.single-row-actions').forEach(el => {
                                    el.style.display = isBatchActive ? 'none' : 'inline-flex';
                                });
                                document.querySelectorAll('.batch-mode-dash').forEach(el => {
                                    el.style.display = isBatchActive ? 'inline' : 'none';
                                });
                            }

                            function clearAllSelections() {
                                const checkboxes = document.querySelectorAll('.schedule-checkbox');
                                checkboxes.forEach(cb => cb.checked = false);
                                const master = document.getElementById('selectAllSchedules');
                                if (master) master.checked = false;
                                updateBatchBar();
                            }

                            // ─── PAGINATION FOR SCHEDULES TABLE ───
                            let currentSchedulePage = 1;
                            let schedulePageSize = 10;

                            function renderSchedulePagination() {
                                const rows = document.querySelectorAll('#scheduleTableBody tr');
                                const totalRows = rows.length;
                                if (totalRows === 0) return;

                                const totalPages = Math.max(1, Math.ceil(totalRows / schedulePageSize));
                                if (currentSchedulePage > totalPages) currentSchedulePage = totalPages;

                                const start = (currentSchedulePage - 1) * schedulePageSize;
                                const end = Math.min(start + schedulePageSize, totalRows);

                                rows.forEach((row, idx) => {
                                    row.style.display = (idx >= start && idx < end) ? '' : 'none';
                                });

                                const info = document.getElementById('schedulePageInfoText');
                                if (info) {
                                    info.innerText = 'Hiển thị ' + (start + 1) + ' đến ' + end + ' trong tổng số ' + totalRows + ' lịch bảo trì';
                                }

                                const container = document.getElementById('schedulePaginationControls');
                                if (!container) return;
                                container.innerHTML = '';

                                // Prev button
                                const prevBtn = document.createElement('button');
                                prevBtn.type = 'button';
                                prevBtn.className = 'page-btn';
                                prevBtn.innerText = '‹';
                                prevBtn.disabled = (currentSchedulePage === 1);
                                prevBtn.onclick = () => {
                                    if (currentSchedulePage > 1) {
                                        currentSchedulePage--;
                                        renderSchedulePagination();
                                    }
                                };
                                container.appendChild(prevBtn);

                                // Page number buttons
                                for (let p = 1; p <= totalPages; p++) {
                                    const pBtn = document.createElement('button');
                                    pBtn.type = 'button';
                                    pBtn.className = 'page-btn' + (p === currentSchedulePage ? ' active' : '');
                                    pBtn.innerText = p;
                                    pBtn.onclick = () => {
                                        currentSchedulePage = p;
                                        renderSchedulePagination();
                                    };
                                    container.appendChild(pBtn);
                                }

                                // Next button
                                const nextBtn = document.createElement('button');
                                nextBtn.type = 'button';
                                nextBtn.className = 'page-btn';
                                nextBtn.innerText = '›';
                                nextBtn.disabled = (currentSchedulePage === totalPages);
                                nextBtn.onclick = () => {
                                    if (currentSchedulePage < totalPages) {
                                        currentSchedulePage++;
                                        renderSchedulePagination();
                                    }
                                };
                                container.appendChild(nextBtn);
                            }

                            function changeSchedulePageSize(val) {
                                schedulePageSize = parseInt(val, 10) || 10;
                                currentSchedulePage = 1;
                                renderSchedulePagination();
                            }

                            document.addEventListener('DOMContentLoaded', () => {
                                renderSchedulePagination();
                            });
                        </script>
                </body>

                </html>