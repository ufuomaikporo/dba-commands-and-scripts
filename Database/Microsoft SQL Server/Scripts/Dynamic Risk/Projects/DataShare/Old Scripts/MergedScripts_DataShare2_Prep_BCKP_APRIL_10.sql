USE tmp_DATASHARE2

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TargetTable NVARCHAR(100)
DECLARE @TargetDB NVARCHAR(100) = DB_NAME()

--*******************************************************************************
-- CLEANUP DATABASE - delete data and views
--********************************************************************************

------------------------------------- Drop views ---------------------------------

WHILE EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables WHERE table_type = 'VIEW')
BEGIN
	SELECT @SQL = 'DROP VIEW ' + table_name FROM 
	INFORMATION_SCHEMA.tables WHERE table_type = 'VIEW'
	
	EXECUTE (@SQL)

END

------------------------------- Delete data from tables --------------------------------

BEGIN TRANSACTION
	DECLARE TruncateTab_Cursor CURSOR FOR
	SELECT 'DELETE FROM ' + table_name FROM INFORMATION_SCHEMA.tables
	WHERE table_name NOT LIKE 'History[_]%'

	OPEN TruncateTab_Cursor
	FETCH NEXT FROM TruncateTab_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM TruncateTab_Cursor INTO @SQL
	END

	CLOSE TruncateTab_Cursor
	DEALLOCATE TruncateTab_Cursor
COMMIT TRANSACTION

--*******************************************************************************************
-- PREP DATABASE (Create Stored procedures and tables)
--*******************************************************************************************

-------------------------------- Add Client_Code column to tables  -------------------------

DECLARE AddClientCode_Cursor CURSOR FOR
SELECT 
    'ALTER TABLE dbo.[' + TABLE_NAME + '] ADD Client_Code  varchar(100) NULL;'
FROM 
    INFORMATION_SCHEMA.TABLES Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.TABLE_NAME
            AND Col.COLUMN_NAME='Client_Code'
    )
AND table_name NOT LIKE 'History[_]%' 
AND table_type = 'BASE_TABLE'

OPEN AddClientCode_Cursor
FETCH NEXT FROM AddClientCode_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddClientCode_Cursor INTO @SQL
END

CLOSE AddClientCode_Cursor
DEALLOCATE AddClientCode_Cursor

---------------------------------- Add OriginalID column to all tables ---------------------------

DECLARE AddOriginalId_Cursor CURSOR FOR
SELECT 
    'ALTER TABLE dbo.[' + TABLE_NAME + '] ADD OriginalID  int NULL;'
FROM 
    INFORMATION_SCHEMA.TABLES Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.TABLE_NAME
            AND Col.COLUMN_NAME='OriginalID'
    )
AND table_name NOT LIKE 'History[_]%' 
AND table_type = 'BASE TABLE'


OPEN AddOriginalId_Cursor
FETCH NEXT FROM AddOriginalId_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddOriginalId_Cursor INTO @SQL
END

CLOSE AddOriginalId_Cursor
DEALLOCATE AddOriginalId_Cursor
GO


------------------------------ Create/Re-Create fn_ScriptColumnsList function ----------------------

CREATE OR ALTER FUNCTION dbo.fn_ScriptColumnsList
(
	@tableName VARCHAR(200)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

	DECLARE @sql NVARCHAR(MAX) = ''

	DECLARE  @ColumnsList AS TABLE (columnId INT, 
											columnName VARCHAR(200) , 
											referencedTable VARCHAR(200) , 
											referencedColumn VARCHAR(200) , 
											columnText VARCHAR(300))


	INSERT INTO @ColumnsList
	SELECT DISTINCT column_id, c.name, referencedTable, referencedColumn, columnText = 't.[' + name + ']'
    FROM sys.columns c
	LEFT JOIN foreignKeys k on c.name = k.columnName AND  k.tableName  = @tableName
	WHERE  object_id = object_id( @tableName)
	ORDER BY column_id

	UPDATE @ColumnsList
	SET columnText = CASE columnName 
						WHEN 'ID' THEN 'Id = ROW_NUMBER() OVER(ORDER BY  (SELECT 1) )'
						WHEN 'OriginalID'  THEN '[OriginalID] = null'
						WHEN 'CreatedDate' THEN 'isnull(t.CreatedDate, t.LastModDateTime)'
						WHEN 'CreatedUser' THEN 'isnull(t.CreatedUser, t.LastModByUserId)'
						ELSE columnText
						END

	IF EXISTS (SELECT 1 FROM @ColumnsList WHERE columnName = 'id')
	BEGIN
		UPDATE @ColumnsList
		SET columnText =  'OriginalID = t.id'
		WHERE columnName = 'OriginalID' 
	END

	UPDATE @ColumnsList
	SET columnText = CASE referencedTable
							WHEN 'ListDomain' then 	columnName + ' = '  + columnName +'NewLD.ID '
							ELSE +' [ref' + referencedTable + columnName + '].[' + referencedColumn + ']' 
							END
	WHERE referencedTable IS NOT NULL

	SELECT @sql = STRING_AGG(columnText, ', ') WITHIN GROUP (ORDER BY columnId)
	FROM
	(SELECT columnId, 
		   columnName,
		   columnText,
		   ROW_NUMBER() OVER (PARTITION BY columnName ORDER BY columnId, referencedTable) AS rownum
	FROM @ColumnsList
	) subq	
	WHERE rownum = 1

	RETURN @sql

END
GO


------------------------- Create/Re-Create dbo.fn_ScriptJoins Function ---------------------

CREATE OR ALTER FUNCTION dbo.fn_ScriptJoins
(
	@tableName VARCHAR(200)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	 
	DECLARE @sql VARCHAR(MAX) = ''

	DECLARE @columnsList as table (columnName VARCHAR(200) , referencedTable VARCHAR(200) , referencedColumn VARCHAR(200) , processed bit)

	INSERT INTO @columnsList
	SELECT columnName, referencedTable, referencedColumn, 0
	FROM foreignKeys
	WHERE  tableName = @tableName

	DECLARE @columnName VARCHAR(200), @referencedTable VARCHAR(200), @referencedColumn VARCHAR(200)
	while exists (SELECT 1 FROM @columnsList WHERE processed = 0)
	BEGIN
		SELECT top 1 @columnName = columnName , @referencedTable = referencedTable, @referencedColumn = referencedColumn
		FROM @columnsList WHERE processed = 0
		
		UPDATE @columnsList SET processed = 1 WHERE columnName = @columnName

		IF @referencedTable = 'ListDomain'
		BEGIN
		SET @sql = @sql + '
			LEFT JOIN @OrgLD '+ @columnName +'OrgLD    
				ON t.'+ @columnName +' = '+ @columnName +'OrgLD.Id 
				AND t.Client_Code = '+ @columnName +'OrgLD.Client_Code 

			LEFT JOIN @NewDomains '+ @columnName +'NewLD 
				ON lower('+ @columnName +'NewLD.Code) = lower('+ @columnName +'OrgLD .Code)
				AND '+ @columnName +'NewLD.ColumnName = ''' + @columnName + ''' 
		'
		END
		ELSE
		BEGIN
		SET @sql = @sql + '
			LEFT JOIN '+ @referencedTable +' ref' + @referencedTable + @columnName + ' with (nolock)  
				ON t.'+ @columnName +' =  ref' + @referencedTable + @columnName + '.OriginalID
				AND t.Client_Code =  ref' + @referencedTable + @columnName + '.Client_Code
		'
		END
	END
	RETURN @sql

END
GO

------------------------------- Re-Create/Create Foreign Keys Table ----------------------------------

DECLARE @databaseName NVARCHAR(250), @sql NVARCHAR(max)
SELECT TOP 1 @databaseName =  name  FROM sys.databases
WHERE name LIKE 
( 
SELECT TOP 1 Client_Code + '%_Stage'  FROM DATASHARE.dbo.VersionInfo
ORDER by VersionInfo.DBVersion DESC
)

IF OBJECT_ID(N'dbo.foreignKeys', N'U') IS NOT NULL  
BEGIN
   DROP TABLE dbo.foreignKeys;
END

SET @sql = '
SELECT 
	tab1.name AS tableName,
    col1.name AS columnName,
    sch.name AS referencedTableSchemaName,
    tab2.name AS referencedTable,
    col2.name AS referencedColumn
INTO dbo.foreignKeys
FROM ' + @databaseName + '.sys.foreign_key_columns fkc
INNER JOIN ' + @databaseName + '.sys.objects obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN ' + @databaseName + '.sys.tables tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN ' + @databaseName + '.sys.columns col1
    ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN ' + @databaseName + '.sys.tables tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN ' + @databaseName + '.sys.schemas sch
    ON tab2.schema_id = sch.schema_id
INNER JOIN ' + @databaseName + '.sys.columns col2
    ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
ORDER by tableName, columnName 
'

EXECUTE sp_executesql @sql
 
--------------------------- Create/Re-Create dbo.sp_LoadTable Stored Procedure -----------------------

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_LoadTable
@tableName NVARCHAR(250)
AS
BEGIN

DECLARE @sql NVARCHAR(max) =''
DECLARE @SelectColumns varchar(2000) 

SELECT @sql =  @sql +
'ALTER INDEX ' + i.name + ' ON  ' + o.name + ' DISABLE;' +CHAR(13)+CHAR(10)
FROM 
    sys.indexes i
JOIN 
    sys.objects  o
    ON i.object_id = o.object_id
WHERE i.type_desc = 'NONCLUSTERED'
  AND o.type_desc = 'USER_TABLE'
  AND o.name = @tableName
PRINT @sql
EXEC(@sql);

SET @sql = ''
IF EXISTS ( SELECT 1 FROM foreignKeys WHERE tableName = @tableName AND referencedTable = 'ListDomain')
BEGIN
SET @sql = @sql + '
	DECLARE  @OrgLD  table ( id int , code varchar(200), client_code varchar(200)  )
	INSERT INTO @OrgLD SELECT id , code , client_code FROM datashare.dbo.ListDomain

	DECLARE @NewDomains table
	(ColumnName	varchar(50)   ,Id int	   ,  Code varchar(50)  )

	INSERT INTO @NewDomains
	SELECT DISTINCT
		ColumnName	   ,ld.Id	   ,upper(ld.Code) Code 
	FROM DATASHARE.dbo.ListDomain ld with (nolock)  
	INNER JOIN DATASHARE.dbo.DomainCatalogColXRef dx with (nolock)  
		on ld.DomainCatalogId = dx.DomainCatalogId  
	WHERE Tablename = ''' + @tableName +  '''
	ORDER BY ColumnName	   ,code;
	'
END

SET @sql = @sql + CHAR(13) + CHAR(10) + ' 

--TRUNCATE TABLE ' + @tableName + ' 

 IF EXISTS ( SELECT 1 WHERE   OBJECTPROPERTY(OBJECT_ID(''' + @tableName + '''), ''TableHasIdentity'') = 1)
	SET identity_insert ' + @tableName + ' on


INSERT INTO ' + @tableName + '( 
'
+ (SELECT STRING_AGG( '[' + name + ']',',') WITHIN GROUP (ORDER BY column_id)
FROM sys.columns
WHERE is_computed = 0 AND  OBJECT_NAME(object_id) = @tableName
)
+

'
)
SELECT    ' + dbo.fn_ScriptColumnsList (@tableName) + ' 
FROM datashare.dbo.' + @tableName + ' as t'

SET @sql = @sql + dbo.fn_ScriptJoins(@tableName)
SET @sql += CHAR(10) + 'WHERE NOT EXISTS (SELECT * FROM ' + @tableName + ')'

PRINT @sql
EXEC sp_executesql @sql;

SET @sql = ''
SELECT @sql =  @sql +
'ALTER INDEX ' + i.name + ' ON  ' + o.name + ' REBUILD;' +CHAR(13)+CHAR(10)
FROM 
    sys.indexes i
JOIN 
    sys.objects  o
    ON i.object_id = o.object_id
WHERE i.type_desc = 'NONCLUSTERED'
  AND o.type_desc = 'USER_TABLE'
  AND o.name = @tableName
  AND i.is_unique_constraint = 0
PRINT @sql
EXEC(@sql);
 
END
GO

------------------------------ Recreate DataShareTablesList Tables ---------------------

IF OBJECT_ID('dbo.DataShareTablesList') IS NOT NULL
BEGIN
	DROP TABLE dbo.DataShareTablesList
END

SELECT name AS TableName, CAST('1' AS BIT) AS Enabled
INTO dbo.DataShareTablesList
FROM Base_IRASv6_STAGE.sys.tables
WHERE name NOT LIKE 'STG[_]%' AND name NOT LIKE 'DBS[_]%' 
AND name NOT LIKE 'History[_]%' AND name NOT LIKE 'H[_]%' 
AND name NOT LIKE 'i[_]%' AND name NOT LIKE 'RISK%'
AND name NOT LIKE 'Load[_]%' -- AND name NOT LIKE 'VirtualTable%'
AND name NOT LIKE 'tmp%'
AND name NOT IN ('Connection', 'ConnectionType', 'DisplayField', 'ScriptTracker', 
'CategoryDataListDomainXRef', 'DomainCatalog', 'DomainCatalogColXRef')
AND name NOT IN (SELECT DISTINCT referencedTable 
							FROM foreignKeys
							WHERE referencedTable in (SELECT DISTINCT
									object_name(c1.object_id) --, c1.name , c2.name 
								FROM sys.columns c1
								inner join sys.columns c2
									on c1.object_id = c2.object_id
								WHERE c1.name = 'Code'
								AND c2.name = 'Descr')
				) 