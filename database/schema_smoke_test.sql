/* Run after schema.sql. This test rolls back all sample data. */
USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @token varchar(36) = CONVERT(varchar(36), NEWID());
    DECLARE @manager_id bigint;
    DECLARE @mentor_id bigint;
    DECLARE @student_user_id bigint;
    DECLARE @student_id bigint;
    DECLARE @semester_id bigint;
    DECLARE @request_id bigint;
    DECLARE @category_id bigint;
    DECLARE @asset_id bigint;
    DECLARE @asset_usage_id bigint;
    DECLARE @incident_id bigint;

    INSERT dbo.users (full_name, email, password_hash, role)
    VALUES (N'LAB Manager', CONCAT('manager-', @token, '@example.test'), 'test-only', 'LAB_MANAGER');
    SET @manager_id = SCOPE_IDENTITY();

    INSERT dbo.users (full_name, email, password_hash, role)
    VALUES (N'Mentor', CONCAT('mentor-', @token, '@example.test'), 'test-only', 'MENTOR');
    SET @mentor_id = SCOPE_IDENTITY();

    INSERT dbo.users (full_name, email, google_subject, role)
    VALUES (N'Student', CONCAT(@token, '@fpt.edu.vn'), @token, 'STUDENT');
    SET @student_user_id = SCOPE_IDENTITY();

    INSERT dbo.student_profiles (user_id, student_code)
    VALUES (@student_user_id, CONCAT('SE-', LEFT(@token, 20)));
    SET @student_id = SCOPE_IDENTITY();

    INSERT dbo.semesters (code, name, start_date, end_date, status)
    VALUES (CONCAT('SEM-', LEFT(@token, 16)), N'Smoke test semester', '2026-01-01', '2026-04-30', 'ACTIVE');
    SET @semester_id = SCOPE_IDENTITY();

    INSERT dbo.lab_usage_requests
        (semester_id, mentor_id, status, approved_by, approved_at)
    VALUES
        (@semester_id, @mentor_id, 'APPROVED', @manager_id, SYSUTCDATETIME());
    SET @request_id = SCOPE_IDENTITY();

    INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
    VALUES (@request_id, @semester_id, @student_id);

    INSERT dbo.asset_categories (category_name)
    VALUES (CONCAT(N'IoT-', @token));
    SET @category_id = SCOPE_IDENTITY();

    INSERT dbo.assets
        (asset_code, asset_name, category_id, tracking_mode,
         total_quantity, condition, is_borrowable)
    VALUES
        (CONCAT('ASSET-', LEFT(@token, 16)), N'IoT test device', @category_id,
         'QUANTITY', 5, 'GOOD', 1);
    SET @asset_id = SCOPE_IDENTITY();

    INSERT dbo.asset_usages
        (request_id, semester_id, student_id, asset_id, quantity,
         due_at, condition_before, created_by)
    VALUES
        (@request_id, @semester_id, @student_id, @asset_id, 2,
         DATEADD(hour, 2, SYSUTCDATETIME()), 'GOOD', @student_user_id);
    SET @asset_usage_id = SCOPE_IDENTITY();

    INSERT dbo.incidents
        (asset_id, asset_usage_id, reported_by, incident_type, description, severity, status)
    VALUES
        (@asset_id, @asset_usage_id, @mentor_id, 'MISSING', N'Test incident', 'HIGH', 'INVESTIGATING');
    SET @incident_id = SCOPE_IDENTITY();

    INSERT dbo.responsibilities
        (incident_id, student_id, determined_by, conclusion, status)
    VALUES
        (@incident_id, @student_id, @mentor_id, N'Test conclusion', 'PENDING_REVIEW');

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.responsibilities r
        JOIN dbo.incidents i ON i.incident_id = r.incident_id
        JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
        WHERE r.incident_id = @incident_id
          AND r.student_id = au.student_id
          AND i.asset_id = @asset_id
          AND au.semester_id = @semester_id
          AND au.quantity = 2
    )
        THROW 51000, 'Core asset-to-student traceability check failed.', 1;

    PRINT 'Schema smoke test passed.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
