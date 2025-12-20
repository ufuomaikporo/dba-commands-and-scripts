/*
	This script saves the foreign key definitions for all foreign keys referencing a specified column to a permanent table. Then it drops the foreign key
*/
-- Declare Variables
DECLARE @list NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100) = 'InlineInspection'
DECLARE @GetTableList NVARCHAR(MAX)
DECLARE @TableList TABLE (table_name NVARCHAR(100))
DECLARE @FKConstraintList TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
							     constraint_name NVARCHAR(300), 
								 FK_table_name NVARCHAR(100), 
								 FK_column_name NVARCHAR(100),
								 PK_table_name NVARCHAR(100),
								 PK_column_name NVARCHAR(100))

DECLARE @GetFKConstraints NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(600)
DECLARE @FK_Table NVARCHAR(100)
DECLARE @FK_column NVARCHAR(100)
DECLARE @PK_table NVARCHAR(100)
DECLARE @PK_column NVARCHAR(100)
DECLARE @constraint_name NVARCHAR(100)
DECLARE @cmd NVARCHAR(MAX)
DECLARE @GetExistsCheck NVARCHAR(100)
DECLARE @IfExistsCheck INT

-- Table to Store Foreign Key Constraints
IF OBJECT_ID('Temp_Foreign_key_Definitions') IS NULL
BEGIN
	EXECUTE ('CREATE TABLE Temp_Foreign_key_Definitions (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, fk_name NVARCHAR(100), definition NVARCHAR(MAX))')
END

-- Generate query to get list of foreign keys referencing the table in the current iteration (store result in temp table)
SET @GetFKConstraints = 'DECLARE @Result TABLE (constraint_name NVARCHAR(300), 
											    FK_table_name NVARCHAR(100), 
												FK_column_name NVARCHAR(100),
												PK_table_name NVARCHAR(100),
												PK_column_name NVARCHAR(100)
												)
INSERT INTO @Result
SELECT constraint_name, FK_table_name, FK_column_name, PK_table_name, PK_column_name
FROM
(
SELECT DISTINCT(rc.constraint_name), 
	   fk_info.Table_Name AS FK_table_name, 
	   fk_info.column_name AS FK_column_name, 
	   pk_info.table_name AS PK_table_name, 
	   pk_info.column_name AS PK_column_name
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
ON rc.constraint_name = fk_info.constraint_name
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
ON rc.unique_constraint_name = pk_info.constraint_name
JOIN INFORMATION_SCHEMA.TABLES tab
ON tab.TABLE_NAME = pk_info.table_name
WHERE pk_info.table_name = ''' + @TableName + '''
AND tab.TABLE_TYPE = ''BASE TABLE'') SQ
	
SELECT constraint_name, FK_table_name, FK_column_name, PK_table_name, PK_column_name
FROM @Result'

INSERT INTO @FKConstraintList
EXECUTE sp_executesql @GetFKConstraints

-- Check if there are any foreign key constraints on the table
IF (SELECT COUNT(1) FROM @FKConstraintList) > 0
BEGIN
	DECLARE Delete_FK_Cursor CURSOR FOR
	SELECT Constraint_Name, FK_table_name, FK_column_name, PK_table_name, PK_column_name
	FROM @FKConstraintList
	WHERE constraint_name = 'FK_Stg_ILI_InlineInspectionId'

	OPEN Delete_FK_Cursor
	FETCH NEXT FROM Delete_FK_Cursor INTO  @constraint_name, @FK_table, @FK_column, @PK_table, @PK_column

	-- Inner loop deletes foreign keys referencing the table in the outer loop
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @constraint_name) 
		BEGIN
			SET @sql = 'ALTER TABLE [' + @FK_Table + '] WITH CHECK ADD CONSTRAINT [' + @constraint_name +
					   '] FOREIGN KEY([' + @FK_column + '])' + ' REFERENCES [dbo].[' + @PK_table + ']([' + @PK_column + '])'

					   SELECT @sql
			SET @GetExistsCheck = 'SELECT @result = 1 FROM Temp_Foreign_key_Definitions WHERE fk_name = ''' + @constraint_name + ''''

			EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			SELECT @IfExistsCheck
			
			IF @IfExistsCheck IS NULL
			BEGIN
				-- Save Foreign Key definition in a permanent table
				EXECUTE ('BEGIN TRANSACTION INSERT INTO Temp_Foreign_key_Definitions SELECT ''' + @constraint_name + ''',''' + @sql + ''' COMMIT TRANSACTION')
			END

			SET @sql = 'ALTER TABLE ' +  @FK_table + ' DROP CONSTRAINT ' + @constraint_name

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE constraint_name = @constraint_name)
			BEGIN
				EXECUTE (@sql)
			END


			
		END
		
		FETCH NEXT FROM Delete_FK_Cursor INTO  @constraint_name, @FK_table, @FK_column, @PK_table, @PK_column
	END
END 

PRINT CHAR(13) + 'The foreign key definitions have been saved to the following table: Temp_Foreign_key_Definitions'