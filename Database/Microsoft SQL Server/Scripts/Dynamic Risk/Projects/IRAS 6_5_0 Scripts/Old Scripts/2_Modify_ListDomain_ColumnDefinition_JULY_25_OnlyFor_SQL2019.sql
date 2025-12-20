--SELECT rc.constraint_name, fk_info.table_name, fk_info.column_name
DECLARE @sql NVARCHAR(MAX)
DECLARE @GetIndex NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @IndexName NVARCHAR(100)
DECLARE @GetIndexInfo NVARCHAR(MAX)
DECLARE @ColumnList1 NVARCHAR(600)
DECLARE @ColumnList2 NVARCHAR(600)
DECLARE @IsNullable NVARCHAR(10) 


DECLARE @list NVARCHAR(MAX)
DECLARE @GetTableList NVARCHAR(MAX)
DECLARE @TableList TABLE (table_name NVARCHAR(100))
DECLARE @GetFKConstraints NVARCHAR(MAX)
DECLARE @FK_Table NVARCHAR(100)
DECLARE @FK_column NVARCHAR(100)
DECLARE @PK_table NVARCHAR(100)
DECLARE @PK_column NVARCHAR(100)
DECLARE @ConstraintName NVARCHAR(100)
DECLARE @cmd NVARCHAR(MAX)
DECLARE @GetExistsCheck NVARCHAR(MAX)
DECLARE @IfExistsCheck INT = 0

DECLARE @TargetTable NVARCHAR(100) = 'ListDomain'
DECLARE @TargetColumn NVARCHAR(100) = 'Id'

-- Temporary Table to store Foriegn key info
DECLARE @FKConstraintList TABLE (constraint_name NVARCHAR(300), 
								FK_table_name NVARCHAR(100), 
								FK_column_name NVARCHAR(100),
								PK_table_name NVARCHAR(100),
								PK_column_name NVARCHAR(100))

-- Table to Store Foreign Key Constraints
IF OBJECT_ID('tempdb.##Temp_Constraint_Definitions', 'U') IS NULL
BEGIN
EXECUTE ('CREATE TABLE ##Temp_Constraint_Definitions (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, constraint_name NVARCHAR(100), definition NVARCHAR(MAX))')
END

-- Permanent table to store commands for recreating an index
IF OBJECT_ID('tempdb.##Temp_Index_Definition', 'U') IS NULL
BEGIN
EXECUTE ('CREATE TABLE ##Temp_Index_Definition (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, index_name NVARCHAR(100), definition NVARCHAR(MAX)
										)'
	)
END

PRINT CHAR(13) + 'DELETE the tables created by this script after the script run is complete. SCROLL DOWN for cleanup instructions'

-- Cursor to cycle through each Column that needs to be modified 
DECLARE AlterColumn_cursor CURSOR FOR
SELECT @TargetTable, @TargetColumn, 'NOT NULL'
UNION
SELECT fk_table, fk_column, is_nullable
FROM
(SELECT OBJECT_NAME(parent_object_id) AS fk_table, 
	COL_NAME(parent_object_id, parent_column_id) AS fk_column,
	CASE
		WHEN is_nullable = 0 THEN 'NOT NULL'
		ELSE 'NULL'
	END AS is_nullable
FROM sys.foreign_key_columns fk_col
JOIN sys.columns col ON fk_col.parent_object_id = col.object_id
	AND fk_col.parent_column_id = col.column_id
WHERE OBJECT_NAME(referenced_object_id) = @TargetTable
AND COL_NAME(referenced_object_id, referenced_column_id) = @TargetColumn
) SubQ

OPEN AlterColumn_cursor
FETCH NEXT FROM AlterColumn_cursor INTO @TableName, @ColumnName, @IsNullable

PRINT CHAR(13) + CHAR(13) + '-------- MODIFYING COLUMN DEFINITIONS FOR [' + UPPER(@TargetTable) + '].[' + UPPER(@TargetColumn) + '] AND ALL ITS DEPENDENT COLUMNS '--------

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @TableName
					AND column_name = @ColumnName AND numeric_precision = 10 AND numeric_scale = 0)
	BEGIN

------------------------------------------ SAVE INDEX DEFINITIONS Then Drop Indexes -----------------------------------------------

	/*
		This section of the script stores index definitions for selected indexes in a permanent table, then drops the selected indexes
	*/

		-- Temp table to store info for rebulding index
		DECLARE @IndexInfo_Tab TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
									index_name NVARCHAR(100), 
									type NVARCHAR(50), 
									table_name NVARCHAR(100), 
									column_name NVARCHAR(100),
									is_descending CHAR(3),
									index_column_id INT,
									is_included_column INT,
									is_padded NVARCHAR(3),
									allow_row_locks NVARCHAR(3),
									allow_page_locks NVARCHAR(3),
									optimize_for_sequential_key NVARCHAR(3))

		-- Command to generate index info
		SET @GetIndexInfo = 'DECLARE @result TABLE (index_name NVARCHAR(100), 
													type NVARCHAR(50), 
													table_name NVARCHAR(100), 
													column_name NVARCHAR(100),
													is_descending CHAR(3),
													index_column_id INT,
													is_included_column INT,
													is_padded NVARCHAR(3),
													allow_row_locks NVARCHAR(3),
													allow_page_locks NVARCHAR(3),
													optimize_for_sequential_key NVARCHAR(3))
		INSERT INTO @result
		SELECT DISTINCT(ind.name) AS index_name,
				ind.type_desc,
				OBJECT_NAME(ind.object_id) AS table_name, 
			   COL_NAME(ind.object_id, column_id) AS column_name,  
			  CASE
					WHEN is_descending_key = 0 THEN ''ASC''
					ELSE ''DESC''
			  END AS is_descending,
			  ind_col.Index_column_id,
			  ind_col.is_included_column,
			  CASE
				WHEN ind.is_padded = 0 THEN ''OFF''
				ELSE ''ON''
			  END AS is_padded,
			  CASE
				WHEN ind.allow_row_locks = 1 THEN ''ON''
				ELSE ''OFF''
			  END AS allow_row_locks,
			  CASE
				WHEN ind.allow_page_locks = 1 THEN ''ON''
				ELSE ''OFF''
			  END AS allow_page_locks,
			  CASE
				WHEN ind.optimize_for_sequential_key = 0 THEN ''OFF''
				ELSE ''ON''
			  END AS optimize_for_sequential_key
		FROM sys.index_columns ind_col
			JOIN sys.indexes ind ON ind_col.object_id = ind.object_id
				AND ind_col.index_id = ind.index_id
		WHERE OBJECT_NAME(ind.object_id) = ''' + @TableName + '''
		AND COL_NAME(ind.object_id, ind_col.column_id) = ''' + @ColumnName + '''
		AND ind.is_primary_key = 0

		SELECT * FROM @result'

		INSERT INTO @IndexInfo_Tab
		EXECUTE (@GetIndexInfo)

		-- Cursor to cycle through each index on a specific column and generate the CREATE INDEX command for each index that is to be dropped
		DECLARE IndexOnCol_Cursor CURSOR FOR
		SELECT DISTINCT(index_name) FROM @IndexInfo_Tab

		OPEN IndexOnCol_Cursor
		FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @sql = 'CREATE ' + type + ' INDEX [' + index_name + '] ON [dbo].[' + table_name + ']' + CHAR(13) 
						+ '(' 

			FROM @IndexInfo_Tab
			WHERE index_name = @IndexName

			-- Index keys list
			SET @ColumnList1 = NULL

			SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' + CHAR(13) + ' ', '') + column_name + ' ' + is_descending 
			FROM @IndexInfo_Tab
			WHERE index_name = @IndexName
			AND is_included_column = 0
			ORDER BY index_column_id

			SET @sql += @ColumnList1 + CHAR(13) + ')'

			-- builds INCLUDE clause
			IF EXISTS (SELECT 1 FROM @IndexInfo_Tab WHERE index_name = @indexName AND is_included_column = 1)
			BEGIN
				SET @sql += CHAR(13) + 'INCLUDE ('
		
				SET @ColumnList1 = NULL

				SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' + CHAR(13) + ' ', '') + column_name  
				FROM @IndexInfo_Tab
				WHERE index_name = @IndexName
				AND is_included_column = 1
				ORDER BY index_column_id

				SET @sql += @ColumnList1 + ')'

			END

			--Add WITH CLAUSE
			SELECT @sql += ' WITH (PAD_INDEX = ' + is_padded + ', ALLOW_ROW_LOCKS = '
			+  allow_row_locks + ', ALLOW_PAGE_LOCKS = ' + allow_page_locks + ', OPTIMIZE_FOR_SEQUENTIAL_KEY = ' + optimize_for_sequential_key + ')' 
			FROM @IndexInfo_Tab
			WHERE index_name = @IndexName
			AND id = (SELECT TOP 1 id
			FROM @IndexInfo_Tab
			WHERE index_name = @IndexName)

			SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Index_Definition WHERE index_name = ''' + @IndexName + ''')
									BEGIN
										SET @result = 1
									END
									ELSE
									BEGIN
										SET @result = 0
									END'

			EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out

			-- Save index in permanent table
			IF @IfExistsCheck = 0
			BEGIN
				-- Save Foreign Key definition in a permanent table
				SET @cmd = 'INSERT INTO ##Temp_Index_Definition
				SELECT ' + '''' + @IndexName +  '''' + ', '+ '''' + @sql + ''''

				EXECUTE (@cmd)	
			END

			-- Drop index
			IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @IndexName)
			BEGIN
				SET @sql = 'DROP INDEX ' + @IndexName + ' ON ' + @TableName
				EXECUTE (@sql)
			END

			FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName
		END
		CLOSE IndexOnCol_Cursor
		DEALLOCATE IndexOnCol_Cursor

	--------------------------------------- Save Foreign Key Definitions and Drop Foreign keys ---------------------------------

	/*
		This section of the script saves the foreign key definitions for all foreign keys referencing a specified column to a permanent table. Then it drops the foreign key
	*/

		-- Generate query to get list of foreign keys referencing the column in the current iteration (store result in temp table)
		SET @GetFKConstraints = 'DECLARE @Result TABLE (constraint_name NVARCHAR(300), 
														FK_table_name NVARCHAR(100), 
														FK_column_name NVARCHAR(100),
														PK_table_name NVARCHAR(100),
														PK_column_name NVARCHAR(100)
														)
		INSERT INTO @Result
		SELECT constraint_name, fk_table, fk_column, pk_table, pk_column
		FROM
		(SELECT OBJECT_NAME(constraint_object_id) AS constraint_name,
		OBJECT_NAME(parent_object_id) AS fk_table,
		COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		OBJECT_NAME(referenced_object_id) AS pk_table,
		COL_NAME(referenced_object_id, referenced_column_id) AS pk_column
		FROM sys.foreign_key_columns
		WHERE OBJECT_NAME(referenced_object_id) = ''' + @TableName +  '''
		AND COL_NAME(referenced_object_id, referenced_column_id) = ''' + @ColumnName + '''
		UNION
		SELECT OBJECT_NAME(constraint_object_id) AS constraint_name,
		OBJECT_NAME(parent_object_id) AS fk_table,
		COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		OBJECT_NAME(referenced_object_id) AS pk_table,
		COL_NAME(referenced_object_id, referenced_column_id) AS pk_column
		FROM sys.foreign_key_columns
		WHERE OBJECT_NAME(parent_object_id) = ''' + @TableName + '''
		AND COL_NAME(parent_object_id, parent_column_id) = ''' + @ColumnName + '''
		) SQ
	
		SELECT constraint_name,	FK_table_name, FK_column_name, PK_table_name, PK_column_name 
		FROM @Result'

		INSERT INTO @FKConstraintList
		EXECUTE sp_executesql @GetFKConstraints

		-- Check if there are any foreign key constraints on the table
		IF (SELECT COUNT(1) FROM @FKConstraintList) > 0
		BEGIN
			DECLARE Delete_FK_Cursor CURSOR FOR
			SELECT Constraint_Name, FK_table_name, FK_column_name, PK_table_name, PK_column_name
			FROM @FKConstraintList

			OPEN Delete_FK_Cursor
			FETCH NEXT FROM Delete_FK_Cursor INTO  @ConstraintName, @FK_table, @FK_column, @PK_table, @PK_column

			-- Loop to iterate through foreign keys referencing the table column in the outer loop
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @ColumnList1 = NULL
				SET @ColumnList2  = NULL

				SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' , '' ) + COL_NAME(parent_object_id, parent_column_id) 
				FROM sys.foreign_key_columns
				WHERE constraint_object_id = OBJECT_ID('' + @ConstraintName + '')
				ORDER BY constraint_column_id

				SELECT @ColumnList2 = COALESCE(@ColumnList2 + ', ' , '' ) +    COL_NAME(referenced_object_id, referenced_column_id)
				FROM sys.foreign_key_columns
				WHERE constraint_object_id = OBJECT_ID('' + @ConstraintName + '')
				ORDER BY constraint_column_id

				IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = @ConstraintName ) 
				BEGIN
					-- Generate command to re-create the foreign key
					SET @sql = 'ALTER TABLE [dbo].[' + @FK_Table + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName +
							   '] FOREIGN KEY(' + @ColumnList1 + ')' + ' REFERENCES [dbo].[' + @PK_table + '](' + @ColumnList2 + ')'

					SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Constraint_Definitions WHERE constraint_name = ''' + @ConstraintName + ''')
									BEGIN
										SET @result = 1
									END
									ELSE
									BEGIN
										SET @result = 0
									END'

					EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			
					-- Save foreign key constraint to permanent table if it is not already in the table
					IF @IfExistsCheck = 0
					BEGIN
						-- Save Foreign Key definition in a permanent table
						EXECUTE ('BEGIN TRANSACTION INSERT INTO ##Temp_Constraint_Definitions SELECT ''' + @ConstraintName + ''',''' + @sql + ''' COMMIT TRANSACTION')
					END

					-- Drop Foreign key constraint
					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE constraint_name = @ConstraintName)
					BEGIN
						SET @sql = 'ALTER TABLE ' +  @FK_table + ' DROP CONSTRAINT ' + @ConstraintName
						EXECUTE (@sql)
					END
	
				END
		
				FETCH NEXT FROM Delete_FK_Cursor INTO  @ConstraintName, @FK_table, @FK_column, @PK_table, @PK_column
			END -- End of WHILE-LOOP

			CLOSE Delete_FK_Cursor
			DEALLOCATE Delete_FK_Cursor
		END 

	--#################################### Save Primary Key Definitions Then Drop Primary Keys on Column ########################################
	
		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE table_name = @TableName AND column_name = @ColumnName )
		BEGIN
			SELECT @ConstraintName = constraint_name FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
			WHERE table_name = @TableName 
			AND column_name = @ColumnName 

			SET @ColumnList1 = NULL

			SELECT @ColumnList1 =  COALESCE(@ColumnList1 + ', ' , '' ) + column_name 
			FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE keys
			WHERE constraint_name = @ConstraintName

			SET @sql = 'ALTER TABLE [' + @TableName + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName + '] PRIMARY KEY (' + @ColumnList1 + ')'
			
			SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Constraint_Definitions WHERE constraint_name = ''' + @ConstraintName + ''')
							BEGIN
								SET @result = 1
							END
							ELSE
							BEGIN
								SET @result = 0
							END'

			EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			
			-- Save Primary Key definition in a permanent table in not already there
			IF @IfExistsCheck = 0
			BEGIN
				SET @cmd = 'INSERT INTO ##Temp_Constraint_Definitions
				SELECT ' + '''' + @ConstraintName +  '''' + ', '+ '''' + @sql + ''''

				EXECUTE (@cmd)	
			END

			--Drop Primary Key
			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE constraint_name = @ConstraintName)
			BEGIN
				SET @sql = 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName
				EXECUTE (@sql)
			END
		END

	----------------------------------------- Modify Foreign Key Column Definition ---------------------------------------------------
	
		SET @sql =  'ALTER TABLE ' + @TableName + ' ALTER COLUMN ' + @ColumnName + ' NUMERIC(10,0) '  + @IsNullable
		EXECUTE (@sql)
	
	END --End of IF-STATEMENT
	

	FETCH NEXT FROM AlterColumn_cursor INTO @TableName, @ColumnName, @IsNullable
END -- End of WHILE-LOOP

CLOSE AlterColumn_cursor
DEALLOCATE AlterColumn_cursor

PRINT CHAR(13) + 'The FOREIGN KEY definitions have been saved to the following table: ##Temp_Constraint_Definitions'
PRINT CHAR(13) + 'The INDEX definitions have been saved to the following table: ##Temp_Index_Definition'

--------------------------------------------- MODIFY ListDomain ID Column ----------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @TargetTable
				AND column_name = @TargetColumn AND numeric_precision = 10 AND numeric_scale = 0)
BEGIN
	SELECT @IsNullable = CASE WHEN is_nullable = 0 THEN 'NOT NULL' ELSE 'NULL'
						END 
						FROM sys.columns
						WHERE OBJECT_NAME(object_id) = @TargetTable
						AND COL_NAME(object_id, column_id) = @TargetColumn

	SET @sql = 'ALTER TABLE ' + @TargetTable + ' ALTER COLUMN ' + @TargetColumn + ' NUMERIC(10,0) ' + @IsNullable
	EXECUTE @sql
END

--############################################## RECREATE INDEXES/CONSTRAINTS ###########################################################

PRINT CHAR(13) + '----------------- RECREATING INDEXES AND FOREIGN KEYS -----------------------------'

EXECUTE('DECLARE RecreateIndex_Cursor CURSOR FOR
SELECT index_name, definition FROM ##Temp_Index_Definition

DECLARE @sql NVARCHAR(MAX)
DECLARE @IndexName NVARCHAR(100)

OPEN RecreateIndex_Cursor
FETCH NEXT FROM RecreateIndex_Cursor INTO @IndexName, @sql

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = @IndexName) 
	BEGIN
		EXECUTE (@sql)
	END
	FETCH NEXT FROM RecreateIndex_Cursor INTO @IndexName, @sql		
END

CLOSE RecreateIndex_Cursor
DEALLOCATE RecreateIndex_Cursor')

--------------------------------------------- Recreate Constraint Keys ----------------------------------------------------------------

EXECUTE('DECLARE RecreateFK_Cursor CURSOR FOR
SELECT constraint_name, definition FROM ##Temp_Constraint_Definitions
ORDER BY constraint_name DESC

DECLARE @ConstraintName NVARCHAR(100)
DECLARE @sql NVARCHAR(MAX)

OPEN RecreateFK_Cursor
FETCH NEXT FROM RecreateFK_Cursor INTO @ConstraintName, @sql

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE constraint_name =  @ConstraintName )
		AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE constraint_name = @ConstraintName)
	BEGIN
		EXECUTE (@sql)
	END

	FETCH NEXT FROM RecreateFK_Cursor INTO @ConstraintName, @sql
END
CLOSE RecreateFK_Cursor
DEALLOCATE RecreateFK_Cursor')

PRINT CHAR(13) + CHAR(13) + '.................The script has COMPLETED '
PRINT CHAR(13)  + 'CLEAN-UP INSTRUCTIONS.........'
PRINT ''
PRINT 'Delete the tables created by this script to store all the modified column foreign key, primary key '
PRINT 'and index definitions (if they are no longer needed) by issuing the following commands'

PRINT CHAR(13) + '/*********************************************************************************************/'
PRINT CHAR(13) + 'DROP TABLE dbo.##Temp_Index_Definition' 
PRINT 'DROP TABLE dbo.##Temp_Constraint_Definitions'
PRINT CHAR(13) + '/*********************************************************************************************/'

