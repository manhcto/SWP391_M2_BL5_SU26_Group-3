# 🚀 HƯỚNG DẪN CHI TIẾT LUỒNG CHẠY MODULE QUẢN LÝ NGƯỜI DÙNG (USER MANAGEMENT)
*(Dành cho thuyết trình, đọc hiểu và bảo vệ đồ án - Trình bày trực quan từ Nút bấm Frontend ➔ Backend ➔ Database ➔ Kết quả màn hình)*

---

## 📑 DANH SÁCH 6 HÀNH ĐỘNG CỦA ADMIN TRONG MODULE:
1. [HÀNH ĐỘNG 1: Admin bấm vào mục "Người dùng" trên Menu Sidebar](#hành-động-1-admin-bấm-vào-mục-người-dùng-trên-menu-sidebar)
2. [HÀNH ĐỘNG 2: Admin gõ tìm kiếm hoặc chọn lọc vai trò / trạng thái](#hành-động-2-admin-gõ-tìm-kiếm-hoặc-chọn-lọc-vai-trò--trạng-thái)
3. [HÀNH ĐỘNG 3: Admin bấm nút "Xem" chi tiết một người dùng](#hành-động-3-admin-bấm-nút-xem-chi-tiết-một-người-dùng)
4. [HÀNH ĐỘNG 4: Admin bấm "+ Thêm Người Dùng" ➔ Điền form ➔ Bấm "Tạo tài khoản"](#hành-động-4-admin-bấm--thêm-người-dùng--điền-form--bấm-tạo-tài-khoản)
5. [HÀNH ĐỘNG 5: Admin bấm nút "Sửa" ➔ Sửa thông tin ➔ Bấm "Lưu thay đổi"](#hành-động-5-admin-bấm-nút-sửa--sửa-thông-tin--bấm-lưu-thay-đổi)
6. [HÀNH ĐỘNG 6: Khóa / Mở khóa nhanh hoặc Đổi vai trò](#hành-động-6-khóa--mở-khóa-nhanh-hoặc-đổi-vai-trò)

---

# HÀNH ĐỘNG 1: Admin bấm vào mục "Người dùng" trên Menu Sidebar

### 🖥️ BƯỚC 1: Ở Frontend (Nút bấm ở đâu?)
- **File:** `src/main/webapp/WEB-INF/views/admin/includes/sidebar.jspf`
- **Vị trí code:** Thẻ menu điều hướng bên trái màn hình:
  ```html
  <a class="nav-link" href="${pageContext.request.contextPath}/admin/users">
      <svg><use href="#i-users"/></svg>
      <span>Người dùng</span>
  </a>
  ```
- **Hành động kích hoạt:** Admin click chuột vào chữ **"Người dùng"**.
- **Yêu cầu gửi đi:** Trình duyệt gửi request `GET /admin/users`.

---

### ⚙️ BƯỚC 2: Backend tiếp nhận & Xử lý ở đâu?
1. **Servlet tiếp nhận:** `UserController.java` (Phương thức `doGet`):
   - Đường dẫn khớp case `default -> showList(request, response);` (Dòng 37).
2. **Hàm xử lý:** `UserController.showList()` (Dòng 63-73):
   ```java
   private void showList(HttpServletRequest request, HttpServletResponse response) {
       // Lấy tham số (lúc này chưa lọc nên là rỗng "")
       String keyword = trim(request.getParameter("keyword"));
       String role = normalize(request.getParameter("role"));
       String status = normalize(request.getParameter("status"));
       
       // Gọi DAO lấy toàn bộ danh sách người dùng từ Database
       request.setAttribute("users", userDAO.findAll(keyword, role, status));
       
       // Chuyển tiếp (forward) dữ liệu sang file list.jsp để hiển thị
       request.getRequestDispatcher("/WEB-INF/views/admin/users/list.jsp").forward(request, response);
   }
   ```
3. **Database truy vấn:** `UserDAO.findAll()` (Dòng 28-59):
   - Chạy câu lệnh SQL:
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

### 🎯 BƯỚC 3: Kết quả trả về trên màn hình
- File `list.jsp` nhận danh sách `${users}` và dùng thẻ `<c:forEach var="u" items="${users}">` vẽ ra **Bảng danh sách 8 cột**:
  *(Mã người dùng, Họ và tên, Email, Vai trò, Mã sinh viên, Chuyên ngành, Trạng thái, Thao tác)*.

---
---

# HÀNH ĐỘNG 2: Admin gõ tìm kiếm hoặc chọn lọc vai trò / trạng thái

### 🖥️ BƯỚC 1: Ở Frontend (Thao tác ở đâu?)
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code:** Thanh tìm kiếm và bộ lọc trên đầu bảng (Dòng 50-95):
  ```html
  <form method="get" action="${pageContext.request.contextPath}/admin/users">
      <!-- Ô nhập từ khóa -->
      <input type="text" name="keyword" value="${keyword}" placeholder="Tìm theo tên, email, MSSV...">
      
      <!-- Dropdown lọc vai trò -->
      <select name="role">
          <option value="">Tất cả vai trò</option>
          <option value="INTERN" ${selectedRole == 'INTERN' ? 'selected' : ''}>Thực tập sinh</option>
          <option value="MENTOR" ${selectedRole == 'MENTOR' ? 'selected' : ''}>Người hướng dẫn</option>
          <option value="LAB_MANAGER" ${selectedRole == 'LAB_MANAGER' ? 'selected' : ''}>Quản lý phòng LAB</option>
      </select>

      <!-- Dropdown lọc trạng thái -->
      <select name="status">
          <option value="">Tất cả trạng thái</option>
          <option value="ACTIVE" ${selectedStatus == 'ACTIVE' ? 'selected' : ''}>Đang hoạt động</option>
          <option value="INACTIVE" ${selectedStatus == 'INACTIVE' ? 'selected' : ''}>Không hoạt động</option>
      </select>

      <button type="submit">Lọc</button>
  </form>
  ```
- **Hành động kích hoạt:** Admin gõ chữ (ví dụ: `minh`) hoặc chọn vai trò `INTERN` ➔ Bấm nút **"Lọc"** (hoặc Enter).
- **Yêu cầu gửi đi:** `GET /admin/users?keyword=minh&role=INTERN&status=ACTIVE`.

---

### ⚙️ BƯỚC 2: Backend tiếp nhận & Xử lý ở đâu?
1. `UserController.showList()` nhận 3 tham số:
   - `keyword = "minh"`
   - `role = "INTERN"`
   - `status = "ACTIVE"`
2. Truyền vào `userDAO.findAll("minh", "INTERN", "ACTIVE")`.
3. Câu lệnh SQL chạy với điều kiện lọc:
   ```sql
   ...
   WHERE u.role != 'ADMIN'
     AND (u.full_name LIKE '%minh%' OR u.email LIKE '%minh%' OR sp.student_code LIKE '%minh%')
     AND (u.role = 'INTERN')
     AND (u.status = 'ACTIVE')
   ORDER BY u.user_id ASC;
   ```

---

### 🎯 BƯỚC 3: Kết quả trả về trên màn hình
- Trang `list.jsp` chỉ hiển thị những người dùng thỏa mãn đúng điều kiện tìm kiếm.
- Các ô input, dropdown vẫn giữ nguyên giá trị đã chọn nhờ biến `${keyword}`, `${selectedRole}`, `${selectedStatus}`.

---
---

# HÀNH ĐỘNG 3: Admin bấm nút "Xem" chi tiết một người dùng

### 🖥️ BƯỚC 1: Ở Frontend (Nút bấm ở đâu?)
- **File:** `src/main/webapp/WEB-INF/views/admin/users/list.jsp`
- **Vị trí code:** Cột cuối cùng của từng dòng trong bảng:
  ```html
  <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/view?id=${u.userId}">Xem</a>
  ```
- **Hành động kích hoạt:** Admin click nút **"Xem"** của người dùng có ID = `5`.
- **Yêu cầu gửi đi:** `GET /admin/users/view?id=5`.

---

### ⚙️ BƯỚC 2: Backend tiếp nhận & Xử lý ở đâu?
1. `UserController.java` (Phương thức `doGet`):
   - Khớp case `"/admin/users/view" -> showDetail(request, response);` (Dòng 32).
2. `UserController.showDetail()` (Dòng 75-88):
   ```java
   private void showDetail(HttpServletRequest request, HttpServletResponse response) {
       long userId = requireId(request, response); // Lấy ra số 5
       User user = userDAO.findById(userId).orElse(null); // Tìm user ID = 5 trong DB
       
       request.setAttribute("user", user); // Đóng gói dữ liệu user
       request.getRequestDispatcher("/WEB-INF/views/admin/users/detail.jsp").forward(request, response);
   }
   ```
3. `UserDAO.findById(5)`:
   - Chạy SQL: `SELECT ... WHERE u.user_id = 5;` trả về đầy đủ: Họ tên, Email, Google Subject ID, Mã SV, Chuyên ngành, Khóa, Ngày tạo, Ngày cập nhật.

---

### 🎯 BƯỚC 3: Kết quả trả về trên màn hình
- Trình duyệt hiển thị trang **`detail.jsp`**: Hồ sơ cá nhân người dùng, có nút "‹ Quay lại" và nút "Chỉnh sửa người dùng này".

---
---

# HÀNH ĐỘNG 4: Admin bấm "+ Thêm Người Dùng" ➔ Điền form ➔ Bấm "Tạo tài khoản"

Luồng này gồm 2 bước: **Mở Form** và **Lưu Dữ Liệu**.

---

### 📍 GIAI ĐOẠN 4.1: Mở form thêm mới (GET)
1. **Frontend:** Admin click nút **"+ Thêm Người Dùng"** ở góc phải trên `list.jsp`:
   ```html
   <a class="primary-button" href="${pageContext.request.contextPath}/admin/users/add">+ Thêm Người Dùng</a>
   ```
2. **Backend xử lý:** `UserController.showAddForm()` (Dòng 90-102):
   - Tạo đối tượng `new User()` mặc định `status = ACTIVE`, `role = INTERN`.
   - Gọi `majorDAO.findActive()` lấy danh mục chuyên ngành từ bảng `dbo.majors`.
   - Chuyển tiếp sang `form.jsp` với `formMode = "add"`.
3. **Màn hình hiển thị:** Form nhập liệu gồm: *Họ tên, Vai trò, Mã sinh viên, Email FPT, Chuyên ngành, Khóa, Trạng thái*.

---

### 📍 GIAI ĐOẠN 4.2: Điền thông tin và Bấm "Tạo tài khoản" (POST)
1. **Frontend:** Admin điền đầy đủ thông tin rồi bấm nút Submit:
   ```html
   <form method="post" action="${pageContext.request.contextPath}/admin/users/add">
       ... các ô input ...
       <button class="primary-button" type="submit">Tạo tài khoản</button>
   </form>
   ```
2. **Backend tiếp nhận:** `UserController.java` (Phương thức `doPost` ➔ gọi `createUser()` - Dòng 128-142):
   ```java
   private void createUser(HttpServletRequest request, HttpServletResponse response) {
       // 1. Đọc dữ liệu từ các ô input
       User user = extractUser(request);
       
       // 2. Validate dữ liệu
       List<String> errors = validate(user, true);
       if (!errors.isEmpty()) {
           // Nếu có lỗi (trùng email, thiếu họ tên, email không phải @fpt.edu.vn):
           forwardWithErrors(request, response, user, errors, "add");
           return;
       }
       
       // 3. Nếu hợp lệ: Lưu vào Database
       userDAO.create(user);
       
       // 4. Chuyển hướng về trang danh sách kèm thông báo thành công
       response.sendRedirect(request.getContextPath() + "/admin/users?success=created");
   }
   ```
3. **Database thực thi Transaction an toàn (`UserDAO.create()` - Dòng 113-149):**
   - Bước A: `INSERT INTO dbo.users (full_name, email, role, status)` ➔ Lấy ID mới sinh `userId`.
   - Bước B (Nếu là Intern): `INSERT INTO dbo.student_profiles (user_id, student_code, major_id, cohort)`.
   - Bước C: `connection.commit()` (Lưu vĩnh viễn vào CSDL).
4. **Kết quả trên màn hình:** Trình duyệt chuyển về `list.jsp`, hiện thanh thông báo màu xanh lá: **"Tạo người dùng mới thành công!"** và người dùng mới xuất hiện ngay trên bảng.

---
---

# HÀNH ĐỘNG 5: Admin bấm nút "Sửa" ➔ Sửa thông tin ➔ Bấm "Lưu thay đổi"

Luồng này cho phép Admin sửa: **Họ và tên, Mã sinh viên, Chuyên ngành, Khóa học, Vai trò (Mentor ⇄ Lab Manager), và Trạng thái**. Email Google OAuth2 được khóa cố định để bảo mật.

---

### 📍 GIAI ĐOẠN 5.1: Mở form chỉnh sửa (GET)
1. **Frontend:** Admin click nút **"Sửa"** tại dòng của user có ID = `8` trên `list.jsp`:
   ```html
   <a class="btn-action" href="${pageContext.request.contextPath}/admin/users/edit?id=8">Sửa</a>
   ```
2. **Backend xử lý:** `UserController.showEditForm()` (Dòng 104-118):
   - Lấy user ID = `8` từ CSDL.
   - Nạp danh mục chuyên ngành `majorDAO.findActive()`.
   - Chuyển tiếp sang `form.jsp` với `formMode = "edit"`.
3. **Màn hình hiển thị:** Form chỉnh sửa với dữ liệu cũ được điền sẵn vào các ô input.

---

### 📍 GIAI ĐOẠN 5.2: Chỉnh sửa và Bấm "Lưu thay đổi" (POST)
1. **Frontend:** Admin sửa lại Họ tên, Mã sinh viên hoặc đổi Chuyên ngành ➔ Bấm nút **"Lưu thay đổi"**:
   ```html
   <form method="post" action="${pageContext.request.contextPath}/admin/users/edit">
       <input type="hidden" name="id" value="${user.userId}">
       
       <!-- Ô sửa Họ tên -->
       <input type="text" name="fullName" value="${user.fullName}" required>
       
       <!-- Email cố định không cho sửa để bảo toàn Google OAuth2 -->
       <input type="email" value="${user.email}" readonly disabled>
       
       <!-- Ô sửa Mã sinh viên (nếu là Intern) -->
       <input type="text" name="studentCode" value="${user.studentCode}">
       
       <!-- Dropdown chọn Chuyên ngành mới -->
       <select name="majorId">...</select>
       
       <button class="primary-button" type="submit">Lưu thay đổi</button>
   </form>
   ```
2. **Backend tiếp nhận:** `UserController.updateUser()` (Dòng 143-187):
   ```java
   private void updateUser(HttpServletRequest request, HttpServletResponse response) {
       long userId = requireId(request, response);
       User user = userDAO.findById(userId).orElse(null);
       
       // Lấy dữ liệu mới từ form
       String fullName = trim(request.getParameter("fullName"));
       String role = normalize(request.getParameter("role"));
       String status = normalize(request.getParameter("status"));
       String studentCode = trim(request.getParameter("studentCode"));
       Long majorId = optionalLong(request.getParameter("majorId"));
       String cohort = trim(request.getParameter("cohort"));
       
       // Cập nhật vào model
       user.setFullName(fullName);
       user.setStatus(status);
       if ("INTERN".equals(user.getRole())) {
           user.setStudentCode(studentCode);
           user.setMajorId(majorId);
           user.setCohort(cohort);
       }
       
       // Validate (Kiểm tra họ tên không trống, mã SV không trùng với SV khác)
       List<String> errors = validate(user, false);
       if (!errors.isEmpty()) {
           forwardWithErrors(request, response, user, errors, "edit");
           return;
       }
       
       // Lưu cập nhật vào CSDL
       userDAO.update(user);
       
       // Chuyển hướng về danh sách
       response.sendRedirect(request.getContextPath() + "/admin/users?success=updated");
   }
   ```
3. **Database thực thi (`UserDAO.update()` - Dòng 209-233):**
   - Chạy `UPDATE dbo.users SET full_name = ?, status = ?, updated_at = SYSUTCDATETIME() WHERE user_id = ?;`
   - Chạy `UPDATE dbo.student_profiles SET student_code = ?, major_id = ?, cohort = ? WHERE user_id = ?;`
4. **Kết quả trên màn hình:** Bảng danh sách cập nhật ngay thông tin mới sửa, hiện thông báo màu xanh: **"Cập nhật thông tin người dùng thành công!"**.

---
---

# HÀNH ĐỘNG 6: Khóa / Mở khóa nhanh hoặc Đổi vai trò

### 1. Khóa / Mở khóa tài khoản:
- **URL kích hoạt:** `GET /admin/users/toggle-status?id=5`
- **Backend xử lý:** `UserController.toggleStatus()` ➔ `UserDAO.toggleStatus()`:
  ```sql
  UPDATE dbo.users
  SET status = CASE WHEN status = 'ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END,
      updated_at = SYSUTCDATETIME()
  WHERE user_id = ?;
  ```
- **Kết quả:** Trạng thái tài khoản đổi tức thì từ `ACTIVE` ➔ `INACTIVE` (hoặc ngược lại).

### 2. Đổi nhanh vai trò Mentor ⇄ Lab Manager:
- **URL kích hoạt:** `GET /admin/users/change-role?id=5&role=LAB_MANAGER`
- **Backend xử lý:** `UserController.changeRole()` ➔ `UserDAO.updateRole()`:
  ```sql
  UPDATE dbo.users
  SET role = ?, updated_at = SYSUTCDATETIME()
  WHERE user_id = ? AND role IN ('MENTOR', 'LAB_MANAGER');
  ```
- **Kết quả:** Chuyển quyền công tác linh hoạt giữa Giảng viên hướng dẫn và Quản lý phòng LAB.

---

## 🏆 TÓM TẮT ĐẶC ĐIỂM KỸ THUẬT NỔI BẬT:
1. **Phân quyền chặt chẽ:** Chặn 100% người dùng không phải `ADMIN` bằng `AuthorizationFilter`.
2. **An toàn dữ liệu:** Bảo toàn liên kết Google OAuth2 bằng cách cố định `email` và quản lý cập nhật 2 bảng bằng **Database Transaction** (`commit` / `rollback`).
3. **Chống SQL Injection:** 100% câu truy vấn dùng **PreparedStatement** có tham số hóa `?`.
