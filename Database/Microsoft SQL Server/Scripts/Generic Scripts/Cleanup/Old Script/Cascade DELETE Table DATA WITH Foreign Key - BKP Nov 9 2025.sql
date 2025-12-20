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
SET @TargetDeleteStmt = 'DELETE FROM DischargeSubsystem WHERE Id IN (11980052
,11980053
,11980054
,11980055
,11979889
,11979890
,11979891
,11979892
,11979893
,11979894
,11979895
,11979896
,11979897
,11979795
,11979804
,11979887
,11980088
)'


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
	SELECT OBJECT_NAME(fkc.constraint_object_id) FKConstraint, 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
			+ ' WITH NOCHECK NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS DisableFKCmd, CASE WHEN is_disabled = 0 THEN 'Enabled' ELSE 'Disabled' END AS Status
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

------------------------------- Get column name from TargetDeleteStmt

SET @TargetColumn = LTRIM(SUBSTRING(@TargetDeleteStmt, CHARINDEX(CHAR(32), @TargetDeleteStmt, CHARINDEX('WHERE', @TargetDeleteStmt)), LEN(@TargetDeleteStmt)))

SET @TargetColumn = SUBSTRING(@TargetColumn, 1, CHARINDEX(CHAR(32), @TargetColumn) - 1)


IF NOT EXISTS (SELECT * FROM Tmp_DeleteFromTablesList WHERE DeleteFromTarget = @TargetDeleteStmt)
BEGIN
	INSERT INTO Tmp_DeleteFromTablesList (TargetTable, FKRank, ChildRank, DeleteFromTarget)
	SELECT @TargetTable, FKRank, ChildRank, @TargetDeleteStmt 
	FROM Tmp_DeleteFromTablesList WHERE TargetTable = @TargetTable
END

SELECT @SQL = SUBSTRING(DeleteFromParent, 1, CHARINDEX('WHERE',DeleteFromParent) - 1) + 
REPLACE(SUBSTRING(@TargetDeleteStmt, CHARINDEX('WHERE', @TargetDeleteStmt), LEN(@TargetDeleteStmt)), @TargetColumn, ParentColumn)
FROM Tmp_DeleteFromTablesList 
WHERE TargetTable = @TargetTable AND TargetColumn = @TargetColumn;

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
		SELECT @SQL, ERROR_MESSAGE();

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
		VALUES (@SQL, ERROR_MESSAGE())
	END CATCH


	FETCH NEXT FROM Delete_Cursor INTO @SQL
END

CLOSE Delete_Cursor
DEALLOCATE Delete_Cursor;

SELECT @TotalRowsDeleted AS 'Total Deleted Parent Table Rows'
PRINT 'A total of ' + CAST(@TotalRowsDeleted AS NVARCHAR) + ' rows have been deleted from parent tables';

----------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE EnableFK_Cursor CURSOR FOR
SELECT FKConstraint, REPLACE(DisableFKCmd, 'WITH NOCHECK NOCHECK CONSTRAINT', 'WITH CHECK CHECK CONSTRAINT') AS EnableFKCmd 
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
		SELECT @SQL, ERROR_MESSAGE();

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
	) ORDER BY FKRank, ChildRank
END
