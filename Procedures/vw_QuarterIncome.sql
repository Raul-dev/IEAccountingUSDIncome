
CREATE VIEW vw_QuarterIncome
AS
SELECT CalendarYear, CalendarQuarter, SUM(IncomeValue) IncomeValue FROM [dbo].[FactIncome] f 
  INNER JOIN [dbo].[DimDate] d ON f.DateID = d.DateID
GROUP BY CalendarYear, CalendarQuarter