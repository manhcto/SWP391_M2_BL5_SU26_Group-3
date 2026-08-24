/*
  LAB Asset Management System - Microsoft SQL Server
  Canonical standalone script for a fresh LAB Asset Management database.
  It contains the complete schema, asset lifecycle, FE-11 allocation tables
  and demo inventory. No additional schema, migration or seed file is needed.

  Rules represented here:
  - One mentor manages the lab.
  - One intern list is submitted per semester.
  - The list contains intern code, name, Gmail and cohort.
  - There are no lab slots or schedules.
  - The list can be edited/deleted while PENDING and is immutable after approval.
  - Demo accounts use password: 123
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE [master];
GO

IF DB_ID(N'lab_asset_management') IS NOT NULL
BEGIN
    RAISERROR('Database lab_asset_management already exists. This script is for a fresh database only.', 16, 1);
    SET NOEXEC ON;
END;

DECLARE @databaseSuffix varchar(32) = REPLACE(CONVERT(varchar(36), NEWID()), '-', '');
DECLARE @dataPath nvarchar(4000) = CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @logPath nvarchar(4000) = CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @createDatabase nvarchar(max);

IF @dataPath IS NULL OR @logPath IS NULL
    THROW 51000, 'SQL Server default data or log path is unavailable.', 1;

SET @createDatabase = N'CREATE DATABASE [lab_asset_management]
    ON PRIMARY (NAME = N''lab_asset_management_data'', FILENAME = N'''
    + REPLACE(@dataPath + N'lab_asset_management_' + @databaseSuffix + N'.mdf', '''', '''''')
    + N''') LOG ON (NAME = N''lab_asset_management_log'', FILENAME = N'''
    + REPLACE(@logPath + N'lab_asset_management_' + @databaseSuffix + N'_log.ldf', '''', '''''') + N''')';
EXEC sys.sp_executesql @createDatabase;
GO

USE [lab_asset_management];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.users (
        user_id bigint IDENTITY(1,1) NOT NULL,
        full_name nvarchar(100) NOT NULL,
        email varchar(255) NOT NULL,
        password_hash varchar(255) NULL,
        must_change_password bit NOT NULL CONSTRAINT DF_users_must_change_password DEFAULT (0),
        password_expires_at datetime2(0) NULL,
        google_subject varchar(255) NULL,
        role varchar(20) NOT NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_users_status DEFAULT ('ACTIVE'),
        created_at datetime2(0) NOT NULL CONSTRAINT DF_users_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_users_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_users PRIMARY KEY (user_id),
        CONSTRAINT UQ_users_email UNIQUE (email),
        CONSTRAINT CK_users_role CHECK (role IN ('ADMIN', 'LAB_MANAGER', 'MENTOR', 'INTERN')),
        CONSTRAINT CK_users_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
    );

    CREATE UNIQUE INDEX UX_users_google_subject
        ON dbo.users (google_subject)
        WHERE google_subject IS NOT NULL;

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

    CREATE INDEX IX_password_reset_requests_target_status
        ON dbo.password_reset_requests (target_user_id, status);
    CREATE UNIQUE INDEX UX_password_reset_requests_open_target
        ON dbo.password_reset_requests (target_user_id)
        WHERE status IN ('PENDING', 'APPROVED', 'ISSUED');

    CREATE TABLE dbo.student_profiles (
        student_id bigint IDENTITY(1,1) NOT NULL,
        user_id bigint NOT NULL,
        student_code varchar(30) NOT NULL,
        major nvarchar(100) NULL,
        cohort varchar(30) NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_student_profiles_status DEFAULT ('ACTIVE'),
        created_at datetime2(0) NOT NULL CONSTRAINT DF_student_profiles_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_student_profiles_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_student_profiles PRIMARY KEY (student_id),
        CONSTRAINT UQ_student_profiles_user UNIQUE (user_id),
        CONSTRAINT UQ_student_profiles_code UNIQUE (student_code),
        CONSTRAINT FK_student_profiles_user FOREIGN KEY (user_id) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_student_profiles_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
    );

    CREATE TABLE dbo.semesters (
        semester_id bigint IDENTITY(1,1) NOT NULL,
        code varchar(20) NOT NULL,
        name nvarchar(100) NOT NULL,
        start_date date NOT NULL,
        end_date date NOT NULL,
        status varchar(10) NOT NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_semesters_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_semesters_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_semesters PRIMARY KEY (semester_id),
        CONSTRAINT UQ_semesters_code UNIQUE (code),
        CONSTRAINT CK_semesters_status CHECK (status IN ('UPCOMING', 'ACTIVE', 'CLOSED')),
        CONSTRAINT CK_semesters_dates CHECK (start_date <= end_date)
    );

    CREATE TABLE dbo.lab_usage_requests (
        request_id bigint IDENTITY(1,1) NOT NULL,
        semester_id bigint NOT NULL,
        mentor_id bigint NOT NULL,
        group_name nvarchar(100) NOT NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_lab_usage_requests_status DEFAULT ('PENDING'),
        request_note nvarchar(max) NULL,
        approved_by bigint NULL,
        approved_at datetime2(0) NULL,
        approval_note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_requests_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_requests_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_lab_usage_requests PRIMARY KEY (request_id),
        CONSTRAINT UQ_lab_usage_requests_id_semester UNIQUE (request_id, semester_id),
        CONSTRAINT UQ_lab_usage_requests_semester UNIQUE (semester_id),
        CONSTRAINT FK_lab_usage_requests_semester FOREIGN KEY (semester_id) REFERENCES dbo.semesters(semester_id),
        CONSTRAINT FK_lab_usage_requests_mentor FOREIGN KEY (mentor_id) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_lab_usage_requests_approver FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_lab_usage_requests_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
        CONSTRAINT CK_lab_usage_requests_approval CHECK (
            (status = 'PENDING' AND approved_by IS NULL AND approved_at IS NULL)
            OR (status IN ('APPROVED', 'REJECTED') AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
        )
    );

    CREATE INDEX IX_lab_usage_requests_semester ON dbo.lab_usage_requests (semester_id);
    CREATE INDEX IX_lab_usage_requests_mentor ON dbo.lab_usage_requests (mentor_id);
    CREATE INDEX IX_lab_usage_requests_status ON dbo.lab_usage_requests (status);

    CREATE TABLE dbo.lab_usage_request_students (
        request_id bigint NOT NULL,
        semester_id bigint NOT NULL,
        student_id bigint NOT NULL,
        added_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_request_students_added_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_lab_usage_request_students PRIMARY KEY (request_id, student_id),
        CONSTRAINT UQ_lab_usage_request_students_request_semester_student
            UNIQUE (request_id, semester_id, student_id),
        CONSTRAINT UQ_lab_usage_request_students_semester_student
            UNIQUE (semester_id, student_id),
        CONSTRAINT FK_lab_usage_request_students_request FOREIGN KEY (request_id, semester_id)
            REFERENCES dbo.lab_usage_requests(request_id, semester_id),
        CONSTRAINT FK_lab_usage_request_students_student FOREIGN KEY (student_id) REFERENCES dbo.student_profiles(student_id)
    );

    CREATE INDEX IX_lab_usage_request_students_semester ON dbo.lab_usage_request_students (semester_id);
    CREATE INDEX IX_lab_usage_request_students_student ON dbo.lab_usage_request_students (student_id);

    EXEC(N'CREATE VIEW dbo.intern_profiles AS
           SELECT student_id AS intern_id, user_id, student_code AS intern_code,
                  major, cohort, status, created_at, updated_at
           FROM dbo.student_profiles');
    EXEC(N'CREATE VIEW dbo.lab_usage_request_interns AS
           SELECT request_id, semester_id, student_id AS intern_id, added_at
           FROM dbo.lab_usage_request_students');

    CREATE TABLE dbo.lab_usage_request_student_entries (
        request_id bigint NOT NULL,
        semester_id bigint NOT NULL,
        student_code varchar(30) NOT NULL,
        full_name nvarchar(100) NOT NULL,
        email varchar(255) NOT NULL,
        cohort varchar(30) NOT NULL,
        added_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_request_student_entries_added_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_lab_usage_request_student_entries PRIMARY KEY (request_id, student_code),
        CONSTRAINT UQ_lab_usage_request_student_entries_request_email UNIQUE (request_id, email),
        CONSTRAINT UQ_lab_usage_request_student_entries_semester_code UNIQUE (semester_id, student_code),
        CONSTRAINT UQ_lab_usage_request_student_entries_semester_email UNIQUE (semester_id, email),
        CONSTRAINT FK_lab_usage_request_student_entries_request FOREIGN KEY (request_id, semester_id)
            REFERENCES dbo.lab_usage_requests(request_id, semester_id) ON DELETE CASCADE
    );

    CREATE INDEX IX_lab_usage_request_student_entries_semester
        ON dbo.lab_usage_request_student_entries (semester_id);

    CREATE TABLE dbo.asset_categories (
        category_id bigint IDENTITY(1,1) NOT NULL,
        category_name nvarchar(100) NOT NULL,
        description nvarchar(255) NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_asset_categories_status DEFAULT ('ACTIVE'),
        created_at datetime2(0) NOT NULL CONSTRAINT DF_asset_categories_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_asset_categories_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_asset_categories PRIMARY KEY (category_id),
        CONSTRAINT UQ_asset_categories_name UNIQUE (category_name),
        CONSTRAINT CK_asset_categories_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
    );

    CREATE TABLE dbo.assets (
        asset_id bigint IDENTITY(1,1) NOT NULL,
        asset_code varchar(50) NOT NULL,
        asset_name nvarchar(150) NOT NULL,
        category_id bigint NOT NULL,
        tracking_mode varchar(10) NOT NULL,
        serial_number varchar(100) NULL,
        total_quantity int NOT NULL CONSTRAINT DF_assets_total_quantity DEFAULT (1),
        condition varchar(10) NOT NULL,
        status varchar(15) NOT NULL CONSTRAINT DF_assets_status DEFAULT ('AVAILABLE'),
        is_borrowable bit NOT NULL CONSTRAINT DF_assets_is_borrowable DEFAULT (1),
        storage_location nvarchar(150) NULL,
        description nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_assets_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_assets_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_assets PRIMARY KEY (asset_id),
        CONSTRAINT UQ_assets_code UNIQUE (asset_code),
        CONSTRAINT FK_assets_category FOREIGN KEY (category_id) REFERENCES dbo.asset_categories(category_id),
        CONSTRAINT CK_assets_tracking_mode CHECK (tracking_mode IN ('SERIALIZED', 'QUANTITY')),
        CONSTRAINT CK_assets_quantity CHECK (
            total_quantity > 0
            AND (tracking_mode = 'QUANTITY' OR total_quantity = 1)
        ),
        CONSTRAINT CK_assets_condition CHECK (condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')),
        CONSTRAINT CK_assets_status CHECK (status IN ('AVAILABLE', 'MAINTENANCE', 'UNAVAILABLE', 'DISPOSED'))
    );

    CREATE UNIQUE INDEX UX_assets_serial_number
        ON dbo.assets (serial_number)
        WHERE serial_number IS NOT NULL;
    CREATE INDEX IX_assets_category ON dbo.assets (category_id);
    CREATE INDEX IX_assets_status ON dbo.assets (status);

    CREATE TABLE dbo.asset_usages (
        asset_usage_id bigint IDENTITY(1,1) NOT NULL,
        request_id bigint NOT NULL,
        semester_id bigint NOT NULL,
        student_id bigint NOT NULL,
        asset_id bigint NOT NULL,
        asset_item_id bigint NULL,
        quantity int NOT NULL CONSTRAINT DF_asset_usages_quantity DEFAULT (1),
        borrowed_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_borrowed_at DEFAULT (SYSUTCDATETIME()),
        due_at datetime2(0) NOT NULL,
        returned_at datetime2(0) NULL,
        condition_before varchar(10) NOT NULL,
        condition_after varchar(10) NULL,
        reported_condition_after varchar(10) NULL,
        return_requested_at datetime2(0) NULL,
        verified_condition_after varchar(10) NULL,
        return_verified_at datetime2(0) NULL,
        return_verified_by bigint NULL,
        status varchar(20) NOT NULL CONSTRAINT DF_asset_usages_status DEFAULT ('IN_USE'),
        note nvarchar(max) NULL,
        return_note nvarchar(max) NULL,
        created_by bigint NOT NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_asset_usages PRIMARY KEY (asset_usage_id),
        CONSTRAINT FK_asset_usages_request_student FOREIGN KEY (request_id, semester_id, student_id)
            REFERENCES dbo.lab_usage_request_students(request_id, semester_id, student_id),
        CONSTRAINT FK_asset_usages_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_asset_usages_creator FOREIGN KEY (created_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_asset_usages_return_verifier FOREIGN KEY (return_verified_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_asset_usages_quantity CHECK (quantity > 0),
        CONSTRAINT CK_asset_usages_asset_item_quantity CHECK (asset_item_id IS NULL OR quantity = 1),
        CONSTRAINT CK_asset_usages_condition_before CHECK (condition_before IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')),
        CONSTRAINT CK_asset_usages_condition_after CHECK (
            condition_after IS NULL OR condition_after IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')
        ),
        CONSTRAINT CK_asset_usages_status CHECK (status IN ('IN_USE', 'RETURN_PENDING', 'RETURNED')),
        CONSTRAINT CK_asset_usages_dates CHECK (
            due_at >= borrowed_at
            AND (returned_at IS NULL OR returned_at >= borrowed_at)
        ),
        CONSTRAINT CK_asset_usages_return CHECK (
            (status IN ('IN_USE', 'RETURN_PENDING') AND returned_at IS NULL)
            OR (status = 'RETURNED' AND returned_at IS NOT NULL AND condition_after IS NOT NULL)
        )
    );

    CREATE INDEX IX_asset_usages_asset_status ON dbo.asset_usages (asset_id, status);
    CREATE INDEX IX_asset_usages_student_status ON dbo.asset_usages (student_id, status);
    CREATE INDEX IX_asset_usages_request_student
        ON dbo.asset_usages (request_id, semester_id, student_id);
    CREATE INDEX IX_asset_usages_semester ON dbo.asset_usages (semester_id);
    CREATE INDEX IX_asset_usages_overdue
        ON dbo.asset_usages (due_at)
        INCLUDE (asset_id, student_id, quantity)
        WHERE returned_at IS NULL;

    CREATE TABLE dbo.inspection_records (
        inspection_id bigint IDENTITY(1,1) NOT NULL,
        semester_id bigint NOT NULL,
        inspected_by bigint NOT NULL,
        inspection_type varchar(10) NOT NULL,
        scope varchar(20) NOT NULL,
        inspection_date datetime2(0) NOT NULL CONSTRAINT DF_inspection_records_date DEFAULT (SYSUTCDATETIME()),
        status varchar(10) NOT NULL CONSTRAINT DF_inspection_records_status DEFAULT ('DRAFT'),
        result varchar(20) NULL,
        note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_inspection_records_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_inspection_records_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_inspection_records PRIMARY KEY (inspection_id),
        CONSTRAINT FK_inspection_records_semester FOREIGN KEY (semester_id) REFERENCES dbo.semesters(semester_id),
        CONSTRAINT FK_inspection_records_inspector FOREIGN KEY (inspected_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_inspection_records_type CHECK (inspection_type IN ('INSPECTION', 'INVENTORY')),
        CONSTRAINT CK_inspection_records_scope CHECK (scope IN ('WHOLE_LAB', 'SELECTED_ASSETS')),
        CONSTRAINT CK_inspection_records_status CHECK (status IN ('DRAFT', 'COMPLETED')),
        CONSTRAINT CK_inspection_records_result CHECK (
            (status = 'DRAFT' AND result IS NULL)
            OR (status = 'COMPLETED' AND result IN ('NORMAL', 'DISCREPANCY_FOUND'))
        )
    );

    CREATE INDEX IX_inspection_records_semester ON dbo.inspection_records (semester_id);
    CREATE INDEX IX_inspection_records_date ON dbo.inspection_records (inspection_date);

    CREATE TABLE dbo.inspection_items (
        inspection_item_id bigint IDENTITY(1,1) NOT NULL,
        inspection_id bigint NOT NULL,
        asset_id bigint NOT NULL,
        expected_quantity int NOT NULL CONSTRAINT DF_inspection_items_expected_quantity DEFAULT (0),
        actual_quantity int NOT NULL CONSTRAINT DF_inspection_items_actual_quantity DEFAULT (0),
        expected_condition varchar(10) NULL,
        actual_condition varchar(10) NULL,
        discrepancy_type varchar(30) NULL,
        discrepancy_note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_inspection_items_created_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_inspection_items PRIMARY KEY (inspection_item_id),
        CONSTRAINT UQ_inspection_items_asset UNIQUE (inspection_id, asset_id),
        CONSTRAINT FK_inspection_items_inspection FOREIGN KEY (inspection_id) REFERENCES dbo.inspection_records(inspection_id),
        CONSTRAINT FK_inspection_items_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT CK_inspection_items_quantity CHECK (expected_quantity >= 0 AND actual_quantity >= 0),
        CONSTRAINT CK_inspection_items_expected_condition CHECK (
            expected_condition IS NULL OR expected_condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')
        ),
        CONSTRAINT CK_inspection_items_actual_condition CHECK (
            actual_condition IS NULL OR actual_condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')
        )
    );

    CREATE INDEX IX_inspection_items_asset ON dbo.inspection_items (asset_id);

    CREATE TABLE dbo.incidents (
        incident_id bigint IDENTITY(1,1) NOT NULL,
        asset_id bigint NOT NULL,
        asset_usage_id bigint NULL,
		asset_item_id bigint NULL,
        inspection_item_id bigint NULL,
        reported_by bigint NOT NULL,
        affected_quantity int NOT NULL CONSTRAINT DF_incidents_affected_quantity DEFAULT (1),
        incident_type varchar(15) NOT NULL,
        description nvarchar(max) NOT NULL,
        severity varchar(10) NOT NULL,
        status varchar(15) NOT NULL CONSTRAINT DF_incidents_status DEFAULT ('REPORTED'),
        occurred_at datetime2(0) NULL,
        reported_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_reported_at DEFAULT (SYSUTCDATETIME()),
        investigation_note nvarchar(max) NULL,
        handling_result nvarchar(max) NULL,
		reported_cause varchar(15) NOT NULL CONSTRAINT DF_incidents_reported_cause DEFAULT ('UNKNOWN'),
		determined_cause varchar(15) NULL,
        reviewed_by bigint NULL,
        reviewed_at datetime2(0) NULL,
        mentor_review_note nvarchar(max) NULL,
        forwarded_at datetime2(0) NULL,
        technical_cause varchar(30) NULL,
        technical_severity varchar(10) NULL,
        repairability varchar(20) NULL,
        recommended_action varchar(30) NULL,
        technical_note nvarchar(max) NULL,
        technical_assessed_by bigint NULL,
        technical_assessed_at datetime2(0) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_incidents PRIMARY KEY (incident_id),
        CONSTRAINT FK_incidents_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_incidents_usage FOREIGN KEY (asset_usage_id) REFERENCES dbo.asset_usages(asset_usage_id),
        CONSTRAINT FK_incidents_inspection_item FOREIGN KEY (inspection_item_id) REFERENCES dbo.inspection_items(inspection_item_id),
        CONSTRAINT FK_incidents_reporter FOREIGN KEY (reported_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_incidents_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_incidents_technical_assessor FOREIGN KEY (technical_assessed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_incidents_quantity CHECK (affected_quantity > 0),
        CONSTRAINT CK_incidents_type CHECK (incident_type IN ('DAMAGE', 'MISSING', 'LOSS', 'MALFUNCTION', 'OTHER')),
        CONSTRAINT CK_incidents_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
        CONSTRAINT CK_incidents_status CHECK (status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING', 'RESOLVED', 'CLOSED')),
		CONSTRAINT CK_incidents_reported_cause CHECK (reported_cause IN ('INTERN', 'NATURAL', 'UNKNOWN')),
		CONSTRAINT CK_incidents_determined_cause CHECK (determined_cause IS NULL OR determined_cause IN ('INTERN', 'NATURAL', 'UNKNOWN')),
        CONSTRAINT CK_incidents_dates CHECK (occurred_at IS NULL OR occurred_at <= reported_at)
    );

    CREATE INDEX IX_incidents_asset ON dbo.incidents (asset_id);
    CREATE INDEX IX_incidents_usage ON dbo.incidents (asset_usage_id) WHERE asset_usage_id IS NOT NULL;
    CREATE INDEX IX_incidents_inspection_item ON dbo.incidents (inspection_item_id) WHERE inspection_item_id IS NOT NULL;
    CREATE INDEX IX_incidents_status ON dbo.incidents (status);

    CREATE TABLE dbo.responsibilities (
        responsibility_id bigint IDENTITY(1,1) NOT NULL,
        incident_id bigint NOT NULL,
        student_id bigint NULL,
        determined_by bigint NOT NULL,
        conclusion nvarchar(max) NOT NULL,
        decision nvarchar(max) NULL,
        status varchar(20) NOT NULL,
        reviewed_by bigint NULL,
        reviewed_at datetime2(0) NULL,
        review_note nvarchar(max) NULL,
        resolution_note nvarchar(max) NULL,
        responsibility_level varchar(15) NULL,
        evidence_summary nvarchar(max) NULL,
        responsibility_note nvarchar(max) NULL,
        handling_recommendation nvarchar(max) NULL,
        responsibility_assessed_by bigint NULL,
        responsibility_assessed_at datetime2(0) NULL,
        determined_at datetime2(0) NOT NULL CONSTRAINT DF_responsibilities_determined_at DEFAULT (SYSUTCDATETIME()),
        resolved_at datetime2(0) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_responsibilities_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_responsibilities_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_responsibilities PRIMARY KEY (responsibility_id),
        CONSTRAINT UQ_responsibilities_incident UNIQUE (incident_id),
        CONSTRAINT FK_responsibilities_incident FOREIGN KEY (incident_id) REFERENCES dbo.incidents(incident_id),
        CONSTRAINT FK_responsibilities_student FOREIGN KEY (student_id) REFERENCES dbo.student_profiles(student_id),
        CONSTRAINT FK_responsibilities_determiner FOREIGN KEY (determined_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_responsibilities_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_responsibilities_assessor FOREIGN KEY (responsibility_assessed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_responsibilities_level CHECK (
            responsibility_level IS NULL OR responsibility_level IN ('UNDETERMINED', 'NONE', 'PARTIAL', 'FULL')
        ),
        CONSTRAINT CK_responsibilities_level_evidence CHECK (
            responsibility_level NOT IN ('PARTIAL', 'FULL')
            OR (student_id IS NOT NULL AND evidence_summary IS NOT NULL AND responsibility_note IS NOT NULL)
        ),
        CONSTRAINT CK_responsibilities_status CHECK (
            status IN ('CONFIRMED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'RESOLVED')
        ),
        CONSTRAINT CK_responsibilities_review_pair CHECK (
            (reviewed_by IS NULL AND reviewed_at IS NULL)
            OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
        ),
        CONSTRAINT CK_responsibilities_review_status CHECK (
            status NOT IN ('APPROVED', 'REJECTED')
            OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
        ),
        CONSTRAINT CK_responsibilities_resolution CHECK (
            (status = 'RESOLVED' AND resolved_at IS NOT NULL)
            OR (status <> 'RESOLVED' AND resolved_at IS NULL)
        )
    );

    CREATE INDEX IX_responsibilities_student ON dbo.responsibilities (student_id);
    CREATE INDEX IX_responsibilities_status ON dbo.responsibilities (status);

    CREATE TABLE dbo.maintenance_records (
        maintenance_id bigint IDENTITY(1,1) NOT NULL,
        asset_id bigint NOT NULL,
        asset_item_id bigint NULL,
        incident_id bigint NULL,
        assessment_id bigint NULL,
        quantity int NOT NULL CONSTRAINT DF_maintenance_records_quantity DEFAULT (1),
        requested_by bigint NOT NULL,
        description nvarchar(max) NOT NULL,
        requested_at datetime2(0) NOT NULL CONSTRAINT DF_maintenance_records_requested_at DEFAULT (SYSUTCDATETIME()),
        status varchar(15) NOT NULL CONSTRAINT DF_maintenance_records_status DEFAULT ('PENDING'),
        approved_by bigint NULL,
        approved_at datetime2(0) NULL,
        approval_note nvarchar(max) NULL,
        repair_started_at datetime2(0) NULL,
        repair_completed_at datetime2(0) NULL,
        repair_result nvarchar(max) NULL,
        repair_outcome varchar(10) NOT NULL CONSTRAINT DF_maintenance_records_repair_outcome DEFAULT ('PENDING'),
        estimated_cost decimal(15,0) NULL,
        actual_cost decimal(15,0) NULL,
        note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_maintenance_records_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_maintenance_records_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_maintenance_records PRIMARY KEY (maintenance_id),
        CONSTRAINT FK_maintenance_records_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_maintenance_records_incident FOREIGN KEY (incident_id) REFERENCES dbo.incidents(incident_id),
        CONSTRAINT FK_maintenance_records_requester FOREIGN KEY (requested_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_maintenance_records_approver FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_maintenance_records_quantity CHECK (quantity > 0),
        CONSTRAINT CK_maintenance_records_status CHECK (
            status IN ('PENDING', 'APPROVED', 'REJECTED', 'IN_PROGRESS', 'COMPLETED')
        ),
        CONSTRAINT CK_maintenance_records_repair_outcome CHECK (
            repair_outcome IN ('PENDING', 'SUCCESS', 'FAILED')
        ),
        CONSTRAINT CK_maintenance_records_approval CHECK (
            (status = 'PENDING' AND approved_by IS NULL AND approved_at IS NULL)
            OR (status IN ('APPROVED', 'REJECTED', 'IN_PROGRESS', 'COMPLETED')
                AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
        ),
        CONSTRAINT CK_maintenance_records_dates CHECK (
            (repair_started_at IS NULL OR repair_started_at >= approved_at)
            AND (repair_completed_at IS NULL
                OR (repair_started_at IS NOT NULL AND repair_completed_at >= repair_started_at))
        ),
        CONSTRAINT CK_maintenance_records_completion CHECK (
            status <> 'COMPLETED'
            OR (repair_started_at IS NOT NULL AND repair_completed_at IS NOT NULL)
        )
    );

    CREATE INDEX IX_maintenance_records_asset ON dbo.maintenance_records (asset_id);
    CREATE INDEX IX_maintenance_records_incident ON dbo.maintenance_records (incident_id) WHERE incident_id IS NOT NULL;
    CREATE INDEX IX_maintenance_records_status ON dbo.maintenance_records (status);

    CREATE TABLE dbo.disposal_records (
        disposal_id bigint IDENTITY(1,1) NOT NULL,
        asset_id bigint NOT NULL,
        asset_item_id bigint NULL,
        maintenance_id bigint NULL,
        quantity int NOT NULL CONSTRAINT DF_disposal_records_quantity DEFAULT (1),
        requested_by bigint NOT NULL,
        reason nvarchar(max) NOT NULL,
        reason_code varchar(30) NULL,
        technical_review_note nvarchar(max) NULL,
        requested_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_requested_at DEFAULT (SYSUTCDATETIME()),
        status varchar(10) NOT NULL CONSTRAINT DF_disposal_records_status DEFAULT ('PENDING'),
        approved_by bigint NULL,
        approved_at datetime2(0) NULL,
        approval_note nvarchar(max) NULL,
        disposal_method varchar(20) NULL,
        completed_by bigint NULL,
        completed_at datetime2(0) NULL,
        completion_note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_disposal_records PRIMARY KEY (disposal_id),
        CONSTRAINT FK_disposal_records_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_disposal_records_maintenance FOREIGN KEY (maintenance_id) REFERENCES dbo.maintenance_records(maintenance_id),
        CONSTRAINT FK_disposal_records_requester FOREIGN KEY (requested_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_disposal_records_approver FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_disposal_records_completer FOREIGN KEY (completed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_disposal_records_quantity CHECK (quantity > 0),
        CONSTRAINT CK_disposal_records_asset_item_quantity CHECK (asset_item_id IS NULL OR quantity = 1),
        CONSTRAINT CK_disposal_records_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')),
        CONSTRAINT CK_disposal_records_completion CHECK (
            (status = 'COMPLETED' AND completed_at IS NOT NULL)
            OR (status <> 'COMPLETED' AND completed_at IS NULL)
        )
    );

    CREATE INDEX IX_disposal_records_asset ON dbo.disposal_records (asset_id);
    CREATE INDEX IX_disposal_records_maintenance ON dbo.disposal_records (maintenance_id) WHERE maintenance_id IS NOT NULL;
    CREATE INDEX IX_disposal_records_status ON dbo.disposal_records (status);
    CREATE UNIQUE INDEX UX_disposal_records_open_quantity_asset ON dbo.disposal_records (asset_id)
        WHERE asset_item_id IS NULL AND status IN ('PENDING', 'APPROVED');

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

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @admin_id bigint;
    DECLARE @manager_id bigint;
    DECLARE @mentor_id bigint;
    DECLARE @intern_one_user_id bigint;
    DECLARE @intern_two_user_id bigint;
    DECLARE @intern_one_id bigint;
    DECLARE @intern_two_id bigint;
    DECLARE @semester_id bigint;
    DECLARE @request_id bigint;
    DECLARE @category_id bigint;
    DECLARE @asset_id bigint;
    DECLARE @usage_one_id bigint;
    DECLARE @usage_two_id bigint;
    DECLARE @incident_one_id bigint;
    DECLARE @incident_two_id bigint;
    DECLARE @password_hash varchar(255) = '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C';

    INSERT dbo.users (full_name, email, password_hash, role, status)
    VALUES
        (N'Demo Admin', 'admin@gmail.com', @password_hash, 'ADMIN', 'ACTIVE'),
        (N'Demo Lab Manager', 'manager@gmail.com', @password_hash, 'LAB_MANAGER', 'ACTIVE'),
        (N'Demo Mentor', 'mentor@gmail.com', @password_hash, 'MENTOR', 'ACTIVE'),
        (N'Demo Intern 1', 'intern@gmail.com', @password_hash, 'INTERN', 'ACTIVE'),
        (N'Demo Intern 2', 'intern2@gmail.com', @password_hash, 'INTERN', 'ACTIVE');

    SELECT @admin_id = user_id FROM dbo.users WHERE email = 'admin@gmail.com';
    SELECT @manager_id = user_id FROM dbo.users WHERE email = 'manager@gmail.com';
    SELECT @mentor_id = user_id FROM dbo.users WHERE email = 'mentor@gmail.com';
    SELECT @intern_one_user_id = user_id FROM dbo.users WHERE email = 'intern@gmail.com';
    SELECT @intern_two_user_id = user_id FROM dbo.users WHERE email = 'intern2@gmail.com';

    INSERT dbo.student_profiles (user_id, student_code, major, cohort, status)
    VALUES
        (@intern_one_user_id, 'INTERN001', NULL, 'K17', 'ACTIVE'),
        (@intern_two_user_id, 'INTERN002', NULL, 'K17', 'ACTIVE');

    SELECT @intern_one_id = student_id
    FROM dbo.student_profiles
    WHERE student_code = 'INTERN001';

    SELECT @intern_two_id = student_id
    FROM dbo.student_profiles
    WHERE student_code = 'INTERN002';

    SELECT @semester_id = semester_id
    FROM dbo.semesters
    WHERE code = 'FA26';

    INSERT dbo.lab_usage_requests
        (semester_id, mentor_id, group_name, status, request_note, approved_by, approved_at, approval_note)
    VALUES
        (@semester_id, @mentor_id, N'FA26 Intern List', 'APPROVED',
         N'Initial intern list for the lab in Fall 2026.', @admin_id, SYSUTCDATETIME(),
         N'Approved as one list for the semester.');

    SET @request_id = SCOPE_IDENTITY();

    INSERT dbo.lab_usage_request_student_entries
        (request_id, semester_id, student_code, full_name, email, cohort)
    VALUES
        (@request_id, @semester_id, 'INTERN001', N'Demo Intern 1', 'intern@gmail.com', 'K17'),
        (@request_id, @semester_id, 'INTERN002', N'Demo Intern 2', 'intern2@gmail.com', 'K17');

    INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
    VALUES
        (@request_id, @semester_id, @intern_one_id),
        (@request_id, @semester_id, @intern_two_id);

    INSERT dbo.asset_categories (category_name, description, status)
    VALUES (N'Thiết bị phòng LAB', N'Danh mục mẫu cho khởi tạo database.', 'ACTIVE');

    SET @category_id = SCOPE_IDENTITY();

    INSERT dbo.assets
        (asset_code, asset_name, category_id, tracking_mode, serial_number, total_quantity,
         condition, status, is_borrowable, storage_location, description)
    VALUES
        ('DEMO-MULTIMETER-001', N'Digital Multimeter', @category_id, 'SERIALIZED',
         'DEMO-SN-001', 1, 'GOOD', 'AVAILABLE', 1, N'Lab cabinet A1', N'Demo asset.');

    SET @asset_id = SCOPE_IDENTITY();

    INSERT dbo.asset_usages
        (request_id, semester_id, student_id, asset_id, quantity, borrowed_at, due_at, returned_at,
         condition_before, condition_after, status, note, created_by)
    VALUES
        (@request_id, @semester_id, @intern_one_id, @asset_id, 1, '2026-08-05T08:00:00',
         '2026-08-12T17:00:00', '2026-08-10T16:30:00', 'GOOD', 'FAIR', 'RETURNED',
         N'Demo usage for a resolved responsibility case.', @intern_one_user_id);

    SET @usage_one_id = SCOPE_IDENTITY();

    INSERT dbo.asset_usages
        (request_id, semester_id, student_id, asset_id, quantity, borrowed_at, due_at, returned_at,
         condition_before, condition_after, status, note, created_by)
    VALUES
        (@request_id, @semester_id, @intern_two_id, @asset_id, 1, '2026-08-13T08:00:00',
         '2026-08-20T17:00:00', '2026-08-16T15:00:00', 'GOOD', 'DAMAGED', 'RETURNED',
         N'Demo usage for a responsibility pending review.', @intern_two_user_id);

    SET @usage_two_id = SCOPE_IDENTITY();

    INSERT dbo.incidents
        (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
         status, occurred_at, reported_at, investigation_note, handling_result)
    VALUES
        (@asset_id, @usage_one_id, @intern_one_user_id, 1, 'MALFUNCTION',
         N'Multimeter probe showed normal consumable wear during project work.', 'LOW', 'RESOLVED',
         '2026-08-10T15:30:00', '2026-08-10T16:35:00',
         N'Mentor inspected the probe and confirmed normal wear.', N'Consumable probe replaced by the LAB.');

    SET @incident_one_id = SCOPE_IDENTITY();

    INSERT dbo.incidents
        (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
         status, occurred_at, reported_at, investigation_note, handling_result)
    VALUES
        (@asset_id, @usage_two_id, @intern_two_user_id, 1, 'DAMAGE',
         N'Excessive voltage input caused the multimeter fuse to fail.', 'HIGH', 'INVESTIGATING',
         '2026-08-16T14:30:00', '2026-08-16T15:05:00',
         N'Usage history and returned condition identify the related Intern.', NULL);

    SET @incident_two_id = SCOPE_IDENTITY();

    INSERT dbo.responsibilities
        (incident_id, student_id, determined_by, conclusion, decision, status, resolution_note,
         determined_at, resolved_at)
    VALUES
        (@incident_one_id, @intern_one_id, @mentor_id,
         N'Normal consumable wear occurred during approved project work.',
         N'Waived - LAB consumable replacement.', 'RESOLVED', N'No Intern compensation required.',
         '2026-08-11T09:00:00', '2026-08-11T09:00:00'),
        (@incident_two_id, @intern_two_id, @mentor_id,
         N'Incorrect voltage range selection caused the fuse failure.',
         N'Component replacement recommendation: 150,000 VND.', 'PENDING_REVIEW', NULL,
         '2026-08-17T09:00:00', NULL);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* ========================================================================
   MERGED EXTENSIONS
   The sections below are included so this file is the single full setup:
   majors lookup, serialized asset items, normalized asset seed, incidents,
   and responsibility test data.
   ======================================================================== */

/* Major lookup migration */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.majors', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.majors (
        major_id bigint IDENTITY(1,1) NOT NULL,
        major_code varchar(20) NOT NULL,
        major_name nvarchar(100) NOT NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_majors_status DEFAULT ('ACTIVE'),
        display_order int NOT NULL CONSTRAINT DF_majors_display_order DEFAULT (0),
        CONSTRAINT PK_majors PRIMARY KEY (major_id),
        CONSTRAINT UQ_majors_code UNIQUE (major_code),
        CONSTRAINT UQ_majors_name UNIQUE (major_name),
        CONSTRAINT CK_majors_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'SE') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('SE', N'Software Engineering', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'AI') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('AI', N'Artificial Intelligence', 2);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'IS') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('IS', N'Information Systems', 3);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'IA') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('IA', N'Information Assurance', 4);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'GD') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('GD', N'Graphic Design', 5);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'MC') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('MC', N'Multimedia Communications', 6);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'BA') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('BA', N'Business Administration', 7);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'DM') INSERT dbo.majors (major_code, major_name, display_order) VALUES ('DM', N'Digital Marketing', 8);

IF COL_LENGTH('dbo.student_profiles', 'major_id') IS NULL
    ALTER TABLE dbo.student_profiles ADD major_id bigint NULL;
GO

IF COL_LENGTH('dbo.student_profiles', 'major') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1 FROM dbo.student_profiles profile
        WHERE profile.major IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.majors major WHERE major.major_name = profile.major)
    )
        THROW 51000, 'Existing student_profiles.major values need a mapping in dbo.majors before migration.', 1;

    UPDATE profile
    SET major_id = major.major_id
    FROM dbo.student_profiles profile
    JOIN dbo.majors major ON major.major_name = profile.major
    WHERE profile.major_id IS NULL;
END;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_student_profiles_major')
    ALTER TABLE dbo.student_profiles
        ADD CONSTRAINT FK_student_profiles_major FOREIGN KEY (major_id) REFERENCES dbo.majors(major_id);

IF COL_LENGTH('dbo.student_profiles', 'major') IS NOT NULL
    ALTER TABLE dbo.student_profiles DROP COLUMN major;

COMMIT TRANSACTION;
GO

/* The major lookup replaces student_profiles.major, so refresh compatibility views. */
EXEC(N'CREATE OR ALTER VIEW dbo.intern_profiles AS
       SELECT sp.student_id AS intern_id, sp.user_id, sp.student_code AS intern_code,
              m.major_name AS major, sp.cohort, sp.status, sp.created_at, sp.updated_at
       FROM dbo.student_profiles sp
       LEFT JOIN dbo.majors m ON m.major_id = sp.major_id');
EXEC(N'CREATE OR ALTER VIEW dbo.lab_usage_request_interns AS
       SELECT request_id, semester_id, student_id AS intern_id, added_at
       FROM dbo.lab_usage_request_students');
GO

/* One row per physical asset item */
IF OBJECT_ID(N'dbo.asset_items', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.asset_items (
        asset_item_id bigint IDENTITY(1,1) NOT NULL,
        asset_id bigint NOT NULL,
        item_code varchar(70) NOT NULL,
        serial_number varchar(100) NULL,
        image_path nvarchar(500) NULL,
        condition varchar(10) NOT NULL CONSTRAINT DF_asset_items_condition DEFAULT ('GOOD'),
        status varchar(15) NOT NULL CONSTRAINT DF_asset_items_status DEFAULT ('AVAILABLE'),
        is_borrowable bit NOT NULL CONSTRAINT DF_asset_items_is_borrowable DEFAULT (1),
        storage_location nvarchar(150) NULL,
        purchase_date date NULL,
        warranty_until date NULL,
        note nvarchar(500) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_asset_items_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_asset_items_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_asset_items PRIMARY KEY (asset_item_id),
        CONSTRAINT UQ_asset_items_code UNIQUE (item_code),
        CONSTRAINT UQ_asset_items_item_asset UNIQUE (asset_item_id, asset_id),
        CONSTRAINT FK_asset_items_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT CK_asset_items_condition CHECK (condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')),
        CONSTRAINT CK_asset_items_status CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'UNAVAILABLE', 'DISPOSED')),
        CONSTRAINT CK_asset_items_dates CHECK (warranty_until IS NULL OR purchase_date IS NULL OR warranty_until >= purchase_date)
    );

    CREATE UNIQUE INDEX UX_asset_items_serial ON dbo.asset_items (serial_number) WHERE serial_number IS NOT NULL;
    CREATE INDEX IX_asset_items_asset ON dbo.asset_items (asset_id);
    CREATE INDEX IX_asset_items_status ON dbo.asset_items (status);

    ;WITH Numbers AS (
        SELECT TOP (SELECT COALESCE(MAX(total_quantity), 1) FROM dbo.assets)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS item_number
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    )
    INSERT dbo.asset_items (asset_id, item_code, serial_number, condition, status, storage_location, note)
    SELECT a.asset_id,
           CONCAT(a.asset_code, '-', RIGHT(CONCAT('0000', n.item_number), 4)),
           CASE WHEN a.serial_number IS NULL THEN NULL ELSE CONCAT(a.serial_number, '-', n.item_number) END,
           a.condition, a.status, a.storage_location, N'Tạo tự động từ dữ liệu thiết bị hiện có'
    FROM dbo.assets a
    JOIN Numbers n ON n.item_number <= a.total_quantity
    WHERE NOT EXISTS (SELECT 1 FROM dbo.asset_items i WHERE i.asset_id = a.asset_id);
END;
GO

/* asset_items is available only after the initial schema and seed above. */
IF COL_LENGTH('dbo.incidents', 'reported_cause') IS NULL
    ALTER TABLE dbo.incidents ADD reported_cause varchar(15) NOT NULL
        CONSTRAINT DF_incidents_reported_cause DEFAULT ('UNKNOWN');
IF COL_LENGTH('dbo.incidents', 'determined_cause') IS NULL
    ALTER TABLE dbo.incidents ADD determined_cause varchar(15) NULL;
IF COL_LENGTH('dbo.incidents', 'reviewed_by') IS NULL
    ALTER TABLE dbo.incidents ADD reviewed_by bigint NULL;
IF COL_LENGTH('dbo.incidents', 'reviewed_at') IS NULL
    ALTER TABLE dbo.incidents ADD reviewed_at datetime2(0) NULL;
IF COL_LENGTH('dbo.incidents', 'mentor_review_note') IS NULL
    ALTER TABLE dbo.incidents ADD mentor_review_note nvarchar(max) NULL;
IF COL_LENGTH('dbo.incidents', 'forwarded_at') IS NULL
    ALTER TABLE dbo.incidents ADD forwarded_at datetime2(0) NULL;
IF COL_LENGTH('dbo.incidents', 'technical_cause') IS NULL
    ALTER TABLE dbo.incidents ADD technical_cause varchar(30) NULL;
IF COL_LENGTH('dbo.incidents', 'technical_severity') IS NULL
    ALTER TABLE dbo.incidents ADD technical_severity varchar(10) NULL;
IF COL_LENGTH('dbo.incidents', 'repairability') IS NULL
    ALTER TABLE dbo.incidents ADD repairability varchar(20) NULL;
IF COL_LENGTH('dbo.incidents', 'recommended_action') IS NULL
    ALTER TABLE dbo.incidents ADD recommended_action varchar(30) NULL;
IF COL_LENGTH('dbo.incidents', 'technical_note') IS NULL
    ALTER TABLE dbo.incidents ADD technical_note nvarchar(max) NULL;
IF COL_LENGTH('dbo.incidents', 'technical_assessed_by') IS NULL
    ALTER TABLE dbo.incidents ADD technical_assessed_by bigint NULL;
IF COL_LENGTH('dbo.incidents', 'technical_assessed_at') IS NULL
    ALTER TABLE dbo.incidents ADD technical_assessed_at datetime2(0) NULL;
IF COL_LENGTH('dbo.responsibilities', 'responsibility_level') IS NULL
    ALTER TABLE dbo.responsibilities ADD responsibility_level varchar(15) NULL;
IF COL_LENGTH('dbo.responsibilities', 'evidence_summary') IS NULL
    ALTER TABLE dbo.responsibilities ADD evidence_summary nvarchar(max) NULL;
IF COL_LENGTH('dbo.responsibilities', 'responsibility_note') IS NULL
    ALTER TABLE dbo.responsibilities ADD responsibility_note nvarchar(max) NULL;
IF COL_LENGTH('dbo.responsibilities', 'handling_recommendation') IS NULL
    ALTER TABLE dbo.responsibilities ADD handling_recommendation nvarchar(max) NULL;
IF COL_LENGTH('dbo.responsibilities', 'responsibility_assessed_by') IS NULL
    ALTER TABLE dbo.responsibilities ADD responsibility_assessed_by bigint NULL;
IF COL_LENGTH('dbo.responsibilities', 'responsibility_assessed_at') IS NULL
    ALTER TABLE dbo.responsibilities ADD responsibility_assessed_at datetime2(0) NULL;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_incidents_status')
    ALTER TABLE dbo.incidents DROP CONSTRAINT CK_incidents_status;
ALTER TABLE dbo.incidents ADD CONSTRAINT CK_incidents_status
    CHECK (status IN ('OPEN', 'REPORTED', 'FORWARDED', 'INVESTIGATING', 'RESOLVED', 'CLOSED'));
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_incidents_reviewer')
    ALTER TABLE dbo.incidents ADD CONSTRAINT FK_incidents_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_incidents_technical_assessor')
    ALTER TABLE dbo.incidents ADD CONSTRAINT FK_incidents_technical_assessor
        FOREIGN KEY (technical_assessed_by) REFERENCES dbo.users(user_id);
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.responsibilities') AND name = 'student_id' AND is_nullable = 0
)
    ALTER TABLE dbo.responsibilities ALTER COLUMN student_id bigint NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_responsibilities_assessor')
    ALTER TABLE dbo.responsibilities ADD CONSTRAINT FK_responsibilities_assessor
        FOREIGN KEY (responsibility_assessed_by) REFERENCES dbo.users(user_id);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_responsibilities_level')
    ALTER TABLE dbo.responsibilities ADD CONSTRAINT CK_responsibilities_level
        CHECK (responsibility_level IS NULL OR responsibility_level IN ('UNDETERMINED', 'NONE', 'PARTIAL', 'FULL'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_responsibilities_level_evidence')
    ALTER TABLE dbo.responsibilities ADD CONSTRAINT CK_responsibilities_level_evidence
        CHECK (responsibility_level NOT IN ('PARTIAL', 'FULL')
            OR (student_id IS NOT NULL AND evidence_summary IS NOT NULL AND responsibility_note IS NOT NULL));
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_incidents_asset_item'
      AND parent_object_id = OBJECT_ID('dbo.incidents')
)
    ALTER TABLE dbo.incidents
        ADD CONSTRAINT FK_incidents_asset_item FOREIGN KEY (asset_item_id)
        REFERENCES dbo.asset_items(asset_item_id);
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_incidents_asset_item'
      AND object_id = OBJECT_ID('dbo.incidents')
)
    CREATE INDEX IX_incidents_asset_item ON dbo.incidents (asset_item_id)
        WHERE asset_item_id IS NOT NULL;
GO

/* Existing databases may already have asset_items; keep the usage link idempotent. */
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
    ALTER TABLE dbo.asset_usages
        ADD CONSTRAINT FK_asset_usages_asset_item FOREIGN KEY (asset_item_id, asset_id)
        REFERENCES dbo.asset_items(asset_item_id, asset_id);
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_asset_usages_asset_item_quantity'
      AND parent_object_id = OBJECT_ID('dbo.asset_usages')
)
    ALTER TABLE dbo.asset_usages
        ADD CONSTRAINT CK_asset_usages_asset_item_quantity
        CHECK (asset_item_id IS NULL OR quantity = 1);
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_asset_usages_asset_item'
      AND object_id = OBJECT_ID('dbo.asset_usages')
)
    CREATE INDEX IX_asset_usages_asset_item ON dbo.asset_usages (asset_item_id)
        WHERE asset_item_id IS NOT NULL;
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_asset_usages_active_asset_item'
      AND object_id = OBJECT_ID('dbo.asset_usages')
)
    CREATE UNIQUE INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages (asset_item_id)
        WHERE asset_item_id IS NOT NULL AND status IN ('IN_USE', 'RETURN_PENDING');
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_disposal_records_asset_item'
      AND parent_object_id = OBJECT_ID('dbo.disposal_records')
)
    ALTER TABLE dbo.disposal_records
        ADD CONSTRAINT FK_disposal_records_asset_item FOREIGN KEY (asset_item_id, asset_id)
        REFERENCES dbo.asset_items(asset_item_id, asset_id);
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_disposal_records_open_asset_item'
      AND object_id = OBJECT_ID('dbo.disposal_records')
)
    CREATE UNIQUE INDEX UX_disposal_records_open_asset_item ON dbo.disposal_records (asset_item_id)
        WHERE asset_item_id IS NOT NULL AND status IN ('PENDING', 'APPROVED');
GO

/* FE-08 exact-item maintenance upgrade. Historical parent-level rows remain readable. */
IF COL_LENGTH('dbo.maintenance_records', 'asset_item_id') IS NULL
    ALTER TABLE dbo.maintenance_records ADD asset_item_id bigint NULL;
IF COL_LENGTH('dbo.maintenance_records', 'assessment_id') IS NULL
    ALTER TABLE dbo.maintenance_records ADD assessment_id bigint NULL;
IF COL_LENGTH('dbo.maintenance_records', 'repair_outcome') IS NULL
    ALTER TABLE dbo.maintenance_records ADD repair_outcome varchar(10) NOT NULL
        CONSTRAINT DF_maintenance_records_repair_outcome DEFAULT ('PENDING');
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_maintenance_records_asset_item'
      AND parent_object_id = OBJECT_ID('dbo.maintenance_records')
)
    ALTER TABLE dbo.maintenance_records
        ADD CONSTRAINT FK_maintenance_records_asset_item FOREIGN KEY (asset_item_id, asset_id)
        REFERENCES dbo.asset_items(asset_item_id, asset_id);
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_maintenance_records_repair_outcome'
      AND parent_object_id = OBJECT_ID('dbo.maintenance_records')
)
    ALTER TABLE dbo.maintenance_records ADD CONSTRAINT CK_maintenance_records_repair_outcome
        CHECK (repair_outcome IN ('PENDING', 'SUCCESS', 'FAILED'));
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_maintenance_records_asset_item'
      AND object_id = OBJECT_ID('dbo.maintenance_records')
)
    CREATE INDEX IX_maintenance_records_asset_item ON dbo.maintenance_records (asset_item_id, status)
        WHERE asset_item_id IS NOT NULL;
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_maintenance_records_active_asset_item'
      AND object_id = OBJECT_ID('dbo.maintenance_records')
)
    CREATE UNIQUE INDEX UX_maintenance_records_active_asset_item ON dbo.maintenance_records (asset_item_id)
        WHERE asset_item_id IS NOT NULL AND status IN ('PENDING', 'APPROVED', 'IN_PROGRESS');
GO

/* Canonicalize the legacy asset usage identity column without rewriting data. */
IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.asset_usages')
      AND name = 'intern_id'
      AND is_computed = 0
)
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.asset_usages')
      AND name = 'student_id'
      AND is_computed = 1
)
BEGIN
    ALTER TABLE dbo.asset_usages DROP COLUMN student_id;
    EXEC sys.sp_rename 'dbo.asset_usages.intern_id', 'student_id', 'COLUMN';
END;
GO

/* FE-04/FE-09 lifecycle upgrade for existing databases. */
IF COL_LENGTH('dbo.asset_usages', 'reported_condition_after') IS NULL
    ALTER TABLE dbo.asset_usages ADD reported_condition_after varchar(10) NULL;
IF COL_LENGTH('dbo.asset_usages', 'return_requested_at') IS NULL
    ALTER TABLE dbo.asset_usages ADD return_requested_at datetime2(0) NULL;
IF COL_LENGTH('dbo.asset_usages', 'verified_condition_after') IS NULL
    ALTER TABLE dbo.asset_usages ADD verified_condition_after varchar(10) NULL;
IF COL_LENGTH('dbo.asset_usages', 'return_verified_at') IS NULL
    ALTER TABLE dbo.asset_usages ADD return_verified_at datetime2(0) NULL;
IF COL_LENGTH('dbo.asset_usages', 'return_verified_by') IS NULL
    ALTER TABLE dbo.asset_usages ADD return_verified_by bigint NULL;
IF COL_LENGTH('dbo.disposal_records', 'reason_code') IS NULL
    ALTER TABLE dbo.disposal_records ADD reason_code varchar(30) NULL;
IF COL_LENGTH('dbo.disposal_records', 'technical_review_note') IS NULL
    ALTER TABLE dbo.disposal_records ADD technical_review_note nvarchar(max) NULL;
IF COL_LENGTH('dbo.disposal_records', 'disposal_method') IS NULL
    ALTER TABLE dbo.disposal_records ADD disposal_method varchar(20) NULL;
IF COL_LENGTH('dbo.disposal_records', 'completed_by') IS NULL
    ALTER TABLE dbo.disposal_records ADD completed_by bigint NULL;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_asset_usages_active_asset_item' AND object_id=OBJECT_ID('dbo.asset_usages'))
    DROP INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_asset_usages_return')
    ALTER TABLE dbo.asset_usages DROP CONSTRAINT CK_asset_usages_return;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_asset_usages_status')
    ALTER TABLE dbo.asset_usages DROP CONSTRAINT CK_asset_usages_status;
ALTER TABLE dbo.asset_usages ADD CONSTRAINT CK_asset_usages_status CHECK (status IN ('IN_USE','RETURN_PENDING','RETURNED'));
ALTER TABLE dbo.asset_usages ADD CONSTRAINT CK_asset_usages_return CHECK (
    (status IN ('IN_USE', 'RETURN_PENDING') AND returned_at IS NULL)
    OR (status = 'RETURNED' AND returned_at IS NOT NULL
        AND COALESCE(verified_condition_after, condition_after) IS NOT NULL)
);
CREATE UNIQUE INDEX UX_asset_usages_active_asset_item ON dbo.asset_usages(asset_item_id)
    WHERE asset_item_id IS NOT NULL AND status IN ('IN_USE','RETURN_PENDING');
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_asset_usages_return_verifier')
    ALTER TABLE dbo.asset_usages ADD CONSTRAINT FK_asset_usages_return_verifier FOREIGN KEY(return_verified_by) REFERENCES dbo.users(user_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_disposal_records_completer')
    ALTER TABLE dbo.disposal_records ADD CONSTRAINT FK_disposal_records_completer FOREIGN KEY(completed_by) REFERENCES dbo.users(user_id);
GO

/* Seed the canonical borrowable equipment inventory. */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @kitCategoryId bigint;
DECLARE @measurementCategoryId bigint;
DECLARE @computerAccessoryCategoryId bigint;

IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Kit thiết bị')
    INSERT dbo.asset_categories (category_name, description, status)
    VALUES (N'Kit thiết bị', N'Các bộ kit điện tử và cảm biến được phép cho intern mượn.', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Thiết bị đo lường')
    INSERT dbo.asset_categories (category_name, description, status)
    VALUES (N'Thiết bị đo lường', N'Thiết bị đo điện và điện tử được phép cho intern mượn.', 'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Phụ kiện máy tính')
    INSERT dbo.asset_categories (category_name, description, status)
    VALUES (N'Phụ kiện máy tính', N'Phụ kiện phục vụ học tập và thuyết trình được phép cho intern mượn.', 'ACTIVE');
SELECT @kitCategoryId = category_id FROM dbo.asset_categories WHERE category_name = N'Kit thiết bị';
SELECT @measurementCategoryId = category_id FROM dbo.asset_categories WHERE category_name = N'Thiết bị đo lường';
SELECT @computerAccessoryCategoryId = category_id FROM dbo.asset_categories WHERE category_name = N'Phụ kiện máy tính';

DECLARE @targets TABLE (
    asset_code varchar(50) NOT NULL PRIMARY KEY,
    asset_name nvarchar(150) NOT NULL,
    category_id bigint NOT NULL,
    total_quantity int NOT NULL,
    is_borrowable bit NOT NULL,
    image_path nvarchar(500) NULL,
    storage_location nvarchar(150) NULL,
    description nvarchar(max) NULL
);

INSERT @targets (asset_code, asset_name, category_id, total_quantity, is_borrowable, image_path, storage_location, description)
VALUES
    ('ARD-KIT-A01', N'Bộ kit Arduino A01', @kitCategoryId, 3, 1, N'/assets/images/equipment/arduino-uno-kit.svg', N'Tủ IoT-01', N'Kit Arduino dùng cho bài thực hành IoT.'),
    ('SENSOR-KIT-S04', N'Bộ kit cảm biến S04', @kitCategoryId, 3, 1, N'/assets/images/equipment/raspberry-pi-kit.svg', N'Tủ IoT-02', N'Kit cảm biến dùng cho bài thực hành đo lường.'),
    ('ARDUINO-UNO-KIT', N'Bộ kit Arduino Uno', @kitCategoryId, 5, 1, N'/assets/images/equipment/arduino-uno-kit.svg', N'Tủ IoT-03', N'Bộ kit Arduino Uno gồm bo mạch, dây nối và cảm biến cơ bản.'),
    ('RASPBERRY-PI-KIT', N'Bộ kit Raspberry Pi', @kitCategoryId, 5, 1, N'/assets/images/equipment/raspberry-pi-kit.svg', N'Tủ IoT-04', N'Bộ kit Raspberry Pi phục vụ thực hành lập trình nhúng.'),
    ('DIGITAL-MULTIMETER', N'Đồng hồ vạn năng số', @measurementCategoryId, 5, 1, N'/assets/images/equipment/digital-multimeter.svg', N'Tủ đo lường-01', N'Đồng hồ vạn năng số dùng để đo điện áp, dòng điện và điện trở.'),
    ('WIRELESS-MOUSE', N'Chuột không dây', @computerAccessoryCategoryId, 5, 1, N'/assets/images/equipment/wireless-mouse.svg', N'Tủ phụ kiện-01', N'Chuột không dây dùng cho thực hành và trình bày.'),
    ('PRESENTATION-REMOTE', N'Bút trình chiếu không dây', @computerAccessoryCategoryId, 5, 1, N'/assets/images/equipment/presentation-remote.svg', N'Tủ phụ kiện-02', N'Bút trình chiếu không dây dùng trong các buổi báo cáo.');

UPDATE a SET a.status = 'UNAVAILABLE', a.is_borrowable = 0, a.updated_at = SYSUTCDATETIME()
FROM dbo.assets a WHERE NOT EXISTS (SELECT 1 FROM @targets t WHERE t.asset_code = a.asset_code);

UPDATE i SET i.status = 'UNAVAILABLE', i.updated_at = SYSUTCDATETIME()
FROM dbo.asset_items i JOIN dbo.assets a ON a.asset_id = i.asset_id
WHERE NOT EXISTS (SELECT 1 FROM @targets t WHERE t.asset_code = a.asset_code);

UPDATE a
SET a.asset_name = t.asset_name, a.category_id = t.category_id, a.tracking_mode = 'QUANTITY',
    a.serial_number = NULL, a.total_quantity = t.total_quantity, a.condition = 'GOOD',
    a.status = 'AVAILABLE', a.is_borrowable = t.is_borrowable, a.storage_location = t.storage_location,
    a.description = t.description, a.updated_at = SYSUTCDATETIME()
FROM dbo.assets a JOIN @targets t ON t.asset_code = a.asset_code;

INSERT dbo.assets
    (asset_code, asset_name, category_id, tracking_mode, serial_number, total_quantity,
     condition, status, is_borrowable, storage_location, description)
SELECT t.asset_code, t.asset_name, t.category_id, 'QUANTITY', NULL, t.total_quantity,
       'GOOD', 'AVAILABLE', t.is_borrowable, t.storage_location, t.description
FROM @targets t
WHERE NOT EXISTS (SELECT 1 FROM dbo.assets a WHERE a.asset_code = t.asset_code);

;WITH Numbers AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS item_number
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.asset_items (asset_id, item_code, serial_number, image_path, condition, status, is_borrowable, storage_location, note)
SELECT a.asset_id, CONCAT(t.asset_code, '-', RIGHT(CONCAT('0000', n.item_number), 4)),
       CONCAT(t.asset_code, '-SN-', RIGHT(CONCAT('0000', n.item_number), 4)), t.image_path,
       'GOOD', 'AVAILABLE', 1, t.storage_location, N'Tạo từ bộ dữ liệu LAB chuẩn hóa'
FROM @targets t JOIN dbo.assets a ON a.asset_code = t.asset_code
JOIN Numbers n ON n.item_number <= t.total_quantity
WHERE NOT EXISTS (SELECT 1 FROM dbo.asset_items i
                  WHERE i.item_code = CONCAT(t.asset_code, '-', RIGHT(CONCAT('0000', n.item_number), 4)));

UPDATE i SET i.serial_number = COALESCE(i.serial_number, CONCAT(t.asset_code, '-SN-', RIGHT(i.item_code, 4))),
    i.image_path = t.image_path, i.is_borrowable = 1, i.updated_at = SYSUTCDATETIME()
FROM dbo.asset_items i JOIN dbo.assets a ON a.asset_id = i.asset_id JOIN @targets t ON t.asset_code = a.asset_code;

UPDATE i SET i.status = 'UNAVAILABLE', i.updated_at = SYSUTCDATETIME()
FROM dbo.asset_items i JOIN dbo.assets a ON a.asset_id = i.asset_id JOIN @targets t ON t.asset_code = a.asset_code
WHERE TRY_CONVERT(int, RIGHT(i.item_code, 4)) > t.total_quantity;

COMMIT TRANSACTION;
GO

/* Five idempotent incident samples */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @asset_id bigint;
    DECLARE @usage_id bigint;
    DECLARE @reporter_id bigint;
    DECLARE @now datetime2(0) = SYSUTCDATETIME();

    SELECT TOP (1) @asset_id = au.asset_id, @usage_id = au.asset_usage_id, @reporter_id = sp.user_id
    FROM dbo.asset_usages au JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
    ORDER BY au.asset_usage_id DESC;
    IF @asset_id IS NULL SELECT TOP (1) @asset_id = asset_id FROM dbo.assets WHERE status <> 'DISPOSED' ORDER BY asset_id DESC;
    IF @reporter_id IS NULL SELECT TOP (1) @reporter_id = user_id FROM dbo.users WHERE status = 'ACTIVE' ORDER BY CASE role WHEN 'INTERN' THEN 0 ELSE 1 END, user_id;
    IF @asset_id IS NULL OR @reporter_id IS NULL THROW 50002, 'At least one active user and one non-disposed asset are required.', 1;

    INSERT dbo.incidents
        (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
         status, occurred_at, reported_at, investigation_note, handling_result)
    SELECT @asset_id, @usage_id, @reporter_id, 1, sample.incident_type, sample.description,
           sample.severity, sample.status, sample.occurred_at, sample.reported_at,
           sample.investigation_note, sample.handling_result
    FROM (VALUES
        ('MISSING', N'[SAMPLE] The equipment carrying case was not returned.', 'MEDIUM', 'OPEN', DATEADD(DAY, -5, @now), DATEADD(MINUTE, 30, DATEADD(DAY, -5, @now)), N'The return checklist is being reviewed.', CAST(NULL AS nvarchar(max))),
        ('OTHER', N'[SAMPLE] The calibration label became unreadable.', 'LOW', 'CLOSED', DATEADD(DAY, -4, @now), DATEADD(MINUTE, 45, DATEADD(DAY, -4, @now)), N'The calibration record was verified.', N'A replacement label was applied.'),
        ('MALFUNCTION', N'[SAMPLE] The display intermittently showed incomplete readings.', 'MEDIUM', 'INVESTIGATING', DATEADD(DAY, -3, @now), DATEADD(MINUTE, 20, DATEADD(DAY, -3, @now)), N'The battery and display connector require inspection.', NULL),
        ('DAMAGE', N'[SAMPLE] The protective cover was torn near the input terminals.', 'LOW', 'RESOLVED', DATEADD(DAY, -2, @now), DATEADD(MINUTE, 15, DATEADD(DAY, -2, @now)), N'The damage did not affect operational safety.', N'The protective cover was replaced.'),
        ('LOSS', N'[SAMPLE] The spare accessory set could not be located.', 'HIGH', 'OPEN', DATEADD(DAY, -1, @now), DATEADD(MINUTE, 30, DATEADD(DAY, -1, @now)), N'Inventory and recent usage records are being reviewed.', NULL)
    ) AS sample (incident_type, description, severity, status, occurred_at, reported_at, investigation_note, handling_result)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.incidents existing WHERE existing.description = sample.description);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Responsibility test data and lab-manager demo account */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'labmanager@gmail.com')
        INSERT dbo.users (full_name, email, password_hash, role, status)
        VALUES (N'Demo Mentor Test', 'labmanager@gmail.com', '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C', 'MENTOR', 'ACTIVE');

    IF NOT EXISTS (SELECT 1 FROM dbo.incidents WHERE description = N'[TEST] Incident awaiting responsibility determination.')
    BEGIN
        DECLARE @asset_id_test bigint;
        DECLARE @usage_id_test bigint;
        DECLARE @reporter_id_test bigint;
        DECLARE @request_id_test bigint;
        DECLARE @semester_id_test bigint;
        DECLARE @student_id_test bigint;

        SELECT TOP (1) @asset_id_test = au.asset_id, @usage_id_test = au.asset_usage_id, @reporter_id_test = sp.user_id
        FROM dbo.asset_usages au JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
        WHERE au.status = 'RETURNED' ORDER BY au.asset_usage_id DESC;

        IF @usage_id_test IS NULL
        BEGIN
            SELECT TOP (1) @request_id_test = rs.request_id, @semester_id_test = rs.semester_id,
                           @student_id_test = rs.student_id, @reporter_id_test = sp.user_id
            FROM dbo.lab_usage_request_students rs JOIN dbo.student_profiles sp ON sp.student_id = rs.student_id
            ORDER BY rs.request_id DESC;
            SELECT TOP (1) @asset_id_test = asset_id FROM dbo.assets WHERE status <> 'DISPOSED' ORDER BY asset_id DESC;
            IF @request_id_test IS NULL OR @asset_id_test IS NULL THROW 50001, 'An intern request membership and asset are required.', 1;
            INSERT dbo.asset_usages
                (request_id, semester_id, student_id, asset_id, quantity, borrowed_at, due_at, returned_at,
                 condition_before, condition_after, status, note, created_by)
            VALUES (@request_id_test, @semester_id_test, @student_id_test, @asset_id_test, 1,
                    DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -1, SYSUTCDATETIME()),
                    DATEADD(MINUTE, -30, SYSUTCDATETIME()), 'GOOD', 'DAMAGED', 'RETURNED',
                    N'[TEST] Returned usage for responsibility testing.', @reporter_id_test);
            SET @usage_id_test = SCOPE_IDENTITY();
        END;

        INSERT dbo.incidents
            (asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
             status, occurred_at, reported_at, investigation_note)
        VALUES (@asset_id_test, @usage_id_test, @reporter_id_test, 1, 'DAMAGE',
                N'[TEST] Incident awaiting responsibility determination.', 'MEDIUM', 'INVESTIGATING',
                DATEADD(MINUTE, -45, SYSUTCDATETIME()), SYSUTCDATETIME(),
                N'Ready for Mentor responsibility testing.');
    END;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* FE-11: semester-based intern equipment allocation. */
IF OBJECT_ID(N'dbo.equipment_activities', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.equipment_activities (
        activity_id bigint IDENTITY(1,1) NOT NULL,
        request_id bigint NOT NULL,
        mentor_id bigint NOT NULL,
        activity_name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL,
        start_date date NOT NULL,
        end_date date NOT NULL,
        status varchar(20) NOT NULL CONSTRAINT DF_equipment_activities_status DEFAULT ('ACTIVE'),
        created_at datetime2(0) NOT NULL CONSTRAINT DF_equipment_activities_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_equipment_activities_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_equipment_activities PRIMARY KEY (activity_id),
        CONSTRAINT UQ_equipment_activities_request_name UNIQUE (request_id, activity_name),
        CONSTRAINT FK_equipment_activities_request FOREIGN KEY (request_id) REFERENCES dbo.lab_usage_requests(request_id),
        CONSTRAINT FK_equipment_activities_mentor FOREIGN KEY (mentor_id) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_equipment_activities_status CHECK (status IN ('ACTIVE', 'CLOSED', 'CANCELLED')),
        CONSTRAINT CK_equipment_activities_dates CHECK (start_date <= end_date)
    );
    CREATE INDEX IX_equipment_activities_mentor ON dbo.equipment_activities (mentor_id, status);
    CREATE UNIQUE INDEX UX_equipment_activities_active_request ON dbo.equipment_activities (request_id)
        WHERE status = 'ACTIVE';
END;
GO

IF OBJECT_ID(N'dbo.equipment_groups', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.equipment_groups (
        allocation_group_id bigint IDENTITY(1,1) NOT NULL,
        activity_id bigint NOT NULL,
        group_name nvarchar(100) NOT NULL,
        leader_intern_id bigint NOT NULL,
        CONSTRAINT PK_equipment_groups PRIMARY KEY (allocation_group_id),
        CONSTRAINT UQ_equipment_groups_activity_name UNIQUE (activity_id, group_name),
        CONSTRAINT FK_equipment_groups_activity FOREIGN KEY (activity_id) REFERENCES dbo.equipment_activities(activity_id) ON DELETE CASCADE,
        CONSTRAINT FK_equipment_groups_leader FOREIGN KEY (leader_intern_id) REFERENCES dbo.student_profiles(student_id)
    );
    CREATE TABLE dbo.equipment_group_members (
        allocation_group_id bigint NOT NULL,
        intern_id bigint NOT NULL,
        CONSTRAINT PK_equipment_group_members PRIMARY KEY (allocation_group_id, intern_id),
        CONSTRAINT FK_equipment_group_members_group FOREIGN KEY (allocation_group_id) REFERENCES dbo.equipment_groups(allocation_group_id) ON DELETE CASCADE,
        CONSTRAINT FK_equipment_group_members_intern FOREIGN KEY (intern_id) REFERENCES dbo.student_profiles(student_id)
    );
END;
GO

IF OBJECT_ID(N'dbo.equipment_allocation_requests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.equipment_allocation_requests (
        allocation_request_id bigint IDENTITY(1,1) NOT NULL,
        activity_id bigint NOT NULL,
        allocation_group_id bigint NULL,
        intern_id bigint NULL,
        asset_id bigint NOT NULL,
        requested_quantity int NOT NULL,
        note nvarchar(500) NULL,
        status varchar(25) NOT NULL CONSTRAINT DF_equipment_allocation_requests_status DEFAULT ('PENDING_APPROVAL'),
        requested_by bigint NOT NULL,
        reviewed_by bigint NULL,
        reviewed_at datetime2(0) NULL,
        review_note nvarchar(500) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_equipment_allocation_requests_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_equipment_allocation_requests_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_equipment_allocation_requests PRIMARY KEY (allocation_request_id),
        CONSTRAINT FK_equipment_allocation_requests_activity FOREIGN KEY (activity_id) REFERENCES dbo.equipment_activities(activity_id),
        CONSTRAINT FK_equipment_allocation_requests_group FOREIGN KEY (allocation_group_id) REFERENCES dbo.equipment_groups(allocation_group_id),
        CONSTRAINT FK_equipment_allocation_requests_intern FOREIGN KEY (intern_id) REFERENCES dbo.student_profiles(student_id),
        CONSTRAINT FK_equipment_allocation_requests_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_equipment_allocation_requests_requester FOREIGN KEY (requested_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_equipment_allocation_requests_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_equipment_allocation_requests_target CHECK (
            (allocation_group_id IS NULL AND intern_id IS NULL)
            OR (allocation_group_id IS NOT NULL AND intern_id IS NULL)
            OR (allocation_group_id IS NULL AND intern_id IS NOT NULL)
        ),
        CONSTRAINT CK_equipment_allocation_requests_quantity CHECK (requested_quantity > 0),
        CONSTRAINT CK_equipment_allocation_requests_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED'))
    );
    CREATE INDEX IX_equipment_allocation_requests_status ON dbo.equipment_allocation_requests (status, activity_id);
    CREATE UNIQUE INDEX UX_equipment_allocation_requests_activity_asset
        ON dbo.equipment_allocation_requests (activity_id, asset_id);
END;
GO

IF OBJECT_ID(N'dbo.equipment_allocation_requests', N'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.equipment_allocation_requests') AND name = N'CK_equipment_allocation_requests_target')
        ALTER TABLE dbo.equipment_allocation_requests DROP CONSTRAINT CK_equipment_allocation_requests_target;
    ALTER TABLE dbo.equipment_allocation_requests ADD CONSTRAINT CK_equipment_allocation_requests_target CHECK ((allocation_group_id IS NULL AND intern_id IS NULL) OR (allocation_group_id IS NOT NULL AND intern_id IS NULL) OR (allocation_group_id IS NULL AND intern_id IS NOT NULL));
END;
GO

IF OBJECT_ID(N'dbo.equipment_allocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.equipment_allocations (
        allocation_id bigint IDENTITY(1,1) NOT NULL,
        allocation_request_id bigint NOT NULL,
        asset_item_id bigint NOT NULL,
        status varchar(25) NOT NULL CONSTRAINT DF_equipment_allocations_status DEFAULT ('READY_FOR_HANDOVER'),
        handed_over_by bigint NULL,
        handed_over_at datetime2(0) NULL,
        received_at datetime2(0) NULL,
        recovered_by bigint NULL,
        recovered_at datetime2(0) NULL,
        return_condition varchar(10) NULL,
        return_note nvarchar(500) NULL,
        CONSTRAINT PK_equipment_allocations PRIMARY KEY (allocation_id),
        CONSTRAINT FK_equipment_allocations_request FOREIGN KEY (allocation_request_id) REFERENCES dbo.equipment_allocation_requests(allocation_request_id),
        CONSTRAINT FK_equipment_allocations_item FOREIGN KEY (asset_item_id) REFERENCES dbo.asset_items(asset_item_id),
        CONSTRAINT FK_equipment_allocations_handover FOREIGN KEY (handed_over_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_equipment_allocations_recovery FOREIGN KEY (recovered_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_equipment_allocations_status CHECK (status IN ('READY_FOR_HANDOVER', 'ACTIVE', 'ISSUE_REPORTED', 'RETURNED')),
        CONSTRAINT CK_equipment_allocations_condition CHECK (return_condition IS NULL OR return_condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN'))
    );
    CREATE UNIQUE INDEX UX_equipment_allocations_active_item ON dbo.equipment_allocations (asset_item_id)
        WHERE status IN ('READY_FOR_HANDOVER', 'ACTIVE', 'ISSUE_REPORTED');
END;
GO

IF OBJECT_ID(N'dbo.equipment_allocation_issue_reports', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.equipment_allocation_issue_reports (
        issue_report_id bigint IDENTITY(1,1) NOT NULL,
        allocation_id bigint NOT NULL,
        reported_by bigint NOT NULL,
        issue_type varchar(20) NOT NULL,
        description nvarchar(1000) NOT NULL,
        image_path nvarchar(500) NULL,
        status varchar(20) NOT NULL CONSTRAINT DF_equipment_issue_reports_status DEFAULT ('PENDING_MENTOR'),
        mentor_note nvarchar(500) NULL,
        incident_id bigint NULL,
        reviewed_by bigint NULL,
        reviewed_at datetime2(0) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_equipment_issue_reports_created_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_equipment_allocation_issue_reports PRIMARY KEY (issue_report_id),
        CONSTRAINT FK_equipment_issue_reports_allocation FOREIGN KEY (allocation_id) REFERENCES dbo.equipment_allocations(allocation_id),
        CONSTRAINT FK_equipment_issue_reports_reporter FOREIGN KEY (reported_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_equipment_issue_reports_incident FOREIGN KEY (incident_id) REFERENCES dbo.incidents(incident_id),
        CONSTRAINT FK_equipment_issue_reports_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_equipment_issue_reports_type CHECK (issue_type IN ('DAMAGE', 'LOSS', 'MISSING_COMPONENT')),
        CONSTRAINT CK_equipment_issue_reports_status CHECK (status IN ('PENDING_MENTOR', 'VERIFIED', 'REJECTED'))
    );
END;
GO

/* FPT Google accounts used by the project team for Intern flow testing. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @fptSemesterId bigint;
    DECLARE @fptRequestId bigint;
    DECLARE @fptMentorId bigint;

    IF NOT EXISTS (SELECT 1 FROM dbo.semesters WHERE code = 'DEMO-2026')
        INSERT dbo.semesters (code, name, start_date, end_date, status)
        VALUES ('DEMO-2026', N'Demo 2026', '2026-01-01', '2026-12-31', 'ACTIVE');
    SELECT @fptSemesterId = semester_id FROM dbo.semesters WHERE code = 'DEMO-2026';
    SELECT TOP (1) @fptMentorId = user_id FROM dbo.users WHERE role = 'MENTOR' AND status = 'ACTIVE' ORDER BY user_id;

    DECLARE @fptInterns TABLE (full_name nvarchar(100), email varchar(255), student_code varchar(30));
    INSERT @fptInterns (full_name, email, student_code) VALUES
        (N'Nguyễn Minh Anh', 'anhnmhe171286@fpt.edu.vn', 'HE171286'),
        (N'Nguyễn Đức Trung', 'trungndhe180362@fpt.edu.vn', 'HE180362'),
        (N'Từ Minh Đức', 'ductmhe180875@fpt.edu.vn', 'HE180875'),
        (N'Trần Bình Minh', 'minhtbhe186275@fpt.edu.vn', 'HE186275'),
        (N'Lương Anh Minh', 'minhlahe180101@fpt.edu.vn', 'HE180101');

    INSERT dbo.users (full_name, email, password_hash, role, status)
    SELECT source.full_name, source.email, NULL, 'INTERN', 'ACTIVE'
    FROM @fptInterns source WHERE NOT EXISTS (SELECT 1 FROM dbo.users existing WHERE existing.email = source.email);

    INSERT dbo.student_profiles (user_id, student_code, cohort, status)
    SELECT account.user_id, source.student_code, 'K18', 'ACTIVE'
    FROM @fptInterns source JOIN dbo.users account ON account.email = source.email
    WHERE NOT EXISTS (SELECT 1 FROM dbo.student_profiles profile WHERE profile.user_id = account.user_id OR profile.student_code = source.student_code);

    IF NOT EXISTS (SELECT 1 FROM dbo.lab_usage_requests WHERE semester_id = @fptSemesterId)
        INSERT dbo.lab_usage_requests
            (semester_id, mentor_id, group_name, status, request_note, approved_by, approved_at, approval_note)
        VALUES (@fptSemesterId, @fptMentorId, N'DEMO-2026 Intern List', 'APPROVED',
                N'Danh sách tài khoản FPT dùng kiểm thử Google OAuth.', @fptMentorId, SYSUTCDATETIME(), N'Dữ liệu demo.');
    SELECT @fptRequestId = request_id FROM dbo.lab_usage_requests WHERE semester_id = @fptSemesterId;

    INSERT dbo.lab_usage_request_student_entries (request_id, semester_id, student_code, full_name, email, cohort)
    SELECT @fptRequestId, @fptSemesterId, source.student_code, source.full_name, source.email, 'K18'
    FROM @fptInterns source
    WHERE NOT EXISTS (SELECT 1 FROM dbo.lab_usage_request_student_entries entry
                      WHERE entry.request_id = @fptRequestId AND (entry.student_code = source.student_code OR entry.email = source.email));

    INSERT dbo.lab_usage_request_students (request_id, semester_id, student_id)
    SELECT @fptRequestId, @fptSemesterId, profile.student_id
    FROM @fptInterns source JOIN dbo.users account ON account.email = source.email
    JOIN dbo.student_profiles profile ON profile.user_id = account.user_id
    WHERE NOT EXISTS (SELECT 1 FROM dbo.lab_usage_request_students member
                      WHERE member.request_id = @fptRequestId AND member.student_id = profile.student_id);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* ========================================================================
   DEMO-READY FIXTURE
   Replaces the small migration-era samples with one coherent LAB dataset.
   Every implemented module has realistic history plus actionable records.
   Dates are relative so a fresh setup remains usable in future semesters.
   ======================================================================== */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM dbo.equipment_allocation_issue_reports;
    DELETE FROM dbo.equipment_allocations;
    DELETE FROM dbo.equipment_allocation_requests;
    DELETE FROM dbo.equipment_group_members;
    DELETE FROM dbo.equipment_groups;
    DELETE FROM dbo.equipment_activities;
    DELETE FROM dbo.password_reset_requests;
    DELETE FROM dbo.disposal_records;
    DELETE FROM dbo.maintenance_records;
    DELETE FROM dbo.responsibilities;
    DELETE FROM dbo.incidents;
    DELETE FROM dbo.inspection_items;
    DELETE FROM dbo.inspection_records;
    DELETE FROM dbo.asset_usages;
    DELETE FROM dbo.asset_items;
    DELETE FROM dbo.assets;
    DELETE FROM dbo.asset_categories;
    DELETE FROM dbo.lab_usage_request_student_entries;
    DELETE FROM dbo.lab_usage_request_students;
    DELETE FROM dbo.lab_usage_requests;
    DELETE FROM dbo.semesters;
    DELETE FROM dbo.student_profiles;
    DELETE FROM dbo.users;

    DECLARE @now datetime2(0) = SYSUTCDATETIME();
    DECLARE @today date = CONVERT(date, @now);
    DECLARE @passwordHash varchar(255) = '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C';

    INSERT dbo.users (full_name, email, password_hash, role, status)
    VALUES
        (N'Nguyễn Hoài An', 'admin@gmail.com', @passwordHash, 'ADMIN', 'ACTIVE'),
        (N'Trần Quốc Huy', 'manager@gmail.com', @passwordHash, 'LAB_MANAGER', 'ACTIVE'),
        (N'Lê Thu Hà', 'mentor@gmail.com', @passwordHash, 'MENTOR', 'ACTIVE'),
        (N'Phạm Minh Quân', 'mentor.ops@gmail.com', @passwordHash, 'MENTOR', 'ACTIVE'),
        (N'Đặng Ngọc Lan', 'inactive.manager@gmail.com', @passwordHash, 'LAB_MANAGER', 'INACTIVE'),
        (N'Nguyễn Minh Anh', 'anhnmhe171286@fpt.edu.vn', NULL, 'INTERN', 'ACTIVE'),
        (N'Nguyễn Đức Trung', 'trungndhe180362@fpt.edu.vn', NULL, 'INTERN', 'ACTIVE'),
        (N'Từ Minh Đức', 'ductmhe180875@fpt.edu.vn', NULL, 'INTERN', 'ACTIVE'),
        (N'Trần Bình Minh', 'minhtbhe186275@fpt.edu.vn', NULL, 'INTERN', 'ACTIVE'),
        (N'Lương Anh Minh', 'minhlahe180101@fpt.edu.vn', NULL, 'INTERN', 'ACTIVE'),
        (N'Bùi Gia Hân', 'hanbghe180999@fpt.edu.vn', NULL, 'INTERN', 'INACTIVE');

    DECLARE @admin bigint = (SELECT user_id FROM dbo.users WHERE email='admin@gmail.com');
    DECLARE @manager bigint = (SELECT user_id FROM dbo.users WHERE email='manager@gmail.com');
    DECLARE @mentor bigint = (SELECT user_id FROM dbo.users WHERE email='mentor@gmail.com');
    DECLARE @mentorOps bigint = (SELECT user_id FROM dbo.users WHERE email='mentor.ops@gmail.com');
    DECLARE @anh bigint = (SELECT user_id FROM dbo.users WHERE email='anhnmhe171286@fpt.edu.vn');
    DECLARE @trung bigint = (SELECT user_id FROM dbo.users WHERE email='trungndhe180362@fpt.edu.vn');
    DECLARE @duc bigint = (SELECT user_id FROM dbo.users WHERE email='ductmhe180875@fpt.edu.vn');
    DECLARE @minh bigint = (SELECT user_id FROM dbo.users WHERE email='minhtbhe186275@fpt.edu.vn');
    DECLARE @luong bigint = (SELECT user_id FROM dbo.users WHERE email='minhlahe180101@fpt.edu.vn');
    DECLARE @han bigint = (SELECT user_id FROM dbo.users WHERE email='hanbghe180999@fpt.edu.vn');

    INSERT dbo.student_profiles (user_id, student_code, major_id, cohort, status)
    VALUES
        (@anh, 'HE171286', (SELECT major_id FROM dbo.majors WHERE major_code='SE'), 'K17', 'ACTIVE'),
        (@trung, 'HE180362', (SELECT major_id FROM dbo.majors WHERE major_code='AI'), 'K18', 'ACTIVE'),
        (@duc, 'HE180875', (SELECT major_id FROM dbo.majors WHERE major_code='SE'), 'K18', 'ACTIVE'),
        (@minh, 'HE186275', (SELECT major_id FROM dbo.majors WHERE major_code='IS'), 'K18', 'ACTIVE'),
        (@luong, 'HE180101', (SELECT major_id FROM dbo.majors WHERE major_code='IA'), 'K18', 'ACTIVE'),
        (@han, 'HE180999', (SELECT major_id FROM dbo.majors WHERE major_code='SE'), 'K18', 'INACTIVE');

    DECLARE @anhStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id=@anh);
    DECLARE @trungStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id=@trung);
    DECLARE @ducStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id=@duc);
    DECLARE @minhStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id=@minh);
    DECLARE @luongStudent bigint = (SELECT student_id FROM dbo.student_profiles WHERE user_id=@luong);

    INSERT dbo.semesters (code, name, start_date, end_date, status)
    VALUES
        ('DEMO-ACTIVE', N'Kỳ thực tập hiện tại', DATEADD(DAY,-45,@today), DATEADD(DAY,75,@today), 'ACTIVE'),
        ('DEMO-NEXT', N'Kỳ thực tập kế tiếp', DATEADD(DAY,90,@today), DATEADD(DAY,180,@today), 'UPCOMING'),
        ('DEMO-CLOSED', N'Kỳ thực tập đã kết thúc', DATEADD(DAY,-210,@today), DATEADD(DAY,-90,@today), 'CLOSED');
    DECLARE @activeSemester bigint = (SELECT semester_id FROM dbo.semesters WHERE code='DEMO-ACTIVE');
    DECLARE @nextSemester bigint = (SELECT semester_id FROM dbo.semesters WHERE code='DEMO-NEXT');
    DECLARE @closedSemester bigint = (SELECT semester_id FROM dbo.semesters WHERE code='DEMO-CLOSED');

    INSERT dbo.lab_usage_requests
        (semester_id, mentor_id, group_name, status, request_note, approved_by, approved_at, approval_note, created_at)
    VALUES
        (@activeSemester,@mentor,N'Nhóm IoT K18 - Smart Garden','APPROVED',N'Nhóm phát triển hệ thống giám sát nhà kính thông minh.',@admin,DATEADD(DAY,-43,@now),N'Đủ hồ sơ, phạm vi sử dụng LAB phù hợp.',DATEADD(DAY,-44,@now)),
        (@nextSemester,@mentor,N'Nhóm Embedded K19 - Robot vận chuyển','PENDING',N'Danh sách dự kiến cho dự án robot tự hành.',NULL,NULL,NULL,DATEADD(DAY,-2,@now)),
        (@closedSemester,@mentorOps,N'Nhóm Robotics K17 - Kho thông minh','REJECTED',N'Danh sách bổ sung sau thời hạn đăng ký.',@admin,DATEADD(DAY,-205,@now),N'Từ chối vì nộp sau thời hạn và thiếu xác nhận môn học.',DATEADD(DAY,-208,@now));
    DECLARE @activeRequest bigint = (SELECT request_id FROM dbo.lab_usage_requests WHERE semester_id=@activeSemester);
    DECLARE @nextRequest bigint = (SELECT request_id FROM dbo.lab_usage_requests WHERE semester_id=@nextSemester);
    DECLARE @closedRequest bigint = (SELECT request_id FROM dbo.lab_usage_requests WHERE semester_id=@closedSemester);

    INSERT dbo.lab_usage_request_student_entries (request_id,semester_id,student_code,full_name,email,cohort)
    VALUES
        (@activeRequest,@activeSemester,'HE171286',N'Nguyễn Minh Anh','anhnmhe171286@fpt.edu.vn','K17'),
        (@activeRequest,@activeSemester,'HE180362',N'Nguyễn Đức Trung','trungndhe180362@fpt.edu.vn','K18'),
        (@activeRequest,@activeSemester,'HE180875',N'Từ Minh Đức','ductmhe180875@fpt.edu.vn','K18'),
        (@activeRequest,@activeSemester,'HE186275',N'Trần Bình Minh','minhtbhe186275@fpt.edu.vn','K18'),
        (@activeRequest,@activeSemester,'HE180101',N'Lương Anh Minh','minhlahe180101@fpt.edu.vn','K18'),
        (@nextRequest,@nextSemester,'HE190201',N'Vũ Hải Nam','namvhhe190201@fpt.edu.vn','K19'),
        (@nextRequest,@nextSemester,'HE190245',N'Hoàng Ngọc Mai','maihnhe190245@fpt.edu.vn','K19'),
        (@closedRequest,@closedSemester,'HE170112',N'Đặng Anh Dũng','dungdahe170112@fpt.edu.vn','K17');
    INSERT dbo.lab_usage_request_students (request_id,semester_id,student_id)
    VALUES
        (@activeRequest,@activeSemester,@anhStudent),(@activeRequest,@activeSemester,@trungStudent),
        (@activeRequest,@activeSemester,@ducStudent),(@activeRequest,@activeSemester,@minhStudent),
        (@activeRequest,@activeSemester,@luongStudent);

    INSERT dbo.asset_categories (category_name,description,status)
    VALUES
        (N'Kit vi điều khiển',N'Bo mạch và bộ kit phục vụ lập trình nhúng.','ACTIVE'),
        (N'Thiết bị đo lường',N'Thiết bị đo điện, kiểm tra tín hiệu và hiệu chuẩn.','ACTIVE'),
        (N'Máy tính và phụ kiện',N'Máy tính nhúng, chuột, webcam và phụ kiện trình chiếu.','ACTIVE'),
        (N'Dụng cụ điện tử',N'Trạm hàn, đầu dò và dụng cụ sửa chữa phần cứng.','ACTIVE'),
        (N'Thiết bị cố định',N'Thiết bị lắp đặt cố định trong phòng LAB.','ACTIVE'),
        (N'Linh kiện tiêu hao',N'Dây nối, cảm biến và linh kiện quản lý theo số lượng.','ACTIVE');
    DECLARE @catKit bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Kit vi điều khiển');
    DECLARE @catMeasure bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Thiết bị đo lường');
    DECLARE @catComputer bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Máy tính và phụ kiện');
    DECLARE @catTool bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Dụng cụ điện tử');
    DECLARE @catFixed bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Thiết bị cố định');
    DECLARE @catConsumable bigint=(SELECT category_id FROM dbo.asset_categories WHERE category_name=N'Linh kiện tiêu hao');

    INSERT dbo.assets (asset_code,asset_name,category_id,tracking_mode,total_quantity,condition,status,is_borrowable,storage_location,description,created_at)
    VALUES
        ('ARD-UNO-R3',N'Bộ kit Arduino Uno R3',@catKit,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ IoT A1',N'Kit cá nhân gồm Arduino Uno, breadboard, dây USB và bộ dây jumper.',DATEADD(DAY,-420,@now)),
        ('RPI4-4GB',N'Raspberry Pi 4 Model B 4GB',@catComputer,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ IoT A2',N'Máy tính nhúng dùng cho gateway và xử lý ảnh biên.',DATEADD(DAY,-380,@now)),
        ('DMM-AN8008',N'Đồng hồ vạn năng ANENG AN8008',@catMeasure,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ đo lường B1',N'Đồng hồ True RMS kèm que đo và túi bảo vệ.',DATEADD(DAY,-350,@now)),
        ('MOUSE-M331',N'Chuột không dây Logitech M331',@catComputer,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ phụ kiện C1',N'Chuột không dây dùng cùng laptop trình bày.',DATEADD(DAY,-300,@now)),
        ('RPI3-LEGACY',N'Raspberry Pi 3 Model B đời cũ',@catComputer,'SERIALIZED',1,'BROKEN','DISPOSED',0,N'Kho thanh lý',N'Thiết bị lịch sử đã hỏng nguồn và hoàn tất thanh lý.',DATEADD(DAY,-900,@now)),
        ('REMOTE-R400',N'Bút trình chiếu Logitech R400',@catComputer,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ phụ kiện C2',N'Bút trình chiếu dùng cho nghiệm thu sprint.',DATEADD(DAY,-240,@now)),
        ('PROJECTOR-EBX06',N'Máy chiếu Epson EB-X06',@catFixed,'SERIALIZED',1,'BROKEN','UNAVAILABLE',0,N'Phòng LAB - trần khu A',N'Máy chiếu cố định, bóng đèn suy giảm và lỗi nguồn.',DATEADD(DAY,-1200,@now)),
        ('OSC-PROBE-10X',N'Đầu dò oscilloscope Hantek 10X',@catMeasure,'SERIALIZED',1,'DAMAGED','UNAVAILABLE',1,N'Tủ đo lường B2',N'Đầu dò 100 MHz, đầu kẹp mass bị lỏng.',DATEADD(DAY,-260,@now)),
        ('SOLDER-936',N'Trạm hàn Hakko 936',@catTool,'SERIALIZED',1,'DAMAGED','AVAILABLE',0,N'Bàn sửa chữa D1',N'Trạm hàn dùng sửa mạch, cảm biến nhiệt đang sai lệch.',DATEADD(DAY,-700,@now)),
        ('TABLET-GALAXY-A',N'Máy tính bảng Galaxy Tab A 2019',@catComputer,'SERIALIZED',1,'BROKEN','UNAVAILABLE',0,N'Kho chờ xử lý',N'Màn hình nứt, pin phồng, không còn an toàn sử dụng.',DATEADD(DAY,-1000,@now)),
        ('WEBCAM-C920',N'Webcam Logitech C920',@catComputer,'SERIALIZED',1,'GOOD','AVAILABLE',1,N'Tủ phụ kiện C3',N'Webcam Full HD dùng họp trực tuyến và nhận diện hình ảnh.',DATEADD(DAY,-180,@now)),
        ('ARD-CLASS-SET',N'Bộ Arduino thực hành theo nhóm',@catKit,'QUANTITY',3,'GOOD','AVAILABLE',1,N'Kệ lớp học A3',N'Ba bộ kit đồng nhất cấp theo nhóm thực tập.',DATEADD(DAY,-330,@now)),
        ('SENSOR-ENV-SET',N'Bộ cảm biến môi trường',@catConsumable,'QUANTITY',2,'DAMAGED','MAINTENANCE',1,N'Tủ IoT A4',N'Bộ DHT22, cảm biến ánh sáng và độ ẩm đất.',DATEADD(DAY,-200,@now)),
        ('JUMPER-65',N'Bộ dây jumper 65 sợi',@catConsumable,'QUANTITY',20,'GOOD','AVAILABLE',1,N'Khay linh kiện E1',N'Dây đực-đực, đực-cái và cái-cái quản lý theo số lượng.',DATEADD(DAY,-150,@now)),
        ('LAB-PROJECTOR',N'Máy chiếu Epson EB-E01',@catFixed,'SERIALIZED',1,'GOOD','AVAILABLE',0,N'Phòng LAB - trần khu B',N'Thiết bị cố định phục vụ giảng dạy và demo.',DATEADD(DAY,-500,@now));

    DECLARE @asset TABLE(code varchar(50) PRIMARY KEY,id bigint);
    INSERT @asset SELECT asset_code,asset_id FROM dbo.assets;
    INSERT dbo.asset_items (asset_id,item_code,serial_number,image_path,condition,status,is_borrowable,storage_location,purchase_date,warranty_until,note,created_at)
    VALUES
        ((SELECT id FROM @asset WHERE code='ARD-UNO-R3'),'ARD-UNO-R3-001','VN-ARD-2025-001',N'/assets/images/equipment/arduino-uno-kit.svg','GOOD','AVAILABLE',1,N'Tủ IoT A1',DATEADD(DAY,-420,@today),DATEADD(DAY,310,@today),N'Đủ 28 linh kiện, sẵn sàng cho mượn live.',DATEADD(DAY,-420,@now)),
        ((SELECT id FROM @asset WHERE code='RPI4-4GB'),'RPI4-4GB-001','10000000A7C91F2B',N'/assets/images/equipment/raspberry-pi-kit.svg','GOOD','IN_USE',1,N'Tủ IoT A2',DATEADD(DAY,-380,@today),DATEADD(DAY,-15,@today),N'Kèm nguồn USB-C 5V/3A và thẻ nhớ 64GB.',DATEADD(DAY,-380,@now)),
        ((SELECT id FROM @asset WHERE code='DMM-AN8008'),'DMM-AN8008-001','AN8-VN-2403158',N'/assets/images/equipment/digital-multimeter.svg','GOOD','IN_USE',1,N'Tủ đo lường B1',DATEADD(DAY,-350,@today),DATEADD(DAY,15,@today),N'Đã hiệu chuẩn gần nhất ba tháng trước.',DATEADD(DAY,-350,@now)),
        ((SELECT id FROM @asset WHERE code='MOUSE-M331'),'MOUSE-M331-001','M331-24-88721',N'/assets/images/equipment/wireless-mouse.svg','GOOD','IN_USE',1,N'Tủ phụ kiện C1',DATEADD(DAY,-300,@today),NULL,N'Đã thay pin trước khi bàn giao.',DATEADD(DAY,-300,@now)),
        ((SELECT id FROM @asset WHERE code='RPI3-LEGACY'),'RPI3-LEGACY-001','000000008F32BC11',N'/assets/images/equipment/raspberry-pi-kit.svg','BROKEN','DISPOSED',0,N'Kho thanh lý',DATEADD(DAY,-900,@today),NULL,N'Đã tháo thẻ nhớ, hoàn tất bàn giao rác thải điện tử.',DATEADD(DAY,-900,@now)),
        ((SELECT id FROM @asset WHERE code='REMOTE-R400'),'REMOTE-R400-001','R400-VN-55102',N'/assets/images/equipment/presentation-remote.svg','GOOD','UNAVAILABLE',1,N'Tủ phụ kiện C2',DATEADD(DAY,-240,@today),DATEADD(DAY,125,@today),N'Đã gán trực tiếp, chờ Intern xác nhận nhận.',DATEADD(DAY,-240,@now)),
        ((SELECT id FROM @asset WHERE code='PROJECTOR-EBX06'),'PROJECTOR-EBX06-001','X6KJ012948',NULL,'BROKEN','UNAVAILABLE',0,N'Phòng LAB - trần khu A',DATEADD(DAY,-1200,@today),NULL,N'Đang chờ Lab Manager duyệt đề xuất thanh lý.',DATEADD(DAY,-1200,@now)),
        ((SELECT id FROM @asset WHERE code='OSC-PROBE-10X'),'OSC-PROBE-10X-001','HT-P6100-2407',N'/assets/images/equipment/digital-multimeter.svg','DAMAGED','UNAVAILABLE',1,N'Tủ đo lường B2',DATEADD(DAY,-260,@today),DATEADD(DAY,105,@today),N'Đang chờ duyệt phiếu bảo trì.',DATEADD(DAY,-260,@now)),
        ((SELECT id FROM @asset WHERE code='SOLDER-936'),'SOLDER-936-001','HK936-19-00482',NULL,'DAMAGED','MAINTENANCE',0,N'Bàn sửa chữa D1',DATEADD(DAY,-700,@today),NULL,N'Đang thay cảm biến nhiệt và kiểm tra tiếp địa.',DATEADD(DAY,-700,@now)),
        ((SELECT id FROM @asset WHERE code='TABLET-GALAXY-A'),'TABLET-GALAXY-A-001','R9MMA02K7TT',NULL,'BROKEN','UNAVAILABLE',0,N'Kho chờ xử lý',DATEADD(DAY,-1000,@today),NULL,N'Đề xuất thanh lý đã được duyệt, chờ bàn giao.',DATEADD(DAY,-1000,@now)),
        ((SELECT id FROM @asset WHERE code='WEBCAM-C920'),'WEBCAM-C920-001','C920-2238LZA',NULL,'GOOD','AVAILABLE',1,N'Tủ phụ kiện C3',DATEADD(DAY,-180,@today),DATEADD(DAY,185,@today),N'Dành cho live demo tạo yêu cầu cấp phát.',DATEADD(DAY,-180,@now)),
        ((SELECT id FROM @asset WHERE code='ARD-CLASS-SET'),'ARD-CLASS-SET-001','ARD-GRP-001',N'/assets/images/equipment/arduino-uno-kit.svg','GOOD','IN_USE',1,N'Kệ lớp học A3',DATEADD(DAY,-330,@today),NULL,N'Đang cấp cho nhóm Smart Garden.',DATEADD(DAY,-330,@now)),
        ((SELECT id FROM @asset WHERE code='ARD-CLASS-SET'),'ARD-CLASS-SET-002','ARD-GRP-002',N'/assets/images/equipment/arduino-uno-kit.svg','GOOD','AVAILABLE',1,N'Kệ lớp học A3',DATEADD(DAY,-330,@today),NULL,N'Bộ dự phòng số 1.',DATEADD(DAY,-330,@now)),
        ((SELECT id FROM @asset WHERE code='ARD-CLASS-SET'),'ARD-CLASS-SET-003','ARD-GRP-003',N'/assets/images/equipment/arduino-uno-kit.svg','FAIR','AVAILABLE',1,N'Kệ lớp học A3',DATEADD(DAY,-330,@today),NULL,N'Bộ dự phòng số 2, hộp có vết xước nhẹ.',DATEADD(DAY,-330,@now)),
        ((SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),'SENSOR-ENV-SET-001','ENV-GRP-001',N'/assets/images/equipment/raspberry-pi-kit.svg','DAMAGED','MAINTENANCE',1,N'Tủ IoT A4',DATEADD(DAY,-200,@today),DATEADD(DAY,165,@today),N'Cảm biến độ ẩm đất trả giá trị không ổn định.',DATEADD(DAY,-200,@now)),
        ((SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),'SENSOR-ENV-SET-002','ENV-GRP-002',N'/assets/images/equipment/raspberry-pi-kit.svg','GOOD','AVAILABLE',1,N'Tủ IoT A4',DATEADD(DAY,-200,@today),DATEADD(DAY,165,@today),N'Bộ dự phòng đầy đủ.',DATEADD(DAY,-200,@now)),
        ((SELECT id FROM @asset WHERE code='LAB-PROJECTOR'),'LAB-PROJECTOR-001','EBE01-X9K22018',NULL,'GOOD','AVAILABLE',0,N'Phòng LAB - trần khu B',DATEADD(DAY,-500,@today),DATEADD(DAY,-135,@today),N'Tài sản cố định, không hiển thị trong luồng mượn.',DATEADD(DAY,-500,@now));

    DECLARE @item TABLE(code varchar(70) PRIMARY KEY,id bigint,asset_id bigint);
    INSERT @item SELECT item_code,asset_item_id,asset_id FROM dbo.asset_items;

    INSERT dbo.asset_usages
        (request_id,semester_id,student_id,asset_id,asset_item_id,quantity,borrowed_at,due_at,returned_at,
         condition_before,condition_after,reported_condition_after,return_requested_at,verified_condition_after,
         return_verified_at,return_verified_by,status,note,return_note,created_by,created_at,updated_at)
    VALUES
        (@activeRequest,@activeSemester,@anhStudent,(SELECT asset_id FROM @item WHERE code='RPI4-4GB-001'),(SELECT id FROM @item WHERE code='RPI4-4GB-001'),1,DATEADD(DAY,-6,@now),DATEADD(DAY,-1,@now),NULL,'GOOD',NULL,NULL,NULL,NULL,NULL,NULL,'IN_USE',N'Chạy gateway MQTT và dashboard thu thập dữ liệu.',NULL,@anh,DATEADD(DAY,-6,@now),DATEADD(DAY,-6,@now)),
        (@activeRequest,@activeSemester,@trungStudent,(SELECT asset_id FROM @item WHERE code='DMM-AN8008-001'),(SELECT id FROM @item WHERE code='DMM-AN8008-001'),1,DATEADD(DAY,-3,@now),DATEADD(DAY,1,@now),NULL,'GOOD',NULL,'GOOD',DATEADD(HOUR,-5,@now),NULL,NULL,NULL,'RETURN_PENDING',N'Đo nguồn 5V và kiểm tra dòng tiêu thụ của cảm biến.',N'Đã vệ sinh que đo, thiết bị hoạt động bình thường.',@trung,DATEADD(DAY,-3,@now),DATEADD(HOUR,-5,@now)),
        (@activeRequest,@activeSemester,@ducStudent,(SELECT asset_id FROM @item WHERE code='MOUSE-M331-001'),(SELECT id FROM @item WHERE code='MOUSE-M331-001'),1,DATEADD(DAY,-2,@now),DATEADD(DAY,1,@now),NULL,'GOOD',NULL,'FAIR',DATEADD(HOUR,-3,@now),NULL,NULL,NULL,'RETURN_PENDING',N'Dùng cùng laptop để trình bày sprint review.',N'Con lăn đôi lúc phản hồi chậm.',@duc,DATEADD(DAY,-2,@now),DATEADD(HOUR,-3,@now)),
        (@activeRequest,@activeSemester,@minhStudent,(SELECT asset_id FROM @item WHERE code='ARD-UNO-R3-001'),(SELECT id FROM @item WHERE code='ARD-UNO-R3-001'),1,DATEADD(DAY,-18,@now),DATEADD(DAY,-14,@now),DATEADD(DAY,-15,@now),'GOOD','GOOD','GOOD',DATEADD(HOUR,20,DATEADD(DAY,-16,@now)),'GOOD',DATEADD(DAY,-15,@now),@mentor,'RETURNED',N'Lập trình bộ điều khiển tưới tự động.',N'Đủ linh kiện, không phát hiện hư hỏng.',@minh,DATEADD(DAY,-18,@now),DATEADD(DAY,-15,@now)),
        (@activeRequest,@activeSemester,@luongStudent,(SELECT asset_id FROM @item WHERE code='RPI3-LEGACY-001'),(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'),1,DATEADD(DAY,-85,@now),DATEADD(DAY,-78,@now),DATEADD(DAY,-79,@now),'FAIR','BROKEN','DAMAGED',DATEADD(DAY,-80,@now),'BROKEN',DATEADD(DAY,-79,@now),@mentor,'RETURNED',N'Dùng thử nghiệm gateway dự phòng cho hệ thống cũ.',N'Không khởi động; đèn nguồn nhấp nháy bất thường.',@luong,DATEADD(DAY,-85,@now),DATEADD(DAY,-79,@now));

    DECLARE @usageRpi4 bigint=(SELECT asset_usage_id FROM dbo.asset_usages WHERE asset_item_id=(SELECT id FROM @item WHERE code='RPI4-4GB-001'));
    DECLARE @usageDmm bigint=(SELECT asset_usage_id FROM dbo.asset_usages WHERE asset_item_id=(SELECT id FROM @item WHERE code='DMM-AN8008-001'));
    DECLARE @usageMouse bigint=(SELECT asset_usage_id FROM dbo.asset_usages WHERE asset_item_id=(SELECT id FROM @item WHERE code='MOUSE-M331-001'));
    DECLARE @usageArduino bigint=(SELECT asset_usage_id FROM dbo.asset_usages WHERE asset_item_id=(SELECT id FROM @item WHERE code='ARD-UNO-R3-001'));
    DECLARE @usageLegacy bigint=(SELECT asset_usage_id FROM dbo.asset_usages WHERE asset_item_id=(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'));

    INSERT dbo.inspection_records (semester_id,inspected_by,inspection_type,scope,inspection_date,status,result,note,created_at)
    VALUES
        (@activeSemester,@manager,'INSPECTION','SELECTED_ASSETS',DATEADD(DAY,-20,@now),'COMPLETED','NORMAL',N'Kiểm tra trước khi bàn giao thiết bị cho sprint mới.',DATEADD(DAY,-20,@now)),
        (@activeSemester,@manager,'INVENTORY','WHOLE_LAB',DATEADD(DAY,-8,@now),'COMPLETED','DISCREPANCY_FOUND',N'Kiểm kê giữa kỳ, phát hiện thiếu dây jumper và một cảm biến lỗi.',DATEADD(DAY,-8,@now)),
        (@activeSemester,@manager,'INSPECTION','SELECTED_ASSETS',DATEADD(DAY,2,@now),'DRAFT',NULL,N'Bản nháp tái kiểm tra các thiết bị chờ xử lý.',@now);
    DECLARE @insNormal bigint=(SELECT inspection_id FROM dbo.inspection_records WHERE result='NORMAL');
    DECLARE @insDiff bigint=(SELECT inspection_id FROM dbo.inspection_records WHERE result='DISCREPANCY_FOUND');
    DECLARE @insDraft bigint=(SELECT inspection_id FROM dbo.inspection_records WHERE status='DRAFT');
    INSERT dbo.inspection_items (inspection_id,asset_id,expected_quantity,actual_quantity,expected_condition,actual_condition,discrepancy_type,discrepancy_note)
    VALUES
        (@insNormal,(SELECT id FROM @asset WHERE code='ARD-UNO-R3'),1,1,'GOOD','GOOD',NULL,NULL),
        (@insNormal,(SELECT id FROM @asset WHERE code='ARD-CLASS-SET'),3,3,'GOOD','GOOD',NULL,NULL),
        (@insDiff,(SELECT id FROM @asset WHERE code='JUMPER-65'),20,18,'GOOD','GOOD','MISSING',N'Thiếu 2 dây cái-cái sau buổi workshop.'),
        (@insDiff,(SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),2,2,'GOOD','DAMAGED','CONDITION_MISMATCH',N'Một cảm biến độ ẩm đất trả kết quả dao động.'),
        (@insDiff,(SELECT id FROM @asset WHERE code='RPI3-LEGACY'),1,1,'FAIR','BROKEN','CONDITION_MISMATCH',N'Bo mạch không khởi động khi cấp nguồn chuẩn.'),
        (@insDraft,(SELECT id FROM @asset WHERE code='PROJECTOR-EBX06'),1,0,'BROKEN',NULL,'PENDING_RECHECK',N'Chờ tháo thiết bị khỏi giá treo để kiểm tra.'),
        (@insDraft,(SELECT id FROM @asset WHERE code='OSC-PROBE-10X'),1,1,'DAMAGED','DAMAGED',NULL,N'Chờ kết quả bảo trì đầu kẹp mass.');

    INSERT dbo.incidents
        (asset_id,asset_usage_id,asset_item_id,inspection_item_id,reported_by,affected_quantity,incident_type,description,severity,status,
         occurred_at,reported_at,investigation_note,handling_result,reported_cause,determined_cause,reviewed_by,reviewed_at,
         mentor_review_note,forwarded_at,technical_cause,technical_severity,repairability,recommended_action,technical_note,
         technical_assessed_by,technical_assessed_at,created_at,updated_at)
    VALUES
        ((SELECT id FROM @asset WHERE code='RPI4-4GB'),@usageRpi4,(SELECT id FROM @item WHERE code='RPI4-4GB-001'),NULL,@anh,1,'MALFUNCTION',N'Gateway mất kết nối Wi-Fi hai lần trong lúc chạy thử tải cao.','MEDIUM','REPORTED',DATEADD(HOUR,-8,@now),DATEADD(HOUR,-7,@now),NULL,NULL,'UNKNOWN',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,DATEADD(HOUR,-7,@now),DATEADD(HOUR,-7,@now)),
        ((SELECT id FROM @asset WHERE code='DMM-AN8008'),@usageDmm,(SELECT id FROM @item WHERE code='DMM-AN8008-001'),NULL,@trung,1,'MALFUNCTION',N'Màn hình đôi lúc mờ khi đo liên tục hơn mười phút.','LOW','FORWARDED',DATEADD(DAY,-2,@now),DATEADD(HOUR,2,DATEADD(DAY,-2,@now)),NULL,NULL,'UNKNOWN',NULL,@mentor,DATEADD(DAY,-1,@now),N'Đã xác nhận hiện tượng, đề nghị kiểm tra pin và tiếp điểm.',DATEADD(DAY,-1,@now),NULL,NULL,NULL,NULL,NULL,NULL,NULL,DATEADD(HOUR,2,DATEADD(DAY,-2,@now)),DATEADD(DAY,-1,@now)),
        ((SELECT id FROM @asset WHERE code='MOUSE-M331'),@usageMouse,(SELECT id FROM @item WHERE code='MOUSE-M331-001'),NULL,@duc,1,'MALFUNCTION',N'Con lăn phản hồi chậm và bỏ qua một số bước cuộn.','MEDIUM','INVESTIGATING',DATEADD(DAY,-1,@now),DATEADD(HOUR,1,DATEADD(DAY,-1,@now)),N'Đang kiểm tra encoder và bụi bên trong.',NULL,'UNKNOWN',NULL,@mentor,DATEADD(HOUR,-20,@now),N'Đã vệ sinh bên ngoài nhưng lỗi vẫn tái hiện.',DATEADD(HOUR,-20,@now),NULL,NULL,NULL,NULL,NULL,NULL,NULL,DATEADD(HOUR,1,DATEADD(DAY,-1,@now)),DATEADD(HOUR,-20,@now)),
        ((SELECT id FROM @asset WHERE code='ARD-UNO-R3'),@usageArduino,(SELECT id FROM @item WHERE code='ARD-UNO-R3-001'),NULL,@minh,1,'OTHER',N'Một dây jumper lỏng chân cắm trong quá trình thử nghiệm.','LOW','RESOLVED',DATEADD(DAY,-16,@now),DATEADD(HOUR,1,DATEADD(DAY,-16,@now)),N'Đối chiếu checklist cho thấy hao mòn phụ kiện thông thường.',N'Đã thay dây jumper dự phòng, bo mạch hoạt động ổn định.','NATURAL','NATURAL',@mentor,DATEADD(DAY,-15,@now),N'Không ghi nhận thao tác sai của Intern.',DATEADD(DAY,-15,@now),'NATURAL_WEAR','MINOR','REPAIRABLE','CONTINUE_USE',N'Lỗi nằm ở dây kết nối tiêu hao, không ảnh hưởng bo mạch.',@manager,DATEADD(DAY,-14,@now),DATEADD(HOUR,1,DATEADD(DAY,-16,@now)),DATEADD(DAY,-14,@now)),
        ((SELECT id FROM @asset WHERE code='RPI3-LEGACY'),@usageLegacy,(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'),NULL,@luong,1,'DAMAGE',N'Bo mạch không khởi động sau khi có mùi khét nhẹ tại cổng nguồn.','HIGH','RESOLVED',DATEADD(DAY,-80,@now),DATEADD(HOUR,1,DATEADD(DAY,-80,@now)),N'Kiểm tra nguồn cấp và lịch sử sử dụng.',N'IC nguồn hỏng, sửa thử không thành công.','UNKNOWN','INTERN',@mentor,DATEADD(DAY,-78,@now),N'Intern dùng adapter không nằm trong bộ phụ kiện được cấp.',DATEADD(DAY,-78,@now),'MISUSE','MAJOR','NOT_REPAIRABLE','DISPOSAL_REVIEW',N'Điện áp adapter không phù hợp làm hỏng tầng nguồn.',@manager,DATEADD(DAY,-75,@now),DATEADD(HOUR,1,DATEADD(DAY,-80,@now)),DATEADD(DAY,-75,@now)),
        ((SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),NULL,(SELECT id FROM @item WHERE code='SENSOR-ENV-SET-001'),(SELECT inspection_item_id FROM dbo.inspection_items WHERE inspection_id=@insDiff AND asset_id=(SELECT id FROM @asset WHERE code='SENSOR-ENV-SET')),@mentor,1,'MALFUNCTION',N'Cảm biến độ ẩm đất trả giá trị nhảy bất thường sau khi cấp phát theo nhóm.','HIGH','OPEN',DATEADD(DAY,-7,@now),DATEADD(DAY,-7,@now),N'Đã cô lập bộ cảm biến khỏi hoạt động của nhóm.',NULL,'UNKNOWN',NULL,NULL,NULL,N'Phát hiện từ kiểm kê giữa kỳ.',DATEADD(DAY,-7,@now),NULL,NULL,NULL,NULL,NULL,NULL,NULL,DATEADD(DAY,-7,@now),DATEADD(DAY,-7,@now)),
        ((SELECT id FROM @asset WHERE code='JUMPER-65'),NULL,NULL,(SELECT inspection_item_id FROM dbo.inspection_items WHERE inspection_id=@insDiff AND asset_id=(SELECT id FROM @asset WHERE code='JUMPER-65')),@mentor,2,'MISSING',N'Thiếu hai dây jumper cái-cái so với số lượng sổ kho.','LOW','RESOLVED',DATEADD(DAY,-8,@now),DATEADD(DAY,-8,@now),N'Đối chiếu biên bản workshop và hộp linh kiện.',N'Ghi nhận hao hụt linh kiện tiêu hao, bổ sung từ kho dự phòng.','NATURAL','NATURAL',@mentor,DATEADD(DAY,-7,@now),N'Không đủ bằng chứng gắn trách nhiệm cho cá nhân.',DATEADD(DAY,-7,@now),'NATURAL_WEAR','MINOR','NOT_APPLICABLE','MONITOR',N'Linh kiện giá trị thấp, quản lý theo số lượng.',@manager,DATEADD(DAY,-6,@now),DATEADD(DAY,-8,@now),DATEADD(DAY,-6,@now));

    DECLARE @incArduino bigint=(SELECT incident_id FROM dbo.incidents WHERE asset_usage_id=@usageArduino);
    DECLARE @incLegacy bigint=(SELECT incident_id FROM dbo.incidents WHERE asset_usage_id=@usageLegacy);
    DECLARE @incSensor bigint=(SELECT incident_id FROM dbo.incidents WHERE asset_item_id=(SELECT id FROM @item WHERE code='SENSOR-ENV-SET-001'));
    DECLARE @incJumper bigint=(SELECT incident_id FROM dbo.incidents WHERE inspection_item_id=(SELECT inspection_item_id FROM dbo.inspection_items WHERE inspection_id=@insDiff AND asset_id=(SELECT id FROM @asset WHERE code='JUMPER-65')));

    INSERT dbo.responsibilities
        (incident_id,student_id,determined_by,conclusion,decision,status,responsibility_level,evidence_summary,responsibility_note,
         handling_recommendation,responsibility_assessed_by,responsibility_assessed_at,determined_at)
    VALUES
        (@incLegacy,@luongStudent,@mentor,N'Intern sử dụng adapter ngoài danh mục được cấp.',N'Nhắc nhở quy trình và đề xuất bồi hoàn adapter chuẩn.','CONFIRMED','FULL',N'Ảnh adapter, nhật ký mượn và kết luận IC nguồn cháy do sai điện áp.',N'Việc dùng nguồn sai thông số trực tiếp gây hỏng tầng nguồn.',N'Đào tạo lại quy trình cấp nguồn; xem xét bồi hoàn theo quy định.',@mentor,DATEADD(DAY,-74,@now),DATEADD(DAY,-74,@now)),
        (@incJumper,NULL,@mentor,N'Không xác định cá nhân làm thất lạc linh kiện tiêu hao.',N'LAB bổ sung từ tồn kho dự phòng.','CONFIRMED','NONE',N'Biên bản workshop không có bàn giao cá nhân.',N'Không đủ căn cứ quy trách nhiệm.',N'Tăng tần suất kiểm đếm hộp linh kiện.',@mentor,DATEADD(DAY,-5,@now),DATEADD(DAY,-5,@now));

    INSERT dbo.maintenance_records
        (asset_id,asset_item_id,incident_id,quantity,requested_by,description,requested_at,status,approved_by,approved_at,
         approval_note,repair_started_at,repair_completed_at,repair_result,repair_outcome,estimated_cost,actual_cost,note,created_at,updated_at)
    VALUES
        ((SELECT id FROM @asset WHERE code='OSC-PROBE-10X'),(SELECT id FROM @item WHERE code='OSC-PROBE-10X-001'),NULL,1,@mentor,N'Thay đầu kẹp mass và kiểm tra suy hao tín hiệu.',DATEADD(HOUR,-10,@now),'PENDING',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',250000,NULL,N'Ưu tiên xử lý trước buổi thực hành đo tín hiệu.',DATEADD(HOUR,-10,@now),DATEADD(HOUR,-10,@now)),
        ((SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),(SELECT id FROM @item WHERE code='SENSOR-ENV-SET-001'),@incSensor,1,@mentor,N'Thay cảm biến độ ẩm đất và hiệu chuẩn lại toàn bộ bộ kit.',DATEADD(DAY,-6,@now),'IN_PROGRESS',@manager,DATEADD(DAY,-5,@now),N'Đồng ý sửa tại LAB.',DATEADD(DAY,-4,@now),NULL,NULL,'PENDING',320000,NULL,N'Kỹ thuật viên Nguyễn Văn Sơn đang kiểm tra.',DATEADD(DAY,-6,@now),DATEADD(DAY,-4,@now)),
        ((SELECT id FROM @asset WHERE code='ARD-UNO-R3'),(SELECT id FROM @item WHERE code='ARD-UNO-R3-001'),@incArduino,1,@mentor,N'Thay dây jumper lỗi và kiểm tra các chân I/O.',DATEADD(DAY,-15,@now),'COMPLETED',@manager,DATEADD(DAY,-15,@now),N'Cho phép thay phụ kiện tại chỗ.',DATEADD(DAY,-15,@now),DATEADD(DAY,-14,@now),N'Đã thay dây, kiểm tra digital/analog I/O đạt yêu cầu.','SUCCESS',50000,35000,N'Hoàn tất bởi kỹ thuật viên LAB.',DATEADD(DAY,-15,@now),DATEADD(DAY,-14,@now)),
        ((SELECT id FROM @asset WHERE code='RPI3-LEGACY'),(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'),@incLegacy,1,@mentor,N'Chẩn đoán và thử thay IC nguồn cho Raspberry Pi đời cũ.',DATEADD(DAY,-73,@now),'COMPLETED',@manager,DATEADD(DAY,-72,@now),N'Cho phép thử sửa một lần trước khi thanh lý.',DATEADD(DAY,-71,@now),DATEADD(DAY,-68,@now),N'Thay IC nguồn không khôi phục được bo mạch; nhiều lớp PCB đã tổn thương.','FAILED',850000,420000,N'Chuyển đề xuất thanh lý.',DATEADD(DAY,-73,@now),DATEADD(DAY,-68,@now));
    DECLARE @mntLegacy bigint=(SELECT maintenance_id FROM dbo.maintenance_records WHERE asset_item_id=(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'));

    INSERT dbo.disposal_records
        (asset_id,asset_item_id,maintenance_id,quantity,requested_by,reason,reason_code,technical_review_note,requested_at,status,
         approved_by,approved_at,approval_note,disposal_method,completed_by,completed_at,completion_note,created_at,updated_at)
    VALUES
        ((SELECT id FROM @asset WHERE code='PROJECTOR-EBX06'),(SELECT id FROM @item WHERE code='PROJECTOR-EBX06-001'),NULL,1,@mentor,N'Bóng đèn và bo nguồn đều hỏng; chi phí thay thế vượt giá trị còn lại.','REPAIR_NOT_ECONOMICAL',NULL,DATEADD(DAY,-1,@now),'PENDING',NULL,NULL,NULL,NULL,NULL,NULL,NULL,DATEADD(DAY,-1,@now),DATEADD(DAY,-1,@now)),
        ((SELECT id FROM @asset WHERE code='TABLET-GALAXY-A'),(SELECT id FROM @item WHERE code='TABLET-GALAXY-A-001'),NULL,1,@mentor,N'Pin phồng và màn hình nứt, có nguy cơ mất an toàn.','UNSAFE',N'Đã xác nhận pin biến dạng; không tiếp tục lưu kho lâu dài.',DATEADD(DAY,-4,@now),'APPROVED',@manager,DATEADD(DAY,-3,@now),N'Duyệt bàn giao đơn vị xử lý rác thải điện tử.',NULL,NULL,NULL,NULL,DATEADD(DAY,-4,@now),DATEADD(DAY,-3,@now)),
        ((SELECT id FROM @asset WHERE code='JUMPER-65'),NULL,NULL,20,@mentor,N'Đề xuất thanh lý toàn bộ vì thiếu hai dây sau kiểm kê.','OTHER',NULL,DATEADD(DAY,-7,@now),'REJECTED',@manager,DATEADD(DAY,-6,@now),N'Từ chối: chỉ thiếu số lượng nhỏ, phần còn lại vẫn sử dụng tốt.',NULL,NULL,NULL,NULL,DATEADD(DAY,-7,@now),DATEADD(DAY,-6,@now)),
        ((SELECT id FROM @asset WHERE code='RPI3-LEGACY'),(SELECT id FROM @item WHERE code='RPI3-LEGACY-001'),@mntLegacy,1,@mentor,N'Sửa chữa thất bại; bo mạch không còn khả năng phục hồi.','NOT_REPAIRABLE',N'Kết quả bảo trì xác nhận hỏng nhiều lớp PCB và không thể sửa kinh tế.',DATEADD(DAY,-67,@now),'COMPLETED',@manager,DATEADD(DAY,-66,@now),N'Duyệt thanh lý theo quy trình rác thải điện tử.','E_WASTE',@manager,DATEADD(DAY,-60,@now),N'Đã tháo thẻ nhớ, xóa nhãn tài sản và bàn giao GreenTech Recycling.',DATEADD(DAY,-67,@now),DATEADD(DAY,-60,@now));

    INSERT dbo.equipment_activities (request_id,mentor_id,activity_name,description,start_date,end_date,status,created_at)
    VALUES (@activeRequest,@mentor,N'Smart Garden - Sprint tích hợp',N'Cấp thiết bị dùng xuyên suốt giai đoạn tích hợp gateway, cảm biến và dashboard.',DATEADD(DAY,-30,@today),DATEADD(DAY,30,@today),'ACTIVE',DATEADD(DAY,-32,@now));
    DECLARE @activity bigint=SCOPE_IDENTITY();
    INSERT dbo.equipment_groups (activity_id,group_name,leader_intern_id)
    VALUES (@activity,N'Nhóm Gateway và Cảm biến',@anhStudent);
    DECLARE @allocationGroup bigint=SCOPE_IDENTITY();
    INSERT dbo.equipment_group_members (allocation_group_id,intern_id)
    VALUES (@allocationGroup,@anhStudent),(@allocationGroup,@trungStudent),(@allocationGroup,@ducStudent);

    INSERT dbo.equipment_allocation_requests
        (activity_id,allocation_group_id,intern_id,asset_id,requested_quantity,note,status,requested_by,reviewed_by,reviewed_at,review_note,created_at)
    VALUES
        (@activity,@allocationGroup,NULL,(SELECT id FROM @asset WHERE code='ARD-CLASS-SET'),1,N'Lập trình node điều khiển tưới.','APPROVED',@mentor,@manager,DATEADD(DAY,-28,@now),N'Đã gán bộ số 001.',DATEADD(DAY,-29,@now)),
        (@activity,NULL,@anhStudent,(SELECT id FROM @asset WHERE code='REMOTE-R400'),1,N'Bàn giao trực tiếp cho trưởng nhóm dùng demo.','APPROVED',@mentor,@manager,DATEADD(DAY,-2,@now),N'Chờ Intern xác nhận nhận.',DATEADD(DAY,-3,@now)),
        (@activity,@allocationGroup,NULL,(SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'),1,N'Đo nhiệt độ, ánh sáng và độ ẩm đất.','APPROVED',@mentor,@manager,DATEADD(DAY,-12,@now),N'Đã gán bộ số 001.',DATEADD(DAY,-13,@now)),
        (@activity,NULL,NULL,(SELECT id FROM @asset WHERE code='WEBCAM-C920'),1,N'Nhận diện tình trạng cây từ ảnh.','PENDING_APPROVAL',@mentor,NULL,NULL,NULL,DATEADD(HOUR,-6,@now)),
        (@activity,NULL,NULL,(SELECT id FROM @asset WHERE code='MOUSE-M331'),1,N'Phụ kiện dự phòng cho khu demo.','REJECTED',@mentor,@manager,DATEADD(DAY,-1,@now),N'Không cần cấp dài hạn; sử dụng theo lượt mượn.',DATEADD(DAY,-2,@now));
    DECLARE @reqClass bigint=(SELECT allocation_request_id FROM dbo.equipment_allocation_requests WHERE asset_id=(SELECT id FROM @asset WHERE code='ARD-CLASS-SET'));
    DECLARE @reqRemote bigint=(SELECT allocation_request_id FROM dbo.equipment_allocation_requests WHERE asset_id=(SELECT id FROM @asset WHERE code='REMOTE-R400'));
    DECLARE @reqSensor bigint=(SELECT allocation_request_id FROM dbo.equipment_allocation_requests WHERE asset_id=(SELECT id FROM @asset WHERE code='SENSOR-ENV-SET'));
    INSERT dbo.equipment_allocations (allocation_request_id,asset_item_id,status,handed_over_by,handed_over_at,received_at)
    VALUES
        (@reqClass,(SELECT id FROM @item WHERE code='ARD-CLASS-SET-001'),'ACTIVE',@manager,DATEADD(DAY,-27,@now),DATEADD(DAY,-27,@now)),
        (@reqRemote,(SELECT id FROM @item WHERE code='REMOTE-R400-001'),'READY_FOR_HANDOVER',@manager,DATEADD(DAY,-2,@now),NULL),
        (@reqSensor,(SELECT id FROM @item WHERE code='SENSOR-ENV-SET-001'),'ISSUE_REPORTED',@manager,DATEADD(DAY,-11,@now),DATEADD(DAY,-11,@now));
    DECLARE @sensorAllocation bigint=(SELECT allocation_id FROM dbo.equipment_allocations WHERE allocation_request_id=@reqSensor);
    INSERT dbo.equipment_allocation_issue_reports
        (allocation_id,reported_by,issue_type,description,status,mentor_note,incident_id,reviewed_by,reviewed_at,created_at)
    VALUES (@sensorAllocation,@duc,'DAMAGE',N'Cảm biến độ ẩm đất trả giá trị dao động mạnh dù đất ổn định.','VERIFIED',N'Đã tái hiện lỗi và chuyển bảo trì.',@incSensor,@mentor,DATEADD(DAY,-7,@now),DATEADD(DAY,-8,@now));

    INSERT dbo.password_reset_requests
        (target_user_id,status,request_note,reviewed_by,reviewed_at,review_note,issued_at,consumed_at,created_at,updated_at)
    VALUES
        (@mentorOps,'PENDING',N'Không còn truy cập thiết bị lưu mật khẩu cũ.',NULL,NULL,NULL,NULL,NULL,DATEADD(HOUR,-4,@now),DATEADD(HOUR,-4,@now)),
        (@manager,'REJECTED',N'Nghi ngờ mật khẩu bị lộ sau buổi hướng dẫn.',@admin,DATEADD(DAY,-9,@now),N'Đã xác minh người dùng vẫn đăng nhập được; yêu cầu tạo lại nếu cần.',NULL,NULL,DATEADD(DAY,-10,@now),DATEADD(DAY,-9,@now)),
        (@mentor,'CONSUMED',N'Đổi máy tính làm việc và cần cấp lại quyền truy cập.',@admin,DATEADD(DAY,-35,@now),N'Đã xác minh danh tính qua quản lý LAB.',DATEADD(DAY,-35,@now),DATEADD(DAY,-34,@now),DATEADD(DAY,-36,@now),DATEADD(DAY,-34,@now));

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT 'FULL DATABASE SETUP COMPLETED' AS setup_status;
SELECT full_name, email, role,
       CASE WHEN role = 'INTERN' THEN 'Google FPT' ELSE '123' END AS demo_login
FROM dbo.users
WHERE status = 'ACTIVE'
ORDER BY CASE role WHEN 'ADMIN' THEN 1 WHEN 'LAB_MANAGER' THEN 2 WHEN 'MENTOR' THEN 3 ELSE 4 END, full_name;
SELECT 'Assets' AS entity, COUNT(*) AS total FROM dbo.assets
UNION ALL SELECT 'Physical items', COUNT(*) FROM dbo.asset_items
UNION ALL SELECT 'Usage records', COUNT(*) FROM dbo.asset_usages
UNION ALL SELECT 'Incidents', COUNT(*) FROM dbo.incidents
UNION ALL SELECT 'Inspections', COUNT(*) FROM dbo.inspection_records
UNION ALL SELECT 'Maintenance records', COUNT(*) FROM dbo.maintenance_records
UNION ALL SELECT 'Disposal records', COUNT(*) FROM dbo.disposal_records
UNION ALL SELECT 'Allocation requests', COUNT(*) FROM dbo.equipment_allocation_requests;
GO
