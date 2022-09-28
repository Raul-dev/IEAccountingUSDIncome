
GO

/****** Object:  Table [staging].[FactIncomeHistory]    Script Date: 2/23/2021 3:11:05 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[staging].[FactIncomeHistory]') AND type in (N'U'))
DROP TABLE [staging].[FactIncomeHistory]
GO

/****** Object:  Table [staging].[FactIncomeHistory]    Script Date: 2/23/2021 3:11:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [staging].[FactIncomeHistory](
	[ID] [int] NULL,
	[DateID] [int] NULL,
	[BatchID] [int] NULL,
	[IncomeUSD] [money] NULL,
	[NaturalKey] [uniqueidentifier] NULL,
	[VersionKey] [uniqueidentifier] NULL,
	[ExchangeDateID] [int] NULL,
	[ExchangeValue] [money] NULL,
	[ExchangeRate] [money] NULL,
	[EndBatchID] [int] NULL,
	[LotOrder] [int] NULL
) ON [PRIMARY]
GO


