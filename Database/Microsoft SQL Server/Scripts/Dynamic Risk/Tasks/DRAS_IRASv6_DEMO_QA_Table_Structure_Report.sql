USE DRAS_IRASv6_DEMO_QA

DECLARE @DBList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('tempdb..##DataDictionary') IS NOT NULL
BEGIN
	DROP TABLE ##DataDictionary
END

IF OBJECT_ID('tempdb..##DataDictionary') IS NULL
BEGIN
	CREATE TABLE ##DataDictionary (TableName NVARCHAR(100)
								  ,ColumnName NVARCHAR(100)
								  ,DataType NVARCHAR(30)
								  ,Nullable NVARCHAR(1)
								  ,PrimaryKey NVARCHAR(1)
								  ,FKParentTable NVARCHAR(100)
								  ,FKParentTableColumn NVARCHAR(100)
								  ,DomainName NVARCHAR(255))
END

SET @DBList = NULL

SET @DBList = REPLACE(@DBList, ' ', '');
SET @DBList = REPLACE(@DBList, CHAR(10), ' ');
SET @DBList = REPLACE(@DBList, CHAR(13), '');
SET @DBList = REPLACE(@DBList, CHAR(9), '');
SET @DBList = REPLACE(@DBList, ' ', ''', ''');
SET @DBList = REPLACE(@DBList, ''''', ', '');

SET @DBList = '''' + @DBList + '''';

IF (@DBList IS NOT NULL )
BEGIN
	SET @SQL = 'SELECT tab.name AS ''table name'', 
		   col.name AS ''column name'',
		   -- The following case function generates the ''data type'' column
		   CASE   
				WHEN stype.name = ''varchar'' THEN ''varchar ('' + CAST(col.max_length AS varchar) + '')''
				WHEN stype.name = ''numeric'' THEN ''numeric ('' + CAST(col.precision AS varchar(2)) + '','' + CAST(col.scale AS varchar(1)) + '')''
				ELSE stype.name
		   END AS ''data type'',
		   -- The following case function generates the ''null'' column
		   CASE 
				WHEN col.is_nullable = 0 THEN ''N''
				ELSE ''Y''
		   END AS ''nullable?'',
		   -- The following case function generates the ''primary key'' column
		   CASE
				WHEN is_primary_key = 1 THEN ''Y''
				ELSE ''N''
		   END ''primary key?'',
		   COALESCE(s.name, '' '') AS ''tie entity'', 
		   COALESCE(st2.name, '' '') AS ''tie attribute'',
		   COALESCE(domain.domain_name, '' '') aS ''domain name''
	FROM sys.tables AS tab
	LEFT JOIN sys.columns col
		ON tab.object_id = col.object_id
	LEFT JOIN sys.types stype
		ON col.user_type_id = stype.user_type_id 
	LEFT JOIN (SELECT indx_col.object_id, indx_col.column_id, indx.is_primary_key 
			   FROM sys.index_columns indx_col
			   LEFT JOIN sys.indexes indx
				ON indx_col.object_id = indx.object_id
				AND indx_col.index_id = indx.index_id
			   WHERE indx_col.index_id = 1) is_primary
		ON is_primary.object_id = col.object_id
		AND is_primary.column_id = col.column_id
	LEFT JOIN sys.foreign_key_columns f_key
		ON f_key.parent_object_id = tab.object_id
		AND col.column_id = f_key.parent_column_id
	LEFT JOIN sys.columns st2
		ON f_key.referenced_object_id = st2.object_id
		AND f_key.referenced_column_id = st2.column_id
	LEFT JOIN sys.tables s
		ON f_key.referenced_object_id = s.object_id 
	LEFT JOIN (SELECT dccx.ColumnName AS column_name, 
					  DomainDescr AS domain_name
			   FROM INFORMATION_SCHEMA.Columns c
			   LEFT JOIN dbo.DomainCatalogColXRef dccx 
				 ON dccx.TableName = c.Table_Name 
				 AND dccx.ColumnName = c.Column_Name
			   LEFT JOIN dbo.DomainCatalog dc
				 ON dccx.DomainCatalogId = dc.Id) domain
		ON domain.column_name = col.name
	WHERE tab.name IN (' + @DBList + ')
	ORDER BY tab.name, col.column_id'

	INSERT INTO ##DataDictionary
	EXECUTE (@SQL)
END
ELSE IF (@DBList IS NULL)
BEGIN 
	DELETE FROM ##DataDictionary
	INSERT INTO ##DataDictionary
	SELECT tab.name AS 'table name', 
		   col.name AS 'column name',
		   -- The following case function generates the 'data type' column
		   CASE   
				WHEN stype.name = 'varchar' THEN 'varchar (' + CAST(col.max_length AS varchar) + ')'
				WHEN stype.name = 'numeric' THEN 'numeric (' + CAST(col.precision AS varchar(2)) + ',' + CAST(col.scale AS varchar(1)) + ')'
				ELSE stype.name
		   END AS 'data type',
		   -- The following case function generates the 'null' column
		   CASE 
				WHEN col.is_nullable = 0 THEN 'N'
				ELSE 'Y'
		   END AS 'nullable?',
		   -- The following case function generates the 'primary key' column
		   CASE
				WHEN is_primary_key = 1 THEN 'Y'
				ELSE 'N'
		   END 'primary key?',
		   COALESCE(s.name, ' ') AS 'tie entity', 
		   COALESCE(st2.name, ' ') AS 'tie attribute',
		   COALESCE(domain.domain_name, ' ') aS 'domain name'
	FROM sys.tables AS tab
	LEFT JOIN sys.columns col
		ON tab.object_id = col.object_id
	LEFT JOIN sys.types stype
		ON col.user_type_id = stype.user_type_id 
	LEFT JOIN (SELECT indx_col.object_id, indx_col.column_id, indx.is_primary_key 
			   FROM sys.index_columns indx_col
			   LEFT JOIN sys.indexes indx
				ON indx_col.object_id = indx.object_id
				AND indx_col.index_id = indx.index_id
			   WHERE indx_col.index_id = 1) is_primary
		ON is_primary.object_id = col.object_id
		AND is_primary.column_id = col.column_id
	LEFT JOIN sys.foreign_key_columns f_key
		ON f_key.parent_object_id = tab.object_id
		AND col.column_id = f_key.parent_column_id
	LEFT JOIN sys.columns st2
		ON f_key.referenced_object_id = st2.object_id
		AND f_key.referenced_column_id = st2.column_id
	LEFT JOIN sys.tables s
		ON f_key.referenced_object_id = s.object_id 
	LEFT JOIN (SELECT dccx.ColumnName AS column_name, 
					  DomainDescr AS domain_name
			   FROM INFORMATION_SCHEMA.Columns c
			   LEFT JOIN dbo.DomainCatalogColXRef dccx 
				 ON dccx.TableName = c.Table_Name 
				 AND dccx.ColumnName = c.Column_Name
			   LEFT JOIN dbo.DomainCatalog dc
				 ON dccx.DomainCatalogId = dc.Id) domain
		ON domain.column_name = col.name
	ORDER BY tab.name, col.column_id
END

SELECT * FROM ##DataDictionary