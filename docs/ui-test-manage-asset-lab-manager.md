# UI Test Plan — Manage Asset (Lab Manager)

## 1. Mục tiêu

Kiểm thử giao diện của chức năng **Manage Asset** dành cho `LAB_MANAGER`:

- Xem, lọc và tìm kiếm `AssetItem`.
- Tạo một nhóm thiết bị và sinh nhiều sản phẩm riêng.
- Import danh sách sản phẩm từ Excel.
- Sửa tình trạng/trạng thái từng sản phẩm.
- Xóa sản phẩm khi thỏa điều kiện nghiệp vụ.

Phạm vi này là **UI automation/E2E test** bằng Playwright. Các unit test `AssetItemDAOTest` và `AssetItemExcelReaderTest` vẫn chạy riêng.

## 2. Điều kiện trước khi chạy

1. Khởi tạo database bằng `database/lab_asset_management_full.sql`.
2. Chạy ứng dụng ở địa chỉ mặc định `http://localhost:8080`.
3. Dùng tài khoản Lab Manager demo:

   ```text
   Email: manager@gmail.com
   Password: 123
   ```

4. Mỗi test tạo dữ liệu mới phải dùng tiền tố mã riêng: `E2E-AST-<timestamp>` để không trùng dữ liệu có sẵn.
5. Không chạy test xóa trên item demo hoặc item đã có lịch sử sử dụng.

## 3. Route và selector hiện có

| Màn hình | Route | Selector/locator ưu tiên |
| --- | --- | --- |
| Login | `/login` | `#email`, `#password`, `button[type='submit']` |
| Danh sách | `/lab-manager/assets` | `a[href$='/lab-manager/assets/new']`, `input[name='keyword']`, `select[name='status']`, `select[name='condition']` |
| Tạo thiết bị | `/lab-manager/assets/new` | `#assetCode`, `#assetName`, `#categoryId`, `#assetType`, `#quantity` |
| Tạo item | Form tạo | `input[name='itemSerialNumber']`, `select[name='itemCondition']`, `select[name='itemStatus']`, `button[name='action'][value='create']` |
| Import Excel | Form tạo | `#assetFile`, `button[name='action'][value='import']` |
| Sửa item | `/lab-manager/assets/{id}/edit` | `#serialNumber`, `#condition`, `#status`, `button[type='submit']` |
| Xóa item | Chi tiết item | `form[action$='/delete'] button` |

> Không dùng XPath theo vị trí. Ưu tiên `id`, `name`, text nút hoặc URL có ý nghĩa nghiệp vụ.

## 4. Kịch bản UI automation

| ID | Kịch bản | Bước chính | Kết quả mong đợi | Ưu tiên |
| --- | --- | --- | --- | --- |
| UI-AST-01 | Đăng nhập Lab Manager và mở danh sách | Login → mở `/lab-manager/assets` | Hiện tiêu đề `Quản lý thiết bị` và nút `+ Thêm thiết bị` | Critical |
| UI-AST-02 | Lọc danh sách theo trạng thái và condition | Chọn `AVAILABLE` + `GOOD` → bấm `Lọc` | Mọi dòng trả về có badge `Sẵn sàng` và `Tốt`, hoặc màn hình báo không có dữ liệu | High |
| UI-AST-03 | Tạo nhóm thiết bị có hai item | Nhập mã duy nhất, tên, category, `BORROWABLE`, quantity `2`, serial cho 2 dòng → tạo | Redirect về list, hiện thông báo thành công, có `E2E-AST-...-0001` và `-0002` | Critical |
| UI-AST-04 | Tạo tài sản cố định | Chọn `FIXED`, quantity `1` → tạo | Dòng mới hiển thị dạng tài sản `Cố định`; không thể mượn | High |
| UI-AST-05 | Kiểm tra quantity không hợp lệ | Nhập quantity `0` hoặc `101` → submit | Form bị chặn bởi validation hoặc hiện lỗi số lượng phải từ 1 đến 100 | High |
| UI-AST-06 | Cập nhật item hư hỏng sang bảo trì | Mở item test → chọn `DAMAGED` + `MAINTENANCE` → lưu | Redirect về chi tiết, status/tình trạng mới hiển thị đúng | High |
| UI-AST-07 | Không cho item hư hỏng vẫn sẵn sàng | Mở item test → chọn `DAMAGED` + `AVAILABLE` → lưu | Không cập nhật thành công; hiện lỗi yêu cầu `MAINTENANCE` hoặc `DISPOSED` | Critical |
| UI-AST-08 | Import Excel hợp lệ | Upload `.xlsx` có `Tốt`, `Sẵn sàng`, serial → `Nạp từ Excel` → tạo | Hiện thông báo đã nạp dữ liệu; serial được đưa vào bảng; tạo thành công | High |
| UI-AST-09 | Import Excel condition sai | Upload `.xlsx` có condition `Không rõ` → `Nạp từ Excel` | Hiện lỗi condition không hợp lệ; không tạo asset | High |
| UI-AST-10 | Xóa item test không có lịch sử sử dụng | Mở một item `E2E-AST` chưa dùng → xác nhận dialog xóa | Redirect về list, hiện thông báo xóa thành công | Medium |
| UI-AST-11 | Không xóa item cuối cùng/đã có usage | Mở item thuộc asset chỉ còn một item hoặc có usage → xóa | Hệ thống từ chối và giữ dữ liệu | High |

## 5. Test data

| Loại | Giá trị đề nghị |
| --- | --- |
| Asset code | `E2E-AST-20260820-001` — sinh lại mỗi lần chạy |
| Asset name | `Playwright Test Multimeter` |
| Item serial | `E2E-SN-001`, `E2E-SN-002` |
| Borrowable asset | `BORROWABLE` |
| Fixed asset | `FIXED` |
| Hợp lệ | `GOOD` + `AVAILABLE`; `DAMAGED` + `MAINTENANCE` |
| Không hợp lệ | `DAMAGED` + `AVAILABLE`; serial dài 101 ký tự; quantity `0`/`101` |
| Excel hợp lệ | `SN-001`, `Tốt`, `Sẵn sàng`, ngày `20/08/2026` |
| Excel không hợp lệ | condition `Không rõ` |

## 6. Quy trình chạy Playwright

### 6.1 Chạy ứng dụng

Mở terminal thứ nhất tại thư mục dự án:

```powershell
.\mvnw.cmd cargo:run
```

Chờ đến khi ứng dụng sẵn sàng tại `http://localhost:8080`.

### 6.2 Chạy test UI

Mở terminal thứ hai tại thư mục dự án. Playwright test phải dùng `headless=false` để nhìn thấy browser thao tác:

```java
Browser browser = playwright.chromium().launch(
    new BrowserType.LaunchOptions().setHeadless(false).setSlowMo(150)
);
```

Sau khi tạo class Playwright, chạy riêng test đó bằng Maven, ví dụ:

```powershell
.\mvnw.cmd test "-Dtest=LabManagerAssetUiTest"
```

## 7. Quy tắc cho Playwright test

- Mỗi test phải tự đăng nhập và tạo `BrowserContext` riêng để không dùng lại session.
- Dùng `page.getByLabel(...)`, `page.locator("#assetCode")` hoặc `page.getByRole(...)`; tránh `page.waitForTimeout(...)`.
- Sau thao tác tạo/sửa/xóa, kiểm tra URL, thông báo thành công/lỗi và nội dung danh sách/chi tiết.
- Chụp screenshot khi test fail và lưu vào `target/playwright-screenshots/`.
- Test tạo dữ liệu phải xóa dữ liệu test sau khi hoàn tất. Nếu không thể xóa do rule nghiệp vụ, ghi rõ mã asset để dọn bằng database test.
- Không hard-code `assetItemId`; tìm item theo mã `E2E-AST-...` do test vừa tạo.

## 8. Phân loại kết quả

| Kết quả | Điều kiện |
| --- | --- |
| PASS | Actual Result khớp Expected Result và assertion Playwright pass |
| FAIL | UI/response khác Expected Result hoặc assertion fail |
| BLOCKED | App, database, test account hoặc browser chưa sẵn sàng |

Khi FAIL, lưu screenshot/log, ghi Test Case ID, dữ liệu đã dùng và Actual Result. Sau khi sửa lỗi, chạy lại case bị fail và các case liên quan (`UI-AST-03` đến `UI-AST-11`) để regression.
