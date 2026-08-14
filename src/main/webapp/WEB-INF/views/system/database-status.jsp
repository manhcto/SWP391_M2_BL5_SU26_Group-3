<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trạng thái database</title></head>
<body>
<main>
    <h1>Kiểm tra kết nối database</h1>
    <p>Trạng thái: <strong>${databaseStatus.connected ? 'Thành công' : 'Thất bại'}</strong></p>
    <p>${databaseStatus.message}</p>
    <p><a href="${pageContext.request.contextPath}/system/database-status">Kiểm tra lại</a> · <a href="${pageContext.request.contextPath}/">Trang chủ</a></p>
</main>
</body>
</html>
