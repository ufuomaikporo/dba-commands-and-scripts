/*
	This script stores index definitions for selected indexes in a permanent table, then drops the selected indexes
*/
--Declare Variables
DECLARE @IndexName NVARCHAR(100) = 'IX_ILIJoint_StationRangeId'
DECLARE @GetIndexInfo NVARCHAR(MAX)
DECLARE @Columnname NVARCHAR(100) = 'InlineInspectionRangeId'
DECLARE @TableName NVARCHAR(100) = 'InlineInspectionJoint'
DECLARE @ColumnList NVARCHAR(600)
DECLARE @sql NVARCHAR(MAX)
DECLARE @GetExistsCheck NVARCHAR(100)
DECLARE @IfExistsCheck INT

-- Temp table to store info for rebulding index
DECLARE @IndexInfo_Tab TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
							index_name NVARCHAR(100), 
							type NVARCHAR(50), 
							table_name NVARCHAR(100), 
							column_name NVARCHAR(100),
							is_descending CHAR(3),
							index_column_id INT,
							is_included_column INT,
							is_padded NVARCHAR(3),
							allow_row_locks NVARCHAR(3),
							allow_page_locks NVARCHAR(3),
							optimize_for_sequential_key NVARCHAR(3))

-- Permanent table to store commands for recreating an index
IF OBJECT_ID('Temp_Index_Definition') IS NULL
BEGIN
	EXECUTE ('CREATE TABLE Temp_Index_Definition (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, index_name NVARCHAR(100), definition NVARCHAR(MAX)
												)'
			)
END

-- Command to generate index info
SET @GetIndexInfo = 'DECLARE @result TABLE (index_name NVARCHAR(100), 
											type NVARCHAR(50), 
											table_name NVARCHAR(100), 
											column_name NVARCHAR(100),
											is_descending CHAR(3),
											index_column_id INT,
											is_included_column INT,
											is_padded NVARCHAR(3),
											allow_row_locks NVARCHAR(3),
											allow_page_locks NVARCHAR(3),
											optimize_for_sequential_key NVARCHAR(3))
INSERT INTO @result
SELECT DISTINCT(ind.name) AS index_name,
		ind.type_desc,
		OBJECT_NAME(ind.object_id) AS table_name, 
	   COL_NAME(ind.object_id, column_id) AS column_name,  
	  CASE
			WHEN is_descending_key = 0 THEN ''ASC''
			ELSE ''DESC''
	  END AS is_descending,
	  ind_col.Index_column_id,
	  is_included_column,
	  CASE
		WHEN is_padded = 0 THEN ''OFF''
		ELSE ''ON''
	  END AS is_padded,
	  CASE
		WHEN allow_row_locks = 1 THEN ''ON''
		ELSE ''OFF''
	  END AS allow_row_locks,
	  CASE
		WHEN allow_page_locks = 1 THEN ''ON''
		ELSE ''OFF''
	  END AS allow_page_locks,
	  CASE
		WHEN optimize_for_sequential_key = 0 THEN ''OFF''
		ELSE ''ON''
	  END AS optimize_for_sequential_key
FROM sys.index_columns ind_col
	JOIN sys.indexes ind ON ind_col.object_id = ind.object_id
		AND ind_col.index_id = ind.index_id
WHERE ind.name = any (SELECT ind.name 
FROM sys.index_columns ind_col
JOIN sys.indexes ind ON ind_col.object_id = ind.object_id
	AND ind_col.index_id = ind.index_id 
WHERE COL_NAME(ind.object_id, ind_col.column_id) = ''' + @Columnname + '''
AND OBJECT_NAME(ind.object_id) = ''' + @TableName + '''
AND is_primary_key = 0
)
ORDER BY 1, 6
SELECT * FROM @result'

--SELECT * FROM sys.indexes
INSERT INTO @IndexInfo_Tab
EXECUTE (@GetIndexInfo)

-- Cursor to cycle through each index on a specific column and generate the CREATE INDEX command for each index that is to be dropped
DECLARE IndexOnCol_Cursor CURSOR FOR
SELECT DISTINCT(index_name) FROM @IndexInfo_Tab

OPEN IndexOnCol_Cursor
FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @ColumnList = NULL
	SELECT @sql = 'CREATE ' + type + ' INDEX [' + index_name + '] ON [dbo].[' + table_name + ']' + CHAR(13) 
	            + '(' 

	FROM @IndexInfo_Tab
	WHERE index_name = @IndexName

	-- Index keys list
	SELECT @ColumnList = COALESCE(@ColumnList + ', ' + CHAR(13) + ' ', '') + column_name + ' ' + is_descending 
	FROM @IndexInfo_Tab
	WHERE index_name = @IndexName
	AND is_included_column = 0
	ORDER BY index_column_id

	SET @sql += @ColumnList + CHAR(13) + ')'

	-- builds INCLUDE clause
	IF EXISTS (SELECT * FROM @IndexInfo_Tab WHERE index_name = @indexName AND is_included_column = 1)
	BEGIN
		SET @sql += CHAR(13) + 'INCLUDE ('
		
		SET @ColumnList = NULL

		SELECT @ColumnList = COALESCE(@ColumnList + ', ' + CHAR(13) + ' ', '') + column_name  
		FROM @IndexInfo_Tab
		WHERE index_name = @IndexName
		AND is_included_column = 1
		ORDER BY index_column_id

		SET @sql += @ColumnList + ')'

	END

	--Add WITH CLAUSE
	SELECT @sql += ' WITH (PAD_INDEX = ' + is_padded + ', ALLOW_ROW_LOCKS = '
	+  allow_row_locks + ', ALLOW_PAGE_LOCKS = ' + allow_page_locks + ', OPTIMIZE_FOR_SEQUENTIAL_KEY = ' + optimize_for_sequential_key + ')' 
	FROM @IndexInfo_Tab
	WHERE index_name = @IndexName
	AND id = (SELECT TOP 1 id
	FROM @IndexInfo_Tab
	WHERE index_name = @IndexName)

	DECLARE @cmd NVARCHAR(MAX)

	SET @GetExistsCheck = 'SELECT @result = 1 FROM Temp_Index_Definition WHERE index_name = ''' + @IndexName + ''''

	EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			
	-- Save index in permanent table
	IF @IfExistsCheck IS NULL
	BEGIN
		-- Save Foreign Key definition in a permanent table
		SET @cmd = 'INSERT INTO Temp_Index_Definition
		SELECT ' + '''' + @IndexName +  '''' + ', '+ '''' + @sql + ''''

		EXECUTE (@cmd)	
	END

	-- Drop index
	IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @IndexName)
	BEGIN
		SET @sql = 'DROP INDEX ' + @IndexName + ' ON ' + @TableName
		EXECUTE (@sql)
	END

	FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName
END
CLOSE IndexOnCol_Cursor
DEALLOCATE IndexOnCol_Cursor

PRINT CHAR(13) + 'The INDEX definitions have been saved to the following table: Temp_Index_Definition'
