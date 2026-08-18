# 🚀 HƯỚNG DẪN CHI TIẾT LUỒNG CHẠY MODULE QUẢN LÝ NGƯỜI DÙNG (USER MANAGEMENT)
*(Trình bày chi tiết và trực quan: **NƠI GỬI (Frontend dòng mấy)** ➔ **NƠI NHẬN (Backend dòng mấy)** ➔ **NƠI TRUY VẤN (DAO/SQL dòng mấy)** ➔ **NƠI HIỂN THỊ KẾT QUẢ**)*

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

### 📤 1. NƠI GỬI (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/includes/sidebar.jspf`
- **Vị trí code (Dòng 26-29):**
  ```html
  <a class="nav-link${activeMenu == 'users' ? ' active' : ''}" href="${pageContext.request.contextPath}/admin/users">
      <svg><use href="#i-users"/></svg>
      <span>Người dùng</span>
  </a>
  ```
- **Hành động:** Admin click chuột vào link "Người dùng".
- **Gói tin gửi đi:** HTTP Request dạng `GET /admin/users`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `src/main/java/fpt/swp391/labtoolequip/controller/admin/UserController.java`
- **Dòng 15:** Nhận diện URL `@WebServlet({"/admin/users", ...})` ➔ Tomcat chuyển request vào `UserController`.
- **Dòng 28:** Phương thức `doGet(HttpServletRequest request, HttpServletResponse response)` tiếp nhận phương thức `GET`.
- **Dòng 31 & Dòng 37:** Lệnh `switch (request.getServletPath())` kiểm tra URL `/admin/users` ➔ Rơi vào nhánh `default` (Dòng 37) và gọi hàm `showList(request, response)`.

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL:
- **Tại Controller (Dòng 63-73):**
  ```java
  private void showList(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
      String keyword = trim(request.getParameter("keyword")); // Nhận keyword = ""
      String role = normalize(request.getParameter("role"));       // Nhận role = ""
      String status = normalize(request.getParameter("status"));   // Nhận status = ""
      
      // Gọi DAO lấy danh sách từ CSDL và lưu vào attribute "users"
      request.setAttribute("users", userDAO.findAll(keyword, role, status));
      
      // Chuyển tiếp (forward) dữ liệu sang file JSP
      request.getRequestDispatcher("/WEB-INF/views/admin/users/list.jsp").forward(request, response);
  }
  ```
- **Tại DAO (`UserDAO.java` - Dòng 28-59):**
  - Thực thi hàm `userDAO.findAll("", "", "")` chạy câu truy vấn SQL:
    ```sql
    SELECT u.user_id, u.full_name, u.email, u.role, u.status,
           sp.student_code, sp.cohort, m.major_name AS major
    FROM dbo.users u
    LEFT JOIN dbo.student_profiles sp ON sp.user_id = u.user_id
    LEFT JOIN dbo.majors m ON m.major_id = sp.major_id
    WHERE u.role != 'ADMIN'
    ORDER BY u.user_id ASC;
    ```

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ (View):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí hiển thị (Dòng 145-218):** Thẻ `<c:forEach var="u" items="${users}">` duyệt qua danh sách và vẽ ra bảng danh sách người dùng gồm 8 cột rõ ràng.

---
---

# HÀNH ĐỘNG 2: Admin gõ tìm kiếm hoặc chọn lọc vai trò / trạng thái

### 📤 1. NƠI GỬI (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code (Dòng 50-95):** Form tìm kiếm & bộ lọc:
  ```html
  <form method="get" action="${pageContext.request.contextPath}/admin/users">
      <input type="text" name="keyword" value="${keyword}" placeholder="Tìm theo tên, email, MSSV...">
      <select name="role">
          <option value="">Tất cả vai trò</option>
          <option value="INTERN" ${selectedRole == 'INTERN' ? 'selected' : ''}>Thực tập sinh</option>
          <option value="MENTOR" ${selectedRole == 'MENTOR' ? 'selected' : ''}>Người hướng dẫn</option>
          <option value="LAB_MANAGER" ${selectedRole == 'LAB_MANAGER' ? 'selected' : ''}>Quản lý phòng LAB</option>
      </select>
      <select name="status">
          <option value="">Tất cả trạng thái</option>
          <option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>Đang hoạt động</option>
          <option value="INACTIVE" ${selectedStatus == 'INACTIVE' ? 'selected' : ''}>Không hoạt động</option>
      </select>
      <button type="submit">Lọc</button>
  </form>
  ```
- **Hành động:** Admin gõ từ khóa (ví dụ: `minh`) hoặc chọn vai trò `INTERN` ➔ Bấm nút **"Lọc"**.
- **Gói tin gửi đi:** HTTP Request dạng `GET /admin/users?keyword=minh&role=INTERN&status=ACTIVE`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)** ➔ **Dòng 37 (`default`)** ➔ Gọi hàm `showList(request, response)`.

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL:
- **Tại Controller (Dòng 65-68):**
  - Lấy tham số: `keyword = "minh"`, `role = "INTERN"`, `status = "ACTIVE"`.
  - Gọi `userDAO.findAll("minh", "INTERN", "ACTIVE")`.
- **Tại DAO (`UserDAO.java` - Dòng 28-59):**
  - Chạy câu lệnh SQL lọc dữ liệu:
    ```sql
    ...
    WHERE u.role != 'ADMIN'
      AND (u.full_name LIKE '%minh%' OR u.email LIKE '%minh%' OR sp.student_code LIKE '%minh%')
      AND (u.role = 'INTERN')
      AND (u.status = 'ACTIVE')
    ORDER BY u.user_id ASC;
    ```

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ (View):
- **File:** `list.jsp`
- Bảng tự động cập nhật chỉ hiển thị những người dùng khớp với điều kiện tìm kiếm.

---
---

# HÀNH ĐỘNG 3: Admin bấm nút "Xem" chi tiết một người dùng

### 📤 1. NƠI GỬI (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code (Dòng 211-212):** Nút Xem trong từng dòng của bảng:
  ```html
  <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/view?id=${u.userId}">Xem</a>
  ```
- **Hành động:** Admin click nút **"Xem"** của người dùng có `id = 5`.
- **Gói tin gửi đi:** HTTP Request dạng `GET /admin/users/view?id=5`.

---

### 📥 2. NƠI NHẬN & ĐIỀU PHỐI (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)**: Tiếp nhận request `GET`.
- **Dòng 32 (`switch` case `"/admin/users/view"`):** Khớp URL và gọi hàm `showDetail(request, response)`.

---

### ⚙️ 3. NƠI XỬ LÝ NGHIỆP VỤ & TRUY VẤN CSDL:
- **Tại Controller (Dòng 75-88):**
  ```java
  private void showDetail(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
      long userId = requireId(request, response); // Dòng 77: Ép kiểu và lấy số 5 từ tham số "id"
      User user = userDAO.findById(userId).orElse(null); // Dòng 81: Tìm user trong CSDL
      
      if (user == null) {
          response.sendError(HttpServletResponse.SC_NOT_FOUND); // Báo lỗi 404 nếu không tìm thấy
          return;
      }
      
      request.setAttribute("user", user); // Đóng gói dữ liệu user
      request.getRequestDispatcher("/WEB-INF/views/admin/users/detail.jsp").forward(request, response); // Dòng 87
  }
  ```
- **Tại DAO (`UserDAO.java` - Dòng 61-70):**
  - Chạy SQL: `SELECT ... WHERE u.user_id = 5;`.

---

### 🎯 4. NƠI NHẬN KẾT QUẢ & HIỂN THỊ (View):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/detail.jsp`
- Hiển thị toàn bộ thông tin chi tiết của người dùng: Họ tên, Email, Vai trò, Trạng thái, Google Subject ID, Mã SV, Chuyên ngành, Khóa học.

---
---

# HÀNH ĐỘNG 4: Admin bấm "+ Thêm Người Dùng" ➔ Điền form ➔ Bấm "Tạo tài khoản"

---

### 📍 GIAI ĐOẠN 4.1: Mở form thêm mới (GET)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `list.jsp` (Dòng 122-125):
  ```html
  <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/add">+ Thêm Người Dùng</a>
  ```
- **Gửi đi:** `GET /admin/users/add`.

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)** ➔ **Dòng 33 (`case "/admin/users/add"`)** ➔ Gọi hàm `showAddForm(request, response)` (Dòng 90-102).

#### ⚙️ 3. Nơi xử lý:
- Tạo `new User()` mặc định, gọi `majorDAO.findActive()` lấy danh mục chuyên ngành.
- Chuyển tiếp (forward) sang `form.jsp` với `formMode = "add"`.

#### 🎯 4. Màn hình hiển thị:
- `form.jsp` hiển thị form trống để Admin nhập thông tin.

---

### 📍 GIAI ĐOẠN 4.2: Điền thông tin và Bấm "Tạo tài khoản" (POST)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/form.jsp`
- **Vị trí code (Dòng 116-169):**
  ```html
  <form method="post" action="${pageContext.request.contextPath}/admin/users/add" class="form-grid">
      <input type="text" name="fullName" required placeholder="Họ và tên...">
      <select name="role" id="roleSelect">...</select>
      <input type="text" name="studentCode" placeholder="Ví dụ: SE160123">
      <input type="email" name="email" required placeholder="Ví dụ: anhnmse160123@fpt.edu.vn">
      <select name="majorId">...</select>
      <input type="text" name="cohort" placeholder="Ví dụ: K16">
      <select name="status"><option value="ACTIVE">Hoạt động ngay</option></select>
      
      <button class="primary-button" type="submit">Tạo tài khoản</button>
  </form>
  ```
- **Hành động:** Admin click nút **"Tạo tài khoản"**.
- **Gói tin gửi đi:** HTTP Request dạng `POST /admin/users/add` chứa toàn bộ dữ liệu trong form.

---

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 45:** Phương thức `doPost(HttpServletRequest request, HttpServletResponse response)` tiếp nhận request `POST`.
- **Dòng 50:** Lệnh `switch` khớp `case "/admin/users/add"` ➔ Gọi hàm `createUser(request, response)`.

---

#### ⚙️ 3. Nơi xử lý nghiệp vụ & Lưu Database:
- **Tại Controller (Dòng 128-142):**
  ```java
  private void createUser(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
      User user = extractUser(request); // Dòng 130: Đọc fullName, email, role, studentCode, majorId, cohort từ form
      List<String> errors = validate(user, true); // Dòng 131: Validate dữ liệu 3 lớp (chống trùng email, trùng mã SV, email FPT)

      if (!errors.isEmpty()) {
          forwardWithErrors(request, response, user, errors, "add"); // Dòng 134: Trả lại form kèm lỗi nếu không hợp lệ
          return;
      }

      userDAO.create(user); // Dòng 138: Gọi DAO lưu vào CSDL
      response.sendRedirect(request.getContextPath() + "/admin/users?success=created"); // Dòng 139: Chuyển hướng
  }
  ```
- **Tại DAO (`UserDAO.java` - Dòng 113-149):**
  - Mở Database Transaction (`connection.setAutoCommit(false)`).
  - Dòng 115-137: `INSERT INTO dbo.users (full_name, email, role, status)` ➔ Lấy `userId` mới sinh.
  - Dòng 139-141: Nếu là `INTERN`, chạy tiếp `INSERT INTO dbo.student_profiles (user_id, student_code, major_id, cohort)`.
  - Dòng 142: `connection.commit()` hoàn tất.

---

#### 🎯 4. Nơi nhận kết quả & Hiển thị (View):
- Trình duyệt chuyển hướng về trang `list.jsp`.
- Màn hình hiển thị thông báo màu xanh lá: **"Tạo người dùng mới thành công!"** và tài khoản mới xuất hiện trên bảng.

---
---

# HÀNH ĐỘNG 5: Admin bấm nút "Sửa" ➔ Sửa thông tin ➔ Bấm "Lưu thay đổi"

---

### 📍 GIAI ĐOẠN 5.1: Mở form chỉnh sửa (GET)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `list.jsp` (Dòng 213-216):
  ```html
  <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/edit?id=8">Sửa</a>
  ```
- **Gửi đi:** `GET /admin/users/edit?id=8`.

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 28 (`doGet`)** ➔ **Dòng 34 (`case "/admin/users/edit"`)** ➔ Gọi hàm `showEditForm(request, response)` (Dòng 104-118).

#### ⚙️ 3. Nơi xử lý:
- Lấy thông tin user ID = 8 từ `userDAO.findById(8)`, lấy danh sách chuyên ngành `majorDAO.findActive()`.
- Chuyển tiếp (forward) sang `form.jsp` với `formMode = "edit"`.

#### 🎯 4. Màn hình hiển thị:
- `form.jsp` hiển thị form có sẵn dữ liệu cũ của user số 8 để Admin chỉnh sửa.

---

### 📍 GIAI ĐOẠN 5.2: Chỉnh sửa và Bấm "Lưu thay đổi" (POST)

#### 📤 1. Nơi gửi (Frontend):
- **File:** `src/main/webapp/WEB-INF/views/admin/users/form.jsp`
- **Vị trí code (Dòng 50-111):**
  ```html
  <form method="post" action="${pageContext.request.contextPath}/admin/users/edit" class="form-grid">
      <input type="hidden" name="id" value="${user.userId}">
      
      <!-- Cho phép sửa Họ tên -->
      <input class="form-control" type="text" name="fullName" value="${user.fullName}" required>
      
      <!-- Email cố định không cho sửa -->
      <input class="form-control readonly-field" type="email" value="${user.email}" readonly disabled>
      
      <!-- Cho phép sửa Mã SV, Chuyên ngành, Khóa (khi là Intern) -->
      <input class="form-control" type="text" name="studentCode" value="${user.studentCode}">
      <select class="form-control" name="majorId">...</select>
      <input class="form-control" type="text" name="cohort" value="${user.cohort}">
      
      <!-- Cho phép đổi Vai trò và Trạng thái -->
      <select class="form-control" name="role">...</select>
      <select class="form-control" name="status">...</select>

      <button class="primary-button" type="submit">Lưu thay đổi</button>
  </form>
  ```
- **Hành động:** Admin click nút **"Lưu thay đổi"**.
- **Gói tin gửi đi:** HTTP Request dạng `POST /admin/users/edit` chứa các giá trị mới.

---

#### 📥 2. Nơi nhận & Điều phối (Backend Controller):
- **File:** `UserController.java`
- **Dòng 45 (`doPost`)** ➔ **Dòng 51 (`case "/admin/users/edit"`)** ➔ Gọi hàm `updateUser(request, response)` (Dòng 143-187).

---

#### ⚙️ 3. Nơi xử lý nghiệp vụ & Cập nhật Database:
- **Tại Controller (Dòng 143-187):**
  ```java
  private void updateUser(HttpServletRequest request, HttpServletResponse response) throws SQLException, ServletException, IOException {
      long userId = requireId(request, response); // Dòng 144: Lấy ID người dùng
      User user = userDAO.findById(userId).orElse(null);
      
      // Dòng 154-159: Đọc dữ liệu mới (fullName, studentCode, majorId, cohort, role, status)
      // Dòng 160-167: Ràng buộc nghiệp vụ (ADMIN, INTERN không bị đổi sai vai trò)
      // Dòng 170-177: Gán dữ liệu mới vào model
      
      List<String> errors = validate(user, false); // Dòng 179: Validate (kiểm tra mã SV mới không trùng với SV khác)
      if (!errors.isEmpty()) {
          forwardWithErrors(request, response, user, errors, "edit");
          return;
      }
      
      userDAO.update(user); // Dòng 185: Lưu cập nhật vào CSDL
      response.sendRedirect(request.getContextPath() + "/admin/users?success=updated"); // Dòng 186
  }
  ```
- **Tại DAO (`UserDAO.java` - Dòng 209-233):**
  - Mở Transaction (`connection.setAutoCommit(false)`).
  - Dòng 224-247: `UPDATE dbo.users SET full_name = ?, role = ?, status = ?, updated_at = SYSUTCDATETIME() WHERE user_id = ?`.
  - Dòng 264-280: Nếu là Intern, chạy tiếp `UPDATE dbo.student_profiles SET student_code = ?, major_id = ?, cohort = ? WHERE user_id = ?`.
  - Dòng 227: `connection.commit()`.

---

#### 🎯 4. Nơi nhận kết quả & Hiển thị (View):
- Trình duyệt chuyển hướng về lại trang `list.jsp`.
- Màn hình hiển thị thông báo màu xanh lá: **"Cập nhật thông tin người dùng thành công!"** và các thông tin sửa đổi được cập nhật trực tiếp trên bảng.

---
---

# HÀNH ĐỘNG 6: Khóa / Mở khóa tài khoản hoặc Đổi vai trò nhanh

### 1. Khóa / Mở khóa tài khoản:
- **📤 Nơi gửi:** Link tại `list.jsp` hoặc `detail.jsp` gửi `GET /admin/users/toggle-status?id=5`.
- **📥 Nơi nhận:** `UserController.java` dòng 28 (`doGet`) ➔ dòng 35 (`case "/admin/users/toggle-status"`) ➔ gọi `toggleStatus()` (Dòng 118-126).
- **⚙️ Nơi xử lý CSDL (`UserDAO.java` - Dòng 166-178):**
  ```sql
  UPDATE dbo.users
  SET status = CASE WHEN status = 'ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END,
      updated_at = SYSUTCDATETIME()
  WHERE user_id = 5;
  ```
- **🎯 Kết quả:** Đổi trạng thái tức thì từ `ACTIVE` ➔ `INACTIVE` (hoặc ngược lại) và load lại trang với thông báo thành công.

---

### 2. Đổi nhanh vai trò Mentor ⇄ Lab Manager:
- **📤 Nơi gửi:** `GET /admin/users/change-role?id=5&role=LAB_MANAGER`.
- **📥 Nơi nhận:** `UserController.java` dòng 36 (`case "/admin/users/change-role"`) ➔ gọi `changeRole()` (Dòng 189-201).
- **⚙️ Nơi xử lý CSDL (`UserDAO.java` - Dòng 180-192):**
  ```sql
  UPDATE dbo.users
  SET role = 'LAB_MANAGER', updated_at = SYSUTCDATETIME()
  WHERE user_id = 5 AND role IN ('MENTOR', 'LAB_MANAGER');
  ```
- **🎯 Kết quả:** Đổi vai trò công tác thành công mà không làm ảnh hưởng đến các vai trò khác.

---

*Tài liệu đã được chuẩn hóa chỉ rõ chính xác từng dòng NƠI GỬI và NƠI NHẬN của từng hành động.* 🎯
