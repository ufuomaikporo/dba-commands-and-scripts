/*
	NOTE**** BEFORE RUNNING THIS SCRIPT be sure to set the STAGE and CONFIG database variables below
*/
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
DECLARE @StageDB NVARCHAR(100);
DECLARE @ConfigDB NVARCHAR(100);
DECLARE @OldDomainId INT;
DECLARE @Count INT
DECLARE @DomainCatalogId INT;

--**************************************** SET THE FOLLOWING VARIABLES ********************************

SET @StageDB = 'TMC_IRASv6_STAGE'
SET @ConfigDB = 'TMC_IRASv6_CONFIG'

--**********************************************************************************************************

---------------------------- Check that a valid Config and Stage DB is being used --------------------------

-- Check that a valid Stage and config database is specifed
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @StageDB)
BEGIN
	SET @SQL = 'THROW 51000, N''A valid Stage database must be specified'', 1;'
	EXECUTE (@SQL)
END
ELSE
BEGIN
	SET @SQL = 'SELECT @Result = COUNT(*) FROM '+@StageDB+'..VersionInfo 
				WHERE DBVersionComment NOT LIKE ''%Link%''
				AND DBVersionComment NOT LIKE ''%Config%'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

	IF @Count = 0
	BEGIN
		SET @SQL = 'THROW 51000, N''The specified Stage database is not a valid Stage database'', 1;'
		EXECUTE (@SQL)
	END
END

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @ConfigDB)
BEGIN
	SET @SQL = 'THROW 51000, N''A valid Config database must be specified'', 1;'
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

IF OBJECT_ID ('tempdb..##RememberedListDomainValues') IS NOT NULL
BEGIN
	DROP TABLE ##RememberedListDomainValues;
END

IF OBJECT_ID ('tempdb..##RememberedListDomainValues') IS NOT NULL
BEGIN
	-- Create a temporary RememberedListDomainValues table
	SET @SQL = 'SELECT * 
	INTO ##RememberedListDomainValues 
	FROM ' + @StageDB +'..RememberedListDomainValues'

	EXECUTE (@SQL)
END

IF OBJECT_ID ('tempdb..##RememberedListDomainValues') IS NOT NULL
BEGIN
	ALTER TABLE ##RememberedListDomainValues ADD ListDomainTableName NVARCHAR(100) 
END

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

IF OBJECT_ID('tempdb..##LDTables') IS NOT NULL
BEGIN
	DROP TABLE ##LDTables;
END;

IF OBJECT_ID ('tmp_TrackListDomainChanges') IS NOT NULL
	AND EXISTS (SELECT 1 FROM sys.foreign_key_columns WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain')
BEGIN
 DROP TABLE tmp_TrackListDomainChanges
END

IF OBJECT_ID ('tmp_TrackListDomainChanges') IS NULL
BEGIN
	CREATE TABLE tmp_TrackListDomainChanges (OldDomainId INT,
									 NewDomainId INT, 
									 Code NVARCHAR(255), 
									 Descr NVARCHAR(255), 
									 DomainCatalogId INT, 
									 NewTableName NVARCHAR(50),
									 ReferencedTableName NVARCHAR(100),
									 ReferencedColumnName NVARCHAR(100),
									 NewTableDCId INT)
END
--IF OBJECT_ID('tempdb..##LDTables') IS NULL
--BEGIN
--	CREATE TABLE ##LDTables  (Id INT IDENTITY(1,1),
--							fk_constraint NVARCHAR(100),
--							fk_table NVARCHAR(100),
--							fk_column NVARCHAR(100),
--							new_table_name NVARCHAR(100),
--							DomainCatalogId INT
--							--ref_table NVARCHAR(100),
--							--ref_column NVARCHAR(100)
--							);
--END;
--return
--select 'TE'
/*
	--This query 
	--1) Generates a list of all child tables with a foreign key constraint referencing the ListDomain table
	--2) Uses the name of the foreign key column from the child table to generate a new name for the new Domain table that will
	--   be used by the child table
	--3) Stores the results in a temporary table

	Generate a List of all tables that are referencing the ListDomain table
*/
IF OBJECT_ID ('tempdb..##LDTables') IS NULL
BEGIN
	CREATE TABLE ##LDTables  (Id INT IDENTITY(1,1),
						FKConstraint NVARCHAR(100),
						FKTableName NVARCHAR(100),
						FKColumnName NVARCHAR(100),
						NewListDomainTable NVARCHAR(100),
						DomainCatalogId INT,
						DomainDescr NVARCHAR(100)
						--ref_table NVARCHAR(100),
						--ref_column NVARCHAR(100)
						);

	SET @SQL = '
	INSERT INTO ##LDTables --(FKConstraint, FKTableName, FKColumnName)
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
				WHEN LEN (REPLACE(DomainDescr, '' '', '''')) > 28
					THEN SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), 1, 28) + ''LD''
				ELSE REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''') + ''LD''
			END AS new_table_name,
			Id,
			DomainDescr
	FROM DomainCatalog
	WHERE Id <> -1'

	EXECUTE (@SQL)

END


DECLARE LDTables_Cursor CURSOR FOR
SELECT FKTableName,
	   FKColumnName
FROM ##LDTables
WHERE NewListDomainTable IS NULL
--AND FKColumnName IN ('ILINCDStatusDomainId', 'ILICBFailPressAlgthmDomainId', 'ILICBStatusDomainId',
--'CoatingLineDomainId', 'StructureTypeDomainId')
--AND FKTableName IN ('InlineInspectionCrsnCallBox', 'InlineInspectionNonCrsnDfct', 'InlineInspectionCrsnCallBox',
--'POECoatingProperty', 'StructureAreaFill')
--and FKTableName = 'StructureAreaFill'--'POECoatingProperty'
--and FKColumnName = 'StructureTypeDomainId'--'CoatingLineDomainId'
--StructureTypeDomainId FROM StructureAreaFill
--AND FKTableName NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 'ActionItemPropDCXRef')

OPEN LDTables_Cursor
FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName

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

	SET @DomainCatalogId = NULL

	SET @SQL = 'SELECT @Result = DomainCatalogId FROM DomainCatalogcolXRef
				WHERE TableName = ''' + @FKTableName + '''
				AND ColumnName = ''' + @FKColumnName + ''''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @DomainCatalogId OUT

	
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
		Then the new list domain table name should be one of the tables already in the temporary table ##LDTables
	*/	
	ELSE IF (@DomainCatalogId IS NOT NULL) OR (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1 ) = 1
	BEGIN
		
		IF (@DomainCatalogId IS NULL)
		BEGIN
			-- The Domain Catalog will be the value that is not -1
			SELECT @DomainCatalogId = DomainCatalogId FROM ##ListDomainInfo
									WHERE DomainCatalogId <> -1
		END

		UPDATE ##LDTables 
		SET NewListDomainTable = (SELECT TOP 1 NewListdomainTable FROM ##LDTables WHERE DomainCatalogId = @DomainCatalogId),
		    DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM ##LDTables WHERE DomainCatalogId = @DomainCatalogId),
		    DomainDescr = (SELECT TOP 1 DomainDescr FROM ##LDTables WHERE DomainCatalogId = @DomainCatalogId)
		WHERE FKTableName = @FKTableName
		AND FKColumnName = @FKColumnName	
	
	END
	ELSE 
	BEGIN
		IF (LEN(@FKColumnName) > 28)
		BEGIN
			SET @NewTableName = SUBSTRING(REPLACE(REPLACE(@FKColumnName, 'DomainId', ''), 'Ld', ''), 1, 28) + 'LD'
		END
		ELSE IF (@FKTableName LIKE 'IRASCustomData%')
		BEGIN
			SET @NewTableName = @FKTableName + REPLACE(@FKColumnName, 'DomainId', 'LD')
		END
		ELSE
		BEGIN
			SET @NewTableName = REPLACE(REPLACE(@FKColumnName, 'DomainId', ''), 'Ld', '') + 'LD'
		END

		IF LEN(@NewTableName) <= 30
		BEGIN
			UPDATE ##LDTables
			SET NewListDomainTable = @NewTableName
			WHERE FKTableName = @FKTableName
			AND FKColumnName = @FKColumnName	
		END
	END
	
	FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName

END
CLOSE LDTables_Cursor
DEALLOCATE LDTables_Cursor

--#####################  Create Tables Populate New List Domain Tables #############

DECLARE ListDomainTables CURSOR FOR
SELECT FKTableName, FKColumnName, NewListDomainTable
FROM ##LDTables
ORDER BY 1 DESC
--WHERE DomainCatalogId = 34

OPEN ListDomainTables
FETCH NEXT FROM ListDomainTables INTO @FKTableName, @FKColumnName, @NewTableName

WHILE @@FETCH_STATUS = 0
BEGIN
	-------------------------------------- CREATE New ListDomain tables ------------------------

	-- Create the new list domain table if it does not already exist
	IF OBJECT_ID(@StageDB + '..' + @NewTableName, 'U') IS NULL
	BEGIN
		SET @SQL = 'CREATE TABLE [' + @StageDB + '].[dbo].[' + @NewTableName + '](
		[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
		[Code] [varchar](60) NOT NULL,
		[Descr] [varchar](255) NOT NULL,
		[EffectiveEndDate] [Datetime] DEFAULT NULL,
		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
		CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY CLUSTERED 
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

------------------------------------ Populate the Table

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

	SELECT @DomainCatalogId = DomainCatalogId FROM ##LDTables
	WHERE FKTableName = @FKTableName
	AND FKColumnName = @FKColumnName

	-- Copy records related to the column and table name in current loop iteration from ListDomain table to tmp_TrackListDomainChanges
	SET @SQL = 'INSERT INTO tmp_TrackListDomainChanges 
				SELECT Id, 
						NULL, 
						Code, 
						Descr, 
						DomainCatalogId, 
						''' + @NewTableName + ''',
						''' + @FKTableName + ''',
						''' + @FKColumnName + ''',
						''' + CAST(@DomainCatalogId AS NVARCHAR) + '''
				FROM ##ListDomainInfo'

	EXECUTE (@SQL)

	-- Populate the new list domain table
	SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
							
				WITH FindDuplicateCode AS
				(
					SELECT Id,
							DomainCatalogId,
							Code,
							Descr,
							CASE 
								WHEN DomainCatalogId = -1 THEN GETDATE()
								ELSE NULL
							END AS EffectiveEndDate,
							ROW_NUMBER() OVER (PARTITION BY Code ORDER BY Code, DomainCatalogId DESC, LEN(Descr)) row_num 
					FROM ##ListDomainInfo
				)
				INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
				SELECT Id, Code, Descr, EffectiveEndDate
				FROM FindDuplicateCode
				WHERE row_num = 1
				AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')
				ORDER BY 1

				SET IDENTITY_INSERT ' + @NewTableName + ' ON'
	
	EXECUTE (@SQL)

-------------------------------- Save records that need to be changed in @FKTableName ---------
	
	SET @SQL = 'UPDATE tmp_TrackListDomainChanges
				SET NewDomainId = nt.Id
				FROM ' + @NewTableName + ' nt
				JOIN tmp_TrackListDomainChanges tmp
				ON nt.Code = tmp.Code
				AND nt.Descr = tmp.Descr
				WHERE NewTableName = ''' + @NewTableName+ ''''

	EXECUTE (@SQL)
	--SET @SQL = 'SELECT @Result = COUNT(*) FROM ##ListDomainInfo
	--WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName + ')' 

	--EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

	--IF @Count > 0
	--BEGIN
	--	SELECT @NewTableName, @FKTableName, @FKColumnName

	--	--SELECT @sql
	--	--break
	--END

-------------------------- Update @FKTableName ------------------------------------
	
	-- Create a new primary key on table referencing ListDomain table if the primary key is on foreign key column
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
				JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
				ON kcu.constraint_name = tc.constraint_name
				WHERE constraint_type = 'PRIMARY KEY'
				AND kcu.table_name = @FKTableName
				AND kcu.column_name = @FKColumnName)
	BEGIN
		DECLARE @ConstraintName NVARCHAR(100)
		
		SELECT @ConstraintName = tc.constraint_name FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
				JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
				ON kcu.constraint_name = tc.constraint_name
				WHERE constraint_type = 'PRIMARY KEY'
				AND kcu.table_name = @FKTableName

		SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @ConstraintName+ '
		
					ALTER TABLE ' + @FKTableName + ' ADD Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED'

		EXECUTE (@SQL)
	END

	SET @SQL = 'UPDATE ' + @FKTableName +'
				SET ' + @FKColumnName + ' = tmp.NewDomainId
				FROM tmp_TrackListDomainChanges tmp
				JOIN ' + @FKTableName + ' fkt
				ON tmp.OldDomainId = fkt.' + @FKColumnName+' 
				WHERE tmp.NewDomainId <> tmp.OldDomainId '

	EXECUTE (@SQL)

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

----------------------------------------------- CREATE FOREIGN KEYS ON NEW DOMAIN TABLES -------------------------------------------------------------
	
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
	END -- if-statement block (check for NULL value)

	*/

	FETCH NEXT FROM ListDomainTables INTO @FKTableName, @FKColumnName, @NewTableName
END

CLOSE ListDomainTables
DEALLOCATE ListDomainTables



RETURN
----################################ CHECK
select * from ##LDTables
WHERE NewListDomainTable in (
select NewListDomainTable from (
select NewListDomainTable, COUNT(NewListDomainTable) as cnt
from ##LDTables
GROUP BY NewListDomainTable
HAVING COUNT(NewListDomainTable) > 1) tmp
)
order by 5

select *, len(newlistdomaintable) from ##LDTables
where DomainCatalogId IS NULL 
order by len(newlistdomaintable) desc

return
------------------------------------------ 
SELECT distinct DomainCatalogId FROM ##LDTables
WHERE NewListDomainTable IN(
SELECT sub.NewListDomainTable FROM
(SELECT NewListDomainTable, Count(NewListDomainTable) col_count 
FROM ##LDTables
WHERE FKColumnName IS NULL-- NewListDomainTable IS NOT NULL
group by NewListDomainTable
having count(NewListDomainTable) > 1) sub
)
AND FKColumnName IS NULL

return

DECLARE test CURSOR FOR
SELECT FKTableName, FKColumnName 
FROM ##LDTables
--WHERE FKColumnName IN ('ILINCDStatusDomainId', 'ILICBFailPressAlgthmDomainId', 'ILICBStatusDomainId',
--'CoatingLineDomainId', 'StructureTypeDomainId')
--AND FKTableName IN ('InlineInspectionCrsnCallBox', 'InlineInspectionNonCrsnDfct', 'InlineInspectionCrsnCallBox',
--'POECoatingProperty', 'StructureAreaFill')
WHERE NewListDomainTable IS NULL
--StructureTypeDomainId FROM Struc tureAreaFill

--return

OPEN test

FETCH NEXT FROM test INTO @FKTableName, @FKColumnName
WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'SELECT @Result = COUNT(*) FROM DomainCatalogColXRef
				WHERE TableName = ''' +@FKTableName + '''
				AND ColumnName = '''+@FKColumnName+''''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT
	IF (@Count = 0)
	BEGIN
		SELECT @FKColumnName, @FKTableName
	END
FETCH NEXT FROM test INTO @FKTableName, @FKColumnName

END
CLOSE test
deallocate test