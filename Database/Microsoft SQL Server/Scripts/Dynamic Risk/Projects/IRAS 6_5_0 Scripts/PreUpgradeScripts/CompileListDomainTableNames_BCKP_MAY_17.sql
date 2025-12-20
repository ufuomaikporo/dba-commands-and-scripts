USE DrasInternal

DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @DCCXRef_DCId INT
DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('DrasInternal.dbo.ListDomainTableInfo') IS NOT NULL
BEGIN
	DROP TABLE DrasInternal.dbo.ListDomainTableInfo
END

IF OBJECT_ID('tempdb..##LD_DCId') IS NOT NULL
BEGIN
	DROP TABLE ##LD_DCId
END

CREATE TABLE ##LD_DCId (DomainCatalogId INT)

IF OBJECT_ID('DrasInternal.dbo.ListDomainTableInfo') IS NULL
BEGIN
	CREATE TABLE DrasInternal.dbo.ListDomainTableInfo (DBName NVARCHAR(100),
													  TableName NVARCHAR(100), 
													  ColumnName NVARCHAR(100),
													  DomainCatalogId INT,
													  DomainDescr NVARCHAR(MAX),
													  LDTableName NVARCHAR(100),
													  flag BIT)
END

-------------------------- Get info on all list domain tables in the stage databases ------------------

DECLARE DBCursor CURSOR FOR
SELECT name FROM sys.databases
WHERE name NOT LIKE '%LINK%'
AND name NOT LIKE '%CONFIG%'
AND name LIKE '%IRASV6%'

OPEN DBCursor
FETCH NEXT FROM DBCursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'USE ' + @DBName + '
	
	INSERT INTO DrasInternal.dbo.ListDomainTableInfo
	SELECT DB_NAME(),
	   OBJECT_NAME(parent_object_id) AS TableName,		
	   COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
	   NULL AS DomainCatalogId,		
	   NULL AS DomainDescr,		
		   NULL AS LDTableName,
		   0 AS flag
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = ''ListDomain''
	AND OBJECT_NAME(parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
	'

	EXECUTE (@SQL)

	FETCH NEXT FROM DBCursor INTO @DBName
END

CLOSE DBCursor
DEALLOCATE DBCursor

-------------------------------- Flag conflicting tables -----------------------------------

DECLARE FlaggedLDCursor CURSOR FOR
SELECT DBName, TableName, ColumnName 
FROM DrasInternal.dbo.ListDomainTableInfo

OPEN FlaggedLDCursor
FETCH NEXT FROM FlaggedLDCursor INTO @DBName, @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @DCCXRef_DCId = NULL

	SET @SQL = 'USE ' + @DBName + '

	SELECT @Result = DomainCatalogId 
	FROM DomainCatalogColXRef 
	WHERE TableName = ''' + @TableName + ''' 
	AND ColumnName = ''' + @ColumnName + ''''

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @DCCXRef_DCId OUTPUT

	SET @SQL = 'USE ' + @DBName + '

	DECLARE @Result TABLE (DCId INT)
	INSERT INTO @Result
	SELECT DISTINCT DomainCatalogId
	FROM ListDomain WHERE Id IN (SELECT ' + @ColumnName + ' FROM ' + @TableName + ')
	AND DomainCatalogId <> -1
	
	SELECT * FROM @Result'

	TRUNCATE TABLE ##LD_DCId

	INSERT INTO ##LD_DCId
	EXECUTE (@SQL)

	-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
	IF (SELECT COUNT(*) FROM ##LD_DCId) > 1 
	BEGIN
		SET @SQL = 'USE ' + @DBName + '

		UPDATE DrasInternal.dbo.ListDomainTableInfo
		SET DomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') FROM DomainCatalog 
							WHERE Id IN (SELECT DomainCatalogId FROM ##LD_DCId)),
			flag = 1
		WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
		AND ColumnName = ''' + @ColumnName + ''''

		EXECUTE (@SQL)
	END
	-- Flag tables with with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
	ELSE IF (SELECT * FROM ##LD_DCId) <> @DCCXRef_DCId
	BEGIN
		SET @SQL = 'USE ' + @DBName + '

		UPDATE DrasInternal.dbo.ListDomainTableInfo
		SET DomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') FROM DomainCatalog 
							WHERE Id IN ((SELECT DomainCatalogId FROM ##LD_DCId), ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ')),
			flag = 1
		WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
		AND ColumnName = ''' + @ColumnName + ''''

		EXECUTE (@SQL)
	END
	ELSE IF @DCCXRef_DCId IS NOT NULL
	BEGIN
		SET @SQL = 'USE ' + @DBName + '

		UPDATE DrasInternal.dbo.ListDomainTableInfo
		SET DomainCatalogId = ''' + CAST(@DCCXRef_DCId AS NVARCHAR) + ''',
			DomainDescr = (SELECT DomainDescr FROM DomainCatalog WHERE Id = ''' + CAST(@DCCXRef_DCId AS NVARCHAR) + ''')
		WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
		AND ColumnName = ''' + @ColumnName + ''''

		EXECUTE (@SQL)
	END
	ELSE 
	BEGIN
		SET @SQL = 'USE ' + @DBName + '
		
		UPDATE DrasInternal.dbo.ListDomainTableInfo
		SET DomainCatalogId = (SELECT * FROM ##LD_DCId),
			DomainDescr = (SELECT DomainDescr FROM DomainCatalog WHERE Id = (SELECT * FROM ##LD_DCId))
		WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
		AND ColumnName = ''' + @ColumnName + ''''

		EXECUTE (@SQL)
	END

	FETCH NEXT FROM FlaggedLDCursor INTO @DBName, @TableName, @ColumnName
END

CLOSE FlaggedLDCursor
DEALLOCATE FlaggedLDCursor

------------------------------ Generate new ListDomain table names --------------------------------

-- Shared Domain table names
UPDATE DrasInternal.dbo.ListDomainTableInfo 
SET LDTableName = 'GLD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '')
WHERE flag = 0

UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = (CASE WHEN PATINDEX('%_DomainId', ColumnName) > 0
				THEN REPLACE(REPLACE(ColumnName, '_DomainId', ''), 'DomainId', '') 
			WHEN PATINDEX('%Ld', ColumnName) > 0
				THEN REPLACE(ColumnName, 'Ld', '')
			ELSE ColumnName
		END)
WHERE flag = 0 AND DomainDescr IS NULL;

UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName =  REPLACE(TableName, 'IRAS', '') + '_' + LDTableName
WHERE TableName LIKE 'IRASCustomData%'
AND flag = 0 AND DomainDescr IS NULL

UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LDTableName, 'Distribution', 'Distr'), 'Condition', 'Cond'), 'Classification', 'Class'), 'Description', 'Descr'), 'DiscoveryDateUpdateReason', 'DDUR'), 'Coating', 'Coat'), 'PressureAlgorithm', 'PressAlgorthm'), 'Reinforcement', 'Reinforce'), 'Remediation', 'Remed'), 'Service', 'Srvc'), 'CrackAnomaly', 'CA'), 'AxialStrain', 'AX'), 'ILIFeature', 'ILIF_'), 'Internal', 'Int'), 'MetalLoss', 'ML'), 'Fabrication', 'Fab')
WHERE LEN(LDTableName) > 27

UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = 'LD_' + LDTableName
WHERE flag = 0 AND DomainDescr IS NULL;

SELECT * FROM DrasInternal.dbo.ListDomainTableInfo
WHERE flag = 0 --AND DomainCatalogId IS NOT NULL
--and DBName like 'DRAS_IRASv6_DEMO_QA' AND tableName = 'UnitOfMeasure'
ORDER BY DomainCatalogId, TableName, ColumnName

--SELECT DomainDescr, COUNT(LDTableName) FROM DrasInternal.dbo.ListDomainTableInfo
--GROUP BY  DomainDescr
--having count(LDTableName) = 1

--return
--select * from DomainCatalog where DomainDescr like '%Grading%'
--SELECT * FROM DrasInternal.dbo.ListDomainTableInfo
--WHERE flag = 1 order by 1, 2

--select * from DrasInternal.dbo.ListDomainTableInfo where flag = 0 and DomainCatalogId is null order by 1, 2

--select TableName, ColumnName, LDTableName, len(LDTableName) from DrasInternal.dbo.ListDomainTableInfo
--group by TableName, Columnname, LDTableName
--order by len(LDTableName) desc