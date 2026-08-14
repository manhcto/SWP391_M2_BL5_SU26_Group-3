/*
  LAB Asset Management System - Microsoft SQL Server
  Creates lab_asset_management when it does not exist, then creates the schema.
  Timestamps are stored in UTC.
*/

USE [master];
GO

IF DB_ID(N'lab_asset_management') IS NULL
    EXEC(N'CREATE DATABASE [lab_asset_management]');
GO

USE [lab_asset_management];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

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
        CONSTRAINT CK_users_role CHECK (role IN ('ADMIN', 'LAB_MANAGER', 'MENTOR', 'STUDENT')),
        CONSTRAINT CK_users_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
        CONSTRAINT CK_users_google_domain CHECK (
            google_subject IS NULL
            OR RIGHT(LOWER(email), LEN('@fpt.edu.vn')) = '@fpt.edu.vn'
        )
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
        status varchar(10) NOT NULL CONSTRAINT DF_lab_usage_requests_status DEFAULT ('PENDING'),
        request_note nvarchar(max) NULL,
        approved_by bigint NULL,
        approved_at datetime2(0) NULL,
        approval_note nvarchar(max) NULL,
        created_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_requests_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at datetime2(0) NOT NULL CONSTRAINT DF_lab_usage_requests_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_lab_usage_requests PRIMARY KEY (request_id),
        CONSTRAINT UQ_lab_usage_requests_id_semester UNIQUE (request_id, semester_id),
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
        CONSTRAINT FK_lab_usage_request_students_request FOREIGN KEY (request_id, semester_id)
            REFERENCES dbo.lab_usage_requests(request_id, semester_id),
        CONSTRAINT FK_lab_usage_request_students_student FOREIGN KEY (student_id) REFERENCES dbo.student_profiles(student_id)
    );

    CREATE INDEX IX_lab_usage_request_students_semester ON dbo.lab_usage_request_students (semester_id);
    CREATE INDEX IX_lab_usage_request_students_student ON dbo.lab_usage_request_students (student_id);

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

    -- The borrowing service must use one transaction to verify that the request is APPROVED,
    -- the asset is borrowable and AVAILABLE, and active quantities do not exceed total_quantity.
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

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
