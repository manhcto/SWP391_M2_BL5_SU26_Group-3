# LAB Asset Management System

Ứng dụng web nội bộ hỗ trợ quản lý sinh viên thực tập, chỗ ngồi cố định và toàn bộ vòng đời tài sản trong phòng LAB của trường đại học.

Trọng tâm của hệ thống là khả năng truy vết:

```text
Sinh viên được phê duyệt
→ Chỗ ngồi cố định theo học kỳ
→ Tài sản
→ Quá trình sử dụng/mượn trả
→ Kiểm tra, kiểm kê
→ Sự cố
→ Điều tra trách nhiệm
→ Bảo trì hoặc thanh lý
```

Đây **không phải** hệ thống đặt phòng học, đặt chỗ hằng ngày, điểm danh hay quản lý cửa hàng thiết bị.

## Phạm vi chức năng

| Mã | Chức năng |
| --- | --- |
| FE-01 | Manage User |
| FE-02 | Manage Asset |
| FE-03 | Manage Lab Usage Request |
| FE-04 | Manage Asset Usage |
| FE-05 | Manage Asset Inspections and Inventories |
| FE-06 | Manage Asset Incidents |
| FE-07 | Manage Responsibilities |
| FE-08 | Manage Asset Maintenance |
| FE-09 | Manage Asset Disposal |
| FE-10 | Manage Dashboard |
| FE-11 | Manage Lab Seat |
| AU-01 | Authentication |

`Manage Lab Usage Request` là quy trình Mentor gửi danh sách sinh viên thực tập theo học kỳ để Lab Manager phê duyệt. Chức năng này không phải quy trình đặt phòng hoặc đăng ký khung giờ.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Quản lý tài khoản, vai trò, trạng thái tài khoản và quyền truy cập hệ thống |
| Lab Manager | Phê duyệt danh sách sinh viên thực tập; giám sát tài sản, chỗ ngồi, kiểm kê và sự cố; duyệt các trường hợp trách nhiệm nghiêm trọng, bảo trì và thanh lý khi cần |
| Mentor | Trực tiếp quản lý sinh viên thực tập, phân chỗ ngồi, tài sản, mượn trả, kiểm kê, sự cố, điều tra trách nhiệm, bảo trì và đề xuất thanh lý |
| Student | Xem chỗ ngồi và tài sản liên quan; mượn/trả tài sản; xem lịch sử sử dụng; báo cáo sự cố; xem thông tin trách nhiệm của chính mình |

Hệ thống sử dụng tài khoản nội bộ. `AU-01 Authentication` gồm đăng nhập, yêu cầu đặt lại mật khẩu và đăng xuất.

## Luồng nghiệp vụ chính

1. Mentor chuẩn bị và gửi danh sách sinh viên thực tập theo học kỳ.
2. Lab Manager phê duyệt hoặc từ chối danh sách/sinh viên.
3. Mentor phân một chỗ ngồi cố định cho từng sinh viên đã được phê duyệt.
4. Sinh viên đăng nhập và sử dụng hoặc mượn tài sản; hệ thống lưu lịch sử mượn trả và tình trạng tài sản.
5. Mentor kiểm tra chỗ ngồi, đối chiếu tài sản dự kiến với tài sản thực tế và ghi nhận kết quả.
6. Khi phát hiện mất, hỏng, sai số lượng hoặc bất thường, Mentor hoặc Student có thể tạo sự cố.
7. Mentor điều tra dựa trên chỗ ngồi, lịch sử sử dụng và bằng chứng trước khi kết luận trách nhiệm.
8. Tài sản hỏng có thể được bảo trì; tài sản không thể sửa có thể được đề xuất thanh lý và chờ Lab Manager phê duyệt.

## Mô hình tài sản

- **Seat Asset:** tài sản cố định hoặc thường xuyên gắn với một chỗ ngồi, ví dụ máy tính, màn hình, bàn hoặc ghế.
- **Shared Asset:** tài sản dùng chung và có thể được nhiều sinh viên mượn, ví dụ Arduino kit, cảm biến hoặc dụng cụ điện tử.
- Tài sản giá trị cao được theo dõi riêng theo mã định danh.
- Linh kiện giống nhau, giá trị thấp có thể được quản lý theo số lượng.

Trạng thái vòng đời điển hình:

```text
Available → Damaged → Under Maintenance → Available
                                      └──→ Disposal Request → Disposed
```

Tài sản đang bảo trì hoặc đã thanh lý không được sử dụng hay cho mượn như tài sản khả dụng.

## Quy tắc nghiệp vụ cốt lõi

- Chỉ sinh viên thực tập đã được phê duyệt mới được phân chỗ ngồi.
- Một sinh viên có một chỗ ngồi cố định trong học kỳ; lịch sử phân chỗ phải được bảo tồn theo học kỳ.
- Một chỗ ngồi không được gán cho nhiều sinh viên đang hoạt động trong cùng học kỳ.
- Mỗi lượt sử dụng tài sản phải xác định sinh viên, tài sản và chỗ ngồi liên quan khi phù hợp.
- Kết quả kiểm tra bình thường không tạo sự cố; kết quả bất thường có thể dẫn đến một sự cố.
- Hệ thống chỉ cung cấp dữ liệu truy vết và **không tự động kết luận sinh viên có trách nhiệm** khi tài sản mất hoặc hỏng.
- Mentor chỉ tạo kết luận trách nhiệm sau khi điều tra; trường hợp nghiêm trọng có thể cần Lab Manager xem xét.
- Student chỉ được truy cập dữ liệu riêng của mình về chỗ ngồi, sử dụng tài sản, sự cố và trách nhiệm.
- Tài sản đã thanh lý không được sử dụng hoặc cho mượn lại.

## Công nghệ

- Java 17
- Jakarta EE Web 10
- JSP và JSTL
- Microsoft SQL Server
- Maven Wrapper
- Apache Tomcat 10.1 qua Cargo Maven plugin
- JUnit 5

## Yêu cầu môi trường

- JDK 17
- Microsoft SQL Server
- Không cần cài Maven toàn cục vì dự án có Maven Wrapper

## Cấu hình cơ sở dữ liệu

Sao chép `.env.example` thành `.env`, sau đó cập nhật thông tin kết nối cục bộ:

```dotenv
DB_URL=jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true
DB_USERNAME=sa
DB_PASSWORD=change-me
```

`AppConfig` ưu tiên biến môi trường của hệ điều hành. Tệp `.env` chỉ dùng cho phát triển cục bộ và đã được Git bỏ qua.

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

Chạy kiểm thử và kiểm tra định dạng:

```powershell
.\mvnw.cmd test
.\mvnw.cmd spotless:check
```

## Cấu trúc dự án

```text
src/
├── main/
│   ├── java/fpt/swp391/labtoolequip/
│   │   ├── config/       # Cấu hình ứng dụng
│   │   ├── controller/   # Servlet và HTTP controller
│   │   ├── model/        # Entity và value object nghiệp vụ
│   │   ├── repository/   # Truy cập dữ liệu
│   │   └── service/      # Use case và quy tắc nghiệp vụ
│   ├── resources/META-INF/
│   │   ├── beans.xml
│   │   └── persistence.xml
│   └── webapp/
│       ├── WEB-INF/web.xml
│       └── index.jsp
└── test/java/fpt/swp391/labtoolequip/
```

Đây là bộ khung ban đầu. Các lớp chỉ được bổ sung khi triển khai use case cụ thể để tránh tạo abstraction chưa cần thiết.
