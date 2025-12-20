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

***NOTE***
1. This script must be executed on an instance of SQL Server 2017 or higher. 
2. The Instance must have a DrasiInternal database. This is where the ListDomainInfo table will be created

*/
USE DrasInternal

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

--***************************************** SCRIPT PARAMETERS ***********************************
/*
Adjust the following before running the script. Make sure to run the script on the server
where you would like the ListDomainTableInfo to be created. The Chosen server must have a DRASInternal db
*/
-- List the servers that will be used to generate the ListDomianTableInfo table data
SET @ServerList = 'DRASSQL2019
DRASSQL2017
DRASSQL2016'

-- If set to '0' it will only execute the LDTable naming portion (runs faster), if set to '1' it will recreate the ListDomainTableInfo table 
SET @RecreateTable = 0
---------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS ##ServerList
CREATE TABLE ##ServerList (Name VARCHAR(100));

SET @ServerList = REPLACE(@ServerLIst, ' ', '')
SET @ServerLIst = REPLACE(@ServerLIst, CHAR(10), ' ')
SET @ServerLIst = REPLACE(@ServerLIst, CHAR(13), '')
SET @ServerLIst = REPLACE(@ServerLIst, CHAR(9), '')
SET @ServerLIst = REPLACE(@ServerLIst, ' ', ''')' + CHAR(10) + 'INSERT INTO ##ServerList VALUES (''')

SET @ServerLIst = 'INSERT INTO ##ServerList VALUES (''' + @ServerList + ''')'

EXECUTE (@ServerList)

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

	IF (@ServerList IS NULL OR TRIM(@ServerList) = '')
	BEGIN
		SET @SQL = 'DECLARE ServerList_Cursor CURSOR FOR
		SELECT TOP 1 name FROM DrasInternal.dbo.Servers 
		WHERE name LIKE ''%SQL%'' AND name NOT LIKE ''%TEST%''
		AND name NOT IN (''CTSQL01.DRAS.LOCAL'', ''SQL2016\LATIN1_GENERAL'', ''DRASSQL2022'', ''PAA-SQL01'', ''SQL2019DEV'', ''SQL2014'')'

		EXECUTE (@SQL)
	END
	ELSE
	BEGIN
		SET @SQL = 'DECLARE ServerList_Cursor CURSOR FOR
		SELECT name FROM ##ServerList'

		EXECUTE (@SQL)
	END

	OPEN ServerList_Cursor
	FETCH NEXT FROM ServerList_Cursor INTO @ServerName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @ServerName AS ServerName

	-------------------------- Get info on all list domain tables in the stage databases ------------------
		
		DROP TABLE IF EXISTS ##DBList
		
		CREATE TABLE ##DBList (name NVARCHAR(100))
	
		SET @SQL = 'INSERT INTO ##DBList (name)
		SELECT name
		FROM [' + @ServerName + '].master.sys.databases
		WHERE name NOT LIKE ''%LINK%''
		AND name NOT LIKE ''%CONFIG%''
		AND name LIKE ''%IRASV6%''
		AND name LIKE ''DRAS%''
		AND state_desc = ''ONLINE'''	

		EXECUTE (@SQL)

		DECLARE DBCursor CURSOR FOR
		SELECT name FROM ##DBList

		OPEN DBCursor
		FETCH NEXT FROM DBCursor INTO @DBName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT  '***************************' + @DBName + '*********************************'
			SELECT @DBName


			-- Check if ListDomain table exists in the database
			IF @ServerName <> @@SERVERNAME
			BEGIN
				SELECT @SQL = 'SELECT @Result = CASE WHEN ObjectId = 3 THEN 1 ELSE 0 END
								FROM OPENQUERY([' + @ServerName + '], 
								''SELECT ObjectId = COUNT(*) FROM '+ @DBName + '.sys.tables WHERE name IN (''''ListDomain'''', ''''DomainCatalog'''', ''''DomainCatalogColXRef'''') '') As Ora'; 

				EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @ObjectExists OUTPUT

			END
			ELSE
			BEGIN
				SET @SQL = 'USE ' + @DBName + '
				SELECT @Result = CASE WHEN (SELECT COUNT(*) 
												FROM sys.tables WHERE name IN (''ListDomain'', ''DomainCatalog'', ''DomainCatalogColXref'')) = 3
												THEN 1 
											ELSE 0
										END'

				EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @ObjectExists OUTPUT
			END

			-- If the ListDomain table exists insert data into ListDomainTableInfo table
			IF (@ObjectExists > 0) 
			BEGIN
					-- if the server in curent loop iteration is not the server the script is running on, execute command with linked server
					IF @ServerName <> @@SERVERNAME 
					BEGIN

						SET @SQL = 'INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
									SELECT * FROM OPENQUERY ([' + @ServerName + '], 
												''SELECT ''''' + @ServerName + ''''',
														''''' + @DBName + ''''',
														(SELECT name FROM ' + @DBName + '.sys.tables WHERE object_id = fkc.parent_object_id) AS TableName,		
														(SELECT name FROM ' + @DBName + '.sys.columns WHERE object_id = fkc.parent_object_id
														AND column_id = fkc.parent_column_id) AS ColumnName,	
														0 AS flag
												FROM ' + @DBName + '.sys.foreign_key_columns  fkc
												WHERE referenced_object_id = (SELECT object_id FROM ' + @DBName + '.sys.tables 
																				WHERE name = ''''ListDomain''''
																			)
												AND parent_object_id NOT IN (SELECT object_id FROM ' + @DBName + '.sys.tables 
																				WHERE name IN (''''RememberedListDomainValues'''', ''''VirtualTableDataListDomain'''', ''''ActionItemPropDCXRef'''', ''''CategoryDataListDomainXRef'''')
																			)
										
															'')
															
												INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
												VALUES (''' + @ServerName + ''', ''' + @DBName + ''', ''POECompanyLookUp'', ''MetalLossTypeDomainId'', 0)

												INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
												VALUES (''' + @ServerName + ''', ''' + @DBName + ''',''POECompanyLookUp'', ''ToolTypeDomainId'', 0)

												INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
												VALUES (''' + @ServerName + ''', ''' + @DBName + ''', ''Stg_ILICrackAnomaly'', ''ILICADepthDomainId'', 0)'

					END
					-- For local server
					ELSE 
					BEGIN
						SET @SQL = '

						USE [' + @DBName + ']

						INSERT INTO [DrasInternal].dbo.ListDomainTableInfo
						(ServerName, DBName, TableName, ColumnName, flag)
						SELECT 	@@SERVERNAME,
								DB_NAME(),
								OBJECT_NAME(parent_object_id) AS TableName,		
								COL_NAME(parent_object_id, parent_column_id) AS ColumnName,		
								0 AS flag
						FROM sys.foreign_key_columns 
						WHERE OBJECT_NAME(referenced_object_id) = ''ListDomain''
						AND OBJECT_NAME(parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
						
						INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
						VALUES (@@SERVERNAME, DB_NAME(), ''POECompanyLookUp'', ''MetalLossTypeDomainId'', 0)

						INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
						VALUES (@@SERVERNAME, DB_NAME(),''POECompanyLookUp'', ''ToolTypeDomainId'', 0)

						INSERT INTO [DrasInternal].[dbo].[ListDomainTableInfo](ServerName, DBName, TableName, ColumnName, flag)
						VALUES (@@SERVERNAME, DB_NAME(), ''Stg_ILICrackAnomaly'', ''ILICADepthDomainId'', 0)
						
						UPDATE [DrasInternal].[dbo].[ListDomainTableInfo]
						'
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

		---------- Find DomainCatalogId entries in ListDomain and DomianCatalogColXRef tables --------

						-- For remote servers
						IF @ServerName <> @@SERVERNAME
						BEGIN
							-- Check if table and column are in DomainCatalogColXRef table
							SELECT @SQL = 'SELECT @Result = DomainCatalogId
											FROM OPENQUERY([' + @ServerName + '],
														''SELECT DomainCatalogId 
														FROM [' + @DBName + '].dbo.DomainCatalogColXRef 
														WHERE TableName = ''''' + @TableName + ''''' 
														AND ColumnName = ''''' + @ColumnName + ''''''')'; 

							EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @DCCXRef_DCId OUTPUT

							-- Find all the distinct DomainCatalogIds in the ListDomain table
							SELECT @SQL = 'SELECT * FROM OPENQUERY([' + @ServerName + '], 
											''SELECT DISTINCT DomainCatalogId
							FROM ' + QUOTENAME(@DBName) + '.[dbo].[ListDomain] 
							WHERE Id IN (SELECT ' + QUOTENAME(@ColumnName) + ' 
											FROM ' + QUOTENAME(@ServerName) + '.' + QUOTENAME(@DBName) + '.[dbo].' + QUOTENAME(@TableName) + ')
							AND DomainCatalogId <> -1'')'; 

							TRUNCATE TABLE ##LD_DCId

							INSERT INTO ##LD_DCId
							EXECUTE (@SQL)
						END
						-- For local server
						ELSE
						BEGIN
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
						END
								
		------------------- Flag inconsistent DomainCatalogId entries ------------------------

						IF @ServerName <> @@SERVERNAME
						BEGIN
							-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
							IF (SELECT COUNT(*) FROM ##LD_DCId) > 1 
							BEGIN
		
								SET @SQL = '
									UPDATE DrasInternal.dbo.ListDomainTableInfo
									SET FlaggedDomainDescr =  subq.DomainDescr,												  
										FlaggedDomainCatalogId = subq.Id,
										flag = 1
									FROM (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') As Id,
													STRING_AGG(DomainDescr, '', '') As DomainDescr
											FROM OPENQUERY([' + @ServerName + '],
													''SELECT Id,
																DomainDescr
													FROM [' + @DBName + '].dbo.DomainCatalog'') AS dc
											JOIN ##LD_DCId Temp
											ON Temp.DomainCatalogId = dc.Id
										) AS subq
									WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
									AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
								
							END
							-- Flag tables with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
							ELSE IF (SELECT * FROM ##LD_DCId) <> @DCCXRef_DCId
							BEGIN
			
								SET @SQL = '
									UPDATE DrasInternal.dbo.ListDomainTableInfo
									SET FlaggedDomainDescr = subq.DomainDescr,
										FlaggedDomainCatalogId = subq.Id,
										flag = 1
									FROM (SELECT STRING_AGG(DomainDescr, '', '') AS DomainDescr,
													STRING_AGG(CAST(Id AS NVARCHAR), '', '') AS Id
											FROM OPENQUERY([' + @ServerName + '],
																	''SELECT Id, DomainDescr
																	FROM [' + @DBName + '].dbo.DomainCatalog'') AS dc
											JOIN ##LD_DCId temp
											ON dc.Id = temp.DomainCatalogId OR dc.Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
										) subq
									WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
									AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
							END
							ELSE 
							BEGIN
								IF @DCCXRef_DCId IS NULL
								BEGIN
									SELECT @DCCXRef_DCId = DomainCatalogId FROM ##LD_DCId
								END

								SET @SQL = '
									UPDATE DrasInternal.dbo.ListDomainTableInfo
									SET DomainCatalogId = subq.Id,
										DomainDescr = subq.DomainDescr
									FROM (SELECT ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ' AS Id,
													DomainDescr
											FROM OPENQUERY(' + @ServerName + ', 
												''SELECT Id, DomainDescr 
													FROM ' + @DBName + '.[dbo].[DomainCatalog]'') AS dc
											WHERE dc.Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
										) subq
									WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
									AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''

							END
						END
						-- For Local Server
						ELSE
						BEGIN
				
							-- Flag tables that have more than 1 DomainCatalogId in ListDomain table
							IF (SELECT COUNT(*) FROM ##LD_DCId) > 1 
							BEGIN
								SET @SQL = '
										UPDATE DrasInternal.dbo.ListDomainTableInfo
										SET FlaggedDomainDescr =  subq.DomainDescr,												  
											FlaggedDomainCatalogId = subq.Id,
											flag = 1
										FROM (SELECT STRING_AGG(CAST(Id AS NVARCHAR), '', '') As Id,
														STRING_AGG(DomainDescr, '', '') As DomainDescr
												FROM [' + @DBName + '].dbo.DomainCatalog dc
												JOIN ##LD_DCId Temp
												ON Temp.DomainCatalogId = dc.Id
											) AS subq
										WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
										AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
							END
							-- Flag tables with a ListDomain DomainCatalogId that does not match DomainCatalogId in DomainCatalogColXRef table
							ELSE IF (SELECT * FROM ##LD_DCId) <> @DCCXRef_DCId
							BEGIN
			
								SET @SQL = '
									UPDATE DrasInternal.dbo.ListDomainTableInfo
									SET FlaggedDomainDescr = subq.DomainDescr,
										FlaggedDomainCatalogId = subq.Id,
										flag = 1
									FROM (SELECT STRING_AGG(DomainDescr, '', '') AS DomainDescr,
													STRING_AGG(CAST(Id AS NVARCHAR), '', '') AS Id
											FROM [' + @DBName + '].dbo.DomainCatalog dc
											JOIN ##LD_DCId temp
											ON dc.Id = temp.DomainCatalogId OR dc.Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
										) subq
									WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
									AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
		
							END
							ELSE 
							BEGIN
								IF @DCCXRef_DCId IS NULL
								BEGIN
									SELECT @DCCXRef_DCId = DomainCatalogId FROM ##LD_DCId
								END
							
								SET @SQL = '
									UPDATE DrasInternal.dbo.ListDomainTableInfo
									SET DomainCatalogId = subq.Id,
										DomainDescr = subq.DomainDescr
									FROM (SELECT ' + CAST(@DCCXRef_DCId AS NVARCHAR) + ' AS Id,
													DomainDescr
											FROM ' + @DBName + '.[dbo].[DomainCatalog ]
											WHERE Id = ' + CAST(@DCCXRef_DCId AS NVARCHAR) + '
										) subq
									WHERE ServerName = ''' + @ServerName + ''' AND DBName = ''' + @DBName + ''' 
									AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''

							END 
						END -- else-statement for Local server

						EXECUTE (@SQL)
		
													
					FETCH NEXT FROM FlaggedLDCursor INTO @TableName, @ColumnName
				END

				CLOSE FlaggedLDCursor
				DEALLOCATE FlaggedLDCursor
						
			-------------- Add DomainCatalogIds in ListDomain table that are not associated with any other table ------------------------------
					 
					-- if the server in curent loop iteration is not the server the script is running on, execute command with linked server
					IF @ServerName <> @@SERVERNAME
					BEGIN

						SET @SQL = '
								INSERT INTO [DrasInternal].dbo.ListDomainTableInfo
								(ServerName, DBName, DomainCatalogId, DomainDescr, flag)
								SELECT * FROM OPENQUERY (' + @ServerName + ', ''SELECT DISTINCT ''''' + @ServerName + ''''',
										''''' + @DBName + ''''',
										ld.DomainCatalogId,
										dc.DomainDescr,
										0 AS flag
								FROM ' + @DBName + '.dbo.DomainCatalog dc
								JOIN ' + @DBName + '.dbo.ListDomain ld
									ON dc.Id = ld.DomainCatalogId
								WHERE ld.DomainCatalogId <> -1'') AS remotesubq
								WHERE remotesubq.DomainDescr NOT IN (SELECT DomainDescr 
																FROM [DrasInternal].dbo.ListDomainTableInfo
																WHERE DomainDescr IS NOT NULL AND DBName = ''' + @DBName + '''  
																AND ServerName = ''' + @ServerName + ''')
						'
								
					END
					ELSE
					BEGIN
							SET @SQL = '
								USE [' + @DBName+ ']

									INSERT INTO [DrasInternal].dbo.ListDomainTableInfo
									(ServerName, DBName, DomainCatalogId, DomainDescr, flag)
									SELECT DISTINCT ''' + @ServerName + ''',
											''' + @DBName + ''',
											ld.DomainCatalogId,
											dc.DomainDescr,
											0 AS flag
									FROM dbo.DomainCatalog dc
									JOIN dbo.ListDomain ld
										ON dc.Id = ld.DomainCatalogId
									WHERE ld.DomainCatalogId <> -1	
									AND DomainDescr NOT IN (SELECT DomainDescr FROM [DrasInternal].dbo.ListDomainTableInfo
															WHERE DomainDescr IS NOT NULL AND DBName = ''' + @DBName + ''' 
															AND ServerName = ''' + @ServerName + ''')'
					END -- End of if-elseif-else 

					EXECUTE (@SQL)
								
			END -- End of While loop

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

BEGIN TRANSACTION

	-- Use the ColumnName to name the LD tables removing '_DomainId' and 'Ld' from new LD name
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = NULL

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'Repair Method'
	WHERE ColumnName IN ('MetalLossRepairMethodDomainId', 'MechDmgRepairMethodDomainId')

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'Shutdown Profile'
	WHERE Columnname = 'ValveTypeClosureProfileLD'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'Valve Type'
	WHERE ColumnName = 'ValveTypeLD'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'Lightning Strike Area Range'
	WHERE ColumnName = 'LightningStrikeAreaRangeLD'

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'Valve Section Number'
	WHERE ColumnName = 'ValveSectionNumberDomainId' 

	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET DomainDescr = 'DCVG Survey Equipment'
	WHERE ColumnName = 'DCVGSurveyEquipmentDomainId' 
	
	-------------------------------------- Intentionally Group LD tables ------------------------------------------

	-- Specify the LD table name for the given Column names 
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE
						WHEN ColumnName LIKE 'ILI%FacType%' OR DomainDescr LIKE 'ILI%Fac%Type%' THEN 'LD_ILIFacilityType'
						WHEN ColumnName = 'ValveTypeLD' THEN 'LD_ValveType'
						WHEN ColumnName LIKE '%Grading%' THEN 'LD_Grading'
						WHEN Columnname = 'CoatingLineDomainId' OR ColumnName = 'CoatingCondLineTypeLD' THEN 'LD_CoatingType'
						WHEN ColumnName LIKE '%CoordSys%' THEN 'LD_CoordinateSystem'
						WHEN ColumnName LIKE 'HCATypeListDomainId' THEN 'LD_HCATypeList'
						WHEN ColumnName LIKE 'ILICAFailPressAlgthmDomainId' THEN 'LD_FailurePressureAlgorithm'
						WHEN ColumnName LIKE 'ILICallBoxInteractRuleDomainId' THEN 'LD_ILICallBoxInteractRule'
						WHEN ColumnName LIKE  'ValveSectionNumberDomainId' THEN 'LD_ValveSectionNumber'
						WHEN ColumnName LIKE 'DCVGSurveyTypeDomainId' THEN 'LD_DCVGSurveyType'
						WHEN ColumnName LIKE 'MechDmgRepairMethodDomainId' OR ColumnName LIKE 'MetalLossRepairMethodDomainId'
							THEN 'LD_RepairMethod'
					  END
	WHERE LDTableName IS NULL
	AND ColumnName NOT IN ('ListDomainId')


	-- Specify the LD table name for the given Domain Descriptions
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = CASE 
						WHEN DomainDescr = 'Area' OR DomainDescr = 'Area Name' THEN 'LD_AreaName'
						WHEN DomainDescr LIKE 'ACVG%Anom%Indication%Type' THEN  'LD_ACVGAnomalyIndicationType'
						WHEN DomainDescr LIKE 'ACVG%Reading%Sev%Classification' THEN 'LD_ACVGReadingSeverityClass'
						WHEN DomainDescr LIKE '%Seismic%' THEN 'LD_SeismicArea'
						-- Grading Columns
						WHEN DomainDescr LIKE '%Grading%' THEN 'LD_Grading'
						WHEN DomainDescr LIKE '%DCVG%Survey%Equipment%' THEN 'LD_DCVGSurveyEquipment'
						WHEN DomainDescr LIKE '%Crack%Anomaly%Type' THEN 'LD_ILICrackAnomalyType' 
						WHEN DomainDescr LIKE 'ILI Facility Type' THEN 	'LD_ILIFacilityType'
						WHEN DomainDescr LIKE 'ILI Feature Type' OR DomainDescr LIKE 'Metal Loss Type' OR
							DomainDescr LIKE 'ILI Metal Loss Types' THEN 'LD_ILIFeatureType'
						WHEN DomainDescr LIKE 'Soil%Environment%' OR DomainDescr LIKE 'Soil%Topography%' OR DomainDescr = 'Soil Land Use'
							THEN 'LD_SoilTopography'
						WHEN DomainDescr LIKE '%Hurricane%Rank%' THEN 'LD_HurricaneRanking'
						WHEN DomainDescr LIKE '%Remed%' THEN 'LD_RemediationMeasure'
						WHEN DomainDescr LIKE '%Frost%Area%' THEN 'LD_FrostAreaRange'
						WHEN DomainDescr LIKE   '%Flood%Rank%' OR DomainDescr LIKE '%Flood%Range%' THEN 'LD_FloodRanking'
						WHEN DomainDescr LIKE '%Flood%SME%' THEN  'LD_FloodSME'
						WHEN DomainDescr LIKE '%Lightning%' THEN 'LD_LightningStrikeDensity'
						WHEN DomainDescr LIKE '%Line%Loop%Type%'  THEN 'LD_LineLoopProductType'
						WHEN DomainDescr IN ('Incident Type', 'Classification Type') THEN 'LD_IncidentType'
						WHEN DomainDescr LIKE 'Incident Status' THEN 'LD_IncidentStatus'
						WHEN DomainDescr IN ('ILI Tool', 'ILI Type') THEN 'LD_ILIToolType'
						WHEN DomainDescr LIKE 'ILI Facility Status' THEN 'LD_ILIFacilityStatus'
						WHEN DomainDescr LIKE 'HCA Type' THEN 'LD_HCAType'
						WHEN DomainDescr LIKE 'Fabrication%Connection%Type%' THEN 'LD_FabricationConnectionType'
						WHEN DomainDescr LIKE 'District / Division Name' THEN 'LD_DistrictDivisionName'
						WHEN DomainDescr LIKE 'Distribution Service Head Susceptibility' THEN 'LD_DistrSrvcHeadSusceptibility'
						WHEN DomainDescr LIKE 'ILI%Fail%Pres%Alg%' OR DomainDescr = 'ILI FPA' 
							THEN 'LD_FailurePressureAlgorithm'
						WHEN DomainDescr LIKE 'Incident%Sever%' THEN 'LD_IncidentSeverity'
						WHEN DomainDescr LIKE 'Coating%Condition%Application%Type' THEN 'LD_CoatingConditionApplication'
						WHEN DomainDescr = 'Coating Condition' OR DomainDescr LIKE 'Coating%Condition%Found'
							THEN 'LD_CoatingCondition'
						WHEN DomainDescr = 'Coating Condition - Weld Type' OR DomainDescr = 'Coating Type - Internal'
							OR DomainDescr = 'Internal Coating Type' OR DomainDescr = 'Coating Condition - Line Type'
							OR DomainDescr = 'Coating Type - Line' OR DomainDescr = 'Coating Type - Weld'
							OR DomainDescr = 'Joint Coating Type'  THEN 'LD_CoatingType'
						WHEN DomainDescr LIKE 'Coating%Condition%Line%Type%' THEN 'LD_CoatingConditionLine'
						WHEN DomainDescr LIKE 'Crack%Failure%Pressure%Algorithm%' THEN 'LD_CrackFailurePressAlgorthm'
						WHEN DomainDescr = 'Bend Strain Type' THEN 'LD_BendStrainType'
						WHEN DomainDescr = 'Component Type' THEN 'LD_ProductType'
						WHEN DomainDescr = 'Damage Prevention Device Type' THEN 'LD_DmgPrevDeviceType'
						WHEN DomainDescr = 'Discovery Date Update Reason CallBox' THEN 'LD_DscvryDtUpdReason'
						WHEN DomainDescr = 'Discovery Date Update Reason Crack' THEN 'LD_DscvryDtUpdReason'
						WHEN DomainDescr = 'Discovery Date Update Reason Feature' THEN 'LD_DscvryDtUpdReason'
						WHEN DomainDescr = 'Class Area Rating' AND ColumnName <> 'LightningStrikeAreaRangeLD' THEN 'LD_ClassAreaRating'
						WHEN DomainDescr = 'Discovery Date Update Reason NonCrsnDfct' THEN 'LD_DscvryDtUpdReason'
						WHEN DomainDescr = 'Crossing Type' THEN 'LD_CrossingType'
						WHEN DomainDescr = 'ILI Defect Status' OR DomainDescr = 'ILI Crack Anomaly Status' 
							OR DomainDescr = 'ILI Feature Status' OR DomainDescr = 'ILICA Status' OR DomainDescr = 'ILICB Status'
							OR DomainDescr = 'Excavation Site Crack Anomaly Status' OR DomainDescr = 'Crack Anomaly Status'
							THEN 'LD_ILIFeatureStatus'
						WHEN DomainDescr = 'Tornado Density' OR DomainDescr = 'Tornado Area Ranking' THEN 'LD_TornadoDensityRange'
						WHEN DomainDescr = 'Shutdown Profile' THEN 'LD_ValveShutdownProfile'
						WHEN DomainDescr = 'ILI Non Corrosion Defect' OR DomainDescr = 'ILI NCD Type' 
							OR DomainDescr = 'Mechanical Damage Defect Type' 
								THEN 'LD_DefectType'
						WHEN DomainDescr = 'ILI Non Crsn Dfct Status'
							OR DomainDescr = 'Mechanical Damage Status' THEN 'LD_DefectStatus'
						WHEN DomainDescr = 'ILI Call Box Interaction rule' THEN 'LD_ILICallBoxInteractRule'

					END
	WHERE LDTableName IS NULL 

	-- Tables with the following Domain Descriptions should be named based on the DomainDescr
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '') 
	WHERE DomainDescr IN ('State / Province Name', 'ILI Status', 'Pipe Material',
		'Failure Pressure Algorithm', 'Coordinate System', 'Classification Type', 
		'ILI Crack Depth', 'Damage Type', 'Hydro Test Status', 'Repair Method', 'Land Use Type',
		'Operating Profile', 'Strain Direction', 'Corrosion Deposit Carbonate', 'Crack Anomaly Status',
		'Corrosion Deposit Texture', 'Corrosion Deposit Magnetic', 'Corrosion Deposit Colour', 'ILI Feature Type', 
		'ACVG Severity Type', 'Axial Strain Available Analysis Type', 'ILICallBox Interact Rule',
		'Datum', 'DCVG Anomaly Indication', 'EF Equipment Condition', 'HCA Type List', 'Repair Method',
		'Soil Macro Environment', 'DCVG Anomaly Severity', 'Distribution Population Density',
		'Soil Condition Visible Salts', 'Soil Condition Visible Salts', 'Soil Condition Soil Material',
		'Soil Condition Slope Position', 'Soil Condition Mottling Size', 'Soil Condition Land Use',
		'Soil Condition Immersed Water', 'Valve Type', 'Pipe Specification', 'Pipe Manufacturer',
		'Valve Connection Type', 'Soil Topography', 'Soil Land Use', 'Surface Preparation Method',
		'Rectifier Status', 'Rectifier Stack Type', 'Rectifier Stack Manufacturer', 'Rectifier Manufacturer',
		'Rectifier DC Arrester', 'Rectifier AC Arrester', 'Product Type', 'Pipe Seam Type',
		'Pipe Condition Seam Type', 'PCM Reading Severity Classification', 'Occupancy Category', 
		'Mechanical Damage Status', 'MIC Analysis Reading','Internal Inspection Condition', 'Inspection Threat Type')
	AND LDTableName IS NULL

	-- Use the same naming convention for all IRASCustom tables
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName =  'LD_' + TableName + '_' + REPLACE(ColumnName, '_DomainId', ''),
		DomainDescr = NULL
	WHERE TableName LIKE 'IRAS%'
	AND flag = 0 

	-- Make sure tables that share both a table and column name have the same LD table name and DomainDescr
	UPDATE tab1
	SET LDTableName = tab2.LDTableName, 
		DomainDescr = tab2.DomainDescr 
	FROM DrasInternal.dbo.ListDomainTableInfo tab1 
	JOIN DrasInternal.dbo.ListDomainTableInfo tab2
		ON tab1.ColumnName = tab2.ColumnName
		AND tab1.TableName = tab2.TableName
		AND tab2.LDTableName IS NOT NULL
	WHERE tab1.LDTableName IS NULL OR tab1.DomainDescr NOT LIKE 'IRAS NOT AVAI%'
	

	-- Use the DomainDescr for the new LD table name for rows with null values in the TableName and ColumnName columns
	UPDATE DrasInternal.dbo.ListDomainTableInfo 
	SET LDTableName =  'LD_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, ' ', ''), '-', ''), '.', ''), '/', ''), '(', ''), ')', ''), '>', ''), '<', ''), '%', ''), '@', ''), '=', ''), '&', ''), ',', '')
	WHERE LDTableName IS NULL 
		
	-- Make sure tables with the same column name have the same DomainDescr
	UPDATE tab1 
	SET DomainDescr = tab2.DomainDescr
	FROM  DrasInternal.dbo.ListDomainTableInfo tab1
	JOIN DrasInternal.dbo.ListDomainTableInfo tab2
	ON tab1.ColumnName = tab2.ColumnName
	AND tab2.DomainDescr IS NOT NULL 
	WHERE tab1.LDTableName IS NULL OR tab1.DomainDescr NOT LIKE 'IRAS NOT AVAI%'

	
	-- Make sure tables with the same DomainDescr have the same LD table name
	UPDATE tab1
	SET LDTableName = tab2.LDTableName
	FROM DrasInternal.dbo.ListDomainTableInfo tab1
	JOIN DrasInternal.dbo.ListDomainTableInfo tab2
		ON tab1.DomainDescr = tab2.DomainDescr
		AND tab2.TableName IS NULL
	WHERE tab1.LDTableName IS NULL OR tab1.DomainDescr NOT LIKE 'IRAS NOT AVAI%'

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
			
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = 'LD_NotApplicable'
	WHERE DomainDescr = 'N/A' 
	AND TableName IS NULL;

	-- Shorten names
	UPDATE DrasInternal.dbo.ListDomainTableInfo
	SET LDTableName = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LDTableName, 'Distribution', 'Distr')
	, 'Condition', 'Cond'), 'Classification', 'Class'), 'Description', 'Descr'), 'DiscoveryDateUpdateReason', 'DDUR')
	, 'Coating', 'Coat'), 'PressureAlgorithm', 'PressAlgorthm'), 'Reinforcement', 'Reinforce'), 'Remediation', 'Remed'), 'Service', 'Srvc'), 'CrackAnomaly', 'CA'), 'AxialStrain', 'AX'), 'ILIFeature', 'ILIF_'), 'Internal', 'Int'), 'MetalLoss', 'ML'), 'Fabrication', 'Fab')
	, 'Exposure', 'Expose'), 'Direction', 'Dirxn'), 'DesignClassRating', 'DCRating'), 'ClassAreaRating', 'CARating'), 'Source', 'Src'), 'Interference', 'int'), 'Methodology', 'Method'), 'Temperature', 'Temp'), 'Crossing', 'Crx'), 'Mitigation', 'Mitgtn'), 'Experience', 'Exp'), 'Collection', 'Collect')
	, 'OperatingTemp', 'OperTemp'), 'DesignAssessment', 'DesignAssess'), 'SpecialPermitingSentencingAreaSegment','SpecialPermitAreaSeg'),'InitialPrioritization', 'InitialPriority'),'NearNeutral', 'Neutrl'),'InspectionAge', 'InspecAge')
	, 'TotalDissolvedSolidsand', 'DsolveSolid'), 'OxygenContamination','OxygContamin'), 'ChemicalInhibitionProgram', 'ChemInhibitProg'), 'ErosiveFactors','Erossion')
	WHERE LEN(LDTableName) > 30 

	-- Add Set names for specific Domain descriptions if not already existing
	IF NOT EXISTS (SELECT * FROM DrasInternal.dbo.ListDomainTableInfo WHERE DomainDescr = 'TPD Buried Markers')
	BEGIN
		INSERT INTO DrasInternal.dbo.ListDomainTableInfo (DomainDescr, LDTableName)
		SELECT '%TPD%Buried%Markers%', 'LD_TPDBuriedMarkers'
	END
	ELSE
	BEGIN
		UPDATE DrasInternal.dbo.ListDomainTableInfo 
		SET LDTableName = 'LD_TPDBuriedMarkers'
		WHERE DomainDescr LIKE '%TPD%Buried%Markers%'
	END
COMMIT TRAN

