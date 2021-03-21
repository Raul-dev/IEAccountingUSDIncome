
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[upload].[CbrUsdRate]') AND type in (N'U'))
DROP TABLE [upload].[CbrUsdRate]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [upload].[CbrUsdRate](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Date] datetime NULL,
	[ExchangeRates] [money] NULL
) ON [PRIMARY]
GO


