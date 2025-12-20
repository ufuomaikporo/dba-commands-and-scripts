/*
This script disables all foreign key constraints. THEN after the user deletes data from a table or set of 
tables, will cascade delete all referencing data. 
*/

USE DRAS_ICDA_Tool_Demo
GO


-------------------------------- Disable Foreign Keys ---------------------------

DECLARE @SQL NVARCHAR(MAX)
-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE --OBJECT_NAME(fkc.referenced_object_id) NOT IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef', 'VirtualTable', 'VirtualColumn') AND
is_disabled = 0

OPEN DiableFK_Cursor
FETCH NEXT FROM DiableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DiableFK_Cursor INTO @SQL
END

CLOSE DiableFK_Cursor
DEALLOCATE DiableFK_Cursor;
GO

----------------------------------- Choose Table to Delete Data From  --------------------------------

--**** NOTE **** This part needs to be modified as desired

DELETE FROM LineLoop 
WHERE LineName NOT IN ('NPS 6 NEW CHIME 05-26 TO 08-13 LOOP'
,'NPS 12 MUSREAU 01-26 TO TCPL 2 NORTH'
,'NPS 4 KARR TANK FARM (PCA-891)'
,'NPS 6 HYTHE TO LA GLACE'
,'NPS 12 RESTHAVEN'
,'NPS 2 HARVEST 10-33'
,'NPS 8 PINE CREEK SOUTH 06-29 TO 11-14 (PCK-130)'
,'NPS 10 PINE CREEK SOUTH 11-14 TO 10-23 (PCK-134)'
,'NPS 8 PINE CREEK SOUTH 10-23 TO PINE CREEK COMPRESSOR (PCK-136)'
,'NPS 8 NORTHWEST PINE 02-10 TO PINE CREEK COMPRESSOR (PCK-150)')

-------------------------------------- Cascade Delete Data from Referencing Tables --------------------------------

DECLARE @SQL NVARCHAR(MAX)
DROP TABLE IF EXISTS ##FKHierarchy;
DROP TABLE IF EXISTS ##ErrorTable;
CREATE TABLE ##ErrorTable (Cmd NVARCHAR(MAX), ErrMsg NVARCHAR(MAX));

WITH CTE AS(
SELECT rt.*, OBJECT_NAME(fkc.referenced_object_id) ParentTab,
COL_NAME(fkc.referenced_object_id,fkc.referenced_column_id) ParentCol,
COL_NAME(fkc.parent_object_id, parent_column_id) ChildCol,
OBJECT_NAME(fkc.constraint_object_id) AS constraint_name
FROM ##RankTab rt
JOIN sys.foreign_key_columns fkc
ON rt.ChildTable = OBJECT_NAME(fkc.parent_object_id)
)
SELECT ChildTable, ChildCol, ParentTab, ParentCol, 'DELETE FROM ' + ChildTable + ' WHERE ' + ChildCol + ' NOT IN (SELECT ' + ParentCol + ' FROM ' + ParentTab + ') ' DeleteStmt,
'ALTER TABLE ' + ChildTable + ' NOCHECK CONSTRAINT ' + constraint_name AS DisableConstraint, FKRank, ParentRank, MaxRankAsChild
INTO ##FKHierarchy
FROM CTE

DECLARE Delete_Cursor CURSOR FOR
SELECT DeleteStmt FROM ##FKHierarchy
ORDER BY FKRank, ParentRank 

OPEN Delete_Cursor
FETCH NEXT FROM Delete_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		EXECUTE (@SQL)
	END TRY
	BEGIN CATCH
		INSERT INTO ##ErrorTable 
		SELECT @SQL, ERROR_MESSAGE()
		BREAK
	END CATCH
	FETCH NEXT FROM Delete_Cursor INTO @SQL
END

CLOSE Delete_Cursor
DEALLOCATE Delete_Cursor

SELECT * FROM ##ErrorTable
GO

----------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE @SQL NVARCHAR(MAX)
DECLARE EnableFK_Cursor CURSOR FOR
--SELECT 'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + + ' CHECK CONSTRAINT ' + name
SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE --OBJECT_NAME(fkc.referenced_object_id) NOT IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef', 'VirtualTable', 'VirtualColumn', 'SystemPreferences', 'Connection') AND 
		is_disabled = 1

OPEN EnableFK_Cursor
FETCH NEXT FROM EnableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM EnableFK_Cursor INTO @SQL
END

CLOSE EnableFK_Cursor
DEALLOCATE EnableFK_Cursor

/*
SELECT * FROM ##ProblemTables

SELECT * FROM ##FKHierarchy WHERE ChildTable like 'Inline%'
ORDER BY FKRank, ParentRank 

DELETE FROM InlineInspection WHERE MaintenanceId NOT IN (SELECT Id FROM Maintenance) 
The DELETE statement conflicted with the REFERENCE constraint "FK_ILIRInlineInspectionId". The conflict occurred in database "DRAS_ICDA_Tool_Demo", table "dbo.InlineInspectionRange", column 'InlineInspectionId'.

*/