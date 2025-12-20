/*

This script updates the view definitions for views referencing the former ListDomain to reference the 
new 'LD_' and 'GLD_' tables. Must be executed on the target database

*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ObjectDefinition NVARCHAR(MAX)
DECLARE @FromClause NVARCHAR(300)
DECLARE @JoinClause NVARCHAR(300)
DECLARE @TableName NVARCHAR(100)
DECLARE @StartIndex INT
DECLARE @EndIndex INT
DECLARE @ClauseStartIndex INT
DECLARE @NextClauseIndex INT
DECLARE @TableAlias NVARCHAR(100)
DECLARE @MultiSpaceExists INT
DECLARE @StrLength INT
DECLARE @PreviousIndex INT
DECLARE @ColumnName NVARCHAR(100)
DECLARE @ViewName NVARCHAR(100)
DECLARE @Type NVARCHAR(100)
DECLARE @NewTableName NVARCHAR(100)
DECLARE @Count INT
DECLARE @ExemptTableList NVARCHAR(500)
-------------------------------------- Table Declaration/Creation -------------------------

IF OBJECT_ID ('tempdb..##SQLClauseTab') IS NOT NULL
BEGIN
	DROP TABLE ##SQLClauseTab
END

IF OBJECT_ID ('tempdb..##SQLClauseTab') IS NULL
BEGIN
	CREATE TABLE ##SQLClauseTab (StartIndex INT,
								 Type VARCHAR(20),
								 TableName NVARCHAR(100),
								 TableAlias NVARCHAR(100),
								 ColumnName NVARCHAR(100),
								 NewLDTableName VARCHAR(100))

END


DECLARE ViewListCursor CURSOR FOR
SELECT table_name FROM INFORMATION_SCHEMA.tables
WHERE table_type = 'VIEW'
--AND table_name = 'PipeSegmentVw'

OPEN ViewListCursor
FETCH NEXT FROM ViewListCursor INTO @ViewName

set @count = 0
WHILE @@FETCH_STATUS = 0
BEGIN

	DELETE FROM ##SQLClauseTab
	SET @ExemptTableList = '''ListDomain'''

---------------------- Remove multispacing from view definitions (double space, triple space, etc) ----------------------

	SET @ObjectDefinition = NULL

	SELECT @ObjectDefinition = OBJECT_DEFINITION (OBJECT_ID(N'dbo.' + @ViewName + ''));  

	SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)

	WHILE @MultiSpaceExists <> 0
	BEGIN
		SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, '  ', ' ') 
 		SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)
	END

	IF (CHARINDEX('ListDomain', @ObjectDefinition) <> 0)
	BEGIN

-------------------------------- Find All FROM Clauses -----------------------------------

		SELECT @StrLength = LEN(@ObjectDefinition)
		 
		SET @StartIndex = 1

		WHILE @StartIndex < @StrLength
		BEGIN
			-- Get table name
			SELECT @ClauseStartIndex = CHARINDEX('FROM', @ObjectDefinition, @StartIndex)

			IF (@ClauseStartIndex = 0)
			BEGIN
				BREAK
			END

			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @ClauseStartIndex) + 1

			IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
			BEGIN
				SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
			END
			ELSE
			BEGIN
				SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			END

			SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
			SELECT @Tablename = REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), '')

			-- Get table alias name
			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
			IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
			BEGIN
				SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
			END
			ELSE
			BEGIN
				SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			END

			SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex  - @StartIndex)
			SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

			INSERT INTO ##SQLClauseTab
			VALUES (@ClauseStartIndex, 
					'FROM', 
					@TableName, 
					@TableAlias, 
					NULL, 
					NULL)

			IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
				AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
			BEGIN
				SET @ExemptTableList += ', ''' + @TableName+ ''''
			END

			SET @StartIndex = @EndIndex + 1

		END
		
------------------------------------ Find All JOIN clauses ---------------------------------
	
		SET @StartIndex = 1

		WHILE @StartIndex < @StrLength
		BEGIN
			-- Get table name
			SELECT @ClauseStartIndex = CHARINDEX('JOIN ', @ObjectDefinition, @StartIndex) 

			SET @StartIndex = @ClauseStartIndex 

			IF (@StartIndex = 0)
			BEGIN
				BREAK
			END

			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
			
			IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
			BEGIN
				SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
			END
			ELSE
			BEGIN
				SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			END

			SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
			SELECT @Tablename = REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), '')

			-- Get table alias name
			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
			IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
			BEGIN
				SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
			END
			ELSE
			BEGIN
				SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			END

			SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
			SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

			INSERT INTO ##SQLClauseTab
			VALUES (@ClauseStartIndex, 
					'JOIN', 	
					@TableName, 
					@TableAlias, 
					NULL, 
					NULL)

			IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
				AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
			BEGIN
				SET @ExemptTableList += ', ''' + @TableName+ ''''
			END

			SET @StartIndex = @EndIndex + 1
		END
		
-------------------------------- Find all table-qualified columns within a View definition --------------------------------

/*Find all table-qualifed columns within the view definition and match it with the start position of a JOIN operation.
 This will match the arguments in the 
*/

		DECLARE ColumnList_Cursor CURSOR FOR
		SELECT DISTINCT TableAlias FROM ##SQLClauseTab
		WHERE TableAlias IS NOT NULL AND TableAlias <> ' '

		OPEN ColumnList_Cursor
		FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias

		WHILE @@FETCH_STATUS = 0
		BEGIN

			SELECT @StartIndex = MIN(StartIndex) FROM ##SQLClauseTab
			WHERE Type = 'JOIN'
			
			WHILE @StartIndex < @StrLength
			BEGIN
				
				SELECT @StartIndex = CHARINDEX(@TableAlias + '.', @ObjectDefinition, @StartIndex) 	

				IF (@StartIndex = 0)
				BEGIN
					BREAK
				END

				SELECT @ClauseStartIndex = MAX(StartIndex) FROM ##SQLClauseTab
				WHERE StartIndex < @StartIndex
				AND Type = 'JOIN'

				-- Get table alias and column name on left side of equal sign in the ON clause
				SELECT @StartIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex) + 1

				IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
				BEGIN
					SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
				END
				ELSE
				BEGIN
					SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
				END

				SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
				SELECT @ColumnName = REPLACE(REPLACE(@ColumnName, CHAR(13), ''), CHAR(10), '')

				INSERT INTO ##SQLClauseTab
				VALUES (@ClauseStartIndex, 
						'COLUMN', 
						(SELECT TOP 1 TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
						AND TableName IS NOT NULL), 
						@TableAlias, 
						@ColumnName,
						NULL) 

				IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
					AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
				BEGIN
					SET @ExemptTableList += ', ''' + @TableName+ ''''
				END
						
				SET @StartIndex = @EndIndex + 1
			END
			
			FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias
		END

		CLOSE ColumnList_Cursor
		DEALLOCATE ColumnList_Cursor

--------------- Match ListDomain entries in View Definition to new ListDomain tables ------------------------	

-- Use the starting index of the JOIN operations to match the ListDomain Id column with the 

		SET @SQL = 'WITH tmpQuery AS (
					SELECT SCT.*, tmp.ListDomainTableName 
					FROM ##SQLClauseTab SCT
					JOIN TempListDomainTable tmp
					ON tmp.ReferencedColumnName = SCT.ColumnName
					AND tmp.ReferencedTableName = SCT.TableName
					WHERE SCT.StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
										WHERE TableName = ''ListDomain'')
					AND ColumnName IS NOT NULL
					)
					UPDATE ##SQLClauseTab
					SET NewLDTableName = Tab2.ListDomainTableName
					FROM ##SQLClauseTab Tab1
					JOIN tmpQuery Tab2
					ON Tab1.StartIndex = Tab2.StartIndex
					WHERE Tab1.TableName = ''ListDomain'''

		EXECUTE (@SQL)
		
----------------------- Store views that contain missing tables in a tmp table --------------------

	SET @Count = 0

	IF OBJECT_ID('tmp_InvalidViews') IS NULL
	BEGIN
		CREATE TABLE tmp_InvalidViews (ViewName NVARCHAR(100),
										Definition NVARCHAR(MAX),
										DropCommand NVARCHAR(100))

	END

	SET @SQL = '
	IF OBJECT_ID(''tempdb..##Result'') IS NOT NULL
	BEGIN
		DROP TABLE ##Result
	END 

	SELECT DISTINCT(TableName) 
	INTO ##Result
	FROM ##SQLClauseTab
	WHERE TableName NOT IN (' + @ExemptTableList + ')
	AND TableName NOT IN (SELECT name FROM sys.tables)'

	EXECUTE (@SQL)

	SELECT @Count = COUNT(*) FROM ##Result

	IF (@Count <> 0)
	BEGIN

		IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName = @ViewName)
		BEGIN
			INSERT INTO tmp_InvalidViews
			SELECT @ViewName, 
					'EXEC sp_helptext N''dbo.' + @ViewName + '''',
					'DROP VIEW ' + @ViewName + ''
					
		END

		EXECUTE (@SQL)

	END
		
--/*********************************************************************************************************
--		                            Modify View Definiion 
--**********************************************************************************************************/

----------------------------------- Modify View Definition ----------------------------

		DECLARE SearchNReplaceCursor CURSOR FOR
		SELECT StartIndex, Type, TableName, TableAlias, NewLDTableName 
		FROM ##SQLClauseTab
		WHERE StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
							WHERE TableName = 'ListDomain')
		AND TableName = 'ListDomain'
		AND NewLDTableName IS NOT NULL
		--ORDER BY 1, 2

		OPEN SearchNReplaceCursor
		FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

		-- Replace ListDomain table wherever it is mentioned with the new list domain table name
		WHILE @@FETCH_STATUS = 0
		BEGIN

			SELECT @ObjectDefinition = REPLACE (@ObjectDefinition, 
							@TableName + ' ' + @TableAlias,
							@NewTableName + ' ' + @TableAlias)
													
			FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName
		END 
	
		CLOSE SearchNReplaceCursor
		DEALLOCATE SearchNReplaceCursor


-------------------------------------- Recreate View -------------------------------------------
		
		SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, 'Create View', 'CREATE OR ALTER VIEW')

		IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName =  @ViewName)
		BEGIN
			EXECUTE (@ObjectDefinition)
		END

	END

	FETCH NEXT FROM ViewListCursor INTO @ViewName

END

CLOSE ViewListCursor
DEALLOCATE ViewListCursor

IF OBJECT_ID ('tmp_InvalidViews') IS NOT NULL
BEGIN
	IF EXISTS (SELECT 1 FROM tmp_InvalidViews) 
	BEGIN
		PRINT 'The following Views could not be modified due to invalid tables in the view definition'
		SELECT * FROM tmp_InvalidViews
	END
	ELSE
	BEGIN
		DROP TABLE tmp_InvalidViews
	END
END

