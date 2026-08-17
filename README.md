# LAB Asset Management System

Ứng dụng web nội bộ hỗ trợ quản lý intern và toàn bộ vòng đời tài sản trong phòng LAB của trường đại học.

Trọng tâm của hệ thống là khả năng truy vết:

```text
Intern được phê duyệt
→ Yêu cầu mượn tài sản theo học kỳ
→ Quá trình sử dụng và trả tài sản
→ Kiểm tra, kiểm kê
→ Sự cố
→ Điều tra trách nhiệm
→ Bảo trì hoặc thanh lý
```

Intern được di chuyển tự do trong LAB; hệ thống không quản lý hoặc chỉ định chỗ ngồi. Đây **không phải** hệ thống đặt phòng học, điểm danh hay quản lý cửa hàng thiết bị.

## Phạm vi chức năng

| Mã | Chức năng |
| --- | --- |
| FE-01 | Manage User |
| FE-02 | Manage Asset |
| FE-03 | Manage Intern List |
| FE-04 | Manage Asset Usage |
| FE-05 | Manage Asset Inspections and Inventories |
| FE-06 | Manage Asset Incidents |
| FE-07 | Manage Responsibilities |
| FE-08 | Manage Asset Maintenance |
| FE-09 | Manage Asset Disposal |
| FE-10 | Manage Dashboard |
| AU-01 | Authentication |

`Manage Intern List` là quy trình Mentor gửi một danh sách intern duy nhất cho mỗi học kỳ để Admin phê duyệt hoặc từ chối. Phòng LAB chỉ có một Mentor phụ trách. Chức năng này không phải quy trình đặt phòng, đăng ký khung giờ hoặc quản lý lịch làm việc.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Quản lý tài khoản; phê duyệt hoặc từ chối danh sách intern; tạo hoặc kích hoạt người dùng; gán, thay đổi và thu hồi vai trò `LAB_MANAGER`, `MENTOR`, `INTERN` |
| Lab Manager | Giám sát tài sản, kiểm kê và sự cố; duyệt các trường hợp trách nhiệm nghiêm trọng, bảo trì và thanh lý khi cần |
| Mentor | Phụ trách duy nhất phòng LAB; gửi một danh sách intern cho mỗi học kỳ; trực tiếp quản lý intern, tài sản, mượn trả, kiểm kê, sự cố, điều tra trách nhiệm, bảo trì và đề xuất thanh lý |
| Intern | Xem tài sản có thể mượn; tự tạo lượt mượn/trả; xem lịch sử sử dụng; báo cáo sự cố; xem thông tin trách nhiệm của chính mình |

## Xác thực và cấp quyền

Phạm vi `AU-01 Authentication` hiện dùng Google OAuth/OIDC và đăng xuất. Đăng nhập development bằng email chỉ xuất hiện khi `DEV_AUTH_ENABLED=true`.

- Admin tạo hoặc kích hoạt tài khoản và gán một trong các vai trò `ADMIN`, `LAB_MANAGER`, `MENTOR`, `INTERN`.
- Google Authentication là dịch vụ xác minh danh tính bên ngoài, không phải vai trò nghiệp vụ. Đăng nhập Google không tự tạo tài khoản và không quyết định quyền hạn.
- Email Google đã xác minh phải thuộc miền FPT, trùng tài khoản được tạo trước và đang ở trạng thái `ACTIVE`.
- Lần đăng nhập đầu tiên bind `google_subject`; các lần sau subject phải khớp binding đã lưu.
- Mỗi người dùng có tài khoản riêng. Vai trò lưu trong hệ thống quyết định dashboard và các chức năng được phép truy cập.
- Filter phía server bảo vệ route `/intern/*`, `/mentor/*`, `/lab-manager/*` và `/admin/*` theo đúng vai trò.

## Luồng nghiệp vụ chính

1. Mentor chuẩn bị và gửi một danh sách intern cho mỗi học kỳ. Danh sách có mã intern, họ tên, Gmail và khóa, ví dụ `K17`.
2. Admin phê duyệt hoặc từ chối toàn bộ danh sách một lần. Mentor chỉ được sửa hoặc xóa khi danh sách còn `PENDING`; Admin là quyền cao nhất nên được xem, sửa hoặc xóa danh sách ở mọi trạng thái. Khi Admin sửa danh sách `APPROVED`, membership intern được đồng bộ theo dữ liệu mới. Khi xóa danh sách, các tài khoản intern không còn liên kết với danh sách/kỳ nào khác sẽ bị xóa cùng; tài khoản còn lịch sử hoặc liên kết khác được giữ lại, và hệ thống không cho xóa danh sách đã phát sinh lịch sử sử dụng tài sản.
3. Mỗi học kỳ chỉ có một danh sách cho phòng LAB. Mã intern và Gmail không được trùng trong cùng học kỳ.
4. Với danh sách đã duyệt, hệ thống tạo hoặc kích hoạt tài khoản, gán vai trò `INTERN` và cấp quyền truy cập.
5. Intern được duyệt có thể tự tạo lượt mượn tài sản nhỏ mà không cần Mentor duyệt từng lượt; hệ thống kiểm tra học kỳ, khả năng cho mượn và số lượng còn lại.
6. Mỗi lượt mượn liên kết trực tiếp một intern với một tài sản, có số lượng, thời điểm mượn và hạn trả; Intern, Mentor hoặc Lab Manager có thể ghi nhận thao tác theo quyền.
6. Mentor hoặc Lab Manager kiểm tra toàn bộ LAB hoặc một nhóm tài sản được chọn, đối chiếu số lượng và tình trạng thực tế.
7. Khi phát hiện mất, hỏng, sai số lượng, quá hạn hoặc bất thường, Mentor hoặc Intern có thể tạo sự cố và nhập thời điểm thực tế xảy ra nếu biết.
8. Mentor điều tra dựa trên lịch sử mượn trả và bằng chứng trước khi kết luận trách nhiệm.
9. Lab Manager tạo quy trình thanh lý cho toàn bộ asset record; có thể hủy khi đang chờ hoặc hoàn tất khi không còn lượt mượn active.

## Mô hình tài sản

- **Tiện ích cố định:** bàn, ghế, tủ, bảng, TV hoặc máy chiếu dùng chung trong LAB. Các tài sản này vẫn được kiểm kê, ghi nhận sự cố, bảo trì và thanh lý nhưng không được mượn.
- **Tài sản có thể mượn:** thiết bị IoT, đồ điện tử, remote, Arduino kit, cảm biến hoặc dụng cụ nhỏ. Intern phải tạo lượt mượn trước khi sử dụng.
- Tài sản có thể được theo dõi riêng theo mã định danh hoặc quản lý theo số lượng đối với các linh kiện giống nhau.
- Vị trí của tiện ích cố định hoặc nơi lưu tài sản được ghi bằng thông tin vị trí, không gắn với intern.

Trạng thái vòng đời điển hình:

```text
Available → Damaged → Under Maintenance → Available
                                      └──→ Disposal Request → Disposed
```

Tài sản đang bảo trì hoặc đã thanh lý không được sử dụng hay cho mượn như tài sản khả dụng.

## Quy tắc nghiệp vụ cốt lõi

- Chỉ tài khoản đã được Admin cấp trước, đúng email, đúng vai trò và đang ở trạng thái `ACTIVE` mới được đăng nhập bằng phương thức được hệ thống hỗ trợ.
- Mỗi người dùng có một tài khoản riêng; hệ thống không tự tạo tài khoản hoặc suy ra vai trò từ tên hay miền email.
- Chỉ intern thuộc danh sách đã được Admin phê duyệt và được cấp tài khoản mới được đăng nhập và mượn tài sản trong học kỳ tương ứng.
- Intern được di chuyển tự do trong LAB; hệ thống không lưu hoặc phân chỗ ngồi.
- Một intern có thể mượn nhiều tài sản cùng lúc; mỗi lượt mượn chỉ xác định một intern và một tài sản.
- Tài sản theo mã riêng chỉ có một người đang mượn tại một thời điểm; tổng số lượng đang mượn của tài sản theo số lượng không được vượt quá tồn kho.
- Tiện ích cố định không được mượn. Tài sản nhỏ phải có lượt mượn với số lượng và hạn trả trước khi sử dụng.
- Kiểm tra và kiểm kê được thực hiện cho toàn bộ LAB hoặc một nhóm tài sản được chọn, không theo chỗ ngồi.
- Kết quả kiểm tra bình thường không tạo sự cố; kết quả bất thường có thể dẫn đến một sự cố.
- Hệ thống chỉ cung cấp dữ liệu truy vết và **không tự động kết luận intern có trách nhiệm** khi tài sản mất hoặc hỏng.
- Mentor chỉ tạo kết luận trách nhiệm sau khi điều tra; mức `LOW`/`MEDIUM` được kết luận trực tiếp, còn `HIGH`/`CRITICAL` phải được Lab Manager duyệt.
- Intern chỉ được truy cập dữ liệu riêng của mình về sử dụng tài sản, sự cố và trách nhiệm.
- Tài sản đã thanh lý không được sử dụng hoặc cho mượn lại.

## Trạng thái triển khai hiện tại

Đã triển khai:

- Schema SQL Server gồm các bảng nghiệp vụ cho một phòng LAB, danh sách intern theo học kỳ và các model Java tương ứng.
- Cấu hình `.env` qua `AppConfig`; kết nối SQL Server qua `DBConnection`.
- Google OAuth/OIDC, bind Google subject, session, logout và Filter phân quyền theo role.
- FE-01 Manage User ở mức MVC/JDBC cơ bản: `UserController`, `UserDAO` và các JSP danh sách, chi tiết, thêm, sửa.
- FE-04 Manage Asset Usage: Intern mượn/trả/xem lịch sử; Lab Manager xem và lọc toàn bộ lịch sử; transaction khóa asset chống over-borrow.
- FE-07 Manage Responsibilities: Mentor tạo, xem, sửa, xóa kết luận trách nhiệm; Lab Manager xem toàn bộ danh sách/chi tiết; Intern chỉ xem trách nhiệm gắn với tài khoản của mình.
- FE-09 Manage Asset Disposal: Lab Manager tạo, sửa, hủy và hoàn tất quy trình `PENDING/CANCELLED/COMPLETED`.
- Controller và JSP khung cho dashboard của Admin, Lab Manager, Mentor và Intern.
- Mentor Dashboard responsive; dữ liệu trên dashboard hiện là dữ liệu trình diễn.

Chưa triển khai đầy đủ:

- DAO, Controller và JSP nghiệp vụ cho FE-02, FE-03, FE-05, FE-06 và FE-08.
- Dữ liệu động cho các dashboard và kiểm thử tự động; `src/test` hiện chỉ có file giữ package.

## Công nghệ

- Java 17
- Jakarta EE Web 10
- JSP, JSTL và Jakarta Servlet
- Bootstrap 5
- JDBC với Microsoft SQL Server
- Google OAuth/OIDC
- java-dotenv
- Maven Wrapper
- Apache Tomcat 10.1 qua Cargo Maven plugin
- JUnit 5 (đã cấu hình, chưa có test case)

## Yêu cầu môi trường

- JDK 17
- Microsoft SQL Server
- Không cần cài Maven toàn cục vì dự án có Maven Wrapper

## Cấu hình cơ sở dữ liệu

Sao chép `.env.example` thành `.env`, sau đó cấu hình:

```dotenv
DB_URL=jdbc:sqlserver://localhost:1433;databaseName=lab_asset_management;encrypt=true;trustServerCertificate=true
DB_USERNAME=sa
DB_PASSWORD=change-me
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=http://localhost:8080/labtoolequip/oauth2/callback
FPT_EMAIL_DOMAIN=fpt.edu.vn
LAB_TIMEZONE=Asia/Ho_Chi_Minh
DEV_AUTH_ENABLED=false
```

`AppConfig` tìm `.env` từ vị trí chạy ứng dụng lên project root. `.env` đã được Git bỏ qua; không commit database password hoặc Google Client Secret.

### Khởi tạo database local

Để tạo toàn bộ bảng và dữ liệu đăng nhập demo, chạy trực tiếp `database/lab_asset_management_full.sql` trong SQL Server Management Studio hoặc bằng `sqlcmd`. Đây là file standalone, không cần thêm file SQL nào khác.

Các tài khoản demo đều dùng mật khẩu `123` khi `DEV_AUTH_ENABLED=true`:

| Email | Role |
| --- | --- |
| `admin@gmail.com` | `ADMIN` |
| `manager@gmail.com` | `LAB_MANAGER` |
| `mentor@gmail.com` | `MENTOR` |
| `intern@gmail.com` | `INTERN` |
| `intern2@gmail.com` | `INTERN` |

File SQL cũng tạo sẵn học kỳ `FA26`, một danh sách intern đã `APPROVED` do Mentor gửi, hai intern thuộc khóa `K17` và hai hồ sơ trách nhiệm FE-07 để kiểm tra phân quyền theo actor.

Khởi tạo database và dữ liệu demo:

```powershell
sqlcmd -S localhost,1433 -U sa -P <password> -C -b -i database/lab_asset_management_full.sql
```

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
└── lab_asset_management_full.sql # Toàn bộ bảng, ràng buộc và dữ liệu demo
src/
├── main/
│   ├── java/fpt/swp391/labtoolequip/
│   │   ├── common/            # DBConnection và thành phần dùng chung
│   │   ├── controller/        # Servlet theo Auth, Admin, Lab Manager, Mentor, Intern
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
│       │   ├── views/         # JSP theo Auth, Admin, Lab Manager, Mentor, Intern
│       │   └── web.xml
│       └── index.jsp
└── test/java/fpt/swp391/labtoolequip/  # Khung test, chưa có test case
```

Dự án hiện theo MVC với Servlet/JSP và DAO dùng JDBC. Chỉ bổ sung DAO, Controller và JSP khi bắt đầu triển khai use case tương ứng.
