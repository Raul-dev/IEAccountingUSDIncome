
GO

/****** Object:  Table [dbo].[FactIncome]    Script Date: 2/23/2021 8:14:03 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactIncome]') AND type in (N'U'))
DROP TABLE [dbo].[FactIncome]
GO

/****** Object:  Table [dbo].[FactIncome]    Script Date: 2/23/2021 8:14:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactIncome](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DateID] [int] NULL,
	[BatchID] [int] NULL,
	[IncomeValue] [money] NULL,
	[CreateDate] [datetime] NULL,
 CONSTRAINT [PK_FactIncome] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

