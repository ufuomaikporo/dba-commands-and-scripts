-- 5_Modify_View_Definitions.sql
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

OPEN ViewListCursor
FETCH NEXT FROM ViewListCursor INTO @ViewName

WHILE @@FETCH_STATUS = 0
BEGIN
	--delete the ##SQLClauseTab and set the ListDomain table as the only table non-existing table allowed in view definition
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
			SELECT @ClauseStartIndex = CHARINDEX('FROM ', @ObjectDefinition, @StartIndex)

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
			SELECT @Tablename = REPLACE(REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), ''), ',', '')

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

/*
	Find all table-qualifed columns in the 'ON' predicate of the JOIN clause of each view definition, then
	match the column (using the tables alias) to a table name.
*/

		DECLARE ColumnList_Cursor CURSOR FOR
		SELECT DISTINCT TableAlias FROM ##SQLClauseTab
		WHERE TableAlias IS NOT NULL AND TableAlias <> ' '
					
		OPEN ColumnList_Cursor
		FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Find the very first JOIN clause in the View definition
			SELECT @StartIndex = MIN(StartIndex) FROM ##SQLClauseTab
			WHERE Type = 'JOIN'

						
			WHILE @StartIndex < @StrLength
			BEGIN
				-- Find the first instance of a table-qualified column reference using the current table alias
				SELECT @StartIndex = CHARINDEX(' ' + @TableAlias + '.', @ObjectDefinition, @StartIndex) 	

				-- Exit if no instance of a table-qualified reference for the current table alias is found 
				IF (@StartIndex = 0)
				BEGIN
					BREAK
				END

				-- Find the JOIN clause that comes before the first instance where the current table alias is used as table-qualified column in a JOIN predicate
				SELECT @ClauseStartIndex = MAX(StartIndex) FROM ##SQLClauseTab
				WHERE StartIndex < @StartIndex
				AND Type = 'JOIN'
																
				-- Get the start position of the column name (aliased using the current table alias) as part of the JOIN predicate
				SELECT @StartIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex) + 1

				-- Use the nearest whitespace after the table-qualified column reference to find the end of column name string
				IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex) AND CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) <> 0)
				BEGIN
					SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
				END
				ELSE
				BEGIN
					SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
				END

				-- If @StartIndex is non-zero and @EndIndex is 0 then you are at the end of the view definition
				IF @EndIndex = 0 AND @StartIndex > 0
				BEGIN
					SELECT @EndIndex = LEN(@ObjectDefinition) + 1
				END

				--Get the column name (aliased by the current table alias) from the JOIN predicate
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

		UPDATE ##SQLClauseTab
		SET TableName = REPLACE(TableName, 'dbo.', '')

--------------- Match ListDomain entries in View Definition to new ListDomain tables ------------------------	

		-- Use the starting index of the JOIN operations to match the ListDomain Id column with the 
		SET @SQL = 'WITH tmpQuery AS (
					SELECT SCT.*, tmp.LDTableName 
					FROM ##SQLClauseTab SCT
					JOIN TempListDomainTable tmp
					ON tmp.ColumnName = SCT.ColumnName
					AND tmp.TableName = SCT.TableName
					WHERE SCT.StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
										WHERE TableName = ''ListDomain'')
					AND tmp.ColumnName IS NOT NULL
					)
					UPDATE ##SQLClauseTab
					SET NewLDTableName = Tab2.LDTableName
					FROM ##SQLClauseTab Tab1
					JOIN tmpQuery Tab2
					ON Tab1.StartIndex = Tab2.StartIndex
					WHERE Tab1.TableName = ''ListDomain'''

		EXECUTE sp_executesql @SQL

----------------------- Store views that contain missing tables in a tmp table --------------------

	--SET @Count = 0

	IF OBJECT_ID('tmp_InvalidViews') IS NULL
	BEGIN
		CREATE TABLE tmp_InvalidViews (ViewName NVARCHAR(100),
										Definition NVARCHAR(MAX),
										DropCommand NVARCHAR(100))

	END

	-- Find all non-existing tables in the view definition
	SET @SQL = '
	IF OBJECT_ID(''tempdb..##Result'') IS NOT NULL
	BEGIN
		DROP TABLE ##Result
	END 

	
	SELECT DISTINCT(TableName) TableName
	INTO ##Result
	FROM ##SQLClauseTab
	WHERE TableName NOT IN (' + @ExemptTableList + ')
	AND TableName NOT IN (SELECT name FROM sys.tables)'

	EXECUTE sp_executesql @SQL
							   				
	-- Get count of missing/non-existing tables in view definition
	SELECT @Count = COUNT(*) FROM ##Result
				
	-- if the view definition has missing tables add the view name and definition to tmp_InvalidViews if not already there
	IF (@Count <> 0)
	BEGIN
					
		IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName = @ViewName)
		BEGIN
			INSERT INTO tmp_InvalidViews
			SELECT @ViewName, 
					'EXEC sp_helptext N''dbo.' + @ViewName + '''',
					'DROP VIEW ' + @ViewName + ''
					
		END

	END
		
/*********************************************************************************************************
					                Modify View Definiion 
**********************************************************************************************************/

--------------------------------- Modify View Definition ----------------------------

		DECLARE SearchNReplaceCursor CURSOR FOR
		SELECT StartIndex, Type, TableName, TableAlias, NewLDTableName 
		FROM ##SQLClauseTab
		WHERE StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
							WHERE TableName = 'ListDomain')
		AND TableName = 'ListDomain'
		AND NewLDTableName IS NOT NULL

		OPEN SearchNReplaceCursor
		FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Replace ListDomain table wherever it is mentioned with the new list domain table name
			SELECT @ObjectDefinition = REPLACE (@ObjectDefinition, 
							@TableName + ' ' + @TableAlias,
							@NewTableName + ' ' + @TableAlias)
													
			FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

		END 
	
		CLOSE SearchNReplaceCursor
		DEALLOCATE SearchNReplaceCursor

-------------------------------------- Recreate View -------------------------------------------
		
		SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, 'Create View', 'CREATE OR ALTER VIEW')
					
		-- Create or alter the view if all the tables in view deinition exist
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
		SELECT 'Invalid view found'
		SELECT * FROM tmp_InvalidViews
	END
	ELSE
	BEGIN
		DROP TABLE tmp_InvalidViews
	END
END