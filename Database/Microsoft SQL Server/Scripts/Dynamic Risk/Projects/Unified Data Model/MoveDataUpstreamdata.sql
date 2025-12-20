DECLARE @SQL NVARCHAR(MAX)
DECLARE @DBname NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)

DROP TABLE IF EXISTS ##TableDefinitions

SELECT table_schema, 
	   table_name, 
	   column_name, 
	   column_default,
	   is_nullable,
	   ordinal_position,
	   CAST(data_type AS VARCHAR(100)) AS data_type,
	   character_maximum_length,
	   numeric_precision
INTO ##TableDefinitions
FROM INFORMATION_SCHEMA.columns
WHERE 1 = 0

DECLARE GetTableList_Cursor CURSOR FOR
SELECT @@SERVERNAME AS ServerName, 'DRAS_IRASv6_DEMO_QA' AS DBname
UNION
SELECT @@SERVERNAME AS ServerName, 'DRAS_IRASV5_UPSTREAM_DEMO' AS DBname

OPEN GetTableList_Cursor
FETCH NEXT FROM GetTableList_Cursor INTO @ServerName, @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'INSERT INTO ##TableDefinitions
	SELECT DISTINCT table_schema, 
					table_name, 
					column_name, 
					column_default,
					is_nullable,
					ordinal_position,
					UPPER(data_type) +
					CASE
						WHEN data_type LIKE ''%varchar%'' THEN + '' ('' + CAST(character_maximum_length AS VARCHAR) + + '')'' 
						WHEN data_type = ''numeric'' THEN + '' (''  + CAST(numeric_precision AS VARCHAR) + '', '' + CAST(numeric_scale AS VARCHAR) + + '')'' 
						ELSE ''''
					END AS data_type,
					character_maximum_length,
					numeric_precision
	FROM ' + QUOTENAME(@ServerName) + '.' + QUOTENAME(@DBName) + '.INFORMATION_SCHEMA.columns t1
	WHERE NOT EXISTS (SELECT * FROM ##TableDefinitions t2 WHERE t1.table_name = t2.table_name 
					  AND t1.column_name = t2.column_name 
					  --AND t1.numeric_precision = t2.numeric_precision
					  --AND t1.character_maximum_length = t2.character_maximum_length
					  )'

	EXECUTE(@SQL)

	FETCH NEXT FROM GetTableList_Cursor INTO @ServerName, @DBName

END

CLOSE GetTableList_Cursor

DEALLOCATE GetTableList_Cursor 

