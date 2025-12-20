DECLARE @SQL1 NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ConstraintName NVARCHAR(200)
DECLARE @ChildSchema NVARCHAR(200)
DECLARE @ChildTable NVARCHAR(200)
DECLARE @ParentSchema NVARCHAR(200)
DECLARE @ParentTable NVARCHAR(200)
DECLARE @ColumnName NVARCHAR(200)

-- Save Foreign key info in temp table
IF OBJECT_ID('tempdb..##SaveForeignKeys') IS NULL
BEGIN
	SELECT OBJECT_NAME(fkc.constraint_object_id) ConstraintName,
		   SCHEMA_NAME(t1.schema_id) AS ChildTableSchema,
		   OBJECT_NAME(fkc.parent_object_id) AS ChildTable,
		   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildTableColumn,
		   SCHEMA_NAME(t2.schema_id) AS ParentTableSchema,
		   OBJECT_NAME(fkc.referenced_object_id) AS ParentTable
	INTO ##SaveForeignKeys
	FROM sys.foreign_key_columns fkc
	JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
	WHERE OBJECT_NAME(fkc.referenced_object_id) LIKE 'LD_%'
END

---------------------------- DROP foreign keys referencing target tables ---------------------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT DISTINCT  'ALTER TABLE ' + ChildTableSchema + '.' + ChildTable + ' DROP CONSTRAINT ' + ConstraintName
FROM ##SaveForeignKeys
WHERE ConstraintName IN (SELECT name FROM sys.foreign_keys)

OPEN DropFK_Cursor 
FETCH NEXT FROM DropFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DropFK_Cursor INTO @SQL
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

--------------------- Modify Identity LD table Ids to use Old ListDomain Id --------------------

DECLARE UpdateLDTab_Cursor CURSOR FOR
SELECT *
FROM ##SaveForeignKeys
where parenttable = 'LD_TeeType'



OPEN UpdateLDTab_Cursor
FETCH NEXT FROM UpdateLDTab_Cursor INTO @ConstraintName, @ChildSchema, @ChildTable, @ColumnName, @ParentSchema, @ParentTable

WHILE @@FETCH_STATUS = 0
BEGIN

select  @ChildSchema, @ChildTable, @ColumnName, @ParentSchema, @ParentTable
	SET @SQL = '

	IF OBJECT_ID(''tempdb..##Temp_Table'') IS NOT NULL
	BEGIN
		DROP TABLE ##Temp_Table
	END

	SELECT * INTO ##Temp_Table
	FROM ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + '

	TRUNCATE TABLE ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + '

	SET IDENTITY_INSERT ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + ' ON

	-- Load modified data into the new LD table
	INSERT INTO ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + '
	(Id, Code, Descr, EffectiveEndDate, CreatedUser, CreatedDate, LastModByUserId, LastModDateTime)
	SELECT DISTINCT CASE WHEN ld.Old_Id IS NULL 
							THEN (SELECT MAX(Old_Id) + 1 FROM Temp_ListDomain WHERE LDTableName = ''' + @ParentTable + ''')
				 ELSE Old_Id
				 END,
			tmp.Code, 
			tmp.Descr, 
			tmp.EffectiveEndDate,  
			CASE WHEN tmp.CreatedUser IS NULL THEN SUSER_SNAME()
				ELSE tmp.CreatedUser
			END, 
			CASE WHEN tmp.CreatedDate IS NULL THEN GETDATE()
				ELSE tmp.CreatedDate
			END, 
			SUSER_SNAME(), 
			GETDATE()
	FROM Temp_ListDomain ld
	JOIN ##Temp_Table tmp
	ON tmp.Code = ld.Code
	AND tmp.Descr = ld.Descr
	WHERE LDTableName = ''' + @ParentTable + '''
	AND NOT EXISTS (SELECT * FROM ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + ' sub
					WHERE sub.Descr = tmp.Descr AND sub.Code = tmp.Code)



	SET IDENTITY_INSERT ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + ' OFF

	-- Update FK columns in child tables
	UPDATE ' + QUOTENAME(@ChildSchema) + '.' + QUOTENAME(@ChildTable)
	+ ' SET ' + @ColumnName + ' = CASE WHEN ld.Old_Id IS NULL THEN ldt.Id
									ELSE ld.Old_Id
									END
	FROM ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + ' ldt
	LEFT JOIN Temp_ListDomain ld
	ON ldt.Code = ld.code
	AND ldt.Descr = ld.Descr
	AND ld.LDTableName = ''' + @ParentTable + '''
	LEFT JOIN ' + QUOTENAME(@ChildSchema) + '.' + QUOTENAME(@ChildTable) + ' tab
	ON ld.New_Id = tab.' + @ColumnName + ''

	print @sql
	--break

	begin try 
	EXECUTE(@SQL)
	end try
	begin catch
		print @sql;
		throw
	end catch
	
	FETCH NEXT FROM UpdateLDTab_Cursor INTO @ConstraintName, @ChildSchema, @ChildTable, @ColumnName, @ParentSchema, @ParentTable
END

CLOSE UpdateLDTab_Cursor
DEALLOCATE UpdateLDTab_Cursor


DECLARE CreateFK_Cursor CURSOR FOR
SELECT *
FROM ##SaveForeignKeys
WHERE ConstraintName NOT IN (SELECT name FROM sys.foreign_keys)
and parenttable = 'LD_TeeType'


OPEN CreateFK_Cursor 
FETCH NEXT FROM CreateFK_Cursor INTO @ConstraintName, @ChildSchema, @ChildTable, @ColumnName, @ParentSchema, @ParentTable

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL =  '-- Replace LD table with new LD table and add PK
			--IF OBJECT_ID(''Temp_' + @ParentTable + ''') IS NOT NULL
			--BEGIN
			--	DROP TABLE ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + '
	
			--	EXECUTE sp_rename '''  + @ParentSchema + '.' + 'Temp_' + @ParentTable + ''', ''' + @ParentTable + '''
				
			--	ALTER TABLE ' + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + ' ADD CONSTRAINT PK_' + @ParentTable + ' PRIMARY KEY (Id)
			--END
			
			ALTER TABLE ' + QUOTENAME(@ChildSchema) + '.' + QUOTENAME(@ChildTable) + ' ADD CONSTRAINT ' + @ConstraintName
			+ ' FOREIGN KEY (' + @ColumnName + ') REFERENCES '  + QUOTENAME(@ParentSchema) + '.' + QUOTENAME(@ParentTable) + '(Id)'
				
	begin try
	EXECUTE (@SQL)
	end try
	begin catch
		print @sql1
		print @sql;
		throw
	end catch
	FETCH NEXT FROM CreateFK_Cursor INTO @ConstraintName, @ChildSchema, @ChildTable, @ColumnName, @ParentSchema, @ParentTable
END

CLOSE CreateFK_Cursor
DEALLOCATE CreateFK_Cursor

/*

*/

--IF OBJECT_ID('tempdb..##SaveForeignKeys') IS NOT NULL
--BEGIN
--	DROP TABLE ##SaveForeignKeys
--END


--UPDATE [dbo].[LD_SoilConditionLandUse] SET Id = ld.Old_Id



--		UPDATE [dbo].[SoilCondition]SET SoilCondLandUseDomainId = ld.Old_Id
--		FROM [dbo].[SoilCondition] ldt
--		JOIN Temp_ListDomain ld
--		ON ld.New_Id = ldt.SoilCondLandUseDomainId AND ld.LDTableName = 'LD_SoilConditionLandUse'


/*
	SELECT 'ALTER TABLE [' + SCHEMA_NAME(t1.schema_id) + '].[' +  OBJECT_NAME(fkc.parent_object_id) + '] NOCHECK CONSTRAINT ' +
	OBJECT_NAME(fkc.constraint_object_id) 
	FROM sys.foreign_key_columns fkc
	JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
	WHERE OBJECT_NAME(fkc.referenced_object_id) LIKE 'LD_%'
	AND is_disabled = 0
*/
