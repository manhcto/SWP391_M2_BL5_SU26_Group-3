/* A reported incident takes its linked usage out of active use immediately. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.asset_usages', N'U') IS NULL OR OBJECT_ID(N'dbo.incidents', N'U') IS NULL
        THROW 51042, 'Cannot apply incident maintenance status: required tables are missing.', 1;

    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.asset_usages') AND name = N'CK_asset_usages_return')
        ALTER TABLE dbo.asset_usages DROP CONSTRAINT CK_asset_usages_return;
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.asset_usages') AND name = N'CK_asset_usages_status')
        ALTER TABLE dbo.asset_usages DROP CONSTRAINT CK_asset_usages_status;

    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.asset_usages') AND name = N'UX_asset_usages_active_asset_item')
        DROP INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.asset_usages') AND name = N'IX_asset_usages_asset_status')
        DROP INDEX IX_asset_usages_asset_status ON dbo.asset_usages;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.asset_usages') AND name = N'IX_asset_usages_student_status')
        DROP INDEX IX_asset_usages_student_status ON dbo.asset_usages;

    ALTER TABLE dbo.asset_usages ALTER COLUMN status varchar(20) NOT NULL;
    ALTER TABLE dbo.asset_usages ADD CONSTRAINT CK_asset_usages_status
        CHECK (status IN ('IN_USE', 'MAINTENANCE', 'RETURNED'));
    ALTER TABLE dbo.asset_usages ADD CONSTRAINT CK_asset_usages_return
        CHECK ((status IN ('IN_USE', 'MAINTENANCE') AND returned_at IS NULL)
            OR (status = 'RETURNED' AND returned_at IS NOT NULL AND condition_after IS NOT NULL));

    CREATE UNIQUE INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages(asset_item_id)
        WHERE asset_item_id IS NOT NULL AND status IN ('IN_USE', 'MAINTENANCE');
    CREATE INDEX IX_asset_usages_asset_status ON dbo.asset_usages(asset_id, status);
    CREATE INDEX IX_asset_usages_student_status ON dbo.asset_usages(student_id, status);

    UPDATE usage SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
    FROM dbo.asset_usages usage
    WHERE usage.status = 'IN_USE' AND EXISTS (
        SELECT 1 FROM dbo.incidents incident
        WHERE incident.asset_usage_id = usage.asset_usage_id
          AND incident.status IN ('OPEN', 'INVESTIGATING')
    );

    IF OBJECT_ID(N'dbo.asset_items', N'U') IS NOT NULL
        UPDATE item SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
        FROM dbo.asset_items item
        JOIN dbo.incidents incident ON incident.asset_item_id = item.asset_item_id
        WHERE item.status <> 'DISPOSED' AND incident.status IN ('OPEN', 'INVESTIGATING');

    UPDATE asset SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
    FROM dbo.assets asset
    JOIN dbo.incidents incident ON incident.asset_id = asset.asset_id
    WHERE incident.asset_item_id IS NULL AND asset.status <> 'DISPOSED'
      AND incident.status IN ('OPEN', 'INVESTIGATING');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
