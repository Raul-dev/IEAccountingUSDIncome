
GO

/****** Object:  Table [upload].[IncomeBook]    Script Date: 2/23/2021 3:04:39 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[upload].[IncomeBook]') AND type in (N'U'))
DROP TABLE [upload].[IncomeBook]
GO

/****** Object:  Table [upload].[IncomeBook]    Script Date: 2/23/2021 3:04:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [upload].[IncomeBook](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[IncomeUsd] [money] NULL,
	[ExchangeDate] [datetime] NULL,
	[ExchangeValue] [money] NULL,
	[ExchangeRate] [money] NULL,
) ON [PRIMARY]
GO


