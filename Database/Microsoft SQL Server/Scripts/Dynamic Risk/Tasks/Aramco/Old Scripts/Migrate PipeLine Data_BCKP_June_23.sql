--USE DRAS_IRASv6_DEMO_QA
/*

This script was used to copy line data from the LineLoop table (in the QA demo database) along with corresponding data from dependent tables
into a different database (Aramco stage db)

Steps used to create script
1. find tables with data
2. of that find tables with StationSeries column
3. of those find tables with parent or child relationship with LineLoop

NOTE*** The generated insert statments need to be looked over before running it. Some modifications may need to be made to 
individual statments as needed. Not all INSERT statments mey need to be run
*/

-------------------------------- Disable Foreign Keys ---------------------------

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName VARCHAR(200)
DECLARE @Count INT

---- Disable foreign keys to delete data from tables
--DECLARE DiableFK_Cursor CURSOR FOR
--SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
--		+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
--FROM sys.foreign_key_columns fkc
--JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
--JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
--JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
--WHERE is_disabled = 0

--OPEN DiableFK_Cursor
--FETCH NEXT FROM DiableFK_Cursor INTO @SQL

--WHILE @@FETCH_STATUS = 0
--BEGIN
--	EXECUTE (@SQL)
--	FETCH NEXT FROM DiableFK_Cursor INTO @SQL
--END

--CLOSE DiableFK_Cursor
--DEALLOCATE DiableFK_Cursor


---------------------------------- FILTER our tables that have no data (are empty)

DROP TABLE IF EXISTS ##CandidateTables
CREATE TABLE ##CandidateTables (TableName VARCHAR(100))

DECLARE InsertTab_List CURSOR FOR
SELECT DISTINCT table_name
FROM INFORMATION_SCHEMA.columns c
WHERE column_name LIKE '%StationSeries%' AND OBJECTPROPERTY(OBJECT_ID(table_name), 'IsTable') = 1
AND table_name NOT LIKE 'Risk%' AND table_name NOT LIKE 'Stg%' AND table_name NOT LIKE 'Load[_]%'
AND table_name NOT LIKE 'IRASCustom%' AND table_name NOT LIKE 'Untitled%'


OPEN InsertTab_List
FETCH NEXT FROM InsertTab_List INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @TableName

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Count OUTPUT

	IF @Count <> 0 
	BEGIN
		INSERT INTO ##CandidateTables VALUES (@TableName)
	END

	FETCH NEXT FROM InsertTab_List INTO @TableName
END

CLOSE InsertTab_List
DEALLOCATE InsertTab_List

----------------------- Construct INSERT statements 

DROP TABLE IF EXISTS tmp_ErrorTable
DROP TABLE IF EXISTS ##CandidateTableDetails
CREATE TABLE tmp_ErrorTable (TableName VARCHAR(100))
DECLARE @InsertColumnList VARCHAR(MAX)
DECLARE @SelectColumnList VARCHAR(MAX)
DECLARE @WhereClause VARCHAR(MAX)
DECLARE @MaxLDId INT

SELECT @MaxLDId = MAX(Id) FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.ListDomain

WHILE EXISTS (SELECT DISTINCT OBJECT_NAME(referenced_object_id) TableName 
				FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM ##CandidateTables)
				AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT TableName FROM ##CandidateTables)
				--UNION SELECT name FROM sys.tables WHERE name IN ('ACVGSurvey')
				--AND name NOT IN (SELECT TableName FROM ##CandidateTables)
			)
BEGIN
	INSERT INTO ##CandidateTables
	SELECT DISTINCT OBJECT_NAME(referenced_object_id) TableName 
	FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM ##CandidateTables)
	AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT TableName FROM ##CandidateTables)
	UNION 
	SELECT name FROM sys.tables 
	WHERE name IN ('DomainCatalogColXRef')
	AND name NOT IN (SELECT TableName FROM ##CandidateTables)
	--FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM ##CandidateTables)
	--AND OBJECT_NAME(referenced_object_id) IN ('DomainCatalogColXRef')
END;



WITH CTE AS 
(
	SELECT DISTINCT rt.Id, 
	c.TableName,
	ROW_NUMBER() OVER (PARTITION BY rt.ChildTable ORDER BY rt.ChildTable, rt.Id) rownum
	FROM ##CandidateTables c
	JOIN ##FKRank rt ON rt.ChildTable = c.TableName
)
SELECT Id, TableName 
INTO ##CandidateTableDetails
FROM CTE WHERE rownum = 1


DECLARE @PKList NVARCHAR(MAX)
DECLARE @Id INT
DECLARE @HasStationSeriesInfo VARCHAR(3)
DECLARE @PKWhereClause NVARCHAR(MAX)
DECLARE @LineName NVARCHAR(1000) = ' LIKE ''%12.7%'''
DECLARE @IdOffset VARCHAR(5) = '99990'
DECLARE @LDIdOffset VARCHAR(7) = '99990'--'1023409'
DROP TABLE IF EXISTS ##ResultTable 
CREATE TABLE ##ResultTable (Id INT, TableName VARCHAR(200), HasStationSeriesInfo VARCHAR(3), stmt VARCHAR(MAX))

DECLARE InsertStmt_Cursor CURSOR FOR
SELECT Id, TableName FROM ##CandidateTableDetails
--where TableName = 'ListDomain'
ORDER BY Id


OPEN InsertStmt_Cursor
FETCH NEXT FROM InsertStmt_Cursor INTO @Id, @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY

		SELECT @InsertColumnList = STRING_AGG(column_name, ', ') 
		FROM INFORMATION_SCHEMA.columns inner_col WHERE table_name = @TableName
		AND (column_name NOT LIKE 'LastMod%' AND column_name NOT LIKE 'Create%')

		DROP TABLE IF EXISTS ##SelectColumns

		SELECT CASE
				--WHEN column_name = 'DomainCatalogId' THEN ' CASE WHEN EXISTS (SELECT * FROM DomainCatalog dc1
				--			JOIN DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
				--			WHERE dc2.Id = t2.DomainCatalogId) THEN 
				--			(SELECT dc1.Id FROM DomainCatalog dc1
				--			JOIN DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
				--			WHERE dc2.Id = t2.DomainCatalogId) ELSE ' + column_name + ' + ' + @IdOffset	+ ' END '	
					WHEN column_name = 'DomainCatalogId' 
						THEN ' (SELECT dc1.Id FROM DomainCatalog dc1 JOIN DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
						WHERE dc2.Id = t2.DomainCatalogId) '
					WHEN column_name = 'VirtualTableId'
						THEN ' (SELECT v1.Id FROM VirtualTable v1 JOIN DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.VirtualTable v2 ON v1.VirtualTableName = v2.VirtualTableName
						WHERE v2.Id = t2.VirtualTableId) '
					WHEN column_name LIKE '%Id' AND 
					column_name <> 'SourceId' AND column_name NOT LIKE '%DomainId' 
						THEN column_name + ' + ' + @IdOffset + ' ' + column_name
					WHEN column_name IN (SELECT COL_NAME(parent_object_id, parent_column_id) FROM sys.foreign_key_columns 
									WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain')
					THEN column_name + ' + ' + @LDIdOffset + ' ' + column_name
					ELSE column_name END ColumnName
		INTO ##SelectColumns
		FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND (column_name NOT LIKE 'LastMod%' AND column_name NOT LIKE 'Create%')

		SELECT @SelectColumnList = STRING_AGG(ColumnName, ', ')  FROM ##SelectColumns

		-- Get a list of the primary keys for each table
		SELECT @PKList = STRING_AGG(' t1.' + tab.column_name + ' = '
		 + CASE 
				WHEN tab.column_name = 'VirtualTableId' THEN ' (SELECT v1.Id FROM VirtualTable v1 JOIN  DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.VirtualTable v2 
									ON v1.VirtualTableName = v2.VirtualTableName
									WHERE v2.Id = t2.VirtualTableId) '
				WHEN tab.column_name = 'DomainCatalogId' THEN ' (SELECT dc1.Id FROM DomainCatalog dc1 JOIN DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
						WHERE dc2.Id = t2.DomainCatalogId) '
				WHEN data_type = 'numeric'  THEN ' t2.' + tab.column_name + ' + ' + @IdOffset 
				ELSE ' t2.' + tab.column_name 
				END, ' AND ') 
		FROM sys.indexes i
		JOIN sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
		JOIN INFORMATION_SCHEMA.columns tab
		ON tab.table_name = OBJECT_NAME(ic.object_id)
		AND tab.column_name = COL_NAME(ic.object_id, ic.column_id)
		WHERE is_primary_key = 1
		AND OBJECT_NAME(ic.object_id) = @TableName

		SELECT @WhereClause = STRING_AGG(
		CASE 
		WHEN column_name LIKE '%StationSeries%' THEN column_name + ' = (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.StationSeries 
									WHERE LineLoopId IN (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.LineLoop WHERE LineName LIKE ''%12.7%'')
									)'
		WHEN column_name = 'DischargeSubsystemId' 
				THEN column_name + ' = (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName+ ') '
		WHEN column_name = 'LineLoopId' 
				THEN column_name + ' = (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.LineLoop WHERE LineName ' + @LineName + ') '
		WHEN column_name = 'Stg_ILIId'
			THEN column_name + ' IN (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.Stg_ILI 
					WHERE DischargeSubsystemID = (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName + '))'
		WHEN column_name = 'InlineInspectionId'
			THEN column_name + ' IN (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.InlineInspection WHERE Stg_ILIId IN (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.Stg_ILI        WHERE DischargeSubsystemID = (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName + '))) ' 
		--ELSE '' -- column_name + ' > ' + @IdOffset
		END
		, ' AND ') 
		FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND column_name LIKE '%Id' AND data_type IN ('int', 'numeric') 
		--AND (column_name LIKE '%StationSeries%' OR column_name IN 
		--('PipelineSubsystemId', 'DischargeSubsystemId', 'LIneLoopId', 'Stg_ILIId',
		--'InlineInspectionId', 'ExcavationSiteId'))

		SET @PKWhereClause = 'WHERE NOT EXISTS (SELECT * FROM ' + @TableName + ' t1 WHERE ' + 
		CASE 
		WHEN @PKList IS NOT NULL 
			THEN @PKList
		ELSE ' t1.Id = t2.Id + ' + @IdOffset 
		END + ')'

		IF (OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity')) = 1
		BEGIN
		SELECT @SQL = 'SET IDENTITY_INSERT ' + @TableName + ' ON ' + CHAR(10) + 'INSERT INTO ' + @TableName + ' (' + @InsertColumnList + ')' + CHAR(10) + 
		'SELECT ' + @SelectColumnList + ' FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.' + @TableName + ' t2 '
		+ @PKWhereClause + COALESCE(' AND (' + @WhereClause + ')', '') 
		+ 'SET IDENTITY_INSERT ' + @TableName + ' OFF '
		END
		ELSE
		BEGIN
			SELECT @SQL = 'INSERT INTO ' + @TableName + ' (' + @InsertColumnList + ')' + CHAR(10) + 
			'SELECT ' + @SelectColumnList + ' FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.' + @TableName + ' t2 ' 
			+ @PKWhereClause + COALESCE(' AND ' + @WhereClause + '', '') 
		END

		IF @TableName = 'DomainCatalog'
		BEGIN
			SET @SQL += ' AND DomainDescr NOT IN (SELECT DomainDescr FROM DomainCatalog) '
		END
		IF @TableName = 'VirtualTable'
		BEGIN
			SET @SQL += ' AND VirtualTableName NOT IN (SELECT VirtualTableName FROM VirtualTable) '
		END
		ELSE IF @TableName = 'Corporation'
		BEGIN
			SET @SQL += ' AND Id IN (SELECT CorporationId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.OperatingUnit 
			WHERE Id IN (SELECT OperatingUnitId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.PipelineSystem WHERE Id IN ((SELECT PipelineSystemId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + ')))) '
		END
		ELSE IF @TableName = 'OperatingUnit'
		BEGIN
			SET @SQL += ' AND Id IN (SELECT OperatingUnitId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.PipelineSystem WHERE Id IN ((SELECT PipelineSystemId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + '))) '
		END
		ELSE IF @TableName = 'PipelineSystem'
		BEGIN
			SET @SQL += ' AND Id IN (SELECT PipelineSystemId FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + ') '
		END
		ELSE IF @TableName = 'LineLoop'
		BEGIN
			SET @SQL += ' AND LineName ' + @LineName + ''
		END
		ELSE IF @TableName = 'DischargeSubsystem'
		BEGIN
			SET @SQL += ' AND DischargeSubsystemName ' + @LineName 
		END
		IF @TableName = 'InlineInspection'
		BEGIN
			SET @SQL += ' AND '
			SELECT @SQL += STRING_AGG(column_name + ' IN (SELECT Id FROM DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.ListDomain) ', ' AND ')
			FROM INFORMATION_SCHEMA.columns WHERE table_name = 'InlineInspection'
			AND column_name LIKE '%DomainId%'				
		END

		SELECT @HasStationSeriesInfo = CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND column_name LIKE '%StationSeriesId%') OR @TableName LIKE '%StationSeries%' THEN 'YES' ELSE 'NO' END

		INSERT INTO ##ResultTable 
		SELECT Id, @TableName, @HasStationSeriesInfo, CASE WHEN @HasStationSeriesInfo = 'NO' AND TableName NOT LIKE '%Domain%' 
															AND TableName NOT IN ('Stg_ILI', 'Inlineinspection',
															'MLVSection', 'LineLoop', 'DischargeSubsystem', 
															'PipelineSystem', 'OperatingUnit', 'Corporation')
															THEN '--' + @SQL ELSE @SQL END
		FROM ##CandidateTableDetails cd WHERE cd.TableName = @TableName

		print @sql
	END TRY
	BEGIN CATCH
		INSERT INTO tmp_ErrorTable VALUES (@TableName)
	END CATCH

	FETCH NEXT FROM InsertStmt_Cursor INTO @Id, @TableName
END


CLOSE InsertStmt_Cursor
DEALLOCATE InsertStmt_Cursor

--------------------------- Re-Enable FK

--DECLARE EnableFK_Cursor CURSOR FOR
--SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
--		+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
--FROM sys.foreign_key_columns fkc
--JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
--JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
--JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
--WHERE is_disabled = 1

--OPEN EnableFK_Cursor
--FETCH NEXT FROM EnableFK_Cursor INTO @SQL

--WHILE @@FETCH_STATUS = 0
--BEGIN
--	EXECUTE (@SQL)
--	FETCH NEXT FROM EnableFK_Cursor INTO @SQL
--END

--CLOSE EnableFK_Cursor
--DEALLOCATE EnableFK_Cursor

SELECT * FROM ##ResultTable ORDER BY Id