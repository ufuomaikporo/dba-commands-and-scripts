IF OBJECT_ID('tempdb..##FKList') IS NOT NULL
BEGIN
	DROP TABLE ##FKList;
END;

IF OBJECT_ID('tempdb..##FKList') IS NULL
BEGIN
	CREATE TABLE ##FKList  (Id INT IDENTITY(1,1),
							fk_constraint NVARCHAR(100),
							fk_table NVARCHAR(100),
							fk_column NVARCHAR(100),
							new_table_name NVARCHAR(100),
							ref_table NVARCHAR(100),
							ref_column NVARCHAR(100)
							);
END;

IF NOT EXISTS (SELECT 1 FROM ##FKList)
BEGIN
	INSERT INTO ##FKList
	SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
		   OBJECT_NAME(parent_object_id) AS fk_table,
		   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		   CASE
		   WHEN PATINDEX('%_DomainId%', COL_NAME(parent_object_id, parent_column_id) ) > 0 
				THEN REPLACE(REPLACE(COL_NAME(parent_object_id, parent_column_id), '_DomainId', ''), 'DomainId', '') + 'LD'
		   WHEN PATINDEX('%LD', COL_NAME(parent_object_id, parent_column_id)) > 0
				THEN REPLACE(COL_NAME(parent_object_id, parent_column_id), 'LD', '') + 'LD'
		   ELSE COL_NAME(parent_object_id, parent_column_id) + 'LD'
		   END AS new_table_name,
		   OBJECT_NAME(referenced_object_id) AS ref_table,
		   COL_NAME(referenced_object_id, referenced_column_id) AS ref_column
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
	AND OBJECT_NAME(constraint_object_id) NOT IN (SELECT fk_constraint FROM ##FKList)

	INSERT INTO ##FKLIST (new_table_name)
	SELECT CASE 
				WHEN LEN (REPLACE(DomainDescr, ' ', '')) > 28
					THEN SUBSTRING(REPLACE(DomainDescr, ' ', ''), 1, 28) + 'LD'
				ELSE REPLACE(DomainDescr, ' ', '') + 'LD'
			END
	FROM DomainCatalog
	WHERE Id NOT IN (SELECT DomainCatalogId FROM domaincatalogcolxref)
	AND REPLACE(DomainDescr, ' ', '') + 'LD' NOT IN (SELECT name FROM sys.tables)
END

DECLARE @SQL NVARCHAR(MAX)
DECLARE @Count INT
DECLARE @fk_table NVARCHAR(100)
DECLARE @fk_column NVARCHAR(100)

DECLARE fklist CURSOR FOR
SELECT fk_column, fk_table FROM ##FKList

OPEN fklist
FETCH NEXT FROM fklist INTO @fk_column, @fk_table

WHILE @@FETCH_STATUS  =0
BEGIN
	SET @SQL = 'SELECT @Result = COUNT(*) FROM DomainCatalogColXRef
				WHERE tablename = '''+ @fk_table+'''
				AND columnname = '''+ @fk_column+''''

		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

		IF @Count = 0
		BEGIN
				SET @SQL = 'SELECT @Result = COUNT (DISTINCT Id) FROM DomainCatalog 
				WHERE Id IN (SELECT DomainCatalogId FROM ListDomain
								WHERE Id IN (SELECT DISTINCT '+@fk_column+' FROM '+@fk_table+')
							)'

				EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

				if @Count >  1
				BEGIN
					SELECT 'SELECT * FROM ListDomain
							WHERE Id IN (SELECT DISTINCT '+@fk_column+' FROM '+@fk_table+')'
				END
		END
FETCH NEXT FROM fklist INTO @fk_column, @fk_table
END
CLOSE fklist
DEALLOCATE fklist

--select * from listdomain where DomainCatalogId = 14
--order by 2

--select * from DomainCatalog where domaindescr like 'Coat%'
--SELECT DISTINCT * FROM InlineInspectionCrsnCallBox