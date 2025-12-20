/*
	This script copies missing tables from a source database to a destination database
*/
DECLARE @SourceDB NVARCHAR(100) = 'PAA_CIM_PROD'
DECLARE @TargetDB NVARCHAR(100) = 'PAA_OneBaseTest_old_DELETE_ME'

DECLARE @SQL NVARCHAR(MAX)
IF OBJECT_ID('tempdb..##TableList') IS NOT NULL
BEGIN
	DROP TABLE ##TableList;
END

SET @SQL = '
SELECT ''IF OBJECT_ID('''''' + table_schema + ''.'' + table_name + '''''') IS NULL'' + CHAR(10) 
		+ ''BEGIN'' + CHAR(10) + ''	SELECT * INTO ' + @TargetDB + '.'' + table_schema + ''.'' 
		+ table_name + CHAR(10) + ''	FROM ' + @SourceDB + '.'' + table_schema + ''.'' + table_name 
		+ CHAR(10) + ''END'' AS ddl
INTO ##TableList
FROM
(
	SELECT * 
	FROM ' + @SourceDB + '.INFORMATION_SCHEMA.tables 
	WHERE table_name in
	(
		SELECT table_name FROM ' + @SourceDB + '.INFORMATION_SCHEMA.tables
		EXCEPT
		SELECT table_name from ' + @TargetDB + '.INFORMATION_SCHEMA.tables
	) 
)sub'

EXECUTE (@SQL)

DECLARE CopyMissingTable_Cursor CURSOR FOR 
SELECT * FROM ##TableList

OPEN CopyMissingTable_Cursor
FETCH NEXT FROM CopyMissingTable_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	--SELECT @SQL
	FETCH NEXT FROM CopyMissingTable_Cursor INTO @SQL
END

CLOSE CopyMissingTable_Cursor
DEALLOCATE CopyMissingTable_Cursor

