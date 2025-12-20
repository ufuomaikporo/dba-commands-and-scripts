/*

This script takes the ListDomain data for all tables referencing the ListDomain table and seperates them
into new tables prefixed with 'GLD_' for shared data or 'LD_' for non-shared data. 

This script also 
1) Takes the ListDomain data in the Category and CategoryDataListDomainXRef tables, breaks it up into smaller tables 
with names prefixed by 'LD_CD_', then drops the Category and CategoryDataListDomainXRef tables. 
2) Modifies the ActionItemPropDCXRef table by adding columns referencing the newly created LisDomain tables.
3) Drops the ListDomain, DomainCatalog, and DomainCatalogColXRef tables

This script must be executed on the target database

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
DECLARE @CategoryId INT;
DECLARE @DomainDescr NVARCHAR(200);

----------------------------------------- Table Definitions -----------------------------------------

IF EXISTS(SELECT 1 FROM sys.tables WHERE name IN ('DomainCatalog', 'ListDomain')) 
BEGIN

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
							DomainDescr NVARCHAR(MAX),
							flag BIT
							);

		SET @SQL = '
		INSERT INTO ##NewDomainTableList 
		SELECT OBJECT_NAME(fkc.constraint_object_id) AS fk_constraint,
			   OBJECT_NAME(fkc.parent_object_id) AS fk_table,
			   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column,
			   ldt.LDTableName,
			   ldt.DomainCatalogId,
			   ldt.DomainDescr,
			   ldt.flag
		FROM sys.foreign_key_columns fkc
		right JOIN DrasInternal.dbo.ListDomainTableInfo  ldt
		ON ldt.DBName = DB_NAME() AND ldt.TableName = OBJECT_NAME(fkc.parent_object_id) 
		AND ldt.ColumnName = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
		WHERE OBJECT_NAME(fkc.referenced_object_id) = ''ListDomain''
		AND OBJECT_NAME(fkc.parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
	'

		EXECUTE (@SQL)

	END

	-- Add entries for DomainCatalogIds that are not associated with any table column
	INSERT INTO ##NewDomainTableList
	SELECT NULL AS FKConstraint,
		   NULL AS FKTableName,
		   NULL AS FKColumName,
		   ldt.LDTableName,
		   ldt.DomainCatalogId,
		   ldt.DomainDescr,
		   ldt.flag
	FROM DrasInternal.dbo.ListDomainTableInfo ldt
	WHERE DBName = DB_NAME()
	AND TableName IS NULL

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
	--------------------- 1) ListDomain source-table columns that can be found in DomainCAtalogXRef table
	
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
				
			SET @SQL = 'THROW 51001, N''There are duplicate DomainCatalogIds in the ListDomain table for Column '''''
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
	
		-- Use the ListDomainTableInfo table in the DrasInternal database to update the new list domain table name and DomainCatalogId if the table name is null
		UPDATE ##NewDomainTableList
		SET NewListDomainTable = (SELECT TOP 1 LDTableName FROM DrasInternal.dbo.ListDomainTableInfo 
									WHERE DomainDescr = (SELECT DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId)
									AND LDTableName IS NOT NULL),
		DomainCatalogId = @DomainCatalogId
		WHERE FKTableName = @FKTableName
		AND FKColumnName = @FKColumnName
		AND NewListDomainTable IS NULL

		-- Assign the new list domain table name from ##NewDomainTableList table to variable
		SELECT @NewTableName = NewListDomainTable 
		FROM ##NewDomainTableList
		WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName
	
	
	/*****************************************************************************************
					 Create and Populate New List Domain Tables 
	**********************************************************************************************/
	
	-------------------------------------- CREATE New ListDomain tables ---------------------------------------

		-- Create the new list domain table if it does not already exist
		IF OBJECT_ID(@NewTableName, 'U') IS NULL
		BEGIN
			SET @SQL = 'CREATE TABLE [dbo].[' + @NewTableName + '](
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
			IF OBJECT_ID ('tu_' + @NewTableName + '', 'TR') IS NULL
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
		IF (@FKColumnName IS NOT NULL)
		BEGIN
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
						AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')
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

						SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
		END
		ELSE 
		BEGIN
			SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
				
						WITH tmpQuery AS 
						(SELECT Id,
								DomainCatalogId,
								Code,
								Descr
						FROM ListDomain WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) +'
						AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')
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
						
						SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
		END

	
		EXECUTE (@SQL)
		
	------------------------------ UPDATE TempListDomainTable  ---------------------------------------

		-- Create TempListDomainTable table in Config database if it doesn't already exist
		SET @SQL = 'IF OBJECT_ID(''TempListDomainTable'', ''U'') IS NULL
					BEGIN
						CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																				ListDomainTableName VARCHAR(100),
																				ReferencedTableName VARCHAR(50),
																				ReferencedColumnName VARCHAR(50),
																				DomainCatalogId INT,
																				DomainDescr VARCHAR(255)
																				)
					END'

		EXECUTE (@SQL)

		-- Insert entries for table and column in current loop iteration into TempListDomainTable
		IF (@FKColumnName IS NOT NULL)
		BEGIN 
			IF NOT EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Real' 
							AND ReferencedTableName = @FKTableName AND ReferencedColumnName = @FKColumnName
							AND ListDomainTableName = @NewTableName)
			BEGIN
			
				INSERT INTO TempListDomainTable
				SELECT 'Real',
						@NewTableName,
						@FKTableName,
						@FKColumnName,
						@DomainCatalogId,
						(SELECT DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId)
			END
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Real' 
						AND ListDomainTableName = @NewTableName)
			BEGIN
				INSERT INTO TempListDomainTable
				SELECT 'Real',
						@NewTableName,
						NULL,
						NULL,
						@DomainCatalogId,
						(SELECT DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId)
			END
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

	---------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------
	
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

END 

IF EXISTS (SELECT 1 FROM sys.foreign_key_columns fkc 
			WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
			AND OBJECT_NAME(parent_object_id) NOT IN ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef'))
BEGIN
	DROP TABLE IF EXISTS ##NewDomainTableList
	DROP TABLE IF EXISTS ##ListDomainInfo

	SET @SQL = 'THROW 51001, N''The script did not complete its execution due to existing foreign keys referencing the ListDomain table.' +
	CHAR(10) + 'Make sure the Virtual tables ListDomain script has been executed first'', 1;'
	EXECUTE (@SQL)
	
END

/*************************************************************************************************
					CREATE New Tables for CategoryDataListDomainXRef Table
**************************************************************************************************/

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NOT NULL AND OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	DROP TABLE ##NewDomainTableList;
END

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NULL AND OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	SET @SQL = '
	WITH tmpQuery AS
	(SELECT ROW_NUMBER() OVER (PARTITION BY CategoryId ORDER BY CategoryId) row_num,
			ValueDomainId, 
			CategoryId, 
			 CASE 
					WHEN LEN (REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''')) > 24
						THEN ''LD_CD_'' + SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', ''''), 1, 24) 
					ELSE ''LD_CD_'' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', '''')
				END AS new_table_name, 
			CategoryDescr 
	FROM CategoryDataListDomainXRef cdldx
	JOIN Category c
		ON c.Id = cdldx.CategoryId
	)
	SELECT CategoryId, new_table_name 
	INTO ##NewCategoryTableList
	FROM tmpQuery
	WHERE row_num = 1'

	EXECUTE(@SQL)

	DECLARE LDTables_Cursor CURSOR FOR
	SELECT * FROM ##NewCategoryTableList

	OPEN LDTables_Cursor
	FETCH NEXT FROM LDTables_Cursor INTO @CategoryId, @NewTableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
--------------------------------------- CREATE New ListDomain tables ---------------------------------------

		-- Create the new list domain table if it does not already exist
		IF OBJECT_ID(@NewTableName, 'U') IS NULL
		BEGIN
			SET @SQL = 'CREATE TABLE [dbo].[' + @NewTableName + '](
			[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
			[CategoryCode] [varchar](60) NOT NULL,
			[CategoryDescr] [varchar](255) NOT NULL,
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
			IF OBJECT_ID ('..tu_' + @NewTableName + '', 'TR') IS NULL
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

---------------------------------- Populate the New List Domain Table ----------------------------------

		SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON

					INSERT INTO ' + @NewTableName + '(Id, CategoryCode, CategoryDescr)
					SELECT DISTINCT ValueDomainId,
						   CategoryCode,
						   CategoryDescr
					FROM CategoryDataListDomainXRef cdldx
					JOIN Category c
						ON c.Id = cdldx.CategoryId 
					WHERE CategoryId = ' + CAST(@CategoryId AS NVARCHAR) + '
					AND ValueDomainId NOT IN (SELECT Id FROM ' + @NewTableName + ')
					
					SET IDENTITY_INSERT ' + @NewTableName + ' OFF'

		EXECUTE(@SQL)

------------------------------ UPDATE TempListDomainTable IN CONFIG DB ---------------------------------------

		-- Create TempListDomainTable table in Config database if it doesn't already exist
		SET @SQL = 'IF OBJECT_ID(''TempListDomainTable'') IS NULL
					BEGIN
						CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																				ListDomainTableName VARCHAR(50),
																				ReferencedTableName VARCHAR(50),
																				ReferencedColumnName VARCHAR(50),
																				DomainCatalogId INT,
																				DomainDescr VARCHAR(255)
																				)
					END'

		EXECUTE (@SQL)

		-- Delete and re-insert entries for table and column in current loop iteration into TempListDomainTable
		SET @SQL = 'MERGE INTO TempListDomainTable s1
		USING (SELECT ''Real'' TableType,
						''' + @NewTableName + ''' AS NewTableName,
						NULL AS FKTableName,
						NULL AS FKColumnName,
						(SELECT MAX(ISNULL(DomainCatalogId, 0)) + 1 FROM TempListDomainTable) Id,
						(SELECT CategoryCode FROM Category WHERE Id = ' + CAST(@CategoryId AS NVARCHAR) + ') CategoryCode
				) s2
		ON (s1.DomainDescr = s2.CategoryCode)
		WHEN MATCHED THEN UPDATE
			SET s1.ListDomainTableName = s2.NewTableName,
				s1.DomainCatalogId = s2.Id,
				s1.DomainDescr = s2.CategoryCode
		WHEN NOT MATCHED THEN INSERT(TableType, ListDomainTablename, ReferencedTableName, ReferencedColumnName, DomainCatalogId, DomainDescr)
		VALUES (s2.TableType, s2.NewTableName, s2.FKTableName, s2.FKColumnName, s2.Id, s2.CategoryCode);'

		EXECUTE(@SQL)
		
		FETCH NEXT FROM LDTables_Cursor INTO @CategoryId, @NewTableName
	END;
	
	CLOSE LDTables_Cursor
	DEALLOCATE LDTables_Cursor
END

------------------------------- DROP CategoryDataListDomainXRef, and Category tables -------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
	   OBJECT_NAME(parent_object_id) AS fk_table
FROM sys.foreign_key_columns
WHERE OBJECT_NAME(referenced_object_id) IN ('Category', 'CategoryDataListDomainXRef')

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @FKConstraintName, @FKTableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName

	EXECUTE(@SQL)

	FETCH NEXT FROM DropFK_Cursor INTO @FKConstraintName, @FKTableName
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE CategoryDataListDomainXRef'
	EXECUTE(@SQL)
END

IF OBJECT_ID('Category', 'U') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE Category'
	EXECUTE(@SQL)
END

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NOT NULL
BEGIN
	DROP TABLE ##NewCategoryTableList;
END

--/*****************************************************************************************
--                 Modify RememberedListDomainValues and ActionItemPropDCXRef tables
--**********************************************************************************************/

----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE Table_Name = 'RememberedListDomainValues'
				AND Column_Name = 'ListDomainTableName') AND OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
BEGIN

	IF OBJECT_ID('tempdb..##RememberedListDomainValues') IS NOT NULL
	BEGIN
		DROP TABLE ##RememberedListDomainValues;
	END

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
	IF OBJECT_ID ('RememberedListDomainValues', 'U') IS NOT NULL
	BEGIN
		DROP TABLE RememberedListDomainValues;
	END

	-- Recreate the RememberedListDomainValues table
	IF OBJECT_ID ('RememberedListDomainValues', 'U') IS NULL
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
	IF OBJECT_ID ('tu_RememberedListDomainValues', 'TR') IS NULL AND OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
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
				AND Column_Name = 'ListDomainTableName') AND OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL
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
	IF OBJECT_ID ('ActionItemPropDCXRef', 'U') IS NOT NULL
	BEGIN
		DROP TABLE ActionItemPropDCXRef;
	END

	-- Recreate ActionItemPropDCXRef table
	IF OBJECT_ID ('ActionItemPropDCXRef', 'U') IS NULL 
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
	IF OBJECT_ID ('tu_ActionItemPropDCXRef', 'TR') IS NULL 
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
		SET @SQL = 'ALTER TABLE ActionItemPropDCXRef ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
		FOREIGN KEY (ActionItemPropertyId) REFERENCES ActionItemProperty (Id)'

		EXECUTE(@SQL)
	END

END

---------------------------------------- DELETE OBSELETE TABLES ------------------------------------------------

/*
	Drop the ListDomain, DomainCatalog, and DomainCatalogColXRef tables if all foreign key constraints have been
	successfully transfered to the new domain tables
*/
IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
BEGIN
	IF NOT EXISTS (SELECT * FROM ##NewDomainTableList
					WHERE FKConstraint IN (SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint
												FROM sys.foreign_key_columns
												WHERE OBJECT_NAME(constraint_object_id) IN (select FKConstraint FROM ##NewDomainTableList)
												AND OBJECT_NAME(referenced_object_id) = 'ListDomain'
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

		IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
		BEGIN
			DROP TABLE ##NewDomainTableList;
		END;

	END;


END