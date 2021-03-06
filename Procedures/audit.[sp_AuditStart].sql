IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_AuditStart' AND o.type = N'P' AND s.name = N'audit'  )
    EXEC('DROP PROCEDURE [audit].[sp_AuditStart]');
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
	DECLARE @ID int 
	EXEC audit.sp_AuditStart @ID = @ID output
	SELECT @ID
	SELECT [meta].[ufn_GetConfigValue]('AuditProcAll')
*/

CREATE PROCEDURE [audit].[sp_AuditStart]	
    @SPName varchar(512) = NULL,
    @SPParams varchar(MAX) = NULL,
    @SPSub  varchar(256) = NULL,		
    @LogID int OUTPUT   	
AS 
BEGIN
	SET NOCOUNT ON 
	DECLARE @AuditProcEnable nvarchar(128)
	SELECT @AuditProcEnable = [meta].[ufn_GetConfigValue]('AuditProcAll')
	IF @AuditProcEnable is NULL
		return 0

	IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
		CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)
		
	DECLARE @ParentID int 
	DECLARE @MainID int 
	DECLARE @CountIds int 
	DECLARE @TranCount int 
	SET @TranCount = @@TRANCOUNT 
	
	SELECT @MainID   =   MIN(LogID), 
		   @ParentID =   MAX(LogID), 
		   @CountIds  = COUNT(LogID) 
	FROM #AuditProc
	
	SET @SPName = LEFT(REPLICATE('    ', @CountIds) + LTRIM(RTRIM(@SPName)), 512) + ISNULL(': ' + @SPSub, '')
	
	INSERT [audit].[LogProcedures] ([MainID], [ParentID], [SPName], [SPParams], [TransactionCount])
	VALUES(@MainID, @ParentID, @SPName, @SPParams, @TranCount)
	SET @LogID  = SCOPE_IDENTITY()
	
	IF @MainID IS NULL 
		UPDATE [audit].[LogProcedures]
		   SET [MainID] = @LogID
		WHERE LogID = @LogID
		
	IF @ParentID IS NULL OR @ParentID < @LogID 
		INSERT #AuditProc(LogID) VALUES(@LogID)					
END
