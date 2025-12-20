/* 
- This script...
1) converts non-temporal (permanent tables) into temporal tables by adding the ValidFrom and ValidTo period columns and creating a history table to track changes to a table's data
2) Deletes all tables prefixed with "h_"

-This script is not client-specific

*/
------------------------------------------------------------------------------- Create temporal tables -----------------------------------------------------------------------------------

-- Variable Declaration
DECLARE @TableName VARCHAR(200);
DECLARE @SQL NVARCHAR(MAX)
DECLARE @HistoryTableName NVARCHAR(100)

-- Create a cursor to loop through the tables in the list
DECLARE TableCursor CURSOR FOR
SELECT REPLACE(name, 'H_', '') FROM sys.tables 
WHERE name LIKE 'H[_]%'
				
-- Use cursor to loop through and modify tables into temporal table
OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName

--select * from sys.tables where name like 'history%'

WHILE @@FETCH_STATUS = 0
BEGIN
	--Check if a user table with the name in variable the @TableName exists
	IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
	BEGIN
		SET @HistoryTableName = 'History_' + @TableName

		-- Create a temporal table on each table on the user table if the history table name is not already in use
		IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @HistoryTableName)
		BEGIN
			-- Create DDL to alter each table and add the period start and end date columns
			SET @SQL = 'ALTER TABLE ' + @TableName + ' 
					ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
							CONSTRAINT DF_'+ @TableName + '_ValidFrom DEFAULT SYSUTCDATETIME(),
						ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
							CONSTRAINT DF_' + @TableName + '_ValidTo DEFAULT CONVERT(DATETIME2,''9999-12-31 23:59:59.9999999''),
						PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
				
						ALTER TABLE ' +  @TableName + '
							SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.' + @HistoryTableName + '));'

				EXECUTE sp_executesql @SQL
			
		END -- End of inner IF-statement
	END -- End of outer IF-statement

	FETCH NEXT FROM TableCursor INTO @TableName
END -- End of While-Loop

DEALLOCATE TableCursor

-------------------------------------------------------------------------------------- Delete "h_" tables ---------------------------------------------------------------------------------

DECLARE @SourceTable NVARCHAR(100)
DECLARE @TriggerName NVARCHAR(100)
DECLARE @TriggerDefinition NVARCHAR(MAX) 
DECLARE @IfExists INT
DECLARE @StartIndex INT
DECLARE @EndIndex INT
DECLARE @TempStr NVARCHAR(MAX)

DECLARE DeleteTableCursor CURSOR FOR
SELECT table_name
FROM INFORMATION_SCHEMA.tables
WHERE table_name LIKE 'h[_]%'
ORDER BY 1

OPEN DeleteTableCursor 
FETCH NEXT FROM DeleteTableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SourceTable = REPLACE(@TableName, 'h_', '')

	DECLARE DeleteTriggerCursor CURSOR FOR
	SELECT name
	FROM sys.triggers
	where OBJECT_NAME(parent_id) = @SourceTable

	OPEN DeleteTriggerCursor
	FETCH NEXT FROM DeleteTriggerCursor INTO @TriggerName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @TriggerDefinition = REPLACE(OBJECT_DEFINITION (OBJECT_ID(@TriggerName)), '''', '''''')
	
		IF (@TriggerName LIKE 'td%')
		BEGIN
			IF OBJECT_ID(@TriggerName, 'TR') IS NOT NULL
			BEGIN
				SET @SQL = 'DROP TRIGGER '+ @TriggerName +''
				EXECUTE (@SQL)
			END
		END
		ELSE
		BEGIN

			SET @SQL = 'SELECT @Result = PATINDEX(''%UPDATE dbo.' + @SourceTable + '%'',N''' + @TriggerDefinition + ''')'
			EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT

			IF (@IfExists = 0)
			BEGIN
				--Drop delete trigger
				SET @SQL = 'DROP TRIGGER '+ @TriggerName +''
				EXECUTE (@SQL)
			END
			ELSE
			BEGIN

				SET @SQL = 'SELECT @Result = PATINDEX(''%INSERT INTO%' + @TableName + '%'', N''' + @TriggerDefinition + ''') - 1'
				EXECUTE sp_executesql @SQL, N'@Result INT OUT', @StartIndex OUT

				SET @SQL = 'SELECT @Result = CHARINDEX(''FROM DELETED'', N''' + @TriggerDefinition + ''',' + CAST(@StartIndex AS NVARCHAR)+') + 15'
				EXECUTE sp_executesql @SQL, N'@Result INT OUT', @EndIndex OUT

				-- Modify the definition for the update trigger and recreate it without references to deleted h_table
				IF (@StartIndex > 0)
				BEGIN TRY

					SELECT @TempStr =  SUBSTRING(@TriggerDefinition, 1 , @StartIndex) 
										+ SUBSTRING(@TriggerDefinition, @EndIndex, LEN(@TriggerDefinition))
					
					SET @TriggerDefinition = @TempStr
					SET @TriggerDefinition = REPLACE(@TriggerDefinition, 'CREATE', 'CREATE OR ALTER')
					SET @TriggerDefinition = REPLACE(@TriggerDefinition, '''''', '''')
				
					EXECUTE(@TriggerDefinition)
				END TRY
				BEGIN CATCH
					SELECT @TriggerDefinition
					PRINT ERROR_MESSAGE()
					--BREAK
				END CATCH
			END
		END

		FETCH NEXT FROM DeleteTriggerCursor INTO @TriggerName
	END

	CLOSE DeleteTriggerCursor
	DEALLOCATE DeleteTriggerCursor

	-- Drop table
	IF OBJECT_ID(@TableName, 'U') IS NOT NULL
	BEGIN
		SET @SQL = 'DROP TABLE ' + @TableName + ''
		EXECUTE (@SQL)
	END

	FETCH NEXT FROM DeleteTableCursor INTO @TableName
END

CLOSE DeleteTableCursor
DEALLOCATE DeleteTableCursor