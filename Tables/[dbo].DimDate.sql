
GO

/****** Object:  Table [dbo].[DimDate]    Script Date: 2/21/2021 10:01:29 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimDate]') AND type in (N'U'))
DROP TABLE [dbo].[DimDate]
GO

/****** Object:  Table [dbo].[DimDate]    Script Date: 2/21/2021 10:01:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimDate](
	[DateID] [int] NOT NULL,
	[FullDateAlternateKey] [date] NOT NULL,
	[DayNumberOfYear] [smallint] NOT NULL,
	[DayNumberOfMonth] [tinyint] NOT NULL,
	[DayNumberOfQuarter] [tinyint] NOT NULL,
	[MonthNumberOfYear] [tinyint] NOT NULL,
	[MonthNumberOfQuarter] [tinyint] NOT NULL,
	[CalendarQuarter] [tinyint] NOT NULL,
	[CalendarYear] [smallint] NOT NULL,
	[DayName] [nvarchar](14) NOT NULL,
	[MonthName] [nvarchar](14) NOT NULL,
	LastOfMonth [date] NOT NULL,
	FirstOfQuarter [date] NOT NULL,
	LastOfQuarter [date] NOT NULL,
	
	[EnglishDayName]  AS (datename(week,[FullDateAlternateKey])),
	[EnglishMonthName]  AS (datename(month,[FullDateAlternateKey])),
	[SimpleRussianDate]  AS (format([FullDateAlternateKey],'d','ru-ru')),
 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
(
	[DateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
