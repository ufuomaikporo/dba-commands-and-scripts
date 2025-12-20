DECLARE @NewTableName NVARCHAR(100)
DECLARE @VirtualColumnId INT
DECLARE @VirtualTableId INT
DECLARE @OldDomainId INT
DECLARE @SQL NVARCHAR(MAX)

DECLARE NewDomainTableList CURSOR FOR
SELECT DISTINCT Id AS VirtualColumnId,
	   VirtualTableId,
	   VirtualColumnName + 'LD'	   
FROM VirtualColumn vt
WHERE VirtualColumnDataTypeInd = 'L';

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

	FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName;
END;

CLOSE NewDomainTableList
DEALLOCATE NewDomainTableList

