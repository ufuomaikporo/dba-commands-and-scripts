/*
RUN on CONFIG database
USE CM_IRASv6_CONFIG
*/
--SELECT * FROM DataSourceTable where NAME like 'LD[_]%VT'
DECLARE @SQL NVARCHAR(MAX)
DECLARE @flag INT
DECLARE @ErrorMsg NVARCHAR(MAX)
DECLARE @StageDatabaseName NVARCHAR(100) = 'CM_IRASv6_STAGE'

SELECT DBVersion, DBVersionCheckPoint, DBVersionComment, LastUpgradeDateTime FROM Versioninfo

BEGIN
	IF (SELECT COUNT(*) FROM sys.databases WHERE name = @StageDatabaseName) = 0
	BEGIN
		SET @ErrorMsg = 'Stage database not found. Please enter a correct stage database name before running this script.' + CHAR(10);
		THROW 51001, @ErrorMsg, 1;  
	END
	ELSE IF SUBSTRING(DB_NAME(), 0, CHARINDEX('_IRAS', DB_NAME())) <>  SUBSTRING(@StageDatabaseName, 0, CHARINDEX('_IRAS', @StageDatabaseName)) 
	BEGIN
		SET @ErrorMsg = 'The stage and config database client names do not appear to match' + CHAR(10);
		THROW 51000, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		EXEC sp_set_session_context N'StageDatabaseName', @StageDatabaseName;
	END

	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @StageDatabaseName + '.dbo.SystemPreferences 
				WHERE ParameterName = ''DatabaseType'' AND Value <> ''Stage'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag = 1
	BEGIN
		SET @ErrorMsg = 'The selected stage database appears to be either a link or a config database.' + CHAR(10);
		THROW 51000, @ErrorMsg, 1;   
	END

	IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Config')
	BEGIN
		RAISERROR( 'The target database is not a Config database. This is a Config database upgrade script.', 11, 0)
	END
END

SET @SQL = 'SELECT * FROM ' + @StageDatabaseName + '..Versioninfo'
EXECUTE (@SQL)

------------------------ Check that all necessary virtual tables are created ----------------

SET @SQL = 'SELECT @Result = COUNT(*)
FROM ' + @StageDatabaseName + '..VirtualColumn_BKP vc
JOIN ' + @StageDatabaseName + '..VirtualTable_BKP vt 
	ON vt.Id = REPLACE(vc.VirtualTableId, CHAR(32), '''')
JOIN DataSourceTable dt 
	ON dt.name = REPLACE(vt.VirtualTableName, CHAR(32), '''')
JOIN DataSourceField df 
	ON df.TableId = dt.Id 
	AND df.FieldName = REPLACE(vc.VirtualColumnName, CHAR(32),'''')
LEFT JOIN ' + @StageDatabaseName + '..TempListDomainTable tld
	ON tld.Tablename = REPLACE(vt.VirtualTableName, CHAR(32), '''') 
	AND tld.ColumnName = REPLACE(vc.VirtualColumnName, CHAR(32), '''')
LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
	ON col.table_name = REPLACE(vt.VirtualTableName, CHAR(32), '''') 
	AND col.column_name = REPLACE(vc.VirtualColumnName, CHAR(32), '''')
where tld.ColumnName IS NULL AND vc.VirtualColumnDataTypeInd = ''L''  OR col.column_name IS NULL'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

IF @flag <> 0 
BEGIN
	SET @SQL = 'SELECT vc.Id AS VirtualColumnId, 
		vc.VirtualColumnName,
		vc.VirtualTableId, 
		vt.VirtualTableName, 
		vc.VirtualColumnDatatypeInd,
		vc.VirtualColumnComment
FROM ' + @StageDatabaseName + '..VirtualColumn_BKP vc
JOIN ' + @StageDatabaseName + '..VirtualTable_BKP vt 
	ON vt.Id = REPLACE(vc.VirtualTableId, CHAR(32), '''')
JOIN DataSourceTable dt 
	ON dt.name = REPLACE(vt.VirtualTableName, CHAR(32), '''')
JOIN DataSourceField df 
	ON df.TableId = dt.Id 
	AND df.FieldName = REPLACE(vc.VirtualColumnName, CHAR(32),'''')
LEFT JOIN ' + @StageDatabaseName + '..TempListDomainTable tld
	ON tld.Tablename = REPLACE(vt.VirtualTableName, CHAR(32), '''') 
	AND tld.ColumnName = REPLACE(vc.VirtualColumnName, CHAR(32), '''')
LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
	ON col.table_name = REPLACE(vt.VirtualTableName, CHAR(32), '''') 
	AND col.column_name = REPLACE(vc.VirtualColumnName, CHAR(32), '''')
where tld.ColumnName IS NULL AND vc.VirtualColumnDataTypeInd = ''L'' OR col.column_name IS NULL'

	EXECUTE (@SQL)

	SET @ErrorMsg= 'The Results tab lists virtual tables that were either not created Or cannot be found in the TempListDomainTable' + CHAR(10);
	THROW 51001, @ErrorMsg, 1
END
			

------------- make sure all tables in TempListdomain table exists

SET @SQL = '
SELECT @Result = COUNT(*) FROM (
SELECT * 
FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
ON tld.TableName = col.table_name AND tld.ColumnName = col.column_name
AND tld.TableSchema = col.table_schema
WHERE col.column_name IS NULL AND tld.TableName IS NOT NULL
UNION
SELECT * FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
ON tld.LDTableName = col.table_name AND ''Id'' = col.column_name 
AND tld.LDTableSchema = col.table_schema
WHERE col.column_name IS NULL) tmp'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT


IF @flag <> 0
BEGIN
	SET @SQL = 'SELECT TableSchema, TableName, ColumnName 
				FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
				LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
				ON tld.TableName = col.table_name AND tld.ColumnName = col.column_name
				AND tld.TableSchema = col.table_schema
				WHERE col.column_name IS NULL AND tld.TableName IS NOT NULL
				UNION
				SELECT LDTableSchema, LDTableName, ColumnName
				FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
				LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
				ON tld.LDTableName = col.table_name AND ''Id'' = col.column_name 
				AND tld.LDTableSchema = col.table_schema
				WHERE col.column_name IS NULL';

	PRINT @SQL
	EXECUTE (@SQL);

	THROW 51001, N'The Results tab lists tables from TempListDomainTable that were not created', 1

END

-------Make sure all stage tables listed in config db exist in stage db (should return null)
SET @SQL = 'SELECT @Result = COUNT(*)
	from DataSourceTable dt
	JOIN DataSourceField df ON df.TableId = dt.Id
	LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab 
	ON tab.table_name = dt.name AND tab.column_name = df.FieldName
	WHERE df.FieldName IS NULL'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

IF @flag <> 0
BEGIN
	SET @SQL = 'SELECT df.fieldName ColumnName, dt.name TableName, TableType
	from DataSourceTable dt
	JOIN DataSourceField df ON df.TableId = dt.Id
	LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab 
	ON tab.table_name = dt.name AND tab.column_name = df.FieldName
	WHERE df.FieldName IS NULL';

	PRINT @SQL
	EXECUTE (@SQL);

	THROW 51001, N'The columns and /or tables listed in the Results tab are found in config db but are missing from the stage database', 1

END

----------------- Missing DataRelation table entry (LD tables with no child tables)

SET @SQL = 'SELECT @Result = COUNT(*) FROM 
						(SELECT dtc.name ChildTable, dfc.FieldName ChildField, dtype.name
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dtc 
							ON dtc.Name = tld.TableName
						LEFT JOIN DataSourceField dfc 
							ON dfc.FieldName = tld.ColumnName AND dfc.TableId = dtc.Id
						LEFT JOIN DataType dtype ON dtype.Id = dfc.DataTypeId
						LEFT JOIN DataSourceTable dtp ON dtp.Name = tld.LDTableName
						LEFT JOIN DataSourceField dfp ON dfp.FieldName = ''Id'' AND dfp.TableId = dtp.Id
						LEFT JOIN DataRelation dr ON dr.ParentFieldId = dfp.Id AND dr.ChildFieldId = dfc.Id 
				WHERE dr.ParentFieldId IS NULL AND tld.Tablename is not null
				UNION
				SELECT dtc.name ChildTable, dfc.FieldName ChildField, dtype.Name
FROM DataSourceTable dtc 
RIGHT JOIN DataSourceField dfc 
	ON dfc.TableId = dtc.Id
JOIN DataType dtype ON dtype.Id = dfc.DataTypeId
LEFT JOIN DataRelation dr ON 
dr.ChildFieldId = dfc.Id 
JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
ON col.table_name = dtc.name AND col.column_name = dfc.FieldName
WHERE dr.ChildFieldId is null and dtype.name = ''Lookup''
AND dtc.name NOT LIKE ''IRASCus%'') tmp'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT



IF @flag <> 0
BEGIN
	SET @SQL = 'SELECT dtp.name ParentTable, dfp.FieldName, dtc.name ChildTable, dfc.FieldName ChildField, dtype.name
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dtc 
							ON dtc.Name = tld.TableName
						LEFT JOIN DataSourceField dfc 
							ON dfc.FieldName = tld.ColumnName AND dfc.TableId = dtc.Id
						LEFT JOIN DataType dtype ON dtype.Id = dfc.DataTypeId
						LEFT JOIN DataSourceTable dtp ON dtp.Name = tld.LDTableName
						LEFT JOIN DataSourceField dfp ON dfp.FieldName = ''Id'' AND dfp.TableId = dtp.Id
						LEFT JOIN DataRelation dr ON dr.ParentFieldId = dfp.Id AND dr.ChildFieldId = dfc.Id 
				WHERE dr.ParentFieldId IS NULL AND tld.Tablename is not null
				UNION
				SELECT NULL, NULL, dtc.name ChildTable, dfc.FieldName ChildField, dtype.Name
FROM DataSourceTable dtc 
RIGHT JOIN DataSourceField dfc 
	ON dfc.TableId = dtc.Id
JOIN DataType dtype ON dtype.Id = dfc.DataTypeId
LEFT JOIN DataRelation dr ON 
dr.ChildFieldId = dfc.Id 
JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
ON col.table_name = dtc.name AND col.column_name = dfc.FieldName
WHERE dr.ChildFieldId is null and dtype.name = ''Lookup''
AND dtc.name NOT LIKE ''IRASCus%'''

	PRINT @SQL
	EXECUTE (@SQL);

	THROW 51001, N'There are missing DataRelation table entries listed in the Results tab', 1
END

------------------ Find missing entries in missing DataSourceFieldMetaData 

SET @SQL = 'SELECT @Result = COUNT(*) FROM
(SELECT DISTINCT tld.LDTableSchema, tt.name TableType, dt.name,
tld.LDTableName TableName, ''Id'' ColumnName
FROM ' + @StageDatabaseName + '..TempListDomainTable tld 
JOIN  DatasourceTable dt ON tld.TableName = dt.name 
JOIN DatasourceField df ON dt.Id = df.TableId
AND df.FieldName = tld.ColumnName
JOIN TableType tt ON tt.Id = dt.TableType
LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
WHERE dm.FieldId IS NULL 
UNION 
SELECT DISTINCT tld.LDTableSchema, tt.name TableType, dt.name, tld.LDTableName TableName, ''Id'' ColumnName
FROM ' + @StageDatabaseName + '..TempListDomainTable tld 
JOIN  DatasourceTable dt ON tld.LDTableName = dt.name 
JOIN DatasourceField df ON dt.Id = df.TableId
AND df.FieldName = ''Id''
JOIN TableType tt ON tt.Id = dt.TableType
LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
WHERE dm.FieldId IS NULL) tmp'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

IF @flag <> 0
BEGIN
	SET @SQL = 'SELECT * FROM
		(SELECT DISTINCT tld.LDTableSchema, tt.name TableType, dt.name,
		tld.LDTableName TableName, ''Id'' ColumnName
		FROM ' + @StageDatabaseName + '..TempListDomainTable tld 
		JOIN  DatasourceTable dt ON tld.TableName = dt.name 
		JOIN DatasourceField df ON dt.Id = df.TableId
		AND df.FieldName = tld.ColumnName
		JOIN TableType tt ON tt.Id = dt.TableType
		LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
		WHERE dm.FieldId IS NULL 
		UNION 
		SELECT DISTINCT tld.LDTableSchema, tt.name TableType, dt.name, tld.LDTableName TableName,
		''Id'' ColumnName
		FROM ' + @StageDatabaseName + '..TempListDomainTable tld 
		JOIN  DatasourceTable dt ON tld.LDTableName = dt.name 
		JOIN DatasourceField df ON dt.Id = df.TableId
		AND df.FieldName = ''Id''
		JOIN TableType tt ON tt.Id = dt.TableType
		LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
		WHERE dm.FieldId IS NULL) tmp'

	PRINT @SQL
	EXECUTE (@SQL);

	THROW 51001, N'There are missing DataSourceFieldMetaData table entries listed in the Results tab', 1
END

------------------- find missing entries in DataSourceTableDomainCatalog

SET @SQL = 'SELECT @Result = COUNT(*)
			FROM ' + @StageDatabaseName + '..TempListDomainTable tld
			LEFT JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			LEFT JOIN DataSourceTableDomainCatalog dtdc ON dtdc.DataSourceTableId = dt.Id 
			AND dtdc.DomainCatalog = tld.DomainDescr
			where dtdc.DataSourceTableId IS NULL AND tld.DomainCatalogId IS NOT NULL'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

IF @flag <> 0
BEGIN
	SET @SQL = 'SELECT DISTINCT tld.LDTableName --, tld.TableName, tld.columnName, 
				tld.DomainDescr, tld.DomainCatalogId --, dcxr.DomainCatalogId , dc.DomainDescr
				FROM ' + @StageDatabaseName + '..TempListDomainTable tld
			LEFT JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			LEFT JOIN DataSourceTableDomainCatalog dtdc ON dtdc.DataSourceTableId = dt.Id 
			AND dtdc.DomainCatalog = tld.DomainDescr
			where dtdc.DataSourceTableId IS NULL AND tld.DomainCatalogId IS NOT NULL'

	PRINT @SQL
	EXECUTE (@SQL);

	THROW 51001, N'There are missing DataSourceTableDomainCatalog table entries listed in the Results tab for LD tables with child tables found in DomainCatalogcolXRef table', 1
END


--SET @SQL = 'SELECT @Result = COUNT(*)
--	FROM DataSourceTableDomainCatalog dtc
--	JOIN DataSourceTable dt ON dt.Id = dtc.DataSourceTableId
--	RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld  ON tld.LDTableName = dt.name
--	AND tld.DomainDescr = dtc.DomainCatalog
--	WHERE (dtc.DataSourceTableId IS NULL OR dtc.DomainCatalogSourceId <> tld.DomainCatalogId OR dtc.DomainCatalog <> tld.DomainDescr)
--	AND TableName NOT LIKE ''IRASCust%'' AND tld.LDTableName <> ''LD_DummyTable_VT'''

--EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

--IF @flag <> 0
--BEGIN
--	SET @SQL = 'SELECT DISTINCT dtc.DataSourceTableId AS TableId, dt.Id, tld.LDTableName LDTableName, --, tld.TableName, tld.ColumnName,
--	--dtc.DomainCatalogSourceId, dtc.DomainCatalog, 
--	tld.DomainCatalogId, tld.DomainDescr
--	FROM DataSourceTableDomainCatalog dtc
--	JOIN DataSourceTable dt ON dt.Id = dtc.DataSourceTableId
--	RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld  ON tld.LDTableName = dt.name
--	AND tld.DomainDescr = dtc.DomainCatalog
--	WHERE (dtc.DataSourceTableId IS NULL OR dtc.DomainCatalogSourceId <> tld.DomainCatalogId OR dtc.DomainCatalog <> tld.DomainDescr)
--	AND TableName NOT LIKE ''IRASCust%'' AND tld.LDTableName <> ''LD_DummyTable_VT'''

--	PRINT @SQL
--	EXECUTE (@SQL);

--	THROW 51001, N'There are missing DataSourceTableDomainCatalog table entries listed in the Results tab for LD tables with child tables THAT ARE NOT in the DomainCatalogColXRef table', 1
--END

/*

SELECT DISTINCT dr.ParentFieldId, dr.ChildFieldId, 
dfp.FieldName ParentCol, dfc.FieldName ChildCol, 
	dtp.name parentTable,
	tld.LDTableName, tld.TableName AS ChildTable, tld.ColumnName 
	FROM CM_IRASv6_STAGE_Nov_24.dbo.TempListDomainTable tld 
	LEFT JOIN DataSourceTable dtp ON dtp.name = tld.LDTableName
	LEFT JOIN DataSourceTable dtc ON dtc.name = tld.TableName
	LEFT JOIN DataSourceField dfp ON dfp.FieldName = 'Id'
	AND dfp.TableId = dtp.Id
	LEFT JOIN DataSourceField dfc ON dfc.FieldName = tld.ColumnName
	AND dfc.TableId = dtc.Id
	LEFT JOIN DataRelation dr ON dr.ChildfieldId = dfc.Id
	AND dr.ParentFieldId = dfp.Id
	--ON tld.TableName = dtc.name AND tld.ColumnName = dfc.FieldName
	WHERE  dtc.name = 'Stg_ILIAxialStrain' and dfc.FieldName ='ILIASAnalysisDomainId'
	dr.ParentFieldId IS NULL AND tld.TableName IS NOT NULL

SELECT * FROM DatasourceTable dt JOIN DataSourceField df ON dt.Id = df.TableId
where dt.name = 'Stg_ILIAxialStrain' AND df.FieldName = 'ILIASAnalysisDomainId'

select ILIASAnalysisDomainId from CM_IRASv6_STAGE_Nov_24..Stg_ILIAxialStrain

-- Query to find virtual table columns found in DataSourceField table that do not have entry in DataSourceTableDomainCatalog
SELECT DISTINCT tld.LDTableName LDTableName, 
					dcxr.ColumnName,
				dcxr.TableName, 
				tt.name AS ChildTableType,
				vc.VirtualColumnComment,
				vc.VirtualColumnDataTypeInd,
				dcxr.DomainCatalogId,
				dc.DomainDescr,
				tld.DomainDescr,
				dsdc.DomainCatalogSourceId,
				dsdc.DomainCatalog
				--'SELECT DISTINCT ' + dcxr.ColumnName + ' FROM ' + CASE WHEN tt.name = 'VirtualTable' THEN 'DRAS.' ELSE 'DBO.' END
				--+ dcxr.TableName--DISTINCT dsdc.DataSourceTableId AS TableId, tld.LDTableName TableName, dsdc.DomainCatalogSourceId, dsdc.DomainCatalog, tld.DomainCatalogId, tld.DomainDescr
FROM CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef dcxr
JOIN DataSourceTable dtc ON dtc.name = dcxr.TableName
JOIN DataSourceField dfc ON dfc.FieldName = dcxr.ColumnName
JOIN TableType tt ON tt.Id = dtc.TableType
JOIN CM_IRASv6_STAGE_Nov_24..DomainCatalog_bkp dc ON dc.Id = dcxr.DomainCatalogId
RIGHT JOIN CM_IRASv6_STAGE_Nov_24..TempListDomainTable tld ON tld.TableName = dcxr.tablename
AND tld.ColumnName = dcxr.columnname
LEFT JOIN CM_IRASv6_STAGE_Nov_24.INFORMATION_SCHEMA.columns col 
	ON col.table_name = dcxr.TableName AND col.column_name = dcxr.ColumnName
LEFT JOIN CM_IRASv6_STAGE_Nov_24..VirtualTable vt  ON vt.VirtualTableName = dcxr.TableName
LEFT JOIN CM_IRASv6_STAGE_Nov_24..VirtualColumn vc ON vc.VirtualColumnName = dcxr.ColumnName 
AND vc.VirtualTableId = vt.Id
LEFT JOIN DataSourceTableDomainCatalog dsdc ON dsdc.DataSourceTableId = dcxr.DomainCatalogId
WHERE dsdc.DataSourceTableId IS NULL AND col.column_name IS NOT NULL AND col.table_name IS NOT NULL 
AND (vc.VirtualColumnDataTypeInd IS NULL OR vc.VirtualColumnDataTypeInd = 'L')
AND tt.name = 'VirtualTable' AND vc.Id is null

select * from DataSourceTableDomainCatalog
s
select * from Temp

select * from CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef


-------------------------------------------
return
select DISTINCT dt.name, dtc.DataSourceTableId AS TableId, dtc.DomainCatalogSourceId, dtc.DomainCatalog, tld.DomainCatalogId, tld.DomainDescr
	FROM DataSourceTableDomainCatalog dtc
	JOIN DataSourceTable dt ON dt.Id = dtc.DataSourceTableId
	RIGHT JOIN CM_IRASv6_STAGE_Nov_24.dbo.TempListDomainTable tld  ON tld.LDTableName = dt.name
	AND tld.DomainDescr = dtc.DomainCatalog 
	--RIGHT JOIN CM_IRASv6_STAGE_Nov_24.dbo.DomainCatalog_bkp dc ON dtc.DomainCatalog = dc.DomainDescr
	WHERE dtc.DataSourceTableId IS NOT NULL --tld.DomainDescr IS NOT NULL AND dtc.DomainCatalog IS NULL AND ListDomain
	anD dt.name = 'LD_DscvryDtUpdReason'
	SELECT * from DataSourceTableDomainCatalog

select * from CM_IRASv6_STAGE_Nov_24..TempListDomainTable where LDTableName = 'LD_ACVGAnomalyIndicationType'

use [CM_IRASv6_CONFIG]
	SELECT DISTINCT dt.name, tld.LDTableName, tld.TableName, tld.ColumnName, dtc.*, 'SELECT ' + tld.ColumnName + ' FROM ' + tld.TableSchema + '.' + tld.TableName--DISTINCT dtc.DataSourceTableId AS TableId, tld.LDTableName TableName, dtc.DomainCatalogSourceId, dtc.DomainCatalog, tld.DomainCatalogId, tld.DomainDescr
	FROM DataSourceTableDomainCatalog dtc
	JOIN DataSourceTable dt ON dt.Id = dtc.DataSourceTableId
	RIGHT JOIN CM_IRASv6_STAGE_Nov_24.dbo.TempListDomainTable tld  ON tld.LDTableName = dt.name
	AND tld.DomainDescr = dtc.DomainCatalog
	WHERE (dtc.DataSourceTableId IS NULL OR dtc.DomainCatalogSourceId <> tld.DomainCatalogId OR dtc.DomainCatalog <> tld.DomainDescr)
	--AND tld.TableType <> 'Virtual'
	AND tld.DomainDescr IS NULL
	AND EXISTS (SELECT * FROM CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef dcxr WHERE dcxr.TableName = tld.TableName and dcxr.ColumnName = tld.ColumnName)
	--AND tld.TableName = 'TPDMarkers'


	AND col.TABLE_NAME IS NULL

	select * from DataSourceFieldMetaData

	SELECT * FROM CM_IRASv6_STAGE_Nov_24..versioninfo
	select * from versioninfo

	select * from DataSourceTableDomainCatalog

SELECT tld.TableName, tld.ColumnName, LDTableName, tld.DomainCatalogId, dcxr.DomainCatalogId, dc.DomainDescr 
FROM CM_IRASv6_STAGE_Nov_24.dbo.TempListDomainTable tld
JOIN CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef dcxr 
ON dcxr.TableName = tld.TableName AND dcxr.ColumnName = tld.ColumnName
JOIN CM_IRASv6_STAGE_Nov_24..DomainCatalog_bkp dc ON dc.Id = dcxr.DomainCatalogId
WHERE tld.TableName = 'TPDMarkers' --tld.DomainDescr IS NULL

SELECT * FROM CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef  WHERE TableName = 'TPDMarkers'

USE CM_IRASv6_STAGE_Nov_24

SELECT OBJECT_NAME(fkc.constraint_object_id) AS fk_constraint,
	   SCHEMA_NAME(t1.schema_id) AS fk_table_schema,
	   OBJECT_NAME(fkc.parent_object_id) AS fk_table,
	   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column,
	   SCHEMA_NAME(t2.schema_id) AS referenced_table_schema,
	   OBJECT_NAME(fkc.referenced_object_id) AS referenced_table,
	   COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column,
	   kcu.ordinal_position
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.parent_object_id) like '%DataSource%'
ORDER BY 1


LD_AXAvailableAnalysisType	Stg_ILIAxialStrain	ILIASAnalysisDomainId
LD_BendStrainType	Stg_ILIBendStrain	ILIBSTypeDomainId
LD_CoordinateSystem	CoverDepthProfile	CoordSysDomainId
use [CM_IRASv6_STAGE_Nov_24]
select ILIBSTypeDomainId from Stg_ILIBendStrain
select CoordSysDomainId from CoverDepthProfile
select ILIASAnalysisDomainId from Stg_ILIAxialStrain
select * from TempListDomainTable where Tablename = 'Stg_ILIBendStrain'

SELECT * FROM
		(SELECT dm.*, --DISTINCT tld.LDTableSchema, tt.name TableType, dt.name,
		tld.LDTableName TableName, 'Id' ColumnName
		FROM CM_IRASv6_STAGE_Nov_24..TempListDomainTable tld 
		JOIN  DatasourceTable dt ON tld.TableName = dt.name 
		JOIN DatasourceField df ON dt.Id = df.TableId
		AND df.FieldName = tld.ColumnName
		JOIN TableType tt ON tt.Id = dt.TableType
		LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
		WHERE dm.FieldId IS NULL 
		UNION 
		SELECT DISTINCT dt.name, tt.name TableType, df.FieldName, dm.FieldId
		FROM CM_IRASv6_STAGE_Nov_24..TempListDomainTable tld 
		JOIN  DatasourceTable dt ON tld.LDTableName = dt.name 
		JOIN DatasourceField df ON dt.Id = df.TableId
		AND df.FieldName = 'Id'
		JOIN TableType tt ON tt.Id = dt.TableType
		LEFT JOIN DataSourceFieldMetaData dm ON dm.FieldId = df.Id
		WHERE dt.name like '%Dummy%' dm.FieldId IS NULL) tmp


SELECT DISTINCT tld.LDTableName, tld.TableName, tld.columnName, 
			tld.DomainDescr, tld.DomainCatalogId, dcxr.DomainCatalogId , dc.DomainDescr
			FROM CM_IRASv6_STAGE_Nov_24..TempListDomainTable tld
			LEFT JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			LEFT JOIN DataSourceTableDomainCatalog dtdc ON dtdc.DataSourceTableId = dt.Id 
			LEFT JOIN CM_IRASv6_STAGE_Nov_24..DomainCatalogColXRef dcxr 
			ON dcxr.TableName = tld.TableName AND dcxr.ColumnName = tld.ColumnName
			LEFT JOIN CM_IRASv6_STAGE_Nov_24..DomainCatalog_bkp dc ON dc.Id = dcxr.DomainCatalogId
			where dtdc.DataSourceTableId IS NULL AND dcxr.DomainCatalogId IS NOT NULL 

	SELECT DISTINCT dt.Id, tld.LDTableName, tld.TableName, tld.Columnname, tld.DomainDescr, tld.DomainCatalogId
			FROM CM_IRASv6_STAGE_Nov_24..TempListDomainTable tld
			JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			LEFT JOIN DataSourceTableDomainCatalog dtdc ON dtdc.DataSourceTableId = dt.Id 
			WHERE NOT EXISTS (SELECT * FROM DataSourceTableDomainCatalog dtdc2 WHERE dtdc.DataSourceTableId = dtdc2.DataSourceTableId
								AND dtdc.DomainCatalog = dtdc2.DomainCatalog)
			AND tld.DomainDescr IS NOT NULL

*/