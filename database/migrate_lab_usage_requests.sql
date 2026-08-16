/* Upgrade an existing lab_asset_management database for Mentor Lab Usage Requests. */
USE [lab_asset_management];
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.lab_usage_requests', 'group_name') IS NULL
        ALTER TABLE dbo.lab_usage_requests
            ADD group_name nvarchar(100) NOT NULL
                CONSTRAINT DF_lab_usage_requests_group_name DEFAULT (N'Legacy group');

    IF OBJECT_ID(N'dbo.lab_time_slots', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.lab_time_slots (
            slot_id tinyint NOT NULL,
            slot_name varchar(20) NOT NULL,
            start_time time(0) NOT NULL,
            end_time time(0) NOT NULL,
            CONSTRAINT PK_lab_time_slots PRIMARY KEY (slot_id),
            CONSTRAINT UQ_lab_time_slots_name UNIQUE (slot_name),
            CONSTRAINT CK_lab_time_slots_id CHECK (slot_id BETWEEN 1 AND 4),
            CONSTRAINT CK_lab_time_slots_time CHECK (start_time < end_time)
        );
    END;

    MERGE dbo.lab_time_slots AS target
    USING (VALUES
        (CAST(1 AS tinyint), 'SLOT_1', CAST('07:30' AS time(0)), CAST('09:50' AS time(0))),
        (CAST(2 AS tinyint), 'SLOT_2', CAST('10:00' AS time(0)), CAST('12:20' AS time(0))),
        (CAST(3 AS tinyint), 'SLOT_3', CAST('12:50' AS time(0)), CAST('15:10' AS time(0))),
        (CAST(4 AS tinyint), 'SLOT_4', CAST('15:20' AS time(0)), CAST('17:30' AS time(0)))
    ) AS source(slot_id, slot_name, start_time, end_time)
    ON target.slot_id = source.slot_id
    WHEN MATCHED THEN UPDATE SET
        slot_name = source.slot_name,
        start_time = source.start_time,
        end_time = source.end_time
    WHEN NOT MATCHED THEN INSERT (slot_id, slot_name, start_time, end_time)
        VALUES (source.slot_id, source.slot_name, source.start_time, source.end_time);

    IF OBJECT_ID(N'dbo.lab_usage_request_slots', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.lab_usage_request_slots (
            request_id bigint NOT NULL,
            day_of_week tinyint NOT NULL,
            slot_id tinyint NOT NULL,
            CONSTRAINT PK_lab_usage_request_slots PRIMARY KEY (request_id, day_of_week, slot_id),
            CONSTRAINT FK_lab_usage_request_slots_request FOREIGN KEY (request_id)
                REFERENCES dbo.lab_usage_requests(request_id) ON DELETE CASCADE,
            CONSTRAINT FK_lab_usage_request_slots_slot FOREIGN KEY (slot_id)
                REFERENCES dbo.lab_time_slots(slot_id),
            CONSTRAINT CK_lab_usage_request_slots_day CHECK (day_of_week BETWEEN 2 AND 7)
        );

        CREATE INDEX IX_lab_usage_request_slots_schedule
            ON dbo.lab_usage_request_slots (day_of_week, slot_id);
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE LOWER(email) = 'minhanh@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, role, status)
        VALUES (N'Nguyễn Minh Anh', 'minhanh@gmail.com',
            '$2a$10$ni/PZ5fY40J5I2f.AJx24OseK6h/8wbYvnqRhj9uoGZfAztXP2LXW',
            'MENTOR', 'ACTIVE');

    IF NOT EXISTS (SELECT 1 FROM dbo.semesters WHERE code = 'FA26')
        INSERT dbo.semesters (code, name, start_date, end_date, status)
        VALUES ('FA26', N'Fall 2026', '2026-08-01', '2026-12-31', 'ACTIVE');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
