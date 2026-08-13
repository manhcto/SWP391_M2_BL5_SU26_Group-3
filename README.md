# LAB Asset Management

Ứng dụng web quản lý việc đặt và sử dụng một phòng LAB cố định, tài sản trong phòng, quá trình bàn giao và trách nhiệm phát sinh trong thời gian sử dụng.

## Phạm vi (Scope)

Hệ thống hỗ trợ:

- Quản lý tài khoản, vai trò và quyền.
- Lecturer tạo Booking cho một Student Group và chỉ định Group Representative.
- Lab Manager duyệt Booking và từng tài sản hạn chế được đăng ký.
- Lab Staff bàn giao, nhận lại LAB và ghi nhận No-show.
- Quản lý hồ sơ, hiện trạng, bảo trì và kiểm kê tài sản.
- Báo cáo, xác minh và kết luận sự cố.
- Dừng Booking khi phát hiện nguy cơ an toàn.
- Xem báo cáo vận hành theo khoảng thời gian.

Hệ thống không quản lý nhiều phòng LAB, vật tư tiêu hao, kho, thanh toán, công nợ, kỷ luật hoặc lịch bảo trì định kỳ.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Quản lý tài khoản, vai trò và ma trận quyền |
| Lab Manager | Duyệt Booking, giám sát tài sản và xem báo cáo |
| Lab Staff | Bàn giao LAB, quản lý hiện trạng tài sản, sự cố, bảo trì và kiểm kê |
| Lecturer | Tạo Booking, nhận/trả LAB và đại diện Student Group chịu trách nhiệm |
| Group Representative | Xem thông tin Booking và báo sự cố với tư cách đầu mối của nhóm |

## Quy tắc cốt lõi

- Một Booking dành toàn bộ LAB cho đúng một Student Group trong một khoảng thời gian.
- Chỉ Booking đã duyệt giữ lịch; các Booking đã duyệt phải cách nhau ít nhất 15 phút.
- Người tạo Booking không được tự duyệt Booking đó.
- Lecturer phải có mặt khi nhận và trả LAB; Group Representative không được ký thay.
- Lecturer vắng quá 15 phút từ giờ bắt đầu có thể bị ghi nhận No-show.
- Tài sản dùng chung được bàn giao cùng LAB. Tài sản hạn chế phải đăng ký và được duyệt riêng.
- Tài sản không khả dụng không được bàn giao hoặc sử dụng.
- Checklist nhận và trả gồm toàn bộ tài sản đang được quản lý.
- Hệ thống lưu kết luận, hướng xử lý và chi phí ước tính nhưng không thu tiền hoặc thi hành kỷ luật.

Nội dung trên được tổng hợp từ `LAB-Asset-Management/CONTEXT.md` và `LAB-Asset-Management/docs/CORE-USE-CASES.md`.

## Công nghệ

- Java 17
- Jakarta EE Web 10
- JSP và JSTL
- Microsoft SQL Server
- Maven Wrapper
- Apache Tomcat 10.1 qua Cargo Maven plugin
- JUnit 5

## Yêu cầu

- JDK 17
- SQL Server
- Không cần cài Maven toàn cục vì dự án có Maven Wrapper

## Cấu hình

Sao chép `.env.example` thành `.env` và cập nhật thông tin kết nối cục bộ:

```dotenv
DB_URL=jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true
DB_USERNAME=sa
DB_PASSWORD=change-me
```

`AppConfig` ưu tiên biến môi trường của hệ điều hành; `.env` chỉ phục vụ phát triển cục bộ và đã được bỏ qua bởi Git.

## Chạy dự án

Windows:

```powershell
.\mvnw.cmd clean package
.\mvnw.cmd cargo:run
```

Linux hoặc macOS:

```bash
./mvnw clean package
./mvnw cargo:run
```

Mở `http://localhost:8080/labtoolequip/`. Dừng server bằng `Ctrl+C`.

Chạy kiểm tra và định dạng:

```powershell
.\mvnw.cmd test
.\mvnw.cmd spotless:check
```

## Cấu trúc dự án

```text
src/
|-- main/
|   |-- java/fpt/swp391/labtoolequip/
|   |   |-- config/       # Cấu hình ứng dụng
|   |   |-- controller/   # Servlet và HTTP controller
|   |   |-- model/        # Entity và value object nghiệp vụ
|   |   |-- repository/   # Truy cập dữ liệu
|   |   `-- service/      # Use case và quy tắc nghiệp vụ
|   |-- resources/META-INF/
|   |   |-- beans.xml
|   |   `-- persistence.xml
|   `-- webapp/
|       |-- assets/
|       |   |-- css/
|       |   `-- js/
|       |-- WEB-INF/
|       |   |-- views/    # JSP không truy cập trực tiếp
|       |   `-- web.xml
|       `-- index.jsp
`-- test/java/fpt/swp391/labtoolequip/
```

Đây là bộ khung ban đầu. Các package chỉ được bổ sung lớp khi triển khai use case cụ thể để tránh tạo abstraction chưa cần thiết.
