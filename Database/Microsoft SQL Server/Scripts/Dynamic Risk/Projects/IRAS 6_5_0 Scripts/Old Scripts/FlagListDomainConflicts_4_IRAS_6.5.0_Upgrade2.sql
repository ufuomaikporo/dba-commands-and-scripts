

DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @DCCXRef_DCId INT
DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Type NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)
DECLARE @RecreateTable INT 
DECLARE @ServerList NVARCHAR(MAX)
DECLARE @ObjectExists INT

SET @DBName = DB_NAME()

IF OBJECT_ID('tempdb..##LD_DCId') IS NOT NULL
BEGIN
	DROP TABLE ##LD_DCId
END

CREATE TABLE ##LD_DCId (DomainCatalogId INT)

DROP TABLE IF EXISTS dbo.##ListDomainTableInfo

CREATE TABLE dbo.##ListDomainTableInfo (Id INT IDENTITY(1,1),
										DBName NVARCHAR(100),
										TableName NVARCHAR(100), 
										ColumnName NVARCHAR(100),
										DomainCatalogId INT,
										DomainDescr NVARCHAR(255),													   
										FlaggedDomainDescr NVARCHAR(MAX),
										FlaggedDomainCatalogId NVARCHAR(MAX),
										flag BIT)

BEGIN TRANSACTION

	INSERT INTO dbo.##ListDomainTableInfo
	(DBName, TableName, ColumnName, flag)
	SELECT 	DB_NAME(),
			OBJECT_NAME(parent_object_id) AS TableName,		
			COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
			0 AS flag
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
	AND OBJECT_NAME(parent_object_id) NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
	
	INSERT INTO dbo.##ListDomainTableInfo (DBName, TableName, ColumnName, flag)
	VALUES (DB_Name(), 'POECompanyLookUp', 'MetalLossTypeDomainId', 0)

	INSERT INTO dbo.##ListDomainTableInfo (DBName, TableName, ColumnName, flag)
	VALUES (DB_Name(),'POECompanyLookUp', 'ToolTypeDomainId', 0)

	INSERT INTO dbo.##ListDomainTableInfo (DBName, TableName, ColumnName, flag)
	VALUES (DB_Name(), 'Stg_ILICrackAnomaly', 'ILICADepthDomainId', 0)
			
COMMIT TRANSACTION

DECLARE FlaggedLDCursor CURSOR FOR
SELECT TableName, ColumnName 
FROM dbo.##ListDomainTableInfo
WHERE DBName = @DBName

OPEN FlaggedLDCursor
FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
			
	SET @DCCXRef_DCId = NULL

---------- Find DomainCatalogId entries in ListDomain and DomianCatalogColXRef tables --------

	BEGIN TRANSACTION
		-- Check if table and column are in DomainCatalogColXRef table
		SELECT @SQL = 'SELECT @Result = DomainCatalogId
						FROM [' + @DBName + '].dbo.DomainCatalogColXRef 
						WHERE TableName = ''' + @TableName + ''' 
						AND ColumnName = ''' + @ColumnName + ''''; 

		EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @DCCXRef_DCId OUTPUT
			
		-- Find all the distinct DomainCatalogIds in the ListDomain table
		SELECT @SQL = 'SELECT DISTINCT DomainCatalogId
		FROM ' + QUOTENAME(@DBName) + '.[dbo].[ListDomain] 
		WHERE Id IN (SELECT ' + QUOTENAME(@ColumnName) + ' 
						FROM ' + QUOTENAME(@DBName) + '.[dbo].' + QUOTENAME(@TableName) + ')
		AND DomainCatalogId <> -1'; 

		
		TRUNCATE TABLE ##LD_DCId

		INSERT INTO ##LD_DCId
		EXECUTE (@SQL)	
		
		IF OBJECT_ID ('ListDomain', 'U') IS NOT NULL
		BEGIN
				-- Find all the distinct DomainCatalogIds in the ListDomain table
			SELECT @SQL = 'SELECT DISTINCT DomainCatalogId
			FROM ' + QUOTENAME(@DBName) + '.[dbo].[ListDomain] 
			WHERE Id IN (SELECT ' + QUOTENAME(@ColumnName) + ' 
							FROM ' + QUOTENAME(@DBName) + '.[dbo].' + QUOTENAME(@TableName) + ')
			AND DomainCatalogId <> -1'; 

			INSERT INTO ##LD_DCId
			EXECUTE (@SQL)	
		END;

		-- Delete duplicate DomainCatalogIds
		WITH CTE AS
		(SELECT ROW_NUMBER() OVER (PARTITION BY DomainCatalogId ORDER BY DomainCatalogId) AS row_num,
				DomainCatalogId
		FROM ##LD_DCId
		) 
		DELETE FROM CTE WHERE row_num > 1

	COMMIT TRANSACTION
								
------------------- Flag inconsistent DomainCatalogId entries ------------------------

	BEGIN TRANSACTION
			
		-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
		IF (SELECT COUNT(*) FROM ##LD_DCId) > 1 
		BEGIN
			SET @SQL = '
					UPDATE dbo.##ListDomainTableInfo
					SET FlaggedDomainDescr =  subq.DomainDescr,												  
						FlaggedDomainCatalogId = subq.Id,
						flag = 1
					FROM (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') As Id,
									STRING_AGG(DomainDescr, '', '') As DomainDescr
							FROM [' + @DBName + '].dbo.DomainCatalog dc
							JOIN ##LD_DCId Temp
							ON Temp.DomainCatalogId = dc.Id
						) AS subq
					WHERE DBName = ''' + @DBName + ''' 
					AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
		END
		-- Flag tables with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
		ELSE IF (SELECT * FROM ##LD_DCId) <> @DCCXRef_DCId
		BEGIN
			
			SET @SQL = '
				UPDATE dbo.##ListDomainTableInfo
				SET FlaggedDomainDescr = subq.DomainDescr,
					FlaggedDomainCatalogId = subq.Id,
					flag = 1
				FROM (SELECT STRING_AGG(DomainDescr, '', '') AS DomainDescr,
								STRING_AGG(CAST(Id AS NVARCHAR), '', '') AS Id
						FROM [' + @DBName + '].dbo.DomainCatalog dc
						JOIN ##LD_DCId temp
						ON dc.Id = temp.DomainCatalogId OR dc.Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
					) subq
				WHERE DBName = ''' + @DBName + ''' 
				AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
		END
		ELSE 
		BEGIN
			IF @DCCXRef_DCId IS NULL
			BEGIN
				SELECT @DCCXRef_DCId = DomainCatalogId FROM ##LD_DCId
			END
							
			SET @SQL = '
				UPDATE dbo.##ListDomainTableInfo
				SET DomainCatalogId = subq.Id,
					DomainDescr = subq.DomainDescr
				FROM (SELECT ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ' AS Id,
								DomainDescr
						FROM ' + @DBName + '.[dbo].[DomainCatalog ]
						WHERE Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
					) subq
				WHERE DBName = ''' + @DBName + ''' 
				AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		END

		EXECUTE (@SQL)
		
	COMMIT TRANSACTION
													
	FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName
END

CLOSE FlaggedLDCursor
DEALLOCATE FlaggedLDCursor
					
SELECT TableName, 
		ColumnName,
		FlaggedDomainCatalogId,
		FlaggedDomainDescr,
		'SELECT * FROM ListDomain WHERE Id IN (SELECT '+ ldi.ColumnName +' FROM ' + ldi.TableName + ')' + CHAR(10) +
		'SELECT * FROM DomainCatalogColXRef WHERE TableName = ''' + ldi.TableName + ''' AND ColumnName = ''' + ldi.ColumnName + '''' + CHAR(10) +
		'SELECT * FROM DomainCatalog WHERE Id IN (' + FlaggedDomainCatalogId + ')' + CHAR(10) +
		'SELECT DISTINCT ld.* FROM ListDomain ld JOIN ' + ldi.TableName + ' tab ON tab.' + ldi.ColumnName + ' = ld.Id'
		+ ' WHERE ld.DomainCatalogId <> ' + CASE WHEN EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName) 
													THEN (SELECT CAST(DomainCatalogId AS NVARCHAR(10)) FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName)
												 ELSE SUBSTRING(FlaggedDomainCatalogId, 0, CHARINDEX(',', FlaggedDomainCatalogId))
											END AS CheckQueries	,
		'INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
		VALUES(, ''' + ldi.TableName + ''', ''' + ldi.ColumnName + ''')' AS Fix
FROM ##ListDomainTableInfo ldi
WHERE flag = 1 AND TableName NOT IN ('PointChar')
AND NOT EXISTS (SELECT * FROM DomainCatalogColXRef dcxref 
WHERE dcxref.TableName = ldi.TableName AND dcxref.ColumnName = ldi.ColumnName)





