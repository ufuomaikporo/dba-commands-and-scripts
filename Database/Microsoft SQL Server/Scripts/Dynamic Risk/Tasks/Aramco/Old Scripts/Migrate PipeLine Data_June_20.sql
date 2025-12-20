USE DRAS_IRASv6_DEMO_QA
/*
select * from LineLoop where LineName like '%12.75%'

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
WHERE OBJECT_NAME(fkc.parent_object_id) = 'LIneLoop'
ORDER BY 1


1. find tables with data
2. of that find tables with StationSeries column
3. of those find tables with parent or child relationship with LineLoop
*/

-------------------------------- Disable Foreign Keys ---------------------------

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName VARCHAR(200)
DECLARE @Count INT

-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE is_disabled = 0

OPEN DiableFK_Cursor
FETCH NEXT FROM DiableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DiableFK_Cursor INTO @SQL
END

CLOSE DiableFK_Cursor
DEALLOCATE DiableFK_Cursor

-------------------------------- FILTER our tables that have no data (are empty)

DROP TABLE IF EXISTS ##CandidateTables
CREATE TABLE ##CandidateTables (TableName VARCHAR(100))

DECLARE InsertTab_List CURSOR FOR
SELECT DISTINCT table_name FROM INFORMATION_SCHEMA.columns
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
CREATE TABLE tmp_ErrorTable (TableName VARCHAR(100))
DECLARE @InsertColumnList VARCHAR(MAX)
DECLARE @SelectColumnList VARCHAR(MAX)
DECLARE @WhereClause VARCHAR(MAX)
DECLARE @MaxLDId INT

SELECT @MaxLDId = MAX(Id) FROM DRASSQL2017.DRAS_IRASV6_DEMO_QA.dbo.ListDomain

INSERT INTO ##CandidateTables
SELECT DISTINCT OBJECT_NAME(referenced_object_id) TableName 
FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) IN (SELECT TableName FROM ##CandidateTables)
AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT TableName FROM ##CandidateTables)
UNION SELECT name FROM sys.tables WHERE name IN ('ACVGSurvey')
AND name NOT IN (SELECT TableName FROM ##CandidateTables)


DECLARE @PKList NVARCHAR(MAX)
DECLARE @PKWhereClause NVARCHAR(MAX)
DECLARE @IdOffset VARCHAR(5) = '99990'
DECLARE @LDIdOffset VARCHAR(7) = '1023409'
DROP TABLE IF EXISTS ##ResultTable 
CREATE TABLE ##ResultTable (TableName VARCHAR(200), stmt VARCHAR(MAX))

DECLARE InsertStmt_Cursor CURSOR FOR
SELECT TableName 
FROM ##CandidateTables ct
JOIN ##FKRank rt ON rt.ChildTable = ct.TableName
--where tablename like 'PipeCondition'
ORDER BY rt.Id

OPEN InsertStmt_Cursor
FETCH NEXT FROM InsertStmt_Cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY

		SELECT @InsertColumnList = STRING_AGG(column_name, ', ') 
		FROM INFORMATION_SCHEMA.columns inner_col WHERE table_name = @TableName
		AND (column_name NOT LIKE 'LastMod%' AND column_name NOT LIKE 'Create%')

		DROP TABLE IF EXISTS ##SelectColumns
		SELECT CASE WHEN column_name LIKE '%Id' AND 
							column_name <> 'SourceId' AND column_name NOT LIKE '%DomainId' THEN column_name + ' + ' + @IdOffset + ' ' + column_name
							WHEN column_name IN (SELECT COL_NAME(parent_object_id, parent_column_id) FROM sys.foreign_key_columns 
											WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain')
							THEN column_name + ' + ' + @LDIdOffset + ' ' + column_name
							ELSE column_name END ColumnName
		INTO ##SelectColumns
		FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND (column_name NOT LIKE 'LastMod%' AND column_name NOT LIKE 'Create%')

		SELECT @SelectColumnList = STRING_AGG(ColumnName, ', ')  FROM ##SelectColumns

		SELECT @PKList = STRING_AGG(' t1.' + column_name + ' = t2.' + column_name + ' + ' + @IdOffset, ' AND ')
		FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
		WHERE table_name = @TableName AND constraint_name LIKE 'PK[_]%' 


		SELECT @WhereClause = STRING_AGG(
		CASE WHEN column_name LIKE '%StationSeries%' THEN column_name + ' = (SELECT Id FROM StationSeries 
									WHERE LineLoopId IN (SELECT Id FROM LineLoop WHERE LineName LIKE ''%12.7%'')
									)'
		WHEN column_name = 'DischargeSubsystemId' 
				THEN column_name + ' = (SELECT Id FROM DischargeSubsystem WHERE  DischargeSubsystemName LIKE ''%12.7%'') '
		WHEN column_name = 'LineLoopId' 
				THEN column_name + ' = (SELECT Id FROM LineLoop WHERE LineName LIKE ''%12.7%'') '
		ELSE column_name + ' > ' + @IdOffset
		END
		, ' OR ') 
		FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
		AND (column_name LIKE '%StationSeries%' OR column_name IN 
		('PipelineSubsystemId', 'DischargeSubsystemId', 'LIneLoopId', 'StgILIId',
		'InlineInspectionId', 'ExcavationSiteId'))

		SET @PKWhereClause = 'WHERE NOT EXISTS (SELECT * FROM ' + @TableName + ' t1 WHERE ' + 
		CASE WHEN @PKList IS NOT NULL THEN @PKList
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
			+ @PKWhereClause + COALESCE(' AND (' + @WhereClause + ')', '') 
		END

		INSERT INTO ##ResultTable SELECT @TableName, @SQL

		print @sql
	END TRY
	BEGIN CATCH
		INSERT INTO tmp_ErrorTable VALUES (@TableName)
	END CATCH

	FETCH NEXT FROM InsertStmt_Cursor INTO @TableName
END


CLOSE InsertStmt_Cursor
DEALLOCATE InsertStmt_Cursor

SELECT * FROM ##ResultTable

--------------------------- Re-Enable FK

DECLARE EnableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE is_disabled = 1

OPEN EnableFK_Cursor
FETCH NEXT FROM EnableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM EnableFK_Cursor INTO @SQL
END

CLOSE EnableFK_Cursor
DEALLOCATE EnableFK_Cursor
