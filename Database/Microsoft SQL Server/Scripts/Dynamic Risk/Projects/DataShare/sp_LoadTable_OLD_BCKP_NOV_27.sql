DECLARE @TableName NVARCHAR(100) = 'InlineInspectionJoint'--'Bend'
DECLARE @SQL NVARCHAR(MAX) =''
DECLARE @SelectColumns VARCHAR(2000) 
DECLARE @MissingData INT

SET @SQL = 'SELECT @Result = COUNT(*) from DATASHARE.dbo.' + @TableName+'
WHERE NOT EXISTS (SELECT * FROM ' + @TableName + ')'

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @MissingData OUTPUT

IF (@MissingData > 0)
BEGIN

	SELECT @SQL = 
	'ALTER INDEX ' + i.name + ' ON ' + o.name + ' DISABLE;' +CHAR(13)+CHAR(10)
	FROM 
		sys.indexes i
	JOIN 
		sys.objects  o
		ON i.object_id = o.object_id
	WHERE i.type_desc = 'NONCLUSTERED'
	  AND o.type_desc = 'USER_TABLE'
	  AND o.name = @TableName

	IF EXISTS ( SELECT 1 FROM ForeignKeys WHERE tableName = @TableName AND referencedTable = 'ListDomain')
	BEGIN
	SET @SQL += '
		DECLARE  @OrgLD  table ( id int , code VARCHAR(200), client_code VARCHAR(200)  )
		INSERT INTO @OrgLD SELECT id , code , client_code FROM DATASHARE.dbo.ListDomain

		DECLARE @NewDomains table
		(ColumnName	VARCHAR(50)   ,Id int	   ,  Code VARCHAR(50)  )

		INSERT INTO @NewDomains
		SELECT DISTINCT
			ColumnName	   ,ld.Id	   ,UPPER(ld.Code) Code 
		FROM DATASHARE.dbo.ListDomain ld WITH (NOLOCK)  
		INNER JOIN DATASHARE.dbo.DomainCatalogColXRef dx WITH (NOLOCK)  
			ON ld.DomainCatalogId = dx.DomainCatalogId  
		WHERE Tablename = ''' + @TableName +  '''
		ORDER BY ColumnName	   ,code;'
	END

	SET @SQL +=   
	'IF EXISTS (SELECT 1 WHERE   OBJECTPROPERTY(OBJECT_ID(''' + @TableName + '''), ''TableHasIdentity'') = 1)
	BEGIN
		SET IDENTITY_INSERT ' + @TableName + ' ON
	END' + CHAR(10) + CHAR(10)

	SET @SQL += ISNULL('ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + (SELECT name FROM sys.key_constraints
														WHERE OBJECT_NAME(parent_object_id) = @TableName AND type = 'PK'), '')

	SET @SQL += CHAR(10) + '
	TRUNCATE TABLE ' + @TableName +'

	INSERT INTO ' + @TableName +' (' + (SELECT '[' + STRING_AGG(name, '], [') WITHIN GROUP (ORDER BY column_id) + ']' FROM sys.columns 
						WHERE OBJECT_NAME(object_id) = @TableName) + ')
	SELECT    ' + dbo.fn_ScriptColumnsList (@TableName) + ' 
	FROM DATASHARE.dbo.' + @TableName + ' as t'

	BEGIN TRY
		PRINT @SQL
		EXECUTE (@SQL);
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	SET @SQL =
	'--Recreate the primary key on the Id column
	IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE OBJECT_NAME(parent_object_id) = ''' + @TableName + ''' AND type = ''PK'')
	BEGIN
		ALTER TABLE ' + @TableName + ' ALTER COLUMN [Id] ' + (SELECT t.name + '(' + CAST(c.precision AS NVARCHAR) + ', ' + CAST(c.scale AS NVARCHAR) + ')' FROM
		sys.columns c JOIN sys.types t	ON c.system_type_id = t.system_type_id
		WHERE OBJECT_NAME(object_id) = @TableName AND c.name = 'Id') + ' NOT NULL;
		ALTER TABLE ' + @TableName + ' ADD CONSTRAINT PK_' + @TableName + ' PRIMARY KEY (Id);
	END' + CHAR(10) + CHAR(10) 

	SELECT @SQL += 
	'ALTER INDEX ' + i.name + ' ON ' + o.name + ' REBUILD;' +CHAR(13)+CHAR(10)
	FROM 
		sys.indexes i
	JOIN 
		sys.objects  o
		ON i.object_id = o.object_id
	WHERE i.type_desc = 'NONCLUSTERED'
	  AND o.type_desc = 'USER_TABLE'
	  AND o.name = @TableName
	  AND i.is_unique_constraint = 0
	PRINT @SQL
	EXECUTE (@SQL);
END

--SELECT 1 FROM sys.key_constraints WHERE OBJECT_NAME(parent_object_id) = 'InlineInspectionJoint' AND type = 'PK'
--sp_columns InlineInspectionJoint
