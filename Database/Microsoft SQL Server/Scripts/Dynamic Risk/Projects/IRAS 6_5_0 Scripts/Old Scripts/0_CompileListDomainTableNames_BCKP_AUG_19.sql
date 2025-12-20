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

	-- Specify the LD table name for the given Column names 
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE
						WHEN ColumnName LIKE 'ILI%FacType%' OR DomainDescr LIKE 'ILI%Fac%Type%' THEN 'LD_ILIFacilityType'
						WHEN ColumnName LIKE 'CoatingCond%LineFound%' OR DomainDescr LIKE 'Coating%Cond%Line%Found%'
							THEN 'LD_CoatingConditionLineFound'
						WHEN ColumnName = 'ValveTypeLD' THEN 'LD_ValveType'
						WHEN ColumnName = 'DesignClassRatingDomainId' THEN 'LD_DesignClassRating'
					  	WHEN ColumnName LIKE '%Fail%Press%Al%' OR ColumnName LIKE 'ILIFPA%' 
							THEN 'LD_FailurePressureAlgorithm'
						WHEN ColumnName LIKE '%ClassAreaRating%' OR ColumnName LIKE '%ClassRating%'
							THEN 'LD_ClassAreaRating'
						WHEN ColumnName LIKE '%CoordSys%' THEN 'LD_CoordinateSystem'
						WHEN ColumnName LIKE 'FrostAreaRangeLD' THEN 'LD_FrostAreaRange'
					  END
	WHERE LDTableName IS NULL
	AND ColumnName NOT IN ('ListDomainId')

	-- Specify the LD table name for the given Domain Descriptions
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE 
						WHEN DomainDescr LIKE '%Seismic%' THEN 'LD_SeismicArea'
						WHEN DomainDescr LIKE '%Crack%Anomaly%Type' THEN 'LD_ILICrackAnomalyType' 
						WHEN DomainDescr LIKE 'ILI%Non%Corrosion%Defect%' THEN 	'LD_ILINonCorrosionDefect'
						WHEN DomainDescr LIKE 'ACVG%Anom%Indication%Type' THEN  'LD_ACVGAnomalyIndicationType'
						WHEN DomainDescr LIKE 'Soil%Environment%' OR DomainDescr LIKE 'Soil%Topography%' OR DomainDescr = 'Soil Land Use'
							THEN 'LD_SoilTopography'
						WHEN DomainDescr LIKE '%Hurricane%Rank%' THEN 'LD_HurricaneRanking'
						WHEN DomainDescr LIKE '%Flood%Area%' OR DomainDescr LIKE '%Flooding%Rank%' OR DomainDescr LIKE '%OF%Flood%' THEN 'LD_FloodAreaRange'
						WHEN DomainDescr IN ('Mechanical Damage Defect Type', 'Repair Method') THEN 'LD_RepairMethod'
						WHEN DomainDescr LIKE '%Lightning%' THEN 'LD_LightningStrikeDensity'
						WHEN DomainDescr LIKE '%Line%Loop%Type%'  THEN 'LD_LineLoopProductType'
						WHEN DomainDescr IN ('Incident Type', 'Classification Type') THEN 'LD_IncidentType'
						WHEN DomainDescr LIKE 'Incident Status' THEN 'LD_IncidentStatus'
						WHEN DomainDescr IN ('ILI Tool', 'ILI Type') THEN 'LD_ILIToolType'
						WHEN DomainDescr LIKE 'ILI Facility Status' THEN 'LD_ILIFacilityStatus'
						WHEN DomainDescr LIKE 'HCA Type' THEN 'LD_HCAType'
						WHEN DomainDescr LIKE '%Frost%Depth%' OR DomainDescr LIKE '%Frost%Area%' THEN 'LD_FrostAreaRange'
						WHEN DomainDescr LIKE 'Fabrication Connection Type' THEN 'LDFabricationConnectionType'
						WHEN DomainDescr LIKE 'Excavation Site Crack Anomaly Status' THEN 'LD_ExcavationSiteCrackAnomalyStatus'
						WHEN DomainDescr LIKE 'District / Division Name' THEN 'LD_DistrictDivisionName'
						WHEN DomainDescr LIKE 'Distribution Service Head Susceptibility' THEN 'LD_DistrSrvcHeadSusceptibility'
						WHEN DomainDescr LIKE 'ILICB%Fail%Pres%Alg%' THEN 'LD_FailurePressureAlgorithm'
						WHEN DomainDescr LIKE 'Incident%Sever%' THEN 'LD_IncidentSeverity'
						WHEN DomainDescr LIKE 'Coating%Line%' THEN 'LD_CoatingLineType'
					END
	WHERE LDTableName IS NULL 

	-- Tables with the following Domain Descriptions should be named based on the DomainDescr
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '') 
	WHERE DomainDescr IN ('State / Province Name', 'ILI Status', 'Pipe Material',
		'Failure Pressure Algorithm', 'Coordinate System', 'Classification Type', 
		'ILI Defect Status', 'ILI Crack Depth', 'Damage Type', 'Hydro Test Status', 'Repair Method',
		'Operating Profile', 'Strain Direction', 
		'ILI Call Box Interaction rule', 'ACVG Reading Severity Classification',
		'ACVG Severity Type', 'Area Name', 'Axial Strain Available Analysis Type', 
		'Coating Condition - Application Type', 'Coating Condition - Weld Type', 'Coating Type - Internal',
		'Coating Type - Weld', 'Datum', 'DCVG Anomaly Indication', 'EF Equipment Condition',
		'Soil Macro Environment', 'DCVG Anomaly Severity', 'Distribution Population Density',
		'Valve Connection Type', 'Tornado Area Ranking', 'Soil Topography', 'Soil Land Use', 
		'Rectifier Status', 'Rectifier Stack Type', 'Rectifier Stack Manufacturer', 'Rectifier Manufacturer',
		'Rectifier DC Arrester', 'Rectifier AC Arrester', 'Product Type', 'Pipe Seam Type',
		'Pipe Condition Seam Type', 'PCM Reading Severity Classification', 'Occupancy Category', 
		'Mechanical Damage Status', 'MIC Analysis Reading','Internal Inspection Condition',
		'Internal Coating Type', 'Inspection Threat Type')
	AND LDTableName IS NULL
	 
	-- Create different tables for each 'grading' type (1.Mechanical 2.MetalLoss 3.CFR 4.Other)
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE
			WHEN DomainDescr LIKE '%Mechanical%Damage%Grading%1%' THEN 'LD_MechanicalDamageGrading1'
			WHEN DomainDescr LIKE '%Mechanical%Damage%Grading%2%' THEN 'LD_MechanicalDamageGrading2'
			WHEN DomainDescr LIKE '%Metal%Loss%Grading%2%' THEN 'LD_MetalLossGrading2'
			WHEN DomainDescr LIKE '%Metal%Loss%Grading%1%' THEN 'LD_MetalLossGrading1'
			WHEN DomainDescr LIKE 'CFR%Grading%' THEN 'LD_CFRGrading'
			WHEN DomainDescr LIKE 'ILI%Grading%2%' OR DomainDescr LIKE 'ILI%Feature%Criteria%'
				THEN 'LD_ILIFeatureGrading2'
			WHEN DomainDescr LIKE 'ILI%Grading%1%' OR DomainDescr LIKE 'ILI%Feature%Response%'
				THEN 'LD_ILIFeatureGrading1'
		END
	WHERE DomainDescr LIKE '%Grading%' 
	OR DomainDescr LIKE 'ILI%Feature%Criteria%' OR DomainDescr LIKE 'ILI%Feature%Response%'

	-- Use the same naming convention for all IRASCustom tables
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName =  'LD_' + TableName + '_' + REPLACE(ColumnName, '_DomainId', '')
	WHERE TableName LIKE 'IRAS%'
	AND flag = 0 

	-- Match a table-column without an LD table name with similarly named table-column with an LD table name
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1 
	JOIN (SELECT TableName, ColumnName, LDTableName FROM DrasInternal.dbo.ListDomainTableInfo) tab2
		ON tab1.ColumnName = tab2.ColumnName
		AND tab1.TableName = tab2.TableName
		AND tab2.LDTableName IS NOT NULL
	WHERE tab1.LDTableName IS NULL 
	AND tab1.ColumnName NOT IN ('ListDomainId')

	-- Match table-column without an LD table name with a similarly named by column with an LD table name
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName = tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1 
	JOIN (SELECT TableName, ColumnName, LDTableName FROM DrasInternal.dbo.ListDomainTableInfo) tab2
		ON tab1.ColumnName = tab2.ColumnName
		AND tab2.LDTableName IS NOT NULL
	WHERE tab1.LDTableName IS NULL 
	AND tab1.ColumnName NOT IN ('ListDomainId')

	-- Match DomainDescr without an LD table with the LD table name of a similar DomainDescr that has an LD table assigned 
	UPDATE  DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName =  tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1
	JOIN (SELECT DomainDescr, LDTableName 
		  FROM DrasInternal.dbo.ListDomainTableInfo ) tab2
	ON tab1.DomainDescr = tab2.DomainDescr
	AND tab2.LDTableName IS NOT NULL
	WHERE tab1.TableName IS NULL AND tab1.ColumnName NOT IN ('ListDomainId')

	-- Use the DomainDescr for the new LD table name for rows with null values in the TableName and ColumnName columns
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName =  'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '')
	WHERE LDTableName IS NULL AND TableName IS NULL
	--AND ColumnName NOT IN ('ListDomainId')

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
	WHERE LDTableName IS NULL 

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
