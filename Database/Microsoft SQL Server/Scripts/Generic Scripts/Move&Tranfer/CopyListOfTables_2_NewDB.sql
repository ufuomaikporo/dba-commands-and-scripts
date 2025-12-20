USE DrasInternal
/*
This script copies specified tables from a specified source database into the specified target schema of the 
database where the script is being executed

NOTE**
1. this script must be executed on the target database
2. Re-running the script may create duplicate data for tables without an 'Id' column
3. If no tables are specifed, all tables from the source database will be copied over
4. If the target table does not exist it will be created without primary or foreign keys
*/

DECLARE @TableList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @SourceDB NVARCHAR(100)
DECLARE @HasIdentityColumn INT
DECLARE @TargetSchema NVARCHAR(100)
DECLARE @TruncateBeforeInsert VARCHAR(1)
DECLARE @SourceSchema VARCHAR(100)

--**********************************************************************************************
SET @SourceDB = 'DrasInternal_New'
SET @SourceSchema = 'Unified'
SET @TargetSchema = 'Unified'

-- Set to 'Y' to truncate the data from the target tables before copying data into them
SET @TruncateBeforeInsert = 'Y'


SET @TableList = 'Event_Tables
ILI_Tables
Lookup_Tables
Configuration_Tables
Spatial_Tables
Hierarchy_Tables
History_Tables
DataManager_Tables
DataExchange_Tables
POE_Tables
ComplainceAuditor_Tables
Staging_Tables
TableChecker_Tables
Virtual_Tables
OutsideForce_Tables
IRASCustom_Tables
Risk_Tables'
--**********************************************************************************************
SET @TableList = REPLACE(@TableList, ' ', '')
SET @TableList = REPLACE(@TableList, CHAR(10), ' ')
SET @TableList = REPLACE(@TableList, CHAR(13), '')
SET @TableList = REPLACE(@TableList, CHAR(9), '')
SET @TableList = REPLACE(@TableList, ' ', ''', ''')
SET @TableList = REPLACE(@TableList, ''''', ', '')

SET @TableList = '''' + @TableList + ''''

IF OBJECT_ID('Tempdb..##TmpTable') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE ##TmpTable')
END

IF OBJECT_ID('Tempdb..##TmpTable') IS NULL
BEGIN
	SET @SQL = ' USE ' + @SourceDB + '
			SELECT * INTO ##TmpTable FROM INFORMATION_SCHEMA.tables
			WHERE table_name IN (' + @TableList +')
			AND table_schema = ''' + @SourceSchema + '''' 
	EXECUTE (@SQL)
END

IF @TruncateBeforeInsert = 'Y'
BEGIN
	---------------------------------- Save the Foreign Key definitions in a table ------------------------

	-- Drop the Table for saving foreign key definitions if it has fewer or same number of foreign key entries as exist in database
	IF OBJECT_ID ('Temp_SavedForeignKeys', 'U') IS NOT NULL
	BEGIN
		SET @SQL = '
		IF  OBJECT_ID(''Temp_SavedForeignKeys'') IS NOT NULL
		BEGIN
			DROP TABLE Temp_SavedForeignKeys
		END'

		EXECUTE (@SQL)
	END

	IF OBJECT_ID ('Temp_SavedForeignKeys', 'U') IS NULL
	BEGIN
		SET @SQL = 'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS Id,
				OBJECT_NAME(fkc.constraint_object_id) AS ForeignKeyName,
				SCHEMA_NAME(t1.schema_id) AS FKTableSchema,
				OBJECT_NAME(fkc.parent_object_id) AS FKTableName,
				COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS FKColumnName,
				SCHEMA_NAME(t2.schema_id) AS ReferencedTableSchema,
				OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable,
				COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
				kcu.ordinal_position,
				CAST(NULL AS NVARCHAR(MAX)) AS CreateFK
		INTO Temp_SavedForeignKeys
		FROM sys.foreign_key_columns fkc
		JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
			ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
			AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
		JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
		JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
		WHERE OBJECT_NAME(fkc.referenced_object_id) IN (' + @TableList + ')' 

		EXECUTE (@SQL)

		SET @SQL = 'UPDATE Temp_SavedForeignKeys
		SET CreateFK = (''IF OBJECT_ID ('''''' + ForeignKeyName +'''''', ''''F'''') IS NULL
				BEGIN'' + CHAR(10) + CHAR(9) +
				''ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + CHAR(10) + CHAR(9) +
				 ''WITH CHECK ADD CONSTRAINT '' + QUOTENAME(ForeignKeyName) + CHAR(10) + CHAR(9) + ''FOREIGN KEY ('' +
				 (SELECT STUFF ( 
									(SELECT '', '' + FKColumnName
									FROM Temp_SavedForeignKeys
									WHERE ForeignKeyName = tab1.ForeignKeyName
									ORDER BY ordinal_position
									FOR XML PATH(N''''), TYPE
									).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
							   )
				 )
				 + '')'' + CHAR(10) + CHAR(9) + ''REFERENCES '' + QUOTENAME(ReferencedTableSchema) + ''.'' + QUOTENAME(ReferencedTable) +
				 ''('' + (SELECT STUFF (
										(SELECT '', '' + ReferencedColumn
										 FROM Temp_SavedForeignKeys
										 WHERE ForeignKeyName = tab1.ForeignKeyName
										 ORDER BY ordinal_position
										 FOR XML PATH(N''''), TYPE
										).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
									 )
						) + '')'' + CHAR(10) + ''END'')
			FROM Temp_SavedForeignKeys tab1'

			BEGIN TRAN
				EXECUTE (@SQL)
			COMMIT TRAN

	END

	-------------------------------------- Drop the Foreign Key Definitions ----------------------------------------

	SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)
	DECLARE DropFK_Cursor CURSOR FOR
	SELECT ''IF OBJECT_ID ('''''' + ForeignKeyName +'''''', ''''F'''') IS NOT NULL
	BEGIN
		ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + '' DROP CONSTRAINT ''
		+ QUOTENAME(ForeignKeyName) + CHAR(10) + '' END''
	FROM Temp_SavedForeignKeys

	OPEN DropFK_Cursor
	FETCH NEXT FROM DropFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN	
		EXECUTE (@SQL)
		FETCH NEXT FROM DropFK_Cursor INTO @SQL
	END

	CLOSE DropFK_Cursor
	DEALLOCATE DropFK_Cursor'

	EXECUTE (@SQL)

	------------------------------------ TRUNCATE TABLES -------------------------------------------------------

	SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)
	DECLARE TruncateTable_Cursor CURSOR FOR
	SELECT ''TRUNCATE TABLE '' + QUOTENAME(SCHEMA_NAME(schema_id)) + ''.'' + QUOTENAME(name) 
	FROM sys.tables
	WHERE temporal_type = 0
	AND SCHEMA_NAME(schema_id) = ''' + @TargetSchema + '''
	AND name IN (' + @TableList +')

	OPEN TruncateTable_Cursor
	FETCH NEXT FROM TruncateTable_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM TruncateTable_Cursor INTO @SQL
	END

	CLOSE TruncateTable_Cursor
	DEALLOCATE TruncateTable_Cursor'

	EXECUTE (@SQL)

END

--------------------------------------- Move Data ------------------------------

DECLARE @TableName NVARCHAR(100)

DECLARE TableCursor CURSOR FOR
SELECT table_name FROM ##TmpTable

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Create an empty table if one does not already exist
	IF OBJECT_ID(@TargetSchema + '.' + @TableName, 'U') IS NULL
	BEGIN
		
		SET @SQL = 'SELECT * INTO '+ @TargetSchema + '.' + @TableName +' FROM '+ @SourceDB+'.' + @SourceSchema + '.'+@TableName+'
					WHERE 1 = 2'
		EXECUTE(@SQL)
	END

	SELECT @HasIdentityColumn = OBJECTPROPERTY(OBJECT_ID(@TargetSchema + '.' + @TableName), 'TableHasIdentity')

	-- Copy data over
	SET @SQL = 'INSERT INTO ' + @TargetSchema + '.' + @TableName  + '(' + (SELECT STRING_AGG (column_name, ', ') WITHIN GROUP (ORDER BY ordinal_position)
											FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
											AND table_schema = @TargetSchema
											) + ')'
				+ CHAR(10) + 'SELECT * FROM ' + @SourceDB+'.' + @SourceSchema + '.'+@TableName  + ' a'
			
	-- Prevent insertion of duplicate data for tables with 'Id' coumn
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'Id')
	BEGIN
		SET @SQL += CHAR(10) + 'WHERE NOT EXISTS (SELECT 1 FROM ' + @TargetSchema + '.' + @TableName  + ' b	WHERE a.Id = b.Id)'
	END

	-- Turn on identity insert for tables with identity column
	IF @HasIdentityColumn = 1 
	BEGIN
		SET @SQL = 'SET IDENTITY_INSERT ' + @TargetSchema + '.' + @TableName + ' ON' + CHAR(10) + CHAR(10) + @SQL
				+ CHAR(10) + CHAR(10) + 'SET IDENTITY_INSERT ' + @TargetSchema + '.' + @TableName + ' OFF'
	END

	BEGIN TRAN
		EXECUTE (@SQL)
	COMMIT TRAN

	FETCH NEXT FROM TableCursor INTO @TableName
END
CLOSE TableCursor
DEALLOCATE TableCursor

------------------------------------- RECREATE Foreign Keys ---------------------------------------

IF @TruncateBeforeInsert = 'Y'
BEGIN
	SET @SQL ='DECLARE @SQL NVARCHAR(MAX)
	DECLARE CreateFK_Cursor CURSOR FOR
	SELECT DISTINCT CreateFK FROM Temp_SavedForeignKeys

	OPEN CreateFK_Cursor
	FETCH NEXT FROM CreateFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			EXECUTE(@SQL)
		END TRY
		BEGIN CATCH
			PRINT @SQL;
			THROW
		END CATCH

		FETCH NEXT FROM CreateFK_Cursor INTO @SQL
	END

	CLOSE CreateFK_Cursor
	DEALLOCATE CreateFK_Cursor'

	EXECUTE (@SQL)
END