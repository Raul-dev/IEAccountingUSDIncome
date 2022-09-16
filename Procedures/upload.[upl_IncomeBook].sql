

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'upl_IncomeBook' AND o.type = N'P' AND s.name = N'upload'  )
    EXEC('DROP PROCEDURE [upload].[upl_IncomeBook]');
GO

GO
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/* 
Example:
EXEC [upload].[upl_IncomeBook]
SELECT * FROM [upload].[IncomeBook]
SELECT [meta].[ufn_GetConfigValue]('ExcelFileIncomeBook');
SELECT * FROM [meta].[ConfigApp]
INSERT [meta].[ConfigApp] (Parameter, StrValue)
SELECT 'ExcelFileIncomeBook',''
SELECT 'ExcelFileIncomeBookCmd',''
INSERT [meta].[ConfigApp] (Parameter, StrValue) VALUES( 'ExcelFileIncomeBook','E:\Work\SQL\IndividualEntrepreneur\IncomeBook.xlsx')

*/
CREATE PROC [upload].[upl_IncomeBook]
	@ExcelFile		nvarchar(256) = NULL,
	@ExcelFileCmd	nvarchar(256) = NULL,
	@ErrMessage	nvarchar(4000) = NULL OUTPUT
AS
BEGIN
	SET CONCAT_NULL_YIELDS_NULL ON
	DECLARE @SPName varchar(510), @SPParams varchar(max), @SPInfo varchar(max), @LogID int, @RowCount int 
	IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
		CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)
		
	SET	@SPName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'			
	IF @ExcelFile is NULL
		SELECT @ExcelFile = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBook');
	IF @ExcelFileCmd is NULL
		SELECT @ExcelFileCmd = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBookCmd');
	SET @SPParams = '@ExcelFile=' +@ExcelFile+'; @ExcelFileCmd='+@ExcelFileCmd+';'
	EXEC audit.sp_AuditStart @SPName = @SPName, @SPParams = @SPParams, @LogID = @LogID OUTPUT

	SET XACT_ABORT OFF

	SET CONCAT_NULL_YIELDS_NULL ON
	SET NOCOUNT ON

	DECLARE @AuditMessage       nvarchar(max) 
	DECLARE @tranc				int
	DECLARE @OverridePrintEnabling		bit
	DECLARE @res				int
	DECLARE @OpenRowSet			nvarchar(max) 
	DECLARE @sqlcmd				nvarchar(max) 
	DECLARE @NewVersionCount    int
	SET @OverridePrintEnabling = 1
	SET @AuditMessage = '[upload].[upl_IncomeBook]; start'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	BEGIN TRY

		SET @tranc = @@TRANCOUNT
		IF @tranc > 0 SAVE TRAN tran_IncomeBook ELSE BEGIN TRAN;
		SELECT @ExcelFile = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBook');
		SELECT @ExcelFileCmd = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBookCmd');
	
		TRUNCATE TABLE [upload].IncomeBook;
		IF @ExcelFile is Null 
			RAISERROR( N'Error: Parameter @ExcelFile must be defined.', 16, 1)

		IF @ExcelFileCmd is Null 
			RAISERROR( N'Error: Parameter @ExcelFile must be defined.', 16, 1)

		SET @OpenRowSet='Excel 12.0;IMEX=1;HDR=YES;DATABASE=' + @ExcelFile
		SET @sqlcmd = '
		INSERT [upload].IncomeBook (Date, IncomeUsd, ExchangeDate, ExchangeValue, ExchangeRate)
		SELECT Date, IncomeUsd, ExchangeDate, ExchangeValue, ExchangeRate FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', '''+@OpenRowSet+''','''+@ExcelFileCmd+''' )
		'
		EXEC [audit].[sp_Print] @sqlcmd, @OverridePrintEnabling
		EXEC (@sqlcmd)
		SET @RowCount = @@ROWCOUNT
		IF @tranc = 0 COMMIT TRANSACTION
		SET @AuditMessage = '[upload].[upl_IncomeBook];@RowCount='+LTRIM(STR(@RowCount))+' finish'
		EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
		EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	END TRY
	BEGIN CATCH
		SELECT @ErrMessage = ERROR_MESSAGE()
		IF @tranc = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tran_IncomeBook
		IF XACT_STATE() != -1 
		  BEGIN
			SET @AuditMessage = '[upload].[upl_IncomeBook]; error=''' + @ErrMessage + ''''	
			EXEC [audit].[sp_Print] @AuditMessage, 2
			EXEC [audit].[sp_AuditError] @LogID = @LogID, @ErrorMessage = @ErrMessage
		  END
		EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
		RETURN -1
	END CATCH

END