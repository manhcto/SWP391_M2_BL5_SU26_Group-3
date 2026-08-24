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
| Lab Manager | CRUD `Asset`/`AssetItem`; điều tra kỹ thuật Incident; xử lý bảo trì và thanh lý; xem kết luận Responsibility |
| Mentor | Phụ trách danh sách intern; xác nhận trả; báo cáo hoặc duyệt/chuyển Incident; kết luận Responsibility; tạo yêu cầu bảo trì/thanh lý |
| Intern | Xem tài sản có thể mượn; tự tạo lượt mượn/trả; xem lịch sử sử dụng; báo hỏng trực tiếp cho Mentor; xem thông tin trách nhiệm của chính mình |

## Xác thực và cấp quyền

Hệ thống dùng xác thực hybrid: Intern đăng nhập bằng Google FPT đã được provision; Admin, Mentor và Lab Manager đăng nhập bằng tài khoản nội bộ cùng mật khẩu BCrypt.

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
7. Mentor hoặc Lab Manager kiểm tra toàn bộ LAB hoặc một nhóm tài sản được chọn, đối chiếu số lượng và tình trạng thực tế.
8. Intern báo Incident từ lượt sử dụng của mình; Mentor duyệt/chuyển. Mentor cũng có thể báo trực tiếp thiết bị hoặc lượt sử dụng thuộc phạm vi phụ trách.
9. Lab Manager điều tra kỹ thuật Incident. Sau kết luận kỹ thuật, Mentor có thể ghi Responsibility `UNDETERMINED/NONE/PARTIAL/FULL`; hệ thống không mặc định Intern có lỗi.
10. Mentor tạo yêu cầu bảo trì hoặc thanh lý cho đúng `AssetItem`; Lab Manager duyệt/xử lý. Hoàn tất chỉ cập nhật Item mục tiêu, không thay đổi sibling hoặc hard-delete lịch sử.

### Luồng cấp phát thiết bị cho lớp Intern (FE-11)

1. Mentor chọn một danh sách Intern đã được Admin duyệt và tạo một yêu cầu cấp phát dùng xuyên suốt thời gian hoạt động của lớp.
2. Trong một yêu cầu, Mentor thêm nhiều loại tài sản cố định hoặc bộ kit; mỗi dòng có loại tài sản, số lượng và ghi chú riêng. Dữ liệu lấy trực tiếp từ danh mục `Asset` đã có trong kho.
3. Lab Manager kiểm tra tồn kho, điều chỉnh số lượng được duyệt cho từng dòng và gán các `AssetItem` cụ thể. Thiết bị được cấp chuyển sang trạng thái đang sử dụng để không xuất hiện trong luồng mượn thông thường.
4. Tất cả Intern thuộc danh sách có thể xem thiết bị dùng chung của lớp. Intern báo hỏng, mất hoặc thiếu phụ kiện kèm ảnh; Mentor xác minh trước khi chuyển thành Incident cho Lab Manager xử lý.
5. Cuối thời gian hoạt động, Lab Manager thu hồi thiết bị và đóng yêu cầu sau khi các tài sản đã được trả hoặc xử lý sự cố.

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
- Mentor chỉ ghi nhận nguyên nhân và thông tin ban đầu trong báo cáo; Lab Manager quyết định việc xử lý, xử phạt và cập nhật `Responsibility` của Intern theo quy định của phòng LAB.
- Intern chỉ được truy cập dữ liệu riêng của mình về sử dụng tài sản, sự cố và trách nhiệm.
- Tài sản đã thanh lý không được sử dụng hoặc cho mượn lại.

## Trạng thái triển khai hiện tại

Đã triển khai:

- Schema SQL Server gồm các bảng nghiệp vụ cho một phòng LAB, danh sách intern theo học kỳ và các model Java tương ứng.
- Danh mục `majors` được lưu riêng trong database; hồ sơ intern tham chiếu `major_id` và form Admin hiển thị các major đang `ACTIVE` bằng dropdown.
- Cấu hình `.env` qua `AppConfig`; kết nối SQL Server qua `DBConnection`.
- Google OAuth/OIDC, bind Google subject, session, logout và Filter phân quyền theo role.
- FE-01 Manage User ở mức MVC/JDBC cơ bản: `UserController`, `UserDAO` và các JSP danh sách, chi tiết, thêm, sửa.
- FE-02 Manage Asset: Lab Manager tạo nhiều sản phẩm từ một loại thiết bị hoặc Excel, sinh mã `AssetItem` riêng, xem/sửa/xóa từng sản phẩm, lưu ảnh và tình trạng; dữ liệu tổng hợp được cập nhật về `Asset`. Mentor chỉ xem các sản phẩm ở trạng thái `AVAILABLE` trong LAB.
- FE-03 Manage Intern List: Mentor tạo/sửa/xóa danh sách theo học kỳ, nhập thủ công hoặc từ Excel; Admin lọc, xem, sửa, xóa và phê duyệt/từ chối.
- FE-04 Manage Asset Usage: Intern mượn và gửi yêu cầu trả; Mentor xác nhận trả. Lifecycle `IN_USE -> RETURN_PENDING -> RETURNED`; transaction khóa asset chống over-borrow.
- FE-06 Manage Incidents: Intern/Mentor báo cáo; Mentor duyệt/chuyển báo cáo Intern; Lab Manager điều tra kỹ thuật và xử lý lifecycle Incident.
- FE-07 Manage Responsibilities: Mentor tạo/sửa kết luận trách nhiệm sau technical finding; `NONE/UNDETERMINED` không bắt buộc Intern; Lab Manager xem; Intern chỉ xem hồ sơ liên quan mình; không hard-delete.
- FE-08 Manage Asset Maintenance: Mentor tạo yêu cầu exact Item; Lab Manager duyệt/từ chối/bắt đầu/hoàn tất; lưu `SUCCESS/FAILED`; parent và sibling không đổi.
- FE-09 Manage Asset Disposal: Mentor tạo yêu cầu; Lab Manager duyệt/từ chối/hoàn tất exact Item; chặn Usage hoặc Maintenance active; `DISPOSED` là terminal.
- Controller và JSP khung cho dashboard của Admin, Lab Manager, Mentor và Intern.
- Mentor Dashboard responsive; dữ liệu trên dashboard hiện là dữ liệu trình diễn.

Quy tắc tình trạng sản phẩm: `GOOD`/`FAIR` có thể dùng. Return bất thường chuyển exact Item sang `UNAVAILABLE`; chỉ khi Lab Manager bắt đầu phiếu bảo trì thì Item mới sang `MAINTENANCE`. AssetUsage không dùng trạng thái `MAINTENANCE`.

Chưa triển khai đầy đủ: FE-05 item-specific inspection và Playwright E2E cho Intern bị phụ thuộc Google OAuth production. Automated suite hiện có unit/integration tests; browser smoke dùng WAR hiện tại trên dedicated port.

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
- JUnit 5 và Playwright

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
```

`AppConfig` tìm `.env` từ vị trí chạy ứng dụng lên project root. `.env` đã được Git bỏ qua; không commit database password hoặc Google Client Secret.

### Khởi tạo database local

`database/lab_asset_management_full.sql` là script database duy nhất của dự án. Chạy file này trên database mới để tạo toàn bộ schema, lifecycle tài sản, FE-11 cấp phát thiết bị và dữ liệu demo.

Các tài khoản Intern demo không có mật khẩu nội bộ; đăng nhập bằng tài khoản Google FPT tương ứng.

Các tài khoản nội bộ demo dùng mật khẩu `123` cho môi trường local:

| Email | Role |
| --- | --- |
| `admin@gmail.com` | `ADMIN` |
| `manager@gmail.com` | `LAB_MANAGER` |
| `mentor@gmail.com` | `MENTOR` |
| `mentor.ops@gmail.com` | `MENTOR` |

Intern demo đăng nhập bằng Google:

| Email | Mã sinh viên |
| --- | --- |
| `anhnmhe171286@fpt.edu.vn` | `HE171286` |
| `trungndhe180362@fpt.edu.vn` | `HE180362` |
| `ductmhe180875@fpt.edu.vn` | `HE180875` |
| `minhtbhe186275@fpt.edu.vn` | `HE186275` |
| `minhlahe180101@fpt.edu.vn` | `HE180101` |

Mock data dùng ngày tương đối và tạo ba kỳ/danh sách `APPROVED`, `PENDING`, `REJECTED`; năm Intern FPT; 15 loại tài sản và 17 Item vật lý. Fixture phủ các trạng thái demo của Usage/Bulk Return, Allocation, Inspection, Incident, Responsibility, Maintenance, Disposal, Password Reset, Dashboard và Lifecycle Timeline. Hai Item `ARD-UNO-R3-001` và `WEBCAM-C920-001` được giữ trống để thao tác live.

Khởi tạo database và dữ liệu demo:

```powershell
sqlcmd -S localhost,1433 -U sa -P <password> -C -b -f 65001 -i database/lab_asset_management_full.sql
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
└── lab_asset_management_full.sql       # Toàn bộ schema và dữ liệu demo
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
