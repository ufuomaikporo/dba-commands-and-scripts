
------------------------------------------------ VERSION 620301 CHECKPOINT 0 ----------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 620301 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Pressure_AlterSchema.sql
			IF EXISTS ( SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Pressure') AND name = 'IX_FK_PressBegStationSeriesId')
			DROP INDEX [IX_FK_PressBegStationSeriesId] ON [dbo].[Pressure]
			IF EXISTS ( SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Pressure') AND name = 'IX_FK_PressEndStationSeriesId')
			DROP INDEX [IX_FK_PressEndStationSeriesId] ON [dbo].[Pressure]
			IF EXISTS ( SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Pressure') AND name = 'IX_FK_PressPressureTypeDomainI')
			DROP INDEX [IX_FK_PressPressureTypeDomainI] ON [dbo].[Pressure]

			IF EXISTS ( SELECT * 
				FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
				WHERE CONSTRAINT_NAME='FK__Pressure__Pressu_LD' )
			ALTER TABLE [dbo].[Pressure] DROP CONSTRAINT [FK__Pressure__Pressu_LD]

            --Column that do not exist in KEYERA are commented out
			--ALTER TABLE [dbo].[Pressure] ALTER COLUMN [PressureTypeDomainId] [numeric] (7,0) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [Pressure] [numeric] (15, 4) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [PressureComment] [varchar](255) NULL
			--ALTER TABLE [dbo].[Pressure] ALTER COLUMN [BeginStationSeriesId] [numeric](10, 0) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [BeginStationNum] [numeric](13, 5) NULL
			--ALTER TABLE [dbo].[Pressure] ALTER COLUMN [EndStationSeriesId] [numeric] (10 ,0) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [EndStationNum] [numeric](13, 5) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [EffectiveStartDate] [datetime] NULL

            -- sourceId column not found in Pressure table in KEYERA
			IF COL_LENGTH('dbo.Pressure', 'sourceId') IS NULL
			ALTER TABLE Pressure
			ADD SourceId [varchar] (50)

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'An error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

-------------------------------------- VERSION 620301 CHECKPOINT 1 -------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 620301 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @sql nvarchar(max)

            -- COMMENTED OUT BECAUSE Theses columns were not found in KEY_IRASV5_UPSTREAM

			-- SET @sql = 'ALTER TABLE [dbo].[Pressure] WITH CHECK 
            --             ADD  CONSTRAINT [FK__Pressure__Pressu_LD] FOREIGN KEY([PressureTypeDomainId])
			-- 			REFERENCES [dbo].[ListDomain] ([Id])'

			-- EXEC sp_executesql @sql

			-- SET @sql = 'ALTER TABLE [dbo].[Pressure] CHECK CONSTRAINT [FK__Pressure__Pressu_LD]'

			-- EXEC sp_executesql @sql

			-- SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressPressureTypeDomainI] ON [dbo].[Pressure]
			-- 			(
			-- 				[PressureTypeDomainId] ASC
			-- 			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

			-- EXEC sp_executesql @sql

			-- SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressBegStationSeriesId] ON [dbo].[Pressure]
			-- 			(
			-- 				[BeginStationSeriesId] ASC
			-- 			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

			-- EXEC sp_executesql @sql

			-- SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressEndStationSeriesId] ON [dbo].[Pressure]
			-- 			(
			-- 				[EndStationSeriesId] ASC
			-- 			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

			-- EXEC sp_executesql @sql

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 620301 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.2 Release 3 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630001', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Updates 01'

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