DECLARE @SourceDB NVARCHAR(100)
DECLARE @TargetDB NVARCHAR(100)
DECLARE @SourceServer NVARCHAR(100)
DECLARE @TargetServer NVARCHAR(100)
DECLARE @FKConstraint NVARCHAR(100)
DECLARE @TableName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

/*************************************************************************************

Run this script on the target server

*************************************************************************************/

SET @SourceDB = 'DRAS_IRASv6_DEMO_QA'
SET @TargetDB = 'Base_IRASv6_STAGE'
SET @SourceServer = 'DRASSQL2017'
SET @TargetServer = @@SERVERNAME

--------------------------------------- Get List of Tables from Source DB --------------------------------

DROP TABLE IF EXISTS TableList 

--Generate a list of tables to be copied from the source database into the target database
SET @SQL = 'SELECT table_name, 
			(SELECT COUNT(*) 
			FROM ' + QUOTENAME(@TargetDB) + '.INFORMATION_SCHEMA.columns t1
			WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns t2
			WHERE t1.table_name = t2.table_name AND t1.column_name = t2.column_name 
			AND t1.ordinal_position = t2.ordinal_position) 
			AND table_name = src.table_name) + 
						(SELECT COUNT(*) 
			FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns t1
			WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@TargetDB) + '.INFORMATION_SCHEMA.columns t2
			WHERE t1.table_name = t2.table_name AND t1.column_name = t2.column_name 
			AND t1.ordinal_position = t2.ordinal_position) 
			AND table_name = src.table_name) AS NonMatchingColumns,
		''INSERT INTO ' + QUOTENAME(@TargetDB) + '.''  
		+ (SELECT DISTINCT QUOTENAME(table_schema) + ''.'' + QUOTENAME(table_name) 
			FROM ' + QUOTENAME(@TargetDB) + '.INFORMATION_SCHEMA.tables targ
			WHERE targ.table_name = src.table_name ) + '' ('' +
		(SELECT DISTINCT STRING_AGG(QUOTENAME(column_name), '', '') 
		FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns src2
		WHERE src2.table_name = src.table_name) + '')'' AS InsertStmt1,
		(SELECT DISTINCT ''SELECT '' + STRING_AGG(QUOTENAME(column_name), '', '') 
		FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns src2
		WHERE src2.table_name = src.table_name) + CHAR(10) +
		''FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.'' 
		+ QUOTENAME(src.table_schema) + ''.'' + QUOTENAME(src.table_name) AS InsertStmt2,
		''SELECT * INTO [dbo].'' + QUOTENAME(src.table_name )
		+ '' FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.'' + QUOTENAME(src.table_schema) + ''.'' + QUOTENAME(src.table_name) AS CreateTableStmt,
		CAST(NULL AS NVARCHAR(MAX)) AS CreatePK,
		TooManyColumns = CASE 
						WHEN (SELECT COUNT(*) FROM ' + QUOTENAME(@SourceServer) +'.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns
							  WHERE table_name = src.table_name) <= 330 THEN ''NO''
						ELSE ''YES''
						END
INTO TableList
FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.tables src
WHERE EXISTS (SELECT table_name, COUNT(column_name) 
			  FROM ' + QUOTENAME(@SourceServer) +'.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns t1
			  WHERE t1.table_name = src.table_name
			  GROUP BY table_name
			  HAVING COUNT(column_name) < 330
			  )
AND table_type = ''BASE TABLE''
AND table_name NOT LIKE ''RiskResultsRaw%''
AND table_name IN (SELECT name FROM sys.tables WHERE temporal_type = 0)


INSERT INTO TableList
SELECT name, NULL, NULL, NULL, NULL, NULL, ''YES''
FROM ' + QUOTENAME(@SourceServer) +'.' + QUOTENAME(@SourceDB) + '.sys.tables
WHERE name NOT IN (SELECT table_name FROM TableList)
AND name NOT LIKE ''RiskResultsRaw%''
AND temporal_type = 0'

EXECUTE(@SQL)

-- Generate primary key creation command and add it to the TableList table
IF @@SERVERNAME = @SourceServer
BEGIN
	SET @SQL = 'UPDATE ' + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.TableList
	SET InsertStmt1 = CASE WHEN NonMatchingColumns = 0 THEN InsertStmt1 END,
		InsertStmt2 = CASE WHEN NonMatchingColumns = 0 THEN InsertStmt2 END,
		CreatePK = tmp.CreatePK
	FROM TableList tl
	JOIN (SELECT DISTINCT OBJECT_NAME(ic.object_id) table_name , ''ALTER TABLE '' 
		+ QUOTENAME(OBJECT_NAME(ic.object_id)) + '' WITH CHECK ADD CONSTRAINT ''
		+ QUOTENAME(name) + '' PRIMARY KEY CLUSTERED (''
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
			
			) + '');'' AS CreatePK
	FROM sys.indexes i
	JOIN sys.index_columns ic
	ON i.object_id = ic.object_id
	AND i.index_id = ic.index_id
	WHERE i.is_primary_key = 1) tmp
	ON tmp.table_name = tl.table_name
	WHERE TooManyColumns = ''NO'''

END
ELSE
BEGIN

	SET @SQL = 'DECLARE @SQL NVARCHAR(MAX)
	SET @SQL =''USE ' + QUOTENAME(@SourceDB) + '

	UPDATE ' + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.TableList
	SET InsertStmt1 = CASE WHEN NonMatchingColumns = 0 THEN InsertStmt1 END,
		InsertStmt2 = CASE WHEN NonMatchingColumns = 0 THEN InsertStmt2 END,
		CreatePK = ''''ALTER TABLE '''' 
		+ QUOTENAME(OBJECT_NAME(ic.object_id)) + '''' WITH CHECK ADD CONSTRAINT ''''
		+ QUOTENAME(name) + '''' PRIMARY KEY CLUSTERED (''''
	+ (SELECT STUFF(
					(SELECT '''', '''' + QUOTENAME(COL_NAME(object_id, column_id)) +
						CASE WHEN is_descending_key = 1 THEN '''' DESC''''
							ELSE '''' ASC''''
						END
					FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.sys.index_columns 
					WHERE object_id = ic.object_id
						AND index_id = ic.index_id
					ORDER BY key_ordinal
					FOR XML PATH(N''''''''), TYPE
					).value(N''''.[1]'''', N''''nvarchar(max)''''), 1, 2, N''''''''
				)
			
		) + '''');'''' 
	FROM ' + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.TableList tmp
	JOIN ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.sys.indexes i 
	ON OBJECT_NAME(i.object_id) = tmp.table_name
	JOIN ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.sys.index_columns ic
	ON i.object_id = ic.object_id
	AND i.index_id = ic.index_id
	WHERE i.is_primary_key = 1''

	EXECUTE(@SQL) AT ' + QUOTENAME(@SourceServer) + ''

END

EXECUTE (@SQL)

----------------------------- Copy foreign key constraint definitions from target ----------------------------

--DROP TABLE IF EXISTS ##FKContraints

SET @SQL = 'IF OBJECT_ID(''tempdb..##FKContraints'') IS NULL
BEGIN
	SELECT DISTINCT OBJECT_NAME(fkc1.constraint_object_id) AS FKConstraint, 
					OBJECT_NAME(fkc1.parent_object_id) FKTable, 
					OBJECT_NAME(fkc1.referenced_object_id) ParentTable,
					''IF OBJECT_ID( ''''''+ OBJECT_NAME(constraint_object_id) +'''''', ''''F'''') IS NOT NULL ALTER TABLE ''
					+ QUOTENAME(SCHEMA_NAME(tab.schema_id)) +''.''+ QUOTENAME(OBJECT_NAME(fkc1.parent_object_id)) 
					+ '' DROP CONSTRAINT '' + OBJECT_NAME(fkc1.constraint_object_id) AS DropFK,
	''IF OBJECT_ID( ''''''+ OBJECT_NAME(constraint_object_id) +'''''', ''''F'''') IS NULL ALTER TABLE '' + QUOTENAME(SCHEMA_NAME(tab.schema_id)) +''.''+ QUOTENAME(OBJECT_NAME(fkc1.parent_object_id))
	+ '' WITH CHECK ADD CONSTRAINT '' + QUOTENAME(OBJECT_NAME(constraint_object_id))
	+ CHAR(10) + ''FOREIGN KEY('' + (SELECT STRING_AGG(QUOTENAME(COL_NAME(fkc2.parent_object_id, fkc2.parent_column_id)), '', '') 
						FROM sys.foreign_key_columns fkc2 WHERE constraint_object_id = fkc1.constraint_object_id) 
	+ '')'' + CHAR(10) + '' REFERENCES '' + QUOTENAME(SCHEMA_NAME(tab2.schema_id)) + ''.'' + QUOTENAME(OBJECT_NAME(fkc1.referenced_object_id)) + ''('' 
	+ (SELECT STRING_AGG(QUOTENAME(COL_NAME(fkc2.referenced_object_id, fkc2.referenced_column_id)), '', '')  
	FROM sys.foreign_key_columns fkc2 WHERE constraint_object_id = fkc1.constraint_object_id) +'')'' AS CreateFK
	INTO ##FKContraints
	FROM sys.foreign_key_columns fkc1
	JOIN sys.tables tab
	ON tab.object_id = fkc1.parent_object_id
	JOIN sys.tables tab2 
	ON tab2.object_id = fkc1.referenced_object_id
END'

EXECUTE (@SQL)

----------------------------------- Drop Foreign Key constraints in Target db ---------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT DropFK FROM ##FKContraints
WHERE FKTable NOT LIKE 'SDE_%'

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE(@SQL)
	FETCH NEXT FROM DropFK_Cursor INTO @SQL
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

-------------------------------------- Truncate tables in Target db ---------------------

DECLARE TruncateTab_Cursor CURSOR FOR
SELECT 'TRUNCATE TABLE ' + name 
FROM sys.tables
WHERE name NOT LIKE 'SDE_%' 
AND temporal_type = 0
AND name NOT IN ('TableList')
ORDER BY name

OPEN TruncateTab_Cursor
FETCH NEXT FROM TruncateTab_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE(@SQL)
	FETCH NEXT FROM TruncateTab_Cursor INTO @SQL
END

CLOSE TruncateTab_Cursor
DEALLOCATE TruncateTab_Cursor

----------------------------------- Load Tables ------------------------------

DECLARE LoadTable_Cursor CURSOR FOR
SELECT table_name 
FROM TableList 
WHERE table_name NOT IN (SELECT name FROM sys.tables WHERE temporal_type = 1)
AND table_name IN ('SystemPreferences', 'ACVGSurveyAnomaly')

OPEN LoadTable_Cursor
FETCH NEXT FROM LoadTable_Cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE @SQL1 NVARCHAR(MAX)

	SET @SQL = ''
	SET @SQL1 = ''

	-- If the columns in the target table do not match columns in source table recreate the table in target db
	IF (SELECT NonMatchingColumns FROM TableList WHERE table_name = @TableName) <> 0
	BEGIN
		IF OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableTemporalType') <> 0
		BEGIN

			SET @SQL = 'SELECT @Result = ''DROP TABLE '' + name FROM sys.tables WHERE temporal_type = 1
			AND name like ''%' + @TableName + '%'''

			EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUTPUT', @SQL OUTPUT

			SELECT @SQL = 'ALTER TABLE ' + table_schema + '.' + table_name  + ' SET (SYSTEM_VERSIONING = OFF);'
			+ CHAR(10) + @SQL + CHAR(10)
			FROM INFORMATION_SCHEMA.tables
			WHERE table_name = @TableName

			SELECT DISTINCT @SQL1 = 'ALTER TABLE ' + table_schema + '.' + table_name  + ' DROP COLUMN ValidTo, ValidFrom'
			FROM INFORMATION_SCHEMA.tables
			WHERE table_name = @TableName
		END

		SELECT @SQL += 'DROP TABLE ' + t.table_schema + '.' + t.table_name + CHAR(10) + tl.CreateTableStmt 
		+ CHAR(10) + @SQL1
		FROM INFORMATION_SCHEMA.tables t
		JOIN TableList tl ON tl.table_name = t.table_name
		WHERE t.table_name = @TableName	
	END
	-- else if the table has an identity column turn on identity insert
	ELSE IF OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity') = 1
	BEGIN
		SELECT @SQL = 'SET IDENTITY_INSERT ' + t.table_schema + '.' + @TableName + ' ON' +
		CHAR(10) + InsertStmt1 
		FROM INFORMATION_SCHEMA.tables t
		JOIN TableList tl ON tl.table_name = t.table_name
		WHERE t.table_name = @TableName

		SELECT @SQL1 =  InsertStmt2 + CHAR(10) 
		+ 'SET IDENTITY_INSERT ' + t.table_schema + '.' + @TableName + ' OFF' 
		FROM INFORMATION_SCHEMA.tables t
		JOIN TableList tl ON tl.table_name = t.table_name
		WHERE t.table_name = @TableName

	END
	ELSE
	BEGIN
		SELECT @SQL = InsertStmt1 FROM TableList WHERE table_name = @TableName
		SELECT @SQL1 = InsertStmt2 FROM TableList WHERE table_name = @TableName

	END

	begin try
		EXECUTE (@SQL + @SQL1)
		print @sql
		print @sql1;
	end try
	begin catch
		print @sql
		print @sql1;
		throw
	end catch

	FETCH NEXT FROM LoadTable_Cursor INTO @TableName
END

CLOSE LoadTable_Cursor
DEALLOCATE LoadTable_Cursor

return
/*
-------------------------------------- Re-create Foreign Keys --------------------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT CreateFK FROM ##FKContraints
WHERE FKTable NOT LIKE 'SDE_%'

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE(@SQL)
	FETCH NEXT FROM DropFK_Cursor INTO @SQL
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

*/