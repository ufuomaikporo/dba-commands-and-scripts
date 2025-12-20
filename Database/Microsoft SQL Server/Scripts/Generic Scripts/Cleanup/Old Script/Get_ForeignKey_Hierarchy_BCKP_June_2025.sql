/*
This script generates the foreign key heirarchy for a database if given a starting root table (top of heirarchy)
*/

DECLARE @RootTable VARCHAR(100) 
DECLARE @NewRoot VARCHAR(100)

-- SET the root table that will be the top of the foreign key heirarchy
SET @RootTable = 'Corporation'


DROP TABLE IF EXISTS ##FKHeirarchy

CREATE TABLE ##FKHeirarchy (Id INT IDENTITY(1,1),
							FKConstraint NVARCHAR(100),
						   ParentTable NVARCHAR(100),
						   ParentColumn NVARCHAR(100),
						   ChildTable NVARCHAR(100), 
						   ChildColumn NVARCHAR(100),
						   RootTableNum INT,
						   FKRank INT)

DECLARE @GroupNum INT = 1

DROP TABLE IF EXISTS ##FKTable

-- Get list of foreign key relationships (NOTE** Risk tables are excluded for clarity during testing)
SELECT OBJECT_NAME(fkc.constraint_object_id) AS FKConstraint,
	   SCHEMA_NAME(t2.schema_id) AS ParentSchema,
	   OBJECT_NAME(fkc.referenced_object_id) AS ParentTable,
	   COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn,
	   SCHEMA_NAME(t1.schema_id) AS ChildSchema,
	   OBJECT_NAME(fkc.parent_object_id) AS ChildTable,
	   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
	   kcu.ordinal_position
INTO ##FKTable
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id

-- Construct foreign key heirarchy
DECLARE FKHierarchy_Cursor CURSOR FOR
SELECT DISTINCT ParentTable
FROM ##FKTable tab1
WHERE ParentTable NOT IN (SELECT ChildTable FROM ##FKTable)
AND ParentTable = @RootTable

OPEN FKHierarchy_Cursor
FETCH NEXT FROM FKHierarchy_Cursor INTO @NewRoot

WHILE @@FETCH_STATUS = 0
BEGIN
----------------------------------- Get Table Hierarchy -----------------------------------

	DECLARE @MemberRank INT = 0	
	
	INSERT INTO ##FKHeirarchy --(FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, RootTableNum, FKRank)
	SELECT NULL, NULL, NULL, ParentTable, ParentColumn, @GroupNum, @MemberRank
	FROM ##FKTable
	WHERE ParentTable = @NewRoot
	UNION
	SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum, @MemberRank + 1
	FROM ##FKTable
	WHERE ParentTable = @NewRoot

	WHILE EXISTS (SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @MemberRank + 2
					FROM ##FKTable 
					WHERE ParentTable IN (SELECT ChildTable FROM ##FKHeirarchy WHERE FKRank = @MemberRank))
	BEGIN

		INSERT INTO ##FKHeirarchy
		SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum,
				@MemberRank + 1
		FROM ##FKTable 
		WHERE ParentTable IN (SELECT ChildTable FROM ##FKHeirarchy WHERE FKRank = @MemberRank)
		AND FKConstraint NOT IN (SELECT FKConstraint FROM ##FKHeirarchy WHERE FKConstraint IS NOT NULL)

		SET @MemberRank += 1
	END

	SET @GroupNum += 1

	FETCH NEXT FROM FKHierarchy_Cursor INTO @NewRoot

END

CLOSE FKHierarchy_Cursor
DEALLOCATE FKHierarchy_Cursor;

DROP TABLE IF EXISTS ##ProblemTables

-- Find tables with self-referencing foreign keys or child tables that are referenced by their parent table
SELECT DISTINCT FKConstraint ProblemFKConstraint, ParentTable, ParentColumn,
table_schema AS ChildSchema, ChildTable, ChildColumn, 
'ALTER TABLE ' + table_schema + '.' + ChildTable + ' NOCHECK CONSTRAINT ' + FKConstraint AS [Disable Self-Referencing Foreign Keys]
INTO ##ProblemTables
FROM ##FKHeirarchy h1 
JOIN INFORMATION_SCHEMA.tables tab ON tab.table_name = h1.ChildTable 
WHERE ParentTable = ChildTable OR 
 EXISTS (SELECT * FROM ##FKHeirarchy h2 WHERE ParentTable 
IN (SELECT ChildTable FROM ##FKHeirarchy WHERE ParentTable = h2.ChildTable)
AND h1.ParentTable = h2.ParentTable AND h1.ChildTable = h2.ChildTable);

-- Exclude tables with self-referencing foreign keys from the foreign key heirarchy
WITH CTE AS
(SELECT *
FROM ##FKHeirarchy h
WHERE EXISTS (SELECT * FROM ##ProblemTables p WHERE p.ParentTable = h.ParentTable
AND p.ChildTable = h.ChildTable)
)
DELETE FROM CTE 

DROP TABLE IF EXISTS ##RankTab;

-- Use temporary table to rank child tables based on foreign key heirarchy
WITH CTE AS
(SELECT DISTINCT p.ParentTable GParent,
c.FKConstraint, c.ParentTable, c.ChildTable, p.FKRank ParentRank, c.FKRank ChildRank, 
p.FKRank + 1 AS TrueRank
, ROW_NUMBER() OVER (PARTITION BY c.ChildTable ORDER BY p.FKRank DESC) fltr
FROM ##FKHeirarchy p
JOIN ##FKHeirarchy c ON p.ChildTable = c.ParentTable
)
SELECT * INTO ##RankTab
FROM CTE 
WHERE fltr = 1

-- Add root table to Rank table
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) = @RootTable)
BEGIN
	INSERT INTO ##RankTab
	SELECT NULL, name, OBJECT_NAME(referenced_object_id), @RootTable, NULL, 0, 0, 1
	FROM sys.foreign_keys 
	WHERE OBJECT_NAME(parent_object_id) = @RootTable
END
ELSE
BEGIN
	INSERT INTO ##RankTab
	SELECT NULL, NULL, NULL, @RootTable, NULL, 0, 0, 1
END

DECLARE @Count INT = 1

-- Re-sort child tables based on parent table rank 
WHILE @Count < 100
BEGIN
	UPDATE ##RankTab
	SET ParentRank = src.ParentRank
	FROM ##RankTab targ
	JOIN
	(
	SELECT tmp.ChildTable, MAX(tmp.ParentRank) ParentRank
	FROM (
	SELECT rt1.ChildTable , h.ParentTable,
	(SELECT TrueRank FROM ##RankTab WHERE ChildTable = h.ParentTable)  AS ParentRank
	FROM ##FKHeirarchy h
	JOIN ##RankTab  rt1 ON rt1.ChildTable = h.ChildTable
	) tmp 
	JOIN ##RankTab rt  ON rt.ChildTable = tmp.ChildTable
	GROUP BY tmp.ChildTable
	) src
	ON targ.ChildTable = src.ChildTable


	UPDATE ##RankTab
	SET TrueRank =  ParentRank + 1
	WHERE ParentRank IS NOT NULL AND
	TrueRank <= ParentRank

	SET @Count += 1

END


SELECT * FROM ##ProblemTables


DROP TABLE IF EXISTS ##FKRank
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) Id, * INTO ##FKRank FROM ##RankTab ORDER BY TrueRank

UPDATE DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.InlineInspection SET ILICompanyDomainId = 23
WHERE  ILICompanyDomainId > (SELECT max(id) FROM  DRASSQL2017.DRAS_IRASv6_DEMO_QA.dbo.Listdomain)


SELECT * FROM ##FKRank where ChildTable NOT LIKE 'Risk%' ORDER BY TrueRank
--INSERT INTO ##FKRank (ChildTable, TrueRank) 
--SELECT name, (SELECT TrueRank FROM ##FKRank WHERE ChildTable IN (SELECT OBJECT_NAME(referenced_object_id) FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) = 'ACVGSurvey'))
--FROM sys.tables t WHERE name IN ('ACVGSurvey')
--SELECT * FROM ##FKRank where ChildTable like 'acvg%'
----SELECT * FROM ##RankTab  where ChildTable like 'acvg%'

--select * from ##RankTab where ChildTable = 'Listdomain'

