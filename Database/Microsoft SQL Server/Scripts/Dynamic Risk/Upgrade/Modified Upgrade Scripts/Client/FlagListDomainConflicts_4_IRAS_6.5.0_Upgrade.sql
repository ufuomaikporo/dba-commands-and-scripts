/*

This script is meant to be used on stage or link databases of IRAS version 6.4.2 or lower. The Data_Check_Queries column in the script output contains relevant ListDomain 
and DomainCatalog queries for the flagged tables.

***NOTE*** The Proposed_Solutions column in the script output contains SUGGESTED fixes based on the DomainCatalog and ListDomain information in other databases. Check the proposed solutions
			first before implementing them.

*/

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

DROP TABLE IF EXISTS tmp_VirtualTableDataListDomain
DROP TABLE IF EXISTS CheckVirtualTableData
DROP TABLE IF EXISTS tmp_FlaggedVirtualTables
DROP TABLE IF EXISTS tmp_DomainCatalogConflict
DROP TABLE IF EXISTS tmp_ListDomainTableInfo

SET @DBName = DB_NAME()

IF (SELECT COUNT(*) FROM sys.tables WHERE name IN ('DomainCatalog', 'ListDomain', 'DomainCatalogColXRef')) <> 3
BEGIN
	PRINT CHAR(10) + 'This database is missing one or more of the DomainCatalog, ListDomain, and/or DomainCatalogColXRef tables.'
		+ CHAR(10) + 'These tables are required to run the script'

	RETURN
END

IF OBJECT_ID('tmp_LD_DCId') IS NOT NULL
BEGIN
	DROP TABLE tmp_LD_DCId
END

DROP TABLE IF EXISTS tmp_FlaggedTables

CREATE TABLE tmp_LD_DCId (DomainCatalogId INT)

DROP TABLE IF EXISTS dbo.tmp_ListDomainTableInfo

CREATE TABLE dbo.tmp_ListDomainTableInfo (Id INT IDENTITY(1,1),
										DBName NVARCHAR(100),
										TableName NVARCHAR(100), 
										ColumnName NVARCHAR(100),
										DomainCatalogId INT,
										DomainDescr NVARCHAR(255),													   
										FlaggedDomainDescr NVARCHAR(MAX),
										FlaggedDomainCatalogId NVARCHAR(MAX),
										HasDomainCatalogColXRefEntry CHAR(1) DEFAULT 'N',
										flag BIT)


INSERT INTO dbo.tmp_ListDomainTableInfo
(DBName, TableName, ColumnName, flag)
SELECT 	DB_NAME(),
		OBJECT_NAME(parent_object_id) AS TableName,		
		COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
		0 AS flag
FROM sys.foreign_key_columns 
WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
AND OBJECT_NAME(parent_object_id) NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
	
INSERT INTO dbo.tmp_ListDomainTableInfo (DBName, TableName, ColumnName, flag)
VALUES (DB_Name(), 'POECompanyLookUp', 'MetalLossTypeDomainId', 0)

INSERT INTO dbo.tmp_ListDomainTableInfo (DBName, TableName, ColumnName, flag)
VALUES (DB_Name(),'POECompanyLookUp', 'ToolTypeDomainId', 0)

INSERT INTO dbo.tmp_ListDomainTableInfo (DBName, TableName, ColumnName, flag)
VALUES (DB_Name(), 'Stg_ILICrackAnomaly', 'ILICADepthDomainId', 0)
			

DECLARE FlaggedLDCursor CURSOR FOR
SELECT TableName, ColumnName 
FROM dbo.tmp_ListDomainTableInfo
WHERE DBName = @DBName

OPEN FlaggedLDCursor
FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
			
	SET @DCCXRef_DCId = NULL

---------- Find DomainCatalogId entries in ListDomain and DomianCatalogColXRef tables --------

	-- Check if table and column are in DomainCatalogColXRef table
	SELECT @SQL = 'SELECT @Result = DomainCatalogId
					FROM [' + @DBName + '].dbo.DomainCatalogColXRef 
					WHERE TableName = ''' + @TableName + ''' 
					AND ColumnName = ''' + @ColumnName + ''''; 

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @DCCXRef_DCId OUTPUT

	IF @DCCXRef_DCId IS NOT NULL
	BEGIN
		UPDATE tmp_ListDomainTableInfo SET HasDomainCatalogColXRefEntry = 'Y'
		WHERE TableName = @TableName AND ColumnName = @ColumnName
	END

	-- Find all the distinct DomainCatalogIds in the ListDomain table
	SELECT @SQL = 'SELECT DISTINCT DomainCatalogId
	FROM ' + QUOTENAME(@DBName) + '.[dbo].[ListDomain] 
	WHERE Id IN (SELECT ' + QUOTENAME(@ColumnName) + ' 
					FROM ' + QUOTENAME(@DBName) + '.[dbo].' + QUOTENAME(@TableName) + ')
	AND DomainCatalogId <> -1'; 

		
	TRUNCATE TABLE tmp_LD_DCId

	INSERT INTO tmp_LD_DCId
	EXECUTE (@SQL)	
		
	IF OBJECT_ID ('ListDomain', 'U') IS NOT NULL
	BEGIN
			-- Find all the distinct DomainCatalogIds in the ListDomain table
		SELECT @SQL = 'SELECT DISTINCT DomainCatalogId
		FROM ' + QUOTENAME(@DBName) + '.[dbo].[ListDomain] 
		WHERE Id IN (SELECT ' + QUOTENAME(@ColumnName) + ' 
						FROM ' + QUOTENAME(@DBName) + '.[dbo].' + QUOTENAME(@TableName) + ')
		AND DomainCatalogId <> -1'; 

		INSERT INTO tmp_LD_DCId
		EXECUTE (@SQL)	
	END;

	-- Delete duplicate DomainCatalogIds
	WITH CTE AS
	(SELECT ROW_NUMBER() OVER (PARTITION BY DomainCatalogId ORDER BY DomainCatalogId) AS row_num,
			DomainCatalogId
	FROM tmp_LD_DCId
	) 
	DELETE FROM CTE WHERE row_num > 1
								
------------------- Flag inconsistent DomainCatalogId entries ------------------------
			
	-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
	IF (SELECT COUNT(*) FROM tmp_LD_DCId) > 1 
	BEGIN
		SET @SQL = '
				UPDATE dbo.tmp_ListDomainTableInfo
				SET FlaggedDomainDescr = (SELECT STUFF(
													(SELECT '', '' + DomainDescr
													FROM ' + QUOTENAME(@DBName) + '.dbo.DomainCatalog dc
													JOIN tmp_LD_DCId Temp
														ON Temp.DomainCatalogId = dc.Id
													ORDER BY dc.Id
													FOR XML PATH('''')
													), 1, 2, ''''
												)
									),												  
					FlaggedDomainCatalogId = (SELECT STUFF(
														(SELECT '', '' + CAST(Id AS NVARCHAR)
														FROM ' + QUOTENAME(@DBName) + '.dbo.DomainCatalog dc
														JOIN tmp_LD_DCId Temp
															ON Temp.DomainCatalogId = dc.Id
														ORDER BY dc.Id
														FOR XML PATH('''')
														), 1, 2, ''''
													)
											),
					flag = 1
				WHERE DBName = ''' + @DBName + ''' AND
				TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
	END
	-- Flag tables with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
	ELSE IF (SELECT * FROM tmp_LD_DCId) <> @DCCXRef_DCId
	BEGIN
			
		SET @SQL = '
			UPDATE dbo.tmp_ListDomainTableInfo
			SET FlaggedDomainDescr = (SELECT STUFF(
													(SELECT '', '' + DomainDescr
													FROM ' + QUOTENAME(@DBName) + '.dbo.DomainCatalog dc
													JOIN tmp_LD_DCId Temp
														ON Temp.DomainCatalogId = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
													ORDER BY dc.Id
													FOR XML PATH('''')
													), 1, 2, ''''
												)
									),
				FlaggedDomainCatalogId = (SELECT STUFF(
													(SELECT '', '' + CAST(Id AS NVARCHAR)
													FROM ' + QUOTENAME(@DBName) + '.dbo.DomainCatalog dc
													JOIN tmp_LD_DCId Temp
														ON Temp.DomainCatalogId = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
													ORDER BY dc.Id
													FOR XML PATH('''')
													), 1, 2, ''''
												)
										),
				flag = 1
			WHERE DBName = ''' + @DBName + ''' AND
			TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
	END
	ELSE 
	BEGIN
		IF @DCCXRef_DCId IS NULL
		BEGIN
			SELECT @DCCXRef_DCId = DomainCatalogId FROM tmp_LD_DCId
		END
							
		SET @SQL = '
			UPDATE dbo.tmp_ListDomainTableInfo
			SET DomainCatalogId = subq.Id,
				DomainDescr = subq.DomainDescr
			FROM (SELECT ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ' AS Id,
							DomainDescr
					FROM ' + @DBName + '.[dbo].[DomainCatalog ]
					WHERE Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
				) subq
			WHERE DBName = ''' + @DBName + ''' AND
			TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
	END

	EXECUTE (@SQL)
	
													
	FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName
END
 
CLOSE FlaggedLDCursor
DEALLOCATE FlaggedLDCursor

INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT TableName, ColumnName, DomainCatalogId
FROM tmp_ListDomainTableInfo
WHERE FlaggedDomainDescr IS NULL AND HasDomainCatalogColXRefEntry = 'N'
AND DomainCatalogId IS NOT NULL 
				
SELECT 'Non-Virtual' TableType,
		NULL VirtualTableId,
		NULL AS VirtualColumnId,
		TableName, 
		ColumnName,
		FlaggedDomainCatalogId AS DomainCatalogId,
		FlaggedDomainDescr DomainDescr,
		'SELECT ''------------------ ListDomain Table ------------------''' + CHAR(10) +
		'SELECT * FROM ListDomain WHERE Id IN (SELECT '+ ldi.ColumnName +' FROM ' + ldi.TableName + ') ORDER BY Code, DomainCatalogId' + CHAR(10) +
		'SELECT ''------------------ DomainCatalogColXRef Table ------------------''' + CHAR(10) +
		'SELECT * FROM DomainCatalogColXRef WHERE TableName = ''' + ldi.TableName + ''' AND ColumnName = ''' + ldi.ColumnName + '''' + CHAR(10) +
		'SELECT ''------------------ DomainCatalog Table ------------------''' + CHAR(10) +
		'SELECT * FROM DomainCatalog WHERE Id IN (' + FlaggedDomainCatalogId + ')' AS Queries,		 
		CASE WHEN flag = 1 AND DomainCatalogId IS NULL THEN
		'UPDATE ListDomain SET DomainCatalogId = ' +  CASE WHEN EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName) 
													THEN (SELECT CAST(DomainCatalogId AS NVARCHAR(10)) FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName)
												 ELSE SUBSTRING(FlaggedDomainCatalogId, 0, CASE WHEN CHARINDEX(',', FlaggedDomainCatalogId) = 0 THEN LEN(FlaggedDomainCatalogId) ELSE CHARINDEX(',', FlaggedDomainCatalogId) END)
											END 
		+ ' FROM ListDomain ld JOIN ' + ldi.TableName + ' tab ON tab.' + ldi.ColumnName + ' = ld.Id'
		+ ' WHERE ld.DomainCatalogId <> ' + CASE WHEN EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName) 
													THEN (SELECT CAST(DomainCatalogId AS NVARCHAR(10)) FROM DomainCatalogColXRef WHERE TableName = ldi.TableName AND ColumnName = ldi.ColumnName)
												 ELSE SUBSTRING(FlaggedDomainCatalogId, 0, CASE WHEN CHARINDEX(',', FlaggedDomainCatalogId) = 0 THEN LEN(FlaggedDomainCatalogId) ELSE CHARINDEX(',', FlaggedDomainCatalogId) END)
											END
				WHEN flag = 0 AND DomainCatalogId IS NULL THEN '--Add a DomainCatalog and DomainCatalogColXRef entry'
				END
		  AS Proposed_Solution,
		  CAST (NULL AS VARCHAR(MAX)) AS VirtualTableComment,
		  CAST (NULL AS VARCHAR(MAX)) AS VirtualColumnComment
INTO tmp_FlaggedTables
FROM tmp_ListDomainTableInfo ldi
WHERE (flag = 1 OR DomainCatalogId IS NULL)
AND TableName NOT IN ('PointChar')
AND TableName NOT LIKE 'Risk%'
AND ColumnName NOT LIKE 'Field[_]%' 
AND NOT EXISTS (SELECT * FROM DomainCatalogColXRef dcxr 
WHERE dcxr.TableName = ldi.TableName AND dcxr.ColumnName = ldi.ColumnName)

SELECT DISTINCT vc.Id VirtualColumnId,
					vc.VirtualColumnName,
					vt.Id VirtualTableId,
					vt.VirtualTableName,
					CASE WHEN dcxr.DomainCatalogId IS NOT NULL THEN dcxr.DomainCatalogId ELSE ld.DomainCatalogId END AS DomainCatalogId,
					CASE WHEN dcxr.DomainCatalogId IS NOT NULL THEN (SELECT DomainDescr FROM DomainCatalog WHERE Id = dcxr.DomainCatalogId) 
						 ELSE (SELECT DomainDescr FROM DomainCatalog WHERE Id = ld.DomainCatalogId) 
					END AS DomainDescr, 
					vt.VirtualTableComment,
					vc.VirtualColumnComment
			INTO tmp_VirtualTableDataListDomain 
			FROM VirtualTableDataListDomain vtld
			JOIN ListDomain ld
				ON vtld.DataFieldValueDomainId = ld.Id
			RIGHT JOIN VirtualTable vt
				ON vt.Id = vtld.VirtualTableId
			RIGHT JOIN VirtualColumn vc
				ON vc.VirtualTableId = vt.Id
			LEFT JOIN DomainCatalogcolXRef dcxr 
				ON dcxr.TableName = vt.VirtualTableName
				AND dcxr.ColumnName = vc.VirtualColumnName
			WHERE vc.VirtualColumnDataTypeInd = 'L'

INSERT INTO tmp_FlaggedTables
SELECT DISTINCT 'Virtual',
	 VirtualTableId, 
	 VirtualColumnId, 
	 VirtualTableName, 
	 VirtualColumnName,
	 STUFF(
				(SELECT ', ' + CAST(DomainCatalogId AS VARCHAR)
				FROM tmp_VirtualTableDataListDomain vt 
				WHERE vtld1.VirtualTableId = vt.VirtualTableId
				AND vtld1.VirtualColumnId = vt.VirtualColumnId
				FOR XML PATH(N''), TYPE
				).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
			),
	 STUFF(
				(SELECT ', ' + DomainDescr
				FROM DomainCatalog 
				WHERE Id IN (SELECT DomainCatalogId FROM tmp_VirtualTableDataListDomain vt 
				  WHERE vtld1.VirtualTableId = vt.VirtualTableId
				  AND vtld1.VirtualColumnId = vt.VirtualColumnId)
				FOR XML PATH(N''), TYPE
				).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
			),
NULL,
CASE WHEN DomainCatalogId IS NULL THEN '--Add Missing DomainCatalog Reference'
WHEN (SELECT COUNT(DomainCatalogId) FROM tmp_VirtualTableDataListDomain vtld2
									WHERE vtld1.VirtualTableName = vtld2.VirtualTableName
									AND vtld1.VirtualColumnName = vtld2.VirtualColumnName)> 1
	THEN '--More than 1 DomainCatalog found'
END AS FlaggedReason,
VirtualTableComment, 
VirtualColumnComment
FROM tmp_VirtualTableDataListDomain vtld1
WHERE VirtualColumnComment <> 'DO NOT USE' AND (DomainCatalogId IS NULL OR (SELECT COUNT(DomainCatalogId) FROM tmp_VirtualTableDataListDomain vtld2
									WHERE vtld1.VirtualTableName = vtld2.VirtualTableName
									AND vtld1.VirtualColumnName = vtld2.VirtualColumnName) > 1)
AND NOT EXISTS (SELECT * FROM DomainCatalogColXRef dcxr 
WHERE dcxr.TableName = vtld1.VirtualTableName AND dcxr.ColumnName = vtld1.VirtualColumnName)

UPDATE tmp_FlaggedTables
SET Proposed_Solution =  'IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = ''' + ldti.DomainDescr + ''')
			BEGIN
			INSERT INTO DomainCatalog(Id, DomainDescr) ' 
			+ 'SELECT MAX(Id) + 1,''' + ldti.DomainDescr + ''' FROM DomainCatalog
			END'  + CHAR(10) +
			'IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = ''' + ldi.TableName + ''' AND ColumnName = ''' + ldi.ColumnName + ''')
			BEGIN
				INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
				SELECT ''' + ldi.TableName + ''',  ''' + ldi.ColumnName + ''', Id
				FROM DomainCatalog WHERE DomainDescr = ''' + ldti.DomainDescr + '''
			END'
FROM tmp_FlaggedTables ldi
JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldti
ON ldti.TableName = ldi.TableName AND ldti.ColumnName = ldi.ColumnName

IF EXISTS (SELECT * FROM tmp_FlaggedTables)
BEGIN
	SET @SQL = '
	IF OBJECT_ID(''tempdb..##FlaggedTables_' + CAST(@@SPID AS NVARCHAR) + ''') IS NOT NULL
	BEGIN
		DROP TABLE ##FlaggedTables_' + CAST(@@SPID AS NVARCHAR) + '
	END

	SELECT *
	INTO ##FlaggedTables_' + CAST(@@SPID AS NVARCHAR) + '
	FROM tmp_FlaggedTables 

	SELECT ''------------- Fix the Following DomainCatalog Conflicts ----------------''
	SELECT * FROM ##FlaggedTables_' + CAST(@@SPID AS NVARCHAR) + '
	ORDER BY TableType DESC, TableName'

	PRINT @SQL
	EXECUTE (@SQL)
END;

WITH CTE AS 
(SELECT DISTINCT ld.Id ListDomainId, VirtualTableName, VirtualColumnName, 
ld.DomainCatalogId [DomainCatalogId from ListDomain table]
, dc.DomainDescr [DomainDescr from ListDomain table], 
dcxr.DomainCatalogId [DomainCatalogId from DomainCatalogColXRef table],
dc2.DomainDescr [DomainDescr from DomainCatalogColXRef table]
FROM VirtualTableDataListDomain vtld
JOIN ListDomain ld ON ld.Id = vtld.DataFieldValueDomainId
JOIN VirtualTable vt ON vt.Id = vtld.VirtualTableId
JOIN VirtualColumn vc ON vc.Id = vtld.VirtualColumnId AND vc.VirtualTableId = vtld.VirtualTableId
JOIN DomainCatalog dc ON dc.Id = ld.DomainCatalogId
JOIN DomainCatalogColXRef dcxr ON dcxr.TableName = vt.VirtualTableName AND dcxr.ColumnName = vc.VirtualColumnName
JOIN DomainCatalog dc2 ON dc2.Id = dcxr.DomainCatalogId
)
SELECT * INTO tmp_DomainCatalogConflict
FROM CTE t1
WHERE EXISTS (SELECT * FROM CTE t2
WHERE t1.VirtualTableName = t2.VirtualTableName
AND t1.VirtualColumnName = t2.VirtualColumnName 
AND [DomainCatalogId from DomainCatalogColXRef table] <> [DomainCatalogId from ListDomain table]
AND [DomainCatalogId from ListDomain table] <> -1)

IF EXISTS (SELECT * FROM tmp_DomainCatalogConflict)
BEGIN
	SELECT '------------- Fix the Following DomainCatalog Conflicts for the Specified VirtualTables ---------------------'
	SELECT * FROM tmp_DomainCatalogConflict
END

IF EXISTS (SELECT * FROM ListDomain WHERE Code IS NULL OR Descr IS NULL)
BEGIN
	SELECT '----------- The Code and Descr Columns of the ListDomain Table Cannot Have NULL Values --------------'
	SELECT ld.Id, DomainCatalogId, DomainDescr, Code, Descr, SourceDomainId, ld.LastModByUserId, ld.LastModDateTime
	FROM ListDomain ld
	JOIN DomainCatalog dc ON ld.DomainCatalogId = dc.Id  WHERE Code IS NULL OR Descr IS NULL
END

IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code IS NULL OR Descr IS NULL) AND NOT EXISTS (SELECT * FROM tmp_FlaggedTables)
AND NOT EXISTS (SELECT * FROM tmp_DomainCatalogConflict)
BEGIN
	PRINT CHAR(10) + 'There are no ListDomain or DomainCatalog conflict'
END

SET @SQL = NULL
SELECT DISTINCT @SQL = COALESCE(@SQL + CHAR(10), '') + 'DROP TABLE ' + name 
FROM sys.tables WHERE name LIKE 'tmp[_]%'

EXECUTE (@SQL)

