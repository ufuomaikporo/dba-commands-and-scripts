/*
This script disables/enables all foreign keys and nonclustered indexes in a database

Before running the script
1) set the Target database with the @TargetDB variable
2) Set the @Switch to '0' to disable foreign key and indexes or set @Switch to '1' to enable them
*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TargetDB NVARCHAR(100)
DECLARE @Switch INT

--*************************************************************************************************

SET @TargetDB = 'DRAS_IRASv6_DEMO_QA'
SET @Switch = 0 -- 0 -> Disable foreign key and nonclusters indexes, 1 --> enable foreign keys and indexes

--****************************************************************************************************

IF (@Switch = 0)
BEGIN

------------------------------ Disable Foreign Keys ---------------------------

	DECLARE DiableFK_Cursor CURSOR FOR
	SELECT 'USE ' + @TargetDB + CHAR(10) +
	'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + ' NOCHECK CONSTRAINT ' + name
	FROM sys.foreign_keys
	WHERE is_disabled = 0

	OPEN DiableFK_Cursor
	FETCH NEXT FROM DiableFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM DiableFK_Cursor INTO @SQL
	END

	CLOSE DiableFK_Cursor
	DEALLOCATE DiableFK_Cursor

------------------------------------ Disable Indexes -------------------------------

-- Disables all NONCUSTERED (non-primary key) indexes on all user tables in the database

	DECLARE DisableIndex_Cursor CURSOR FOR
	SELECT 'USE '+ @TargetDB + CHAR(10) +
	'ALTER INDEX ' + ind.name + ' ON ' + SCHEMA_NAME(obj.schema_id) + '.' + OBJECT_NAME(ind.object_id) + ' DISABLE'
	FROM sys.indexes ind
	JOIN sys.objects obj
	ON ind.object_id = obj.object_id
	WHERE ind.type_desc = 'NONCLUSTERED'
	AND obj.type_desc = 'USER_TABLE'
	AND is_disabled = 0

	OPEN DisableIndex_Cursor
	FETCH NEXT FROM DisableIndex_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM DisableIndex_Cursor INTO @SQL
	END

	CLOSE DisableIndex_Cursor
	DEALLOCATE DisableIndex_Cursor

	IF NOT EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.objects o ON i.object_id = o.object_id 
				WHERE o.type_desc = 'USER_TABLE' AND i.type_desc = 'NONCLUSTERED' AND is_disabled = 0)
	BEGIN
		PRINT 'All nonclustered indexes on user tables have been disabled'
	END

	IF NOT EXISTS (SELECT 1 from sys.foreign_keys WHERE is_disabled = 0)
	BEGIN
		PRINT 'All foreign keys have been disabled'
	END
END

-------------------------------- Enable Foreign Keys and Nonclustered Indexes -----------------------

IF (@Switch = 1)
BEGIN

-------------------------------------- Enable Indexes --------------------------------------

	DECLARE EnableIndex_Cursor CURSOR FOR
	SELECT  'USE '+ @TargetDB + CHAR(10) +
	'ALTER INDEX ' + ind.name + ' ON ' + SCHEMA_NAME(obj.schema_id) + '.' + OBJECT_NAME(ind.object_id) + ' REBUILD'
	FROM sys.indexes ind
	JOIN sys.objects obj
	ON ind.object_id = obj.object_id
	WHERE ind.type_desc = 'NONCLUSTERED'
	AND obj.type_desc = 'USER_TABLE'
	AND is_disabled = 1

	OPEN EnableIndex_Cursor
	FETCH NEXT FROM EnableIndex_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM EnableIndex_Cursor INTO @SQL
	END

	CLOSE EnableIndex_Cursor
	DEALLOCATE EnableIndex_Cursor

------------------------------------- Enable Foreign Keys -------------------------------------

	DECLARE EnableFK_Cursor CURSOR FOR
	SELECT  'USE '+ @TargetDB + CHAR(10) +
	'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + + ' CHECK CONSTRAINT ' + name
	FROM sys.foreign_keys
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

	IF NOT EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.objects o ON i.object_id = o.object_id 
				WHERE o.type_desc = 'USER_TABLE' AND i.type_desc = 'NONCLUSTERED' AND is_disabled = 1)
	BEGIN
		PRINT 'All nonclustered indexes on user tables have been enabled'
	END

	IF NOT EXISTS (SELECT 1 from sys.foreign_keys WHERE is_disabled = 1)
	BEGIN
		PRINT 'All foreign keys have been enabled'
	END
END

