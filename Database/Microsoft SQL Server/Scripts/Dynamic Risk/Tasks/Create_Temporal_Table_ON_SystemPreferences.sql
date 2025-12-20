DECLARE @TableName NVARCHAR(100) 
DECLARE @HistoryTableName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

SET @TableName = 'SystemPreferences'
SET @HistoryTableName = 'History_' + @TableName

--Check if a user table exists with the name contained in @TableName varaible
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
BEGIN

	-- Create a temporal table if the history table name is not already in use
	IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @HistoryTableName)
	BEGIN
		PRINT 'CONVERTING ' + @TableName + ' TO A TEMPORAL TABLE'
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
	END
END