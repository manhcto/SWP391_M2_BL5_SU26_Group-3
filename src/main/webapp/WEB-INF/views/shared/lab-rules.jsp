<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<c:set var="activeMenu" value="labRules" scope="request"/>
<c:choose>
    <c:when test="${roleBase == '/lab-manager'}"><c:set var="pageClass" value="lab-manager-page"/><c:set var="portalName" value="CỔNG QUẢN LÝ PHÒNG LAB"/></c:when>
    <c:when test="${roleBase == '/mentor'}"><c:set var="pageClass" value="mentor-page"/><c:set var="portalName" value="CỔNG NGƯỜI HƯỚNG DẪN"/></c:when>
    <c:otherwise><c:set var="pageClass" value="intern-dashboard-page"/><c:set var="portalName" value="CỔNG THỰC TẬP SINH"/></c:otherwise>
</c:choose>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nội quy phòng lab | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
</head>
<body class="${pageClass}">
<div class="app-shell">
    <c:choose>
        <c:when test="${roleBase == '/lab-manager'}"><%@ include file="../labmanager/includes/sidebar.jspf"%></c:when>
        <c:when test="${roleBase == '/mentor'}"><%@ include file="../mentor/includes/sidebar.jspf"%></c:when>
        <c:otherwise><%@ include file="../student/includes/sidebar.jspf"%></c:otherwise>
    </c:choose>
    <main class="main-content">
        <header class="topbar">
            <div class="heading-wrap">
                <button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button>
                <div><h1>Nội quy phòng lab</h1><p>Quy định sử dụng phòng LAB và trách nhiệm theo từng vai trò</p></div>
            </div>
            <div class="topbar-actions"><div class="top-profile"><div class="avatar">LAB</div><span><c:out value="${currentUser.fullName}"/></span></div></div>
        </header>

        <section class="content-area lab-rules-page">
            <div class="content-heading">
                <div><p class="eyebrow">${portalName}</p><h2>Bảng nội quy chung</h2></div>
            </div>

            <article class="panel rules-panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-grid"/></svg></span><h3>Quy định áp dụng cho tất cả người dùng</h3></div></header>
                <div class="rules-grid">
                    <section class="rule-card"><h3>1. Ra vào và sử dụng phòng</h3><p>Chỉ sử dụng phòng LAB trong phạm vi được phân quyền, giữ trật tự, không tự ý di chuyển bàn ghế, thiết bị cố định hoặc tài sản chung.</p></section>
                    <section class="rule-card"><h3>2. Mượn và trả thiết bị</h3><p>Mọi thiết bị mượn phải được ghi nhận trên hệ thống, dùng đúng mục đích học tập hoặc làm việc, trả đúng hạn và đúng tình trạng đã nhận.</p></section>
                    <section class="rule-card"><h3>3. Bảo quản tài sản</h3><p>Không tháo lắp, sửa chữa, cài đặt lại hoặc chuyển giao thiết bị cho người khác khi chưa được người phụ trách cho phép.</p></section>
                    <section class="rule-card"><h3>4. Báo cáo bất thường</h3><p>Khi phát hiện mất mát, hư hỏng, sai số lượng hoặc nguy cơ mất an toàn, phải báo ngay trên hệ thống hoặc cho người phụ trách phòng LAB.</p></section>
                    <section class="rule-card"><h3>5. An toàn và bảo mật</h3><p>Không chia sẻ tài khoản, không lưu dữ liệu cá nhân trên máy dùng chung, không mang chất dễ cháy nổ hoặc đồ ăn nước uống gần thiết bị.</p></section>
                    <section class="rule-card"><h3>6. Trách nhiệm cá nhân</h3><p>Người dùng chịu trách nhiệm với tài sản được giao, thông tin đã nhập và các thao tác thực hiện bằng tài khoản của mình.</p></section>
                </div>
            </article>

            <article class="panel rules-panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-users"/></svg></span><h3>Trách nhiệm theo vai trò</h3></div></header>
                <div class="role-rules">
                    <section><h3>Quản Trị Viên</h3><p>Quản lý tài khoản, phân quyền đúng vai trò, phê duyệt danh sách thực tập sinh theo học kỳ và đảm bảo dữ liệu người dùng được cập nhật chính xác.</p></section>
                    <section><h3>Quản Lý Phòng Lab</h3><p>Theo dõi tài sản toàn phòng, kiểm tra định kỳ, xử lý sự cố nghiêm trọng, duyệt trách nhiệm mức cao và quyết định bảo trì hoặc thanh lý khi cần.</p></section>
                    <section><h3>Người Hướng Dẫn</h3><p>Quản lý danh sách thực tập sinh, hướng dẫn sử dụng thiết bị, kiểm tra việc mượn trả, ghi nhận sự cố và lập kết luận trách nhiệm sau khi xác minh.</p></section>
                    <section><h3>Thực Tập Sinh</h3><p>Chỉ mượn thiết bị khi có nhu cầu hợp lệ, sử dụng cẩn thận, trả đúng hạn, báo cáo sự cố trung thực và theo dõi trách nhiệm cá nhân trên hệ thống.</p></section>
                </div>
            </article>

            <article class="panel rules-panel">
                <header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-alert"/></svg></span><h3>Quy chế xử phạt</h3></div></header>
                <div class="role-rules">
                    <section><h3>Vi phạm nhẹ</h3><p>Các lỗi như quên cập nhật trạng thái mượn trả, để khu vực sử dụng chưa gọn hoặc vi phạm nội quy lần đầu sẽ được nhắc nhở và ghi nhận để theo dõi.</p></section>
                    <section><h3>Hư hỏng nhẹ</h3><p>Nếu Mentor có thể khắc phục an toàn, Mentor trực tiếp xử lý và hướng dẫn lại người dùng. Trường hợp này không cần lập sự cố gửi Lab Manager.</p></section>
                    <section><h3>Sự cố nghiêm trọng</h3><p>Mất thiết bị, hư hỏng không thể tự sửa, nguy cơ mất an toàn hoặc ảnh hưởng hoạt động LAB phải báo ngay cho Lab Manager để xác minh và lập hồ sơ trách nhiệm.</p></section>
                    <section><h3>Đền bù và hạn chế quyền</h3><p>Mức đền bù dựa trên kết luận xác minh; chỉ Mentor hoặc Lab Manager được cập nhật quyết định này. Vi phạm lặp lại hoặc cố ý có thể bị tạm dừng quyền mượn thiết bị.</p></section>
                </div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
