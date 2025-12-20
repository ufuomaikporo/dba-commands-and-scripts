-- Refresh the metadata for all views in the 'dbo' schema
SET NOCOUNT ON
DECLARE @viewName AS VARCHAR(255)
DECLARE @count int
DECLARE @replace NVARCHAR(MAX)
DECLARE @replace2 NVARCHAR(MAX)

DECLARE listOfViews CURSOR FOR
    SELECT [TABLE_NAME]
      FROM INFORMATION_SCHEMA.VIEWS v
           LEFT OUTER JOIN sys.sql_dependencies d ON v.[TABLE_NAME] = OBJECT_NAME(d.object_id)
     WHERE [TABLE_SCHEMA] = 'dbo' AND
           (d.[class_desc] IS NULL OR d.[class_desc] <> 'OBJECT_OR_COLUMN_REFERENCE_SCHEMA_BOUND')
     GROUP BY [TABLE_NAME]
     ORDER BY [TABLE_NAME]

OPEN listOfViews
FETCH NEXT FROM listOfViews into @viewName

SET @count = 0
WHILE (@@FETCH_STATUS <> -1)
BEGIN
    BEGIN TRY
        EXEC sp_refreshview @viewName
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 ROLLBACK
        PRINT @viewName + ' has ERRORS: ' + ERROR_MESSAGE()
		
		
		SELECT @replace = REPLACE(view_definition, 'CREATE VIEW', 'ALTER VIEW') FROM INFORMATION_SCHEMA.VIEWS
		WHERE table_name = @viewName
		
		IF CHARINDEX('LastModDateTime', @replace) <> 0
		BEGIN
			SELECT @replace2 = REPLACE(@replace, 'LastModDateTime', 'LastModDate') FROM INFORMATION_SCHEMA.VIEWS
			WHERE table_name = @viewName
		END
		ELSE
			SET @replace2 = @replace

		IF CHARINDEX('LastModDate', @replace2) <> 0
		BEGIN
			SELECT @replace = REPLACE(@replace2, 'LastModDate', 'LastModDateTime') FROM INFORMATION_SCHEMA.VIEWS
			WHERE table_name = @viewName
		END
		ELSE
			SET @replace = @replace2

		IF CHARINDEX('CreateByUserId', @replace) <> 0
		BEGIN
			SELECT @replace2 = REPLACE(@replace, 'CreateByUserId', 'CreatedUser') FROM INFORMATION_SCHEMA.VIEWS
			WHERE table_name = @viewName
		END
		ELSE
			SET @replace2 = @replace
		
		IF CHARINDEX('CreateDate', @replace2) <> 0
		BEGIN
			SELECT @replace = REPLACE(@replace2, 'CreateDate', 'CreatedDate') FROM INFORMATION_SCHEMA.VIEWS
			WHERE table_name = @viewName
		END
		ELSE
			SET @replace = @replace2

		EXECUTE(@replace)
	

        SET @count = @count + 1
    END CATCH
    FETCH NEXT FROM listOfViews INTO @viewName
END

CLOSE listOfViews
DEALLOCATE listOfViews

PRINT 'Total Views with errors: ' + CAST(@count AS nvarchar(10))

SET NOCOUNT OFF