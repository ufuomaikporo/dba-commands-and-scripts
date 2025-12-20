DECLARE @trigger_id AS INT
DECLARE @trigger_name AS NVARCHAR(150)
DECLARE @table_name AS NVARCHAR(150)
DECLARE @trigger_def AS NVARCHAR(MAX)
DECLARE @defintion_script AS NVARCHAR(MAX)
DECLARE @search_string AS NVARCHAR(100)
DECLARE @replace_string AS NVARCHAR(100)
DECLARE @search_value AS NVARCHAR(70)
DECLARE @GetColumnCount AS NVARCHAR(1000)
DECLARE @count AS INT
DECLARE @GetColumnDropList NVARCHAR(1000)
DECLARE @column_drop_list NVARCHAR(200)
SET @search_string = 'Create%User%'
set @table_name = 'VALVE'

SET @count = 3

-- Dynamic SQL that involves using a scalar local variable within the Dynamic SQL statement to store a column result then outputing the
-- stored result into another local variable in T-SQL. the column result is turned into a scalar list
SET @GetColumnDropList = 'SELECT @result  = COALESCE(@result + '', '''''', '''''''') + CONVERT(varchar(12), column_name) + ''''''''
FROM 
(SELECT TOP ' + CAST((@count - 1) AS NVARCHAR) + ' tab.name AS table_name,
      col.name AS column_name,
	  con.name AS constraint_name
FROM sys.tables tab
INNER JOIN sys.columns col 
ON tab.object_id = col.object_id
LEFT JOIN sys.default_constraints con
ON con.parent_column_id = col.column_id
WHERE col.name LIKE ' + '''' + @search_string + '''' +
' AND tab.name = ' + '''' + @table_name + '''' + 
' ORDER BY 3 DESC) subq;'
EXECUTE sp_executesql @GetColumnDropList, N'@result NVARCHAR(100) OUT', @column_drop_list OUT
SELECT @column_drop_list

-----------------------  Dynamic SQL for inserts into tables -----------------------------------------------
DECLARE @GetDefaultConstraints NVARCHAR(500)
DECLARE @DefaultConstrList TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, default_constr_name NVARCHAR(100))
SET @GetDefaultConstraints = 'DECLARE @result TABLE (cons_name NVARCHAR(100))
INSERT INTO @result 
SELECT cons.name 
FROM sys.default_constraints cons
WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + '''' + ')
AND parent_column_id IN (SELECT column_id FROM sys.columns col
                        WHERE col.name LIKE (N''Create%User%'')
                        AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + ''''+ ')
						);
						SELECT * FROM @result'
INSERT INTO @DefaultConstrList					
EXECUTE (@GetDefaultConstraints)

-------------------------------- Looping through a table without a cursor ------------------------------------
DECLARE @row_count INT ; -- used to determine when to exit the loop
DECLARE @row_id INT = 1; -- initialized to identity column value of first row in table
DECLARE @constraint_name VARCHAR(150)
SELECT @row_count = COUNT(*) FROM @DefaultConstrList;

WHILE @row_id <= @row_count
BEGIN
	SELECT @constraint_name = default_constr_name FROM @DefaultConstrList
	IF (@constraint_name IS NOT NULL)
		EXECUTE ('ALTER TABLE ' + @table_name + ' DROP CONSTRAINT ' + @constraint_name)
	SET @row_id += 1
END
 
--IF @ConstraintName IS NOT NULL
--EXECUTE ('ALTER TABLE INCIDENT DROP CONSTRAINT ' + @ConstraintName)

