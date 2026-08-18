USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @asset_id bigint;
    DECLARE @usage_id bigint;
    DECLARE @reporter_id bigint;
    DECLARE @now datetime2(0) = SYSUTCDATETIME();

    SELECT TOP (1)
        @asset_id = au.asset_id,
        @usage_id = au.asset_usage_id,
        @reporter_id = sp.user_id
    FROM dbo.asset_usages AS au
    JOIN dbo.student_profiles AS sp ON sp.student_id = au.student_id
    ORDER BY au.asset_usage_id DESC;

    IF @asset_id IS NULL
        SELECT TOP (1) @asset_id = asset_id
        FROM dbo.assets
        WHERE status <> 'DISPOSED'
        ORDER BY asset_id DESC;

    IF @reporter_id IS NULL
        SELECT TOP (1) @reporter_id = user_id
        FROM dbo.users
        WHERE status = 'ACTIVE'
        ORDER BY CASE role WHEN 'INTERN' THEN 0 ELSE 1 END, user_id;

    IF @asset_id IS NULL OR @reporter_id IS NULL
        THROW 50002, 'At least one active user and one non-disposed asset are required.', 1;

    INSERT dbo.incidents
        (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
         status, occurred_at, reported_at, investigation_note, handling_result)
    SELECT
        @asset_id, @usage_id, @reporter_id, 1, sample.incident_type, sample.description,
        sample.severity, sample.status, sample.occurred_at, sample.reported_at,
        sample.investigation_note, sample.handling_result
    FROM (VALUES
        ('MISSING', N'[SAMPLE] The equipment carrying case was not returned.', 'MEDIUM', 'OPEN',
         DATEADD(DAY, -5, @now), DATEADD(MINUTE, 30, DATEADD(DAY, -5, @now)),
         N'The return checklist is being reviewed.', CAST(NULL AS nvarchar(max))),
        ('OTHER', N'[SAMPLE] The calibration label became unreadable.', 'LOW', 'CLOSED',
         DATEADD(DAY, -4, @now), DATEADD(MINUTE, 45, DATEADD(DAY, -4, @now)),
         N'The calibration record was verified.', N'A replacement label was applied.'),
        ('MALFUNCTION', N'[SAMPLE] The display intermittently showed incomplete readings.', 'MEDIUM', 'INVESTIGATING',
         DATEADD(DAY, -3, @now), DATEADD(MINUTE, 20, DATEADD(DAY, -3, @now)),
         N'The battery and display connector require inspection.', NULL),
        ('DAMAGE', N'[SAMPLE] The protective cover was torn near the input terminals.', 'LOW', 'RESOLVED',
         DATEADD(DAY, -2, @now), DATEADD(MINUTE, 15, DATEADD(DAY, -2, @now)),
         N'The damage did not affect operational safety.', N'The protective cover was replaced.'),
        ('LOSS', N'[SAMPLE] The spare accessory set could not be located.', 'HIGH', 'OPEN',
         DATEADD(DAY, -1, @now), DATEADD(MINUTE, 30, DATEADD(DAY, -1, @now)),
         N'Inventory and recent usage records are being reviewed.', NULL)
    ) AS sample
        (incident_type, description, severity, status, occurred_at, reported_at,
         investigation_note, handling_result)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.incidents AS existing
        WHERE existing.description = sample.description
    );

    SELECT @@ROWCOUNT AS incidents_added;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
