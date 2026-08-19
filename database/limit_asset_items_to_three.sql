/* Keep at most three physical items for each quantity-tracked asset. */
USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.asset_usages', 'asset_item_id') IS NOT NULL
    BEGIN
        DECLARE @historyCheck nvarchar(max) = N'
            IF EXISTS (
                SELECT 1
                FROM (
                    SELECT
                        i.asset_item_id,
                        ROW_NUMBER() OVER (
                            PARTITION BY i.asset_id
                            ORDER BY i.asset_item_id
                        ) AS item_number
                    FROM dbo.asset_items i
                    JOIN dbo.assets a ON a.asset_id = i.asset_id
                    WHERE a.tracking_mode = ''QUANTITY''
                ) r
                JOIN dbo.asset_usages u ON u.asset_item_id = r.asset_item_id
                WHERE r.item_number > 3
            )
                THROW 51020, ''Some items beyond the first three have borrowing history. Review them before deleting.'', 1;';

        EXEC sys.sp_executesql @historyCheck;
    END;

    ;WITH RankedItems AS (
        SELECT
            i.asset_item_id,
            ROW_NUMBER() OVER (
                PARTITION BY i.asset_id
                ORDER BY i.asset_item_id
            ) AS item_number
        FROM dbo.asset_items i
        JOIN dbo.assets a ON a.asset_id = i.asset_id
        WHERE a.tracking_mode = 'QUANTITY'
    )
    DELETE i
    FROM dbo.asset_items i
    JOIN RankedItems r ON r.asset_item_id = i.asset_item_id
    WHERE r.item_number > 3;

    UPDATE dbo.assets
    SET total_quantity = 3,
        updated_at = SYSUTCDATETIME()
    WHERE tracking_mode = 'QUANTITY'
      AND total_quantity > 3;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT
    a.asset_id,
    a.asset_code,
    a.total_quantity,
    COUNT(i.asset_item_id) AS item_count
FROM dbo.assets a
LEFT JOIN dbo.asset_items i ON i.asset_id = a.asset_id
WHERE a.tracking_mode = 'QUANTITY'
GROUP BY a.asset_id, a.asset_code, a.total_quantity
ORDER BY a.asset_id;
GO
