

IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'uts' )
    EXEC('CREATE SCHEMA [uts]');
GO
IF EXISTS ( SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'usp_UnitTest' AND o.type = N'P' AND s.name = N'uts'  )
    EXEC('DROP PROCEDURE [uts].[usp_UnitTest]');
GO
-- EXEC [uts].[usp_UnitTest] @TestsList='2'
-- SELECT * FROM uts.ResultUnitTest
CREATE PROCEDURE [uts].[usp_UnitTest]
	@WithOutput		bit		= 1, 
	@WithCleanup	int		= 1,
	@TestsList	 	nvarchar(4000)	= ''
AS
-- Debug
DECLARE @TotalTestCount int
SET @TotalTestCount = 3
SET @TestsList = ISNULL(RTRIM(LTRIM(@TestsList)), '')
IF EXISTS (SELECT * FROM tempdb.sys.objects WHERE object_id = OBJECT_ID('tempdb.dbo.#Test') AND type in (N'U'))	
	DROP TABLE #Test
SELECT TestID = CONVERT(int, LTRIM(RTRIM(value))) INTO #Test 
FROM STRING_SPLIT(@TestsList, ',')
WHERE ISNUMERIC(LTRIM(RTRIM(value))) = 1

WHILE @TotalTestCount > 0 AND @TestsList = ''
  BEGIN 
	INSERT #Test(TestID) VALUES(@TotalTestCount)
	SET @TotalTestCount = @TotalTestCount - 1
  END



IF  EXISTS (SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE o.name = N'ResultUnitTest' AND o.type = N'U' AND s.name = N'uts' ) 
	DROP TABLE uts.ResultUnitTest

CREATE TABLE uts.ResultUnitTest(
	TestName nvarchar(200), 
	StepID int, 
	Error nvarchar(max),	
	datestamp datetime DEFAULT (GetDate())
	)
INSERT uts.ResultUnitTest(TestName, Error)	SELECT  TestName ='   EXEC uts.usp_UnitTest @TestsList = ''' + ISNULL(@TestsList ,'')+'''' , Error = ''

DECLARE @TestName nvarchar(100), @sql nvarchar(MAX), @TableNameOut nvarchar(255), @Error nvarchar(500)

DECLARE @TestID int 
DECLARE @res int
DECLARE @ErrMessage nvarchar(max)
DECLARE cur CURSOR FAST_FORWARD LOCAL FOR  
SELECT TestID FROM #Test ORDER BY TestID ASC
OPEN cur
FETCH NEXT FROM cur INTO @TestID
WHILE @@FETCH_STATUS = 0 
BEGIN
BEGIN TRY


IF @TestID = 1
  BEGIN
	SELECT @TestName = '1. Fill Dim Date'

	EXEC [dbo].[sp_FillDimDate]  @FromDate = '20190101', @ToDate = '20221231', @Culture = 'ru-ru',  @IsOutput = 0

	IF NOT EXISTS (SELECT * FROM uts.ResultUnitTest WHERE TestName = @TestName) INSERT uts.ResultUnitTest( TestName, Error) VALUES(@TestName, '')
	
  END

  IF @TestID = 2
  BEGIN
	SELECT @TestName = '2. Upload IncomeBook.xlsx into DWH'

	EXEC @res = [dbo].[sp_RunBatch] @ErrMessage = @ErrMessage OUTPUT
	SET @sql = '
		INSERT uts.ResultUnitTest( TestName, StepID, Error)
		SELECT TestName = ''' + @TestName +  ''', StepID = 1, Error =  '+ IsNull(@ErrMessage,'') + '
		'
	if @res != 0
		EXEC( @sql)

	EXEC @res = [dbo].[sp_RunTransform] @ErrMessage = @ErrMessage OUTPUT
	SET @sql = '
		INSERT uts.ResultUnitTest( TestName, StepID, Error)
		SELECT TestName = ''' + @TestName +  ''', StepID = 2, Error =  '+ IsNull(@ErrMessage,'') + '
		'
	if @res != 0
		EXEC( @sql)

	EXEC @res = [dbo].[sp_FillFactIncome] @ErrMessage = @ErrMessage OUTPUT
	SET @sql = '
		INSERT uts.ResultUnitTest( TestName, StepID, Error)
		SELECT TestName = ''' + @TestName +  ''', StepID = 3, Error =  '+ IsNull(@ErrMessage,'') + '
		'
	if @res != 0
		EXEC( @sql)



	IF NOT EXISTS (SELECT * FROM uts.ResultUnitTest WHERE TestName = @TestName) INSERT uts.ResultUnitTest( TestName, Error) VALUES(@TestName, '')

  END

-----------------------------------------
END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION

    DECLARE @ErrorMessage nvarchar(4000), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int, @ErrorProcedure  nvarchar(200)
    SELECT @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE(), @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-')
	SET @ErrorMessage = N'Error '+LTRIM(STR(@ErrorNumber,10,0))+', Level '+LTRIM(STR(@ErrorSeverity,10,0))+', State '+LTRIM(STR(@ErrorState,10,0))+', Procedure '+@ErrorProcedure+', Line '+LTRIM(STR(@ErrorLine,10,0))+', ' + 'Message: '+ ERROR_MESSAGE();        
	
	INSERT uts.ResultUnitTest( TestName, Error) VALUES('[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+'].' + ISNULL(@TestName,'NULL'),  @ErrorMessage)
    

END CATCH  

FETCH NEXT FROM cur INTO @TestID 
-----------------------------------------

END
CLOSE cur
DEALLOCATE cur

SELECT * FROM uts.ResultUnitTest
GO
