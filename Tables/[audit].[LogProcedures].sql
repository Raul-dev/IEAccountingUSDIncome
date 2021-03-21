IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'audit' )
    EXEC('CREATE SCHEMA [audit]');

GO

/****** Object:  Table [audit].[LogProcedures]    Script Date: 2/12/2021 2:05:01 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[audit].[LogProcedures]') AND type in (N'U'))
DROP TABLE [audit].[LogProcedures]
GO


/****** Object:  Table [audit].[LogProcedures]    Script Date: 2/12/2021 12:37:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [audit].[LogProcedures](
	[LogID] [BIGINT] IDENTITY(1,1) NOT NULL,
	[MainID] [BIGINT] NULL,
	[ParentID] [BIGINT] NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[Duration] [int] NULL,
	[RowCount] [int] NULL,
	[SYS_USER_NAME] [varchar](256) NOT NULL,
	[SYS_HOST_NAME] [varchar](100) NOT NULL,
	[SYS_APP_NAME] [varchar](128) NOT NULL,
	[SPID] [int] NOT NULL,
	[SPName] [varchar](512) NULL,
	[SPParams] [varchar](max) NULL,
	[SPInfo] [varchar](max) NULL,
	[ErrorMessage] [varchar](2048) NULL,
	[TransactionCount] [int] NULL,
 CONSTRAINT [PK_audit_LogProcedures] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [audit] 
GO

ALTER TABLE [audit].[LogProcedures] ADD  CONSTRAINT [[DF_LogProcedures_start_datetime]]]  DEFAULT (getdate()) FOR [StartTime]
GO

ALTER TABLE [audit].[LogProcedures] ADD  CONSTRAINT [[DF_LogProcedures_sys_user_name]]]  DEFAULT (original_login()) FOR [sys_user_name]
GO

ALTER TABLE [audit].[LogProcedures] ADD  CONSTRAINT [[DF_LogProcedures_sys_host_name]]]  DEFAULT (host_name()) FOR [sys_host_name]
GO

ALTER TABLE [audit].[LogProcedures] ADD  CONSTRAINT [[DF_LogProcedures_sys_app_name]]]  DEFAULT (app_name()) FOR [sys_app_name]
GO

ALTER TABLE [audit].[LogProcedures] ADD  CONSTRAINT [DF_LogProcedures_spid]  DEFAULT (@@spid) FOR [spid]
GO


