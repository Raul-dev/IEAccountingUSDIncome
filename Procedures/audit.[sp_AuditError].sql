
/****** Object:  StoredProcedure [audit].[sp_AuditError]    Script Date: 21.03.2021 10:12:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER PROCEDURE [audit].[sp_AuditError] 
	@LogID			int  = NULL,
    @ErrorMessage	varchar(2048) = NULL,
    @isFinish		bit = 0
AS 
BEGIN
	SET NOCOUNT ON		 

	UPDATE [audit].[LogProcedures]
	SET [ErrorMessage] = LEFT( ISNULL([ErrorMessage],'') 
						+ ISNULL(@ErrorMessage, 'Error') + '; ', 2048)						
	WHERE [LogID] = @LogID	
	
	IF @isFinish = 1 
		EXEC [audit].[sp_AuditFinish] @LogID = @LogID
END
GO


