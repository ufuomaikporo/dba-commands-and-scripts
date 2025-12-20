/*
NOTE**** 
1. You must disable all the foreign keys listed in the ##ProblemTables table that are not self-referencing foreign keys 
	before you can use a DELETE statement to delete data from tables in order of the foreign key hierarchy. 
2. MAKE SURE to re-enable the foreign keys that are disabled after data deletion
3. Tables that are self-referencing (references itself) and/or that have a mutual reference (two tables referencing each other) 
	will be be excluded from the recursive query. Otherwise it force the recursion to reach the recursion limit and produce an error

-- Query to get foreign keys that need to be disabled before deleting data based on FK hierarchy
SELECT * FROM ##ProblemTables WHERE ParentTable <> ChildTable

*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @RootTable VARCHAR(100) 

--*****************************************************************************************
-- Start of heirarchy
SET @RootTable = 'Corporation'

--*******************************************************************************************

DROP TABLE IF EXISTS ##ProblemTables
DROP TABLE IF EXISTS ##FKTableRank
DROP TABLE IF EXISTS ##FKHierarchy

-- Find tables with self-referencing foreign keys or child tables that are referenced by their parent table
SELECT DISTINCT OBJECT_NAME(constraint_object_id) ProblemFKConstraint, OBJECT_NAME(referenced_object_id) ParentTable,
COL_NAME(referenced_object_id, referenced_column_id) ParentColumn,
table_schema AS ChildSchema, OBJECT_NAME(parent_object_id) ChildTable, COL_NAME(parent_object_id, parent_column_id) ChildColumn, 
'ALTER TABLE ' + table_schema + '.' + OBJECT_NAME(parent_object_id) + ' NOCHECK CONSTRAINT ' + OBJECT_NAME(constraint_object_id) AS [Disable Self-Referencing Foreign Keys]
INTO ##ProblemTables
FROM sys.foreign_key_columns h1 
JOIN INFORMATION_SCHEMA.tables tab ON tab.table_name = OBJECT_NAME(h1.parent_object_id)  
WHERE OBJECT_NAME(referenced_object_id) = OBJECT_NAME(parent_object_id)  
OR OBJECT_NAME(referenced_object_id) IN (SELECT OBJECT_NAME(parent_object_id) FROM sys.foreign_keys h2 WHERE referenced_object_id = h1.parent_object_id)

------------------------------------ Find chain of child tables starting from the @RootTable  ----------------------

-- Recursive CTE to map out the full foreign key hierarchy
;WITH FKHierarchy_CTE AS (
    -- Anchor: start from root tables (tables not referenced by any FK, or user-specified root)
   SELECT 
        1 AS Level,
        fk.referenced_object_id AS ReferencedTableID,
        OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
        fk.parent_object_id AS TableID,
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        fk.name AS ForeignKeyName
    FROM sys.foreign_keys fk
    WHERE (OBJECT_NAME(fk.referenced_object_id) = 'Corporation'
        OR fk.referenced_object_id NOT IN (SELECT parent_object_id FROM sys.foreign_keys))
        AND OBJECT_NAME(fk.referenced_object_id) NOT IN (SELECT ChildTable FROM ##ProblemTables)

    UNION ALL

    -- Recursive: find children
    SELECT 
        h.Level + 1,
        fk.referenced_object_id,
        OBJECT_NAME(fk.referenced_object_id),
        fk.parent_object_id,
        OBJECT_NAME(fk.parent_object_id),
        fk.name
    FROM sys.foreign_keys fk
    INNER JOIN FKHierarchy_CTE h ON fk.referenced_object_id = h.TableID
    WHERE OBJECT_NAME(fk.parent_object_id) NOT IN (SELECT ChildTable FROM ##ProblemTables)
)
SELECT ROW_NUMBER() OVER (ORDER BY Level, ReferencedTable, TableName) AS Id, *
INTO ##FKHierarchy
FROM (SELECT DISTINCT  Level,
    ReferencedTable, 
    TableName,
    ForeignKeyName
FROM FKHierarchy_CTE
UNION
SELECT DISTINCT
    0,
	NULL,
    OBJECT_NAME(fk.referenced_object_id),
    NULL
FROM sys.foreign_keys fk
WHERE (OBJECT_NAME(fk.referenced_object_id) = 'Corporation'
    OR fk.referenced_object_id NOT IN (SELECT parent_object_id FROM sys.foreign_keys))
    AND OBJECT_NAME(fk.referenced_object_id) NOT IN (SELECT ChildTable FROM ##ProblemTables)) tmp

SET @SQL = NULL;

--INSERT INTO ##FKHierarchy
--SELECT DISTINCT
--    0,
--	NULL,
--    OBJECT_NAME(fk.referenced_object_id),
--    NULL,
--    fk.parent_object_id AS TableID
--FROM sys.foreign_keys fk
--WHERE (OBJECT_NAME(fk.referenced_object_id) = 'Corporation'
--    OR fk.referenced_object_id NOT IN (SELECT parent_object_id FROM sys.foreign_keys))
--    AND OBJECT_NAME(fk.referenced_object_id) NOT IN (SELECT ChildTable FROM ##ProblemTables);

select * from ##FKHierarchy order by Id
return;

---- Get unique table ranking with DELETE statements to delete data from tables in order of their foreign key hierarchy

WITH CTE AS 
(
SELECT Id, 
	   TableName, 
	   'DELETE FROM ' + TableName + CHAR(10) + 'GO' AS DeleteStmt , 
	   ROW_NUMBER()  OVER (PARTITION BY TableName ORDER BY Id desc) rowid
FROM ##FKHierarchy 
)
SELECT *
INTO ##FKTableRank
FROM CTE WHERE rowid = 1  
ORDER BY Id DESC

--------------------------- Cursor to print out DELETE statements based on FK hierarchy ----------------

DECLARE Print_Cursor CURSOR FOR
SELECT DeleteStmt FROM ##FKTableRank
ORDER BY Id DESC

OPEN Print_Cursor
FETCH NEXT FROM Print_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT @SQL

	FETCH NEXT FROM Print_Cursor INTO @SQL
END

CLOSE Print_Cursor
DEALLOCATE Print_Cursor

-- List of foreign keys that need to be disabled before deleting in order of FK hierarchy
SELECT * FROM ##ProblemTables WHERE ParentTable <> ChildTable;

SELECT * FROM ##FKHierarchy order by id