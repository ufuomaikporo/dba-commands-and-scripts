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
DECLARE @Check INT;

------------------------------- GET LIST OF TABLES THAT WILL BE CREATED -----------------------------
--DECLARE ListDomain_Cursor CURSOR FOR
--select * from 
--(
--SELECT fk_info.constraint_name AS fk_constraint,
--	   fk_info.table_name AS fk_table, 
--	   fk_info.column_name fk_column,	
--	 --  CASE
--		--WHEN PATINDEX('%_DomainId%', fk_info.column_name ) > 0 
--		--	THEN 
--			REPLACE(REPLACE(fk_info.column_name, '_DomainId', ''), 'DomainId', ''),
--	  -- END AS new_table_name,
--	   pk_info.constraint_name AS ref_constraint,
--	   pk_info.table_name AS ref_table,
--	   pk_info.column_name AS ref_column
--FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
--JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
--ON rc.constraint_name = fk_info.constraint_name
--JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
--ON rc.unique_constraint_name = pk_info.constraint_name
--WHERE pk_info.table_name = 'ListDomain'
--and fk_info.column_name like '%domainid%') sub
--where PATINDEX('%[_D]omainI[Dd][0-9]', sub.fk_column) > 0 --PATINDEX('%[Ll][Dd]', sub.fk_column) > 0

IF OBJECT_ID('tempdb..##FKList') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE ##FKList';

	EXECUTE (@SQL);
END;

IF OBJECT_ID('tempdb..##FKList') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE ##FKList (Id INT IDENTITY(1,1),
										   fk_constraint NVARCHAR(100),
										   fk_table NVARCHAR(100),
										   fk_column NVARCHAR(100),
										   new_table_name NVARCHAR(100),
										   ref_constraint NVARCHAR(100),
										   ref_table NVARCHAR(100),
										   ref_column NVARCHAR(100)
										  )';

	EXECUTE (@SQL);
END;

IF OBJECT_ID('tempdb..##NewTableList') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE ##NewTableList');
END;

IF OBJECT_ID('tempdb..##NewTableList') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE ##NewTableList  (FKConstraintName NVARCHAR(100),
								 FKTableName NVARCHAR(100),
								 FKColumnName NVARCHAR(100),
								 NewTableName NVARCHAR(100)
								)';
	EXECUTE (@SQL);
END

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
ORDER BY new_table_name';

--Insert into a temporary table the list of foreign keys referecing the LIstDomain table and associated info
EXECUTE (@SQL);

SET @Counter = 1

SET @SQL = 'SELECT @Result = COUNT(*) FROM ##FKList';

EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Limit OUT

WHILE @Counter <= @Limit
BEGIN
----------------------------------- GENERATE THE NEW TABLE NAME --------------------------------------

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

	SET @SQL = 'SELECT @Result = COUNT(new_table_name) 
		FROM ##FKList WHERE new_table_name = ''' + @NewTableName + ''''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Check OUT

	-- If the new table name is not unique or if the name is already being used, the name will be modified to remove table name repetition
	IF(@Check > 1 OR OBJECT_ID(@NewTableName) IS NOT NULL)
	BEGIN
		/* 
			If the combination of the new table and the table name of the orignal ListDomain child table is longer 
			than 30 characters, remove the word 'InlineInspection' from the name
		*/
		IF (LEN(@FKTableName + @NewTableName) > 30)
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

				SET @SQL = 'INSERT INTO ##NewTableList
				SELECT fk_constraint, fk_table, fk_column, ''' + @NewTableName + '''
				FROM ##FKList
				WHERE Id = ' + CAST(@Counter AS NVARCHAR);

				EXECUTE (@SQL);
			END
			-- if it's still longer than 30 characters truncate the part of the name derived from the ListDomain child table
			ELSE 
			BEGIN
				SET @CharToRemove = LEN(@ModifiedFKTableName + @NewTableName) - 30
				SET @CharToKeep = LEN(@ModifiedFKTableName) - @CharToRemove

				SET @ModifiedFKTableName = SUBSTRING(@ModifiedFKTableName, 1, @CharToKeep)
				SET @NewTableName = @ModifiedFKTableName + @NewTableName

				SET @SQL = 'INSERT INTO ##NewTableList
				SELECT fk_constraint, fk_table, fk_column, ''' + @NewTableName + '''
				FROM ##FKList
				WHERE Id = ' + CAST(@Counter AS NVARCHAR);

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

			SET @SQL = 'INSERT INTO ##NewTableList
			SELECT fk_constraint, fk_table, fk_column, ''' + @NewTableName + '''
			FROM ##FKList
			WHERE Id = ' + CAST(@Counter AS NVARCHAR);

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

		SET @SQL = 'INSERT INTO ##NewTableList
		SELECT fk_constraint, fk_table, fk_column, ''' + @NewTableName + '''
		FROM ##FKList
		WHERE Id = ' + CAST(@Counter AS NVARCHAR);

		EXECUTE (@SQL);
	END;

------------------------------------------ CREATE THE NEW TABLE -----------------------------------------

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

-------------------------------- REMOVE LISTDOMAIN FOREIGN KEYS FROM TABLES -------------------------------

	SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;

	--EXECUTE (@SQL);

------------------------------------- CREATE NEW FOREIGN KEYS -------------------------------------------------------------
--select * from ##newtablelist
-----------------------------------------------------------------------------------------------------------------------
	
	SET @Counter += 1
END

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

--select DISTINCT(newtablename) from ##newtablelist where newtablename like '%Risk%' --'RiskCalculatioDistrictDivision'

--select newtablename, count(newtablename) from ##newtablelist
--group by newtablename
--having count(newtablename) > 1
--except
--SELECT table_name from INFORMATION_SCHEMA.tables 
--WHERE table_name IN (SELECT NewTableName FROM ##NewTableList)

--SELECT * FROM INFORMATION_SCHEMA.columns
--WHERE column_name = 'Code'

--SELECT * FROM ##NewTableList
--WHERE NewTableName IN (SELECT table_name from INFORMATION_SCHEMA.tables 
--WHERE table_name IN (SELECT NewTableName FROM ##NewTableList))

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

