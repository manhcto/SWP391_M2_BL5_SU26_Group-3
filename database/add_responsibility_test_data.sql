USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'labmanager@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, role, status)
        VALUES (
            N'Demo Lab Manager Test',
            'labmanager@gmail.com',
            '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C',
            'LAB_MANAGER',
            'ACTIVE'
        );

    IF NOT EXISTS (
        SELECT 1 FROM dbo.incidents
        WHERE description = N'[TEST] Incident awaiting responsibility determination.'
    )
    BEGIN
        DECLARE @asset_id bigint;
        DECLARE @usage_id bigint;
        DECLARE @reporter_id bigint;
        DECLARE @request_id bigint;
        DECLARE @semester_id bigint;
        DECLARE @student_id bigint;

        SELECT TOP (1)
            @asset_id = au.asset_id,
            @usage_id = au.asset_usage_id,
            @reporter_id = sp.user_id
        FROM dbo.asset_usages AS au
        JOIN dbo.student_profiles AS sp ON sp.student_id = au.student_id
        WHERE au.status = 'RETURNED'
        ORDER BY au.asset_usage_id DESC;

        IF @usage_id IS NULL
        BEGIN
            SELECT TOP (1)
                @request_id = rs.request_id,
                @semester_id = rs.semester_id,
                @student_id = rs.student_id,
                @reporter_id = sp.user_id
            FROM dbo.lab_usage_request_students AS rs
            JOIN dbo.student_profiles AS sp ON sp.student_id = rs.student_id
            ORDER BY rs.request_id DESC;

            SELECT TOP (1) @asset_id = asset_id
            FROM dbo.assets
            WHERE status <> 'DISPOSED'
            ORDER BY asset_id DESC;

            IF @request_id IS NULL OR @asset_id IS NULL
                THROW 50001, 'An intern request membership and asset are required.', 1;

            INSERT dbo.asset_usages
                (request_id, semester_id, student_id, asset_id, quantity, borrowed_at, due_at,
                 returned_at, condition_before, condition_after, status, note, created_by)
            VALUES
                (@request_id, @semester_id, @student_id, @asset_id, 1,
                 DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -1, SYSUTCDATETIME()),
                 DATEADD(MINUTE, -30, SYSUTCDATETIME()), 'GOOD', 'DAMAGED', 'RETURNED',
                 N'[TEST] Returned usage for responsibility testing.', @reporter_id);

            SET @usage_id = SCOPE_IDENTITY();
        END;

        INSERT dbo.incidents
            (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type,
             description, severity, status, occurred_at, reported_at, investigation_note)
        VALUES
            (@asset_id, @usage_id, @reporter_id, 1, 'DAMAGE',
             N'[TEST] Incident awaiting responsibility determination.',
             'MEDIUM', 'INVESTIGATING', DATEADD(MINUTE, -45, SYSUTCDATETIME()),
             SYSUTCDATETIME(), N'Ready for Mentor responsibility testing.');
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
