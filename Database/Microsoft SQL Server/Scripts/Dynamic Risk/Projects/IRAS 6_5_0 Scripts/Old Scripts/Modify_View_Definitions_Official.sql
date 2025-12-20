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


IF OBJECT_ID ('tempdb..##ONClause') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE ##ONClause'
	EXECUTE (@SQL)
END

IF OBJECT_ID ('tempdb..##ONClause') IS NULL
BEGIN
	CREATE TABLE ##ONClause (StartIndex INT,
							 TableAlias NVARCHAR(100),
							 ColumnName NVARCHAR(100))
END

DECLARE ViewListCursor CURSOR FOR
SELECT TOP 5 table_name FROM INFORMATION_SCHEMA.tables
WHERE table_type = 'VIEW'
AND table_name = 'IncidentVw'

OPEN ViewListCursor
FETCH NEXT FROM ViewListCursor INTO @ViewName

WHILE @@FETCH_STATUS = 0
BEGIN

------------------------ Remove multispacing from view definitions (double space, triple space, etc) ----------------------

	SELECT @ObjectDefinition = OBJECT_DEFINITION (OBJECT_ID(N'dbo.' + @ViewName + ''));  

	select @ViewName

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

			SET @StartIndex = @EndIndex + 1

		END

------------------------------------ Find All JOIN clauses ---------------------------------
	
		SET @StartIndex = 1

		WHILE @StartIndex < @StrLength
		BEGIN
			-- Get table name
			SELECT @StartIndex = CHARINDEX('JOIN', @ObjectDefinition, @StartIndex)

			SELECT @ClauseStartIndex = StartIndex FROM ##SQLClauseTab
			WHERE Type = 'FROM'
			AND StartIndex < @StartIndex

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

			SET @StartIndex = @EndIndex + 1
		END

		--SELECT * from ##SQLClauseTab
		--break
	----------------------------------- Find all ON clauses ------------------------------

		--SELECT @StartIndex = MIN(StartIndex) FROM ##SQLClauseTab
		SELECT @StartIndex = PATINDEX('%JOIN%ON%', @ObjectDefinition)

		WHILE @StartIndex < @StrLength
		BEGIN
			-- Get table name
			SELECT @StartIndex = CHARINDEX(' ON ', @ObjectDefinition, @StartIndex)
		
			SELECT @ClauseStartIndex = StartIndex FROM ##SQLClauseTab
			WHERE Type = 'FROM'
			AND StartIndex < @StartIndex

			IF (@StartIndex = 0)
			BEGIN
				BREAK
			END

			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 4
			SELECT @EndIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex)

			SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
			SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

			SELECT @StartIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex) + 1
			SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)

			INSERT INTO ##SQLClauseTab
			VALUES (@ClauseStartIndex, 
					'ON', 
					(SELECT TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
					AND TableName IS NOT NULL), 
					REPLACE(@TableAlias, CHAR(13), ''), 
					@ColumnName,
					NULL) 

			SELECT @StartIndex = CHARINDEX('=', @ObjectDefinition, @EndIndex) 
			SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
			SELECT @EndIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex)

			SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
			SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

			SELECT @StartIndex = @EndIndex + 1
			SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
			SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)

			INSERT INTO ##SQLClauseTab
			VALUES (@ClauseStartIndex, 
					'ON', 
					(SELECT TOP 1 TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
					AND TableName IS NOT NULL), 
					REPLACE(@TableAlias, CHAR(13), ''), 
					@ColumnName,
					NULL) 

		END		

			select * from ##SQLClauseTab
		break

	------------------------------  Get all Join conditions after AND operator ---------------------------------
		
		SET @StartIndex = 1
		SELECT @StartIndex = CHARINDEX('AND', @ObjectDefinition, @EndIndex)

			SELECT @NextClauseIndex = MIN(DISTINCT StartIndex) 
			FROM ##SQLClauseTab
			WHERE StartIndex > @ClauseStartIndex

			--IF (@StartIndex >= @NextClauseIndex)
			--BEGIN
			--	BREAK
			--END
			--ELSE
			--BEGIN
				WHILE @StartIndex < @NextClauseIndex
				BEGIN
					SELECT @StartIndex = CHARINDEX('AND', @ObjectDefinition, @StartIndex)

					IF (@StartIndex = 0)
					BEGIN
						BREAK
					END

					SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
					SELECT @EndIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex)

					SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
					SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

					SELECT @StartIndex = @EndIndex + 1
					SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
					SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)

					INSERT INTO ##SQLClauseTab
					VALUES (@ClauseStartIndex, 
							'AND', 
							(SELECT TOP 1 TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
							AND TableName IS NOT NULL), 
							REPLACE(@TableAlias, CHAR(13), ''), 
							@ColumnName,
							NULL) 

					SELECT @StartIndex = CHARINDEX('=', @ObjectDefinition, @EndIndex) 
					SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
					SELECT @EndIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex)

					SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
					SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

					SELECT @StartIndex = @EndIndex + 1
					SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
					SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)

					INSERT INTO ##SQLClauseTab
					VALUES (@ClauseStartIndex, 
							'AND', 
							(SELECT TOP 1 TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
							AND TableName IS NOT NULL), 
							REPLACE(@TableAlias, CHAR(13), ''), 
							@ColumnName,
							NULL) 

					SET @StartIndex = @EndIndex + 1

				--END
			END

			--SET @StartIndex = @EndIndex + 1
		--END

	

		SET @SQL = 'WITH tmpQuery AS (
					SELECT SCT.*, tmp.ListDomainTableName FROM ##SQLClauseTab SCT
					JOIN TempListDomainTable tmp
					ON tmp.ReferencedColumnName = SCT.ColumnName
					AND tmp.ReferencedTableName = SCT.TableName
					WHERE SCT.StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
										WHERE TableName = ''ListDomain'')
					)
					UPDATE ##SQLClauseTab
					SET NewLDTableName = Tab2.ListDomainTableName
					FROM ##SQLClauseTab Tab1
					JOIN tmpQuery Tab2
					ON Tab1.StartIndex = Tab2.StartIndex
					WHERE Tab1.TableName = ''ListDomain'''

		EXECUTE (@SQL)
		
		select * from ##SQLClauseTab

	/*********************************************************************************************************
		 Modify View Definiion 
	**********************************************************************************************************/

	--------------------- Remove multispacing from view definitions (double space, triple space, etc) ----------

	--	SELECT @ObjectDefinition = OBJECT_DEFINITION (OBJECT_ID(N'dbo.' + @ViewName + ''));  

	--	SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)

	--	WHILE @MultiSpaceExists <> 0
	--	BEGIN
	--		SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, '  ', ' ') 
 --			SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)
	--	END

		--------------------------- Cursor to do a search and replace for ListDomain table name ---------------

		DECLARE SearchNReplaceCursor CURSOR FOR
		SELECT StartIndex, Type, TableName, TableAlias, NewLDTableName 
		FROM ##SQLClauseTab
		WHERE StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
							WHERE TableName = 'ListDomain')
		AND TableName = 'ListDomain'
		ORDER BY 1, 2

		OPEN SearchNReplaceCursor
		FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SQL = 'SELECT @Result = REPLACE(''' + REPLACE(@ObjectDefinition, '''', '''''') 
						+ ''',''' + @TableName + ' ' + REPLACE(@TableAlias, CHAR(10), '') + ''''
						+ ', ''' + @NewTableName + ' ' + @TableAlias+ ''')'

			select @sql
			EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUT', @ObjectDefinition OUT
	
			FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName
		END 
	
		CLOSE SearchNReplaceCursor
		DEALLOCATE SearchNReplaceCursor

		break
		------------------------------------- Recreate View -------------------------------------------

		SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, 'Create View', 'CREATE OR ALTER VIEW')
		EXECUTE (@ObjectDefinition)

	END

	FETCH NEXT FROM ViewListCursor INTO @ViewName

END

CLOSE ViewListCursor
DEALLOCATE ViewListCursor

return
select * from ##SQLClauseTab
order by 1, 2

SELECT * FROM ##SQLClauseTab
WHERE StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
					WHERE TableName = 'ListDomain')
AND TableName = 'ListDomain'
order by 1, 2