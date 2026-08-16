/*
  LAB Asset Management System - portable SQL Server database.
  Safe to share: no credentials, personal data, or machine-specific file paths.
  Contains the full schema and only the four required lab time slots.
  Run once with a SQL Server account that can create databases.
  Configure each application instance separately through its local .env file.
*/

USE [master]
GO

IF DB_ID(N'lab_asset_management') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [lab_asset_management]');
END
GO

USE [lab_asset_management]
GO

/****** Object:  Table [dbo].[asset_categories]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[asset_categories](
	[category_id] [bigint] IDENTITY(1,1) NOT NULL,
	[category_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[status] [varchar](10) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_asset_categories] PRIMARY KEY CLUSTERED 
(
	[category_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[asset_usages]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[asset_usages](
	[asset_usage_id] [bigint] IDENTITY(1,1) NOT NULL,
	[request_id] [bigint] NOT NULL,
	[semester_id] [bigint] NOT NULL,
	[student_id] [bigint] NOT NULL,
	[asset_id] [bigint] NOT NULL,
	[quantity] [int] NOT NULL,
	[borrowed_at] [datetime2](0) NOT NULL,
	[due_at] [datetime2](0) NOT NULL,
	[returned_at] [datetime2](0) NULL,
	[condition_before] [varchar](10) NOT NULL,
	[condition_after] [varchar](10) NULL,
	[status] [varchar](10) NOT NULL,
	[note] [nvarchar](max) NULL,
	[created_by] [bigint] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_asset_usages] PRIMARY KEY CLUSTERED 
(
	[asset_usage_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[assets]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[assets](
	[asset_id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset_code] [varchar](50) NOT NULL,
	[asset_name] [nvarchar](150) NOT NULL,
	[category_id] [bigint] NOT NULL,
	[tracking_mode] [varchar](10) NOT NULL,
	[serial_number] [varchar](100) NULL,
	[total_quantity] [int] NOT NULL,
	[condition] [varchar](10) NOT NULL,
	[status] [varchar](15) NOT NULL,
	[is_borrowable] [bit] NOT NULL,
	[storage_location] [nvarchar](150) NULL,
	[description] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_assets] PRIMARY KEY CLUSTERED 
(
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[disposal_records]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[disposal_records](
	[disposal_id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset_id] [bigint] NOT NULL,
	[maintenance_id] [bigint] NULL,
	[quantity] [int] NOT NULL,
	[requested_by] [bigint] NOT NULL,
	[reason] [nvarchar](max) NOT NULL,
	[requested_at] [datetime2](0) NOT NULL,
	[status] [varchar](10) NOT NULL,
	[approved_by] [bigint] NULL,
	[approved_at] [datetime2](0) NULL,
	[approval_note] [nvarchar](max) NULL,
	[completed_at] [datetime2](0) NULL,
	[completion_note] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_disposal_records] PRIMARY KEY CLUSTERED 
(
	[disposal_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[incidents]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[incidents](
	[incident_id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset_id] [bigint] NOT NULL,
	[asset_usage_id] [bigint] NULL,
	[inspection_item_id] [bigint] NULL,
	[reported_by] [bigint] NOT NULL,
	[affected_quantity] [int] NOT NULL,
	[incident_type] [varchar](15) NOT NULL,
	[description] [nvarchar](max) NOT NULL,
	[severity] [varchar](10) NOT NULL,
	[status] [varchar](15) NOT NULL,
	[occurred_at] [datetime2](0) NULL,
	[reported_at] [datetime2](0) NOT NULL,
	[investigation_note] [nvarchar](max) NULL,
	[handling_result] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_incidents] PRIMARY KEY CLUSTERED 
(
	[incident_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[inspection_items]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inspection_items](
	[inspection_item_id] [bigint] IDENTITY(1,1) NOT NULL,
	[inspection_id] [bigint] NOT NULL,
	[asset_id] [bigint] NOT NULL,
	[expected_quantity] [int] NOT NULL,
	[actual_quantity] [int] NOT NULL,
	[expected_condition] [varchar](10) NULL,
	[actual_condition] [varchar](10) NULL,
	[discrepancy_type] [varchar](30) NULL,
	[discrepancy_note] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_inspection_items] PRIMARY KEY CLUSTERED 
(
	[inspection_item_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[inspection_records]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inspection_records](
	[inspection_id] [bigint] IDENTITY(1,1) NOT NULL,
	[semester_id] [bigint] NOT NULL,
	[inspected_by] [bigint] NOT NULL,
	[inspection_type] [varchar](10) NOT NULL,
	[scope] [varchar](20) NOT NULL,
	[inspection_date] [datetime2](0) NOT NULL,
	[status] [varchar](10) NOT NULL,
	[result] [varchar](20) NULL,
	[note] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_inspection_records] PRIMARY KEY CLUSTERED 
(
	[inspection_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[lab_time_slots]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lab_time_slots](
	[slot_id] [tinyint] NOT NULL,
	[slot_name] [varchar](20) NOT NULL,
	[start_time] [time](0) NOT NULL,
	[end_time] [time](0) NOT NULL,
 CONSTRAINT [PK_lab_time_slots] PRIMARY KEY CLUSTERED 
(
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[lab_usage_request_slots]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lab_usage_request_slots](
	[request_id] [bigint] NOT NULL,
	[day_of_week] [tinyint] NOT NULL,
	[slot_id] [tinyint] NOT NULL,
 CONSTRAINT [PK_lab_usage_request_slots] PRIMARY KEY CLUSTERED 
(
	[request_id] ASC,
	[day_of_week] ASC,
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[lab_usage_request_students]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lab_usage_request_students](
	[request_id] [bigint] NOT NULL,
	[semester_id] [bigint] NOT NULL,
	[student_id] [bigint] NOT NULL,
	[added_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_lab_usage_request_students] PRIMARY KEY CLUSTERED 
(
	[request_id] ASC,
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[lab_usage_requests]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lab_usage_requests](
	[request_id] [bigint] IDENTITY(1,1) NOT NULL,
	[semester_id] [bigint] NOT NULL,
	[mentor_id] [bigint] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[request_note] [nvarchar](max) NULL,
	[approved_by] [bigint] NULL,
	[approved_at] [datetime2](0) NULL,
	[approval_note] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
	[group_name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_lab_usage_requests] PRIMARY KEY CLUSTERED 
(
	[request_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[maintenance_records]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[maintenance_records](
	[maintenance_id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset_id] [bigint] NOT NULL,
	[incident_id] [bigint] NULL,
	[quantity] [int] NOT NULL,
	[requested_by] [bigint] NOT NULL,
	[description] [nvarchar](max) NOT NULL,
	[requested_at] [datetime2](0) NOT NULL,
	[status] [varchar](15) NOT NULL,
	[approved_by] [bigint] NULL,
	[approved_at] [datetime2](0) NULL,
	[approval_note] [nvarchar](max) NULL,
	[repair_started_at] [datetime2](0) NULL,
	[repair_completed_at] [datetime2](0) NULL,
	[repair_result] [nvarchar](max) NULL,
	[note] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_maintenance_records] PRIMARY KEY CLUSTERED 
(
	[maintenance_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[responsibilities]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[responsibilities](
	[responsibility_id] [bigint] IDENTITY(1,1) NOT NULL,
	[incident_id] [bigint] NOT NULL,
	[student_id] [bigint] NOT NULL,
	[determined_by] [bigint] NOT NULL,
	[conclusion] [nvarchar](max) NOT NULL,
	[decision] [nvarchar](max) NULL,
	[status] [varchar](20) NOT NULL,
	[reviewed_by] [bigint] NULL,
	[reviewed_at] [datetime2](0) NULL,
	[review_note] [nvarchar](max) NULL,
	[resolution_note] [nvarchar](max) NULL,
	[determined_at] [datetime2](0) NOT NULL,
	[resolved_at] [datetime2](0) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_responsibilities] PRIMARY KEY CLUSTERED 
(
	[responsibility_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[semesters]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[semesters](
	[semester_id] [bigint] IDENTITY(1,1) NOT NULL,
	[code] [varchar](20) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[start_date] [date] NOT NULL,
	[end_date] [date] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_semesters] PRIMARY KEY CLUSTERED 
(
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[student_profiles]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[student_profiles](
	[student_id] [bigint] IDENTITY(1,1) NOT NULL,
	[user_id] [bigint] NOT NULL,
	[student_code] [varchar](30) NOT NULL,
	[major] [nvarchar](100) NULL,
	[cohort] [varchar](30) NULL,
	[status] [varchar](10) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_student_profiles] PRIMARY KEY CLUSTERED 
(
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[users]    Script Date: 17/08/2026 1:49:54 SA ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users](
	[user_id] [bigint] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](100) NOT NULL,
	[email] [varchar](255) NOT NULL,
	[password_hash] [varchar](255) NULL,
	[google_subject] [varchar](255) NULL,
	[role] [varchar](20) NOT NULL,
	[status] [varchar](10) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[lab_time_slots] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (1, N'SLOT_1', CAST(N'07:30:00' AS Time), CAST(N'09:50:00' AS Time))
INSERT [dbo].[lab_time_slots] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (2, N'SLOT_2', CAST(N'10:00:00' AS Time), CAST(N'12:20:00' AS Time))
INSERT [dbo].[lab_time_slots] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (3, N'SLOT_3', CAST(N'12:50:00' AS Time), CAST(N'15:10:00' AS Time))
INSERT [dbo].[lab_time_slots] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (4, N'SLOT_4', CAST(N'15:20:00' AS Time), CAST(N'17:30:00' AS Time))
GO
GO
GO

GO

GO

GO

GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_asset_categories_name]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[asset_categories] ADD  CONSTRAINT [UQ_asset_categories_name] UNIQUE NONCLUSTERED 
(
	[category_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_asset_usages_asset_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_asset_usages_asset_status] ON [dbo].[asset_usages]
(
	[asset_id] ASC,
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_asset_usages_overdue]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_asset_usages_overdue] ON [dbo].[asset_usages]
(
	[due_at] ASC
)
INCLUDE([asset_id],[student_id],[quantity]) 
WHERE ([returned_at] IS NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_asset_usages_request_student]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_asset_usages_request_student] ON [dbo].[asset_usages]
(
	[request_id] ASC,
	[semester_id] ASC,
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_asset_usages_semester]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_asset_usages_semester] ON [dbo].[asset_usages]
(
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_asset_usages_student_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_asset_usages_student_status] ON [dbo].[asset_usages]
(
	[student_id] ASC,
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_assets_code]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [UQ_assets_code] UNIQUE NONCLUSTERED 
(
	[asset_code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_assets_category]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_assets_category] ON [dbo].[assets]
(
	[category_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_assets_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_assets_status] ON [dbo].[assets]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_assets_serial_number]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_assets_serial_number] ON [dbo].[assets]
(
	[serial_number] ASC
)
WHERE ([serial_number] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_disposal_records_asset]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_disposal_records_asset] ON [dbo].[disposal_records]
(
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_disposal_records_maintenance]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_disposal_records_maintenance] ON [dbo].[disposal_records]
(
	[maintenance_id] ASC
)
WHERE ([maintenance_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_disposal_records_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_disposal_records_status] ON [dbo].[disposal_records]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_incidents_asset]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_incidents_asset] ON [dbo].[incidents]
(
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_incidents_inspection_item]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_incidents_inspection_item] ON [dbo].[incidents]
(
	[inspection_item_id] ASC
)
WHERE ([inspection_item_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_incidents_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_incidents_status] ON [dbo].[incidents]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_incidents_usage]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_incidents_usage] ON [dbo].[incidents]
(
	[asset_usage_id] ASC
)
WHERE ([asset_usage_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_inspection_items_asset]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[inspection_items] ADD  CONSTRAINT [UQ_inspection_items_asset] UNIQUE NONCLUSTERED 
(
	[inspection_id] ASC,
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_inspection_items_asset]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_inspection_items_asset] ON [dbo].[inspection_items]
(
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_inspection_records_date]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_inspection_records_date] ON [dbo].[inspection_records]
(
	[inspection_date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_inspection_records_semester]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_inspection_records_semester] ON [dbo].[inspection_records]
(
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_lab_time_slots_name]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[lab_time_slots] ADD  CONSTRAINT [UQ_lab_time_slots_name] UNIQUE NONCLUSTERED 
(
	[slot_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_lab_usage_request_slots_schedule]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_request_slots_schedule] ON [dbo].[lab_usage_request_slots]
(
	[day_of_week] ASC,
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_lab_usage_request_students_request_semester_student]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[lab_usage_request_students] ADD  CONSTRAINT [UQ_lab_usage_request_students_request_semester_student] UNIQUE NONCLUSTERED 
(
	[request_id] ASC,
	[semester_id] ASC,
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_lab_usage_request_students_semester]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_request_students_semester] ON [dbo].[lab_usage_request_students]
(
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_lab_usage_request_students_student]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_request_students_student] ON [dbo].[lab_usage_request_students]
(
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_lab_usage_requests_id_semester]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[lab_usage_requests] ADD  CONSTRAINT [UQ_lab_usage_requests_id_semester] UNIQUE NONCLUSTERED 
(
	[request_id] ASC,
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_lab_usage_requests_mentor]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_requests_mentor] ON [dbo].[lab_usage_requests]
(
	[mentor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_lab_usage_requests_semester]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_requests_semester] ON [dbo].[lab_usage_requests]
(
	[semester_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_lab_usage_requests_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_lab_usage_requests_status] ON [dbo].[lab_usage_requests]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_maintenance_records_asset]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_maintenance_records_asset] ON [dbo].[maintenance_records]
(
	[asset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_maintenance_records_incident]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_maintenance_records_incident] ON [dbo].[maintenance_records]
(
	[incident_id] ASC
)
WHERE ([incident_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_maintenance_records_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_maintenance_records_status] ON [dbo].[maintenance_records]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_responsibilities_incident]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[responsibilities] ADD  CONSTRAINT [UQ_responsibilities_incident] UNIQUE NONCLUSTERED 
(
	[incident_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_responsibilities_status]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_responsibilities_status] ON [dbo].[responsibilities]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_responsibilities_student]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE NONCLUSTERED INDEX [IX_responsibilities_student] ON [dbo].[responsibilities]
(
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_semesters_code]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[semesters] ADD  CONSTRAINT [UQ_semesters_code] UNIQUE NONCLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_student_profiles_code]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[student_profiles] ADD  CONSTRAINT [UQ_student_profiles_code] UNIQUE NONCLUSTERED 
(
	[student_code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_student_profiles_user]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[student_profiles] ADD  CONSTRAINT [UQ_student_profiles_user] UNIQUE NONCLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_users_email]    Script Date: 17/08/2026 1:49:54 SA ******/
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [UQ_users_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_users_google_subject]    Script Date: 17/08/2026 1:49:54 SA ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_users_google_subject] ON [dbo].[users]
(
	[google_subject] ASC
)
WHERE ([google_subject] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[asset_categories] ADD  CONSTRAINT [DF_asset_categories_status]  DEFAULT ('ACTIVE') FOR [status]
GO
ALTER TABLE [dbo].[asset_categories] ADD  CONSTRAINT [DF_asset_categories_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[asset_categories] ADD  CONSTRAINT [DF_asset_categories_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[asset_usages] ADD  CONSTRAINT [DF_asset_usages_quantity]  DEFAULT ((1)) FOR [quantity]
GO
ALTER TABLE [dbo].[asset_usages] ADD  CONSTRAINT [DF_asset_usages_borrowed_at]  DEFAULT (sysutcdatetime()) FOR [borrowed_at]
GO
ALTER TABLE [dbo].[asset_usages] ADD  CONSTRAINT [DF_asset_usages_status]  DEFAULT ('IN_USE') FOR [status]
GO
ALTER TABLE [dbo].[asset_usages] ADD  CONSTRAINT [DF_asset_usages_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[asset_usages] ADD  CONSTRAINT [DF_asset_usages_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [DF_assets_total_quantity]  DEFAULT ((1)) FOR [total_quantity]
GO
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [DF_assets_status]  DEFAULT ('AVAILABLE') FOR [status]
GO
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [DF_assets_is_borrowable]  DEFAULT ((1)) FOR [is_borrowable]
GO
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [DF_assets_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[assets] ADD  CONSTRAINT [DF_assets_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[disposal_records] ADD  CONSTRAINT [DF_disposal_records_quantity]  DEFAULT ((1)) FOR [quantity]
GO
ALTER TABLE [dbo].[disposal_records] ADD  CONSTRAINT [DF_disposal_records_requested_at]  DEFAULT (sysutcdatetime()) FOR [requested_at]
GO
ALTER TABLE [dbo].[disposal_records] ADD  CONSTRAINT [DF_disposal_records_status]  DEFAULT ('PENDING') FOR [status]
GO
ALTER TABLE [dbo].[disposal_records] ADD  CONSTRAINT [DF_disposal_records_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[disposal_records] ADD  CONSTRAINT [DF_disposal_records_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[incidents] ADD  CONSTRAINT [DF_incidents_affected_quantity]  DEFAULT ((1)) FOR [affected_quantity]
GO
ALTER TABLE [dbo].[incidents] ADD  CONSTRAINT [DF_incidents_status]  DEFAULT ('OPEN') FOR [status]
GO
ALTER TABLE [dbo].[incidents] ADD  CONSTRAINT [DF_incidents_reported_at]  DEFAULT (sysutcdatetime()) FOR [reported_at]
GO
ALTER TABLE [dbo].[incidents] ADD  CONSTRAINT [DF_incidents_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[incidents] ADD  CONSTRAINT [DF_incidents_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[inspection_items] ADD  CONSTRAINT [DF_inspection_items_expected_quantity]  DEFAULT ((0)) FOR [expected_quantity]
GO
ALTER TABLE [dbo].[inspection_items] ADD  CONSTRAINT [DF_inspection_items_actual_quantity]  DEFAULT ((0)) FOR [actual_quantity]
GO
ALTER TABLE [dbo].[inspection_items] ADD  CONSTRAINT [DF_inspection_items_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inspection_records] ADD  CONSTRAINT [DF_inspection_records_date]  DEFAULT (sysutcdatetime()) FOR [inspection_date]
GO
ALTER TABLE [dbo].[inspection_records] ADD  CONSTRAINT [DF_inspection_records_status]  DEFAULT ('DRAFT') FOR [status]
GO
ALTER TABLE [dbo].[inspection_records] ADD  CONSTRAINT [DF_inspection_records_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inspection_records] ADD  CONSTRAINT [DF_inspection_records_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[lab_usage_request_students] ADD  CONSTRAINT [DF_lab_usage_request_students_added_at]  DEFAULT (sysutcdatetime()) FOR [added_at]
GO
ALTER TABLE [dbo].[lab_usage_requests] ADD  CONSTRAINT [DF_lab_usage_requests_status]  DEFAULT ('PENDING') FOR [status]
GO
ALTER TABLE [dbo].[lab_usage_requests] ADD  CONSTRAINT [DF_lab_usage_requests_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[lab_usage_requests] ADD  CONSTRAINT [DF_lab_usage_requests_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[lab_usage_requests] ADD  CONSTRAINT [DF_lab_usage_requests_group_name]  DEFAULT (N'Legacy group') FOR [group_name]
GO
ALTER TABLE [dbo].[maintenance_records] ADD  CONSTRAINT [DF_maintenance_records_quantity]  DEFAULT ((1)) FOR [quantity]
GO
ALTER TABLE [dbo].[maintenance_records] ADD  CONSTRAINT [DF_maintenance_records_requested_at]  DEFAULT (sysutcdatetime()) FOR [requested_at]
GO
ALTER TABLE [dbo].[maintenance_records] ADD  CONSTRAINT [DF_maintenance_records_status]  DEFAULT ('PENDING') FOR [status]
GO
ALTER TABLE [dbo].[maintenance_records] ADD  CONSTRAINT [DF_maintenance_records_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[maintenance_records] ADD  CONSTRAINT [DF_maintenance_records_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[responsibilities] ADD  CONSTRAINT [DF_responsibilities_determined_at]  DEFAULT (sysutcdatetime()) FOR [determined_at]
GO
ALTER TABLE [dbo].[responsibilities] ADD  CONSTRAINT [DF_responsibilities_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[responsibilities] ADD  CONSTRAINT [DF_responsibilities_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[semesters] ADD  CONSTRAINT [DF_semesters_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[semesters] ADD  CONSTRAINT [DF_semesters_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[student_profiles] ADD  CONSTRAINT [DF_student_profiles_status]  DEFAULT ('ACTIVE') FOR [status]
GO
ALTER TABLE [dbo].[student_profiles] ADD  CONSTRAINT [DF_student_profiles_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[student_profiles] ADD  CONSTRAINT [DF_student_profiles_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_status]  DEFAULT ('ACTIVE') FOR [status]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [FK_asset_usages_asset] FOREIGN KEY([asset_id])
REFERENCES [dbo].[assets] ([asset_id])
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [FK_asset_usages_asset]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [FK_asset_usages_creator] FOREIGN KEY([created_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [FK_asset_usages_creator]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [FK_asset_usages_request_student] FOREIGN KEY([request_id], [semester_id], [student_id])
REFERENCES [dbo].[lab_usage_request_students] ([request_id], [semester_id], [student_id])
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [FK_asset_usages_request_student]
GO
ALTER TABLE [dbo].[assets]  WITH CHECK ADD  CONSTRAINT [FK_assets_category] FOREIGN KEY([category_id])
REFERENCES [dbo].[asset_categories] ([category_id])
GO
ALTER TABLE [dbo].[assets] CHECK CONSTRAINT [FK_assets_category]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [FK_disposal_records_approver] FOREIGN KEY([approved_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [FK_disposal_records_approver]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [FK_disposal_records_asset] FOREIGN KEY([asset_id])
REFERENCES [dbo].[assets] ([asset_id])
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [FK_disposal_records_asset]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [FK_disposal_records_maintenance] FOREIGN KEY([maintenance_id])
REFERENCES [dbo].[maintenance_records] ([maintenance_id])
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [FK_disposal_records_maintenance]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [FK_disposal_records_requester] FOREIGN KEY([requested_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [FK_disposal_records_requester]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [FK_incidents_asset] FOREIGN KEY([asset_id])
REFERENCES [dbo].[assets] ([asset_id])
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [FK_incidents_asset]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [FK_incidents_inspection_item] FOREIGN KEY([inspection_item_id])
REFERENCES [dbo].[inspection_items] ([inspection_item_id])
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [FK_incidents_inspection_item]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [FK_incidents_reporter] FOREIGN KEY([reported_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [FK_incidents_reporter]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [FK_incidents_usage] FOREIGN KEY([asset_usage_id])
REFERENCES [dbo].[asset_usages] ([asset_usage_id])
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [FK_incidents_usage]
GO
ALTER TABLE [dbo].[inspection_items]  WITH CHECK ADD  CONSTRAINT [FK_inspection_items_asset] FOREIGN KEY([asset_id])
REFERENCES [dbo].[assets] ([asset_id])
GO
ALTER TABLE [dbo].[inspection_items] CHECK CONSTRAINT [FK_inspection_items_asset]
GO
ALTER TABLE [dbo].[inspection_items]  WITH CHECK ADD  CONSTRAINT [FK_inspection_items_inspection] FOREIGN KEY([inspection_id])
REFERENCES [dbo].[inspection_records] ([inspection_id])
GO
ALTER TABLE [dbo].[inspection_items] CHECK CONSTRAINT [FK_inspection_items_inspection]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [FK_inspection_records_inspector] FOREIGN KEY([inspected_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [FK_inspection_records_inspector]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [FK_inspection_records_semester] FOREIGN KEY([semester_id])
REFERENCES [dbo].[semesters] ([semester_id])
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [FK_inspection_records_semester]
GO
ALTER TABLE [dbo].[lab_usage_request_slots]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_request_slots_request] FOREIGN KEY([request_id])
REFERENCES [dbo].[lab_usage_requests] ([request_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[lab_usage_request_slots] CHECK CONSTRAINT [FK_lab_usage_request_slots_request]
GO
ALTER TABLE [dbo].[lab_usage_request_slots]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_request_slots_slot] FOREIGN KEY([slot_id])
REFERENCES [dbo].[lab_time_slots] ([slot_id])
GO
ALTER TABLE [dbo].[lab_usage_request_slots] CHECK CONSTRAINT [FK_lab_usage_request_slots_slot]
GO
ALTER TABLE [dbo].[lab_usage_request_students]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_request_students_request] FOREIGN KEY([request_id], [semester_id])
REFERENCES [dbo].[lab_usage_requests] ([request_id], [semester_id])
GO
ALTER TABLE [dbo].[lab_usage_request_students] CHECK CONSTRAINT [FK_lab_usage_request_students_request]
GO
ALTER TABLE [dbo].[lab_usage_request_students]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_request_students_student] FOREIGN KEY([student_id])
REFERENCES [dbo].[student_profiles] ([student_id])
GO
ALTER TABLE [dbo].[lab_usage_request_students] CHECK CONSTRAINT [FK_lab_usage_request_students_student]
GO
ALTER TABLE [dbo].[lab_usage_requests]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_requests_approver] FOREIGN KEY([approved_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[lab_usage_requests] CHECK CONSTRAINT [FK_lab_usage_requests_approver]
GO
ALTER TABLE [dbo].[lab_usage_requests]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_requests_mentor] FOREIGN KEY([mentor_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[lab_usage_requests] CHECK CONSTRAINT [FK_lab_usage_requests_mentor]
GO
ALTER TABLE [dbo].[lab_usage_requests]  WITH CHECK ADD  CONSTRAINT [FK_lab_usage_requests_semester] FOREIGN KEY([semester_id])
REFERENCES [dbo].[semesters] ([semester_id])
GO
ALTER TABLE [dbo].[lab_usage_requests] CHECK CONSTRAINT [FK_lab_usage_requests_semester]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [FK_maintenance_records_approver] FOREIGN KEY([approved_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [FK_maintenance_records_approver]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [FK_maintenance_records_asset] FOREIGN KEY([asset_id])
REFERENCES [dbo].[assets] ([asset_id])
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [FK_maintenance_records_asset]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [FK_maintenance_records_incident] FOREIGN KEY([incident_id])
REFERENCES [dbo].[incidents] ([incident_id])
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [FK_maintenance_records_incident]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [FK_maintenance_records_requester] FOREIGN KEY([requested_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [FK_maintenance_records_requester]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [FK_responsibilities_determiner] FOREIGN KEY([determined_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [FK_responsibilities_determiner]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [FK_responsibilities_incident] FOREIGN KEY([incident_id])
REFERENCES [dbo].[incidents] ([incident_id])
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [FK_responsibilities_incident]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [FK_responsibilities_reviewer] FOREIGN KEY([reviewed_by])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [FK_responsibilities_reviewer]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [FK_responsibilities_student] FOREIGN KEY([student_id])
REFERENCES [dbo].[student_profiles] ([student_id])
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [FK_responsibilities_student]
GO
ALTER TABLE [dbo].[student_profiles]  WITH CHECK ADD  CONSTRAINT [FK_student_profiles_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[student_profiles] CHECK CONSTRAINT [FK_student_profiles_user]
GO
ALTER TABLE [dbo].[asset_categories]  WITH CHECK ADD  CONSTRAINT [CK_asset_categories_status] CHECK  (([status]='INACTIVE' OR [status]='ACTIVE'))
GO
ALTER TABLE [dbo].[asset_categories] CHECK CONSTRAINT [CK_asset_categories_status]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_condition_after] CHECK  (([condition_after] IS NULL OR ([condition_after]='BROKEN' OR [condition_after]='DAMAGED' OR [condition_after]='FAIR' OR [condition_after]='GOOD')))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_condition_after]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_condition_before] CHECK  (([condition_before]='BROKEN' OR [condition_before]='DAMAGED' OR [condition_before]='FAIR' OR [condition_before]='GOOD'))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_condition_before]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_dates] CHECK  (([due_at]>=[borrowed_at] AND ([returned_at] IS NULL OR [returned_at]>=[borrowed_at])))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_dates]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_quantity]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_return] CHECK  (([status]='IN_USE' AND [returned_at] IS NULL OR [status]='RETURNED' AND [returned_at] IS NOT NULL AND [condition_after] IS NOT NULL))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_return]
GO
ALTER TABLE [dbo].[asset_usages]  WITH CHECK ADD  CONSTRAINT [CK_asset_usages_status] CHECK  (([status]='RETURNED' OR [status]='IN_USE'))
GO
ALTER TABLE [dbo].[asset_usages] CHECK CONSTRAINT [CK_asset_usages_status]
GO
ALTER TABLE [dbo].[assets]  WITH CHECK ADD  CONSTRAINT [CK_assets_condition] CHECK  (([condition]='BROKEN' OR [condition]='DAMAGED' OR [condition]='FAIR' OR [condition]='GOOD'))
GO
ALTER TABLE [dbo].[assets] CHECK CONSTRAINT [CK_assets_condition]
GO
ALTER TABLE [dbo].[assets]  WITH CHECK ADD  CONSTRAINT [CK_assets_quantity] CHECK  (([total_quantity]>(0) AND ([tracking_mode]='QUANTITY' OR [total_quantity]=(1))))
GO
ALTER TABLE [dbo].[assets] CHECK CONSTRAINT [CK_assets_quantity]
GO
ALTER TABLE [dbo].[assets]  WITH CHECK ADD  CONSTRAINT [CK_assets_status] CHECK  (([status]='DISPOSED' OR [status]='UNAVAILABLE' OR [status]='MAINTENANCE' OR [status]='AVAILABLE'))
GO
ALTER TABLE [dbo].[assets] CHECK CONSTRAINT [CK_assets_status]
GO
ALTER TABLE [dbo].[assets]  WITH CHECK ADD  CONSTRAINT [CK_assets_tracking_mode] CHECK  (([tracking_mode]='QUANTITY' OR [tracking_mode]='SERIALIZED'))
GO
ALTER TABLE [dbo].[assets] CHECK CONSTRAINT [CK_assets_tracking_mode]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [CK_disposal_records_approval] CHECK  (([status]='PENDING' AND [approved_by] IS NULL AND [approved_at] IS NULL OR ([status]='COMPLETED' OR [status]='REJECTED' OR [status]='APPROVED') AND [approved_by] IS NOT NULL AND [approved_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [CK_disposal_records_approval]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [CK_disposal_records_completion] CHECK  (([status]='COMPLETED' AND [completed_at] IS NOT NULL OR [status]<>'COMPLETED' AND [completed_at] IS NULL))
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [CK_disposal_records_completion]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [CK_disposal_records_quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [CK_disposal_records_quantity]
GO
ALTER TABLE [dbo].[disposal_records]  WITH CHECK ADD  CONSTRAINT [CK_disposal_records_status] CHECK  (([status]='COMPLETED' OR [status]='REJECTED' OR [status]='APPROVED' OR [status]='PENDING'))
GO
ALTER TABLE [dbo].[disposal_records] CHECK CONSTRAINT [CK_disposal_records_status]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [CK_incidents_dates] CHECK  (([occurred_at] IS NULL OR [occurred_at]<=[reported_at]))
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [CK_incidents_dates]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [CK_incidents_quantity] CHECK  (([affected_quantity]>(0)))
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [CK_incidents_quantity]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [CK_incidents_severity] CHECK  (([severity]='CRITICAL' OR [severity]='HIGH' OR [severity]='MEDIUM' OR [severity]='LOW'))
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [CK_incidents_severity]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [CK_incidents_status] CHECK  (([status]='CLOSED' OR [status]='RESOLVED' OR [status]='INVESTIGATING' OR [status]='OPEN'))
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [CK_incidents_status]
GO
ALTER TABLE [dbo].[incidents]  WITH CHECK ADD  CONSTRAINT [CK_incidents_type] CHECK  (([incident_type]='OTHER' OR [incident_type]='MALFUNCTION' OR [incident_type]='LOSS' OR [incident_type]='MISSING' OR [incident_type]='DAMAGE'))
GO
ALTER TABLE [dbo].[incidents] CHECK CONSTRAINT [CK_incidents_type]
GO
ALTER TABLE [dbo].[inspection_items]  WITH CHECK ADD  CONSTRAINT [CK_inspection_items_actual_condition] CHECK  (([actual_condition] IS NULL OR ([actual_condition]='BROKEN' OR [actual_condition]='DAMAGED' OR [actual_condition]='FAIR' OR [actual_condition]='GOOD')))
GO
ALTER TABLE [dbo].[inspection_items] CHECK CONSTRAINT [CK_inspection_items_actual_condition]
GO
ALTER TABLE [dbo].[inspection_items]  WITH CHECK ADD  CONSTRAINT [CK_inspection_items_expected_condition] CHECK  (([expected_condition] IS NULL OR ([expected_condition]='BROKEN' OR [expected_condition]='DAMAGED' OR [expected_condition]='FAIR' OR [expected_condition]='GOOD')))
GO
ALTER TABLE [dbo].[inspection_items] CHECK CONSTRAINT [CK_inspection_items_expected_condition]
GO
ALTER TABLE [dbo].[inspection_items]  WITH CHECK ADD  CONSTRAINT [CK_inspection_items_quantity] CHECK  (([expected_quantity]>=(0) AND [actual_quantity]>=(0)))
GO
ALTER TABLE [dbo].[inspection_items] CHECK CONSTRAINT [CK_inspection_items_quantity]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [CK_inspection_records_result] CHECK  (([status]='DRAFT' AND [result] IS NULL OR [status]='COMPLETED' AND ([result]='DISCREPANCY_FOUND' OR [result]='NORMAL')))
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [CK_inspection_records_result]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [CK_inspection_records_scope] CHECK  (([scope]='SELECTED_ASSETS' OR [scope]='WHOLE_LAB'))
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [CK_inspection_records_scope]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [CK_inspection_records_status] CHECK  (([status]='COMPLETED' OR [status]='DRAFT'))
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [CK_inspection_records_status]
GO
ALTER TABLE [dbo].[inspection_records]  WITH CHECK ADD  CONSTRAINT [CK_inspection_records_type] CHECK  (([inspection_type]='INVENTORY' OR [inspection_type]='INSPECTION'))
GO
ALTER TABLE [dbo].[inspection_records] CHECK CONSTRAINT [CK_inspection_records_type]
GO
ALTER TABLE [dbo].[lab_time_slots]  WITH CHECK ADD  CONSTRAINT [CK_lab_time_slots_id] CHECK  (([slot_id]>=(1) AND [slot_id]<=(4)))
GO
ALTER TABLE [dbo].[lab_time_slots] CHECK CONSTRAINT [CK_lab_time_slots_id]
GO
ALTER TABLE [dbo].[lab_time_slots]  WITH CHECK ADD  CONSTRAINT [CK_lab_time_slots_time] CHECK  (([start_time]<[end_time]))
GO
ALTER TABLE [dbo].[lab_time_slots] CHECK CONSTRAINT [CK_lab_time_slots_time]
GO
ALTER TABLE [dbo].[lab_usage_request_slots]  WITH CHECK ADD  CONSTRAINT [CK_lab_usage_request_slots_day] CHECK  (([day_of_week]>=(2) AND [day_of_week]<=(7)))
GO
ALTER TABLE [dbo].[lab_usage_request_slots] CHECK CONSTRAINT [CK_lab_usage_request_slots_day]
GO
ALTER TABLE [dbo].[lab_usage_requests]  WITH CHECK ADD  CONSTRAINT [CK_lab_usage_requests_approval] CHECK  (([status]='PENDING' AND [approved_by] IS NULL AND [approved_at] IS NULL OR ([status]='REJECTED' OR [status]='APPROVED') AND [approved_by] IS NOT NULL AND [approved_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[lab_usage_requests] CHECK CONSTRAINT [CK_lab_usage_requests_approval]
GO
ALTER TABLE [dbo].[lab_usage_requests]  WITH CHECK ADD  CONSTRAINT [CK_lab_usage_requests_status] CHECK  (([status]='REJECTED' OR [status]='APPROVED' OR [status]='PENDING'))
GO
ALTER TABLE [dbo].[lab_usage_requests] CHECK CONSTRAINT [CK_lab_usage_requests_status]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [CK_maintenance_records_approval] CHECK  (([status]='PENDING' AND [approved_by] IS NULL AND [approved_at] IS NULL OR ([status]='COMPLETED' OR [status]='IN_PROGRESS' OR [status]='REJECTED' OR [status]='APPROVED') AND [approved_by] IS NOT NULL AND [approved_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [CK_maintenance_records_approval]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [CK_maintenance_records_completion] CHECK  (([status]<>'COMPLETED' OR [repair_started_at] IS NOT NULL AND [repair_completed_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [CK_maintenance_records_completion]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [CK_maintenance_records_dates] CHECK  ((([repair_started_at] IS NULL OR [repair_started_at]>=[approved_at]) AND ([repair_completed_at] IS NULL OR [repair_started_at] IS NOT NULL AND [repair_completed_at]>=[repair_started_at])))
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [CK_maintenance_records_dates]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [CK_maintenance_records_quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [CK_maintenance_records_quantity]
GO
ALTER TABLE [dbo].[maintenance_records]  WITH CHECK ADD  CONSTRAINT [CK_maintenance_records_status] CHECK  (([status]='COMPLETED' OR [status]='IN_PROGRESS' OR [status]='REJECTED' OR [status]='APPROVED' OR [status]='PENDING'))
GO
ALTER TABLE [dbo].[maintenance_records] CHECK CONSTRAINT [CK_maintenance_records_status]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [CK_responsibilities_resolution] CHECK  (([status]='RESOLVED' AND [resolved_at] IS NOT NULL OR [status]<>'RESOLVED' AND [resolved_at] IS NULL))
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [CK_responsibilities_resolution]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [CK_responsibilities_review_pair] CHECK  (([reviewed_by] IS NULL AND [reviewed_at] IS NULL OR [reviewed_by] IS NOT NULL AND [reviewed_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [CK_responsibilities_review_pair]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [CK_responsibilities_review_status] CHECK  ((NOT ([status]='REJECTED' OR [status]='APPROVED') OR [reviewed_by] IS NOT NULL AND [reviewed_at] IS NOT NULL))
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [CK_responsibilities_review_status]
GO
ALTER TABLE [dbo].[responsibilities]  WITH CHECK ADD  CONSTRAINT [CK_responsibilities_status] CHECK  (([status]='RESOLVED' OR [status]='REJECTED' OR [status]='APPROVED' OR [status]='PENDING_REVIEW' OR [status]='CONFIRMED'))
GO
ALTER TABLE [dbo].[responsibilities] CHECK CONSTRAINT [CK_responsibilities_status]
GO
ALTER TABLE [dbo].[semesters]  WITH CHECK ADD  CONSTRAINT [CK_semesters_dates] CHECK  (([start_date]<=[end_date]))
GO
ALTER TABLE [dbo].[semesters] CHECK CONSTRAINT [CK_semesters_dates]
GO
ALTER TABLE [dbo].[semesters]  WITH CHECK ADD  CONSTRAINT [CK_semesters_status] CHECK  (([status]='CLOSED' OR [status]='ACTIVE' OR [status]='UPCOMING'))
GO
ALTER TABLE [dbo].[semesters] CHECK CONSTRAINT [CK_semesters_status]
GO
ALTER TABLE [dbo].[student_profiles]  WITH CHECK ADD  CONSTRAINT [CK_student_profiles_status] CHECK  (([status]='INACTIVE' OR [status]='ACTIVE'))
GO
ALTER TABLE [dbo].[student_profiles] CHECK CONSTRAINT [CK_student_profiles_status]
GO
ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [CK_users_role] CHECK  (([role]='STUDENT' OR [role]='MENTOR' OR [role]='LAB_MANAGER' OR [role]='ADMIN'))
GO
ALTER TABLE [dbo].[users] CHECK CONSTRAINT [CK_users_role]
GO
ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [CK_users_status] CHECK  (([status]='INACTIVE' OR [status]='ACTIVE'))
GO
ALTER TABLE [dbo].[users] CHECK CONSTRAINT [CK_users_status]
GO
