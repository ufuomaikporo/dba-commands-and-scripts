DECLARE @SQL NVARCHAR(MAX)
DECLARE @DeleteTableList NVARCHAR(MAX)
DECLARE @ExemptList NVARCHAR(MAX)

--*****************************************************************************************************************************

SET @DeleteTableList = 'Corporation
OperatingUnit
PipelineSystem
DischargeSubsystem
Lineloop
StationSeries
MLVSection
MLVCorrection
SeriesConnection
Bend
Area
StateProvince
DistrictDivision'

SET @ExemptList = ''

--*********************************************************************************************************************

SET @ExemptList += CHAR(10) + 'ActionItemProperty
AppList
AppTableListXref
AppTables
CenterpriseSequence
ClusterSettings
Connection
ConnectionType
DEParentChildIdCols
DomainCatalog
DomainCatalogColXRef
ListDomain
RCComputationType
RCHCAReasonType
RiskResultModuleGroup
Role
ServerProfile
SystemPreferences
tmpListDomain_Identity
User
VersionHistory
VersionInfo
VirtualTable
VirtualColumn'

SET @ExemptList = REPLACE(@ExemptList, ' ', '')
SET @ExemptList = REPLACE(@ExemptList, CHAR(10), ' ')
SET @ExemptList = REPLACE(@ExemptList, CHAR(13), '')
SET @ExemptList = REPLACE(@ExemptList, CHAR(9), '')
SET @ExemptList = REPLACE(@ExemptList, ' ', ''', ''')
SET @ExemptList = REPLACE(@ExemptList, ''''', ', '')

SET @ExemptList = '''' + @ExemptList + ''''

SET @DeleteTableList = REPLACE(@DeleteTableList, ' ', '')
SET @DeleteTableList = REPLACE(@DeleteTableList, CHAR(10), ' ')
SET @DeleteTableList = REPLACE(@DeleteTableList, CHAR(13), '')
SET @DeleteTableList = REPLACE(@DeleteTableList, CHAR(9), '')
SET @DeleteTableList = REPLACE(@DeleteTableList, ' ', ''', ''')
SET @DeleteTableList = REPLACE(@DeleteTableList, ''''', ', '')

SET @DeleteTableList = '''' + @DeleteTableList + ''''

---------------------------------- Save the Foreign Key definitions in a table ------------------------

IF OBJECT_ID ('Temp_SavedForeignKeys') IS NOT NULL 
BEGIN
	DROP TABLE Temp_SavedForeignKeys
END


SET @SQL = 'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS Id,
		OBJECT_NAME(fkc.constraint_object_id) AS ForeignKeyName,
		SCHEMA_NAME(t1.schema_id) AS FKTableSchema,
		OBJECT_NAME(fkc.parent_object_id) AS FKTableName,
		COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS FKColumnName,
		SCHEMA_NAME(t2.schema_id) AS ReferencedTableSchema,
		OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable,
		COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
		NULL AS ColumnId
INTO Temp_SavedForeignKeys
FROM sys.foreign_key_columns fkc
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) IN (' + @DeleteTableList + ')' -- Exempted tables

EXECUTE (@SQL)

-------------------------------------- Drop the Foreign Key Definitions ----------------------------------------

SET @SQL = 'DECLARE DropFK_Cursor CURSOR FOR
SELECT ''IF OBJECT_ID ('''''' + ForeignKeyName +'''''', ''''F'''') IS NOT NULL
BEGIN
	ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + '' DROP CONSTRAINT ''
	+ QUOTENAME(ForeignKeyName) + CHAR(10) + '' END''
FROM Temp_SavedForeignKeys'

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

SET @SQL = 'DECLARE TruncateTable_Cursor CURSOR FOR
SELECT ''TRUNCATE TABLE '' + QUOTENAME(name) 
FROM sys.tables
WHERE temporal_type = 0
AND SCHEMA_NAME(schema_id) = ''dbo''
AND name IN (' + @DeleteTableList +')
AND name NOT IN (' + @ExemptList + ')'

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

SET @SQL ='DECLARE CreateFK_Cursor CURSOR FOR
SELECT ''IF OBJECT_ID ('''''' + ForeignKeyName +'''''', ''''F'''') IS NOT NULL
BEGIN'' + CHAR(10) + CHAR(9) +
''ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + CHAR(10) + CHAR(9) +
 ''WITH CHECK ADD CONSTRAINT '' + QUOTENAME(ForeignKeyName) + CHAR(10) + CHAR(9) + ''FOREIGN KEY ('' +
 (SELECT STUFF ( 
					(SELECT '', '' + FKColumnName
					FROM Temp_SavedForeignKeys
					WHERE ForeignKeyName = tab1.ForeignKeyName
					FOR XML PATH(N''''), TYPE
					).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
			   )
 )
 + '')'' + CHAR(10) + CHAR(9) + ''REFERENCES '' + QUOTENAME(ReferencedTableSchema) + ''.'' + QUOTENAME(ReferencedTable) +
 ''('' + (SELECT STUFF (
						(SELECT '', '' + ReferencedColumn
						 FROM Temp_SavedForeignKeys
						 WHERE ForeignKeyName = tab1.ForeignKeyName
						 FOR XML PATH(N''''), TYPE
						).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
					 )
		) + '')'' + CHAR(10) + ''END''
FROM Temp_SavedForeignKeys tab1'

EXECUTE (@SQL)

OPEN CreateFK_Cursor
FETCH NEXT FROM CreateFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE(@SQL)

	FETCH NEXT FROM CreateFK_Cursor INTO @SQL
END

CLOSE CreateFK_Cursor
DEALLOCATE CreateFK_Cursor

