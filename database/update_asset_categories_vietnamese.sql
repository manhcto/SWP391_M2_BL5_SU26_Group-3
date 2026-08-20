/* Translate asset categories and remove unwanted categories and their demo data. */
USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE dbo.asset_categories
    SET category_name = N'Thiết bị phòng LAB',
        description = N'Thiết bị dùng chung trong phòng LAB.',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'General Lab Equipment';

    UPDATE dbo.asset_categories
    SET category_name = N'Thiết bị IoT',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'IoT Device';

    UPDATE dbo.asset_categories
    SET category_name = N'Thiết bị điện tử',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'Electronics';

    UPDATE dbo.asset_categories
    SET category_name = N'Dụng cụ',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'Tools';

    UPDATE dbo.asset_categories
    SET category_name = N'Cơ sở vật chất',
        updated_at = SYSUTCDATETIME()
    WHERE category_name = N'Facilities';

    DECLARE @facilitiesCategoryId bigint;
    SELECT @facilitiesCategoryId = category_id
    FROM dbo.asset_categories
    WHERE category_name = N'Cơ sở vật chất';

    IF @facilitiesCategoryId IS NOT NULL
    BEGIN
        DELETE r
        FROM dbo.responsibilities r
        JOIN dbo.incidents i ON i.incident_id = r.incident_id
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE d
        FROM dbo.disposal_records d
        JOIN dbo.assets a ON a.asset_id = d.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE m
        FROM dbo.maintenance_records m
        JOIN dbo.assets a ON a.asset_id = m.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE i
        FROM dbo.incidents i
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE u
        FROM dbo.asset_usages u
        JOIN dbo.assets a ON a.asset_id = u.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE i
        FROM dbo.inspection_items i
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE i
        FROM dbo.asset_items i
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.category_id = @facilitiesCategoryId;

        DELETE FROM dbo.assets
        WHERE category_id = @facilitiesCategoryId;

        DELETE FROM dbo.asset_categories
        WHERE category_id = @facilitiesCategoryId;
    END;

    DECLARE @fixedCategoryId bigint;
    SELECT @fixedCategoryId = category_id
    FROM dbo.asset_categories
    WHERE category_name = N'Tài sản cố định';

    IF @fixedCategoryId IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.assets a
            WHERE a.category_id = @fixedCategoryId
              AND a.asset_code NOT LIKE 'FIXED-%'
        )
            THROW 51010, 'Category Tài sản cố định contains non-demo assets. Review them before deleting the category.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.assets a
            WHERE a.category_id = @fixedCategoryId
              AND (
                    EXISTS (SELECT 1 FROM dbo.asset_usages u WHERE u.asset_id = a.asset_id)
                 OR EXISTS (SELECT 1 FROM dbo.inspection_items i WHERE i.asset_id = a.asset_id)
                 OR EXISTS (SELECT 1 FROM dbo.incidents i WHERE i.asset_id = a.asset_id)
                 OR EXISTS (SELECT 1 FROM dbo.maintenance_records m WHERE m.asset_id = a.asset_id)
                 OR EXISTS (SELECT 1 FROM dbo.disposal_records d WHERE d.asset_id = a.asset_id)
              )
        )
            THROW 51011, 'Fixed assets have history and cannot be deleted automatically.', 1;

        DELETE i
        FROM dbo.asset_items i
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.category_id = @fixedCategoryId;

        DELETE FROM dbo.assets
        WHERE category_id = @fixedCategoryId;

        DELETE FROM dbo.asset_categories
        WHERE category_id = @fixedCategoryId;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT category_id, category_name, status
FROM dbo.asset_categories
ORDER BY category_id;
GO
