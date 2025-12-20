DECLARE @NewTableName NVARCHAR(100)
DECLARE @VirtualColumnId INT
DECLARE @VirtualTableId INT
DECLARE @OldDomainId INT
DECLARE @SQL NVARCHAR(MAX)

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

DECLARE NewDomainTableList CURSOR FOR
SELECT DISTINCT Id AS VirtualColumnId,
	   VirtualTableId,
	   VirtualColumnName + 'LD'	   
FROM VirtualColumn vt
WHERE VirtualColumnDataTypeInd = 'L'

OPEN NewDomainTableList;
FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName;

WHILE @@FETCH_STATUS = 0
BEGIN

-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------
	
	IF OBJECT_ID('dbo.' + @NewTableName) IS NULL
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

--------------------------------------------- SAVE OLD DOMAIN ID INFO ----------------------------------------------

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
		--select @sql break
		EXECUTE (@SQL);
				 --select * from ##DomainInfo break

-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------
	
	IF OBJECT_ID('dbo.' + @NewTableName) IS NOT NULL
	BEGIN
		SET @SQL = 'INSERT INTO ' + @NewTableName + ' (Code, Descr)
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
					AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')';
		EXECUTE (@SQL);
	END

-------------------------------------- UPDATE Domain Id in VirtualTableDataListDomain table ------------------------------------------------
	
	-- Drop Foreign Key Referencing the ListDomain table

	IF EXISTS (SELECT OBJECT_NAME(constraint_object_id)
					FROM sys.foreign_key_columns
					WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
					AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
				)
	BEGIN
		SELECT @SQL = 'ALTER TABLE VirtualTableDataListDomain DROP CONSTRAINT ' +  OBJECT_NAME(constraint_object_id)
						FROM sys.foreign_key_columns
						WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
						AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
		EXECUTE (@SQL)
	END

	-- Update the temporary table for storing the old and new domain information
	SET @SQL = 'UPDATE ##DomainInfo
				SET NewDomainId = Id
				FROM ' + @NewTableName + ' nt
				JOIN ##DomainInfo di
				ON nt.Code = di.Code
				AND nt.Descr = di.Descr'

	EXECUTE (@SQL)
		
	SET @SQL = 'UPDATE VirtualTableDataListDomain
				SET DataFieldValueDomainId = Id
				FROM ' + @NewTableName + ' nt
				JOIN ##DomainInfo di
					ON nt.code = di.code
					AND nt.descr = di.descr
				JOIN VirtualTableDataListDomain vtld
					ON di.VirtualTableId = vtld.VirtualTableId
					AND di.VirtualColumnId = vtld.VirtualColumnId
					AND di.OldDomainId = vtld.DataFieldValueDomainId
				WHERE vtld.VirtualTableId = ''' + CAST(@VirtualTableId AS NVARCHAR) + '''
				AND vtld.VirtualColumnId = ''' + CAST(@VirtualColumnId AS NVARCHAR) + ''''
					--select @sql
	EXECUTE (@SQL);

	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName;
END;

CLOSE NewDomainTableList
DEALLOCATE NewDomainTableList

