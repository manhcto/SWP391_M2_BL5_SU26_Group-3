/* Local/demo data only. Run after schema.sql. Safe to run repeatedly. */
USE [lab_asset_management];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'student.test@fpt.edu.vn')
    INSERT dbo.users(full_name, email, role, status) VALUES (N'Test Student', 'student.test@fpt.edu.vn', 'STUDENT', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'mentor.test@fpt.edu.vn')
    INSERT dbo.users(full_name, email, role, status) VALUES (N'Test Mentor', 'mentor.test@fpt.edu.vn', 'MENTOR', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'manager.test@fpt.edu.vn')
    INSERT dbo.users(full_name, email, role, status) VALUES (N'Test Lab Manager', 'manager.test@fpt.edu.vn', 'LAB_MANAGER', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'admin.test@fpt.edu.vn')
    INSERT dbo.users(full_name, email, role, status) VALUES (N'Test Admin', 'admin.test@fpt.edu.vn', 'ADMIN', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'minhlahe180101@fpt.edu.vn')
    INSERT dbo.users(full_name, email, role, status) VALUES (N'Minh La', 'minhlahe180101@fpt.edu.vn', 'STUDENT', 'ACTIVE');

DECLARE @studentUser bigint = (SELECT user_id FROM dbo.users WHERE email = 'student.test@fpt.edu.vn');
IF NOT EXISTS (SELECT 1 FROM dbo.student_profiles WHERE user_id = @studentUser)
    INSERT dbo.student_profiles(user_id, student_code, status) VALUES (@studentUser, 'TEST001', 'ACTIVE');

DECLARE @demoStudentUser bigint = (SELECT user_id FROM dbo.users WHERE email = 'minhlahe180101@fpt.edu.vn');
IF NOT EXISTS (SELECT 1 FROM dbo.student_profiles WHERE user_id = @demoStudentUser)
    INSERT dbo.student_profiles(user_id, student_code, status) VALUES (@demoStudentUser, 'HE180101', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Test equipment')
    INSERT dbo.asset_categories(category_name, status) VALUES (N'Test equipment', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'TEST-ASSET-01')
    INSERT dbo.assets(asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status, is_borrowable)
    VALUES ('TEST-ASSET-01', N'Test multimeter', (SELECT category_id FROM dbo.asset_categories WHERE category_name = N'Test equipment'), 'QUANTITY', 2, 'GOOD', 'AVAILABLE', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.assets WHERE asset_code = 'TEST-ASSET-02')
    INSERT dbo.assets(asset_code, asset_name, category_id, tracking_mode, total_quantity, condition, status, is_borrowable)
    VALUES ('TEST-ASSET-02', N'Test retired oscilloscope', (SELECT category_id FROM dbo.asset_categories WHERE category_name = N'Test equipment'), 'SERIALIZED', 1, 'BROKEN', 'UNAVAILABLE', 0);

IF NOT EXISTS (SELECT 1 FROM dbo.semesters WHERE code = 'LOCAL-TEST')
    INSERT dbo.semesters(code, name, start_date, end_date, status)
    VALUES ('LOCAL-TEST', N'Local browser test', CAST(GETDATE() AS date), DATEADD(day, 7, CAST(GETDATE() AS date)), 'ACTIVE');

DECLARE @semester bigint = (SELECT semester_id FROM dbo.semesters WHERE code = 'LOCAL-TEST');
DECLARE @mentor bigint = (SELECT user_id FROM dbo.users WHERE email = 'mentor.test@fpt.edu.vn');
DECLARE @manager bigint = (SELECT user_id FROM dbo.users WHERE email = 'manager.test@fpt.edu.vn');
DECLARE @student bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id = @studentUser);
DECLARE @demoStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id = @demoStudentUser);
IF NOT EXISTS (SELECT 1 FROM dbo.lab_usage_requests WHERE semester_id = @semester AND mentor_id = @mentor)
    INSERT dbo.lab_usage_requests(semester_id, mentor_id, status, approved_by, approved_at, group_name)
    VALUES (@semester, @mentor, 'APPROVED', @manager, SYSUTCDATETIME(), N'Local test group');

DECLARE @request bigint = (SELECT request_id FROM dbo.lab_usage_requests WHERE semester_id = @semester AND mentor_id = @mentor);
IF NOT EXISTS (SELECT 1 FROM dbo.lab_usage_request_students WHERE request_id = @request AND student_id = @student)
    INSERT dbo.lab_usage_request_students(request_id, semester_id, student_id) VALUES (@request, @semester, @student);
IF NOT EXISTS (SELECT 1 FROM dbo.lab_usage_request_students WHERE request_id = @request AND student_id = @demoStudent)
    INSERT dbo.lab_usage_request_students(request_id, semester_id, student_id) VALUES (@request, @semester, @demoStudent);

-- Browser tests can run at any local time; production requests still use assigned slots only.
DECLARE @day tinyint = DATEPART(weekday, GETDATE());
DECLARE @slot tinyint = (SELECT TOP 1 slot_id FROM dbo.lab_time_slots WHERE CAST(GETDATE() AS time) >= start_time AND CAST(GETDATE() AS time) < end_time);
IF @day BETWEEN 2 AND 7 AND @slot IS NOT NULL AND NOT EXISTS
    (SELECT 1 FROM dbo.lab_usage_request_slots WHERE request_id = @request AND day_of_week = @day AND slot_id = @slot)
    INSERT dbo.lab_usage_request_slots(request_id, day_of_week, slot_id) VALUES (@request, @day, @slot);
GO
