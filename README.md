# LAB Asset Management System

Ứng dụng web nội bộ hỗ trợ quản lý sinh viên thực tập và toàn bộ vòng đời tài sản trong phòng LAB của trường đại học.

Trọng tâm của hệ thống là khả năng truy vết:

```text
Sinh viên được phê duyệt
→ Yêu cầu mượn tài sản theo học kỳ
→ Quá trình sử dụng và trả tài sản
→ Kiểm tra, kiểm kê
→ Sự cố
→ Điều tra trách nhiệm
→ Bảo trì hoặc thanh lý
```

Sinh viên được di chuyển tự do trong LAB; hệ thống không quản lý hoặc chỉ định chỗ ngồi. Đây **không phải** hệ thống đặt phòng học, điểm danh hay quản lý cửa hàng thiết bị.

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
| AU-01 | Authentication |

`Manage Lab Usage Request` là quy trình Mentor gửi danh sách sinh viên thực tập theo học kỳ để Lab Manager phê duyệt. Chức năng này không phải quy trình đặt phòng hoặc đăng ký khung giờ.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Quản lý tài khoản, vai trò, trạng thái tài khoản và quyền truy cập hệ thống |
| Lab Manager | Phê duyệt danh sách sinh viên thực tập; giám sát tài sản, kiểm kê và sự cố; duyệt các trường hợp trách nhiệm nghiêm trọng, bảo trì và thanh lý khi cần |
| Mentor | Trực tiếp quản lý sinh viên thực tập, tài sản, mượn trả, kiểm kê, sự cố, điều tra trách nhiệm, bảo trì và đề xuất thanh lý |
| Student | Xem tài sản có thể mượn; tự tạo lượt mượn/trả; xem lịch sử sử dụng; báo cáo sự cố; xem thông tin trách nhiệm của chính mình |

`AU-01 Authentication` gồm đăng nhập bằng tài khoản nội bộ, đăng nhập bằng tài khoản Google có đuôi `@fpt.edu.vn`, tự đổi mật khẩu nội bộ và đăng xuất. Google Authentication là dịch vụ xác thực bên ngoài hỗ trợ hệ thống, không được tính là actor hoặc role nghiệp vụ.

## Luồng nghiệp vụ chính

1. Mentor chuẩn bị và gửi danh sách sinh viên thực tập theo học kỳ.
2. Lab Manager phê duyệt hoặc từ chối toàn bộ danh sách.
3. Sinh viên thuộc danh sách đã được duyệt có thể tự tạo lượt mượn tài sản nhỏ mà không cần Mentor duyệt từng lượt; hệ thống kiểm tra học kỳ, khả năng cho mượn và số lượng còn lại.
4. Mỗi lượt mượn liên kết trực tiếp một sinh viên với một tài sản, có số lượng và hạn trả; Student, Mentor hoặc Lab Manager có thể ghi nhận thao tác theo quyền.
5. Mentor hoặc Lab Manager kiểm tra toàn bộ LAB hoặc một nhóm tài sản được chọn, đối chiếu số lượng và tình trạng thực tế.
6. Khi phát hiện mất, hỏng, sai số lượng, quá hạn hoặc bất thường, Mentor hoặc Student có thể tạo sự cố.
7. Mentor điều tra dựa trên lịch sử mượn trả và bằng chứng trước khi kết luận trách nhiệm.
8. Tài sản hỏng có thể được bảo trì; tài sản không thể sửa có thể được đề xuất thanh lý và chờ Lab Manager phê duyệt.

## Mô hình tài sản

- **Tiện ích cố định:** bàn, ghế, tủ, bảng, TV hoặc máy chiếu dùng chung trong LAB. Các tài sản này vẫn được kiểm kê, ghi nhận sự cố, bảo trì và thanh lý nhưng không được mượn.
- **Tài sản có thể mượn:** thiết bị IoT, đồ điện tử, remote, Arduino kit, cảm biến hoặc dụng cụ nhỏ. Sinh viên phải tạo lượt mượn trước khi sử dụng.
- Tài sản có thể được theo dõi riêng theo mã định danh hoặc quản lý theo số lượng đối với các linh kiện giống nhau.
- Vị trí của tiện ích cố định hoặc nơi lưu tài sản được ghi bằng thông tin vị trí, không gắn với sinh viên.

Trạng thái vòng đời điển hình:

```text
Available → Damaged → Under Maintenance → Available
                                      └──→ Disposal Request → Disposed
```

Tài sản đang bảo trì hoặc đã thanh lý không được sử dụng hay cho mượn như tài sản khả dụng.

## Quy tắc nghiệp vụ cốt lõi

- Chỉ sinh viên thuộc danh sách đã được Lab Manager phê duyệt mới được mượn tài sản trong học kỳ tương ứng.
- Sinh viên được di chuyển tự do trong LAB; hệ thống không lưu hoặc phân chỗ ngồi.
- Một sinh viên có thể mượn nhiều tài sản cùng lúc; mỗi lượt mượn chỉ xác định một sinh viên và một tài sản.
- Tài sản theo mã riêng chỉ có một người đang mượn tại một thời điểm; tổng số lượng đang mượn của tài sản theo số lượng không được vượt quá tồn kho.
- Tiện ích cố định không được mượn. Tài sản nhỏ phải có lượt mượn với số lượng và hạn trả trước khi sử dụng.
- Kiểm tra và kiểm kê được thực hiện cho toàn bộ LAB hoặc một nhóm tài sản được chọn, không theo chỗ ngồi.
- Kết quả kiểm tra bình thường không tạo sự cố; kết quả bất thường có thể dẫn đến một sự cố.
- Hệ thống chỉ cung cấp dữ liệu truy vết và **không tự động kết luận sinh viên có trách nhiệm** khi tài sản mất hoặc hỏng.
- Mentor chỉ tạo kết luận trách nhiệm sau khi điều tra; mức `LOW`/`MEDIUM` được kết luận trực tiếp, còn `HIGH`/`CRITICAL` phải được Lab Manager duyệt.
- Student chỉ được truy cập dữ liệu riêng của mình về sử dụng tài sản, sự cố và trách nhiệm.
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

Kiểm tra kết nối SQL Server tại `http://localhost:8080/labtoolequip/system/database-status`.

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
│   │   ├── controller/   # Servlet theo Auth, Admin, Lab Manager, Mentor, Student và System
│   │   ├── model/        # Entity và value object nghiệp vụ
│   │   ├── repository/   # Truy cập dữ liệu
│   │   └── service/      # Use case và quy tắc nghiệp vụ
│   ├── resources/META-INF/
│   │   ├── beans.xml
│   │   └── persistence.xml
│   └── webapp/
│       ├── WEB-INF/
│       │   ├── views/    # JSP theo Auth, Admin, Lab Manager, Mentor, Student và System
│       │   └── web.xml
│       └── index.jsp
└── test/java/fpt/swp391/labtoolequip/
```

Đây là bộ khung ban đầu. Các lớp chỉ được bổ sung khi triển khai use case cụ thể để tránh tạo abstraction chưa cần thiết.
