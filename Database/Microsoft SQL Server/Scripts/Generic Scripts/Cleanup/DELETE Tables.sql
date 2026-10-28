DECLARE @list NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @GetTableList NVARCHAR(MAX)
DECLARE @TableList TABLE (table_name NVARCHAR(100))
DECLARE @FKConstraintList TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, FK_Table NVARCHAR(100), constraint_name NVARCHAR(100))
DECLARE @GetFKConstraints NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(600)
DECLARE @FK_Table NVARCHAR(100)
DECLARE @constraint_name NVARCHAR(100)

-- List of tables to be deleted
SET @List = N'
table1
table2'

SET @List = REPLACE(@List, ' ', '')
SET @List = REPLACE(@List, CHAR(10), ' ')
SET @List = REPLACE(@List, CHAR(13), '')
SET @List = REPLACE(@List, CHAR(9), '')
SET @List = REPLACE(@List, ' ', ''', ''')
SET @List = REPLACE(@List, ''''', ', '')

SET @List = '''' + @List + ''''

--select @list


-- Generate Query to get a list of all the tables that need to be dropped (results stored in a temporary table)
SET @GetTableList = 'DECLARE @result TABLE (table_name NVARCHAR(100))
INSERT INTO @Result
SELECT table_name FROM information_schema.tables
WHERE table_name in (' + @List + ') 
SELECT * FROM @Result'

INSERT INTO @TableList
EXECUTE sp_executesql @GetTableList

DECLARE DeleteTable_Cursor CURSOR FOR
SELECT * FROM @TableList

OPEN DeleteTable_Cursor  
FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 

-- Outer While loop cycles through the tables that needs to be deleted
WHILE @@FETCH_STATUS = 0  
BEGIN 
	
	-- Generate query to get list of foreign keys referencing the table in the current iteration (store result in temp table)
	SET @GetFKConstraints = 'DECLARE @Result TABLE (FK_table NVARCHAR(100), constraint_name NVARCHAR(300))
	INSERT INTO @Result
	SELECT SubQ.table_name, SubQ.constraint_name 
	FROM
	(
	SELECT DISTINCT(rc.constraint_name), fk_info.TABLE_NAME
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
	ON rc.constraint_name = fk_info.constraint_name
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
	ON rc.unique_constraint_name = pk_info.constraint_name
	JOIN INFORMATION_SCHEMA.TABLES tab
	ON tab.TABLE_NAME = pk_info.table_name
	WHERE pk_info.table_name = ''' + @TableName + '''
	AND tab.TABLE_TYPE = ''BASE TABLE'') SubQ
	
	SELECT * FROM @Result'

	INSERT INTO @FKConstraintList
	EXECUTE sp_executesql @GetFKConstraints

	-- Check if there are any foreign key constraints on the table
	IF (SELECT COUNT(*) FROM @FKConstraintList) > 0
	BEGIN
		DECLARE @Counter INT = 1
		DECLARE @TabLength INT 
		SELECT @TabLength = MAX(id) FROM @FKConstraintList

		-- Inner loop deletes foreign keys referencing the table in the outer loop
		WHILE @Counter <= (SELECT MAX(ID) FROM @FKConstraintList)
		BEGIN
			SELECT @constraint_name = constraint_name FROM @FKConstraintList
			WHERE id = @Counter

			SELECT @FK_Table = FK_Table FROM @FKConstraintList
			WHERE id = @Counter

			IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @constraint_name) --AND parent_object_id = OBJECT_ID('' + @FK_Table + ''))
			BEGIN
				SET @SQL = 'ALTER TABLE ' + @FK_Table + ' DROP CONSTRAINT ' + @constraint_name

				-- Drops foreign key
				EXECUTE (@SQL)
			END
		
			SET @Counter += 1
		END
	END 
    
	-- Drops Table
	EXECUTE ('DROP TABLE dbo.' + @TableName )

	FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 
END 

CLOSE DeleteTable_Cursor  
DEALLOCATE DeleteTable_Cursor
