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
SET @TargetDeleteStmt = 'DELETE FROM DischargeSubsystem WHERE REPLACE(SourceId, ''LineLoopId'', '''')
IN (''1000'', ''1100'', ''1200'', ''1200'', ''1500'', ''1600'', ''1900'', ''2400'', ''2600'', ''2800'', ''3000'', ''3000'', ''3500'', ''4000'', ''4600'', ''4800'', ''4800'', ''4900'', ''5600'', ''5700'', ''6200'', ''6300'', ''6400'', ''6500'', ''6600'', ''6700'', ''6800'', ''6900'', ''69100'', ''69200'', ''85100'', ''85200'', ''85500'', ''85600'', ''85700'', ''85800'', ''85900'', ''86100'', ''86500'', ''86700'', ''87000'', ''87200'', ''87300'', ''87500'', ''87600'', ''87800'', ''88200'', ''88300'', ''88500'', ''88900'', ''89300'', ''89500'', ''89900'', ''90000'', ''91000'', ''91300'', ''91400'', ''91500'', ''91600'', ''91700'', ''91800'', ''92300'', ''92400'', ''92700'', ''92800'', ''92900'', ''93000'', ''93500'', ''93900'', ''94000'', ''94100'', ''94400'', ''94700'', ''94900'', ''95200'', ''95300'', ''95600'', ''95700'', ''123500'', ''124400'', ''130100'', ''145800'', ''145900'', ''146000'', ''147600'', ''147700'', ''147800'', ''147900'', ''148400'', ''148500'', ''148800'', ''154000'', ''155000'', ''156000'', ''156400'', ''160200'', ''160300'', ''161500'', ''162300'', ''162400'', ''162500'', ''162600'', ''162700'', ''162800'', ''162900'', ''163000'', ''163100'', ''163300'', ''163400'', ''163700'', ''164200'', ''167000'', ''167600'', ''167700'', ''167900'', ''168100'', ''168800'', ''169000'', ''169200'', ''170000'', ''170100'', ''170200'', ''170300'', ''171700'', ''171900'', ''172700'', ''172800'', ''173300'', ''173900'', ''174400'', ''174600'', ''175200'', ''175300'', ''176000'', ''176600'', ''182200'', ''182300'', ''183000'', ''184200'', ''184300'', ''184600'', ''184700'', ''184700'', ''185100'', ''185200'', ''185900'', ''186300'', ''186600'', ''186700'', ''1300'', ''1400'', ''1400'', ''1700'', ''1800'', ''2000'', ''2100'', ''2200'', ''2300'', ''2300'', ''2500'', ''2700'', ''2700'', ''2900'', ''3100'', ''3300'', ''3400'', ''3700'', ''3800'', ''3900'', ''4100'', ''4200'', ''4300'', ''4400'', ''4500'', ''4700'', ''5500'', ''5900'', ''6000'', ''6100'', ''7000'', ''7100'', ''48400'', ''48400'', ''48400'', ''48500'', ''48500'', ''48500'', ''48500'', ''48500'', ''48500'', ''48600'', ''48600'', ''48600'', ''48600'', ''48600'', ''48600'', ''48600'', ''48600'', ''48700'', ''48700'', ''48700'', ''48700'', ''48700'', ''48700'', ''48700'', ''48700'', ''48800'', ''48900'', ''48900'', ''48900'', ''48900'', ''48900'', ''48900'', ''48900'', ''48900'', ''49000'', ''49000'', ''49100'', ''49100'', ''69700'', ''84800'', ''84900'', ''85000'', ''85100'', ''85100'', ''85200'', ''85200'', ''85200'', ''85300'', ''85300'', ''85400'', ''86000'', ''86200'', ''86300'', ''86300'', ''86400'', ''86600'', ''86600'', ''86600'', ''86800'', ''86900'', ''87100'', ''87400'', ''87600'', ''87600'', ''87900'', ''88000'', ''88100'', ''88400'', ''88600'', ''88700'', ''88800'', ''89000'', ''89100'', ''89200'', ''89400'', ''89600'', ''89700'', ''90000'', ''90000'', ''91000'', ''91000'', ''91000'', ''91000'', ''91100'', ''92000'', ''92100'', ''92200'', ''92500'', ''92600'', ''93100'', ''93300'', ''93400'', ''94200'', ''94300'', ''94500'', ''94600'', ''94700'', ''94700'', ''95400'', ''122100'', ''122200'', ''122300'', ''122400'', ''122500'', ''122600'', ''122700'', ''122800'', ''122900'', ''123700'', ''123800'', ''131300'', ''132500'', ''132600'', ''132700'', ''137700'', ''141700'', ''141800'', ''141900'', ''142100'', ''143300'', ''143500'', ''146100'', ''146600'', ''146900'', ''147100'', ''147100'', ''147200'', ''147200'', ''147300'', ''147300'', ''148000'', ''148000'', ''148000'', ''148000'', ''148200'', ''148700'', ''149000'', ''149800'', ''149900'', ''150000'', ''150100'', ''150100'', ''150100'', ''150200'', ''150200'', ''150200'', ''150700'', ''150800'', ''151100'', ''151300'', ''151600'', ''153000'', ''156300'', ''159000'', ''159600'', ''159700'', ''160100'', ''160200'', ''160200'', ''160200'', ''160200'', ''160200'', ''160300'', ''160300'', ''160300'', ''160300'', ''160300'', ''160300'', ''160300'', ''160400'', ''160600'', ''161400'', ''161500'', ''161800'', ''161900'', ''162000'', ''162200'', ''162300'', ''162300'', ''162300'', ''162500'', ''162600'', ''162600'', ''162600'', ''162600'', ''162700'', ''162700'', ''162700'', ''162700'', ''162800'', ''162800'', ''162900'', ''163000'', ''163000'', ''163000'', ''163000'', ''163000'', ''163000'', ''163000'', ''163000'', ''163200'', ''163500'', ''163600'', ''164000'', ''164400'', ''164700'', ''165300'', ''166200'', ''166400'', ''166500'', ''166600'', ''166900'', ''167800'', ''167800'', ''168900'', ''169400'', ''172900'', ''173400'', ''173500'', ''174900'', ''175500'', ''177300'', ''177600'', ''177700'', ''178000'', ''178100'', ''179200'', ''179800'', ''179900'', ''180000'', ''180400'', ''180900'', ''181000'', ''181100'', ''181200'', ''181300'', ''181400'', ''181500'', ''181600'', ''181700'', ''181900'', ''182000'', ''182100'', ''183100'', ''183500'', ''183600'', ''184000'', ''184400'', ''184800'', ''185500'', ''185600'', ''185700'', ''185800'', ''186100'', ''186200'')
AND SourceId LIKE ''LineLoopId%'''

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
SELECT DISTINCT TargetTable, ParentTable, 'WITH CTE AS (SELECT * FROM ' + TargetTable 
+ ' C WHERE NOT EXISTS (SELECT * FROM ' + ParentTable + ' P WHERE ' + (SELECT STUFF(
				(SELECT '  p.'  + ct.ParentColumn + ' = c.' + ct.TargetColumn 
				+ CASE WHEN (SELECT COUNT(DISTINCT ParentColumn) FROM Tmp_DeleteFromTablesList cs WHERE cs.TargetTable = pt.TargetTable AND cs.ParentTable = pt.ParentTable) = 1 THEN ' OR' ELSE ' AND' END
				FROM Tmp_DeleteFromTablesList ct
				WHERE pt.TargetTable = ct.TargetTable
				AND pt.ParentTable = ct.ParentTable
				FOR XML PATH('')
				), 1, 2, ''
			)) + ') AND ' + (SELECT STUFF(
				(SELECT '  ' + ct.TargetColumn + ' IS NOT NULL AND'
				FROM Tmp_DeleteFromTablesList ct
				WHERE pt.TargetTable = ct.TargetTable
				AND pt.ParentTable = ct.ParentTable
				FOR XML PATH('')
				), 1, 2, ''
			)) + ') DELETE FROM CTE' AS DeleteCmd
FROM Tmp_DeleteFromTablesList pt
) 
UPDATE Tmp_DeleteFromTablesList 
SET DeleteFromTarget = REPLACE(REPLACE(REPLACE(DeleteCmd, ' AND NOT EXISTS ()', '  '), ' AND)', ')'), ' OR)', ')')
FROM CTE 
JOIN Tmp_DeleteFromTablesList dl
ON dl.ParentTable = cte.ParentTable
AND dl.TargetTable = cte.TargetTable;


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
								WHERE cct.ParentTable = ct.ParentTable
								AND cct.TargetTable = ct.TargetTable
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

