

/****** Object:  Table [meta].[CONFIG]    Script Date: 2/12/2021 2:11:28 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[meta].[ConfigApp]') AND type in (N'U'))
DROP TABLE [meta].[ConfigApp]
GO

/****** Object:  Table [meta].[CONFIG]    Script Date: 2/12/2021 2:11:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [meta].[ConfigApp](
	[Parameter] [nvarchar](128) NOT NULL ,
	[StrValue] [nvarchar](256) NULL,
	
	CONSTRAINT [PK_audit_LogProcedures] PRIMARY KEY CLUSTERED 
	(
		[Parameter] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	
 )
GO


