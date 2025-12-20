/* 
The script generates the commands to recreate the following (EXCEPT for non-clustered indexes)

1. Default constraints
2. Triggers
3. Primary Key 
4. Foreign Keys 

on a list of tables then stores the commands in a table named Temp_DependentObjectsDefinition.
You can copy and execute the commands to create the dependent objects then delete the Temp_DependentObjectsDefinition
table once you're done

*/
DECLARE @TableList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)

--**********************************************************************************************

SET @TableList = 'MonteCarlo_Crack
MonteCarlo_Feature
MonteCarlo_MechDamageImmed
MonteCarlo_NCD'
--**********************************************************************************************

SET @TableList = REPLACE(@TableList, ' ', '')
SET @TableList = REPLACE(@TableList, CHAR(10), ' ')
SET @TableList = REPLACE(@TableList, CHAR(13), '')
SET @TableList = REPLACE(@TableList, CHAR(9), '')
SET @TableList = REPLACE(@TableList, ' ', ''', ''')
SET @TableList = REPLACE(@TableList, ''''', ', '')

SET @TableList = '''' + @TableList + ''''

IF OBJECT_ID('Temp_DependentObjectsDefinition') IS NOT NULL
BEGIN
	DROP TABLE Temp_DependentObjectsDefinition;
END

--  Recreate Default Constraints
SET @SQL = 'SELECT OBJECT_NAME(parent_object_id) AS ParentObjectName, 
name AS DependentObjectName,
''DEFAULT_CONSTRAINT'' AS DependentObjectType,
''ALTER TABLE '' + OBJECT_NAME(parent_object_id) + ''
ADD CONSTRAINT '' + name + ''
DEFAULT '' + definition + '' FOR '' + COL_NAME(parent_object_id, parent_column_id) + '';'' AS ObjectDefinition
INTO Temp_DependentObjectsDefinition
FROM sys.default_constraints
WHERE OBJECT_NAME(parent_object_id) IN (' + @TableList + ')'

EXECUTE(@SQL)

--RECREATE triggers
SET @SQL = 'INSERT INTO Temp_DependentObjectsDefinition
SELECT OBJECT_NAME(trig.parent_id), 
OBJECT_NAME(trig.object_id),
''TRIGGER'', 
definition 
FROM sys.sql_modules sm
JOIN sys.triggers trig
	ON sm.object_id = trig.object_id
WHERE sm.object_id IN (SELECT object_id FROM sys.triggers WHERE OBJECT_NAME(parent_id )
IN (' + @TableList + '))'

EXECUTE (@SQL)

-- Recreate Primary keys
SET @SQL = 'INSERT INTO Temp_DependentObjectsDefinition
SELECT DISTINCT OBJECT_NAME(ic.object_id), 
name,
''PRIMARY KEY'',
''ALTER TABLE '' + OBJECT_NAME(ic.object_id) + '' WITH CHECK ADD CONSTRAINT '' + name + '' PRIMARY KEY CLUSTERED (''
+ (SELECT STUFF(
				(SELECT '', '' + COL_NAME(object_id, column_id) +
					CASE WHEN is_descending_key = 1 THEN '' DESC''
						ELSE '' ASC''
					END
				FROM sys.index_columns 
				WHERE object_id = ic.object_id
					AND index_id = ic.index_id
				ORDER BY key_ordinal
				FOR XML PATH(N''''), TYPE
				).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
			)
			
	) + '');''
FROM sys.indexes i
JOIN sys.index_columns ic
ON i.object_id = ic.object_id
AND i.index_id = ic.index_id
WHERE i.type_desc = ''CLUSTERED''
AND OBJECT_NAME(ic.object_id) IN (' + @TableList + ')'

EXECUTE (@SQL)

-- Recreate Foreign Key Constraints
SET @SQL = 'INSERT INTO Temp_DependentObjectsDefinition
SELECT DISTINCT tab.name, 
OBJECT_NAME(fkc1.constraint_object_id),
''FOREIGN KEY'',
''ALTER TABLE '' + QUOTENAME(SCHEMA_NAME(tab.schema_id)) +''.''+ QUOTEnAME(OBJECT_NAME(fkc1.parent_object_id) )
+ '' WITH CHECK ADD CONSTRAINT '' + QUOTENAME(OBJECT_NAME(constraint_object_id)) 
+ CHAR(10) + ''FOREIGN KEY('' + (SELECT STUFF(
											(SELECT '', '' + QUOTENAME(COL_NAME(fkc2.parent_object_id, fkc2.parent_column_id))
											 FROM sys.foreign_key_columns fkc2 
											 WHERE constraint_object_id = fkc1.constraint_object_id
											 FOR XML PATH(N''''), TYPE
											 ).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
										 )
							)
+ CHAR(10) + '') REFERENCES '' + QUOTENAME(SCHEMA_NAME(tab2.schema_id)) + ''.'' + QUOTENAME(OBJECT_NAME(fkc1.referenced_object_id)) + ''('' 
+ (SELECT STUFF(
				(SELECT '', '' + QUOTENAME(COL_NAME(fkc2.referenced_object_id, fkc2.referenced_column_id))
				FROM sys.foreign_key_columns fkc2 
				WHERE constraint_object_id = fkc1.constraint_object_id
				FOR XML PATH(N''''), TYPE
				).value(N''.[1]'', N''nvarchar(max)''), 1, 2, N''''
			  )
	)
    +'')'' AS FK_Definition
FROM sys.foreign_key_columns fkc1
JOIN sys.tables tab
ON tab.object_id = fkc1.parent_object_id
JOIN sys.tables tab2 
ON tab2.object_id = fkc1.referenced_object_id
WHERE OBJECT_NAME(fkc1.parent_object_id) IN (' + @TableList + ')'

EXECUTE(@SQL)

-- Cursor Loop that could be used to run the commands in Temp_DependentObjectsDefinition table
--DECLARE CreateObject_cursor CURSOR FOR
--SELECT * FROM Temp_DependentObjectsDefinition

--OPEN CreateObject_cursor
--FETCH NEXT FROM CreateObject_cursor INTO @SQL

--WHILE @@FETCH_STATUS = 0
--BEGIN
--	SELECT  @SQL
--	FETCH NEXT FROM CreateObject_cursor INTO @SQL
--END

--CLOSE CreateObject_cursor 
--DEALLOCATE CreateObject_cursor



