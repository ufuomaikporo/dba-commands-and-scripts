/*
 This script deletes data from all tables in the database where it is executed if no tables are specifed in
 the @TruncateList variable. Some tables are automatically exempt from data deletion. But if you would like to 
 add more tables to the exempt list use the @ExemptList variable to specify these tables.

 This can be used to cleanup the STAGE and LINK databases (including GUID cleanup)
*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TruncateList NVARCHAR(MAX)
DECLARE @ExemptList NVARCHAR(MAX)
DECLARE @DropSavedFKDefinitions NVARCHAR(1)
DECLARE @RecursionRootTables NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)

--*****************************************************************************************************************************

/*
List of tables whose data will be truncated. This is a carriage return delimited list (ENTER key). 
Any child tables descended from the listed tables will also be truncated using existing foreign key 
relationships. Use the @ExemptList variable to specicy tables that should be exempt from data deletion.

NOTE**: If no tables are specified in @TruncateList variable then all tables will be truncated
*/
SET @TruncateList = NULL

-- List of tables that are exempt from data deletion (cariage return delimited list)
SET @ExemptList = ''

-- Drop the table created by this script to store foreign key definitions. Set to 'Y' to drop the table
SET @DropSavedFKDefinitions = 'N'

--*********************************************************************************************************************

IF @TruncateList IS NULL OR LTRIM(RTRIM(@TruncateList)) = ''
BEGIN
	SET @TruncateList = NULL
	SELECT @TruncateList = COALESCE(@TruncateList + CHAR(10), '') + table_name FROM INFORMATION_SCHEMA.tables 
	WHERE table_name LIKE 'Extract[_]%'
	OR table_name LIKE 'LD[_]%'
	OR table_name IN ('DomainCatalog', 'ListDomain', 'DomainCatalogColXRef', 'VirtualTable', 'VirtualColumn')
END

/*
List of tables that cause the recursion query to go over the maximum recursion limit. These tables
should be inlcuded in the root and not the recursive portion of the recursive CTE 
*/
SET @RecursionRootTables = 'InlineInspection
Classification'

IF @ExemptList <> '' 
BEGIN
	SET @ExemptList += CHAR(10)
END
ELSE
BEGIN
	SET @ExemptList = ''
END

-- The following tables will automatically be added to the exempt list
SET @ExemptList += 'ActionItemProperty
AppList
AppTableListXref
AppTables
CenterpriseSequence
ClusterSettings
Connection
ConnectionType
DEParentChildIdCols
RCComputationType
RCHCAReasonType
RiskResultModuleGroup
Role
ServerProfile
SystemPreferences
Temp_SavedForeignKeyDefinitions
User
VersionHistory
VersionInfo
GUIDLookup
ILIGUIDLookup
VTGUIDLookup
'

SET @ExemptList = REPLACE(@ExemptList, ' ', '')
SET @ExemptList = REPLACE(@ExemptList, CHAR(10), ' ')
SET @ExemptList = REPLACE(@ExemptList, CHAR(13), '')
SET @ExemptList = REPLACE(@ExemptList, CHAR(9), '')
SET @ExemptList = REPLACE(@ExemptList, ' ', ''', ''')
SET @ExemptList = REPLACE(@ExemptList, ''''', ', '')

SET @ExemptList = '''' + @ExemptList + ''''

IF OBJECT_ID('tempdb..##ProblemTables') IS NOT NULL
BEGIN
	DROP TABLE ##ProblemTables
END

CREATE TABLE ##ProblemTables (TableName NVARCHAR(100))

SET @RecursionRootTables = REPLACE(@RecursionRootTables, ' ', '')
SET @RecursionRootTables = REPLACE(@RecursionRootTables, CHAR(10), ' ')
SET @RecursionRootTables = REPLACE(@RecursionRootTables, CHAR(13), '')
SET @RecursionRootTables = REPLACE(@RecursionRootTables, CHAR(9), '')
SET @RecursionRootTables = REPLACE(@RecursionRootTables, ' ', '''), ' + CHAR(10) + '(''') 

-- Store tables that will cause issues for the recursive query in a table
SET @SQL = 'INSERT INTO ##ProblemTables VALUES(''' + @RecursionRootTables + ''')'
EXECUTE(@SQL)

IF OBJECT_ID ('tempdb..##TruncateTableList', 'U') IS NOT NULL
BEGIN
	DROP TABLE ##TruncateTableList
END

-- Table to store list of tables whose data will be truncated
CREATE TABLE ##TruncateTableList (TableName NVARCHAR(100))

IF @TruncateList = '' OR @TruncateList IS NULL
BEGIN
	SET @TruncateList = NULL
	SET @SQL = 'DECLARE @Result TABLE (TableName NVARCHAR(100)) 
	SELECT name
	FROM sys.tables
	WHERE name NOT IN (' + @ExemptList + ')'

	INSERT INTO ##TruncateTableList
	EXECUTE (@SQL)

END
ELSE
BEGIN
	SET @TruncateList = REPLACE(@TruncateList, ' ', '')
	SET @TruncateList = REPLACE(@TruncateList, CHAR(10), ' ')
	SET @TruncateList = REPLACE(@TruncateList, CHAR(13), '')
	SET @TruncateList = REPLACE(@TruncateList, CHAR(9), '')
	SET @TruncateList = REPLACE(@TruncateList, ' ', ''', ''')
	SET @TruncateList = REPLACE(@TruncateList, ''''', ', '')

	SET @TruncateList = '''' + @TruncateList + ''''

	SET @SQL = 'DECLARE @Result TABLE (TableName NVARCHAR(100)) 
	INSERT INTO @Result
	SELECT DISTINCT OBJECT_NAME(parent_object_id) FKTable
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_Id) IN (SELECT name FROM sys.tables 
												WHERE name IN (' + @TruncateList + ')
												AND name NOT IN (' + @ExemptList + ')
												)
	UNION
	SELECT name FROM sys.tables 
	WHERE name IN (SELECT name FROM sys.tables 
				   WHERE name IN (' + @TruncateList + ')
				   AND name NOT IN (' + @ExemptList + ')
											)
	
	SELECT * FROM @Result'

	-- Store list of tables that need to be truncated and their direct dependent child tables in ##TruncateTableList table
	INSERT INTO ##TruncateTableList
	EXECUTE (@SQL)


	-- Add tables that will cause problems for the recursive query to ##TruncateTableList table so they can be part of the root Tables for the recursion
	SET @SQL = 'INSERT INTO ##TruncateTableList 
				SELECT name FROM sys.tables tab
				WHERE name IN (SELECT TableName FROM ##ProblemTables)
				AND EXISTS (SELECT * FROM sys.foreign_key_columns fkc
							WHERE OBJECT_NAME(referenced_object_id) IN (SELECT * FROM ##TruncateTableList)
							AND fkc.parent_object_id = tab.object_id)
				AND NOT EXISTS (SELECT * FROM ##TruncateTableList del
								WHERE tab.name = del.TableName)'

	EXECUTE(@SQL)

---------------------------- Find All Child Tables --------------------------------------

	-- Loop through foreign key hierarchy of all tables in ##TruncateTableList and add all child tables to the delete list
	DECLARE TableList CURSOR FAST_FORWARD FOR
	SELECT TableName FROM ##TruncateTableList

	--delete from ##ProblemTables

	OPEN TableList
	FETCH NEXT FROM TableList INTO @TableName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		WITH ForeignKeyCTE
		AS (
			--Anchor. Get the root(s) for the recursive
			SELECT  1 AS Level, 
					OBJECT_NAME(referenced_object_Id) ReferencedTable, 
					OBJECT_NAME(parent_object_id) FKTable
			FROM 
			sys.foreign_key_columns 
			WHERE OBJECT_NAME(referenced_object_Id) = @TableName 
			UNION ALL
			--Recursive. Get the direct descendants at each level
			SELECT  m.level + 1, OBJECT_NAME(t.referenced_object_Id), OBJECT_NAME(t.parent_object_id)
			FROM sys.foreign_key_columns t 
				INNER JOIN ForeignKeyCTE m on m.FKTable = OBJECT_NAME(t.referenced_object_Id)
			WHERE FKTable NOT IN (SELECT * FROM ##ProblemTables) -- Excludes problem tables from recursive section
		)
		INSERT INTO ##TruncateTableList
		SELECT DISTINCT FKTable
		FROM ForeignKeyCTE t
		WHERE NOT EXISTS (SELECT * FROM ##TruncateTableList d 
							WHERE d.TableName = t.FKTable)

		FETCH NEXT FROM TableList INTO @TableName
	END 

	CLOSE TableList
	DEALLOCATE TableList
END


---------------------------------- Save the Foreign Key definitions in a table ------------------------

/* 
Drop the table that saves foreign key definitions if one or both of the following are true
1. it has fewer or the same number of foreign keys as currently exists within the database 
2. The @DropSavedFKDefinitions variable if set to 'Y'
*/
IF OBJECT_ID ('Temp_SavedForeignKeyDefinitions', 'U') IS NOT NULL
BEGIN
	
	SET @SQL = 'IF  (SELECT COUNT(*) FROM Temp_SavedForeignKeyDefinitions) <= (SELECT COUNT(*) FROM sys.foreign_keys) OR (''' + @DropSavedFKDefinitions + ''' = ''Y'')
	BEGIN
		DROP TABLE Temp_SavedForeignKeyDefinitions
	END'

	EXECUTE (@SQL)
END

IF OBJECT_ID ('Temp_SavedForeignKeyDefinitions', 'U') IS NULL
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
	INTO Temp_SavedForeignKeyDefinitions
	FROM sys.foreign_key_columns fkc
	JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
		ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
		AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id' 

	EXECUTE (@SQL)

	-- Construct command to recreate foreign keys
	SET @SQL = 'UPDATE Temp_SavedForeignKeyDefinitions
	SET CreateFK = (''IF OBJECT_ID ('''''' + ForeignKeyName +'''''', ''''F'''') IS NULL
			BEGIN'' + CHAR(10) + CHAR(9) +
			''ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + CHAR(10) + CHAR(9) +
			 ''WITH CHECK ADD CONSTRAINT '' + QUOTENAME(ForeignKeyName) + CHAR(10) + CHAR(9) + ''FOREIGN KEY ('' +
			 (SELECT STUFF ( 
								(SELECT '', '' + FKColumnName
								FROM Temp_SavedForeignKeyDefinitions
								WHERE ForeignKeyName = tab1.ForeignKeyName
								ORDER BY ordinal_position
								FOR XML PATH(N''''), TYPE
								).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
						   )
			 )
			 + '')'' + CHAR(10) + CHAR(9) + ''REFERENCES '' + QUOTENAME(ReferencedTableSchema) + ''.'' + QUOTENAME(ReferencedTable) +
			 ''('' + (SELECT STUFF (
									(SELECT '', '' + ReferencedColumn
									 FROM Temp_SavedForeignKeyDefinitions
									 WHERE ForeignKeyName = tab1.ForeignKeyName
									 ORDER BY ordinal_position
									 FOR XML PATH(N''''), TYPE
									).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
								 )
					) + '')'' + CHAR(10) + ''END'')
		FROM Temp_SavedForeignKeyDefinitions tab1'

		EXECUTE (@SQL)

END

-------------------------------------- Drop the Foreign Key Definitions ----------------------------------------

SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)
DECLARE DropFK_Cursor CURSOR FOR
SELECT DISTINCT ''ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + '' DROP CONSTRAINT ''
	+ QUOTENAME(ForeignKeyName) + CHAR(10)  
FROM Temp_SavedForeignKeyDefinitions tmp
WHERE EXISTS (SELECT name FROM sys.foreign_keys WHERE name = tmp.ForeignKeyName)'

EXECUTE (@SQL)

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN	
	EXECUTE (@SQL)
	FETCH NEXT FROM DropFK_Cursor INTO @SQL
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

------------------------------------ TRUNCATE TABLES -------------------------------------------------------

-- Truncate tables in delete list plus any child tables associated with them
SET @SQL = 'DECLARE TruncateTable_Cursor CURSOR FOR
SELECT ''TRUNCATE TABLE '' + SchemaName + ''.'' + TableName AS Cmd
FROM (
SELECT SCHEMA_NAME(schema_id) SchemaName, name AS TableName
FROM sys.tables t
JOIN ##TruncateTableList dt ON t.name = dt.TableName
WHERE temporal_type = 0
AND name NOT IN (SELECT name FROM sys.tables WHERE name IN (' + @ExemptList + '))
UNION 
SELECT FKTableSchema, FKTableName
FROM Temp_SavedForeignKeyDefinitions
WHERE ReferencedTable IN (SELECT TableName FROM ##TruncateTableList)
AND FKTableName NOT IN (SELECT name FROM sys.tables WHERE name IN (' + @ExemptList + '))
) tmp
'
EXECUTE (@SQL)

OPEN TruncateTable_Cursor
FETCH NEXT FROM TruncateTable_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM TruncateTable_Cursor INTO @SQL
END

CLOSE TruncateTable_Cursor
DEALLOCATE TruncateTable_Cursor

------------------------------------- RECREATE Foreign Keys ---------------------------------------

DECLARE CreateFK_Cursor CURSOR FOR
SELECT DISTINCT CreateFK FROM Temp_SavedForeignKeyDefinitions

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
DEALLOCATE CreateFK_Cursor

-- Deletes table that stores foreign key definitions
IF (@DropSavedFKDefinitions = 'Y')
BEGIN
	DROP TABLE Temp_SavedForeignKeyDefinitions
END

SELECT TableName AS 'Truncated Tables'  
FROM ##TruncateTableList
ORDER BY 1

/*

*/