
CREATE OR ALTER FUNCTION [dbo].[fn_dev_Split]			
(
@string			nvarchar(max),
@separator		char(1)
)
RETURNS @resultset table (
	Items		nvarchar(max)
)
AS
BEGIN

IF @separator IS NULL OR @separator = '' RETURN

SET @string = LTRIM(RTRIM( @string))

WHILE LEN(@string) > 0
  BEGIN
	IF CHARINDEX( @separator, @string) = 0
	  BEGIN
		INSERT @resultset SELECT @string
		BREAK
	  END
	INSERT @resultset SELECT LTRIM(RTRIM( SUBSTRING( @string, 1, CHARINDEX( @separator, @string) - 1)))
	SET @string = LTRIM(RTRIM( RIGHT( @string, LEN(@string) - CHARINDEX( @separator, @string))))
  END

DELETE @resultset WHERE LEN(Items) = 0

RETURN 

END


GO


GO
CREATE OR ALTER  FUNCTION [dbo].[fn_dev_FKfields](
	@TableName	sysname,
	@SchemaTable sysname = NULL
) RETURNS table

AS

RETURN (
	SELECT f.[NAME] as TableName, ColF.[NAME] as ColumnName , con.[NAME] as ConstraintName ,   r.[NAME] as TableRefName , ColR.[NAME] As ColumnRefName 
	, SCHEMA_NAME(f.[schema_id]) as SchemaTable, SCHEMA_NAME(r.[schema_id]) as SchemaTableRef
	FROM sysforeignkeys INNER JOIN sysobjects con ON sysforeignkeys.constid =  con.id
	INNER JOIN sys.tables f ON sysforeignkeys.fkeyid =  f.[object_id]
	INNER JOIN sys.tables r ON sysforeignkeys.rkeyid =  r.[object_id]
	INNER JOIN syscolumns ColR ON sysforeignkeys.rkeyid =  ColR.id AND sysforeignkeys.rkey = ColR.colorder
	INNER JOIN syscolumns ColF ON sysforeignkeys.fkeyid =  ColF.id AND sysforeignkeys.fkey = ColF.colorder
	WHERE  r.[NAME] = @TableName 
	  AND SCHEMA_NAME( r.[schema_id]) = ISNULL( @SchemaTable, 'dbo')
	)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- SELECT * FROM session_state
-- [dbo].[sp_dev_ObjectMove] @OperationTypeID = 0, @Table ='session_state', @TargetID =1

CREATE OR ALTER  PROC [dbo].[sp_dev_ObjectMove](
	@OperationTypeID int = 0,	-- 0 - Info
								-- 1 - Delete TargetID object 
								-- 2 - Move TargetID to SourceID object
								-- 3 - Move TargetID to SourceID object and delete TargetID object 
	@Table nvarchar(128),
	@Schema nvarchar(128) = 'dbo',
	@TargetID int, 
	@SourceID int = Null, 
	@LevelID  int = 0,
	@ApplyScript int = 0,
	@WithOutput int = 1,
	@err_message nvarchar(4000) = Null OUTPUT,
	@UseTableTargetID int = 0
)
AS
BEGIN


SET NOCOUNT ON

----- External Tables --------------------------------------------------------
IF NOT EXISTS (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.[dbo].[#ExtForeignKey]') )
	CREATE TABLE [#ExtForeignKey](
		TableName			nvarchar(128) NOT NULL,
		ColumnName			nvarchar(128) NOT NULL,
		TableRefName		nvarchar(128) NOT NULL,
		ColumnRefName		nvarchar(128) NOT NULL,
		SchemaTable			nvarchar(128) NULL,
		SchemaTableRef		nvarchar(128) NULL
	)

IF NOT EXISTS (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.[dbo].[#ExcludeTable]') )
	CREATE TABLE [#ExcludeTable](
		TableName			nvarchar(128) NOT NULL,
		SchemaTable			nvarchar(128) NULL,
		OperationTypeID		int NOT NULL
	)

IF NOT EXISTS (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.[dbo].[#TableNameList]') )
	CREATE TABLE [#TableNameList] (
		RowID			int identity(1, 1) NOT NULL,
		TableName		nvarchar (128),
		SchemaTable		nvarchar(128),
		ColumnName		nvarchar(128),
		[RowCount]		int,	
		[LevelID]		int,
		PrimeKeyID		nvarchar(4000),
		SqlCmd			nvarchar(4000),
		TargetID		int,
		SourceID		int,
		RowCmd			int,
		Msg				nvarchar(4000)
	)

IF NOT EXISTS (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.[dbo].[#TargetID]') )
	CREATE TABLE [#TargetID] (
		TargetID			int Primary Key NOT NULL,
	)

-------------------------------------------------------------

	IF ISNULL(LTRIM(RTRIM(@Schema)), '') = ''	SET @Schema = 'dbo'
	IF @OperationTypeID IS NULL	OR @OperationTypeID NOT IN (0, 1, 2, 3)	SET @OperationTypeID = 0

	IF ISNULL(@UseTableTargetID, 0) = 1 AND  @OperationTypeID <> 1 SET @UseTableTargetID = 0
	IF NOT EXISTS (SELECT * FROM [#TargetID]) SET @UseTableTargetID = 0
	
	IF @TargetID = @SourceID and @OperationTypeID IN (2, 3) 
	  BEGIN
	  	
		RETURN 
	  END

	Print ''
	Print 'Start sp_dev_ObjectMove : @Table = [' + @Schema + '].[' + @Table + ']'
		+ '; @TargetID = ' + ISNULL(Cast(@TargetID as nvarchar(100)), 'NULL')
		+ '; @SourceID = ' + ISNULL(Cast(@SourceID as nvarchar(100)), 'NULL')
		+ '; @LevelID = '  + ISNULL(Cast(@LevelID  as nvarchar(100)), 'NULL')



	DECLARE @TableName nvarchar(128), @ColumnName nvarchar(128), @ConstraintName nvarchar(128), @TableRefName nvarchar(128), @ColumnRefName nvarchar(128), @SchemaTable nvarchar(128), @SchemaTableRef nvarchar(128) 
	, @Count int, @Sql nvarchar (4000), @_LevelID int
	, @PrimeKeyID nvarchar(4000)
	, @PrimeIDName nvarchar(128)
	, @IsDropConstraint bit, @LevelID2 int, @PrimeKeyID2 nvarchar(4000)	
	, @TranCounter int


if @LevelID = 0
BEGIN
	IF @OperationTypeID	<> 0
	BEGIN
		IF NOT EXISTS( SELECT * FROM #TableNameList WHERE LevelID = 200) 
		  BEGIN
			INSERT #TableNameList( LevelID, SqlCmd) 
			VALUES (200, 'DECLARE @ErrMsg nvarchar(4000) BEGIN TRY BEGIN TRAN')

			INSERT #TableNameList( LevelID, SqlCmd) 
			VALUES (-100, 'COMMIT TRAN END TRY
									BEGIN CATCH 
										SET @ErrMsg = ERROR_MESSAGE()
										ROLLBACK TRAN
										RAISERROR( @ErrMsg, 16, 1) 
									END CATCH 
									SELECT Info = CASE WHEN @ErrMsg is Null THEN ''Successfully ' 
							+  CASE WHEN @OperationTypeID = 1 then ' deleted' WHEN @OperationTypeID = 2 THEN ' updated'  ELSE '' END + '''' 
							+ ' ELSE ''Error: '' + @ErrMsg END ')
		  END
	END
	
	INSERT #TableNameList( TableName, SchemaTable, ColumnName, [RowCount], LevelID, TargetID, SqlCmd) 
		SELECT TableName = @Table, SchemaTable = @Schema, ColumnName = syscolumns.name, [RowCount] = 1, LevelID = 0, TargetID = @TargetID, 
			SqlCmd = N'   DELETE ['+ @Schema +'].[' + @Table + '] FROM ['+ @Schema +'].[' + @Table + '] WHERE [' + syscolumns.name  + ']'
							+ CASE WHEN @UseTableTargetID = 1 THEN ' IN (SELECT TargetID FROM #TargetID)' 
							  ELSE ' = ' + Cast(@TargetID as nvarchar(100)) END
		FROM  
			sys.tables r INNER JOIN sysobjects obj ON r.[object_id] = obj.parent_obj
			INNER JOIN sysindexes ON sysindexes.name = obj.Name
			INNER JOIN sysindexkeys ON r.[object_id] = sysindexkeys.ID and sysindexes.indid = sysindexkeys.indid
			INNER JOIN syscolumns ON r.[object_id] = syscolumns.ID and sysindexkeys.colid = syscolumns.colid 
		WHERE r.[NAME] = @Table AND SCHEMA_NAME(r.[schema_id]) = @Schema AND obj.xtype='PK' AND @OperationTypeID IN ( 1, 3)

	SET @LevelID = 1

END
	SELECT TableName, ColumnName, ConstraintName, TableRefName, ColumnRefName, SchemaTable, SchemaTableRef
	INTO #ForeignKey
	FROM dbo.fn_dev_FKfields( @Table, @Schema)
	
	INSERT #ForeignKey(TableName, ColumnName, ConstraintName, TableRefName, ColumnRefName, SchemaTable, SchemaTableRef)
	SELECT TableName, ColumnName, ConstraintName = '', TableRefName, ColumnRefName, ISNULL(SchemaTable, 'dbo'), ISNULL( SchemaTableRef, 'dbo')
	FROM #ExtForeignKey WHERE TableRefName = @Table AND ISNULL(SchemaTableRef, 'dbo') = @Schema
	
	DECLARE Table_Cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT TableName, ColumnName, ConstraintName, TableRefName, ColumnRefName, SchemaTable, SchemaTableRef
			FROM #ForeignKey
	
	OPEN Table_Cursor 

	FETCH NEXT FROM Table_Cursor INTO @TableName, @ColumnName, @ConstraintName, @TableRefName, @ColumnRefName, @SchemaTable, @SchemaTableRef

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @PrimeIDName = Null
		SET @PrimeKeyID = Null
		SET @_LevelID = @LevelID
		
		SELECT @PrimeIDName = syscolumns.name
		FROM  
			sys.tables r INNER JOIN sysobjects obj ON r.[object_id] = obj.parent_obj			
			INNER JOIN sysindexes ON sysindexes.name = obj.Name
			INNER JOIN sysindexkeys ON r.[object_id] = sysindexkeys.ID and sysindexes.indid = sysindexkeys.indid
			INNER JOIN syscolumns ON r.[object_id] = syscolumns.ID and sysindexkeys.colid = syscolumns.colid 
		WHERE  r.[NAME] = @TableName  AND SCHEMA_NAME(r.[schema_id]) = @SchemaTable AND obj.xtype='PK'

		Set @Sql = N' SELECT @PrimeKeyID = IsNull(  @PrimeKeyID+'','','''') + CAST(['+ @PrimeIDName + '] as nvarchar(128)) 
						FROM ['+ @SchemaTable +'].[' + @TableName +'] WHERE [' + @ColumnName +'] = @TargetID ORDER BY ['+ @PrimeIDName + '] ASC
						SET @Count = @@ROWCOUNT '
		--print @Sql
		exec sp_executesql  @Sql , N'@Count int OUTPUT, @PrimeKeyID nvarchar(4000) OUTPUT, @TargetID int' , @Count OUTPUT, @PrimeKeyID OUTPUT, @TargetID

		if ISNULL(@Count, 0) <> 0 OR @UseTableTargetID = 1 OR @PrimeIDName IS NULL
		BEGIN
			SELECT @IsDropConstraint = 0, @LevelID2 = NULL, @PrimeKeyID2 = NULL
					
			SELECT @LevelID2 = MIN(LevelID) 
			FROM #TableNameList t
			CROSS APPLY [dbo].[fn_dev_Split]( t.PrimeKeyID, ',') a
			JOIN [dbo].[fn_dev_Split](@PrimeKeyID, ',') s ON s.items = a.items 
			WHERE t.TableName   = @TableName 
			  AND t.SchemaTable = @SchemaTable
										    
			IF @LevelID2 IS NOT NULL			
			  BEGIN
				SET @IsDropConstraint = 1
				IF @_LevelID > @LevelID2 SET @_LevelID = @LevelID2
												
				SELECT @PrimeKeyID2 = IsNull( @PrimeKeyID2+',','') + CAST(s.items as nvarchar(128))  
				FROM [dbo].[fn_dev_Split] (@PrimeKeyID, ',') s
						WHERE NOT EXISTS( SELECT * FROM #TableNameList t CROSS APPLY [dbo].[fn_dev_Split]( t.PrimeKeyID, ',') a			
									  WHERE t.TableName = @TableName AND t.SchemaTable = @SchemaTable AND a.items = s.items ) 												  
				SET @Count = @@ROWCOUNT 
				SET @PrimeKeyID =  @PrimeKeyID2
			  END 

			print '################################ LevelID = '+ Cast(@LevelID  as nvarchar(50))  
			print 'Table name: [' + @SchemaTable + '].[' + @TableName + ']'
				+ ';   Refference Key: ' + @ColumnName + '=' + CAST(@TargetID as nvarchar(100))
				+ ';   Primary Key: ' + Isnull(@PrimeIDName,'') + '=' + IsNull(@PrimeKeyID,'')
				+ ';   ConstraintName: ' + Isnull(@ConstraintName,'') 
				+ ';   TableRefName: ' + Isnull(@TableRefName,'') 
				+ ';   ColumnRefName: ' + Isnull(@ColumnRefName,'')
				+ ';   IsDropConstraint: ' + CAST(@IsDropConstraint as nvarchar(100)) 
				+ ';   _LevelID: ' + CAST(@_LevelID as nvarchar(100)) 
			Print 'Row count = ' + Cast(@Count  as nvarchar(50))

			IF @UseTableTargetID = 1 OR @IsDropConstraint = 1
				BEGIN				  
				  IF NOT EXISTS (SELECT * FROM #TableNameList WHERE TableName = @ConstraintName) AND ISNULL( @ConstraintName, '') <> ''
					BEGIN 
						DECLARE	@object_id	int					SET @object_id = NULL
						DECLARE @delete_referential_action int 
						DECLARE @update_referential_action int
						
						Set @Sql= N'SELECT @object_id = object_id,
										@delete_referential_action = delete_referential_action,
										@update_referential_action = update_referential_action
									FROM [sys].[foreign_keys] 
									WHERE [object_id] = OBJECT_ID(N''[' + @ConstraintName + ']'') 
									  AND [parent_object_id] = OBJECT_ID(N''['+ @SchemaTable +'].[' + @TableName + ']'')'
						
						exec sp_executesql  @Sql , N'@object_id int OUTPUT, @delete_referential_action int OUTPUT, @update_referential_action int OUTPUT' , @object_id OUTPUT,  @delete_referential_action OUTPUT, @update_referential_action OUTPUT

						IF @object_id IS NOT NULL -- if foreign keys exists
						  BEGIN
							print '    ALTER TABLE ['+ @SchemaTable +'].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'

							SET @sql = '  IF EXISTS( SELECT * FROM [sys].[foreign_keys] WHERE [object_id] = OBJECT_ID(N''[' + @ConstraintName + ']'') AND [parent_object_id] = OBJECT_ID(N''['+ @SchemaTable +'].[' + @TableName + ']'')) '
									 + 'ALTER TABLE ['+ @SchemaTable +'].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'
							
							IF @OperationTypeID = 0 SET @Sql = NULL

							INSERT #TableNameList (TableName, ColumnName, [RowCount], LevelID, SqlCmd) 
							VALUES (@ConstraintName, @ColumnName, 0, 150, @Sql)

							SET @sql = '  IF NOT EXISTS( SELECT * FROM [sys].[foreign_keys] WHERE [object_id] = OBJECT_ID(N''[' + @ConstraintName + ']'') AND [parent_object_id] = OBJECT_ID(N''['+ @SchemaTable +'].[' + @TableName + ']'')) '
									 + 'ALTER TABLE ['+ @SchemaTable +'].[' + @TableName + '] ADD CONSTRAINT [' + @ConstraintName + '] FOREIGN KEY ([' + @ColumnName + ']) REFERENCES ['+ @SchemaTableRef +'].[' + @TableRefName + ']([' + @ColumnRefName + '])'
									 + CASE WHEN @delete_referential_action = 1 THEN ' ON DELETE CASCADE ' ELSE '' END 
									 + CASE WHEN @update_referential_action = 1 THEN ' ON UPDATE CASCADE ' ELSE '' END

							IF @OperationTypeID = 0 SET @Sql = NULL

							INSERT #TableNameList (TableName, ColumnName, [RowCount], LevelID, SqlCmd) 
							VALUES (@ConstraintName, @ColumnName, 0, -50, @Sql)
						  END
					END 
				END

			IF @UseTableTargetID = 1 OR @Count <> 0 OR @PrimeIDName IS NULL
			BEGIN

				IF @OperationTypeID = 0
					INSERT #TableNameList (TableName, SchemaTable, ColumnName, [RowCount], LevelID, PrimeKeyID, TargetID, SourceID) 
					VALUES (@TableName, @SchemaTable, @ColumnName, @Count, @_LevelID, @PrimeKeyID, @TargetID, @SourceID)

				IF @OperationTypeID IN ( 1, 3) AND   
					NOT EXISTS( SELECT * FROM #ExcludeTable WHERE TableName = @TableName AND ISNULL(SchemaTable, 'dbo') = @SchemaTable AND OperationTypeID IN( 1, 3))					
				BEGIN
					Set @Sql =N'    DELETE ['+ @SchemaTable +'].[' + @TableName +']' 
							+'		FROM ['+ @SchemaTable +'].[' + @TableName +'] WHERE [' + @ColumnName + '] ' 
							+ CASE WHEN @UseTableTargetID = 1 THEN ' IN (SELECT TargetID FROM #TargetID)' 
							  ELSE ' = ' + Cast(@TargetID as nvarchar(100)) END
					
					IF @UseTableTargetID = 1 AND @TableName = @Table AND @ColumnName <> @PrimeIDName 
						Set @Sql =N'    UPDATE ['+ @SchemaTable +'].[' + @TableName +'] SET [' + @ColumnName + '] = NULL ' 
								+'		FROM ['+ @SchemaTable +'].[' + @TableName +'] WHERE [' + @ColumnName + '] IN (SELECT TargetID FROM #TargetID)' 

					IF @Table = 'PortfolioTask' AND @LevelID > 1
					  BEGIN
						Set @Sql =N'    UPDATE ['+ @SchemaTable +'].[' + @TableName +'] SET [' + @ColumnName + '] = NULL ' 
									+'	 FROM ['+ @SchemaTable +'].[' + @TableName +'] WHERE [' + @ColumnName + '] = ' + Cast(@TargetID as nvarchar(100))
						SET @Count = 0
					  END
					
					INSERT #TableNameList (TableName, SchemaTable, ColumnName, [RowCount], LevelID, PrimeKeyID, SqlCmd, TargetID) 
					VALUES (@TableName, @SchemaTable, @ColumnName, @Count, @_LevelID, @PrimeKeyID, @Sql, @TargetID)
				END

				IF @OperationTypeID IN( 2, 3) AND @LevelID = 1 AND
					NOT EXISTS( SELECT * FROM #ExcludeTable WHERE TableName = @TableName AND ISNULL(SchemaTable, 'dbo') = @SchemaTable AND OperationTypeID IN( 2, 3))
				BEGIN
					DECLARE @stop bit	SET @stop = 1	-- stop cascade deleting for updated row

					Set @Sql =N'    UPDATE ['+ @SchemaTable +'].[' + @TableName +'] SET   [' + @ColumnName + '] = ' + Cast(@SourceID as nvarchar(100))
							+'		FROM ['+ @SchemaTable +'].[' + @TableName +']   WHERE [' + @ColumnName + '] = ' + Cast(@TargetID as nvarchar(100))
					
					SET @TranCounter = @@TRANCOUNT 
					IF @@TRANCOUNT = 0
						BEGIN TRANSACTION	-- Test Update tran
					ELSE
						SAVE TRANSACTION ProcedureSave;

						BEGIN TRY
							EXEC sp_executesql  @Sql  	
						END TRY
						BEGIN CATCH
							SET @Sql = '--	' + @Sql + '	--	Skip update due to the error: ' + ERROR_MESSAGE()
							SET @stop = 0
						END CATCH

					IF @@TRANCOUNT > 0
						IF @TranCounter = 0 ROLLBACK TRANSACTION
						ELSE 
						ROLLBACK TRANSACTION ProcedureSave;

					INSERT #TableNameList (TableName, SchemaTable, ColumnName, [RowCount], LevelID, PrimeKeyID, SqlCmd, TargetID, SourceID) 
					VALUES (@TableName, @SchemaTable, @ColumnName, CASE WHEN @stop = 1 THEN @Count ELSE 0 END, 100, @PrimeKeyID, @Sql, @TargetID, @SourceID)					
					
					IF @stop = 1 SET @Count = 0		-- stop cascade deleting for updated row
				END
			END
		END

		SELECT @_LevelID = @_LevelID + 1

		if @OperationTypeID <> 2 and @Count <> 0 and @UseTableTargetID <> 1
			and (  EXISTS(SELECT * FROM dbo.fn_dev_FKfields( @TableName, @SchemaTable)) 
				OR EXISTS(SELECT * FROM #ExtForeignKey WHERE TableRefName = @TableName AND ISNULL(SchemaTableRef, 'dbo') = @SchemaTable))
			BEGIN 
				DECLARE @ItemIndex TABLE( items int)

				DECLARE @ItemID int	SET @ItemID = NULL

				INSERT INTO @ItemIndex(items)
				SELECT items FROM [dbo].[fn_dev_Split](@PrimeKeyID, ',')
				
				SELECT Top 1 @ItemID = items FROM @ItemIndex
				ORDER BY items 

				WHILE @ItemID IS NOT NULL
				BEGIN
			
					EXEC [dbo].[sp_dev_ObjectMove] @OperationTypeID = @OperationTypeID, @Table = @TableName, @Schema = @SchemaTable, @TargetID = @ItemID, @SourceID = NULL, @LevelID = @_LevelID, @WithOutput =0 

					if EXISTS( SELECT * FROM @ItemIndex WHERE @ItemID < items)
						SELECT Top 1 @ItemID = items FROM @ItemIndex
						WHERE @ItemID < items 
						ORDER BY items 
					ELSE
						SET @ItemID = NULL

				END
				DELETE FROM @ItemIndex
			END

		---!!!!!!!!!!-------
		FETCH NEXT FROM Table_Cursor INTO @TableName, @ColumnName, @ConstraintName, @TableRefName, @ColumnRefName, @SchemaTable, @SchemaTableRef
		---!!!!!!!!!!-------
	END

	CLOSE Table_Cursor
	DEALLOCATE Table_Cursor


	if @LevelID = 1
	BEGIN
		DECLARE @RowID int 		
		DECLARE @HasError bit	SET @HasError = 0

		DECLARE Table_Cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT RowID, SqlCmd
			FROM #TableNameList
			WHERE TableName IS NOT NULL 
			ORDER BY LevelID DESC, RowID ASC

		OPEN Table_Cursor 
		
		SET @TranCounter = @@TRANCOUNT 
		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION	
		ELSE
			SAVE TRANSACTION ProcedureSave2;
		print '--===== Executed Script ==============='
		FETCH NEXT FROM Table_Cursor INTO @RowID, @Sql
		WHILE @@FETCH_STATUS = 0 AND @ApplyScript = 1 AND @OperationTypeID <> 0
			BEGIN
				BEGIN TRY
					print @Sql
					SET @Count = 0
					SET @Sql = @Sql + ' SET @Count = @@ROWCOUNT'
					EXEC sp_executesql  @Sql , N'@Count int OUTPUT', @Count OUTPUT

					UPDATE #TableNameList 
					SET RowCmd = @Count,
						Msg = 'Successfully' + CASE WHEN LevelID between 0 AND 50 THEN ' deleted' 
													WHEN LevelID = 100			  THEN ' updated' ELSE ' done' END
					WHERE RowID = @RowID
			
				END TRY
				BEGIN CATCH
			
					UPDATE #TableNameList 
					SET RowCmd = @Count,
						Msg = 'Error: ' + ISNULL( ERROR_MESSAGE(), '')
					WHERE RowID = @RowID
					SET @HasError = 1
		
				END CATCH

				FETCH NEXT FROM Table_Cursor INTO @RowID, @Sql
			END
		CLOSE Table_Cursor
		DEALLOCATE Table_Cursor
		print '--====================================='
		----- Result ------
		IF @WithOutput = 1 --OR ( @ApplyScript = 1 AND @OperationTypeID <> 0)
		SELECT 
			[Object]	= ISNULL( ISNULL( '[' + SchemaTable + '].', '') + '[' + TableName + ']', ''), 
			[Target]	= ISNULL( '[' + ColumnName + ']' + ISNULL(' = ' + Cast(TargetID as nvarchar(100)), ''), ''), 
			[Script]	= ISNULL( SqlCmd, ''),
			[Message]	= ISNULL( Msg, ''),
			[Count]		= ISNULL( RTRIM(LTRIM(STR(CASE WHEN @ApplyScript = 1 AND @OperationTypeID <> 0 THEN RowCmd ELSE [RowCount] END))), '')
		FROM #TableNameList
		ORDER BY LevelID DESC, RowID ASC

		--SET @HasError = 1 -- just for test

		IF @HasError = 0
		BEGIN 
			IF @@TRANCOUNT > 0
				IF @TranCounter = 0 COMMIT TRANSACTION
				ELSE 
				COMMIT TRANSACTION ProcedureSave1;
		END
		ELSE 
			IF @@TRANCOUNT > 0
				IF @TranCounter = 0 ROLLBACK TRANSACTION
				ELSE 
				ROLLBACK TRANSACTION ProcedureSave1;
	END



END
