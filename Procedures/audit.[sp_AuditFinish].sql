IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_AuditFinish' AND o.type = N'P' AND s.name = N'audit'  )
    EXEC('DROP PROCEDURE [audit].[sp_AuditFinish]');
GO
GO
/****** Object:  StoredProcedure [audit].[p_AuditFinish]    Script Date: 2/14/2021 3:19:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [audit].[sp_AuditFinish] 
	@LogID		int = NULL,    
    @RecordCount	int = NULL,
    @SPInfo		varchar(MAX) = NULL
AS 
BEGIN
	SET NOCOUNT ON 
	DECLARE @AuditProcEnable nvarchar(128)
	SELECT @AuditProcEnable = [meta].[ufn_GetConfigValue]('AuditProcAll')
	IF @AuditProcEnable is NULL
		return 0
	IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
		CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)

	DECLARE @TranCount int 
	SET @TranCount = @@TRANCOUNT
		
	UPDATE [audit].[LogProcedures]
	SET [EndTime]   = GETDATE(),
		[Duration]  = DATEDIFF(ms, [StartTime], GETDATE()),
		[RowCount] = @RecordCount,
		[SPInfo] = ISNULL([SPInfo], '')
					 + CASE WHEN [TransactionCount] = @TranCount THEN '' 
					   ELSE 'Tran count changed to ' + ISNULL(LTRIM(STR(@TranCount, 10, 0)), 'NULL') + ';' END
					 + CASE WHEN @SPInfo IS NULL THEN ''
					   ELSE 'Finish:' + CONVERT(varchar(19), GETDATE(), 120) + ':' + @SPInfo + ';' END					   
	WHERE [LogID] = @LogID
	
	DELETE FROM #AuditProc WHERE LogID >= @LogID
END
