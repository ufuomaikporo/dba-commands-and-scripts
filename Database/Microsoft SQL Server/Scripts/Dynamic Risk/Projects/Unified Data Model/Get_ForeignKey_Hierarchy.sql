/*




*/


DROP TABLE IF EXISTS ##FKHeirarchy

CREATE TABLE ##FKHeirarchy (Id INT IDENTITY(1,1),
						 FKConstraint NVARCHAR(100),
						   ParentTable NVARCHAR(100),
						   ParentColumn NVARCHAR(100),
						   ChildTable NVARCHAR(100), 
						   ChildColumn NVARCHAR(100),
						   RootTableNum INT,
						   FKRank INT)

DROP TABLE IF EXISTS ##FKTable

-- Store List of database foreign keys within table
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
ORDER BY 1


DECLARE @RootTable NVARCHAR(100) 
DECLARE @GroupNum INT = 1
DECLARE @SQL NVARCHAR(MAX)

/* 
Cursor to find foreign key heirarchy. SET parent table to the root of 
heirarchy (i.e. the table you would like to delete from)
*/
DECLARE FKHierarchy_Cursor CURSOR FOR
SELECT DISTINCT ParentTable
FROM ##FKTable tab1
--WHERE --ParentTable NOT IN (SELECT ChildTable FROM ##FKTable) AND
--ParentTable in ('ListDomain')

OPEN FKHierarchy_Cursor
FETCH NEXT FROM FKHierarchy_Cursor INTO @RootTable

WHILE @@FETCH_STATUS = 0
BEGIN
----------------------------------- Get Table Hierarchy -----------------------------------

	DECLARE @MemberRank INT = 0	
	
	INSERT INTO ##FKHeirarchy --(FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, RootTableNum, FKRank)
	SELECT NULL, NULL, NULL, ParentTable, ParentColumn, @GroupNum, @MemberRank
	FROM ##FKTable
	WHERE ParentTable = @RootTable
	UNION
	SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum, @MemberRank + 1
	FROM ##FKTable
	WHERE ParentTable = @RootTable

	WHILE EXISTS (SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @MemberRank + 2
					FROM ##FKTable 
					WHERE ParentTable IN (SELECT ChildTable FROM ##FKHeirarchy WHERE FKRank = @MemberRank))
	BEGIN

		INSERT INTO ##FKHeirarchy-- (FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, RootTableNum, FKRank)
		SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum,
				@MemberRank + 1
		FROM ##FKTable 
		WHERE ParentTable IN (SELECT ChildTable FROM ##FKHeirarchy WHERE FKRank = @MemberRank)
		AND FKConstraint NOT IN (SELECT FKConstraint FROM ##FKHeirarchy WHERE FKConstraint IS NOT NULL)

		SET @MemberRank += 1
	END

	SET @GroupNum += 1

	FETCH NEXT FROM FKHierarchy_Cursor INTO @RootTable

END

CLOSE FKHierarchy_Cursor
DEALLOCATE FKHierarchy_Cursor;

DROP TABLE IF EXISTS ##ProblemTables

SELECT DISTINCT FKConstraint, ParentTable, ParentColumn,
table_schema AS ChildSchema, ChildTable, ChildColumn, 
'ALTER TABLE ' + table_schema + '.' + ChildTable + ' NOCHECK CONSTRAINT ' + FKConstraint AS DisableFK
INTO ##ProblemTables
FROM ##FKHeirarchy h1 
JOIN INFORMATION_SCHEMA.tables tab ON tab.table_name = h1.ChildTable 
WHERE ParentTable = ChildTable OR 
 EXISTS (SELECT * FROM ##FKHeirarchy h2 WHERE ParentTable 
IN (SELECT ChildTable FROM ##FKHeirarchy WHERE ParentTable = h2.ChildTable)
AND h1.ParentTable = h2.ParentTable AND h1.ChildTable = h2.ChildTable);

WITH CTE AS
(SELECT *
FROM ##FKHeirarchy h
WHERE EXISTS (SELECT * FROM ##ProblemTables p WHERE p.ParentTable = h.ParentTable
AND p.ChildTable = h.ChildTable)
)
DELETE FROM CTE 

DROP TABLE IF EXISTS ##RankTab

SELECT DISTINCT ChildTable, MIN(FKRank) AS FKRank, 
NULL AS ParentRank, CAST(NULL AS NVARCHAR(800)) AS ParentTables
INTO ##RankTab 
FROM ##FKHeirarchy 
GROUP BY ChildTable
ORDER BY FKRank

DECLARE @Count INT = 1

WHILE @Count < 50
BEGIN
	UPDATE ##RankTab
	SET ParentRank = src.ParentRank
	FROM ##RankTab targ
	JOIN
	(
	SELECT tmp.ChildTable, MAX(tmp.ParentRank) ParentRank
	FROM (
	SELECT rt1.ChildTable , h.ParentTable,
	(SELECT FKRank--MaxRankAsChild 
	FROM ##RankTab WHERE ChildTable = h.ParentTable)  AS ParentRank
	FROM ##FKHeirarchy h
	JOIN ##RankTab  rt1 ON rt1.ChildTable = h.ChildTable
	) tmp 
	JOIN ##RankTab rt  ON rt.ChildTable = tmp.ChildTable
	GROUP BY tmp.ChildTable
	) src
	ON targ.ChildTable = src.ChildTable


	UPDATE ##RankTab
	SET FKRank =  ParentRank + 1
	WHERE ParentRank IS NOT NULL AND
	FKRank <= ParentRank

	SET @Count += 1

END

UPDATE ##RankTab
SET ParentTables = (SELECT STRING_AGG(ParentTable, ', ') FROM (SELECT DISTINCT parentTable FROM ##FKHeirarchy WHERE ChildTable = tab.ChildTable) tmp)
FROM ##RankTab tab

SET @SQL = 'SELECT * FROM ##RankTab ORDER BY FKRank'

IF EXISTS (SELECT * FROM ##ProblemTables)
BEGIN

	SELECT * FROM ##ProblemTables ORDER BY ParentTable

	PRINT 'Use the folling query to view the foreign key heirarchy for all tables within this database ordered by the FKRank: '
	PRINT CHAR(10) + @SQL + CHAR(10)
	PRINT 'IF Deleting from tables you MUST disable the foreign keys listed in the results tab first' 
END


/*

ALTER TABLE dbo.InlineInspection NOCHECK CONSTRAINT FK_BaseILI_ILI
ALTER TABLE dbo.Stg_ILI NOCHECK CONSTRAINT FK_BaseStgILI_ILI
ALTER TABLE dbo.InlineInspection NOCHECK CONSTRAINT FK_InlineInspection_Stg_ILI
ALTER TABLE dbo.Stg_ILI NOCHECK CONSTRAINT FK_Stg_ILI_InlineInspectionId

 SELECT 'DELETE FROM ' + ChildTable FROM ##RankTab ORDER BY FKRank DESC

SELECT DISTINCT FKConstraint, ParentTable, ParentColumn,
table_schema AS ChildSchema, ChildTable, ChildColumn, 
'ALTER TABLE ' + table_schema + '.' + ChildTable + ' NOCHECK CONSTRAINT ' + FKConstraint AS DisableFK
FROM ##FKHeirarchy h1 
JOIN INFORMATION_SCHEMA.tables tab ON tab.table_name = h1.ChildTable 

SELECT * FROM ##ProblemTables

select *, 'DELETE FROM ' + ChildTable from ##RankTab  --WHERE ChildTable like 'InlineInspection%'
order by MaxRankAsChild desc

select * --, ROW_NUMBER() OVER (PARTITION BY ChildTable ORDER BY RootTableNum, FKRank) rownum
from ##FKHeirarchy where ParentTable NOT LIKE 'risk%' and ChildTable not like 'risk%'
or parenttable is null
order by RootTableNum, FKRank
*/
