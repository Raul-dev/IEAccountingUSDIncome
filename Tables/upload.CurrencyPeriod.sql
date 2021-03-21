
GO

/****** Object:  Table [dbo].[DimBatch]    Script Date: 3/8/2021 4:16:30 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[upload].[CurrencyPeriod]') AND type in (N'U'))
DROP TABLE [upload].[CurrencyPeriod]
GO

/****** Object:  Table [dbo].[DimBatch]    Script Date: 3/8/2021 4:16:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [upload].[CurrencyPeriod](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BatchID] [int] NOT NULL,
	[DateID_Start] [int] NOT NULL,
	[DateID_End] [int] NOT NULL,
	[CreateDate] [datetime] NULL,
 CONSTRAINT [PK_CurrencyPeriod] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


