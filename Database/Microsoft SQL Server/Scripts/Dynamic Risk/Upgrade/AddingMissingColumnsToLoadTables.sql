DECLARE @SQL NVARCHAR(MAX)

DECLARE AlterTable_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + QUOTENAME(table_schema) + '.[Load_' + table_name + '] ADD ' + column_name + 
(CASE 
	WHEN data_type = 'numeric' THEN ' NUMERIC(' + CAST(numeric_precision AS NVARCHAR) + ', ' 
			+ CAST(numeric_scale AS NVARCHAR) + ')'
	WHEN data_type = 'varchar' THEN ' VARCHAR(' + CAST(character_maximum_length AS NVARCHAR) + ')'
	WHEN data_type LIKE 'date%' THEN ' ' + data_type
END)
FROM INFORMATION_SCHEMA.columns tab1
WHERE table_name IN (SELECT REPLACE(table_name, 'Load_', '') 
					FROM INFORMATION_SCHEMA.tables WHERE table_name like 'Load[_]%'
					)
 AND column_name NOT IN (SELECT column_name 
						 FROM INFORMATION_SCHEMA.columns WHERE table_name = 'Load_' + tab1.table_name)

OPEN AlterTable_Cursor
FETCH NEXT FROM AlterTable_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AlterTable_Cursor INTO @SQL
END

CLOSE AlterTable_Cursor
DEALLOCATE AlterTable_Cursor
