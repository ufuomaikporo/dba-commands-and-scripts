-- Add columns to versioninfo table to track database version and checkpoint based on transmission database
BEGIN
	DECLARE @sql NVARCHAR(MAX)

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'VersionInfo' AND column_name = 'TransDBVersion' )
	BEGIN
		EXECUTE sp_executesql N'ALTER TABLE versioninfo ADD TransDBVersion NUMERIC(8,0)';
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'VersionInfo' AND column_name = 'TransDBVersionCheckPoint' )
	BEGIN
		EXECUTE sp_executesql N'ALTER TABLE versioninfo ADD TransDBVersionCheckPoint NUMERIC(5,0)'
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'VersionInfo' AND column_name = 'TransDBVersionComment' )
	BEGIN
		EXECUTE sp_executesql N'ALTER TABLE versioninfo ADD TransDBVersionComment VARCHAR(255)';
	END

	IF EXISTS (SELECT * FROM versioninfo)
	BEGIN
		EXECUTE sp_executesql N'UPDATE versioninfo SET TransDBVersion = 620301,
					           TransDBVersionCheckPoint = 0;'
	END
	ELSE
	BEGIN
		EXECUTE sp_executesql N'INSERT INTO versioninfo (DBVersion, 
								DBVersionComment, 
								TransDBVersion,
								TransDBVersionCheckPoint) 
		VALUES (100001,
				''Upstream Service Pack DDL 1.0, Rel. 0, Updates 1'',
				620301,
				0)'
	END
END
GO
   
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
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'Pressure' AND column_name = 'PressureTypeDomainId')
			BEGIN
				ALTER TABLE [dbo].[Pressure] ADD [PressureTypeDomainId] [numeric] (10,0) NULL
			END
			
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [PressureTypeDomainId] [numeric] (10,0) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [Pressure] [numeric] (15, 4) NULL
			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [PressureComment] [varchar](255) NULL

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'Pressure' AND column_name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE [dbo].[Pressure] ADD [BeginStationSeriesId] [numeric](10, 0) NULL
			END

			ALTER TABLE [dbo].[Pressure] ALTER COLUMN [BeginStationNum] [numeric](13, 5) NULL

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'Pressure' AND column_name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE [dbo].[Pressure] ADD [EndStationSeriesId] [numeric] (10 ,0) NULL
			END

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

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE constraint_name = 'FK__Pressure__Pressu_LD')
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[Pressure] WITH CHECK 
							ADD  CONSTRAINT [FK__Pressure__Pressu_LD] FOREIGN KEY([PressureTypeDomainId])
							REFERENCES [dbo].[ListDomain] ([Id])'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Pressure] CHECK CONSTRAINT [FK__Pressure__Pressu_LD]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT *
						   FROM 
								 sys.indexes ind 
							INNER JOIN 
								 sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
							INNER JOIN 
								 sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
							INNER JOIN 
								 sys.tables t ON ind.object_id = t.object_id 
						   WHERE 
								 ind.is_primary_key = 0 
								 AND ind.is_unique = 0 
								 AND ind.is_unique_constraint = 0 
								 AND t.is_ms_shipped = 0 
								 AND t.name = 'Pressure'
								 AND col.name = 'PressureTypeDomainId')
			BEGIN
				SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressPressureTypeDomainId] ON [dbo].[Pressure]
							(
								[PressureTypeDomainId] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT *
						FROM 
								sys.indexes ind 
						INNER JOIN 
								sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
						INNER JOIN 
								sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
						INNER JOIN 
								sys.tables t ON ind.object_id = t.object_id 
						WHERE 
								ind.is_primary_key = 0 
								AND ind.is_unique = 0 
								AND ind.is_unique_constraint = 0 
								AND t.is_ms_shipped = 0 
								AND t.name = 'Pressure'
								AND col.name = 'BeginStationSeriesId')
			BEGIN
				SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressBegStationSeriesId] ON [dbo].[Pressure]
							(
								[BeginStationSeriesId] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT *
				FROM 
						sys.indexes ind 
				INNER JOIN 
						sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
				INNER JOIN 
						sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
				INNER JOIN 
						sys.tables t ON ind.object_id = t.object_id 
				WHERE 
						ind.is_primary_key = 0 
						AND ind.is_unique = 0 
						AND ind.is_unique_constraint = 0 
						AND t.is_ms_shipped = 0 
						AND t.name = 'Pressure'
						AND col.name = 'EndStationSeriesId')
			BEGIN
				SET @sql = 'CREATE NONCLUSTERED INDEX [IX_FK_PressEndStationSeriesId] ON [dbo].[Pressure]
							(
								[EndStationSeriesId] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

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
	PRINT ERROR_MESSAGE()
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