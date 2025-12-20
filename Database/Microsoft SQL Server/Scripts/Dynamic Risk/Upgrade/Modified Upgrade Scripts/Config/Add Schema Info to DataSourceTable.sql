DECLARE @SQL NVARCHAR(MAX)
DECLARE @StageDatabase NVARCHAR(100)

SET @StageDatabaseName = ''

IF @StageDatabaseName = '' 
BEGIN
	THROW 51000, 'Missing @StageDatabaseName. Please enter the stage database before running this.', 1;  
END

IF NOT EXISTS (SELECT * FROM DataSourceSchema WHERE name = 'DRAS')
BEGIN
	INSERT INTO DataSourceSchema (Name)
	VALUES ('DRAS')
END

-- Add a foreign on the DataSourceSchema table referencing the DataSourceTable table
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DataSourceTableSchema')
BEGIN
	ALTER TABLE DataSourceTable WITH CHECK ADD CONSTRAINT FK_DataSourceTableSchema
	FOREIGN KEY (DataSourceSchemaId) REFERENCES DataSourceSchema (Id)
END


SET @SQL = 'UPDATE DataSourceTable
SET DataSourceSchemaId = CASE 
						WHEN rs.name = ''DRAS'' THEN (SELECT Id FROM DataSourceSchema WHERE Name = ''DRAS'')
					 END
FROM DataSourceTable dst
JOIN ' + @StageDatabaseName + '.sys.tables rt
ON rt.name = dst.name
JOIN ' + @StageDatabaseName + '.sys.schemas rs
ON rt.schema_id = rs.schema_id'

EXECUTE (@SQL)



