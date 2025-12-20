DECLARE @ColumnName NVARCHAR(100);
DECLARE @TableName NVARCHAR(100);
DECLARE @ConstraintName NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);

---------------------------------- RENAME COLUMNS & REMOVE DUPLICATE COLUMNS ---------------------------------------------

DECLARE RenameColumnList CURSOR FOR
SELECT table_name, column_name
FROM INFORMATION_SCHEMA.columns
WHERE column_name LIKE 'LastMod%' OR
    column_name LIKE 'Create%'
EXCEPT
SELECT table_name, column_name
FROM INFORMATION_SCHEMA.columns
WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId');

OPEN RenameColumnList
FETCH NEXT FROM RenameColumnList INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@ColumnName LIKE 'LastMod%User%')
	BEGIN
		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'LastModByUserId')
		BEGIN
			-- Find and drop the default constraint on the column
			SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
			WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
			AND parent_column_id IN (SELECT column_id FROM sys.columns col
									WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
									' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
									)'
			EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

			-- Drop default constraint if it exists
			IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
			BEGIN
				EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
			END

				-- Drop the column if it exists
			IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
			BEGIN
				EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
			END

		END
		ELSE
		BEGIN
			SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''LastModByUserId'', ''COLUMN''';
			EXECUTE (@SQL)
		END
	END

	IF (@ColumnName LIKE 'Create%User%')
	BEGIN

		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'CreatedUser')
		BEGIN
			-- Find and drop the default constraint on the column
			SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
			WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
			AND parent_column_id IN (SELECT column_id FROM sys.columns col
									WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
									' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
									)'
			EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

			-- Drop default constraint if it exists
			IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
			BEGIN
				EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
			END

				-- Drop the column if it exists
			IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
			BEGIN
				EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
			END
		END
		ELSE
		BEGIN
			SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''CreatedUser'', ''COLUMN''';
			EXECUTE (@SQL)
		END
	END

	IF (@ColumnName LIKE 'LastMod%Date%')
	BEGIN
		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'LastModDateTime')
		BEGIN
			-- Find and drop the default constraint on the column
			SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
			WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
			AND parent_column_id IN (SELECT column_id FROM sys.columns col
									WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
									' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
									)'
			EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

			-- Drop default constraint if it exists
			IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
			BEGIN
				EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
			END

				-- Drop the column if it exists
			IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
			BEGIN
				EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
			END
		END
		ELSE
		BEGIN
			SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''LastModDateTime'', ''COLUMN''';
			EXECUTE (@SQL)
		END
	END

	IF (@ColumnName LIKE 'Create%Date%')
	BEGIN
		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'CreatedDate')
		BEGIN
			-- Find and drop the default constraint on the column
			SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
			WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
			AND parent_column_id IN (SELECT column_id FROM sys.columns col
									WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
									' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
									)'
			EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

			-- Drop default constraint if it exists
			IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
			BEGIN
				EXECUTE ('ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName)
			END

				-- Drop the column if it exists
			IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
			BEGIN
				EXECUTE('ALTER TABLE ' + @TableName + ' DROP COLUMN ' + @ColumnName)
			END
		END
		ELSE
		BEGIN
			SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''CreatedDate'', ''COLUMN''';
			EXECUTE (@SQL)
		END
	END

	FETCH NEXT FROM RenameColumnList INTO @TableName, @ColumnName
END 

CLOSE RenameColumnList 
DEALLOCATE RenameColumnList

---------------------------------- ADD MISSING COLUMNS --------------------------------------

DECLARE AddColumnList CURSOR FOR
SELECT table_name 
FROM INFORMATION_SCHEMA.tables 
WHERE table_name NOT IN (SELECT table_name 
						FROM (SELECT table_name, COUNT(table_name) AS cnt
								FROM INFORMATION_SCHEMA.columns
								WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')
								GROUP BY table_name
								HAVING COUNT(table_name) = 4
							) subq
						)
AND Table_Type = 'BASE TABLE'; 

OPEN AddColumnList
FETCH NEXT FROM AddColumnList INTO @TableName

WHILE @@FETCH_STATUS = 0 
BEGIN
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name ='CreatedDate')
	BEGIN
		SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD CreatedDate DATE DEFAULT GETDATE() NOT NULL'
		EXECUTE (@SQL)
	END

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModDateTime')
	BEGIN
		SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD LastModDateTime DATE DEFAULT GETDATE() NOT NULL'
		EXECUTE (@SQL)
	END

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'CreatedUser')
	BEGIN
		SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD CreatedUser NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'
		EXECUTE (@SQL)
	END

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModByUserId')
	BEGIN
		SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD LastModByUserId NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'
		EXECUTE (@SQL)
	END

	FETCH NEXT FROM AddColumnList INTO @TableName
END

CLOSE AddColumnList 
DEALLOCATE AddColumnList
