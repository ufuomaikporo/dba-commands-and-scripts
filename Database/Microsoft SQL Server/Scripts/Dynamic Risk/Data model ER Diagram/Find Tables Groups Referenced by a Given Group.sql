DECLARE @List NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @SourceDB NVARCHAR(100) = 'TestUnifiedModel6'
DECLARE @SchemaName NVARCHAR(100) = 'Unified'
DECLARE @TableName NVARCHAR(100) = 'Virtual_Tables'
DECLARE @GroupName NVARCHAR(MAX)
DECLARE @FindType NVARCHAR(100) = 'child'


SET @GroupName = 'ComplainceAuditor_Tables
Configuration_Tables
DataExchange_Tables
DataManager_Tables
Event_Tables
Hierarchy_Tables
History_Tables
ILI_Tables
IRASCustom_Tables
Lookup_Tables
OutsideForces_Tables
POE_Tables
Risk_Tables
Spatial_Tables
Staging_Tables
TableChecker_Tables
Virtual_Tables'

IF @FindType = 'parent'
BEGIN
	SET @FindType = 'parent_object_id'
END
ELSE
BEGIN
	SET @FindType = 'referenced_object_id'
END

DROP TABLE IF EXISTS ##TableList

CREATE TABLE ##TableList (name NVARCHAR(100))

SET @SQL = REPLACE(@GroupName, ' ', '')
SET @SQL = REPLACE(@SQL, CHAR(10), ' ')
SET @SQL = REPLACE(@SQL, CHAR(13), '')
SET @SQL = REPLACE(@SQL, CHAR(9), '')
SET @SQL = REPLACE(@SQL, ' ', ''')' + CHAR(10) + 'INSERT INTO ##TableList VALUES(''')
SET @SQL = 'INSERT INTO ##TableList VALUES(''' + @SQL + ''')'

EXECUTE (@SQL)


--ERDiagram_CenterlineTables
--ERDiagram_ComplianceAuditorTables
--ERDiagram_ConfiguratonTables
--ERDiagram_DataExchangeTables
--ERDiagram_DataManagerTables
--ERDiagram_EventTables
--ERDiagram_ILITables
--ERDiagram_IRASCustomTables
--ERDiagram_LookupTables
--ERDiagram_OutsideForceTables
--ERDiagram_POETables
--ERDiagram_RiskTables
--ERDiagram_StagingTables
--ERDiagram_TableCheckerTables
--ERDiagram_VirtualTables

--SET @List = 'DomainCatalog
--DomainCatalogColXRef
--ListDomain'

--SET @List = REPLACE(@List, ' ', '')
--SET @List = REPLACE(@List, CHAR(10), ' ')
--SET @List = REPLACE(@List, CHAR(13), '')
--SET @List = REPLACE(@List, CHAR(9), '')
--SET @List = REPLACE(@List, ' ', ''', ''')
--SET @List = REPLACE(@List, ''''', ', '')

--SET @List = '''' + @List + ''''



--SET @SQL = 'INSERT INTO '+ @TableName+'
--SELECT name FROM sys.tables WHERE name IN (' + @List + ')'

--print @sql

--return

SELECT @SQL = STRING_AGG('WHEN EXISTS (SELECT * FROM DrasInternal.INFORMATION_SCHEMA.columns WHERE table_schema = ''' + @SchemaName + ''' AND table_name = ''' + name + ''' AND column_name =  fk_table) THEN ''' + name + '''', CHAR(10))
FROM ##TableList

SET @SQL = 'USE ' + @SourceDB + '
SELECT fk_table,
		CASE' + CHAR(10) + @SQL

SET @SQL = @SQL + CHAR(10) + 'END AS TableGroup
INTO ##ChildTables
FROM (
SELECT --OBJECT_NAME(fkc.constraint_object_id) AS fk_constraint,
	   SCHEMA_NAME(t1.schema_id) AS fk_table_schema,
	   OBJECT_NAME(fkc.parent_object_id) AS fk_table
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.'+ @FindType +') IN (SELECT column_name FROM DrasInternal.INFORMATION_SCHEMA.columns
WHERE table_schema = ''' + @SchemaName + ''' AND table_name = ''' + @TableName + ''')
) subq'


DROP TABLE IF EXISTS ##ChildTables
EXECUTE (@SQL)

SELECT DISTINCT TableGroup FROM ##ChildTables where TableGroup is NOT null
AND TableGroup <> @TableName ORDER BY 1

return

SET @SQL = '
USE ' + @SourceDB + '
SELECT fk_table,
		CASE
			WHEN EXISTS (SELECT * FROM DrasInternal.ERDiagram_CenterlineTables WHERE TableName = fk_table) THEN ''CenterLineTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.ERDiagram_ComplianceAuditorTables WHERE TableName = fk_table) THEN ''ComplianceAuditorTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.ERDiagram_ConfiguratonTables WHERE TableName = fk_table) THEN ''ConfiguratonTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.ERDiagram_DataExchangeTables WHERE TableName = fk_table) THEN ''DataExchangeTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_DataManagerTables WHERE TableName = fk_table) THEN ''DataManagerTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_EventTables WHERE TableName = fk_table) THEN ''EventTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_ILITables WHERE TableName = fk_table) THEN ''ILITables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_IRASCustomTables WHERE TableName = fk_table) THEN ''IRASCustomTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_LookupTables WHERE TableName = fk_table) THEN ''LookupTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_OutsideForceTables WHERE TableName = fk_table) THEN ''OutsideForceTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_POETables WHERE TableName = fk_table) THEN ''POETables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_RiskTables WHERE TableName = fk_table) THEN ''RiskTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_StagingTables WHERE TableName = fk_table) THEN ''StagingTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_TableCheckerTables WHERE TableName = fk_table) THEN ''TableCheckerTables''
			WHEN EXISTS (SELECT * FROM DrasInternal.dbo.ERDiagram_VirtualTables WHERE TableName = fk_table) THEN ''VirtualTables''
		END AS TableGroup
FROM (
SELECT --OBJECT_NAME(fkc.constraint_object_id) AS fk_constraint,
	   SCHEMA_NAME(t1.schema_id) AS fk_table_schema,
	   OBJECT_NAME(fkc.parent_object_id) AS fk_table
	   --COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column,
	   --SCHEMA_NAME(t2.schema_id) AS referenced_table_schema,
	   --OBJECT_NAME(fkc.referenced_object_id) AS referenced_table,
	   --COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column,
	   --kcu.ordinal_position
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT TableName 
FROM DrasInternal.dbo.' + @TableName +')
) subq'


DROP TABLE IF EXISTS ##ERDiagramGroup

CREATE TABLE ##ERDiagramGroup (TableName VARCHAR(100), GroupName VARCHAR(100))

INSERT INTO ##ERDiagramGroup
EXECUTE (@SQL)

select DISTINCT GroupName FROM ##ERDiagramGroup
SELECT * FROM ##ERDiagramGroup


