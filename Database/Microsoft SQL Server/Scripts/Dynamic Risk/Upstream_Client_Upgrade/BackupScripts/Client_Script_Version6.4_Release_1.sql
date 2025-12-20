IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage')
BEGIN
	RAISERROR( 'The target database is not Stage database for applying this upgrade script.', 11, 0)
END
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			--COMMENTED OUT - Sections that include tables that do not exist in KEY_IRASV5_UPSTREAM (i.e StructureVertex)

			-- AddCreatedDateCreatedUserColumn.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CouponReading' And c.Column_Name = 'CreatedDate')
			BEGIN
				SET @sql = 'ALTER TABLE CouponReading ADD CreatedDate DATETIME DEFAULT GETDATE() NOT NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT distinct * FROM (
			select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			from sys.tables as t
			join sys.columns as c on (c.[object_id] = t.[object_id])
			join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
				where TableName = 'CouponReading' and ColumnName = 'CreatedDate'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[CouponReading] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CouponReading' And c.Column_Name = 'CreatedUser')
			BEGIN
				SET @sql = 'ALTER TABLE CouponReading ADD CreatedUser VARCHAR(45) DEFAULT (suser_sname()) NOT NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT distinct * FROM (
			select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			from sys.tables as t
			join sys.columns as c on (c.[object_id] = t.[object_id])
			join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
				where TableName = 'CouponReading' and ColumnName = 'CreatedUser'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[CouponReading] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_CouponReading' And c.Column_Name = 'CreatedUser')
			BEGIN
				SET @sql = 'ALTER TABLE Load_CouponReading ADD CreatedUser VARCHAR(45) DEFAULT (suser_sname()) NOT NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT distinct * FROM (
			select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			from sys.tables as t
			join sys.columns as c on (c.[object_id] = t.[object_id])
			join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
				where TableName = 'Load_CouponReading' and ColumnName = 'CreatedUser'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[Load_CouponReading] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_CouponReading' And c.Column_Name = 'CreatedDate')
			BEGIN
				SET @sql = 'ALTER TABLE Load_CouponReading ADD CreatedDate DATETIME DEFAULT (getdate()) NOT NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT distinct * FROM (
			select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			from sys.tables as t
			join sys.columns as c on (c.[object_id] = t.[object_id])
			join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
				where TableName = 'Load_CouponReading' and ColumnName = 'CreatedDate'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[Load_CouponReading] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
				EXEC sp_executesql @sql
			END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'StructureVertex' And c.Column_Name = 'CreatedDate')
			--BEGIN
			--	SET @sql = 'ALTER TABLE StructureVertex ADD CreatedDate DATETIME DEFAULT (getdate()) NOT NULL'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS(
			--	SELECT distinct * FROM (
			--select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			--from sys.tables as t
			--join sys.columns as c on (c.[object_id] = t.[object_id])
			--join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
			--	where TableName = 'StructureVertex' and ColumnName = 'CreatedDate'
			--)
			--BEGIN
			--	SET @sql = 'ALTER TABLE [dbo].[StructureVertex] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'StructureVertex' And c.Column_Name = 'CreatedUser')
			--BEGIN
			--	SET @sql = 'ALTER TABLE StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT (suser_sname()) NOT NULL'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS(
			--	SELECT distinct * FROM (
			--select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			--from sys.tables as t
			--join sys.columns as c on (c.[object_id] = t.[object_id])
			--join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
			--	where TableName = 'StructureVertex' and ColumnName = 'CreatedUser'
			--)
			--BEGIN
			--	SET @sql = 'ALTER TABLE [dbo].[StructureVertex] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_StructureVertex' And c.Column_Name = 'CreatedDate')
			--BEGIN
			--	SET @sql = 'ALTER TABLE Load_StructureVertex ADD CreatedDate DATETIME DEFAULT (getdate()) NOT NULL'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS(
			--	SELECT distinct * FROM (
			--select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			--from sys.tables as t
			--join sys.columns as c on (c.[object_id] = t.[object_id])
			--join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
			--	where TableName = 'Load_StructureVertex' and ColumnName = 'CreatedDate'
			--)
			--BEGIN
			--	SET @sql = 'ALTER TABLE [dbo].[Load_StructureVertex] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_StructureVertex' And c.Column_Name = 'CreatedUser')
			--BEGIN
			--	SET @sql = 'ALTER TABLE Load_StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT (suser_sname()) NOT NULL'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS(
			--	SELECT distinct * FROM (
			--select t.name as TableName, c.[name] as ColumnName ,dc.[name] AS DefaultConstraint,dc.[definition]
			--from sys.tables as t
			--join sys.columns as c on (c.[object_id] = t.[object_id])
			--join sys.default_constraints as dc on (dc.[object_id] = c.[default_object_id])) tmp
			--	where TableName = 'Load_StructureVertex' and ColumnName = 'CreatedUser'
			--)
			--BEGIN
			--	SET @sql = 'ALTER TABLE [dbo].[Load_StructureVertex] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
			--	EXEC sp_executesql @sql
			--END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @sql nvarchar(max)
			
			-- AlterHydroTestName_Stage.sql
			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'HydroTest' And c.Column_Name = 'HydroTestName')
			BEGIN
				SET @sql = 'ALTER TABLE HydroTest ALTER COLUMN HydroTestName varchar(50) NULL'
				EXEC sp_executesql @sql
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_HydroTest' And c.Column_Name = 'HydroTestName')
			BEGIN
				SET @sql = 'ALTER TABLE Load_HydroTest ALTER COLUMN HydroTestName varchar(50) NULL'
				EXEC sp_executesql @sql
			END
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 2
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- CLIENT_NewRecordsIntoSystemPreferencesAndListDomain_BL40381.sql
			/*
				New records to be inserted in the ListDomian table.
				List domains for excavation import anomaly type.
			*/
			-- Metal Loss (Corrosion) default type
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Corrosion' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Type'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Type'), 'Corrosion', 'Corrosion', NULL);
			END
			-- Mechanical Damage (Deformation) default type
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Deformation' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Defect Type'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Defect Type'), 'Deformation', 'Deformation', NULL);
			END
			-- ESCA (CrackLike) default type
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Crack-Like' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type'), 'Crack-Like', 'Crack-Like', NULL);
			END


			/*
				New records to be inserted in the ListDomian table.
				List domains for excavation import anomaly status.
			*/
			-- Metal Loss (Corrosion) "Not Found In Field" status
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Status'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Status'), 'Not Found In Field', 'Not Found In Field', NULL);
			END
			-- Mechanical Damage (Deformation) "Not Found In Field" status
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Status'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Status'), 'Not Found In Field', 'Not Found In Field', NULL);
			END
			-- ESCA (CrackLike) "Not Found In Field" status
			IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Site Crack Anomaly Status'))
			BEGIN
				INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
				VALUES ((SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Site Crack Anomaly Status'), 'Not Found In Field', 'Not Found In Field', NULL);
			END


			/*
				New records to be inserted in the SystemPreferences table.
				System preferences that define the default list domains for anomalies in excavation import.
			*/
			-- Metal Loss (Corrosion) type default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultMetalLossType')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultMetalLossType', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Corrosion' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Type')), null);
			END
			-- Metal Loss (Corrosion) status default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultMetalLossStatus')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultMetalLossStatus', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Metal Loss Status')), null);
			END
			-- Mechanical Damage (Deformation) type default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultMechanicalDamageType')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultMechanicalDamageType', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Deformation' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Defect Type')), null);
			END
			-- Mechanical Damage (Deformation) status default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultMechanicalDamageStatus')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultMechanicalDamageStatus', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Mechanical Damage Status')), null);
			END
			-- ESCA (CrackLike) type default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultESCAType')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultESCAType', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Crack-Like' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type')), null);
			END
			-- ESCA (CrackLike) status default list domain
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'DefaultESCAStatus')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('DefaultESCAStatus', (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Site Crack Anomaly Status')), null);
			END
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 3
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			--COMMENTED OUT - Sections that involve tables that do not exist in KEY_IRASV5_UPSTREAM (i.e LandSlideArea)

			-- Script To Create Load LandSlideArea.sql
			-- CREATE Extract_LandSlideArea TABLE AND ADD CheckSumValue TO LandSlideArea

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'LandSlideArea' AND c.COLUMN_NAME = 'CheckSumValue')
			--BEGIN
			--	ALTER TABLE LandSlideArea ADD CheckSumValue [INT]  NULL
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'load_LandSlideArea')
			--BEGIN
			--	CREATE TABLE [dbo].[load_LandSlideArea](
			--		[Id] [numeric](10, 0) NOT NULL,
			--		[EffectiveStartDate] [datetime] NULL,
			--		[EffectiveEndDate] [datetime] NULL,
			--		[LandSlideAreaRangeLD] [numeric](7, 0) NULL,
			--		[LandSlideAreaMin] [numeric](10, 0) NULL,
			--		[LandSlideAreaMax] [numeric](10, 0) NULL,
			--		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
			--		[BeginStationNum] [numeric](13, 5) NOT NULL,
			--		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
			--		[EndStationNum] [numeric](13, 5) NOT NULL,
			--		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			--		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			--		[LandSlideAreaCode] [varchar](55) NULL,
			--		[LandSlideAreaLD] [numeric](7, 0) NULL,
			--		[SourceId] [varchar](50) NOT NULL,
			--		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
			--		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			--		[CheckSumValue] [INT] NOT NULL
			--		CONSTRAINT [Pk_LandSlideAreaSourceId] PRIMARY KEY CLUSTERED 
			--	(
			--		[SourceId] ASC
			--	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			--	) ON [PRIMARY]
			--END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 4
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			--COMMENTED OUT - Sections that involve tables that do not exist in KEY_IRASV5_UPSTREAM (i.e EarthquakeArea)

			-- Script To Create Load_EarthquakeArea Table.sql

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'EarthquakeArea' AND c.COLUMN_NAME = 'CheckSumValue')
			--BEGIN
			--	Alter table EarthquakeArea add CheckSumValue[int] NULL
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'Load_EarthQuakeArea')
			--BEGIN
			--	CREATE TABLE [dbo].[Load_EarthQuakeArea](
			--		[Id] [numeric](10, 0) NOT NULL,
			--		[EffectiveStartDate] [datetime] NULL,
			--		[EffectiveEndDate] [datetime] NULL,
			--		[EarthQuakeAreaRangeLD] [numeric](7, 0) NULL,
			--		[EarthQuakeAreaMin] [numeric](10, 0) NULL,
			--		[EarthQuakeAreaMax] [numeric](10, 0) NULL,
			--		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
			--		[BeginStationNum] [numeric](13, 5) NOT NULL,
			--		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
			--		[EndStationNum] [numeric](13, 5) NOT NULL,
			--		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			--		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			--		[SourceId] [varchar](50) Not NULL,
			--		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
			--		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			--		[CheckSumValue] [int] NOT NULL,
			--	 CONSTRAINT [PK_EarthQuakeAreaSourceId] PRIMARY KEY CLUSTERED 
			--	  --CONSTRAINT [PK_Load_FloodArea] PRIMARY KEY CLUSTERED 
			--	(
			--		[SourceId] ASC
			--	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			--	) ON [PRIMARY]

			--END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 5
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN
			DECLARE @sql nvarchar(max)

			-- ScripToCreateLoadTableForExcavationSiteCrackAnomaly.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'LOAD_EXCAVSITECRACKANOMALY')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].LOAD_EXCAVSITECRACKANOMALY(
							[Id] [numeric](10, 0) NOT NULL,
							[EffectiveStartDate] [datetime] NOT NULL,
							[EffectiveEndDate] [datetime] NULL,
							[ExcavationSiteId] [numeric](10, 0) NULL,
							[ESCAVendorPackageCode] [varchar](50) NULL,
							[ESCATypeDomainId] [numeric](7, 0) NULL,
							[ESCAAnomalyNumber] [varchar](15) NULL,
							[ESCAAnomalyDepth] [varchar](15) NULL,
							[ESCAGirthWeldNum] [varchar](25) NULL,
							[ESCADistanceFromGirthWeld] [numeric](10, 3) NULL,
							[ESCALargestIndividualInd] [numeric](10, 0) NULL,
							[ESCALength] [numeric](9, 2) NULL,
							[ESCAWidth] [numeric](9, 2) NULL,
							[ESCAOrientation] [numeric](3, 0) NULL,
							[ESCASurfaceInd] [varchar](2) NULL,
							[ESCADescr] [varchar](254) NULL,
							[ESCAComment] [varchar](255) NULL,
							[ESCAGirthWeldNumDS] [varchar](25) NULL,
							[ESCADistanceFromGirthWeldDS] [numeric](10, 3) NULL,
							[AppVersion] [varchar](255) NULL,
							[ESCALatitude] [numeric](11, 9) NULL,
							[ESCALongitude] [numeric](12, 9) NULL,
							[Escax] [numeric](12, 3) NULL,
							[Escay] [numeric](12, 3) NULL,
							[Escaz] [numeric](10, 3) NULL,
							[StationSeriesId] [numeric](10, 0) NULL,
							[StationNum] [numeric](13, 5) NULL,
							[LastModByUserId] [varchar](45) NOT NULL,
							[LastModDateTime] [datetime] NOT NULL,
							[InlineInspectionCAId] [numeric](10, 0) NULL,
							[ESCAStatusDomainId] [numeric](7, 0) NOT NULL,
							[ESCADepthPct] [numeric](8, 5) NULL,
							[SourceId] [varchar](50) NOT NULL,
							[CreatedDate] [datetime] NOT NULL,
							[CreatedUser] [varchar](45) NOT NULL,
							[CheckSumValue] [int] NOT NULL,
						 CONSTRAINT [PK_EXCAVCASourceId] PRIMARY KEY CLUSTERED 
						(
							[SourceId] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
						) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END
			
			IF NOT EXISTS(
				SELECT obj_table.NAME      AS TableName, 
					   obj_Constraint.NAME AS ConstraintName, 
					   columns.NAME        AS ColumnName
				FROM   sys.objects obj_table 
					   JOIN sys.objects obj_Constraint 
						 ON obj_table.object_id = obj_Constraint.parent_object_id 
					   JOIN sys.sysconstraints constraints 
						 ON constraints.constid = obj_Constraint.object_id 
					   JOIN sys.columns columns 
						 ON columns.object_id = obj_table.object_id 
							AND columns.column_id = constraints.colid 
				where obj_table.NAME = 'LOAD_EXCAVSITECRACKANOMALY' and columns.Name = 'LastModByUserId'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[LOAD_EXCAVSITECRACKANOMALY] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT obj_table.NAME      AS TableName, 
					   obj_Constraint.NAME AS ConstraintName, 
					   columns.NAME        AS ColumnName
				FROM   sys.objects obj_table 
					   JOIN sys.objects obj_Constraint 
						 ON obj_table.object_id = obj_Constraint.parent_object_id 
					   JOIN sys.sysconstraints constraints 
						 ON constraints.constid = obj_Constraint.object_id 
					   JOIN sys.columns columns 
						 ON columns.object_id = obj_table.object_id 
							AND columns.column_id = constraints.colid 
				where obj_table.NAME = 'LOAD_EXCAVSITECRACKANOMALY' and columns.Name = 'LastModDateTime'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[LOAD_EXCAVSITECRACKANOMALY] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT obj_table.NAME      AS TableName, 
					   obj_Constraint.NAME AS ConstraintName, 
					   columns.NAME        AS ColumnName
				FROM   sys.objects obj_table 
					   JOIN sys.objects obj_Constraint 
						 ON obj_table.object_id = obj_Constraint.parent_object_id 
					   JOIN sys.sysconstraints constraints 
						 ON constraints.constid = obj_Constraint.object_id 
					   JOIN sys.columns columns 
						 ON columns.object_id = obj_table.object_id 
							AND columns.column_id = constraints.colid 
				where obj_table.NAME = 'LOAD_EXCAVSITECRACKANOMALY' and columns.Name = 'CreatedDate'
			)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[LOAD_EXCAVSITECRACKANOMALY] ADD  DEFAULT (getdate()) FOR [CreatedDate]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS(
				SELECT obj_table.NAME      AS TableName, 
					   obj_Constraint.NAME AS ConstraintName, 
					   columns.NAME        AS ColumnName
				FROM   sys.objects obj_table 
					   JOIN sys.objects obj_Constraint 
						 ON obj_table.object_id = obj_Constraint.parent_object_id 
					   JOIN sys.sysconstraints constraints 
						 ON constraints.constid = obj_Constraint.object_id 
					   JOIN sys.columns columns 
						 ON columns.object_id = obj_table.object_id 
							AND columns.column_id = constraints.colid 
				where obj_table.NAME = 'LOAD_EXCAVSITECRACKANOMALY' and columns.Name = 'CreatedUser'
				)
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[LOAD_EXCAVSITECRACKANOMALY] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]'
				EXEC sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 6
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 7
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640007 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 7
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 1 Updates 01 hotfixes
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640101', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 1, Updates 01 hotfixes'

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 0
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO