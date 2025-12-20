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

DECLARE @TableName VARCHAR(200)
DECLARE @Schema VARCHAR(200)
DECLARE delete_cur CURSOR FOR
SELECT table_schema, table_name FROM INFORMATION_SCHEMA.tables 
WHERE table_name LIKE 'LD[_]%'

OPEN delete_cur
FETCH NEXT FROM delete_cur INTO @Schema, @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'WITH duplicates AS  
	( SELECT Id, Code, Descr,
				ROW_NUMBER() OVER (PARTITION BY Code, Descr, COALESCE(EffectiveEndDate, GETDATE()) ORDER BY Id) row_num 
		FROM ' + @Schema + '.' + @TableName + '  
	)  
	DELETE FROM duplicates WHERE row_num > 1;'
	
	begin try
	EXECUTE (@SQL)
	end try
	begin catch
		print @sql;
		throw
	end catch

	FETCH NEXT FROM delete_cur INTO @Schema, @TableName
END

CLOSE delete_cur
DEALLOCATE delete_cur

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



