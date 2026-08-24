# 🚀 HƯỚNG DẪN CHI TIẾT LUỒNG CHẠY MODULE QUẢN LÝ NGƯỜI DÙNG (USER MANAGEMENT)
*(Tài liệu chuẩn dành cho thuyết trình và bảo vệ đồ án: **NƠI GỬI (Frontend)** ➔ **NƠI NHẬN (Backend)** ➔ **NƠI XỬ LÝ (DAO/SQL)** ➔ **NƠI HIỂN THỊ KẾT QUẢ** - Kèm giải thích chi tiết từng dòng code và câu lệnh SQL)*

---

## 📑 DANH SÁCH 6 HÀNH ĐỘNG CỦA ADMIN:
1. [HÀNH ĐỘNG 1: Admin bấm vào mục "Người dùng" trên Menu Sidebar](#hành-động-1-admin-bấm-vào-mục-người-dùng-trên-menu-sidebar)
2. [HÀNH ĐỘNG 2: Admin gõ tìm kiếm hoặc chọn lọc vai trò / trạng thái](#hành-động-2-admin-gõ-tìm-kiếm-hoặc-chọn-lọc-vai-trò--trạng-thái)
3. [HÀNH ĐỘNG 3: Admin bấm nút "Xem" chi tiết một người dùng](#hành-động-3-admin-bấm-nút-xem-chi-tiết-một-người-dùng)
4. [HÀNH ĐỘNG 4: Admin bấm "+ Thêm Người Dùng" ➔ Điền form ➔ Bấm "Tạo tài khoản"](#hành-động-4-admin-bấm--thêm-người-dùng--điền-form--bấm-tạo-tài-khoản)
5. [HÀNH ĐỘNG 5: Admin bấm nút "Sửa" ➔ Sửa thông tin ➔ Bấm "Lưu thay đổi"](#hành-động-5-admin-bấm-nút-sửa--sửa-thông-tin--bấm-lưu-thay-đổi)
6. [HÀNH ĐỘNG 6: Khóa / Mở khóa tài khoản hoặc Đổi vai trò nhanh](#hành-động-6-khóa--mở-khóa-tài-khoản-hoặc-đổi-vai-trò-nhanh)

---

# HÀNH ĐỘNG 1: Admin bấm vào mục "Người dùng" trên Menu Sidebar

### 📤 1. NƠI GỬI (Frontend - Giao diện người dùng):
- **File:** `src/main/webapp/WEB-INF/views/admin/includes/sidebar.jspf`
- **Vị trí code (Dòng 26-29):**
  ```html
  <a class="nav-link${activeMenu == 'users' ? ' active' : ''}" href="${pageContext.request.contextPath}/admin/users">
      <svg><use href="#i-users"/></svg>
      <span>Người dùng</span>
  </a>
  ```
- **Giải thích:**
  - `${pageContext.request.contextPath}/admin/users`: Tạo ra đường link tuyệt đối dẫn tới route `/admin/users` của ứng dụng.
  - Khi Admin click vào link này, trình duyệt sẽ gửi đi một HTTP Request bằng phương thức **`GET`** tới URL: `/admin/users`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `src/main/java/fpt/swp391/labtoolequip/controller/admin/UserController.java`
- **Dòng 15:** `@WebServlet({"/admin/users", ...})` ➔ Máy chủ Tomcat nhận biết URL `/admin/users` được ánh xạ vào class `UserController`.
- **Dòng 28:** Phương thức `doGet(HttpServletRequest request, HttpServletResponse response)` được Tomcat tự động gọi để đón request `GET`.
- **Dòng 31-38:** Lệnh `switch (request.getServletPath())` kiểm tra đường dẫn:
  ```java
  switch (request.getServletPath()) {
      case "/admin/users/view" -> showDetail(request, response);
      case "/admin/users/add" -> showAddForm(request, response);
      case "/admin/users/edit" -> showEditForm(request, response);
      case "/admin/users/toggle-status" -> toggleStatus(request, response);
      case "/admin/users/change-role" -> changeRole(request, response);
      default -> showList(request, response); // <── ĐÓN /admin/users TẠI DÒNG 37
  }
  ```
  *(Vì URL là `/admin/users`, không khớp với `/view`, `/add`, `/edit`... nên rơi vào nhánh `default` ở dòng 37 và gọi hàm `showList`).*

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL (Controller & DAO):

#### 🔹 A. Tại Controller (`UserController.java` - Dòng 63-73):
```java
private void showList(HttpServletRequest request, HttpServletResponse response) 
        throws SQLException, ServletException, IOException {
    // Dòng 65-67: Đọc tham số tìm kiếm (lúc mới vào chưa tìm gì nên nhận giá trị rỗng "")
    String keyword = trim(request.getParameter("keyword"));
    String role = normalize(request.getParameter("role"));
    String status = normalize(request.getParameter("status"));
    
    // Dòng 68: Gọi DAO truy vấn CSDL và gắn danh sách người dùng vào biến "users" gửi sang JSP
    request.setAttribute("users", userDAO.findAll(keyword, role, status));
    
    // Dòng 69-71: Lưu lại trạng thái lọc để form không bị mất giá trị
    request.setAttribute("keyword", keyword);
    request.setAttribute("selectedRole", role);
    request.setAttribute("selectedStatus", status);
    
    // Dòng 72: Chuyển tiếp (forward) toàn bộ dữ liệu sang file list.jsp để vẽ giao diện
    request.getRequestDispatcher("/WEB-INF/views/admin/users/list.jsp").forward(request, response);
}
```

#### 🔹 B. Tại DAO (`UserDAO.java` - Dòng 28-59):
Hàm `userDAO.findAll("", "", "")` chạy câu lệnh SQL nối bảng để lấy dữ liệu:
```sql
SELECT u.user_id, u.full_name, u.email, u.password_hash, u.google_subject,
       u.role, u.status, u.created_at, u.updated_at,
       sp.student_code, sp.major_id, m.major_name AS major, sp.cohort
FROM dbo.users u
LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
LEFT JOIN dbo.majors m ON m.major_id = sp.major_id
WHERE u.role != 'ADMIN'
ORDER BY u.user_id ASC;
```

#### 📝 GIẢI THÍCH CHI TIẾT TỪNG DÒNG SQL TRÊN:
- **`SELECT u.user_id, u.full_name, ...`**: Chọn lấy các cột cần thiết từ bảng tài khoản `users` (ID, Họ tên, Email, Vai trò, Trạng thái, Ngày tạo).
- **`FROM dbo.users u`**: Bảng chính chứa thông tin tài khoản người dùng.
- **`LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id`**: Nối bảng `student_profiles` với bảng `users` qua khóa ngoại `user_id`. Dùng `LEFT JOIN` để nếu là Mentor hoặc Lab Manager (không có hồ sơ sinh viên) thì vẫn lấy được tài khoản ra (các cột sinh viên sẽ mang giá trị `NULL`).
- **`LEFT JOIN dbo.majors m ON m.major_id = sp.major_id`**: Nối bảng danh mục `majors` để lấy tên chuyên ngành tiếng Anh chuẩn (`Software Engineering`, `IoT Embedded`...).
- **`WHERE u.role != 'ADMIN'`**: Loại trừ tài khoản Quản trị viên hệ thống để danh sách chỉ hiển thị nhân sự và sinh viên cần quản lý.
- **`ORDER BY u.user_id ASC`**: Sắp xếp danh sách theo ID người dùng tăng dần từ nhỏ đến lớn (từ người tạo trước đến người tạo sau).

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ (View):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code (Dòng 145-218):**
  ```jsp
  <!-- Vòng lặp duyệt từng user trong danh sách ${users} do Servlet gửi sang -->
  <c:forEach var="u" items="${users}">
      <tr>
          <td><strong>#USR-${u.userId}</strong></td> <!-- Cột 1: Mã người dùng ID -->
          <td>${u.fullName}</td>                     <!-- Cột 2: Họ và tên -->
          <td>${u.email}</td>                        <!-- Cột 3: Email -->
          <td>${u.role}</td>                         <!-- Cột 4: Vai trò -->
          <td>${u.studentCode != null ? u.studentCode : '---'}</td> <!-- Cột 5: Mã SV (Staff hiện '---') -->
          <td>${u.major != null ? u.major : '---'}</td>             <!-- Cột 6: Chuyên ngành (Staff hiện '---') -->
          <td>${u.status == 'ACTIVE' ? 'Đang hoạt động' : 'Không hoạt động'}</td> <!-- Cột 7: Trạng thái -->
          <td><!-- Cột 8: Các nút bấm Xem, Sửa --></td>
      </tr>
  </c:forEach>
  ```
- **Kết quả trên màn hình:** Bảng danh sách 8 cột hiển thị đầy đủ toàn bộ người dùng trong hệ thống.

---
---

# HÀNH ĐỘNG 2: Admin gõ tìm kiếm hoặc chọn lọc vai trò / trạng thái

### 📤 1. NƠI GỬI (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code (Dòng 50-95):**
  ```html
  <form method="get" action="${pageContext.request.contextPath}/admin/users">
      <!-- Ô nhập từ khóa tìm kiếm -->
      <input type="text" name="keyword" value="${keyword}" placeholder="Tìm theo tên, email, MSSV...">
      
      <!-- Dropdown chọn vai trò cần lọc -->
      <select name="role">
          <option value="">Tất cả vai trò</option>
          <option value="INTERN" ${selectedRole == 'INTERN' ? 'selected' : ''}>Thực tập sinh</option>
          <option value="MENTOR" ${selectedRole == 'MENTOR' ? 'selected' : ''}>Người hướng dẫn</option>
          <option value="LAB_MANAGER" ${selectedRole == 'LAB_MANAGER' ? 'selected' : ''}>Quản lý phòng LAB</option>
      </select>

      <!-- Dropdown chọn trạng thái cần lọc -->
      <select name="status">
          <option value="">Tất cả trạng thái</option>
          <option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>Đang hoạt động</option>
          <option value="INACTIVE" ${selectedStatus == 'INACTIVE' ? 'selected' : ''}>Không hoạt động</option>
      </select>

      <button type="submit">Lọc</button>
  </form>
  ```
- **Hành động:** Admin gõ từ khóa `minh`, chọn vai trò `INTERN` ➔ Bấm nút **"Lọc"**.
- **Gói tin gửi đi:** Request `GET /admin/users?keyword=minh&role=INTERN&status=ACTIVE`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)** ➔ **Dòng 37 (`default`)** ➔ Gọi hàm `showList(request, response)`.

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL:
- **Tại Controller (Dòng 65-68):**
  - `request.getParameter("keyword")` ➔ lấy chuỗi `"minh"`.
  - `request.getParameter("role")` ➔ lấy chuỗi `"INTERN"`.
  - `request.getParameter("status")` ➔ lấy chuỗi `"ACTIVE"`.
  - Gọi `userDAO.findAll("minh", "INTERN", "ACTIVE")`.
- **Tại DAO (`UserDAO.java` - Dòng 28-59):**
  - Chạy câu lệnh SQL lọc có điều kiện:
    ```sql
    SELECT u.user_id, u.full_name, u.email, u.role, u.status,
           sp.student_code, sp.cohort, m.major_name AS major
    FROM dbo.users u
    LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
    LEFT JOIN dbo.majors m ON m.major_id = sp.major_id
    WHERE u.role != 'ADMIN'
      AND (? = '' OR u.full_name LIKE ? OR u.email LIKE ? OR sp.student_code LIKE ?)
      AND (? = '' OR u.role = ?)
      AND (? = '' OR u.status = ?)
    ORDER BY u.user_id ASC;
    ```
  - **Giải thích:**
    - `(? = '' OR u.full_name LIKE ? ...)`: Nếu có truyền từ khóa `"minh"`, SQL sẽ tìm kiếm tương đối `%minh%` trên cả 3 cột Họ tên, Email và Mã sinh viên.
    - `(? = '' OR u.role = ?)`: Lọc chính xác vai trò là `INTERN`.
    - `(? = '' OR u.status = ?)`: Lọc chính xác trạng thái là `ACTIVE`.

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ:
- **File:** `list.jsp`
- Bảng danh sách lập tức chỉ hiển thị những sinh viên có tên/email/mã SV chứa chữ `minh`, vai trò là Thực tập sinh và đang hoạt động.

---
---

# HÀNH ĐỘNG 3: Admin bấm nút "Xem" chi tiết một người dùng

### 📤 1. NƠI GỬI (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code (Dòng 211-212):**
  ```html
  <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/view?id=${u.userId}">Xem</a>
  ```
- **Hành động:** Admin click nút **"Xem"** của người dùng có ID là `5`.
- **Gói tin gửi đi:** Request `GET /admin/users/view?id=5`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)**: Tiếp nhận request `GET`.
- **Dòng 32 (`case "/admin/users/view"`):** Khớp URL và gọi hàm `showDetail(request, response)`.

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL:
- **Tại Controller (Dòng 75-88):**
  ```java
  private void showDetail(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
      long userId = requireId(request, response); // Dòng 77: Ép kiểu "5" sang số long 5L
      User user = userDAO.findById(userId).orElse(null); // Dòng 81: Tìm kiếm trong DB
      
      if (user == null) {
          response.sendError(HttpServletResponse.SC_NOT_FOUND); // Báo 404 nếu không tìm thấy
          return;
      }
      
      request.setAttribute("user", user); // Dòng 86: Gắn đối tượng user vào request
      request.getRequestDispatcher("/WEB-INF/views/admin/users/detail.jsp").forward(request, response); // Dòng 87
  }
  ```
- **Tại DAO (`UserDAO.java` - Dòng 61-70):**
  - Chạy câu lệnh SQL:
    ```sql
    SELECT u.user_id, u.full_name, u.email, u.password_hash, u.google_subject,
           u.role, u.status, u.created_at, u.updated_at,
           sp.student_code, sp.major_id, m.major_name AS major, sp.cohort
    FROM dbo.users u
    LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
    LEFT JOIN dbo.majors m ON m.major_id = sp.major_id
    WHERE u.user_id = 5;
    ```
  - **Giải thích:** Lấy toàn bộ thông tin chi tiết của riêng người dùng có mã `user_id = 5`.

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ:
- **File:** `src/main/webapp/WEB-INF/views/admin/users/detail.jsp`
- Màn hình hiển thị thẻ hồ sơ cá nhân đầy đủ: Mã người dùng `#USR-5`, Họ tên, Email, Google Subject ID (nếu đã liên kết Google), Mã sinh viên, Chuyên ngành, Khóa học, Ngày tạo và Ngày sửa đổi gần nhất.

---
---

# HÀNH ĐỘNG 4: Admin bấm "+ Thêm Người Dùng" ➔ Điền form ➔ Bấm "Tạo tài khoản"

---

### 📍 GIAI ĐOẠN 4.1: Mở form thêm mới (GET)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `list.jsp` (Dòng 122-125): Thẻ link `<a class="primary-button" href="${pageContext.request.contextPath}/admin/users/add">+ Thêm Người Dùng</a>`.
- **Gửi đi:** `GET /admin/users/add`.

#### 📥 2. Nơi nhận (Backend Controller):
- **File:** `UserController.java` (Dòng 28 `doGet` ➔ Dòng 33 `case "/admin/users/add"` ➔ gọi `showAddForm`).

#### ⚙️ 3. Nơi xử lý (Dòng 90-102):
- Tạo đối tượng `new User()` mặc định vai trò `INTERN`, trạng thái `ACTIVE`.
- Gọi `majorDAO.findActive()` chạy `SELECT major_id, major_code, major_name FROM dbo.majors WHERE is_active = 1` lấy danh sách chuyên ngành đang mở.
- Chuyển tiếp sang `form.jsp` với biến `formMode = "add"`.

#### 🎯 4. Màn hình hiển thị:
- `form.jsp` mở ra giao diện thêm mới người dùng với các ô nhập liệu còn trống.

---

### 📍 GIAI ĐOẠN 4.2: Điền thông tin và Bấm "Tạo tài khoản" (POST)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/form.jsp`
- **Vị trí code (Dòng 116-169):**
  ```html
  <form method="post" action="${pageContext.request.contextPath}/admin/users/add" class="form-grid">
      <input type="text" name="fullName" value="Nguyễn Văn A" required>
      <select name="role" id="roleSelect"><option value="INTERN">Thực tập sinh</option></select>
      <input type="text" name="studentCode" value="SE160999">
      <input type="email" name="email" value="anvse160999@fpt.edu.vn" required>
      <select name="majorId"><option value="1">SE - Software Engineering</option></select>
      <input type="text" name="cohort" value="K16">
      <select name="status"><option value="ACTIVE">Hoạt động ngay</option></select>
      
      <button class="primary-button" type="submit">Tạo tài khoản</button>
  </form>
  ```
- **Hành động:** Admin click nút **"Tạo tài khoản"**.
- **Gói tin gửi đi:** HTTP Request dạng `POST /admin/users/add` chứa toàn bộ dữ liệu điền trong form.

---

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 45:** Phương thức `doPost(HttpServletRequest request, HttpServletResponse response)` đón nhận request `POST`.
- **Dòng 50:** `switch` khớp `case "/admin/users/add"` ➔ Gọi hàm `createUser(request, response)`.

---

#### ⚙️ 3. Nơi xử lý nghiệp vụ & Lưu Database:

##### 🔸 Tại Controller (`UserController.java` - Dòng 128-142):
```java
private void createUser(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
    // 1. Đọc dữ liệu từ form
    User user = extractUser(request); 
    
    // 2. Validate dữ liệu 3 lớp
    List<String> errors = validate(user, true); 
    if (!errors.isEmpty()) {
        // Nếu có lỗi -> Trả về lại form.jsp kèm danh sách thông báo lỗi
        forwardWithErrors(request, response, user, errors, "add"); 
        return;
    }

    // 3. Gọi DAO lưu vào CSDL
    userDAO.create(user); 
    
    // 4. Chuyển hướng về trang danh sách
    response.sendRedirect(request.getContextPath() + "/admin/users?success=created"); 
}
```

##### 🔸 Tại DAO (`UserDAO.java` - Dòng 113-149):
```java
public long create(User user) throws SQLException {
    try (Connection connection = dbConnection.getConnection()) {
        connection.setAutoCommit(false); // Mở Database Transaction
        try {
            // Bước 1: Chèn vào bảng dbo.users
            String sql1 = "INSERT INTO dbo.users (full_name, email, role, status) VALUES (?, ?, ?, ?)";
            // Thực thi chèn và lấy ID mới sinh userId ...

            // Bước 2: Nếu là INTERN, chèn tiếp thông tin học vụ vào dbo.student_profiles
            if ("INTERN".equals(user.getRole())) {
                String sql2 = "INSERT INTO dbo.student_profiles (user_id, student_code, major_id, cohort, status) VALUES (?, ?, ?, ?, ?)";
                // Thực thi chèn student_profiles ...
            }
            
            connection.commit(); // Bước 3: Commit lưu vĩnh viễn cả 2 bảng
            return userId;
        } catch (SQLException exception) {
            connection.rollback(); // Nếu lỗi -> Rollback hủy bỏ toàn bộ
            throw exception;
        }
    }
}
```

#### 📝 GIẢI THÍCH CHI TIẾT CÁC CÂU LỆNH SQL:
1. **`INSERT INTO dbo.users (full_name, email, role, status) VALUES (?, ?, ?, ?)`**: Chèn thông tin tài khoản cơ sở vào bảng `users`. CSDL tự động sinh mã khóa chính `user_id` qua cơ chế `IDENTITY(1,1)`.
2. **`INSERT INTO dbo.student_profiles (user_id, student_code, major_id, cohort, status) VALUES (?, ?, ?, ?, ?)`**: Chèn bản ghi hồ sơ sinh viên liên kết với `user_id` vừa sinh ở trên.
3. **`connection.commit()` / `connection.rollback()`**: Đảm bảo tính toàn vẹn dữ liệu (ACID). Nếu chèn bảng thứ 2 bị lỗi, bảng 1 cũng sẽ bị hủy để không sinh ra tài khoản rác mồ côi.

---

#### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ:
- Trình duyệt chuyển hướng về URL: `/admin/users?success=created`.
- `list.jsp` nhận tham số `success=created` ➔ Hiển thị thanh thông báo màu xanh lá: **"Tạo người dùng mới thành công!"** và người dùng mới vừa tạo xuất hiện ngay ở dòng cuối cùng của bảng.

---
---

# HÀNH ĐỘNG 5: Admin bấm nút "Sửa" ➔ Sửa thông tin ➔ Bấm "Lưu thay đổi"

---

### 📍 GIAI ĐOẠN 5.1: Mở form chỉnh sửa (GET)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `list.jsp` (Dòng 213-216): Thẻ link `<a class="btn-action" href="${pageContext.request.contextPath}/admin/users/edit?id=8">Sửa</a>`.
- **Gửi đi:** `GET /admin/users/edit?id=8`.

#### 📥 2. Nơi nhận (Backend Controller):
- **File:** `UserController.java` (Dòng 28 `doGet` ➔ Dòng 34 `case "/admin/users/edit"` ➔ gọi `showEditForm`).

#### ⚙️ 3. Nơi xử lý (Dòng 104-118):
- Lấy thông tin user có ID = `8` từ CSDL bằng `userDAO.findById(8)`.
- Nạp danh mục chuyên ngành `majorDAO.findActive()`.
- Chuyển tiếp sang `form.jsp` với biến `formMode = "edit"`.

#### 🎯 4. Màn hình hiển thị:
- `form.jsp` mở ra với các ô Họ tên, Mã SV, Chuyên ngành, Khóa học... đã được điền sẵn dữ liệu cũ của user số 8 để Admin chỉnh sửa. Ô Email hiển thị dạng `readonly` cố định.

---

### 📍 GIAI ĐOẠN 5.2: Chỉnh sửa và Bấm "Lưu thay đổi" (POST)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/form.jsp`
- **Vị trí code (Dòng 50-111):**
  ```html
  <form method="post" action="${pageContext.request.contextPath}/admin/users/edit" class="form-grid">
      <input type="hidden" name="id" value="8">
      
      <!-- Sửa Họ tên có dấu -->
      <input class="form-control" type="text" name="fullName" value="Trần Bình Minh" required>
      
      <!-- Email bị khóa cố định để bảo toàn Google OAuth -->
      <input class="form-control readonly-field" type="email" value="minhtbh@fpt.edu.vn" readonly disabled>
      
      <!-- Sửa Mã sinh viên -->
      <input class="form-control" type="text" name="studentCode" value="SE186275">
      
      <!-- Đổi Chuyên ngành mới -->
      <select class="form-control" name="majorId">
          <option value="2" selected>IA - Information Assurance</option>
      </select>
      
      <!-- Sửa Khóa học -->
      <input class="form-control" type="text" name="cohort" value="K18">
      
      <button class="primary-button" type="submit">Lưu thay đổi</button>
  </form>
  ```
- **Hành động:** Admin click nút **"Lưu thay đổi"**.
- **Gói tin gửi đi:** HTTP Request dạng `POST /admin/users/edit` chứa ID và các giá trị mới.

---

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 45:** `doPost()` tiếp nhận request `POST`.
- **Dòng 51:** `switch` khớp `case "/admin/users/edit"` ➔ Gọi hàm `updateUser(request, response)`.

---

#### ⚙️ 3. Nơi xử lý nghiệp vụ & Cập nhật Database:

##### 🔸 Tại Controller (`UserController.java` - Dòng 143-187):
```java
private void updateUser(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
    long userId = requireId(request, response); // Dòng 144: Lấy ID = 8
    User user = userDAO.findById(userId).orElse(null);
    
    // Dòng 154-159: Đọc dữ liệu mới (Họ tên, Mã SV, Chuyên ngành, Khóa, Vai trò, Trạng thái)
    String fullName = trim(request.getParameter("fullName"));
    String studentCode = trim(request.getParameter("studentCode"));
    Long majorId = optionalLong(request.getParameter("majorId"));
    String cohort = trim(request.getParameter("cohort"));
    String status = normalize(request.getParameter("status"));
    
    // Gán dữ liệu mới vào model
    user.setFullName(fullName);
    user.setStatus(status);
    if ("INTERN".equals(user.getRole())) {
        user.setStudentCode(studentCode);
        user.setMajorId(majorId);
        user.setCohort(cohort);
    }
    
    // Dòng 179: Validate kiểm tra (Mã SV mới không được trùng với sinh viên khác trong DB)
    List<String> errors = validate(user, false);
    if (!errors.isEmpty()) {
        forwardWithErrors(request, response, user, errors, "edit");
        return;
    }
    
    // Dòng 185: Gọi DAO cập nhật CSDL
    userDAO.update(user);
    
    // Dòng 186: Chuyển hướng về trang danh sách
    response.sendRedirect(request.getContextPath() + "/admin/users?success=updated");
}
```

##### 🔸 Tại DAO (`UserDAO.java` - Dòng 209-233 & Dòng 264-280):
Thực thi các câu lệnh SQL cập nhật trong Database:
```sql
-- Cập nhật bảng users (Họ tên, vai trò, trạng thái, thời gian sửa đổi)
UPDATE dbo.users
SET full_name = N'Trần Bình Minh',
    role = 'INTERN',
    status = 'ACTIVE',
    updated_at = SYSUTCDATETIME()
WHERE user_id = 8;

-- Cập nhật bảng student_profiles (Mã sinh viên, chuyên ngành, khóa học)
UPDATE dbo.student_profiles
SET student_code = 'SE186275',
    major_id = 2,
    cohort = 'K18',
    status = 'ACTIVE',
    updated_at = SYSUTCDATETIME()
WHERE user_id = 8;
```

#### 📝 GIẢI THÍCH CHI TIẾT CÁC CÂU LỆNH SQL:
- **`UPDATE dbo.users SET full_name = ...`**: Cập nhật lại Họ và tên hiển thị trong hệ thống và tự động cập nhật mốc thời gian `updated_at = SYSUTCDATETIME()`.
- **`UPDATE dbo.student_profiles SET student_code = ..., major_id = ..., cohort = ...`**: Cập nhật mã sinh viên mới, mã định danh chuyên ngành mới (`major_id`) và khóa học mới.

---

#### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ:
- Trình duyệt chuyển hướng về `/admin/users?success=updated`.
- `list.jsp` hiển thị thanh thông báo màu xanh lá: **"Cập nhật thông tin người dùng thành công!"** và bảng danh sách thể hiện ngay thông tin mới sửa.

---
---

# HÀNH ĐỘNG 6: Khóa / Mở khóa tài khoản hoặc Đổi vai trò nhanh

### 1. Khóa / Mở khóa nhanh tài khoản:
- **📤 Nơi gửi:** Link trên giao diện gửi request `GET /admin/users/toggle-status?id=5`.
- **📥 Nơi nhận:** `UserController.java` dòng 28 (`doGet`) ➔ dòng 35 (`case "/admin/users/toggle-status"`) ➔ gọi `toggleStatus()` (Dòng 118-126).
- **⚙️ Nơi xử lý CSDL (`UserDAO.java` - Dòng 166-178):**
  ```sql
  UPDATE dbo.users
  SET status = CASE WHEN status = 'ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END,
      updated_at = SYSUTCDATETIME()
  WHERE user_id = 5;
  ```
  - **Giải thích:** Sử dụng biểu thức `CASE WHEN` trực tiếp trong SQL Server: Nếu tài khoản đang là `ACTIVE` thì đổi sang `INACTIVE`, ngược lại nếu đang `INACTIVE` thì mở lại thành `ACTIVE` trong 1 lượt truy vấn duy nhất.
- **🎯 Kết quả:** Trạng thái tài khoản được đảo ngược tức thì và trang web tự động load lại danh sách.

---

### 2. Đổi nhanh vai trò Mentor ⇄ Lab Manager:
- **📤 Nơi gửi:** Link gửi request `GET /admin/users/change-role?id=5&role=LAB_MANAGER`.
- **📥 Nơi nhận:** `UserController.java` dòng 36 (`case "/admin/users/change-role"`) ➔ gọi `changeRole()` (Dòng 189-201).
- **⚙️ Nơi xử lý CSDL (`UserDAO.java` - Dòng 180-192):**
  ```sql
  UPDATE dbo.users
  SET role = 'LAB_MANAGER',
      updated_at = SYSUTCDATETIME()
  WHERE user_id = 5 AND role IN ('MENTOR', 'LAB_MANAGER');
  ```
  - **Giải thích:** Cập nhật vai trò mới cho nhân sự, có điều kiện chặn `role IN ('MENTOR', 'LAB_MANAGER')` để đảm bảo không bao giờ đổi nhầm vai trò của `ADMIN` hoặc `INTERN`.
- **🎯 Kết quả:** Người dùng được chuyển đổi vai trò công tác thành công.

---

*Tài liệu đã được cập nhật đầy đủ toàn bộ giải thích chi tiết cho từng dòng code và câu lệnh SQL.* 🎯
