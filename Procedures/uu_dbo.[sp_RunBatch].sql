
GO

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_RunBatch' AND o.type = N'P' AND s.name = N'dbo'  )
    EXEC('DROP PROCEDURE [dbo].[sp_RunBatch]');
GO
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/* 
Example:
[dbo].[sp_RunBatch]
TRUNCATE TABLE [audit].[LogProcedures]
SELECT * FROM [audit].[LogProcedures]
SELECT 'ExcelFileIncomeBookCmd',''
INSERT [meta].[ConfigApp] (Parameter, StrValue) VALUES( 'ExcelFileIncomeBook','E:\Work\SQL\IndividualEntrepreneur\IncomeBook.xlsx')
UPDATE [meta].[ConfigApp] SET StrValue = 'E:\Work\SQL\IndividualEntrepreneur\Declaration.xlsm'
WHERE Parameter = 'ExcelFileIncomeBook'
	EXEC [dbo].[sp_RunBatch]
	EXEC [dbo].[sp_RunTransform]
	EXEC [dbo].[sp_FillFactIncome]
*/
CREATE PROC [dbo].[sp_RunBatch]
	@ErrMessage	nvarchar(4000) = NULL OUTPUT
AS
BEGIN
SET CONCAT_NULL_YIELDS_NULL ON
DECLARE @SPName varchar(510), @SPParams varchar(max), @SPInfo varchar(max), @LogID int, @RowCount int 
IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
	CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)
SET	@SPName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'			
SET @SPParams =
'@ErrMessage='+ISNULL(''''+@ErrMessage+'''','NULL')
EXEC audit.sp_AuditStart @SPName = @SPName, @SPParams = @SPParams, @LogID = @LogID OUTPUT


SET XACT_ABORT OFF

SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @Trancnt				int
DECLARE @AuditMessage		nvarchar(max)
DECLARE @ExecStr 			nvarchar(max)
DECLARE @OverridePrintEnabling		bit
DECLARE @Res				int
SET @OverridePrintEnabling = 0

SET @AuditMessage = '[dbo].[sp_RunBatch]; start'		
EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling

BEGIN TRY

	SET @Trancnt = @@TRANCOUNT
	IF @Trancnt > 0 SAVE TRAN tr_GenerateTable ELSE BEGIN TRAN

	DECLARE @BatchID int, @FromDate int, @ToDate int, @CreateDate datetime, @StartDate int
	SELECT @CreateDate = GetDate(), @StartDate = CAST(CONVERT(varchar(25), GetDate(), 112) as int)
	INSERT DimBatch (DateID, CreateDate)
	SELECT @StartDate, @CreateDate
	TRUNCATE TABLE [upload].[IncomeBook]
	EXEC @res = [upload].[upl_IncomeBook] @ErrMessage = @ErrMessage OUTPUT
	IF @res != 0
		RAISERROR(N'Error: [%]', 16, 1, @ErrMessage)

	SELECT  @FromDate = Min(DateID) , @ToDate = Max(DateID) FROM [upload].[IncomeBook] i INNER JOIN DimDate d ON  i.[Date]  = d.[FullDateAlternateKey]

	IF EXISTS(SELECT *
			FROM DimDate d LEFT JOIN [upload].[IncomeBook] i ON  i.[Date]  = d.[FullDateAlternateKey]
			WHERE i.[Date] is NULL AND (DateID >= @FromDate OR DateID <= @ToDate)
			)
	BEGIN
		TRUNCATE TABLE [upload].[CurrencyPeriod]
		TRUNCATE TABLE [upload].[CbrUsdRate]
		SELECT  @FromDate = Min(DateID) , @ToDate = Max(DateID) FROM [upload].[IncomeBook] i INNER JOIN DimDate d ON  i.[Date]  = d.[FullDateAlternateKey]

		SELECT @BatchID= max(BatchID) FROM DimBatch
		SELECT d.DateID, FullDateAlternateKey,
			idLead = LEAD (d.DateID, 1,0) OVER(ORDER BY d.DateID), 
			dLead = LEAD (d.FullDateAlternateKey) OVER(ORDER BY d.DateID),
			dLag = LAG (d.FullDateAlternateKey) OVER(ORDER BY d.DateID),
			dDiff =  Datediff(dd, d.FullDateAlternateKey, LEAD (d.FullDateAlternateKey) OVER(ORDER BY d.DateID) )
			into #tmp1
		FROM DimDate d LEFT JOIN [dbo].[DimExchRateUSD] i ON  i.DateID  = d.DateID
		WHERE i.DateID is NULL AND (d.DateID >= @FromDate AND d.DateID <= @ToDate)
		
		DECLARE @ID int, @EndDate int


		DECLARE PeriodsTable CURSOR LOCAL STATIC FOR
		SELECT
			r.ID,
			StartDate = s.FullDateAlternateKey,
			EndDate = DATEADD(mm,1 ,e.FullDateAlternateKey)
		FROM (
		SELECT sr.ID, 
				StartDate = CAST(sr.DateID / 100 AS int) * 100 + 1, 
				EndDate = CAST(ed.DateID / 100 AS int) * 100 + 1
			
			FROM (
				SELECT ID =ROW_NUMBER() OVER (ORDER BY DateID),
				DateID = CASE WHEN dLag is Null THEN DateID
					ELSE (
						CASE WHEN IsNull(dDiff,1) <> 1 THEN idLead
						ELSE NULL
						END
					)
					END
			FROM #tmp1 
			WHERE dLag is Null or IsNull(dDiff,1) <> 1
			) sr INNER JOIN (
				SELECT ID = ROW_NUMBER() OVER (ORDER BY DateID), DateID 
				FROM #tmp1 
				WHERE IsNULL(dDiff,2) <> 1
				) ed ON sr.ID = ed.ID
			) r INNER JOIN DimDate s ON s.DateID = r.StartDate
			INNER JOIN DimDate e ON e.DateID = r.EndDate
		ORDER BY ID
		OPEN PeriodsTable

		DECLARE @Start datetime, @End datetime
		FETCH NEXT FROM PeriodsTable INTO @ID, @Start, @End
		While @@FETCH_STATUS=0
		BEGIN
			
			INSERT [upload].[CurrencyPeriod] (BatchID, DateID_Start, DateID_End, CreateDate)
			SELECT @BatchID,  CAST(CONVERT(varchar(25), @Start, 112) as int), CAST(CONVERT(varchar(25), @End, 112) as int), @CreateDate

			EXEC @res = [upload].[upl_CbrUsdRate] @FromDate = @Start, @ToDate = @End, @ErrMessage = @ErrMessage OUTPUT
			IF @res != 0 
			BEGIN
				CLOSE PeriodsTable
				DEALLOCATE PeriodsTable
				RAISERROR(N'Error: [%]', 16, 1, @ErrMessage)
			END 
			FETCH NEXT FROM PeriodsTable INTO @ID, @Start, @End
		END
		CLOSE PeriodsTable
		DEALLOCATE PeriodsTable
	END

	IF @Trancnt = 0 COMMIT TRANSACTION

	SET @AuditMessage = '[dbo].[sp_RunBatch]; finish'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	EXEC audit.sp_AuditFinish @Logid = @Logid, @RecordCount = @RowCount

END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
    IF @Trancnt = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tr_GenerateTable
	IF XACT_STATE() != -1 
	  BEGIN
		SET @AuditMessage = '[dbo].[sp_RunBatch]; error=''' + @ErrMessage + ''''	
		EXEC [audit].[sp_Print] @AuditMessage, 2
		EXEC [audit].[sp_AuditError] @LogID = @LogID, @ErrorMessage = @ErrMessage
	  END
	EXEC audit.sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	RETURN -1
END CATCH

END