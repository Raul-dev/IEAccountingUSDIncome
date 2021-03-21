
/****** Object:  Table [dbo].[DimExchRateUSD]    Script Date: 2/23/2021 7:56:10 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimExchRateUSD]') AND type in (N'U'))
DROP TABLE [dbo].[DimExchRateUSD]
GO

/****** Object:  Table [dbo].[DimExchRateUSD]    Script Date: 2/23/2021 7:56:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimExchRateUSD](
	[DateID] [int] NOT NULL,
	[BatchID] [int] NULL,
	[ExchangeRates] [money] NOT NULL,
	[CreateDate] [datetime] NULL,
 CONSTRAINT [PK_DimExchRateUSD] PRIMARY KEY CLUSTERED 
(
	[DateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


