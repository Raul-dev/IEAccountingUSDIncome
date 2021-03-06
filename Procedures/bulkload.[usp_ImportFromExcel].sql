IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'usp_ImportFromExcel' AND o.type = N'P' AND s.name = N'bulkload'  )
    EXEC('DROP PROCEDURE [bulkload].[usp_ImportFromExcel]');
GO


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
Example:
EXEC [bulkload].[usp_ImportFromExcel] 'D:\projects\Beluga\Response to the data request 28-01-2021.xlsx', 'SELECT * FROM [Item$]', '[bulkload].[UploadItem]'
SELECT * FROM [bulkload].[IncomeBook]
SELECT * FROM [audit].[PROC_LOGS]
SELECT @ExcelFile = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBook');
	SELECT @ExcelFileCmd = [meta].[ufn_GetConfigValue]('ExcelFileIncomeBookCmd');
*/
CREATE PROC [bulkload].[usp_ImportFromExcel]
	 @ExcelFile		nvarchar(256),
	 @ExcelFileCmd	nvarchar(256),
	 @TableName		nvarchar(128)
	
AS
BEGIN
SET CONCAT_NULL_YIELDS_NULL ON
DECLARE @SPName varchar(510), @SPParams varchar(max), @SPInfo varchar(max), @LogID int, @RowCount int 
IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
	CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)
		
SET	@SPName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'			
SET @SPParams = '@ExcelFile=' +@ExcelFile+'; @ExcelFileCmd='+@ExcelFileCmd+';'
EXEC audit.sp_AuditStart @SPName = @SPName, @SPParams = @SPParams, @LogID = @LogID OUTPUT

--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
SET XACT_ABORT OFF

SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @AuditMessage       nvarchar(max) 
DECLARE @ErrMessage         nvarchar(max) 
DECLARE @tranc				int
DECLARE @OverridePrintEnabling		bit
DECLARE @res				int
DECLARE @OpenRowSet			nvarchar(max) 
DECLARE @sqlcmd				nvarchar(max) 
DECLARE @NewVersionCount    int
SET @OverridePrintEnabling = 1
SET @AuditMessage = '[bulkload].[usp_ImportFromExcel]; start'
EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
BEGIN TRY

	SET @tranc = @@TRANCOUNT
	IF @tranc > 0 SAVE TRAN tran_ImportFromExcel ELSE BEGIN TRAN;
	
	--TRUNCATE TABLE [bulkload].IncomeBook;
	IF @ExcelFile is Null 
		RAISERROR( N'Error: Parameter @ExcelFile must be defined.', 16, 1)

	IF @ExcelFileCmd is Null 
		RAISERROR( N'Error: Parameter @ExcelFile must be defined.', 16, 1)
	
	IF EXISTS ( SELECT * FROM sys.objects where object_id = OBJECT_ID(@TableName))
		EXEC('DROP table ' + @TableName);

	SET @OpenRowSet='Excel 12.0;IMEX=1;HDR=YES;DATABASE=' + @ExcelFile
	SET @sqlcmd = '
	SELECT * INTO '+@TableName+' FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', '''+@OpenRowSet+''','''+@ExcelFileCmd+''' )
	'
	EXEC [audit].[sp_Print] @sqlcmd, @OverridePrintEnabling
	EXEC (@sqlcmd)
	SET @RowCount = @@ROWCOUNT
	IF @tranc = 0 COMMIT TRANSACTION
	SET @AuditMessage = '[bulkload].[usp_ImportFromExcel];@RowCount='+LTRIM(STR(@RowCount))+' finish'
	EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
    IF @tranc = 0 ROLLBACK TRAN ELSE IF XACT_STATE() != -1 ROLLBACK TRAN tran_ImportFromExcel
	IF XACT_STATE() != -1 
	  BEGIN
		SET @AuditMessage = '[bulkload].[usp_ImportFromExcel]; error=''' + @ErrMessage + ''''	
		EXEC [audit].[sp_Print] @AuditMessage, @OverridePrintEnabling
	  END
	EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
	RETURN -1
END CATCH

END