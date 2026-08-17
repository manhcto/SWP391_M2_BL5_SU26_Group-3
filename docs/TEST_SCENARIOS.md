# Kịch bản Unit Test và System Test

**Dự án:** LAB Asset Management System  
**Phiên bản tài liệu:** 1.0  
**Ngày lập:** 17/08/2026  
**Căn cứ:** mã nguồn hiện tại, `README.md`, `database/schema.sql` và `database/mock_data.sql`

## 1. Mục tiêu và phạm vi

Tài liệu này kiểm thử các chức năng đã có mã thực thi:

- AU-01: đăng nhập bằng mật khẩu/Google, đăng xuất, session và phân quyền.
- FE-01: quản lý người dùng.
- FE-03: Mentor tạo yêu cầu sử dụng LAB và Admin duyệt/từ chối.
- FE-04: Student mượn/trả tài sản; Lab Manager xem lịch sử.
- FE-08: Mentor đề xuất và Lab Manager xử lý bảo trì.
- FE-09: Lab Manager tạo, cập nhật, hủy và hoàn tất thanh lý.
- FE-10: dashboard theo vai trò.

FE-02 (quản lý tài sản), FE-05 (kiểm kê), FE-06 (sự cố) và FE-07 (trách nhiệm) mới có schema/model hoặc giao diện khung nên chỉ ghi nhận ở backlog, chưa tính vào tiêu chí pass của phiên bản hiện tại.

## 2. Quy ước

| Thuộc tính | Giá trị |
| --- | --- |
| Mức ưu tiên | P0: bảo mật/toàn vẹn dữ liệu; P1: nghiệp vụ chính; P2: chức năng hỗ trợ |
| Trạng thái thiết kế | `AUTO`: phù hợp tự động hóa; `MANUAL`: chạy qua trình duyệt/dịch vụ ngoài; `BACKLOG`: chưa thể chạy do chức năng chưa hoàn thiện |
| Kết quả chạy | `PASS`, `FAIL`, `BLOCKED`, `NOT RUN` |
| Nguyên tắc Unit Test | Không truy cập SQL Server, mạng, Tomcat hoặc filesystem thật |
| Nguyên tắc System Test | Chạy trên WAR triển khai với SQL Server test riêng và dữ liệu có thể reset |

Không viết Unit Test cho getter/setter thuần của model. Các câu SQL, transaction và mapping JDBC được kiểm tra ở mức integration/System Test vì chúng phụ thuộc SQL Server.

## 3. Dữ liệu và môi trường System Test

### 3.1 Môi trường

1. JDK 17, SQL Server và Tomcat 10.1 (qua Cargo Maven plugin).
2. Tạo database riêng `lab_asset_management_test`; tuyệt đối không dùng database production.
3. Chạy lần lượt `database/schema.sql` và `database/mock_data.sql` trên database test.
4. Cấu hình `LAB_TIMEZONE=Asia/Ho_Chi_Minh` và URL ứng dụng `http://localhost:8080/labtoolequip`.
5. Bổ sung tài khoản test có mật khẩu đã biết cho đủ bốn vai trò; tạo thêm một tài khoản `INACTIVE`.
6. Mỗi đợt test phải reset database về cùng một snapshot để ca sau không phụ thuộc ca trước.

### 3.2 Bộ dữ liệu tối thiểu

| Mã dữ liệu | Nội dung |
| --- | --- |
| U-ADMIN | Admin ACTIVE |
| U-MANAGER | Lab Manager ACTIVE |
| U-MENTOR-1 / U-MENTOR-2 | Hai Mentor ACTIVE để kiểm tra quyền sở hữu |
| U-STUDENT-1 / U-STUDENT-2 | Hai Student ACTIVE có student profile |
| U-INACTIVE | Tài khoản INACTIVE có mật khẩu hợp lệ |
| S-ACTIVE | Học kỳ ACTIVE chứa ngày test |
| R-APPROVED | Yêu cầu LAB APPROVED chứa U-STUDENT-1 và slot hiện tại |
| A-QTY | Asset QUANTITY, AVAILABLE, borrowable, tổng số lượng 2 |
| A-SERIAL | Asset SERIALIZED, AVAILABLE, borrowable, tổng số lượng 1 |
| A-FIXED | Asset AVAILABLE nhưng không được mượn |
| A-MAINT | Asset MAINTENANCE |
| A-DISPOSED | Asset DISPOSED |

## 4. Kịch bản Unit Test

### 4.1 Xác thực và session

| ID | Thành phần | Dữ liệu/thao tác | Kết quả mong đợi | Ưu tiên | Tự động hóa |
| --- | --- | --- | --- | --- | --- |
| UT-AUTH-01 | `LoginController.validPassword` | User ACTIVE, BCrypt hash của `123`, mật khẩu `123` | Trả về `true` | P0 | AUTO (đã có) |
| UT-AUTH-02 | `LoginController.validPassword` | Cùng user, mật khẩu sai | Trả về `false` | P0 | AUTO (đã có) |
| UT-AUTH-03 | `LoginController.validPassword` | User INACTIVE, mật khẩu đúng | Trả về `false` | P0 | AUTO (đã có) |
| UT-AUTH-04 | `LoginController.validPassword` | Lần lượt: user null, password null, hash null, hash rỗng | Mọi trường hợp trả về `false`, không ném exception | P0 | AUTO |
| UT-AUTH-05 | `LoginController.validPassword` | Hash không đúng định dạng BCrypt | Trả về `false`, không làm hỏng request | P0 | AUTO |
| UT-AUTH-06 | `LoginController.newState` | Sinh 100 state | Không trùng; mỗi state dùng bảng chữ URL-safe, không có `=` | P0 | AUTO |
| UT-AUTH-07 | `AuthSession.dashboard` | ADMIN, LAB_MANAGER, MENTOR, STUDENT | Trả đúng lần lượt `/admin/dashboard`, `/lab-manager/dashboard`, `/mentor/dashboard`, `/student/dashboard` có context path | P0 | AUTO |
| UT-AUTH-08 | `AuthSession.dashboard` | Role null/không hợp lệ | Trả về `<contextPath>/login` | P0 | AUTO |

### 4.2 Sinh email FPT

| ID | Thành phần | Dữ liệu/thao tác | Kết quả mong đợi | Ưu tiên | Tự động hóa |
| --- | --- | --- | --- | --- | --- |
| UT-EMAIL-01 | `EmailHelper.generateFptEmail` | `Nguyễn Minh Anh`, `SE160123`, student=true | `anhnmse160123@fpt.edu.vn` | P1 | AUTO |
| UT-EMAIL-02 | `EmailHelper.generateFptEmail` | `Phạm Quang Dũng`, code rỗng, student=false | `dungpq@fpt.edu.vn` | P1 | AUTO |
| UT-EMAIL-03 | `EmailHelper.generateFptEmail` | Tên có `Đ`, dấu tiếng Việt, nhiều khoảng trắng | Email bỏ dấu, viết thường, không chứa khoảng trắng | P1 | AUTO |
| UT-EMAIL-04 | `EmailHelper.generateFptEmail` | Code ` HE-18 0101 `, student=true | Code được chuẩn hóa còn ký tự chữ/số | P1 | AUTO |
| UT-EMAIL-05 | `EmailHelper.generateFptEmail` | fullName null/rỗng/chỉ khoảng trắng | Trả chuỗi rỗng | P1 | AUTO |
| UT-EMAIL-06 | `EmailHelper.generateFptEmail` | Có code nhưng student=false | Email không chứa code | P2 | AUTO |

### 4.3 Đọc file yêu cầu LAB

| ID | Thành phần | Dữ liệu/thao tác | Kết quả mong đợi | Ưu tiên | Tự động hóa |
| --- | --- | --- | --- | --- | --- |
| UT-XLSX-01 | `LabUsageRequestExcelReader.read` | File `.xlsx` có sheet Students và Slots hợp lệ | Đọc đúng student, day 2..7 và slot 1..4 | P1 | AUTO (đã có) |
| UT-XLSX-02 | `read(Part)` | Part null hoặc size=0 | Trả hai danh sách rỗng | P1 | AUTO |
| UT-XLSX-03 | `read(InputStream, fileName)` | Tên file `.xls`, `.csv`, null | Ném `IOException` báo chỉ nhận `.xlsx` | P1 | AUTO |
| UT-XLSX-04 | `read` | Thiếu một trong hai sheet bắt buộc | Ném `IOException` nêu đúng cấu trúc cần có | P1 | AUTO |
| UT-XLSX-05 | `readStudents` gián tiếp | Có dòng rỗng xen giữa các dòng hợp lệ | Bỏ qua dòng rỗng, vẫn đọc đủ dữ liệu hợp lệ | P2 | AUTO |
| UT-XLSX-06 | `readStudents` gián tiếp | Dòng chỉ thiếu code, name hoặc email | Ném `IOException` và chỉ đúng số dòng | P1 | AUTO |
| UT-XLSX-07 | `readSlots` gián tiếp | `Thứ 1`, `Thứ 8`, `Slot 0`, `Slot 5` | Ném `IOException` và chỉ đúng số dòng | P1 | AUTO |
| UT-XLSX-08 | `readSlots` gián tiếp | `Thứ 2`, `Slot 3` | Chuyển thành day=2, slotId=3 | P1 | AUTO |
| UT-XLSX-09 | `read` | Nội dung hỏng nhưng đuôi `.xlsx` | Ném `IOException`, không rò exception nội bộ Apache POI ra UI | P1 | AUTO |

### 4.4 Guard nghiệp vụ không cần database

| ID | Thành phần | Dữ liệu/thao tác | Kết quả mong đợi | Ưu tiên | Tự động hóa |
| --- | --- | --- | --- | --- | --- |
| UT-USAGE-01 | `AssetUsageDAO.borrow` | quantity=0 hoặc âm | Ném `IllegalArgumentException` trước khi mở kết nối | P0 | AUTO |
| UT-USAGE-02 | `AssetUsageDAO.returnUsage` | conditionAfter null hoặc ngoài GOOD/FAIR/DAMAGED/BROKEN | Ném `IllegalArgumentException` trước khi mở kết nối | P0 | AUTO |
| UT-DISPOSAL-01 | `DisposalRecordDAO.create` | reason null/rỗng | Ném `IllegalArgumentException` trước khi mở kết nối | P1 | AUTO |
| UT-DISPOSAL-02 | `DisposalRecordDAO.updatePending` | reason null/rỗng | Ném `IllegalArgumentException` trước khi mở kết nối | P1 | AUTO |

### 4.5 Tiêu chí pass Unit Test

- 100% ca P0 và P1 phải PASS.
- Không có test phụ thuộc thứ tự chạy, mạng, đồng hồ hệ thống hoặc database.
- Chạy bằng `mvnw.cmd test`; kết quả lặp lại giống nhau ít nhất ba lần.
- Các model chỉ chứa dữ liệu không cần test riêng.

### 4.6 Baseline ngày 17/08/2026

Lệnh `mvnw.cmd test` đã chạy thành công: **2 tests, 0 failures, 0 errors, 0 skipped**. Hai ca hiện có tương ứng UT-AUTH-01..03 (gộp trong một test method) và UT-XLSX-01. Các ca Unit Test còn lại trong tài liệu đang ở trạng thái `NOT RUN` cho đến khi được tự động hóa.

## 5. Kịch bản System Test

### 5.1 Authentication, authorization và session

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-AUTH-01 | Chưa đăng nhập | Mở `/admin/users`, `/mentor/lab-requests`, `/student/usages`, `/lab-manager/disposals` | Mỗi URL chuyển tới `/login`; không lộ dữ liệu | P0 | AUTO |
| ST-AUTH-02 | Đăng nhập từng role | Truy cập URL của role khác | HTTP 403; không thực thi DAO/mutation | P0 | AUTO |
| ST-AUTH-03 | Chưa đăng nhập và Student | Mở `/labmanager/maintenance` | Chưa đăng nhập bị chuyển login; Student nhận 403 | P0 | AUTO |
| ST-AUTH-04 | U-ADMIN ACTIVE | POST `/login` với mật khẩu đúng | Tạo session mới và chuyển `/admin/dashboard` | P0 | AUTO |
| ST-AUTH-05 | U-ADMIN ACTIVE | Đăng nhập bằng mật khẩu sai | Không tạo session; hiện thông báo chung, không tiết lộ email có tồn tại | P0 | AUTO |
| ST-AUTH-06 | U-INACTIVE | Đăng nhập bằng mật khẩu đúng | Từ chối đăng nhập | P0 | AUTO |
| ST-AUTH-07 | Đã đăng nhập | POST `/logout`, sau đó dùng Back/mở URL bảo vệ | Session bị vô hiệu; URL bảo vệ chuyển login | P0 | AUTO |
| ST-AUTH-08 | Đã đăng nhập | Để session không hoạt động 30 phút | Session hết hạn; lần truy cập tiếp theo chuyển login | P1 | MANUAL |
| ST-AUTH-09 | OAuth cấu hình đúng | Bắt đầu Google login | URL Google có client_id, redirect_uri, scope và state ngẫu nhiên; state lưu trong session | P0 | MANUAL |
| ST-AUTH-10 | OAuth callback | Gửi callback thiếu/sai state | HTTP 400; không đổi trạng thái đăng nhập | P0 | AUTO |
| ST-AUTH-11 | Google email xác minh nhưng ngoài miền FPT hoặc chưa được cấp tài khoản | Hoàn tất OAuth | Từ chối; không tự tạo user | P0 | MANUAL |
| ST-AUTH-12 | User đã bind Google subject A | Đăng nhập bằng subject B cùng email | Từ chối identity mismatch | P0 | MANUAL |
| ST-AUTH-13 | Đã đăng nhập | Kiểm tra cookie session | Cookie có HttpOnly; không chứa role/password ở phía client | P0 | MANUAL |

### 5.2 FE-01 – Quản lý người dùng

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-USER-01 | U-ADMIN | Mở danh sách; lọc theo keyword, role, status | Chỉ trả bản ghi khớp; dữ liệu hiển thị được escape | P1 | AUTO |
| ST-USER-02 | U-ADMIN | Tạo STUDENT đủ fullName, studentCode, status; bỏ trống email | Tạo user và student profile; email FPT tự sinh đúng | P1 | AUTO |
| ST-USER-03 | U-ADMIN | Tạo STUDENT thiếu studentCode | Không ghi DB; hiện lỗi validation | P1 | AUTO |
| ST-USER-04 | U-ADMIN | Tạo user thiếu fullName, role/status bị sửa thành giá trị lạ | Không ghi DB; hiện lỗi tương ứng | P1 | AUTO |
| ST-USER-05 | U-ADMIN | Tạo user trùng email hoặc studentCode | Transaction rollback; hiện thông báo thân thiện; không có bản ghi mồ côi | P0 | AUTO |
| ST-USER-06 | U-ADMIN | Import nhiều dòng hợp lệ, dòng comment/rỗng và email bỏ trống | Bỏ dòng comment/rỗng; tự sinh email; số lượng import đúng | P1 | AUTO |
| ST-USER-07 | U-ADMIN | Import batch chứa một dòng trùng dữ liệu | Quy tắc atomic được xác nhận: rollback toàn batch hoặc báo rõ dòng lỗi; không tạo dữ liệu không xác định | P0 | AUTO |
| ST-USER-08 | U-ADMIN | Toggle ACTIVE → INACTIVE rồi thử đăng nhập user đó | Trạng thái đổi; user không đăng nhập được | P0 | AUTO |
| ST-USER-09 | U-ADMIN | Đổi role hợp lệ MENTOR/LAB_MANAGER và thử role khác | Role hợp lệ được lưu; role ngoài danh sách bị từ chối | P0 | AUTO |
| ST-USER-10 | U-ADMIN | Gọi mutation toggle/change-role bằng GET từ trang ngoài, không có CSRF token | Server phải từ chối; trạng thái user không đổi | P0 | AUTO |

### 5.3 FE-03 – Yêu cầu sử dụng LAB

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-REQ-01 | U-MENTOR-1, học kỳ mở | Tạo request bằng dòng student và slot nhập tay hợp lệ | Tạo PENDING, gắn đúng mentor, semester, students và slots | P1 | AUTO |
| ST-REQ-02 | U-MENTOR-1 | Tải template Excel | HTTP 200; file `.xlsx` mở được, có đúng sheet Students và Slots | P1 | AUTO |
| ST-REQ-03 | U-MENTOR-1 | Tạo request từ file Excel hợp lệ | Dữ liệu import đúng và request PENDING được tạo | P1 | AUTO |
| ST-REQ-04 | U-MENTOR-1 | Kết hợp nhập tay và Excel có student/slot trùng | Dữ liệu được merge, không tạo duplicate | P1 | AUTO |
| ST-REQ-05 | U-MENTOR-1 | Bỏ group/semester/student/slot hoặc email sai định dạng | Không ghi DB; form giữ dữ liệu; hiển thị đầy đủ lỗi | P1 | AUTO |
| ST-REQ-06 | U-MENTOR-1 | POST add/edit/delete thiếu hoặc sai CSRF token | HTTP 403; dữ liệu không đổi | P0 | AUTO |
| ST-REQ-07 | Request thuộc U-MENTOR-1 | U-MENTOR-2 mở chi tiết/sửa/xóa bằng ID đoán được | 404/403; không lộ và không sửa dữ liệu | P0 | AUTO |
| ST-REQ-08 | Request PENDING thuộc U-MENTOR-1 | Sửa students/slots rồi lưu | Update atomic; dữ liệu cũ được thay đúng | P1 | AUTO |
| ST-REQ-09 | Request APPROVED/REJECTED | Mentor thử sửa hoặc xóa | Bị từ chối; dữ liệu không đổi | P0 | AUTO |
| ST-REQ-10 | U-ADMIN, request PENDING | Quyết định APPROVED | Cập nhật approver/time; student được liên kết/kích hoạt theo transaction | P0 | AUTO |
| ST-REQ-11 | U-ADMIN, request PENDING | Quyết định REJECTED kèm note | Status/note đúng; student không được cấp membership | P1 | AUTO |
| ST-REQ-12 | Request đã quyết định | Gửi quyết định lần hai hoặc hai Admin gửi đồng thời | Chỉ một quyết định thành công; không ghi đè quyết định đầu | P0 | AUTO |

### 5.4 FE-04 – Mượn và trả tài sản

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-USAGE-01 | U-STUDENT-1, R-APPROVED, đang đúng slot | Mở `/student/usages/borrow` | Chỉ hiển thị asset AVAILABLE, borrowable và không có disposal PENDING | P1 | AUTO |
| ST-USAGE-02 | Như trên, A-QTY còn 2 | Mượn quantity=1 | Tạo IN_USE, condition_before theo asset, due_at bằng cuối slot, created_by đúng user | P0 | AUTO |
| ST-USAGE-03 | Student ngoài slot/semester hoặc request chưa APPROVED | Thử mượn | Từ chối; không tạo usage | P0 | AUTO |
| ST-USAGE-04 | A-FIXED/A-MAINT/A-DISPOSED | Gửi POST trực tiếp để mượn | Từ chối dù assetId hợp lệ | P0 | AUTO |
| ST-USAGE-05 | A-QTY tổng 2, đang mượn 1 | Mượn thêm 2 | Từ chối insufficient quantity; không over-borrow | P0 | AUTO |
| ST-USAGE-06 | A-SERIAL tổng 1 | Hai Student gửi mượn đồng thời | Đúng một request thành công; tổng IN_USE không vượt 1 | P0 | AUTO |
| ST-USAGE-07 | Asset có disposal PENDING | Thử mượn | Từ chối; không tạo usage | P0 | AUTO |
| ST-USAGE-08 | Usage IN_USE của U-STUDENT-1 | Trả với GOOD/FAIR/DAMAGED/BROKEN | Chuyển RETURNED, ghi returned_at/condition_after/note | P0 | AUTO |
| ST-USAGE-09 | Usage đã RETURNED | Gửi trả lần hai | Từ chối; bản ghi không đổi | P0 | AUTO |
| ST-USAGE-10 | Usage của U-STUDENT-1 | U-STUDENT-2 mở chi tiết hoặc gửi trả bằng ID đó | Không xem được; không trả hộ được | P0 | AUTO |
| ST-USAGE-11 | U-STUDENT-1 có nhiều usage | Mở history/detail | Chỉ thấy dữ liệu của chính mình, sắp mới nhất trước | P0 | AUTO |
| ST-USAGE-12 | U-MANAGER | Lọc toàn bộ usage theo keyword/status | Xem đúng dữ liệu toàn hệ thống; filter hoạt động | P1 | AUTO |

### 5.5 FE-08 – Bảo trì

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-MAINT-01 | U-MENTOR-1 | Tạo đề xuất với asset, quantity, description hợp lệ | Tạo PENDING, requested_by đúng Mentor | P1 | AUTO |
| ST-MAINT-02 | Có đề xuất của hai Mentor | U-MENTOR-1 mở danh sách/chi tiết | Chỉ thấy đề xuất của mình | P0 | AUTO |
| ST-MAINT-03 | U-MANAGER, record PENDING | APPROVED kèm note | Ghi approver/time/note; asset chuyển MAINTENANCE | P1 | AUTO |
| ST-MAINT-04 | U-MANAGER, record PENDING | REJECTED | Record REJECTED; asset không bị đưa vào MAINTENANCE | P1 | AUTO |
| ST-MAINT-05 | Record APPROVED | Chuyển IN_PROGRESS | Ghi repair_started_at; chưa có repair_completed_at | P1 | AUTO |
| ST-MAINT-06 | Record IN_PROGRESS | Chuyển COMPLETED, nhập result/note | Ghi completed_at; asset trở lại AVAILABLE | P0 | AUTO |
| ST-MAINT-07 | Record ở trạng thái bất kỳ | Gửi status/decision ngoài tập hợp hoặc nhảy trạng thái | Server từ chối; record và asset không đổi | P0 | AUTO |
| ST-MAINT-08 | Giả lập lỗi khi update asset sau khi update record | Thực hiện approve/complete | Toàn transaction rollback; record và asset không lệch trạng thái | P0 | AUTO |
| ST-MAINT-09 | U-STUDENT hoặc chưa đăng nhập | POST trực tiếp add/approve/edit | 403 hoặc redirect login; không mutation | P0 | AUTO |

### 5.6 FE-09 – Thanh lý

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-DISP-01 | U-MANAGER | Mở form tạo | Chỉ hiện asset chưa DISPOSED và chưa có disposal PENDING | P1 | AUTO |
| ST-DISP-02 | Asset hợp lệ | Tạo với reason rỗng | Hiện validation; không ghi DB | P1 | AUTO |
| ST-DISP-03 | A-QTY tổng 2 | Tạo disposal | Record PENDING có quantity=2 và requested_by đúng | P1 | AUTO |
| ST-DISP-04 | Disposal PENDING | Sửa reason hợp lệ | Chỉ reason của record PENDING được đổi | P1 | AUTO |
| ST-DISP-05 | Disposal không còn PENDING | Thử sửa/hủy/complete lại | Từ chối; dữ liệu không đổi | P0 | AUTO |
| ST-DISP-06 | Disposal PENDING | Hủy kèm note | Status chuyển CANCELLED, ghi note; asset vẫn dùng được nếu không có chặn khác | P1 | AUTO |
| ST-DISP-07 | Asset còn usage IN_USE | Complete disposal | Từ chối và rollback | P0 | AUTO |
| ST-DISP-08 | Không còn usage IN_USE | Complete disposal | Disposal COMPLETED; asset DISPOSED và is_borrowable=false trong cùng transaction | P0 | AUTO |
| ST-DISP-09 | Disposal vừa complete | Student gửi request mượn bằng assetId | Từ chối | P0 | AUTO |
| ST-DISP-10 | Hai Manager thao tác cùng disposal PENDING | Complete/cancel đồng thời | Chỉ một thao tác thành công; không có trạng thái trung gian | P0 | AUTO |
| ST-DISP-11 | Có nhiều record | Lọc keyword/status | Danh sách đúng filter và mới nhất trước | P2 | AUTO |

### 5.7 Dashboard, giao diện và yêu cầu phi chức năng

| ID | Tiền điều kiện | Các bước chính | Kết quả mong đợi | Ưu tiên | Kiểu |
| --- | --- | --- | --- | --- | --- |
| ST-UI-01 | Đăng nhập từng role | Mở dashboard | Chuyển đúng dashboard, menu không hiển thị chức năng trái quyền | P1 | MANUAL |
| ST-UI-02 | Dữ liệu có ký tự `<script>` trong field tự do | Mở list/detail | Ký tự được hiển thị dạng text; script không chạy | P0 | AUTO |
| ST-UI-03 | Dữ liệu tiếng Việt | Tạo, tìm kiếm và xem lại | UTF-8 đúng, không lỗi dấu | P1 | MANUAL |
| ST-UI-04 | Chrome/Edge bản hiện hành; viewport 360, 768, 1440 px | Duyệt các form/list/detail chính | Không tràn ngang ngoài bảng có chủ đích; menu và nút thao tác dùng được | P2 | MANUAL |
| ST-NF-01 | Dataset 10.000 users, 50.000 usages | Mở/filter các trang danh sách 10 lần | p95 phản hồi server dưới 2 giây trong môi trường test chuẩn | P2 | AUTO |
| ST-NF-02 | 20 request đồng thời mượn asset tổng quantity=2 | Gửi đồng thời | Tối đa tổng quantity 2 thành công; không deadlock kéo dài/quá bán | P0 | AUTO |
| ST-NF-03 | Tắt DB trong khi submit | Thực hiện mutation | Hiện lỗi kiểm soát; không lộ connection string/stack trace/secrets | P0 | MANUAL |

## 6. Ma trận truy vết yêu cầu

| Yêu cầu | Kịch bản chính | Khả năng chạy hiện tại |
| --- | --- | --- |
| AU-01 | UT-AUTH-*, ST-AUTH-* | Có thể chạy; OAuth cần Google test account/config |
| FE-01 | UT-EMAIL-*, ST-USER-* | Có thể chạy |
| FE-02 | ST-USAGE-04, ST-MAINT-*, ST-DISP-* chỉ kiểm tra trạng thái asset liên quan | BACKLOG cho CRUD asset độc lập |
| FE-03 | UT-XLSX-*, ST-REQ-* | Có thể chạy; route duyệt hiện thuộc Admin |
| FE-04 | UT-USAGE-*, ST-USAGE-* | Có thể chạy khi đúng slot hiện tại |
| FE-05 | Chưa có controller/DAO/JSP nghiệp vụ | BACKLOG |
| FE-06 | Chưa có controller/DAO/JSP nghiệp vụ | BACKLOG |
| FE-07 | Chưa có controller/DAO/JSP nghiệp vụ | BACKLOG |
| FE-08 | ST-MAINT-* | Có thể chạy sau khi xử lý lỗi route/phân quyền |
| FE-09 | UT-DISPOSAL-*, ST-DISP-* | Có thể chạy sau khi đồng bộ trạng thái CANCELLED |
| FE-10 | ST-UI-01 | Có thể chạy; một phần dashboard vẫn là dữ liệu trình diễn |

## 7. Rủi ro/khuyết điểm mã nguồn mà bộ test phải bắt được

1. `AuthorizationFilter` chỉ bảo vệ prefix `/lab-manager/`, trong khi maintenance dùng `/labmanager/maintenance`; ST-AUTH-03 và ST-MAINT-09 dự kiến FAIL cho đến khi route được đồng bộ.
2. `DisposalRecordDAO.cancel` ghi status `CANCELLED`, nhưng constraint `CK_disposal_records_status` trong `schema.sql` không cho phép `CANCELLED`; ST-DISP-06 dự kiến FAIL.
3. Toggle status và change role của user được gọi bằng GET, không có CSRF token; ST-USER-10 dự kiến FAIL và đây là lỗi bảo mật P0.
4. Luồng maintenance cập nhật record và asset bằng hai transaction tách rời, đồng thời bắt rồi bỏ qua lỗi cập nhật asset; ST-MAINT-08 có thể phát hiện trạng thái lệch.
5. `MaintenanceDAO` chưa ràng buộc transition trạng thái trong câu UPDATE; ST-MAINT-07 có thể phát hiện việc nhảy trạng thái hoặc decision không hợp lệ.
6. Tài liệu nghiệp vụ mô tả Lab Manager duyệt yêu cầu LAB, nhưng mã hiện tại dùng route `/admin/lab-requests` và yêu cầu role ADMIN; cần chốt lại yêu cầu trước khi nghiệm thu ST-REQ-10..12.

## 8. Thứ tự chạy đề xuất

1. Build và Unit Test: `mvnw.cmd clean test`.
2. Khởi tạo lại database test.
3. Chạy smoke: ST-AUTH-01..07, ST-USER-02, ST-REQ-01/10, ST-USAGE-02/08, ST-MAINT-01/03/06, ST-DISP-03/08.
4. Chạy toàn bộ ca P0, sau đó P1 và P2.
5. Chạy concurrency và non-functional cuối cùng trên database vừa reset.
6. Lưu evidence gồm timestamp, input, HTTP status, ảnh màn hình và truy vấn xác nhận DB cho mọi ca FAIL.

## 9. Tiêu chí hoàn thành

- 100% P0 được chạy và PASS; không chấp nhận lỗi phân quyền, over-borrow hoặc transaction nửa chừng.
- Ít nhất 95% P1 PASS; mọi FAIL còn lại có defect ID, owner và thời hạn sửa.
- Không còn defect mức Critical/High mở.
- Các chức năng BACKLOG không được tính làm PASS và không được ghi là đã kiểm thử.

## 10. Mẫu ghi nhận kết quả

| Test ID | Build | Người chạy | Thời gian | Actual result | Kết quả | Defect ID | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ST-... | 1.0-SNAPSHOT |  |  |  | NOT RUN |  |  |
