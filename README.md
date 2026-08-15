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

`Manage Lab Usage Request` là quy trình Mentor gửi danh sách sinh viên thực tập theo học kỳ để Lab Manager phê duyệt hoặc từ chối. Chức năng này không phải quy trình đặt phòng hoặc đăng ký khung giờ.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Quản lý tài khoản; tạo hoặc kích hoạt người dùng; gán, thay đổi và thu hồi vai trò `LAB_MANAGER`, `MENTOR`, `STUDENT` |
| Lab Manager | Phê duyệt hoặc từ chối danh sách sinh viên do Mentor gửi; giám sát tài sản, kiểm kê và sự cố; duyệt các trường hợp trách nhiệm nghiêm trọng, bảo trì và thanh lý khi cần |
| Mentor | Trực tiếp quản lý sinh viên thực tập, tài sản, mượn trả, kiểm kê, sự cố, điều tra trách nhiệm, bảo trì và đề xuất thanh lý |
| Student | Xem tài sản có thể mượn; tự tạo lượt mượn/trả; xem lịch sử sử dụng; báo cáo sự cố; xem thông tin trách nhiệm của chính mình |

## Xác thực và cấp quyền

Phạm vi `AU-01 Authentication` gồm đăng nhập bằng tài khoản nội bộ, đăng nhập với Google, đổi mật khẩu và đăng xuất. Chức năng yêu cầu đặt lại mật khẩu đã bị loại khỏi phạm vi hiện tại.

- Admin tạo hoặc kích hoạt tài khoản và gán một trong các vai trò `ADMIN`, `LAB_MANAGER`, `MENTOR`, `STUDENT`.
- Tài khoản nội bộ sử dụng email và mật khẩu đã được băm; người dùng không được tự đăng ký hoặc tự chọn vai trò.
- Google Authentication là dịch vụ xác minh danh tính bên ngoài, không phải vai trò nghiệp vụ. Đăng nhập Google không tự tạo tài khoản và không quyết định quyền hạn.
- Khi đăng nhập với Google được triển khai, email Google phải trùng khớp tài khoản đã được tạo trước và đang ở trạng thái `ACTIVE`.
- Mỗi người dùng có tài khoản riêng. Vai trò lưu trong hệ thống quyết định dashboard và các chức năng được phép truy cập.

> Trạng thái hiện tại: `/login` mới là màn hình email/mật khẩu mẫu và chưa thực hiện xác thực. Google OAuth, đổi mật khẩu và đăng xuất sẽ được triển khai ở phase sau.

## Luồng nghiệp vụ chính

1. Mentor chuẩn bị và gửi cho Lab Manager danh sách sinh viên thực tập theo học kỳ.
2. Lab Manager phê duyệt hoặc từ chối toàn bộ danh sách.
3. Với danh sách đã duyệt, Admin tạo hoặc kích hoạt tài khoản, gán vai trò `STUDENT` và cấp quyền truy cập.
4. Sinh viên được duyệt có thể tự tạo lượt mượn tài sản nhỏ mà không cần Mentor duyệt từng lượt; hệ thống kiểm tra học kỳ, khả năng cho mượn và số lượng còn lại.
5. Mỗi lượt mượn liên kết trực tiếp một sinh viên với một tài sản, có số lượng và hạn trả; Student, Mentor hoặc Lab Manager có thể ghi nhận thao tác theo quyền.
6. Mentor hoặc Lab Manager kiểm tra toàn bộ LAB hoặc một nhóm tài sản được chọn, đối chiếu số lượng và tình trạng thực tế.
7. Khi phát hiện mất, hỏng, sai số lượng, quá hạn hoặc bất thường, Mentor hoặc Student có thể tạo sự cố.
8. Mentor điều tra dựa trên lịch sử mượn trả và bằng chứng trước khi kết luận trách nhiệm.
9. Tài sản hỏng có thể được bảo trì; tài sản không thể sửa có thể được đề xuất thanh lý và chờ Lab Manager phê duyệt.

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

- Chỉ tài khoản đã được Admin cấp trước, đúng email, đúng vai trò và đang ở trạng thái `ACTIVE` mới được đăng nhập bằng phương thức được hệ thống hỗ trợ.
- Mỗi người dùng có một tài khoản riêng; hệ thống không tự tạo tài khoản hoặc suy ra vai trò từ tên hay miền email.
- Chỉ sinh viên thuộc danh sách đã được Lab Manager phê duyệt và được Admin cấp tài khoản mới được đăng nhập và mượn tài sản trong học kỳ tương ứng.
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

## Trạng thái triển khai hiện tại

Đã triển khai:

- Schema SQL Server gồm 14 bảng nghiệp vụ và các model Java tương ứng.
- Kết nối SQL Server qua `DBConnection` và biến môi trường.
- FE-01 Manage User ở mức MVC/JDBC cơ bản: `UserController`, `UserDAO` và các JSP danh sách, chi tiết, thêm, sửa.
- Controller và JSP khung cho dashboard của Admin, Lab Manager, Mentor và Student.
- Mentor Dashboard responsive; dữ liệu trên dashboard hiện là dữ liệu trình diễn.

Chưa triển khai đầy đủ:

- Xác thực thật, Google OAuth, phân quyền request, đổi mật khẩu và đăng xuất.
- DAO, Controller và JSP nghiệp vụ cho FE-02 đến FE-09.
- Dữ liệu động cho các dashboard và kiểm thử tự động; `src/test` hiện chỉ có file giữ package.

## Công nghệ

- Java 17
- Jakarta EE Web 10
- JSP, JSTL và Jakarta Servlet
- JDBC với Microsoft SQL Server
- BCrypt cho mật khẩu tài khoản nội bộ
- Maven Wrapper
- Apache Tomcat 10.1 qua Cargo Maven plugin
- JUnit 5 (đã cấu hình, chưa có test case)

## Yêu cầu môi trường

- JDK 17
- Microsoft SQL Server
- Không cần cài Maven toàn cục vì dự án có Maven Wrapper

## Cấu hình cơ sở dữ liệu

Khai báo các biến môi trường sau trong hệ điều hành hoặc Run Configuration của IntelliJ/Tomcat:

```dotenv
DB_URL=jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true
DB_USERNAME=sa
DB_PASSWORD=change-me
```

`DBConnection` đọc trực tiếp các biến môi trường trên. Có thể dùng Java system properties cùng tên khi chạy cục bộ. Ứng dụng không tự đọc tệp `.env`; `.env.example` chỉ là mẫu cấu hình và `.env` đã được Git bỏ qua.

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

Nếu cổng `8080` đang được sử dụng:

```powershell
.\mvnw.cmd "-Dcargo.servlet.port=8090" cargo:run
```

Chạy build và kiểm tra định dạng:

```powershell
.\mvnw.cmd clean package
.\mvnw.cmd spotless:check
```

## Cấu trúc dự án

```text
database/
├── schema.sql                 # Script tạo schema SQL Server
├── schema.dbml                # Mô hình database dạng DBML
└── schema_smoke_test.sql      # Script kiểm tra nhanh schema
src/
├── main/
│   ├── java/fpt/swp391/labtoolequip/
│   │   ├── common/            # DBConnection và thành phần dùng chung
│   │   ├── controller/        # Servlet theo Auth, Admin, Lab Manager, Mentor, Student
│   │   ├── dao/               # Truy cập dữ liệu bằng JDBC
│   │   └── model/             # Model tương ứng các bảng nghiệp vụ
│   ├── resources/META-INF/
│   │   ├── beans.xml          # Descriptor CDI rỗng từ bộ khung
│   │   └── persistence.xml    # Descriptor JPA rỗng, hiện chưa được sử dụng
│   └── webapp/
│       ├── assets/
│       │   ├── css/           # Stylesheet giao diện
│       │   └── images/        # Logo và hình ảnh tĩnh
│       ├── WEB-INF/
│       │   ├── views/         # JSP theo Auth, Admin, Lab Manager, Mentor, Student
│       │   └── web.xml
│       └── index.jsp
└── test/java/fpt/swp391/labtoolequip/  # Khung test, chưa có test case
```

Dự án hiện theo MVC với Servlet/JSP và DAO dùng JDBC. Chỉ bổ sung DAO, Controller và JSP khi bắt đầu triển khai use case tương ứng.
