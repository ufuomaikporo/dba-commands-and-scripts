/* 
- This script converts non-temporal (permanent tables) into temporal tables by 
	adding the ValidFrom and ValidTo period columns and creating a history table to track changes to a table's data

-This script is not client-specific

*/
-- Variable Declaration
DECLARE @TableName VARCHAR(200);
DECLARE @ModifyTable NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX)
DECLARE @HistoryTableName NVARCHAR(100)

-- Create a cursor to loop through the tables in the list
DECLARE TableCursor CURSOR FOR
SELECT SUBSTRING(name, 3, LEN(name)) FROM sys.tables 
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


