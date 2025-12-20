
-- T-SQL to get column names for specified columns with default values
DECLARE @result VARCHAR(150)
SELECT @result = COALESCE(@result + ', ''', '''') + CONVERT(varchar(12), column_name) + ''''
FROM 
(SELECT TOP 3 tab.name AS table_name,
	  col.column_id,
      col.name AS column_name,
	  con.name AS constraint_name
FROM sys.tables tab
INNER JOIN sys.columns col 
ON tab.object_id = col.object_id
LEFT JOIN sys.default_constraints con
ON con.parent_column_id = col.column_id
WHERE col.name LIKE 'Create%User%'
  AND tab.name = 'VALVE' 
ORDER BY 3 DESC) subq

SELECT @result

-- Dynamic SQL version of the sam query above
DECLARE @search_string AS VARCHAR(70)
DECLARE @table_name AS VARCHAR(150)
DECLARE @GetColumnCount AS NVARCHAR(1000)
DECLARE @count AS INT
SET @search_string = 'Create%User%'
set @table_name = 'INCIDENT'
DECLARE @GetDefaultConstraint NVARCHAR(1000)
SET @count = 2
DECLARE @column_drop_list NVARCHAR(200)

SET @GetDefaultConstraint = 'SELECT @result = COALESCE(@result + '', '''''', '''''''') + CONVERT(varchar(12), column_name) + ''''''''
FROM 
(SELECT TOP ' + CAST(@count AS NVARCHAR) + ' tab.name AS table_name,
      col.name AS column_name,
	  con.name AS constraint_name
FROM sys.tables tab
INNER JOIN sys.columns col 
ON tab.object_id = col.object_id
LEFT JOIN sys.default_constraints con
ON con.parent_column_id = col.column_id
WHERE col.name LIKE ' + '''' + @search_string + '''' +
' AND tab.name = ' + '''' + @table_name + '''' + 
' ORDER BY 3) subq;'
EXECUTE sp_executesql @GetDefaultConstraint, N'@result NVARCHAR(100) out', @column_drop_list out
SELECT @column_drop_list

---------------------------Dynamic SQL query to top nth number a query result -----------------

SET @GetDefaultConstraint = 'SELECT TOP ' + CAST(@count -1 AS NVARCHAR) + ' tab.name AS table_name,
      col.name AS column_name,
	  con.name AS constraint_name
FROM sys.tables tab
INNER JOIN sys.columns col 
ON tab.object_id = col.object_id
LEFT JOIN sys.default_constraints con
ON con.parent_column_id = col.column_id
WHERE col.name LIKE ' + '''' + @search_string + '''' +
  ' AND tab.name = ' + '''' + @table_name + '''' +
 ' ORDER BY 3'
EXECUTE sp_executesql @GetDefaultConstraint
SELECT @GetDefaultConstraint