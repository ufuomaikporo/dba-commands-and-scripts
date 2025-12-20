/*
	NOTE**** BEFORE RUNNING THIS SCRIPT be sure to set the STAGE and CONFIG database variables below
*/
DECLARE @StageDB NVARCHAR(100)
DECLARE @ConfigDB NVARCHAR(100)
DECLARE @NewTableName NVARCHAR(100)
DECLARE @VirtualColumnId INT
DECLARE @VirtualTableId INT
DECLARE @OldDomainId INT
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Count INT

--**************************************** SET THE FOLLOWING VARIABLES ********************************

SET @StageDB = 'TMC_IRASv6_STAGE'
SET @ConfigDB = 'TMC_IRASv6_CONFIG'

--**********************************************************************************************************


IF OBJECT_ID('tempdb..##DomainInfo') IS NOT NULL
BEGIN
	DROP TABLE ##DomainInfo;
END
IF OBJECT_ID('tempdb..##DomainInfo') IS NULL
BEGIN
	CREATE TABLE ##DomainInfo (VirtualTableId NUMERIC,
							   VirtualColumnId NUMERIC,
							   VirtualTableStationingId NUMERIC,
							   OldDomainId NUMERIC,
							   Code VARCHAR(40),
							   Descr VARCHAR(255),
							   NewDomainId NUMERIC
							  );
END;

IF OBJECT_ID ('Tempdb..NewDomainTableList') IS NOT NULL
BEGIN
	DROP TABLE NewDomainTableList
END

IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NULL
BEGIN
	SELECT DISTINCT Id AS VirtualColumnId,
	   VirtualTableId,
	   VirtualColumnName + 'VTLD'	 AS NewTableName  
	INTO ##NewDomainTableList
	FROM VirtualColumn vt
	WHERE VirtualColumnDataTypeInd = 'L'
	
END

DECLARE NewDomainTableList CURSOR FOR
SELECT * FROM ##NewDomainTableList
ORDER BY 3

OPEN NewDomainTableList;
FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName;

WHILE @@FETCH_STATUS = 0
BEGIN

-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------

	IF OBJECT_ID('dbo.' + @NewTableName) IS NULL
	BEGIN
		SET @SQL = 'CREATE TABLE [' + @StageDB + '].[dbo].[' + @NewTableName + '](
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

--------------------------------------------- SAVE OLD DOMAIN ID INFO ----------------------------------------------
	
	SET @Count = 1
	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @NewTableName + ''
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

	-- Save the old domain info only if the new domain table is empty
	IF (@Count = 0)
	BEGIN

		SET @SQL = 'TRUNCATE TABLE ##DomainInfo;

					INSERT INTO ##DomainInfo (VirtualTableId, 
											  VirtualColumnId, 
											  VirtualTableStationingId, 
											  OldDomainId,
											  Code,
											  Descr)
					SELECT VirtualTableId, 
						   VirtualColumnId, 
						   VirtualTableStationingId, 
						   DataFieldValueDomainId,
						   ld.Code,
						   ld.Descr
					FROM VirtualTableDataListDomain vtld
					JOIN ListDomain ld
						ON ld.Id = vtld.DataFieldValueDomainId
					WHERE VirtualTableId = ''' + CAST(@VirtualTableId AS NVARCHAR) + '''
					AND VirtualColumnId = ''' + CAST(@VirtualColumnId AS NVARCHAR) + '''';

		EXECUTE (@SQL);
	END

-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------
	
	IF OBJECT_ID(@StageDB + '.dbo.' + @NewTableName) IS NOT NULL AND @Count = 0
	BEGIN
		SET @SQL = 'INSERT INTO ' + @StageDB +'.dbo.' + @NewTableName + ' (Code, Descr)
					SELECT Code, Descr 
					FROM ListDomain
					WHERE DomainCatalogId IN (SELECT DISTINCT DomainCatalogId 
											  FROM ListDomain 
											  WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId 
															FROM VirtualTableDataListDomain
															WHERE VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + '
															AND VirtualColumnId = ' + CAST(@VirtualColumnId AS NVARCHAR) + '
														  )
											)
					AND Code NOT IN (SELECT Code FROM ' + @StageDB +'.dbo.' + @NewTableName + ')';

		EXECUTE (@SQL);	

	END 

-------------------------------------- UPDATE Domain Id in VirtualTableDataListDomain table ------------------------------------------------
	
	-- Drop Foreign Key Referencing the ListDomain table

	IF EXISTS (SELECT 1
					FROM sys.foreign_key_columns
					WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
					AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
				)
	BEGIN
		SELECT @SQL = 'ALTER TABLE ' + @StageDB + '.dbo.VirtualTableDataListDomain DROP CONSTRAINT ' +  OBJECT_NAME(constraint_object_id)
						FROM sys.foreign_key_columns
						WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
						AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
		EXECUTE (@SQL)

		-- Create temporary table in config databases to store list domain info
		SET @SQL = 'IF OBJECT_ID('''+ @ConfigDB +'.dbo.TempListDomainTable'') IS NOT NULL
					BEGIN
						DROP TABLE '+ @ConfigDB +'.dbo.TempListDomainTable
					END

					IF OBJECT_ID('''+ @ConfigDB +'.dbo.TempListDomainTable'') IS NULL
					BEGIN
						CREATE TABLE '+ @ConfigDB +'.dbo.TempListDomainTable (TableType VARCHAR(50),
																			  ListDomainTableName VARCHAR(50),
																			  ReferencedTableName VARCHAR(50),
																			  ReferencedColumnName VARCHAR(50),
																			  DomainCatalog VARCHAR(255)
																			  )
						
						INSERT INTO '+ @ConfigDB +'.dbo.TempListDomainTable
						SELECT ''Virtual'' AS TableType,
							   nld.NewTableName,
							   vt.VirtualTableName AS ReferencedTableName,
							   vc.VirtualColumnName AS ReferencedColumnName,
							   (SELECT DomainDescr 
							    FROM ' + @StageDB + '.dbo.DomainCatalog 
								WHERE Id IN (SELECT DISTINCT DomainCatalogId FROM ' + @StageDB + '.dbo.Listdomain 
											 WHERE Id IN (SELECT DataFieldValueDomainId 
														  FROM ' + @StageDB + '.dbo.VirtualTableDataListDomain
														  WHERE VirtualColumnId = nld.VirtualColumnId
														  AND VirtualTableId = nld.VirtualTableId
														  )
											)
								) As DomainCatalogName
						FROM ##NewDomainTableList nld
						LEFT JOIN ' + @StageDB + '.dbo.VirtualTable vt 
							ON nld.VirtualTableId = vt.Id
						JOIN ' + @StageDB + '.dbo.VirtualColumn vc
							ON nld.VirtualColumnId = vc.Id
						ORDER BY 2
					END'

			EXECUTE (@SQL)
	END

	-- Update the temporary table for storing the old and new domain information
	SET @SQL = 'UPDATE ##DomainInfo
				SET NewDomainId = Id
				FROM '+ @StageDB +'.dbo.' + @NewTableName + ' nt
				JOIN ##DomainInfo di
				ON nt.Code = di.Code
				AND nt.Descr = di.Descr'

	EXECUTE (@SQL)
	
	-- Update domain info on VirtualTableDataListDomain table
	SET @SQL = 'UPDATE VirtualTableDataListDomain
				SET DataFieldValueDomainId = Id
				FROM '+ @StageDB +'.dbo.' + @NewTableName + ' nt
				JOIN ##DomainInfo di
					ON nt.code = di.code
					AND nt.descr = di.descr
				JOIN VirtualTableDataListDomain vtld
					ON di.VirtualTableId = vtld.VirtualTableId
					AND di.VirtualColumnId = vtld.VirtualColumnId
					AND di.OldDomainId = vtld.DataFieldValueDomainId
				WHERE vtld.VirtualTableId = ''' + CAST(@VirtualTableId AS NVARCHAR) + '''
				AND vtld.VirtualColumnId = ''' + CAST(@VirtualColumnId AS NVARCHAR) + ''''

	EXECUTE (@SQL);

	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName;
END;

CLOSE NewDomainTableList
DEALLOCATE NewDomainTableList
