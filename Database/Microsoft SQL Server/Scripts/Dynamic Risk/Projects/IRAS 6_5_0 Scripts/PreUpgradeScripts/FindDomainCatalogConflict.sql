DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @DCCXRef_DCId INT
DECLARE @LD_DCId TABLE (DomainCatalogId INT)
DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('tempdb..##FlaggedListDomains') IS NOT NULL
BEGIN
	DROP TABLE ##FlaggedListDomains
END

SELECT OBJECT_NAME(parent_object_id) AS TableName,
		COL_NAME(parent_object_id, parent_column_id) AS ColumnName,
		CAST(NULL AS NVARCHAR(MAX)) AS DomainCatalogId,
		CAST(NULL AS NVARCHAR(MAX)) AS DomainDescr,
		0 AS flag
INTO ##FlaggedListDomains
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
AND OBJECT_NAME(parent_object_id) NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
--and  OBJECT_NAME(parent_object_id) = 'RiskCalcScoreTableValue'
--and COL_NAME(parent_object_id, parent_column_id) = 'RCVARIABLESCORESOURCEDOMAINIDY'

DECLARE FlaggedLDCursor CURSOR FOR
SELECT TableName, ColumnName FROM ##FlaggedListDomains

OPEN FlaggedLDCursor
FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN

	DELETE FROM @LD_DCId
	SET @DCCXRef_DCId = NULL

	SELECT @DCCXref_DCId = DomainCatalogId 
	FROM DomainCatalogColXRef 
	WHERE TableName = @TableName AND ColumnName = @ColumnName

	SET @SQL = 'DECLARE @Result TABLE (DCId INT)
	INSERT INTO @Result
	SELECT DISTINCT DomainCatalogId
	FROM ListDomain WHERE Id IN (SELECT ' + @ColumnName + ' FROM ' + @TableName + ')
	AND DomainCatalogId <> -1
	
	SELECT * FROM @Result'

	INSERT INTO @LD_DCId
	EXECUTE (@SQL)

	-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
	IF (SELECT COUNT(*) FROM @LD_DCId) > 1 
	BEGIN
		UPDATE ##FlaggedListDomains
		SET DomainCatalogId = (SELECT STRING_AGG(DomainCatalogId, ', ') FROM @LD_DCId),
			DomainDescr = (SELECT STRING_AGG(DomainDescr, ', ') FROM DomainCatalog 
							WHERE Id IN (SELECT DomainCatalogId FROM @LD_DCId)),
			flag = 1
		WHERE TableName = @TableName AND ColumnName = @ColumnName
	END
	-- Flag tables with with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
	ELSE IF (SELECT * FROM @LD_DCId) <> @DCCXRef_DCId
	BEGIN
		UPDATE ##FlaggedListDomains
		SET DomainCatalogId = (SELECT CAST(DomainCatalogId AS VARCHAR) FROM @LD_DCId) + ', ' + CAST(@DCCXRef_DCId AS VARCHAR),
			DomainDescr = (SELECT STRING_AGG(DomainDescr, ', ') FROM DomainCatalog 
							WHERE Id IN (SELECT DomainCatalogId FROM @LD_DCId)),
			flag = 1
		WHERE TableName = @TableName AND ColumnName = @ColumnName
	END
	ELSE IF @DCCXRef_DCId IS NOT NULL
	BEGIN
		UPDATE ##FlaggedListDomains
		SET DomainCatalogId = @DCCXRef_DCId
		WHERE TableName = @TableName AND ColumnName = @ColumnName
	END
	ELSE 
	BEGIN
		UPDATE ##FlaggedListDomains
		SET DomainCatalogId = (SELECT * FROM @LD_DCId)
		WHERE TableName = @TableName AND ColumnName = @ColumnName
	END


	FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName
END

CLOSE FlaggedLDCursor
DEALLOCATE FlaggedLDCursor

SELECT * FROM ##FlaggedListDomains
WHERE flag = 1 or DomainCatalogId IS NULL ORDER BY 3, 1

