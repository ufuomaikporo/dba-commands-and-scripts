DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @RefConstraintName NVARCHAR(100);
DECLARE @RefTableName NVARCHAR(100);
DECLARE @RefColumnName NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SetTableName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @Counter INT;
DECLARE @Limit INT;
DECLARE @CharToRemove INT;
DECLARE @CharToKeep INT;

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

DECLARE @FKList TABLE (Id INT IDENTITY(1,1),
					   fk_constraint NVARCHAR(100),
					   fk_table NVARCHAR(100),
					   fk_column NVARCHAR(100),
					   new_table_name NVARCHAR(100),
					   ref_constraint NVARCHAR(100),
					   ref_table NVARCHAR(100),
					   ref_column NVARCHAR(100)
					  );

IF OBJECT_ID('tempdb..##NewTableList') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE tempdb..##NewTableList');
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

IF OBJECT_ID('tempdb..##test') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE tempdb..##test');
END;


-- The query modifies the foreign key column name from the ListDomain child table to be used as a new table name
SET @SQL = 'DECLARE @Result TABLE ( fk_constraint NVARCHAR(100),
                                    fk_table NVARCHAR(100),
									fk_column NVARCHAR(100),
									new_table_name NVARCHAR(100),
									ref_constraint NVARCHAR(100),
									ref_table NVARCHAR(100),
									ref_column NVARCHAR(100));
WITH ColumnInfo AS (
SELECT fk_info.constraint_name AS fk_constraint,
	   fk_info.table_name AS fk_table, 
	   fk_info.column_name fk_column,
	   rc.unique_constraint_name
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
ON rc.constraint_name = fk_info.constraint_name
)

INSERT INTO @Result
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
ORDER BY new_table_name

SELECT * FROM @Result';

-- Insert query into table that generates a list of all foreign keys referencing the ListDomain table (plus related info)
INSERT INTO @FKList
EXECUTE (@SQL);

SET @Counter = 1
SELECT @Limit = COUNT(*) FROM @FKList

WHILE @Counter <= @Limit
BEGIN
----------------------------------- GENERATE THE NEW TABLE NAME --------------------------------------

	SELECT @NewTableName = new_table_name FROM @FKList
	WHERE Id = @Counter;

	SELECT @FKTableName = fk_table FROM @FKList
	WHERE Id = @Counter;

	SELECT @FKColumnName = fk_column FROM @FKList
	WHERE Id = @Counter;

	SELECT @FKConstraintName = fk_constraint FROM @FKList
	WHERE Id = @Counter;

	-- If the new table name is not unique, the name will be modified to remove table name repetition
	IF(SELECT COUNT(new_table_name) 
		FROM @FKList WHERE new_table_name = @NewTableName) > 1
	BEGIN
		/* 
			If the combination of the new table and the table name of the orignal ListDomain child table is longer 
			than 30 characters, remove the word 'InlineInspection' from the name
		*/
		IF (LEN(@FKTableName + @NewTableName) > 30)
		BEGIN
			SET @FKTableName = REPLACE(@FKTableName, 'InlineInspection', '');
			
			IF(LEN(@FKTableName + @NewTableName) <= 30)
			BEGIN
				SET @NewTableName = @FKTableName + @NewTableName

				INSERT INTO ##NewTableList
				SELECT fk_constraint, fk_table, fk_column, @NewTableName
				FROM @FKList
				WHERE Id = @Counter;
			END
			-- if it's still longer than 30 characters truncate the part of the name derived from the ListDomain child table
			ELSE 
			BEGIN
				SET @CharToRemove = LEN(@FKTableName + @NewTableName) - 30
				SET @CharToKeep = LEN(@FKTableName) - @CharToRemove

				SET @FKTableName = SUBSTRING(@FKTableName, 1, @CharToKeep)
				SET @NewTableName = @FKTableName + @NewTableName

				INSERT INTO ##NewTableList
				SELECT fk_constraint, fk_table, fk_column, @NewTableName
				FROM @FKList
				WHERE Id = @Counter;
			END;
		END
		/*
			If the combination of the new table name the table name of the original ListDomain child table is less 
			than 30 characters, keep the name
		*/
		ELSE
		BEGIN
			SET @NewTableName = @FKTableName + @NewTableName

			INSERT INTO ##NewTableList
			SELECT fk_constraint, fk_table, fk_column, @NewTableName
			FROM @FKList
			WHERE Id = @Counter;
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

		INSERT INTO ##NewTableList
		SELECT fk_constraint, fk_table, fk_column, @NewTableName
		FROM @FKList
		WHERE Id = @Counter;
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

	SET @Counter += 1
END


---------------------------------------------- Checks -----------------------------------------------

--SELECT *, LEN(newTableName) AS NewTableName_Length FROM ##NewTableList
--ORDER BY  FKColumnName, NewTableName

--SELECT NewTableName, COUNT(NewTableName)
--FROM ##NewTableList
--GROUP BY NewTableName
--HAVING COUNT(NewTableName) > 1

--SELECT COUNT(*) FROM @FKList
--SELECT COUNT(*) FROM ##NewTableList
--SELECT MAX(LEN(NewTableName)) FROM ##NewTableList

SELECT * from INFORMATION_SCHEMA.tables 
WHERE table_name IN (SELECT NewTableName FROM ##NewTableList)

--SELECT * FROM ##NewTableList
--WHERE NewTableName IN (SELECT table_name from INFORMATION_SCHEMA.tables 
--WHERE table_name IN (SELECT NewTableName FROM ##NewTableList))

-----------------------------------------------------------------------------------------------------

--OPEN ListDomain_Cursor 
--FETCH NEXT FROM ListDomain_Cursor INTO @FKConstraintName, @FKTableName, @FKColumnName, @NewTableName, @RefConstraintName, @RefTableName, @RefColumnName

--WHILE @@FETCH_STATUS = 0
--BEGIN
--	DECLARE @ModifyTableName NVARCHAR(100);

--	IF(SELECT COUNT(*) FROM @FKList WHERE new_table_name = @NewTableName) > 1)
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

