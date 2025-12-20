/*
1. This script copies a list of tables from a source database into a target database. Including the
	primary key, unique keys, foreign keys, default constraints
2. The script should be executed on the target database
*/

DECLARE @TableList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @SourceDB NVARCHAR(100)
DECLARE @CleanTargetDB NVARCHAR(1)
DECLARE @SourceSchema NVARCHAR(100)
DECLARE @TargetSchema NVARCHAR(100)
DECLARE @Schema NVARCHAR(100)
DECLARE @InlcudePKandFK CHAR(1)
DECLARE @TargetColumns VARCHAR(MAX)
DECLARE @PkList VARCHAR(MAX)
DECLARE @CleanTargetTable CHAR(1)

--*********************************************************************************************

-- Set @CleanTargetDB to 'Y' if you want to DROP all tables in the target databases before copyng tables
SET @CleanTargetDB = 'N'
SET @CleanTargetTable = 'Y'
SET @InlcudePKandFK = 'Y'



-- Set the source database where tables will be copied from

SET @SourceDB = 'PSE_IRASv6_TRANS_STAGE_Upgrade'
SET @SourceSchema = 'dbo'
SET @TargetSchema = @SourceSchema

-- set list of tables to be copied
SET @TableList = 'Category
'

DROP TABLE IF EXISTS ##TableList
DROP TABLE IF EXISTS ##ErrorTable

CREATE TABLE ##TableList (Name NVARCHAR(100))
CREATE TABLE ##ErrorTable (Command NVARCHAR(MAX), Details NVARCHAR(MAX))

SET @SQL = REPLACE(@TableList, ' ', '')
SET @SQL = REPLACE(@SQL, CHAR(10), ' ')
SET @SQL = REPLACE(@SQL, CHAR(13), '')
SET @SQL = REPLACE(@SQL, CHAR(9), '')
SET @SQL = REPLACE(@SQL, ' ', ''', ''')
SET @SQL = REPLACE(@SQL, ''''', ', '')

SET @TableList = '''' + @SQL + ''''

SET @SQL = 'INSERT INTO ##TableList
SELECT DISTINCT table_name FROM ' + @SourceDB + '.INFORMATION_SCHEMA.tables 
WHERE table_name IN (' + @TableList + ')
AND table_schema = ''dbo'''

EXECUTE (@SQL)

------------------------------------ Delete all tables from target database ---------------

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = @TargetSchema)
BEGIN
	SET @SQL = 'CREATE SCHEMA ' + @TargetSchema
	EXECUTE(@SQL)
END

IF @CleanTargetDB = 'Y'
BEGIN
	-- DROP foreign key constraints 

	DECLARE DropFK_Cursor CURSOR FOR
	SELECT DISTINCT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' 
	+ QUOTENAME(OBJECT_NAME(parent_object_id)) + ' DROP CONSTRAINT '
		+ QUOTENAME(name) + CHAR(10) 
	FROM sys.foreign_keys

	EXECUTE (@SQL)

	OPEN DropFK_Cursor
	FETCH NEXT FROM DropFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN	
		EXECUTE (@SQL)
		FETCH NEXT FROM DropFK_Cursor INTO @SQL
	END

	CLOSE DropFK_Cursor
	DEALLOCATE DropFK_Cursor


	DECLARE TableList_Cursor CURSOR FOR
	SELECT table_schema, table_name FROM INFORMATION_SCHEMA.tables

	OPEN TableList_Cursor
	FETCH NEXT FROM TableList_Cursor INTO @Schema, @Tablename

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'DROP TABLE IF EXISTS ' + @Schema + '.' + @TableName
		EXECUTE (@SQL)
		FETCH NEXT FROM TableList_Cursor INTO @Schema, @Tablename
	END 

	CLOSE TableList_Cursor
	DEALLOCATE TableList_Cursor

END

IF @CleanTargetTable = 'Y' AND @CleanTargetDB <> 'Y'
BEGIN
	
	-------------------------------- Disable Foreign Keys ---------------------------

	-- Disable foreign keys to delete data from tables
	DECLARE DiableFK_Cursor CURSOR FOR
	SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
			+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
	FROM sys.foreign_key_columns fkc
	JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
	WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT name FROM ##TableList)
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

	-------------------------------------- DELETE from Tables ------------------------------

	DECLARE DeleteTable_Cursor CURSOR FOR
	SELECT 'DELETE FROM ' + name
	FROM ##TableList

	OPEN DeleteTable_Cursor
	FETCH NEXT FROM DeleteTable_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN	
		EXECUTE (@SQL)
		FETCH NEXT FROM DeleteTable_Cursor INTO @SQL
	END

	CLOSE DeleteTable_Cursor
	DEALLOCATE DeleteTable_Cursor

	----------------------------------- Re-enable Foreign Keys -------------------------------------

	DECLARE EnableFK_Cursor CURSOR FOR
	SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
			+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
	FROM sys.foreign_key_columns fkc
	JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
	WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT name FROM ##TableList)
	AND is_disabled = 1

	OPEN EnableFK_Cursor
	FETCH NEXT FROM EnableFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM EnableFK_Cursor INTO @SQL
	END

	CLOSE EnableFK_Cursor
	DEALLOCATE EnableFK_Cursor

END

------------------------ Copy selected tables from source to target database ---------------------- 

DROP TABLE IF EXISTS ##PKConstraints

SET @SQL = '
USE ' + @SourceDB+ '

--SELECT DISTINCT OBJECT_NAME(i.object_id) AS TableName, COL_NAME(ic.object_id, ic.column_id) ColumnName, 
--name ConstraintName,
--''ALTER TABLE ' + @TargetSchema + '.'' + OBJECT_NAME(ic.object_id) + '' WITH CHECK ADD CONSTRAINT '' 
--+ name + CASE WHEN is_primary_key = 1 THEN '' PRIMARY KEY '' + type_desc COLLATE SQL_Latin1_General_CP1_CI_AS ELSE '' UNIQUE '' END +  ''  (''
--+ (SELECT STUFF(
--				(SELECT '', '' + COL_NAME(object_id, column_id) +
--					CASE WHEN is_descending_key = 1 THEN '' DESC''
--						ELSE '' ASC''
--					END
--				FROM sys.index_columns 
--				WHERE object_id = ic.object_id
--					AND index_id = ic.index_id
--				ORDER BY key_ordinal
--				FOR XML PATH(N''''), TYPE
--				).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
--			)
			
--	) + ''); '' AS Index_Definition
--INTO ##PKConstraints
--FROM sys.indexes i
--JOIN sys.index_columns ic
--ON i.object_id = ic.object_id
--AND i.index_id = ic.index_id
--WHERE (i.is_primary_key = 1
--OR i.is_unique_constraint = 1)

SELECT  DISTINCT OBJECT_NAME(i.object_id) AS TableName, COL_NAME(ic.object_id, ic.column_id) ColumnName, 
i.name ConstraintName, 
CASE WHEN is_primary_key = 1 THEN ''PK'' WHEN is_unique_constraint = 1 THEN ''UQ'' ELSE ''Index'' END AS IndexType
, CASE WHEN is_primary_key = 1 OR is_unique_constraint = 1 THEN 
''ALTER TABLE ' + @TargetSchema + '.'' + QUOTENAME(OBJECT_NAME(ic.object_id)) 
+ '' WITH CHECK ADD CONSTRAINT '' 
+ QUOTENAME(i.name)
+ CASE WHEN is_primary_key = 1 THEN '' PRIMARY KEY '' WHEN is_unique_constraint = 1 THEN '' UNIQUE '' END + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS 
ELSE ''CREATE '' + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + '' INDEX '' + QUOTENAME(i.name) + '' ON '' + QUOTENAME(SCHEMA_NAME(t.schema_id) )
+ ''.'' + QUOTENAME(OBJECT_NAME(t.object_id))  END + '' (''
+ (SELECT STUFF(
				(SELECT '', '' + QUOTENAME(COL_NAME(object_id, column_id)) +
					CASE WHEN is_descending_key = 1 THEN '' DESC''
						ELSE '' ASC''
					END
				FROM sys.index_columns 
				WHERE object_id = ic.object_id
					AND index_id = ic.index_id
				ORDER BY key_ordinal
				FOR XML PATH(N''''), TYPE
				).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
			)
			
	) + '') WITH (PAD_INDEX ='' + CASE WHEN is_padded = 0 THEN '' OFF'' ELSE '' ON'' END 
			+ '', STATISTICS_NORECOMPUTE ='' + CASE WHEN s.no_recompute = 0 THEN '' OFF'' ELSE '' ON'' END 
			+ '', ALLOW_ROW_LOCKS ='' + CASE WHEN allow_row_locks = 0 THEN '' OFF'' ELSE '' ON'' END 
			+ '', ALLOW_PAGE_LOCKS ='' + CASE WHEN allow_page_locks = 0 THEN '' OFF'' ELSE '' ON'' END + '')''   AS Index_Definition
INTO ##PKConstraints
FROM sys.indexes i
JOIN sys.index_columns ic
ON i.object_id = ic.object_id
AND i.index_id = ic.index_id
JOIN sys.stats s ON  s.object_id = i.object_id AND s.name = i.name
JOIN sys.tables t ON i.object_id = t.object_id'

EXECUTE (@SQL)

DECLARE TableList_Cursor CURSOR FOR
SELECT DISTINCT name FROM ##TableList

OPEN TableList_Cursor
FETCH NEXT FROM TableList_Cursor INTO @Tablename

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @TargetColumns = NULL
	SET @PkList = NULL
	DROP TABLE IF EXISTS ##TargetColumns 
	DROP TABLE IF EXISTS ##SourceColumns

	SELECT column_name INTO ##TargetColumns FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName

	SELECT @PKList = COALESCE(@PKList + ' AND ', '') + ' t1.' + ColumnName + ' = t2.' + ColumnName 
	FROM ##PKConstraints
	WHERE TableName = @TableName
	
	SET @SQL = 'USE ' + @SourceDB + '
	SELECT column_name INTO ##SourceColumns FROM INFORMATION_SCHEMA.columns WHERE table_name = ''' + @TableName + '''' 

	EXECUTE (@SQL)

	SET @SQL = 'SELECT @TargetColumns = COALESCE(@TargetColumns + '', '', '''') + column_name 
	FROM ##TargetColumns 
	WHERE column_name IN (SELECT column_name FROM ##SourceColumns)'

	EXECUTE sp_executesql @SQL, N'@TargetColumns VARCHAR(MAX) OUTPUT', @TargetColumns OUTPUT

	SET @SQL = 'INSERT INTO ' + @TargetSchema + '.' + @TableName + ' (' + @TargetColumns + ')
	SELECT ' + @TargetColumns + ' FROM '+ @SourceDB +'.' + @SourceSchema + '.' + @TableName + ' t1
	WHERE NOT EXISTS (SELECT * FROM ' + @TargetSchema + '.' + @TableName + ' t2 WHERE ' + @PkList + ')'

	IF OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity') = 1
	BEGIN
		SET @SQL = 'SET IDENTITY_INSERT ' + @TableName + ' ON ' + CHAR(10) + @SQL 
		+ 'SET IDENTITY_INSERT ' + @TableName + ' OFF '
	END

	begin try
	EXECUTE (@SQL)
	end try
	begin catch
		print @sql;
		throw
	end catch
	FETCH NEXT FROM TableList_Cursor INTO @Tablename
END 

CLOSE TableList_Cursor
DEALLOCATE TableList_Cursor

------------------------------- Copy primary and unique key constraints from source ----------------------

IF @InlcudePKandFK = 'Y'
BEGIN

	DECLARE CreatePK_Cursor CURSOR FOR
	SELECT TableName, Index_Definition 
	FROM ##PKConstraints k
	WHERE TableName IN (SELECT name FROM ##TableList)
	AND NOT EXISTS (SELECT * FROM sys.indexes WHERE name = k.ConstraintName AND OBJECT_NAME(object_id) = k.TableName)


	OPEN CreatePK_Cursor
	FETCH NEXT FROM CreatePK_Cursor INTO @TableName, @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		begin try
		EXECUTE (@SQL)
		end try
		begin catch
			print @sql;
			throw
		end catch
		FETCH NEXT FROM CreatePK_Cursor INTO @TableName, @SQL
	END


	CLOSE CreatePK_Cursor
	DEALLOCATE CreatePK_Cursor

	----------------------------- Copy foreign key constraints from source ----------------------------

	DROP TABLE IF EXISTS ##FKContraints

	SET @SQL = 'USE ' + @SourceDB + '
	SELECT DISTINCT OBJECT_NAME(fkc1.parent_object_id) FKTable, OBJECT_NAME(fkc1.referenced_object_id) ParentTable,
	''IF OBJECT_ID( ''''''+ OBJECT_NAME(constraint_object_id) +'''''', ''''F'''') IS NULL BEGIN ALTER TABLE ['' + SCHEMA_NAME(tab.schema_id) +''].[''+ OBJECT_NAME(fkc1.parent_object_id) 
	+ ''] WITH CHECK ADD CONSTRAINT ['' + OBJECT_NAME(constraint_object_id) + '']'' 
	+ CHAR(10) + ''FOREIGN KEY('' + (SELECT ''['' + STRING_AGG(COL_NAME(fkc2.parent_object_id, fkc2.parent_column_id), ''], ['') + '']'' 
						FROM sys.foreign_key_columns fkc2 WHERE constraint_object_id = fkc1.constraint_object_id) 
	+ CHAR(10) + '') REFERENCES ['' + SCHEMA_NAME(tab2.schema_id) + ''].['' + OBJECT_NAME(fkc1.referenced_object_id) + '']('' 
	+ (SELECT ''['' + STRING_AGG(COL_NAME(fkc2.referenced_object_id, fkc2.referenced_column_id), ''], ['')  + '']''
	FROM sys.foreign_key_columns fkc2 WHERE constraint_object_id = fkc1.constraint_object_id) +'') END'' AS FK_Definition
	INTO ##FKContraints
	FROM sys.foreign_key_columns fkc1
	JOIN sys.tables tab
	ON tab.object_id = fkc1.parent_object_id
	JOIN sys.tables tab2 
	ON tab2.object_id = fkc1.referenced_object_id'

	EXECUTE (@SQL)

	DECLARE CreateFK_Cursor CURSOR FOR
	SELECT FK_Definition
	FROM ##FKContraints 
	WHERE FKTable IN (SELECT name FROM sys.tables)
	AND ParentTable IN (SELECT name FROM sys.tables)
	AND FKTable IN (SELECT name FROM ##TableList)

	OPEN CreateFK_Cursor
	FETCH NEXT FROM CreateFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			EXECUTE (@SQL)
		END TRY
		BEGIN CATCH
			INSERT INTO ##ErrorTable (Command, Details)
			VALUES (@SQL, ERROR_MESSAGE())
		END CATCH

		FETCH NEXT FROM CreateFK_Cursor INTO @SQL
	END

	CLOSE CreateFK_Cursor
	DEALLOCATE CreateFK_Cursor

	--------------------------------------------- Copy table Defaults ---------------------------------------------

	DROP TABLE IF EXISTS ##DefaultConstraints

	SET @SQL = ' USE ' + @SourceDB + '
				SELECT OBJECT_NAME(parent_object_id) AS TableName, COL_NAME(parent_object_id, parent_column_id) ColumnName,
						''ALTER TABLE '' + OBJECT_NAME(parent_object_id) + ''
						ADD CONSTRAINT '' + name + '' DEFAULT '' + definition + '' FOR '' + COL_NAME(parent_object_id, parent_column_id) AS Constraint_def		 
			INTO ##DefaultConstraints
			FROM sys.default_constraints'

	EXECUTE (@SQL)

	DECLARE CreateDefaultConst_Cursor CURSOR FOR
	SELECT Constraint_def
	FROM ##DefaultConstraints df
	WHERE TableName IN (SELECT name FROM ##TableList)
	AND NOT EXISTS (SELECT * FROM sys.default_constraints WHERE OBJECT_NAME(parent_object_id) = df.TableName 
	AND COL_NAME(parent_object_id, parent_column_id) = df.ColumnName)
	AND COL_LENGTH(df.TableName, df.Columnname) IS NOT NULL

	OPEN CreateDefaultConst_Cursor
	FETCH NEXT FROM CreateDefaultConst_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		begin try
		EXECUTE (@SQL)
		end try
		begin catch
			print @sql;
			throw
		end catch

		FETCH NEXT FROM CreateDefaultConst_Cursor INTO @SQL
	END

	CLOSE CreateDefaultConst_Cursor
	DEALLOCATE CreateDefaultConst_Cursor

	-------------------------------------- Add Indexes ------------------------------------
 
END

IF @CleanTargetDB = 'Y'
BEGIN
	SELECT name AS [Dropped the following tables before copying data into them] 
	FROM ##TableList 
END

IF @CleanTargetTable = 'Y'
BEGIN
	SELECT name AS [DELETED data from the following tables before copying data into them] 
	FROM ##TableList 
END
ELSE
BEGIN
	SELECT name AS [Copied data to the following tables] FROM ##TableList
END

IF EXISTS (SELECT * FROM ##ErrorTable)
BEGIN
	SELECT * FROM ##ErrorTable
END

