----------------------------------- VERSION 630001 CHECKPOINT 0 ----------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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

----------------------------------------- VERSION 630001 CHECKPOINT 1 -----------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 HOTFIX Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630002', DBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfix Updates 02'

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

------------------------------------------- VERSION 630002 CHECKPOINT 0 ------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA
			-- Stage-StructureScript.sql


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

-------------------------------------------- VERSION 630002 CHECKPOINT 1 --------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Stage-StructureScript.sql
        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA

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

------------------------------------------------ VERSION 630002 CHECKPOINT 2 ------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- Stage-StructureScript.sql
        --This block was meant to update the table structure for the 'Structure' table, which does not exist in KEYERA

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

---------------------------------------------- VERSION 630002 CHECKPOINT 3 -------------------------------------------------------
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 630002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 HOTFIX Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '630003', DBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfix Updates 03'

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