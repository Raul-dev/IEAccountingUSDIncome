IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_Print' AND o.type = N'P' AND s.name = N'audit'  )
    EXEC('DROP PROCEDURE [audit].[sp_Print]');
GO

GO
/*

[audit].[sp_Print] @string = ' SELECT * FROM Security '

*/

CREATE PROCEDURE [audit].[sp_Print]
	@string		nvarchar(max),
	@OverrideConfig bit = 0
AS
BEGIN
	DECLARE @str		nvarchar(4000)
	DECLARE @part int	SET @part = 4000
	DECLARE @len int	SET @len  = LEN(@string)
	DECLARE @AuditPrintEnable nvarchar(128)
	SELECT @AuditPrintEnable = [meta].[ufn_GetConfigValue]('AuditPrintAll') 
	IF ISNULL(@AuditPrintEnable,0) = 2 OR (@OverrideConfig = 0  AND ISNULL(@AuditPrintEnable,0) = 0)
		return 0
	WHILE @len > 0
		BEGIN 
			IF @len <= @part 
				BEGIN
					Print @string
					BREAK
				END

			SET @str = LEFT(@string, @part)
			--SET @str = LEFT(@str, LEN(@str ) - CHARINDEX(CHAR(13), REVERSE(@str)) + 1)

			Print @str		

			SET @string = RIGHT(@string, @len - LEN(@str))
			SET @len  = LEN(@string)
			
		END 


END


