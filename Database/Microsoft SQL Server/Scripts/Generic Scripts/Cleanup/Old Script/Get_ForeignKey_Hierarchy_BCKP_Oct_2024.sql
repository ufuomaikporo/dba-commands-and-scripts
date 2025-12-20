USE DRAS_IRASv6_DEMO_QA
-- Problematic tables that will cause the recursive query to error out due to reaching the recursion limit
DECLARE @ProblemTables NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @RootTable VARCHAR(100) 

--*****************************************************************************************
-- Start of heirarchy
SET @RootTable = 'Corporation'

/*
List of tables that cause the recursion query to go over the maximum recursion limit. These tables
should be inlcuded in the root and not the recursive portion of the recursive CTE 
*/
SET @ProblemTables = 'InlineInspection
Classification'

--*******************************************************************************************

IF OBJECT_ID('tempdb..##ProblemTables') IS NOT NULL
BEGIN
	DROP TABLE ##ProblemTables
END

CREATE TABLE ##ProblemTables (TableName NVARCHAR(100))

SET @ProblemTables = REPLACE(@ProblemTables, ' ', '')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(10), ' ')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(13), '')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(9), '')
SET @ProblemTables = REPLACE(@ProblemTables, ' ', '''), ' + CHAR(10) + '(''') 

-- Store tables that will cause issues for the recursive query in a table
SET @SQL = 'INSERT INTO ##ProblemTables VALUES(''' + @ProblemTables + ''')'
EXECUTE(@SQL)

IF OBJECT_ID('ForeignKeyHierarchy', 'U') IS NOT NULL
BEGIN
	DROP TABLE ForeignKeyHierarchy
END

CREATE TABLE ForeignKeyHierarchy (Level INT, ReferencedTable NVARCHAR(100), TableName VARCHAR(100))

INSERT INTO ForeignKeyHierarchy
SELECT 0, 
		NULL,
		@RootTable

------------------------------------ Find chain of child tables starting from the @RootTable  ----------------------

DECLARE TableList CURSOR FAST_FORWARD FOR
SELECT DISTINCT OBJECT_NAME(parent_object_id) FKTable
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(referenced_object_Id) = @RootTable

OPEN TableList
FETCH NEXT FROM TableList INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN

	WITH ForeignKeyCTE
	AS (
		--Anchor. Get the root(s) for the recursive
		SELECT  NULL AS Level, 
				OBJECT_NAME(referenced_object_Id) ReferencedTable, 
				OBJECT_NAME(parent_object_id) FKTable
		FROM 
		sys.foreign_key_columns 
		WHERE OBJECT_NAME(referenced_object_Id) = @TableName 
		--AND OBJECT_NAME(referenced_object_Id) NOT IN ('Stg_ILI', 'InlineInspection')
		UNION ALL
		--Recursive. Get the direct descendants at each level
		SELECT  NULL, OBJECT_NAME(t.referenced_object_Id), OBJECT_NAME(t.parent_object_id)
		FROM sys.foreign_key_columns t 
			INNER JOIN ForeignKeyCTE m on m.FKTable = OBJECT_NAME(t.referenced_object_Id)
		WHERE FKTable NOT IN (SELECT TableName FROM ##ProblemTables)
	)
	INSERT INTO ForeignKeyHierarchy
	SELECT Level, ReferencedTable, FKTable
	FROM ForeignKeyCTE t
	WHERE NOT EXISTS (SELECT * FROM ForeignKeyHierarchy d 
						WHERE d.TableName = t.FKTable
						AND d.ReferencedTable = t.ReferencedTable);
	
	FETCH NEXT FROM TableList INTO @TableName
END 

CLOSE TableList;
DEALLOCATE TableList;

-------------------------------- Find all descendent child tables for tables in ##ProblemTables ---------------------------------------

DECLARE TableList CURSOR FAST_FORWARD FOR
SELECT DISTINCT OBJECT_NAME(parent_object_id) FKTable
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(referenced_object_Id) IN (SELECT TableName FROM ##ProblemTables)

OPEN TableList
FETCH NEXT FROM TableList INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	WITH ForeignKeyCTE
	AS (
		--Anchor. Get the root(s) for the recursive
		SELECT  NULL Level, 
				OBJECT_NAME(referenced_object_Id) ReferencedTable, 
				OBJECT_NAME(parent_object_id) FKTable
		FROM 
		sys.foreign_key_columns 
		WHERE OBJECT_NAME(referenced_object_Id) = @TableName 
		--AND OBJECT_NAME(referenced_object_Id) NOT IN ('Stg_ILI', 'InlineInspection')
		UNION ALL
		--Recursive. Get the direct descendants at each level
		SELECT  NULL, OBJECT_NAME(t.referenced_object_Id), OBJECT_NAME(t.parent_object_id)
		FROM sys.foreign_key_columns t 
			INNER JOIN ForeignKeyCTE m on m.FKTable = OBJECT_NAME(t.referenced_object_Id)
		WHERE FKTable NOT IN (SELECT TableName FROM ##ProblemTables)
	)
	INSERT INTO ForeignKeyHierarchy
	SELECT Level, ReferencedTable, FKTable
	FROM ForeignKeyCTE t
	WHERE NOT EXISTS (SELECT * FROM ForeignKeyHierarchy d 
						WHERE d.TableName = t.FKTable
						AND d.ReferencedTable = t.ReferencedTable)
 
 
	FETCH NEXT FROM TableList INTO @TableName
END 

CLOSE TableList;
DEALLOCATE TableList;

----------------------------- Find chain of parent tables for tables in ##ProblemTables ---------------------------

DECLARE TableList CURSOR FAST_FORWARD FOR
SELECT DISTINCT OBJECT_NAME(referenced_object_id) FKTable
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(parent_object_Id) IN (SELECT TableName FROM ##ProblemTables)

OPEN TableList
FETCH NEXT FROM TableList INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN

	WITH ForeignKeyCTE
	AS (
		--Anchor. Get the root(s) for the recursive
		SELECT  NULL Level, 
				OBJECT_NAME(referenced_object_Id) ReferencedTable, 
				OBJECT_NAME(parent_object_id) FKTable
		FROM 
		sys.foreign_key_columns 
		WHERE OBJECT_NAME(parent_object_Id) = @TableName 
		UNION ALL
		--Recursive. Get the direct descendants at each level
		SELECT  NULL, OBJECT_NAME(t.referenced_object_Id), OBJECT_NAME(t.parent_object_id)
		FROM sys.foreign_key_columns t 
			INNER JOIN ForeignKeyCTE m on m.ReferencedTable = OBJECT_NAME(t.parent_object_Id)
		WHERE FKTable NOT IN (SELECT TableName FROM ##ProblemTables)
	)
	INSERT INTO ForeignKeyHierarchy
	SELECT Level, ReferencedTable, FKTable
	FROM ForeignKeyCTE t
	WHERE NOT EXISTS (SELECT * FROM ForeignKeyHierarchy d 
						WHERE d.TableName = t.FKTable
						AND d.ReferencedTable = t.ReferencedTable)
	AND FKTable <> @RootTable;
 
	FETCH NEXT FROM TableList INTO @TableName
END;

CLOSE TableList
DEALLOCATE TableList;

-- Delete duplicate rows
WITH duplicates AS  
( SELECT *,
		 ROW_NUMBER() OVER (PARTITION BY ReferencedTable, TableName ORDER BY Level) row_num 
  FROM ForeignKeyHierarchy  
)  
DELETE Duplicates WHERE row_num <> 1

-- Assign levels for each row based on parent-child heirarchy
UPDATE ForeignKeyHierarchy 
SET Level = (CASE 
				WHEN tab2.TableName IS NULL THEN 0
				--WHEN tab2.TableName IS NOT NULL and tab1.level IS NULL THEN 0
				ELSE tab2.Level + 1
			END)
FROM ForeignKeyHierarchy tab1
LEFT JOIN (SELECT * FROM ForeignKeyHierarchy ) tab2
ON tab1.ReferencedTable = tab2.TableName

-- Make sure all rows with NULL values for level column are assigned a value
WHILE EXISTS (SELECT * FROM ForeignKeyHierarchy WHERE Level IS NULL)
BEGIN
	UPDATE ForeignKeyHierarchy 
	SET Level = (CASE 
					WHEN tab2.TableName IS NULL THEN 0
					--WHEN tab2.TableName IS NOT NULL and tab1.level IS NULL THEN 0
					ELSE tab2.Level + 1
				END)
	FROM ForeignKeyHierarchy tab1
	LEFT JOIN (SELECT * FROM ForeignKeyHierarchy ) tab2
	ON tab1.ReferencedTable = tab2.TableName
	WHERE tab1.Level IS NULL
	AND tab2.Level IS NOT NULL
END


SELECT  * FROM ForeignKeyHierarchy
WHERE TableName NOT LIKE 'Risk%' and ReferencedTable = 'ListDomain'
 ORDER BY 1, 2, 3

 return

SELECT tab1.level, tab1.ReferencedTable, tab1.TableName, tab2.Level, tab2.ReferencedTable, tab2.TableName 
FROM ForeignKeyHierarchy tab1
LEFT JOIN  ForeignKeyHierarchy tab2
ON tab1.ReferencedTable = tab2.TableName
WHERE tab1.Level IS NULL


SELECT DISTINCT * FROM ForeignKeyHierarchy
WHERE TableName NOT LIKE 'Risk%' --and ReferencedTable = 'InlineInspection'
 ORDER BY 1, 2, 3

return

SELECT DISTINCT * FROM ForeignKeyHierarchy
WHERE TableName = 'Classification'

CLOSE TableList
DEALLOCATE TableList

select * from ForeignKeyHierarchy tab1 where exists (
select ReferencedTable, 
		--ParentColumnName, 
		TableName,
		--ChildColumnName, 
		count(*) 
from ForeignKeyHierarchy tab2
where tab1.ReferencedTable = tab2.ReferencedTable
AND tab1.TableName = tab2.TableName
group by ReferencedTable, 
		--ParentColumnName, 
		TableName
		--ChildColumnName
having count(*) > 1
) order by 2,3,1

RETURN

--select count(DISTINCT TableName) FROM ForeignKeyHierarchy
SELECT DISTINCT * FROM ForeignKeyHierarchy
WHERE TableName NOT LIKE 'Risk%' --and ReferencedTable = 'InlineInspection'
 ORDER BY 1, 2, 3


--SELECT SERVERPROPERTY('collation') AS SQLServerCollation
