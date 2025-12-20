/*

This script moves data from a source database to a target database. In the case where the target database already
has some data it moves the missing data

*/
DECLARE @SourceDB NVARCHAR(100);
DECLARE @TargetDB NVARCHAR(100);
DECLARE @SourceTable NVARCHAR(100);
DECLARE @TargetTable NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @PKColumns NVARCHAR(100);
DECLARE @HasIdentityCol INT;
DECLARE @FKName NVARCHAR(100);
DECLARE @NumOfMissingRows INT;
DECLARE @PKColumnCount INT;
DECLARE @JoinColumns NVARCHAR(max)
DECLARE @ColumnList NVARCHAR(MAX)

SET @TargetDB = DB_NAME()
SET @SourceDB = 'DRAS_IRASv6_DEMO_QA'

------------------------------------ Temporary Tables Created by Script ----------------------------------------

IF OBJECT_ID ('tempdb..##TableLoadList') IS NOT NULL
BEGIN
	DROP TABLE ##TableLoadList
END

IF OBJECT_ID ('tempdb..##TableLoadList') IS NULL
BEGIN
	CREATE TABLE ##TableLoadList (Id INT IDENTITY (1,1),
									TableName NVARCHAR(100))
END

------------------------------------ Disable Foreign Key Constraints ----------------------------

DECLARE ForeignKey_Cursor CURSOR FOR
SELECT name, OBJECT_NAME(parent_object_id) AS Tablename
FROM sys.foreign_keys

OPEN ForeignKey_Cursor
FETCH NEXT FROM ForeignKey_Cursor INTO @FKName, @TargetTable

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'ALTER TABLE ' + QUOTENAME(@TargetDB) + '..' + QUOTENAME(@TargetTable) + ' NOCHECK CONSTRAINT ' + @FKName + ''

	EXECUTE (@SQL)

	FETCH NEXT FROM ForeignKey_Cursor INTO @FKName, @TargetTable
END 

CLOSE ForeignKey_Cursor
DEALLOCATE ForeignKey_Cursor

-------------------------------------- MOVE Missing Data From Source DB to Target DB ---------------------------------------

SET @SQL = 'SELECT name FROM ' + @SourceDB + '.sys.tables
WHERE name IN (SELECT name FROM ' + @TargetDB + '.sys.tables)
AND name NOT IN (''Connection'')'

INSERT INTO ##TableLoadList
EXECUTE (@SQL)


DECLARE TableList_Cursor CURSOR FOR
SELECT TableName FROM ##TableLoadList

OPEN TableList_Cursor
FETCH NEXT FROM TableList_Cursor INTO @TargetTable

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SourceTable = @TargetTable

	SET @PKColumns = NULL
	SET @JoinColumns = NULL
	SET @ColumnList = NULL
	SET @NumOfMissingRows = 0
	SET @HasIdentityCol = 0

	-- Get the number of primary key columns on a table
	SELECT @PKColumnCount = COUNT(*) 
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	WHERE constraint_name = (SELECT name FROM sys.key_constraints
							WHERE parent_object_id = OBJECT_ID(@SourceTable) 
							AND type = 'PK')

	-- Get the list of primary key columns for the target table
	SELECT @PKColumns = COALESCE(@PKColumns + ', ', '') + column_name FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	WHERE constraint_name = (SELECT name FROM sys.key_constraints
							 WHERE parent_object_id = OBJECT_ID(@SourceTable)
								AND type = 'PK')

	SELECT @JoinColumns = COALESCE(@JoinColumns + ' AND ', '') + 'S.' + column_name + ' = ' + 'T.' + column_name
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	WHERE constraint_name = (SELECT name FROM sys.key_constraints
							 WHERE parent_object_id = OBJECT_ID(@SourceTable)
								AND type = 'PK') 
	
	IF OBJECT_ID('tempdb..##TempTable') IS NOT NULL
	BEGIN
		DROP TABLE ##TempTable;
	END

	-- Find row entries in the Source DB that do not exist in the Target DB (To avoid data duplication)
	SET @SQL = 'IF OBJECT_ID(''tempdb..##TempTable'') IS NULL
	BEGIN
		SELECT * INTO ##TempTable 
		FROM ' + @SourceDB + '..' + @SourceTable + ' S
		WHERE NOT EXISTS (SELECT *
							FROM ' + @TargetDB + '..' + @TargetTable + ' T
							WHERE ' + @JoinColumns+ ') 
	END';
	
	EXECUTE (@SQL)

	-- Get number of missing rows from source db in the target table
	SET @SQL = 'IF OBJECT_ID(''tempdb..##TempTable'') IS NOT NULL
	BEGIN
		SELECT @Result = COUNT(*) FROM ##TempTable
	END'

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @NumOfMissingRows OUTPUT

	IF @PKColumns IS NOT NULL
	BEGIN
		SELECT @ColumnList = COALESCE(@ColumnList + '], [', '') + column_name 
		FROM 
		INFORMATION_SCHEMA.columns WHERE table_name = @TargetTable

		SET @ColumnList = '[' + @ColumnList + ']'
	END

	-- If there are rows in the source table missing from the target table, insert the missing rows 
	IF @NumOfMissingRows <> 0
	BEGIN
		
		-- Check if the numeric PK column is also an identity column
		IF (@PKColumnCount = 1)
			AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(@TargetTable) AND COL_NAME(object_id, column_id) = @PKColumns)
		BEGIN
			SET @HasIdentityCol = 1		
		END

		-- Build and execute command to insert missing data into the target database
		SET @SQL = '
		BEGIN TRANSACTION
			INSERT INTO ' + @TargetDB + '..' + @TargetTable + ' (' + @ColumnList + ')
			SELECT * FROM ##TempTable
		COMMIT TRANSACTION' 

		-- Add the IDENTITY_INSERT command if there is an identity column
		IF (@HasIdentityCol = 1)
		BEGIN 
			SET @SQL = 'SET IDENTITY_INSERT ' +@TargetDB+ '..' + @TargetTable+ ' ON' + @SQL 
			           + CHAR(13) +'SET IDENTITY_INSERT ' +@TargetDB+ '..' + @TargetTable+ ' OFF'
		END
	
		EXECUTE (@SQL)
	
	END 

	FETCH NEXT FROM TableList_Cursor INTO @TargetTable

END

CLOSE TableList_Cursor
DEALLOCATE TableList_Cursor

------------------------------------ ENABLE Foreign Key Constraints ------------------------

DECLARE ForeignKey_Cursor CURSOR FOR
SELECT name, OBJECT_NAME(parent_object_id) 
FROM sys.foreign_keys

OPEN ForeignKey_Cursor
FETCH NEXT FROM ForeignKey_Cursor INTO @FKName, @TargetTable

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'ALTER TABLE ' + @TargetTable + ' CHECK CONSTRAINT ' + @FKName + ''

	EXECUTE (@SQL)

	FETCH NEXT FROM ForeignKey_Cursor INTO @FKName, @TargetTable
END 

CLOSE ForeignKey_Cursor
DEALLOCATE ForeignKey_Cursor
