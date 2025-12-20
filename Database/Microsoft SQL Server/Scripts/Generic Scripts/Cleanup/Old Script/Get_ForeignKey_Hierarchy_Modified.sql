--USE DRAS_IRASv6_DEMO_QA
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

SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE table_name IN (SELECT OBJECT_NAME(referenced_object_id) 
					FROM sys.foreign_keys)
	AND table_name NOT IN (SELECT OBJECT_NAME(parent_object_id) 
					FROM sys.foreign_keys)

-- Recursive CTE to map out the full foreign key hierarchy
;WITH FKHierarchy AS (
    -- Anchor: start from root tables (tables not referenced by any FK, or user-specified root)
    SELECT 
        1 AS Level,
        fk.referenced_object_id AS ReferencedTableID,
        OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
        fk.parent_object_id AS TableID,
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        fk.name AS ForeignKeyName
    FROM sys.foreign_keys fk
    WHERE OBJECT_NAME(fk.referenced_object_id) = @RootTable
        OR fk.referenced_object_id NOT IN (SELECT parent_object_id FROM sys.foreign_keys)
        OR OBJECT_NAME(fk.referenced_object_id) IN (SELECT TableName FROM ##ProblemTables)

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
    INNER JOIN FKHierarchy h ON fk.referenced_object_id = h.TableID
    WHERE OBJECT_NAME(fk.parent_object_id) NOT IN (SELECT TableName FROM ##ProblemTables)
)
SELECT 
    Level, 
    ReferencedTable, 
    TableName, 
    ForeignKeyName
FROM FKHierarchy
ORDER BY Level, ReferencedTable, TableName;

