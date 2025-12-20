/*

This script compiles a list of new list domain table names prefixed with either 'LD_' or 'GLD_'. The 'GLD_' 
prefixed tables are for referencing tables that share ListDomain data or referencing tables with ListDomain
data that can be traced to a single DomainCatalogId. The 'LD' prefixed tables are for referencing tables that 
do not have ListDomain data or a known DomainCatalogId from the DomainCatalogColXRef table.

Tables that have conflicting DomainCatalogIds have a flag of 1 and the conflicting DomainCatalogIds and DomainDescr
are listed in the DomainCatalogId and FlaggedDomainCatalogId columns.

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
DECLARE @RecreateTable INT 

---------------------------------------------------------------------------------------------------------------------

--Set the @Type to "All" to cycle through multiple servers. Leave blank to only use the current server

SET @Type = ''

-- If set to '0' it will only execute the LDTable naming portion (faster), if set to '1' it will recreate the ListDomainTableInfo table 
SET @RecreateTable = 0

-- The target Server ust be a server with a database named DrasInternal where the ListDomainInfo table will be created
SET @TargetServer = ''

---------------------------------------------------------------------------------------------------------------------
BEGIN TRAN
	IF (@RecreateTable = 1)
	BEGIN
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
															   LDTableName NVARCHAR(100),
															   DomainCatalogId INT,
															   DomainDescr NVARCHAR(255),													   
															   FlaggedDomainDescr NVARCHAR(MAX),
															   FlaggedDomainCatalogId NVARCHAR(MAX),
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
						(ServerName, DBName, TableName, ColumnName, flag)
						SELECT ''''' + @ServerName + ''''',
								DB_NAME(),
								OBJECT_NAME(parent_object_id) AS TableName,		
								COL_NAME(parent_object_id, parent_column_id) AS ColumnName,	
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
						(ServerName, DBName, TableName, ColumnName, flag)
						SELECT ''' + @ServerName + ''',
								DB_NAME(),
								OBJECT_NAME(parent_object_id) AS TableName,		
								COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
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
								SET FlaggedDomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') 
												   FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
													WHERE Id IN (SELECT DomainCatalogId FROM ##LD_DCId)),
									FlaggedDomainCatalogId = (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') 
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
								SET FlaggedDomainDescr = (SELECT STRING_AGG(DomainDescr, '', '') 
													FROM [' + @ServerName + '].[' + @DBName + '].dbo.DomainCatalog 
													WHERE Id IN ((SELECT DomainCatalogId FROM ##LD_DCId), ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ')
												  ),
									FlaggedDomainCatalogId = (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') 
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
								(ServerName, DBName, DomainCatalogId, DomainDescr, flag)
								SELECT DISTINCT ''''' + @ServerName + ''''',
										''''' + @DBName + ''''',
										ld.DomainCatalogId,
										dc.DomainDescr,
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
								(ServerName, DBName, DomainCatalogId, DomainDescr, flag)
								SELECT DISTINCT ''' + @ServerName + ''',
										''' + @DBName + ''',
										ld.DomainCatalogId,
										dc.DomainDescr,
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

	END 
	---------------------------------- Generate new ListDomain table names --------------------------------

	-- Use the ColumnName to name the LD tables removing '_DomainId' and 'Ld' from new LD name
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = NULL

	-------------------------------------- Intentionally Group LD tables ------------------------------------------
	/*
	Force the 'CoatingCondLineTypeLd' column of the 'CoatingCondition' table and any other table with a column name
	'CoatingCondLineTypeLD', 'CoatingLineDomainId' to share the same Listdomain table as the 
	'CoatingTypeDomainId' column of the 'Coating' table
	*/
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = 'LD_CoatingLine'
	WHERE ColumnName IN ('CoatingCondLineTypeLD', 'CoatingLineDomainId')
	OR DomainDescr LIKE 'Coating%Line%Type%' OR DomainDescr LIKE 'Coating%Type%Line%'

	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = 'LD_CoatingConditionLineFound'
	WHERE  ColumnName LIKE 'CoatingCond%LineFound%' OR DomainDescr LIKE 'Coating%Cond%Line%Found%'

	-- Tables with the following Domain Descriptions should share the same LD table named after the DomainDescr
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '') 
	WHERE DomainDescr IN ('State / Province Name', 'ILI Status', 'Pipe Material',
		'Failure Pressure Algorithm', 'Coordinate System', 'Classification Type', 
		'ILI Defect Status', 'ILI Crack Depth', 'Damage Type', 'Hydro Test Status', 'Repair Method',
		'Shutdown Profile', 'Operating Profile', 'Strain Direction', 'LineLoopType', 'Valve Type',
		'ILI Crack Anomaly Type', 'ILI Call Box Interaction rule')
	 
	-- Tables with the 'ILI Type' and 'ILI Tool' DomainDescr should share the same LD table
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_ILIToolType'
	WHERE DomainDescr IN ('ILI Type', 'ILI Tool')
	OR ColumnName = 'ToolTypeDomainId'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_FailurePressureAlgorithm'
	WHERE ColumnName LIKE '%Fail%Press%Al%' OR ColumnName LIKE 'ILIFPA%' 

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_ClassAreaRating'
	WHERE ColumnName LIKE '%ClassAreaRating%' OR ColumnName LIKE '%ClassRating%'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName =  'LD_CoordinateSystem'
	WHERE ColumnName LIKE '%CoordSys%' 

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_ILIFacilityType'
	WHERE ColumnName LIKE 'ILI%FacType%' OR DomainDescr LIKE 'ILI%Fac%Type%'
	--AND ColumnName NOT IN ('ListDomainId')

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_ILINonCorrosionDefect'
	WHERE DomainDescr LIKE 'ILI%Non%Corrosion%Defect%'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE
			WHEN DomainDescr LIKE 'ILI%Feature%Grading%2%' OR DomainDescr LIKE '%ILINCDGrading%2%' OR DomainDescr LIKE 'ILI%Feature%Criteria%'
				THEN 'LD_ILIGrading2'
			WHEN DomainDescr LIKE 'ILI%Feature%Grading%' OR DomainDescr LIKE '%ILINCDGrading%1%' OR DomainDescr LIKE 'ILI%Feature%Response%'
				THEN 'LD_ILIGrading1'
			WHEN DomainDescr LIKE '%Mechanical%Damage%Grading%1%' THEN 'LD_MechanicalDamageGrading1'
			WHEN DomainDescr LIKE '%Mechanical%Damage%Grading%2%' THEN 'LD_MechanicalDamageGrading2'
			WHEN DomainDescr LIKE '%ILI%Crack%Grading%1%' THEN 'LD_ILICrackGrading1'
			WHEN DomainDescr LIKE '%ILI%Crack%Grading%2%' THEN 'LD_ILICrackGrading2'
			WHEN DomainDescr LIKE 'CFR%Grading%' THEN 'LD_CFRGrading'
		END
	WHERE DomainDescr LIKE '%Grading%' 
	OR DomainDescr LIKE 'ILI%Feature%'


	-- Use the same naming convention for all IRASCustom tables
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName =  'LD_' + TableName + '_' + REPLACE(ColumnName, '_DomainId', '')
	WHERE TableName LIKE 'IRAS%'
	AND flag = 0 

	-- Match a table-column without an LD table name with similarly named table-column
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1 
	JOIN (SELECT TableName, ColumnName, LDTableName FROM DrasInternal.dbo.ListDomainTableInfo) tab2
		ON tab1.ColumnName = tab2.ColumnName
		AND tab1.TableName = tab2.TableName
		AND tab2.LDTableName IS NOT NULL
	WHERE tab1.LDTableName IS NULL 
	AND tab1.ColumnName NOT IN ('ListDomainId')

	-- Match Table by columnName
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1 
	JOIN (SELECT TableName, ColumnName, LDTableName FROM DrasInternal.dbo.ListDomainTableInfo) tab2
		ON tab1.ColumnName = tab2.ColumnName
		AND tab2.LDTableName IS NOT NULL
	WHERE tab1.LDTableName IS NULL 
	AND tab1.ColumnName NOT IN ('ListDomainId')

	-- For rows with null values for TableName and TableColumn, try to match the DomainDescr to a row with a known LD table name
	UPDATE  DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName =  tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1
	JOIN (SELECT DomainDescr, LDTableName 
		  FROM DrasInternal.dbo.ListDomainTableInfo ) tab2
	ON tab1.DomainDescr = tab2.DomainDescr
	AND tab2.LDTableName IS NOT NULL
	WHERE tab1.TableName IS NULL

	-- Use the DomainDescr for the new LD table name for rows with null values in the TableName and ColumnName columns
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName =  'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '')
	WHERE LDTableName IS NULL AND TableName IS NULL

	-- Any remaining rows with a NULL value for LDTableName will be named using the ColumnName
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE 
				WHEN ColumnName = 'ListDomainId' THEN 'LD_ListDomainValues'
				WHEN PATINDEX('%_DomainId', ColumnName) > 0
					THEN 'LD_' + REPLACE(REPLACE(ColumnName, '_DomainId', ''), 'DomainId', '') 
				WHEN PATINDEX('%Ld', ColumnName) > 0
					THEN 'LD_' + REPLACE(ColumnName, 'Ld', '')
				ELSE 'LD_' + ColumnName
			END
	WHERE LDTableName IS NULL AND TableName IS NOT NULL

	-- Shorten names
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LDTableName, 'Distribution', 'Distr')
	, 'Condition', 'Cond'), 'Classification', 'Class'), 'Description', 'Descr'), 'DiscoveryDateUpdateReason', 'DDUR')
	, 'Coating', 'Coat'), 'PressureAlgorithm', 'PressAlgorthm'), 'Reinforcement', 'Reinforce'), 'Remediation', 'Remed'), 'Service', 'Srvc'), 'CrackAnomaly', 'CA'), 'AxialStrain', 'AX'), 'ILIFeature', 'ILIF_'), 'Internal', 'Int'), 'MetalLoss', 'ML'), 'Fabrication', 'Fab')
	, 'Exposure', 'Expose'), 'Direction', 'Dirxn'), 'DesignClassRating', 'DCRating'), 'ClassAreaRating', 'CARating'), 'Source', 'Src'), 'Interference', 'int'), 'Methodology', 'Method'), 'Temperature', 'Temp'), 'Crossing', 'Crx'), 'Mitigation', 'Mitgtn'), 'Experience', 'Exp'), 'Collection', 'Collect')
	, 'OperatingTemp', 'OperTemp'), 'DesignAssessment', 'DesignAssess'), 'SpecialPermitingSentencingAreaSegment','SpecialPermitAreaSeg'),'InitialPrioritization', 'InitialPriority'),'NearNeutral', 'Neutrl'),'InspectionAge', 'InspecAge')
	, 'TotalDissolvedSolidsand', 'DsolveSolid'), 'OxygenContamination','OxygContamin'), 'ChemicalInhibitionProgram', 'ChemInhibitProg'), 'ErosiveFactors','Erossion')
	WHERE LEN(LDTableName) > 30 

COMMIT TRAN
