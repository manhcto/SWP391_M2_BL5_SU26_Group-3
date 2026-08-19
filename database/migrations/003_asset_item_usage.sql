/* Link each new borrowing record to the physical AssetItem it uses. */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.asset_usages', 'asset_item_id') IS NULL
BEGIN
    ALTER TABLE dbo.asset_usages ADD asset_item_id bigint NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_asset_usages_asset_item'
      AND parent_object_id = OBJECT_ID('dbo.asset_usages')
)
BEGIN
    ALTER TABLE dbo.asset_usages
        ADD CONSTRAINT FK_asset_usages_asset_item FOREIGN KEY (asset_item_id)
        REFERENCES dbo.asset_items(asset_item_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_asset_usages_asset_item'
      AND object_id = OBJECT_ID('dbo.asset_usages')
)
BEGIN
    CREATE INDEX IX_asset_usages_asset_item ON dbo.asset_usages (asset_item_id)
        WHERE asset_item_id IS NOT NULL;
END;

COMMIT TRANSACTION;
GO
