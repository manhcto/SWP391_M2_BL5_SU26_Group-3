/* Local/demo data. Run after database/schema.sql. Safe to run repeatedly. */
USE [lab_asset_management];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @password_hash varchar(255) = '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C';
    DECLARE @approval_at datetime2(0) = '2026-08-01T08:00:00';

    DECLARE @interns TABLE (
        email varchar(255) NOT NULL PRIMARY KEY,
        full_name nvarchar(100) NOT NULL,
        student_code varchar(30) NOT NULL,
        cohort varchar(30) NOT NULL
    );

    INSERT @interns (email, full_name, student_code, cohort)
    VALUES
        ('anhnmhe171286@fpt.edu.vn', N'Nguyễn Minh Anh', 'HE171286', 'K17'),
        ('trungndhe180362@fpt.edu.vn', N'Nguyễn Đức Trung', 'HE180362', 'K18'),
        ('ductmhe180875@fpt.edu.vn', N'Từ Minh Đức', 'HE180875', 'K18'),
        ('minhtbhe186275@fpt.edu.vn', N'Trần Bình Minh', 'HE186275', 'K18'),
        ('minhlahe180101@fpt.edu.vn', N'Lương Anh Minh', 'HE180101', 'K18');

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'admin@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, must_change_password, role, status)
        VALUES (N'Demo Admin', 'admin@gmail.com', @password_hash, 0, 'ADMIN', 'ACTIVE');

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'manager@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, must_change_password, role, status)
        VALUES (N'Demo Lab Manager', 'manager@gmail.com', @password_hash, 0, 'LAB_MANAGER', 'ACTIVE');

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'mentor@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, must_change_password, role, status)
        VALUES (N'Demo Mentor', 'mentor@gmail.com', @password_hash, 0, 'MENTOR', 'ACTIVE');

    UPDATE dbo.users
    SET full_name = CASE email
                        WHEN 'admin@gmail.com' THEN N'Demo Admin'
                        WHEN 'manager@gmail.com' THEN N'Demo Lab Manager'
                        WHEN 'mentor@gmail.com' THEN N'Demo Mentor'
                    END,
        password_hash = @password_hash,
        must_change_password = 0,
        password_expires_at = NULL,
        role = CASE email
                   WHEN 'admin@gmail.com' THEN 'ADMIN'
                   WHEN 'manager@gmail.com' THEN 'LAB_MANAGER'
                   WHEN 'mentor@gmail.com' THEN 'MENTOR'
               END,
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    WHERE email IN ('admin@gmail.com', 'manager@gmail.com', 'mentor@gmail.com')
      AND (full_name <> CASE email
                             WHEN 'admin@gmail.com' THEN N'Demo Admin'
                             WHEN 'manager@gmail.com' THEN N'Demo Lab Manager'
                             WHEN 'mentor@gmail.com' THEN N'Demo Mentor'
                         END
           OR password_hash IS NULL
           OR password_hash <> @password_hash
           OR must_change_password <> 0
           OR password_expires_at IS NOT NULL
           OR role <> CASE email
                          WHEN 'admin@gmail.com' THEN 'ADMIN'
                          WHEN 'manager@gmail.com' THEN 'LAB_MANAGER'
                          WHEN 'mentor@gmail.com' THEN 'MENTOR'
                      END
           OR status <> 'ACTIVE');

    INSERT dbo.users (full_name, email, password_hash, must_change_password, role, status)
    SELECT i.full_name, i.email, NULL, 0, 'INTERN', 'ACTIVE'
    FROM @interns AS i
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.users AS u
        WHERE u.email = i.email
    );

    UPDATE u
    SET full_name = i.full_name,
        password_hash = NULL,
        must_change_password = 0,
        password_expires_at = NULL,
        role = 'INTERN',
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    FROM dbo.users AS u
    JOIN @interns AS i ON i.email = u.email
    WHERE u.full_name <> i.full_name
       OR u.password_hash IS NOT NULL
       OR u.must_change_password <> 0
       OR u.password_expires_at IS NOT NULL
       OR u.role <> 'INTERN'
       OR u.status <> 'ACTIVE';

    INSERT dbo.student_profiles (user_id, student_code, cohort, status)
    SELECT u.user_id, i.student_code, i.cohort, 'ACTIVE'
    FROM @interns AS i
    JOIN dbo.users AS u ON u.email = i.email
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.student_profiles AS p
        WHERE p.user_id = u.user_id
    );

    UPDATE p
    SET student_code = i.student_code,
        cohort = i.cohort,
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    FROM dbo.student_profiles AS p
    JOIN dbo.users AS u ON u.user_id = p.user_id
    JOIN @interns AS i ON i.email = u.email
    WHERE p.student_code <> i.student_code
       OR p.cohort IS NULL
       OR p.cohort <> i.cohort
       OR p.status <> 'ACTIVE';

    IF NOT EXISTS (SELECT 1 FROM dbo.semesters WHERE code = 'DEMO-2026')
        INSERT dbo.semesters (code, name, start_date, end_date, status)
        VALUES ('DEMO-2026', N'Demo Year 2026', '2026-01-01', '2026-12-31', 'ACTIVE');

    UPDATE dbo.semesters
    SET name = N'Demo Year 2026',
        start_date = '2026-01-01',
        end_date = '2026-12-31',
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    WHERE code = 'DEMO-2026'
      AND (name <> N'Demo Year 2026'
           OR start_date <> '2026-01-01'
           OR end_date <> '2026-12-31'
           OR status <> 'ACTIVE');

    DECLARE @admin_id bigint = (
        SELECT user_id FROM dbo.users WHERE email = 'admin@gmail.com'
    );
    DECLARE @mentor_id bigint = (
        SELECT user_id FROM dbo.users WHERE email = 'mentor@gmail.com'
    );
    DECLARE @semester_id bigint = (
        SELECT semester_id FROM dbo.semesters WHERE code = 'DEMO-2026'
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.lab_usage_requests WHERE semester_id = @semester_id)
        INSERT dbo.lab_usage_requests
            (semester_id, mentor_id, group_name, status, approved_by, approved_at)
        VALUES
            (@semester_id, @mentor_id, N'Demo 2026 Intern List', 'APPROVED', @admin_id, @approval_at);

    DECLARE @request_id bigint = (
        SELECT request_id FROM dbo.lab_usage_requests WHERE semester_id = @semester_id
    );

    UPDATE dbo.lab_usage_requests
    SET mentor_id = @mentor_id,
        group_name = N'Demo 2026 Intern List',
        status = 'APPROVED',
        approved_by = @admin_id,
        approved_at = @approval_at,
        updated_at = SYSUTCDATETIME()
    WHERE request_id = @request_id
      AND (mentor_id <> @mentor_id
           OR group_name <> N'Demo 2026 Intern List'
           OR status <> 'APPROVED'
           OR approved_by IS NULL
           OR approved_by <> @admin_id
           OR approved_at IS NULL
           OR approved_at <> @approval_at);

    INSERT dbo.lab_usage_request_student_entries
        (request_id, semester_id, student_code, full_name, email, cohort)
    SELECT @request_id, @semester_id, i.student_code, i.full_name, i.email, i.cohort
    FROM @interns AS i
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.lab_usage_request_student_entries AS e
        WHERE e.request_id = @request_id
          AND e.student_code = i.student_code
    );

    UPDATE e
    SET full_name = i.full_name,
        email = i.email,
        cohort = i.cohort
    FROM dbo.lab_usage_request_student_entries AS e
    JOIN @interns AS i ON i.student_code = e.student_code
    WHERE e.request_id = @request_id
      AND (e.full_name <> i.full_name
           OR e.email <> i.email
           OR e.cohort <> i.cohort);

    INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
    SELECT @request_id, @semester_id, p.student_id
    FROM @interns AS i
    JOIN dbo.users AS u ON u.email = i.email
    JOIN dbo.student_profiles AS p ON p.user_id = u.user_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.lab_usage_request_students AS m
        WHERE m.request_id = @request_id
          AND m.student_id = p.student_id
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Demo Lab Equipment')
        INSERT dbo.asset_categories (category_name, description, status)
        VALUES (N'Demo Lab Equipment', N'Minimal assets for local workflow testing.', 'ACTIVE');

    UPDATE dbo.asset_categories
    SET description = N'Minimal assets for local workflow testing.',
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'Demo Lab Equipment'
      AND (description IS NULL
           OR description <> N'Minimal assets for local workflow testing.'
           OR status <> 'ACTIVE');

    DECLARE @category_id bigint = (
        SELECT category_id
        FROM dbo.asset_categories
        WHERE category_name = N'Demo Lab Equipment'
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'DEMO-ARDUINO-KIT')
        INSERT dbo.assets
            (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
             is_borrowable, storage_location, description)
        VALUES
            ('DEMO-ARDUINO-KIT', N'Arduino starter kit', @category_id, 'QUANTITY', 3, 'GOOD', 'AVAILABLE',
             1, N'Cabinet A1', N'Borrowable quantity asset.');

    IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'DEMO-MULTIMETER-001')
        INSERT dbo.assets
            (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
             is_borrowable, storage_location, description)
        VALUES
            ('DEMO-MULTIMETER-001', N'Digital multimeter', @category_id, 'SERIALIZED', 1, 'GOOD', 'AVAILABLE',
             1, N'Cabinet A2', N'Borrowable serialized asset.');

    IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'DEMO-OSC-001')
        INSERT dbo.assets
            (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
             is_borrowable, storage_location, description)
        VALUES
            ('DEMO-OSC-001', N'Bench oscilloscope', @category_id, 'SERIALIZED', 1, 'BROKEN', 'UNAVAILABLE',
             0, N'Repair shelf', N'Disposal-eligible serialized asset.');

    UPDATE dbo.assets
    SET asset_name = N'Arduino starter kit',
        category_id = @category_id,
        tracking_mode = 'QUANTITY',
        serial_number = NULL,
        total_quantity = 3,
        condition = 'GOOD',
        status = 'AVAILABLE',
        is_borrowable = 1,
        storage_location = N'Cabinet A1',
        description = N'Borrowable quantity asset.',
        updated_at = SYSUTCDATETIME()
    WHERE asset_code = 'DEMO-ARDUINO-KIT'
      AND (asset_name <> N'Arduino starter kit'
           OR category_id <> @category_id
           OR tracking_mode <> 'QUANTITY'
           OR serial_number IS NOT NULL
           OR total_quantity <> 3
           OR condition <> 'GOOD'
           OR status <> 'AVAILABLE'
           OR is_borrowable <> 1
           OR storage_location IS NULL
           OR storage_location <> N'Cabinet A1'
           OR description IS NULL
           OR description <> N'Borrowable quantity asset.');

    UPDATE dbo.assets
    SET asset_name = N'Digital multimeter',
        category_id = @category_id,
        tracking_mode = 'SERIALIZED',
        serial_number = NULL,
        total_quantity = 1,
        condition = 'GOOD',
        status = 'AVAILABLE',
        is_borrowable = 1,
        storage_location = N'Cabinet A2',
        description = N'Borrowable serialized asset.',
        updated_at = SYSUTCDATETIME()
    WHERE asset_code = 'DEMO-MULTIMETER-001'
      AND (asset_name <> N'Digital multimeter'
           OR category_id <> @category_id
           OR tracking_mode <> 'SERIALIZED'
           OR serial_number IS NOT NULL
           OR total_quantity <> 1
           OR condition <> 'GOOD'
           OR status <> 'AVAILABLE'
           OR is_borrowable <> 1
           OR storage_location IS NULL
           OR storage_location <> N'Cabinet A2'
           OR description IS NULL
           OR description <> N'Borrowable serialized asset.');

    UPDATE dbo.assets
    SET asset_name = N'Bench oscilloscope',
        category_id = @category_id,
        tracking_mode = 'SERIALIZED',
        serial_number = NULL,
        total_quantity = 1,
        condition = 'BROKEN',
        status = 'UNAVAILABLE',
        is_borrowable = 0,
        storage_location = N'Repair shelf',
        description = N'Disposal-eligible serialized asset.',
        updated_at = SYSUTCDATETIME()
    WHERE asset_code = 'DEMO-OSC-001'
      AND (asset_name <> N'Bench oscilloscope'
           OR category_id <> @category_id
           OR tracking_mode <> 'SERIALIZED'
           OR serial_number IS NOT NULL
           OR total_quantity <> 1
           OR condition <> 'BROKEN'
           OR status <> 'UNAVAILABLE'
           OR is_borrowable <> 0
           OR storage_location IS NULL
           OR storage_location <> N'Repair shelf'
           OR description IS NULL
           OR description <> N'Disposal-eligible serialized asset.');

    DECLARE @multimeter_id bigint = (
        SELECT asset_id FROM dbo.assets WHERE asset_code = 'DEMO-MULTIMETER-001'
    );
    DECLARE @oscilloscope_id bigint = (
        SELECT asset_id FROM dbo.assets WHERE asset_code = 'DEMO-OSC-001'
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_items WHERE item_code = 'DEMO-MULTIMETER-001-ITEM')
        INSERT dbo.asset_items
            (asset_id, item_code, serial_number, condition, status, is_borrowable, storage_location, note)
        VALUES
            (@multimeter_id, 'DEMO-MULTIMETER-001-ITEM', 'MM-DEMO-001', 'GOOD', 'AVAILABLE', 1,
             N'Cabinet A2', N'Borrowable serialized item.');

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_items WHERE item_code = 'DEMO-OSC-001-ITEM')
        INSERT dbo.asset_items
            (asset_id, item_code, serial_number, condition, status, is_borrowable, storage_location, note)
        VALUES
            (@oscilloscope_id, 'DEMO-OSC-001-ITEM', 'OSC-DEMO-001', 'BROKEN', 'UNAVAILABLE', 0,
             N'Repair shelf', N'Disposal-eligible serialized item.');

    UPDATE dbo.asset_items
    SET asset_id = @multimeter_id,
        serial_number = 'MM-DEMO-001',
        condition = 'GOOD',
        status = 'AVAILABLE',
        is_borrowable = 1,
        storage_location = N'Cabinet A2',
        note = N'Borrowable serialized item.',
        updated_at = SYSUTCDATETIME()
    WHERE item_code = 'DEMO-MULTIMETER-001-ITEM'
      AND (asset_id <> @multimeter_id
           OR serial_number <> 'MM-DEMO-001'
           OR condition <> 'GOOD'
           OR status <> 'AVAILABLE'
           OR is_borrowable <> 1
           OR storage_location IS NULL
           OR storage_location <> N'Cabinet A2'
           OR note IS NULL
           OR note <> N'Borrowable serialized item.');

    UPDATE dbo.asset_items
    SET asset_id = @oscilloscope_id,
        serial_number = 'OSC-DEMO-001',
        condition = 'BROKEN',
        status = 'UNAVAILABLE',
        is_borrowable = 0,
        storage_location = N'Repair shelf',
        note = N'Disposal-eligible serialized item.',
        updated_at = SYSUTCDATETIME()
    WHERE item_code = 'DEMO-OSC-001-ITEM'
      AND (asset_id <> @oscilloscope_id
           OR serial_number <> 'OSC-DEMO-001'
           OR condition <> 'BROKEN'
           OR status <> 'UNAVAILABLE'
           OR is_borrowable <> 0
           OR storage_location IS NULL
           OR storage_location <> N'Repair shelf'
           OR note IS NULL
           OR note <> N'Disposal-eligible serialized item.');

    /* Five physical laptops under one Asset master for Usage and Disposal demos. */
    IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'DEMO-ASUS-TUF-F15')
        INSERT dbo.assets
            (asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status,
             is_borrowable, storage_location, description)
        VALUES
            ('DEMO-ASUS-TUF-F15', N'Laptop ASUS TUF Gaming F15', @category_id, 'SERIALIZED', 4,
             'GOOD', 'AVAILABLE', 1, N'Laptop cabinet', N'Five tagged laptops; one has been disposed.');

    DECLARE @tuf_asset_id bigint = (
        SELECT asset_id FROM dbo.assets WHERE asset_code = 'DEMO-ASUS-TUF-F15'
    );

    UPDATE dbo.assets
    SET asset_name = N'Laptop ASUS TUF Gaming F15', category_id = @category_id,
        tracking_mode = 'SERIALIZED', serial_number = NULL, total_quantity = 4,
        condition = 'GOOD', status = 'AVAILABLE', is_borrowable = 1,
        storage_location = N'Laptop cabinet',
        description = N'Five tagged laptops; one has been disposed.', updated_at = SYSUTCDATETIME()
    WHERE asset_id = @tuf_asset_id;

    DECLARE @tuf_items TABLE (
        item_code varchar(70) PRIMARY KEY,
        serial_number varchar(100),
        condition varchar(10),
        status varchar(15),
        is_borrowable bit,
        note nvarchar(500)
    );
    INSERT @tuf_items VALUES
        ('TUF-001', 'ASUS-TUF-DEMO-001', 'GOOD',   'AVAILABLE',   1, N'Sẵn sàng cho mượn.'),
        ('TUF-002', 'ASUS-TUF-DEMO-002', 'GOOD',   'IN_USE',      1, N'Đang được thực tập sinh sử dụng.'),
        ('TUF-003', 'ASUS-TUF-DEMO-003', 'BROKEN', 'UNAVAILABLE', 0, N'Cháy bo mạch; đang chờ duyệt thanh lý.'),
        ('TUF-004', 'ASUS-TUF-DEMO-004', 'BROKEN', 'DISPOSED',    0, N'Đã hoàn tất thanh lý.'),
        ('TUF-005', 'ASUS-TUF-DEMO-005', 'GOOD',   'AVAILABLE',   1, N'Đã trả trong tình trạng tốt.');

    INSERT dbo.asset_items
        (asset_id, item_code, serial_number, condition, status, is_borrowable, storage_location,
         purchase_date, warranty_until, note)
    SELECT @tuf_asset_id, i.item_code, i.serial_number, i.condition, i.status, i.is_borrowable,
           N'Laptop cabinet', '2026-01-15', '2028-01-15', i.note
    FROM @tuf_items AS i
    WHERE NOT EXISTS (SELECT 1 FROM dbo.asset_items ai WHERE ai.item_code = i.item_code);

    UPDATE ai
    SET asset_id = @tuf_asset_id, serial_number = i.serial_number, condition = i.condition,
        status = i.status, is_borrowable = i.is_borrowable, storage_location = N'Laptop cabinet',
        purchase_date = '2026-01-15', warranty_until = '2028-01-15', note = i.note,
        updated_at = SYSUTCDATETIME()
    FROM dbo.asset_items ai
    JOIN @tuf_items i ON i.item_code = ai.item_code;

    DECLARE @intern_1_user_id bigint = (SELECT user_id FROM dbo.users WHERE email = 'anhnmhe171286@fpt.edu.vn');
    DECLARE @intern_2_user_id bigint = (SELECT user_id FROM dbo.users WHERE email = 'trungndhe180362@fpt.edu.vn');
    DECLARE @intern_3_user_id bigint = (SELECT user_id FROM dbo.users WHERE email = 'ductmhe180875@fpt.edu.vn');
    DECLARE @intern_1_id bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id = @intern_1_user_id);
    DECLARE @intern_2_id bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id = @intern_2_user_id);
    DECLARE @intern_3_id bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id = @intern_3_user_id);
    DECLARE @tuf_002_id bigint = (SELECT asset_item_id FROM dbo.asset_items WHERE item_code = 'TUF-002');
    DECLARE @tuf_003_id bigint = (SELECT asset_item_id FROM dbo.asset_items WHERE item_code = 'TUF-003');
    DECLARE @tuf_004_id bigint = (SELECT asset_item_id FROM dbo.asset_items WHERE item_code = 'TUF-004');
    DECLARE @tuf_005_id bigint = (SELECT asset_item_id FROM dbo.asset_items WHERE item_code = 'TUF-005');
    DECLARE @manager_id bigint = (SELECT user_id FROM dbo.users WHERE email = 'manager@gmail.com');

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_usages WHERE asset_item_id = @tuf_002_id AND note = N'DEMO:TUF-002-IN-USE')
        INSERT dbo.asset_usages
            (request_id, semester_id, intern_id, asset_id, asset_item_id, quantity, borrowed_at, due_at,
             condition_before, status, note, created_by)
        VALUES
            (@request_id, @semester_id, @intern_1_id, @tuf_asset_id, @tuf_002_id, 1,
             '2026-08-18T08:00:00', '2026-08-28T17:00:00', 'GOOD', 'IN_USE', N'DEMO:TUF-002-IN-USE', @intern_1_user_id);

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_usages WHERE asset_item_id = @tuf_003_id AND note = N'DEMO:TUF-003-RETURNED-BROKEN')
        INSERT dbo.asset_usages
            (request_id, semester_id, intern_id, asset_id, asset_item_id, quantity, borrowed_at, due_at,
             returned_at, condition_before, condition_after, status, note, return_note, created_by)
        VALUES
            (@request_id, @semester_id, @intern_2_id, @tuf_asset_id, @tuf_003_id, 1,
             '2026-08-05T08:00:00', '2026-08-12T17:00:00', '2026-08-12T15:30:00',
             'GOOD', 'BROKEN', 'RETURNED', N'DEMO:TUF-003-RETURNED-BROKEN', N'Máy không khởi động; nghi cháy bo mạch.', @intern_2_user_id);

    IF NOT EXISTS (SELECT 1 FROM dbo.asset_usages WHERE asset_item_id = @tuf_005_id AND note = N'DEMO:TUF-005-RETURNED-GOOD')
        INSERT dbo.asset_usages
            (request_id, semester_id, intern_id, asset_id, asset_item_id, quantity, borrowed_at, due_at,
             returned_at, condition_before, condition_after, status, note, return_note, created_by)
        VALUES
            (@request_id, @semester_id, @intern_3_id, @tuf_asset_id, @tuf_005_id, 1,
             '2026-08-01T08:00:00', '2026-08-08T17:00:00', '2026-08-08T16:00:00',
             'GOOD', 'GOOD', 'RETURNED', N'DEMO:TUF-005-RETURNED-GOOD', N'Đã kiểm tra, máy hoạt động bình thường.', @intern_3_user_id);

    UPDATE dbo.disposal_records
    SET reason = N'Không thể sửa chữa do cháy bo mạch.', updated_at = SYSUTCDATETIME()
    WHERE asset_item_id = @tuf_003_id AND reason = N'DEMO:TUF-003-PENDING-DISPOSAL';

    IF NOT EXISTS (SELECT 1 FROM dbo.disposal_records WHERE asset_item_id = @tuf_003_id AND status IN ('PENDING', 'APPROVED'))
        INSERT dbo.disposal_records
            (asset_id, asset_item_id, quantity, requested_by, reason, requested_at, status)
        VALUES
            (@tuf_asset_id, @tuf_003_id, 1, @mentor_id, N'Không thể sửa chữa do cháy bo mạch.',
             '2026-08-15T09:00:00', 'PENDING');

    UPDATE dbo.disposal_records
    SET reason = N'Chi phí sửa chữa vượt giá trị thay thế.', updated_at = SYSUTCDATETIME()
    WHERE asset_item_id = @tuf_004_id AND reason = N'DEMO:TUF-004-COMPLETED-DISPOSAL';

    IF NOT EXISTS (SELECT 1 FROM dbo.disposal_records WHERE asset_item_id = @tuf_004_id AND status = 'COMPLETED')
        INSERT dbo.disposal_records
            (asset_id, asset_item_id, quantity, requested_by, reason, requested_at, status,
             approved_by, approved_at, approval_note, completed_at, completion_note)
        VALUES
            (@tuf_asset_id, @tuf_004_id, 1, @mentor_id, N'Chi phí sửa chữa vượt giá trị thay thế.',
             '2026-07-10T09:00:00', 'COMPLETED', @manager_id, '2026-07-11T10:00:00',
             N'Đồng ý thanh lý thiết bị không thể sửa chữa.', '2026-07-15T14:00:00', N'Đã bàn giao đơn vị thu gom thiết bị điện tử.');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
