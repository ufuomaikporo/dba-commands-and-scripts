DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @StageDB NVARCHAR(100);
DECLARE @ConfigDB NVARCHAR(100);
DECLARE @Count INT
DECLARE @DomainCatalogId INT;
DECLARE @CategoryId INT;
DECLARE @CategoryCode NVARCHAR(100);

/*************************************************************************************************
					CREATE New Tables based on CategoryDataListDomainXRef Table
**************************************************************************************************/

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NOT NULL AND OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	DROP TABLE ##NewDomainTableList;
END

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NULL AND OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	SET @SQL = '
	WITH tmpQuery AS
	(SELECT ROW_NUMBER() OVER (PARTITION BY CategoryId ORDER BY CategoryId) row_num,
			ValueDomainId, 
			CategoryId, 
			 CASE 
					WHEN LEN (REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''')) > 24
						THEN ''LD_CD_'' + SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', ''''), 1, 24) 
					ELSE ''LD_CD_'' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CategoryCode, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', '''')
				END AS new_table_name, 
			CategoryDescr 
	FROM CategoryDataListDomainXRef cdldx
	JOIN Category c
		ON c.Id = cdldx.CategoryId
	)
	SELECT CategoryId, new_table_name 
	INTO ##NewCategoryTableList
	FROM tmpQuery
	WHERE row_num = 1'

	EXECUTE(@SQL)

	DECLARE LDTables_Cursor CURSOR FOR
	SELECT * FROM ##NewCategoryTableList

	OPEN LDTables_Cursor
	FETCH NEXT FROM LDTables_Cursor INTO @CategoryId, @NewTableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
--------------------------------------- CREATE New ListDomain tables ---------------------------------------

		-- Create the new list domain table if it does not already exist
		IF OBJECT_ID(@NewTableName, 'U') IS NULL
		BEGIN
			SET @SQL = 'CREATE TABLE [dbo].[' + @NewTableName + '](
			[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
			[CategoryCode] [varchar](60) NOT NULL,
			[CategoryDescr] [varchar](255) NOT NULL,
			[EffectiveEndDate] [Datetime],
			[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
			[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY CLUSTERED 
			(
				[Id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
			) ON [PRIMARY]';

			EXECUTE (@SQL);
		
			-- Recreate update trigger on new listdomain table table
			IF OBJECT_ID ('..tu_' + @NewTableName + '', 'TR') IS NULL
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

---------------------------------- Populate the New List Domain Table ----------------------------------

		SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON

					INSERT INTO ' + @NewTableName + '(Id, CategoryCode, CategoryDescr)
					SELECT DISTINCT ValueDomainId,
						   CategoryCode,
						   CategoryDescr
					FROM CategoryDataListDomainXRef cdldx
					JOIN Category c
						ON c.Id = cdldx.CategoryId 
					WHERE CategoryId = ' + CAST(@CategoryId AS NVARCHAR) + '
					AND ValueDomainId NOT IN (SELECT Id FROM ' + @NewTableName + ')
					
					SET IDENTITY_INSERT ' + @NewTableName + ' OFF'

		EXECUTE(@SQL)

------------------------------ UPDATE TempListDomainTable IN CONFIG DB ---------------------------------------

		-- Create TempListDomainTable table in Config database if it doesn't already exist
		SET @SQL = 'IF OBJECT_ID(''TempListDomainTable'') IS NULL
					BEGIN
						CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																				ListDomainTableName VARCHAR(50),
																				ReferencedTableName VARCHAR(50),
																				ReferencedColumnName VARCHAR(50),
																				DomainCatalogId INT,
																				DomainDescr VARCHAR(255),
																				NumOfRowsinListDomainTbl INT
																				)
					END'

		EXECUTE (@SQL)

		-- Delete and re-insert entries for table and column in current loop iteration into TempListDomainTable
		SET @SQL = 'MERGE INTO TempListDomainTable s1
		USING (SELECT ''Real'' TableType,
						''' + @NewTableName + ''' AS NewTableName,
						NULL AS FKTableName,
						NULL AS FKColumnName,
						(SELECT MAX(ISNULL(DomainCatalogId, 0)) + 1 FROM TempListDomainTable) Id,
						(SELECT CategoryCode FROM Category WHERE Id = ' + CAST(@CategoryId AS NVARCHAR) + ') CategoryCode
				) s2
		ON (s1.DomainDescr = s2.CategoryCode)
		WHEN MATCHED THEN UPDATE
			SET s1.ListDomainTableName = s2.NewTableName,
				s1.DomainCatalogId = s2.Id,
				s1.DomainDescr = s2.CategoryCode
		WHEN NOT MATCHED THEN INSERT(TableType, ListDomainTablename, ReferencedTableName, ReferencedColumnName, DomainCatalogId, DomainDescr)
		VALUES (s2.TableType, s2.NewTableName, s2.FKTableName, s2.FKColumnName, s2.Id, s2.CategoryCode);'

		EXECUTE(@SQL)

		FETCH NEXT FROM LDTables_Cursor INTO @CategoryId, @NewTableName
	END;

	CLOSE LDTables_Cursor
	DEALLOCATE LDTables_Cursor
END

--------------------------------- DROP CategoryDataListDomainXRef, and Category tables -------------------

DECLARE DropFK_Cursor CURSOR FOR
SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
	   OBJECT_NAME(parent_object_id) AS fk_table
FROM sys.foreign_key_columns
WHERE OBJECT_NAME(referenced_object_id) IN ('Category', 'CategoryDataListDomainXRef')

OPEN DropFK_Cursor
FETCH NEXT FROM DropFK_Cursor INTO @FKConstraintName, @FKTableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName

	EXECUTE(@SQL)

	FETCH NEXT FROM DropFK_Cursor INTO @FKConstraintName, @FKTableName
END

CLOSE DropFK_Cursor
DEALLOCATE DropFK_Cursor

IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE CategoryDataListDomainXRef'
	EXECUTE(@SQL)
END

IF OBJECT_ID('Category', 'U') IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE Category'
	EXECUTE(@SQL)
END

IF OBJECT_ID('tempdb..##NewCategoryTableList') IS NOT NULL
BEGIN
	DROP TABLE ##NewCategoryTableList;
END
