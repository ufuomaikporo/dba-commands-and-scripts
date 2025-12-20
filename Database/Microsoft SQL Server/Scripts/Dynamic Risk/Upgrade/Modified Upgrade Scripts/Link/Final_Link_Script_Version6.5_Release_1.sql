IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Link')
BEGIN
	RAISERROR( 'The target database is not Link database for applying this upgrade script.', 11, 0)
END
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650016 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)

			-- Add_IdentityColumn_to_ILIGUIDLookup.sql
			-- Make Id column of ILIGUIDLookup table an identity column
			IF OBJECT_ID('ILIGUIDLookup_upgr') IS NOT NULL
			BEGIN
				DROP TABLE ILIGUIDLookup_upgr
			END


			SELECT * INTO ILIGUIDLookup_upgr
			FROM ILIGUIDLookup 

			DROP TABLE ILIGUIDLookup

			CREATE TABLE ILIGUIDLookup (Id NUMERIC(10, 0) IDENTITY(1,1) NOT NULL,
										GUID VARCHAR(255) NOT NULL,
										TableName VARCHAR(30) NOT NULL)

			SET IDENTITY_INSERT ILIGUIDLookup ON

			INSERT INTO ILIGUIDLookup(Id, GUID, TableName)
			SELECT Id, GUID, TableName FROM ILIGUIDLookup_upgr

			SET IDENTITY_INSERT ILIGUIDLookup OFF

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL + CHAR(10), '') + 'DROP TABLE ' + name
			FROM sys.tables WHERE name LIKE '%[_]upgr'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650016 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Create_VirtualTableDummyTables_4_StageDB.sql

			/*
			This is a stage database script that creates load tables for the new Virtual tables for 6.5.1 IRAS data model
			*/

			DECLARE @SQL NVARCHAR(MAX)

			IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
			BEGIN
				SET @SQL = 'CREATE SCHEMA DRAS'
				EXECUTE (@SQL)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_Number' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_Number
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column Float
				,CONSTRAINT  PK_Load_VT_NumberSourceId PRIMARY KEY(SourceId)
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_Date' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_Date
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column DATETIME
				,CONSTRAINT  PK_Load_VT_DateTableSourceId PRIMARY KEY(SourceId)
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_Flag' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_Flag
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column NUMERIC(1,0)
				,CONSTRAINT  PK_Load_VT_FlgTableSourceId PRIMARY KEY(SourceId)
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_Indicator' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_Indicator
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column CHAR(1)
				,CONSTRAINT  PK_Load_VT_IndTableSourceId PRIMARY KEY(SourceId)
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_DomainId' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_DomainId
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column NUMERIC(7,0)
				,CONSTRAINT  PK_Load_VT_DomainIdSourceId PRIMARY KEY(SourceId)
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_String' AND table_schema = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Load_VT_String
				(Id NUMERIC(10,0) NOT NULL
				,SourceId VARCHAR(50) 
				,CheckSumValue INT NOT NULL
				,EffectiveStartDate	DATETIME
				,EffectiveEndDate DATETIME
				,LastModByUserId VARCHAR(45) NOT NULL     
				,LastModDateTime DATETIME NOT NULL   
				,CreatedDate DATETIME NOT NULL   
				,CreatedUser VARCHAR(45) NOT NULL   
				,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
				,BeginStationNum NUMERIC(13,5) NOT NULL
				,EndStationSeriesId	NUMERIC(10,0) NOT NULL
				,EndStationNum NUMERIC(13,5) NOT NULL
				,VT_Column VARCHAR(512)
				,CONSTRAINT  PK_Load_VT_StringSourceId PRIMARY KEY(SourceId)
				)
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650016 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- ETP_Update_sp_Dx6UpdateCorrectionDomains.sql
			Declare @sql nvarchar(max)

			SET @sql = 'ALTER PROCEDURE [dbo].[sp_Dx6UpdateCorrectionDomains]
						AS
						BEGIN

						CREATE TABLE #StateProvince
							(
								[StateProvinceDomainId] [NUMERIC](7, 0) NULL,
								[BeginStationSeriesId]  [NUMERIC](10, 0) NULL,
								[BeginStationNum]       [NUMERIC](13, 5) NULL,
								[EndStationSeriesId]    [NUMERIC](10, 0) NULL,
								[EndStationNum]         [NUMERIC](13, 5) NULL,
								[LineLoopId]            [NUMERIC](10, 0) NULL,
								[BeginChainage]         [NUMERIC](13, 5) NULL,
								[EndChainage]           [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #MinStateProvince
							(
								[StateProvinceDomainId] [NUMERIC](7, 0) NULL,
								[LineLoopId]            [NUMERIC](10, 0) NULL,
								[BeginChainage]         [NUMERIC](13, 5) NULL,
								[EndChainage]           [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #Area
							(
								[AreaDomainId]         [NUMERIC](7, 0) NULL,
								[BeginStationSeriesId] [NUMERIC](10, 0) NULL,
								[BeginStationNum]      [NUMERIC](13, 5) NULL,
								[EndStationSeriesId]   [NUMERIC](10, 0) NULL,
								[EndStationNum]        [NUMERIC](13, 5) NULL,
								[LineLoopId]           [NUMERIC](10, 0) NULL,
								[BeginChainage]        [NUMERIC](13, 5) NULL,
								[EndChainage]          [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #MinArea
							(
								[AreaDomainId]  [NUMERIC](7, 0) NULL,
								[LineLoopId]    [NUMERIC](10, 0) NULL,
								[BeginChainage] [NUMERIC](13, 5) NULL,
								[EndChainage]   [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #DistrictDivision
							(
								[DistrictDivisionDomainId] [NUMERIC](7, 0) NULL,
								[BeginStationSeriesId]     [NUMERIC](10, 0) NULL,
								[BeginStationNum]          [NUMERIC](13, 5) NULL,
								[EndStationSeriesId]       [NUMERIC](10, 0) NULL,
								[EndStationNum]            [NUMERIC](13, 5) NULL,
								[LineLoopId]               [NUMERIC](10, 0) NULL,
								[BeginChainage]            [NUMERIC](13, 5) NULL,
								[EndChainage]              [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #MinDistrictDivision
							(
								[DistrictDivisionDomainId] [NUMERIC](7, 0) NULL,
								[LineLoopId]               [NUMERIC](10, 0) NULL,
								[BeginChainage]            [NUMERIC](13, 5) NULL,
								[EndChainage]              [NUMERIC](13, 5) NULL
							)

						CREATE TABLE #MLVCorrection
							(
								[Id]                       [NUMERIC](10, 0) NULL,
								[EffectiveStartDate]       [DATETIME] NULL,
								[EffectiveEndDate]         [DATETIME] NULL,
								[MultiplierNum]            [NUMERIC](5, 3) NULL,
								[FactorNum]                [NUMERIC](13, 5) NULL,
								[MLVSectionId]             [NUMERIC](10, 0) NULL,
								[StateProvinceDomainId]    [NUMERIC](7, 0) NULL,
								[DistrictDivisionDomainId] [NUMERIC](7, 0) NULL,
								[AreaDomainId]             [NUMERIC](7, 0) NULL,
								[StationSeriesId]          [NUMERIC](10, 0) NULL,
								[BeginStationNum]          [NUMERIC](13, 5) NULL,
								[EndStationNum]            [NUMERIC](13, 5) NULL,
								[LineLoopId]               [NUMERIC](10, 0) NULL,
								[BeginChainage]            [NUMERIC](13, 5) NULL,
								[EndChainage]              [NUMERIC](13, 5) NULL
							)

						INSERT INTO #MLVCorrection
									(Id,
										EffectiveStartDate,
										EffectiveEndDate,
										MultiplierNum,
										FactorNum,
										MLVSectionId,
										StateProvinceDomainId,
										DistrictDivisionDomainId,
										AreaDomainId,
										StationSeriesId,
										BeginStationNum,
										EndStationNum)
						SELECT Id,
								EffectiveStartDate,
								EffectiveEndDate,
								MultiplierNum,
								FactorNum,
								MLVSectionId,
								StateProvinceDomainId,
								DistrictDivisionDomainId,
								AreaDomainId,
								StationSeriesId,
								BeginStationNum,
								EndStationNum
						FROM   dbo.MLVCorrection mc

						UPDATE mlv
						SET    LineLoopId = ss.LineLoopId,
								BeginChainage = ( mlv.BeginStationNum * MultiplierNum ) + FactorNum,
								EndChainage = ( mlv.EndStationNum * MultiplierNum ) + FactorNum
						FROM   #MLVCorrection mlv
								INNER JOIN dbo.StationSeries ss
										ON mlv.StationSeriesId = ss.Id

						INSERT INTO #StateProvince
									(StateProvinceDomainId,
										BeginStationSeriesId,
										BeginStationNum,
										EndStationSeriesId,
										EndStationNum)
						SELECT StateProvinceDomainId,
								BeginStationSeriesId,
								BeginStationNum,
								EndStationSeriesId,
								EndStationNum
						FROM   dbo.StateProvince sp

						UPDATE s
						SET    BeginChainage = ( s.BeginStationNum * mc_b.MultiplierNum ) + mc_b.FactorNum,
								EndChainage = ( s.EndStationNum * mc_e.MultiplierNum ) + mc_e.FactorNum,
								LineLoopId = ss_b.LineLoopId
						FROM   #StateProvince s
								INNER JOIN dbo.StationSeries ss_b
										ON s.BeginStationSeriesId = ss_b.Id
								INNER JOIN dbo.MLVCorrection mc_b
										ON ss_b.Id = mc_b.StationSeriesId
								INNER JOIN dbo.StationSeries ss_e
										ON s.EndStationSeriesId = ss_e.Id
								INNER JOIN dbo.MLVCorrection mc_e
										ON ss_e.Id = mc_e.StationSeriesId

						DELETE FROM #StateProvince
						WHERE  LineLoopId IS NULL  OR
								BeginChainage IS NULL  OR
								EndChainage IS NULL

						INSERT INTO #MinStateProvince
									(LineLoopId,
										BeginChainage)
						SELECT LineLoopId,
								Min( BeginChainage )
						FROM   #StateProvince sp
						GROUP  BY LineLoopId

						UPDATE s
						SET    EndChainage = sp.EndChainage,
								StateProvinceDomainId = sp.StateProvinceDomainId
						FROM   #MinStateProvince s
								INNER JOIN #StateProvince sp
										ON s.LineLoopId = sp.LineLoopId AND
											s.BeginChainage = sp.BeginChainage

						INSERT INTO #Area
									(AreaDomainId,
										BeginStationSeriesId,
										BeginStationNum,
										EndStationSeriesId,
										EndStationNum)
						SELECT AreaDomainId,
								BeginStationSeriesId,
								BeginStationNum,
								EndStationSeriesId,
								EndStationNum
						FROM   dbo.Area sp

						UPDATE s
						SET    BeginChainage = ( s.BeginStationNum * mc_b.MultiplierNum ) + mc_b.FactorNum,
								EndChainage = ( s.EndStationNum * mc_e.MultiplierNum ) + mc_e.FactorNum,
								LineLoopId = ss_b.LineLoopId
						FROM   #Area s
								INNER JOIN dbo.StationSeries ss_b
										ON s.BeginStationSeriesId = ss_b.Id
								INNER JOIN dbo.MLVCorrection mc_b
										ON ss_b.Id = mc_b.StationSeriesId
								INNER JOIN dbo.StationSeries ss_e
										ON s.EndStationSeriesId = ss_e.Id
								INNER JOIN dbo.MLVCorrection mc_e
										ON ss_e.Id = mc_e.StationSeriesId

						DELETE FROM #Area
						WHERE  LineLoopId IS NULL  OR
								BeginChainage IS NULL  OR
								EndChainage IS NULL

						INSERT INTO #MinArea
									(LineLoopId,
										BeginChainage)
						SELECT LineLoopId,
								Min( BeginChainage )
						FROM   #Area sp
						GROUP  BY LineLoopId

						UPDATE s
						SET    EndChainage = sp.EndChainage,
								AreaDomainId = sp.AreaDomainId
						FROM   #MinArea s
								INNER JOIN #Area sp
										ON s.LineLoopId = sp.LineLoopId AND
											s.BeginChainage = sp.BeginChainage

						INSERT INTO #DistrictDivision
									(DistrictDivisionDomainId,
										BeginStationSeriesId,
										BeginStationNum,
										EndStationSeriesId,
										EndStationNum)
						SELECT DistrictDivisionDomainId,
								BeginStationSeriesId,
								BeginStationNum,
								EndStationSeriesId,
								EndStationNum
						FROM   dbo.DistrictDivision sp

						UPDATE s
						SET    BeginChainage = ( s.BeginStationNum * mc_b.MultiplierNum ) + mc_b.FactorNum,
								EndChainage = ( s.EndStationNum * mc_e.MultiplierNum ) + mc_e.FactorNum,
								LineLoopId = ss_b.LineLoopId
						FROM   #DistrictDivision s
								INNER JOIN dbo.StationSeries ss_b
										ON s.BeginStationSeriesId = ss_b.Id
								INNER JOIN dbo.MLVCorrection mc_b
										ON ss_b.Id = mc_b.StationSeriesId
								INNER JOIN dbo.StationSeries ss_e
										ON s.EndStationSeriesId = ss_e.Id
								INNER JOIN dbo.MLVCorrection mc_e
										ON ss_e.Id = mc_e.StationSeriesId

						DELETE FROM #DistrictDivision
						WHERE  LineLoopId IS NULL  OR
								BeginChainage IS NULL  OR
								EndChainage IS NULL

						INSERT INTO #MinDistrictDivision
									(LineLoopId,
										BeginChainage)
						SELECT LineLoopId,
								Min( BeginChainage )
						FROM   #DistrictDivision sp
						GROUP  BY LineLoopId

						UPDATE s
						SET    EndChainage = sp.EndChainage,
								DistrictDivisionDomainId = sp.DistrictDivisionDomainId
						FROM   #MinDistrictDivision s
								INNER JOIN #DistrictDivision sp
										ON s.LineLoopId = sp.LineLoopId AND
											s.BeginChainage = sp.BeginChainage

						--Draw Linear Lines
						IF Object_id( ''tempdb..#MLVCorrectionLinear'' ) IS NOT NULL BEGIN
								DROP TABLE #MLVCorrectionLinear
							END

						CREATE TABLE #MLVCorrectionLinear
							(
								OId        NUMERIC (10, 0) NULL,
								LineLoopId NUMERIC(10, 0) NULL,
								Chainage   NUMERIC(13, 5) NULL
							)

						INSERT INTO #MLVCorrectionLinear
									(OId,
										LineLoopId,
										Chainage)
						SELECT Row_number( )
									OVER (
									ORDER BY LineLoopId, Chainage) AS OId,
								*
						FROM   ( SELECT LineLoopId,
										BeginChainage AS Chainage
									FROM   #MLVCorrection
									UNION
									SELECT LineLoopId,
										EndChainage AS Chainage
									FROM   #MLVCorrection
									UNION
									SELECT LineLoopId,
										BeginChainage AS Chainage
									FROM   #StateProvince
									UNION
									SELECT LineLoopId,
										EndChainage AS Chainage
									FROM   #StateProvince
									UNION
									SELECT LineLoopId,
										BeginChainage AS Chainage
									FROM   #Area
									UNION
									SELECT LineLoopId,
										EndChainage AS Chainage
									FROM   #Area
									UNION
									SELECT LineLoopId,
										BeginChainage AS Chainage
									FROM   #DistrictDivision
									UNION
									SELECT LineLoopId,
										EndChainage AS Chainage
									FROM   #DistrictDivision ) t
						ORDER  BY LineLoopId,Chainage

						--Create Dynamic Segments for the MLVCorrection Table
						IF Object_id( ''tempdb..#MLVDynamicSeg'' ) IS NOT NULL BEGIN
								DROP TABLE #MLVDynamicSeg
							END

						CREATE TABLE #MLVDynamicSeg
							(
								ID            NUMERIC(10, 0) NULL,
								LineLoopId    NUMERIC (10, 0) NULL,
								BeginChainage NUMERIC(13, 5) NULL,
								EndChainage   NUMERIC(13, 5) NULL
							)

						INSERT INTO #MLVDynamicSeg
									(ID,
										LineLoopId,
										BeginChainage,
										EndChainage)
						SELECT mvcl1.OID      AS Id,
								mvcl1.LineLoopId,
								mvcl1.Chainage AS BeginChainage,
								mvcl2.Chainage AS EndChainage
						FROM   #MLVCorrectionLinear mvcl1
								INNER JOIN #MLVCorrectionLinear mvcl2
										ON mvcl1.LineLoopId = mvcl2.LineLoopId AND
											mvcl2.OId = mvcl1.OID + 1

						-- Get back station series from chainage
						IF Object_id( ''tempdb..#MLVCorrectionStationing'' ) IS NOT NULL BEGIN
								DROP TABLE #MLVCorrectionStationing
							END

						CREATE TABLE #MLVCorrectionStationing
							(
								ID              NUMERIC(10, 0) NULL,
								StationSeriesId NUMERIC (10, 0) NULL,
								BeginChainage   NUMERIC (13, 5) NULL,
								EndChainage     NUMERIC (13, 5) NULL,
								LineLoopId      NUMERIC (10, 0) NULL
							)

						INSERT INTO #MLVCorrectionStationing
									(ID,
										StationSeriesId,
										BeginChainage,
										EndChainage,
										LineLoopId)
						SELECT mds.ID,
								sscBeg.Id,
								mds.BeginChainage,
								mds.EndChainage,
								mds.LineLoopId
						FROM   #MLVDynamicSeg mds
								INNER JOIN ( SELECT ss.Id,
													ss.LineLoopId,
													ss.BeginStationNum,
													ss.EndStationNum,
													ss.BeginStationNum * mlv.MultiplierNum + mlv.FactorNum AS BeginChainage,
													ss.EndStationNum * mlv.MultiplierNum + mlv.FactorNum   AS EndChainage
											FROM   dbo.StationSeries ss
													INNER JOIN dbo.MLVCorrection mlv
															ON ss.Id = mlv.StationSeriesId ) sscBeg
										ON mds.LineLoopId = sscBeg.LineLoopId AND
											mds.BeginChainage >= sscBeg.BeginChainage AND
											mds.EndChainage <= sscBeg.EndChainage

						--Get MLVCorrection Data
						IF Object_id( ''tempdb..#MLVCorrection_New'' ) IS NOT NULL BEGIN
								DROP TABLE #MLVCorrection_New
							END

						CREATE TABLE #MLVCorrection_New
							(
								Id                       NUMERIC (10, 0) NULL,
								EffectiveStartDate       DATETIME NULL,
								EffectiveEndDate         DATETIME NULL,
								MultiplierNum            NUMERIC (5, 3) NULL,
								FactorNum                NUMERIC (13, 5) NULL,
								MLVSectionId             NUMERIC (10, 0) NULL,
								StateProvinceDomainId    NUMERIC (7, 0) NULL,
								DistrictDivisionDomainId NUMERIC (7, 0) NULL,
								AreaDomainId             NUMERIC (7, 0) NULL,
								StationSeriesId          NUMERIC (10, 0) NULL,
								BeginStationNum          NUMERIC (13, 5) NULL,
								EndStationNum            NUMERIC (13, 5) NULL,
								Record_Status            VARCHAR(1) NULL,
								BeginChainage            NUMERIC (13, 5) NULL,
								EndChainage              NUMERIC (13, 5) NULL,
								LineLoopId               NUMERIC (10, 0) NULL
							)

						INSERT INTO #MLVCorrection_New
									(Id,
										EffectiveStartDate,
										EffectiveEndDate,
										MultiplierNum,
										FactorNum,
										MLVSectionId,
										StateProvinceDomainId,
										DistrictDivisionDomainId,
										AreaDomainId,
										StationSeriesId,
										BeginStationNum,
										EndStationNum,
										BeginChainage,
										EndChainage,
										LineLoopId)
						SELECT Row_number( )
									OVER (
									ORDER BY mcs.LineLoopId, mcs.BeginChainage, mcs.EndChainage) AS ID,
								mc.EffectiveStartDate,
								mc.EffectiveEndDate,
								mc.MultiplierNum,
								mc.FactorNum,
								mc.MLVSectionId,
								NULL AS StateProvinceDomainId,
								NULL AS DistrictDivisionDomainId,
								NULL AS AreaDomainId,
								mcs.StationSeriesId,
								NULL AS BeginStationNum,
								NULL AS EndStationNum,
								mcs.BeginChainage,
								mcs.EndChainage,
								mcs.LineLoopId
						FROM   #MLVCorrectionStationing mcs
								INNER JOIN #MLVCorrection mc
										ON mcs.LineLoopId = mc.LineLoopId AND
											mcs.BeginChainage >= mc.BeginChainage AND
											mcs.BeginChainage <= mc.EndChainage AND
											mcs.StationSeriesId = mc.StationSeriesId AND
											mcs.EndChainage >= mc.BeginChainage AND
											mcs.EndChainage <= mc.EndChainage

						--Recalculate Begin Stationing
						UPDATE mcs
						SET    BeginStationNum = ( mcs.BeginChainage - mc_beg.FactorNum ) / mc_beg.MultiplierNum
						FROM   #MLVCorrection_New mcs
								INNER JOIN #MLVCorrection mc_beg
										ON mcs.LineLoopId = mc_beg.LineLoopId AND
											mcs.BeginChainage >= mc_beg.BeginChainage AND
											mcs.BeginChainage <= mc_beg.EndChainage AND
											mcs.StationSeriesId = mc_beg.StationSeriesId

						--Recalculate End Stationing
						UPDATE mcs
						SET    EndStationNum = ( mcs.EndChainage - mc_end.FactorNum ) / mc_end.MultiplierNum
						FROM   #MLVCorrection_New mcs
								INNER JOIN #MLVCorrection mc_end
										ON mcs.LineLoopId = mc_end.LineLoopId AND
											mcs.EndChainage >= mc_end.BeginChainage AND
											mcs.EndChainage <= mc_end.EndChainage AND
											mcs.StationSeriesId = mc_end.StationSeriesId

						--Update State
						UPDATE mcs
						SET    mcs.StateProvinceDomainId = tbl.StateProvinceDomainId
						FROM   #MLVCorrection_New mcs
								INNER JOIN #StateProvince tbl
										ON mcs.LineLoopId = tbl.LineLoopId AND
											mcs.BeginChainage >= tbl.BeginChainage AND
											mcs.BeginChainage <= tbl.EndChainage AND
											mcs.EndChainage >= tbl.BeginChainage AND
											mcs.EndChainage <= tbl.EndChainage

						--Update Area
						UPDATE mcs
						SET    mcs.AreaDomainId = tbl.AreaDomainId
						FROM   #MLVCorrection_New mcs
								INNER JOIN #Area tbl
										ON mcs.LineLoopId = tbl.LineLoopId AND
											mcs.BeginChainage >= tbl.BeginChainage AND
											mcs.BeginChainage <= tbl.EndChainage AND
											mcs.EndChainage >= tbl.BeginChainage AND
											mcs.EndChainage <= tbl.EndChainage

						--Update District
						UPDATE mcs
						SET    mcs.DistrictDivisionDomainId = tbl.DistrictDivisionDomainId
						FROM   #MLVCorrection_New mcs
								INNER JOIN #DistrictDivision tbl
										ON mcs.LineLoopId = tbl.LineLoopId AND
											mcs.BeginChainage >= tbl.BeginChainage AND
											mcs.BeginChainage <= tbl.EndChainage AND
											mcs.EndChainage >= tbl.BeginChainage AND
											mcs.EndChainage <= tbl.EndChainage

						DELETE FROM dbo.MLVCorrection

						INSERT INTO dbo.MLVCorrection
									(Id,
										EffectiveStartDate,
										EffectiveEndDate,
										MultiplierNum,
										FactorNum,
										MLVSectionId,
										StateProvinceDomainId,
										DistrictDivisionDomainId,
										AreaDomainId,
										StationSeriesId,
										BeginStationNum,
										EndStationNum)
						SELECT Distinct Id,
								EffectiveStartDate,
								EffectiveEndDate,
								MultiplierNum,
								FactorNum,
								MLVSectionId,
								StateProvinceDomainId,
								DistrictDivisionDomainId,
								AreaDomainId,
								StationSeriesId,
								BeginStationNum,
								EndStationNum
						FROM   #MLVCorrection_New mc

						DROP TABLE #MLVCorrection

						DROP TABLE #DistrictDivision

						DROP TABLE #MinDistrictDivision

						DROP TABLE #Area

						DROP TABLE #MinArea

						DROP TABLE #StateProvince

						DROP TABLE #MinStateProvince

						DROP TABLE #MLVCorrection_New

						DROP TABLE #MLVCorrectionStationing

						DROP TABLE #MLVDynamicSeg

						DROP TABLE #MLVCorrectionLinear

						END'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650016 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 1
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650101', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 1', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			declare @sql nvarchar(max) 

			IF EXISTS (select * from sys.indexes where name = 'ILIGUIDLookup_TableName')
			BEGIN
				SET @sql = 'DROP INDEX ILIGUIDLookup.ILIGUIDLookup_TableName'
				Exec sp_executesql @sql
			END

			IF NOT EXISTS (select * from sys.indexes where name = 'IX_ILIGUIDLookup_TableName')
			BEGIN
				SET @sql = 'CREATE NONCLUSTERED INDEX IX_ILIGUIDLookup_TableName ON dbo.ILIGUIDLookup (TableName) Include (GUID)'
				Exec sp_executesql @sql
			END

			IF NOT EXISTS (select * from sys.indexes where name = 'IX_VTGUIDLookup_TableName')
			BEGIN
				SET @sql = 'CREATE NONCLUSTERED INDEX IX_VTGUIDLookup_TableName ON dbo.VTGUIDLookup (TableName) Include (GUID)'
				Exec sp_executesql @sql
			END
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 2
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650102', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 2', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Update sp_AlignLocateEndStationNum stored proc.sql
			-- Run on link database for updating sp_AlignLocateEndStationNum
			Declare @sql nvarchar(max)

			SET @sql = 'ALTER PROCEDURE [dbo].[sp_AlignLocateEndStationNum]
			AS
			BEGIN
				DECLARE @tableName varchar(100)
				DECLARE @sql nvarchar(max)

				DECLARE l_cursor CURSOR FOR
					SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN (
					SELECT ''Extract_'' + Replace(REPLACE(Table_Name, ''ETL_'', ''''),''_Locate'', '''')  FROM INFORMATION_SCHEMA.TABLES WHERE table_name LIKE ''ETL%locate%'')

				OPEN l_cursor 
					FETCH NEXT FROM l_cursor INTO @tableName

					WHILE @@FETCH_STATUS = 0 
					BEGIN
							If exists (select * from INFORMATION_SCHEMA.Columns where Table_Name = @tableName AND Column_Name = ''StationNum'')
							BEGIN
								SET @sql = ''UPDATE tbl
											SET tbl.BeginStationNum = ss.EndStationNum, tbl.EndStationNum = ss.EndStationNum, tbl.StationNum = ss.EndStationNum
											FROM '' + @tableName + '' tbl
											INNER JOIN StationSeries ss on tbl.BeginStationSeriesId = cast(ss.Id as varchar(500))
											WHERE ISNUMERIC(tbl.BeginStationNum) = 1 AND tbl.BeginStationNum > ss.EndStationNum''
							END
							ELSE
							BEGIN
								SET @sql = ''UPDATE tbl
											SET tbl.BeginStationNum = ss.EndStationNum, tbl.EndStationNum = ss.EndStationNum
											FROM '' + @tableName + '' tbl
											INNER JOIN StationSeries ss on tbl.BeginStationSeriesId = cast(ss.Id as varchar(500))
											WHERE ISNUMERIC(tbl.BeginStationNum) = 1 AND tbl.BeginStationNum > ss.EndStationNum''
							END

							EXEC sp_executesql @sql

						FETCH NEXT FROM l_cursor INTO @tableName
					END

				CLOSE l_cursor
				DEALLOCATE l_cursor
			END'
			EXEC sp_executesql @sql
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO



BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 3
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650103', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 3', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			/*

			This script converts virtual tables in a client database to flat/non-virtual tables and moves the 
			converted tables into the 'DRAS' schema. Must be executed on the target database

			*/
			DECLARE @VirtualTableName NVARCHAR(100)
			DECLARE @VirtualColumnName NVARCHAR(100)
			DECLARE @VirtualTableId INT
			DECLARE @VCDataTypeTable NVARCHAR(100)
			DECLARE @VCDataTypeColumn NVARCHAR(100)
			DECLARE @ForeignKeyName NVARCHAR(100)
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @ColumnList NVARCHAR(MAX)
			DECLARE @JoinList NVARCHAR(MAX)
			DECLARE @Counter INT = 1
			DECLARE @LDTableName NVARCHAR(100)
			DECLARE @NewTableName NVARCHAR(100)
			DECLARE @ErrorMessage NVARCHAR(MAX)
			DECLARE @flag INT

			IF OBJECT_ID ('VirtualColumn_upgr') IS NOT NULL
			BEGIN
				DROP TABLE VirtualColumn_upgr
			END

			
			/*
				Create temporary table to store the VirtualColumn values and the table name for the table associated with the 
				VirtualColumnDataTypeInd column
			*/


			SELECT vt.Id VirtualTableId,
					vc.Id VirtualColumnId, 
					REPLACE(VirtualTableName, CHAR(32), '') AS VirtualTableName,
					REPLACE(VirtualColumnName, CHAR(32), '') AS VirtualColumnName,
					CASE 
						WHEN VirtualColumnDataTypeInd = 'N' THEN 'VirtualTableDataNum'
						WHEN VirtualColumnDataTypeInd = 'D' THEN 'VirtualTableDataDate'
						WHEN VirtualColumnDataTypeInd = 'I' THEN 'VirtualTableDataInd'
						WHEN VirtualColumnDataTypeInd = 'L' THEN 'VirtualTableDataListDomain'
						WHEN VirtualColumnDataTypeInd = 'F' THEN 'VirtualTableDataFlg'
						WHEN VirtualColumnDataTypeInd = 'S' THEN 'VirtualTableDataString'
					END AS VCDataTypeTable,
					CASE 
						WHEN VirtualColumnDataTypeInd = 'N' THEN 'DataFieldValueNum'
						WHEN VirtualColumnDataTypeInd = 'D' THEN 'DataFieldValueDate'
						WHEN VirtualColumnDataTypeInd = 'I' THEN 'DataFieldValueInd'
						WHEN VirtualColumnDataTypeInd = 'L' THEN 'DataFieldValueDomainId'
						WHEN VirtualColumnDataTypeInd = 'F' THEN 'DataFieldValueFlg'
						WHEN VirtualColumnDataTypeInd = 'S' THEN 'DataFieldValueString' 
					END AS VCDataTypeColumn,
					VirtualColumnComment
			INTO VirtualColumn_upgr
			FROM VirtualColumn vc
			JOIN VirtualTable vt ON vc.VirtualTableId = vt.Id
			WHERE vc.VirtualColumnComment <> 'DO NOT USE'

			--------------------------------------- Create Schema to store Virtual Tables ----------------------------

			IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
			BEGIN
				EXECUTE ('CREATE SCHEMA DRAS')
			END
			
			---------------------- Split LD tables with Virtual and non-Virtual data -------------------

			DECLARE SharedLDTable_Cursor CURSOR FOR
			SELECT TableName, ColumnName, LDTableName 
			FROM TempListDomainTable 
			WHERE TableType = 'Virtual' AND LDTableName
			IN (SELECT LDTableName FROM TempListDomainTable
			WHERE TableType= 'Real')

			OPEN SharedLDTable_Cursor
			FETCH NEXT FROM SharedLDTable_Cursor INTO @VirtualTableName, @VirtualColumnName, @LDTableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @NewTableName = @LDTableName + '_VT'

			--------------------- Create a New LD Table for Virtual Table data -------------------

				SET @SQL = 'IF OBJECT_ID(''DRAS.' + @NewTableName + ''', ''U'') IS NULL
				BEGIN
					CREATE TABLE [DRAS].' + QUOTENAME( @NewTableName) + '(
					[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
					[Code] varchar(60) NOT NULL,
					[Descr] varchar(255) NOT NULL,
					[EffectiveEndDate] Datetime,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
					CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY (Id)
					)
				END';

				EXECUTE (@SQL)
			
				-- Recreate update trigger on LD table
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = ''tu_' + @NewTableName + ''')
				BEGIN
					EXECUTE(''CREATE TRIGGER [DRAS].[tu_' + @NewTableName + '] ON [DRAS].[' + @NewTableName + '] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE DRAS.' + @NewTableName + '
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM DRAS.' + @NewTableName + ' as t, DELETED as d
						WHERE t.Id=d.Id;
					END'')
				END'

				EXECUTE (@SQL)

				----------------------- Move Data in new virtual table ld Table -----------------------
					
				SET @SQL = ' SET IDENTITY_INSERT DRAS.' + @NewTableName + ' ON	

					INSERT INTO DRAS.' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
					SELECT Id, nt.Code, nt.Descr, nt.EffectiveEndDate
					FROM ' + @LDTableName + ' nt
					WHERE NOT EXISTS (SELECT * FROM DRAS.' + @NewTableName + ' nt2 WHERE nt.Id = nt2.Id)

					SET IDENTITY_INSERT DRAS.' + @NewTableName + ' OFF	'

				EXECUTE (@SQL)

				------------------------- Update data in info tables ------------------

				-- Update data in Temp_VirtualTableDataListDomain
				SET @SQL = 'UPDATE Temp_VirtualTableDataListDomain
				SET LDTableName = ''' + @NewTableName + ''',
					New_DataFieldValueDomainId = nt.Id
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN DRAS.' + @NewTableName + ' nt
				ON nt.Code = vtld.Code
				AND nt.Descr = vtld.Descr
				AND vtld.LDTableName = ''' + @LDTableName +  ''''

				EXECUTE (@SQL)

				-- Update data in Temp_ListDomain table
				SET @SQL = 'UPDATE Temp_ListDomain
				SET LDTableName = ''' + @NewTableName + ''',
					New_Id = nt.Id
				FROM Temp_ListDomain ld
				JOIN DRAS.' + @NewTableName + ' nt
				ON ld.LDTableName = ''' + @LDTableName + '''
				AND nt.Code = ld.Code
				AND nt.Descr = ld.Descr'

				EXECUTE (@SQL)

				-- Update data in TempListDomainTable table
				SET @SQL = 'UPDATE TempListDomainTable
				SET LDTableName = ''' + @NewTableName + ''',
					ListDomainDataCountMatches = (SELECT CASE WHEN COUNT(*) = 0 THEN ''YES''
																	ELSE ''NO''
																	END	
															FROM Temp_ListDomain ld
																WHERE NOT EXISTS (SELECT * FROM DRAS.' + @NewTableName + ' nt
																					WHERE nt.code = ld.Code AND nt.Descr = ld.Descr
																					AND nt.Id = ld.New_Id)
																AND LDTableName = '''+ @NewTableName +'''
															),
								HasData = (SELECT CASE WHEN COUNT(*) > 0 THEN ''YES''
													ELSE ''NO''
												END
										FROM DRAS.' + @NewTableName + ')
				WHERE TableName = ''' + @VirtualTableName + '''
				AND ColumnName = ''' + @VirtualColumnName + ''''

				EXECUTE (@SQL)

				FETCH NEXT FROM SharedLDTable_Cursor INTO @VirtualTableName, @VirtualColumnName, @LDTableName
			END

			CLOSE SharedLDTable_Cursor
			DEALLOCATE SharedLDTable_Cursor 
			
			----------------------- Move the Virtual tables LD tables to DRAS schema  ---------------------------------------

			SET @SQL = 'DECLARE MoveTables_Cursor CURSOR FOR 
				SELECT LDTableName
				FROM dbo.TempListDomainTable tldt
				WHERE tldt.TableType = ''Virtual'' AND (LDTableName NOT LIKE ''LD[_]%VT''
				OR COALESCE(LDTableSchema, ''NULL'') <> ''DRAS'')'

			EXECUTE (@SQL)


			OPEN MoveTables_Cursor
			FETCH NEXT FROM MoveTables_Cursor INTO @LDTableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Add '_VT' to end of virtual table LD tables	
				SET @NewTableName = REPLACE(REPLACE(@LDTableName, 'DomainId', ''), '_VT', '') + '_VT'

				-- Move table to DRAS schema
				IF OBJECT_ID('dbo.' + @LDTableName) IS NOT NULL
				BEGIN
					SET @SQL = 'ALTER SCHEMA DRAS TRANSFER dbo.' + @LDTableName

					EXECUTE (@SQL)
				END

				-- Rename virtual table LD table
				IF OBJECT_ID('DRAS.' + @NewTableName) IS NULL --AND OBJECT_ID('DRAS.' + @LDTableName) IS NOT NULL
				BEGIN
					SET @sql = 'EXEC sp_rename ''DRAS.' + @LDTableName + ''', ''' + @NewTableName + ''''
						
					EXECUTE (@SQL)
				END

				---------------------------- Recreate update trigger -------------------------------

				IF OBJECT_ID ('DRAS.tu_' + @LDTableName) IS NOT NULL
				BEGIN
					SET @SQL = 'DROP TRIGGER DRAS.tu_' + @LDTableName 

					EXECUTE (@SQL)
				END

				SET @SQL = 'CREATE OR ALTER TRIGGER [DRAS].[tu_' + @NewTableName + '] ON [DRAS].[' + @NewTableName + '] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE DRAS.' + @NewTableName + '
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM DRAS.' + @NewTableName + ' as t, DELETED as d
								WHERE t.Id=d.Id;
							END'

				EXEC sp_executesql @sql

				------------------------- Update data in info tables ------------------

				-- Update data in Temp_VirtualTableDataListDomain
				SET @SQL = 'UPDATE Temp_VirtualTableDataListDomain
				SET LDTableName = ''' + @NewTableName + '''
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN DRAS.' + @NewTableName + ' nt
				ON nt.Code = vtld.Code
				AND nt.Descr = vtld.Descr
				AND vtld.LDTableName = ''' + @LDTableName +  ''''

				EXECUTE (@SQL)

				-- Update data in Temp_ListDomain table
				SET @SQL = 'UPDATE Temp_ListDomain
				SET LDTableName = ''' + @NewTableName + ''',
					New_Id = nt.Id
				FROM Temp_ListDomain ld
				JOIN DRAS.' + @NewTableName + ' nt
				ON ld.LDTableName = ''' + @LDTableName + '''
				AND nt.Code = ld.Code
				AND nt.Descr = ld.Descr'

				EXECUTE (@SQL)
				
				-- Update data in TempListDomainTable table
				SET @SQL = 'UPDATE TempListDomainTable
				SET LDTableName = ''' + @NewTableName + ''',
					LDTableSchema = (SELECT table_schema FROM INFORMATION_SCHEMA.tables WHERE table_name = ''' + @NewTableName + '''),
					ListDomainDataCountMatches = (SELECT CASE WHEN COUNT(*) = 0 THEN ''YES''
																	ELSE ''NO''
																	END	
															FROM Temp_ListDomain ld
																WHERE NOT EXISTS (SELECT * FROM DRAS.' + @NewTableName + ' nt
																					WHERE nt.code = ld.Code AND nt.Descr = ld.Descr
																					AND nt.Id = ld.New_Id)
																AND LDTableName = '''+ @NewTableName +'''
															),
								HasData = (SELECT CASE WHEN COUNT(*) > 0 THEN ''YES''
													ELSE ''NO''
												END
										FROM DRAS.' + @NewTableName + ')
				WHERE LDTableName = ''' + @LDTableName + ''''

				EXECUTE (@SQL)

				FETCH NEXT FROM MoveTables_Cursor INTO @LDTableName
			END

			CLOSE MoveTables_Cursor
			DEALLOCATE MoveTables_Cursor
			
			----------------------------------------- Create Virtual Tables -----------------------------------------------

			-- Only creates a virtual table if it has atleast 1 virtual column
			DECLARE VirtualTable_Cursor CURSOR FOR
			SELECT VirtualTableId, VirtualTableName
			FROM VirtualColumn_upgr 

			OPEN VirtualTable_Cursor
			FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
	
				--Drop the non-temporary tables created by this script
				IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
				BEGIN
					DROP TABLE tmp_VirtualTableData
				END

				SET @ColumnList = 'SELECT ROW_NUMBER() OVER (ORDER BY VTS.VirtualTableStationingId) AS Id, '

				SET @JoinList = CHAR(10) + 'INTO tmp_VirtualTableData
				FROM VirtualTableStationing VTS'

				--------------------------- Construct code to create virtual column --------------------

				/* 
					Cursor to construct column list and join condition for SELECT statement used to create the virtual table. 
					Columns with a 'DO NOT USE' comment will not be created
				*/
				DECLARE VirtualColumns_Cursor CURSOR FOR
				SELECT VirtualColumnName,
					   VCDataTypeTable,
					   VCDataTypeColumn
				FROM VirtualColumn_upgr
				WHERE VirtualTableName = @VirtualTableName

				OPEN VirtualColumns_Cursor
				FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

				-- Use a loop to generate the select statement that will be used to populate the new virtual tables
				WHILE @@FETCH_STATUS = 0
				BEGIN

					SET @ColumnList += 'T' + CAST(@Counter AS NVARCHAR) + '.[' + @VCDataTypeColumn + '] AS ' + @VirtualColumnName + ', '
					SET @JoinList += CHAR(13) + 'LEFT JOIN ' + @VCDataTypeTable + ' T' + CAST(@Counter AS NVARCHAR) + ''
								+ CHAR(13) + ' ON T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableId = VTS.VirtualTableId'
								+ CHAR(13) + 'AND T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableStationingId = VTS.VirtualTableStationingId'
	
					SET @Counter += 1
					FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

				END
				CLOSE VirtualColumns_Cursor
				DEALLOCATE VirtualColumns_Cursor


				IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
				BEGIN
					DROP TABLE tmp_VirtualTableData
				END

				SET @SQL = @ColumnList 
				+ 'VTS.EffectiveStartDate, 
				VTS.EffectiveEndDate,
				VTS.BeginStationSeriesId,
				VTS.BeginStationNum,
				VTS.EndStationSeriesId,
				VTS.EndStationNum,
				VTS.SourceId,
				VTS.CreatedUser,
				VTS.CreatedDate,
				VTS.LastModByUserId,
				VTS.LastModDateTime
				' + @JoinList + CHAR(10) 
				+ 'WHERE VTS.VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + ''
		
				EXECUTE (@SQL)

				SET @ColumnList = NULL

				-- Get the list of columns that will be used to create the new virtual table
				SELECT @ColumnList = COALESCE(@ColumnList + '], [', '') + column_name 
				FROM INFORMATION_SCHEMA.columns
				WHERE table_name = 'tmp_VirtualTableData'
				AND column_name NOT IN ('VirtualTableId', 'VirtualTableStationingId')
				ORDER BY ordinal_position

				SET @ColumnList = '[' + @ColumnList + ']'

				-- Create and populate the new virtual table in the DRAS schema
				IF OBJECT_ID('DRAS.' + @VirtualTableName, 'U') IS NULL
				BEGIN
		
					SET @SQL = 'SELECT ' + @ColumnList + '
						INTO DRAS.' + @VirtualTableName + '
						FROM tmp_VirtualTableData'
			
					EXECUTE (@SQL)
				END

				SET @SQL = NULL
		
			---------------------------------- Add a Primary Key to Newly Created Virtual Table ------------------------------------

				IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE type = 'PK' 
								AND OBJECT_NAME(parent_object_id) = @VirtualTableName AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ALTER COLUMN Id NUMERIC(10, 0) NOT NULL'

					EXECUTE(@SQL)

					SET @SQL += CHAR(10) + 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD CONSTRAINT PK_' + @VirtualTableName + ' PRIMARY KEY CLUSTERED (Id)'
					
					EXECUTE (@SQL)
				END

				-- Update TempListDomainTable table
				SET @SQL = 'UPDATE TempListDomainTable
				SET TableSchema = ''DRAS''
				WHERE TableName = ''' + @VirtualTableName + '''
				AND TableType = ''Virtual'''
	
				EXECUTE (@SQL)

			------------------------------------ Add Column Defaults to Change-tracking columns --------------------------------------

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'LastModByUserId' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]'
					
					EXECUTE (@SQL)
				END
	
				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'LastModDateTime' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedDate' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN	
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
					
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedUser' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
					
					EXECUTE (@SQL)
				END

			------------------------------------ Create Triggers on Newly Created Virtual Tables --------------------------------------
				
				IF OBJECT_ID('DRAS.tu_' + @VirtualTableName, 'TR') IS NULL
				BEGIN
					
					SET @SQL = 'CREATE TRIGGER [DRAS].[tu_' + @VirtualTableName + '] ON [DRAS].[' + @VirtualTableName+ '] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE DRAS.' + @VirtualTableName + '
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM DRAS.' + @VirtualTableName + ' as t, DELETED as d
						WHERE t.Id=d.Id;
					END'

					EXECUTE (@SQL)
				END				

				FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

			END 

			CLOSE VirtualTable_Cursor
			DEALLOCATE VirtualTable_Cursor

			----------------- Update schema information in TempListDomainTable table -----------------

			UPDATE TempListDomainTable		
			SET TableSchema = ctab.table_schema
			FROM TempListDomainTable tld
			JOIN INFORMATION_SCHEMA.columns ctab ON ctab.table_name = tld.TableName
			AND tld.ColumnName = ctab.column_name

			UPDATE TempListDomainTable		
			SET LDTableSchema = ptab.table_schema
			FROM TempListDomainTable tld
			JOIN INFORMATION_SCHEMA.tables ptab ON ptab.table_name = tld.LDTableName

			/********************************************************************************************
											 Sanity Checks 
			********************************************************************************************/

			--------- Check that all LD tables and child tables in TempListDomainTable table exist -------
			
			SET @SQL = 'SELECT @flag = COUNT(*) FROM TempListDomainTable tld
						WHERE NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables tab
										  WHERE tab.table_name = tld.LDTableName 
										  AND tab.table_schema = tld.LDTableSchema)';

			EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT

			IF @flag <> 0 
			BEGIN

				SELECT TableType, LDTableSchema, LDTableName, 'Id' 
				FROM TempListDomainTable tld
				WHERE NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns tab
								  WHERE tab.table_name = tld.LDTableName
								  AND tab.column_name = 'Id'
								  AND tab.table_schema = tld.LDTableSchema)
				UNION 
				SELECT TableType, TableSchema, TableName, ColumnName
				FROM TempListDomainTable tld
				WHERE NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns tab
								  WHERE tab.table_name = tld.TableName 
								  AND tab.column_name = ColumnName
								  AND tab.table_schema = tld.TableSchema)
				AND TableName IS NOT NULL
				
				SET @SQL = NULL;

				THROW 51001, N'The LD tables listed in the Results tab were found in the TempListDomainTable table but were not created', 1;
			
			END

			/*
				Check that the LDTableName and DomainCatalogId are conistent in
				Temp_VirtualTableDataListDomain, Temp_ListDomain and TempListDomainTable tables
			*/

			SELECT  @flag = COUNT(*)
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN Temp_ListDomain ld
			ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
			JOIN TempListDomainTable tmp
			ON vtld.VirtualTableName = tmp.TableName
			AND vtld.VirtualColumnName = tmp.ColumnName
			WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId OR
				vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
				OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
				OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL
				OR vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
				OR ld.DomainDescr <> tmp.DomainDescr 
				OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
				OR vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
				OR ld.DomainCatalogId <> tmp.DomainCatalogId 
				OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%')
				 
			EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT

			IF @Flag <> 0
			BEGIN

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.Old_DataFieldValueDomainId
						,ld.Old_Id
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId 

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.LDTableName VirtualTableDataListDomain_LDTableName
						,ld.LDTableName ListDomain_LDTableName
						,tmp.LDTableName TempListDomainTable_LDTableName
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
					OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
					OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
						,ld.DomainDescr ListDomain_DomainDescr
						,tmp.DomainDescr TempListDomainTable_DomainDescr
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
					OR ld.DomainDescr <> tmp.DomainDescr 
					OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
					
				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.DomainCatalogId VirtualTableDataListDomain_DomainCatalogId
						,ld.DomainCatalogId ListDomain_DomainCatalogId
						,tmp.DomainCatalogId TempListDomainTable_DomainCatalogId
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
					OR ld.DomainCatalogId <> tmp.DomainCatalogId 
					OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL 
					OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%');			 

				EXECUTE (@SQL)

				SET @SQL = NULL

				SET @ErrorMessage = N'The New LD table name, DomainCatalogId, and/or new ListDomain Ids are inconistent in the following tables: '
				+CHAR(10) + 'Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable' + CHAR(10) + CHAR(10)
				+ 'These columns must match across these tables. ' + CHAR(10)+ CHAR(10) +'The inconsistent rows are in the Results tab' + CHAR(10);
			
				THROW 51001, @ErrorMessage, 1

			END

			-------------------------------- Drop Unnecessary tables -------------------------------------

			--Drop the non-temporary tables created by this script
			IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
			BEGIN
				DROP TABLE tmp_VirtualTableData
			END

			------------------------------------- Drop Virtual tables source tables -------------------------------

			/* Delete the following source tables (VirtualTable, VirtualTableDataDate, VirtualTableDataFlg) 
			once all the virtual tables have been converted to flat tables
			*/
			IF NOT EXISTS (SELECT 1 from virtualTable WHERE VirtualTableName NOT IN (SELECT name FROM sys.tables))
			BEGIN

				DECLARE @TableName NVARCHAR(100)

				DECLARE DeleteTables CURSOR FOR
				SELECT table_name FROM INFORMATION_SCHEMA.tables 
				WHERE table_name IN ('VirtualColumn',
				'VirtualTable',
				'VirtualTableDataDate',
				'VirtualTableDataFlg',
				'VirtualTableDataInd',
				'VirtualTableDataListDomain',
				'VirtualTableDataNum',
				'VirtualTableDataString',
				'VirtualTableStationing')

				OPEN DeleteTables
				FETCH NEXT FROM DeleteTables INTO @TableName

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @SQL = ''

					SELECT @SQL += 'ALTER TABLE ' + OBJECT_NAME(fkc.parent_object_id) + ' DROP CONSTRAINT '
							+ OBJECT_NAME(fkc.constraint_object_id) + CHAR(10)
					FROM sys.foreign_key_columns fkc
					JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
					JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
					WHERE OBJECT_NAME(referenced_object_id) = @TableName

					SET @SQL += 'IF OBJECT_ID (''' + @TableName + '_BKP'') IS NULL
					BEGIN 
						SELECT * INTO ' + @TableName + '_BKP FROM ' + @TableName + '
					END

					DROP TABLE ' + @TableName;

					EXECUTE (@SQL)

					FETCH NEXT FROM DeleteTables INTO @TableName
				END

				CLOSE DeleteTables
				DEALLOCATE DeleteTables

			END	
			
			----------------------- Update LD table schema in relevant tables ---------------------------

			IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
			BEGIN
				SET @SQL = 'UPDATE CategoryDataListDomainXRef
				SET ListDomainTableSchema = table_schema
				FROM CategoryDataListDomainXRef cdl
				JOIN INFORMATION_SCHEMA.tables tab
				ON cdl.ListDomainTableName = tab.table_name'

				EXECUTE (@SQL)
			END

			IF OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
			BEGIN
				SET @SQL = 'UPDATE RememberedListDomainValues
				SET ListDomainTableSchema = table_schema
				FROM RememberedListDomainValues rdv
				JOIN INFORMATION_SCHEMA.tables tab
				ON rdv.ListDomainTableName = tab.table_name'

				EXECUTE (@SQL)
			END

			IF OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL
			BEGIN
				SET @SQL = 'UPDATE ActionItemPropDCXRef
				SET ListDomainTableSchema = table_schema
				FROM ActionItemPropDCXRef aip
				JOIN INFORMATION_SCHEMA.tables tab
				ON aip.ListDomainTableName = tab.table_name'

				EXECUTE (@SQL)
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Alter_IDAllocationTableNameColumn.sql
			/*
			This is a stage database script that increase the size of the TableName column in the IDAllocation table to accommodate storing the schema name along with the table name.
			*/

			/* Remove the primary key contraint before altering the column */
			ALTER TABLE IDAllocation
			DROP CONSTRAINT PK_IDAllocation;
 
			/* Increase the size to VARCHAR(255) */
			ALTER TABLE IDAllocation
			ALTER COLUMN TableName VARCHAR(255) NOT NULL;
 
			 /* Add the primary key contraint after the column is altered */
			ALTER TABLE IDAllocation
			ADD CONSTRAINT PK_IDAllocation PRIMARY KEY (TableName);
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 4
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650104', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 4', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			 -- Add missing foreign keys to virtual LD tables that are being referenced
			DECLARE @SQL NVARCHAR(MAX) 

			SET @SQL = 'DECLARE CreateFK_Cursor CURSOR FOR 
			SELECT ''ALTER TABLE '' + TableSchema + ''.'' + TableName + '' WITH CHECK ADD CONSTRAINT '' +
			''FK_'' + CASE WHEN ColumnName = ColumnName THEN SUBSTRING(REPLACE(ColumnName, ''DomainId'', ''''), 1, 25)
							WHEN LEN(REPLACE(ColumnName, ''DomainId'', '''')) >= 25 THEN SUBSTRING(REPLACE(ColumnName, ''DomainId'', ''''), 1, 25)
							ELSE REPLACE(ColumnName, ''DomainId'', '''') + SUBSTRING(TableName, 1, (25 - LEN(REPLACE(ColumnName, ''DomainId'', ''''))))
						END	+ ''LD'' + '' FOREIGN KEY ('' + ColumnName + '')
										 REFERENCES '' + LDTableSchema + ''.'' + LDTableName + ''(Id)''
			FROM TempListDomainTable 
			WHERE LDTableName NOT IN (SELECT OBJECT_NAME(referenced_object_id) FROM sys.foreign_keys)
			AND TableName IS NOT NULL
			 '

			EXECUTE (@SQL)

			OPEN CreateFK_Cursor
			FETCH NEXT FROM CreateFK_Cursor INTO @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE (@SQL)

				FETCH NEXT FROM CreateFK_Cursor INTO @SQL
			END

			CLOSE CreateFK_Cursor
			DEALLOCATE CreateFK_Cursor

			---------------------------------------- DELETE OBSELETE TABLES ------------------------------------------------

			 /*
				Create copies of the Domain tables (i.e. ListDomain, DomainCatalog) and Virtual tables (i.e. VirtualTable, VirtualTableDataListDomain) 
				by appending '_BKP' to end of table names
			*/
			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL, '') + 'SELECT * INTO ' + REPLACE(name, '_BKP', '') + '_BKP FROM ' + name + CHAR(10)
			FROM sys.tables 
			WHERE (name LIKE 'Virtual%'
			OR name IN ('DomainCatalogColXRef', 'DomainCatalog', 'ListDomain'))
			AND name NOT LIKE 'temp%'
			AND REPLACE(name, '_BKP', '') + '_BKP' NOT IN (SELECT name FROM sys.tables)

			EXECUTE (@SQL)

			SET @SQL = NULL

			-- Drop foreign keys referencing domain and virtual tables
			SELECT  @SQL = COALESCE(@SQL, '') + 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' DROP CONSTRAINT '
			+ name + CHAR(10)
			FROM sys.foreign_keys
			WHERE (OBJECT_NAME(referenced_object_id)  LIKE 'Virtual%'
			OR OBJECT_NAME(referenced_object_id)  IN ('DomainCatalogColXRef', 'DomainCatalog', 'ListDomain'))
			AND OBJECT_NAME(referenced_object_id)  NOT LIKE 'temp%'

			EXECUTE (@SQL)

			SET @SQL = NULL

			-- Drop Domain and virtual tables
			SELECT @SQL = COALESCE(@SQL, '') + 'DROP TABLE ' + name + CHAR(10)
			FROM sys.tables 
			WHERE (name  LIKE 'Virtual%'
			OR name  IN ('DomainCatalogColXRef', 'DomainCatalog', 'ListDomain'))
			AND name  NOT LIKE '%bkp'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 5
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650105', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 5', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Move all virtual table extract and actual tables into DRAS schema
			DECLARE @sql nvarchar(max) 

			DECLARE s_cursor cursor FOR
				select 'ALTER SCHEMA DRAS TRANSFER dbo.' + TABLE_NAME
				from INFORMATION_SCHEMA.Tables where TABLE_NAME like 'Extract_Vt_%' AND TABLE_SCHEMA = 'dbo'
				union
				select 'ALTER SCHEMA DRAS TRANSFER dbo.' + TABLE_NAME 
				from INFORMATION_SCHEMA.Tables where TABLE_NAME like '%Vt_%'
				AND TABLE_SCHEMA = 'dbo'
				AND Replace(TABLE_NAME, 'Vt_','') IN (SELECT VirtualTableName from VirtualTable_BKP)

			OPEN s_cursor
				FETCH NEXT FROM s_cursor into @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM s_cursor into @sql
				END
			CLOSE s_cursor
			DEALLOCATE s_cursor
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			declare @sql nvarchar(max)
			declare @tableName nvarchar(100)
			declare s_cursor cursor FOR 
				select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'DRAS'

			OPEN s_cursor

				FETCH NEXT FROM s_cursor INTO @tableName

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = 'INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT ''' + @tableName + ''', ''BeginStationNum'',''feet'',''meter'',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = ''' + @tableName + ''' And ColumnName = ''BeginStationNum'')'
					Exec sp_executesql @sql

					SET @sql = 'INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT ''' + @tableName + ''', ''EndStationNum'',''feet'',''meter'',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = ''' + @tableName + ''' And ColumnName = ''EndStationNum'')'
					Exec sp_executesql @sql
		
					FETCH NEXT FROM s_cursor INTO @tableName
				END
			CLOSE s_cursor
			DEALLOCATE s_cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'ALTER function [dbo].[fn_ScriptJoinReferenceTable]
							(
								@tableName varchar(200), @referenceTable varchar(200)
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
								FROM StageFkeysInfo tmp
								WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = @referenceTable
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			SET @sql = 'ALTER function [dbo].[fn_ScriptJoins]
							(
								@tableName varchar(200), @withStationSeries int
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)
								IF @withStationSeries = 1
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM StageFkeysInfo tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = ''StationSeries''
									FOR XML PATH('''')), 1, 1, '''') )
								END
								ELSE
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM StageFkeysInfo tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable <> ''StationSeries'' 
									FOR XML PATH('''')), 1, 1, '''') )
								END

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			SET @sql = 'ALTER function [dbo].[fn_ScriptJoinLDColumn]
							(
								@tableName varchar(200), @columnName varchar(200), @tableAlias varchar(10) = ''ref''
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN (SELECT Min(Id) AS Id, Upper(Code) AS Code FROM '' + tmp.ReferencedTable + '' with (nolock) GROUP BY Code) '' + @tableAlias
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END  + '' ON '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName		
								FROM StageFkeysInfo tmp
								WHERE tmp.TableName = @tableName AND tmp.ColumnName = @columnName
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 6
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650106', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 6', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			Declare @sql nvarchar(max)
			Declare d_cursor cursor FOR
				select 'Drop Table ' + TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_NAME like '%Vt[_]%' and TABLE_SCHEMA = 'dbo'

			OPEN d_cursor
				FETCH NEXT FROM d_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM d_cursor INTO @sql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.Tables WHERE TABLE_NAME = 'Err_Vt_SampleErrorTable' AND TABLE_SCHEMA = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Err_Vt_SampleErrorTable(
					[IRASId] [numeric](20, 0) NULL,
					[EffectiveStartDate] varchar(500) NULL,
					[EffectiveEndDate] varchar(500) NULL,
					[SourceId] [varchar](50) NULL,
					[DataFieldValueDate] [varchar](600) NULL,
					[DataFieldValueFlg] [varchar](600) NULL,
					[DataFieldValueInd] [varchar](600) NULL,
					[DataFieldValueDomainId] [varchar](600) NULL,
					[DataFieldValueNum] [varchar](600) NULL,
					[DataFieldValueString] [varchar](600) NULL,
					[BeginStationSeriesId] [varchar](255) NULL,
					[BeginStationNum] [varchar](255) NULL,
					[EndStationSeriesId] [varchar](255) NULL,
					[EndStationNum] [varchar](255) NULL,
					[ErrorCount] [int] NULL,
					[WarningCount] [int] NULL,
					[MessagesText] [varchar](4000) NULL,
					[ElementName] [varchar](255) NULL,
					[LastModByUserId] [varchar](100) NOT NULL default suser_sname(),
					[LastModDateTime] [datetime] NOT NULL default getdate()
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.Tables WHERE TABLE_NAME = 'Extract_Vt_SampleExtractTable' AND TABLE_SCHEMA = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Extract_Vt_SampleExtractTable(
					[EffectiveStartDate] [varchar](500) NULL,
					[EffectiveEndDate] [varchar](500) NULL,
					[BeginStationSeriesGUID] [varchar](500) NULL,
					[BeginStationSeriesId] [varchar](500) NULL,
					[BeginStationNum] [varchar](500) NULL,
					[EndStationSeriesGUID] [varchar](500) NULL,
					[EndStationSeriesId] [varchar](500) NULL,
					[EndStationNum] [varchar](500) NULL,
					[DataFieldValueDate] [varchar](500) NULL,
					[DataFieldValueFlg] [varchar](500) NULL,
					[DataFieldValueInd] [varchar](500) NULL,
					[DataFieldValueDomainId] [varchar](500) NULL,
					[DataFieldValueNum] [varchar](500) NULL,
					[DataFieldValueString] [varchar](500) NULL,
					[LastModByUserId] [varchar](500) NULL,
					[LastModDateTime] [varchar](500) NULL,
					[SourceId] [varchar](500) NULL,
					[CreatedDate] [varchar](500) NULL,
					[CreatedUser] [varchar](500) NULL
				)
			END

			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.Tables WHERE TABLE_NAME = 'Vt_SampleTable' AND TABLE_SCHEMA = 'DRAS')
			BEGIN
				CREATE TABLE DRAS.Vt_SampleTable(
					[Id] [numeric](10, 0) NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[BeginStationSeriesGUID] [varchar](50) NULL,
					[BeginStationSeriesId] [numeric](10, 0) NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesGUID] [varchar](50) NULL,
					[EndStationSeriesId] [numeric](10, 0) NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL,
					[DataFieldValueDate] [datetime] NULL,
					[DataFieldValueFlg] [numeric](1, 0) NULL,
					[DataFieldValueInd] [char](1) NULL,
					[DataFieldValueDomainId] [numeric](7, 0) NULL,
					[DataFieldValueNum] [float] NULL,
					[DataFieldValueString] [varchar](512) NULL,
					[LastModByUserId] [varchar](45) NOT NULL default suser_sname(),
					[LastModDateTime] [datetime] NOT NULL default getdate(),
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime] NOT NULL default getdate(),
					[CreatedUser] [varchar](45) NOT NULL default suser_sname(),
					[CheckSumValue] int NULL
				)
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			declare @sql nvarchar(max)

			SET @sql = 'IF object_id(''DRAS.tu_Vt_SampleTable'') IS NOT NULL
						BEGIN
							DROP TRIGGER DRAS.tu_Vt_SampleTable
						END'
			EXEC sp_executesql @sql

			SET @sql = 'Create TRIGGER DRAS.tu_Vt_SampleTable ON DRAS.Vt_SampleTable FOR UPDATE AS
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE DRAS.Vt_SampleTable
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate()
							FROM DRAS.Vt_SampleTable as t, DELETED as d
							WHERE t.SourceId=d.SourceId;
						END'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			declare @sql nvarchar(max)
			declare d_cursor cursor FOR
				select 'Drop table ' + TABLE_NAME AS TableName from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'Err_vt%' and TABLE_SCHEMA = 'dbo'
				UNION
				select 'Drop table DRAS.' + TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'Err[_]%' and TABLE_SCHEMA = 'DRAS'
				and TABLE_NAME <> 'Err_Vt_SampleErrorTable'

			OPEN d_cursor
				FETCH NEXT FROM d_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM d_cursor INTO @sql
				END
			CLOSE d_cursor
			DEALLOCATE d_cursor			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 4, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			declare @sql nvarchar(max)
			SET @sql = 'ALTER PROCEDURE [dbo].[sp_InsertNewListDomains]
						(
							@tableName              VARCHAR(250), 
							@domainCatalogTableName VARCHAR(250) = NULL, 
							@isVirtualTable         BIT          = 0
						)
						AS
							BEGIN
								IF @domainCatalogTableName IS NULL
									BEGIN
										SET @domainCatalogTableName = @tableName;
									END;
								DECLARE @TrimSQL AS NVARCHAR(MAX)= '''';
								IF @isVirtualTable = 0
									BEGIN
										SELECT @TrimSQL = ''update  extract_'' + @tableName + '' set  '' + STUFF(
										(
											SELECT '','' + tmp.ColumnName + '' = left( '' + tmp.ColumnName + '' , 40)''
											FROM StageFKeysInfo tmp
											WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName
										FOR XML PATH(''''), TYPE
										).value(''.'', ''NVARCHAR(MAX)''), 1, 1, '''');
									END;
									ELSE
									BEGIN
										SELECT @TrimSQL = ''update  DRAS.Extract_'' + @tableName + '' set DataFieldValueDomainId = left( DataFieldValueDomainId , 40)'';
									END;
								PRINT @TrimSQL;
								EXEC (@TrimSQL);
        
								DECLARE @sql NVARCHAR(MAX)
								DECLARE i_cursor CURSOR FOR
									SELECT ''INSERT INTO '' 
									+ CASE WHEN @isVirtualTable = 0 THEN tmp.ReferencedTable ELSE ''DRAS.'' + tmp.ReferencedTable END
									+ ''(Code, Descr) Select '' 
									+ CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END 
									+ '','' + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END + '' FROM '' 
									+ CASE WHEN @isVirtualTable = 0 THEN '''' ELSE ''DRAS.'' END + ''Extract_'' 
									+ tmp.TableName + '' WHERE '' 
									+ + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END
									+ '' NOT IN (SELECT CODE FROM '' 
									+ CASE WHEN @isVirtualTable = 0 THEN tmp.ReferencedTable ELSE ''DRAS.'' + tmp.ReferencedTable END + '') AND '' 
									+ + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END
									+ '' IS NOT NULL'' 
									FROM StageFKeysInfo tmp
									WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName
		
								OPEN i_cursor
									FETCH NEXT FROM i_cursor INTO @sql

									WHILE @@FETCH_STATUS = 0
									BEGIN
										PRINT @sql;
										EXEC (@sql);
				
										FETCH NEXT FROM i_cursor INTO @sql
									END

								CLOSE i_cursor
								DEALLOCATE i_cursor
							END;'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 5, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN
			declare @sql nvarchar(max)

			SET @sql = 'IF object_id(''fn_ScriptJoinColumn'') IS NOT NULL
						BEGIN
							DROP FUNCTION fn_ScriptJoinColumn
						END'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE function [dbo].[fn_ScriptJoinColumn]
							(
								@tableName varchar(200), @columnName varchar(200), @tableAlias varchar(10) = ''ref''
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END + '' with (nolock) ON '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
								FROM (
								SELECT FK_NAME,TableName,ColumnName,ReferencedTable,ReferencedColumn
								FROM StageFkeysInfo
								) tmp
								WHERE tmp.TableName = @tableName AND tmp.ColumnName = @columnName
								order by TableName
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''fn_ScriptJoinLDColumn'') IS NOT NULL
						BEGIN
							DROP FUNCTION fn_ScriptJoinLDColumn
						END'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE function [dbo].[fn_ScriptJoinLDColumn]
						(
							@tableName varchar(200), @columnName varchar(200), @tableAlias varchar(10) = ''ref''
						)
						returns varchar(max)
						as
						BEGIN
							DECLARE @sql varchar(max)

							SET @sql = (SELECT joinStatement = STUFF(
							(SELECT '' LEFT JOIN (SELECT Min(Id) AS Id, Upper(Code) AS Code FROM '' 
							+ Case WHEN EXISTS (Select * From INFORMATION_SCHEMA.Tables where Table_Name = tmp.ReferencedTable AND TABLE_SCHEMA = ''DRAS'') THEN ''DRAS.'' + tmp.ReferencedTable ELSE tmp.ReferencedTable END
							+ '' with (nolock) GROUP BY Code) '' + @tableAlias
							+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END  + '' ON '' + @tableAlias 
							+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END
							+ ''.'' + tmp.ReferencedColumn + '' = t.'' + case when @columnName <> ''DataFieldValueDomainId'' THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END
							FROM StageFkeysInfo tmp
							WHERE tmp.TableName = @tableName AND (tmp.ColumnName = @columnName OR (tmp.ReferencedTable LIKE ''LD%'' AND @columnName = ''DataFieldValueDomainId''))
							FOR XML PATH('''')), 1, 1, '''') )

							RETURN @sql
						END'
			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''fn_ScriptJoinReferenceTable'') IS NOT NULL
						BEGIN
							DROP FUNCTION fn_ScriptJoinReferenceTable
						END'
			EXEC sp_executesql @sql


			SET @sql = 'CREATE function [dbo].[fn_ScriptJoinReferenceTable]
							(
								@tableName varchar(200), @referenceTable varchar(200)
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
								FROM StageFkeysInfo tmp
								WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = @referenceTable
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''fn_ScriptJoins'') IS NOT NULL
						BEGIN
							DROP FUNCTION fn_ScriptJoins
						END'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE function [dbo].[fn_ScriptJoins]
							(
								@tableName varchar(200), @withStationSeries int
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)
								IF @withStationSeries = 1
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM StageFkeysInfo tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = ''StationSeries''
									FOR XML PATH('''')), 1, 1, '''') )
								END
								ELSE
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM StageFkeysInfo tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable <> ''StationSeries'' 
									FOR XML PATH('''')), 1, 1, '''') )
								END

								RETURN @sql
							END'
			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''fn_GenerateTransfromSelectStatement'') IS NOT NULL
						BEGIN
							DROP FUNCTION fn_GenerateTransfromSelectStatement
						END'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE function [dbo].[fn_GenerateTransfromSelectStatement]
						(
							@tableName varchar(200) 
						)
						returns varchar(max)
						AS
						BEGIN

						DECLARE @column_names varchar(max) = ''''
						DECLARE @column_name varchar(100)
						DECLARE @column_short_name varchar(100)
						DECLARE @joins varchar(max) = ''''
						DECLARE @selectStatment varchar(max) = ''''
						DECLARE @refTableCount int 
						DECLARE @refParentTableCount int 
						DECLARE @fromUnit varchar(50)
						DECLARE @toUnit varchar(50)
						DECLARE @precision varchar(10)
						DECLARE @scale varchar(10)
						DECLARE @conversionVariables varchar(max) = ''''
						DECLARE @execConversions varchar(max) = ''''
						DECLARE @tempconversionVariables varchar(max) = ''''
						DECLARE @exectempConversions varchar(max) = ''''
						DECLARE @ldTableName varchar(100) = ''''
						DECLARE @IsListDomain int = 0

						-- Check whether the table is virtual table

						IF EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @tableName AND TABLE_SCHEMA = ''DRAS'')
						BEGIN
							SET @tableName = ''DRAS.'' + @tableName
						END

						-- Create temp listdomain table variable
						Declare @ListDomain TABLE (
						FK_Name varchar(100), TableName varchar(100), ColumnName varchar(100), ReferencedTable varchar(100), ReferencedColumn varchar(100))

						Insert into @ListDomain
						SELECT FK_Name, TableName, ColumnName, ReferencedTable, ReferencedColumn 
						FROM StageFkeysInfo tmp
						WHERE tmp.ReferencedTable like ''LD_%''
						order by tablename

						-- Generate variables for conversion - no temperature
						DECLARE cv_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')
						OPEN cv_cursor
							FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + '' ''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + ''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) '' + CHAR(13)
								FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit
							END
						CLOSE cv_cursor
						DEALLOCATE cv_cursor

						-- Generate exec conversion stored proc - no temperature
						DECLARE ec_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')

						OPEN ec_cursor
							FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + '' ''
							END


							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + ''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', NULL, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit
							END
						CLOSE ec_cursor
						DEALLOCATE ec_cursor

						-- Generate variables for conversion - temperature
						DECLARE tcv_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tcv_cursor
							FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @tempconversionVariables =''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) , @TempOffset numeric(13,5)'' + CHAR(13)
								FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tcv_cursor
						DEALLOCATE tcv_cursor

						-- Generate exec conversion stored proc - temperature
						DECLARE tec_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE   (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tec_cursor
							FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @exectempConversions =''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', @TempOffset OUTPUT, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tec_cursor
						DEALLOCATE tec_cursor

						SET @column_names = ''Id = case when t.SourceId not like ''''%[^0-9]%'''' then t.SourceId else IDLookup.Id end '' + CHAR(13)

						-- Get StationSeriesId columns
						DECLARE s_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							AND c.Column_Name LIKE ''%StationSeriesId'' ORDER BY c.Column_Name

						SET @refTableCount = 1
						OPEN s_cursor
							FETCH NEXT FROM s_cursor INTO @column_name
	
							IF @@FETCH_STATUS = 0
							BEGIN
								SET @column_names = @column_names + '',''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF @column_name <> ''StationSeriesId''
								BEGIN
									SET @column_names = @column_names + ''ss'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', '' 

									SET @joins = @joins + '' LEFT JOIN StationSeries ss'' + cast(@refTableCount AS varchar(10)) + '' with (nolock) ON ss'' + cast(@refTableCount AS varchar(10)) + ''.SourceId = t.'' + @column_name + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + ''ss1.Id AS '' + @column_name + '', '' 
								END

								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM s_cursor INTO @column_name
							END

						CLOSE s_cursor
						DEALLOCATE s_cursor

						IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where (c.Table_Name = @tableName or c.Table_Name = Replace(@tableName, ''DRAS.'', '''')) AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId''))
						BEGIN
							IF right(@column_names, 1) = '',''
							BEGIN
								SET @column_names = subString(@column_names, 1, len(@column_names)-1)
							END

							SET @column_names = @column_names + 
								(SELECT Cols = STUFF((SELECT  '', '' + CASE WHEN c.Column_Name = ''BeginStationSeriesId'' THEN ''BeginStationSeriesGUID'' WHEN c.Column_Name = ''EndStationSeriesId'' THEN ''EndStationSeriesGUID'' WHEN c.Column_Name = ''StationSeriesId'' THEN ''StationSeriesGUID'' END + '' = t.'' + QUOTENAME(c.Column_Name)
								FROM INFORMATION_SCHEMA.COLUMNS c	
								WHERE (table_name = @tableName or table_name = Replace(@tableName, ''DRAS.'', ''''))
								AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId'')
								ORDER BY c.Column_Name
								FOR XML PATH('''')), 1, 2, ''''))
						END

						-- Get ListDomain columns
						IF EXISTS (Select * from StageFKeysInfo where ReferencedTable LIKE ''LD%'' AND TableName = CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN REPLACE(@tableName, ''DRAS.'', '''') ELSE ''MLVCorrection'' END)
						BEGIN
							SET @IsListDomain = 1
						END
						ELSE
						BEGIN
							SET @IsListDomain = 0
						END

						DECLARE l_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							And (Column_Name in (Select ColumnName from StageFKeysInfo where ReferencedTable LIKE ''LD%'') or Column_Name = ''DataFieldValueDomainId'')
							ORDER BY c.Column_Name


						SET @refTableCount = 1
						OPEN l_cursor
							FETCH NEXT FROM l_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN


								IF @column_name like ''%DomainId''
								BEGIN
									SET @column_short_name = replace(@column_name, ''DomainId'', '''')
								END
								ELSE
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''ld'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END

								IF @IsListDomain = 1
								BEGIN
									SET @joins = @joins + '' '' + (SELECT Replace(dbo.fn_ScriptJoinLDColumn(Replace(
			
									CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN @tableName ELSE ''MLVCorrection'' END
			
			
									, ''DRAS.'', ''''), @column_name, '' tbl'' + cast(@refTableCount AS varchar(10))), ''.Id'', ''.Code''))+ CHAR(13)
								END

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								IF @IsListDomain = 1
								BEGIN
									SET @column_names = @column_names + '', tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + '', Cast(null as numeric(10,0)) AS '' + @column_name + '', Cast(null as varchar(40)) AS '' + @column_short_name + CHAR(13)
								END

								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM l_cursor INTO @column_name

							END

						CLOSE l_cursor
						DEALLOCATE l_cursor

						-- Get ParentColumns columns
						DECLARE p_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							And Column_Name in (select ColumnName from StageFKeysInfo where TableName= case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END )
							And Column_Name NOT in (Select ColumnName from @ListDomain)
							AND Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'', ''BaseIliId'', ''Stg_ILIId'')
							ORDER BY c.Column_Name

						SET @refParentTableCount = 1
						OPEN p_cursor
							FETCH NEXT FROM p_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''Id'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END

								IF @column_name IN (''RCReasonTypeId'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.Code'')) + CHAR(13)
								END
								ELSE IF @column_name NOT IN (''RCScenarioID'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.SourceId'')) + CHAR(13)
								END
								ELSE
								BEGIN
									SET @joins = @joins + '' '' + (SELECT dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10)))) + CHAR(13)
								END

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								SET @refParentTableCount = @refParentTableCount + 1

								FETCH NEXT FROM p_cursor INTO @column_name
							END

						CLOSE p_cursor
						DEALLOCATE p_cursor

						IF NOT EXISTS (Select * from INFORMATION_SCHEMA.Tables where TABLE_NAME = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END AND TABLE_SCHEMA = ''DRAS'')
						BEGIN
							SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
								on IDLookup.GUID = t.SourceId
									and IDLookup.TableName = '''''' + @TableName + '''''''' + CHAR(13)
						END
						ELSE
						BEGIN
							SET @joins = @joins + '' LEFT JOIN VTGUIDLookup IDLookup with (nolock)
								on IDLookup.GUID = t.SourceId
									and IDLookup.TableName = '''''' + Replace(@tableName, ''DRAS.'', '''') + '''''''' + CHAR(13)
						END

						----Get columns which required conversion -- no temperature
						DECLARE c_cursor CURSOR FOR
							SELECT * FROM (
								SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							) tmp
							ORDER BY ColumnName

						OPEN c_cursor
							FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END
								ELSE IF right(@column_names, 2) = '', ''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								IF @column_name <> ''StationNum''
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END

								FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE c_cursor
						DEALLOCATE c_cursor

						----Get columns which required conversion -- temperature

						DECLARE ct_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN ct_cursor
							FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', '' + @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE ct_cursor
						DEALLOCATE ct_cursor

						---- Get all other columns
						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + '','' +
						(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
						FROM INFORMATION_SCHEMA.Columns c 
						LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
						Where c.Table_Name = ''Extract_'' + Replace(@tableName, ''DRAS.'', '''')
						AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
						And sfi.ColumnName IS NULL
						AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'', ''DataFieldValueDomainId'')
						AND c.Column_Name NOT LIKE ''%StationNum''
						AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = Replace(@tableName, ''DRAS.'', ''''))
						ORDER BY c.Column_Name
						FOR XML PATH('''')), 1, 2, ''''))

						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + CHAR(13) +  '',[LastModDateTime] = getdate() 
						,[LastModByUserId] = SUSER_SNAME() 
						,t.[SourceId]
						,[CreatedDate] = getdate()  
						,[CreatedUser] = SUSER_SNAME() 
						,t.[CheckSumValue]''

						IF NOT EXISTS (Select * from INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''DRAS'' AND TABLE_NAME = Replace(@tableName, ''DRAS.'', ''''))
						BEGIN
							SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
						END
						ELSE
						BEGIN
							SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from DRAS.Extract_'' + Replace(@tableName, ''DRAS.'', '''') + '' with (nolock)) as t ''+ CHAR(13) + @joins
						END

						RETURN @selectStatment
						END
						'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 6, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 7
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650107', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 7', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650107 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			declare @sql nvarchar(max)

			IF not exists (select * from INFORMATION_SCHEMA.Columns where TABLE_NAME = 'Err_Valve' and COLUMN_NAME = 'ValveConditionDomainID')
			BEGIN
				set @sql = 'Alter table Err_Valve Add ValveConditionDomainID varchar(500)'
				EXEC sp_executesql @sql
			END

			IF not exists (select * from INFORMATION_SCHEMA.Columns where TABLE_NAME = 'Err_Valve' and COLUMN_NAME = 'ValveCondition')
			BEGIN
				set @sql = 'Alter table Err_Valve Add ValveCondition varchar(500)'
				EXEC sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650107 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 8
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650108', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 8', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650108 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Extract_Valve' And c.Column_Name = 'ValveWithinFenceInd')
			BEGIN
			ALTER TABLE [dbo].Extract_Valve ADD ValveWithinFenceInd [varchar](500) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Extract_Valve' And c.Column_Name = 'ValveQstnrPctFraction')
			BEGIN
			ALTER TABLE [dbo].Extract_Valve ADD ValveQstnrPctFraction [varchar](500) NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650108 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 9
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650109', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 9', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650109 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			declare @sql nvarchar(max)

			if not exists (select * from INFORMATION_SCHEMA.Columns where TABLE_NAME = 'Err_Valve' and COLUMN_NAME = 'ValveManufacturerDomainId')
			BEGIN
				SET @sql = 'ALTER TABLE Err_Valve ADD ValveManufacturerDomainId varchar(500)'
				EXEC sp_executesql @sql
			END

			if not exists (select * from INFORMATION_SCHEMA.Columns where TABLE_NAME = 'Err_Valve' and COLUMN_NAME = 'ValveManufacturer')
			BEGIN
				SET @sql = 'ALTER TABLE Err_Valve ADD ValveManufacturer varchar(500)'
				EXEC sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650109 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 10
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650110', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 10', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650110 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Recreate PipeSegmentVw View
			IF OBJECT_ID ('PipeSegmentVw', 'V') IS NOT NULL
			BEGIN
				EXECUTE('ALTER VIEW PipeSegmentVw as
				 WITH Chainage AS
				 (SELECT LineLoopId,
				 ss.Id,
				 ss.BeginStationNum,
				 ss.EndStationNum,
				 MIN(mlv.MLVSectionId) AS MLVSectionId,
				 MIN(mlv.FactorNum) AS FactorNum,
				 MIN(mlv.MultiplierNum) AS MultiplierNum
				 FROM StationSeries ss
				 INNER JOIN MLVCorrection mlv
				 ON ss.Id = mlv.StationSeriesId
				 GROUP BY LineLoopId,
				 ss.Id,
				 ss.BeginStationNum,
				 ss.EndStationNum
				 )
				SELECT LL.Id AS LineLoopId,
				 LL.LineName,
				 S1.MLVSectionName AS StartMLVSectionName,
				 S2.MLVSectionName AS EndMLVSectionName,
				 cast(TT.BeginStationNum * (SSBegin.MultiplierNum) + (SSBegin.FactorNum) as numeric(13,3)) AS StartDisplayChainage,
				 cast(TT.EndStationNum * (SSEnd.MultiplierNum) + (SSEnd.FactorNum) as numeric(13,3)) AS EndDisplayChainage,
				 TT.EffectiveStartDate,
				 PipeInserviceDate,
				 PipeOutsideDiameter,
				 PipeNominalDiameter,
				 CAST(ROUND(PipeWallThickness * 0.0393700787, 3) AS NUMERIC(5,3)) AS PipeWallThickness,
				 PipeGrade,
				 PipeRepairNumber,
				 PipeCutOutNumber,
				 PipeToughness,
				 PipeSeamDomainId,
				 PipeGirthWeldDomainId,
				 PipeWeldInspectPct,
				 PipeComment,
				 PipeHeatNumber,
				 PipeWelderID,
				 PipeNDENumber,
				 TT.BeginStationSeriesId,
				 TT.EndStationSeriesId,
				 PipeJointFactor,
				 PipeConvertedInd,
				 PipeManufacturer.Code AS PipeManufacturer,
				 PipeSeamOrientation.Code AS PipeSeamOrientation,
				 PipeSpecification.Code AS PipeSpecification,
				 PipeMaterial.Code AS PipeMaterial,
				 PipeConstructSeason.Code AS PipeConstructSeason,
				 PipeInstallContractor.Code AS PipeInstallContractor,
				 PipeNDETType.Code AS PipeNDETType,
				 PipeSubtype.Code AS PipeSubtype,
				 PipeManufacturerDomainId,
				 PipeSeamOrientationDomainId,
				 PipeSpecificationDomainId,
				 PipeMaterialDomainId,
				 PipeConstructSeasonDomainId,
				 PipeInstallContractorDomainId,
				 PipeNDETTypeDomainId,
				 PipeSubtypeDomainId
				FROM PipeSegment tt
				INNER JOIN Chainage SSBegin
				ON TT.BeginStationSeriesId = SSBegin.Id
				INNER JOIN Chainage SSEnd
				ON TT.EndStationSeriesId = SSEnd.Id
				INNER JOIN MLVSection S1
				ON S1.Id = SSBegin.MLVSectionId
				INNER JOIN MLVSection S2
				ON S2.Id = SSBegin.MLVSectionId
				JOIN LineLoop LL
				ON SSBegin.LineLoopId = LL.ID
				LEFT JOIN LD_PipeManufacturer PipeManufacturer
				ON TT.PipeManufacturerDomainId = PipeManufacturer.Id
				LEFT JOIN LD_PipeSeamOrientation PipeSeamOrientation
				ON TT.PipeSeamOrientationDomainId = PipeSeamOrientation.Id
				LEFT JOIN LD_PipeSpecification PipeSpecification
				ON TT.PipeSpecificationDomainId = PipeSpecification.Id
				LEFT JOIN LD_PipeMaterial PipeMaterial
				ON TT.PipeMaterialDomainId = PipeMaterial.Id
				LEFT JOIN LD_PipeConstructionSeason PipeConstructSeason
				ON TT.PipeConstructSeasonDomainId = PipeConstructSeason.Id
				LEFT JOIN LD_PipeInstallContractor PipeInstallContractor
				ON TT.PipeInstallContractorDomainId = PipeInstallContractor.Id
				LEFT JOIN LD_PipeNDETType PipeNDETType
				ON TT.PipeNDETTypeDomainId = PipeNDETType.Id
				LEFT JOIN LD_PipeSubtype PipeSubtype
				ON TT.PipeSubtypeDomainId = PipeSubtype.Id
				WHERE TT.EffectiveEndDate IS NULL')
			END

			-- 5_Modify_View_Definitions.sql
			/*

			This script updates the view definitions for views referencing the former ListDomain to reference the 
			new 'LD_' and 'GLD_' tables. Must be executed on the target database

			*/
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @ObjectDefinition NVARCHAR(MAX)
			DECLARE @FromClause NVARCHAR(300)
			DECLARE @JoinClause NVARCHAR(300)
			DECLARE @TableName NVARCHAR(100)
			DECLARE @StartIndex INT
			DECLARE @EndIndex INT
			DECLARE @ClauseStartIndex INT
			DECLARE @NextClauseIndex INT
			DECLARE @TableAlias NVARCHAR(100)
			DECLARE @MultiSpaceExists INT
			DECLARE @StrLength INT
			DECLARE @PreviousIndex INT
			DECLARE @ColumnName NVARCHAR(100)
			DECLARE @ViewName NVARCHAR(100)
			DECLARE @Type NVARCHAR(100)
			DECLARE @NewTableName NVARCHAR(100)
			DECLARE @Count INT
			DECLARE @ExemptTableList NVARCHAR(500)
			-------------------------------------- Table Declaration/Creation -------------------------

			IF OBJECT_ID ('SQLClauseTab_upgr') IS NOT NULL
			BEGIN
				DROP TABLE SQLClauseTab_upgr
			END

			IF OBJECT_ID ('SQLClauseTab_upgr') IS NULL
			BEGIN
				CREATE TABLE SQLClauseTab_upgr (StartIndex INT,
												Type VARCHAR(20),
												TableName NVARCHAR(100),
												TableAlias NVARCHAR(100),
												ColumnName NVARCHAR(100),
												NewLDTableName VARCHAR(100))

			END


			DECLARE ViewListCursor CURSOR FOR
			SELECT table_name FROM INFORMATION_SCHEMA.tables
			WHERE table_type = 'VIEW'	

			OPEN ViewListCursor
			FETCH NEXT FROM ViewListCursor INTO @ViewName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				--delete the SQLClauseTab_upgr and set the ListDomain table as the only table non-existing table allowed in view definition
				DELETE FROM SQLClauseTab_upgr
				SET @ExemptTableList = '''ListDomain'''

			---------------------- Remove multispacing from view definitions (double space, triple space, etc) ----------------------

				SET @ObjectDefinition = NULL

				SELECT @ObjectDefinition = OBJECT_DEFINITION (OBJECT_ID(N'dbo.' + @ViewName + ''));  

				SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)

				WHILE @MultiSpaceExists <> 0
				BEGIN
					SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, '  ', ' ') 
 					SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)
				END

				IF (CHARINDEX('ListDomain', @ObjectDefinition) <> 0)
				BEGIN

			-------------------------------- Find All FROM Clauses -----------------------------------

					SELECT @StrLength = LEN(@ObjectDefinition)
		 
					SET @StartIndex = 1

					WHILE @StartIndex < @StrLength
					BEGIN
						-- Get table name
						SELECT @ClauseStartIndex = CHARINDEX('FROM ', @ObjectDefinition, @StartIndex)

						IF (@ClauseStartIndex = 0)
						BEGIN
							BREAK
						END

						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @ClauseStartIndex) + 1

						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @Tablename = REPLACE(REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), ''), ',', '')

						-- Get table alias name
						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex  - @StartIndex)
						SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

						INSERT INTO SQLClauseTab_upgr
						VALUES (@ClauseStartIndex, 
								'FROM', 
								@TableName, 
								@TableAlias, 
								NULL, 
								NULL)

						IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
							AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
						BEGIN
							SET @ExemptTableList += ', ''' + @TableName+ ''''
						END

						SET @StartIndex = @EndIndex + 1

					END

			------------------------------------ Find All JOIN clauses ---------------------------------
	
					SET @StartIndex = 1

					WHILE @StartIndex < @StrLength
					BEGIN
						-- Get table name
						SELECT @ClauseStartIndex = CHARINDEX('JOIN ', @ObjectDefinition, @StartIndex) 

						SET @StartIndex = @ClauseStartIndex 

						IF (@StartIndex = 0)
						BEGIN
							BREAK
						END

						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @Tablename = REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), '')

						-- Get table alias name
						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

						INSERT INTO SQLClauseTab_upgr
						VALUES (@ClauseStartIndex, 
								'JOIN', 	
								@TableName, 
								@TableAlias, 
								NULL, 
								NULL)
						 
						IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
							AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
						BEGIN
							SET @ExemptTableList += ', ''' + @TableName+ ''''
						END

						SET @StartIndex = @EndIndex + 1
					END

			-------------------------------- Find all table-qualified columns within a View definition --------------------------------

			/*
				Find all table-qualifed columns in the 'ON' predicate of the JOIN clause of each view definition, then
				match the column (using the tables alias) to a table name.
			*/

					DECLARE ColumnList_Cursor CURSOR FOR
					SELECT DISTINCT TableAlias FROM SQLClauseTab_upgr
					WHERE TableAlias IS NOT NULL AND TableAlias <> ' '
					
					OPEN ColumnList_Cursor
					FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias

					WHILE @@FETCH_STATUS = 0
					BEGIN
						-- Find the very first JOIN clause in the View definition
						SELECT @StartIndex = MIN(StartIndex) FROM SQLClauseTab_upgr
						WHERE Type = 'JOIN'

						
						WHILE @StartIndex < @StrLength
						BEGIN
							-- Find the first instance of a table-qualified column reference using the current table alias
							SELECT @StartIndex = CHARINDEX(' ' + @TableAlias + '.', @ObjectDefinition, @StartIndex) 	

							-- Exit if no instance of a table-qualified reference for the current table alias is found 
							IF (@StartIndex = 0)
							BEGIN
								BREAK
							END

							-- Find the JOIN clause that comes before the first instance where the current table alias is used as table-qualified column in a JOIN predicate
							SELECT @ClauseStartIndex = MAX(StartIndex) FROM SQLClauseTab_upgr
							WHERE StartIndex < @StartIndex
							AND Type = 'JOIN'
																
							-- Get the start position of the column name (aliased using the current table alias) as part of the JOIN predicate
							SELECT @StartIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex) + 1

							-- Use the nearest whitespace after the table-qualified column reference to find the end of column name string
							IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex) AND CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) <> 0)
							BEGIN
								SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
							END
							ELSE
							BEGIN
								SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
							END

							-- If @StartIndex is non-zero and @EndIndex is 0 then you are at the end of the view definition
							IF @EndIndex = 0 AND @StartIndex > 0
							BEGIN
								SELECT @EndIndex = LEN(@ObjectDefinition) + 1
							END

							--Get the column name (aliased by the current table alias) from the JOIN predicate
							SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
							SELECT @ColumnName = REPLACE(REPLACE(@ColumnName, CHAR(13), ''), CHAR(10), '')
				

							INSERT INTO SQLClauseTab_upgr
							VALUES (@ClauseStartIndex, 
									'COLUMN', 
									(SELECT TOP 1 TableName FROM SQLClauseTab_upgr WHERE TableAlias = @TableAlias 
									AND TableName IS NOT NULL), 
									@TableAlias, 
									@ColumnName,
									NULL) 


							IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
								AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
							BEGIN
								SET @ExemptTableList += ', ''' + @TableName+ ''''
							END
						
							SET @StartIndex = @EndIndex + 1
						END
			
						FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias
					END

					CLOSE ColumnList_Cursor
					DEALLOCATE ColumnList_Cursor

					UPDATE SQLClauseTab_upgr
					SET TableName = REPLACE(TableName, 'dbo.', '')

			--------------- Match ListDomain entries in View Definition to new ListDomain tables ------------------------	

					-- Use the starting index of the JOIN operations to match the ListDomain Id column with the 
					SET @SQL = 'WITH tmpQuery AS (
								SELECT SCT.*, tmp.LDTableName 
								FROM SQLClauseTab_upgr SCT
								JOIN TempListDomainTable tmp
								ON tmp.ColumnName = SCT.ColumnName
								AND tmp.TableName = SCT.TableName
								WHERE SCT.StartIndex IN (SELECT StartIndex FROM SQLClauseTab_upgr
													WHERE TableName = ''ListDomain'')
								AND tmp.ColumnName IS NOT NULL
								)
								UPDATE SQLClauseTab_upgr
								SET NewLDTableName = Tab2.LDTableName
								FROM SQLClauseTab_upgr Tab1
								JOIN tmpQuery Tab2
								ON Tab1.StartIndex = Tab2.StartIndex
								WHERE Tab1.TableName = ''ListDomain'''

					EXECUTE sp_executesql @SQL

			----------------------- Store views that contain missing tables in a tmp table --------------------

				--SET @Count = 0

				IF OBJECT_ID('tmp_InvalidViews') IS NULL
				BEGIN
					CREATE TABLE tmp_InvalidViews (ViewName NVARCHAR(100),
													Definition NVARCHAR(MAX),
													DropCommand NVARCHAR(100))

				END

				-- Find all non-existing tables in the view definition
				SET @SQL = '
				IF OBJECT_ID(''Result_upgr'') IS NOT NULL
				BEGIN
					DROP TABLE Result_upgr
				END 

	
				SELECT DISTINCT(TableName) TableName
				INTO Result_upgr
				FROM SQLClauseTab_upgr
				WHERE TableName NOT IN (' + @ExemptTableList + ')
				AND TableName NOT IN (SELECT name FROM sys.tables)'

				EXECUTE sp_executesql @SQL
							   				
				-- Get count of missing/non-existing tables in view definition
				SELECT @Count = COUNT(*) FROM Result_upgr
				
				-- if the view definition has missing tables add the view name and definition to tmp_InvalidViews if not already there
				IF (@Count <> 0)
				BEGIN
					
					IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName = @ViewName)
					BEGIN
						INSERT INTO tmp_InvalidViews
						SELECT @ViewName, 
								'EXEC sp_helptext N''dbo.' + @ViewName + '''',
								'DROP VIEW ' + @ViewName + ''
					
					END

				END
		
			/*********************************************************************************************************
												Modify View Definiion 
			**********************************************************************************************************/

			--------------------------------- Modify View Definition ----------------------------

					DECLARE SearchNReplaceCursor CURSOR FOR
					SELECT StartIndex, Type, TableName, TableAlias, NewLDTableName 
					FROM SQLClauseTab_upgr
					WHERE StartIndex IN (SELECT StartIndex FROM SQLClauseTab_upgr
										WHERE TableName = 'ListDomain')
					AND TableName = 'ListDomain'
					AND NewLDTableName IS NOT NULL

					OPEN SearchNReplaceCursor
					FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

					WHILE @@FETCH_STATUS = 0
					BEGIN
						-- Replace ListDomain table wherever it is mentioned with the new list domain table name
						SELECT @ObjectDefinition = REPLACE (@ObjectDefinition, 
										@TableName + ' ' + @TableAlias,
										@NewTableName + ' ' + @TableAlias)
													
						FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

					END 
	
					CLOSE SearchNReplaceCursor
					DEALLOCATE SearchNReplaceCursor

			-------------------------------------- Recreate View -------------------------------------------
		
					SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, 'Create View', 'CREATE OR ALTER VIEW')
					
					-- Create or alter the view if all the tables in view deinition exist
					IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName =  @ViewName)
					BEGIN
						BEGIN TRY
							EXECUTE (@ObjectDefinition)
						END TRY
						BEGIN CATCH
							PRINT CHAR(10) + 'Failing SQL: ' + CHAR(10) + @ObjectDefinition + CHAR(10);
							DEALLOCATE ViewListCursor;
							THROW
						END CATCH
					END

				END

				FETCH NEXT FROM ViewListCursor INTO @ViewName

			END

			CLOSE ViewListCursor
			DEALLOCATE ViewListCursor

			IF OBJECT_ID ('tmp_InvalidViews') IS NOT NULL
			BEGIN
				IF EXISTS (SELECT 1 FROM tmp_InvalidViews) 
				BEGIN
					SELECT 'Invalid view found'
					SELECT * FROM tmp_InvalidViews
				END
				ELSE
				BEGIN
					DROP TABLE tmp_InvalidViews
				END
			END

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL + CHAR(10), '') + 'DROP TABLE ' + name
			FROM sys.tables WHERE name LIKE '%[_]upgr%'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650110 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 11
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650111', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 11', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650111 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			declare @sql nvarchar(max)

			SET @sql = 'if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = ''tmpRememberedListDomainValues'') 
			BEGIN
				drop table tmpRememberedListDomainValues
			END'

			Exec sp_executesql @sql

			SET @sql = 'select * into tmpRememberedListDomainValues  from RememberedListDomainValues '

			Exec sp_executesql @sql

			SET @sql = 'DROP TABLE RememberedListDomainValues'

			Exec sp_executesql @sql

			SET @sql = 'CREATE TABLE [dbo].[RememberedListDomainValues](
				[Id] [numeric](18, 0) Identity(1,1) NOT NULL,
				[DomainValue] [varchar](255) NULL,
				[ListDomainID] [int] NULL,
				[ListDomainTableSchema] [sysname] NULL,
				[ListDomainTableName] [nvarchar](100) NULL,
				[CreatedUser] [varchar](64) DEFAULT (suser_sname()) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[LastModByUserId] [varchar](64)DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			 CONSTRAINT [PK_RememberedListDomainValues] PRIMARY KEY CLUSTERED 
			(
				[Id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'

			EXEC sp_executesql @sql

			SET @sql = 'CREATE TRIGGER [dbo].[tu_RememberedListDomainValues] ON [dbo].[RememberedListDomainValues] FOR UPDATE AS 
								IF EXISTS(SELECT * FROM DELETED)
								BEGIN
									UPDATE dbo.RememberedListDomainValues
									SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
									FROM dbo.RememberedListDomainValues as t, DELETED as d
									WHERE t.Id=d.Id;
								END'

			EXEC sp_executesql @sql

			SET @sql = 'ALTER TABLE [dbo].[RememberedListDomainValues] ENABLE TRIGGER [tu_RememberedListDomainValues]'
			EXEC sp_executesql @sql

			SET @SQL = 'SET Identity_Insert RememberedListDomainValues ON
			INSERT INTO RememberedListDomainValues(Id,DomainValue,ListDomainID,ListDomainTableSchema,ListDomainTableName) 
			SELECT Id,DomainValue,ListDomainID,ListDomainTableSchema,ListDomainTableName FROM tmpRememberedListDomainValues
			SET Identity_Insert RememberedListDomainValues OFF'

			EXECUTE (@SQL)

			SET @sql = 'if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = ''tmpRememberedListDomainValues'') 
			BEGIN
				drop table tmpRememberedListDomainValues
			END'

			EXEC sp_executesql @sql

			-- Save a copy of SystemPreferences table
			IF OBJECT_ID('SystemPreferences_BKP') IS NULL
			BEGIN
				SELECT * INTO SystemPreferences_BKP 
				FROM SystemPreferences
			END

			-- Update ListDomain Ids in SystemPreferences table
			UPDATE SystemPreferences 
			SET value = CASE WHEN New_Id IS NULL THEN Old_Id ELSE New_Id END
			FROM SystemPreferences sp
			JOIN Temp_ListDomain ld ON CAST(sp.value AS INT) = Old_Id
			WHERE ParameterName LIKE 'Default%'
			AND value LIKE '[0-9]%[0-9]'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650111 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 12
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650112', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 12', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650112 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			
			----------------------------- Assign value to blank Code columns in LD tables ---------------------------
			
			DECLARE @TableName NVARCHAR(100)
			DECLARE @SchemaName NVARCHAR(100)
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @ColumnList NVARCHAR(MAX)

			-- Update LD table Code and Descr columns containing an empty string or whitespace with "Unknown - #?"

			DECLARE LDTable_Cursor CURSOR FOR
			SELECT table_schema, table_name FROM INFORMATION_SCHEMA.tables
			WHERE table_name LIKE 'LD[_]%'

			OPEN LDTable_Cursor
			FETCH NEXT FROM LDTable_Cursor INTO @SchemaName, @TableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL = 'IF EXISTS (SELECT * FROM ' + @SchemaName + '.' + @TableName + ' 
										WHERE Code IS NULL 
										OR REPLACE(REPLACE(REPLACE(REPLACE(Code, CHAR(32), ''''), CHAR(9), ''''), CHAR(10), ''''), CHAR(13), '''') = '''')
							BEGIN
								WITH CTE AS
								(SELECT *, 
										ROW_NUMBER() 
											OVER (ORDER BY (SELECT COUNT(*) FROM ' + @SchemaName + '.' + @TableName + ' 
															WHERE Code = ''Unknown'')
												 ) + 1 CNT

								 FROM ' + @SchemaName + '.' + @TableName + '
								 WHERE Code IS NULL 
									OR REPLACE(REPLACE(REPLACE(REPLACE(Code, CHAR(32), ''''), CHAR(9), ''''), CHAR(10), ''''), CHAR(13), '''') = ''''
								)
								UPDATE CTE
								SET Code = ''Unknown - #'' + CAST(CNT AS VARCHAR),
									Descr = ''Unknown - #'' + CAST(CNT AS VARCHAR)
							END'

				EXECUTE (@SQL)
				FETCH NEXT FROM LDTable_Cursor INTO @SchemaName, @TableName
			END
			CLOSE LDTable_Cursor
			DEALLOCATE LDTable_Cursor

			------------------------ Make all Virtual table Id columns Identity columns ----------------------
			
			IF OBJECT_ID ('SavedConstraints_upgr') IS NOT NULL
			BEGIN
				DROP TABLE SavedConstraints_upgr
			END

			-- Save foreign key definitions
			SELECT DISTINCT OBJECT_NAME(fkc1.parent_object_id ) AS TableName, 
					OBJECT_NAME(constraint_object_id) AS ConstraintName,
					'Foreign Key' AS Type,
			'IF OBJECT_ID (''' + SCHEMA_NAME(tab.schema_id) + '.' + OBJECT_NAME(constraint_object_id) + ''', ''F'') IS NULL
			BEGIN
				ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(tab.schema_id)) +'.'+ QUOTENAME(OBJECT_NAME(fkc1.parent_object_id) )
			+ ' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(OBJECT_NAME(constraint_object_id)) 
			+ CHAR(10) + 'FOREIGN KEY(' + (SELECT STUFF(
														(SELECT ', ' + QUOTENAME(COL_NAME(fkc2.parent_object_id, fkc2.parent_column_id))
															FROM sys.foreign_key_columns fkc2 
															WHERE constraint_object_id = fkc1.constraint_object_id
															FOR XML PATH(N''), TYPE
															).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
														)
										)
			+ CHAR(10) + ') REFERENCES ' + QUOTENAME(SCHEMA_NAME(tab2.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(fkc1.referenced_object_id)) + '(' 
			+ (SELECT STUFF(
							(SELECT ', ' + QUOTENAME(COL_NAME(fkc2.referenced_object_id, fkc2.referenced_column_id))
							FROM sys.foreign_key_columns fkc2 
							WHERE constraint_object_id = fkc1.constraint_object_id
							FOR XML PATH(N''), TYPE
							).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
							)
				)
				+')' + CHAR(10) + 'END' AS ConstraintDefinition
			INTO SavedConstraints_upgr
			FROM sys.foreign_key_columns fkc1
			JOIN sys.tables tab
			ON tab.object_id = fkc1.parent_object_id
			JOIN sys.tables tab2 
			ON tab2.object_id = fkc1.referenced_object_id
			WHERE EXISTS (SELECT * FROM sys.columns  c JOIN sys.tables t ON t.object_id = c.object_id
							WHERE c.name = 'Id' AND SCHEMA_NAME(schema_id) IN ('DRAS')
							AND is_identity = 0
							AND t.object_id = fkc1.parent_object_id) 

			-- Save Primary key definitions
			INSERT INTO SavedConstraints_upgr
			SELECT DISTINCT OBJECT_NAME(ic.object_id), 
				   i.name,
				   'Primary Key',
			'IF OBJECT_ID (''' + SCHEMA_NAME(schema_id) + '.' + i.name + ''', ''PK'') IS NULL
			BEGIN
			ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(ic.object_id) + ' WITH CHECK ADD CONSTRAINT ' + i.name  
			+ ' PRIMARY KEY ' + i.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS  + ' ('
			+ (SELECT STUFF(
							(SELECT ', ' + COL_NAME(object_id, column_id) +
								CASE WHEN is_descending_key = 1 THEN ' DESC'
									ELSE ' ASC'
								END
							FROM sys.index_columns 
							WHERE object_id = ic.object_id
								AND index_id = ic.index_id
							ORDER BY key_ordinal
							FOR XML PATH(N''), TYPE
							).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
						)
			
				) + ') 
				END;'
			FROM sys.indexes i
			JOIN sys.index_columns ic
			ON i.object_id = ic.object_id
			AND i.index_id = ic.index_id
			JOIN sys.tables t ON t.object_id = i.object_id 
			WHERE i.is_primary_key = 1
			AND OBJECT_NAME(i.object_id) IN (SELECT TableName FROM SavedConstraints_upgr 
											WHERE TableName IN (SELECT OBJECT_NAME(object_id) 
																FROM sys.indexes WHERE is_primary_key = 1)
											)
			AND NOT EXISTS (SELECT * FROM SavedConstraints_upgr WHERE ConstraintName = i.name)

			DECLARE VirtualTables_Cursor CURSOR FOR
			SELECT DISTINCT SCHEMA_NAME(schema_id) SchemaName, t.name
			FROM sys.columns c 
			JOIN sys.tables t ON c.object_id = t.object_id
			WHERE t.name NOT LIKE 'LD[_]%' AND SCHEMA_NAME(schema_id) = 'DRAS'
			AND c.name = 'Id' AND is_identity = 0

			OPEN VirtualTables_Cursor
			FETCH NEXT FROM VirtualTables_Cursor INTO @SchemaName, @TableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME('tmp_' + @TableName) + '('

				SET @ColumnList = NULL

				SELECT @ColumnList = COALESCE(@ColumnList + ',' + CHAR(10), '') + column_name + ' ' + data_type + 
					CASE WHEN data_type = 'numeric' THEN '(' + CAST(numeric_precision AS NVARCHAR) + ', ' + CAST(numeric_scale AS NVARCHAR) + ')'
						 WHEN data_type LIKE '%char%' THEN '(' + CAST(character_maximum_length AS NVARCHAR) + ')'
						 ELSE '' 
					END +
					CASE WHEN column_name = 'Id' THEN ' IDENTITY(1,1) ' ELSE '' END +
					CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' + column_default ELSE '' END
					+ CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END 
				FROM INFORMATION_SCHEMA.columns 
				WHERE table_name = @TableName
				AND table_schema = @SchemaName

				SET @SQL += @ColumnList + ')'

				SET @ColumnList = NULL
				SELECT @ColumnList = COALESCE(@ColumnList + ',' + CHAR(10), '') + column_name 
				FROM INFORMATION_SCHEMA.columns 
				WHERE table_name = @TableName
				AND table_schema = @SchemaName
				ORDER BY ordinal_position

				SET @SQL += CHAR(10) + 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME('tmp_' + @TableName) + ' ON 
				INSERT INTO '  + QUOTENAME(@SchemaName) + '.' + QUOTENAME('tmp_' + @TableName) + '(' + @ColumnList + ')'
				+ CHAR(10) + 'SELECT * FROM '  + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
				CHAR(10) + 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME('tmp_' + @TableName) + ' OFF '
				+ CHAR(10) + 'DROP TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) 
				+ CHAR(10) + 'EXECUTE sp_rename ''' + @SchemaName + '.' + 'tmp_' + @TableName  + ''', ''' + @TableName + ''''
				+ CHAR(10)

				SELECT @SQL = COALESCE (@SQL + CHAR(10), '') + ConstraintDefinition 
				FROM SavedConstraints_upgr
				WHERE TableName = @TableName
				AND Type <> 'Foreign Key'
	
				-- recreate tables with missing IDENTITY property on Id columns
				IF OBJECT_ID (@SchemaName + '.' + @TableName) IS NOT NULL
				BEGIN
					BEGIN TRY
						EXECUTE(@SQL)
					END try
					begin catch
						print @sql;
						throw
					end catch
				END

				FETCH NEXT FROM VirtualTables_Cursor INTO @SchemaName, @TableName
			END

			CLOSE VirtualTables_Cursor
			DEALLOCATE VirtualTables_Cursor

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL + CHAR(10), '') + 'DROP TABLE ' + name
			FROM sys.tables WHERE name LIKE '%[_]upgr'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO
 
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650112 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 13
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650113', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 13', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650113 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @TableName NVARCHAR(100)
			DECLARE @SchemaName NVARCHAR(100)

			DECLARE UpdateData_Cur CURSOR FOR
			SELECT table_schema, table_name 
			FROM INFORMATION_SCHEMA.tables WHERE table_name LIKE 'LD[_]%'

			OPEN UpdateData_Cur
			FETCH NEXT FROM UpdateData_Cur INTO @SchemaName, @TableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL = 'IF EXISTS (SELECT * FROM ' + @SchemaName + '.' + @TableName + ' nld' + CHAR(10)
				 + 'JOIN ListDomain_BKP ld ON ld.Id = nld.Id
				 WHERE nld.Code <> ld.Code OR nld.Descr <> ld.Descr)
				 BEGIN
		
					UPDATE ' + @SchemaName + '.' + @TableName + '
					SET Code = ld.Code, 
						Descr = ld.Descr
					FROM ' + @SchemaName + '.' + @TableName + ' nld' + CHAR(10)
					+ 'JOIN ListDomain_BKP ld ON ld.Id = nld.Id
					WHERE nld.Code <> ld.Code OR nld.Descr <> ld.Descr
				 END'

				EXECUTE (@SQL)

				FETCH NEXT FROM UpdateData_Cur INTO @SchemaName, @TableName
			END

			CLOSE UpdateData_Cur
			DEALLOCATE UpdateData_Cur

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650113 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 14
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650114', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 14', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650114 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @TableName VARCHAR(200)
			DECLARE @SchemaName VARCHAR(200)
			
			-- Modify stored proc for inserting new Listdomains into LD table to exclude duplicate data
			SET @SQL = 'CREATE OR ALTER PROCEDURE [dbo].[sp_InsertNewListDomains]  
			(  
			@tableName              VARCHAR(250),   
			@domainCatalogTableName VARCHAR(250) = NULL,   
			@isVirtualTable         BIT          = 0  
			)  
			AS  
			BEGIN  
			IF @domainCatalogTableName IS NULL  
				BEGIN  
				SET @domainCatalogTableName = @tableName;  
				END;  
			DECLARE @TrimSQL AS NVARCHAR(MAX)= '''';  
			IF @isVirtualTable = 0  
				BEGIN  
				SELECT @TrimSQL = ''update  extract_'' + @tableName + '' set  '' + STUFF(  
				(  
				SELECT '','' + tmp.ColumnName + '' = left( '' + tmp.ColumnName + '' , 40)''  
				FROM StageFKeysInfo tmp  
				WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName  
				FOR XML PATH(''''), TYPE  
				).value(''.'', ''NVARCHAR(MAX)''), 1, 1, '''');  
				END;  
				ELSE  
				BEGIN  
				SELECT @TrimSQL = ''update  DRAS.Extract_'' + @tableName + '' set DataFieldValueDomainId = left( DataFieldValueDomainId , 40)'';  
				END;  
			PRINT @TrimSQL;  
			EXEC (@TrimSQL);  
          
			DECLARE @sql NVARCHAR(MAX)  
			DECLARE i_cursor CURSOR FOR  
				SELECT ''INSERT INTO ''   
				+ CASE WHEN @isVirtualTable = 0 THEN tmp.ReferencedTable ELSE ''DRAS.'' + tmp.ReferencedTable END  
				+ ''(Code, Descr) Select DISTINCT ''   
				+ CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END   
				+ '','' + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END + '' FROM ''   
				+ CASE WHEN @isVirtualTable = 0 THEN '''' ELSE ''DRAS.'' END + ''Extract_''   
				+ tmp.TableName + '' WHERE ''   
				+ + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END  
				+ '' NOT IN (SELECT CODE FROM ''   
				+ CASE WHEN @isVirtualTable = 0 THEN tmp.ReferencedTable ELSE ''DRAS.'' + tmp.ReferencedTable END + '') AND ''   
				+ + CASE WHEN @isVirtualTable = 0 THEN tmp.ColumnName ELSE ''DataFieldValueDomainId'' END  
				+ '' IS NOT NULL''   
				FROM StageFKeysInfo tmp  
				WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName  
    
			OPEN i_cursor  
				FETCH NEXT FROM i_cursor INTO @sql  
  
				WHILE @@FETCH_STATUS = 0  
				BEGIN  
				PRINT @sql;  
				EXEC (@sql);  
      
				FETCH NEXT FROM i_cursor INTO @sql  
				END  
  
			CLOSE i_cursor  
			DEALLOCATE i_cursor  
			END;'

			EXECUTE (@SQL)

			------------------------------------- Add missing ListDomain Ids to tables -----------------------------------

			-- Add missing ListDomain Ids to RememberedListDomainValues table
			UPDATE RememberedListDomainValues
			SET ListDomainID = rld2.ListDomainID
			FROM RememberedListDomainValues rld
			JOIN RememberedListDomainValues_BKP rld2 ON rld.Id = rld2.Id
			WHERE rld.ListDomainID IS NULL

			IF COL_LENGTH('CategoryDataListDomainXRef', 'New_Id') IS NOT NULL
			BEGIN
				EXECUTE sp_rename 'dbo.CategoryDataListDomainXRef.New_Id', 'ListDomainId', 'COLUMN';
			END

			-- Make the CreatedUser column in CategoryDataListDomainXRef table a varchar column if it is not
			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = 'CategoryDataListDomainXRef' AND column_name = 'CreatedUser' AND data_type <> 'varchar')
			BEGIN
				SELECT @SQL = 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' DROP CONSTRAINT ' + name
				FROM sys.default_constraints 
				WHERE OBJECT_NAME(parent_object_id) = 'CategoryDataListDomainXRef'
				AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedUser'

				EXECUTE (@SQL)

				ALTER TABLE CategoryDataListDomainXRef ALTER COLUMN CreatedUser VARCHAR(45) 
				ALTER TABLE CategoryDataListDomainXRef ADD CONSTRAINT DF__CategoryD__Creat__77D73C2F DEFAULT suser_sname() FOR CreatedUser
			END

			IF COL_LENGTH('CategoryDataListDomainXRef', 'LastModByUserId') IS NOT NULL
			BEGIN
				EXECUTE sp_rename 'dbo.CategoryDataListDomainXRef.LastModByUserId', 'LastModByUserId', 'COLUMN'
			END

			-- Update NULL values of LDTableName, ListDomainTableName, and CreatedUser in CategoryDataListDomainXRef table
			SET @SQL = 'UPDATE cd
			SET ListDomainId = cd2.ValueDomainId
			FROM CategoryDataListDomainXRef cd
			JOIN CategoryDataListDomainXRef_BKP cd2 ON cd.Id = cd2.Id
			WHERE cd.ListDomainId IS NULL
					
			UPDATE cd
			SET ListDomainTableName = COALESCE(cd.ListDomainTableName, tld.LDTableName, ld.LDTableName),
				ListDomainTableSchema = COALESCE((SELECT table_schema FROM INFORMATION_SCHEMA.tables 
					WHERE table_name = COALESCE(cd.ListDomainTableName, tld.LDTableName, vtld.LDTableName, ld.LDTableName)), ''dbo''),
				CreatedUser = CASE WHEN cd.CreatedUser IS NULL THEN cd.LastModByUserId ELSE cd.CreatedUser END
			FROM CategoryDataListDomainXRef cd
			LEFT JOIN Temp_ListDomain ld ON ld.Old_Id = cd.ListDomainId
			LEFT JOIN TempListdomainTable tld ON tld.DomainCatalogId = ld.DomainCatalogId
			LEFT JOIN Temp_VirtualTableDataListDomain vtld ON vtld.Old_DataFieldValueDomainId = cd.ListDomainId
			WHERE cd.ListDomainTableName IS NULL OR cd.ListDomainTableSchema IS NULL OR cd.CreatedUser IS NULL'

			EXECUTE (@SQL)

			-- Create missing LD tables mentioned in CategoryDataListDomainXRef, RememberedListDomainValues and ActionItemPropDCXRef
			DECLARE CreateTable_Cursor CURSOR FOR
			SELECT DISTINCT ListDomainTableSchema, ListDomainTableName FROM CategoryDataListDomainXRef 
			WHERE ListDomainTableName NOT IN (SELECT name FROM sys.tables)
			UNION 
			SELECT DISTINCT ListDomainTableSchema, ListDomainTableName FROM RememberedListDomainValues
			WHERE ListDomainTableName NOT IN (SELECT name FROM sys.tables)
			UNION
			SELECT DISTINCT ListDomainTableSchema, ListDomainTableName FROM ActionItemPropDCXRef
			WHERE ListDomainTableName NOT IN (SELECT name FROM sys.tables)

			OPEN CreateTable_Cursor
			FETCH NEXT FROM CreateTable_Cursor INTO @SchemaName, @TableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' +QUOTENAME( @TableName) + '(
					[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
					[Code] varchar(60) NOT NULL,
					[Descr] varchar(255) NOT NULL,
					[EffectiveEndDate] Datetime,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL
					)';

				EXECUTE (@SQL)

				INSERT INTO TempListDomainTable (TableType, LDTableSchema, LDTableName, DomainCatalogId, DomainDescr)
				SELECT DISTINCT CASE WHEN @SchemaName = 'DRAS' THEN 'Virtual' ELSE 'Real' END,
						@SchemaName, @TableName, DomainCatalogId, DomainDescr
				FROM Temp_ListDomain WHERE LDTableName = @TableName
				AND NOT EXISTS (SELECT * FROM TempListDomainTable WHERE LDTableName = @TableName)

				FETCH NEXT FROM CreateTable_Cursor INTO @SchemaName, @TableName
			END

			CLOSE CreateTable_Cursor
			DEALLOCATE CreateTable_Cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650114 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 15
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650115', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 15', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650115 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
DECLARE @sql nvarchar(max)

			SET @sql = 'ALTER function [dbo].[fn_GenerateTransfromSelectStatement]
						(
							@tableName varchar(200) 
						)
						returns varchar(max)
						AS
						BEGIN

						DECLARE @column_names varchar(max) = ''''
						DECLARE @column_name varchar(100)
						DECLARE @column_short_name varchar(100)
						DECLARE @joins varchar(max) = ''''
						DECLARE @selectStatment varchar(max) = ''''
						DECLARE @refTableCount int 
						DECLARE @refParentTableCount int 
						DECLARE @fromUnit varchar(50)
						DECLARE @toUnit varchar(50)
						DECLARE @precision varchar(10)
						DECLARE @scale varchar(10)
						DECLARE @conversionVariables varchar(max) = ''''
						DECLARE @execConversions varchar(max) = ''''
						DECLARE @tempconversionVariables varchar(max) = ''''
						DECLARE @exectempConversions varchar(max) = ''''
						DECLARE @ldTableName varchar(100) = ''''
						DECLARE @IsListDomain int = 0

						-- Check whether the table is virtual table

						IF EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @tableName AND TABLE_SCHEMA = ''DRAS'')
						BEGIN
							SET @tableName = ''DRAS.'' + @tableName
						END

						-- Create temp listdomain table variable
						Declare @ListDomain TABLE (
						FK_Name varchar(100), TableName varchar(100), ColumnName varchar(100), ReferencedTable varchar(100), ReferencedColumn varchar(100))

						Insert into @ListDomain
						SELECT FK_Name, TableName, ColumnName, ReferencedTable, ReferencedColumn 
						FROM StageFkeysInfo tmp
						WHERE tmp.ReferencedTable like ''LD_%''
						order by tablename

						-- Generate variables for conversion - no temperature
						DECLARE cv_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')
						OPEN cv_cursor
							FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + '' ''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + ''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) '' + CHAR(13)
								FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit
							END
						CLOSE cv_cursor
						DEALLOCATE cv_cursor

						-- Generate exec conversion stored proc - no temperature
						DECLARE ec_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')

						OPEN ec_cursor
							FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + '' ''
							END


							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + ''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', NULL, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit
							END
						CLOSE ec_cursor
						DEALLOCATE ec_cursor

						-- Generate variables for conversion - temperature
						DECLARE tcv_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tcv_cursor
							FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @tempconversionVariables =''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) , @TempOffset numeric(13,5)'' + CHAR(13)
								FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tcv_cursor
						DEALLOCATE tcv_cursor

						-- Generate exec conversion stored proc - temperature
						DECLARE tec_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE   (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tec_cursor
							FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @exectempConversions =''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', @TempOffset OUTPUT, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tec_cursor
						DEALLOCATE tec_cursor

						SET @column_names = ''Id = case when t.SourceId not like ''''%[^0-9]%'''' then t.SourceId else IDLookup.Id end '' + CHAR(13)

						-- Get StationSeriesId columns
						DECLARE s_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							AND c.Column_Name LIKE ''%StationSeriesId'' ORDER BY c.Column_Name

						SET @refTableCount = 1
						OPEN s_cursor
							FETCH NEXT FROM s_cursor INTO @column_name
	
							IF @@FETCH_STATUS = 0
							BEGIN
								SET @column_names = @column_names + '',''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF @column_name <> ''StationSeriesId''
								BEGIN
									SET @column_names = @column_names + ''ss'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', '' 

									SET @joins = @joins + '' LEFT JOIN StationSeries ss'' + cast(@refTableCount AS varchar(10)) + '' with (nolock) ON ss'' + cast(@refTableCount AS varchar(10)) + ''.SourceId = t.'' + @column_name + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + ''ss1.Id AS '' + @column_name + '', '' 
								END

								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM s_cursor INTO @column_name
							END

						CLOSE s_cursor
						DEALLOCATE s_cursor

						IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where (c.Table_Name = @tableName or c.Table_Name = Replace(@tableName, ''DRAS.'', '''')) AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId''))
						BEGIN
							IF right(@column_names, 1) = '',''
							BEGIN
								SET @column_names = subString(@column_names, 1, len(@column_names)-1)
							END

							SET @column_names = @column_names + 
								(SELECT Cols = STUFF((SELECT  '', '' + CASE WHEN c.Column_Name = ''BeginStationSeriesId'' THEN ''BeginStationSeriesGUID'' WHEN c.Column_Name = ''EndStationSeriesId'' THEN ''EndStationSeriesGUID'' WHEN c.Column_Name = ''StationSeriesId'' THEN ''StationSeriesGUID'' END + '' = t.'' + QUOTENAME(c.Column_Name)
								FROM INFORMATION_SCHEMA.COLUMNS c	
								WHERE (table_name = @tableName or table_name = Replace(@tableName, ''DRAS.'', ''''))
								AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId'')
								ORDER BY c.Column_Name
								FOR XML PATH('''')), 1, 2, ''''))
						END

						-- Get ListDomain columns
						IF EXISTS (Select * from StageFKeysInfo where ReferencedTable LIKE ''LD%'' AND TableName = CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN REPLACE(@tableName, ''DRAS.'', '''') ELSE ''MLVCorrection'' END)
						BEGIN
							SET @IsListDomain = 1
						END
						ELSE
						BEGIN
							SET @IsListDomain = 0
						END

						DECLARE l_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							And (Column_Name in (Select ColumnName from StageFKeysInfo where ReferencedTable LIKE ''LD%'') or Column_Name = ''DataFieldValueDomainId'')
							ORDER BY c.Column_Name


						SET @refTableCount = 1
						OPEN l_cursor
							FETCH NEXT FROM l_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN


								IF @column_name like ''%DomainId''
								BEGIN
									SET @column_short_name = replace(@column_name, ''DomainId'', '''')
								END
								ELSE
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''ld'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END

								IF @IsListDomain = 1
								BEGIN
									SET @joins = @joins + '' '' + (SELECT Replace(dbo.fn_ScriptJoinLDColumn(Replace(
			
									CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN @tableName ELSE ''MLVCorrection'' END
			
			
									, ''DRAS.'', ''''), @column_name, '' tbl'' + cast(@refTableCount AS varchar(10))), ''.Id'', ''.Code''))+ CHAR(13)
								END

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								IF @IsListDomain = 1
								BEGIN
									SET @column_names = @column_names + '', tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + '', Cast(null as numeric(10,0)) AS '' + @column_name + '', Cast(null as varchar(40)) AS '' + @column_short_name + CHAR(13)
								END

								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM l_cursor INTO @column_name

							END

						CLOSE l_cursor
						DEALLOCATE l_cursor

						-- Get ParentColumns columns
						DECLARE p_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							And Column_Name in (select ColumnName from StageFKeysInfo where TableName= case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END )
							And Column_Name NOT in (Select ColumnName from @ListDomain)
							AND Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'', ''BaseIliId'', ''Stg_ILIId'')
							ORDER BY c.Column_Name

						SET @refParentTableCount = 1
						OPEN p_cursor
							FETCH NEXT FROM p_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''Id'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END

								IF @column_name IN (''RCReasonTypeId'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.Code'')) + CHAR(13)
								END
								ELSE IF @column_name NOT IN (''RCScenarioID'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.SourceId'')) + CHAR(13)
								END
								ELSE
								BEGIN
									SET @joins = @joins + '' '' + (SELECT dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10)))) + CHAR(13)
								END

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								SET @refParentTableCount = @refParentTableCount + 1

								FETCH NEXT FROM p_cursor INTO @column_name
							END

						CLOSE p_cursor
						DEALLOCATE p_cursor

						IF NOT EXISTS (Select * from INFORMATION_SCHEMA.Tables where TABLE_NAME = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END AND TABLE_SCHEMA = ''DRAS'')
						BEGIN
							IF @TableName = ''DischargeSubSystem''
							BEGIN
								SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
									on IDLookup.GUID = t.SourceId
										and IDLookup.TableName = ''''Lineloop'''''' + CHAR(13)
							END
							ELSE IF @TableName = ''MLVSection''
							BEGIN
								SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
									on IDLookup.GUID = t.SourceId
										and IDLookup.TableName = ''''StationSeries'''''' + CHAR(13)
							END
							ELSE
							BEGIN
								SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
									on IDLookup.GUID = t.SourceId
										and IDLookup.TableName = '''''' + @TableName + '''''''' + CHAR(13)
							END
						END
						ELSE
						BEGIN
							SET @joins = @joins + '' LEFT JOIN VTGUIDLookup IDLookup with (nolock)
								on IDLookup.GUID = t.SourceId
									and IDLookup.TableName = '''''' + Replace(@tableName, ''DRAS.'', '''') + '''''''' + CHAR(13)
						END

						----Get columns which required conversion -- no temperature
						DECLARE c_cursor CURSOR FOR
							SELECT * FROM (
								SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
							) tmp
							ORDER BY ColumnName

						OPEN c_cursor
							FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END
								ELSE IF right(@column_names, 2) = '', ''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								IF @column_name <> ''StationNum''
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END

								FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE c_cursor
						DEALLOCATE c_cursor

						----Get columns which required conversion -- temperature

						DECLARE ct_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN ct_cursor
							FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', '' + @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE ct_cursor
						DEALLOCATE ct_cursor

						---- Get all other columns
						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + '','' +
						(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
						FROM INFORMATION_SCHEMA.Columns c 
						LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
						Where c.Table_Name = ''Extract_'' + Replace(@tableName, ''DRAS.'', '''')
						AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
						And sfi.ColumnName IS NULL
						AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'', ''DataFieldValueDomainId'')
						AND c.Column_Name NOT LIKE ''%StationNum''
						AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = Replace(@tableName, ''DRAS.'', ''''))
						ORDER BY c.Column_Name
						FOR XML PATH('''')), 1, 2, ''''))

						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + CHAR(13) +  '',[LastModDateTime] = getdate() 
						,[LastModByUserId] = SUSER_SNAME() 
						,t.[SourceId]
						,[CreatedDate] = getdate()  
						,[CreatedUser] = SUSER_SNAME() 
						,t.[CheckSumValue]''

						IF NOT EXISTS (Select * from INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''DRAS'' AND TABLE_NAME = Replace(@tableName, ''DRAS.'', ''''))
						BEGIN
							SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
						END
						ELSE
						BEGIN
							SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from DRAS.Extract_'' + Replace(@tableName, ''DRAS.'', '''') + '' with (nolock)) as t ''+ CHAR(13) + @joins
						END

						RETURN @selectStatment
						END'

			EXEC sp_executesql @sql
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650115 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 16
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650116', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 16', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650116 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @TableName VARCHAR(200)
			DECLARE @PKList VARCHAR(MAX)
			
			-- Add Default value to columns missing one for 'LastModByUserId', 'LastModDateTime', 'CreatedUser', 'CreatedDate' columns
			DECLARE AddDefault_Cur CURSOR FOR
			SELECT 'ALTER TABLE ' + tab.table_schema + '.' + tab.table_name + ' ADD CONSTRAINT DF_' + table_name + '_' + column_name + ' DEFAULT ' +
			CASE WHEN tab.column_name LIKE '%Date%' THEN ' GETDATE() ' ELSE ' SUSER_SNAME() ' END
			+ ' FOR ' + column_name
			FROM INFORMATION_SCHEMA.columns tab
			WHERE column_name IN ('LastModByUserId', 'LastModDateTime', 'CreatedUser', 'CreatedDate')
			AND column_default IS NULL 


			OPEN AddDefault_Cur
			FETCH NEXT FROM AddDefault_Cur INTO @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE (@SQL)

				FETCH NEXT FROM AddDefault_Cur INTO @SQL
			END
			

			CLOSE AddDefault_Cur
			DEALLOCATE AddDefault_Cur


			IF OBJECT_ID('Tmp_AddTriggerList') IS NOT NULL
			BEGIN
				DROP TABLE Tmp_AddTriggerList
			END

			-- Add an update trigger to tables missing one for 'LastModByUserId', 'LastModDateTime' columns
			SELECT DISTINCT table_name, table_schema, index_id
			INTO Tmp_AddTriggerList
			FROM INFORMATION_SCHEMA.columns tab
			JOIN sys.indexes i ON OBJECT_NAME(i.object_id) = tab.table_name
			AND is_primary_key = 1
			LEFT JOIN sys.triggers tr ON tab.table_name = OBJECT_NAME(tr.parent_id)
			WHERE column_name IN ('LastModByUserId', 'LastModDateTime')
			AND tr.name IS NULL AND table_name NOT LIKE 'Load[_]%'

			DECLARE AddTrigger_Cur CURSOR FOR
			SELECT DISTINCT table_name FROM Tmp_AddTriggerList


			OPEN AddTrigger_Cur
			FETCH NEXT FROM AddTrigger_Cur INTO @TableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @PKList = NULL

				SELECT @PKList = COALESCE(@PKList + ' AND ', '') + ' t.' +
						COL_NAME(ic.object_id, column_id) + ' = d.' + COL_NAME(ic.object_id, column_id)						  
				FROM sys.indexes i
				JOIN sys.index_columns ic
				ON i.object_id = ic.object_id
				AND i.index_id = ic.index_id
				WHERE is_primary_key = 1 AND OBJECT_NAME(i.object_id) = @TableName

				SELECT @SQL =  'CREATE TRIGGER ' + QUOTENAME(table_schema) + '.tu_' + table_name + ' ON ' + QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) + ' 
					FOR UPDATE AS   
					IF EXISTS(SELECT * FROM DELETED)  
					BEGIN  
						UPDATE ' + QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) + '   
						SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE()   
						FROM ' + QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) + '  as t, DELETED as d  
						WHERE ' + @PKList + ';
						END'
				FROM Tmp_AddTriggerList
				WHERE table_name = @TableName

				EXECUTE (@SQL)
					
				FETCH NEXT FROM AddTrigger_Cur INTO @TableName
			END

			CLOSE AddTrigger_Cur
			DEALLOCATE AddTrigger_Cur

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650116 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 17
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650117', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 17', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650117 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			Declare @sql nvarchar(max)

			IF object_id('sp_CreateCustomTable') IS NOT NULL
			BEGIN
				SET @sql = 'DROP Procedure sp_CreateCustomTable'
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE Procedure [dbo].[sp_CreateCustomTable] (
			@vtTableName varchar(100) = '''',
			@vtColumnName varchar(100) = '''',
			@columnType varchar(1) = '''' -- Type should be L = ListDomain, D = Date, F = Flag, I = Indicator, N = Number and S = String
			)
			AS
			BEGIN
				If ltrim(rtrim(@vtTableName)) = '''' or ltrim(rtrim(@vtColumnName)) = '''' or ltrim(rtrim(@columnType)) = ''''
				BEGIN
					RAISERROR (15600, -1, -1, ''sp_CreateCustomTable'');
					return
				END

				declare @sql nvarchar(max)

				IF NOT EXISTS (select * from INFORMATION_SCHEMA.TABLES Where TABLE_NAME = @vtTableName AND TABLE_SCHEMA = ''DRAS'')
				BEGIN
					SET @sql = ''CREATE TABLE [DRAS].['' + @vtTableName + ''](
									[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
									['' + @vtColumnName + ''] '' 
									+ Case When @columnType = ''L'' then ''[numeric](10, 0)''
										When @columnType = ''D'' then ''[datetime]''
										When @columnType = ''F'' then ''[numeric](1,0)''
										When @columnType = ''I'' then ''[char](1)''
										When @columnType = ''N'' then ''[float]''
										Else ''[varchar](512)'' END
									+ '' NULL,
									[EffectiveStartDate] [datetime] NULL,
									[EffectiveEndDate] [datetime] NULL,
									[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
									[BeginStationNum] [numeric](13, 5) NOT NULL,
									[EndStationSeriesId] [numeric](10, 0) NOT NULL,
									[EndStationNum] [numeric](13, 5) NOT NULL,
									[SourceId] [varchar](50) NULL,
									[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
									[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
									[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
									[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
									[CheckSumValue] [int] NULL,
								 CONSTRAINT [PK_'' + @vtTableName + ''] PRIMARY KEY CLUSTERED 
								(
									[Id] ASC
								)
								) ON [PRIMARY]''

					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + '']  WITH CHECK ADD  CONSTRAINT [FK_'' + @vtTableName + ''_BgnStnId] FOREIGN KEY([BeginStationSeriesId])
								REFERENCES [dbo].[StationSeries] ([Id])''
					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] CHECK CONSTRAINT [FK_'' + @vtTableName + ''_BgnStnId]''
					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + '']  WITH CHECK ADD  CONSTRAINT [FK_'' + @vtTableName + ''_EndStnId] FOREIGN KEY([EndStationSeriesId])
								REFERENCES [dbo].[StationSeries] ([Id])''
					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] CHECK CONSTRAINT [FK_'' + @vtTableName + ''_EndStnId]''
					EXEC sp_executesql @sql

					IF @columnType = ''L''
					BEGIN

						SET @sql = ''CREATE TABLE [DRAS].[LD_'' + @vtColumnName + ''_VT](
										[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
										[Code] [varchar](60) NOT NULL,
										[Descr] [varchar](255) NOT NULL,
										[EffectiveEndDate] [datetime] Default (NULL) NULL,
										[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
										[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
										[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
										[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
									 CONSTRAINT [PK_LD_'' + @vtColumnName + ''] PRIMARY KEY CLUSTERED 
									(
										[Id] ASC
									)
									) ON [PRIMARY]''
						EXEC sp_executesql @sql

						SET @sql = ''CREATE   TRIGGER [DRAS].[tu_LD_'' + @vtColumnName + ''_VT] ON [DRAS].[LD_'' + @vtColumnName + ''_VT] FOR UPDATE AS 
												IF EXISTS(SELECT * FROM DELETED)
												BEGIN
													UPDATE DRAS.LD_'' + @vtColumnName + ''_VT
													SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
													FROM DRAS.LD_'' + @vtColumnName + ''_VT as t, DELETED as d
													WHERE t.Id=d.Id;
												END''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].[LD_'' + @vtColumnName + ''_VT] ENABLE TRIGGER [tu_LD_'' + @vtColumnName + ''_VT]''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + '']  WITH CHECK ADD  CONSTRAINT [FK_'' + @vtColumnName + ''LD] FOREIGN KEY(['' + @vtColumnName + ''])
									REFERENCES [DRAS].[LD_'' + @vtColumnName + ''_VT] ([Id])''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] CHECK CONSTRAINT [FK_'' + @vtColumnName + ''LD]''
						EXEC sp_executesql @sql
					END

					SET @sql = ''CREATE   TRIGGER [DRAS].[tu_'' + @vtTableName + ''] ON [DRAS].['' + @vtTableName + ''] FOR UPDATE AS 
											IF EXISTS(SELECT * FROM DELETED)
											BEGIN
												UPDATE DRAS.'' + @vtTableName + ''
												SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
												FROM DRAS.'' + @vtTableName + '' as t, DELETED as d
												WHERE t.Id=d.Id;
											END''
					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] ENABLE TRIGGER [tu_'' + @vtTableName + '']''
					EXEC sp_executesql @sql

				END
			END'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650117 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 18
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650118', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 18', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650118 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			------------------------------ Add missing data to virtual tables ------------------------------
			
			DECLARE @VirtualTableName NVARCHAR(100)
			DECLARE @VirtualColumnName NVARCHAR(100)
			DECLARE @VirtualTableId INT
			DECLARE @VCDataTypeTable NVARCHAR(100)
			DECLARE @VCDataTypeColumn NVARCHAR(100)
			DECLARE @ForeignKeyName NVARCHAR(100)
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @ColumnList NVARCHAR(MAX)
			DECLARE @JoinList NVARCHAR(MAX)
			DECLARE @Counter INT = 1
			DECLARE @LDTableName NVARCHAR(100)
			DECLARE @NewTableName NVARCHAR(100)
			DECLARE @ErrorMessage NVARCHAR(MAX)
			DECLARE @Schema NVARCHAR(200)
			DECLARE @flag INT

			IF OBJECT_ID ('VirtualColumn_upgr') IS NOT NULL
			BEGIN
				DROP TABLE VirtualColumn_upgr
			END

			
			/*
				Create temporary table to store the VirtualColumn values and the table name for the table associated with the 
				VirtualColumnDataTypeInd column
			*/


			SELECT vt.Id VirtualTableId,
					vc.Id VirtualColumnId, 
					REPLACE(VirtualTableName, CHAR(32), '') AS VirtualTableName,
					REPLACE(VirtualColumnName, CHAR(32), '') AS VirtualColumnName,
					CASE 
						WHEN VirtualColumnDataTypeInd = 'N' THEN 'VirtualTableDataNum'
						WHEN VirtualColumnDataTypeInd = 'D' THEN 'VirtualTableDataDate'
						WHEN VirtualColumnDataTypeInd = 'I' THEN 'VirtualTableDataInd'
						WHEN VirtualColumnDataTypeInd = 'L' THEN 'VirtualTableDataListDomain'
						WHEN VirtualColumnDataTypeInd = 'F' THEN 'VirtualTableDataFlg'
						WHEN VirtualColumnDataTypeInd = 'S' THEN 'VirtualTableDataString'
					END AS VCDataTypeTable,
					CASE 
						WHEN VirtualColumnDataTypeInd = 'N' THEN 'DataFieldValueNum'
						WHEN VirtualColumnDataTypeInd = 'D' THEN 'DataFieldValueDate'
						WHEN VirtualColumnDataTypeInd = 'I' THEN 'DataFieldValueInd'
						WHEN VirtualColumnDataTypeInd = 'L' THEN 'DataFieldValueDomainId'
						WHEN VirtualColumnDataTypeInd = 'F' THEN 'DataFieldValueFlg'
						WHEN VirtualColumnDataTypeInd = 'S' THEN 'DataFieldValueString' 
					END AS VCDataTypeColumn,
					VirtualColumnComment
			INTO VirtualColumn_upgr
			FROM VirtualColumn_BKP vc
			JOIN VirtualTable_BKP vt ON vc.VirtualTableId = vt.Id
			WHERE (vc.VirtualColumnComment <> 'DO NOT USE' OR VirtualColumnComment IS NULL)

			-- Only creates a virtual table if it has atleast 1 virtual column
			DECLARE VirtualTable_Cursor CURSOR FOR
			SELECT DISTINCT VirtualTableId, VirtualTableName
			FROM VirtualColumn_upgr

			OPEN VirtualTable_Cursor
			FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

			WHILE @@FETCH_STATUS = 0
			BEGIN
	
				--Drop the non-temporary tables created by this script
				IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
				BEGIN
					DROP TABLE tmp_VirtualTableData
				END

				SET @ColumnList = 'SELECT ROW_NUMBER() OVER (ORDER BY VTS.VirtualTableStationingId) AS Id, '

				SET @JoinList = CHAR(10) + 'INTO tmp_VirtualTableData
				FROM VirtualTableStationing_BKP VTS'

				--------------------------- Construct code to create virtual column --------------------

				/* 
					Cursor to construct column list and join condition for SELECT statement used to create the virtual table. 
					Columns with a 'DO NOT USE' comment will not be created
				*/
				DECLARE VirtualColumns_Cursor CURSOR FOR
				SELECT VirtualColumnName,
						VCDataTypeTable + '_BKP',
						VCDataTypeColumn
				FROM VirtualColumn_upgr
				WHERE VirtualTableName = @VirtualTableName


				OPEN VirtualColumns_Cursor
				FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

				-- Use a loop to generate the select statement that will be used to populate the new virtual tables
				WHILE @@FETCH_STATUS = 0
				BEGIN

					SET @ColumnList += 'T' + CAST(@Counter AS NVARCHAR) + '.[' + @VCDataTypeColumn + '] AS ' + @VirtualColumnName + ', '
					SET @JoinList += CHAR(13) + 'LEFT JOIN ' + @VCDataTypeTable + ' T' + CAST(@Counter AS NVARCHAR) + ''
								+ CHAR(13) + ' ON T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableId = VTS.VirtualTableId'
								+ CHAR(13) + 'AND T' + CAST(@Counter AS NVARCHAR) + '.VirtualTableStationingId = VTS.VirtualTableStationingId'
	
					SET @Counter += 1
					FETCH NEXT FROM VirtualColumns_Cursor INTO @VirtualColumnName, @VCDataTypeTable, @VCDataTypeColumn

				END
				CLOSE VirtualColumns_Cursor
				DEALLOCATE VirtualColumns_Cursor


				IF OBJECT_ID ('tmp_VirtualTableData', 'U') IS NOT NULL
				BEGIN
					DROP TABLE tmp_VirtualTableData
				END

				SET @SQL = @ColumnList 
				+ 'VTS.EffectiveStartDate,
				VTS.EffectiveEndDate,
				VTS.BeginStationSeriesId,
				VTS.BeginStationNum,
				VTS.EndStationSeriesId,
				VTS.EndStationNum,
				VTS.SourceId,
				VTS.CreatedUser,
				VTS.CreatedDate,
				VTS.LastModByUserId,
				VTS.LastModDateTime
				' + @JoinList + CHAR(10) 
				+ 'WHERE VTS.VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + ''
		
				EXECUTE (@SQL)

				IF OBJECT_ID('tmp_ColumnList') IS NOT NULL
				BEGIN
					DROP TABLE tmp_ColumnList
				END

				-- Store the list of columns for the virtual table that will be created in a temporary table
				SELECT ordinal_position, column_name, 
					CASE  
						 WHEN column_name = 'Id' THEN 'NUMERIC(10,0) IDENTITY(1,1) NOT NULL' 
						 WHEN column_name LIKE 'Effective%Date' THEN 'DATETIME'
						 WHEN column_name IN ('CreatedUser', 'LastModByUserId') THEN 'VARCHAR(45) DEFAULT (suser_sname()) NOT NULL'
						 WHEN column_name IN ('CreatedDate', 'LastModDateTime') THEN 'DATETIME DEFAULT (getdate()) NOT NULL'
						 WHEN column_name LIKE '%StationSeries%' THEN 'NUMERIC(10,0)'
						 WHEN column_name LIKE '%StationNum%' THEN 'NUMERIC(13,5)'
						 WHEN column_name = 'SourceId' THEN 'VARCHAR(50)'
						 ELSE CASE VCDataTypeColumn WHEN 'DataFieldValueInd' THEN 'CHAR(1)'
													WHEN 'DataFieldValueDate' THEN 'DATETIME'
													WHEN 'DataFieldValueFlg' THEN 'NUMERIC(1,0)'
													WHEN 'DataFieldValueDomainId' THEN 'NUMERIC(10,0)'
													WHEN 'DataFieldValueNum' THEN 'FLOAT'
													WHEN 'DataFieldValueString' THEN 'VARCHAR(512)'
							  END
					END AS data_type
				INTO tmp_ColumnList
				FROM INFORMATION_SCHEMA.columns c
				LEFT JOIN VirtualColumn_upgr vc ON vc.VirtualColumnName = c.column_name 
				WHERE table_name = 'tmp_VirtualTableData'
				AND column_name NOT IN ('VirtualTableId', 'VirtualTableStationingId')
				ORDER BY ordinal_position 

				-- Populate the parent of the virtual table if it has ListDomain columns
				IF EXISTS (SELECT * FROM VirtualColumn_BKP WHERE VirtualColumnName = @VirtualColumnName AND VirtualColumnDataTypeInd = 'L')
				BEGIN
				
					-- Check to see if the ListDomain entries for the virtual table found in the VirtualTableDataListDomain_BKP table have the same DomainCatalog. If so use the LDTable for that catalog
					IF (SELECT COUNT(DISTINCT DomainCatalogId) FROM VirtualTableDataListDomain_BKP vtld
						JOIN VirtualTable_BKP vt ON vt.Id =  vtld.VirtualTableId
						JOIN VirtualColumn_BKP vc ON vc.VirtualTableId = vtld.VirtualTableId AND vc.Id = vtld.VirtualColumnId
						JOIN ListDomain_BKP ld ON ld.Id = vtld.DataFieldValueDomainId 
						WHERE VirtualTableName = @VirtualTableName AND VirtualColumnName = @VirtualColumnName) = 1
					BEGIN

						SELECT @LDTableName = LDTableName,
							   @Schema = LDTableSchema
						FROM TempListDomainTable 
						WHERE DomainCatalogId = (SELECT DISTINCT DomainCatalogId FROM VirtualTableDataListDomain_BKP vtld
												JOIN VirtualTable_BKP vt ON vt.Id =  vtld.VirtualTableId
												JOIN VirtualColumn_BKP vc ON vc.VirtualTableId = vtld.VirtualTableId AND vc.Id = vtld.VirtualColumnId
												JOIN ListDomain_BKP ld ON ld.Id = vtld.DataFieldValueDomainId 
												WHERE VirtualTableName = @VirtualTableName AND VirtualColumnName = @VirtualColumnName)
					END
					-- or else find an appropriate LD table for the virtual table (first check the TempListDomainTable to see if there is an entry for the Virtual table and column)
					ELSE IF EXISTS (SELECT * FROM TempListDomainTable WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName)
					BEGIN
						SELECT @LDTableName = LDTableName,
							   @Schema = LDTableSchema  
						FROM TempListDomainTable 
						WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName
					END
					-- or else use the LD_DummyTable_VT table as the ListDomaintable
					ELSE
					BEGIN
						SELECT @LDTableName = 'LD_DummyTable_VT', @Schema= 'DRAS'
					END

					SET @SQL = NULL

					-- Drop the foreign key linking the virtual table to an LD table if the LD table it is being linked to is not appropriate
					IF NOT EXISTS (SELECT * FROM TempListDomainTable WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName AND LDTableName = @LDTableName AND LDTableSchema = @Schema) 
					BEGIN

						SELECT @SQL = 'ALTER TABLE ' + SCHEMA_NAME(t1.schema_id) + '.' +  OBJECT_NAME(fkc.parent_object_id) + ' DROP CONSTRAINT ' +
						OBJECT_NAME(fkc.constraint_object_id)
						FROM sys.foreign_key_columns fkc
						JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
						JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
						JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
						JOIN TempListDomainTable tld ON tld.TableName = OBJECT_NAME(fkc.parent_object_id)
						AND tld.ColumnName = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
						WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName AND TableType = 'Virtual'

						EXECUTE (@SQL)

					END

					-- Insert parent values into the parent LD table for each virtual table that has a ListDomain reference
					IF OBJECT_ID(@Schema + '.' + @LDTableName, 'U') IS NOT NULL
					BEGIN
					SET @SQL = 'SET IDENTITY_INSERT '  + @Schema + '.' + @LDTableName + ' ON
						INSERT INTO ' + @Schema + '.' + @LDTableName + ' (Id, Code, Descr, EffectiveEndDate) 
						SELECT DISTINCT ld.Id, Code, Descr, NULL
						FROM ListDomain_BKP ld 
						JOIN VirtualTableDataListDomain_BKP vtld
						ON ld.Id = vtld.DataFieldValueDomainId
						JOIN VirtualTable_BKP vt ON vt.Id =  vtld.VirtualTableId
						JOIN VirtualColumn_BKP vc ON vc.VirtualTableId = vtld.VirtualTableId AND vc.Id = vtld.VirtualColumnId
						WHERE VirtualTableName = ''' + @VirtualTableName + ''' AND VirtualColumnName = ''' + @VirtualColumnName + '''
						AND NOT EXISTS (SELECT * FROM ' + @Schema + '.' + @LDTableName + ' WHERE Id = ld.Id)
						SET IDENTITY_INSERT ' + @Schema + '.' + @LDTableName + ' OFF '

						EXECUTE (@SQL)
					END
					ELSE
					BEGIN
						-- Create the LD table if it does not exist
						SET @SQL = 'CREATE TABLE ' + @Schema + '.' + @LDTableName + ' (
						[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
						[Code] varchar(60) NOT NULL,
						[Descr] varchar(255) NOT NULL,
						[EffectiveEndDate] Datetime,
						[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
						[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
						[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
						[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
						CONSTRAINT [PK_LD_DummyTable_VT] PRIMARY KEY (Id ASC))'

						EXECUTE (@SQL)

						-- create an update trigger on the LD table to update the LastModByUserId and LastModDateTime columns
						SET @SQL = 'CREATE TRIGGER ['+ @Schema + '].[tu_' + @LDTableName + '] ON [' + @Schema + '].[' + @LDTableName+ '] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE ' + @Schema + '.' + @LDTableName + '
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM ' + @Schema + '.' + @LDTableName + ' as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

						EXECUTE (@SQL )

						-- Insert ListDomain parent info for virtual tables into the LD table 
						SET @SQL = 'SET IDENTITY_INSERT '  + @Schema + '.' + @LDTableName + ' ON
						INSERT INTO ' + @Schema + '.' + @LDTableName + ' (Id, Code, Descr, EffectiveEndDate) 
						SELECT DISTINCT ld.Id, Code, Descr, NULL
						FROM ListDomain_BKP ld 
						JOIN VirtualTableDataListDomain_BKP vtld
						ON ld.Id = vtld.DataFieldValueDomainId
						JOIN VirtualTable_BKP vt ON vt.Id =  vtld.VirtualTableId
						JOIN VirtualColumn_BKP vc ON vc.VirtualTableId = vtld.VirtualTableId AND vc.Id = vtld.VirtualColumnId
						WHERE VirtualTableName = ''' + @VirtualTableName + ''' AND VirtualColumnName = ''' + @VirtualColumnName + '''
						AND NOT EXISTS (SELECT * FROM ' + @Schema + '.' + @LDTableName + ' WHERE Id = ld.Id)
						SET IDENTITY_INSERT ' + @Schema + '.' + @LDTableName + ' OFF'

						EXECUTE (@SQL)
					END

				END

				-- Update the TempListDomainTable table or add the virtual table to it if not already there
				IF EXISTS (SELECT * FROM TempListDomainTable WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName)
				BEGIN
						
					UPDATE TempListDomainTable
					SET LDTableSchema = @Schema,
						LDTableName = @LDTableName,
						DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM TempListDomainTable WHERE LDTableName = @LDTableName),
						DomainDescr = (SELECT TOP 1 DomainDescr FROM TempListDomainTable WHERE LDTableName = @LDTableName)
					WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName

				END
				ELSE IF EXISTS (SELECT * FROM VirtualColumn_BKP vc JOIN VirtualTable_BKP vt ON vt.Id = vc.VirtualTableId 
								WHERE VirtualTableName = @VirtualTableName AND VirtualColumnName = @VirtualColumnName AND VirtualColumnDataTypeInd = 'L')
				BEGIN
					INSERT INTO TempListDomainTable (TableType,LDTableSchema, LDTableName, TableSchema, TableName, ColumnName, DomainCatalogId, DomainDescr)
					SELECT DISTINCT 'Virtual', @Schema, @LDTableName, 'DRAS', @VirtualTableName, @VirtualColumnName, DomainCatalogId, DomainDescr
					FROM VirtualTableDataListDomain_BKP vtld
					JOIN VirtualTable_BKP vt ON vt.Id =  vtld.VirtualTableId
					JOIN VirtualColumn_BKP vc ON vc.VirtualTableId = vtld.VirtualTableId AND vc.Id = vtld.VirtualColumnId
					JOIN ListDomain_BKP ld ON ld.Id = vtld.DataFieldValueDomainId 
					JOIN DomainCatalog_BKP dc ON dc.Id = ld.DomainCatalogId
					WHERE VirtualTableName = @VirtualTableName AND VirtualColumnName = @VirtualColumnName
					AND NOT EXISTS (SELECT * FROM TempListDomainTable WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName)

				END

				IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables WHERE table_schema <> 'DRAS' AND table_name = @VirtualTableName)
				BEGIN
					SET @VirtualTableName = @VirtualTableName + '_VT'
				END

				SET @ColumnList = NULL

				SELECT @ColumnList = COALESCE(@ColumnList + ', ', '') + column_name 
				FROM tmp_ColumnList WHERE column_name <> 'Id'
				ORDER BY ordinal_position

				-- Create and populate the new virtual table in the DRAS schema
				IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = 'tmp_VirtualTableData'
						   EXCEPT
						   SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @VirtualTableName)
					OR EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @VirtualTableName
							   EXCEPT
							   SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = 'tmp_VirtualTableData')
					OR OBJECTPROPERTY(OBJECT_ID('DRAS.' + @VirtualTableName), 'TableHasIdentity') <> 1
				BEGIN
					-- Drop and recreate the table then insert into the table

					IF OBJECT_ID('DRAS.' + @VirtualTableName) IS NOT NULL
					BEGIN
						SET @SQL = 'DROP TABLE DRAS.' + @VirtualTableName	
						EXECUTE (@SQL)
					END

					SET @SQL = NULL

					SELECT @SQL = COALESCE(@SQL + ', ' + CHAR(10), '') + column_name + ' ' + data_type 
					FROM tmp_ColumnList

					SET @SQL = 'CREATE TABLE DRAS.' + @VirtualTableName + '(' + @SQL + ')'

					SET @SQL += CHAR(10) + CHAR(10) + 'INSERT INTO DRAS.' + @VirtualTableName + ' (' + @ColumnList + ')
						SELECT ' + @ColumnList + ' FROM tmp_VirtualTableData'
				
				END
				ELSE
				BEGIN
					-- Add missing data to table
					SET @SQL = 'INSERT INTO DRAS.' + @VirtualTableName + ' (' + @ColumnList + ')
					SELECT ' + @ColumnList + ' FROM tmp_VirtualTableData tmp
					WHERE NOT EXISTS (SELECT * FROM DRAS.' + @VirtualTableName + ' WHERE Id = tmp.Id)'

				END

				BEGIN TRY
					EXECUTE (@SQL)
				END TRY
				BEGIN CATCH
					PRINT @SQL;
					THROW
				END CATCH

			------------------------------------ Add a Primary Key to Newly Created Virtual Table ------------------------------------

				IF NOT EXISTS (SELECT * FROM sys.indexes i JOIN sys.index_columns ic ON i.object_id = ic.object_id
								AND i.index_id = ic.index_id JOIN sys.tables tab ON tab.object_id = i.object_id
								WHERE OBJECT_NAME(ic.object_id) = @VirtualTableName  AND SCHEMA_NAME(tab.schema_id) = 'DRAS' AND is_primary_key = 1)
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ALTER COLUMN Id NUMERIC(10, 0) NOT NULL'

					EXECUTE(@SQL)

					SET @SQL = CHAR(10) + 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD CONSTRAINT PK_' + @VirtualTableName + '_VT PRIMARY KEY CLUSTERED (Id)'
								
					EXECUTE (@SQL)	

				END

				-- Update TempListDomainTable table
				SET @SQL = 'UPDATE TempListDomainTable
				SET TableSchema = ''DRAS''
				WHERE TableName = ''' + @VirtualTableName + '''
				AND TableType = ''Virtual'''
	
				EXECUTE (@SQL)

			------------------------------------ Add Column Defaults to Change-tracking columns --------------------------------------

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'LastModByUserId' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]'
					
					EXECUTE (@SQL)
				END
	
				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'LastModDateTime' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'

					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedDate' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN	
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
					
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE OBJECT_NAME (parent_object_id) = @VirtualTableName
							AND COL_NAME(parent_object_id, parent_column_id) = 'CreatedUser' AND SCHEMA_NAME(schema_id) = 'DRAS')
				BEGIN
					SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
					
					EXECUTE (@SQL)
				END

			------------------------------------ Create Triggers on Newly Created Virtual Tables --------------------------------------
				
				IF OBJECT_ID('DRAS.tu_' + @VirtualTableName, 'TR') IS NULL
				BEGIN
					
					SET @SQL = 'CREATE TRIGGER [DRAS].[tu_' + @VirtualTableName + '] ON [DRAS].[' + @VirtualTableName+ '] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE DRAS.' + @VirtualTableName + '
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM DRAS.' + @VirtualTableName + ' as t, DELETED as d
						WHERE t.Id=d.Id;
					END'

					EXECUTE (@SQL)
				END

				------------------------------------ Add Foreign Keys  -------------------------------
				
				---- Add foreign keys referencing LD tables
				--DECLARE AddFK_Cursor CURSOR FOR
				--SELECT VirtualColumnName FROM VirtualColumn_upgr
				--WHERE VirtualTableName = @VirtualTableName
				--AND VCDataTypeTable = 'VirtualTableDataListDomain'

				--OPEN AddFK_Cursor
				--FETCH NEXT FROM AddFK_Cursor INTO @VirtualColumnName

				--WHILE @@FETCH_STATUS = 0
				--BEGIN 
					
				--	SET @ForeignKeyName = 'FK_' + CASE WHEN @VirtualTableName = @VirtualColumnName THEN SUBSTRING(REPLACE(@VirtualColumnName, 'DomainId', ''), 1, 30) 
				--		WHEN LEN(REPLACE(@VirtualColumnName, 'DomainId', '')) >= 25 THEN SUBSTRING(REPLACE(@VirtualColumnName, 'DomainId', ''), 1, 25)
				--		ELSE SUBSTRING(REPLACE(@VirtualColumnName, 'DomainId', ''), 1, 12) + SUBSTRING(@VirtualTableName, 1, 12)
				--	END	+ 'LD'

				--	IF NOT EXISTS (SELECT * FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = @VirtualTableName
				--					AND COL_NAME(parent_object_id, parent_column_id) = @VirtualColumnName)
				--		AND EXISTS (SELECT * FROM TempListDomainTable WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName)
				--	BEGIN

				--		SELECT @SQL = 'ALTER TABLE [DRAS].[' + TableName + '] WITH CHECK ADD CONSTRAINT ' 
				--		+ @ForeignKeyName + '_VT' + CHAR(10) + 'FOREIGN KEY (' + ColumnName + ')' + CHAR(10)
				--		+ 'REFERENCES ' + @Schema + '.[' + LDTableName + '](Id)'
				--		FROM TempListDomainTable
				--		WHERE TableName = @VirtualTableName AND ColumnName = @VirtualColumnName

				--		EXECUTE (@SQL)	
				--	END

				--	FETCH NEXT FROM AddFK_Cursor INTO @VirtualColumnName
				--END

				--CLOSE AddFK_Cursor
				--DEALLOCATE AddFK_Cursor

				--SET @ForeignKeyName = 'FK_' + @VirtualTableName + '_BgnStnId'

				---- Add foreign key for virtual table BeginStationSeriesId column
				--IF NOT EXISTS (SELECT * FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = @VirtualTableName
				--				AND COL_NAME(parent_object_id, parent_column_id) = 'BeginStationSeriesId') 
				--BEGIN
				--	SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] WITH CHECK ADD CONSTRAINT ' + @ForeignKeyName
				--			+ CHAR(10) + ' FOREIGN KEY (BeginStationSeriesId) ' + ' REFERENCES [dbo].[StationSeries](Id)'
					
				--	EXECUTE (@SQL)	
				--END
				
				--SET @ForeignKeyName = 'FK_' + @VirtualTableName + '_EndStnId'
				
				---- Add foreign key for virtual table EndStationSeriesId column
				--IF NOT EXISTS (SELECT * FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = @VirtualTableName
				--				AND COL_NAME(parent_object_id, parent_column_id) = 'EndStationSeriesId') 
				--BEGIN
				--	SET @SQL = 'ALTER TABLE [DRAS].[' + @VirtualTableName + '] WITH CHECK ADD CONSTRAINT ' + @ForeignKeyName
				--			+ CHAR(10) + ' FOREIGN KEY (EndStationSeriesId) ' + ' REFERENCES [dbo].[StationSeries](Id)'
				
				--	EXECUTE (@SQL)	

				--END

				FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableId, @VirtualTableName

			END 

			CLOSE VirtualTable_Cursor
			DEALLOCATE VirtualTable_Cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650118 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 19
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650119', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 19', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650119 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Script To make Composite key for GUIDLookUp table.sql

			-- Backup GUIDLookup table
			IF NOT EXISTS (Select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'GUIDLookup_backup')
			SELECT *
			INTO GUIDLookup_backup
			FROM GUIDLookup;

			-- Drop primary key constraint on ID column
			-- Find the constraint name first (replace with actual name if known)
			DECLARE @ConstraintName NVARCHAR(128);
			SELECT @ConstraintName = 
			name
			FROM sys.key_constraints
			WHERE parent_object_id = OBJECT_ID('GUIDLookup')
			  AND type = 'PK';

			IF @ConstraintName IS NOT NULL
			BEGIN
				EXEC('ALTER TABLE GUIDLookup DROP CONSTRAINT [' + @ConstraintName + ']');
			END

			-- Add composite primary key on ID and [Table] columns
			IF NOT EXISTS (SELECT name FROM SYS.key_constraints WHERE NAME LIKE 'PK_GUIDLookup' and  parent_object_id = OBJECT_ID('GUIDLookup'))
			ALTER TABLE GUIDLookup
			ADD CONSTRAINT PK_GUIDLookup PRIMARY KEY (ID, TableName);

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650119 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 20
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650120', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 20', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650120 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			Declare @sql nvarchar(max)

			SET @sql = 'ALTER Procedure [dbo].[sp_CreateCustomTable] (
			@vtTableName varchar(100) = '''',
			@vtColumnName varchar(100) = '''',
			@columnType varchar(1) = '''' -- Type should be L = ListDomain, D = Date, F = Flag, I = Indicator, N = Number and S = String
			)
			AS
			BEGIN
				If ltrim(rtrim(@vtTableName)) = '''' or ltrim(rtrim(@vtColumnName)) = '''' or ltrim(rtrim(@columnType)) = ''''
				BEGIN
					RAISERROR (15600, -1, -1, ''sp_CreateCustomTable'');
					return
				END

				declare @sql nvarchar(max)

				IF (SELECT value FROM SystemPreferences WHERE ParameterName = ''ConversionFromImperialRequired'') = 1
				BEGIN
					Insert into ConversionLookup (TableName, ColumnName, FromUnit, ToUnit, Precision, Scale)
					select @vtTableName, ''BeginStationNum'', ''feet'', ''meter'', 38, 5 
					where not exists (select 1 from ConversionLookup where TableName = @vtTableName and ColumnName = ''BeginStationNum'')

					Insert into ConversionLookup (TableName, ColumnName, FromUnit, ToUnit, Precision, Scale)
					select @vtTableName, ''EndStationNum'', ''feet'', ''meter'', 38, 5 
					where not exists (select 1 from ConversionLookup where TableName = @vtTableName and ColumnName = ''EndStationNum'')

				END

				IF NOT EXISTS (select * from INFORMATION_SCHEMA.TABLES Where TABLE_NAME = @vtTableName AND TABLE_SCHEMA = ''DRAS'')
				BEGIN
					SET @sql = ''CREATE TABLE [DRAS].['' + @vtTableName + ''](
									[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
									['' + @vtColumnName + ''] '' 
									+ Case When @columnType = ''L'' then ''[numeric](10, 0)''
										When @columnType = ''D'' then ''[datetime]''
										When @columnType = ''F'' then ''[numeric](1,0)''
										When @columnType = ''I'' then ''[char](1)''
										When @columnType = ''N'' then ''[float]''
										Else ''[varchar](512)'' END
									+ '' NULL,
									[EffectiveStartDate] [datetime] NULL,
									[EffectiveEndDate] [datetime] NULL,
									[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
									[BeginStationNum] [numeric](13, 5) NOT NULL,
									[EndStationSeriesId] [numeric](10, 0) NOT NULL,
									[EndStationNum] [numeric](13, 5) NOT NULL,
									[SourceId] [varchar](50) NULL,
									[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
									[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
									[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
									[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
									[CheckSumValue] [int] NULL,
								 CONSTRAINT [PK_'' + @vtTableName + ''] PRIMARY KEY CLUSTERED 
								(
									[Id] ASC
								)
								) ON [PRIMARY]''

					EXEC sp_executesql @sql

					SET @sql = ''CREATE TABLE [DRAS].[Extract_'' + @vtTableName + ''](
									[Id] [numeric](10, 0) NULL,
									[EffectiveStartDate] [datetime] NULL,
									[EffectiveEndDate] [datetime] NULL,
									[BeginStationSeriesGUID] [varchar](50) NULL,
									[BeginStationSeriesId] [numeric](10, 0) NULL,
									[BeginStationNum] [numeric](13, 5) NOT NULL,
									[EndStationSeriesGUID] [varchar](50) NULL,
									[EndStationSeriesId] [numeric](10, 0) NULL,
									[EndStationNum] [numeric](13, 5) NOT NULL,
									[DataFieldValueDate] [datetime] NULL,
									[DataFieldValueFlg] [numeric](1, 0) NULL,
									[DataFieldValueInd] [char](1) NULL,
									[DataFieldValueDomainId] [numeric](7, 0) NULL,
									[DataFieldValueNum] [float] NULL,
									[DataFieldValueString] [varchar](512) NULL,
									[LastModByUserId] [varchar](45) NOT NULL DEFAULT (suser_sname()),
									[LastModDateTime] [datetime] NOT NULL DEFAULT (getdate()),
									[SourceId] [varchar](50) NOT NULL,
									[CreatedDate] [datetime] NOT NULL DEFAULT (getdate()),
									[CreatedUser] [varchar](45) NOT NULL DEFAULT (suser_sname())
								)'' 

					EXEC sp_executesql @sql

					SET @sql = ''CREATE TABLE [DRAS].[Err_'' + @vtTableName + ''](
									[IRASId] [numeric](20, 0) NULL,
									[EffectiveStartDate] [varchar](500) NULL,
									[EffectiveEndDate] [varchar](500) NULL,
									[SourceId] [varchar](50) NULL,
									[DataFieldValueDate] [varchar](600) NULL,
									[DataFieldValueFlg] [varchar](600) NULL,
									[DataFieldValueInd] [varchar](600) NULL,
									[DataFieldValueDomainId] [varchar](600) NULL,
									[DataFieldValueNum] [varchar](600) NULL,
									[DataFieldValueString] [varchar](600) NULL,
									[BeginStationSeriesId] [varchar](255) NULL,
									[BeginStationNum] [varchar](255) NULL,
									[EndStationSeriesId] [varchar](255) NULL,
									[EndStationNum] [varchar](255) NULL,
									[ErrorCount] [int] NULL,
									[WarningCount] [int] NULL,
									[MessagesText] [varchar](4000) NULL,
									[ElementName] [varchar](255) NULL,
									[LastModByUserId] [varchar](100) NOT NULL DEFAULT (suser_sname()),
									[LastModDateTime] [datetime] NOT NULL DEFAULT (getdate())
								)''

					EXEC sp_executesql @sql

					IF @columnType = ''L''
					BEGIN

						SET @sql = ''CREATE TABLE [DRAS].[LD_'' + @vtColumnName + ''_VT](
										[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
										[Code] [varchar](60) NOT NULL,
										[Descr] [varchar](255) NOT NULL,
										[EffectiveEndDate] [datetime] Default (NULL) NULL,
										[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
										[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
										[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
										[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
									 CONSTRAINT [PK_LD_'' + @vtColumnName + ''] PRIMARY KEY CLUSTERED 
									(
										[Id] ASC
									)
									) ON [PRIMARY]''
						EXEC sp_executesql @sql

						SET @sql = ''CREATE   TRIGGER [DRAS].[tu_LD_'' + @vtColumnName + ''_VT] ON [DRAS].[LD_'' + @vtColumnName + ''_VT] FOR UPDATE AS 
												IF EXISTS(SELECT * FROM DELETED)
												BEGIN
													UPDATE DRAS.LD_'' + @vtColumnName + ''_VT
													SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
													FROM DRAS.LD_'' + @vtColumnName + ''_VT as t, DELETED as d
													WHERE t.Id=d.Id;
												END''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].[LD_'' + @vtColumnName + ''_VT] ENABLE TRIGGER [tu_LD_'' + @vtColumnName + ''_VT]''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + '']  WITH CHECK ADD  CONSTRAINT [FK_'' + @vtColumnName + ''LD] FOREIGN KEY(['' + @vtColumnName + ''])
									REFERENCES [DRAS].[LD_'' + @vtColumnName + ''_VT] ([Id])''
						EXEC sp_executesql @sql

						SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] CHECK CONSTRAINT [FK_'' + @vtColumnName + ''LD]''
						EXEC sp_executesql @sql
					END

					SET @sql = ''CREATE   TRIGGER [DRAS].[tu_'' + @vtTableName + ''] ON [DRAS].['' + @vtTableName + ''] FOR UPDATE AS 
											IF EXISTS(SELECT * FROM DELETED)
											BEGIN
												UPDATE DRAS.'' + @vtTableName + ''
												SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
												FROM DRAS.'' + @vtTableName + '' as t, DELETED as d
												WHERE t.Id=d.Id;
											END''
					EXEC sp_executesql @sql

					SET @sql = ''ALTER TABLE [DRAS].['' + @vtTableName + ''] ENABLE TRIGGER [tu_'' + @vtTableName + '']''
					EXEC sp_executesql @sql

				END
			END'

			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650120 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 21
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650121', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 21', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650121 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			declare @sql nvarchar(max)

			If not exists (select * from INFORMATION_SCHEMA.Tables where TABLE_NAME = 'VirtualDataModelInfo')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[VirtualDataModelInfo](
								[Id] [bigint] IDENTITY(1,1) NOT NULL,
								[Name] [nvarchar](100) NULL,
								[Description] [nvarchar](512) NULL,
								[ArchiveFilePath] [ntext] NULL,
								[ConfigFilePath] [ntext] NULL,
								[VirtualDataModelName] [nvarchar](128) NULL,
								[IsActive] [bit] NULL,
								[PauseCaching] [bit] NULL,
								[ServerName] [nvarchar](100) NULL,
								[CreateDtTm] [datetime] NULL,
								[UpdateDtTm] [datetime] NULL,
								[CreatedBy] [nvarchar](100) NULL,
								[UpdatedBy] [nvarchar](100) NULL,
								[Status] [nvarchar](30) NULL,
								[CacheDbInfo] [ntext] NULL,
								[ErrorInfo] [ntext] NULL,
								[TraceSessionId] [bigint] NULL,
								[AllowUsers] [text] NULL,
							 CONSTRAINT [VirtualDataModelInfo_Pk] PRIMARY KEY CLUSTERED 
							(
								[Id] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
							) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'

				EXECUTE sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650121 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 22
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650122', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 22', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650122 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			declare @sql nvarchar(max)
			declare d_cursor Cursor FOR
				SELECT 'DROP TRIGGER ' + t.name as DropScripts  
				FROM sys.triggers t
				INNER JOIN sys.tables tbl ON t.parent_id = tbl.object_id
				WHERE tbl.name IN (
					select 'JobQueue' UNION 
					select 'ScheduledTask' UNION 
					select 'JobInfo' UNION 
					select 'ServerRequestQueue' UNION 
					select 'ServerHealthInfo' UNION 
					select 'ServerEvent' UNION 
					select 'PendingFileDrop' UNION 
					select 'ServerProfile' UNION 
					select 'ClusterSettings' UNION 
					select 'VirtualDataModelInfo' UNION 
					select 'TraceSession' UNION 
					select 'JobTrace' UNION 
					select 'EventListener' UNION 
					select 'EventSubscriber' UNION 
					select 'EventData' UNION 
					select 'EventQueue' UNION 
					select 'EventScheduleInfo' UNION 
					select 'EventTransactionLog' UNION 
					select 'AUser' UNION 
					select 'RestApiDepConfig' UNION 
					select 'RestApiDeployment' UNION 
					select 'ApiDeploymentInfo' UNION 
					select 'User' UNION 
					select 'Role' UNION 
					select 'BusinessEntity' UNION 
					select 'TargetFlow' UNION 
					select 'Mapping' UNION 
					select 'Submission' UNION 
					select 'SubmissionAction' UNION 
					select 'SubmissionProcess' UNION 
					select 'Deployment' UNION 
					select 'Deployment2' 
				)

			OPEN d_cursor
	
				Fetch next from d_cursor into @sql

				WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC sp_executesql @sql		
					Fetch next from d_cursor into @sql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650122 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 23
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650123', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 23', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650123 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			declare @vtTableName varchar(100)
			declare @sql nvarchar(max)

			-- Drop old vt tables

			declare d_cursor cursor for 
				select 'Drop Table DRAS.' + TABLE_NAME from INFORMATION_SCHEMA.TABLES where Table_Name like '%vt%' and Table_Name not like 'Load%' and Table_Name not like 'LD%'
				and TABLE_NAME NOT IN ('VTGUIDLookup', 'Vt_SampleTable', 'Err_Vt_SampleErrorTable', 'Extract_Vt_SampleExtractTable')

			OPEN d_cursor

				FETCH NEXT FROM d_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0 
				BEGIN
					Exec sp_executesql @sql
					FETCH NEXT FROM d_cursor INTO @sql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor



			-- Create the Extract and error tables for virtual tables

			declare c_cursor cursor for 
				select distinct TableName from tmpDataExchangeAllMappingsInfo where TableName in (select VirtualTableName from VirtualTable_BKP)

			OPEN c_cursor

				FETCH NEXT FROM c_cursor INTO @vtTableName

				WHILE @@FETCH_STATUS = 0
				BEGIN
		
					-- Create the Extract tables for virtual tables
					IF EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Extract_' + @vtTableName)
					BEGIN
						SET @sql = 'DROP TABLE [DRAS].[Extract_' + @vtTableName + ']'
						Exec sp_executesql @sql
					END

					IF NOT EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Extract_' + @vtTableName)
					BEGIN
						SET @sql = 'CREATE TABLE [DRAS].[Extract_' + @vtTableName + '](
										[EffectiveStartDate] [varchar](500) NULL,
										[EffectiveEndDate] [varchar](500) NULL,
										[BeginStationSeriesGUID] [varchar](500) NULL,
										[BeginStationSeriesId] [varchar](500) NULL,
										[BeginStationNum] [varchar](500) NULL,
										[EndStationSeriesGUID] [varchar](500) NULL,
										[EndStationSeriesId] [varchar](500) NULL,
										[EndStationNum] [varchar](500) NULL,
										[DataFieldValueDate] [varchar](500) NULL,
										[DataFieldValueFlg] [varchar](500) NULL,
										[DataFieldValueInd] [varchar](500) NULL,
										[DataFieldValueDomainId] [varchar](500) NULL,
										[DataFieldValueNum] [varchar](500) NULL,
										[DataFieldValueString] [varchar](500) NULL,
										[LastModByUserId] [varchar](500) NULL DEFAULT (suser_sname()),
										[LastModDateTime] [varchar](500) NULL DEFAULT (getdate()),
										[SourceId] [varchar](500) NULL,
										[CreatedDate] [varchar](500) NULL DEFAULT (getdate()),
										[CreatedUser] [varchar](500) NULL DEFAULT (suser_sname())
									)'
						Exec sp_executesql @sql
					END

					-- Create the Error tables for virtual tables
					IF NOT EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Err_' + @vtTableName)
					BEGIN
						SET @sql = 'CREATE TABLE [DRAS].[Err_' + @vtTableName + '](
										[IRASId] [numeric](20, 0) NULL,
										[EffectiveStartDate] [varchar](500) NULL,
										[EffectiveEndDate] [varchar](500) NULL,
										[SourceId] [varchar](50) NULL,
										[DataFieldValueDate] [varchar](600) NULL,
										[DataFieldValueFlg] [varchar](600) NULL,
										[DataFieldValueInd] [varchar](600) NULL,
										[DataFieldValueDomainId] [varchar](600) NULL,
										[DataFieldValueNum] [varchar](600) NULL,
										[DataFieldValueString] [varchar](600) NULL,
										[BeginStationSeriesId] [varchar](255) NULL,
										[BeginStationNum] [varchar](255) NULL,
										[EndStationSeriesId] [varchar](255) NULL,
										[EndStationNum] [varchar](255) NULL,
										[ErrorCount] [int] NULL,
										[WarningCount] [int] NULL,
										[MessagesText] [varchar](4000) NULL,
										[ElementName] [varchar](255) NULL,
										[LastModByUserId] [varchar](100) NOT NULL DEFAULT (suser_sname()),
										[LastModDateTime] [datetime] NOT NULL DEFAULT (getdate())
									)'

						Exec sp_executesql @sql
					END

					FETCH NEXT FROM c_cursor INTO @vtTableName
				END

			CLOSE c_cursor
			DEALLOCATE c_cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650123 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 24
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650124', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 24', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650124 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			Declare @sql nvarchar(max)
			Declare c_cursor cursor FOR
				Select 'IF NOT EXISTS (select * from INFORMATION_SCHEMA.TABLES where table_name = ''' + tmp.TableName + ''' AND TABLE_SCHEMA = ''DRAS'')
				BEGIN
					SELECT * INTO DRAS.' + tmp.TableName + ' FROM dbo.' + tmp.TableName + '
				END' 
				from (
				select 'ETL_' + TableName AS TableName from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_StoredProcedure' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Intersect' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Locate' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Located_Points' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				) tmp
				INNER JOIN INFORMATION_SCHEMA.TABLES t on t.TABLE_NAME = tmp.TableName AND t.TABLE_SCHEMA = 'dbo'

			OPEN c_cursor
				FETCH NEXT FROM c_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM c_cursor INTO @sql
				END

			CLOSE c_cursor
			DEALLOCATE c_cursor

			Declare d_cursor cursor FOR
				select 'Drop Table dbo.' + tmp.TableName
				from (
				select 'ETL_' + TableName AS TableName from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_StoredProcedure' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Intersect' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Locate' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				UNION
				select 'ETL_' + TableName + '_Located_Points' from tmpDataExchangeAllMappingsInfo m where TableName in (Select VirtualTableName from VirtualTable_BKP)
				) tmp
				INNER JOIN INFORMATION_SCHEMA.TABLES t on t.TABLE_NAME = tmp.TableName AND t.TABLE_SCHEMA = 'dbo'

			OPEN d_cursor
				FETCH NEXT FROM d_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM d_cursor INTO @sql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650124 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 25
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650125', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 25', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650125 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- fn_GenerateTransfromSelectStatement.sql

			declare @sql nvarchar(max)

			set @sql = 'ALTER function [dbo].[fn_GenerateTransfromSelectStatement]
									(
										@tableName varchar(200) 
									)
									returns varchar(max)
									AS
									BEGIN

									DECLARE @column_names varchar(max) = ''''
									DECLARE @column_name varchar(100)
									DECLARE @column_short_name varchar(100)
									DECLARE @joins varchar(max) = ''''
									DECLARE @selectStatment varchar(max) = ''''
									DECLARE @refTableCount int 
									DECLARE @refParentTableCount int 
									DECLARE @fromUnit varchar(50)
									DECLARE @toUnit varchar(50)
									DECLARE @precision varchar(10)
									DECLARE @scale varchar(10)
									DECLARE @conversionVariables varchar(max) = ''''
									DECLARE @execConversions varchar(max) = ''''
									DECLARE @tempconversionVariables varchar(max) = ''''
									DECLARE @exectempConversions varchar(max) = ''''
									DECLARE @ldTableName varchar(100) = ''''
									DECLARE @IsListDomain int = 0

									-- Check whether the table is virtual table

									IF EXISTS (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @tableName AND TABLE_SCHEMA = ''DRAS'')
									BEGIN
										SET @tableName = ''DRAS.'' + @tableName
									END

									-- Create temp listdomain table variable
									Declare @ListDomain TABLE (
									FK_Name varchar(100), TableName varchar(100), ColumnName varchar(100), ReferencedTable varchar(100), ReferencedColumn varchar(100))

									Insert into @ListDomain
									SELECT FK_Name, TableName, ColumnName, ReferencedTable, ReferencedColumn 
									FROM StageFkeysInfo tmp
									WHERE tmp.ReferencedTable like ''LD_%''
									order by tablename

									-- Generate variables for conversion - no temperature
									DECLARE cv_cursor CURSOR FOR
										SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')
									OPEN cv_cursor
										FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit

										IF @@FETCH_STATUS = 0
										BEGIN
											SET @conversionVariables = @conversionVariables + '' ''
										END

										WHILE @@FETCH_STATUS = 0
										BEGIN
											SET @conversionVariables = @conversionVariables + ''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) '' + CHAR(13)
											FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit
										END
									CLOSE cv_cursor
									DEALLOCATE cv_cursor

									-- Generate exec conversion stored proc - no temperature
									DECLARE ec_cursor CURSOR FOR
										SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = replace(@tableName, ''DRAS.'', '''')

									OPEN ec_cursor
										FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit

										IF @@FETCH_STATUS = 0
										BEGIN
											SET @execConversions = @execConversions + '' ''
										END


										WHILE @@FETCH_STATUS = 0
										BEGIN
											SET @execConversions = @execConversions + ''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', NULL, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
											FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit
										END
									CLOSE ec_cursor
									DEALLOCATE ec_cursor

									-- Generate variables for conversion - temperature
									DECLARE tcv_cursor CURSOR FOR
										SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

									OPEN tcv_cursor
										FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

										WHILE @@FETCH_STATUS = 0
										BEGIN
											SET @tempconversionVariables =''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) , @TempOffset numeric(13,5)'' + CHAR(13)
											FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
										END
									CLOSE tcv_cursor
									DEALLOCATE tcv_cursor

									-- Generate exec conversion stored proc - temperature
									DECLARE tec_cursor CURSOR FOR
										SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE   (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

									OPEN tec_cursor
										FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

										WHILE @@FETCH_STATUS = 0
										BEGIN
											SET @exectempConversions =''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', @TempOffset OUTPUT, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
											FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
										END
									CLOSE tec_cursor
									DEALLOCATE tec_cursor

									IF EXISTS (Select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tableName and COLUMN_NAME = ''Id'')
									BEGIN
									SET @column_names = ''Id = case when t.SourceId not like ''''%[^0-9]%'''' then t.SourceId else IDLookup.Id end '' + CHAR(13)
									END
						


									-- Get StationSeriesId columns
									DECLARE s_cursor CURSOR FOR
										SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
										AND c.Column_Name LIKE ''%StationSeriesId'' ORDER BY c.Column_Name

									SET @refTableCount = 1
									OPEN s_cursor
										FETCH NEXT FROM s_cursor INTO @column_name
	
										IF @@FETCH_STATUS = 0 AND LEN(@column_names) > 0
										BEGIN
											SET @column_names = @column_names + '',''
										END

										WHILE @@FETCH_STATUS = 0
										BEGIN
											IF @column_name <> ''StationSeriesId''
											BEGIN
												SET @column_names = @column_names + ''ss'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', '' 

												SET @joins = @joins + '' LEFT JOIN StationSeries ss'' + cast(@refTableCount AS varchar(10)) + '' with (nolock) ON ss'' + cast(@refTableCount AS varchar(10)) + ''.SourceId = t.'' + @column_name + CHAR(13)
											END
											ELSE
											BEGIN
												SET @column_names = @column_names + ''ss1.Id AS '' + @column_name + '', '' 
											END

											SET @refTableCount = @refTableCount + 1

											FETCH NEXT FROM s_cursor INTO @column_name
										END

									CLOSE s_cursor
									DEALLOCATE s_cursor

									IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where (c.Table_Name = @tableName or c.Table_Name = Replace(@tableName, ''DRAS.'', '''')) AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId''))
									BEGIN
										IF right(@column_names, 1) = '',''
										BEGIN
											SET @column_names = subString(@column_names, 1, len(@column_names)-1)
										END

										SET @column_names = @column_names + 
											(SELECT Cols = STUFF((SELECT  '', '' + CASE WHEN c.Column_Name = ''BeginStationSeriesId'' THEN ''BeginStationSeriesGUID'' WHEN c.Column_Name = ''EndStationSeriesId'' THEN ''EndStationSeriesGUID'' WHEN c.Column_Name = ''StationSeriesId'' THEN ''StationSeriesGUID'' END + '' = t.'' + QUOTENAME(c.Column_Name)
											FROM INFORMATION_SCHEMA.COLUMNS c	
											WHERE (table_name = @tableName or table_name = Replace(@tableName, ''DRAS.'', ''''))
											AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId'')
											ORDER BY c.Column_Name
											FOR XML PATH('''')), 1, 2, ''''))
									END

									-- Get ListDomain columns
									IF EXISTS (Select * from StageFKeysInfo where ReferencedTable LIKE ''LD%'' AND TableName = CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN REPLACE(@tableName, ''DRAS.'', '''') ELSE ''MLVCorrection'' END)
									BEGIN
										SET @IsListDomain = 1
									END
									ELSE
									BEGIN
										SET @IsListDomain = 0
									END

									DECLARE l_cursor CURSOR FOR
										SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
										And (Column_Name in (Select ColumnName from StageFKeysInfo where ReferencedTable LIKE ''LD%'') or Column_Name = ''DataFieldValueDomainId'')
										ORDER BY c.Column_Name


									SET @refTableCount = 1
									OPEN l_cursor
										FETCH NEXT FROM l_cursor INTO @column_name

										WHILE @@FETCH_STATUS = 0
										BEGIN


											IF @column_name like ''%DomainId''
											BEGIN
												SET @column_short_name = replace(@column_name, ''DomainId'', '''')
											END
											ELSE
											BEGIN
												SET @column_short_name = CASE WHEN right(@column_name, 2) = ''ld'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
											END

											IF @IsListDomain = 1
											BEGIN
												SET @joins = @joins + '' '' + (SELECT Replace(dbo.fn_ScriptJoinLDColumn(Replace(
			
												CASE WHEN @tableName NOT IN (''DistrictDivision'', ''Area'', ''StateProvince'') THEN @tableName ELSE ''MLVCorrection'' END
			
			
												, ''DRAS.'', ''''), @column_name, '' tbl'' + cast(@refTableCount AS varchar(10))), ''.Id'', ''.Code''))+ CHAR(13)
											END

											IF right(@column_names, 1) = '',''
											BEGIN
												SET @column_names = subString(@column_names, 1, len(@column_names)-1)
											END

											IF @IsListDomain = 1
											BEGIN
												IF LEN(@column_names) > 0
													SET @column_names = @column_names + '', tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
												ELSE
													SET @column_names = ''tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
											END
											ELSE
											BEGIN
												IF LEN(@column_names) > 0
													SET @column_names = @column_names + '', Cast(null as numeric(10,0)) AS '' + @column_name + '', Cast(null as varchar(40)) AS '' + @column_short_name + CHAR(13)
												ELSE
													SET @column_names =''Cast(null as numeric(10,0)) AS '' + @column_name + '', Cast(null as varchar(40)) AS '' + @column_short_name + CHAR(13)
											END

											SET @refTableCount = @refTableCount + 1

											FETCH NEXT FROM l_cursor INTO @column_name

										END

									CLOSE l_cursor
									DEALLOCATE l_cursor

									-- Get ParentColumns columns
									DECLARE p_cursor CURSOR FOR
										SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
										And Column_Name in (select ColumnName from StageFKeysInfo where TableName= case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END )
										And Column_Name NOT in (Select ColumnName from @ListDomain)
										AND Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'', ''BaseIliId'', ''Stg_ILIId'')
										ORDER BY c.Column_Name

									SET @refParentTableCount = 1
									OPEN p_cursor
										FETCH NEXT FROM p_cursor INTO @column_name

										WHILE @@FETCH_STATUS = 0
										BEGIN
											BEGIN
												SET @column_short_name = CASE WHEN right(@column_name, 2) = ''Id'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
											END
								
											IF @column_name IN (''RCReasonTypeId'')
											BEGIN
												SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.Code'')) + CHAR(13)
											END
											ELSE IF @column_name NOT IN (''RCScenarioID'')
											BEGIN
												SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.SourceId'')) + CHAR(13)
											END
											ELSE
											BEGIN
												SET @joins = @joins + '' '' + (SELECT dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10)))) + CHAR(13)
											END

											IF right(@column_names, 1) = '',''
											BEGIN
												SET @column_names = subString(@column_names, 1, len(@column_names)-1)
											END

											IF LEN(@column_names) > 0
												SET @column_names = @column_names + '', p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
											ELSE
												SET @column_names =''p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
											SET @refParentTableCount = @refParentTableCount + 1

											FETCH NEXT FROM p_cursor INTO @column_name
										END

									CLOSE p_cursor
									DEALLOCATE p_cursor

									IF NOT EXISTS (Select * from INFORMATION_SCHEMA.Tables where TABLE_NAME = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END AND TABLE_SCHEMA = ''DRAS'')
									BEGIN
										IF @TableName = ''DischargeSubSystem''
										BEGIN
											SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
												on IDLookup.GUID = t.SourceId
													and IDLookup.TableName = ''''Lineloop'''''' + CHAR(13)
										END
										ELSE IF @TableName = ''MLVSection''
										BEGIN
											SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
												on IDLookup.GUID = t.SourceId
													and IDLookup.TableName = ''''StationSeries'''''' + CHAR(13)
										END
										ELSE
										BEGIN
											SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
												on IDLookup.GUID = t.SourceId
													and IDLookup.TableName = '''''' + @TableName + '''''''' + CHAR(13)
										END
									END
									ELSE
									BEGIN
										SET @joins = @joins + '' LEFT JOIN VTGUIDLookup IDLookup with (nolock)
											on IDLookup.GUID = t.SourceId
												and IDLookup.TableName = '''''' + Replace(@tableName, ''DRAS.'', '''') + '''''''' + CHAR(13)
									END

									----Get columns which required conversion -- no temperature
									DECLARE c_cursor CURSOR FOR
										SELECT * FROM (
											SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = case when @tableName like ''DRAS.%'' then Replace(@tableName, ''DRAS.'', '''') else @tableName END
										) tmp
										ORDER BY ColumnName

									OPEN c_cursor
										FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

										WHILE @@FETCH_STATUS = 0
										BEGIN
											IF right(@column_names, 1) = '',''
											BEGIN
												SET @column_names = subString(@column_names, 1, len(@column_names)-1)
											END
											ELSE IF right(@column_names, 2) = '', ''
											BEGIN
												SET @column_names = subString(@column_names, 1, len(@column_names)-1)
											END

											IF @column_name <> ''StationNum''
											BEGIN
												IF LEN(@column_names) > 0
													SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
												ELSE
													SET @column_names = @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
											END
											ELSE
											BEGIN
											IF LEN(@column_names) > 0
												SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
											ELSE
												SET @column_names = @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
											END

											FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
										END
									CLOSE c_cursor
									DEALLOCATE c_cursor

									----Get columns which required conversion -- temperature

									DECLARE ct_cursor CURSOR FOR
										SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

									OPEN ct_cursor
										FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

										WHILE @@FETCH_STATUS = 0
										BEGIN
											IF right(@column_names, 1) = '',''
											BEGIN
												SET @column_names = subString(@column_names, 1, len(@column_names)-1)
											END

											IF LEN(@column_names) > 0
												SET @column_names = @column_names + '', '' + @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
											ELSE
												SET @column_names = @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
											FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
										END
									CLOSE ct_cursor
									DEALLOCATE ct_cursor

									---- Get all other columns
						
									IF right(@column_names, 1) = '',''
									BEGIN
										SET @column_names = subString(@column_names, 1, len(@column_names)-1)
									END
									IF LEN(@column_names) > 0
										SET @column_names = @column_names + '','' +
										(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
										FROM INFORMATION_SCHEMA.Columns c 
										LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
										Where c.Table_Name = ''Extract_'' + Replace(@tableName, ''DRAS.'', '''')
										AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
										And sfi.ColumnName IS NULL
										AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'', ''DataFieldValueDomainId'')
										AND c.Column_Name NOT LIKE ''%StationNum''
										AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = Replace(@tableName, ''DRAS.'', ''''))
										ORDER BY c.Column_Name
										FOR XML PATH('''')), 1, 2, ''''))
									ELSE 
										SET @column_names = 
										(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
										FROM INFORMATION_SCHEMA.Columns c 
										LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
										Where c.Table_Name = ''Extract_'' + Replace(@tableName, ''DRAS.'', '''')
										AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
										And sfi.ColumnName IS NULL
										AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'', ''DataFieldValueDomainId'')
										AND c.Column_Name NOT LIKE ''%StationNum''
										AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = Replace(@tableName, ''DRAS.'', ''''))
										ORDER BY c.Column_Name
										FOR XML PATH('''')), 1, 2, ''''))
						

									IF right(@column_names, 1) = '',''
									BEGIN
										SET @column_names = subString(@column_names, 1, len(@column_names)-1)
									END

									SET @column_names = @column_names + CHAR(13) +  '',[LastModDateTime] = getdate() 
									,[LastModByUserId] = SUSER_SNAME() 
									,t.[SourceId]
									,[CreatedDate] = getdate()  
									,[CreatedUser] = SUSER_SNAME() 
									,t.[CheckSumValue]''

									IF NOT EXISTS (Select * from INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''DRAS'' AND TABLE_NAME = Replace(@tableName, ''DRAS.'', ''''))
									BEGIN
										SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
									END
									ELSE
									BEGIN
										SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from DRAS.Extract_'' + Replace(@tableName, ''DRAS.'', '''') + '' with (nolock)) as t ''+ CHAR(13) + @joins
									END

									RETURN @selectStatment
									END'
			exec sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650125 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 25
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650126', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 1, Updates 25', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

/*
	Everything below this should remain at the end of this script. Any added code should be placed above
	this section and the @FinalDBVersion variable should be changed to the last DBVersion within this script
*/
BEGIN
	DECLARE @FinalDBVersion INT 
	DECLARE @DBVersion INT 
	DECLARE @CheckPoint INT
	DECLARE @ErrorMsg NVARCHAR(600)

	SET @FinalDBVersion = 650126

	SELECT @DBVersion = DBVersion, @CheckPoint = DBVersionCheckPoint
	FROM Versioninfo

	IF EXISTS (SELECT * FROM dbo.VersionInfo WHERE DBVersion BETWEEN 650016 AND @FinalDBVersion)
		AND @DBVersion <> @FinalDBVersion AND @CheckPoint <> 0
	BEGIN

		SET @ErrorMsg = 'The database upgrade did not complete. This database is currently at DBVersion ' 
		+ CAST(@DBVersion AS NVARCHAR) + ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR);
		
		THROW 51001, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		PRINT 'This database is currently at DBVersion ' + CAST(@DBVersion AS NVARCHAR) 
		+ ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR) + '.'
		+ CHAR(10) + 'This script upgrades IRAS databases from DBVersion 650016 to ' + CAST(@FinalDBVersion AS NVARCHAR);	
	END
END
GO