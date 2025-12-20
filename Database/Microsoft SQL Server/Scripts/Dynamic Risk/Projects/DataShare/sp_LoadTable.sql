USE [DATASHARE2]
GO

/****** Object:  StoredProcedure [dbo].[sp_LoadTable]    Script Date: 11/27/2024 9:06:49 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_LoadTable]
@TableName NVARCHAR(250)
AS
BEGIN

	DECLARE @SQL NVARCHAR(MAX) 
	DECLARE @SQL2 NVARCHAR(MAX)
	DECLARE @SQL3 NVARCHAR(MAX)
	DECLARE @SQL4 NVARCHAR(MAX)
	DECLARE @MissingData INT = NULL
	DECLARE @PKColumns NVARCHAR(MAX)
	DECLARE @FKColumn NVARCHAR(100)
	--DECLARE @TableName NVARCHAR(100) = 'CalculatorParameters'

	SET @SQL = ''
	SET @SQL2 = ''
	SET @SQL3 = ''
	SET @SQL4 = ''

	IF OBJECT_ID(@TableName, 'U') IS NOT NULL 
	BEGIN
		
		IF OBJECT_ID('tempdb..##PKColumns') IS NOT NULL 
		BEGIN
			DROP TABLE ##PKColumns;
		END

		--Save list of primary key columns
		SELECT ic.column_id AS ColumnId,
				CASE WHEN COL_NAME(ic.object_id,column_id) = 'Id'  AND COL_LENGTH(@TableName, 'OriginalId') IS NOT NULL 
						THEN 'OriginalId' 
					ELSE COL_NAME(ic.object_id,column_id) 
				END AS ColumnName,
				CASE data_type WHEN 'numeric' THEN 'NUMERIC(' + CAST(numeric_precision AS NVARCHAR) + ', ' + CAST(numeric_scale AS NVARCHAR) + ')'
							   WHEN 'varchar' THEN 'VARCHAR(' + CAST(character_maximum_length AS NVARCHAR) + ')'
							   WHEN 'int' THEN 'INT'
							   WHEN 'date' THEN 'DATE'
							   WHEN 'datetime' THEN 'DATETIME'
				END AS DataType
		INTO ##PKColumns
		FROM sys.indexes i
		JOIN sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
		JOIN INFORMATION_SCHEMA.columns c
		ON COL_NAME(ic.object_id, ic.column_id) = c.column_name
		AND OBJECT_NAME(ic.object_id) = c.table_name
		WHERE OBJECT_NAME(ic.object_id) = @TableName
		AND i.type_desc = 'CLUSTERED'
		AND COL_NAME(ic.object_id, column_id) <> 'Client_Code'
	
		SELECT @PKColumns = STRING_AGG(ColumnName, ', ') WITHIN GROUP (ORDER BY ColumnId)
		FROM ##PKColumns

		
		-- Turn off System-versioning for tables that have it enabled
		IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'systemPreferences' AND temporal_type <> 0)
		BEGIN
			SET @SQL += 'ALTER TABLE dbo.' + @TableName + ' SET (SYSTEM_VERSIONING = OFF);
						ALTER TABLE dbo.' + @TableName + '
						DROP PERIOD FOR SYSTEM_TIME;' + CHAR(10) + CHAR(10)

		END

		-- Drop all unique keys and primary key constraints on the table
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + name + CHAR(10)
		FROM sys.key_constraints 
		WHERE type IN ('PK', 'UQ') 
		AND OBJECT_NAME(parent_object_id) = @TableName 			
	
		-- Drop all check constraints on the table
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + name + CHAR(10)
		FROM sys.check_constraints 
		WHERE COL_NAME(parent_object_id, parent_column_id) = 'Id'
		AND OBJECT_NAME(parent_object_id) = @TableName

		-- Set INDENTITY INSERT ON if the table has an identity column
		IF EXISTS (SELECT 1 WHERE   OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity') = 1) 
		BEGIN
			SET @SQL += 'SET IDENTITY_INSERT ' + @TableName + ' ON' + CHAR(10)
		END

		-- Make non-null columns with null values nullable
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN ' + column_name 
			+ CASE data_type WHEN 'numeric' THEN ' NUMERIC(' 
								+ CAST(numeric_precision AS NVARCHAR) + ', ' + CAST(numeric_scale AS NVARCHAR) + ')'
							 WHEN 'datetime' THEN ' DATETIME'
			  END + ' NULL;' + CHAR(10)
		FROM INFORMATION_SCHEMA.columns
		WHERE table_name = @TableName
		AND column_name IN ('EffectiveStartDate', 'BeginStationSeriesId')
		AND column_name NOT IN (SELECT column_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_name = @TableName)
		AND is_nullable = 'NO'

		-- Alter any foreign key columns referencing an Id column without a precision of 10 and scale of 0 
		SELECT @SQL += 'ALTER TABLE ' + fk.TableName + ' ALTER COLUMN ' + fk.ColumnName + ' NUMERIC(10, 0) NULL' + CHAR(10)  
		FROM ForeignKeys fk
		JOIN sys.columns  c
		ON c.name = fk.ColumnName
		AND OBJECT_NAME(c.object_id) = fk.TableName
		WHERE TableName = @TableName
		AND ReferencedColumn = 'Id'
		AND (precision <> 10
		OR scale <> 0)

		-- Rearrange column order using a temporary table
		SET @SQL2 += 'DROP TABLE IF EXISTS Temp_' + @TableName + CHAR(10)
		SET @SQL3 += 
		(SELECT 'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1), Client_Code' + ISNULL(', ' + REPLACE(@PKColumns, 'OriginalId', 'Id'), '') + ') AS Id,'
		+ ' [Client_Code], ' 
		+ (CASE WHEN COL_LENGTH('DATASHARE.dbo.' + @TableName, 'Id') IS NOT NULL THEN ' OriginalId = [Id],' ELSE '' END )
		+ '[' +STRING_AGG(column_name, '], [') WITHIN GROUP (ORDER BY ordinal_position) + ']' 
		+ CHAR(10) + 'INTO Temp_' + @TableName + CHAR(10) + 'FROM DATASHARE.dbo.' + @TableName 
		FROM DATASHARE.INFORMATION_SCHEMA.columns
		WHERE table_name = @TableName
		AND column_name NOT IN ('Id','Client_Code', 'OriginalID')) + CHAR(10) + CHAR(10) 

		-- Make the 'Id' column not-null and drop table so the temporary table can be renamed as the new table
		SET @SQL4 += 'ALTER TABLE Temp_' + @TableName + ' ALTER COLUMN [Id] INT NOT NULL;' + CHAR(10)
		+ 'DROP TABLE ' + @TableName + CHAR(10) + CHAR(10) +
		'EXECUTE sp_rename ''Temp_' + @TableName + ''', ''' + @TableName + '''' + CHAR(10)

		SET @SQL4 += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN Client_Code VARCHAR(100) NOT NULL;' + CHAR(10)
		
		SELECT @SQL4 += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN ' + ColumnName + ' ' + DataType + ' NOT NULL;' + CHAR(10)
		FROM ##PKColumns
	
		PRINT @SQL 
		PRINT @SQL2 
		PRINT @SQL3 
		PRINT @SQL4
		EXECUTE(@SQL + @SQL2 + @SQL3 + @SQL4)
			
		SET @SQL = NULL

		-- Recreate the triggers, check constraints and default constraints on tables
		SELECT @SQL = definition + CHAR(10) 
		FROM Temp_DependentTableObjects 
		WHERE TableName = @TableName 
		AND ObjectName NOT IN ('CKC_ID_VERSIONI')
		AND ObjectName NOT LIKE '%ValidTo%'
		AND Objectname NOT LIKE '%ValidFrom%'
		ORDER BY ObjectType DESC

		PRINT @SQL 
		EXECUTE (@SQL)
		
		--Recreate the primary key on the Id column
		IF (@PKColumns IS NOT NULL) 
		BEGIN
			SET @SQL = 'ALTER TABLE ' + @TableName + ' ADD CONSTRAINT PK_' + @TableName + ' PRIMARY KEY (Client_Code, ' + @PKColumns + ');' + CHAR(10)
		END
		ELSE 	
		BEGIN
			SET @SQL = 'ALTER TABLE ' + @TableName + ' ADD CONSTRAINT PK_' + @TableName + ' PRIMARY KEY (Id);' + CHAR(10)
		END

		PRINT @SQL
		EXECUTE (@SQL);
	END
END
GO


