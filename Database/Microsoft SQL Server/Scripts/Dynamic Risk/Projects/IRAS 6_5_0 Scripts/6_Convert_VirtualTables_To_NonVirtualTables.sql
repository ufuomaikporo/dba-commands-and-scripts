/*

This script converts virtual tables in a client database to flat/non-virtual tables and moves the 
converted tables into the 'DRAS' schema. Must be executed on the target database

*/
DECLARE @VirtualTableName NVARCHAR(100)
DECLARE @VirtualColumnName NVARCHAR(100)
DECLARE @VirtualTableId INT
DECLARE @VCDataTypeTable NVARCHAR(100)
DECLARE @VCDataTypeColumn NVARCHAR(100)
DECLARE @ForeignKeyName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ColumnList NVARCHAR(MAX)
DECLARE @JoinList NVARCHAR(MAX)
DECLARE @Counter INT = 1

IF OBJECT_ID ('tempdb..##VirtualColumn') IS NOT NULL
BEGIN
	DROP TABLE ##VirtualColumn
END

IF OBJECT_ID('TempVirtualTableInfo') IS NOT NULL
BEGIN
	DROP TABLE TempVirtualTableInfo
END

-- Table to store virtual table info (i.e. schema, name)
IF OBJECT_ID('dbo.TempVirtualTableInfo') IS NULL
BEGIN
	CREATE TABLE TempVirtualTableInfo (SchemaName VARCHAR(100), VirtualTableName VARCHAR(100))
END


/*
	Create temporary table to store the VirtualColumn values and the table name for the table associated with the 
	VirtualColumnDataTypeInd column
*/
IF OBJECT_ID('VirtualTable') IS NOT NULL
BEGIN
	SELECT Id, 
			VirtualTableId, 
			VirtualColumnName,
			CASE 
				WHEN VirtualColumnDataTypeInd = 'N' THEN 'VirtualTableDataNum'
				WHEN VirtualColumnDataTypeInd = 'D' THEN 'VirtualTableDataDate'
				WHEN VirtualColumnDataTypeInd = 'I' THEN 'VirtualTableDataInd'
				WHEN VirtualColumnDataTypeInd = 'L' THEN 'VirtualTableDataListDomain'
				WHEN VirtualColumnDataTypeInd = 'F' THEN 'VirtualTableDataFlg'
				WHEN VirtualColumnDataTypeInd = 'S' THEN 'VirtualTableDataString'
			END AS VCDataTypeTable,
			CASE 
				WHEN VirtualColumnDataTypeInd = 'N' THEN 'DataFieldValueNum'
				WHEN VirtualColumnDataTypeInd = 'D' THEN 'DataFieldValueDate'
				WHEN VirtualColumnDataTypeInd = 'I' THEN 'DataFieldValueInd'
				WHEN VirtualColumnDataTypeInd = 'L' THEN 'DataFieldValueDomainId'
				WHEN VirtualColumnDataTypeInd = 'F' THEN 'DataFieldValueFlg'
				WHEN VirtualColumnDataTypeInd = 'S' THEN 'DataFieldValueString' 
			END AS VCDataTypeColumn,
			VirtualColumnComment
	INTO ##VirtualColumn
	FROM VirtualColumn

	--------------------------------------- Create Schema to store Virtual Tables ----------------------------

	IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
	BEGIN
		SET @SQL = 'CREATE SCHEMA DRAS'
		EXECUTE (@SQL)
	END

	----------------------------------------- Create Virtual Tables -----------------------------------------------

	DECLARE VirtualTable_Cursor CURSOR FOR
	SELECT Id, VirtualTableName FROM VirtualTable 

	OPEN VirtualTable_Cursor
	FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		--Drop the non-temporary tables created by this script
		IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
		BEGIN
			DROP TABLE tmp_VirtualTableData
		END

		SET @ColumnList = 'SELECT ROW_NUMBER() OVER (ORDER BY VTS.VirtualTableStationingId) AS Id, '

		SET @JoinList = CHAR(10) + 'INTO tmp_VirtualTableData
		FROM VirtualTableStationing VTS'

		DECLARE VirtualColumns_Cursor CURSOR FOR
		SELECT VirtualColumnName,
			   VCDataTypeTable,
			   VCDataTypeColumn
		FROM ##VirtualColumn
		WHERE VirtualTableId = @VirtualTableId
		AND VirtualColumnName NOT IN ('DO NOT USE')

		OPEN VirtualColumns_Cursor
		FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

		-- Use a loop to generate the select statement that will be used to populate the new virtual tables
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @ColumnList += 'T' + CAST(@Counter AS NVARCHAR) + '.[' + @VCDataTypeColumn + '] AS ' + @VirtualColumnName + ', '
			SET @JoinList += CHAR(13) + 'LEFT JOIN ' + @VCDataTypeTable + ' T' + CAST(@Counter AS NVARCHAR) + ''
						+ CHAR(13) + ' ON T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableId = VTS.VirtualTableId'
						+ CHAR(13) + 'AND T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableStationingId = VTS.VirtualTableStationingId'
	
			SET @Counter += 1
			FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

		END
		CLOSE VirtualColumns_Cursor
		DEALLOCATE VirtualColumns_Cursor

		SET @SQL = @ColumnList 
		+ 'VTS.EffectiveStartDate, 
		VTS.EffectiveEndDate,
		VTS.BeginStationSeriesId,
		VTS.BeginStationNum,
		VTS.EndStationSeriesId,
		VTS.EndStationNum,
		VTS.SourceId,
		VTS.CreatedUser,
		VTS.CreatedDate,
		VTS.LastModByUserId,
		VTS.LastModDateTime
		' + @JoinList + CHAR(10) 
		+ 'WHERE VTS.VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + ''
		
		EXECUTE (@SQL)

		SET @ColumnList = NULL

		-- Get the list of columns that will be used to create the new virtual table
		SELECT @ColumnList = COALESCE(@ColumnList + '], [', '') + column_name 
		FROM INFORMATION_SCHEMA.columns
		WHERE table_name = 'tmp_VirtualTableData'
		AND column_name NOT IN ('VirtualTableId', 'VirtualTableStationingId')
		ORDER BY ordinal_position

		SET @ColumnList = '[' + @ColumnList + ']'

		-- Create and populate the new virtual table in the DRAS schema
		IF OBJECT_ID('DRAS' + '.' + @VirtualTableName) IS NULL
		BEGIN
			SET @SQL = 'SELECT ' + @ColumnList + '
				INTO DRAS.' + @VirtualTableName + '
				FROM tmp_VirtualTableData'
			
			EXECUTE (@SQL)

			INSERT INTO TempVirtualTableInfo
			VALUES ('DRAS', @VirtualTableName)
		END
	
	---------------------------------- Add a Primary Key to Newly Created Virtual Table ------------------------------------

		IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE type = 'PK' 
						AND OBJECT_NAME(parent_object_id) = @VirtualTableName AND SCHEMA_NAME(schema_id) = 'DRAS')
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ALTER COLUMN Id NUMERIC(10, 0) NOT NULL'
			EXECUTE (@SQL)

			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD CONSTRAINT PK_' + @VirtualTableName + ' PRIMARY KEY CLUSTERED (Id)'
			EXECUTE (@SQL)
		END

	------------------------------------ Add Column Defaults to Change-tracking columns --------------------------------------

		IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
					AND COL_NAME(parent_object_id, parent_column_id) = 'LastModByUserId' AND SCHEMA_NAME(schema_id) = 'DRAS')
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]'
			EXECUTE (@SQL)
		END

		IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
					AND COL_NAME(parent_object_id, parent_column_id) = 'LastModDateTime' AND SCHEMA_NAME(schema_id) = 'DRAS')
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'
			EXECUTE (@SQL)
		END

		IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
					AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedDate' AND SCHEMA_NAME(schema_id) = 'DRAS')
		BEGIN	
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
			EXECUTE (@SQL)
		END

		IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
					AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedUser' AND SCHEMA_NAME(schema_id) = 'DRAS')
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
			EXECUTE (@SQL)
		END

	------------------------------------ Create Triggers on Newly Created Virtual Tables --------------------------------------
		
		IF OBJECT_ID('[DRAS].[tu_' + @VirtualTableName + ']' , 'TR') IS NULL
		BEGIN
			SET @SQL = '	
			CREATE TRIGGER [DRAS].[tu_' + @VirtualTableName + '] ON [DRAS].[' + @VirtualTableName+ '] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE DRAS.' + @VirtualTableName + '
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM DRAS.' + @VirtualTableName + ' as t, DELETED as d
				WHERE t.Id=d.Id;
			END'

			EXECUTE (@SQL)
		END

		-------------------------------- Create foreign Keys on ListDomain columns ----------------------------

		SET @ForeignKeyName = 'FK_' + CASE WHEN LEN(@VirtualTableName) <= 10 
								   THEN @VirtualTableName ELSE SUBSTRING(@VirtualTableName, 1, 3) 
							  END + '_' + @VirtualColumnName + '_DomainId'

		IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @ForeignKeyName) 
		BEGIN
			SET @SQL = NULL

			SELECT @SQL = 'ALTER TABLE [DRAS].[' + ReferencedTableName + '] WITH CHECK ADD CONSTRAINT ' 
			+ @ForeignKeyName + CHAR(10) + 'FOREIGN KEY (' + ReferencedColumnName + ')' + CHAR(10)
			+ 'REFERENCES [DRAS].[' + ListDomainTableName + '](Id)'
			FROM TempListDomainTable
			WHERE ReferencedTableName = @VirtualTableName

			EXECUTE (@SQL)	
			
		END

		SET @ForeignKeyName = 'FK_' + CASE WHEN LEN(@VirtualTableName) <= 10 
							THEN @VirtualTableName ELSE SUBSTRING(@VirtualTableName, 1, 3) 
						END + '_' + @VirtualColumnName + '_BeginStationSeriesId'

		IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @ForeignKeyName) 
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] WITH CHECK ADD CONSTRAINT ' + @ForeignKeyName
					+ CHAR(10) + ' FOREIGN KEY (BeginStationSeriesId) ' + ' REFERENCES [dbo].[StationSeries](Id)'

			EXECUTE (@SQL)
		END

		SET @ForeignKeyName = 'FK_' + CASE WHEN LEN(@VirtualTableName) <= 10 
					THEN @VirtualTableName ELSE SUBSTRING(@VirtualTableName, 1, 3) 
				END + '_' + @VirtualColumnName + '_EndStationSeriesId'

		IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @ForeignKeyName) 
		BEGIN
			SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] WITH CHECK ADD CONSTRAINT ' + @ForeignKeyName
					+ CHAR(10) + ' FOREIGN KEY (EndStationSeriesId) ' + ' REFERENCES [dbo].[StationSeries](Id)'

			EXECUTE (@SQL)
		END
		FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

	END 

	CLOSE VirtualTable_Cursor
	DEALLOCATE VirtualTable_Cursor
END

-------------------------------- Drop Unnecessary tables -------------------------------------

--Drop the non-temporary tables created by this script
IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
BEGIN
	DROP TABLE tmp_VirtualTableData
END

------------------------------------- Drop Virtual tables source tables -------------------------------

/* Delete the following source tables (VirtualTable, VirtualTableDataDate, VirtualTableDataFlg) 
once all the virtual tables have been converted to flat tables
*/
IF NOT EXISTS (SELECT 1 from virtualTable WHERE VirtualTableName NOT IN (SELECT name FROM sys.tables))
BEGIN

	DECLARE @TableName NVARCHAR(100)

	DECLARE DeleteTables CURSOR FOR
	SELECT table_name FROM INFORMATION_SCHEMA.tables 
	WHERE table_name IN ('VirtualColumn',
	'VirtualTable',
	'VirtualTableDataDate',
	'VirtualTableDataFlg',
	'VirtualTableDataInd',
	'VirtualTableDataListDomain',
	'VirtualTableDataNum',
	'VirtualTableDataString',
	'VirtualTableStationing')

	OPEN DeleteTables
	FETCH NEXT FROM DeleteTables INTO @TableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = ''

		SELECT @SQL += 'ALTER TABLE ' + OBJECT_NAME(fkc.parent_object_id) + ' DROP CONSTRAINT '
				+ OBJECT_NAME(fkc.constraint_object_id) + CHAR(10)
		FROM sys.foreign_key_columns fkc
		JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
		JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
		WHERE OBJECT_NAME(referenced_object_id) = @TableName

		SET @SQL += 'DROP TABLE ' + @TableName;

		EXECUTE (@SQL)

		FETCH NEXT FROM DeleteTables INTO @TableName
	END

	CLOSE DeleteTables
	DEALLOCATE DeleteTables
END