/*
	NOTE**** BEFORE RUNNING THIS SCRIPT be sure to set the CONFIG database variable below. The script
	must be executed on the stage database
*/
DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @StageDB NVARCHAR(100);
DECLARE @ConfigDB NVARCHAR(100);
DECLARE @Count INT
DECLARE @DomainCatalogId INT;

--**************************************** SET THE FOLLOWING VARIABLES ********************************

SET @ConfigDB = 'TMC_IRASv6_CONFIG'

--**********************************************************************************************************

---------------------------- Check that a valid Config and Stage DB is being used --------------------------

SELECT @StageDB = DB_NAME()

-- Check that the stage database is valid stage or link db
SET @SQL = 'SELECT @Result = COUNT(*) FROM '+@StageDB+'..VersionInfo 
			WHERE DBVersionComment NOT LIKE ''%Config%'''

EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

IF @Count = 0
BEGIN
	SET @SQL = 'THROW 51000, N''The specified Stage database is not a valid Stage database'', 1;'
	EXECUTE (@SQL)
END

-- Check that the config database exists on the server, is a valid config db, and is from same client as stage
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @ConfigDB)
BEGIN
	SET @SQL = 'THROW 51000, N''A valid Config database must be specified'', 1;'
	EXECUTE (@SQL)
END
ELSE IF (SUBSTRING(@StageDB, 1, CHARINDEX('_', @StageDB) - 1) <> SUBSTRING(@ConfigDB, 1, CHARINDEX('_', @ConfigDB) - 1))
BEGIN
	SET @SQL = 'THROW 51000, N''The stage and config databases are not from the same client'', 1;'
	EXECUTE (@SQL)
END
ELSE
BEGIN
	SET @SQL = 'SELECT @Result = COUNT(*) FROM '+@ConfigDB+'..VersionInfo 
				WHERE DBVersionComment LIKE ''%Config%'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

	IF @Count = 0
	BEGIN
		SET @SQL = 'THROW 51000, N''The specified Config database is not a valid Config database'', 1;'
		EXECUTE (@SQL)
	END
END

----------------------------------------- Table Definitions -----------------------------------------

IF OBJECT_ID('tempdb..##ListDomainInfo') IS NOT NULL
BEGIN
	DROP TABLE ##ListDomainInfo
END

IF OBJECT_ID('tempdb..##ListDomainInfo') IS NULL
BEGIN
	CREATE TABLE ##ListDomainInfo ( Id INT, 
									DomainCatalogId INT,
									Code NVARCHAR(60),  
									Descr NVARCHAR(255));
END

IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
BEGIN
	DROP TABLE ##NewDomainTableList;
END;

/*
	Generates a list of all child tables with a foreign key constraint referencing the 
	ListDomain table and store the results in a temporary table
*/

IF OBJECT_ID ('tempdb..##NewDomainTableList') IS NULL
BEGIN
	CREATE TABLE ##NewDomainTableList  (Id INT IDENTITY(1,1),
						FKConstraint NVARCHAR(100),
						FKTableName NVARCHAR(100),
						FKColumnName NVARCHAR(100),
						NewListDomainTable NVARCHAR(100),
						DomainCatalogId INT,
						DomainDescr NVARCHAR(100)
						);

	SET @SQL = '
	INSERT INTO ##NewDomainTableList --(FKConstraint, FKTableName, FKColumnName)
	SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
		   OBJECT_NAME(parent_object_id) AS fk_table,
		   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		   NULL,
		   NULL,
		   NULL
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = ''ListDomain''
	AND OBJECT_NAME(parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'')
	UNION
	SELECT NULL,
		   NULL,
		   NULL,
		   CASE 
				WHEN LEN (REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''')) > 28
					THEN ''LD_'' + SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), 1, 28) 
				ELSE ''LD_'' + REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''') 
			END AS new_table_name,
			Id,
			DomainDescr
	FROM DomainCatalog
	WHERE Id <> -1'

	EXECUTE (@SQL)

END

/*****************************************************************************************
                 Create and Populate New List Domain Tables 
**********************************************************************************************/

DECLARE LDTables_Cursor CURSOR FOR
SELECT FKTableName,
	   FKColumnName,
	   NewListDomainTable,
	   DomainCatalogId
FROM ##NewDomainTableList

OPEN LDTables_Cursor
FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId

WHILE @@FETCH_STATUS = 0
BEGIN
------------------- 1) ListDomain source-table columns that can be found in DomainCAtalogXRef table
	
	-- Store all ListDomain table entries for the table and column in the current loop iteration into a temporary table
	SET @SQL = 'DELETE FROM ##ListDomainInfo

					INSERT INTO ##ListDomainInfo (Id, DomainCatalogId, Code, Descr)
					SELECT Id,
						   DomainCatalogId,
						   Code,
						   Descr
					FROM ListDomain
					WHERE Id IN (SELECT DISTINCT ' + @FKColumnName + ' FROM ' + @FKTableName+ ')'

	EXECUTE (@SQL)

	SELECT @DomainCatalogId = DomainCatalogId FROM DomainCatalogColXRef
	WHERE TableName = @FKTableName
	AND ColumnName = @FKColumnName
	
	/*
		If the table and column in the current loop has an entry in the DomainCatalogColXRef table
		and more than 1 distinct DomainCatalogIds (other than -1) in it's ListDomain table entries,
		throw an error and force the user to fix the issue manually
	*/
	IF (@DomainCatalogId IS NOT NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) >= 2
	BEGIN

		PRINT CHAR(10) + 'ERROR: More than 1 distinct DomainCatalogId was found in the Listdomain table for Column '''  
						+ @FKColumnName + '''' + CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + ''''
						+ '. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
						+ CHAR(10) + CHAR(9) + CHAR(9) + 'The query below shows all the ListDomain table entries for the table-column combination mentioned' + CHAR(10)
		
		PRINT 'QUERY: SELECT * FROM ##ListDomainInfo' + CHAR(10)

		PRINT 'SOLUTION: An entry was found in the DomainCatalogColXRef table. Replace the values in the column ''' + @FKColumnName + ''''
				+ CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + '''' 
				+ ' with Ids from the ListDomain table that have the appropriate Code, Descr, '
				+ CHAR(10) + CHAR(9) + CHAR(9) + 'and a DomainCatalogId of ' + CAST(@DomainCatalogId AS NVARCHAR) + '.' 
				 + ' You can modify and use the following command.' + CHAR(10) 
		PRINT 'COMMAND: UPDATE ' + @FKTableName + ' SET ' + @FKColumnName + ' = {NewListDomainId}' + CHAR(10) +
			'		 WHERE ' + @FKColumnName + ' = {OldListDomainId}' + CHAR(10)
				
		SET @SQL = 'THROW 51001, N''There are duplicate DomainCatalogIds in the ListDomain table entries for Column '''''
					+ @FKColumnName + '''''' + CHAR(10) + 'of table ''''' + @FKTableName + '''''. You must manually fix the issue before re-running the script'', 1;'
		EXECUTE (@SQL)
							
	END
	/*
		if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
		table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
		then throw an error to force user to manually fix the issue
	*/
	ELSE IF (@DomainCatalogId IS NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) >= 2
	BEGIN
		PRINT CHAR(10) + 'ERROR: More than 1 distinct DomainCatalogId was found in the Listdomain table for Column ---> '  
						+ @FKColumnName + CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + ''''
						+ '. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
						+ CHAR(10) + CHAR(9) + CHAR(9) + 'The query below shows all the ListDomain table entries for the table-column combination mentioned' + CHAR(10)
		
		PRINT 'QUERY: SELECT * FROM ##ListDomainInfo' + CHAR(10)
		
		PRINT 'SOLUTION: A reference could not be found in the DomainCatalogColXRef table for column ''' + @FKColumnName + ''''
			+ CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + '''. '
			+ 'Talk to the BA assigned to the client for this database.' 
			+ CHAR(10) + CHAR(9) + CHAR(9) + 'You may need to set some values in ''' + @FKColumnName+ ''' column of ''' + @FKTableName + ''' table to NULL' + CHAR(10)	
	
		SET @SQL = 'THROW 51001, N''There are duplicate DomainCatalogIds in the ListDomain table entries for Column '''''  
					+ @FKColumnName + '''''' + CHAR(10) + 'of table ''''' + @FKTableName +'''''. You must manually fix the issue before re-running the script'', 1;'
		EXECUTE (@SQL)
	END
	/*
		If the table and column in the current loop has an entry in the DomainCatalogColXRef table
		or has entries in the ListDomain table with a single distinct DomainCatalogId other than -1
		Then the new list domain table name should be one of the tables already in the temporary table ##NewDomainTableList
	*/	
	ELSE IF (@DomainCatalogId IS NOT NULL) OR (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1 ) = 1
	BEGIN
		IF (@DomainCatalogId IS NULL)
		BEGIN
			-- The Domain Catalog will be the value that is not -1
			SELECT @DomainCatalogId = DomainCatalogId FROM ##ListDomainInfo
									WHERE DomainCatalogId <> -1
		END

		UPDATE ##NewDomainTableList
		SET NewListDomainTable = st.NewListDomainTable,
			DomainCatalogId = st.DomainCatalogId,
			DomainDescr = st.DomainDescr
		FROM (SELECT NewListDomainTable, DomainCatalogId, DomainDescr
				FROM ##NewDomainTableList
				WHERE DomainCatalogId = @DomainCatalogId
					AND FKTableName IS NULL) st
		WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName

	END
	ELSE 
	BEGIN
		/*
            If the current table and column has the same name as another table and column 
            that already has a Domainid, Domaindescr, and new list domain table name, then 
            use that new list domain table name
        */
		IF EXISTS (SELECT 1 FROM ##NewDomainTableList WHERE FKColumnName = @FKColumnName 
				   AND DomainCatalogId IS NOT NULL
				 )
		BEGIN
			UPDATE ##NewDomainTableList
			SET DomainCatalogId = st.DomainCatalogId,
				DomainDescr = st.DomainDescr,
				NewListDomainTable = st.NewListDomainTable
			FROM (SELECT DomainCatalogId, DomainDescr, NewListDomainTable
				  FROM ##NewDomainTableList
				  WHERE FKColumnName = @FKColumnName
				  AND DomainCatalogId IS NOT NULL) st
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName

		END
		-- Use the 'Coordinate System' DomainCatalog Id, Descr and tablename for columns with 'CoordSys' in the name
		ELSE IF (@FKColumnName LIKE '%CoordSys%')
		BEGIN
			UPDATE ##NewDomainTableList
			SET DomainCatalogId = st.DomainCatalogId,
				DomainDescr = st.DomainDescr,
				NewListDomainTable = st.NewListDomainTable
			FROM (SELECT TOP 1 DomainCatalogId, DomainDescr, NewListDomainTable
					FROM ##NewDomainTableList
					WHERE DomainDescr = 'Coordinate System'
					AND DomainCatalogId IS NOT NULL) st
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName

		END
		-- For rows with null DomainCatalogId, match column names with DomainDescr from DomainCatalog table by removing 'DomainId' suffix
		ELSE IF EXISTS (SELECT 1 FROM DomainCatalog 
						WHERE REPLACE(DomainDescr, ' ', '') = REPLACE(@FKColumnName, 'DomainId', '')
						)
		BEGIN
			UPDATE ##NewDomainTableList 
			SET DomainCatalogId = st.DomainCatalogId,
				DomainDescr = st.DomainDescr,
				NewListDomainTable = st.NewListDomainTable 
			FROM (SELECT s2.NewListDomainTable, 
						s2.DomainCatalogId, 
							s2.DomainDescr
					FROM ##NewDomainTableList s1
					JOIN ##NewDomainTableList s2
						ON REPLACE(s1.FKColumnName, 'DomainId', '') = REPLACE(s2.DomainDescr, ' ', '')
						AND s1.DomainCatalogId IS NULL
						AND s2.FKColumnName IS NULL) st
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName
		END
		-- For rows with null DomainCatalogId, match column names with DomainDescr from DomainCatalog table by removing 'Ld' suffix
		ELSE IF EXISTS (SELECT 1 FROM DomainCatalog 
						WHERE REPLACE(DomainDescr, ' ', '') = REPLACE(@FKColumnName, 'Ld', '')
						)
		BEGIN	
			UPDATE ##NewDomainTableList 
			SET DomainCatalogId = st.DomainCatalogId,
				DomainDescr = st.DomainDescr,
				NewListDomainTable = st.NewListDomainTable 
			FROM (SELECT s2.NewListDomainTable, 
						s2.DomainCatalogId, 
							s2.DomainDescr
					FROM ##NewDomainTableList s1
					JOIN ##NewDomainTableList s2
						ON REPLACE(s1.FKColumnName, 'Ld', '') = REPLACE(s2.DomainDescr, ' ', '')
						AND s1.DomainCatalogId IS NULL
						AND s2.FKColumnName IS NULL) st	
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName
		END
		ELSE IF (@FKTableName LIKE 'IRASCustomData%')
		BEGIN
			SET @NewTableName = 'LD_' + @FKTableName + REPLACE(@FKColumnName, '_DomainId', '')
			
			UPDATE ##NewDomainTableList
			SET NewListDomainTable = @NewTableName
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName	
		END
		ELSE
		BEGIN
			SET @NewTableName = 'LD_' + REPLACE(REPLACE(@FKColumnName, 'DomainId', ''), 'Ld', '') 

			UPDATE ##NewDomainTableList
			SET NewListDomainTable = @NewTableName
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName	
		END
	END

	-- Set the name for the new list domain table
	SELECT @NewTableName = NewListDomainTable 
							FROM ##NewDomainTableList
							WHERE FKTableName = @FKTableName
								AND FKColumnName = @FKColumnName

-------------------------------------- CREATE New ListDomain tables ---------------------------------------

	-- Create the new list domain table if it does not already exist
	IF OBJECT_ID(@StageDB + '..' + @NewTableName, 'U') IS NULL
	BEGIN
		SET @SQL = 'CREATE TABLE [' + @StageDB + '].[dbo].[' + @NewTableName + '](
		[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
		[Code] [varchar](60) NOT NULL,
		[Descr] [varchar](255) NOT NULL,
		[EffectiveEndDate] [Datetime],
		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
		CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
		) ON [PRIMARY]';

		EXECUTE (@SQL);

		-- Recreate update trigger on new listdomain table table
		IF OBJECT_ID (@StageDB + '..tu_' + @NewTableName + '', 'TR') IS NULL
		BEGIN
			SET @SQL = 'CREATE TRIGGER [dbo].[tu_' + @NewTableName + '] ON [dbo].[' + @NewTableName + '] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.' + @NewTableName + '
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.' + @NewTableName + ' as t, DELETED as d
				WHERE t.Id=d.Id;
			END'

			EXECUTE (@SQL)
		END
	END;

-------------------------------- Populate the New List Domain Table ----------------------------------
 
	-- Populate the new list domain table
	SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
				
				WITH tmpQuery AS 
				(SELECT Id,
						DomainCatalogId,
						Code,
						Descr
				FROM ListDomain
				WHERE Id IN (SELECT DISTINCT ' + @FKColumnName + ' FROM ' + @FKTableName + ')
				UNION
				SELECT Id,
						DomainCatalogId,
						Code,
						Descr
				FROM ListDomain WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) +'
				)
				INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
				SELECT Id,
					   CASE 
						WHEN Code = '''' THEN ''<None>''
						ELSE Code
						END AS Code,
					   CASE 
						WHEN Code = '''' THEN ''<None>''
						ELSE Descr
						END AS Descr,
					   CASE 
							WHEN DomainCatalogId = -1 THEN GETDATE()
							ELSE NULL
						END AS EffectiveEndDate
				FROM tmpQuery
				WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName + ')
				ORDER BY 1

				SET IDENTITY_INSERT ' + @NewTableName + ' ON'
	
	EXECUTE (@SQL)

---------------------------- UPDATE TempListDomainTable IN CONFIG DB ---------------------------------------

	-- Create TempListDomainTable table in Config database if it doesn't already exist
	SET @SQL = 'IF OBJECT_ID('''+ @ConfigDB +'..TempListDomainTable'') IS NULL
				BEGIN
					CREATE TABLE '+ @ConfigDB +'.dbo.TempListDomainTable (TableType VARCHAR(50),
																			ListDomainTableName VARCHAR(50),
																			ReferencedTableName VARCHAR(50),
																			ReferencedColumnName VARCHAR(50),
																			DomainCatalogId INT,
																			DomainDescr VARCHAR(255),
																			NumOfRowsinListDomainTbl INT
																			)
				END'

	EXECUTE (@SQL)

	-- Delete and re-insert entries for table and column in current loop iteration into TempListDomainTable
	IF (@FKTableName IS NOT NULL)
	BEGIN
		SET @SQL = 'IF OBJECT_ID (''' + @ConfigDB + '..TempListDomainTable'') IS NOT NULL
					BEGIN 
						IF (SELECT COUNT(*) FROM ' + @ConfigDB +'..TempListDomainTable
							WHERE ReferencedTableName = ''' + @FKTableName + '''
							AND ReferencedColumnName = ''' + @FKColumnName + '''
							AND TableType = ''Real''
							) <> 0
						BEGIN
							-- Delete entry from TempListDomainTable table if it already exists
							DELETE FROM ' + @ConfigDB +'..TempListDomainTable
							WHERE ReferencedTableName = ''' + @FKTableName + '''
							AND ReferencedColumnName = ''' + @FKColumnName + '''
							AND TableType = ''Real''
						END

						-- Insert new entries into TempListDomainTable table			
						INSERT INTO ' + @ConfigDB +'..TempListDomainTable
						SELECT ''Real'',
								NewListDomainTable,
								FKTableName,
								FKColumnName,
								DomainCatalogId,
								DomainDescr,
								(SELECT COUNT(*) FROM ListDomain 
								WHERE Id IN (SELECT ' + @FKColumnName + ' FROM ' + @FKTableName + '))
						FROM ##NewDomainTableList
						WHERE FKTableName = ''' + @FKTableName+ '''
						AND FKColumnName = ''' + @FKColumnName +'''
				END'

		EXECUTE (@SQL)
	END
	ELSE
	BEGIN
		SET @SQL = 'IF OBJECT_ID (''' + @ConfigDB + '..TempListDomainTable'') IS NOT NULL
					BEGIN 
						IF (SELECT COUNT(*) FROM ' + @ConfigDB +'..TempListDomainTable
							WHERE TableType = ''Real''
							AND ReferencedTableName IS NULL) <> 0
						BEGIN
							DELETE FROM ' + @ConfigDB + '..TempListDomainTable
							WHERE ListDomainTableName = ''' + @NewTableName + '''
							AND TableType = ''Real''
							AND ReferencedTableName IS NULL
						END

						-- Insert new entries into TempListDomainTable table			
						INSERT INTO ' + @ConfigDB +'..TempListDomainTable
									SELECT ''Real'',
								NewListDomainTable,
								FKTableName,
								FKColumnName,
								DomainCatalogId,
								DomainDescr,
								NULL
						FROM ##NewDomainTableList
						WHERE NewListDomainTable = ''' + @NewTableName + '''
						AND FKTableName IS NULL
					END'

		EXECUTE (@SQL)
	END
		
--------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------
		
	SELECT @FKConstraintName = FKConstraint FROM ##NewDomainTableList
							WHERE FKTableName = @FKTableName
							AND FKColumnName = @FKColumnName

	-- Drop the foreign key on the domain child table if it references the ListDomain table
	IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(constraint_object_id) = @FKConstraintName
				AND OBJECT_NAME(referenced_object_id) = 'ListDomain') 
	BEGIN
		BEGIN TRY
			SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;

			EXECUTE (@SQL);
		END TRY
		BEGIN CATCH
			PRINT 'Msg: ' + ERROR_MESSAGE() + CHAR(10);
			SELECT @SQL AS Failing_SQL;
		END CATCH;
	END;

-------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------
	
	-- recreate foreign keys on domain child table to reference new domain table
	IF OBJECT_ID(@FKConstraintName, 'F') IS NULL
	BEGIN
		BEGIN TRY
		SET @SQL = 'ALTER TABLE ' + @FKTableName + ' ADD CONSTRAINT ' + @FKConstraintName + ' FOREIGN KEY (' + @FKColumnName + ') 
					REFERENCES ' + @NewTableName + '(Id)';

		EXECUTE (@SQL);
		END TRY
		BEGIN CATCH
			PRINT 'Msg: ' + ERROR_MESSAGE() + CHAR(10);
			SELECT @SQL AS Failing_SQL;
		END CATCH;
	END;
	
	FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId

END
CLOSE LDTables_Cursor
DEALLOCATE LDTables_Cursor

/*****************************************************************************************
                 Modify RememberedListDomainValues and ActionItemPropDCXRef tables
**********************************************************************************************/

----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE Table_Name = 'RememberedListDomainValues'
				AND Column_Name = 'ListDomainTableName')
BEGIN
	-- Copy data from RememberedListDomainValues into temporary table
	SET @SQL = 'SELECT Id, 
		   DomainValue,
		   ListDomainId,
		   (SELECT TOP 1 NewListDomainTable FROM ##NewDomainTableList
		    WHERE DomainCatalogId = rldv.DomainCatalogId) AS ListDomainTableName,
			CreatedUser,
			CreatedDate,
			LastModByUserId,
			LastModDateTime
	INTO ##RememberedListDomainValues
	FROM RememberedListDomainValues rldv'

	EXECUTE (@SQL)

	SELECT TOP 1 @FKConstraintName = OBJECT_NAME(constraint_object_id)		  
	FROM sys.foreign_key_columns
	WHERE OBJECT_NAME(parent_object_id) = 'RememberedListDomainValues'
	AND OBJECT_NAME(referenced_object_id) IN ('ListDomain', 'DomainCatalog')

	-- Drop the second foreign keys on the RememberedListDomainValues table referencing ListDomain or DomainCatalog table
	IF OBJECT_ID(@FKConstraintName, 'F') IS NOT NULL
	BEGIN
		SET @SQL = 'ALTER TABLE RememberedListDomainValues DROP CONSTRAINT ' + @FKConstraintName + ''
		EXECUTE (@SQL)
	END

	SELECT TOP 1 @FKConstraintName = OBJECT_NAME(constraint_object_id)	
	FROM sys.foreign_key_columns
	WHERE OBJECT_NAME(parent_object_id) = 'RememberedListDomainValues'
	AND OBJECT_NAME(referenced_object_id) IN ('ListDomain', 'DomainCatalog')

	-- Drop the second foreign keys on the RememberedListDomainValues table referencing ListDomain or DomainCatalog table
	IF OBJECT_ID(@FKConstraintName, 'F') IS NOT NULL
	BEGIN
		SET @SQL = 'ALTER TABLE RememberedListDomainValues DROP CONSTRAINT ' + @FKConstraintName + ''
		EXECUTE (@SQL)
	END

	-- Drop the RememberedListDomainValues
	IF OBJECT_ID (@StageDB + '..RememberedListDomainValues', 'U') IS NOT NULL
	BEGIN
		DROP TABLE RememberedListDomainValues;
	END

	-- Recreate the RememberedListDomainValues table
	IF OBJECT_ID (@StageDB + '..RememberedListDomainValues', 'U') IS NULL
	BEGIN
		SET @SQL = 'SELECT * INTO RememberedListDomainValues
					FROM ##RememberedListDomainValues
					ORDER BY 1

					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [CreatedDate]

					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'

		EXECUTE (@SQL)

	END

	-- Recreate update trigger on RememberedListDomainValues table
	IF OBJECT_ID (@StageDB + '..tu_RememberedListDomainValues', 'TR') IS NULL
	BEGIN
		SET @SQL = 'CREATE TRIGGER [dbo].[tu_RememberedListDomainValues] ON [dbo].[RememberedListDomainValues] FOR UPDATE AS 
		IF EXISTS(SELECT * FROM DELETED)
		BEGIN
			UPDATE dbo.RememberedListDomainValues
			SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
			FROM dbo.RememberedListDomainValues as t, DELETED as d
			WHERE t.Id=d.Id;
		END'

		EXECUTE (@SQL)
	END
END

-------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------
	
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE Table_Name = 'ActionItemPropDCXRef'
				AND Column_Name = 'ListDomainTableName')
BEGIN
	
	IF OBJECT_ID ('tempdb..##ActionItemPropDCXRef', 'U') IS NULL
	BEGIN
		-- Store data from ActionItemPropDCXRef into temporary table 
		SET @SQL = 'SELECT ActionItemPropertyId,
							(SELECT TOP 1 NewListDomainTable FROM ##NewDomainTableList
							WHERE DomainCatalogId = aip.DomainCatalogId) AS ListDomainTableName,
							CreatedUser,
							CreatedDate,
							LastModByUserId,
							LastModDateTime
					INTO ##ActionItemPropDCXRef 
					FROM ActionItemPropDCXRef aip'

		EXECUTE (@SQL)
	END

	SELECT TOP 1 @FKConstraintName = OBJECT_NAME(constraint_object_id)	
	FROM sys.foreign_key_columns
	WHERE OBJECT_NAME(parent_object_id) = 'ActionItemPropDCXRef'
	AND OBJECT_NAME(referenced_object_id) IN ('DomainCatalog', 'ListDomain')

	-- Drop the foreign key on the ActionItemPropDCXRef table referencing DomainCatalog or ListDomain tables
	IF OBJECT_ID(@FKConstraintName, 'F') IS NOT NULL
	BEGIN
		SET @SQL = 'ALTER TABLE ActionItemPropDCXRef DROP CONSTRAINT ' + @FKConstraintName + ''
		EXECUTE (@SQL)
	END

	-- Drop ActionItemPropDCXRef table
	IF OBJECT_ID (@StageDB + '..ActionItemPropDCXRef') IS NOT NULL
	BEGIN
		DROP TABLE ActionItemPropDCXRef;
	END

	-- Recreate ActionItemPropDCXRef table
	IF OBJECT_ID (@StageDB + '..ActionItemPropDCXRef') IS NULL
	BEGIN
		SET @SQL = 'SELECT * INTO ActionItemPropDCXRef
					FROM ##ActionItemPropDCXRef
					
					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [CreatedDate]

					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'

		EXECUTE (@SQL)
	END

	-- Recreate update trigger on ActionItemPropDCXRef
	IF OBJECT_ID (@StageDB + '..tu_ActionItemPropDCXRef', 'TR') IS NULL
	BEGIN
		SET @SQL = 'CREATE TRIGGER [dbo].[tu_ActionItemPropDCXRef] ON [dbo].[ActionItemPropDCXRef] FOR UPDATE AS 
		IF EXISTS(SELECT * FROM DELETED)
		BEGIN
			UPDATE dbo.ActionItemPropDCXRef
			SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
			FROM dbo.ActionItemPropDCXRef as t, DELETED as d
			WHERE t.ActionItemPropertyId=d.ActionItemPropertyId;
		END'

		EXECUTE (@SQL)
	END

	-- Recreate Foreign key referencing the ActionItemProperty table
	IF NOT EXISTS (SELECT 1 FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = 'ActionItemPropDCXRef'
					AND OBJECT_NAME(referenced_object_id) = 'ActionItemProperty')
	BEGIN
		ALTER TABLE ActionItemPropDCXRef ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
		FOREIGN KEY (ActionItemPropertyId) REFERENCES ActionItemProperty (Id)
	END

END

------------------------------------------ DELETE OBSELETE TABLES ------------------------------------------------

/*
	Drop the ListDomain, DomainCatalog, and DomainCatalogColXRef tables if all foreign key constraints have been
	successfully transfered to the new domain tables
*/
IF NOT EXISTS (SELECT 1 FROM ##NewDomainTableList
				WHERE FKConstraint NOT IN (SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint
											FROM sys.foreign_key_columns
											WHERE OBJECT_NAME(constraint_object_id) IN (select FKConstraint FROM ##NewDomainTableList)
											AND OBJECT_NAME(referenced_object_id) <> 'ListDomain'
											)
				)
BEGIN
	IF OBJECT_ID('ListDomain', 'U') IS NOT NULL
	BEGIN
		DROP TABLE ListDomain;
	END;

	IF OBJECT_ID('DomainCatalogColXRef', 'U') IS NOT NULL
	BEGIN
		DROP TABLE DomainCatalogColXRef;
	END;

	IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog')
	BEGIN
		DECLARE FKList_Cursor CURSOR FOR
		SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
			   OBJECT_NAME(parent_object_id) AS fk_table
		FROM sys.foreign_key_columns
		WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog';

		OPEN FKList_Cursor;
		FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;
			EXECUTE (@SQL);

			FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;
		END;

		CLOSE FKList_Cursor;
		DEALLOCATE FKList_Cursor;
	END;

	IF OBJECT_ID('DomainCatalog', 'U') IS NOT NULL
	BEGIN
		DROP TABLE DomainCatalog;
	END;

END;