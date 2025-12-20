/*
	NOTE**** BEFORE RUNNING THIS SCRIPT be sure to set the CONFIG database variables below. The script
	must be executed on the stage database
*/
DECLARE @StageDB NVARCHAR(100)
DECLARE @ConfigDB NVARCHAR(100)
DECLARE @NewTableName NVARCHAR(100)
DECLARE @VirtualColumnId INT
DECLARE @VirtualTableId INT
DECLARE @VirtualTableName NVARCHAR(100)
DECLARE @VirtualColumnName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Count INT
DECLARE @DomainCatalogId INT

--**************************************** SET THE FOLLOWING VARIABLES ********************************

SET @ConfigDB = ''

--**********************************************************************************************************

---------------------------- Check that a valid Config and Stage DB is being used --------------------------

SELECT @StageDB = DB_NAME()

-- Check that the stage database is valid
SET @SQL = 'SELECT @Result = COUNT(*) FROM '+@StageDB+'..VersionInfo 
			WHERE DBVersionComment NOT LIKE ''%Link%''
			AND DBVersionComment NOT LIKE ''%Config%'''

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

---------------------------------- Create/Define Temporary tables ---------------------------------

IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NOT NULL
BEGIN
	DROP TABLE ##NewDomainTableList
END

IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NULL
BEGIN

	CREATE TABLE ##NewDomainTableList (VirtualColumnId INT,
									   VirtualTableId INT,
									   NewTableName NVARCHAR(100),
									   DomainCatalogId INT)

	INSERT INTO ##NewDomainTableList
	SELECT DISTINCT Id AS VirtualColumnId,
			VirtualTableId,
			NULL,
			NULL
	FROM VirtualColumn vt
	WHERE VirtualColumnDataTypeInd = 'L'
	ORDER BY 3

END

------------------------------ Cursor to Create new list domain virtual tables -------------------------------

DECLARE NewDomainTableList CURSOR FOR
SELECT VirtualColumnId, VirtualTableId FROM ##NewDomainTableList

OPEN NewDomainTableList
FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'SELECT @Result = VirtualColumnName 
	FROM ' + @StageDB + '..VirtualColumn WHERE id = ' + CAST(@VirtualColumnId AS NVARCHAR)

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualColumnName OUT

	SET @SQL = 'SELECT @Result = VirtualTableName 
	FROM ' + @StageDB + '..VirtualTable WHERE Id = ' + CAST(@VirtualTableId AS NVARCHAR)

	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualTableName OUT

	SET @DomainCatalogId = NULL

	SET @SQL = 'SELECT @Result = DomainCatalogId 
	FROM ' +@StageDB + '..DomainCatalogColXRef 
	WHERE TableName = ''' + @VirtualTableName + '''
	AND ColumnName = ''' + @VirtualColumnName + ''''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @DomainCatalogId OUT


	-- If there is an entry in the DomainCatalogColXRef table for the table and column
	IF (@DomainCatalogId IS NOT NULL)
	BEGIN
		SET @SQL =  'SELECT @Result = (SELECT DomainDescr FROM DomainCatalog 
		WHERE Id = ' + CAST(@DomainCatalogId AS NVARCHAR) + ')'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @NewTableName OUT

		SET @NewTableName = REPLACE(REPLACE(REPLACE(REPLACE(@NewTableName, ' ', ''), '-', ''), '.', ''), '/', '') 
	END
	ELSE IF (SELECT COUNT(DISTINCT @DomainCatalogId) FROM ListDomain 
			WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
						 WHERE VirtualTableId = @VirtualTableId
						 AND VirtualColumnId = @VirtualColumnId
						  ) 
			) = 1
	BEGIN
		   SELECT TOP 1 @DomainCatalogId = DomainCatalogId FROM ListDomain
		   WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
						 WHERE VirtualTableId = @VirtualTableId
						 AND VirtualColumnId = @VirtualColumnId
						  ) 

		SET @SQL =  'SELECT @Result = (SELECT DomainDescr FROM DomainCatalog 
		WHERE Id = ' + CAST(@DomainCatalogId AS NVARCHAR) + ')'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @NewTableName OUT

		SET @NewTableName = REPLACE(REPLACE(REPLACE(REPLACE(@NewTableName, ' ', ''), '-', ''), '.', ''), '/', '') 

	END
	ELSE IF (SELECT COUNT(DISTINCT @DomainCatalogId) FROM ListDomain 
			WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
						 WHERE VirtualTableId = @VirtualTableId
						 AND VirtualColumnId = @VirtualColumnId
						  ) 
			) > 1
	BEGIN 
		SET @SQL = 'THROW 51001, N''There is are more than 1 domain categories for '''''  
					+ @VirtualTableName + '''''' + ' virutal table and ''''' + @VirtualColumnName +''''' virtual column.' + CHAR(10) 
					+ '. Only domain category can be assigned for the column-table combination for this script to continue '', 1;'
		EXECUTE (@SQL)
	END
	ELSE
	BEGIN
		SET @NewTableName = REPLACE(REPLACE(@VirtualColumnName, 'Ld' , ''), 'DomainId', '') 
	END

	IF (LEN(@NewTableName) > 28)
	BEGIN
		SET @NewTableName = SUBSTRING(@NewTableName, 1, 28) + 'LD'
	END
	ELSE
	BEGIN
		SET @NewTableName = @NewTableName + 'LD'
	END

	UPDATE ##NewDomainTableList
	SET NewTableName = @NewTableName,
		DomainCatalogId = @DomainCatalogId
	WHERE VirtualColumnId = @VirtualColumnId
	AND VirtualTableId = @VirtualTableId

	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId
END

CLOSE NewDomainTableList
DEALLOCATE NewDomainTableList

------------------------- Create and update the TempListDomainTable table in Config database ----------------

-- Create temporary table in config databases to store list domain info
SET @SQL = 'IF OBJECT_ID('''+ @ConfigDB +'.dbo.TempListDomainTable'') IS NOT NULL
			BEGIN
				DROP TABLE '+ @ConfigDB +'.dbo.TempListDomainTable
			END'

EXECUTE (@SQL)

SET @SQL = 'IF OBJECT_ID('''+ @ConfigDB +'.dbo.TempListDomainTable'') IS NULL
			BEGIN
				CREATE TABLE '+ @ConfigDB +'.dbo.TempListDomainTable (TableType VARCHAR(50),
																		ListDomainTableName VARCHAR(50),
																		ReferencedTableName VARCHAR(50),
																		ReferencedColumnName VARCHAR(50),
																		DomainCatalogId INT,
																		DomainDescr VARCHAR(255),
																		NumOfRowsinListDomainTbl INT
																		)
						
				INSERT INTO '+ @ConfigDB +'.dbo.TempListDomainTable
				SELECT ''Virtual'' AS TableType,
						nld.NewTableName,
						vt.VirtualTableName AS ReferencedTableName,
						vc.VirtualColumnName AS ReferencedColumnName,
						DomainCatalogId,
						(SELECT DomainDescr FROM DomainCatalog WHERE Id = nld.DomainCatalogId) As DomainDescr,
						(SELECT COUNT(*) FROM ' + @StageDB + '..ListDomain WHERE Id IN (SELECT DataFieldValueDomainId
																	FROM ' + @StageDB + '..VirtualTableDataListDomain 
																	WHERE VirtualTableId = nld.VirtualTableId 
																	AND VirtualColumnId = nld.VirtualColumnId
																	) 
						)		
				FROM ##NewDomainTableList nld
				LEFT JOIN ' + @StageDB + '.dbo.VirtualTable vt 
					ON nld.VirtualTableId = vt.Id
				JOIN ' + @StageDB + '.dbo.VirtualColumn vc
					ON nld.VirtualColumnId = vc.Id
			END'
			
EXECUTE (@SQL)

------------------------------------  Create New list domain tables --------------------------------

DECLARE NewDomainTableList CURSOR FOR
SELECT VirtualColumnId, VirtualTableId, NewTableName 
FROM ##NewDomainTableList
--WHERE NewTableName = 'ProductTypeLD'

OPEN NewDomainTableList;
FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName

WHILE @@FETCH_STATUS = 0
BEGIN 
-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------
	
	IF OBJECT_ID('dbo.' + @NewTableName) IS NULL
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
					CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY NONCLUSTERED 
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
	
-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------
	
	-- Populate the new list domain table if it is empty (Ensures the ListDomain Id is unique)
	SET @SQL = 'IF (SELECT COUNT(*) FROM ' + @NewTableName + ') = 0
				BEGIN
					-- Copy relevant data for the current table and column in loop iteration from ListDomain table to a temporary table
					IF OBJECT_ID(''tempdb..##ListDomainInfo'') IS NOT NULL
					BEGIN
						DROP TABLE ##ListDomainInfo;
					END

					SELECT Id, DomainCatalogId, Code, Descr
					INTO ##ListDomainInfo
					FROM ' + @StageDB + '.dbo.ListDomain
					WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId 
															FROM VirtualTableDataListDomain
															WHERE VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + '
															AND VirtualColumnId = ' + CAST(@VirtualColumnId AS NVARCHAR) + '
														  
											)
		
				-- Copy data from temporary table into new list domain table
				SET IDENTITY_INSERT ' + @StageDB +'.dbo.' + @NewTableName + ' ON
						
					INSERT INTO ' + @StageDB +'.dbo.' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
					SELECT Id, 
						   Code, 
						   Descr,
						   CASE 
								WHEN DomainCatalogId = -1 THEN GETDATE()
								ELSE NULL
							END AS EffectiveEndDate
					FROM ##ListDomainInfo
					WHERE Id NOT IN (SELECT Id FROM ' + @StageDB +'.dbo.' + @NewTableName + ')
					
					SET IDENTITY_INSERT ' + @StageDB +'.dbo.' + @NewTableName + ' OFF
			END';

		EXECUTE (@SQL);	 

---------------------------------- Drop Foreign key and UPDATE VirtualTableDataListDomain table ------------------------------------------------
	
	-- Drop Foreign Key Referencing the ListDomain table if it exists
	IF EXISTS (SELECT 1
					FROM sys.foreign_key_columns
					WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
					AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
				)
	BEGIN
		-- Drop foreign key
		SELECT @SQL = 'ALTER TABLE ' + @StageDB + '.dbo.VirtualTableDataListDomain DROP CONSTRAINT ' +  OBJECT_NAME(constraint_object_id)
						FROM sys.foreign_key_columns
						WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
						AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'

		EXECUTE (@SQL)
			
	END

	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName
END;

CLOSE NewDomainTableList
DEALLOCATE NewDomainTableList

DROP TABLE ##NewDomainTableList