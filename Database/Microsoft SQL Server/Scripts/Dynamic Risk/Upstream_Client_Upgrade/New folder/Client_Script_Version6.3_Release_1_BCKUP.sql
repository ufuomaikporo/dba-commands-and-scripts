---------------------------------------------- VERSION 630003 CHECKPOINT 0 ------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			/* Adding V6 columns.sql 
                The table structure for the following tables were being modified in this block but do not exist in KEYERA
                        --CoverDepthProfile, DistBusinessDistrict, DistInsideMeter, DistServiceHeadSuscept, IncidentHistory
                This block modifies the CreatedUser, CreatedDate columns which need to be renamed in KEYERA (Currently CreateDate, CreateByUserId)
                    SourceId column does not exist in KEYERA
            */
			-- IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'CreatedUser')
			-- BEGIN
			-- 	ALTER TABLE Pressure
			-- 	ADD CreatedUser varchar(45) DEFAULT (suser_sname()) NOT NULL
			-- END

			-- IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'CreatedDate')
			-- BEGIN
			-- 	ALTER TABLE Pressure
			-- 	ADD CreatedDate datetime DEFAULT (getdate()) NOT NULL
			-- END

			-- IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Pressure' And c.Column_Name = 'SourceId')
			-- BEGIN
			-- 	ALTER TABLE Pressure
			-- 	ADD SourceId varchar(50) NULL
			-- END

			ALTER TABLE dbo.Pressure
			ALTER COLUMN BeginStationNum numeric(13, 5) NOT NULL

			ALTER TABLE dbo.Pressure
			ALTER COLUMN EndStationNum numeric(13, 5) NOT NULL

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

----------------------------------------------- VERSION 630003 CHECKPOINT 1 --------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			UPDATE CoverDepthProfile
			SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId,
			BeginStationNum = StationNum, EndStationNum = StationNum

            -- The CoverDepthProfile table structure was being altered in this block but does not exist in KEYERA
			
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

------------------------------------------- VERSION 630003 CHECKPOINT 2 ----------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
	
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

----------------------------------------------- VERSION 630003 CHECKPOINT 3 -------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630101', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 01'

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

----------------------------------------------- VERSION 630101 CHECKPOINT 0 ---------------------------------------------
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
								Id numeric(10,0) NOT NULL,
								CasingId numeric(10,0) NOT NULL,
								CasingReadingDate datetime NOT NULL,
								USPipeToSoilOn numeric(5,0) NULL,
								USPipeToSoilOff numeric(5,0) NULL,
								USCasingToSoilOn numeric(5,0) NULL,
								USCasingToSoilOff numeric(5,0) NULL,
								DSPipeToSoilOn numeric(5,0) NULL,
								DSPipeToSoilOff numeric(5,0) NULL,
								DSCasingToSoilOn numeric(5,0) NULL,
								DSCasingToSoilOff numeric(5,0) NULL,
								CasingReadingComment varchar(255) NULL,
								LastModByUserId varchar(45) DEFAULT suser_sname() NOT NULL,
								LastModDateTime datetime DEFAULT getdate() NOT NULL,
								SourceId varchar(50) NULL,
								CreatedDate datetime DEFAULT getdate() NOT NULL,
								CreatedUser varchar(45) DEFAULT suser_sname() NOT NULL,
						 CONSTRAINT [PK_CasingReading] PRIMARY KEY CLUSTERED 
						(
							[CasingId] ASC,
							[CasingReadingDate] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
						) ON [PRIMARY]
						END'

			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''FK_CasingReadingCasingId'') IS NULL
						BEGIN
							ALTER TABLE [dbo].[CasingReading]  WITH CHECK ADD  CONSTRAINT [FK_CasingReadingCasingId] FOREIGN KEY([CasingId])
							REFERENCES [dbo].[Casing] ([Id])
						END'

			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''FK_CasingReadingCasingId'') IS NOT NULL
						BEGIN
							ALTER TABLE [dbo].[CasingReading] CHECK CONSTRAINT [FK_CasingReadingCasingId]
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

------------------------------------------- VERSION 630101 CHECKPOINT 1 ----------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- CLIENT_ColocateTables_AddStationingColumns_BL27743.sql
			-- This scripts adds stationing columns, including respective foreign keys, to tables ColocateSite, ColocateCluster, ColocateCrack, ColocateGirthWeld, ColocateNCD


			-- Changes to ColocateSite table

			-- Add BeginStationSeriesId column to ColocateSite table
			DECLARE @sql nvarchar(max)

			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateSite'' and COLUMN_NAME =''BeginStationSeriesId'')
						BEGIN
							ALTER TABLE ColocateSite ADD BeginStationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add BeginStationNum column to ColocateSite table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateSite'' and COLUMN_NAME =''BeginStationNum'')
						BEGIN
							ALTER TABLE ColocateSite ADD BeginStationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add EndStationSeriesId column to ColocateSite table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateSite'' and COLUMN_NAME =''EndStationSeriesId'')
						BEGIN
							ALTER TABLE ColocateSite ADD EndStationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add EndStationNum column to ColocateSite table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateSite'' and COLUMN_NAME =''EndStationNum'')
						BEGIN
							ALTER TABLE ColocateSite ADD EndStationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add foreign key for BeginStationSeriesId
			IF object_id('FK_ColocateSiteBeginSSId') IS NULL
			BEGIN
				   ALTER TABLE ColocateSite ADD CONSTRAINT FK_ColocateSiteBeginSSId FOREIGN KEY (BeginStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			-- Add foreign key for EndStationSeriesId
			IF object_id('FK_ColocateSiteEndSSId') IS NULL
			BEGIN
				   ALTER TABLE ColocateSite ADD CONSTRAINT FK_ColocateSiteEndSSId FOREIGN KEY (EndStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			-- Changes to ColocateCluster table

			-- Add StationSeriesId column to ColocateCluster table

			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateCluster'' and COLUMN_NAME =''StationSeriesId'')
						BEGIN
							ALTER TABLE ColocateCluster ADD StationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add StationNum column to ColocateCluster table

			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateCluster'' and COLUMN_NAME =''StationNum'')
						BEGIN
							ALTER TABLE ColocateCluster ADD StationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add foreign key for StationSeriesId
			IF object_id('FK_ColocateClusterStnSerId') IS NULL
			BEGIN
				   ALTER TABLE ColocateCluster ADD CONSTRAINT FK_ColocateClusterStnSerId FOREIGN KEY (StationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			-- Changes to ColocateCrack table

			-- Add StationSeriesId column to ColocateCrack table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateCrack'' and COLUMN_NAME =''StationSeriesId'')
						BEGIN
							ALTER TABLE ColocateCrack ADD StationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add StationNum column to ColocateCrack table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateCrack'' and COLUMN_NAME =''StationNum'')
						BEGIN
							ALTER TABLE ColocateCrack ADD StationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add foreign key for StationSeriesId
			IF object_id('FK_ColocateCrackStnSerId') IS NULL
			BEGIN
				   ALTER TABLE ColocateCrack ADD CONSTRAINT FK_ColocateCrackStnSerId FOREIGN KEY (StationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			-- Changes to ColocateGirthWeld table

			-- Add StationSeriesId column to ColocateGirthWeld table

			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateGirthWeld'' and COLUMN_NAME =''StationSeriesId'')
						BEGIN
							ALTER TABLE ColocateGirthWeld ADD StationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add StationNum column to ColocateGirthWeld table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateGirthWeld'' and COLUMN_NAME =''StationNum'')
						BEGIN
							ALTER TABLE ColocateGirthWeld ADD StationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add foreign key for StationSeriesId
			IF object_id('FK_ColocateGWStnSerId') IS NULL
			BEGIN
				   ALTER TABLE ColocateGirthWeld ADD CONSTRAINT FK_ColocateGWStnSerId FOREIGN KEY (StationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			-- Changes to ColocateNCD table

			-- Add StationSeriesId column to ColocateNCD table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateNCD'' and COLUMN_NAME =''StationSeriesId'')
						BEGIN
							ALTER TABLE ColocateNCD ADD StationSeriesId NUMERIC(10,0) NULL
						END'

			EXEC sp_executesql @sql

			-- Add StationNum column to ColocateNCD table
			SET @sql = 'IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.columns where TABLE_NAME =''ColocateNCD'' and COLUMN_NAME =''StationNum'')
						BEGIN
							ALTER TABLE ColocateNCD ADD StationNum NUMERIC(13,5) NULL
						END'

			EXEC sp_executesql @sql

			-- Add foreign key for StationSeriesId
			IF object_id('FK_ColocateNCDStnSerId') IS NULL
			BEGIN
				   ALTER TABLE ColocateNCD ADD CONSTRAINT FK_ColocateNCDStnSerId FOREIGN KEY (StationSeriesId) REFERENCES dbo.StationSeries(Id)
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

------------------------------------------ VERSION 630101 CHECKPOINT 2 -----------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630102', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 02'

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

-------------------------------------------------- VERSION 630102 CHECKPOINT 0 ----------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--Add JointAlignment.PipesegmentId index.sql
			-- This script is for removing the extra foreign keys and adding the foreign key index for JointAlignment.PipeSegmentId.
			-- This script should only be run on Stage database.

			DECLARE @sql nvarchar(max)

			DECLARE d_cursor CURSOR FOR
				SELECT 'ALTER TABLE ' + tmp.TableName + ' DROP CONSTRAINT ' + FK_NAME FROM (
				SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
				FROM sys.foreign_key_columns fkc
				INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
				INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
				INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
				INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
				INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
				INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
				) tmp
				WHERE tmp.TableName = 'JointAlignment' AND tmp.ColumnName = 'PipeSegmentId'

			OPEN d_cursor
				FETCH NEXT FROM d_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM d_cursor INTO @sql
				END

			CLOSE d_cursor
			DEALLOCATE d_cursor
			
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

---------------------------------------- VERSION 630102 CHECKPOINT 1 ------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			--Add JointAlignment.PipesegmentId index.sql

			ALTER TABLE [dbo].[JointAlignment]  WITH CHECK ADD FOREIGN KEY([PipeSegmentId])
			REFERENCES [dbo].[PipeSegment] ([Id])

			IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_JointAlignment_PipeSegId')
			BEGIN
				CREATE NONCLUSTERED INDEX [IX_JointAlignment_PipeSegId] ON [dbo].[JointAlignment]
				(
					PipeSegmentId ASC
				)
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

----------------------------------------------- VERSION 630102 CHECKPOINT 2 -----------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630103', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 03'

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

-------------------------------------------- VERSION 630103 CHECKPOINT 0 ---------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Valve' And c.Column_Name = 'ValveConditionDomainID')
			BEGIN
				ALTER TABLE Valve ADD ValveConditionDomainID [numeric](7,0) NULL
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

--------------------------------------------------- VERSION 630103 CHECKPOINT 1 ----------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630104', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 04'

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

------------------------------------------ VERSION 630104 CHECKPOINT 0 ------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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

------------------------------------------- VERSION 630104 CHECKPOINT 1 ------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
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

------------------------------------------------- VERSION 630104 CHECKPOINT 2 --------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 05
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630105', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 05'

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

------------------------------------------------- VERSION 630105 CHECKPOINT 0 ---------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (select 1
						from  sysobjects
					   where  id = object_id('ActionItem')
						and   type = 'U')
			BEGIN

			  -- create table
			  EXEC ('
			  CREATE TABLE [dbo].[ActionItem](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[ProjectRunDate] [datetime] NULL,
				[Description] [varchar](4000) NULL,
				[EffectiveEndDate] [datetime] NULL,
				[HierarchyLevel] [numeric](3, 0) NULL,
				[HierarchyName] [varchar](100) NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
				CONSTRAINT [PK_ActionItem] PRIMARY KEY CLUSTERED 
				(
					[Id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]
			  ')
  
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItem')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItem]'
	
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItem] ON [dbo].[ActionItem] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.ActionItem
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.ActionItem as t, DELETED as d
				WHERE t.Id=d.Id;
			END'

			EXEC sp_executesql @sql

			-- Create the new table for the action item range.
			IF NOT EXISTS (select 1
						from  sysobjects
					   where  id = object_id('ActionItemRange')
						and   type = 'U')
			BEGIN

			  -- create table
			  EXEC ('
			  CREATE TABLE [dbo].[ActionItemRange](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[ActionItemId] [numeric](18, 0) NOT NULL,
				[LineId] [numeric](18, 0) NOT NULL,
				[LineName] [varchar](100) NULL,
				[BeginMeasure] [numeric](18, 5) NOT NULL,
				[EndMeasure] [numeric](18, 5) NOT NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
			 CONSTRAINT [PK_ActionItemRange] PRIMARY KEY CLUSTERED 
			  (
				[Id] ASC
			  )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			  ) ON [PRIMARY]
			  ')

			  -- add trigger
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemRange]  WITH CHECK ADD  CONSTRAINT [FK_ActionItemRange_ActionItem] FOREIGN KEY([ActionItemId])
			  REFERENCES [dbo].[ActionItem] ([Id])
			  ') 
  
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemRange] CHECK CONSTRAINT [FK_ActionItemRange_ActionItem]
			  ') 
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItemRange')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItemRange]'
	
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemRange] ON [dbo].[ActionItemRange] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemRange
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemRange as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql

			IF NOT EXISTS (SELECT 1
						FROM   INFORMATION_SCHEMA.COLUMNS
						WHERE  TABLE_NAME = 'ActionItem'
								AND COLUMN_NAME = 'ProjectRunDate'
								AND TABLE_SCHEMA='DBO')
			BEGIN
				ALTER TABLE ActionItem
				ADD ProjectRunDate DATETIME;
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

-------------------------------------------- VERSION 630105 CHECKPOINT 1 --------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 06
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630106', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Updates 06'

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