/*
  LAB Asset Management System - Microsoft SQL Server
  Standalone database script for the intern-list workflow.

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

IF DB_ID(N'lab_asset_management') IS NULL
    EXEC(N'CREATE DATABASE [lab_asset_management]');
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
        quantity int NOT NULL CONSTRAINT DF_asset_usages_quantity DEFAULT (1),
        borrowed_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_borrowed_at DEFAULT (SYSUTCDATETIME()),
        due_at datetime2(0) NOT NULL,
        returned_at datetime2(0) NULL,
        condition_before varchar(10) NOT NULL,
        condition_after varchar(10) NULL,
        status varchar(10) NOT NULL CONSTRAINT DF_asset_usages_status DEFAULT ('IN_USE'),
        note nvarchar(max) NULL,
        created_by bigint NOT NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_asset_usages_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_asset_usages PRIMARY KEY (asset_usage_id),
        CONSTRAINT FK_asset_usages_request_student FOREIGN KEY (request_id, semester_id, student_id)
            REFERENCES dbo.lab_usage_request_students(request_id, semester_id, student_id),
        CONSTRAINT FK_asset_usages_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_asset_usages_creator FOREIGN KEY (created_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_asset_usages_quantity CHECK (quantity > 0),
        CONSTRAINT CK_asset_usages_condition_before CHECK (condition_before IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')),
        CONSTRAINT CK_asset_usages_condition_after CHECK (
            condition_after IS NULL OR condition_after IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')
        ),
        CONSTRAINT CK_asset_usages_status CHECK (status IN ('IN_USE', 'RETURNED')),
        CONSTRAINT CK_asset_usages_dates CHECK (
            due_at >= borrowed_at
            AND (returned_at IS NULL OR returned_at >= borrowed_at)
        ),
        CONSTRAINT CK_asset_usages_return CHECK (
            (status = 'IN_USE' AND returned_at IS NULL)
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
        inspection_item_id bigint NULL,
        reported_by bigint NOT NULL,
        affected_quantity int NOT NULL CONSTRAINT DF_incidents_affected_quantity DEFAULT (1),
        incident_type varchar(15) NOT NULL,
        description nvarchar(max) NOT NULL,
        severity varchar(10) NOT NULL,
        status varchar(15) NOT NULL CONSTRAINT DF_incidents_status DEFAULT ('OPEN'),
        occurred_at datetime2(0) NULL,
        reported_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_reported_at DEFAULT (SYSUTCDATETIME()),
        investigation_note nvarchar(max) NULL,
        handling_result nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_incidents_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_incidents PRIMARY KEY (incident_id),
        CONSTRAINT FK_incidents_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_incidents_usage FOREIGN KEY (asset_usage_id) REFERENCES dbo.asset_usages(asset_usage_id),
        CONSTRAINT FK_incidents_inspection_item FOREIGN KEY (inspection_item_id) REFERENCES dbo.inspection_items(inspection_item_id),
        CONSTRAINT FK_incidents_reporter FOREIGN KEY (reported_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_incidents_quantity CHECK (affected_quantity > 0),
        CONSTRAINT CK_incidents_type CHECK (incident_type IN ('DAMAGE', 'MISSING', 'LOSS', 'MALFUNCTION', 'OTHER')),
        CONSTRAINT CK_incidents_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
        CONSTRAINT CK_incidents_status CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'CLOSED')),
        CONSTRAINT CK_incidents_dates CHECK (occurred_at IS NULL OR occurred_at <= reported_at)
    );

    CREATE INDEX IX_incidents_asset ON dbo.incidents (asset_id);
    CREATE INDEX IX_incidents_usage ON dbo.incidents (asset_usage_id) WHERE asset_usage_id IS NOT NULL;
    CREATE INDEX IX_incidents_inspection_item ON dbo.incidents (inspection_item_id) WHERE inspection_item_id IS NOT NULL;
    CREATE INDEX IX_incidents_status ON dbo.incidents (status);

    CREATE TABLE dbo.responsibilities (
        responsibility_id bigint IDENTITY(1,1) NOT NULL,
        incident_id bigint NOT NULL,
        student_id bigint NOT NULL,
        determined_by bigint NOT NULL,
        conclusion nvarchar(max) NOT NULL,
        decision nvarchar(max) NULL,
        status varchar(20) NOT NULL,
        reviewed_by bigint NULL,
        reviewed_at datetime2(0) NULL,
        review_note nvarchar(max) NULL,
        resolution_note nvarchar(max) NULL,
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
        incident_id bigint NULL,
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
        maintenance_id bigint NULL,
        quantity int NOT NULL CONSTRAINT DF_disposal_records_quantity DEFAULT (1),
        requested_by bigint NOT NULL,
        reason nvarchar(max) NOT NULL,
        requested_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_requested_at DEFAULT (SYSUTCDATETIME()),
        status varchar(10) NOT NULL CONSTRAINT DF_disposal_records_status DEFAULT ('PENDING'),
        approved_by bigint NULL,
        approved_at datetime2(0) NULL,
        approval_note nvarchar(max) NULL,
        completed_at datetime2(0) NULL,
        completion_note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_disposal_records_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_disposal_records PRIMARY KEY (disposal_id),
        CONSTRAINT FK_disposal_records_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT FK_disposal_records_maintenance FOREIGN KEY (maintenance_id) REFERENCES dbo.maintenance_records(maintenance_id),
        CONSTRAINT FK_disposal_records_requester FOREIGN KEY (requested_by) REFERENCES dbo.users(user_id),
        CONSTRAINT FK_disposal_records_approver FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id),
        CONSTRAINT CK_disposal_records_quantity CHECK (quantity > 0),
        CONSTRAINT CK_disposal_records_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')),
        CONSTRAINT CK_disposal_records_approval CHECK (
            (status = 'PENDING' AND approved_by IS NULL AND approved_at IS NULL)
            OR (status IN ('APPROVED', 'REJECTED', 'COMPLETED')
                AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
        ),
        CONSTRAINT CK_disposal_records_completion CHECK (
            (status = 'COMPLETED' AND completed_at IS NOT NULL)
            OR (status <> 'COMPLETED' AND completed_at IS NULL)
        )
    );

    CREATE INDEX IX_disposal_records_asset ON dbo.disposal_records (asset_id);
    CREATE INDEX IX_disposal_records_maintenance ON dbo.disposal_records (maintenance_id) WHERE maintenance_id IS NOT NULL;
    CREATE INDEX IX_disposal_records_status ON dbo.disposal_records (status);

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

SELECT
    u.full_name,
    u.email,
    u.role,
    '123' AS demo_password
FROM dbo.users AS u
ORDER BY u.user_id;
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
        storage_location nvarchar(150) NULL,
        purchase_date date NULL,
        warranty_until date NULL,
        note nvarchar(500) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_asset_items_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_asset_items_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_asset_items PRIMARY KEY (asset_item_id),
        CONSTRAINT UQ_asset_items_code UNIQUE (item_code),
        CONSTRAINT FK_asset_items_asset FOREIGN KEY (asset_id) REFERENCES dbo.assets(asset_id),
        CONSTRAINT CK_asset_items_condition CHECK (condition IN ('GOOD', 'FAIR', 'DAMAGED', 'BROKEN')),
        CONSTRAINT CK_asset_items_status CHECK (status IN ('AVAILABLE', 'MAINTENANCE', 'UNAVAILABLE', 'DISPOSED')),
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
        ADD CONSTRAINT FK_asset_usages_asset_item FOREIGN KEY (asset_item_id)
        REFERENCES dbo.asset_items(asset_item_id);
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_asset_usages_asset_item'
      AND object_id = OBJECT_ID('dbo.asset_usages')
)
    CREATE INDEX IX_asset_usages_asset_item ON dbo.asset_usages (asset_item_id)
        WHERE asset_item_id IS NOT NULL;
GO

/* Reduce the demo inventory to two borrowable kits. */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @kitCategoryId bigint;

IF NOT EXISTS (SELECT 1 FROM dbo.asset_categories WHERE category_name = N'Kit thiết bị')
    INSERT dbo.asset_categories (category_name, description, status)
    VALUES (N'Kit thiết bị', N'Các bộ kit điện tử và cảm biến được phép cho intern mượn.', 'ACTIVE');
SELECT @kitCategoryId = category_id FROM dbo.asset_categories WHERE category_name = N'Kit thiết bị';

DECLARE @targets TABLE (
    asset_code varchar(50) NOT NULL PRIMARY KEY,
    asset_name nvarchar(150) NOT NULL,
    category_id bigint NOT NULL,
    total_quantity int NOT NULL,
    is_borrowable bit NOT NULL,
    storage_location nvarchar(150) NULL,
    description nvarchar(max) NULL
);

INSERT @targets (asset_code, asset_name, category_id, total_quantity, is_borrowable, storage_location, description)
VALUES
    ('ARD-KIT-A01', N'Bộ kit Arduino A01', @kitCategoryId, 3, 1, N'Tủ IoT-01', N'Kit Arduino dùng cho bài thực hành IoT.'),
    ('SENSOR-KIT-S04', N'Bộ kit cảm biến S04', @kitCategoryId, 3, 1, N'Tủ IoT-02', N'Kit cảm biến dùng cho bài thực hành đo lường.');

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
INSERT dbo.asset_items (asset_id, item_code, condition, status, storage_location, note)
SELECT a.asset_id, CONCAT(t.asset_code, '-', RIGHT(CONCAT('0000', n.item_number), 4)),
       'GOOD', 'AVAILABLE', t.storage_location, N'Tạo từ bộ dữ liệu LAB chuẩn hóa'
FROM @targets t JOIN dbo.assets a ON a.asset_code = t.asset_code
JOIN Numbers n ON n.item_number <= t.total_quantity
WHERE NOT EXISTS (SELECT 1 FROM dbo.asset_items i
                  WHERE i.item_code = CONCAT(t.asset_code, '-', RIGHT(CONCAT('0000', n.item_number), 4)));

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
        VALUES (N'Demo Lab Manager Test', 'labmanager@gmail.com', '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C', 'LAB_MANAGER', 'ACTIVE');

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

SELECT 'FULL DATABASE SETUP COMPLETED' AS setup_status;
GO
