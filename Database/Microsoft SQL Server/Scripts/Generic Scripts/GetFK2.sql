DECLARE @SQL NVARCHAR(MAX)
DECLARE @DeleteList NVARCHAR(MAX)
DECLARE @ExemptList NVARCHAR(MAX)
DECLARE @DropSavedFKDefinitions NVARCHAR(1)
DECLARE @ProblemTables NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @RootTable NVARCHAR(100)
/*
List of tables that cause the recursion query to go over the maximum recursion limit. These tables
should be inlcuded in the root and not the recursive portion of the recursive CTE 
*/

SET @RootTable = 'StationSeries'

SET @ProblemTables = 'InlineInspection
Classification
Maintenance'

IF OBJECT_ID('tempdb..##ProblemTables') IS NOT NULL
BEGIN
	DROP TABLE ##ProblemTables
END

CREATE TABLE ##ProblemTables (TableName NVARCHAR(100))

SET @ProblemTables = REPLACE(@ProblemTables, ' ', '')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(10), ' ')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(13), '')
SET @ProblemTables = REPLACE(@ProblemTables, CHAR(9), '')
SET @ProblemTables = REPLACE(@ProblemTables, ' ', ''', ''')

SET @ProblemTables = '''' + @ProblemTables + ''''

---- Store tables that will cause issues for the recursive query in a table
--SET @SQL = 'INSERT INTO ##ProblemTables VALUES(''' + @ProblemTables + ''')'
--EXECUTE(@SQL)

IF OBJECT_ID ('ForeignKeyHierarchy', 'U') IS NOT NULL
BEGIN
	DROP TABLE ForeignKeyHierarchy
END

-- Table to store list of tables whose data will be truncated
CREATE TABLE ForeignKeyHierarchy (Level INT, 
								  ParentTableName NVARCHAR(100), 
								  --ParentColumnName NVARCHAR(100),
								  ChildTableName NVARCHAR(100)
								  --ChildColumnName NVARCHAR(100)
								  )

IF OBJECT_ID ('tempdb..##TempTable', 'U') IS NOT NULL
BEGIN
	DROP TABLE ##TempTable
END

-- Table to store list of tables whose data will be truncated
CREATE TABLE ##TempTable (Level INT, ParentTableName NVARCHAR(100), ChildTableName NVARCHAR(100))

IF EXISTS (SELECT * FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = @RootTable)
BEGIN
	INSERT INTO ForeignKeyHierarchy
	SELECT 0, 
		   OBJECT_NAME(referenced_object_id),
		   --COL_NAME(referenced_object_id, referenced_column_id),
		   @RootTable
		  -- COL_NAME(parent_object_id, parent_column_id)
	FROM sys.foreign_key_columns
	WHERE OBJECT_NAME(parent_object_id) = @RootTable
END
ELSE
BEGIN
	INSERT INTO ForeignKeyHierarchy
	SELECT 0,
		   NULL,
		   --NULL,
		   @RootTable
		   --NULL
END

INSERT INTO ForeignKeyHierarchy
SELECT * FROM (
SELECT DISTINCT 1 Level, 
	   @RootTable AS ParentTableName,
	   --COL_NAME(referenced_object_id, referenced_column_id) AS ParentColumnName,
	   OBJECT_NAME(parent_object_id) AS ChildTableName
	  -- COL_NAME(parent_object_id, parent_column_id) AS ChildColumnName
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(referenced_object_id) = @RootTable) subq
WHERE NOT EXISTS (SELECT * FROM ForeignKeyHierarchy d 
					  WHERE d.ChildTableName = subq.ChildTableName
					 -- AND d.ChildColumnName = subq.ChildColumnName
					  AND d.ParentTableName = subq.ParentTableName
					  --AND d.ParentColumnName = subq.ParentColumnName
				 )

SET @SQL = 'INSERT INTO ##ProblemTables
SELECT DISTINCT ChildTableName FROM ForeignKeyHierarchy
WHERE ChildTableName IN (' + @ProblemTables + ')';

EXECUTE (@SQL);

DECLARE TableList CURSOR FAST_FORWARD FOR
SELECT DISTINCT ChildTableName FROM ForeignKeyHierarchy order by 1

OPEN TableList
FETCH NEXT FROM TableList INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	print @tableName;
	WITH ForeignKeyCTE
	AS (
		--Anchor. Get the root(s) for the recursive
		SELECT  1 AS Level, 
				OBJECT_NAME(referenced_object_Id) AS ParentTableName, 
				--COL_NAME(referenced_object_id, referenced_column_id) AS ParentColumnName,
				OBJECT_NAME(parent_object_id) AS ChildTableName
				--COL_NAME(parent_object_id, parent_column_id) AS ChildColumnName
		FROM 
		sys.foreign_key_columns fkc
		WHERE OBJECT_NAME(referenced_object_Id) = @TableName 
		UNION ALL
		--Recursive. Get the direct descendants at each level
		SELECT  m.level + 1, 
				OBJECT_NAME(t.referenced_object_Id) AS ParentTableName, 
				--COL_NAME(t.referenced_object_id, t.referenced_column_id) AS ParentColumnName,
				OBJECT_NAME(t.parent_object_id) AS ChildTableName
				--COL_NAME(t.parent_object_id, t.parent_column_id) AS ChildColumnName
		FROM sys.foreign_key_columns t 
			INNER JOIN ForeignKeyCTE m on m.ChildTableName = OBJECT_NAME(t.referenced_object_Id)
		WHERE ChildTableName NOT IN (SELECT * FROM ##ProblemTables) -- Excludes problem tables from recursive section
	)
	INSERT INTO ForeignKeyHierarchy
	SELECT DISTINCT Level, 
		   ParentTableName, 
		   --ParentColumnName, 
		   ChildTableName
		   --ChildColumnName
	FROM ForeignKeyCTE t
	WHERE NOT EXISTS (SELECT * FROM ForeignKeyHierarchy d 
					  WHERE d.ChildTableName = t.ChildTableName
					  --AND d.ChildColumnName = t.ChildColumnName
					  AND d.ParentTableName = t.ParentTableName
					  --AND d.ParentColumnName = t.ParentColumnName
					  )

	FETCH NEXT FROM TableList INTO @TableName
END 

CLOSE TableList
DEALLOCATE TableList;

return;

-- Delete duplicate rows
WITH duplicates AS  
( SELECT *,
		 ROW_NUMBER() OVER (PARTITION BY ParentTableName, ChildTableName ORDER BY level ) row_num 
  FROM ForeignKeyHierarchy  
)  
DELETE Duplicates WHERE row_num = 2

---------------------------------------------------------------

-- Store child tables that are direct descendants of ##ProblemTables if not already there
INSERT INTO ForeignKeyHierarchy
SELECT NULL,
	   OBJECT_NAME(referenced_object_id) ParentTableName,
	   --COL_NAME(referenced_object_id, referenced_column_id) AS ParentColumnName,
	   OBJECT_NAME(parent_object_id) ChildTableName
	   --COL_NAME(parent_object_id, parent_column_id) AS ChildColumnName
FROM sys.foreign_key_columns fkc
WHERE OBJECT_NAME(parent_object_id) IN (SELECT * FROM ##ProblemTables WHERE TableName <> @RootTable)
AND NOT EXISTS (SELECT * FROM ForeignKeyHierarchy fkh
				WHERE fkh.ParentTableName = OBJECT_NAME(fkc.referenced_object_id)
				AND fkh.ChildTableName = OBJECT_NAME(fkc.parent_object_id))

-- Store parent tables of tables listed in ##ProblemTables in ForeignKeyHierarchy table
INSERT INTO ForeignKeyHierarchy
SELECT NULL,
	   OBJECT_NAME(referenced_object_id) ParentTableName,
	   --COL_NAME(referenced_object_id, referenced_column_id) AS ParentColumnName,
	   OBJECT_NAME(parent_object_id) ChildTableName
	   --COL_NAME(parent_object_id, parent_column_id) AS ChildColumnName
FROM sys.foreign_key_columns fkc
WHERE OBJECT_NAME(referenced_object_id) IN (SELECT * FROM ##ProblemTables WHERE TableName <> @RootTable)
AND NOT EXISTS (SELECT * FROM ForeignKeyHierarchy fkh
				WHERE fkh.ParentTableName = OBJECT_NAME(fkc.referenced_object_id)
				AND fkh.ChildTableName = OBJECT_NAME(fkc.parent_object_id))

select * from ForeignKeyHierarchy tab1 where exists (
select ParentTableName, 
		--ParentColumnName, 
		ChildTableName,
		--ChildColumnName, 
		count(*) 
from ForeignKeyHierarchy tab2
where tab1.ParentTableName = tab2.ParentTableName
AND tab1.ChildTableName = tab2.ChildTableName
group by ParentTableName, 
		--ParentColumnName, 
		ChildTableName
		--ChildColumnName
having count(*) > 1
) order by 2,3,1

select * from ForeignKeyHierarchy where level is null
return;
-- Update the level column using known level of tables with the same name in the ParentTableName column
UPDATE ForeignKeyHierarchy 
SET Level = (SELECT TOP 1 Level 
			 FROM ForeignKeyHierarchy tab2
			 WHERE tab1.ParentTableName = tab2.ParentTableName
			 AND tab1.ChildTableName = tab2.ChildTableName
			 AND Level IS NOT NULL)
FROM ForeignKeyHierarchy tab1
WHERE Level IS NULL

select * from ForeignKeyHierarchy order by 1 --where level is null


DECLARE TableList CURSOR FAST_FORWARD FOR
SELECT DISTINCT ChildTableName FROM ForeignKeyHierarchy
WHERE ParentTableName IN (SELECT * FROM ##ProblemTables WHERE ChildTableName <> @RootTable)

return

OPEN TableList
FETCH NEXT FROM TableList INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN

	WITH ForeignKeyCTE
	AS (
		--Anchor. Get the root(s) for the recursive
		SELECT  NULL AS Level, 
				OBJECT_NAME(referenced_object_Id) ParentTableName, 
				OBJECT_NAME(parent_object_id) FKTable
		FROM 
		sys.foreign_key_columns 
		WHERE OBJECT_NAME(referenced_object_Id) = @TableName 
		UNION ALL
		--Recursive. Get the direct descendants at each level
		SELECT  NULL, OBJECT_NAME(t.referenced_object_Id), OBJECT_NAME(t.parent_object_id)
		FROM sys.foreign_key_columns t 
			INNER JOIN ForeignKeyCTE m on m.FKTable = OBJECT_NAME(t.referenced_object_Id)
		WHERE FKTable NOT IN (SELECT * FROM ##ProblemTables) -- Excludes problem tables from recursive section
	)
	INSERT INTO ForeignKeyHierarchy
	SELECT DISTINCT NULL, ParentTableName, FKTable
	FROM ForeignKeyCTE t
	WHERE NOT EXISTS (SELECT * FROM ##TempTable d 
						WHERE d.ChildTableName = t.FKTable
						AND d.ParentTableName = t.ParentTableName)

	FETCH NEXT FROM TableList INTO @TableName
END 

CLOSE TableList
DEALLOCATE TableList
select * from ##TempTable