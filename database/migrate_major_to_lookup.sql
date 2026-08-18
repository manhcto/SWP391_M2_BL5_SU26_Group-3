/* Run this once on an existing lab_asset_management database. */
USE [lab_asset_management];
GO

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
GO

IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'SE')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('SE', N'Software Engineering', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'AI')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('AI', N'Artificial Intelligence', 2);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'IS')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('IS', N'Information Systems', 3);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'IA')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('IA', N'Information Assurance', 4);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'GD')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('GD', N'Graphic Design', 5);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'MC')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('MC', N'Multimedia Communications', 6);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'BA')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('BA', N'Business Administration', 7);
IF NOT EXISTS (SELECT 1 FROM dbo.majors WHERE major_code = 'DM')
    INSERT dbo.majors (major_code, major_name, display_order) VALUES ('DM', N'Digital Marketing', 8);

IF COL_LENGTH('dbo.student_profiles', 'major_id') IS NULL
    ALTER TABLE dbo.student_profiles ADD major_id bigint NULL;
GO

IF COL_LENGTH('dbo.student_profiles', 'major') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dbo.student_profiles profile
        WHERE profile.major IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM dbo.majors major WHERE major.major_name = profile.major
          )
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
