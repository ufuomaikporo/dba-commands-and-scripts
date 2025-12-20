DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @RefConstraintName NVARCHAR(100);
DECLARE @RefTableName NVARCHAR(100);
DECLARE @RefColumnName NVARCHAR(100);
DECLARE @ModifiedFKTableName NVARCHAR(100);
DECLARE @TempString NVARCHAR(100);
DECLARE @EndIndex INT;
DECLARE @StartIndex INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SetTableName NVARCHAR(100);
DECLARE @Counter INT;
DECLARE @Limit INT;
DECLARE @CharToRemove INT;
DECLARE @CharToKeep INT;
DECLARE @IfExists INT;
DECLARE @IsDuplicate INT;
DECLARE @Code NVARCHAR(100);
DECLARE @Descr NVARCHAR(100);
DECLARE @OldDomainId INT;
DECLARE @NewDomainId INT;
DECLARE @TableName NVARCHAR(100);
declare @subcount int = 0;

SET IMPLICIT_TRANSACTIONS OFF;
------------------------------- GET LIST OF TABLES THAT WILL BE CREATED -----------------------------

IF OBJECT_ID('tempdb..##MissingDomainIds') IS NULL
BEGIN
	CREATE TABLE ##MissingDomainIds (OldDomainId INT, 
							 NewDomainId INT, 
							 Code NVARCHAR(60),  
							 Descr NVARCHAR(255));
END;

IF OBJECT_ID('tempdb..##ListDomainCodes') IS NULL
BEGIN
	CREATE TABLE ##ListDomainCodes (OldDomainId INT, Code NVARCHAR(60), Descr NVARCHAR(255));
END

IF OBJECT_ID ('tempdb..##TempDomainTable') IS NULL
BEGIN
	CREATE TABLE [dbo].[##TempDomainTable](
		[Id] [numeric](10, 0) CONSTRAINT [PK_##TempDomainTable] PRIMARY KEY,
		[Code] [varchar](60) NOT NULL,
		[Descr] [varchar](255) NOT NULL,
		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
		 )
END

IF OBJECT_ID('tempdb..##FKList') IS NULL
BEGIN
	CREATE TABLE ##FKList  (Id INT IDENTITY(1,1),
							fk_constraint NVARCHAR(100),
							fk_table NVARCHAR(100),
							fk_column NVARCHAR(100),
							new_table_name NVARCHAR(100),
							ref_constraint NVARCHAR(100),
							ref_table NVARCHAR(100),
							ref_column NVARCHAR(100),
							CONSTRAINT [UQ_TmpFKList] UNIQUE (fk_constraint)
							);
END;

-- The query modifies the foreign key column name from the ListDomain child table to be used as a new table name
SET @SQL = '
WITH ColumnInfo AS (
SELECT fk_info.constraint_name AS fk_constraint,
	   fk_info.table_name AS fk_table, 
	   fk_info.column_name fk_column,
	   rc.unique_constraint_name
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
ON rc.constraint_name = fk_info.constraint_name
)

INSERT INTO ##FKList
SELECT ci.fk_constraint,
	   ci.fk_table,
	   ci.fk_column,
	   CASE
	   WHEN PATINDEX(''%_DomainId%'', ci.fk_column ) > 0 
			THEN REPLACE(REPLACE(ci.fk_column, ''_DomainId'', ''''), ''DomainId'', '''')
	   WHEN PATINDEX(''%LD'', ci.fk_column) > 0
			THEN REPLACE(ci.fk_column, ''LD'', '''')
	   ELSE ci.fk_column
	   END AS new_table_name,
	   pk_info.constraint_name AS ref_constraint,
	   pk_info.table_name AS ref_table,
	   pk_info.column_name AS ref_column
FROM ColumnInfo ci
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
ON ci.unique_constraint_name = pk_info.constraint_name
WHERE pk_info.table_name = ''ListDomain'' 
AND ci.fk_constraint NOT IN (SELECT fk_constraint FROM ##FKList)';

--Insert into a temporary table the list of foreign keys referecing the LIstDomain table and associated info
EXECUTE (@SQL);

SET @Counter = 0

SET @SQL = 'SELECT @Result = COUNT(*) FROM ##FKList';

EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Limit OUT

WHILE @Counter <= @Limit
BEGIN

	SET @Counter += 1
----------------------------------- GENERATE THE NEW TABLE NAME --------------------------------------
select @Counter = id from ##fklist where fk_constraint = 'FK_POECoatPropCoatLineDomainId'


	SET @SQL = 'SELECT @Result = new_table_name FROM ##FKList
	WHERE Id = ' + CAST(@Counter AS NVARCHAR);

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @NewTableName OUT;

	SET @SQL = 'SELECT @Result = fk_table FROM ##FKList
	WHERE Id = ' + CAST(@Counter AS NVARCHAR);

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @FKTableName OUT;

	SET @SQL = 'SELECT @Result = fk_column FROM ##FKList
	WHERE Id = ' + CAST(@Counter AS NVARCHAR);

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @FKColumnName OUT;

	SET @SQL = 'SELECT @Result = fk_constraint FROM ##FKList
	WHERE Id = ' + CAST(@Counter AS NVARCHAR);

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @FKConstraintName OUT;

	SET @SQL = 'IF (SELECT COUNT(new_table_name) 
					FROM ##FKList WHERE new_table_name = ''' + @NewTableName + ''') > 1
				BEGIN
					SET @Result = 1;
				END
				ELSE
				BEGIN
					SET @Result = 0;
				END;'

	SET @IfExists = NULL
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT	
	
	-- If the newly generated table name is not unique (duplication exists), the name will be modified to remove table name repetition
	IF(@IfExists = 1 OR OBJECT_ID(@NewTableName, 'U') IS NOT NULL AND COL_LENGTH(@NewTableName, 'Code') IS NULL AND COL_LENGTH(@NewTableName, 'Descr') IS NULL)
	BEGIN
		/*
			If the new generated table name is the same as the foreign key table name, prefix the new table name with the
			initials of the foreign key table name
		*/
		IF (@FKTableName = @NewTableName OR PATINDEX ('' + @FKTableName + '%', @NewTableName) > 0)
		BEGIN
			SET @ModifiedFKTableName = ''
			SET @StartIndex = 1


			WHILE @StartIndex < LEN(@FKTableName)
			BEGIN
				SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
				SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 1)

				SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex

				IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
				BEGIN
					SET @EndIndex = LEN(@FKTableName);
				END;

				SET @StartIndex = @EndIndex
				--set @Counter += 1
			END

			SET @NewTableName = @ModifiedFKTableName + @NewTableName

			SET @SQL = 'UPDATE ##FKList 
			SET new_table_name = ''' + @NewTableName + '''
			WHERE id = ' + CAST(@Counter AS NVARCHAR);

			EXECUTE (@SQL);
		END
		/* 
			If the combination of the new table and the table name of the orignal ListDomain child table is longer 
			than 30 characters, remove the word 'InlineInspection' from the name
		*/
		ELSE IF (LEN(@FKTableName + @NewTableName) > 30)
		BEGIN
			SET @StartIndex = 1;
			SET @ModifiedFKTableName = ''

			WHILE @StartIndex < LEN(@FKTableName)
			BEGIN
				SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
				SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex;

				IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
				BEGIN
					SET @EndIndex = LEN(@FKTableName) + 1;
				END;

				IF ((@EndIndex - @StartIndex) <= 5)
				BEGIN
					SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, @EndIndex - @StartIndex);
				END
				ELSE
				BEGIN
					SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 3);
				END;

				SET @StartIndex = @EndIndex; 

			END;
			
			IF(LEN(@ModifiedFKTableName + @NewTableName) <= 30)
			BEGIN
				SET @NewTableName = @ModifiedFKTableName + @NewTableName

				SET @SQL = 'UPDATE ##FKList 
				SET new_table_name = ''' + @NewTableName + '''
				WHERE id = ' + CAST(@Counter AS NVARCHAR);

				EXECUTE (@SQL);
			END
			-- if it's still longer than 30 characters truncate the part of the name derived from the ListDomain child table
			ELSE 
			BEGIN
				SET @CharToRemove = LEN(@ModifiedFKTableName + @NewTableName) - 30
				SET @CharToKeep = LEN(@ModifiedFKTableName) - @CharToRemove

				SET @ModifiedFKTableName = SUBSTRING(@ModifiedFKTableName, 1, @CharToKeep)
				SET @NewTableName = @ModifiedFKTableName + @NewTableName

				SET @SQL = 'UPDATE ##FKList 
				SET new_table_name = ''' + @NewTableName + '''
				WHERE id = ' + CAST(@Counter AS NVARCHAR);

				EXECUTE (@SQL);
			END;
		END
		/*
			If the combination of the new table name the table name of the original ListDomain child table is less 
			than 30 characters, keep the name
		*/
		ELSE
		BEGIN
			SET @NewTableName = @FKTableName + @NewTableName

			SET @SQL = 'UPDATE ##FKList 
				SET new_table_name = ''' + @NewTableName + '''
				WHERE id = ' + CAST(@Counter AS NVARCHAR);

			EXECUTE (@SQL);
		END;	
	END
	/*
		if the new table name is unique, then keep it
	*/
	ELSE
	BEGIN
		/*
			New table names derived from the 'Field_%' columns of ListDomain child tables should have
			the child table name prefixed in front of it for consistency
		*/
		IF(PATINDEX('IRASCustomData%' , @FKTableName) <> 0 AND PATINDEX('Field_%', @NewTableName) <> 0)
		BEGIN
			SET @NewTableName = @FKTableName + @NewTableName;
		END;

		SET @SQL = 'UPDATE ##FKList 
			SET new_table_name = ''' + @NewTableName + '''
			WHERE id = ' + CAST(@Counter AS NVARCHAR);

		EXECUTE (@SQL);
	END;

------------------------------------------ CREATE THE NEW TABLES -----------------------------------------

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

----------------------------------- INSERT DATA INTO NEW DOMAIN TABLE ------------------------------------------

	---- Check if the new domain table is empty
	--SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @NewTableName + ')
	--			BEGIN
	--				-- Table is not empty
	--				SET @Result = 0;
	--			END
	--			ELSE
	--			BEGIN
	--				-- Table is empty
	--				SET @Result = 1;
	--			END'
	
	--SET @IfExists = NULL
	--EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT;

	---- Truncate the new domain table if it's not empty
	--IF (@IfExists = 0 )
	--BEGIN
	--	SET @SQL = 'IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
	--							WHERE OBJECT_NAME(constraint_object_id) = ''' + @FKConstraintName +'''
	--							AND OBJECT_NAME(referenced_object_id) = ''' + @NewTableName +''')
	--				BEGIN
	--					ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName + ';
	--				END
					
	--				TRUNCATE TABLE ' + @NewTableName ;
	--	EXECUTE (@SQL);
	--END

	--SET @SQL = 'TRUNCATE TABLE ##ListDomainCodes;

	--			INSERT INTO ##ListDomainCodes
	--			SELECT DISTINCT(TRIM(code)) As Code, TRIM(Descr)
	--			FROM ListDomain
	--			WHERE DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef
	--									 WHERE tablename = ''' + @FKTableName + '''
	--									 AND columnname = ''' + @FKColumnName + ''')
	--			OR 
	--			Id IN (SELECT DISTINCT(' + @FKColumnName + ') 
	--				   FROM ' + @FKTableName +')';

	SET @SQL = 'TRUNCATE TABLE ##ListDomainCodes;

				INSERT INTO ##ListDomainCodes
				SELECT DISTINCT(' + @FKColumnName + '), TRIM(Ld.Code), TRIM(Ld.Descr)
				FROM ' + @FKTableName +' fk_table
				JOIN ListDomain Ld
				ON Ld.Id = fk_table.'+ @FKColumnName +'
					   WHERE '+ @FKColumnName +' NOT IN (SELECT Id FROM '+ @NewTableName +') '

	EXECUTE (@SQL);

	---- Check if the Code 'values' within the temp table ##ListDomainCodes are unique 
	--SET @SQL = 'IF (SELECT COUNT(DISTINCT(Code)) FROM ##ListDomainCodes) = (SELECT COUNT(1) FROM ##ListDomainCodes)
	--			BEGIN
	--				-- Code values are unique in ##ListDomainCodes table
	--				SET @Result = 1;
	--			END
	--			ELSE 
	--			BEGIN
	--				-- Code values are not unique in ##ListDomainCodes
	--				SET @Result = 0;
	--			END'
	
	--SET @IfExists = NULL;
	--EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT;
	
	SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
				SELECT Code, Descr
				FROM ##ListDomainCodes
				WHERE Code NOT IN (SELECT Code FROM ' + @NewTableName + ')';

	EXECUTE (@SQL);

	---- If the 'Code' values in temp table ##ListDomainCodes are unique, use it to populate the new domain table
	--IF (@IfExists = 1)
	--BEGIN
	--	SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
	--				SELECT Code, Descr
	--				FROM ##ListDomainCodes
	--				WHERE Code NOT IN (SELECT Code FROM ' + @NewTableName + ')';

	--	EXECUTE (@SQL);
	--END
	---- If 'Code' values are not unique, insert values one at a time and perform check to ensure uniqueness
	--ELSE
	--BEGIN
	--	DECLARE LDCursor CURSOR FOR
	--	SELECT Code, Descr FROM ##ListDomainCodes

	--	OPEN LDCursor;
	--	FETCH NEXT FROM LDCursor INTO @Code, @Descr;

	--	WHILE @@FETCH_STATUS = 0
	--	BEGIN
	--		-- Check if the 'Code' value being inserted already exists in the new domain table
	--		SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @NewTableName + '
	--					WHERE Code = ''' + REPLACE(TRIM(@Code), '''', '''''') + ''')
	--					BEGIN
	--						-- Code is already in New domain table 
	--						SET @Result = 1;
	--					END
	--					ELSE
	--					BEGIN
	--						-- Code is not in new domain table
	--						SET @Result = 0;
	--					END';

	--		SET @IfExists = NULL
	--		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT;		
		
	--		-- Insert into new domain table if the 'Code' value is not already there
	--		IF (@IfExists = 0)
	--		BEGIN

	--			--SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
	--			--			SELECT TOP 1 Code, Descr
	--			--			FROM ListDomain
	--			--			WHERE Code = ''' + REPLACE(@Code, '''', '''''') + '''' ;
	--			SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
	--						VALUES (''' + REPLACE(@Code, '''', '''''') + ''', ''' + REPLACE(@Descr, '''', '''''') +''')
	--						' ;
	--			select @sql
	--			--EXECUTE (@SQL);			
	--		END;

	--		FETCH NEXT FROM LDCursor INTO @Code, @Descr;
	--	END; -- End of While-loop

	--	CLOSE LDCursor;
	--	DEALLOCATE LDCursor;
	--END -- end if-else statement

-------------------------------------- REMOVE FOREIGN KEY REFERENCING THE LISTDOMAIN TABLE -------------------------------

	-- Drop the foreign key on the domain child table if it references the ListDomain table
	IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(constraint_object_id) = @FKConstraintName
				AND OBJECT_NAME(referenced_object_id) = 'ListDomain') 
	BEGIN
		SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;

		begin try
		EXECUTE (@SQL);
		end try
		begin catch
			select @sql
			print error_message()
			--break
		end catch
	END;

------------------------------------------- UPDATE DOMAIN ID IN CHILD TABLE --------------------------------------------------
 
--	-- Check to see if there are any domain child key values that do not have a parent key value in the new domain table
--	SET @SQL = 'IF EXISTS (SELECT 1 FROM ' + @FKTableName + ' fk_table
--							WHERE fk_table.' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + '))
--				BEGIN 
--					 --There are missin key values
--					SET @Result = 1;
--				END
--				ELSE
--				BEGIN
--					 --No missing key values
--					SET @Result = 0;
--				END'

--	SET @IfExists = NULL
--	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT

--	-- If there are any domain child key values that do not have a corresponding parent key value update the child table values
--	IF (@IfExists = 1)
--	BEGIN
--		-- Get the old and new domain Ids for all domain Ids in child table that need to be changed
--		SET @SQL = 'TRUNCATE TABLE ##MissingDomainIds
					
--					INSERT INTO ##MissingDomainIds
--					SELECT SubQ.' + @FKColumnName + ' As OldDomainId, 
--					NewDomain.Id As NewDomainId,
--					TRIM(Ld.Code), 
--					Ld.Descr
--					FROM
--					(SELECT DISTINCT(' + @FKColumnName + ') AS ' + @FKColumnName + '
--						FROM ' + @FKTableName + ' fk_table
--						WHERE ' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + ')
--					) SubQ
--					JOIN ListDomain Ld
--						ON Ld.Id = SubQ.' + @FKColumnName +'
--					JOIN ' + @NewTableName + ' NewDomain
--						ON TRIM(NewDomain.Code) = TRIM(Ld.Code)'

--		SET @SQL = 'TRUNCATE TABLE ##MissingDomainIds
					
--					INSERT INTO ##MissingDomainIds
--					SELECT DISTINCT(' + @FKColumnName + ') AS OldDomainId, 
--					NewDomain.Id AS NewDomainId,
--					TRIM(Ld.Code), 
--					Ld.Descr
--					FROM ' + @FKTableName +' fk_table
--					JOIN ListDomain Ld
--					ON Ld.Id = fk_table.'+ @FKColumnName +'
--					LEFT JOIN ' + @NewTableName + ' NewDomain
--					ON TRIM(NewDomain.Code) = TRIM(Ld.Code)
--					WHERE '+ @FKColumnName +' NOT IN (SELECT Id FROM '+ @NewTableName +')'
			
--		-- Insert Old and New domain Ids into a table
--		EXECUTE (@SQL);

--	--	--SET @TableName = '@domain'

--	--	SET @SQL = 'UPDATE ' + @FKTableName + '
--	--				SET ' + @FKColumnName + ' = NewDomainId
--	--				FROM ' + @FKTableName + ' fk_table
--	--				JOIN ##MissingDomainIds D
--	--					ON D.OldDomainId = fk_table.' + @FKColumnName +'
--	--					';
--	--select @sql 
--	--break
--		--EXECUTE (@SQL);
--		DECLARE UpdateDomainId_Cursor CURSOR FOR
--		SELECT OldDomainId, NewDomainId 
--		FROM ##MissingDomainIds
--		ORDER BY Code;

--		OPEN UpdateDomainId_Cursor;
--		FETCH NEXT FROM UpdateDomainId_Cursor INTO @OldDomainId, @NewDomainId;

--		DECLARE @NewValue INT = 200;
--		DECLARE @SubCounter INT = 0;

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
			
--			SET @Subcounter += 1

--			BEGIN TRY
				
--				SET @SQL = 'UPDATE ' + @FKTableName + '
--							SET ' + @FKColumnName + ' = ' + CAST(@NewDomainId AS NVARCHAR) + '
--							WHERE ' + @FKColumnName + ' = ' + CAST(@OldDomainId AS NVARCHAR) + '';

--				EXECUTE (@SQL);

--				--DELETE FROM ##MissingDomainIds 
--				--WHERE OldDomainId = @OldDomainId;
				
--			END TRY
--			/*
--				If the UPDATE statment fails because of a uniqueness constraint modify the Id column in the 
--				new domain table to be the same as the old Id column from the ListDomain table and try again 
--			*/
--			BEGIN CATCH			
							
--				SET @NewValue = @NewValue + @SubCounter

--				SET @SQL = 'TRUNCATE TABLE ##TempDomainTable;

--							INSERT INTO ##TempDomainTable
--							SELECT * FROM ' + @NewTableName + ';

--							UPDATE ##TempDomainTable
--							SET Id = ' + CAST(@NewValue AS NVARCHAR) + '
--							WHERE Id = ' + CAST(@NewDomainId AS NVARCHAR) + ';

--							TRUNCATE TABLE ' + @NewTableName + ';

--							SET IDENTITY_INSERT ' + @NewTableName + ' ON;

--							INSERT INTO ' + @NewTableName + ' (Id, Code, Descr)
--							SELECT Id, Code, Descr 
--							FROM ##TempDomainTable;

--							SET IDENTITY_INSERT ' + @NewTableName + ' OFF';
				
--				EXECUTE (@SQL);
				
--				SET @SQL = 'UPDATE ' + @FKTableName + '
--								SET ' + @FKColumnName + ' = ' + CAST(@NewValue AS NVARCHAR) + '
							
--								WHERE ' + @FKColumnName + ' = ' + CAST(@OldDomainId AS NVARCHAR) + '';
				
--				begin try
--				EXECUTE (@SQL);	
--				end try
--				begin catch
--						print 'attempting insrt'
--						print error_message()
--					select @OldDomainId OldDomainId, @NewValue newValue
--				end catch

--				--DELETE FROM ##MissingDomainIds 
--				--WHERE OldDomainId = @OldDomainId;

--			END CATCH;

--			FETCH NEXT FROM UpdateDomainId_Cursor INTO @OldDomainId, @NewDomainId;
--		END; -- end of Cursor While-loop

--		CLOSE UpdateDomainId_Cursor;
--		DEALLOCATE UpdateDomainId_Cursor;
--	END;

--------------	--select @FKTableName, @FKColumnName, @NewTableName

--------------	--break

------------------------------------------------ RECREATE FOREIGN KEYS -------------------------------------------------------------
	
--	-- recreate foreign keys on domain child table to reference new domain table
--	IF OBJECT_ID(@FKConstraintName, 'F') IS NULL
--	BEGIN
--		SET @SQL = 'ALTER TABLE ' + @FKTableName + ' ADD CONSTRAINT ' + @FKConstraintName + ' FOREIGN KEY (' + @FKColumnName + ') 
--					REFERENCES ' + @NewTableName + '(Id)';

--		begin try
--		EXECUTE (@SQL);
--		end try
--		begin catch
--			print error_message()
--			select @sql
--			set @subcount += 1
--		end catch
--	END;

-------------------------------------------------------------------------------------------------------------------------
	break
END;
--select @subcount As failed_fk_recreations
---------------------------------------------- Checks -----------------------------------------------

--SELECT *, LEN(newTableName) AS NewTableName_Length FROM ##NewTableList
--ORDER BY  FKColumnName, NewTableName

--SELECT NewTableName, COUNT(NewTableName)
--FROM ##NewTableList
--GROUP BY NewTableName
--HAVING COUNT(NewTableName) > 1

--SELECT COUNT(*) FROM ##FKList
--SELECT COUNT(*) FROM ##NewTableList
--SELECT MAX(LEN(NewTableName)) FROM ##NewTableList
--select * from ##fklist where fk_table IN ('FloodArea' 
--,'HurricaneArea'
--,'InternalCoating'
--,'JointCoating'
--,'LandSlideArea'
--,'LandUse'
--,'LineLoop'
--,'MaterialRoughness'
--,'ValveType'
--,'Valve')
--ORDER BY fk_table

--select DISTINCT(newtablename) from ##newtablelist where newtablename like '%Risk%' --'RiskCalculatioDistrictDivision'

--select newtablename, count(newtablename) from ##newtablelist
--group by newtablename
--having count(newtablename) > 1
--except
--SELECT table_name from INFORMATION_SCHEMA.tables 
--WHERE table_name IN (SELECT new_table_name FROM ##FKList)

--SELECT * FROM INFORMATION_SCHEMA.columns
--WHERE column_name = 'Code'

--SELECT * FROM ##fklist
--WHERE new_table_name IN (SELECT table_name from INFORMATION_SCHEMA.tables 
--WHERE table_name IN (SELECT new_table_name FROM ##fklist))

-----------------------------------------------------------------------------------------------------

--OPEN ListDomain_Cursor 
--FETCH NEXT FROM ListDomain_Cursor INTO @FKConstraintName, @FKTableName, @FKColumnName, @NewTableName, @RefConstraintName, @RefTableName, @RefColumnName

--WHILE @@FETCH_STATUS = 0
--BEGIN
--	DECLARE @ModifyTableName NVARCHAR(100);

--	IF(SELECT COUNT(*) FROM ##FKList WHERE new_table_name = @NewTableName) > 1)
--	BEGIN
--		IF(LEN(@FKTableName + @NewTableName) <= 30)
--		BEGIN
--			SET @NewTableName = @FKTableName + @NewTableName
--		END
--	END
--	SET @SetTableName = REPLACE(REPLACE(@FKColumnName, 'DomainId', ''), 'LD', '')
--	select @SetTableName
--	FETCH NEXT FROM ListDomain_Cursor INTO @FKConstraintName, @FKTableName, @FKColumnName, @NewTableName, @RefConstraintName, @RefTableName, @RefColumnName
--END

--CLOSE ListDomain_Cursor
--DEALLOCATE ListDomain_Cursor

