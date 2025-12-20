DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @ModifiedFKTableName NVARCHAR(100);
DECLARE @TempString NVARCHAR(100);
DECLARE @EndIndex INT;
DECLARE @StartIndex INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @CharToRemove INT;
DECLARE @CharToKeep INT;
DECLARE @IfExists INT;
DECLARE @Code NVARCHAR(100);
DECLARE @Descr NVARCHAR(100);

--------------------------------------------------- TABLES THAT WILL BE CREATED ------------------------------------------------------

IF OBJECT_ID('tempdb..##ListDomainInfo') IS NULL
BEGIN
	CREATE TABLE ##ListDomainInfo (OldDomainId INT, 
									NewDomainId INT, 
									Code NVARCHAR(60),  
									Descr NVARCHAR(255));
END

IF OBJECT_ID('tempdb..##FKList') IS NOT NULL
BEGIN
	DROP TABLE ##FKList;
END;

IF OBJECT_ID('tempdb..##FKList') IS NULL
BEGIN
	CREATE TABLE ##FKList  (Id INT IDENTITY(1,1),
							fk_constraint NVARCHAR(100),
							fk_table NVARCHAR(100),
							fk_column NVARCHAR(100),
							new_table_name NVARCHAR(100),
							ref_table NVARCHAR(100),
							ref_column NVARCHAR(100),
							CONSTRAINT [UQ_TmpFKList] UNIQUE (fk_constraint)
							);
END;

/*
	This query 
	1) Generates a list of all child tables with a foreign key constraint referencing the ListDomain table
	2) Uses the name of the foreign key column from the child table to generate a new name for the new Domain table that will
	   be used by the child table
	3) Stores the results in a temporary table
*/
IF NOT EXISTS (SELECT 1 FROM ##FKList)
BEGIN
	INSERT INTO ##FKList
	SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
		   OBJECT_NAME(parent_object_id) AS fk_table,
		   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		   CASE
		   WHEN PATINDEX('%_DomainId%', COL_NAME(parent_object_id, parent_column_id) ) > 0 
				THEN REPLACE(REPLACE(COL_NAME(parent_object_id, parent_column_id), '_DomainId', ''), 'DomainId', '') + 'LD'
		   WHEN PATINDEX('%LD', COL_NAME(parent_object_id, parent_column_id)) > 0
				THEN REPLACE(COL_NAME(parent_object_id, parent_column_id), 'LD', '') + 'LD'
		   ELSE COL_NAME(parent_object_id, parent_column_id) + 'LD'
		   END AS new_table_name,
		   OBJECT_NAME(referenced_object_id) AS ref_table,
		   COL_NAME(referenced_object_id, referenced_column_id) AS ref_column
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
	AND OBJECT_NAME(constraint_object_id) NOT IN (SELECT fk_constraint FROM ##FKList);
END

DECLARE FKList_Cursor CURSOR FOR
SELECT fk_constraint, 
	   fk_table, 
	   fk_column, 
	   new_table_name 
FROM ##FKList

OPEN FKList_Cursor
FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName, @FKColumnName, @NewTableName

/*
	Go through each row in the ##FKList table and...

	1) Create a new domain table
	2) Populate the new domain table
	3) Drop the foreign key referencing the old domain table (ListDomain)
	4) Update the foreign key column in the child table
	5) Recreate the foreign key to reference the new domain table
*/
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if the generated name for the new domain table is unique
	SET @SQL = 'IF (SELECT COUNT(new_table_name) 
					FROM ##FKList WHERE new_table_name = ''' + @NewTableName + ''') > 1
				BEGIN
                    -- Table name is not unique
					SET @Result = 1;
				END
				ELSE
				BEGIN
                    -- Table name is unique
					SET @Result = 0;
				END;'

	SET @IfExists = NULL
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT	

	-- If the newly generated table name is not unique (duplication exists), the name will be modified to remove table name repetition
	IF(@IfExists = 1) OR EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @NewTableName)
	OR (@NewTableName LIKE 'Field_[0-9]%')
	BEGIN
		/*
			If the new generated table name is very similar to the foreign key table name, prefix the new table name with the
			first 3 letters of the foreign key table name
		*/
		IF (SUBSTRING(@FKTableName, 1, 3) = SUBSTRING(@NewTableName, 1, 3))
		BEGIN

			SET @NewTableName = SUBSTRING(@FKTableName, 1, 1) + @NewTableName;

		END
		-- Rename new domain tables for Inlinespection child tables as follows
		ELSE IF (@FKTableName LIKE 'InlineInspection%')
		BEGIN

			SET @NewTableName = 'Inline' + @NewTableName;

		END
		/* 
			If the combination of the new domain table name and foreign table name is longer 
			than 30 characters, shorten the foreign key table name and add it in front of the new table name
		*/
		ELSE IF (LEN(@FKTableName + @NewTableName) > 30)
		BEGIN
			
			SET @NewTableName = SUBSTRING(@FKTableName, 1, 30 - LEN(@NewTableName)) + @NewTableName

		END;
		/*
			New table names derived from the 'Field_%' columns of ListDomain child tables should have
			the foreign table name prefixed in front of it so the tables are easy to distinguish from one another
		*/
		ELSE IF (PATINDEX('IRASCustomData%' , @FKTableName) <> 0 AND PATINDEX('Field%', @NewTableName) <> 0)
		BEGIN

			SET @NewTableName = @FKTableName + '_' + @NewTableName;
		
		END
		ELSE
		BEGIN
		
			SET @NewTableName = @FKTableName + @NewTableName;	
		
		END;

	END

	UPDATE ##FKList SET new_table_name = @NewTableName
	WHERE fk_constraint = @FKConstraintName

---------------------------------------------- CREATE THE NEW TABLES -----------------------------------------

	IF OBJECT_ID(@NewTableName, 'U') IS NULL
	BEGIN
		SET @SQL = 'CREATE TABLE [dbo].[' + @NewTableName + '](
		[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
		[Code] [varchar](60) NOT NULL,
		[Descr] [varchar](255) NOT NULL,
		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
		CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY NONCLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
		CONSTRAINT [UQ_' + @NewTableName + '] UNIQUE NONCLUSTERED 
		(
			[Code] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]';

		EXECUTE (@SQL);
	END;

	-- Create new List Domain tables for Domain catalog entries that are not associated with a user table
	DECLARE @TableName NVARCHAR(100)

	DECLARE TableList CURSOR FOR 
	SELECT REPLACE(DomainDescr, ' ', '') + 'LD' FROM DomainCatalog
	WHERE Id NOT IN (SELECT DomainCatalogId FROM domaincatalogcolxref)
	AND REPLACE(DomainDescr, ' ', '') + 'LD' NOT IN (SELECT name FROM sys.tables)

	OPEN TableList
	FETCH NEXT FROM TableList INTO @TableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'CREATE TABLE [dbo].[' + @TableName + '](
		[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
		[Code] [varchar](60) NOT NULL,
		[Descr] [varchar](255) NOT NULL,
		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
		CONSTRAINT [PK_' + @TableName + '] PRIMARY KEY NONCLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
		CONSTRAINT [UQ_' + @TableName + '] UNIQUE NONCLUSTERED 
		(
			[Code] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]';

		EXECUTE (@SQL);
		FETCH NEXT FROM TableList INTO @TableName
	END

	CLOSE TableList
	DEALLOCATE TableList

------------------------------------- INSERT DATA INTO NEW DOMAIN TABLE ------------------------------------------
	
	-- Check if there are any domain codes missing from the new domain table or if the table is empty
	SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @FKTableName +' fk_table
							JOIN ListDomain Ld
							ON Ld.Id = fk_table.'+ @FKColumnName +'
							LEFT JOIN ' + @NewTableName + ' NewDomain
							ON TRIM(NewDomain.Code) = TRIM(Ld.Code)
							WHERE TRIM(Ld.Code) NOT IN (SELECT Code FROM '+ @NewTableName +')) OR
							(SELECT COUNT(1) FROM ' + @NewTableName + ') = 0
				BEGIN
					-- Some domain codes are missing in the new domain table
					SET @Result = 1;
				END 
				ELSE
				BEGIN
					-- All domain codes are in the new domain table
					SET @Result = 0;
				END';
	
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT;

	-- If there are any domain codes missing in the new domain table or if it is empty, insert domain codes into new domain table
	IF (@IfExists = 1)
	BEGIN
	
		-- Create and populate the table for storing Domain info
		SET @SQL = 'IF OBJECT_ID(''tempdb..##ListDomainInfo'') IS NOT NULL
					BEGIN
						DROP TABLE ##ListDomainInfo;

						SELECT	DISTINCT fk_table.' + @FKColumnName + ' As OldDomainId, 
								TRIM(Ld.Code) AS Code, 
								TRIM(Ld.Descr) As Descr
						INTO ##ListDomainInfo
						FROM ' + @FKTableName + ' fk_table
						JOIN ListDomain Ld
							ON Ld.Id = fk_table.' + @FKColumnName + '
					END';

		EXECUTE (@SQL);
		
		-- If there are duplicate code values in the ##ListDomainInfo table populate new domain table one row at a time
		IF (SELECT COUNT(DISTINCT Code) FROM ##ListDomainInfo) <> (SELECT COUNT(Code) FROM ##ListDomainInfo)	
		BEGIN
			DECLARE ListDomain_Cursor CURSOR FOR
			SELECT Code, Descr FROM ##ListDomainInfo;

			OPEN ListDomain_Cursor
			FETCH NEXT FROM ListDomain_Cursor INTO @Code, @Descr

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Check if the Code already exists in the new domain table
				SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @NewTableName + ' 
										WHERE Code = ''' + REPLACE(@Code, '''', '''''') + ''')
							BEGIN
								-- Code already exists in table
								SET @Result = 1;
							END
							ELSE
							BEGIN
								-- Code does not exist
								SET @Result = 0;
							END';

				EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT;
				
				-- If the code is not already in the new domain table insert in the table
				IF (@IfExists = 0)
				BEGIN
					SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
								VALUES (''' + REPLACE(@Code, '''', '''''') + ''', ''' + REPLACE(@Descr, '''', '''''') + ''')';

					EXECUTE (@SQL);
				END;

				FETCH NEXT FROM ListDomain_Cursor INTO @Code, @Descr;
			END

			CLOSE ListDomain_Cursor;
			DEALLOCATE ListDomain_Cursor;

		END
		-- Populate domain table with a single insert statement if the code values are unique in the ##ListDomainInfo table
		ELSE
		BEGIN
			BEGIN TRY
				SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
							SELECT DISTINCT Code, Descr 
							FROM ##ListDomainInfo LDI
							WHERE Code NOT IN (SELECT Code FROM ' + @NewTableName + ')';

				EXECUTE (@SQL);

			END TRY
			BEGIN CATCH
				PRINT 'Msg: ' + ERROR_MESSAGE() + CHAR(10) ;
				SELECT @SQL AS Failing_SQL;
			
			END CATCH;	
		END
		
	END;
	
--------------------------------------- REMOVE FOREIGN KEY REFERENCING THE LISTDOMAIN TABLE -------------------------------
	
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

----------------------------------------- UPDATE DOMAIN ID IN CHILD TABLE --------------------------------------------------
 
	-- Check to see if there are any key values in the child table that do not have a parent key value in the new domain table
	SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @FKTableName + ' fk_table
							WHERE fk_table.' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + '))
				BEGIN 
					 --There are missin key values
					SET @Result = 1;
				END
				ELSE
				BEGIN
					 --No missing key values
					SET @Result = 0;
				END'

	SET @IfExists = NULL
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT

	/*
		If there are any domain child key values that do not have a corresponding parent key value in the 
		new domain table, update the child table values to match the new domain table
	*/
	IF (@IfExists = 1)
	BEGIN	
			
		SET @SQL = 'IF OBJECT_ID(''tempdb..##ListDomainInfo'', ''U'') IS NOT NULL
					BEGIN
						DROP TABLE ##ListDomainInfo;

						SELECT fk_table.' + @FKColumnName + ' As OldDomainId, 
							NewDomain.Id AS NewDomainId, 
							TRIM(Ld.Code) AS Code, 
							TRIM(Ld.Descr) AS Descr
						INTO ##ListDomainInfo
						FROM ' + @FKTableName + ' fk_table
						JOIN ListDomain Ld
							ON Ld.Id = fk_table.' + @FKColumnName + '
						JOIN ' + @NewTableName + ' NewDomain
							ON TRIM(NewDomain.Code) = TRIM(Ld.Code)
					END';

		EXECUTE (@SQL);

		-- Check if the list domain code entries are duplicated int the List domain child table
		SET @SQL = 'IF EXISTS (SELECT NewDomainId, Count(*) AS count
								FROM ##ListDomainInfo
								GROUP BY NewDomainId
								HAVING COUNT(*) > 1) 
					AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
								WHERE table_name = ''' + @FKTableName + '''
								AND column_name = ''' + @FKColumnName + '''
								AND constraint_name LIKE ''PK%'')
					BEGIN
						SET @Result = 1
					END
					ELSE
					BEGIN
						SET @Result = 0
					END'

		SET @IfExists = NULL
		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT
				
		/*
			Delete duplicate code entires from the Child Domain table. Keep the entry with the most descriptive value 
			for the 'Descr' column
		*/
		IF (@IfExists = 1)
		BEGIN
		
			SET @SQL = '
			DECLARE @NewDomainId INT
			DECLARE @KeepId INT

			DECLARE DuplicateList CURSOR FOR
			SELECT NewDomainId 
			FROM (SELECT NewDomainId, Count(*) AS count
					FROM ##ListDomainInfo
					GROUP BY NewDomainId
					HAVING COUNT(*) > 1) tmp

			OPEN DuplicateList
			FETCH NEXT FROM DuplicateList INTO @NewDomainId

			WHILE @@FETCH_STATUS = 0
			BEGIN

				SELECT TOP 1 @KeepId =  OldDomainId
				FROM ##ListDomainInfo
				WHERE NewDomainId = @NewDomainId
				AND LEN(Descr) = (SELECT MAX(LEN(Descr))
									FROM ##ListDomainInfo
									WHERE NewDomainId = @NewDomainId
									)
				DELETE FROM ' + @FKTableName + '
				WHERE ' + @FKColumnName + ' IN (SELECT OldDomainId FROM ##ListDomainInfo
						WHERE NewDomainId = @NewDomainId
						AND OldDomainId != @KeepId
						)

				FETCH NEXT FROM DuplicateList INTO @NewDomainId
			END

			CLOSE DuplicateList
			DEALLOCATE DuplicateList'

			EXECUTE (@SQL)

		END
		
		-- Update the child domain table Domain Id column with the NewDomainId values 
		BEGIN TRY
			SET @SQL = 'UPDATE ' + @FKTableName + '
						SET ' + @FKColumnName + ' = NewDomainId
						FROM ##ListDomainInfo LDI
						JOIN ' + @FKTableName + ' fk_table
							ON fk_table.' + @FKColumnName + ' = LDI.OldDomainId';

			EXECUTE (@SQL);
		END TRY
		BEGIN CATCH
			PRINT 'Msg: ' + ERROR_MESSAGE() + CHAR(10);
			SELECT @SQL AS Failing_SQL;
		END CATCH

	END;

--------------------------------------------- CREATE FOREIGN KEYS ON NEW DOMAIN TABLES -------------------------------------------------------------
	
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

	FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName, @FKColumnName, @NewTableName;
END;

CLOSE FKList_Cursor;
DEALLOCATE FKList_Cursor;

------------------------------------------ DELETE OBSELETE TABLES ------------------------------------------------

/*
	Drop the ListDomain, DomainCatalog, and DomainCatalogColXRef tables if all foreign key constraints have been
	successfully transfered to the new domain tables
*/
--IF NOT EXISTS (SELECT 1 FROM ##FKList
--				WHERE fk_constraint NOT IN (SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint
--											FROM sys.foreign_key_columns
--											WHERE OBJECT_NAME(constraint_object_id) IN (select fk_constraint FROM ##FKList)
--											AND OBJECT_NAME(referenced_object_id) <> 'ListDomain'
--											)
--				)
--BEGIN
--	IF OBJECT_ID('ListDomain', 'U') IS NOT NULL
--	BEGIN
--		DROP TABLE ListDomain;
--	END;

--	IF OBJECT_ID('DomainCatalogColXRef', 'U') IS NOT NULL
--	BEGIN
--		DROP TABLE DomainCatalogColXRef;
--	END;

--	IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
--				WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog')
--	BEGIN
--		DECLARE FKList_Cursor CURSOR FOR
--		SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
--			   OBJECT_NAME(parent_object_id) AS fk_table
--		FROM sys.foreign_key_columns
--		WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog';

--		OPEN FKList_Cursor;
--		FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;
--			EXECUTE (@SQL);

--			FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;
--		END;

--		CLOSE FKList_Cursor;
--		DEALLOCATE FKList_Cursor;
--	END;

--	IF OBJECT_ID('DomainCatalog', 'U') IS NOT NULL
--	BEGIN
--		DROP TABLE DomainCatalog;
--	END;

--END;