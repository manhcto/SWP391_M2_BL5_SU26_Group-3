/*
 * The application represents every physical product as an AssetItem.
 * A serialized Asset may therefore own one or more AssetItems.
 *
 * Older databases enforced total_quantity = 1 for SERIALIZED assets,
 * which caused /lab-manager/assets/new to fail whenever a Lab Manager
 * created multiple physical products in one submission.
 */
IF OBJECT_ID(N'dbo.assets', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_assets_quantity'
          AND parent_object_id = OBJECT_ID(N'dbo.assets')
    )
        ALTER TABLE dbo.assets DROP CONSTRAINT CK_assets_quantity;

    ALTER TABLE dbo.assets
        ADD CONSTRAINT CK_assets_quantity CHECK (total_quantity > 0);
END;
GO
