IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'sp_InitDataBase' AND o.type = N'P' AND s.name = N'meta'  )
    EXEC('DROP PROCEDURE [meta].[sp_InitDataBase]');
GO

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*

[meta].[sp_InitDataBase]
TRUNCATE TABLE [meta].[ConfigApp]
*/

CREATE PROCEDURE [meta].[sp_InitDataBase]
	@IsDebugMode		bit = 0
	
AS
BEGIN
IF (NOT EXISTS(SELECT 1 FROM [meta].[ConfigApp]))
BEGIN
	INSERT [meta].[ConfigApp] ([Parameter], [StrValue])
	VALUES ('AuditProcAll', '1')

	INSERT [meta].[ConfigApp]([Parameter], [StrValue])
	VALUES ('AuditPrintAll', '1')

	INSERT [meta].[ConfigApp] ([Parameter], [StrValue]) SELECT 'ExcelFileIncomeBookCmd','Select * from [Sheet1$]'

END

END
GO

