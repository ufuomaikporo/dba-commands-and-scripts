
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Adding V6 columns.sql
			-- This script is for adding the V6 columns into CoverDepthProfile

			DECLARE @sql nvarchar(max)

			IF OBJECT_ID('CoverDepthProfile') IS NULL
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[CoverDepthProfile](
								[Id] [numeric](10, 0) NOT NULL,
								[EffectiveStartDate] [datetime] NOT NULL,
								[EffectiveEndDate] [datetime] NULL,
								[CoverDepthReading] [numeric](8, 4) NOT NULL,
								[Latitude] [numeric](11, 9) NOT NULL,
								[Longitude] [numeric](12, 9) NOT NULL,
								[CoordSysDomainId] [numeric](7, 0) NOT NULL,
								[CoverDepthProfileComment] [varchar](255) NULL,
								[StationSeriesId] [numeric](10, 0) NOT NULL,
								[StationNum] [numeric](10, 3) NOT NULL,
								[LastModByUserId] [varchar](45) NOT NULL DEFAULT (suser_sname()),
								[LastModDateTime] [datetime] NOT NULL DEFAULT (getdate()),
								[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
								[BeginStationNum] [numeric](13, 5) NOT NULL,
								[EndStationSeriesId] [numeric](10, 0) NOT NULL,
								[EndStationNum] [numeric](13, 5) NOT NULL,
								[SourceId] [varchar](50) NOT NULL,
								[CreatedDate] [datetime] NOT NULL DEFAULT (getdate()),
								[CreatedUser] [varchar](45) NOT NULL DEFAULT (suser_sname()),
								[BeginStationSeriesGUID] [varchar](50) NULL,
								[EndStationSeriesGUID] [varchar](50) NULL,
							 CONSTRAINT [PK_CoverDepthProfile] PRIMARY KEY CLUSTERED 
							(
								[Id] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
							) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END

			SET @sql = ''

			IF Object_ID('FK_DOCCoordSysLD') IS NULL
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[CoverDepthProfile]  WITH CHECK ADD  CONSTRAINT [FK_DOCCoordSysLD] FOREIGN KEY([CoordSysDomainId])
							REFERENCES [dbo].[ListDomain] ([Id])'	
				EXEC sp_executesql @sql
			END

			IF Object_ID('FK_DOCCoordSysLD') IS NOT NULL
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[CoverDepthProfile] CHECK CONSTRAINT [FK_DOCCoordSysLD]'	
				EXEC sp_executesql @sql
			END

			IF object_id('tu_CoverDepthProfile') IS NULL
			BEGIN
				SET @sql = 'CREATE TRIGGER [dbo].[tu_CoverDepthProfile] ON [dbo].[CoverDepthProfile] 
							FOR UPDATE 
							AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
							UPDATE ElevationProfile
							SET 
								LastModByUserId = suser_sname()
							, LastModDateTime = getdate() 
							FROM 
								ElevationProfile as t
							, DELETED as d
							WHERE t.Id = d.Id;
							END'
				EXEC sp_executesql @sql
			END

			IF object_id('tu_CoverDepthProfile') IS NOT NULL
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[CoverDepthProfile] ENABLE TRIGGER [tu_CoverDepthProfile]'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD BeginStationSeriesId numeric(10,0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'BeginStationNum')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD BeginStationNum numeric(13, 5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD EndStationSeriesId numeric(10,0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'EndStationNum')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD EndStationNum numeric(13, 5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CoverDepthProfile' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE CoverDepthProfile
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.CoverDepthProfile
			ALTER COLUMN StationNum numeric(13, 5) NULL

			ALTER TABLE dbo.CoverDepthProfile
			ALTER COLUMN EffectiveStartDate datetime

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistBusinessDistrict' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DistBusinessDistrict
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistBusinessDistrict' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DistBusinessDistrict
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END
	
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistBusinessDistrict' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DistBusinessDistrict
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.DistBusinessDistrict
			ALTER COLUMN BeginStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistBusinessDistrict
			ALTER COLUMN EndStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistBusinessDistrict
			ALTER COLUMN EffectiveStartDate datetime

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistInsideMeter' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DistInsideMeter
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistInsideMeter' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DistInsideMeter
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistInsideMeter' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DistInsideMeter
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.DistInsideMeter
			ALTER COLUMN BeginStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistInsideMeter
			ALTER COLUMN EndStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistInsideMeter
			ALTER COLUMN EffectiveStartDate datetime

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistServiceHeadSuscept' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DistServiceHeadSuscept
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistServiceHeadSuscept' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DistServiceHeadSuscept
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DistServiceHeadSuscept' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DistServiceHeadSuscept
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.DistServiceHeadSuscept
			ALTER COLUMN BeginStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistServiceHeadSuscept
			ALTER COLUMN EndStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.DistServiceHeadSuscept
			ALTER COLUMN EffectiveStartDate datetime

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'IncidentHistory' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE IncidentHistory
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'IncidentHistory' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE IncidentHistory
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'IncidentHistory' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE IncidentHistory
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.IncidentHistory
			ALTER COLUMN BeginStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.IncidentHistory
			ALTER COLUMN EndStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.IncidentHistory
			ALTER COLUMN EffectiveStartDate datetime

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE Pressure
				ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE Pressure
				ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE Pressure
				ADD SourceId varchar(50) NULL
			END

			ALTER TABLE dbo.Pressure
			ALTER COLUMN BeginStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.Pressure
			ALTER COLUMN EndStationNum numeric(13, 5) NULL

			ALTER TABLE dbo.Pressure
			ALTER COLUMN EffectiveStartDate datetime
			
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			EXECUTE ('UPDATE CoverDepthProfile
			SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId,
			BeginStationNum = StationNum, EndStationNum = StationNum')

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- CLIENT_ADD_ILIJointMeasuredWallThickness.sql
			-- Add the new ILIJointMeasuredWallThickness field to the InlineInspection and Stg_ILI Joint tables

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'InlineInspectionJoint' and c.COLUMN_NAME = 'ILIJointMeasuredWallThickness')
			BEGIN
				ALTER TABLE InlineInspectionJoint ADD ILIJointMeasuredWallThickness NUMERIC(9,5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'Stg_ILIJoint' and c.COLUMN_NAME = 'ILIJointMeasuredWallThickness')
			BEGIN
				ALTER TABLE Stg_ILIJoint ADD ILIJointMeasuredWallThickness NUMERIC(9,5) NULL
			END
		
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- CLIENT_PMMTypeColumn.sql
			--- BL item: 30747
			IF NOT EXISTS(SELECT 1 FROM [dbo].[DomainCatalog] WHERE [DomainDescr] = 'PMM Type')
			BEGIN
				Declare @catalogId int, @domainId int;

				Select @catalogId = ISNULL(MAX(id),0) + 1 from [DomainCatalog];
				Select @domainId = ISNULL(MAX(id),0) + 1 from [ListDomain];

				INSERT INTO [DomainCatalog] ([Id], [DomainDescr])
					VALUES (@catalogId, 'PMM Type')

				INSERT INTO [dbo].[ListDomain]
					   ([Id], [DomainCatalogId], [Code], [Descr], [SourceDomainId])
				 VALUES
					   (@domainId, @catalogId, 'Monitoring', 'Monitoring', NULL)

				INSERT INTO [dbo].[ListDomain]
					   ([Id], [DomainCatalogId], [Code], [Descr], [SourceDomainId])
				 VALUES
					   (@domainId + 1, @catalogId, 'Mitigation', 'Mitigation', NULL)

				INSERT INTO [dbo].[ListDomain]
					   ([Id], [DomainCatalogId], [Code], [Descr], [SourceDomainId])
				 VALUES
					   (@domainId + 2, @catalogId, 'Prevention', 'Prevention', NULL)
			END
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 4
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Applcication Version 6.3 Release 1 Update 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630101', DBVersionComment = 'Link Service Pack DDL 6.3, Rel. 1, Updates 01'
		
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			-- Adding_CasingReading_Table.sql
			DECLARE @sql nvarchar(max)

			SET @sql = 'IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = ''CasingReading'')
						BEGIN
							CREATE TABLE CasingReading 
							(
								Id numeric(10,0) NULL,
								CasingId numeric(10,0) NULL,
								CasingReadingDate datetime NULL,
								USPipeToSoilOn numeric(5,0) NULL,
								USPipeToSoilOff numeric(5,0) NULL,
								USCasingToSoilOn numeric(5,0) NULL,
								USCasingToSoilOff numeric(5,0) NULL,
								DSPipeToSoilOn numeric(5,0) NULL,
								DSPipeToSoilOff numeric(5,0) NULL,
								DSCasingToSoilOn numeric(5,0) NULL,
								DSCasingToSoilOff numeric(5,0) NULL,
								CasingReadingComment varchar(255) NULL,
								LastModByUserId varchar(45) DEFAULT suser_sname() NULL,
								LastModDateTime datetime DEFAULT getdate() NULL,
								SourceId varchar(50) NULL,
								CreatedDate datetime DEFAULT getdate() NULL,
								CreatedUser varchar(45) DEFAULT suser_sname() NULL
						) ON [PRIMARY]
						END'

			EXEC sp_executesql @sql

			IF object_id('tu_CasingReading') IS NULL
			BEGIN

				SET @sql = 'CREATE TRIGGER [dbo].[tu_CasingReading] ON [dbo].[CasingReading] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE dbo.CasingReading
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM dbo.CasingReading as t, DELETED as d
								WHERE t.CasingId=d.CasingId AND
									  t.CasingReadingDate=d.CasingReadingDate;
							END'

				EXEC sp_executesql @sql
			END

			SET @sql = 'IF object_id(''tu_CasingReading'') IS NOT NULL
						BEGIN
							ALTER TABLE [dbo].[CasingReading] ENABLE TRIGGER [tu_CasingReading]
						END'

			EXEC sp_executesql @sql
			
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- CLIENT_ColocateTables_AddStationingColumns_BL27743.sql
			-- This scripts adds stationing columns, including respective foreign keys, to tables ColocateSite, ColocateCluster, ColocateCrack, ColocateGirthWeld, ColocateNCD


			-- Changes to ColocateSite table

			-- Add BeginStationSeriesId column to ColocateSite table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateSite' and COLUMN_NAME ='BeginStationSeriesId')
			BEGIN
				ALTER TABLE ColocateSite ADD BeginStationSeriesId NUMERIC(10,0) NULL
			END

			-- Add BeginStationNum column to ColocateSite table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateSite' and COLUMN_NAME ='BeginStationNum')
			BEGIN
				ALTER TABLE ColocateSite ADD BeginStationNum NUMERIC(13,5) NULL
			END

			-- Add EndStationSeriesId column to ColocateSite table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateSite' and COLUMN_NAME ='EndStationSeriesId')
			BEGIN
				ALTER TABLE ColocateSite ADD EndStationSeriesId NUMERIC(10,0) NULL
			END

			-- Add EndStationNum column to ColocateSite table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateSite' and COLUMN_NAME ='EndStationNum')
			BEGIN
				ALTER TABLE ColocateSite ADD EndStationNum NUMERIC(13,5) NULL
			END

			-- Changes to ColocateCluster table

			-- Add StationSeriesId column to ColocateCluster table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateCluster' and COLUMN_NAME ='StationSeriesId')
			BEGIN
				ALTER TABLE ColocateCluster ADD StationSeriesId NUMERIC(10,0) NULL
			END

			-- Add StationNum column to ColocateCluster table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateCluster' and COLUMN_NAME ='StationNum')
			BEGIN
				ALTER TABLE ColocateCluster ADD StationNum NUMERIC(13,5) NULL
			END

			-- Changes to ColocateCrack table

			-- Add StationSeriesId column to ColocateCrack table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateCrack' and COLUMN_NAME ='StationSeriesId')
			BEGIN
				ALTER TABLE ColocateCrack ADD StationSeriesId NUMERIC(10,0) NULL
			END

			-- Add StationNum column to ColocateCrack table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateCrack' and COLUMN_NAME ='StationNum')
			BEGIN
				ALTER TABLE ColocateCrack ADD StationNum NUMERIC(13,5) NULL
			END

			-- Changes to ColocateGirthWeld table

			-- Add StationSeriesId column to ColocateGirthWeld table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateGirthWeld' and COLUMN_NAME ='StationSeriesId')
			BEGIN
				ALTER TABLE ColocateGirthWeld ADD StationSeriesId NUMERIC(10,0) NULL
			END

			-- Add StationNum column to ColocateGirthWeld table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateGirthWeld' and COLUMN_NAME ='StationNum')
			BEGIN
				ALTER TABLE ColocateGirthWeld ADD StationNum NUMERIC(13,5) NULL
			END

			-- Changes to ColocateNCD table

			-- Add StationSeriesId column to ColocateNCD table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateNCD' and COLUMN_NAME ='StationSeriesId')
			BEGIN
				ALTER TABLE ColocateNCD ADD StationSeriesId NUMERIC(10,0) NULL
			END

			-- Add StationNum column to ColocateNCD table
			IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME ='ColocateNCD' and COLUMN_NAME ='StationNum')
			BEGIN
				ALTER TABLE ColocateNCD ADD StationNum NUMERIC(13,5) NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Applcication Version 6.3 Release 1 Update 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630102', DBVersionComment = 'Link Service Pack DDL 6.3, Rel. 1, Updates 02'
		
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			-- AlterTable_Valve_Stage.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Valve' And c.Column_Name = 'ValveConditionDomainID')
			BEGIN
				ALTER TABLE [dbo].[Valve] ADD ValveConditionDomainID [numeric](7,0) NULL
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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Applcication Version 6.3 Release 1 Update 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630103', DBVersionComment = 'Link Service Pack DDL 6.3, Rel. 1, Updates 03'
		
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- ScriptTracker.sql
			IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name= 'ScriptTracker')
			BEGIN
				CREATE TABLE ScriptTracker
				(Id numeric(10) IDENTITY,
				ScriptName varchar(100),
				ScriptDetails varchar(255),
				Reason varchar(255),
				ClientSpecific varchar(10), --yes, no
				ScriptedByUser varchar (45),
				ScriptCreateDate datetime,
				ScriptDeliveredDate datetime,
				Version varchar(20),
				CreatedDate datetime DEFAULT (getdate()) NOT NULL,
				CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL,
				LastModByUserId varchar(45) DEFAULT (suser_sname()) NOT NULL,
				LastModDateTime datetime DEFAULT (getdate()) NOT NULL,
					CONSTRAINT PK_ScriptTracker PRIMARY KEY CLUSTERED
				(
				Id ASC)
				);
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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @sql nvarchar(max)

			--Create trigger for the tu_ScriptTracker table
			SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE TYPE = ''TR'' AND NAME = ''tu_ScriptTracker'')
						DROP TRIGGER [dbo].[tu_ScriptTracker]'
		
			EXEC sp_executesql @sql

			SET @sql = 'CREATE TRIGGER dbo.tu_ScriptTracker ON dbo.ScriptTracker FOR UPDATE AS
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ScriptTracker
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate()
							FROM dbo.ScriptTracker as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql

			SET @sql = 'ALTER TABLE dbo.ScriptTracker ENABLE TRIGGER tu_ScriptTracker'

			EXEC sp_executesql @sql
		
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Applcication Version 6.3 Release 1 Update 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630104', DBVersionComment = 'Link Service Pack DDL 6.3, Rel. 1, Updates 04'
		
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