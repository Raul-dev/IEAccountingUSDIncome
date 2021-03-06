

IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'ufn_GetLastDate' AND o.type = N'FN' AND s.name = N'meta'  )
    EXEC('DROP FUNCTION [meta].[ufn_GetLastDate]');
GO

GO
/****** Object:  UserDefinedFunction [meta].[ufn_ConvertDecToStr]    Script Date: 2/11/2021 3:46:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/* 
SELECT [meta].[ufn_GetLastDate]()
*/

CREATE Function [meta].[ufn_GetLastDate](
	
) RETURNS datetime
WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS
BEGIN
	RETURN DATEFROMPARTS(2100, 12, 31) 
END
