/*

his script takes the ListDomain data for virtual tables and seperates them
into various ListDomain tables with names prefixed by 'LD_' or 'GLD_' in the 'DRAS' schema. 
'GLD_' tables share ListDomain data with other tables whereas 'LD_' tables have only one table
referencing them. 

This script also creates or deletes and recreates the TempListdomainTable table. This script must be executed
on the target database

*/

DECLARE @NewTableName NVARCHAR(100)
DECLARE @VirtualColumnId INT
DECLARE @VirtualTableId INT
DECLARE @VirtualTableName NVARCHAR(100)
DECLARE @VirtualColumnName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Count INT
DECLARE @DomainCatalogId INT

---------------------------------- Create/Define Temporary tables ---------------------------------
IF OBJECT_ID('VirtualTableDataListDomain', 'U') IS NOT NULL
BEGIN

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
		SELECT DISTINCT vc.Id AS VirtualColumnId,
				VirtualTableId,
				'LD_' + VirtualColumnname,
				NULL
		FROM VirtualColumn vc
		JOIN VirtualTable vt
			ON vc.VirtualTableId =vt.Id
		WHERE VirtualColumnDataTypeInd = 'L'
	END

	UPDATE ##NewDomainTableList
	SET NewTableName = REPLACE(REPLACE(NewTableName, 'Remediation', 'Remed'), 'Reinforcement', 'Reinforce')
	WHERE LEN(NewTableName) > 30

--------------------------------------- Create Schema to store Virtual Tables ----------------------------

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
BEGIN
	SET @SQL = 'CREATE SCHEMA DRAS'
	EXECUTE (@SQL)
END

/**************************************************************************************************
									VALIDATE LISTDOMAIN DATA
**********************************************************************************************/

	DECLARE NewDomainTableList CURSOR FOR
	SELECT VirtualColumnId, VirtualTableId, NewTableName, DomainCatalogId 
	FROM ##NewDomainTableList

	OPEN NewDomainTableList
	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName, @DomainCatalogId

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'SELECT @Result = VirtualColumnName 
		FROM VirtualColumn WHERE id = ' + CAST(@VirtualColumnId AS NVARCHAR)

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualColumnName OUT

		SET @SQL = 'SELECT @Result = VirtualTableName 
		FROM VirtualTable WHERE Id = ' + CAST(@VirtualTableId AS NVARCHAR)

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualTableName OUT

		SET @DomainCatalogId = NULL

		SET @SQL = 'SELECT @Result = DomainCatalogId 
		FROM DomainCatalogColXRef 
		WHERE TableName = ''' + @VirtualTableName + '''
		AND ColumnName = ''' + @VirtualColumnName + ''''

		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @DomainCatalogId OUT

		IF (@DomainCatalogId IS NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ListDomain 
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

		UPDATE ##NewDomainTableList
		SET DomainCatalogId = @DomainCatalogId
		WHERE VirtualColumnId = @VirtualColumnId
		AND VirtualTableId = @VirtualTableId

	-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------
	
		IF OBJECT_ID('DRAS.' + @NewTableName) IS NULL
		BEGIN
			SET @SQL = 'CREATE TABLE [DRAS].[' + @NewTableName + '](
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

		END;

		-- Recreate update trigger on new listdomain table table
		IF OBJECT_ID ( 'DRAS.tu_' + @NewTableName + '', 'TR') IS NULL
		BEGIN
			SET @SQL = 'CREATE TRIGGER [DRAS].[tu_' + @NewTableName + '] ON [DRAS].[' + @NewTableName + '] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE DRAS.' + @NewTableName + '
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM DRAS.' + @NewTableName + ' as t, DELETED as d
				WHERE t.Id=d.Id;
			END'

			EXECUTE (@SQL)
		END

	-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------

		-- Populate the new list domain table if it is empty (Ensures the ListDomain Id is unique)
		SET @SQL = 'IF (SELECT COUNT(*) FROM DRAS.' + @NewTableName + ') = 0
					BEGIN 
					
					-- Copy data into new list domain table
					SET IDENTITY_INSERT DRAS.' + @NewTableName + ' ON;
					
					WITH tmpQuery AS
					(SELECT Id,
							Code,
							Descr,
							DomainCatalogId
					 FROM dbo.ListDomain
					 WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId 
									FROM VirtualTableDataListDomain
									WHERE VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + '
									AND VirtualColumnId = ' + CAST(@VirtualColumnId AS NVARCHAR) + ')
					UNION
					SELECT Id,
						   Code,
						   Descr,
						   DomainCatalogId
					FROM dbo.ListDomain
					WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) + '
					)
					INSERT INTO DRAS.' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
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
					WHERE Id NOT IN (SELECT Id FROM DRAS.' + @NewTableName + ')
					
					SET IDENTITY_INSERT DRAS.' + @NewTableName + ' OFF
				END';

		EXECUTE (@SQL);	 

		FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName, @DomainCatalogId
	END

	CLOSE NewDomainTableList
	DEALLOCATE NewDomainTableList

	------------------------------- CREATE AND/OR UPDATE the TempListDomainTable table ------------------------

	-- Create temporary table in config databases to store list domain info
	SET @SQL = 'IF OBJECT_ID(''dbo.TempListDomainTable'') IS NOT NULL
				BEGIN
					DROP TABLE dbo.TempListDomainTable
				END'

	EXECUTE (@SQL)

	SET @SQL = 'IF OBJECT_ID(''dbo.TempListDomainTable'') IS NULL
				BEGIN
					CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
															ListDomainTableName VARCHAR(100),
															ReferencedTableName VARCHAR(50),
															ReferencedColumnName VARCHAR(50),
															DomainCatalogId INT,
															DomainDescr VARCHAR(255)
															)
						
					BEGIN TRANSACTION
						INSERT INTO dbo.TempListDomainTable
						SELECT ''Virtual'' AS TableType,
								nld.NewTableName,
								vt.VirtualTableName AS ReferencedTableName,
								vc.VirtualColumnName AS ReferencedColumnName,
								DomainCatalogId,
								(SELECT DomainDescr FROM DomainCatalog WHERE Id = nld.DomainCatalogId) As DomainDescr	
						FROM ##NewDomainTableList nld
						LEFT JOIN dbo.VirtualTable vt 
							ON nld.VirtualTableId = vt.Id
						JOIN dbo.VirtualColumn vc
							ON nld.VirtualColumnId = vc.Id
					COMMIT TRANSACTION
				END'
			
	EXECUTE (@SQL)

END
------------------------------------- DROP VirtualTableDataListDomain table -------------------------------

IF OBJECT_ID('dbo.VirtualTableDataListDomain', 'U') IS NOT NULL
BEGIN
	-- Drop Foreign Key Referencing the ListDomain table if it exists
	IF EXISTS (SELECT 1
					FROM sys.foreign_key_columns
					WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
					AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
				) AND EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Virtual')
	BEGIN
		-- Drop foreign key
		SELECT @SQL = 'ALTER TABLE dbo.VirtualTableDataListDomain DROP CONSTRAINT ' +  OBJECT_NAME(constraint_object_id)
						FROM sys.foreign_key_columns
						WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
						AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'

		EXECUTE (@SQL)
			
	END

	IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NOT NULL
	BEGIN
		DROP TABLE ##NewDomainTableList
	END
END