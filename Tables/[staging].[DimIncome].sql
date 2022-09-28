
GO

/****** Object:  Table [staging].[DimIncome]    Script Date: 2/23/2021 12:59:11 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[staging].[DimIncome]') AND type in (N'U'))
DROP TABLE [staging].[DimIncome]
GO

/****** Object:  Table [staging].[DimIncome]    Script Date: 2/23/2021 12:59:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [staging].[DimIncome](
	[ID] [int] NULL,
	[DateID] [int] NULL,
	[BatchID] [int] NULL,
	[IncomeUSD] [money] NULL,
	[NaturalKey] [uniqueidentifier] NULL,
	[ExchangeDate] [int] NULL,
	[ExchangeValue] [money] NULL,
	[ExchangeRate] [money] NULL,
	[CreateDate] [datetime] NULL,
	[ChangeDate] [datetime] NULL
) ON [PRIMARY]
GO


