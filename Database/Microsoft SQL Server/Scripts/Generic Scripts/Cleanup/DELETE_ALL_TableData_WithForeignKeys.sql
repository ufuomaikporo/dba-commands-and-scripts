/*
This script disables foreign key constraints then deletes data from all tables that have disabled foreign key constraints
*/

DECLARE @SQL NVARCHAR(MAX)

-------------------------------- Disable Foreign Keys ---------------------------

-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) NOT IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef', 'VirtualTable', 'VirtualColumn')
AND is_disabled = 0

OPEN DiableFK_Cursor
FETCH NEXT FROM DiableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DiableFK_Cursor INTO @SQL
END

CLOSE DiableFK_Cursor
DEALLOCATE DiableFK_Cursor
----------------------------------- Delete Data from Tables ---------------------------

DECLARE DeleteData_Cursor CURSOR FOR
SELECT 'DELETE FROM ' + QUOTENAME(name) + ';' AS DeleteStmt
FROM sys.tables
WHERE temporal_type = 0
AND name NOT IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef', 'VirtualTable', 'VirtualColumn') -- Exempted tables
AND SCHEMA_NAME(schema_id) = 'dbo'

OPEN DeleteData_Cursor
FETCH NEXT FROM DeleteData_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		EXECUTE (@SQL)
	END TRY
	BEGIN CATCH
		PRINT @SQL;
		THROW 
	END CATCH

	FETCH NEXT FROM DeleteData_Cursor INTO @SQL
END

CLOSE DeleteData_Cursor
DEALLOCATE DeleteData_Cursor

----------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE EnableFK_Cursor CURSOR FOR
--SELECT 'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + + ' CHECK CONSTRAINT ' + name
SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE is_disabled = 1

OPEN EnableFK_Cursor
FETCH NEXT FROM EnableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM EnableFK_Cursor INTO @SQL
END

CLOSE EnableFK_Cursor
DEALLOCATE EnableFK_Cursor