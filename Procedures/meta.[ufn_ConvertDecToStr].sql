IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'meta' )
    EXEC('CREATE SCHEMA [meta]');
GO
IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'ufn_ConvertDecToStr' AND o.type = N'FN' AND s.name = N'meta'  )
    EXEC('DROP FUNCTION [meta].[ufn_ConvertDecToStr]');
GO

GO

/****** Object:  UserDefinedFunction [meta].[ufn_ConvertDecToStr]    Script Date: 2/11/2021 12:55:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






/* 
SELECT meta.ufn_ConvertDecToStr(0.00000010000), '0.0000001'
*/

CREATE Function [meta].[ufn_ConvertDecToStr](
	@val	decimal  (36, 16)
) RETURNS nvarchar(50)
WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS
BEGIN
	RETURN 
		CASE WHEN ROUND(@val, 0, 1) = @val THEN LTRIM(STR(@val, 20, 0)) ELSE LEFT(@val, LEN(@val) - PATINDEX('%[^0]%', REVERSE(@val)) + 1) END
END
GO


