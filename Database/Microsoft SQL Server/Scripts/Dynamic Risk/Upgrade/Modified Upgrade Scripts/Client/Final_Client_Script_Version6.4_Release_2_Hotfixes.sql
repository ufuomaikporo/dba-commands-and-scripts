IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage')
BEGIN
	RAISERROR( 'The target database is not Stage database for applying this upgrade script.', 11, 0)
END
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Change SourceId to nullable
			DECLARE @sql nvarchar(max)
			DECLARE c_cursor CURSOR FOR
				SELECT 'Alter table ' + c.Table_Name + ' Alter Column SourceId Varchar(50) NULL' FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'SourceId' AND is_nullable = 'NO' AND c.Table_Name NOT LIKE 'LOAD%'

			OPEN c_cursor
				FETCH NEXT FROM c_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM c_cursor INTO @sql
				END

			CLOSE c_cursor
			DEALLOCATE c_cursor

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 06 hotfixes
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640206', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 06 hotfixes'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			IF object_id('FK_FloodArea_FloodAreaLD') IS NULL
			BEGIN
				ALTER TABLE [dbo].[FloodArea]  WITH CHECK ADD  CONSTRAINT [FK_FloodArea_FloodAreaLD] FOREIGN KEY([FloodAreaLD])
				REFERENCES [dbo].[ListDomain] ([Id])
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

-- BEGIN TRY
-- 	BEGIN TRAN
-- 		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
-- 		BEGIN
-- 			-- Overlays_ListDomain.sql
-- 			DECLARE @sql nvarchar(max)

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_FrostAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_FrostAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FROST AREA RANGE'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'FrostArea', 'LandUseFrostAreaRangeLDDomainId'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'FROST AREA RANGE'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FrostArea' AND ColumnName = 'FrostAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE #Temp_FrostAreaRange (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_FrostAreaRange (ListDomain)
-- 						values 
-- 						(''2.032-2.286m'')
-- 						,(''0-0.127m'')
-- 						,(''0.127-0.254m'')
-- 						,(''1.778-2.032m'')
-- 						,(''1.27-1.524m'')
-- 						,(''2.54--99.999m'')
-- 						,(''1.016-1.27m'')
-- 						,(''0.254-0.508m'')
-- 						,(''1.524-1.778m'')
-- 						,(''0.762-1.016m'')
-- 						,(''0.508-0.762m'')
-- 						,(''2.286-2.54m'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FrostArea'' and Columnname = ''FrostAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_FrostAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FrostArea'' and Columnname = ''FrostAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_FrostAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						END'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_LandUseType'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_LandUseType'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Land Use Type'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Land Use Type');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'LandUse', 'LandUseDomainId'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'Land Use Type'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LandUse' AND ColumnName = 'LandUseDomainId');

-- 			SET @sql = 'INSERT INTO #Temp_LandUseType (ListDomain)
-- 						values 
-- 						(''Wetlands'')
-- 						,(''Agricultural'')
-- 						,(''Low Density Residential'')
-- 						,(''Commercial/Industrial'')
-- 						,(''High Density Residential'')
-- 						,(''Remote'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LandUse'' and ColumnName = ''LandUseDomainId'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_LandUseType f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LandUse'' and ColumnName = ''LandUseDomainId'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_LandUseType f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_SoilType'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_SoilType'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Soil Type'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Type');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'SoilArea', 'SoilTypeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'Soil Type'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'SoilArea' AND ColumnName = 'SoilTypeLD');


-- 			SET @sql = 'CREATE TABLE #Temp_SoilType (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_SoilType (ListDomain)
-- 						values 
-- 						(''High Clay Content'')
-- 						,(''Other'')
-- 						,(''Rocky Soil'')
-- 						,(''Sandy Loam'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''SoilArea'' and ColumnName = ''SoilTypeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_SoilType f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''SoilArea'' and ColumnName = ''SoilTypeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_SoilType f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_FaultAreaSlipRate'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_FaultAreaSlipRate'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA DIP DIRECTION'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'FaultArea', 'FaultAreaSlipRateLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'FAULT AREA DIP DIRECTION'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaSlipRateLD');


-- 			SET @sql = 'CREATE TABLE #Temp_FaultAreaSlipRate (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_FaultAreaSlipRate (ListDomain)
-- 						values 
-- 						(''< 0.2 mm/year'')
-- 						,(''<0.2 mm/year'')
-- 						,(''0.2 - 1 mm/year'')
-- 						,(''>5 mm/year'')
-- 						,(''unknown'')
-- 						,(''1-5 mm/year'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaSlipRateLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_FaultAreaSlipRate f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaSlipRateLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_FaultAreaSlipRate f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_FaultAreaSlipSense'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_FaultAreaSlipSense'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA SLIP SENSE'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA SLIP SENSE');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'FaultArea', 'FaultAreaSlipSenseLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'FAULT AREA SLIP SENSE'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaSlipSenseLD');


-- 			SET @sql = 'CREATE TABLE #Temp_FaultAreaSlipSense (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_FaultAreaSlipSense (ListDomain)
-- 						values 
-- 						(''Normal'')
-- 						,(''unknown'')
-- 						,(''Thrust'')
-- 						,(''Reverse'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaSlipSenseLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_FaultAreaSlipSense f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaSlipSenseLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_FaultAreaSlipSense f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_FaultAreaDipDirection'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_FaultAreaDipDirection'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA DIP DIRECTION'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'FaultArea', 'FaultAreaDipDirectionLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'FAULT AREA DIP DIRECTION'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaDipDirectionLD');

-- 			SET @sql = 'CREATE TABLE #Temp_FaultAreaDipDirection (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_FaultAreaDipDirection (ListDomain)
-- 						values 
-- 						(''North'')
-- 						,(''Vertical'')
-- 						,(''East'')
-- 						,(''Northeast'')
-- 						,(''Center'')
-- 						,(''Southwest'')
-- 						,(''South'')
-- 						,(''Unspecified'')
-- 						,(''Northwest'')
-- 						,(''Southeast'')
-- 						,(''West'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaDipDirectionLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_FaultAreaDipDirection f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FaultArea'' and ColumnName = ''FaultAreaDipDirectionLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_FaultAreaDipDirection f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_TornadoDensityRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_TornadoDensityRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Tornado Area Ranking'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tornado Area Ranking');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'TornadoDensityArea', 'TornadoDensityRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'Tornado Area Ranking'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'TornadoDensityArea' AND ColumnName = 'TornadoDensityRangeLD');


-- 			SET @sql = 'CREATE TABLE  #Temp_TornadoDensityRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_TornadoDensityRange (ListDomain)
-- 						values 
-- 						(''0.500001 - 0.9999'')
-- 						,(''0 - 0.01'')
-- 						,(''0.010001 - 0.500'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''TornadoDensityArea'' and ColumnName = ''TornadoDensityRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_TornadoDensityRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''TornadoDensityArea'' and ColumnName = ''TornadoDensityRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_TornadoDensityRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_HurricaneAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_HurricaneAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Hurricane Ranking'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'HurricaneArea', 'HurricaneAreaRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'OF Hurricane Ranking'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'HurricaneArea' AND ColumnName = 'HurricaneAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE  #Temp_HurricaneAreaRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_HurricaneAreaRange (ListDomain)
-- 						values 
-- 						(''0-84'')
-- 						,(''85-100'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''HurricaneArea'' and ColumnName = ''HurricaneAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_HurricaneAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''HurricaneArea'' and ColumnName = ''HurricaneAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_HurricaneAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_SoilLandUse'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_SoilLandUse'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Soil Land Use'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Land Use');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'SoilLandUseArea', 'SoilLandUseLd'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'Soil Land Use'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'SoilLandUseArea' AND ColumnName = 'SoilLandUseLd');


-- 			SET @sql = 'CREATE TABLE #Temp_SoilLandUse (
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_SoilLandUse (ListDomain)
-- 						values 
-- 						(''Agricultural'')
-- 						,(''Salt/Tidal Flats'')
-- 						,(''Others'')
-- 						,(''Wetlands'')

-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''SoilLandUseArea'' and ColumnName = ''SoilLandUseLd'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_SoilLandUse f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''SoilLandUseArea'' and ColumnName = ''SoilLandUseLd'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_SoilLandUse f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_LightningStrikeAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_LightningStrikeAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Lightning Strike Density'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Lightning Strike Density');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'LightningStrikeArea', 'LightningStrikeAreaRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'Lightning Strike Density'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LightningStrikeArea' 
-- 							AND ColumnName = 'LightningStrikeAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE  #Temp_LightningStrikeAreaRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_LightningStrikeAreaRange (ListDomain)
-- 						values 
-- 						(''3-4'')
-- 						,(''7-8'')
-- 						,(''4-5'')
-- 						,(''8-9'')
-- 						,(''5-6'')
-- 						,(''2-3'')
-- 						,(''0-1'')
-- 						,(''1-2'')
-- 						,(''6-7'')


-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LightningStrikeArea'' and ColumnName = ''LightningStrikeAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_LightningStrikeAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LightningStrikeArea'' and ColumnName = ''LightningStrikeAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_LightningStrikeAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_FloodAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_FloodAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Flood Ranking'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'FloodArea', 'FloodAreaRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'OF Flood Ranking'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FloodArea' AND ColumnName = 'FloodAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE  #Temp_FloodAreaRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_FloodAreaRange (ListDomain)
-- 						values 
-- 						(''85-100'')
-- 						,(''70-84'')
-- 						,(''0-69'')



-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FloodArea'' and ColumnName = ''FloodAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_FloodAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''FloodArea'' and ColumnName = ''FloodAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_FloodAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_LandSlideAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_LandSlideAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'LANDSLIDE AREA RANGE'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'LANDSLIDE AREA RANGE');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'LandSlideArea', 'LandSlideAreaRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'LANDSLIDE AREA RANGE'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LandSlideArea' AND ColumnName = 'LandSlideAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE  #Temp_LandSlideAreaRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_LandSlideAreaRange (ListDomain)
-- 						values 
-- 						(''85-100'')
-- 						,(''70-84'')
-- 						,(''0-69'')


-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LandSlideArea'' and ColumnName = ''LandSlideAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_LandSlideAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''LandSlideArea'' and ColumnName = ''LandSlideAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_LandSlideAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			SET @sql = 'IF OBJECT_ID(''tempdb..#Temp_EarthQuakeAreaRange'',''U'') IS NOT NULL
-- 						DROP TABLE #Temp_EarthQuakeAreaRange'
-- 			EXEC sp_executesql @sql

-- 			INSERT INTO DomainCatalog (Id, DomainDescr)
-- 			SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Seismic Ranking'
-- 			FROM DomainCatalog
-- 			WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking');

-- 			INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
-- 			SELECT Id, 'EarthQuakeArea', 'EarthQuakeAreaRangeLD'
-- 			FROM DomainCatalog 
-- 			WHERE DomainDescr = 'OF Seismic Ranking'
-- 			AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'EarthQuakeArea' AND ColumnName = 'EarthQuakeAreaRangeLD');

-- 			SET @sql = 'CREATE TABLE  #Temp_EarthQuakeAreaRange(
-- 							ListDomain varchar(40))

-- 						INSERT INTO #Temp_EarthQuakeAreaRange (ListDomain)
-- 						values 
-- 						(''85-100'')
-- 						,(''70-84'')
-- 						,(''0-69'')


-- 						IF EXISTS (Select 
-- 							(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''EarthQuakeArea'' and ColumnName = ''EarthQuakeAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 						from #Temp_EarthQuakeAreaRange f
-- 						left outer join listdomain ld on f.ListDomain = ld.code
-- 						where ld.code is null)
-- 						begin 
-- 							insert into ListDomain
-- 							(DomainCatalogId, Code, Descr)
-- 							Select 
-- 								(Select DomainCatalogId from DomainCatalogColXRef where TableName = ''EarthQuakeArea'' and ColumnName = ''EarthQuakeAreaRangeLD'') as DomainCatalogId, f.ListDomain as Code, f.ListDomain as Descr
-- 							from #Temp_EarthQuakeAreaRange f
-- 							left outer join listdomain ld on f.ListDomain = ld.code
-- 							where ld.code is null
-- 						end'
-- 			EXEC sp_executesql @sql

-- 			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2
-- 		END	
-- 	COMMIT TRAN
-- END TRY
-- BEGIN CATCH
-- 	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
-- 	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
-- 	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
-- 	ROLLBACK TRAN
-- END CATCH

-- GO

-- BEGIN TRY
-- 	BEGIN TRAN
-- 		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
-- 		BEGIN
-- 			/********************************************************************************************************/
-- 			-- Update VersionInfo Application Version 6.4 Release 2 Updates 07 hotfixes
-- 			/********************************************************************************************************/

-- 			UPDATE dbo.VersionInfo
-- 			SET DBVersion = '640207', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 07 hotfixes'

-- 			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0
-- 		END	
-- 	COMMIT TRAN
-- END TRY
-- BEGIN CATCH
-- 	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
-- 	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
-- 	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
-- 	ROLLBACK TRAN
-- END CATCH

-- GO

-- BEGIN TRY
-- 	BEGIN TRAN
-- 		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640207 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
-- 		BEGIN
-- 			-- StageDB_FixColumnType_Bug50293.sql
-- 			IF Exists( SELECT DATA_TYPE
-- 			FROM INFORMATION_SCHEMA.COLUMNS
-- 			WHERE TABLE_NAME = 'Stg_ILIFacility' AND COLUMN_NAME = 'ILIFacNumber' AND DATA_TYPE = 'numeric')
-- 			BEGIN
-- 			ALTER TABLE [dbo].[Stg_ILIFacility] ALTER COLUMN ILIFacNumber [varchar](30) NULL;
-- 			END

-- 			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1
-- 		END	
-- 	COMMIT TRAN
-- END TRY
-- BEGIN CATCH
-- 	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
-- 	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
-- 	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
-- 	ROLLBACK TRAN
-- END CATCH

-- GO

-- BEGIN TRY
-- 	BEGIN TRAN
-- 		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640207 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
-- 		BEGIN
-- 			/********************************************************************************************************/
-- 			-- Update VersionInfo Application Version 6.4 Release 2 Updates 08 hotfixes
-- 			/********************************************************************************************************/

-- 			UPDATE dbo.VersionInfo
-- 			SET DBVersion = '640208', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 08 hotfixes'

-- 			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0
-- 		END	
-- 	COMMIT TRAN
-- END TRY
-- BEGIN CATCH
-- 	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
-- 	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
-- 	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
-- 	ROLLBACK TRAN
-- END CATCH

-- GO
