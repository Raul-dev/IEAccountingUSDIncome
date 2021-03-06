IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'ufn_GetConfigValue' AND o.type = N'FN' AND s.name = N'meta'  )
    EXEC('DROP FUNCTION [meta].[ufn_GetConfigValue]');
GO

GO
/****** Object:  UserDefinedFunction [meta].[sp_GetConfigValue]    Script Date: 2/15/2021 12:51:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
SELECT * FROM sys.sql_modules WHERE object_id  in (
SELECT object_id  FROM sys.objects WHERE name= 'ufn_GetConfigValue'
)

*/
CREATE Function [meta].[ufn_GetConfigValue](
	@Parameter	nvarchar(256)
) RETURNS nvarchar(256)
AS
BEGIN
	DECLARE @Value nvarchar(256)
	SET @Value = (SELECT StrValue FROM [meta].[ConfigApp] WHERE PARAMETER = @Parameter)
	RETURN @Value;
END
