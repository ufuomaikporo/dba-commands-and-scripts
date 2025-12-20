--USE DRAS_IRASv6_DEMO_QA
/*

This script was used to copy line data from the LineLoop table (in the QA demo database) along with corresponding data from dependent tables
into a different database (Aramco stage db)



NOTE*** The generated insert statments need to be looked over before beign used. Some modifications may need to be made to 
individual INSERT statments before execution. Not all INSERT statments may need to be executed, and some have been commented
out for this reason
*/

-------------------------------- Disable Foreign Keys ---------------------------

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName VARCHAR(200)
DECLARE @Count INT
DECLARE @InsertColumnList VARCHAR(MAX)
DECLARE @SelectColumnList VARCHAR(MAX)
DECLARE @WhereClause VARCHAR(MAX)
DECLARE @MaxLDId INT
DECLARE @SourceServer VARCHAR(200)
DECLARE @SourceDatabase VARCHAR(200)
DECLARE @PKList NVARCHAR(MAX)
DECLARE @Id INT
DECLARE @HasStationSeriesInfo VARCHAR(3)
DECLARE @PKWhereClause NVARCHAR(MAX)
DECLARE @LineName NVARCHAR(1000) 
DECLARE @IdOffset VARCHAR(5) 
DECLARE @LDIdOffset VARCHAR(7) 

DROP TABLE IF EXISTS tmp_ErrorTable
DROP TABLE IF EXISTS tmp_CandidateTableDetails
DROP TABLE IF EXISTS tmp_CandidateTables
DROP TABLE IF EXISTS tmp_ResultTable 

CREATE TABLE tmp_ErrorTable (TableName VARCHAR(100))
CREATE TABLE tmp_CandidateTables (TableName VARCHAR(100))
CREATE TABLE tmp_ResultTable (Id INT, TableName VARCHAR(200), HasStationSeriesData VARCHAR(3), stmt VARCHAR(MAX))


SET @SourceServer = 'DRASSQL2017'
SET @SourceDatabase = 'DRAS_IRASv6_DEMO_QA'
SET @LineName = 'LIKE ''%12.7%'''
SET @IdOffset = '99990'
SET @LDIdOffset = @IdOffset

---------------------------------- FILTER out tables that have no data (are empty)

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
		INSERT INTO tmp_CandidateTables VALUES (@TableName)
	END

	FETCH NEXT FROM InsertTab_List INTO @TableName
END

CLOSE InsertTab_List
DEALLOCATE InsertTab_List

----------------------- Construct INSERT statements 

SET @SQL = 'SELECT @Result = MAX(Id) FROM ' + @SourceServer + '.' + QUOTENAME(@SourceDatabase) + '.dbo.ListDomain'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @MaxLDId OUTPUT

-- Add the parent tables of the tables in the tmp_CandidateTables table (Also include tables that need to be include i.e DomainCatalogColXRef)
WHILE EXISTS (SELECT DISTINCT OBJECT_NAME(referenced_object_id) TableName 
				FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM tmp_CandidateTables)
				AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT TableName FROM tmp_CandidateTables)
			)
BEGIN
	INSERT INTO tmp_CandidateTables
	SELECT DISTINCT OBJECT_NAME(referenced_object_id) TableName 
	FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM tmp_CandidateTables)
	AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT TableName FROM tmp_CandidateTables)
	UNION 
	SELECT name FROM sys.tables 
	WHERE name IN ('DomainCatalogColXRef')
	AND name NOT IN (SELECT TableName FROM tmp_CandidateTables)
END;

-- Use the Foreign key ranking to generate an Id for sorting the INSERT statements to avoid FK conflicts
WITH CTE AS 
(
	SELECT DISTINCT rt.Id, 
	c.TableName,
	ROW_NUMBER() OVER (PARTITION BY rt.ChildTable ORDER BY rt.ChildTable, rt.Id) rownum
	FROM tmp_CandidateTables c
	JOIN ##FKRank rt ON rt.ChildTable = c.TableName
)
SELECT Id, TableName 
INTO tmp_CandidateTableDetails
FROM CTE WHERE rownum = 1

-- Add code to disable and re-enable foreign keys for mutual-referencing tables (i.e Stg_ILI and InlineInspection). Only needs to be done for 1 table in each pair
INSERT INTO tmp_ResultTable
SELECT Id - 1,
NULL, NULL, 'ALTER TABLE ' + fr.ChildTable + ' NOCHECK CONSTRAINT ' + pt.FKConstraint
FROM ##ProblemTables pt  
JOIN ##FKRank fr ON pt.ChildTable = fr.ChildTable
WHERE fr.ChildTable = 'Stg_ILI' AND ChildColumn = 'InlineInspectionId'
UNION
SELECT Id + 1,
NULL, NULL, 'ALTER TABLE ' + fr.ChildTable + ' CHECK CONSTRAINT ' + pt.FKConstraint
FROM ##ProblemTables pt  
JOIN ##FKRank fr ON pt.ChildTable = fr.ChildTable
WHERE fr.ChildTable = 'Stg_ILI' AND ChildColumn = 'InlineInspectionId'

---------------------------- Generate INSERT statements

DECLARE InsertStmt_Cursor CURSOR FOR
SELECT Id, TableName FROM tmp_CandidateTableDetails
ORDER BY Id

OPEN InsertStmt_Cursor
FETCH NEXT FROM InsertStmt_Cursor INTO @Id, @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY

		-- Get the column list for the INSERT statment (some nullable columns are excluded i.e LastModDateTime, CreatedUser, etc)
		SELECT @InsertColumnList = STRING_AGG(column_name, ', ') 
		FROM INFORMATION_SCHEMA.columns inner_col WHERE table_name = @TableName
		AND (column_name NOT LIKE 'LastMod%' AND column_name NOT LIKE 'Create%')

		DROP TABLE IF EXISTS ##SelectColumns

		/*
			Build SELECT clause. Include special handling for DomainCatalogId and VirtualTableId columns to retain the Id from the
			source database if it already exists in the target (workaround for unique key conflictfor DomainDescr and VirtualTableName columns)
		*/
		SELECT CASE	
					WHEN column_name = 'DomainCatalogId' 
						THEN ' (SELECT dc1.Id FROM DomainCatalog dc1 JOIN ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
						WHERE dc2.Id = t2.DomainCatalogId) '
					WHEN column_name = 'VirtualTableId'
						THEN ' (SELECT v1.Id FROM VirtualTable v1 JOIN ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.VirtualTable v2 ON v1.VirtualTableName = v2.VirtualTableName
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

		/*
			Get a list of the primary keys for each table for use in WHERE clause to exclude rows already in target table from INSERT statement. 
			Inlcude special handling for VirtualTableId and DomainCatalogId to avoid primary/unique key conflict
		*/
		SELECT @PKList = STRING_AGG(' t1.' + tab.column_name + ' = '
		 + CASE 
				WHEN tab.column_name = 'VirtualTableId' THEN ' (SELECT v1.Id FROM VirtualTable v1 JOIN  ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.VirtualTable v2 
									ON v1.VirtualTableName = v2.VirtualTableName
									WHERE v2.Id = t2.VirtualTableId) '
				WHEN tab.column_name = 'DomainCatalogId' THEN ' (SELECT dc1.Id FROM DomainCatalog dc1 JOIN ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DomainCatalog dc2 ON dc1.DomainDescr = dc2.DomainDescr
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

		-- Construct portion of WHERE clause to filter for rows that contain data associated with the pipeline data being imported 
		SELECT @WhereClause = STRING_AGG( 
		CASE 
		WHEN column_name LIKE '%StationSeries%' THEN column_name + ' = (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.StationSeries 
									WHERE LineLoopId IN (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.LineLoop WHERE LineName LIKE ''%12.7%'')
									)'
		WHEN column_name = 'DischargeSubsystemId' 
				THEN column_name + ' = (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName+ ') '
		WHEN column_name = 'LineLoopId' 
				THEN column_name + ' = (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.LineLoop WHERE LineName ' + @LineName + ') '
		WHEN column_name = 'Stg_ILIId'
			THEN column_name + ' IN (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.Stg_ILI 
					WHERE DischargeSubsystemID = (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName + '))'
		WHEN column_name = 'InlineInspectionId'
			THEN column_name + ' IN (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.InlineInspection WHERE Stg_ILIId IN (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.Stg_ILI        WHERE DischargeSubsystemID = (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE  DischargeSubsystemName ' + @LineName + '))) ' 
		END
		, ' AND ') 
		FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND column_name LIKE '%Id' AND data_type IN ('int', 'numeric') 

		-- Construct portion of the WHERE clause to check that duplicate data is not inserted
		SET @PKWhereClause = 'WHERE NOT EXISTS (SELECT * FROM ' + @TableName + ' t1 WHERE ' + 
		CASE 
		WHEN @PKList IS NOT NULL 
			THEN @PKList
		ELSE ' t1.Id = t2.Id + ' + @IdOffset 
		END + ')'

		-- Include IDENTITY_INSERT on and off to allow INSERT into tables with an identity property
		IF (OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity')) = 1
		BEGIN
		SELECT @SQL = 'SET IDENTITY_INSERT ' + @TableName + ' ON ' + CHAR(10) + 'INSERT INTO ' + @TableName + ' (' + @InsertColumnList + ')' + CHAR(10) + 
		'SELECT ' + @SelectColumnList + ' FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.' + @TableName + ' t2 '
		+ @PKWhereClause + COALESCE(' AND (' + @WhereClause + ')', '') 
		+ 'SET IDENTITY_INSERT ' + @TableName + ' OFF '
		END
		ELSE
		BEGIN
			SELECT @SQL = 'INSERT INTO ' + @TableName + ' (' + @InsertColumnList + ')' + CHAR(10) + 
			'SELECT ' + @SelectColumnList + ' FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.' + @TableName + ' t2 ' 
			+ @PKWhereClause + COALESCE(' AND ' + @WhereClause + '', '') 
		END

		/*
			Special handling for specific tables to make the INSERT statements works or link the data being imported to the specifed pipeline
		*/
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
			SET @SQL += ' AND Id IN (SELECT CorporationId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.OperatingUnit 
			WHERE Id IN (SELECT OperatingUnitId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.PipelineSystem WHERE Id IN ((SELECT PipelineSystemId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + ')))) '
		END
		ELSE IF @TableName = 'OperatingUnit'
		BEGIN
			SET @SQL += ' AND Id IN (SELECT OperatingUnitId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.PipelineSystem WHERE Id IN ((SELECT PipelineSystemId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + '))) '
		END
		ELSE IF @TableName = 'PipelineSystem'
		BEGIN
			SET @SQL += ' AND Id IN (SELECT PipelineSystemId FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.DischargeSubsystem WHERE DischargeSubsystemName ' + @LineName + ') '
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
			SELECT @SQL += STRING_AGG(column_name + ' IN (SELECT Id FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDatabase) + '.dbo.ListDomain) ', ' AND ')
			FROM INFORMATION_SCHEMA.columns WHERE table_name = 'InlineInspection'
			AND column_name LIKE '%DomainId%'				
		END

		-- Keep track of tables that have a stationseries column (i.e BeginStationSeriesId, EndStationSeriesId)
		SELECT @HasStationSeriesInfo = CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND column_name LIKE '%StationSeriesId%') OR @TableName LIKE '%StationSeries%' THEN 'YES' ELSE 'NO' END

		-- Store results in a results table. comment out INSERT statements for tables that do not have station series data (Except for a few exempt tables)
		INSERT INTO tmp_ResultTable 
		SELECT Id, @TableName, @HasStationSeriesInfo, CASE WHEN @HasStationSeriesInfo = 'NO' AND TableName NOT LIKE '%Domain%' 
															AND TableName NOT IN ('Stg_ILI', 'Inlineinspection',
															'MLVSection', 'LineLoop', 'DischargeSubsystem', 
															'PipelineSystem', 'OperatingUnit', 'Corporation')
															THEN '--' + @SQL ELSE @SQL END
		FROM tmp_CandidateTableDetails cd WHERE cd.TableName = @TableName

		PRINT @sql
	END TRY
	BEGIN CATCH
		INSERT INTO tmp_ErrorTable VALUES (@TableName)
	END CATCH

	FETCH NEXT FROM InsertStmt_Cursor INTO @Id, @TableName
END

CLOSE InsertStmt_Cursor
DEALLOCATE InsertStmt_Cursor

-- Display results
IF EXISTS (SELECT * FROM tmp_ErrorTable)
BEGIN
	SELECT * FROM tmp_ErrorTable
END

SELECT * FROM tmp_ResultTable ORDER BY Id