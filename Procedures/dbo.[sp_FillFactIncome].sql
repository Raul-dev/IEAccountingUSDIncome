
GO

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_FillFactIncome' AND o.type = N'P' AND s.name = N'dbo'  )
    EXEC('DROP PROCEDURE [dbo].[sp_FillFactIncome]');
GO
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/* 
Example:
	[dbo].[sp_FillFactIncome]
*/
CREATE PROC [dbo].[sp_FillFactIncome]
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
DECLARE @RowCounttmp		int
SET @OverridePrintEnabling = 0

SET @AuditMessage = '[dbo].[sp_FillFactIncome]; start'		
EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling

BEGIN TRY

	SET @Trancnt = @@TRANCOUNT
	IF @Trancnt > 0 SAVE TRAN tr_FillFactIncome ELSE BEGIN TRAN

	TRUNCATE TABLE [dbo].[FactIncome]
	INSERT [dbo].[FactIncome] (DateID, BatchID, IncomeValue, CreateDate)
	SELECT fih.DateID, fih.BatchID, (fih.IncomeUSD ) * der.ExchangeRates IncomeValue, CreateDate = GetDate()
	FROM [dbo].[FactIncomeHistory] fih INNER JOIN [dbo].[DimExchRateUSD] der ON fih.DateID = der.DateID
	WHERE fih.EndBatchID is NULL
	SET @RowCount = @@ROWCOUNT

	INSERT [dbo].[FactIncome] (DateID, BatchID, IncomeValue, CreateDate)
	SELECT DateID, ex.BatchID, IncomeValue = ex.IncomeValue - base.IncomeValue , CreateDate =  GetDate() FROM
		(SELECT fih.ID, fih.DateID, (fih.ExchangeValue ) * der.ExchangeRates IncomeValue , der_ExchangeRates = der.ExchangeRates
		FROM [dbo].[FactIncomeHistory] fih INNER JOIN [dbo].[DimExchRateUSD] der ON fih.DateID = der.DateID
		WHERE fih.EndBatchID is NULL
		) Base INNER JOIN
		(SELECT fih.ID, fih.ExchangeDateID, fih.BatchID, (fih.ExchangeValue ) * der.ExchangeRates IncomeValue, der_ExchangeRates = der.ExchangeRates
		FROM [dbo].[FactIncomeHistory] fih LEFT JOIN [dbo].[DimExchRateUSD] der ON fih.ExchangeDateID = der.DateID
		WHERE fih.EndBatchID is NULL AND NOT fih.ExchangeValue IS NULL
		) ex ON Base.ID = ex.ID
	WHERE base.IncomeValue < ex.IncomeValue
	SET @RowCounttmp = @@ROWCOUNT
	SET @RowCount = @RowCount + @RowCounttmp

	IF @Trancnt = 0 COMMIT TRANSACTION

	SET @AuditMessage = '[dbo].[sp_FillFactIncome] Inserted FactIncome @RowCount= '+LTRIM(STR(@RowCount))+' finish'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	EXEC audit.sp_AuditFinish @Logid = @Logid, @RecordCount = @RowCount

END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
    IF @Trancnt = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tr_FillFactIncome
	IF XACT_STATE() != -1 
	  BEGIN
		SET @AuditMessage = '[dbo].[sp_FillFactIncome]; error=''' + @ErrMessage + ''''	
		EXEC [audit].[sp_Print] @AuditMessage, 2
		EXEC [audit].[sp_AuditError] @LogID = @LogID, @ErrorMessage = @ErrMessage
	  END
	EXEC audit.sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	RETURN -1
END CATCH

END