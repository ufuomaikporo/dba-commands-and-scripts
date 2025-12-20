INSERT INTO SystemPreferences (ParameterName,Value)
SELECT 'DatabaseType', 'Stage' WHERE NOT Exists (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType')
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- AlterSchemaDigTables_ExcavationSiteCrackAnomaly_Stage.sql
			--Script To Run On Stage Database

			-- Alter Table ExcavationSiteCrackAnomaly in Stage database

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'SourceId')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD SourceId [varchar](50)  NULL
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'EffectiveStartDate' And c.IS_NULLABLE = 'NO')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ALTER COLUMN EffectiveStartDate datetime NULL
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'ExcavationSiteId' And c.IS_NULLABLE = 'NO')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ALTER COLUMN ExcavationSiteId numeric(10,0) NULL
			END

			-- Add Begin/End StationSeriesId, StationNum and GUID columns

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD BeginStationSeriesId [numeric](10,0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'BeginStationNum')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD BeginStationNum [numeric](13,5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD EndStationSeriesId [numeric](10,0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'EndStationNum')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD EndStationNum [numeric](13,5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ExcavationSiteCrackAnomaly ADD CreatedDate [datetime] NULL
				ALTER TABLE [dbo].[ExcavationSiteCrackAnomaly] ADD  DEFAULT (getdate()) FOR [CreatedDate]
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'CreatedUser')
			BEGIN
			ALTER TABLE ExcavationSiteCrackAnomaly ADD CreatedUser [varchar](45) NULL
			ALTER TABLE [dbo].[ExcavationSiteCrackAnomaly] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
			END

			IF NOT EXISTS (SELECT * FROM sys.objects o WHERE o.object_id = object_id(N'[dbo].[FK_ExSiteCrckAno_BegSSId]') AND OBJECTPROPERTY(o.object_id, N'IsForeignKey') = 1)
			BEGIN
				ALTER TABLE [dbo].[ExcavationSiteCrackAnomaly] WITH CHECK ADD CONSTRAINT [FK_ExSiteCrckAno_BegSSId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			IF NOT EXISTS (SELECT * FROM sys.objects o WHERE o.object_id = object_id(N'[dbo].[FK_ExSiteCrckAno_EndSSId]') AND OBJECTPROPERTY(o.object_id, N'IsForeignKey') = 1)
			BEGIN
				ALTER TABLE [dbo].[ExcavationSiteCrackAnomaly] WITH CHECK ADD CONSTRAINT [FK_ExSiteCrckAno_EndSSId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ExcavationSiteCrackAnomaly ADD CreatedDate datetime
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationSiteCrackAnomaly' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE ExcavationSiteCrackAnomaly ADD CreatedUser varchar(45)
			END
			
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			UPDATE ExcavationSiteCrackAnomaly SET CreatedDate = getdate() WHERE CreatedDate IS NULL
			UPDATE ExcavationSiteCrackAnomaly SET CreatedUser = suser_sname() WHERE CreatedUser IS NULL

			ALTER TABLE ExcavationSiteCrackAnomaly ALTER COLUMN CreatedDate datetime NOT NULL
			ALTER TABLE ExcavationSiteCrackAnomaly ALTER COLUMN CreatedUser varchar(45) NOT NULL

			-- AlterTable_PipeCond_Stage.sql

			-- Alter PipeCondition table Drop Primary Key on Id Column 
			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC WHERE TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND TC.TABLE_NAME = 'PipeCondition' AND TC.TABLE_SCHEMA ='dbo')
			BEGIN
			ALTER TABLE PipeCondition DROP CONSTRAINT PK_PipeCondition
			END

			-- Alter PipeCondition table to add SourceId, ExcavationSiteGUID, CreatedDate and CreatedUser

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'PipeCondition' And c.Column_Name = 'SourceId')
			BEGIN
			ALTER TABLE PipeCondition ADD SourceId [varchar](50)  null
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'PipeCondition' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE PipeCondition ADD CreatedDate [datetime] DEFAULT (getdate()) NOT NULL
				ALTER TABLE [dbo].[PipeCondition] ADD  DEFAULT (getdate()) FOR [CreatedDate]
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'PipeCondition' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE PipeCondition ADD CreatedUser [varchar](45) DEFAULT (suser_sname()) NOT NULL
				ALTER TABLE [dbo].[PipeCondition] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- CLIENT_Fix_Excavation_Stationing35364.sql
			-- Create the missing Begin/End stationing fields for the excavation tables that have not yet been updated
			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationGirthWeld' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [EndStationNum] [numeric](13,5) NULL
			END

			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'MechanicalDamage' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].MechanicalDamage ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].MechanicalDamage ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].MechanicalDamage ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].MechanicalDamage ADD [EndStationNum] [numeric](13,5) NULL
			END

			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationSiteCrackAnomaly' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [EndStationNum] [numeric](13,5) NULL
			END

			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'PipeSoilPotentialPipe' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [EndStationNum] [numeric](13,5) NULL
			END

			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CoatingDefect' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].CoatingDefect ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].CoatingDefect ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].CoatingDefect ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].CoatingDefect ADD [EndStationNum] [numeric](13,5) NULL
			END

			-- Add the new fields
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CorrosionDeposit' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				-- Add the fields as nullable
				ALTER TABLE [dbo].CorrosionDeposit ADD [BeginStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].CorrosionDeposit ADD [BeginStationNum] [numeric](13,5) NULL
				ALTER TABLE [dbo].CorrosionDeposit ADD [EndStationSeriesId] [numeric](10,0) NULL
				ALTER TABLE [dbo].CorrosionDeposit ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationGirthWeld' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationGirthWeld' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationGirthWeld' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationGirthWeld' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationGirthWeld ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'MechanicalDamage' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].MechanicalDamage ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'MechanicalDamage' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].MechanicalDamage ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'MechanicalDamage' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].MechanicalDamage ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'MechanicalDamage' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].MechanicalDamage ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationSiteCrackAnomaly' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationSiteCrackAnomaly' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationSiteCrackAnomaly' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'ExcavationSiteCrackAnomaly' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'PipeSoilPotentialPipe' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'PipeSoilPotentialPipe' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'PipeSoilPotentialPipe' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'PipeSoilPotentialPipe' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].PipeSoilPotentialPipe ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CoatingDefect' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CoatingDefect ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CoatingDefect' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CoatingDefect ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CoatingDefect' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CoatingDefect ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CoatingDefect' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CoatingDefect ADD [EndStationNum] [numeric](13,5) NULL
			END

			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CorrosionDeposit' And c.COLUMN_NAME = 'BeginStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CorrosionDeposit ADD [BeginStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CorrosionDeposit' And c.COLUMN_NAME = 'BeginStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CorrosionDeposit ADD [BeginStationNum] [numeric](13,5) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CorrosionDeposit' And c.COLUMN_NAME = 'EndStationSeriesId') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CorrosionDeposit ADD [EndStationSeriesId] [numeric](10,0) NULL
			END
			IF (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.Columns c Where c.TABLE_NAME = 'CorrosionDeposit' And c.COLUMN_NAME = 'EndStationNum') IS NULL
			BEGIN 
				ALTER TABLE [dbo].CorrosionDeposit ADD [EndStationNum] [numeric](13,5) NULL
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_ExcavationGWBegStnSrsId]') IS NULL
			BEGIN
				--UPDATE [dbo].ExcavationGirthWeld SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].ExcavationGirthWeld  WITH NOCHECK ADD  CONSTRAINT [FK_ExcavationGWBegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].ExcavationGirthWeld  WITH NOCHECK ADD  CONSTRAINT [FK_ExcavationGWEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_MechanicalDamageBegStnSrsId]') IS NULL
			BEGIN
				UPDATE [dbo].MechanicalDamage SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].MechanicalDamage  WITH NOCHECK ADD  CONSTRAINT [FK_MechanicalDamageBegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].MechanicalDamage  WITH NOCHECK ADD  CONSTRAINT [FK_MechanicalDamageEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_ExcavationCABegStnSrsId]') IS NULL
			BEGIN
				--UPDATE [dbo].ExcavationSiteCrackAnomaly SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly  WITH NOCHECK ADD  CONSTRAINT [FK_ExcavationCABegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].ExcavationSiteCrackAnomaly  WITH NOCHECK ADD  CONSTRAINT [FK_ExcavationCAEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_PSPPipeBegStnSrsId]') IS NULL
			BEGIN
				--UPDATE [dbo].PipeSoilPotentialPipe SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].PipeSoilPotentialPipe  WITH NOCHECK ADD  CONSTRAINT [FK_PSPPipeBegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].PipeSoilPotentialPipe  WITH NOCHECK ADD  CONSTRAINT [FK_PSPPipeEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_CoatingDefectBegStnSrsId]') IS NULL
			BEGIN
				--UPDATE [dbo].CoatingDefect SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].CoatingDefect  WITH NOCHECK ADD  CONSTRAINT [FK_CoatingDefectBegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].CoatingDefect  WITH NOCHECK ADD  CONSTRAINT [FK_CoatingDefectEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			-- Set the values of the newly added fields and add the field constraints
			IF object_id('[FK_CorrosionDepositBegStnSrsId]') IS NULL
			BEGIN
				--UPDATE [dbo].CorrosionDeposit SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId, BeginStationNum = StationNum, EndStationNum = StationNum

				ALTER TABLE [dbo].CorrosionDeposit  WITH NOCHECK ADD  CONSTRAINT [FK_CorrosionDepositBegStnSrsId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
				ALTER TABLE [dbo].CorrosionDeposit  WITH NOCHECK ADD  CONSTRAINT [FK_CorrosionDepositEndStnSrsId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			-- CLIENT_Remove_Excavation_Constraints35196.sql
			-- Drop old database constraints for Excavation table
			-- NOTE only the orientation and percent have actual range checks now, the rest are simply checked that they can be saved to the database.
			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_MECHDMGORIENTATIO_MECHANIC' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGORIENTATIO_MECHANIC

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_MECHDMGLENGTH_MECHANIC' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGLENGTH_MECHANIC

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_MECHDMGWIDTH_MECHANIC' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGWIDTH_MECHANIC

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK__Mechanica__MechD__18E19391' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CK__Mechanica__MechD__18E19391

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK__Mechanica__MechD__17ED6F58' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CK__Mechanica__MechD__17ED6F58

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_MECHDMGPEAKTOPEAK_MECHANIC' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGPEAKTOPEAK_MECHANIC

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_MECHDMGWAVELENGTH_MECHANIC' and table_name = 'MechanicalDamage')
				ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGWAVELENGTH_MECHANIC


			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ESCA_ESCAS_SurfInd' and table_name = 'ExcavationSiteCrackAnomaly')
				ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CK_ESCA_ESCAS_SurfInd

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_ESCALENGTH_ESCA' and table_name = 'ExcavationSiteCrackAnomaly')
				ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CKC_ESCALENGTH_ESCA

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ESCA_ESCAWidth' and table_name = 'ExcavationSiteCrackAnomaly')
				ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CK_ESCA_ESCAWidth

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_ESCAORIENTATION_ESCA' and table_name = 'ExcavationSiteCrackAnomaly')
				ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CKC_ESCAORIENTATION_ESCA


			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_GIRTHWELDREFERENC_EXCAVATI' and table_name = 'ExcavationGirthWeld')
				ALTER TABLE ExcavationGirthWeld DROP CONSTRAINT CKC_GIRTHWELDREFERENC_EXCAVATI


			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_PIPECONDOUTSIDEDI_PIPECOND' and table_name = 'PipeCondition')
				ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDOUTSIDEDI_PIPECOND

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_PIPECONDWALLTHICK_PIPECOND' and table_name = 'PipeCondition')
				ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDWALLTHICK_PIPECOND

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_PIPECONDGRADE_PIPECOND' and table_name = 'PipeCondition')
				ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDGRADE_PIPECOND

			if exists (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CKC_PIPECONDWELDBEADH_PIPECOND' and table_name = 'PipeCondition')
				ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDWELDBEADH_PIPECOND

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN
			--ExcavationGirthWeld_Stage.sql
			-- Alter Table ExcavationGirthWeld in Stage database

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'SourceId')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD SourceId [varchar](50) NULL
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'EffectiveStartDate' And c.IS_NULLABLE = 'NO')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ALTER COLUMN EffectiveStartDate datetime NULL
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'ExcavationSiteId' And c.IS_NULLABLE = 'NO')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ALTER COLUMN ExcavationSiteId numeric(10,0) NULL
			END

			-- Add Begin/End StationSeriesId, StationNum and GUID columns

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'BeginStationSeriesId')
			--BEGIN
			--ALTER TABLE ExcavationGirthWeld ADD BeginStationSeriesId [numeric](10,0) NULL
			--END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'BeginStationNum')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD BeginStationNum [numeric](13,5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD EndStationSeriesId [numeric](10,0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'EndStationNum')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD EndStationNum [numeric](13,5) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'CreatedDate')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD CreatedDate [datetime] DEFAULT (getdate()) NOT NULL
			--ALTER TABLE [dbo].[ExcavationGirthWeld] ADD  DEFAULT (getdate()) FOR [CreatedDate]
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ExcavationGirthWeld' And c.Column_Name = 'CreatedUser')
			BEGIN
			ALTER TABLE ExcavationGirthWeld ADD CreatedUser [varchar](45) DEFAULT (suser_sname()) NOT NULL
			--ALTER TABLE [dbo].[ExcavationGirthWeld] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			--ExcavationGirthWeld_Stage.sql
			IF NOT EXISTS (SELECT * FROM sys.objects o WHERE o.object_id = object_id(N'[dbo].[FK_ExcGirthWld_BegStnSeriesId]') AND OBJECTPROPERTY(o.object_id, N'IsForeignKey') = 1)
			BEGIN
				ALTER TABLE [dbo].[ExcavationGirthWeld] WITH CHECK ADD CONSTRAINT [FK_ExcGirthWld_BegStnSeriesId] FOREIGN KEY([BeginStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			IF NOT EXISTS (SELECT * FROM sys.objects o WHERE o.object_id = object_id(N'[dbo].[FK_ExcGirthWld_EndStnSeriesId]') AND OBJECTPROPERTY(o.object_id, N'IsForeignKey') = 1)
			BEGIN
				ALTER TABLE [dbo].[ExcavationGirthWeld] WITH CHECK ADD CONSTRAINT [FK_ExcGirthWld_EndStnSeriesId] FOREIGN KEY([EndStationSeriesId]) REFERENCES [dbo].[StationSeries] ([Id])
			END

			IF NOT EXISTS (SELECT * FROM sys.objects o WHERE o.object_id = object_id(N'[dbo].[FK_ExcGirthWld_ExcvSiteId]') AND OBJECTPROPERTY(o.object_id, N'IsForeignKey') = 1)
			BEGIN
				ALTER TABLE [dbo].[ExcavationGirthWeld] WITH CHECK ADD CONSTRAINT [FK_ExcGirthWld_ExcvSiteId] FOREIGN KEY([ExcavationSiteId]) REFERENCES [dbo].[ExcavationSite] ([Id])
			END
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630223 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 7
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640001', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 01'

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


BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640001 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			-- AddLoadLITables_ILICheckSumValue_Stage.sql
			-- Create Load_ILI tables and CheckSumValue columns for the ILI tables.

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_InlineInspection')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_InlineInspection](
							[Id] [numeric](10, 0) NOT NULL,
							[MaintenanceId] [numeric](10, 0) NULL,
							[ILIName] [varchar](50) NULL,
							[ILICompanyDomainId] [numeric](7, 0) NULL,
							[ILICallBoxInteractRuleDomainId] [numeric](7, 0) NULL,
							[ILIReportReceivedDate] [datetime] NULL,
							[ILIStartDate] [datetime] NULL,
							[ILIEndDate] [datetime] NULL,
							[ILIDescr] [varchar](255) NULL,
							[ILIStatusDomainId] [numeric](7, 0) NULL,
							[ILITypeDomainId] [numeric](7, 0) NULL,
							[ILIBaselineAssessmentFlg] [numeric](1, 0) NULL,
							[ILIDummyToolFlg] [numeric](1, 0) NULL,
							[ILIBenchMarkFlg] [numeric](1, 0) NULL,
							[ILIStartDate2] [datetime] NULL,
							[ILIEndDate2] [datetime] NULL,
							[SpecVersion] [varchar](20) NULL,
							[AppVersion] [varchar](255) NULL,
							[Stg_ILIId] [numeric](10, 0) NULL,
							[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
							[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
							[MeasuredFrom] [varchar](50) NULL,
							[SystemOfMeasure] [varchar](25) NULL,
							[AlignmentType] [varchar](15) NULL,
							[DscvryDt] [datetime] NULL,
							[BaseIliId] [numeric](10, 0) NULL,
							[SourceId] [varchar](50) NOT NULL,
							[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
							[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
							[CheckSumValue] [int] NOT NULL,
						 CONSTRAINT [PK_ILISourceId] PRIMARY KEY CLUSTERED 
						(
							[SourceId] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
						) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END
			
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_ILICrackAnomaly')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_ILICrackAnomaly](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[InlineInspectionRangeId] [numeric](10, 0) NULL,
				[ILICAVendorPackageCode] [varchar](50) NULL,
				[ILICATypeDomainId] [numeric](7, 0) NULL,
				[ILICAAnomalyNumber] [varchar](15) NULL,
				[ILICAOdometer] [numeric](10, 3) NULL,
				[ILICAAnomalyDepth] [varchar](15) NULL,
				[ILICAGirthWeldNum] [varchar](25) NULL,
				[ILICADistanceFromGirthWeld] [numeric](10, 3) NULL,
				[ILICALargestIndividualInd] [numeric](10, 3) NULL,
				[ILICALength] [numeric](10, 3) NULL,
				[ILICAWidth] [numeric](10, 3) NULL,
				[ILICAOrientation] [numeric](6, 3) NULL,
				[ILICAFailPressAlgthmDomainId] [numeric](7, 0) NULL,
				[ILICAFailurePressure] [numeric](16, 4) NULL,
				[ILICARupturePressureRatio] [numeric](5, 3) NULL,
				[ILICACAOP] [numeric](5, 0) NULL,
				[ILICASurfaceInd] [varchar](2) NULL,
				[ILICADescr] [varchar](254) NULL,
				[ILICAComment] [varchar](255) NULL,
				[ILICAGrading1DomainId] [numeric](7, 0) NULL,
				[ILICAGrading2DomainId] [numeric](7, 0) NULL,
				[ILICAX] [numeric](12, 3) NULL,
				[ILICAY] [numeric](12, 3) NULL,
				[ILICAZ] [numeric](10, 3) NULL,
				[StationSeriesId] [numeric](10, 0) NULL,
				[StationNum] [numeric](13, 5) NULL,
				[ILICAFPRtc] [numeric](10, 3) NULL,
				[ILICAFPR] [numeric](10, 3) NULL,
				[ILICAGirthWeldNumDS] [varchar](25) NULL,
				[ILICADistanceFromGirthWeldDS] [numeric](10, 3) NULL,
				[ILICALatitude] [numeric](11, 9) NULL,
				[ILICALongitude] [numeric](12, 9) NULL,
				[AppVersion] [varchar](255) NULL,
				[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				[ILICAStatusDomainId] [numeric](7, 0) NULL,
				[ILICAAnomalyType] [char](1) NULL,
				[POE] [numeric](15, 14) NULL,
				[ResponseTime] [datetime] NULL,
				[RelativePosition] [varchar](10) NULL,
				[CalcLatitude] [numeric](11, 9) NULL,
				[CalcLongitude] [numeric](12, 9) NULL,
				[UpdateAudit] [varchar](255) NULL,
				[DscvryDt] [datetime] NULL,
				[UpdtDscvryDt] [datetime] NULL,
				[OperatorComment] [varchar](255) NULL,
				[DscvryDtUpdReasonDomainId] [numeric](7, 0) NULL,
				[GrowthRate] [numeric](9, 7) NULL,
				[ILICADepthDomainID] [numeric](7, 0) NULL,
				[ILICADepthPct] [numeric](8, 5) NULL,
				[SentencedResponseTime] [datetime] NULL,
				[BeginStationSeriesId] [numeric](10, 0) NULL,
				[BeginStationNum] [numeric](13, 5) NULL,
				[EndStationSeriesId] [numeric](10, 0) NULL,
				[EndStationNum] [numeric](13, 5) NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname())NOT NULL,
				[InlineInspectionId] [numeric](10, 0) NULL,
				[GrowthRateLength] [numeric](9, 7) NULL,
				[IRASCustomDate1] [datetime] NULL,
				[IRASCustomDate2] [datetime] NULL,
				[IRASCustomDate3] [datetime] NULL,
				[IRASCustomDate4] [datetime] NULL,
				[IRASCustomDate5] [datetime] NULL,
				[IRASCustomNum1] [float] NULL,
				[IRASCustomNum2] [float] NULL,
				[IRASCustomNum3] [float] NULL,
				[IRASCustomNum4] [float] NULL,
				[IRASCustomNum5] [float] NULL,
				[IRASCustomString1] [varchar](255) NULL,
				[IRASCustomString2] [varchar](255) NULL,
				[IRASCustomString3] [varchar](255) NULL,
				[IRASCustomString4] [varchar](255) NULL,
				[IRASCustomString5] [varchar](255) NULL,
				[ILICAGrowthRateDepth] [numeric](6, 4) NULL,
				[ILICAGrowthRateLength] [numeric](6, 4) NULL,
				[ILICAESF] [numeric](6, 4) NULL,
				[ILICADepthTolerance] [numeric](8, 3) NULL,
				[ILICALengthTolerance] [numeric](10, 3) NULL,
				[ILICAWidthTolerance] [numeric](10, 3) NULL,
				[ILICADepthToleranceStdDev] [numeric](8, 3) NULL,
				[ILICALengthToleranceStdDev] [numeric](10, 3) NULL,
				[ILICAWidthToleranceStdDev] [numeric](10, 3) NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [PK_ILICASourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'

			EXEC sp_executesql @sql			
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_ILICrsnCallBox')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_ILICrsnCallBox](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[InlineInspectionRangeId] [numeric](10, 0) NOT NULL,
				[InlineInspectionFeatureId] [numeric](10, 0) NULL,
				[ILICBStatusDomainId] [numeric](7, 0) NULL,
				[ILICBOdometer] [numeric](10, 3) NULL,
				[ILICBCrsnCallBoxNumber] [varchar](15) NULL,
				[ILICBDepthPct] [numeric](8, 5) NULL,
				[ILICBLength] [numeric](10, 3) NULL,
				[ILICBWidth] [numeric](10, 3) NULL,
				[ILICBOrientation] [numeric](6, 3) NULL,
				[ILICBFailPressAlgthmDomainId] [numeric](7, 0) NULL,
				[ILICBFailurePressure] [numeric](16, 4) NULL,
				[ILICBRupturePressureRatio] [numeric](7, 3) NULL,
				[ILICBManualSizedInd] [char](1) NULL,
				[ILICBSurfaceInd] [varchar](2) NULL,
				[ILICBComment] [varchar](255) NULL,
				[StationSeriesId] [numeric](10, 0) NULL,
				[StationNum] [numeric](13, 5) NULL,
				[ILICBLatitude] [numeric](11, 9) NULL,
				[ILICBLongitude] [numeric](12, 9) NULL,
				[ILICBCoordSysDomainId] [numeric](7, 0) NULL,
				[ILICBX] [numeric](12, 3) NULL,
				[ILICBY] [numeric](12, 3) NULL,
				[ILICBZ] [numeric](10, 3) NULL,
				[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				[ILICBVendorPackageCode] [varchar](10) NULL,
				[ILICBGirthWeldNumUS] [varchar](25) NULL,
				[ILICBDistanceFromGirthWeldUS] [numeric](10, 3) NULL,
				[ILICBGirthWeldNumDS] [varchar](25) NULL,
				[ILICBDistanceFromGirthWeldDS] [numeric](10, 3) NULL,
				[ILICBFPR] [numeric](5, 3) NULL,
				[ILICBFPRtc] [numeric](5, 3) NULL,
				[MetalLossType] [varchar](50) NULL,
				[CalcLatitude] [numeric](11, 9) NULL,
				[CalcLongitude] [numeric](12, 9) NULL,
				[UpdateAudit] [varchar](255) NULL,
				[DscvryDt] [datetime] NULL,
				[UpdtDscvryDt] [datetime] NULL,
				[OperatorComment] [varchar](255) NULL,
				[DscvryDtUpdReasonDomainId] [numeric](7, 0) NULL,
				[GrowthRate] [numeric](9, 7) NULL,
				[BeginStationSeriesId] [numeric](10, 0) NULL,
				[BeginStationNum] [numeric](13, 5) NULL,
				[EndStationSeriesId] [numeric](10, 0) NULL,
				[EndStationNum] [numeric](13, 5) NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[InlineInspectionId] [numeric](10, 0) NULL,
				[IRASCustomDate1] [datetime] NULL,
				[IRASCustomDate2] [datetime] NULL,
				[IRASCustomDate3] [datetime] NULL,
				[IRASCustomDate4] [datetime] NULL,
				[IRASCustomDate5] [datetime] NULL,
				[IRASCustomNum1] [float] NULL,
				[IRASCustomNum2] [float] NULL,
				[IRASCustomNum3] [float] NULL,
				[IRASCustomNum4] [float] NULL,
				[IRASCustomNum5] [float] NULL,
				[IRASCustomString1] [varchar](255) NULL,
				[IRASCustomString2] [varchar](255) NULL,
				[IRASCustomString3] [varchar](255) NULL,
				[IRASCustomString4] [varchar](255) NULL,
				[IRASCustomString5] [varchar](255) NULL,
				[ILICBERF] [numeric](6, 4) NULL,
				[ILICBDepthTolerance] [numeric](8, 3) NULL,
				[ILICBLengthTolerance] [numeric](10, 3) NULL,
				[ILICBWidthTolerance] [numeric](10, 3) NULL,
				[ILICBDepthToleranceStdDev] [numeric](8, 3) NULL,
				[ILICBLengthToleranceStdDev] [numeric](10, 3) NULL,
				[ILICBWidthToleranceStdDev] [numeric](10, 3) NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [PK_ILICBSourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'
				
				EXEC sp_executesql @sql
			
			END
	
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_InlineInspectionFacility')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_InlineInspectionFacility](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[InlineInspectionRangeId] [numeric](10, 0) NOT NULL,
				[ILIFacTypeDomainId] [numeric](7, 0) NULL,
				[ILIFacStatusDomainId] [numeric](7, 0) NULL,
				[ILIFacOdometer] [numeric](10, 3) NULL,
				[ILIFacGirthWeldNum] [varchar](25) NULL,
				[ILIFacDistanceFromGirthWeld] [numeric](10, 3) NULL,
				[ILIFacOrientation] [numeric](6, 3) NULL,
				[ILIFacDescr] [varchar](255) NULL,
				[StationSeriesId] [numeric](10, 0) NULL,
				[StationNum] [numeric](13, 5) NULL,
				[ILIFacNumber] [varchar](30) NULL,
				[ILIFacLatitude] [numeric](11, 9) NULL,
				[ILIFacLongitude] [numeric](12, 9) NULL,
				[ILIFacCoordSysDomainId] [numeric](7, 0) NULL,
				[ILIFacX] [numeric](12, 3) NULL,
				[ILIFacY] [numeric](12, 3) NULL,
				[ILIFacZ] [numeric](10, 3) NULL,
				[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				[ILIFToolSpeed] [numeric](7, 3) NULL,
				[CalcLatitude] [numeric](11, 9) NULL,
				[CalcLongitude] [numeric](12, 9) NULL,
				[OperatorComment] [varchar](255) NULL,
				[BeginStationSeriesId] [numeric](10, 0) NULL,
				[BeginStationNum] [numeric](13, 5) NULL,
				[EndStationSeriesId] [numeric](10, 0) NULL,
				[EndStationNum] [numeric](13, 5) NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[InlineInspectionId] [numeric](10, 0) NULL,
				[IRASCustomDate1] [datetime] NULL,
				[IRASCustomDate2] [datetime] NULL,
				[IRASCustomDate3] [datetime] NULL,
				[IRASCustomDate4] [datetime] NULL,
				[IRASCustomDate5] [datetime] NULL,
				[IRASCustomNum1] [float] NULL,
				[IRASCustomNum2] [float] NULL,
				[IRASCustomNum3] [float] NULL,
				[IRASCustomNum4] [float] NULL,
				[IRASCustomNum5] [float] NULL,
				[IRASCustomString1] [varchar](255) NULL,
				[IRASCustomString2] [varchar](255) NULL,
				[IRASCustomString3] [varchar](255) NULL,
				[IRASCustomString4] [varchar](255) NULL,
				[IRASCustomString5] [varchar](255) NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [PK_ILIFacSourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_InlineInspectionFeature')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_InlineInspectionFeature](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[InlineInspectionRangeId] [numeric](10, 0) NOT NULL,
				[ILIFTypeDomainId] [numeric](7, 0) NULL,
				[ILIFStatusDomainId] [numeric](7, 0) NULL,
				[ILIFOdometer] [numeric](10, 3) NULL,
				[ILIFFeatureNumber] [varchar](15) NULL,
				[ILIFPeakDepthPct] [numeric](8, 5) NULL,
				[ILIFGirthWeldNum] [varchar](25) NULL,
				[ILIFDistanceFromGirthWeld] [numeric](10, 3) NULL,
				[ILIFLength] [numeric](10, 3) NULL,
				[ILIFWidth] [numeric](10, 3) NULL,
				[ILIFLAPALength] [numeric](10, 3) NULL,
				[ILIFLAPADepthPct] [numeric](8, 5) NULL,
				[ILIFOrientation] [numeric](6, 3) NULL,
				[ILIFFailPressAlgthmDomainId] [numeric](7, 0) NULL,
				[ILIFFailurePressure] [numeric](16, 4) NULL,
				[ILIFRupturePressureRatio] [numeric](5, 3) NULL,
				[ILIFCAOP] [numeric](5, 0) NULL,
				[ILIFSurfaceInd] [varchar](2) NULL,
				[ILIFComment] [varchar](255) NULL,
				[ILIFGrading1DomainId] [numeric](7, 0) NULL,
				[ILIFGrading2DomainId] [numeric](7, 0) NULL,
				[ILIFResponseTime] [datetime] NULL,
				[ILIFFPRtc] [numeric](10, 3) NULL,
				[ILIFPOERupture] [numeric](20, 18) NULL,
				[ILIFPOELeak] [numeric](20, 18) NULL,
				[ILIFFPR] [numeric](10, 3) NULL,
				[AppVersion] [varchar](255) NULL,
				[ILIFVendorPackageCode] [varchar](10) NULL,
				[ILIFBoxCount] [numeric](4, 0) NULL,
				[ILIFGirthWeldNumDS] [varchar](25) NULL,
				[ILIFDistanceFromGirthWeldDS] [numeric](10, 3) NULL,
				[ILIFERF] [numeric](10, 3) NULL,
				[CFRGrading1DomainID] [numeric](7, 0) NULL,
				[CFRGrading2DomainID] [numeric](7, 0) NULL,
				[ILIFLatitude] [numeric](11, 9) NULL,
				[ILIFLongitude] [numeric](12, 9) NULL,
				[ILIFCoordSysDomainId] [numeric](7, 0) NULL,
				[ILIFX] [numeric](12, 3) NULL,
				[ILIFY] [numeric](12, 3) NULL,
				[ILIFZ] [numeric](10, 3) NULL,
				[StationSeriesId] [numeric](10, 0) NULL,
				[StationNum] [numeric](13, 5) NULL,
				[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				[MetalLossType] [varchar](50) NULL,
				[CalcLatitude] [numeric](11, 9) NULL,
				[CalcLongitude] [numeric](12, 9) NULL,
				[FprB31G] [numeric](10, 3) NULL,
				[FprTcB31G] [numeric](10, 3) NULL,
				[FprModB31G] [numeric](10, 3) NULL,
				[FprTcModB31G] [numeric](10, 3) NULL,
				[FprSentencing] [numeric](10, 3) NULL,
				[UpdateAudit] [varchar](255) NULL,
				[DscvryDt] [datetime] NULL,
				[UpdtDscvryDt] [datetime] NULL,
				[OperatorComment] [varchar](255) NULL,
				[DscvryDtUpdReasonDomainId] [numeric](7, 0) NULL,
				[GrowthRate] [numeric](9, 7) NULL,
				[GrowthRateStdDev] [numeric](9, 7) NULL,
				[SentencedResponseTime] [datetime] NULL,
				[BeginStationSeriesId] [numeric](10, 0) NULL,
				[BeginStationNum] [numeric](13, 5) NULL,
				[EndStationSeriesId] [numeric](10, 0) NULL,
				[EndStationNum] [numeric](13, 5) NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[InlineInspectionId] [numeric](10, 0) NULL,
				[IRASCustomDate1] [datetime] NULL,
				[IRASCustomDate2] [datetime] NULL,
				[IRASCustomDate3] [datetime] NULL,
				[IRASCustomDate4] [datetime] NULL,
				[IRASCustomDate5] [datetime] NULL,
				[IRASCustomNum1] [float] NULL,
				[IRASCustomNum2] [float] NULL,
				[IRASCustomNum3] [float] NULL,
				[IRASCustomNum4] [float] NULL,
				[IRASCustomNum5] [float] NULL,
				[IRASCustomString1] [varchar](255) NULL,
				[IRASCustomString2] [varchar](255) NULL,
				[IRASCustomString3] [varchar](255) NULL,
				[IRASCustomString4] [varchar](255) NULL,
				[IRASCustomString5] [varchar](255) NULL,
				[ILIFDepthTolerance] [numeric](8, 3) NULL,
				[ILIFLengthTolerance] [numeric](10, 3) NULL,
				[ILIFWidthTolerance] [numeric](10, 3) NULL,
				[ILIFDepthToleranceStdDev] [numeric](8, 3) NULL,
				[ILIFLengthToleranceStdDev] [numeric](10, 3) NULL,
				[ILIFWidthToleranceStdDev] [numeric](10, 3) NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [PK_ILIFSourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'

				EXEC sp_executesql @sql
			
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_InlineInspectionJoint')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_InlineInspectionJoint](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[InlineInspectionRangeId] [numeric](10, 0) NOT NULL,
				[ILIJointGirthWeldNum] [varchar](25) NULL,
				[ILIJointGirthWeldOdometer] [numeric](10, 3) NULL,
				[ILIJointSpoolLength] [numeric](10, 3) NULL,
				[ILIJointDiameter] [numeric](9, 5) NULL,
				[ILIJointWallThickness] [numeric](9, 5) NULL,
				[ILIJointGrade] [numeric](10, 5) NULL,
				[ILIJointSeamOrientation] [numeric](6, 3) NULL,
				[ILIJointSpiralAngle] [numeric](3, 0) NULL,
				[ILIJointComment] [varchar](255) NULL,
				[StationSeriesId] [numeric](10, 0) NULL,
				[StationNum] [numeric](13, 5) NULL,
				[ILIJointLatitude] [numeric](11, 9) NULL,
				[ILIJointLongitude] [numeric](12, 9) NULL,
				[ILIJointCoordSysDomainId] [numeric](7, 0) NULL,
				[ILIJointX] [numeric](12, 3) NULL,
				[ILIJointY] [numeric](12, 3) NULL,
				[ILIJointZ] [numeric](10, 3) NULL,
				[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				[ILIJointGirthWeldNumPrevious] [varchar](25) NULL,
				[CalcLatitude] [numeric](11, 9) NULL,
				[CalcLongitude] [numeric](12, 9) NULL,
				[UpdateAudit] [varchar](255) NULL,
				[MOP] [numeric](9, 4) NULL,
				[DPP] [numeric](9, 4) NULL,
				[DPPUpdateDate] [datetime] NULL,
				[DPPUpdateReason] [varchar](255) NULL,
				[OperatorComment] [varchar](255) NULL,
				[SeamType] [char](1) NULL,
				[BeginStationSeriesId] [numeric](10, 0) NULL,
				[BeginStationNum] [numeric](13, 5) NULL,
				[EndStationSeriesId] [numeric](10, 0) NULL,
				[EndStationNum] [numeric](13, 5) NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[InlineInspectionId] [numeric](10, 0) NULL,
				[IRASCustomDate1] [datetime] NULL,
				[IRASCustomDate2] [datetime] NULL,
				[IRASCustomDate3] [datetime] NULL,
				[IRASCustomDate4] [datetime] NULL,
				[IRASCustomDate5] [datetime] NULL,
				[IRASCustomNum1] [float] NULL,
				[IRASCustomNum2] [float] NULL,
				[IRASCustomNum3] [float] NULL,
				[IRASCustomNum4] [float] NULL,
				[IRASCustomNum5] [float] NULL,
				[IRASCustomString1] [varchar](255) NULL,
				[IRASCustomString2] [varchar](255) NULL,
				[IRASCustomString3] [varchar](255) NULL,
				[IRASCustomString4] [varchar](255) NULL,
				[IRASCustomString5] [varchar](255) NULL,
				[ILIJToolSpeed] [numeric](8, 4) NULL,
				[ILIJDetectableLength] [numeric](8, 4) NULL,
				[ILIJointMeasuredWallThickness] [numeric](9, 5) NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [PK_ILIJSourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]'

				EXEC sp_executesql @sql
			
		END

		IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_ILINonCrsnDfct')
		BEGIN
			SET @sql = 'CREATE TABLE [dbo].[Load_ILINonCrsnDfct](
			[Id] [numeric](10, 0) NOT NULL,
			[EffectiveStartDate] [datetime] NULL,
			[EffectiveEndDate] [datetime] NULL,
			[InlineInspectionRangeId] [numeric](10, 0) NOT NULL,
			[ILINCDTypeDomainId] [numeric](7, 0) NULL,
			[ILINCDStatusDomainId] [numeric](7, 0) NULL,
			[ILINCDOdometer] [numeric](10, 3) NULL,
			[ILINCDFeatureNumber] [varchar](15) NULL,
			[ILINCDLength] [numeric](10, 3) NULL,
			[ILINCDWidth] [numeric](10, 3) NULL,
			[ILINCDOrientation] [numeric](6, 3) NULL,
			[ILINCDDepthPct] [numeric](8, 5) NULL,
			[ILINCDDepthPctNPS] [numeric](8, 5) NULL,
			[ILINCDGirthWeldNum] [varchar](25) NULL,
			[ILINCDDistanceFromGirthWeld] [numeric](10, 3) NULL,
			[ILINCDComment] [varchar](255) NULL,
			[ILINCDGrading1DomainId] [numeric](7, 0) NULL,
			[ILINCDGrading2DomainId] [numeric](7, 0) NULL,
			[ILINCDResponseTime] [datetime] NULL,
			[ILINCDStrain] [numeric](4, 4) NULL,
			[ILINCDVendorPackageCode] [varchar](10) NULL,
			[ILINCDGirthWeldNumDS] [varchar](25) NULL,
			[ILINCDDistanceFromGirthWeldDS] [numeric](10, 3) NULL,
			[ILINCDSurfaceInd] [varchar](2) NULL,
			[CFRGrading1DomainID] [numeric](7, 0) NULL,
			[CFRGrading2DomainID] [numeric](7, 0) NULL,
			[ILINCDLatitude] [numeric](11, 9) NULL,
			[ILINCDLongitude] [numeric](12, 9) NULL,
			[ILINCDCoordSysDomainId] [numeric](7, 0) NULL,
			[ILINCDX] [numeric](12, 3) NULL,
			[ILINCDY] [numeric](12, 3) NULL,
			[ILINCDZ] [numeric](10, 3) NULL,
			[StationSeriesId] [numeric](10, 0) NULL,
			[StationNum] [numeric](13, 5) NULL,
			[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			[CalcLatitude] [numeric](11, 9) NULL,
			[CalcLongitude] [numeric](12, 9) NULL,
			[UpdateAudit] [varchar](255) NULL,
			[DscvryDt] [datetime] NULL,
			[UpdtDscvryDt] [datetime] NULL,
			[OperatorComment] [varchar](255) NULL,
			[DscvryDtUpdReasonDomainId] [numeric](7, 0) NULL,
			[SentencedResponseTime] [datetime] NULL,
			[BeginStationSeriesId] [numeric](10, 0) NULL,
			[BeginStationNum] [numeric](13, 5) NULL,
			[EndStationSeriesId] [numeric](10, 0) NULL,
			[EndStationNum] [numeric](13, 5) NULL,
			[SourceId] [varchar](50) NOT NULL,
			[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
			[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[InlineInspectionId] [numeric](10, 0) NULL,
			[IRASCustomDate1] [datetime] NULL,
			[IRASCustomDate2] [datetime] NULL,
			[IRASCustomDate3] [datetime] NULL,
			[IRASCustomDate4] [datetime] NULL,
			[IRASCustomDate5] [datetime] NULL,
			[IRASCustomNum1] [float] NULL,
			[IRASCustomNum2] [float] NULL,
			[IRASCustomNum3] [float] NULL,
			[IRASCustomNum4] [float] NULL,
			[IRASCustomNum5] [float] NULL,
			[IRASCustomString1] [varchar](255) NULL,
			[IRASCustomString2] [varchar](255) NULL,
			[IRASCustomString3] [varchar](255) NULL,
			[IRASCustomString4] [varchar](255) NULL,
			[IRASCustomString5] [varchar](255) NULL,
			[ILINCDHardness] [numeric](8, 4) NULL,
			[ILINCDDepthTolerance] [numeric](8, 3) NULL,
			[ILINCDLengthTolerance] [numeric](10, 3) NULL,
			[ILINCDWidthTolerance] [numeric](10, 3) NULL,
			[ILINCDDepthToleranceStdDev] [numeric](8, 3) NULL,
			[ILINCDLengthToleranceStdDev] [numeric](10, 3) NULL,
			[ILINCDWidthToleranceStdDev] [numeric](10, 3) NULL,
			[CheckSumValue] [int] NOT NULL,
		 CONSTRAINT [PK_ILINCDSourceId] PRIMARY KEY CLUSTERED 
		(
			[SourceId] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]'

			EXEC sp_executesql @sql

		END

		IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_InlineInspectionRange')
		BEGIN
			SET @sql = 'CREATE TABLE [dbo].[Load_InlineInspectionRange](
			[Id] [numeric](10, 0) NOT NULL,
			[EffectiveStartDate] [datetime] NULL,
			[EffectiveEndDate] [datetime] NULL,
			[InlineInspectionId] [numeric](10, 0) NOT NULL,
			[ILIRToolDomainId] [numeric](7, 0) NULL,
			[ILIRStatusDomainId] [numeric](7, 0) NULL,
			[ILIRFailPressAlgthmDomainId] [numeric](7, 0) NULL,
			[ILIRDescr] [varchar](255) NULL,
			[ILIRStartOdometer] [numeric](10, 3) NULL,
			[ILIREndOdometer] [numeric](10, 3) NULL,
			[ILIRStartDate] [datetime] NULL,
			[ILIREndDate] [datetime] NULL,
			[BeginStationSeriesId] [numeric](10, 0) NULL,
			[BeginStationNum] [numeric](13, 5) NULL,
			[EndStationSeriesId] [numeric](10, 0) NULL,
			[EndStationNum] [numeric](13, 5) NULL,
			[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			[ILIStartDate2] [datetime] NULL,
			[ILIEndDate2] [datetime] NULL,
			[ILIRStartDate2] [datetime] NULL,
			[ILIREndDate2] [datetime] NULL,
			[ILIReportDate] [datetime] NULL,
			[ILIRCoordProj] [varchar](50) NULL,
			[ILIRCoordDatum] [varchar](25) NULL,
			[ILIRHeightDatum] [varchar](50) NULL,
			[UndercallFactorDepthPct] [numeric](7, 3) NULL,
			[ILIRStatusUpdateDate] [datetime] NULL,
			[ILIRStatusUpdateUserId] [varchar](45) NULL,
			[ILIRStatusUpdateComment] [varchar](255) NULL,
			[ILIRToolMean] [numeric](8, 7) NULL,
			[ILIRToolStdDeviation] [numeric](8, 7) NULL,
			[SourceId] [varchar](50) NOT NULL,
			[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
			[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
			[CheckSumValue] [int] NOT NULL,
		 CONSTRAINT [PK_ILIRSourceId] PRIMARY KEY CLUSTERED 
		(
			[SourceId] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]'
			
			EXEC sp_executesql @sql
		
		END
	
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspection' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTION ADD [CheckSumValue] [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionRange' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONRANGE ADD [CheckSumValue] [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionFacility' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONFACILITY ADD [CheckSumValue] [int] NULL
			END 

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionFeature' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONFEATURE ADD [CheckSumValue] [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionNonCrsnDfct' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONNONCRSNDFCT ADD [CheckSumValue] [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionJoint' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONJOINT ADD [CheckSumValue] [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'InlineInspectionCrackAnomaly' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE INLINEINSPECTIONCRACKANOMALY ADD [CheckSumValue] [int] NULL
			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640001 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			--COMMENTED OUT - BeginStationSeriesId and EndStationSeriesId columns not found in pressure table
			-- IDM_FixPressureTable.sql
			---- Resolve IDM not allowing or saving stationing for the Pressure table. 

			-- -- Alter Stationing Columns to NOT Allow NULLS
			-- ALTER TABLE dbo.Pressure NOCHECK CONSTRAINT FK_Pressure_BeginStnSrs
			-- ALTER TABLE dbo.Pressure NOCHECK CONSTRAINT FK_Pressure_EndStnSrs

			-- DROP INDEX IX_FK_PressBegStationSeriesId ON dbo.Pressure
			-- DROP INDEX IX_FK_PressEndStationSeriesId ON dbo.Pressure

			-- ALTER TABLE dbo.Pressure ALTER COLUMN BeginStationSeriesId NUMERIC(10, 0) NOT NULL
			ALTER TABLE dbo.Pressure ALTER COLUMN BeginStationNum NUMERIC(13, 5) NOT NULL
			-- ALTER TABLE dbo.Pressure ALTER COLUMN EndStationSeriesId NUMERIC(10, 0) NOT NULL
			ALTER TABLE dbo.Pressure ALTER COLUMN EndStationNum NUMERIC(13, 5) NOT NULL

			-- -- Reenable Constraints and Create Dropped Index
			-- ALTER TABLE dbo.Pressure CHECK CONSTRAINT FK_Pressure_BeginStnSrs
			-- ALTER TABLE dbo.Pressure CHECK CONSTRAINT FK_Pressure_EndStnSrs

			-- CREATE INDEX IX_FK_PressBegStationSeriesId ON dbo.Pressure(BeginStationSeriesId)
			-- CREATE INDEX IX_FK_PressEndStationSeriesId ON dbo.Pressure(EndStationSeriesId)

			-- Fix Issues with SEUSA IDM to not allow gaps or overlaps on the Pressure table
			--UPDATE dbo.DataManagerTable SET TableAllowGapsFlg = 0, TableAllowOverlapsFlg = 0 WHERE TableName = 'Pressure'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640001 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640002', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 02'

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


BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @dropSql nvarchar(max)
			DECLARE @addSql nvarchar(max)
			DECLARE @sql nvarchar(max)

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'tmpListDomainForeignKeys')
			BEGIN
				set @sql = 'DROP TABLE tmpListDomainForeignKeys'
				EXEC sp_executesql @sql
			END

			SELECT 'ALTER TABLE ' + tmp.TableName + ' ADD CONSTRAINT ' + tmp.FK_NAME + ' FOREIGN KEY (' + tmp.ColumnName + ') REFERENCES ' + tmp.ReferencedTable + '(' + tmp.ReferencedColumn + ')'  AS AddForeignKeyScript
			INTO tmpListDomainForeignKeys
			FROM (
			SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
			INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
			INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
			INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
			INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
			INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
			) tmp
			WHERE tmp.ReferencedTable = 'ListDomain' AND tmp.ReferencedColumn = 'Id'

			DECLARE d_cursor CURSOR FOR
				SELECT 'Alter table ' + TableName + ' Drop Constraint ' + tmp.FK_NAME AS DropConstraintsScript FROM (
				SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
				FROM sys.foreign_key_columns fkc
				INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
				INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
				INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
				INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
				INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
				INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
				) tmp
				WHERE tmp.ReferencedTable = 'ListDomain' AND tmp.ReferencedColumn = 'Id'

			OPEN d_cursor
				FETCH NEXT FROM d_cursor INTO @dropSql

				WHILE @@FETCH_STATUS = 0
				BEGIN

					EXEC sp_executesql @dropSql

					FETCH NEXT FROM d_cursor INTO @dropSql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ListDomain' And COLUMNPROPERTY(object_id(TABLE_SCHEMA+'.'+TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1)
			BEGIN
				SET @sql = 'IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = ''tmpListDomain_Identity'')
								BEGIN
									SELECT * INTO tmpListDomain_Identity FROM dbo.ListDomain ld
								END'
	
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE ListDomain DROP CONSTRAINT PK_ListDomain'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE ListDomain DROP COLUMN Id'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE ListDomain ADD Id Numeric(10,0) IDENTITY(1,1) NOT NULL'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE ListDomain ADD CONSTRAINT PK_ListDomain PRIMARY KEY (Id)'
				EXEC sp_executesql @sql

				SET @sql = 'DELETE FROM ListDomain'
				EXEC sp_executesql @sql

				SET @sql = 'SET IDENTITY_INSERT ListDomain ON 
							INSERT INTO dbo.ListDomain (Id,DomainCatalogId,Code,Descr,SourceDomainId,LastModByUserId,LastModDateTime) 
							SELECT Id,DomainCatalogId,Code,Descr,SourceDomainId,LastModByUserId,LastModDateTime FROM tmpListDomain_Identity
							SET IDENTITY_INSERT ListDomain OFF'
				EXEC sp_executesql @sql

			END


			DECLARE f_cursor CURSOR FOR
				SELECT AddForeignKeyScript FROM tmpListDomainForeignKeys

			OPEN f_cursor
				FETCH NEXT FROM f_cursor INTO @addSql

				WHILE @@FETCH_STATUS = 0
				BEGIN

					EXEC sp_executesql @addSql

					FETCH NEXT FROM f_cursor INTO @addSql
				END

			CLOSE f_cursor
			DEALLOCATE f_cursor

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'tmpListDomainForeignKeys')
			BEGIN
				set @sql = 'DROP TABLE tmpListDomainForeignKeys'
				EXEC sp_executesql @sql
			END

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640003', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 03'

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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640003 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'SimCalcFeatureLeak')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[SimCalcFeatureLeak](
					[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
					[InlineInspectionID] [numeric](10, 0) NOT NULL,
					[InlineInspectionRangeID] [numeric](10, 0) NOT NULL,
					[ILIFeatureID] [numeric](10, 0) NOT NULL,
					[SimulationYear] [numeric](4, 0) NOT NULL,
					[LastCalcYear] [numeric](4, 0) NOT NULL,
					[NumberOfIterations] [numeric](10, 0) NOT NULL,
					[yr0] [numeric](20, 18) NOT NULL,
					[yr1] [numeric](20, 18) NOT NULL,
					[yr2] [numeric](20, 18) NOT NULL,
					[yr3] [numeric](20, 18) NOT NULL,
					[yr4] [numeric](20, 18) NOT NULL,
					[yr5] [numeric](20, 18) NOT NULL,
					[yr6] [numeric](20, 18) NOT NULL,
					[yr7] [numeric](20, 18) NOT NULL,
					[yr8] [numeric](20, 18) NOT NULL,
					[yr9] [numeric](20, 18) NOT NULL,
					[yr10] [numeric](20, 18) NOT NULL,
					[yr11] [numeric](20, 18) NOT NULL,
					[yr12] [numeric](20, 18) NOT NULL,
					[yr13] [numeric](20, 18) NOT NULL,
					[yr14] [numeric](20, 18) NOT NULL,
					[yr15] [numeric](20, 18) NOT NULL,
					[yr16] [numeric](20, 18) NOT NULL,
					[yr17] [numeric](20, 18) NOT NULL,
					[yr18] [numeric](20, 18) NOT NULL,
					[yr19] [numeric](20, 18) NOT NULL,
					[CalculationDate] [datetime] NULL,
					[CreatedDate] [datetime] DEFAULT (getdate()) NULL,
					[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NULL,
					[LastModByUserID] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				 CONSTRAINT [PK_SimCalcFeatureLeak] PRIMARY KEY CLUSTERED 
				(
					[ID] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				)'

				EXEC sp_executesql @sql
			END

			IF object_id('tu_SimCalcFeatureLeak') IS NULL
			BEGIN
				SET @sql = 'CREATE TRIGGER [dbo].[tu_SimCalcFeatureLeak] ON [dbo].[SimCalcFeatureLeak] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE dbo.SimCalcFeatureLeak
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM dbo.SimCalcFeatureLeak as t, DELETED as d
								WHERE t.Id=d.Id;
							END'

				EXEC sp_executesql @sql
			END

			IF object_id('tu_SimCalcFeatureLeak') IS NOT NULL
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[SimCalcFeatureLeak] ENABLE TRIGGER [tu_SimCalcFeatureLeak]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'SimCalcFeatureTotal')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[SimCalcFeatureTotal](
					[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
					[InlineInspectionID] [numeric](10, 0) NOT NULL,
					[InlineInspectionRangeID] [numeric](10, 0) NOT NULL,
					[ILIFeatureID] [numeric](10, 0) NOT NULL,
					[SimulationYear] [numeric](4, 0) NOT NULL,
					[LastCalcYear] [numeric](4, 0) NOT NULL,
					[NumberOfIterations] [numeric](10, 0) NOT NULL,
					[yr0] [numeric](20, 18) NOT NULL,
					[yr1] [numeric](20, 18) NOT NULL,
					[yr2] [numeric](20, 18) NOT NULL,
					[yr3] [numeric](20, 18) NOT NULL,
					[yr4] [numeric](20, 18) NOT NULL,
					[yr5] [numeric](20, 18) NOT NULL,
					[yr6] [numeric](20, 18) NOT NULL,
					[yr7] [numeric](20, 18) NOT NULL,
					[yr8] [numeric](20, 18) NOT NULL,
					[yr9] [numeric](20, 18) NOT NULL,
					[yr10] [numeric](20, 18) NOT NULL,
					[yr11] [numeric](20, 18) NOT NULL,
					[yr12] [numeric](20, 18) NOT NULL,
					[yr13] [numeric](20, 18) NOT NULL,
					[yr14] [numeric](20, 18) NOT NULL,
					[yr15] [numeric](20, 18) NOT NULL,
					[yr16] [numeric](20, 18) NOT NULL,
					[yr17] [numeric](20, 18) NOT NULL,
					[yr18] [numeric](20, 18) NOT NULL,
					[yr19] [numeric](20, 18) NOT NULL,
					[CalculationDate] [datetime] NULL,
					[CreatedDate] [datetime] DEFAULT (getdate()) NULL,
					[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NULL,
					[LastModByUserID] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
				 CONSTRAINT [PK_SimCalcFeatureTotal] PRIMARY KEY CLUSTERED 
				(
					[ID] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				)'

				EXEC sp_executesql @sql
			END

			IF object_id('tu_SimCalcFeatureTotal') IS NULL
			BEGIN
				SET @sql = 'CREATE TRIGGER [dbo].[tu_SimCalcFeatureTotal] ON [dbo].[SimCalcFeatureTotal] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE dbo.SimCalcFeatureTotal
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM dbo.SimCalcFeatureTotal as t, DELETED as d
								WHERE t.Id=d.Id;
							END'

				EXEC sp_executesql @sql
			END

			IF object_id('tu_SimCalcFeatureTotal') IS NOT NULL
			BEGIN
				SET @sql = 'ALTER TABLE [dbo].[SimCalcFeatureTotal] ENABLE TRIGGER [tu_SimCalcFeatureTotal]'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'SimCalcFeatureRupture')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[SimCalcFeatureRupture](
				[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
				[InlineInspectionID] [numeric](10, 0) NOT NULL,
				[InlineInspectionRangeID] [numeric](10, 0) NOT NULL,
				[ILIFeatureID] [numeric](10, 0) NOT NULL,
				[SimulationYear] [numeric](4, 0) NOT NULL,
				[LastCalcYear] [numeric](4, 0) NOT NULL,
				[NumberOfIterations] [numeric](10, 0) NOT NULL,
				[yr0] [numeric](20, 18) NOT NULL,
				[yr1] [numeric](20, 18) NOT NULL,
				[yr2] [numeric](20, 18) NOT NULL,
				[yr3] [numeric](20, 18) NOT NULL,
				[yr4] [numeric](20, 18) NOT NULL,
				[yr5] [numeric](20, 18) NOT NULL,
				[yr6] [numeric](20, 18) NOT NULL,
				[yr7] [numeric](20, 18) NOT NULL,
				[yr8] [numeric](20, 18) NOT NULL,
				[yr9] [numeric](20, 18) NOT NULL,
				[yr10] [numeric](20, 18) NOT NULL,
				[yr11] [numeric](20, 18) NOT NULL,
				[yr12] [numeric](20, 18) NOT NULL,
				[yr13] [numeric](20, 18) NOT NULL,
				[yr14] [numeric](20, 18) NOT NULL,
				[yr15] [numeric](20, 18) NOT NULL,
				[yr16] [numeric](20, 18) NOT NULL,
				[yr17] [numeric](20, 18) NOT NULL,
				[yr18] [numeric](20, 18) NOT NULL,
				[yr19] [numeric](20, 18) NOT NULL,
				[CalculationDate] [datetime] NULL,
				[CreatedDate] [datetime] DEFAULT (getdate()) NULL,
				[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NULL,
				[LastModByUserID] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
			 CONSTRAINT [PK_SimCalcFeatureRupture] PRIMARY KEY CLUSTERED 
			(
				[ID] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			)'

				EXEC sp_executesql @sql

				IF object_id('tu_SimCalcFeatureRupture') IS NULL
				BEGIN
					SET @sql = 'CREATE TRIGGER [dbo].[tu_SimCalcFeatureRupture] ON [dbo].[SimCalcFeatureRupture] FOR UPDATE AS 
								IF EXISTS(SELECT * FROM DELETED)
								BEGIN
									UPDATE dbo.SimCalcFeatureRupture
									SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
									FROM dbo.SimCalcFeatureRupture as t, DELETED as d
									WHERE t.Id=d.Id;
								END'

					EXEC sp_executesql @sql
				END

				IF object_id('tu_SimCalcFeatureRupture') IS NOT NULL
				BEGIN
					SET @sql = 'ALTER TABLE [dbo].[SimCalcFeatureRupture] ENABLE TRIGGER [tu_SimCalcFeatureRupture]'

					EXEC sp_executesql @sql
				END
			END


			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640003 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640004', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 04'

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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640004 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'CREATE PROCEDURE [dbo].[sp_Dx6ConfigV5]
						AS
						BEGIN

						IF Object_id( ''tempdb..#temp_Fabrication'' ) IS NOT NULL BEGIN
								DROP TABLE #temp_Fabrication
							END

						CREATE TABLE #temp_Fabrication
							(
								[Id]                               [NUMERIC](18, 0) NULL,
								[EffectiveStartDate]               [DATETIME] NULL,
								[EffectiveEndDate]                 [DATETIME] NULL,
								[FabricationTypeDomainId]          [NUMERIC](7, 0) NULL,
								[FabricationTypeDomainCode]        [VARCHAR](40) NULL,
								[FabricationTypeDomainDesc]        [VARCHAR](255) NULL,
								[FabricationOutsideDiameter]       [NUMERIC](8, 4) NULL,
								[FabricationName]                  [VARCHAR](100) NULL,
								[FabricationComment]               [VARCHAR](255) NULL,
								[StationSeriesId]                  [NUMERIC](10, 0) NULL,
								[StationNum]                       [NUMERIC](10, 3) NULL,
								[FabricationManufacturingTypeLd]   [NUMERIC](7, 0) NULL,
								[FabricationManufacturingTypeCode] [VARCHAR](40) NULL,
								[FabricationManufacturingTypeDesc] [VARCHAR](255) NULL,
								[FabricationOutletGrade]           [NUMERIC](5, 0) NULL,
								[FabricationOutletWallthickness]   [NUMERIC](9, 5) NULL,
								[FabricationInletDiameter]         [NUMERIC](5, 3) NULL,
								[FabricationInletGrade]            [NUMERIC](5, 0) NULL,
								[FabricationInletWallThickness]    [NUMERIC](9, 5) NULL,
								[FabricationPressureRating]        [NUMERIC](5, 0) NULL,
								[FabricationOutletDiameter]        [NUMERIC](5, 3) NULL,
								[FabricationConnectDomainID]       [NUMERIC](7, 0) NULL,
								[FabricationConnectCode]           [VARCHAR](40) NULL,
								[FabricationConnectDesc]           [VARCHAR](255) NULL,
							)

						INSERT INTO #temp_Fabrication
									(Id,
										EffectiveStartDate,
										EffectiveEndDate,
										FabricationTypeDomainCode,
										FabricationTypeDomainDesc,
										FabricationOutsideDiameter,
										FabricationName,
										FabricationComment,
										StationSeriesId,
										StationNum,
										FabricationManufacturingTypeCode,
										FabricationManufacturingTypeDesc,
										FabricationOutletGrade,
										FabricationOutletWallthickness,
										FabricationInletDiameter,
										FabricationInletGrade,
										FabricationInletWallThickness,
										FabricationPressureRating,
										FabricationOutletDiameter,
										FabricationConnectCode,
										FabricationConnectDesc)
						SELECT Row_number( )
									OVER (
									ORDER BY BeginStationSeriesId, BeginStationNum) AS Id,
								EffectiveStartDate,
								EffectiveEndDate,
								ElbowTypeCode,
								ElbowTypeDescr,
								ElbowOutsideDiameter,
								ElbowName,
								ElbowComment,
								BeginStationSeriesId,
								BeginStationNum,
								ElbowManufacturingTypeCode,
								ElbowManufacturingTypeDescr,
								ElbowOutletGrade,
								ElbowOutletWallthickness,
								ElbowInletDiameter,
								ElbowInletGrade,
								ElbowInletWallThickness,
								ElbowPressureRating,
								ElbowOutletDiameter,
								ElbowConnectCode,
								ElbowConnectDescr
						FROM   ( SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS ElbowTypeCode,
										t.Descr AS ElbowTypeDescr,
										ElbowOutsideDiameter,
										ElbowName,
										ElbowComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS ElbowManufacturingTypeCode,
										m.Descr AS ElbowManufacturingTypeDescr,
										ElbowOutletGrade,
										ElbowOutletWallthickness,
										ElbowInletDiameter,
										ElbowInletGrade,
										ElbowInletWallThickness,
										ElbowPressureRating,
										ElbowOutletDiameter,
										c.Code  AS ElbowConnectCode,
										c.Descr AS ElbowConnectDescr
									FROM   dbo.Elbow f
										LEFT JOIN dbo.ListDomain c
												ON f.ElbowConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.ElbowManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.ElbowTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS ExtrusionTypeCode,
										t.Descr AS ExtrusionTypeDescr,
										ExtrusionOutsideDiameter,
										ExtrusionName,
										ExtrusionComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS ExtrusionManufacturingTypeCode,
										m.Descr AS ExtrusionManufacturingTypeDescr,
										ExtrusionOutletGrade,
										ExtrusionOutletWallthickness,
										ExtrusionInletDiameter,
										ExtrusionInletGrade,
										ExtrusionInletWallThickness,
										ExtrusionPressureRating,
										ExtrusionOutletDiameter,
										c.Code  AS ExtrusionConnectCode,
										c.Descr AS ExtrusionConnectDescr
									FROM   dbo.Extrusion f
										LEFT JOIN dbo.ListDomain c
												ON f.ExtrusionConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.ExtrusionManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.ExtrusionTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS FlangeTypeCode,
										t.Descr AS FlangeTypeDescr,
										FlangeOutsideDiameter,
										FlangeName,
										FlangeComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS FlangeManufacturingTypeCode,
										m.Descr AS FlangeManufacturingTypeDescr,
										FlangeOutletGrade,
										FlangeOutletWallthickness,
										FlangeInletDiameter,
										FlangeInletGrade,
										FlangeInletWallThickness,
										FlangePressureRating,
										FlangeOutletDiameter,
										c.Code  AS FlangeConnectCode,
										c.Descr AS FlangeConnectDescr
									FROM   dbo.Flange f
										LEFT JOIN dbo.ListDomain c
												ON f.FlangeConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.FlangeManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.FlangeTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS ReducerTypeCode,
										t.Descr AS ReducerTypeDescr,
										ReducerOutsideDiameter,
										ReducerName,
										ReducerComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS ReducerManufacturingTypeCode,
										m.Descr AS ReducerManufacturingTypeDescr,
										ReducerOutletGrade,
										ReducerOutletWallthickness,
										ReducerInletDiameter,
										ReducerInletGrade,
										ReducerInletWallThickness,
										ReducerPressureRating,
										ReducerOutletDiameter,
										c.Code  AS ReducerConnectCode,
										c.Descr AS ReducerConnectDescr
									FROM   dbo.Reducer f
										LEFT JOIN dbo.ListDomain c
												ON f.ReducerConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.ReducerManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.ReducerTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS TeeTypeCode,
										t.Descr AS TeeTypeDescr,
										TeeOutsideDiameter,
										TeeName,
										TeeComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS TeeManufacturingTypeCode,
										m.Descr AS TeeManufacturingTypeDescr,
										TeeOutletGrade,
										TeeOutletWallthickness,
										TeeInletDiameter,
										TeeInletGrade,
										TeeInletWallThickness,
										TeePressureRating,
										TeeOutletDiameter,
										c.Code  AS TeeConnectCode,
										c.Descr AS TeeConnectDescr
									FROM   dbo.Tee f
										LEFT JOIN dbo.ListDomain c
												ON f.TeeConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.TeeManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.TeeTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS TeeTypeCode,
										t.Descr AS TeeTypeDescr,
										TapOutsideDiameter,
										TapName,
										TapComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS TapManufacturingTypeCode,
										m.Descr AS TapManufacturingTypeDescr,
										TapOutletGrade,
										TapOutletWallthickness,
										TapInletDiameter,
										TapInletGrade,
										TapInletWallThickness,
										TapPressureRating,
										TapOutletDiameter,
										c.Code  AS TapConnectCode,
										c.Descr AS TapConnectDescr
									FROM   dbo.Tap f
										LEFT JOIN dbo.ListDomain c
												ON f.TapConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.TapManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.TapTypeDomainId = t.Id
									UNION
									SELECT f.Id,
										EffectiveStartDate,
										EffectiveEndDate,
										t.Code  AS VentTypeCode,
										t.Descr AS VentTypeDescr,
										VentOutsideDiameter,
										VentName,
										VentComment,
										BeginStationSeriesId,
										BeginStationNum,
										m.Code  AS VentManufacturingTypeCode,
										m.Descr AS VentManufacturingTypeDescr,
										VentOutletGrade,
										VentOutletWallthickness,
										VentInletDiameter,
										VentInletGrade,
										VentInletWallThickness,
										VentPressureRating,
										VentOutletDiameter,
										c.Code  AS VentConnectCode,
										c.Descr AS VentConnectDescr
									FROM   dbo.Vent f
										LEFT JOIN dbo.ListDomain c
												ON f.VentConnectDomainId = c.Id
										LEFT JOIN dbo.ListDomain m
												ON f.VentManufacturingTypeLd = m.Id
										LEFT JOIN dbo.ListDomain t
												ON f.VentTypeDomainId = t.Id ) tbl

						INSERT INTO ListDomain
									(DomainCatalogId,
										Code,
										Descr,
										SourceDomainId)
						SELECT ( SELECT DomainCatalogId
									FROM   dbo.DomainCatalogColXRef
									WHERE  TableName = ''Fabrication'' AND
										ColumnName = ''FabricationTypeDomainId'' ) AS DomainCatalogId,
								tbl.Code,
								tbl.Descr,
								NULL                                              AS SourceDomainId
						FROM   ( SELECT DISTINCT FabricationTypeDomainCode AS Code,
													FabricationTypeDomainDesc AS Descr
									FROM   #temp_Fabrication
									WHERE  FabricationTypeDomainCode IS NOT NULL ) tbl
						WHERE  tbl.Code NOT IN ( SELECT Code
													FROM   ListDomain
													WHERE  DomainCatalogId =
														( SELECT DomainCatalogId
															FROM   DomainCatalogColXRef
															WHERE  TableName = ''Fabrication'' AND
																	ColumnName = ''FabricationTypeDomainId'' ) )

						INSERT INTO ListDomain
									(DomainCatalogId,
										Code,
										Descr,
										SourceDomainId)
						SELECT ( SELECT DomainCatalogId
									FROM   dbo.DomainCatalogColXRef
									WHERE  TableName = ''Fabrication'' AND
										ColumnName = ''FabricationManufacturingTypeLd'' ) AS DomainCatalogId,
								tbl.Code,
								tbl.Descr,
								NULL                                                     AS SourceDomainId
						FROM   ( SELECT DISTINCT FabricationManufacturingTypeCode AS Code,
													FabricationManufacturingTypeDesc AS Descr
									FROM   #temp_Fabrication
									WHERE  FabricationManufacturingTypeCode IS NOT NULL ) tbl
						WHERE  tbl.Code NOT IN ( SELECT Code
													FROM   ListDomain
													WHERE  DomainCatalogId =
														( SELECT DomainCatalogId
															FROM   DomainCatalogColXRef
															WHERE  TableName = ''Fabrication'' AND
																	ColumnName = ''FabricationManufacturingTypeLd'' ) )

						INSERT INTO ListDomain
									(DomainCatalogId,
										Code,
										Descr,
										SourceDomainId)
						SELECT ( SELECT DomainCatalogId
									FROM   dbo.DomainCatalogColXRef
									WHERE  TableName = ''Fabrication'' AND
										ColumnName = ''FabricationConnectDomainID'' ) AS DomainCatalogId,
								tbl.Code,
								tbl.Descr,
								NULL                                                 AS SourceDomainId
						FROM   ( SELECT DISTINCT FabricationConnectCode AS Code,
													FabricationConnectDesc AS Descr
									FROM   #temp_Fabrication
									WHERE  FabricationConnectCode IS NOT NULL ) tbl
						WHERE  tbl.Code NOT IN ( SELECT Code
													FROM   ListDomain
													WHERE  DomainCatalogId =
														( SELECT DomainCatalogId
															FROM   DomainCatalogColXRef
															WHERE  TableName = ''Fabrication'' AND
																	ColumnName = ''FabricationConnectDomainID'' ) )

						UPDATE f
						SET    FabricationTypeDomainId = t.Id,
								FabricationManufacturingTypeLd = m.Id,
								FabricationConnectDomainID = c.Id
						FROM   #temp_Fabrication f
								LEFT JOIN dbo.ListDomain t
										ON f.FabricationTypeDomainCode = t.Code AND
											t.DomainCatalogId =
											( SELECT DomainCatalogId
											FROM   dbo.DomainCatalogColXRef
											WHERE  TableName = ''Fabrication'' AND
													ColumnName = ''FabricationTypeDomainId'' )
								LEFT JOIN dbo.ListDomain m
										ON f.FabricationManufacturingTypeCode = m.Code AND
											m.DomainCatalogId =
											( SELECT DomainCatalogId
											FROM   dbo.DomainCatalogColXRef
											WHERE  TableName = ''Fabrication'' AND
													ColumnName = ''FabricationManufacturingTypeLd'' )
								LEFT JOIN dbo.ListDomain c
										ON f.FabricationConnectCode = c.Code AND
											c.DomainCatalogId =
											( SELECT DomainCatalogId
											FROM   dbo.DomainCatalogColXRef
											WHERE  TableName = ''Fabrication'' AND
													ColumnName = ''FabricationConnectDomainID'' )

						DELETE FROM dbo.Fabrication

						INSERT INTO dbo.Fabrication
									(Id,
										EffectiveStartDate,
										EffectiveEndDate,
										FabricationTypeDomainId,
										FabricationOutsideDiameter,
										FabricationName,
										FabricationComment,
										StationSeriesId,
										StationNum,
										FabricationManufacturingTypeLd,
										FabricationOutletGrade,
										FabricationOutletWallthickness,
										FabricationInletDiameter,
										FabricationInletGrade,
										FabricationInletWallThickness,
										FabricationPressureRating,
										FabricationOutletDiameter,
										FabricationConnectDomainID,
										BeginStationSeriesId,
										BeginStationNum,
										EndStationSeriesId,
										EndStationNum)
						SELECT Id,
								EffectiveStartDate,
								EffectiveEndDate,
								FabricationTypeDomainId,
								FabricationOutsideDiameter,
								FabricationName,
								FabricationComment,
								StationSeriesId,
								StationNum,
								FabricationManufacturingTypeLd,
								FabricationOutletGrade,
								FabricationOutletWallthickness,
								FabricationInletDiameter,
								FabricationInletGrade,
								FabricationInletWallThickness,
								FabricationPressureRating,
								FabricationOutletDiameter,
								FabricationConnectDomainID,
								StationSeriesId,
								StationNum,
								StationSeriesId,
								StationNum
						FROM   #temp_Fabrication

						DROP TABLE #temp_Fabrication

						END'
			EXEC sp_executesql @sql

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640004 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 05
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640005', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 05'

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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640005 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Change Stg_ILIAxialStrain.Id as identity column.sql
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'tmpStg_ILIAxialStrain')
			BEGIN
				SET @sql = 'SELECT * INTO tmpStg_ILIAxialStrain FROM Stg_ILIAxialStrain'

				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (select * from INFORMATION_SCHEMA.COLUMNS
			where COLUMNPROPERTY(object_id(TABLE_SCHEMA+'.'+TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1
			AND TABLE_NAME = 'Stg_ILIAxialStrain' AND TABLE_SCHEMA = 'dbo')
			BEGIN
				SET @sql = 'DROP TABLE Stg_ILIAxialStrain'

				EXEC sp_executesql @sql

				SET @sql = 'CREATE TABLE [dbo].[Stg_ILIAxialStrain](
								[Id] [numeric](10, 0) Identity(1,1) NOT NULL,
								[EffectiveStartDate] [datetime] NULL,
								[EffectiveEndDate] [datetime] NULL,
								[Stg_ILIId] [numeric](10, 0) NULL,
								[Stg_ILIRangeId] [numeric](10, 0) NULL,
								[StationSeriesId] [numeric](10, 0) NULL,
								[StationNum] [numeric](13, 5) NULL,
								[BeginStationSeriesId] [numeric](10, 0) NULL,
								[BeginStationNum] [numeric](13, 5) NULL,
								[EndStationSeriesId] [numeric](10, 0) NULL,
								[EndStationNum] [numeric](13, 5) NULL,
								[ILIASFeatureIdentifier] [varchar](15) NULL,
								[ILIASOdometer] [numeric](10, 3) NULL,
								[ILIASSensorP1Strain] [numeric](7, 3) NULL,
								[ILIASSensorP2Strain] [numeric](7, 3) NULL,
								[ILIASSensorP3Strain] [numeric](7, 3) NULL,
								[ILIASSensorP4Strain] [numeric](7, 3) NULL,
								[ILIASSensorP5Strain] [numeric](7, 3) NULL,
								[ILIASSensorP6Strain] [numeric](7, 3) NULL,
								[ILIASSensorP7Strain] [numeric](7, 3) NULL,
								[ILIASSensorP8Strain] [numeric](7, 3) NULL,
								[ILIASAxialStrain] [numeric](7, 3) NULL,
								[ILIASSensorP1Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP2Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP3Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP4Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP5Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP6Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP7Orientation] [numeric](6, 3) NULL,
								[ILIASSensorP8Orientation] [numeric](6, 3) NULL,
								[ILIASAreaOfInterest] [char](1) NULL,
								[ILIASAnalysisDomainId] [numeric](10, 0) NULL,
								[ILIASComments] [varchar](255) NULL,
								[ILIASX] [numeric](12, 3) NULL,
								[ILIASY] [numeric](12, 3) NULL,
								[ILIASZ] [numeric](10, 3) NULL,
								[ILIASLatitude] [numeric](12, 9) NULL,
								[ILIASLongitude] [numeric](12, 9) NULL,
								[ILIASGirthWeldNum] [varchar](25) NULL,
								[ILIASDistanceFromGirthWeld] [numeric](10, 3) NULL,
								[ILIASGirthWeldNumDS] [varchar](25) NULL,
								[ILIASDistanceFromGirthWeldDS] [numeric](10, 3) NULL,
								[IRASCustomDate1] [datetime] NULL,
								[IRASCustomDate2] [datetime] NULL,
								[IRASCustomDate3] [datetime] NULL,
								[IRASCustomDate4] [datetime] NULL,
								[IRASCustomDate5] [datetime] NULL,
								[IRASCustomNum1] [float] NULL,
								[IRASCustomNum2] [float] NULL,
								[IRASCustomNum3] [float] NULL,
								[IRASCustomNum4] [float] NULL,
								[IRASCustomNum5] [float] NULL,
								[IRASCustomString1] [varchar](255) NULL,
								[IRASCustomString2] [varchar](255) NULL,
								[IRASCustomString3] [varchar](255) NULL,
								[IRASCustomString4] [varchar](255) NULL,
								[IRASCustomString5] [varchar](255) NULL,
								[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
								[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
							 CONSTRAINT [PK_Stg_ILIAxialStrain] PRIMARY KEY CLUSTERED 
							(
								[Id] ASC
							)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
							) ON [PRIMARY]'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain]  WITH CHECK ADD  CONSTRAINT [FK_Stg_ILIASAnalysisDomainId] FOREIGN KEY([ILIASAnalysisDomainId])
							REFERENCES [dbo].[ListDomain] ([Id])'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] CHECK CONSTRAINT [FK_Stg_ILIASAnalysisDomainId]'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain]  WITH CHECK ADD  CONSTRAINT [FK_Stg_ILIASBegStationSeriesId] FOREIGN KEY([BeginStationSeriesId])
							REFERENCES [dbo].[StationSeries] ([Id])'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] CHECK CONSTRAINT [FK_Stg_ILIASBegStationSeriesId]'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain]  WITH CHECK ADD  CONSTRAINT [FK_Stg_ILIASEndStationSeriesId] FOREIGN KEY([EndStationSeriesId])
							REFERENCES [dbo].[StationSeries] ([Id])'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] CHECK CONSTRAINT [FK_Stg_ILIASEndStationSeriesId]'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain]  WITH CHECK ADD  CONSTRAINT [FK_Stg_ILIASStg_ILIId] FOREIGN KEY([Stg_ILIId])
							REFERENCES [dbo].[Stg_ILI] ([Id])'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] CHECK CONSTRAINT [FK_Stg_ILIASStg_ILIId]'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain]  WITH CHECK ADD  CONSTRAINT [FK_Stg_ILIASStg_ILIRangeId] FOREIGN KEY([Stg_ILIRangeId])
							REFERENCES [dbo].[Stg_ILIRange] ([Id])'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] CHECK CONSTRAINT [FK_Stg_ILIASStg_ILIRangeId]'
				EXEC sp_executesql @sql

				SET @sql = 'CREATE TRIGGER [dbo].[tu_Stg_ILIAxialStrain] ON [dbo].[Stg_ILIAxialStrain] FOR UPDATE AS 
									IF EXISTS(SELECT * FROM DELETED)
									BEGIN
										UPDATE dbo.Stg_ILIAxialStrain
										SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
										FROM dbo.Stg_ILIAxialStrain as t, DELETED as d
										WHERE t.Id=d.Id;
									END'
				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE [dbo].[Stg_ILIAxialStrain] ENABLE TRIGGER [tu_Stg_ILIAxialStrain]'
				EXEC sp_executesql @sql

			END
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640005 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @sql nvarchar(max)

			IF (SELECT COUNT(*) FROM Stg_ILIAxialStrain) <> (SELECT COUNT(*) FROM tmpStg_ILIAxialStrain)
			BEGIN
				SET @sql = 'SET IDENTITY_INSERT Stg_ILIAxialStrain ON
							INSERT INTO dbo.Stg_ILIAxialStrain
							(
								Id,
								EffectiveStartDate,
								EffectiveEndDate,
								Stg_ILIId,
								Stg_ILIRangeId,
								StationSeriesId,
								StationNum,
								BeginStationSeriesId,
								BeginStationNum,
								EndStationSeriesId,
								EndStationNum,
								ILIASFeatureIdentifier,
								ILIASOdometer,
								ILIASSensorP1Strain,
								ILIASSensorP2Strain,
								ILIASSensorP3Strain,
								ILIASSensorP4Strain,
								ILIASSensorP5Strain,
								ILIASSensorP6Strain,
								ILIASSensorP7Strain,
								ILIASSensorP8Strain,
								ILIASAxialStrain,
								ILIASSensorP1Orientation,
								ILIASSensorP2Orientation,
								ILIASSensorP3Orientation,
								ILIASSensorP4Orientation,
								ILIASSensorP5Orientation,
								ILIASSensorP6Orientation,
								ILIASSensorP7Orientation,
								ILIASSensorP8Orientation,
								ILIASAreaOfInterest,
								ILIASAnalysisDomainId,
								ILIASComments,
								ILIASX,
								ILIASY,
								ILIASZ,
								ILIASLatitude,
								ILIASLongitude,
								ILIASGirthWeldNum,
								ILIASDistanceFromGirthWeld,
								ILIASGirthWeldNumDS,
								ILIASDistanceFromGirthWeldDS,
								IRASCustomDate1,
								IRASCustomDate2,
								IRASCustomDate3,
								IRASCustomDate4,
								IRASCustomDate5,
								IRASCustomNum1,
								IRASCustomNum2,
								IRASCustomNum3,
								IRASCustomNum4,
								IRASCustomNum5,
								IRASCustomString1,
								IRASCustomString2,
								IRASCustomString3,
								IRASCustomString4,
								IRASCustomString5,
								CreatedUser,
								CreatedDate,
								LastModByUserId,
								LastModDateTime
							)
							SELECT Id,
								EffectiveStartDate,
								EffectiveEndDate,
								Stg_ILIId,
								Stg_ILIRangeId,
								StationSeriesId,
								StationNum,
								BeginStationSeriesId,
								BeginStationNum,
								EndStationSeriesId,
								EndStationNum,
								ILIASFeatureIdentifier,
								ILIASOdometer,
								ILIASSensorP1Strain,
								ILIASSensorP2Strain,
								ILIASSensorP3Strain,
								ILIASSensorP4Strain,
								ILIASSensorP5Strain,
								ILIASSensorP6Strain,
								ILIASSensorP7Strain,
								ILIASSensorP8Strain,
								ILIASAxialStrain,
								ILIASSensorP1Orientation,
								ILIASSensorP2Orientation,
								ILIASSensorP3Orientation,
								ILIASSensorP4Orientation,
								ILIASSensorP5Orientation,
								ILIASSensorP6Orientation,
								ILIASSensorP7Orientation,
								ILIASSensorP8Orientation,
								ILIASAreaOfInterest,
								ILIASAnalysisDomainId,
								ILIASComments,
								ILIASX,
								ILIASY,
								ILIASZ,
								ILIASLatitude,
								ILIASLongitude,
								ILIASGirthWeldNum,
								ILIASDistanceFromGirthWeld,
								ILIASGirthWeldNumDS,
								ILIASDistanceFromGirthWeldDS,
								IRASCustomDate1,
								IRASCustomDate2,
								IRASCustomDate3,
								IRASCustomDate4,
								IRASCustomDate5,
								IRASCustomNum1,
								IRASCustomNum2,
								IRASCustomNum3,
								IRASCustomNum4,
								IRASCustomNum5,
								IRASCustomString1,
								IRASCustomString2,
								IRASCustomString3,
								IRASCustomString4,
								IRASCustomString5,
								CreatedUser,
								CreatedDate,
								LastModByUserId,
								LastModDateTime
							FROM tmpStg_ILIAxialStrain
					SET IDENTITY_INSERT Stg_ILIAxialStrain OFF'
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640005 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 06
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640006', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 06'

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

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640006 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Client_EnsureSiteDefaultListDomains_40391.sql
			-- Ensure required listdomains exist for 6.4 rel 0 Import site. Note expect to not require these any more in subsequent release.
			Declare @CatID As Integer
			Declare @LDID As Integer
			Declare @LDCodeDesc As VARCHAR(20)

			-- Add the default (field value not found) LD for excavation site anomaly types
			Set @LDCodeDesc = 'OTHER'
			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossTypeDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgDefectTypeDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			Set @LDCodeDesc = '25'
			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCATypeDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			-- Verify LDs exist
			IF (Select Count(*) 
				--x.ColumnName, ld.* 
				from ListDomain ld 
				Join DomainCatalogColXRef x on x.DomainCatalogId = ld.DomainCatalogId AND ld.Code in  ('25', 'OTHER')
				WHERE x.TableName in ('ExcavationSiteCrackAnomaly', 'MechanicalDamage', 'metalloss') AND x.ColumnName like '%TypeDomainId') <> 3
			BEGIN
				RaisError ('Script failed. Missing DomainCatalog or LISTDOMAIN for ExcavationSite anomaly *TypeDomainId fields', 15, 10)
			End

			-- Create missing excavation site anomaly status default (field value not found) list domains
			Set @LDCodeDesc = 'Unknown'
			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossStatusDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgStatusDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			Set @CatID = (SELECT DomainCatalogId from DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCAStatusDomainId')
			Set @LDID =  (SELECT Id from ListDomain WHERE DomainCatalogId = @CatID AND Code = @LDCodeDesc)
			if @LDID IS null AND @CatID IS NOT NULL
			BEGIN
				Set @LDID = (SELECT COALESCE(MAX(ID), 0) + 1 FROM ListDomain)
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (@LDID, @CatID, @LDCodeDesc, @LDCodeDesc)
			End

			-- Verify LDs exist
			IF (Select Count(*)
				--x.ColumnName, ld.* 
				from ListDomain ld 
				Join DomainCatalogColXRef x on x.DomainCatalogId = ld.DomainCatalogId AND ld.Code in  ('Unknown')
				WHERE x.TableName in ('ExcavationSiteCrackAnomaly', 'MechanicalDamage', 'metalloss') AND x.ColumnName like '%StatusDomainId') <> 3
			BEGIN
				RaisError ('Script failed. Missing DomainCatalog or LISTDOMAIN for ExcavationSite anomaly *StatusDomainId fields', 15, 10)
			End

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 1
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 640006 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 07
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '640007', TransDBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 07'

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
