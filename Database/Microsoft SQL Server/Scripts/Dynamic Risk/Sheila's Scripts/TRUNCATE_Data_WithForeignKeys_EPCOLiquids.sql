/*
 This script deletes data from all tables in the database where it is executed if no tables are specifed in
 the @DeleteList variable. Some tables are automatically exempt from data deletion. But if you would like to 
 add more tables to the exempt list use the @ExemptList variable to specify these tables.

 This can be used to cleanup the STAGE and LINK databases (including GUID cleanup)
*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @DeleteList NVARCHAR(MAX)
DECLARE @ExemptList NVARCHAR(MAX)
DECLARE @DropSavedFKTable NVARCHAR(1)

--*****************************************************************************************************************************

/*
List of tables whose data will be deleted (cariage return delimited list). If no tables are listed then the data in 
all tables (except tables listed in @ExemptList) will be deleted
*/
SET @DeleteList = 'Bend
Casing
Coating
Crossing
CrossingLocn
Fabrication
HydroTest
HydroTestRange
Incident
InlineInspection
InlineInspectionFeature
InlineInspectionRange
JointCoating
LandUse
MAOP
MOP
OperatingData
PipeSegment
ProductComponent
Tap
Valve
Vt_AddHierarchy_AssessmentId
Vt_AddHierarchy_LineName
Vt_AddHierarchy_LineNumber
Vt_AddHierarchy_PODSID
Vt_CommerciallyNavigableWaterway
Vt_CouponCorrRate
Vt_CTCouplingPresence
Vt_CTPressureCycle
Vt_ECSMECoatEvaluation
Vt_HighPopulationArea
Vt_ICCleanPigProgram
Vt_InternalCoatingSME
Vt_MPressureCycling
Vt_NonClassifiedAreas
Vt_OFFaultLine
Vt_OFFrostDepth
Vt_OFSeismicArea
Vt_OFUnstableSlope
Vt_ONValveTime
Vt_OtherPopulationArea
Vt_PipeLineLocation
Vt_SCCNNSCCHistoryScore
Vt_SCCPs
Vt_TPDMarkers
Vt_TPDPatrolFrequency
Vt_TPDPublicAwareness
Vt_UnusuallySensitiveAreas
VirtualTableStationing
VirtualTableDataNum
VirtualTableDataString
VirtualTableDataFlg
VirtualTableDataInd
VirtualTableDataListDomain
VirtualTableDataDate'

-- List of tables that are exempt from data deletion (cariage return delimited list)
SET @ExemptList = 'Corporation
OperatingUnit
PipelineSystem
DischargeSubsystem
LineLoop
StationSeries
MLVSection
MLVCorrection
SeriesConnection'

-- Drop the table that stores foreign key definitions. This should be set to 'Y' if it is the first time running this script on this database
SET @DropSavedFKTable = 'N'

--*********************************************************************************************************************

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
Temp_SavedForeignKeys
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

IF OBJECT_ID ('tempdb..##DeleteListTable', 'U') IS NOT NULL
BEGIN
	DROP TABLE ##DeleteListTable
END

CREATE TABLE ##DeleteListTable (TableName NVARCHAR(100))

IF @DeleteList = '' OR @DeleteList IS NULL
BEGIN
	SET @DeleteList = NULL
	SET @SQL = 'DECLARE @Result TABLE (TableName NVARCHAR(100)) 
	SELECT name
	FROM sys.tables
	WHERE name NOT IN (' + @ExemptList + ')'

	INSERT INTO ##DeleteListTable
	EXECUTE (@SQL)
END
ELSE
BEGIN
	SET @DeleteList = REPLACE(@DeleteList, ' ', '')
	SET @DeleteList = REPLACE(@DeleteList, CHAR(10), ' ')
	SET @DeleteList = REPLACE(@DeleteList, CHAR(13), '')
	SET @DeleteList = REPLACE(@DeleteList, CHAR(9), '')
	SET @DeleteList = REPLACE(@DeleteList, ' ', ''', ''')
	SET @DeleteList = REPLACE(@DeleteList, ''''', ', '')

	SET @DeleteList = '''' + @DeleteList + ''''

	SET @SQL = 'DECLARE @Result TABLE (TableName NVARCHAR(100)) 
	INSERT INTO @Result
	SELECT name FROM sys.tables 
	WHERE name IN (' + @DeleteList + ')
	AND name NOT IN (' + @ExemptList + ')
	
	SELECT * FROM @Result'

	INSERT INTO ##DeleteListTable
	EXECUTE (@SQL)
END

---------------------------------- Save the Foreign Key definitions in a table ------------------------

-- Drop the Table for saving foreign key definitions if it has fewer or same number of foreign key entries as exist in database
IF OBJECT_ID ('Temp_SavedForeignKeys', 'U') IS NOT NULL
BEGIN
	
	SET @SQL = 'IF  (SELECT COUNT(*) FROM Temp_SavedForeignKeys) <= (SELECT COUNT(*) FROM sys.foreign_keys) OR (''' + @DropSavedFKTable + ''' = ''Y'')
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
	WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT TableName FROM ##DeleteListTable)' -- Exempted tables

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

		EXECUTE (@SQL)

END

-------------------------------------- Drop the Foreign Key Definitions ----------------------------------------

SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)
DECLARE DropFK_Cursor CURSOR FOR
SELECT ''ALTER TABLE '' + QUOTENAME(FKTableSchema) + ''.'' + QUOTENAME(FKTableName) + '' DROP CONSTRAINT ''
	+ QUOTENAME(ForeignKeyName) + CHAR(10) 
FROM Temp_SavedForeignKeys tmp
WHERE EXISTS (SELECT * FROM sys.foreign_keys WHERE name = tmp.ForeignKeyName)

EXECUTE (@SQL)

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

DECLARE TruncateTable_Cursor CURSOR FOR
SELECT 'TRUNCATE TABLE ' + QUOTENAME(name) 
FROM sys.tables t
JOIN ##DeleteListTable dt ON t.name = dt.TableName
WHERE temporal_type = 0
AND SCHEMA_NAME(schema_id) = 'dbo'

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
SELECT DISTINCT CreateFK FROM Temp_SavedForeignKeys'


EXECUTE (@SQL)

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

