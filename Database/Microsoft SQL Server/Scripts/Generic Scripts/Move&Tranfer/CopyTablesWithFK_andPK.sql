/*
1. This script copies a list of tables from a source database into a target database. Including the
	primary key, unique keys, indexes, foreign keys, default constraints
2. The script should be executed on the target database

You may need to grant VIEW DEFINITION permission to the user running the script or the Linked Server user

*/

DECLARE @TableList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @ObjectName NVARCHAR(100)
DECLARE @Type NVARCHAR(100)
DECLARE @SourceDB NVARCHAR(100)
DECLARE @DropNRecreateTables NVARCHAR(1)
DECLARE @SourceServer VARCHAR(200)
DECLARE @SourceSchema NVARCHAR(100)
DECLARE @TargetSchema NVARCHAR(100)
DECLARE @Schema NVARCHAR(100)
DECLARE @IncludeDependencies CHAR(1)
DECLARE @IncludeIndexes CHAR(1)
DECLARE @TargetColumns VARCHAR(MAX)
DECLARE @PkList VARCHAR(MAX)
DECLARE @TruncateBeforeDelete CHAR(1)


--*********************************************************************************************

-- Adjustable script parameters
SET @DropNRecreateTables = 'N' -- Drop target tables (if they already exist) before re-creating them
SET @TruncateBeforeDelete = 'N' -- Truncate the target table before insert
SET @IncludeDependencies = 'N' -- Include Primary Key, Unique Key, Foreign Key, Default Constraints, Triggers
SET @IncludeIndexes = 'N' --- Copy indexes on tables including primary and unique key index (Only works if index name is not already being used)

-- Set the source database where tables will be copied from
SET @SourceServer = NULL
SET @SourceDB = NULL
SET @SourceSchema = NULL
SET @TargetSchema = NULL

-- set list of tables to be copied
SET @TableList = ''

--********************************************************************************************* 

DROP TABLE IF EXISTS ##TableList
DROP TABLE IF EXISTS ##ErrorTable

CREATE TABLE ##TableList (TableSchema VARCHAR(200), TableName NVARCHAR(100))
CREATE TABLE ##ErrorTable (Command NVARCHAR(MAX), Details NVARCHAR(MAX))

SET @SQL = REPLACE(@TableList, ' ', '')
SET @SQL = REPLACE(@SQL, CHAR(10), ' ')
SET @SQL = REPLACE(@SQL, CHAR(13), '')
SET @SQL = REPLACE(@SQL, CHAR(9), '')
SET @SQL = REPLACE(@SQL, ' ', ''', ''')
SET @SQL = REPLACE(@SQL, ''''', ', '')

SET @TableList = '''' + @SQL + ''''

SET @SourceServer = COALESCE(REPLACE(@SourceServer, LTRIM(RTRIM('')), ''), @@SERVERNAME)
SET @SourceSchema = CASE WHEN LTRIM(RTRIM(@SourceSchema)) = '' THEN NULL ELSE @SourceSchema END
SET @TargetSchema = COALESCE(REPLACE(@TargetSchema, LTRIM(RTRIM('')), NULL), REPLACE(@SourceSchema, LTRIM(RTRIM('')), NULL), 'dbo')

IF @SourceServer = @@SERVERNAME
BEGIN
	SET @SQL = 'INSERT INTO ##TableList
	SELECT DISTINCT table_schema, table_name
	FROM ' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.tables 
	WHERE table_name IN (' + @TableList + ')
	AND table_schema = CASE WHEN ''' + COALESCE(@SourceSchema, 'NULL') + ''' = ''NULL'' THEN table_schema 
	ELSE ''' + COALESCE(@SourceSchema, 'NULL') + ''' END'
END
ELSE 
BEGIN
	SET @SQL = 'INSERT INTO ##TableList
	SELECT DISTINCT table_schema, table_name
	FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.tables 
	WHERE table_name IN (' + @TableList + ')
	AND table_schema = CASE WHEN ''' + COALESCE(@SourceSchema, 'NULL') + ''' = ''NULL'' 
	THEN table_schema ELSE ''' + COALESCE(@SourceSchema, 'NULL') + ''' END'
END

EXECUTE (@SQL)

------------------------------------ Delete all tables from target database ---------------

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = @TargetSchema)
BEGIN
	SET @SQL = 'CREATE SCHEMA ' + @TargetSchema
	EXECUTE(@SQL)
END

IF @DropNRecreateTables = 'Y'
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

-------------------------------- Disable Foreign Keys ---------------------------

-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' NOCHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT TableName FROM ##TableList)
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

IF @TruncateBeforeDelete = 'Y' AND @DropNRecreateTables <> 'Y'
BEGIN
	
	-------------------------------------- DELETE from Tables ------------------------------

	DECLARE DeleteTable_Cursor CURSOR FOR
	SELECT 'TRUNCATE TABLE ' + @TargetSchema + '.' + TableName
	FROM ##TableList WHERE Tablename IN (SELECT name FROM sys.tables)

	OPEN DeleteTable_Cursor
	FETCH NEXT FROM DeleteTable_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN	
		EXECUTE (@SQL)
		FETCH NEXT FROM DeleteTable_Cursor INTO @SQL
	END

	CLOSE DeleteTable_Cursor
	DEALLOCATE DeleteTable_Cursor
END


------------------------ Copy selected tables from source to target database ---------------------- 

DROP TABLE IF EXISTS ##Indexes

IF @SourceServer = @@SERVERNAME
BEGIN
	SET @SQL = 'SELECT t.name AS TableName, 
		sc.name AS TableSchema,
		c.name ColumnName, 
		i.name ConstraintName, 
		CASE WHEN is_primary_key = 1 THEN ''PRIMARY KEY'' WHEN is_unique_constraint = 1 THEN ''UNIQUE KEY'' END AS ConstraintType
		,i.type_desc AS IndexType
		, CASE WHEN is_primary_key = 1 OR is_unique_constraint = 1 THEN 
		''ALTER TABLE dbo.'' + t.name
		+ '' WITH CHECK ADD CONSTRAINT '' 
		+ QUOTENAME(i.name)
		+ CASE WHEN is_primary_key = 1 THEN '' PRIMARY KEY '' WHEN is_unique_constraint = 1 THEN '' UNIQUE '' END + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE ''CREATE '' + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + '' INDEX '' + QUOTENAME(i.name) + '' ON '' + QUOTENAME(sc.name)
		+ ''.'' + QUOTENAME(t.name)  END + '' (''
		+ (SELECT STUFF(
						(SELECT '', '' + QUOTENAME(c2.name) +
							CASE WHEN is_descending_key = 1 THEN '' DESC''
								ELSE '' ASC''
							END
						FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic2
						JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c2 ON c2.column_id = ic2.column_id
						AND c2.object_id = ic2.object_id
						WHERE ic2.object_id = ic.object_id
						AND ic2.index_id = ic.index_id
						AND ic2.is_included_column = 0
						ORDER BY key_ordinal
						FOR XML PATH(N''''), TYPE
						).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
					) 
			
			) + '')'' + CASE WHEN EXISTS (SELECT * FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns 
			WHERE object_id = i.object_id AND index_id = i.index_id AND is_included_column = 1) THEN
					'' INCLUDE ('' + COALESCE((SELECT STUFF(
						(SELECT '', '' + QUOTENAME(c2.name)
						FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic2
						JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c2 ON c2.column_id = ic2.column_id
						AND c2.object_id = ic2.object_id
						WHERE ic2.object_id = ic.object_id
						AND ic2.index_id = ic.index_id
						AND ic2.is_included_column = 1
						ORDER BY key_ordinal
						FOR XML PATH('''')
						), 1, 2, ''''
					)), '''') + '')'' ELSE '''' END +  '' WITH (PAD_INDEX ='' + CASE WHEN is_padded = 0 THEN '' OFF'' ELSE '' ON'' END 
					+ '', STATISTICS_NORECOMPUTE ='' + CASE WHEN s.no_recompute = 0 THEN '' OFF'' ELSE '' ON'' END 
					+ '', ALLOW_ROW_LOCKS ='' + CASE WHEN allow_row_locks = 0 THEN '' OFF'' ELSE '' ON'' END 
					+ '', ALLOW_PAGE_LOCKS ='' + CASE WHEN allow_page_locks = 0 THEN '' OFF'' ELSE '' ON'' END + '')''   AS Index_Definition
		INTO ##Indexes
		FROM ' + QUOTENAME(@SourceDB) + '.sys.indexes i
		JOIN ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
		JOIN ' + QUOTENAME(@SourceDB) + '.sys.stats s ON  s.object_id = i.object_id AND s.name = i.name
		JOIN ' + QUOTENAME(@SourceDB) + '.sys.tables t ON i.object_id = t.object_id
		JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas sc ON sc.schema_id = t.schema_id'

END
ELSE
BEGIN
	SET @SQL = 'SELECT *
	INTO ##Indexes
	FROM OPENQUERY (' + QUOTENAME(@SourceServer) + ', ''
	SELECT t.name AS TableName, 
	sc.name AS TableSchema,
	c.name ColumnName, 
	i.name ConstraintName, 
	CASE WHEN is_primary_key = 1 THEN ''PRIMARY KEY'' WHEN is_unique_constraint = 1 THEN ''UNIQUE KEY'' END AS ConstraintType
	,i.type_desc AS IndexType
	, CASE WHEN is_primary_key = 1 OR is_unique_constraint = 1 THEN 
	''''ALTER TABLE dbo.'''' + t.name
	+ '''' WITH CHECK ADD CONSTRAINT '''' 
	+ QUOTENAME(i.name)
	+ CASE WHEN is_primary_key = 1 THEN '''' PRIMARY KEY '''' WHEN is_unique_constraint = 1 THEN '''' UNIQUE '''' END + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS 
	ELSE ''''CREATE '''' + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + '''' INDEX '''' + QUOTENAME(i.name) + '''' ON '''' + QUOTENAME(sc.name)
	+ ''''.'''' + QUOTENAME(t.name)  END + '''' (''''
	+ (SELECT STUFF(
					(SELECT '''', '''' + QUOTENAME(c2.name) +
						CASE WHEN is_descending_key = 1 THEN '''' DESC''''
							ELSE '''' ASC''''
						END
					FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic2
					JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c2 ON c2.column_id = ic2.column_id
					AND c2.object_id = ic2.object_id
					WHERE ic2.object_id = ic.object_id
					AND ic2.index_id = ic.index_id
					AND ic2.is_included_column = 0
					ORDER BY key_ordinal
					FOR XML PATH(N''''''''), TYPE
					).value(N''''.[1]'''', N''''nvarchar(max)''''), 1, 2, N''''''''
				) 
			
		) + '''')'''' + CASE WHEN EXISTS (SELECT * FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns 
		WHERE object_id = i.object_id AND index_id = i.index_id AND is_included_column = 1) THEN
				'''' INCLUDE ('''' + COALESCE((SELECT STUFF(
					(SELECT '''', '''' + QUOTENAME(c2.name)
					FROM ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic2
					JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c2 ON c2.column_id = ic2.column_id
					AND c2.object_id = ic2.object_id
					WHERE ic2.object_id = ic.object_id
					AND ic2.index_id = ic.index_id
					AND ic2.is_included_column = 1
					ORDER BY key_ordinal
					FOR XML PATH('''''''')
					), 1, 2, ''''''''
				)), '''''''') + '''')'''' ELSE '''''''' END +  '''' WITH (PAD_INDEX ='''' + CASE WHEN is_padded = 0 THEN '''' OFF'''' ELSE '''' ON'''' END 
				+ '''', STATISTICS_NORECOMPUTE ='''' + CASE WHEN s.no_recompute = 0 THEN '''' OFF'''' ELSE '''' ON'''' END 
				+ '''', ALLOW_ROW_LOCKS ='''' + CASE WHEN allow_row_locks = 0 THEN '''' OFF'''' ELSE '''' ON'''' END 
				+ '''', ALLOW_PAGE_LOCKS ='''' + CASE WHEN allow_page_locks = 0 THEN '''' OFF'''' ELSE '''' ON'''' END + '''')''''   AS Index_Definition
	FROM ' + QUOTENAME(@SourceDB) + '.sys.indexes i
	JOIN ' + QUOTENAME(@SourceDB) + '.sys.index_columns ic
	ON i.object_id = ic.object_id
	AND i.index_id = ic.index_id
	JOIN ' + QUOTENAME(@SourceDB) + '.sys.stats s ON  s.object_id = i.object_id AND s.name = i.name
	JOIN ' + QUOTENAME(@SourceDB) + '.sys.tables t ON i.object_id = t.object_id
	JOIN ' + QUOTENAME(@SourceDB) + '.sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
	JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas sc ON sc.schema_id = t.schema_id'')'
END

EXECUTE (@SQL)

------------------------------------------ Generate Foreign key definitions --------------------------------------

DROP TABLE IF EXISTS ##FKContraints

IF @SourceServer = @@SERVERNAME
BEGIN
	SET @SQL = 'SELECT DISTINCT ct.name FKTable, scc.name AS ChildTableSchema, ct.name AS ChildTable, cc.name AS ChildColumn, scp.name ParentTableSchema,
	pt.name ParentTable, pc.name AS ParentColumn, fk.name ConstraintName,
			''IF OBJECT_ID( ''''''+ fk.name +'''''', ''''F'''') IS NULL BEGIN ALTER TABLE ['' + scc.name +''].[''+ ct.name 
			+ ''] WITH CHECK ADD CONSTRAINT ['' + fk.name + '']'' 
			+ CHAR(10) + ''FOREIGN KEY('' + (SELECT STUFF(
														(SELECT '', '' + QUOTENAME(c2.name)
															FROM ' + @SourceDB+ '.sys.foreign_key_columns fkc2 
															JOIN ' + @SourceDB+ '.sys.columns c2 ON c2.object_id = fkc2.parent_object_id
															AND c2.column_id = fkc2.parent_column_id
															WHERE constraint_object_id = fkc.constraint_object_id
															ORDER BY fkc2.constraint_column_id
															FOR XML PATH(N''''), TYPE
															).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
														)
													)
						+ CHAR(10) + '') REFERENCES '' + QUOTENAME(scp.name) + ''.'' + QUOTENAME(pt.name) + ''('' 
						+ (SELECT STUFF(
										(SELECT '', '' + QUOTENAME(c2.name)
										FROM ' + @SourceDB+ '.sys.foreign_key_columns fkc2 
										JOIN ' + @SourceDB+ '.sys.columns c2 ON c2.object_id = fkc2.referenced_object_id
										AND c2.column_id = fkc2.referenced_column_id
										WHERE constraint_object_id = fkc.constraint_object_id
										ORDER BY fkc2.constraint_column_id
										FOR XML PATH(N''''), TYPE
										).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
									  )
							)
							+'')
						END '' AS FK_Definition
			INTO ##FKContraints
			FROM ' + @SourceDB+ '.sys.foreign_keys fk
			JOIN ' + @SourceDB+ '.sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
			JOIN ' + @SourceDB+ '.sys.tables ct
			ON ct.object_id = fkc.parent_object_id
			JOIN ' + @SourceDB+ '.sys.tables pt 
			ON pt.object_id = fkc.referenced_object_id
			JOIN ' + @SourceDB+ '.sys.columns cc ON cc.object_id = fkc.parent_object_id AND fkc.parent_column_id = cc.column_id
			JOIN ' + @SourceDB+ '.sys.columns pc ON pc.object_id = fkc.referenced_object_id AND fkc.referenced_column_id = pc.column_id
			JOIN ' + @SourceDB+ '.sys.schemas scp ON scp.schema_id = pt.schema_id
			JOIN ' + @SourceDB+ '.sys.schemas scc ON scc.schema_id = ct.schema_id'
END
ELSE
BEGIN
	SET @SQL = 'SELECT * INTO ##FKContraints
	FROM OPENQUERY(' + QUOTENAME(@SourceServer) + ', ''SELECT DISTINCT ct.name FKTable, scc.name AS ChildTableSchema, ct.name AS ChildTable, cc.name AS ChildColumn, fkc. scp.name ParentTableSchema,
	pt.name ParentTable, pc.name AS ParentColumn, fk.name ConstraintName,
			''''IF OBJECT_ID( ''''''''''''+ fk.name +'''''''''''', ''''''''F'''''''') IS NULL BEGIN ALTER TABLE ['''' + scc.name +''''].[''''+ ct.name 
			+ ''''] WITH CHECK ADD CONSTRAINT ['''' + fk.name + '''']'''' 
			+ CHAR(10) + ''''FOREIGN KEY('''' + (SELECT STUFF(
														(SELECT '''', '''' + QUOTENAME(c2.name)
															FROM ' + @SourceDB+ '.sys.foreign_key_columns fkc2 
															JOIN ' + @SourceDB+ '.sys.columns c2 ON c2.object_id = fkc2.parent_object_id
															AND c2.column_id = fkc2.parent_column_id
															WHERE constraint_object_id = fkc.constraint_object_id
															ORDER BY fkc2.constraint_column_id
															FOR XML PATH(N''''''''), TYPE
															).value(N''''.[1]'''', N''''nvarchar(max)''''), 1, 2, N''''''''
														)
													)
						+ CHAR(10) + '''') REFERENCES '''' + QUOTENAME(scp.name) + ''''.'''' + QUOTENAME(pt.name) + ''''('''' 
						+ (SELECT STUFF(
										(SELECT '''', '''' + QUOTENAME(c2.name)
										FROM ' + @SourceDB+ '.sys.foreign_key_columns fkc2 
										JOIN ' + @SourceDB+ '.sys.columns c2 ON c2.object_id = fkc2.referenced_object_id
										AND c2.column_id = fkc2.referenced_column_id
										WHERE constraint_object_id = fkc.constraint_object_id
										ORDER BY fkc2.constraint_column_id
										FOR XML PATH(N''''''''), TYPE
										).value(N''''.[1]'''', N''''nvarchar(max)''''), 1, 2, N''''''''
									  )
							)
							+'''')
						END '''' AS FK_Definition
			FROM ' + @SourceDB+ '.sys.foreign_keys fk
			JOIN ' + @SourceDB+ '.sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
			JOIN ' + @SourceDB+ '.sys.tables ct
			ON ct.object_id = fkc.parent_object_id
			JOIN ' + @SourceDB+ '.sys.tables pt 
			ON pt.object_id = fkc.referenced_object_id
			JOIN ' + @SourceDB+ '.sys.columns cc ON cc.object_id = fkc.parent_object_id AND fkc.parent_column_id = cc.column_id
			JOIN ' + @SourceDB+ '.sys.columns pc ON pc.object_id = fkc.referenced_object_id AND fkc.referenced_column_id = pc.column_id
			JOIN ' + @SourceDB+ '.sys.schemas scp ON scp.schema_id = pt.schema_id
			JOIN ' + @SourceDB+ '.sys.schemas scc ON scc.schema_id = ct.schema_id'')'
END

EXECUTE (@SQL)

----------------------------- Get Default Constraint Definitions ----------------------------

DROP TABLE IF EXISTS ##DefaultConstraints

IF @SourceServer = @@SERVERNAME
BEGIN
	SET @SQL = 'SELECT df.name ConstraintName, t.name AS TableName, sc.name AS TableSchema, c.name ColumnName,
					''ALTER TABLE '' + t.name + ''
					ADD CONSTRAINT '' + df.name + '' DEFAULT '' + definition + '' FOR '' + c.name AS Constraint_def		 
		INTO ##DefaultConstraints 
		FROM ' + @SourceDB + '.sys.default_constraints df
		JOIN ' + @SourceDB + '.sys.tables t ON t.object_id = df.parent_object_id
		JOIN ' + @SourceDB + '.sys.columns c ON c.object_id = df.parent_object_id
		AND c.column_id = df.parent_column_id
		JOIN sys.schemas sc ON sc.schema_id = t.schema_id'	
END
ELSE
BEGIN
	SET @SQL = 'SELECT * INTO ##DefaultConstraints FROM OPENQUERY(' + QUOTENAME(@SourceServer) + ', ''
				SELECT df.name ConstraintName, t.name AS TableName, sc.name AS TableSchema, c.name ColumnName,
						''''ALTER TABLE '''' + t.name + ''''
						ADD CONSTRAINT '''' + df.name + '''' DEFAULT '''' + definition + '''' FOR '''' + c.name AS Constraint_def		 
			FROM ' + @SourceDB + '.sys.default_constraints df
			JOIN ' + @SourceDB + '.sys.tables t ON t.object_id = df.parent_object_id
			JOIN ' + @SourceDB + '.sys.columns c ON c.object_id = df.parent_object_id
			AND c.column_id = df.parent_column_id
			JOIN sys.schemas sc ON sc.schema_id = t.schema_id'')'
END

EXECUTE (@SQL)



DROP TABLE IF EXISTS ##SourceObjects

IF @SourceServer = @@SERVERNAME
BEGIN
	SET @SQL = 'SELECT obj.name AS ObjectName,
							obj.type_desc AS ObjectType,
							sch.name TableSchema,
							tab.name AS TableName,
							m.definition AS definition,
							5 AS Ranking
				INTO ##SourceObjects
				FROM ' + @SourceDB + '.sys.sql_modules m 
				JOIN ' + @SourceDB + '.sys.objects obj ON obj.object_id = m.object_id
				JOIN ' + @SourceDB + '.sys.tables tab ON tab.object_id = obj.parent_object_id
				JOIN ' + @SourceDB + '.sys.schemas sch ON sch.schema_id = tab.schema_id'
END
ELSE
BEGIN
	SET @SQL = 'SELECT * INTO ##SourceObjects
	FROM OPENQUERY(' + QUOTENAME(@SourceServer) + ',
					''SELECT obj.name AS ObjectName,
							obj.type_desc ObjectType,
							sch.name TableSchema,
							tab.name TableName,
							m.definition AS definition
						FROM ' + @SourceDB + '.sys.sql_modules m 
						JOIN ' + @SourceDB + '.sys.objects obj ON obj.object_id = m.object_id
						JOIN ' + @SourceDB + '.sys.tables tab ON tab.object_id = obj.parent_object_id
						JOIN ' + @SourceDB + '.sys.schemas sch ON sch.schema_id = tab.schema_id'')'
END

EXECUTE (@SQL)  

INSERT INTO ##SourceObjects (ObjectName, ObjectType, TableSchema, TableName, definition, Ranking)
SELECT ConstraintName, 'DEFAULT CONSTRAINT', TableSchema, TableName, Constraint_def, 4AS Ranking FROM ##DefaultConstraints
WHERE ConstraintName NOT IN (SELECT ObjectName FROM ##SourceObjects)
UNION
SELECT ConstraintName, 'FOREIGN KEY', ChildTableSchema, ChildTable, FK_Definition, 3 FROM ##FKContraints
WHERE ConstraintName NOT IN (SELECT ObjectName FROM ##SourceObjects)
UNION
SELECT ConstraintName, CASE WHEN ConstraintType IS NOT NULL THEN ConstraintType ELSE IndexType + ' INDEX' COLLATE SQL_Latin1_General_CP1_CI_AS END
,TableSchema, TableName, Index_Definition, CASE WHEN ConstraintType IS NOT NULL THEN 1 ELSE 2 END FROM ##Indexes
WHERE ConstraintName NOT IN (SELECT ObjectName FROM ##SourceObjects)

-------------------------------- Copy Table data --------------------------------------------

DECLARE TableList_Cursor CURSOR FOR
SELECT DISTINCT TableSchema, TableName FROM ##TableList

OPEN TableList_Cursor
FETCH NEXT FROM TableList_Cursor INTO @SourceSchema, @Tablename

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = NULL
	SET @TargetColumns = NULL
	SET @PkList = NULL
	DROP TABLE IF EXISTS ##TargetColumns 
	DROP TABLE IF EXISTS ##SourceColumns

	IF @SourceServer = @@SERVERNAME
	BEGIN
		SET @SQL = 'SELECT column_name INTO ##TargetColumns
		FROM ' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns
		WHERE table_name = ''' + @TableName + '''
		AND (OBJECT_ID(''' + @TableName + ''') IS NOT NULL 
		AND column_name IN (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = ''' + @TableName + '''))'
	END
	ELSE
	BEGIN
		SET @SQL = 'SELECT column_name INTO ##TargetColumns
		FROM ' + QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.columns
		WHERE table_name = ''' + @TableName + '''
		AND (OBJECT_ID(''' + @TableName + ''') IS NOT NULL 
		AND column_name IN (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = ''' + @TableName + '''))'
	END


	EXECUTE (@SQL)

	-- Generate list of PK columns for table to use filter out rows already inserted in tables
	SELECT @PKList = COALESCE(@PKList + ' AND ', '') + ' t1.' + ColumnName + ' = t2.' + ColumnName 
	FROM ##Indexes
	WHERE TableName = @TableName AND IndexType = 'PK'
	
	SET @SQL = 'SELECT @TargetColumns = COALESCE(@TargetColumns + '', '', '''') + column_name 
	FROM ##TargetColumns'

	EXECUTE sp_executesql @SQL, N'@TargetColumns VARCHAR(MAX) OUTPUT', @TargetColumns OUTPUT

	IF OBJECT_ID(@TargetSchema + '.' + @TableName, 'U') IS NOT NULL
	BEGIN
		IF @SourceServer = @@SERVERNAME
		BEGIN
			SET @SQL = 'INSERT INTO ' + @TargetSchema + '.' + @TableName + ' (' + @TargetColumns + ')
			SELECT ' + @TargetColumns + ' 
			FROM ' + QUOTENAME(@SourceDB) + '.' + @SourceSchema + '.' + @TableName + ' t1
			WHERE NOT EXISTS (SELECT * FROM ' + @TargetSchema + '.' + @TableName + ' t2 WHERE ' + @PkList + ')'
		END
		ELSE
		BEGIN
			SET @SQL = 'INSERT INTO ' + @TargetSchema + '.' + @TableName + ' (' + @TargetColumns + ')
			SELECT * FROM OPENQUERY(' + QUOTENAME(@SourceServer) + ' ,''SELECT ' + @TargetColumns + ' 
			FROM ' + QUOTENAME(@SourceDB) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@TableName) + ''') t1
			WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TableName) + ' t2 
			WHERE ' + @PkList + ')'
		END

		IF OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity') = 1 AND @SQL LIKE '%INSERT INTO%'
		BEGIN
			SET @SQL = 'SET IDENTITY_INSERT ' + @TableName + ' ON ' + CHAR(10) + @SQL 
			+ 'SET IDENTITY_INSERT ' + @TableName + ' OFF '
		END
	END


	IF @SourceServer = @@SERVERNAME AND OBJECT_ID(@TargetSchema + '.' + @TableName, 'U') IS NULL
	BEGIN
		SET @SQL = '
		SELECT ' + COALESCE(@TargetColumns, '*') + ' 
		INTO ' + @TargetSchema + '.' + @TableName + '
		FROM ' + QUOTENAME(@SourceDB) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@TableName)
	END
	ELSE IF OBJECT_ID(@TargetSchema + '.' + @TableName, 'U') IS NULL
	BEGIN
		SET @SQL = 'SELECT * INTO ' + @TargetSchema + '.' + @TableName + '
		FROM OPENQUERY(' + QUOTENAME(@SourceServer) + ' ,''SELECT ' + COALESCE(@TargetColumns, '*') + ' 
		FROM ' + QUOTENAME(@SourceDB) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@TableName) + ''')'
	END

	BEGIN TRY
		EXECUTE (@SQL)
	END TRY
	BEGIN CATCH
		PRINT @SQL;
		THROW
	END CATCH

	FETCH NEXT FROM TableList_Cursor INTO @SourceSchema, @Tablename
END 

CLOSE TableList_Cursor
DEALLOCATE TableList_Cursor

------------------------------- Copy Dependencies (i.e primary key, foreign key, etc) from source ----------------------

-- Add primary key, unique keys, indexes, foreign keys, default constraints, triggers
IF @IncludeDependencies = 'Y' AND @IncludeIndexes = 'Y'
BEGIN

	DECLARE AddDependents_cur CURSOR FOR
	SELECT ObjectName, TableName, ObjectType, definition FROM ##SourceObjects so
	WHERE TableName IN (SELECT TableName FROM ##TableList) 
	AND so.ObjectName NOT IN (SELECT name FROM sys.objects)
	AND EXISTS (SELECT * FROM ##FKContraints fk
							   WHERE so.ObjectName = fk.ConstraintName
							   AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = fk.ParentTable 
											AND column_name = fk.ParentColumn)
				OR so.ObjectType <> 'FOREIGN KEY'
		)   
	ORDER BY Ranking
END
ELSE IF @IncludeDependencies = 'Y' AND @IncludeIndexes = 'N'
BEGIN
	DECLARE AddDependents_cur CURSOR FOR
	SELECT ObjectName, TableName, ObjectType, definition FROM ##SourceObjects so
	WHERE TableName IN (SELECT TableName FROM ##TableList) 
	AND so.ObjectName NOT IN (SELECT name FROM sys.objects)
	AND EXISTS (SELECT * FROM ##FKContraints fk
							   WHERE so.ObjectName = fk.ConstraintName
							   AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = fk.ParentTable 
											AND column_name = fk.ParentColumn)
				OR so.ObjectType <> 'FOREIGN KEY'
		)   
	AND so.ObjectType NOT LIKE '%INDEX%'
	ORDER BY Ranking
END
ELSE IF @IncludeDependencies = 'N' AND @IncludeIndexes = 'Y'
BEGIN
	DECLARE AddDependents_cur CURSOR FOR
	SELECT ObjectName, TableName, ObjectType, definition FROM ##SourceObjects so
	WHERE TableName IN (SELECT TableName FROM ##TableList) 
	AND so.ObjectName NOT IN (SELECT name FROM sys.objects)  
	AND so.ObjectName IN (SELECT ConstraintName FROM ##Indexes)
	ORDER BY Ranking
END
ELSE
BEGIN
	DECLARE AddDependents_cur CURSOR FOR
	SELECT ObjectName, TableName, ObjectType, definition FROM ##SourceObjects so
	WHERE ObjectName IS NULL 
END

OPEN AddDependents_cur
FETCH NEXT FROM AddDependents_cur INTO @ObjectName, @TableName, @Type, @SQL

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRY
		PRINT 'Creating Dependency ' + @ObjectName + ' ON Table '
		EXECUTE (@SQL)
	END TRY
	BEGIN CATCH
		PRINT @SQL;
		THROW
	END CATCH
	FETCH NEXT FROM AddDependents_cur INTO @ObjectName, @TableName, @Type, @SQL
END


CLOSE AddDependents_cur
DEALLOCATE AddDependents_cur
 

IF @DropNRecreateTables = 'Y'
BEGIN
	SELECT TableName AS [Dropped the following tables before copying data into them] 
	FROM ##TableList 
END

IF @TruncateBeforeDelete = 'Y'
BEGIN
	SELECT TableName AS [DELETED data from the following tables before copying data into them] 
	FROM ##TableList 
END
ELSE
BEGIN
	SELECT TableName AS [Copied data to the following tables] FROM ##TableList
END

IF EXISTS (SELECT * FROM ##ErrorTable)
BEGIN
	SELECT * FROM ##ErrorTable
END

------------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE EnableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTEnAME(SCHEMA_NAME(t1.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc.parent_object_id))
		+ ' CHECK CONSTRAINT ' + QUOTENAME(OBJECT_NAME(fkc.constraint_object_id)) AS fk_constraint
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) IN (SELECT TableName FROM ##TableList)
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

