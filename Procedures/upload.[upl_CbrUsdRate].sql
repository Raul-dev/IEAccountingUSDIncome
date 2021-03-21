

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'upl_CbrUsdRate' AND o.type = N'P' AND s.name = N'upload'  )
    EXEC('DROP PROCEDURE [upload].[upl_CbrUsdRate]');
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/* 
Example:
EXEC [upload].[upl_CbrUsdRate] '20200101', '20201231'
EXEC [upload].[upl_CbrUsdRate] '20200101', '20200102'
DECLARE @xmlString varchar(max)
EXEC [upload].[upl_LoadXMLFromFile] 'http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=01.01.2020&date_req2=29.05.2020&VAL_NM_RQ=R01235', @xmlString output
EXEC [audit].[sp_Print] @xmlString
INSERT [meta].[ConfigApp] (Parameter, StrValue) VALUES( 'ExcelFileIncomeBook','E:\Work\SQL\IndividualEntrepreneur\IncomeBook.xlsx')

SELECT * FROM [upload].[CbrUsdRate]


*/
CREATE PROC [upload].[upl_CbrUsdRate]
 @FromDate datetime = NULL, 
 @ToDate datetime = NULL,
 @ErrMessage nvarchar(max) = NULL OUTPUT
AS
BEGIN
	SET CONCAT_NULL_YIELDS_NULL ON
	DECLARE @SPName varchar(510), @SPParams varchar(max), @SPInfo varchar(max), @LogID int, @RowCount int 
	IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
		CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)
		
	SET	@SPName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'			
    IF @FromDate is NULL OR @ToDate is NULL
	BEGIN
		SET @FromDate = DATEFROMPARTS(YEAR(GetDate()), 1, 1)
		SET @ToDate = DATEFROMPARTS(YEAR(GetDate()), 12, 31)
	END
	SET @SPParams = '@FromDate=' +CAST(@FromDate as nvarchar(11))+'; @ToDate='+CAST(@ToDate as nvarchar(11))+';'
	EXEC audit.sp_AuditStart @SPName = @SPName, @SPParams = @SPParams, @LogID = @LogID OUTPUT

SET XACT_ABORT OFF

SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @AuditMessage       nvarchar(max) 
DECLARE @Trancnt				int
DECLARE @OverridePrintEnabling		bit
DECLARE @res				int
DECLARE @OpenRowSet			nvarchar(max) 
DECLARE @sqlcmd				nvarchar(max) 
DECLARE @NewVersionCount    int
SET @OverridePrintEnabling = 0
SET @AuditMessage = '[upload].[upl_CbrUsdRate]; start'
EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling

BEGIN TRY

	SET @Trancnt = @@TRANCOUNT
	IF @Trancnt > 0 SAVE TRAN tr_CbrUsdRate_Upload ELSE BEGIN TRAN;

	DECLARE @xmlString varchar(max)
	DECLARE @url varchar(255)
	DECLARE @h int
	DECLARE @StartDate datetime
	DECLARE @FinishDate datetime
	DECLARE @RowCounttmp int
	
	DECLARE @MaxCount int

	SET @FromDate = DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), DAY(@FromDate))
	IF( @ToDate > GetDate())
		SET @ToDate = DATEFROMPARTS(YEAR(GetDate()), MONTH(GetDate()), DAY(GetDate()))
	ELSE
		SET @ToDate = DATEFROMPARTS(YEAR(@ToDate), MONTH(@ToDate), DAY(@ToDate))
	
	
	IF ( DATEDIFF(dd, @FromDate, @ToDate) < 0 )
		RAISERROR( N'Error: Parameter @FromDate must be be less than @ToDate.', 16, 1)
	

	SET @StartDate = @FromDate
	IF ( DATEDIFF(dd, @FromDate, @ToDate ) > 54 )
		SET @FinishDate = DATEADD(dd, 55, @StartDate) - 1
	ELSE
		SET @FinishDate = @ToDate

	SET @MaxCount = 0


	WHILE (@MaxCount < 45 ) -- Maximum 5 year
	BEGIN
		
		SELECT  @url = 'http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1='+
			Convert(char(10), @StartDate, 104)+'&date_req2='+
			Convert(char(10), @FinishDate, 104)+'&VAL_NM_RQ=R01235'
		print @url
		SET @xmlString = NULL
		exec [upload].upl_LoadXMLFromFile
			@url, 
			@xmlString output

		EXEC sp_xml_preparedocument  @h output, @xmlString
		
		
		INSERT [upload].[CbrUsdRate] ( Date, ExchangeRates)
		SELECT  
			(DATEFROMPARTS(CAST(SUBSTRING(date,7,4) AS int), CAST(SUBSTRING(date,4,2) AS int), CAST(SUBSTRING(date,1,2) AS int))) [Date], 
			Convert(money, replace(Value, ',', '.')) ExchangeRates 
		FROM 
			OpenXML (@h, '//Record', 0)
		WITH 
		(
			[Date] char(10) '@Date',
			Nominal int './Nominal',
			Value varchar(10) './Value'
		)
		SET @RowCounttmp = @@ROWCOUNT
		SET @RowCount = IsNull(@RowCount,0) + @RowCounttmp
		SELECT @StartDate = @FinishDate + 1
		
		SELECT @MaxCount = @MaxCount +1
		exec sp_xml_removedocument @h
		
		IF (DATEDIFF(dd, @FinishDate, @ToDate) <= 0  )
			SELECT @MaxCount = 45
		IF ( DATEDIFF(dd, @StartDate, @ToDate ) > 54 )
			SET @FinishDate = DATEADD(dd, 55, @StartDate) - 1
		ELSE
			SET @FinishDate = @ToDate
		
	END
	
	IF @Trancnt = 0 COMMIT TRANSACTION
	SET @AuditMessage = '[upload].[upl_CbrUsdRate];@RowCount='+LTRIM(STR(IsNull(@RowCount,0)))+' finish'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount

END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
    IF @Trancnt = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tr_CbrUsdRate_Upload
	IF XACT_STATE() != -1 
	  BEGIN
		SET @AuditMessage = '[upload].[upl_CbrUsdRate]; error=''' + @ErrMessage + ''''	
			EXEC [audit].[sp_Print] @AuditMessage, 2
			EXEC [audit].[sp_AuditError] @LogID = @LogID, @ErrorMessage = @ErrMessage
	  END
	EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	RETURN -1
END CATCH

END