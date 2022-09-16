
GO

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_RunTransform' AND o.type = N'P' AND s.name = N'dbo'  )
    EXEC('DROP PROCEDURE [dbo].[sp_RunTransform]');
GO
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/* 
Example:
[dbo].[sp_RunTransform]

*/
CREATE PROC [dbo].[sp_RunTransform]
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

SET @AuditMessage = '[dbo].[sp_RunTransform]; start'		
EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling

BEGIN TRY

	SET @Trancnt = @@TRANCOUNT
	IF @Trancnt > 0 SAVE TRAN tr_RunTransform ELSE BEGIN TRAN
	
	DECLARE @BatchID int, @FromDate int, @ToDate int, @CreateDate datetime, @StartDate int
	SELECT @CreateDate = GetDate(), @StartDate = CAST(CONVERT(varchar(25), GetDate(), 112) as int)
	SELECT @BatchID= max(BatchID) FROM DimBatch

	IF EXISTS(SELECT * FROM [upload].[CbrUsdRate])
	BEGIN

		MERGE INTO [dbo].[DimExchRateUSD] as target
		USING (
				SELECT dd.DateID, der.BatchID, der.ExchangeRates, der.CreateDate
					FROM [dbo].[DimDate] dd  
					INNER JOIN [upload].[CurrencyPeriod] c ON dd.DateID >= c.DateID_Start AND  dd.DateID < c.DateID_End
					LEFT JOIN
						(SELECT [Date], BatchID = @BatchID, ExchangeRates, CreateDate = @CreateDate, NextDate = LEAD(Date) OVER(ORDER BY Date)  
							FROM [upload].[CbrUsdRate] 
						) der ON  dd.FullDateAlternateKey BETWEEN der.Date AND ISNULL(der.NextDate -1, der.Date)
				WHERE NOT der.Date IS NULL
				) 
			as source (DateID, BatchID, ExchangeRates, CreateDate)
		ON (target.DateID = source.DateID)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (DateID, BatchID, ExchangeRates, CreateDate)
			VALUES (DateID, BatchID, ExchangeRates, CreateDate)
		WHEN MATCHED THEN  
		UPDATE SET  BatchID = source.BatchID, 
			ExchangeRates = source.ExchangeRates, 
			CreateDate = @CreateDate;
		SET @RowCount = @@ROWCOUNT

		SET @AuditMessage = '[dbo].[sp_RunTransform]; Merge DimExchRateUSD @RowCount= '+LTRIM(STR(@RowCount))+' '
		EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling

	END

	TRUNCATE TABLE [staging].[FactIncomeHistory]
	INSERT [staging].[FactIncomeHistory]([DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate])
	SELECT d.[DateID],
		BatchID = @BatchID,
		[IncomeUSD], 
		[NaturalKey] = CAST (SUBSTRING(HASHBYTES ( 'SHA2_256', LTRIM(RTRIM(STR(d.[CalendarYear]))) + LTRIM(RTRIM(STR(d.[MonthNumberOfYear]))) ), 0,32) as uniqueidentifier),
		[VersionKey] = CAST (SUBSTRING(HASHBYTES ( 'SHA2_256', LTRIM(RTRIM(STR(d.[DateID]))) + CAST([IncomeUSD] as varchar(30)) + LTRIM(RTRIM(IsNull(STR(d2.[DateID]),'null'))) + IsNull(CAST([ExchangeValue] as varchar(30)) ,'null') + IsNull(CAST([ExchangeRate] as varchar(30)) ,'null')  )  , 0,32) as uniqueidentifier),
		[ExchangeDateID] = d2.[DateID], 
		i.[ExchangeValue], 
		i.[ExchangeRate]
	FROM [upload].[IncomeBook] i INNER JOIN DimDate d ON  CAST(i.Date as date) = d.FullDateAlternateKey
		LEFT JOIN DimDate d2 ON  CAST(i.ExchangeDate as date) = d2.FullDateAlternateKey

	SELECT @FromDate = min([DateID]),  @ToDate = max([DateID]) FROM [staging].[FactIncomeHistory]

	 --Fix deleted
	INSERT [staging].[FactIncomeHistory] ([ID], [DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], [EndBatchID])
	SELECT source.[ID], source.[DateID], source.[BatchID], source.[IncomeUSD], source.[NaturalKey], source.[VersionKey], source.[ExchangeDateID], source.[ExchangeValue], source.[ExchangeRate],  @BatchID 
	FROM [dbo].[FactIncomeHistory] as source 
	WHERE source.EndBatchID is NULL AND NOT EXISTS( SELECT 1 FROM [staging].[FactIncomeHistory] as target WHERE  source.[NaturalKey] = target.[NaturalKey] )
	AND (source.DateID >= @FromDate or source.DateID <= @ToDate)
	SET @RowCount = @@ROWCOUNT

	-- Transformation
	-- delete dublicate
	DELETE FROM target
	FROM [dbo].[FactIncomeHistory] as source INNER JOIN [staging].[FactIncomeHistory] as target 
			ON source.[NaturalKey] = target.[NaturalKey] AND source.[VersionKey] = target.[VersionKey] 
	WHERE source.EndBatchID is NULL AND target.ID is NULL

	INSERT [staging].[FactIncomeHistory] ([ID], [DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], [EndBatchID])
	SELECT source.[ID], source.[DateID], source.[BatchID], source.[IncomeUSD], source.[NaturalKey], source.[VersionKey], source.[ExchangeDateID], source.[ExchangeValue], source.[ExchangeRate],  @BatchID 
	FROM [dbo].[FactIncomeHistory] as source 
	WHERE source.EndBatchID is NULL AND EXISTS( SELECT 1 FROM [staging].[FactIncomeHistory] as target WHERE  source.[NaturalKey] = target.[NaturalKey] AND target.ID is NULL )
	SET @RowCount = @@ROWCOUNT

	MERGE INTO [dbo].[FactIncomeHistory] as target
	USING (SELECT [ID], [DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], [EndBatchID], CreateDate = GetDate() FROM [staging].[FactIncomeHistory]
			) 
		as source ([ID], [DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], [EndBatchID], CreateDate)
	ON (target.ID = source.ID)
	WHEN NOT MATCHED BY TARGET THEN 
		INSERT ([DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], CreateDate)
		VALUES ([DateID], [BatchID], [IncomeUSD], [NaturalKey], [VersionKey], [ExchangeDateID], [ExchangeValue], [ExchangeRate], CreateDate)
	WHEN MATCHED THEN  
	UPDATE SET  EndBatchID = source.EndBatchID , 
		[ChangeDate] = @CreateDate;
	SET @RowCount = @@ROWCOUNT

	IF @Trancnt = 0 COMMIT TRANSACTION

	SET @AuditMessage = '[dbo].[sp_RunTransform]; Merge FactIncomeHistory @RowCount= '+LTRIM(STR(@RowCount))+'; finish'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	EXEC audit.sp_AuditFinish @Logid = @Logid, @RecordCount = @RowCount

END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
    IF @Trancnt = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tr_RunTransform
	IF XACT_STATE() != -1 
	  BEGIN
		SET @AuditMessage = '[dbo].[sp_RunTransform]; error=''' + @ErrMessage + ''''	
		EXEC [audit].[sp_Print] @AuditMessage, 2
		EXEC [audit].[sp_AuditError] @LogID = @LogID, @ErrorMessage = @ErrMessage
		
	  END
	EXEC audit.sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	RETURN -1
END CATCH

END