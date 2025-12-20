----------------------------------- VERSION 630001 CHECKPOINT 0 ----------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630001 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- LINK_SystemPreferences_InsertMaxSequentialVTProcesses_BL31240.sql

			/*
				New record to be inserted in the SystemPreferences table of the LINK DATABASE
			*/
			-- Add maximum sequential virtual table processes record to SystemPreferences table
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'MaxSequentialVTProcesses')
			BEGIN  
			  INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
			  VALUES ('MaxSequentialVTProcesses', 5, null);
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

----------------------------------------- VERSION 630001 CHECKPOINT 1 -----------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630001 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 HOTFIX Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630002', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfix Updates 02'

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

------------------------------------------- VERSION 630002 CHECKPOINT 0 ------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA
			-- Stage-StructureScript.sql

			IF OBJECT_ID('Structure', 'U') IS NULL
			BEGIN
				EXECUTE ('CREATE TABLE [dbo].[Structure](
						[Id] [numeric](10, 0) NOT NULL,
						[EffectiveStartDate] [datetime] NOT NULL,
						[EffectiveEndDate] [datetime] NULL,
						[StructureTypeDomainId] [numeric](10, 0) NOT NULL,
						[StructureComment] [varchar](255) NULL,
						[BuildingCnt] [numeric](5, 0) NOT NULL,
						[DwellingUnitCnt] [numeric](6, 2) NULL,
						[OccupancyCtgryDomainId] [numeric](10, 0) NOT NULL,
						[StructureCoordSysDomainId] [numeric](10, 0) NOT NULL,
						[StructureAreaPointInd] [char](1) NOT NULL,
						[StructureActiveFlg] [numeric](1, 0) NOT NULL,
						[StoreyCnt] [numeric](5, 0) NOT NULL,
						[DaysPerWeek] [numeric](3, 0) NULL,
						[WeeksPerYear] [numeric](3, 0) NULL,
						[OccupantCnt] [numeric](11, 6) NULL,
						[LastModByUserId] [varchar](45) NOT NULL,
						[LastModDateTime] [datetime] NOT NULL,
					 CONSTRAINT [PK_Structure] PRIMARY KEY CLUSTERED 
					(
						[Id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
					) ON [PRIMARY]

					ALTER TABLE [dbo].[Structure] ADD  DEFAULT ((0)) FOR [StoreyCnt]

					ALTER TABLE [dbo].[Structure] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

					ALTER TABLE [dbo].[Structure] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

					ALTER TABLE [dbo].[Structure]  WITH CHECK ADD  CONSTRAINT [FK_StructCoordSysDomainId] FOREIGN KEY([StructureCoordSysDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[Structure] CHECK CONSTRAINT [FK_StructCoordSysDomainId]

					ALTER TABLE [dbo].[Structure]  WITH CHECK ADD  CONSTRAINT [FK_StructOccupCtgryDomainId] FOREIGN KEY([OccupancyCtgryDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[Structure] CHECK CONSTRAINT [FK_StructOccupCtgryDomainId]

					ALTER TABLE [dbo].[Structure]  WITH CHECK ADD  CONSTRAINT [FK_StructTypeDomainId] FOREIGN KEY([StructureTypeDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[Structure] CHECK CONSTRAINT [FK_StructTypeDomainId]

					ALTER TABLE [dbo].[Structure]  WITH CHECK ADD  CONSTRAINT [CKC_STRUCTUREACTIVEFL_STRUCTUR] CHECK  (([StructureActiveFlg]=(1) OR [StructureActiveFlg]=(0)))

					ALTER TABLE [dbo].[Structure] CHECK CONSTRAINT [CKC_STRUCTUREACTIVEFL_STRUCTUR]

					ALTER TABLE [dbo].[Structure]  WITH CHECK ADD  CONSTRAINT [CKC_STRUCTUREAREAPOIN_STRUCTUR] CHECK  (([StructureAreaPointInd]=''P'' OR [StructureAreaPointInd]=''A''))

					ALTER TABLE [dbo].[Structure] CHECK CONSTRAINT [CKC_STRUCTUREAREAPOIN_STRUCTUR]')
			END

			
			IF OBJECT_ID('tu_structure', 'TR') IS NULL
			BEGIN
				EXECUTE ('CREATE TRIGGER [dbo].[tu_structure] ON [dbo].[Structure] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.Structure
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.Structure as t, DELETED as d
							WHERE t.Id=d.Id;
						END

						ALTER TABLE [dbo].[Structure] ENABLE TRIGGER [tu_structure]')
			END

			IF OBJECT_ID('StructureVertex', 'U') IS NULL
			BEGIN
			EXECUTE ('CREATE TABLE [dbo].[StructureVertex](
					[StructureId] [numeric](10, 0) NOT NULL,
					[StructureVertexSeq] [numeric](4, 0) NOT NULL,
					[StructureVertexLatitude] [numeric](11, 9) NOT NULL,
					[StructureVertexLongitude] [numeric](12, 9) NOT NULL,
					[StructureVertexX] [numeric](12, 3) NULL,
					[StructureVertexY] [numeric](12, 3) NULL,
					[StructureVertexZ] [numeric](10, 3) NULL,
					[LastModByUserId] [varchar](45) NOT NULL,
					[LastModDateTime] [datetime] NOT NULL,
				 CONSTRAINT [PK_StructureVertex] PRIMARY KEY CLUSTERED 
				(
					[StructureId] ASC,
					[StructureVertexSeq] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]

				ALTER TABLE [dbo].[StructureVertex] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

				ALTER TABLE [dbo].[StructureVertex] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

				ALTER TABLE [dbo].[StructureVertex]  WITH CHECK ADD  CONSTRAINT [FK_StructVertexStructureId] FOREIGN KEY([StructureId])
				REFERENCES [dbo].[Structure] ([Id])

				ALTER TABLE [dbo].[StructureVertex] CHECK CONSTRAINT [FK_StructVertexStructureId]

				ALTER TABLE [dbo].[StructureVertex]  WITH CHECK ADD  CONSTRAINT [CKC_STRUCTUREVERTEXLA_STRUCTUR] CHECK  (([StructureVertexLatitude]>=(-90) AND [StructureVertexLatitude]<=(90)))

				ALTER TABLE [dbo].[StructureVertex] CHECK CONSTRAINT [CKC_STRUCTUREVERTEXLA_STRUCTUR]

				ALTER TABLE [dbo].[StructureVertex]  WITH CHECK ADD  CONSTRAINT [CKC_STRUCTUREVERTEXLO_STRUCTUR] CHECK  (([StructureVertexLongitude]>=(-180) AND [StructureVertexLongitude]<=(180)))

				ALTER TABLE [dbo].[StructureVertex] CHECK CONSTRAINT [CKC_STRUCTUREVERTEXLO_STRUCTUR]

				ALTER TABLE [dbo].[StructureVertex]  WITH CHECK ADD  CONSTRAINT [CKC_STRUCTUREVERTEXSE_STRUCTUR] CHECK  (([StructureVertexSeq]>=(1)))

				ALTER TABLE [dbo].[StructureVertex] CHECK CONSTRAINT [CKC_STRUCTUREVERTEXSE_STRUCTUR]')
			END

			IF OBJECT_ID('tu_structurevertex', 'TR') IS NULL
			BEGIN
				EXECUTE ('CREATE TRIGGER [dbo].[tu_structurevertex] ON [dbo].[StructureVertex] FOR UPDATE AS 
				IF EXISTS(SELECT * FROM DELETED)
				BEGIN
					UPDATE dbo.StructureVertex
					SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
					FROM dbo.StructureVertex as t, DELETED as d
					WHERE t.StructureId=d.StructureId AND
						  t.StructureVertexSeq=d.StructureVertexSeq;
				END

				ALTER TABLE [dbo].[StructureVertex] ENABLE TRIGGER [tu_structurevertex]')
			END

			IF OBJECT_ID('FK_StructVertexStructureId') IS NULL
			BEGIN
				EXECUTE ('ALTER TABLE dbo.StructureVertex WITH CHECK ADD CONSTRAINT FK_StructVertexStructureId FOREIGN KEY(StructureId) REFERENCES dbo.Structure(Id)')
			END

			IF OBJECT_ID('FK_CalcClassStructXrStructId') IS NULL AND OBJECT_ID('CalcClassStructXref', 'U') IS NOT NULL
			BEGIN
				EXECUTE ('ALTER TABLE dbo.CalcClassStructXref WITH CHECK ADD CONSTRAINT FK_CalcClassStructXrStructId FOREIGN KEY(StructureId) REFERENCES dbo.Structure(Id)')
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

-------------------------------------------- VERSION 630002 CHECKPOINT 1 --------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Stage-StructureScript.sql
        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA

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

------------------------------------------------ VERSION 630002 CHECKPOINT 2 ------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- Stage-StructureScript.sql
        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA

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

---------------------------------------------- VERSION 630002 CHECKPOINT 3 -------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 HOTFIX Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630003', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfix Updates 03'

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