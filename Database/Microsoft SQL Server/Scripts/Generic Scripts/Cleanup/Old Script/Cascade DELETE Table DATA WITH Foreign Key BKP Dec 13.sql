/*
This script disables all foreign key constraints. THEN after the user deletes data from a table or set of 
tables, will cascade delete all referencing data. 
*/

DECLARE @SQL NVARCHAR(MAX)
DECLARE @Id INT
DECLARE @RootTable VARCHAR(200) 
DECLARE @NewRoot VARCHAR(200)
DECLARE @TargetTable VARCHAR(200)
DECLARE @TargetColumn VARCHAR(100) 
DECLARE @TargetDeleteStmt VARCHAR(MAX)
DECLARE @FKName VARCHAR(200)
DECLARE @TotalRowsDeleted INT 
DECLARE @Count INT
DROP TABLE IF EXISTS #FKHeirarchy;
DROP TABLE IF EXISTS #DeleteFromParentTable;
DROP TABLE IF EXISTS #ErrorTable;
DROP TABLE IF EXISTS #ProblemTables
DROP TABLE IF EXISTS #RankTab;
DROP TABLE IF EXISTS #FKTable


--****************************************** SET VARIABLES ******************************************************

--**** NOTE **** This section needs to be modified as desired


-- Choose initial table to delete data from. Data from tables that are related to the deleted table data below will also be deleted
SET @TargetDeleteStmt = 'DELETE FROM DischargeSubsystem WHERE SourceId NOT IN (''LineLoopId1000'', ''LineLoopId1100'', ''LineLoopId1200'', ''LineLoopId1200'', ''LineLoopId1500'', ''LineLoopId1600'', ''LineLoopId1900'', ''LineLoopId2400'', ''LineLoopId2600'', ''LineLoopId2800'', ''LineLoopId3000'', ''LineLoopId3000'', ''LineLoopId3500'', ''LineLoopId4000'', ''LineLoopId4600'', ''LineLoopId4800'', ''LineLoopId4800'', ''LineLoopId4900'', ''LineLoopId5600'', ''LineLoopId5700'', ''LineLoopId6200'', ''LineLoopId6300'', ''LineLoopId6400'', ''LineLoopId6500'', ''LineLoopId6600'', ''LineLoopId6700'', ''LineLoopId6800'', ''LineLoopId6900'', ''LineLoopId69100'', ''LineLoopId69200'', ''LineLoopId85100'', ''LineLoopId85200'', ''LineLoopId85500'', ''LineLoopId85600'', ''LineLoopId85700'', ''LineLoopId85800'', ''LineLoopId85900'', ''LineLoopId86100'', ''LineLoopId86500'', ''LineLoopId86700'', ''LineLoopId87000'', ''LineLoopId87200'', ''LineLoopId87300'', ''LineLoopId87500'', ''LineLoopId87600'', ''LineLoopId87800'', ''LineLoopId88200'', ''LineLoopId88300'', ''LineLoopId88500'', ''LineLoopId88900'', ''LineLoopId89300'', ''LineLoopId89500'', ''LineLoopId89900'', ''LineLoopId90000'', ''LineLoopId91000'', ''LineLoopId91300'', ''LineLoopId91400'', ''LineLoopId91500'', ''LineLoopId91600'', ''LineLoopId91700'', ''LineLoopId91800'', ''LineLoopId92300'', ''LineLoopId92400'', ''LineLoopId92700'', ''LineLoopId92800'', ''LineLoopId92900'', ''LineLoopId93000'', ''LineLoopId93500'', ''LineLoopId93900'', ''LineLoopId94000'', ''LineLoopId94100'', ''LineLoopId94400'', ''LineLoopId94700'', ''LineLoopId94900'', ''LineLoopId95200'', ''LineLoopId95300'', ''LineLoopId95600'', ''LineLoopId95700'', ''LineLoopId123500'', ''LineLoopId124400'', ''LineLoopId130100'', ''LineLoopId145800'', ''LineLoopId145900'', ''LineLoopId146000'', ''LineLoopId147600'', ''LineLoopId147700'', ''LineLoopId147800'', ''LineLoopId147900'', ''LineLoopId148400'', ''LineLoopId148500'', ''LineLoopId148800'', ''LineLoopId154000'', ''LineLoopId155000'', ''LineLoopId156000'', ''LineLoopId156400'', ''LineLoopId160200'', ''LineLoopId160300'', ''LineLoopId161500'', ''LineLoopId162300'', ''LineLoopId162400'', ''LineLoopId162500'', ''LineLoopId162600'', ''LineLoopId162700'', ''LineLoopId162800'', ''LineLoopId162900'', ''LineLoopId163000'', ''LineLoopId163100'', ''LineLoopId163300'', ''LineLoopId163400'', ''LineLoopId163700'', ''LineLoopId164200'', ''LineLoopId167000'', ''LineLoopId167600'', ''LineLoopId167700'', ''LineLoopId167900'', ''LineLoopId168100'', ''LineLoopId168800'', ''LineLoopId169000'', ''LineLoopId169200'', ''LineLoopId170000'', ''LineLoopId170100'', ''LineLoopId170200'', ''LineLoopId170300'', ''LineLoopId171700'', ''LineLoopId171900'', ''LineLoopId172700'', ''LineLoopId172800'', ''LineLoopId173300'', ''LineLoopId173900'', ''LineLoopId174400'', ''LineLoopId174600'', ''LineLoopId175200'', ''LineLoopId175300'', ''LineLoopId176000'', ''LineLoopId176600'', ''LineLoopId182200'', ''LineLoopId182300'', ''LineLoopId183000'', ''LineLoopId184200'', ''LineLoopId184300'', ''LineLoopId184600'', ''LineLoopId184700'', ''LineLoopId184700'', ''LineLoopId185100'', ''LineLoopId185200'', ''LineLoopId185900'', ''LineLoopId186300'', ''LineLoopId186600'', ''LineLoopId186700'', ''LineLoopId1300'', ''LineLoopId1400'', ''LineLoopId1400'', ''LineLoopId1700'', ''LineLoopId1800'', ''LineLoopId2000'', ''LineLoopId2100'', ''LineLoopId2200'', ''LineLoopId2300'', ''LineLoopId2300'', ''LineLoopId2500'', ''LineLoopId2700'', ''LineLoopId2700'', ''LineLoopId2900'', ''LineLoopId3100'', ''LineLoopId3300'', ''LineLoopId3400'', ''LineLoopId3700'', ''LineLoopId3800'', ''LineLoopId3900'', ''LineLoopId4100'', ''LineLoopId4200'', ''LineLoopId4300'', ''LineLoopId4400'', ''LineLoopId4500'', ''LineLoopId4700'', ''LineLoopId5500'', ''LineLoopId5900'', ''LineLoopId6000'', ''LineLoopId6100'', ''LineLoopId7000'', ''LineLoopId7100'', ''LineLoopId48400'', ''LineLoopId48400'', ''LineLoopId48400'', ''LineLoopId48500'', ''LineLoopId48500'', ''LineLoopId48500'', ''LineLoopId48500'', ''LineLoopId48500'', ''LineLoopId48500'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48600'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48700'', ''LineLoopId48800'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId48900'', ''LineLoopId49000'', ''LineLoopId49000'', ''LineLoopId49100'', ''LineLoopId49100'', ''LineLoopId69700'', ''LineLoopId84800'', ''LineLoopId84900'', ''LineLoopId85000'', ''LineLoopId85100'', ''LineLoopId85100'', ''LineLoopId85200'', ''LineLoopId85200'', ''LineLoopId85200'', ''LineLoopId85300'', ''LineLoopId85300'', ''LineLoopId85400'', ''LineLoopId86000'', ''LineLoopId86200'', ''LineLoopId86300'', ''LineLoopId86300'', ''LineLoopId86400'', ''LineLoopId86600'', ''LineLoopId86600'', ''LineLoopId86600'', ''LineLoopId86800'', ''LineLoopId86900'', ''LineLoopId87100'', ''LineLoopId87400'', ''LineLoopId87600'', ''LineLoopId87600'', ''LineLoopId87900'', ''LineLoopId88000'', ''LineLoopId88100'', ''LineLoopId88400'', ''LineLoopId88600'', ''LineLoopId88700'', ''LineLoopId88800'', ''LineLoopId89000'', ''LineLoopId89100'', ''LineLoopId89200'', ''LineLoopId89400'', ''LineLoopId89600'', ''LineLoopId89700'', ''LineLoopId90000'', ''LineLoopId90000'', ''LineLoopId91000'', ''LineLoopId91000'', ''LineLoopId91000'', ''LineLoopId91000'', ''LineLoopId91100'', ''LineLoopId92000'', ''LineLoopId92100'', ''LineLoopId92200'', ''LineLoopId92500'', ''LineLoopId92600'', ''LineLoopId93100'', ''LineLoopId93300'', ''LineLoopId93400'', ''LineLoopId94200'', ''LineLoopId94300'', ''LineLoopId94500'', ''LineLoopId94600'', ''LineLoopId94700'', ''LineLoopId94700'', ''LineLoopId95400'', ''LineLoopId122100'', ''LineLoopId122200'', ''LineLoopId122300'', ''LineLoopId122400'', ''LineLoopId122500'', ''LineLoopId122600'', ''LineLoopId122700'', ''LineLoopId122800'', ''LineLoopId122900'', ''LineLoopId123700'', ''LineLoopId123800'', ''LineLoopId131300'', ''LineLoopId132500'', ''LineLoopId132600'', ''LineLoopId132700'', ''LineLoopId137700'', ''LineLoopId141700'', ''LineLoopId141800'', ''LineLoopId141900'', ''LineLoopId142100'', ''LineLoopId143300'', ''LineLoopId143500'', ''LineLoopId146100'', ''LineLoopId146600'', ''LineLoopId146900'', ''LineLoopId147100'', ''LineLoopId147100'', ''LineLoopId147200'', ''LineLoopId147200'', ''LineLoopId147300'', ''LineLoopId147300'', ''LineLoopId148000'', ''LineLoopId148000'', ''LineLoopId148000'', ''LineLoopId148000'', ''LineLoopId148200'', ''LineLoopId148700'', ''LineLoopId149000'', ''LineLoopId149800'', ''LineLoopId149900'', ''LineLoopId150000'', ''LineLoopId150100'', ''LineLoopId150100'', ''LineLoopId150100'', ''LineLoopId150200'', ''LineLoopId150200'', ''LineLoopId150200'', ''LineLoopId150700'', ''LineLoopId150800'', ''LineLoopId151100'', ''LineLoopId151300'', ''LineLoopId151600'', ''LineLoopId153000'', ''LineLoopId156300'', ''LineLoopId159000'', ''LineLoopId159600'', ''LineLoopId159700'', ''LineLoopId160100'', ''LineLoopId160200'', ''LineLoopId160200'', ''LineLoopId160200'', ''LineLoopId160200'', ''LineLoopId160200'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160300'', ''LineLoopId160400'', ''LineLoopId160600'', ''LineLoopId161400'', ''LineLoopId161500'', ''LineLoopId161800'', ''LineLoopId161900'', ''LineLoopId162000'', ''LineLoopId162200'', ''LineLoopId162300'', ''LineLoopId162300'', ''LineLoopId162300'', ''LineLoopId162500'', ''LineLoopId162600'', ''LineLoopId162600'', ''LineLoopId162600'', ''LineLoopId162600'', ''LineLoopId162700'', ''LineLoopId162700'', ''LineLoopId162700'', ''LineLoopId162700'', ''LineLoopId162800'', ''LineLoopId162800'', ''LineLoopId162900'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163000'', ''LineLoopId163200'', ''LineLoopId163500'', ''LineLoopId163600'', ''LineLoopId164000'', ''LineLoopId164400'', ''LineLoopId164700'', ''LineLoopId165300'', ''LineLoopId166200'', ''LineLoopId166400'', ''LineLoopId166500'', ''LineLoopId166600'', ''LineLoopId166900'', ''LineLoopId167800'', ''LineLoopId167800'', ''LineLoopId168900'', ''LineLoopId169400'', ''LineLoopId172900'', ''LineLoopId173400'', ''LineLoopId173500'', ''LineLoopId174900'', ''LineLoopId175500'', ''LineLoopId177300'', ''LineLoopId177600'', ''LineLoopId177700'', ''LineLoopId178000'', ''LineLoopId178100'', ''LineLoopId179200'', ''LineLoopId179800'', ''LineLoopId179900'', ''LineLoopId180000'', ''LineLoopId180400'', ''LineLoopId180900'', ''LineLoopId181000'', ''LineLoopId181100'', ''LineLoopId181200'', ''LineLoopId181300'', ''LineLoopId181400'', ''LineLoopId181500'', ''LineLoopId181600'', ''LineLoopId181700'', ''LineLoopId181900'', ''LineLoopId182000'', ''LineLoopId182100'', ''LineLoopId183100'', ''LineLoopId183500'', ''LineLoopId183600'', ''LineLoopId184000'', ''LineLoopId184400'', ''LineLoopId184800'', ''LineLoopId185500'', ''LineLoopId185600'', ''LineLoopId185700'', ''LineLoopId185800'', ''LineLoopId186100'', ''LineLoopId186200'')'

-- SET the root table that is at the top of the foreign key heirarchy
SET @RootTable = 'Corporation'

--************************************************************************************************************

------------------------------------------ Generate Foreign Key Hierarchy --------------------

CREATE TABLE #ErrorTable (Cmd NVARCHAR(MAX), ErrMsg NVARCHAR(MAX));

CREATE TABLE #FKHeirarchy (Id INT IDENTITY(1,1),
							FKConstraint NVARCHAR(100),
						   ParentTable NVARCHAR(100),
						   ParentColumn NVARCHAR(100),
						   ChildTable NVARCHAR(100), 
						   ChildColumn NVARCHAR(100),
						   RootTableNum INT,
						   FKRank INT)

DECLARE @GroupNum INT = 1


-- Get list of foreign key relationships (NOTE** Risk tables are excluded for clarity during testing)
SELECT OBJECT_NAME(fkc.constraint_object_id) AS FKConstraint,
	   SCHEMA_NAME(t2.schema_id) AS ParentSchema,
	   OBJECT_NAME(fkc.referenced_object_id) AS ParentTable,
	   COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn,
	   SCHEMA_NAME(t1.schema_id) AS ChildSchema,
	   OBJECT_NAME(fkc.parent_object_id) AS ChildTable,
	   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
	   kcu.ordinal_position
INTO #FKTable
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id


-- Construct foreign key heirarchy
DECLARE FKHierarchy_Cursor CURSOR FOR
SELECT DISTINCT ParentTable
FROM #FKTable tab1
WHERE ParentTable IN (SELECT OBJECT_NAME(referenced_object_id) FROM sys.foreign_keys 
) 

OPEN FKHierarchy_Cursor
FETCH NEXT FROM FKHierarchy_Cursor INTO @NewRoot

WHILE @@FETCH_STATUS = 0
BEGIN
----------------------------------- Get Table Hierarchy -----------------------------------

	DECLARE @MemberRank INT = 0	
	
	INSERT INTO #FKHeirarchy --(FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, RootTableNum, FKRank)
	SELECT NULL, NULL, NULL, ParentTable, ParentColumn, @GroupNum, @MemberRank
	FROM #FKTable
	WHERE ParentTable = @NewRoot
	UNION
	SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum, @MemberRank + 1
	FROM #FKTable
	WHERE ParentTable = @NewRoot

	WHILE EXISTS (SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @MemberRank + 2
					FROM #FKTable 
					WHERE ParentTable IN (SELECT ChildTable FROM #FKHeirarchy WHERE FKRank = @MemberRank))
	BEGIN

		INSERT INTO #FKHeirarchy
		SELECT FKConstraint, ParentTable, ParentColumn, ChildTable, ChildColumn, @GroupNum,
				@MemberRank + 1
		FROM #FKTable 
		WHERE ParentTable IN (SELECT ChildTable FROM #FKHeirarchy WHERE FKRank = @MemberRank)
		AND FKConstraint NOT IN (SELECT FKConstraint FROM #FKHeirarchy WHERE FKConstraint IS NOT NULL)

		SET @MemberRank += 1
	END

	SET @GroupNum += 1

	FETCH NEXT FROM FKHierarchy_Cursor INTO @NewRoot

END

CLOSE FKHierarchy_Cursor
DEALLOCATE FKHierarchy_Cursor;


-- Find tables with self-referencing foreign keys or child tables that are referenced by their parent table
SELECT DISTINCT FKConstraint, ParentTable, ParentColumn,
table_schema AS ChildSchema, ChildTable, ChildColumn, 
'ALTER TABLE ' + table_schema + '.' + ChildTable + ' NOCHECK CONSTRAINT ' + FKConstraint AS [Disable Self-Referencing Foreign Keys]
INTO #ProblemTables
FROM #FKHeirarchy h1 
JOIN INFORMATION_SCHEMA.tables tab ON tab.table_name = h1.ChildTable 
WHERE ParentTable = ChildTable OR 
 EXISTS (SELECT * FROM #FKHeirarchy h2 WHERE ParentTable 
IN (SELECT ChildTable FROM #FKHeirarchy WHERE ParentTable = h2.ChildTable)
AND h1.ParentTable = h2.ParentTable AND h1.ChildTable = h2.ChildTable);

-- Use temporary table to rank child tables based on foreign key heirarchy
WITH CTE AS
(SELECT DISTINCT p.ParentTable GParent,
c.FKConstraint, c.ParentTable, c.ChildTable, p.FKRank ParentRank, c.FKRank ChildRank, 
p.FKRank + 1 AS TrueRank
, ROW_NUMBER() OVER (PARTITION BY c.ChildTable ORDER BY p.FKRank DESC) fltr
FROM #FKHeirarchy p
JOIN #FKHeirarchy c ON p.ChildTable = c.ParentTable
)
SELECT * INTO #RankTab
FROM CTE 
WHERE fltr = 1

SET @Count = 1

-- Re-sort child tables based on parent table rank 
WHILE @Count < 100
BEGIN
	UPDATE #RankTab
	SET ParentRank = src.ParentRank
	FROM #RankTab targ
	JOIN
	(
	SELECT tmp.ChildTable, MAX(tmp.ParentRank) ParentRank
	FROM (
	SELECT rt1.ChildTable , h.ParentTable,
	(SELECT TrueRank FROM #RankTab WHERE ChildTable = h.ParentTable)  AS ParentRank
	FROM #FKHeirarchy h
	JOIN #RankTab  rt1 ON rt1.ChildTable = h.ChildTable
	) tmp 
	JOIN #RankTab rt  ON rt.ChildTable = tmp.ChildTable
	GROUP BY tmp.ChildTable
	) src
	ON targ.ChildTable = src.ChildTable


	UPDATE #RankTab
	SET TrueRank =  ParentRank + 1
	WHERE ParentRank IS NOT NULL AND
	TrueRank <= ParentRank

	SET @Count += 1

END

INSERT INTO #RankTab
SELECT DISTINCT NULL, NULL, NULL, OBJECT_NAME(referenced_object_id), NULL, 0, 0, 1
FROM sys.foreign_keys 
WHERE referenced_object_id NOT IN (SELECT parent_object_id FROM sys.foreign_keys)
AND OBJECT_NAME(referenced_object_id) NOT IN (SELECT ChildTable FROM #RankTab)

DROP TABLE IF EXISTS #FKRank
SELECT ROW_NUMBER() OVER (ORDER BY TrueRank) Id, * 
INTO #FKRank FROM #RankTab

-------------------------------- Disable Foreign Keys ---------------------------

IF OBJECT_ID('Tempdb..#ForeignKeys') IS NULL
BEGIN
	SELECT OBJECT_NAME(fkc.constraint_object_id) FKConstraint, 
		   OBJECT_NAME(fkc.parent_object_id) TableName,
		   'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
			+ ' WITH NOCHECK NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS DisableFKCmd, 
			'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
			+ ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS EnableFKCmd,
			CASE WHEN is_disabled = 0 THEN 'Enabled' ELSE 'Disabled' END AS Status
	INTO #ForeignKeys
	FROM sys.foreign_key_columns fkc
	JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
	WHERE is_disabled = 0
END

-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT FKConstraint, DisableFKCmd FROM #ForeignKeys

OPEN DiableFK_Cursor
FETCH NEXT FROM DiableFK_Cursor INTO @FKName, @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		EXECUTE (@SQL)


		UPDATE #ForeignKeys SET Status = (CASE WHEN sfk.is_disabled = 1 THEN 'Disabled' ELSE 'Enabled' END)
		FROM #ForeignKeys fk
		JOIN sys.foreign_keys sfk ON fk.FKConstraint = sfk.name
		WHERE FKConstraint = @FKName
	END TRY
	BEGIN CATCH
		PRINT @SQL;
		THROW
	END CATCH

	FETCH NEXT FROM DiableFK_Cursor INTO @FKName, @SQL
END

CLOSE DiableFK_Cursor
DEALLOCATE DiableFK_Cursor;

-------------------------------------- Cascade Delete Data from Referencing Tables --------------------------------

IF OBJECT_ID('Tmp_DeleteFromTablesList') IS NULL
BEGIN
	WITH CTE AS(
	SELECT rt.*, OBJECT_NAME(fkc.referenced_object_id) ParentTab,
	COL_NAME(fkc.referenced_object_id,fkc.referenced_column_id) ParentCol,
	COL_NAME(fkc.parent_object_id, parent_column_id) ChildCol,
	OBJECT_NAME(fkc.constraint_object_id) AS constraint_name
	FROM #FKRank rt
	JOIN sys.foreign_key_columns fkc
	ON rt.ChildTable = OBJECT_NAME(fkc.parent_object_id)
	)
	SELECT IDENTITY(INT, 1,1) AS Id,
		   constraint_name AS FKConstraint,
		   ChildTable AS TargetTable, 
		   ChildCol AS TargetColumn, 
		   ParentTab AS ParentTable, 
		   ParentCol AS ParentColumn, 
		   NULL AS TargetNumRowsDeleted,
		   NULL AS ParentNumRowsDeleted,
		   CAST(NULL AS NVARCHAR(MAX)) DeleteFromTarget,
		   CAST(NULL AS NVARCHAR(MAX)) AS DeleteFromParent,
		   'ALTER TABLE ' + ChildTable + ' NOCHECK CONSTRAINT ' + constraint_name AS DisableConstraint,
		   	TrueRank AS FKRank,
			ChildRank, 
			ParentRank
	INTO Tmp_DeleteFromTablesList
	FROM CTE;
END;

-- Generate delete statements for child tables 
WITH CTE AS (
SELECT DISTINCT FKConstraint, TargetTable, ParentTable, 'WITH CTE AS (SELECT * FROM ' + TargetTable 
+ ' c WHERE NOT EXISTS (SELECT * FROM ' + ParentTable + ' p WHERE ' + (SELECT STUFF(
				(SELECT '  p.'  + ct.ParentColumn + ' = c.' + ct.TargetColumn + ' AND'
				FROM Tmp_DeleteFromTablesList ct
				WHERE pt.FKConstraint = ct.FKConstraint
				FOR XML PATH('')
				), 1, 2, ''
			)) + ') AND' + (SELECT STUFF(
				(SELECT '   c.' + ct.TargetColumn + ' IS NOT NULL AND'
				FROM Tmp_DeleteFromTablesList ct
				WHERE pt.FKConstraint = ct.FKConstraint
				FOR XML PATH('')
				), 1, 2, ''
			)) + ') DELETE FROM CTE' AS DeleteCmd
FROM Tmp_DeleteFromTablesList pt
) 
UPDATE Tmp_DeleteFromTablesList 
SET DeleteFromTarget = REPLACE(REPLACE(REPLACE(DeleteCmd, ' AND NOT EXISTS ()', '  '), ' AND)', ')'), ' OR)', ')')
FROM CTE 
JOIN Tmp_DeleteFromTablesList dl
ON dl.FKConstraint = cte.FKConstraint;

------ Generate delete statements for parent tables
WITH CTE AS (
SELECT DISTINCT ParentTable, 'WITH CTE AS (SELECT * FROM ' + ParentTable + ' p WHERE NOT EXISTS (' 
+ (SELECT STUFF(
				(SELECT DISTINCT'  SELECT * FROM ' + ct.TargetTable + ' c WHERE ' 
				+ (SELECT STUFF(
								(SELECT '  c.' + cct.TargetColumn + ' = p.' + cct.ParentColumn 
								+ CASE WHEN (SELECT COUNT(DISTINCT TargetColumn) FROM Tmp_DeleteFromTablesList cs WHERE cs.TargetTable = ct.TargetTable 
									AND cs.ParentTable = ct.ParentTable AND cs.ParentColumn = ct.ParentColumn) = 1 THEN ' AND' ELSE ' OR' END
								FROM Tmp_DeleteFromTablesList cct
								WHERE cct.FKConstraint = ct.FKConstraint
								FOR XML PATH('')
								), 1, 2, ''
							)
					) 
				+ ') AND EXISTS (SELECT * FROM ' + ct.TargetTable + ') AND NOT EXISTS ('
				FROM Tmp_DeleteFromTablesList ct
				WHERE ct.ParentTable = pt.ParentTable
				FOR XML PATH('')
				), 1, 2, ''
			)) + ')' + ') DELETE FROM CTE' AS DeleteCmd
FROM Tmp_DeleteFromTablesList pt
)
UPDATE Tmp_DeleteFromTablesList 
SET DeleteFromParent = REPLACE(REPLACE(REPLACE(DeleteCmd, ' AND NOT EXISTS ()', '  '), ' AND)', ')'), ' OR)', ')')
FROM CTE 
JOIN Tmp_DeleteFromTablesList dl
ON dl.ParentTable = cte.ParentTable;

-- Get Tablename from @TargetDeleteStmt variable
SELECT @TargetTable = SUBSTRING(@TargetDeleteStmt, CHARINDEX('DELETE FROM ', @TargetDeleteStmt) + 12,  
	CASE WHEN CHARINDEX('WHERE', @TargetDeleteStmt) - (CHARINDEX('DELETE FROM ', @TargetDeleteStmt) + 12 ) > 0 
		THEN CHARINDEX('WHERE', @TargetDeleteStmt) - (CHARINDEX('DELETE FROM ', @TargetDeleteStmt) + 12 ) 
		ELSE LEN(@TargetDeleteStmt)
	END
	)

SELECT @TargetTable = LTRIM(RTRIM(@TargetTable))

-- Get column name from TargetDeleteStmt

SET @TargetColumn = LTRIM(SUBSTRING(@TargetDeleteStmt, CHARINDEX(CHAR(32), @TargetDeleteStmt, CHARINDEX('WHERE', @TargetDeleteStmt)), LEN(@TargetDeleteStmt)))
SET @TargetColumn = SUBSTRING(@TargetColumn, 1, CHARINDEX(CHAR(32), @TargetColumn) - 1)

-- Add the delete statement set at start fo script to table
IF EXISTS (SELECT * FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable AND ParentTable IS NULL)
BEGIN
	UPDATE Tmp_DeleteFromTablesList 
	SET FKRank = (SELECT MAX(FKRank) FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable),
		ChildRank = (SELECT MAX(ChildRank) FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable),
		DeleteFromTarget = @TargetDeleteStmt
	FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable AND ParentTable IS NULL 
END
ELSE
BEGIN
	INSERT INTO Tmp_DeleteFromTablesList (TargetTable, FKRank, ChildRank, DeleteFromTarget)
	SELECT DISTINCT @TargetTable TargetTable, FKRank, ChildRank, @TargetDeleteStmt DeleteFromTarget
	FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable
END

-------------------------------------------- Delete from Target/Child tables -----------------------------------------

DECLARE Delete_Cursor CURSOR FOR
SELECT DeleteFromTarget 
FROM Tmp_DeleteFromTablesList 
ORDER BY FKRank, ChildRank ASC;


SET @TotalRowsDeleted = 0
SET @Count = 0

OPEN Delete_Cursor
FETCH NEXT FROM Delete_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		
		
		BEGIN TRAN

			EXECUTE (@SQL)

			SET @Count = @@ROWCOUNT

			SET @TotalRowsDeleted += @Count

			UPDATE Tmp_DeleteFromTablesList
			SET TargetNumRowsDeleted = COALESCE(TargetNumRowsDeleted, 0) + @Count
			WHERE DeleteFromTarget = @SQL

		COMMIT TRAN 

	END TRY
	BEGIN CATCH
		INSERT INTO #ErrorTable
		SELECT @SQL, ERROR_MESSAGE()
		WHERE @SQL NOT IN (SELECT Cmd FROM #ErrorTable);

		PRINT @SQL;

	END CATCH

	FETCH NEXT FROM Delete_Cursor INTO @SQL
END

CLOSE Delete_Cursor
DEALLOCATE Delete_Cursor;

SELECT @TotalRowsDeleted AS 'Total Deleted Child Table Rows'
PRINT 'A total of ' + CAST(@TotalRowsDeleted AS NVARCHAR) + ' rows have been deleted from child/target tables';

-------------------------------------- Delete from parent table -----------------------------------------------------

DECLARE Delete_Cursor CURSOR FOR
SELECT DISTINCT DeleteFromParent 
FROM Tmp_DeleteFromTablesList 

SET @count = 0
SET @TotalRowsDeleted = 0

OPEN Delete_Cursor
FETCH NEXT FROM Delete_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRY
		BEGIN TRAN
			EXECUTE (@SQL)
		
		SET @Count = @@ROWCOUNT

		SET @TotalRowsDeleted += @Count

		UPDATE Tmp_DeleteFromTablesList
		SET ParentNumRowsDeleted = COALESCE(ParentNumRowsDeleted, 0) + @Count
		WHERE DeleteFromParent = @SQL

	COMMIT TRAN

	END TRY
	BEGIN CATCH
		PRINT @SQL;
		INSERT INTO #ErrorTable
		SELECT @SQL, ERROR_MESSAGE()
		WHERE @SQL NOT IN (SELECT Cmd FROM #ErrorTable);

	END CATCH


	FETCH NEXT FROM Delete_Cursor INTO @SQL
END

CLOSE Delete_Cursor
DEALLOCATE Delete_Cursor;

SELECT @TotalRowsDeleted AS 'Total Deleted Parent Table Rows'
PRINT 'A total of ' + CAST(@TotalRowsDeleted AS NVARCHAR) + ' rows have been deleted from parent tables';

----------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE EnableFK_Cursor CURSOR FOR
SELECT FKConstraint, EnableFKCmd 
FROM #ForeignKeys
WHERE Status = 'Disabled'

OPEN EnableFK_Cursor
FETCH NEXT FROM EnableFK_Cursor INTO @FKName, @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY

		EXECUTE (@SQL);

		UPDATE #ForeignKeys SET Status = (CASE WHEN sfk.is_disabled = 1 THEN 'Disabled' ELSE 'Enabled' END)
		FROM #ForeignKeys fk
		JOIN sys.foreign_keys sfk ON fk.FKConstraint = sfk.name

	END TRY
	BEGIN CATCH
		INSERT INTO #ErrorTable 
		SELECT @SQL, ERROR_MESSAGE()
		WHERE @SQL NOT IN (SELECT Cmd FROM #ErrorTable);

		PRINT @SQL;

	END CATCH

	FETCH NEXT FROM EnableFK_Cursor INTO @FKName, @SQL
END

CLOSE EnableFK_Cursor
DEALLOCATE EnableFK_Cursor;

IF EXISTS (SELECT * FROM #ErrorTable)
BEGIN
	SELECT * FROM #ErrorTable
END
ELSE IF EXISTS (SELECT * FROM Tmp_DeleteFromTablesList WHERE TargetNumRowsDeleted IS NOT NULL AND TargetNumRowsDeleted <> 0 
				OR ParentNumRowsDeleted IS NOT NULL AND ParentNumRowsDeleted <> 0)
BEGIN
	SELECT * FROM Tmp_DeleteFromTablesList WHERE (TargetNumRowsDeleted IS NOT NULL AND TargetNumRowsDeleted <> 0 OR
	ParentNumRowsDeleted IS NOT NULL AND ParentNumRowsDeleted <> 0
	) ORDER BY FKRank, ChildRank, TargetTable
END

