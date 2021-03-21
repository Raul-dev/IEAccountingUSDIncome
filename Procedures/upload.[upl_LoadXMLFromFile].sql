IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'upl_LoadXMLFromFile' AND o.type = N'P' AND s.name = N'upload'  )
    EXEC('DROP PROCEDURE [upload].[upl_LoadXMLFromFile]');
GO

CREATE PROCEDURE [upload].upl_LoadXMLFromFile
(
	@tcFileName		VARCHAR(255),
	@tcXMLString	VARCHAR(8000) OUTPUT
) AS
BEGIN
	SET CONCAT_NULL_YIELDS_NULL ON
	DECLARE @SPName varchar(510), @SPParams varchar(max), @SPInfo varchar(max), @LogID int, @RowCount int 
	IF NOT EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'tempdb.dbo.#AuditProc'))
		CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)

		
	SET	@SPName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'			
	SET @SPParams =
	  '@tcFileName='+ISNULL(''''+@tcFileName+'''','NULL')+','
	+ '@tcXMLString='+ISNULL(''''+@tcXMLString+'''','NULL')
	EXEC audit.sp_AuditStart @SPName = @SPName, @SPParams = @SPParams, @LogID = @LogID OUTPUT

	-- Scratch variables used in the script
	DECLARE @retVal INT
	DECLARE @oXML INT
	DECLARE @errorSource VARCHAR(8000)
	DECLARE @errorDescription VARCHAR(8000)
	DECLARE @loadRetVal INT

	-- Initialize the XML document
	EXEC @retVal = sp_OACreate 'MSXML2.DOMDocument', @oXML OUTPUT
	IF (@retVal <> 0)
	BEGIN
		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @oXML, @errorSource OUTPUT, @errorDescription OUTPUT
		RAISERROR (@errorDescription, 16, 1)

		-- Release the reference to the COM object
		EXEC sp_OADestroy @oXML
		RETURN
	END

	EXEC @retVal = sp_OASetProperty @oXML, 'async', 0
	IF @retVal <> 0
	BEGIN
 		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @oXML, @errorSource OUTPUT, @errorDescription OUTPUT
		RAISERROR (@errorDescription, 16, 1)

		-- Release the reference to the COM object
		EXEC sp_OADestroy @oXML
		RETURN
	END

	-- Load the XML into the document
	EXEC @retVal = sp_OAMethod @oXML, 'load', @loadRetVal OUTPUT, @tcFileName
	IF (@retVal <> 0)
	BEGIN
		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @oXML, @errorSource OUTPUT, @errorDescription OUTPUT
		RAISERROR (@errorDescription, 16, 1)

		-- Release the reference to the COM object
		EXEC sp_OADestroy @oXML
		RETURN
	END

	-- Get the loaded XML
	EXEC @retVal = sp_OAMethod @oXML, 'xml', @tcXMLString OUTPUT
	IF (@retVal <> 0)
	BEGIN
		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @oXML, @errorSource OUTPUT, @errorDescription OUTPUT
		RAISERROR (@errorDescription, 16, 1)

		-- Release the reference to the COM object
		EXEC sp_OADestroy @oXML
		RETURN
	END

	-- Release the reference to the COM object
	EXEC sp_OADestroy @oXML
	EXEC [audit].sp_AuditFinish @LogID = @LogID, @RecordCount = @RowCount
END