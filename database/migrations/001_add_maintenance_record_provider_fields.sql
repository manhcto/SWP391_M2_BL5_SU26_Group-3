USE lab_asset_management;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.maintenance_records', 'provider_phone') IS NULL
    ALTER TABLE dbo.maintenance_records ADD provider_phone varchar(30) NULL;

IF COL_LENGTH('dbo.maintenance_records', 'provider_address') IS NULL
    ALTER TABLE dbo.maintenance_records ADD provider_address nvarchar(255) NULL;

IF COL_LENGTH('dbo.maintenance_records', 'image_url') IS NULL
    ALTER TABLE dbo.maintenance_records ADD image_url nvarchar(1000) NULL;

COMMIT TRANSACTION;
GO
