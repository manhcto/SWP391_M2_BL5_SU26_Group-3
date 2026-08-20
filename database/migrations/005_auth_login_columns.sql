/* Allows email/password login on an existing database before the full FE-04/FE-09 migration. */
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.users', N'U') IS NULL
        THROW 51031, 'Cannot apply authentication login columns: dbo.users is missing.', 1;

    IF COL_LENGTH(N'dbo.users', N'must_change_password') IS NULL
    BEGIN
        ALTER TABLE dbo.users
            ADD must_change_password bit NOT NULL
                CONSTRAINT DF_users_must_change_password DEFAULT (0) WITH VALUES;
    END;

    IF COL_LENGTH(N'dbo.users', N'password_expires_at') IS NULL
        ALTER TABLE dbo.users ADD password_expires_at datetime2(0) NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
