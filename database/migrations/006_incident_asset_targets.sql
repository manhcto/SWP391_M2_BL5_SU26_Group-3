/* Allow an incident to target a specific asset item without an active usage. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.incidents', N'U') IS NULL OR OBJECT_ID(N'dbo.asset_items', N'U') IS NULL
        THROW 51041, 'Cannot apply incident targets: required tables are missing.', 1;

    IF COL_LENGTH(N'dbo.incidents', N'asset_item_id') IS NULL
        ALTER TABLE dbo.incidents ADD asset_item_id bigint NULL;

    IF COL_LENGTH(N'dbo.incidents', N'reported_cause') IS NULL
        ALTER TABLE dbo.incidents ADD reported_cause varchar(15) NOT NULL
            CONSTRAINT DF_incidents_reported_cause DEFAULT ('UNKNOWN') WITH VALUES;

    IF COL_LENGTH(N'dbo.incidents', N'determined_cause') IS NULL
        ALTER TABLE dbo.incidents ADD determined_cause varchar(15) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_incidents_asset_item')
        EXEC(N'ALTER TABLE dbo.incidents WITH CHECK
               ADD CONSTRAINT FK_incidents_asset_item FOREIGN KEY (asset_item_id)
               REFERENCES dbo.asset_items(asset_item_id);');

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_incidents_reported_cause')
        EXEC(N'ALTER TABLE dbo.incidents ADD CONSTRAINT CK_incidents_reported_cause
               CHECK (reported_cause IN (''INTERN'', ''NATURAL'', ''UNKNOWN''));');

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_incidents_determined_cause')
        EXEC(N'ALTER TABLE dbo.incidents ADD CONSTRAINT CK_incidents_determined_cause
               CHECK (determined_cause IS NULL OR determined_cause IN (''INTERN'', ''NATURAL'', ''UNKNOWN''));');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.incidents') AND name = N'IX_incidents_asset_item')
        EXEC(N'CREATE INDEX IX_incidents_asset_item ON dbo.incidents(asset_item_id) WHERE asset_item_id IS NOT NULL;');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
