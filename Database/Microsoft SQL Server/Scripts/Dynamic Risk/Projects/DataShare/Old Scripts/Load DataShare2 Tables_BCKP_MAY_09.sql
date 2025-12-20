USE tmp_DATASHARE2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SQL NVARCHAR(MAX)

------------------------------ Drop All Foreign Keys ---------------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT DISTINCT 'ALTER TABLE ['+ tableName + '] DROP CONSTRAINT [' + ForeignKeyName + ']' 
FROM ForeignKeys tab2
WHERE ForeignKeyName IN (SELECT name FROM sys.foreign_keys)

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DropFK_Cursor INTO @SQL
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

---------------------------------- Load Tables ------------------------------------

DECLARE LoadTables_Cursor CURSOR FOR
SELECT TableName
FROM DataShareTablesList 
WHERE ENABLEd = 1
--and tablename = 'ListDomain'
--and tablename  IN ('Corporation', 'OperatingUnit', 'PipelineSystem','ListDomain', 'LineLoop', 'StationSeries','Bend')
 
DECLARE @TableName VARCHAR(250)

OPEN LoadTables_Cursor
FETCH NEXT FROM LoadTables_Cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRY
		EXEC sp_LoadTable @TableName
	END TRY
	BEGIN CATCH
		SELECT @TableName
		DEALLOCATE LoadTables_Cursor
		PRINT ERROR_MESSAGE()
		RETURN
	END CATCH

	UPDATE DataShareTablesList SET Enabled = 0
	WHERE TableName = @TableName
	
	FETCH NEXT FROM LoadTables_Cursor INTO @TableName

END

CLOSE LoadTables_Cursor
DEALLOCATE LoadTables_Cursor

--------------------------------------- Recreate Foreign Keys -------------------------------------

-- Add the column order for the referenced primary keys in the ForeignKeys table
BEGIN TRANSACTION
	UPDATE ForeignKeys
	SET ReferencedColumn = 'OriginalId'
	WHERE ReferencedColumn = 'Id';

	UPDATE ForeignKeys
	SET ColumnName = 'OriginalId'
	WHERE ColumnName = 'Id';

	SET @SQL = 'UPDATE ForeignKeys
	SET ColumnId = kcu.Ordinal_Position
	FROM INFORMATION_SCHEMA.key_column_usage kcu
	JOIN ForeignKeys fk
	ON fk.ReferencedTable = kcu.table_name
	AND fk.ReferencedColumn  = kcu.column_name'

	EXECUTE (@SQL)

COMMIT TRANSACTION

DECLARE @ForeignKey NVARCHAR(100)
DECLARE ReCreateFK_Cursor CURSOR FOR
SELECT ForeignKeyName FROM ForeignKeys 

OPEN ReCreateFK_Cursor
FETCH NEXT FROM ReCreateFK_Cursor INTO @ForeignKey

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = ''

	IF NOT EXISTS (SELECT * FROM sys.foreign_keys 
					WHERE name IN (SELECT ForeignKeyName FROM ForeignKeys WHERE TableName = @TableName))
	BEGIN
	
		SELECT DISTINCT @SQL +=	'ALTER TABLE ['+ tableName + '] WITH CHECK ADD CONSTRAINT [' + ForeignKeyName + ']' +
		+ CHAR(10) + 'FOREIGN KEY([Client_Code], ' + (SELECT '[' + STRING_AGG(columnName, '], [') WITHIN GROUP (ORDER BY ColumnId) + ']' 
							FROM ForeignKeys WHERE ForeignKeyName = tab2.ForeignKeyName
							AND ColumnName <> 'Client_Code') + ')' 
		+ CHAR(10) + 'REFERENCES [' + referencedTableSchema + '].[' 
		+ referencedTable + ']([Client_Code], ' + (SELECT '[' + STRING_AGG((CASE referencedColumn WHEN 'Id' THEN 'OriginalId' ELSE referencedColumn END), '], [') WITHIN GROUP (ORDER BY ColumnId)  + ']'
								FROM ForeignKeys tab1 WHERE ForeignKeyName = tab2.ForeignKeyName
								AND referencedColumn <> 'Client_Code') +');' + CHAR(10) + CHAR(10)
		FROM ForeignKeys tab2
		WHERE ForeignKeyName = @ForeignKey 
		AND @ForeignKey NOT IN (SELECT name FROM sys.foreign_keys)
		
		BEGIN TRY
			EXECUTE (@SQL)
		END TRY
		BEGIN CATCH
			PRINT @SQL
			PRINT ERROR_MESSAGE()
			DEALLOCATE ReCreateFK_Cursor
			RETURN
		END CATCH

	END

	FETCH NEXT FROM ReCreateFK_Cursor INTO @ForeignKey
END

CLOSE ReCreateFK_Cursor
DEALLOCATE ReCreateFK_Cursor