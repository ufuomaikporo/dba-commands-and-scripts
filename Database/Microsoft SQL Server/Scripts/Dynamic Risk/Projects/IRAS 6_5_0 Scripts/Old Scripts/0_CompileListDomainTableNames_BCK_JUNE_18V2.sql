/*

This script compiles a list of new list domain table names prefixed with either 'LD_' or 'GLD_'. The 'GLD_' 
prefixed tables are for referencing tables that share ListDomain data or referencing tables with ListDomain
data that can be traced to a single DomainCatalogId. The 'LD' prefixed tables are for referencing tables that 
do not have ListDomain data or a known DomainCatalogId from the DomainCatalogColXRef table.

Tables that have conflicting DomainCatalogIds have a flag of 1 and the conflicting DomainCatalogIds and DomainDescr
are listed in the DomainCatalogId and FlaggedDCId columns.

This script can be made to collect the information mentioned above only for the current server where the script
is being executed or on multiple servers. If it is being executed for multiple servers set @Type = 'All' and
make sure to run it on SQL2019

*/
USE DrasInternal

DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @DCCXRef_DCId INT
DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Type NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)
DECLARE @TargetServer NVARCHAR(100) 

---------------------------------------------------------------------------------------------------------------------

--Set the @Type to "All" to cycle through multiple servers. Leave blank to only use the current server

SET @Type = ''

-- The target Server ust be a server with a database named DrasInternal where the ListDomainInfo table will be created
SET @TargetServer = ''
---------------------------------------------------------------------------------------------------------------------

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
	CREATE TABLE DrasInternal.dbo.ListDomainTableInfo (Id INT IDENTITY(1,1),
													   ServerName NVARCHAR(100),
													   DBName NVARCHAR(100),
													   TableName NVARCHAR(100), 
													   ColumnName NVARCHAR(100),
													   DomainCatalogId INT,
													   DomainDescr NVARCHAR(MAX),													   
													   LDTableName NVARCHAR(100),
													   FlaggedDCId NVARCHAR(MAX),
													   flag BIT)
END

IF @TargetServer = '' OR @TargetServer IS NULL
BEGIN
	SET @TargetServer = @@SERVERNAME
END

IF (@Type = 'All')
BEGIN
	SET @SQL = 'DECLARE ServerList_Cursor CURSOR FOR
	SELECT TOP 1 name FROM ' + @TargetServer + '.DrasInternal.dbo.Servers 
	WHERE name LIKE ''%SQL%'' AND name NOT LIKE ''%TEST%''
	AND name NOT IN (''CTSQL01.DRAS.LOCAL'', ''SQL2016\LATIN1_GENERAL'', ''DRASSQL2022'', ''PAA-SQL01'', ''SQL2019DEV'', ''SQL2014'')'

	EXECUTE (@SQL)
END
ELSE
BEGIN
	SET @SQL = 'DECLARE ServerList_Cursor CURSOR FOR
	SELECT ''' + @@SERVERNAME + ''''

	EXECUTE (@SQL)
END

OPEN ServerList_Cursor
FETCH NEXT FROM ServerList_Cursor INTO @ServerName

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @ServerName

-------------------------- Get info on all list domain tables in the stage databases ------------------
	IF OBJECT_ID('tempdb..##DBList') IS NOT NULL
	BEGIN
		DROP TABLE ##DBList
	END

	CREATE TABLE ##DBList (name NVARCHAR(100))
	
	SET @SQL = 'INSERT INTO ##DBList 
	SELECT name
	FROM [' + @ServerName + '].master.sys.databases
	WHERE name NOT LIKE ''%LINK%''
	AND name NOT LIKE ''%CONFIG%''
	AND name LIKE ''%IRASV6%'''	

	EXECUTE (@SQL)

	DECLARE DBCursor CURSOR FOR
	SELECT name FROM ##DBList

	OPEN DBCursor
	FETCH NEXT FROM DBCursor INTO @DBName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		IF OBJECT_ID (@DBName + '..ListDomain', 'U') IS NOT NULL
		BEGIN
			-- if the server in curent loop iteration is not the server the script is running on, execute command with linked server
			IF @ServerName <> @@SERVERNAME 
			BEGIN
				SET @SQL = '
				EXECUTE (''
				USE [' + @DBName + ']

				INSERT INTO [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
				SELECT ''''' + @ServerName + ''''',
						DB_NAME(),
						OBJECT_NAME(parent_object_id) AS TableName,		
						COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
						NULL AS DomainCatalogId,	
						NULL AS DomainDescr,	
						NULL AS LDTableName,
						NULL AS FlaggedDCId,
						0 AS flag
				FROM sys.foreign_key_columns 
				WHERE OBJECT_NAME(referenced_object_id) = ''''ListDomain''''
				AND OBJECT_NAME(parent_object_id) NOT IN (''''RememberedListDomainValues'''', ''''VirtualTableDataListDomain'''', ''''ActionItemPropDCXRef'''', ''''CategoryDataListDomainXRef'''')
				'') AT [' + @ServerName + ']'
			END
			ELSE 
			BEGIN
				SET @SQL = '

				USE [' + @DBName + ']

				INSERT INTO [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
				SELECT ''' + @ServerName + ''',
						DB_NAME(),
						OBJECT_NAME(parent_object_id) AS TableName,		
						COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
						NULL AS DomainCatalogId,	
						NULL AS DomainDescr,	
						NULL AS LDTableName,
						NULL AS FlaggedDCId,
						0 AS flag
				FROM sys.foreign_key_columns 
				WHERE OBJECT_NAME(referenced_object_id) = ''ListDomain''
				AND OBJECT_NAME(parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')'
			END
		
			EXECUTE (@SQL)

			---------------------------------- Flag tables with conflicting DomainCatalogIds -----------------------------------

			DECLARE FlaggedLDCursor CURSOR FOR
			SELECT TableName, ColumnName 
			FROM DrasInternal.dbo.ListDomainTableInfo
			WHERE DBName = @DBName

			OPEN FlaggedLDCursor
			FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				SET @DCCXRef_DCId = NULL

				SET @SQL = '
				SELECT @Result = DomainCatalogId 
				FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalogColXRef 
				WHERE TableName = ''' + @TableName + ''' 
				AND ColumnName = ''' + @ColumnName + ''''
				EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @DCCXRef_DCId OUTPUT

				SET @SQL = '
				DECLARE @Result TABLE (DCId INT)

				INSERT INTO @Result
				SELECT DISTINCT DomainCatalogId
				FROM [' + @ServerName + '].[' + @DBName + '].dbo.ListDomain 
				WHERE Id IN (SELECT ' + @ColumnName + ' 
								FROM [' + @ServerName + '].[' + @DBName + '].dbo.' + @TableName + ')
				AND DomainCatalogId <> -1
	
				SELECT * FROM @Result'

				TRUNCATE TABLE ##LD_DCId

				INSERT INTO ##LD_DCId
				EXECUTE (@SQL)

				-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
				IF (SELECT COUNT(*) FROM ##LD_DCId) > 1 
				BEGIN
					SET @SQL = '
					BEGIN TRANSACTION
						UPDATE DrasInternal.dbo.ListDomainTableInfo
						SET DomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') 
										   FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
											WHERE Id IN (SELECT DomainCatalogId FROM ##LD_DCId)),
							FlaggedDCId = (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') 
										FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
										WHERE Id IN (SELECT DomainCatalogId FROM ##LD_DCId)),
							flag = 1
						WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
						AND ColumnName = ''' + @ColumnName + '''
					COMMIT TRANSACTION'

					EXECUTE (@SQL)
		
				END
				-- Flag tables with with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
				ELSE IF (SELECT * FROM ##LD_DCId) <> @DCCXRef_DCId
				BEGIN
					SET @SQL = '
					BEGIN TRANSACTION
						UPDATE DrasInternal.dbo.ListDomainTableInfo
						SET DomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') 
											FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
											WHERE Id IN ((SELECT DomainCatalogId FROM ##LD_DCId), ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ')
										  ),
							FlaggedDCId = (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') 
										 FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
										 WHERE Id IN ((SELECT DomainCatalogId FROM ##LD_DCId), ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ')
										 ),
							flag = 1
						WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
						AND ColumnName = ''' + @ColumnName + '''
					COMMIT TRANSACTION'

					EXECUTE (@SQL)
		
				END
				ELSE IF @DCCXRef_DCId IS NOT NULL
				BEGIN
					SET @SQL = '
					BEGIN TRANSACTION
						UPDATE DrasInternal.dbo.ListDomainTableInfo
						SET DomainCatalogId = ''' + CAST(@DCCXRef_DCId AS NVARCHAR) + ''',
							DomainDescr = (SELECT DomainDescr 
											FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
											WHERE Id = ''' + CAST(@DCCXRef_DCId AS NVARCHAR) + ''')
						WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
						AND ColumnName = ''' + @ColumnName + '''
					COMMIT TRANSACTION'

					EXECUTE (@SQL)
				END
				ELSE 
				BEGIN
					SET @SQL = '
					BEGIN TRANSACTION
						UPDATE DrasInternal.dbo.ListDomainTableInfo
						SET DomainCatalogId = (SELECT * FROM ##LD_DCId),
							DomainDescr = (SELECT DomainDescr 
											FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
											WHERE Id = (SELECT * FROM ##LD_DCId))
						WHERE DBName = ''' + @DBName + ''' AND TableName = ''' + @TableName + ''' 
						AND ColumnName = ''' + @ColumnName + '''
					COMMIT TRANSACTION'

					EXECUTE (@SQL)
				END

				FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName
			END

			CLOSE FlaggedLDCursor
			DEALLOCATE FlaggedLDCursor

		------------ Add DomainCatalogIds in ListDomain table that are not associated with any other table ------------------------------
	
			-- if the server in curent loop iteration is not the server the script is running on, execute command with linked server
			IF @ServerName <> @@SERVERNAME
			BEGIN
				SET @SQL = '
				EXECUTE (''

						USE [' + @DBName + ']

						INSERT INTO [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
						SELECT DISTINCT ''''' + @ServerName + ''''',
								''''' + @DBName + ''''',
								NULL AS TableName,
								NULL AS ColumnName,
								ld.DomainCatalogId,
								dc.DomainDescr,
								NULL AS LDTableName,
								NULL AS FlaggedDCId,
								0 AS flag
						FROM dbo.DomainCatalog dc
						JOIN ListDomain ld
							ON dc.Id = ld.DomainCatalogId
						WHERE ld.DomainCatalogId <> -1	
						AND DomainDescr NOT IN (SELECT DomainDescr FROM [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
													WHERE DomainDescr IS NOT NULL AND DBName = ''''' + @DBName + ''''' AND ServerName = ''''' + @ServerName + ''''')
					'') AT [' + @ServerName + ']'
			END
			ELSE
			BEGIN
					SET @SQL = '
						USE [' + @DBName+ ']

						INSERT INTO [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
						SELECT DISTINCT ''' + @ServerName + ''',
								''' + @DBName + ''',
								NULL AS TableName,
								NULL AS ColumnName,
								ld.DomainCatalogId,
								dc.DomainDescr,
								NULL AS LDTableName,
								NULL AS FlaggedDCId,
								0 AS flag
						FROM dbo.DomainCatalog dc
						JOIN ListDomain ld
							ON dc.Id = ld.DomainCatalogId
						WHERE ld.DomainCatalogId <> -1	
						AND DomainDescr NOT IN (SELECT DomainDescr FROM [' + @TargetServer + '].[DrasInternal].dbo.ListDomainTableInfo
													WHERE DomainDescr IS NOT NULL AND DBName = ''' + @DBName + ''' AND ServerName = ''' + @ServerName + ''')'
			END

			EXECUTE (@SQL)
		END

		FETCH NEXT FROM DBCursor INTO @DBName
	END

	CLOSE DBCursor
	DEALLOCATE DBCursor

	FETCH NEXT FROM ServerList_Cursor INTO @ServerName
END

CLOSE ServerList_Cursor
DEALLOCATE ServerList_Cursor

------------------------------ Generate new ListDomain table names --------------------------------

-- Remove special characters from names
UPDATE DrasInternal.dbo.ListDomainTableInfo 
SET LDTableName = 'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '')
WHERE (flag = 0 OR flag IS NULL) AND DomainDescr IS NOT NULL

-- Remove '_DomainId' and 'Ld' from name
UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = (CASE WHEN PATINDEX('%_DomainId', ColumnName) > 0
				THEN REPLACE(REPLACE(ColumnName, '_DomainId', ''), 'DomainId', '') 
			WHEN PATINDEX('%Ld', ColumnName) > 0
				THEN REPLACE(ColumnName, 'Ld', '')
			ELSE ColumnName
		END)
WHERE flag = 0 AND DomainDescr IS NULL;

-- Shorten names
UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName =  REPLACE(TableName, 'IRAS', '') + '_' + LDTableName
WHERE TableName LIKE 'IRASCustomData%'
AND flag = 0 AND DomainDescr IS NULL

-- Shorten names
UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LDTableName, 'Distribution', 'Distr')
, 'Condition', 'Cond'), 'Classification', 'Class'), 'Description', 'Descr'), 'DiscoveryDateUpdateReason', 'DDUR')
, 'Coating', 'Coat'), 'PressureAlgorithm', 'PressAlgorthm'), 'Reinforcement', 'Reinforce'), 'Remediation', 'Remed'), 'Service', 'Srvc'), 'CrackAnomaly', 'CA'), 'AxialStrain', 'AX'), 'ILIFeature', 'ILIF_'), 'Internal', 'Int'), 'MetalLoss', 'ML'), 'Fabrication', 'Fab')
, 'Exposure', 'Expose'), 'Direction', 'Dirctn'), 'DesignClassRating', 'DCRating'), 'ClassAreaRating', 'CARating'), 'Source', 'Src'), 'Interference', 'int'), 'Methodology', 'Method'), 'Temperature', 'Temp'), 'Crossing', 'Crx'), 'Mitigation', 'Mitgtn'), 'Experience', 'Exp'), 'Collection', 'Collect')
WHERE LEN(LDTableName) > 27 AND flag = 0

-- Add 'LD_' prefix to table names
UPDATE DrasInternal.dbo.ListDomainTableInfo
SET LDTableName = 'LD_' + LDTableName
WHERE LDTableName IS NOT NULL
AND LDTableName NOT LIKE 'LD[_]%';

-- Find DomainDescr for tables that are missing one but share same TableName and ColumnName as tables with a DomainDescr
UPDATE  DrasInternal.dbo.ListDomainTableInfo 
SET LDTableName = Tab2.LDTableName,
	DomainDescr = Tab2.DomainDescr
FROM DrasInternal.dbo.ListDomainTableInfo tab1
JOIN (SELECT  * FROM DrasInternal.dbo.ListDomainTableInfo 
		WHERE DomainDescr IS NOT NULL
		AND flag = 0) tab2
ON tab1.ColumnName = tab2.ColumnName
AND tab1.TableName = tab2.TableName
WHERE tab1.DomainDescr IS NULL 
AND tab1.TableName NOT LIKE 'IRASCustom%'


----Rename tables that have the same ListDomain table name as Global Listdomain tables (GLD tables)
--UPDATE DrasInternal.dbo.ListDomainTableInfo
--SET LDTableName = REPLACE(LDTableName, 'LD_', 'GLD_')
--WHERE LDTableName IN (SELECT LDTableName 
--					  FROM (SELECT LDTableName, COUNT(*) AS cnt
--							FROM DrasInternal.dbo.ListDomainTableInfo
--							WHERE LDTableName IS NOT NULL
--							GROUP BY LDTableName 
--							HAVING COUNT(*) > 1
--							) subq
--					)

				
 
