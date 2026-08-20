/* FE-04, FE-09, and authentication schema prerequisites. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.users', N'U') IS NULL
       OR OBJECT_ID(N'dbo.asset_items', N'U') IS NULL
       OR OBJECT_ID(N'dbo.asset_usages', N'U') IS NULL
       OR OBJECT_ID(N'dbo.disposal_records', N'U') IS NULL
    BEGIN
        ;THROW 51030, 'Cannot apply FE-04, FE-09, and authentication prerequisites: expected tables are missing.', 1;
    END;

    /* FE-04 kept the business term Intern while the shared schema renamed it Student. */
    IF OBJECT_ID(N'dbo.intern_profiles') IS NULL
       AND OBJECT_ID(N'dbo.student_profiles', N'U') IS NOT NULL
    BEGIN
        EXEC(N'CREATE VIEW dbo.intern_profiles AS
               SELECT student_id AS intern_id, user_id, student_code AS intern_code,
                      major, cohort, status, created_at, updated_at
               FROM dbo.student_profiles');
    END;

    IF OBJECT_ID(N'dbo.lab_usage_request_interns') IS NULL
       AND OBJECT_ID(N'dbo.lab_usage_request_students', N'U') IS NOT NULL
    BEGIN
        EXEC(N'CREATE VIEW dbo.lab_usage_request_interns AS
               SELECT request_id, semester_id, student_id AS intern_id, added_at
               FROM dbo.lab_usage_request_students');
    END;

    IF COL_LENGTH(N'dbo.users', N'must_change_password') IS NULL
    BEGIN
        ALTER TABLE dbo.users
            ADD must_change_password bit NOT NULL
                CONSTRAINT DF_users_must_change_password DEFAULT (0) WITH VALUES;
    END;

    IF COL_LENGTH(N'dbo.users', N'password_expires_at') IS NULL
    BEGIN
        ALTER TABLE dbo.users ADD password_expires_at datetime2(0) NULL;
    END;

    IF OBJECT_ID(N'dbo.password_reset_requests', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.password_reset_requests (
            reset_request_id bigint IDENTITY(1,1) NOT NULL,
            target_user_id bigint NOT NULL,
            status varchar(10) NOT NULL CONSTRAINT DF_password_reset_requests_status DEFAULT ('PENDING'),
            request_note nvarchar(max) NULL,
            reviewed_by bigint NULL,
            reviewed_at datetime2(0) NULL,
            review_note nvarchar(max) NULL,
            issued_at datetime2(0) NULL,
            consumed_at datetime2(0) NULL,
            created_at datetime2(0) NOT NULL CONSTRAINT DF_password_reset_requests_created_at DEFAULT (SYSUTCDATETIME()),
            updated_at datetime2(0) NOT NULL CONSTRAINT DF_password_reset_requests_updated_at DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT PK_password_reset_requests PRIMARY KEY (reset_request_id),
            CONSTRAINT FK_password_reset_requests_target FOREIGN KEY (target_user_id) REFERENCES dbo.users(user_id),
            CONSTRAINT FK_password_reset_requests_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id),
            CONSTRAINT CK_password_reset_requests_status CHECK (
                status IN ('PENDING', 'APPROVED', 'REJECTED', 'ISSUED', 'CONSUMED')
            )
        );

    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.password_reset_requests')
          AND name = N'IX_password_reset_requests_target_status'
    )
    BEGIN
        CREATE INDEX IX_password_reset_requests_target_status
            ON dbo.password_reset_requests (target_user_id, status);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.password_reset_requests')
          AND name = N'UX_password_reset_requests_open_target'
    )
    BEGIN
        CREATE UNIQUE INDEX UX_password_reset_requests_open_target
            ON dbo.password_reset_requests (target_user_id)
            WHERE status IN ('PENDING', 'APPROVED', 'ISSUED');
    END;

    IF COL_LENGTH(N'dbo.asset_items', N'is_borrowable') IS NULL
    BEGIN
        ALTER TABLE dbo.asset_items
            ADD is_borrowable bit NOT NULL
                CONSTRAINT DF_asset_items_is_borrowable DEFAULT (1) WITH VALUES;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.asset_items')
          AND name = N'CK_asset_items_status'
          AND UPPER(definition) NOT LIKE N'%IN_USE%'
    )
    BEGIN
        ALTER TABLE dbo.asset_items DROP CONSTRAINT CK_asset_items_status;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.asset_items')
          AND name = N'CK_asset_items_status'
    )
    BEGIN
        ALTER TABLE dbo.asset_items WITH CHECK
            ADD CONSTRAINT CK_asset_items_status
            CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'UNAVAILABLE', 'DISPOSED'));
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.asset_items')
          AND name = N'UQ_asset_items_item_asset'
    )
    BEGIN
        ALTER TABLE dbo.asset_items
            ADD CONSTRAINT UQ_asset_items_item_asset UNIQUE (asset_item_id, asset_id);
    END;

    IF COL_LENGTH(N'dbo.asset_usages', N'asset_item_id') IS NULL
    BEGIN
        ALTER TABLE dbo.asset_usages ADD asset_item_id bigint NULL;
    END;

    IF COL_LENGTH(N'dbo.asset_usages', N'return_note') IS NULL
    BEGIN
        ALTER TABLE dbo.asset_usages ADD return_note nvarchar(max) NULL;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.asset_usages')
          AND name = N'FK_asset_usages_asset_item'
    )
    BEGIN
        ALTER TABLE dbo.asset_usages WITH CHECK
            ADD CONSTRAINT FK_asset_usages_asset_item FOREIGN KEY (asset_item_id)
                REFERENCES dbo.asset_items(asset_item_id);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.asset_usages')
          AND fk.referenced_object_id = OBJECT_ID(N'dbo.asset_items')
          AND 2 = (
              SELECT COUNT(*)
              FROM sys.foreign_key_columns fkc
              WHERE fkc.constraint_object_id = fk.object_id
          )
          AND EXISTS (
              SELECT 1
              FROM sys.foreign_key_columns fkc
              JOIN sys.columns parent_column
                ON parent_column.object_id = fkc.parent_object_id
               AND parent_column.column_id = fkc.parent_column_id
              JOIN sys.columns referenced_column
                ON referenced_column.object_id = fkc.referenced_object_id
               AND referenced_column.column_id = fkc.referenced_column_id
              WHERE fkc.constraint_object_id = fk.object_id
                AND parent_column.name = N'asset_item_id'
                AND referenced_column.name = N'asset_item_id'
          )
          AND EXISTS (
              SELECT 1
              FROM sys.foreign_key_columns fkc
              JOIN sys.columns parent_column
                ON parent_column.object_id = fkc.parent_object_id
               AND parent_column.column_id = fkc.parent_column_id
              JOIN sys.columns referenced_column
                ON referenced_column.object_id = fkc.referenced_object_id
               AND referenced_column.column_id = fkc.referenced_column_id
              WHERE fkc.constraint_object_id = fk.object_id
                AND parent_column.name = N'asset_id'
                AND referenced_column.name = N'asset_id'
          )
    )
    BEGIN
        ALTER TABLE dbo.asset_usages WITH CHECK
            ADD CONSTRAINT FK_asset_usages_asset_item_asset FOREIGN KEY (asset_item_id, asset_id)
                REFERENCES dbo.asset_items(asset_item_id, asset_id);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.asset_usages')
          AND name = N'CK_asset_usages_asset_item_quantity'
    )
    BEGIN
        ALTER TABLE dbo.asset_usages WITH CHECK
            ADD CONSTRAINT CK_asset_usages_asset_item_quantity
            CHECK (asset_item_id IS NULL OR quantity = 1);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.asset_usages')
          AND name = N'IX_asset_usages_asset_item'
    )
    BEGIN
        CREATE INDEX IX_asset_usages_asset_item ON dbo.asset_usages (asset_item_id)
            WHERE asset_item_id IS NOT NULL;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.asset_usages')
          AND name = N'UX_asset_usages_active_asset_item'
    )
    BEGIN
        CREATE UNIQUE INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages (asset_item_id)
            WHERE asset_item_id IS NOT NULL AND status = 'IN_USE';
    END;

    IF COL_LENGTH(N'dbo.disposal_records', N'asset_item_id') IS NULL
    BEGIN
        ALTER TABLE dbo.disposal_records ADD asset_item_id bigint NULL;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.disposal_records')
          AND name = N'CK_disposal_records_status'
          AND (
              UPPER(definition) NOT LIKE N'%PENDING%'
              OR UPPER(definition) NOT LIKE N'%APPROVED%'
              OR UPPER(definition) NOT LIKE N'%REJECTED%'
              OR UPPER(definition) NOT LIKE N'%COMPLETED%'
              OR UPPER(definition) LIKE N'%CANCELLED%'
          )
    )
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.disposal_records
            WHERE status NOT IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')
        )
        BEGIN
            ;THROW 51031, 'Cannot replace disposal statuses while legacy values exist; map them explicitly before retrying.', 1;
        END;

        ALTER TABLE dbo.disposal_records DROP CONSTRAINT CK_disposal_records_status;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.disposal_records')
          AND name = N'CK_disposal_records_status'
    )
    BEGIN
        ALTER TABLE dbo.disposal_records WITH CHECK
            ADD CONSTRAINT CK_disposal_records_status
            CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'));
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.disposal_records')
          AND name = N'CK_disposal_records_asset_item_quantity'
    )
    BEGIN
        ALTER TABLE dbo.disposal_records WITH CHECK
            ADD CONSTRAINT CK_disposal_records_asset_item_quantity
            CHECK (asset_item_id IS NULL OR quantity = 1);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.disposal_records')
          AND name = N'FK_disposal_records_asset_item'
    )
    BEGIN
        ALTER TABLE dbo.disposal_records WITH CHECK
            ADD CONSTRAINT FK_disposal_records_asset_item FOREIGN KEY (asset_item_id)
                REFERENCES dbo.asset_items(asset_item_id);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.disposal_records')
          AND fk.referenced_object_id = OBJECT_ID(N'dbo.asset_items')
          AND 2 = (
              SELECT COUNT(*)
              FROM sys.foreign_key_columns fkc
              WHERE fkc.constraint_object_id = fk.object_id
          )
          AND EXISTS (
              SELECT 1
              FROM sys.foreign_key_columns fkc
              JOIN sys.columns parent_column
                ON parent_column.object_id = fkc.parent_object_id
               AND parent_column.column_id = fkc.parent_column_id
              JOIN sys.columns referenced_column
                ON referenced_column.object_id = fkc.referenced_object_id
               AND referenced_column.column_id = fkc.referenced_column_id
              WHERE fkc.constraint_object_id = fk.object_id
                AND parent_column.name = N'asset_item_id'
                AND referenced_column.name = N'asset_item_id'
          )
          AND EXISTS (
              SELECT 1
              FROM sys.foreign_key_columns fkc
              JOIN sys.columns parent_column
                ON parent_column.object_id = fkc.parent_object_id
               AND parent_column.column_id = fkc.parent_column_id
              JOIN sys.columns referenced_column
                ON referenced_column.object_id = fkc.referenced_object_id
               AND referenced_column.column_id = fkc.referenced_column_id
              WHERE fkc.constraint_object_id = fk.object_id
                AND parent_column.name = N'asset_id'
                AND referenced_column.name = N'asset_id'
          )
    )
    BEGIN
        ALTER TABLE dbo.disposal_records WITH CHECK
            ADD CONSTRAINT FK_disposal_records_asset_item_asset FOREIGN KEY (asset_item_id, asset_id)
                REFERENCES dbo.asset_items(asset_item_id, asset_id);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.disposal_records')
          AND name = N'UX_disposal_records_open_asset_item'
    )
    BEGIN
        CREATE UNIQUE INDEX UX_disposal_records_open_asset_item ON dbo.disposal_records (asset_item_id)
            WHERE asset_item_id IS NOT NULL AND status IN ('PENDING', 'APPROVED');
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
