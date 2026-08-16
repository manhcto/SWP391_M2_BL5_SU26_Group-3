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

`Manage Lab Usage Request` là quy trình Mentor gửi cho Admin danh sách sinh viên và nhiều slot học lặp lại hằng tuần theo học kỳ để Admin phê duyệt hoặc từ chối. Chức năng này không phải quy trình đặt phòng.

## Vai trò

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Admin | Phê duyệt hoặc từ chối Lab Usage Request; quản lý tài khoản; tạo hoặc kích hoạt người dùng; gán, thay đổi và thu hồi vai trò `LAB_MANAGER`, `MENTOR`, `STUDENT` |
| Lab Manager | Giám sát tài sản, kiểm kê và sự cố; duyệt các trường hợp trách nhiệm nghiêm trọng, bảo trì và thanh lý khi cần |
| Mentor | Trực tiếp quản lý sinh viên thực tập, tài sản, mượn trả, kiểm kê, sự cố, điều tra trách nhiệm, bảo trì và đề xuất thanh lý |
| Student | Xem tài sản có thể mượn; tự tạo lượt mượn/trả; xem lịch sử sử dụng; báo cáo sự cố; xem thông tin trách nhiệm của chính mình |

## Xác thực và cấp quyền

Phạm vi `AU-01 Authentication` gồm đăng nhập bằng tài khoản nội bộ, đăng nhập với Google, đổi mật khẩu và đăng xuất. Chức năng yêu cầu đặt lại mật khẩu đã bị loại khỏi phạm vi hiện tại.

- Admin tạo hoặc kích hoạt tài khoản và gán một trong các vai trò `ADMIN`, `LAB_MANAGER`, `MENTOR`, `STUDENT`.
- Tài khoản nội bộ sử dụng email và mật khẩu đã được băm; người dùng không được tự đăng ký hoặc tự chọn vai trò. Khi Mentor gửi request, hệ thống chỉ lưu bản chụp mã sinh viên, họ tên và email trong request, chưa tạo tài khoản.
- Google Authentication là dịch vụ xác minh danh tính bên ngoài, không phải vai trò nghiệp vụ. Hệ thống chấp nhận mọi miền email do Google xác minh.
- Khi đăng nhập với Google, email đã được Google xác minh phải trùng chính xác một tài khoản `ACTIVE` trong User List. Vì tài khoản Student chỉ được tạo sau khi Admin duyệt Lab Usage Request, sinh viên chưa được duyệt không thể đăng nhập.
- Mỗi người dùng có tài khoản riêng. Vai trò lưu trong hệ thống quyết định dashboard mở đầu sau khi đăng nhập: `ADMIN`, `LAB_MANAGER`, `MENTOR` hoặc `STUDENT`.
- Trong giai đoạn phát triển hiện tại, hệ thống chỉ yêu cầu đã đăng nhập và **chưa khóa truy cập chéo theo role**, để nhóm có thể mở các URL của role khác khi xây giao diện. Phân quyền cứng sẽ được bật sau.

## Luồng nghiệp vụ chính

1. Mentor nhập thủ công hoặc import Excel danh sách sinh viên, nhóm và các slot học lặp lại hằng tuần theo học kỳ rồi gửi cho Admin.
2. Admin xem toàn bộ request tại `/admin/lab-requests` và phê duyệt hoặc từ chối cả danh sách.
3. Chỉ khi `APPROVED`, hệ thống mới tạo hoặc kích hoạt đồng thời tài khoản `STUDENT` và hồ sơ sinh viên trong cùng transaction; nếu `REJECTED` thì không thêm user. Email đã được Google xác minh là khóa đối chiếu quyền truy cập.
4. Sinh viên được duyệt có thể tự tạo lượt mượn tài sản nhỏ mà không cần Mentor duyệt từng lượt; hệ thống kiểm tra học kỳ, khả năng cho mượn và số lượng còn lại.
5. Mỗi lượt mượn liên kết trực tiếp một sinh viên với một tài sản, có số lượng và hạn trả; Student, Mentor hoặc Lab Manager có thể ghi nhận thao tác theo quyền.
6. Mentor hoặc Lab Manager kiểm tra toàn bộ LAB hoặc một nhóm tài sản được chọn, đối chiếu số lượng và tình trạng thực tế.
7. Khi phát hiện mất, hỏng, sai số lượng, quá hạn hoặc bất thường, Mentor hoặc Student có thể tạo sự cố.
8. Mentor điều tra dựa trên lịch sử mượn trả và bằng chứng trước khi kết luận trách nhiệm.
9. Tài sản hỏng có thể được bảo trì; tài sản không thể sửa có thể được đề xuất thanh lý và chờ Lab Manager phê duyệt.

## Manage Lab Usage Request phía Mentor

Mentor truy cập `/mentor/lab-requests` từ sidebar dùng chung để:

- Xem và lọc request theo từ khóa, trạng thái và học kỳ.
- Tạo request bằng cách nhập tên nhóm, chọn nhiều slot lặp lại hằng tuần và thêm danh sách sinh viên.
- Xem chi tiết mọi request; chỉ sửa hoặc xóa request có trạng thái `PENDING` và thuộc chính Mentor đang đăng nhập.
- Nhập sinh viên và slot trực tiếp trên form hoặc import tệp `.xlsx`.

Các khung giờ cố định:

| Slot | Thời gian |
| --- | --- |
| Slot 1 | 07:30–09:50 |
| Slot 2 | 10:00–12:20 |
| Slot 3 | 12:50–15:10 |
| Slot 4 | 15:20–17:30 |

Một request có thể chọn nhiều slot từ Thứ 2 đến Thứ 7. Các slot được hiểu là lịch lặp lại mỗi tuần trong học kỳ đã chọn.

Tệp Excel phải có đúng hai sheet:

| Sheet | Các cột bắt buộc |
| --- | --- |
| `Students` | `Student Code`, `Full Name`, `Email` |
| `Slots` | `Day Of Week`, `Slot Number` |

Có thể tải file mẫu ngay tại màn Add/Edit. Email được chuẩn hóa về chữ thường, mã sinh viên và email phải duy nhất trong request; xung đột với tài khoản hiện có được kiểm tra khi Admin duyệt.

## Manage Lab Usage Request phía Admin

Admin truy cập `/admin/lab-requests` từ sidebar để lọc, xem lịch và danh sách sinh viên rồi duyệt toàn bộ request. Thao tác duyệt dùng `POST` và khóa request đang `PENDING`:

- `APPROVED`: tạo mới hoặc kích hoạt các tài khoản `STUDENT`, liên kết hồ sơ sinh viên và cập nhật request trong cùng một transaction. Bất kỳ xung đột email/mã sinh viên nào cũng làm rollback toàn bộ.
- `REJECTED`: chỉ lưu trạng thái và ghi chú từ chối; không tạo, kích hoạt hoặc thêm sinh viên vào Manage Users.

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
- Mỗi người dùng có một tài khoản riêng. Hệ thống không suy ra vai trò từ tên hoặc miền email; dữ liệu sinh viên trong request `PENDING` chưa phải tài khoản và chỉ được thêm vào User List sau khi Admin duyệt.
- Chỉ sinh viên có email thuộc danh sách đã được Admin phê duyệt và được kích hoạt mới được truy cập và mượn tài sản trong học kỳ tương ứng.
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

- Schema SQL Server gồm 16 bảng nghiệp vụ và các model Java tương ứng.
- Kết nối SQL Server trực tiếp bằng cấu hình local trong `DBConnection`.
- FE-01 Manage User ở mức MVC/JDBC cơ bản: `UserController`, `UserDAO` và các JSP danh sách, chi tiết, thêm, sửa.
- AU-01: đăng nhập email/mật khẩu BCrypt, Google Authentication, session, chuyển dashboard theo role và đăng xuất dùng chung.
- FE-03 phía Mentor: sidebar dùng chung, List/Add/View/Edit/Delete request, nhiều slot mỗi tuần và import Excel hai sheet `Students`/`Slots`.
- Controller và JSP khung cho dashboard của Admin, Lab Manager, Mentor và Student.
- Mentor Dashboard responsive; dữ liệu trên dashboard hiện là dữ liệu trình diễn.

Chưa triển khai đầy đủ:

- Đổi mật khẩu và phân quyền chặn truy cập chéo theo role.
- DAO, Controller và JSP nghiệp vụ cho FE-02, FE-04 đến FE-09.
- Dữ liệu động cho các dashboard và kiểm thử tự động của các module còn lại. FE-03 đã có test cho chức năng đọc file Excel.

## Công nghệ

- Java 17
- Jakarta EE Web 10
- JSP, JSTL và Jakarta Servlet
- JDBC với Microsoft SQL Server
- BCrypt cho mật khẩu tài khoản nội bộ
- Maven Wrapper
- Apache Tomcat 10.1 qua Cargo Maven plugin
- JUnit 5

## Yêu cầu môi trường

- JDK 17
- Microsoft SQL Server
- Không cần cài Maven toàn cục vì dự án có Maven Wrapper

## Cấu hình cơ sở dữ liệu

Bản demo local không dùng `.env` hoặc biến môi trường. `DBConnection` hiện kết nối trực tiếp đến database `lab_asset_management` trên `localhost:1433` bằng tài khoản SQL Server `minhanh`.

> Đây chỉ là cấu hình phục vụ demo. Không commit mật khẩu thật hoặc dùng cách cấu hình này khi triển khai production.

Với database đã tạo từ phiên bản cũ, chạy migration an toàn sau trước khi khởi động ứng dụng:

```powershell
sqlcmd -S localhost -d lab_asset_management -U sa -P "<password>" -C -i database/migrate_lab_usage_requests.sql
```

Database mới có thể tạo trực tiếp bằng `database/schema.sql`. Migration bổ sung `group_name`, bốn khung giờ cố định, bảng slot lặp theo tuần và học kỳ mẫu `FA26`; không tự tạo tài khoản Mentor và không xóa dữ liệu hiện có.

## Chạy dự án

### Cấu hình Google Authentication

Google Client ID là mã định danh công khai, không phải mật khẩu và không cần file `.env`. Tạo OAuth 2.0 Web Client trong Google Cloud, khai báo:

- Authorized JavaScript origin: `http://localhost:8080`
- Authorized redirect URI khi chạy Cargo: `http://localhost:8080/labtoolequip/login/google`
- Nếu IntelliJ deploy ứng dụng ở root context: `http://localhost:8080/login/google`

Truyền Client ID bằng Java system property khi chạy:

```powershell
.\mvnw.cmd "-Dgoogle.clientId=YOUR_CLIENT_ID.apps.googleusercontent.com" cargo:run
```

Trong IntelliJ/Tomcat có thể thêm VM option tương đương:

```text
-Dgoogle.clientId=YOUR_CLIENT_ID.apps.googleusercontent.com
```

Nếu chưa cấu hình, đăng nhập email/mật khẩu vẫn hoạt động và nút Google hiển thị trạng thái chưa cấu hình.

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
├── migrate_lab_usage_requests.sql # Migration FE-03 cho database hiện có
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
└── test/java/fpt/swp391/labtoolequip/  # Unit test, gồm test import Excel FE-03
```

Dự án hiện theo MVC với Servlet/JSP và DAO dùng JDBC. Chỉ bổ sung DAO, Controller và JSP khi bắt đầu triển khai use case tương ứng.
