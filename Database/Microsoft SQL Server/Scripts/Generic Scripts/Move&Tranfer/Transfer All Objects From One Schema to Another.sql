/*
	This script moves all tables and views from a source schema to a target schema 
*/
DECLARE @SourceSchema NVARCHAR(100) = 'pods';
DECLARE @TargetSchema NVARCHAR(100) = 'dbo';
DECLARE @SQL NVARCHAR(MAX);

DECLARE object_cursor CURSOR FOR
SELECT obj.name
FROM sys.objects obj
INNER JOIN sys.schemas schem ON schem.schema_id = obj.schema_id
WHERE schem.name = @SourceSchema
AND type IN ('U', 'V')

DECLARE @obj_name NVARCHAR(100)

OPEN object_cursor
FETCH NEXT FROM object_cursor INTO @obj_name

WHILE @@FETCH_STATUS = 0  
BEGIN  
	--SET @SQL = @Tar
	IF OBJECT_ID(@TargetSchema + '.' + @obj_name) IS NULL
	BEGIN
		BEGIN TRY
			SET @SQL = 'ALTER SCHEMA ' + @TargetSchema + ' TRANSFER ' + @SourceSchema + '.' + @obj_name;
			EXECUTE (@SQL);
		END TRY
		BEGIN CATCH
			SELECT @SQL;
			PRINT ERROR_MESSAGE();
			BREAK;
		END CATCH
	END
	ELSE
	BEGIN
		SELECT 'An object with the name ' + @TargetSchema + '.' + @obj_name + ' already exists'
	END;

	FETCH NEXT FROM object_cursor INTO @obj_name
END 

CLOSE object_cursor  
DEALLOCATE object_cursor 
