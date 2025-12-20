USE DrasInternal

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableList NVARCHAR(MAX)
DECLARE @TargetTable NVARCHAR(100)
DECLARE @TargetSchema NVARCHAR(100)
DECLARE @SourceDB NVARCHAR(100) 
DECLARE @TableName NVARCHAR(100)

SET @SourceDB = 'TestUnifiedModel6'
SET @TargetSchema = 'Unified'
SET @TargetTable = 'TableChecker_Tables'

SET @TableList = 'TblChkErrCenterline
TblChkErrDataGaps
TblChkErrInvalidRecord
TblChkErrOverlap
TblChkErrStationGap'

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = @TargetSchema)
BEGIN
	SET @SQL = 'CREATE SCHEMA ' + @TargetSchema
	EXECUTE (@SQL)
END

DROP TABLE IF EXISTS ##TableList

CREATE TABLE ##TableList (name NVARCHAR(100))
 
SET @SQL = REPLACE(@TableList, ' ', '')
SET @SQL = REPLACE(@SQL, CHAR(10), ' ')
SET @SQL = REPLACE(@SQL, CHAR(13), '')
SET @SQL = REPLACE(@SQL, CHAR(9), '')
SET @SQL = REPLACE(@SQL, ' ', ''')' + CHAR(10) + 'INSERT INTO ##TableList VALUES(''')
SET @SQL = 'INSERT INTO ##TableList VALUES(''' + @SQL + ''')'

EXECUTE (@SQL)

SET @SQL = 'DELETE FROM ##TableList
WHERE name NOT IN (SELECT name FROM ' + @SourceDB + '.sys.tables)'

EXECUTE (@SQL)

DECLARE @SQL2 NVARCHAR(MAX)
DECLARE @SQL1 NVARCHAR(MAX)
DECLARE @SQL3 NVARCHAR(MAX)
DECLARE @counter INT = 4

SET @SQL =  'SELECT @Result = STRING_AGG(name, '' NVARCHAR(1),'') WITHIN GROUP (ORDER BY name) + '' NVARCHAR(1))''
FROM (SELECT TOP 100 name FROM ' + @SourceDB + '.sys.tables
WHERE name IN (SELECT name FROM ##TableList) ORDER BY name) subq'

EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUTPUT', @Result = @SQL OUTPUT


SET @SQL = 'DROP TABLE IF EXISTS ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable)
+ CHAR(10) + 'CREATE TABLE ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' (' +@SQL

EXECUTE (@SQL)

WHILE (SELECT COUNT(*) FROM ##TableList) <> (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE table_name = @TargetTable
AND table_schema = @TargetSchema)
BEGIN

	SET @SQL =  'SELECT @Result = STRING_AGG(name, '' NVARCHAR(1),'') WITHIN GROUP (ORDER BY name) + '' NVARCHAR(1)''
	FROM (SELECT TOP 100 name FROM ' + @SourceDB + '.sys.tables
	WHERE name IN (SELECT name FROM ##TableList) 
	AND name NOT IN (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = ''' + @TargetTable + '''
	AND table_schema = ''' + @TargetSchema + ''')) subq'

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUTPUT', @Result = @SQL OUTPUT
	
	SET @SQL = 'ALTER TABLE ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' ADD ' + @SQL

	EXECUTE (@SQL)

END

