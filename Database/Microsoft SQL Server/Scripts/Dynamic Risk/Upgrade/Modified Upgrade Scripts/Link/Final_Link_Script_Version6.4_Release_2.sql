IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Link')
BEGIN
	RAISERROR( 'The target database is not Link database for applying this upgrade script.', 11, 0)
END
go

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- LINK_SystemPreferences_InsertValidateAsteraLicense_Bug43794.sql
			/*
				New record to be inserted in the SystemPreferences table of the LINK DATABASE
			*/
			-- Add record to SystemPreferences table: flag to indicate whether the Astera license is validated before running DataExchange or not.
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'ValidateAsteraLicense')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('ValidateAsteraLicense', 0, null);
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640201', DBVersionComment = 'Link Service Pack DDL 6.4, Rel. 2, Updates 01'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- UpdateSoilType_DomainCatalogColXRef_ColumnName.sql
			
			IF EXISTS (SELECT * from DomainCatalogColXRef where TableName = 'SoilArea' and domaincatalogid = (Select Id from domaincatalog where domaindescr = 'Soil Type') and columnname <> 'SoilTypeLD')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE ColumnName = 'SoilTypeLD'  AND TableName = 'SoilArea')
				BEGIN
					update domaincatalogcolxref 
					set columnname = 'SoilTypeLD' 
					where 
					tablename = 'SoilArea' and domaincatalogid = (Select Id from domaincatalog where domaindescr = 'Soil Type')
				END
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640202', DBVersionComment = 'Link Service Pack DDL 6.4, Rel. 2, Updates 02'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Alter_sp_ConversionCheck_Link.sql
			IF object_id('sp_ConversionCheck') IS NOT NULL
			BEGIN
				DROP PROCEDURE sp_ConversionCheck
			END

			DECLARE @sql nvarchar(max)

			SET @sql = 'CREATE PROCEDURE [dbo].[sp_ConversionCheck]
						(@fromCode VARCHAR(50), 
						 @toCode   VARCHAR(50), 
						 @offset   NUMERIC(13, 5)  = NULL OUTPUT, 
						 @factor   NUMERIC(13, 5) OUTPUT
						)
						AS
							BEGIN
								IF ( SELECT value
									FROM SystemPreferences
									WHERE ParameterName = ''ConversionFromImperialRequired''
								) = 0
									BEGIN
										SET @factor = 1; -- conversion is not required so return 1 
									END;
								IF @fromCode = @toCode
									BEGIN
										SET @factor = 1; -- conversion is not required so return 1 
									END;
								IF(@fromCode = ''Fahrenheit''
								   AND @toCode = ''Celsius'')
								  AND
								(
									SELECT value
									FROM SystemPreferences
									WHERE ParameterName = ''ConversionFromImperialRequired''
								) = 0
									BEGIN
										SET @offset = 0;
										SET @factor = 1; -- conversion is not required so return 1 
									END;
								IF(@fromCode = ''Fahrenheit''
								   AND @toCode = ''Celsius'')
								  AND
								(
									SELECT value
									FROM SystemPreferences
									WHERE ParameterName = ''ConversionFromImperialRequired''
								) = 1
									BEGIN
										SET @offset = -32;
										SET @factor = 0.5555555556;
									END;

								--if @fromCode = ''Celsius'' and @toCode = ''Fahrenheit''
								--	set @offset = 32
								--	set @factor = 1.8

								IF
								(
									SELECT value
									FROM SystemPreferences
									WHERE ParameterName = ''ConversionFromImperialRequired''
								) = 1
									BEGIN
										SELECT TOP 1 @Factor = Factor
										FROM dbo.UnitConversion uc
											 INNER JOIN dbo.UnitOfMeasure uomf ON uc.UnitCodeFromId = uomf.Id
																				  AND uomf.code = @fromCode
											 INNER JOIN dbo.UnitOfMeasure uomt ON uc.UnitCodeToId = uomt.Id
																				  AND uomt.Code = @toCode;
									END;
							END;'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Create_Temporal_Table_ON_SystemPreferences.sql
			DECLARE @TableName NVARCHAR(100) 
			DECLARE @HistoryTableName NVARCHAR(100)
			DECLARE @SQL NVARCHAR(MAX)

			SET @TableName = 'SystemPreferences'
			SET @HistoryTableName = 'History_' + @TableName

			--Check if a user table exists with the name contained in @TableName varaible
			IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
			BEGIN

				-- Create a temporal table if the history table name is not already in use
				IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @HistoryTableName)
				BEGIN
					PRINT 'CONVERTING ' + @TableName + ' TO A TEMPORAL TABLE'
					-- Create DDL to alter each table and add the period start and end date columns
					SET @SQL = 'ALTER TABLE ' + @TableName + ' 
						ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
								CONSTRAINT DF_'+ @TableName + '_ValidFrom DEFAULT SYSUTCDATETIME(),
							ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
								CONSTRAINT DF_' + @TableName + '_ValidTo DEFAULT CONVERT(DATETIME2,''9999-12-31 23:59:59.9999999''),
							PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
				
							ALTER TABLE ' +  @TableName + '
								SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.' + @HistoryTableName + '));'

					EXECUTE sp_executesql @SQL
				END
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'NodeConnection')
			BEGIN
				CREATE TABLE [dbo].[NodeConnection](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NOT NULL,
					[EffectiveEndDate] [datetime] NULL,
					[NodeId] [numeric](10, 0) NOT NULL,
					[NodeConnectionTypeDomainId] [numeric](7, 0) NOT NULL,
					[NodeConnectionStatusDomainId] [numeric](7, 0) NOT NULL,
					[NodeConnectionLatitude] [numeric](11, 9) NULL,
					[NodeConnectionLongitude] [numeric](12, 9) NULL,
					[NodeConnectionCoordSysLD] [numeric](7, 0) NOT NULL,
					[NodeConnectionX] [numeric](12, 3) NULL,
					[NodeConnectionY] [numeric](12, 3) NULL,
					[NodeConnectionZ] [numeric](10, 3) NULL,
					[StationSeriesId] [numeric](10, 0) NOT NULL,
					[StationNum] [numeric](13, 5) NOT NULL,
					[LastModByUserId] [varchar](45) default suser_sname() NOT NULL,
					[LastModDateTime] [datetime] default getdate() NOT NULL,
					[CheckSumValue] [int] NULL,
					[SourceId] [varchar](50) NULL,
					[CreatedDate] [datetime] default getdate() NOT NULL,
					[CreatedUser] [varchar](45) default suser_sname() NOT NULL,
					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL)
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- Script To add BeginStationSeriesId, EndStationSeriesId, BeginStationNum, EndStationNum.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'BeginStationSeriesID')
			BEGIN
			ALTER TABLE NodeConnection ADD BeginStationSeriesId NUMERIC (10,0) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'BeginStationNum')
			BEGIN
			ALTER TABLE NodeConnection ADD BeginStationNum NUMERIC (13,5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
			ALTER TABLE NodeConnection ADD EndStationSeriesId NUMERIC (10,0) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'EndStationNum')
			BEGIN
			ALTER TABLE NodeConnection ADD EndStationNum NUMERIC (13,5) NOT NULL
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			-- Script To Add SourceId, CreatedDate, CreatedUser to Node Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE Node ADD SourceId varchar (50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE Node ADD CreatedDate DATETIME default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE Node ADD CreatedUser VARCHAR(45) DEFAULT suser_sname() NOT NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 5
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN
			-- Script To Add SourceId, CreatedDate, CreatedUser to NodeConnection Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE NodeConnection ADD SourceId varchar (50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE NodeConnection ADD CreatedDate DATETIME default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE NodeConnection ADD CreatedUser VARCHAR(45) default suser_sname() NOT NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 6
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			-- Script To create Err_HCAPipeGasConstantFactor Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Err_HCAPipeGasConstantFactor')
			BEGIN
				CREATE TABLE [dbo].[Err_HCAPipeGasConstantFactor](
					[IRASId] [numeric](20, 0) NULL,
					[SourceId] [varchar](500) NULL,
					[EffectiveStartDate] [varchar](500) NULL,
					[EffectiveEndDate] [varchar](500) NULL,
					[GasConstantFactor] [varchar](500) NULL,
					[BeginStationSeriesId] [varchar](500) NULL,
					[BeginStationNum] [varchar](500) NULL,
					[EndStationSeriesId] [varchar](500) NULL,
					[EndStationNum] [varchar](500) NULL,
					[ErrorCount] [int] NULL,
					[WarningCount] [int] NULL,
					[MessagesText] [varchar](4000) NULL,
					[ElementName] [varchar](500) NULL,
					[LastModByUserId] [varchar](500) DEFAULT suser_sname() NULL,
					[LastModDateTime] [datetime] default getdate() NOT NULL
				) ON [PRIMARY]
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 7
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 7
		BEGIN
			-- Script To create Err_HCAPipePIRBuffer Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Err_HCAPipePIRBuffer')
			BEGIN

				CREATE TABLE [dbo].[Err_HCAPipePIRBuffer](
					[IRASId] [numeric](20, 0) NULL,
					[SourceId] [varchar](500) NULL,
					[EffectiveStartDate] [varchar](500) NULL,
					[EffectiveEndDate] [varchar](500) NULL,
					[PIRBuffer] [varchar](500) NULL,
					[BeginStationSeriesId] [varchar](500) NULL,
					[BeginStationNum] [varchar](500) NULL,
					[EndStationSeriesId] [varchar](500) NULL,
					[EndStationNum] [varchar](500) NULL,
					[ErrorCount] [int] NULL,
					[WarningCount] [int] NULL,
					[MessagesText] [varchar](4000) NULL,
					[ElementName] [varchar](500) NULL,
					[LastModByUserId] [varchar](500) default suser_sname() NULL,
					[LastModDateTime] [datetime] default getdate() NOT NULL
				) ON [PRIMARY]

			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 8
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 8
		BEGIN
			-- Script To create Err_Node Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Err_Node')
			BEGIN
				CREATE TABLE [dbo].[Err_Node](
					[IRASId] [numeric](20, 0) NULL,
					[NodeName] [varchar](500) NULL,
					[NodeAltName] [varchar](500) NULL,
					[LastModByUserId] [varchar](500) default suser_sname() NULL,
					[LastModDateTime] [datetime] default getdate() NULL,
					[SourceId] [varchar](500) NULL,
					[Errorcount] [int] NULL,
					[Warningcount] [int] NULL,
					[Messagestext] [varchar](4000) NULL,
					[Elementname] [varchar](500) NULL
				) ON [PRIMARY]
			End
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 9
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 9
		BEGIN
			-- Script To create Err_NodeConnection Table.sql

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Err_NodeConnection')
			BEGIN
				CREATE TABLE [dbo].[Err_NodeConnection](
					[IRASId] [numeric](20, 0) NULL,
					[EffectiveStartDate] [varchar](500) NULL,
					[EffectiveEndDate] [varchar](500) NULL,
					[NodeId] [varchar](500) NULL,
					[NodeConnectionType] [varchar](500) NULL,
					[NodeConnectionTypeDomainId] [varchar](500) NULL,
					[NodeConnectionStatus] [varchar](500) NULL,
					[NodeConnectionStatusDomainId] [varchar](500) NULL,
					[NodeConnectionLatitude] [varchar](500) NULL,
					[NodeConnectionLongitude] [varchar](500) NULL,
					[NodeConnectionCoordSys] [varchar](500) NULL,
					[NodeConnectionCoordSysLD] [varchar](500) NULL,
					[NodeConnectionX] [varchar](500) NULL,
					[NodeConnectionY] [varchar](500) NULL,
					[NodeConnectionZ] [varchar](500) NULL,
					[StationSeriesId] [varchar](500) NULL,
					[StationNum] [varchar](500) NULL,
					[SourceId] [varchar](500) NULL,
					[BeginStationSeriesId] [varchar](500) NULL,
					[BeginStationNum] [varchar](500) NULL,
					[EndStationSeriesId] [varchar](500) NULL,
					[EndStationNum] [varchar](500) NULL,
					[ErrorCount] [int] NULL,
					[WarningCount] [int] NULL,
					[MessagesText] [varchar](4000) NULL,
					[ElementName] [varchar](500) NULL,
					[LastModByUserId] [varchar](100) default suser_sname() NOT NULL,
					[LastModDateTime] [datetime] default getdate() NOT NULL
				) ON [PRIMARY]
			End

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 10
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 10
		BEGIN
			-- Script To Create Extract_Node Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Extract_Node')
			BEGIN
				CREATE TABLE [dbo].[Extract_Node](
					[Id] [varchar](500) NULL,
					[NodeName] [varchar](500) NULL,
					[NodeAltName] [varchar](500) NULL,
					[LastModByUserId] [varchar](500) NULL,
					[LastModDateTime] [varchar](500) NULL,
					[SourceId] [varchar](500) NULL,
					[CreatedDate] [varchar](500) NULL,
					[CreatedUser] [varchar](500) NULL
				) ON [PRIMARY]
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 11
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 11
		BEGIN
			-- Script To Create Extract_NodeConnection Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Extract_NodeConnection')
			BEGIN
				CREATE TABLE [dbo].[Extract_NodeConnection](
					[Id] [varchar](500) NULL,
					[EffectiveStartDate] [varchar](500) NULL,
					[EffectiveEndDate] [varchar](500) NULL,
					[NodeId] [varchar](500) NULL,
					[NodeConnectionTypeDomainId] [varchar](500) NULL,
					[NodeConnectionStatusDomainId] [varchar](500) NULL,
					[NodeConnectionLatitude] [varchar](500) NULL,
					[NodeConnectionLongitude] [varchar](500) NULL,
					[NodeConnectionCoordSysLD] [varchar](500) NULL,
					[NodeConnectionX] [varchar](500) NULL,
					[NodeConnectionY] [varchar](500) NULL,
					[NodeConnectionZ] [varchar](500) NULL,
					[StationSeriesId] [varchar](500)  NULL,
					[StationNum] [varchar](500) NULL,
					[LastModByUserId] [varchar](500)  NULL,
					[LastModDateTime] [varchar](500)  NULL,
					[SourceId] [varchar](500)  NULL,
					[CreatedDate] [varchar](500)  NULL,
					[CreatedUser] [varchar](500) NULL,
					[BeginStationSeriesId] [varchar](500)  NULL,
					[BeginStationNum] [varchar](500)  NULL,
					[EndStationSeriesId] [varchar](500)  NULL,
					[EndStationNum] [varchar](500) NULL,
					[BeginStationSeriesGUID] [varchar](500) NULL,
					[EndStationSeriesGUID] [varchar](500) NULL,
					[NodeGUID] [varchar](500) NULL
				) ON [PRIMARY]
			End
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 12
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 12
		BEGIN
			-- Triggers_For_Updating_VersionInfo_Table.sql
			IF object_id('tu_versioninfo') IS NOT NULL
			BEGIN
				DROP TRIGGER tu_versioninfo
			END

			DECLARE @sql nvarchar(max)

			SET @sql = 'CREATE TRIGGER [dbo].[tu_versioninfo] ON [dbo].[VersionInfo] 
						FOR UPDATE AS 
						BEGIN
							UPDATE dbo.VersionInfo
							SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
							FROM dbo.VersionInfo as t, DELETED as d
							WHERE t.Id=d.Id;
						END'
			EXEC sp_executesql @sql

			SET @sql = 'ALTER TABLE [dbo].[VersionInfo] ENABLE TRIGGER [tu_versioninfo]'
			EXEC sp_executesql @sql

			IF object_id('th_versioninfo') IS NOT NULL
			BEGIN
				DROP TRIGGER th_versioninfo
			END

			SET @sql = 'CREATE TRIGGER [dbo].[th_versioninfo]
						ON [dbo].[VersionInfo] 
						FOR UPDATE AS
						BEGIN

							IF(UPDATE(DBVersion))
							BEGIN
								UPDATE dbo.versioninfo
								SET LastUpgradeUserId = SUSER_SNAME(),
									LastUpgradeDateTime = GETDATE()
								FROM dbo.VersionInfo as t, DELETED as d
								WHERE t.Id=d.Id;
							END;

							IF (UPDATE(LastUpgradeUserId) OR UPDATE(LastUpgradeDateTime) OR UPDATE (LastUpgradeType)
								 or UPDATE(DBVersion) or UPDATE(DBVersionComment) OR Update(DBVersionCheckPoint))
							BEGIN   
								INSERT INTO VersionHistory (DBVersion, DBVersionComment, LastModByUserId, LastModDateTime, DataExchangeLastRunDateTime,LastUpgradeUserId,LastUpgradeDateTime,LastUpgradeType,DBVersionCheckPoint)
								SELECT DBVersion, DBVersionComment, LastModByUserId, LastModDateTime, DataExchangeLastRunDateTime,LastUpgradeUserId,LastUpgradeDateTime,LastUpgradeType,DBVersionCheckPoint
								FROM DELETED
							END

						END'

			EXEC sp_executesql @sql

			SET @sql = 'ALTER TABLE [dbo].[VersionInfo] ENABLE TRIGGER [th_versioninfo]'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 13
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 13
		BEGIN
			-- UpdateColumnsNullable_CoverDepthProfile_Link.sql
			if (select  is_nullable from    sys.columns where   object_id = object_id('COVERDEPTHPROFILE') and name = 'Latitude') = 0
			BEGIN
			ALTER TABLE COVERDEPTHPROFILE ALTER COLUMN Latitude numeric(11,9) null
			end

			if (select  is_nullable from    sys.columns where   object_id = object_id('COVERDEPTHPROFILE')  and name = 'Longitude') = 0
			BEGIN
			ALTER TABLE COVERDEPTHPROFILE ALTER COLUMN Longitude numeric(12,9) null
			end


			if (select  is_nullable from    sys.columns where   object_id = object_id('COVERDEPTHPROFILE') and name = 'CoordSysDomainId') = 0
			BEGIN
			ALTER TABLE COVERDEPTHPROFILE ALTER COLUMN CoordSysDomainId numeric(7,0) null
			end

			if (select  is_nullable from    sys.columns where   object_id = object_id('COVERDEPTHPROFILE')  and name = 'CoverDepthReading') = 0
			BEGIN
			ALTER TABLE COVERDEPTHPROFILE ALTER COLUMN CoverDepthReading numeric(8,4) null
			end
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 14
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640202 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 14
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640203', DBVersionComment = 'Link Service Pack DDL 6.4, Rel. 2, Updates 03'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640203 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @ColumnName NVARCHAR(100);
			DECLARE @TableName NVARCHAR(100);
			DECLARE @ConstraintName NVARCHAR(100);
			DECLARE @SQL NVARCHAR(MAX);

			---------------------------------- RENAME COLUMNS & REMOVE DUPLICATE COLUMNS ---------------------------------------------

			DECLARE RenameColumnList CURSOR FOR
			SELECT table_name, column_name
			FROM INFORMATION_SCHEMA.columns
			WHERE column_name LIKE 'LastMod%' OR
				column_name LIKE 'Create%'
			EXCEPT
			SELECT table_name, column_name
			FROM INFORMATION_SCHEMA.columns
			WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId');

			OPEN RenameColumnList
			FETCH NEXT FROM RenameColumnList INTO @TableName, @ColumnName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF (@ColumnName LIKE 'LastMod%User%')
				BEGIN
					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'LastModByUserId')
					BEGIN
						-- Find and drop the default constraint on the column
						SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
						WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
						AND parent_column_id IN (SELECT column_id FROM sys.columns col
												WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
												' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
												)'
						EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

						-- Drop default constraint if it exists
						IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
						BEGIN
							EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
						END

							-- Drop the column if it exists
						IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
						BEGIN
							EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
						END

					END
					ELSE
					BEGIN
						SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''LastModByUserId'', ''COLUMN''';
						EXECUTE (@SQL)
					END
				END

				IF (@ColumnName LIKE 'Create%User%')
				BEGIN

					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'CreatedUser')
					BEGIN
						-- Find and drop the default constraint on the column
						SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
						WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
						AND parent_column_id IN (SELECT column_id FROM sys.columns col
												WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
												' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
												)'
						EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

						-- Drop default constraint if it exists
						IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
						BEGIN
							EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
						END

							-- Drop the column if it exists
						IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
						BEGIN
							EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
						END
					END
					ELSE
					BEGIN
						SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''CreatedUser'', ''COLUMN''';
						EXECUTE (@SQL)
					END
				END

				IF (@ColumnName LIKE 'LastMod%Date%')
				BEGIN
					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'LastModDateTime')
					BEGIN
						-- Find and drop the default constraint on the column
						SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
						WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
						AND parent_column_id IN (SELECT column_id FROM sys.columns col
												WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
												' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
												)'
						EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

						-- Drop default constraint if it exists
						IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
						BEGIN
							EXECUTE ('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT ' + @ConstraintName)
						END

							-- Drop the column if it exists
						IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
						BEGIN
							EXECUTE('ALTER TABLE [' + @TableName + '] DROP COLUMN ' + @ColumnName)
						END
					END
					ELSE
					BEGIN
						SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''LastModDateTime'', ''COLUMN''';
						EXECUTE (@SQL)
					END
				END

				IF (@ColumnName LIKE 'Create%Date%')
				BEGIN
					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name = 'CreatedDate')
					BEGIN
						-- Find and drop the default constraint on the column
						SET @SQL = 'SELECT @Result = cons.name FROM sys.default_constraints cons
						WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' + ')
						AND parent_column_id IN (SELECT column_id FROM sys.columns col
												WHERE col.name LIKE N' + '''' + @ColumnName + '''' +
												' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@TableName) + '''' +')
												)'
						EXECUTE sp_executesql @SQL, N'@Result @Result NVARCHAR(100) OUT', @ConstraintName OUT;

						-- Drop default constraint if it exists
						IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @ConstraintName)
						BEGIN
							EXECUTE ('ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName)
						END

							-- Drop the column if it exists
						IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @ColumnName AND table_name = @TableName)
						BEGIN
							EXECUTE('ALTER TABLE ' + @TableName + ' DROP COLUMN ' + @ColumnName)
						END
					END
					ELSE
					BEGIN
						SET @SQL = 'EXEC sp_rename ''' + @TableName + '.' + @ColumnName + ''', ''CreatedDate'', ''COLUMN''';
						EXECUTE (@SQL)
					END
				END

				FETCH NEXT FROM RenameColumnList INTO @TableName, @ColumnName
			END 

			CLOSE RenameColumnList 
			DEALLOCATE RenameColumnList

			---------------------------------- ADD MISSING COLUMNS --------------------------------------

			DECLARE AddColumnList CURSOR FOR
			SELECT table_name 
			FROM INFORMATION_SCHEMA.tables 
			WHERE table_name NOT IN (SELECT table_name 
									FROM (SELECT table_name, COUNT(table_name) AS cnt
											FROM INFORMATION_SCHEMA.columns
											WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')
											GROUP BY table_name
											HAVING COUNT(table_name) = 4
										) subq
									)
			AND Table_Type = 'BASE TABLE'; 

			OPEN AddColumnList
			FETCH NEXT FROM AddColumnList INTO @TableName

			WHILE @@FETCH_STATUS = 0 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name ='CreatedDate')
				BEGIN
					SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD CreatedDate DATE DEFAULT GETDATE() NOT NULL'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModDateTime')
				BEGIN
					SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD LastModDateTime DATE DEFAULT GETDATE() NOT NULL'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'CreatedUser')
				BEGIN
					SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD CreatedUser NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModByUserId')
				BEGIN
					SET @SQL = 'ALTER TABLE [' + @TableName + '] ADD LastModByUserId NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'
					EXECUTE (@SQL)
				END

				FETCH NEXT FROM AddColumnList INTO @TableName
			END

			CLOSE AddColumnList 
			DEALLOCATE AddColumnList
		
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640203 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640204', DBVersionComment = 'Link Service Pack DDL 6.4, Rel. 2, Updates 04'

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

