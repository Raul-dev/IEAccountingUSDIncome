
GO

/****** Object:  Table [dbo].[DimBatch]    Script Date: 2/23/2021 2:21:40 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimBatch]') AND type in (N'U'))
DROP TABLE [dbo].[DimBatch]
GO

/****** Object:  Table [dbo].[DimBatch]    Script Date: 2/23/2021 2:21:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimBatch](
	[BatchID] [int] IDENTITY(1,1) NOT NULL,
	[DateID] [int] NULL,
	[CreateDate] [datetime] NULL,
 CONSTRAINT [PK_DimBatch] PRIMARY KEY CLUSTERED 
(
	[BatchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


