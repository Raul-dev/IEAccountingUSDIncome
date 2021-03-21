
GO

/****** Object:  Table [dbo].[FactIncomeHistory]    Script Date: 2/23/2021 3:12:23 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactIncomeHistory]') AND type in (N'U'))
DROP TABLE [dbo].[FactIncomeHistory]
GO

/****** Object:  Table [dbo].[FactIncomeHistory]    Script Date: 2/23/2021 3:12:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactIncomeHistory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DateID] [int] NULL,
	[BatchID] [int] NULL,
	[IncomeUSD] [money] NULL,
	[NaturalKey] [uniqueidentifier] NULL,
	[VersionKey] [uniqueidentifier] NULL,
	[ExchangeDateID] [int] NULL,
	[ExchangeValue] [money] NULL,
	[ExchangeRate] [money] NULL,
	[EndBatchID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[ChangeDate] [datetime] NULL,
 CONSTRAINT [PK_FactIncomeHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

