/*
Loads missing data from the Source database tables into the target database tables

Prerequisites
1) Run this script from the Destination/target Server
2) Tables must already exist in the target database

*/

DECLARE @TableName NVARCHAR(100)
DECLARE @SchemaName NVARCHAR(100)
DECLARE @ColumnList NVARCHAR(MAX)
DECLARE @SourceServer NVARCHAR(100)
DECLARE @SourceDB NVARCHAR(100)
DECLARE @TargetDB NVARCHAR(100)
DECLARE @TargetServer NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @IsMissingRows INT

SET @SourceServer = 'SQL2019'
SET @TargetServer = 'SQL2016'
SET @SourceDB = 'EEC_US_TRANS_IRASv6_IRASP_STAGE'
SET @TargetDB = 'EEC_US_TRANS_IRASv6_IRASP_STAGE'

IF OBJECT_ID('tempdb..##TableList') IS NOT NULL
BEGIN
	DROP TABLE ##TableList;
END

IF OBJECT_ID('tempdb..##TableList') IS NULL
BEGIN
	CREATE TABLE ##TableList (TableName NVARCHAR(100), SchemaName NVARCHAR(100),NumMissingRows INT)
END

SET @SQL = 'SELECT name, SCHEMA_NAME(schema_id)
FROM '+ @SourceServer +'.' + @SourceDB + '.sys.tables
WHERE EXISTS (SELECT * FROM ' + @TargetServer + '.' + @TargetDB + '.sys.tables)
ORDER BY 1'
				
INSERT INTO ##TableList (Tablename, SchemaName)
EXECUTE (@SQL)

IF (SELECT @@SERVERNAME )= @TargetServer AND (SELECT DB_NAME()) = @TargetDB
BEGIN
	DECLARE GetRowCount_Cursor CURSOR FOR
	SELECT TableName, SchemaName FROM ##TableList

	OPEN GetRowCount_Cursor
	FETCH NEXT FROM GetRowCount_Cursor INTO @TableName, @SchemaName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'UPDATE ##TableList
		SET NumMissingRows = ((SELECT COUNT(*) FROM ' + @SourceServer + '.' + @SourceDB + '.' + @SchemaName+ '.' + @TableName + ')
		- (SELECT COUNT(*) FROM ' + @SchemaName+ '.' + @TableName + '))
		WHERE TableName = ''' + @TableName + '''
		AND SchemaName = ''' + @SchemaName +''''

		EXECUTE (@SQL)

		FETCH NEXT FROM GetRowCount_Cursor INTO @TableName, @SchemaName
	END

	CLOSE GetRowCount_Cursor
	DEALLOCATE GetRowCount_Cursor

	select * from ##TableList where NumMissingRows <> 0	 order by 3 desc
	return

	DECLARE TableList_Cursor CURSOR FOR
	SELECT TableName, SchemaName 
	FROM ##TableList
	WHERE NumMissingRows <> 0

	OPEN TableList_Cursor
	FETCH NEXT FROM TableList_Cursor INTO @TableName, @SchemaName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT 'Loading Table ' + @TableName	
			
		SET @ColumnList = NULL
				
		IF (SELECT OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity')) = 1
		BEGIN
			SELECT @ColumnList = COALESCE(@ColumnList + '], [', '[') + name 
			FROM sys.columns
			WHERE OBJECT_NAME(object_id) = @TableName
			ORDER BY column_id

			SET @ColumnList += ']'

			SET @SQL = 'USE ' + @TargetDB + CHAR(10) +
			'SET IDENTITY_INSERT '+ @SchemaName +'.' + @TableName +' ON' + CHAR(10) +
			'BEGIN TRANSACTION' + CHAR(10) +
			'INSERT INTO ' + @SchemaName + '.' + @TableName + ' (' + @ColumnList +')' + CHAR(10)
		END
		ELSE
		BEGIN
			SET @SQL = 'USE ' + @TargetDB + CHAR(10) +
			'BEGIN TRANSACTION' + CHAR(10) +
			'INSERT INTO ' + @SchemaName + '.' + @TableName + CHAR(10)
		END

		BEGIN TRY
		SET @SQL += 'SELECT * FROM ' + @SourceServer + '.' + @SourceDB + '.' + @SchemaName + '.' + @TableName + CHAR(10)
				+ 'WHERE NOT EXISTS (SELECT * FROM ' + @SchemaName + '.' + @TableName + ')' + CHAR(10)
				+ 'COMMIT TRANSACTION'
			
			
		EXECUTE (@SQL)
		END TRY
		BEGIN CATCH
			SELECT @SQL
			PRINT ERROR_MESSAGE()
			BREAK

		END CATCH
		

		FETCH NEXT FROM TableList_Cursor INTO @TableName, @SchemaName
	END
	
	CLOSE TableList_Cursor
	DEALLOCATE TableList_Cursor
END
GO

