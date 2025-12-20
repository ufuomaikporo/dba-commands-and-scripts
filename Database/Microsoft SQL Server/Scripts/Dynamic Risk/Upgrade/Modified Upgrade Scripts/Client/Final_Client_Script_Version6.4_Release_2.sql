IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage')
BEGIN
	RAISERROR( 'The target database is not Stage database for applying this upgrade script.', 11, 0)
END
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- UpdateSoilType_DomainCatalogColXRef_ColumnName.sql

			if exists (Select * from DomainCatalogColXRef where TableName = 'SoilArea' and domaincatalogid = (Select Id from domaincatalog where domaindescr = 'Soil Type') and columnname <> 'SoilTypeLD')
			begin
				IF NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE ColumnName = 'SoilTypeLD' AND TableName = 'SoilArea')
				BEGIN
					update domaincatalogcolxref 
					set columnname = 'SoilTypeLD' 
					where 
					tablename = 'SoilArea' and domaincatalogid = (Select Id from domaincatalog where domaindescr = 'Soil Type')
				END
			end

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	PRINT 'Line: ' + CHAR(10) + ERROR_MESSAGE()
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
			SET DBVersion = '640201', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 01'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- Script To Add CheckSumValue Column to Node table and create Load_Node table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE Node ADD CheckSumValue [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_Node')
			BEGIN
			CREATE TABLE [dbo].[Load_Node](
				[Id] [numeric](10, 0) NOT NULL,
				[NodeName] [varchar](70) NOT NULL,
				[NodeAltName] [varchar](100) NULL,
				[LastModByUserId] [varchar](45) NOT NULL,
				[LastModDateTime] [datetime] NOT NULL,
				[SourceId] [varchar](50) NOT NULL,
				[CreatedDate] [datetime] NOT NULL,
				[CreatedUser] [varchar](45) NOT NULL,
				[CheckSumValue] [int] NOT NULL,
			 CONSTRAINT [Pk_Load_NodeSourceId] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]
			End
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- Script To Add CheckSumValue Column to NodeConnection table and create Load_NodeConnection table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'NodeConnection' And c.Column_Name = 'CheckSumValue')
			BEGIN
			ALTER TABLE NodeConnection ADD CheckSumValue [int] NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_NodeConnection')
			BEGIN

			CREATE TABLE [dbo].[Load_NodeConnection](
				[Id] [numeric](10, 0) NOT NULL,
				[EffectiveStartDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[NodeId] [numeric](10, 0) NOT NULL,
				[NodeConnectionTypeDomainId] [numeric](7, 0) NULL,
				[NodeConnectionStatusDomainId] [numeric](7, 0) NULL,
				[NodeConnectionLatitude] [numeric](11, 9) NULL,
				[NodeConnectionLongitude] [numeric](12, 9) NULL,
				[NodeConnectionCoordSysLD] [numeric](7, 0) NULL,
				[NodeConnectionX] [numeric](12, 3) NULL,
				[NodeConnectionY] [numeric](12, 3) NULL,
				[NodeConnectionZ] [numeric](10, 3) NULL,
				[StationSeriesId] [numeric](10, 0) NOT NULL,
				[StationNum] [numeric](10, 3) NOT NULL,
				[LastModByUserId] [varchar](45) NOT NULL,
				[LastModDateTime] [datetime] NOT NULL,
				[SourceId] [varchar] (50) NOT NULL,
				[CreatedDate]  [datetime] NOT NULL,
				[CreatedUser] [varchar] (45) NOT NULL,
				[BeginStationSeriesId] [numeric] (10,0) NOT NULL,
				[BeginStationNum] [numeric] (13,5) NOT NULL,
				[EndStationSeriesId] [numeric] (10,0) NOT NULL,
				[EndStationNum] [numeric] (13,5) NOT NULL,
				[CheckSumValue] [int] NULL
			 CONSTRAINT [PK_Load_NodeConnection] PRIMARY KEY CLUSTERED 
			(
				[SourceId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]

			End
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			-- Script To Add SourceId, CreatedDate, CreatedUser to Node Table.sql
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'SourceId')
			BEGIN
			ALTER TABLE Node ADD SourceId varchar (50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Node' And c.Column_Name = 'CreatedDate')
			BEGIN
			ALTER TABLE Node ADD CreatedDate DATETIME DEFAULT getdate() NOT NULL
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			-- Triggers_For_Updating_VersionInfo_Table.sql
			DECLARE @sql nvarchar(max)

			IF object_id('tu_versioninfo') IS NOT NULL
			BEGIN
				DROP TRIGGER tu_versioninfo
			END

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 7
		BEGIN
			-- UpdateColumnsNullable_CoverDepthProfile_Stage.sql
			if (select  is_nullable from    sys.columns where   object_id = object_id('LOAD_COVERDEPTHPROFILE') and name = 'Latitude') = 0
			BEGIN
			ALTER TABLE LOAD_COVERDEPTHPROFILE ALTER COLUMN Latitude numeric(11,9) null
			end

			if (select  is_nullable from    sys.columns where   object_id = object_id('LOAD_COVERDEPTHPROFILE')  and name = 'Longitude') = 0
			BEGIN
			ALTER TABLE LOAD_COVERDEPTHPROFILE ALTER COLUMN Longitude numeric(12,9) null
			end


			if (select  is_nullable from    sys.columns where   object_id = object_id('LOAD_COVERDEPTHPROFILE') and name = 'CoordSysDomainId') = 0
			BEGIN
			ALTER TABLE LOAD_COVERDEPTHPROFILE ALTER COLUMN CoordSysDomainId numeric(7,0) null
			end

			if (select  is_nullable from    sys.columns where   object_id = object_id('LOAD_COVERDEPTHPROFILE')  and name = 'CoverDepthReading') = 0
			BEGIN
			ALTER TABLE LOAD_COVERDEPTHPROFILE ALTER COLUMN CoverDepthReading numeric(8,4) null
			end

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640201 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 8
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640202', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 02'

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
		--#########################################################################################################
		-- VARIABLE DECLARATION AND INITIALIZATION
		--#########################################################################################################

		-- Stores trigger info
		DECLARE @trigger_id AS INT
		DECLARE @trigger_name AS VARCHAR(150)
		DECLARE @trigger_def AS VARCHAR(MAX) 

		-- Stores name of column being searched for or replaced
		DECLARE @search_string AS NVARCHAR(100)
		DECLARE @replace_string AS NVARCHAR(100)

		-- Stores SQL queries and commands
		DECLARE @GetColumnCount AS NVARCHAR(1000)
		DECLARE @GetDefaultConst AS NVARCHAR(500)
		DECLARE @GetColumnList NVARCHAR(500)
		DECLARE @GetOldColList NVARCHAR(500)
		DECLARE @GetAddColumnList NVARCHAR(500)
		DECLARE @GetColModList NVARCHAR(500)
		DECLARE @GetTriggerModList NVARCHAR(800)

		--Stores table and column info
		DECLARE @column_name VARCHAR(70)
		DECLARE @table_name AS VARCHAR(150)
		DECLARE @column_count AS INT
		DECLARE @constraint_name NVARCHAR(200)
		DECLARE @default_constraint NVARCHAR(70)
		DECLARE @q_column_name NVARCHAR(800)
		DECLARE @data_type NVARCHAR(70)

		-- Stores counter values for while-loop
		DECLARE @row_count INT
		DECLARE @counter INT 
		DECLARE @sub_counter INT

		-- Stores list of column names 
		DECLARE @new_name_list VARCHAR(MAX);
		DECLARE @old_name_list VARCHAR(MAX)

		-- Stores result after search and replace operation
		DECLARE @snr_process_1 NVARCHAR(MAX)
		DECLARE @snr_process_2 NVARCHAR(MAX)

		-- counts occurrence of a word within a string
		DECLARE @word_count INT

		-- Stores modified trigger definition
		DECLARE @new_definition NVARCHAR(MAX)

		-- Stores position index within a string
		DECLARE @index_select_stmt INT
		DECLARE @index_insert_stmt INT
		DECLARE @index_update_stmt INT
		DECLARE @begin_phrase_index INT
		DECLARE @end_phrase_index INT
		DECLARE @index_case_func INT

		--Stores substrings
		DECLARE @update_stmt NVARCHAR(MAX)
		DECLARE @begin_stmt NVARCHAR(MAX)
		DECLARE @insert_stmt NVARCHAR(MAX)
		DECLARE @select_stmt NVARCHAR(MAX)
		DECLARE @insertNselect_stmt NVARCHAR(MAX)
		DECLARE @set_clause_limit NVARCHAR(MAX)

		------------------------------------------- TABLE DECLARATION/CREATION -------------------------------------------------------

		-- Table to store search and replace values for columns that need to be renamed
		DECLARE @SearchNReplace_tbl TABLE (id INT IDENTITY(1,1), searchString NVARCHAR(70), newString NVARCHAR(70), dataType NVARCHAR(70), default_const NVARCHAR(70))  
		INSERT INTO @SearchNReplace_tbl VALUES ('Create%User%','CreatedUser', 'VARCHAR(45)', 'SUSER_SNAME()');
		INSERT INTO @SearchNReplace_tbl VALUES ('LastMod%User%','LastModByUserId', 'VARCHAR(45)', 'SUSER_SNAME()');
		INSERT INTO @SearchNReplace_tbl VALUES ('Create%Date%','CreatedDate', 'DATETIME', 'GETDATE()');
		INSERT INTO @SearchNReplace_tbl VALUES ('LastMod%Date%','LastModDateTime', 'DATETIME', 'GETDATE()');

		-- Stores trigger info
		DECLARE @TriggerList_tbl TABLE (row_id INT IDENTITY(1,1), trigger_id INT, trigger_name NVARCHAR(100), table_name NVARCHAR(100), definitions NVARCHAR(MAX));

		-- Stores query to get the count of duplicate columns
		IF OBJECT_ID('tempdb..##ColumnCount_tbl') IS NOT NULL
				DROP TABLE ##ColumnCount_tbl;

		CREATE TABLE ##ColumnCount_tbl (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_count INT)

		-- Stores list of tables that do not have a column with the specified column name. The column(s) will be added to the tables in this list
		DECLARE @AddColumnList_tbl TABLE (id INT IDENTITY(1,1), table_name NVARCHAR(100))

		-- Table to store list of columns that need to be renamed
		DECLARE @RenameColList_tbl TABLE (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_name NVARCHAR(100))

		-- Store list of of tables with duplicate columns
		IF OBJECT_ID('tempdb..##DuplicateColumnList_tbl') IS NOT NULL
				DROP TABLE ##DuplicateColumnList_tbl;

		CREATE TABLE ##DuplicateColumnList_tbl (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_name NVARCHAR(100))

		-- Stores list of old column names with the corresponding new name that will replace it
		DECLARE @OldColNames_tbl TABLE (oldColName NVARCHAR(500), newColName NVARCHAR(500));

		--####################################################################################################################################
		-- INITIALIZE SOME VARIABLES
		--#####################################################################################################################################

		-- Stores new column names (with quotes) in a comma-seperated list 
		SELECT @new_name_list = COALESCE(@new_name_list + ', ''', '''') + CONVERT(VARCHAR(100), newString) + ''''
		FROM @SearchNReplace_tbl;

		-- Use loop to load temporary table with a list of old column names (that need to be changed) with the corresponding new column name that will replace them
		SET @counter = 1;
		SELECT @row_count = COUNT(*) FROM @SearchNReplace_tbl;

		WHILE @counter <= @row_count
		BEGIN
			SELECT @search_string = searchString FROM @SearchNReplace_tbl
			WHERE id = @counter;
			SELECT @replace_string = newString FROM @SearchNReplace_tbl
			WHERE id = @counter;

			SET @GetOldColList = 'DECLARE @result_tbl TABLE (oldColName NVARCHAR(100), newColName NVARCHAR(100))
			INSERT INTO @result_tbl
			SELECT DISTINCT(col.name), ' + 'N''' + @replace_string + '''' + '
			FROM sys.columns col
			JOIN sys.triggers trig
			ON trig.parent_id = col.object_id
			WHERE col.name LIKE N' + '''' + @search_string + '''
			AND col.name != N' + '''' + @replace_string + '''' + ';
			SELECT * FROM @result_tbl;'

			INSERT INTO @OldColNames_tbl
			EXECUTE(@GetOldColList)

			SET @counter += 1;
		END

		-- Stores quoted old column names in a comma-seperated list
		SELECT @old_name_list = COALESCE(@old_name_list + ', ''', '''') + CONVERT(VARCHAR(100), oldColName) + ''''
		FROM @OldColNames_tbl;

		-- The 'LastUpgradeDate' column exists in a trigger but does not exist in a table and needs to be changed to match the column name in tables 
		INSERT INTO @OldColNames_tbl VALUES ('LastUpgradeDate', 'LastUpgradeDateTime');

		--##################################################################################################################################
		-- RENAMING COLUMNS, ADDING COLUMNS, AND REMOVING DUPLICATED COLUMNS
		--##################################################################################################################################

		-- Cursor to store list of search and replacement values for column names
		DECLARE Search_replace_cursor CURSOR FOR
		SELECT searchString, newString, dataType, default_const FROM @SearchNReplace_tbl;

		-- Open cursor that stores list of regEx search string and replacement column name
		OPEN Search_replace_cursor;
		FETCH NEXT FROM Search_replace_cursor INTO @search_string, @replace_string, @data_type, @default_constraint

		-- Loop through Search_replace_cursor. For each column search-string and replacement string pair do the following...
		WHILE @@FETCH_STATUS = 0
		BEGIN

		------------------------------------------- ADD THE COLUMNS TO EVERY TABLE THAT DOES NOT HAVE THEM--------------------------------------------
	
		PRINT CHAR (10) + 'ADDING DATA TRACKING COLUMNS TO TABLES THAT ARE MISSING THEM...'

			-- Get the report on tables that do not have a column with a name that matches the current search-string
			SET @GetAddColumnList = 'DECLARE @result_tbl TABLE (table_name NVARCHAR(100));
			INSERT INTO @result_tbl
			SELECT table_name FROM INFORMATION_SCHEMA.TABLES 
			WHERE table_type = ''BASE TABLE''
			EXCEPT
			SELECT name FROM sys.TABLES 
			WHERE name LIKE ''GDB%'' OR
					name LIKE ''SDE%'' OR
					name LIKE ''i[0-9]%'' OR
					temporal_type = 1
			EXCEPT
			SELECT DISTINCT(table_name) 
			FROM INFORMATION_SCHEMA.COLUMNS isc
			WHERE column_name LIKE '+ '''' + @search_string + '''' + ';
			SELECT * FROM @result_tbl'

			-- Insert the report result into a table
			INSERT INTO @AddColumnList_tbl
			EXECUTE(@GetAddColumnList)

			-- For every table in the report result add the column
			SET @counter = 1
			SELECT @row_count = COUNT(*) FROM @AddColumnList_tbl
			DECLARE @ddl_statment NVARCHAR(100) 
	
			WHILE @counter <= @row_count
			BEGIN
				SELECT @table_name = table_name FROM @AddColumnList_tbl
				WHERE id = @counter
				SET @ddl_statment = CONCAT('ALTER TABLE ', @table_name, ' ADD ', @replace_string, ' ', @data_type, ' DEFAULT ', @default_constraint, ';' )

				IF NOT EXISTS(SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table_name AND column_name = @replace_string)
				BEGIN
					-- The 'LastUpgradeDateTime' column does not need to be added to every table
					IF(@replace_string != 'LastUpgradeDateTime')
						EXECUTE(@ddl_statment);
				END;
					
				SET @counter += 1
			END

		-------------------------------------------- DELETE DUPLICATE COLUMNS--------------------------------------------------------------

		PRINT CHAR(10) + 'DELETING DUPLICATE COLUMNS..'

			-- Stores command to create table to store column count for each table (to find duplicate columns)
			SET @GetColumnCount = 'DECLARE @result TABLE (table_name NVARCHAR(100), column_count INT)
			INSERT INTO @result
			SELECT table_name, COUNT(column_name) AS column_count
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE column_name LIKE N' + '''' + @search_string + '''' +
			' GROUP BY table_name 
			HAVING COUNT(column_name) > 1;
			SELECT * FROM @result;'

			TRUNCATE TABLE ##ColumnCount_tbl;
			TRUNCATE TABLE ##DuplicateColumnList_tbl;


			INSERT INTO ##ColumnCount_tbl
			EXECUTE sp_executesql @GetColumnCount;

			SET @counter = 1
			SELECT @row_count = COUNT(*) FROM ##ColumnCount_tbl;

			-- Store the columns to be deleted (all but 1 column) in a temporary table
			WHILE @counter <= @row_count
			BEGIN
		
				SELECT @table_name = table_name FROM ##ColumnCount_tbl
				WHERE id = @counter;

				SELECT @column_count = column_count FROM ##ColumnCount_tbl
				WHERE id = @counter;

				-- Stores query to populate a table variable with the list of duplicated columns for a given table
				SET @GetColumnList = 'DECLARE @result TABLE (table_name NVARCHAR(100), column_name NVARCHAR(100));
				INSERT INTO @result
				SELECT TOP '+ CAST((@column_count - 1) AS NVARCHAR) +'table_name, column_name
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE column_name LIKE N' + '''' + @search_string + '''' + 
				'	AND table_name = N' + '''' + @table_name + ''';'
				+ ' SELECT * FROM @result;'

				-- Get the list of columns that fit the search-string and store them in a table variable
				INSERT INTO ##DuplicateColumnList_tbl
				EXECUTE(@GetColumnList);

				SET @counter += 1;
			END

			-- Delete columns from table list
			SET @counter = 1
			SELECT @row_count = COUNT(*) FROM ##DuplicateColumnList_tbl;

			WHILE @counter <= @row_count
			BEGIN
				SELECT @table_name = table_name FROM ##DuplicateColumnList_tbl
				WHERE id = @counter;

				SELECT @column_name = column_name FROM ##DuplicateColumnList_tbl
				WHERE id = @counter;

				-- Find and drop the default constraint on the column
				SET @GetDefaultConst = 'SELECT @result = cons.name FROM sys.default_constraints cons
				WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + '''' + ')
				AND parent_column_id IN (SELECT column_id FROM sys.columns col
										WHERE col.name LIKE N' + '''' + @column_name + '''' +
										' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + '''' +')
										)'
				EXECUTE sp_executesql @GetDefaultConst, N'@result NVARCHAR(100) OUT', @constraint_name OUT;

				-- Drop default constraint if it exists
				IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @constraint_name)
					EXECUTE ('ALTER TABLE ' + @table_name + ' DROP CONSTRAINT ' + @constraint_name)

					-- Drop the column if it exists
				IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @column_name AND table_name = @table_name)
					EXECUTE('ALTER TABLE ' + @table_name + ' DROP COLUMN ' + @column_name)

				SET @counter += 1;
			END

		-------------------------------------------------------------- RENAME COLUMNS ------------------------------------------------------------------------------------

		PRINT CHAR(10) + 'RENAMING COLUMNS'

			-- Stores statment to get report on tables that need to be renamed
			SET @GetColModList = N'DECLARE @result TABLE (table_name NVARCHAR(100), column_name NVARCHAR(100))
			INSERT INTO @result 
			SELECT tab.name, col.name
			FROM sys.tables tab
			JOIN sys.columns col
			ON tab.object_id = col.object_id
			WHERE col.name IN (N' + @old_name_list +');
			SELECT * FROM @result;'

			-- Insert report into table
			INSERT INTO @RenameColList_tbl 
			EXECUTE(@GetColModList)

			SET @counter = 1 
			SELECT @row_count = COUNT(*) FROM @RenameColList_tbl;

			-- Loop through the tables stored in table variable and rename columns
			WHILE @counter <= @row_count
			BEGIN
				SELECT @column_name = column_name FROM @RenameColList_tbl
				WHERE id = @counter;

				SELECT @table_name = table_name FROM @RenameColList_tbl
				WHERE id = @counter;

				SELECT @replace_string = newColName FROM @OldColNames_tbl
				WHERE oldColName = @column_name

				-- Gets the qualified column name for the unique remaining column
				SET @q_column_name = CONCAT('sp_rename ''', @table_name , '.' + @column_name, '''', ', ', '''', @replace_string, '''', ', ''COLUMN'';')
		
				-- Renames the column with the replacement-string
				IF NOT EXISTS(SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table_name AND column_name = @replace_string)
					EXECUTE(@q_column_name);

				SET @counter += 1;
			END

			-- Fetch the next search-string, replacement-string pair
			FETCH NEXT FROM Search_replace_cursor INTO @search_string, @replace_string, @data_type, @default_constraint
		END -- End of Search_replace_cursor
		CLOSE Search_replace_cursor ;
		DEALLOCATE Search_replace_cursor; 

		--#####################################################################################################################################
		-- SAVE AND MODIFY TRIGGER DEFINITIONS FOR ALL AFFECTED TRIGGERS
		--#####################################################################################################################################

		--------------------------------------------------SAVE TRIGGER DEFINTIONS IN A TEMPORARY TABLE -----------------------------------------------

		PRINT 'MODIFYING TRIGGER DEFINITIONS...' + CHAR(10)

		-- Stores query to generate report of triggers that will be affected
		SET @GetTriggerModList = 'DECLARE @result_tbl TABLE (trigger_id NVARCHAR(100), trigger_name NVARCHAR(100), table_name NVARCHAR(100), definitions NVARCHAR(MAX))
		SELECT DISTINCT(trig.object_id) AS trigger_id, 
				name AS trigger_name, 
				subq.table_name,
				OBJECT_DEFINITION(trig.object_id)
		FROM sys.triggers trig
		JOIN 
		(SELECT trig.object_id AS trig_id,
				trig.name AS trigger_name,
				isc.table_name, 
				isc.column_name
		FROM INFORMATION_SCHEMA.COLUMNS isc
		INNER JOIN sys.triggers trig
			ON OBJECT_ID(isc.table_name) = trig.parent_id
		WHERE column_name IN (N' + @new_name_list + ')
		) subq
		ON subq.trig_id = trig.object_id;

		SELECT * FROM @result_tbl;'

		-- Insert query results into a local temporary table
		DELETE FROM @TriggerList_tbl;

		INSERT INTO @TriggerList_tbl
		EXECUTE(@GetTriggerModList)

		------------------------------------------------- MODIFY TRIGGER DEFINITIONS -----------------------------------------------------------

		-- Create cursor to loop through each old-column name
		DECLARE string_replace CURSOR FOR
		SELECT * FROM @OldColNames_tbl
		ORDER BY 1 DESC;

		OPEN string_replace
		FETCH NEXT FROM string_replace INTO @search_string, @replace_string

		-- Break up the definition of each trigger into smaller sections for processing. Loop through each column name that needs to be replaced
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @counter = 1
			SELECT @row_count = COUNT(*) FROM @TriggerList_tbl

			-- Loop through each trigger definition
			WHILE @counter <= @row_count
			BEGIN

				SELECT @trigger_def = definitions
				FROM @TriggerList_tbl
				WHERE row_id = @counter

				--Get the position index of the INSERT INTO statement
				SET @index_insert_stmt = CHARINDEX('INSERT INTO', @trigger_def)

				-- Stores beginning of CREATE TRIGGER statement. ELSE statement is for trigger definitions without an INSERT INTO or SELECT clause
				IF (@index_insert_stmt = 0)
					SELECT @begin_stmt = definitions
					FROM @TriggerList_tbl
					WHERE row_id = @counter;
				ELSE
				BEGIN
					-- Stores beginning of CREATE TRIGGER STATEMENT including UPDATE clause
					SELECT @begin_stmt = SUBSTRING(definitions, 0, @index_insert_stmt)
					FROM @TriggerList_tbl
					WHERE row_id = @counter;

					-- Store both the INSERT INTO and SELECT statements
					SELECT @insertNselect_stmt = SUBSTRING(definitions, @index_insert_stmt, LEN(definitions))
					FROM @TriggerList_tbl
					WHERE row_id = @counter

					-- Stores the position index for where the SELECT statement begins
					SELECT @index_select_stmt = CHARINDEX('SELECT', @insertNselect_stmt)
					FROM @TriggerList_tbl
					WHERE row_id = @counter;

					--Store the INSERT INTO statement
					SELECT @insert_stmt = SUBSTRING(@insertNselect_stmt, 0, @index_select_stmt);

					--Store the SELECT statement
					SELECT @select_stmt = SUBSTRING(@insertNselect_stmt, @index_select_stmt, LEN(@insertNselect_stmt))
					FROM @TriggerList_tbl
					WHERE row_id = @counter;
				END -- End of ELSE statement

				------------------------------------PROCESS BEGINNING OF CREATE TRIGGER STATEMENT------------------------------------

				-- Replace every occurrence of the new column name with the old column name so that all the names are uniform for a given column
				SELECT @snr_process_1 = REPLACE(@begin_stmt, @replace_string, @search_string)

				--Replace the old column name with the new column name
				SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)

				-- Stores the index for the beginning of the UPDATE clause
				SET @index_update_stmt = CHARINDEX('UPDATE', @snr_process_2);

				-- if there is an UPDATE clause the following block of code is executed
				IF (@index_update_stmt > 0)
				BEGIN

					-- Save first part of CREATE TRIGGER statement (the section before UPDATE clause)
					SET @new_definition = SUBSTRING(@snr_process_2, 0, @index_update_stmt);

					-- Store Update statement for processing
					SET @update_stmt = SUBSTRING(@snr_process_2, @index_update_stmt, LEN(@snr_process_2));

					-- Get the index of the first CASE function. column names mentioned in a CASE function will remain untouched
					SET @index_case_func = PATINDEX('%CASE%WHEN%', @update_stmt)

					-- Get the portion of the SET clause that comes before the first CASE function
					IF @index_case_func <> 0
					BEGIN
						SET @set_clause_limit = SUBSTRING(@update_stmt, 0, @index_case_func)
					END
					ELSE
					BEGIN
						SET @set_clause_limit = SUBSTRING(@update_stmt, 0, CHARINDEX('FROM',@update_stmt))
					END

					-- Get the number of occurrence of the replacement string (new column name) within the UPDATE statement (for UPDATE clauses with and without CASE functions)
					IF (@index_case_func = 0)
						SELECT @word_count = (LEN(@update_stmt) - LEN(REPLACE(@update_stmt, @replace_string, '')))/LEN(@replace_string)
					ELSE
						SELECT @word_count = (LEN(@set_clause_limit) - LEN(REPLACE(@set_clause_limit, @replace_string, '')))/LEN(@replace_string)

						-- Delete repeated column name if it is repeated more than once within the SET clause of the UPDATE statement
						SET @sub_counter = 1;
						WHILE @sub_counter < @word_count
						BEGIN 
		
							-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
							SET @begin_phrase_index = CHARINDEX( @replace_string, @update_stmt);
							SET @end_phrase_index = CHARINDEX(',', @update_stmt, @begin_phrase_index);

							-- Exit if it encounters a SET clause
							IF (@begin_phrase_index >= @index_case_func AND @index_case_func > 0)
							BEGIN
								BREAK
							END

							-- Delete duplicate column name in the SET clause
							IF (@index_case_func <> 0)
							BEGIN
								SET @update_stmt = STUFF(@update_stmt, @begin_phrase_index, (@end_phrase_index - @begin_phrase_index) + 1, '');
							END

							SET @sub_counter += 1;

						END --End of While-loop

					SET @new_definition += @update_stmt;

				END --End of IF-statement;
				ELSE 
					SET @new_definition = @snr_process_2;

				------------------------------------- PROCESS INSERT STATEMENT-----------------------------------------------

				-- For trigger definitions that have a INSERT INTO and SELECT statements
				IF (@index_insert_stmt > 0)
				BEGIN

					-- Perform 2 search and replace operations like before
					SELECT @snr_process_1 = REPLACE(@insert_stmt, @replace_string, @search_string)
					SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)
			
					-- Get the number of occurrence of a column name
					SELECT @word_count = (LEN(@snr_process_2) - LEN(REPLACE(@snr_process_2, @replace_string, '')))/LEN(@replace_string)

					-- Delete repeated column name if it is repeated more than once
					SET @sub_counter = 1
					WHILE @sub_counter < @word_count
					BEGIN
						-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
						SET @snr_process_2 = STUFF(@snr_process_2, CHARINDEX(@replace_string, @snr_process_2) - 1, LEN(@replace_string) + 2, '');

						SET @sub_counter += 1;
					END
		
					SET @new_definition += @snr_process_2
					---------------------------------------------- PROCESS SELECT STATEMENT -------------------------------------------------------------

					-- Perform 2 search and replace operations
					SELECT @snr_process_1 = REPLACE(@select_stmt, @replace_string, @search_string)
					SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)

					-- Get the number of occurrence of a column name
					SELECT @word_count = (LEN(@snr_process_2) - LEN(REPLACE(@snr_process_2, @replace_string, '')))/LEN(@replace_string)

					-- Delete repeated column name if needed
					SET @sub_counter = 1
					WHILE @sub_counter < @word_count
					BEGIN
		
						-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
						SET @snr_process_2 = STUFF(@snr_process_2, CHARINDEX(@replace_string, @snr_process_2) - 1, LEN(@replace_string) + 2, '');

						SET @sub_counter += 1;
					END
		
					SET @new_definition += @snr_process_2
				END -- End of IF statement

				-- Update the trigger definintion for the trigger currently being processed 
				UPDATE @TriggerList_tbl
				SET definitions = @new_definition
				WHERE row_id = @counter
		
				SET @counter += 1;

			END -- End of While-loop

			FETCH NEXT FROM string_replace INTO @search_string, @replace_string;

		END -- End of Cursor While-loop

		CLOSE string_replace;
		DEALLOCATE string_replace;

		--#########################################################################################################################################################
		-- RECREATE TRIGGERS
		--#########################################################################################################################################################

		PRINT 'RECREATED TRIGGERS WITH MODIFIED DEFINITIONS' + CHAR(10)

		-- Table to store triggers that failed to be recreated
		IF OBJECT_ID('FailedRecreatedTriggers') IS NOT NULL
			DROP TABLE FailedRecreatedTriggers;

		CREATE TABLE FailedRecreatedTriggers (trigger_name NVARCHAR(60),  error_msg NVARCHAR(MAX), definitions NVARCHAR(MAX));

		TRUNCATE TABLE FailedRecreatedTriggers;

		-- Create cursor to loop through each trigger 
		DECLARE trigger_list_cursor CURSOR FOR
		SELECT trigger_name, definitions FROM @TriggerList_tbl;

		-- for storing ddl statements
		DECLARE @create_statement NVARCHAR(MAX);
		DECLARE @drop_statement VARCHAR(500);

		-- Stores error message
		DECLARE @error_msg VARCHAR(500);

		IF EXISTS (SELECT * FROM @TriggerList_tbl)
		BEGIN
			OPEN trigger_list_cursor
			FETCH NEXT FROM trigger_list_cursor INTO @trigger_name, @trigger_def

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Get the DDL statement to drop and recreate the trigger
				SET @drop_statement = N'DROP TRIGGER ' +  @trigger_name + ';';
				SET @create_statement = @trigger_def;

				-- Drop and recreate the trigger
				BEGIN TRY
					EXECUTE(@drop_statement);
					EXECUTE (@create_statement);
				END TRY 
				BEGIN CATCH
					-- Stores error message to be displayed
					SET @error_msg = 'Failed to recreate trigger: ' + @trigger_name

					-- displays the error message stored in @error_msg if an error is raised
					RAISERROR(@error_msg, -1, -1)

					-- Stores triggers that failed to be recreated in a global temporary table
					INSERT INTO FailedRecreatedTriggers
					VALUES(@trigger_name,  ERROR_MESSAGE(), @trigger_def)

				END CATCH 
		
				FETCH NEXT FROM trigger_list_cursor INTO @trigger_name, @trigger_def;
			END
			CLOSE trigger_list_cursor;
		END
		DEALLOCATE trigger_list_cursor;

		IF EXISTS (SELECT * FROM FailedRecreatedTriggers)
		BEGIN
			PRINT CHAR(10) + 'THE DEFINITIONS FOR THE ' + CAST(@counter AS VARCHAR) + ' TRIGGERS THAT FAILED TO BE RECREATED CAN BE FOUND WITH THE FOLLOWING SELECT STATEMENT...';
			PRINT CHAR(10) + 'SELECT definitions FROM FailedRecreatedTriggers';

			PRINT CHAR(10) + 'A MORE DETAILED ERROR MESSAGE CAN BE FOUND WITH THE FOLLOWING SELECT STATEMENT...';
			PRINT CHAR(10) +'SELECT trigger_name, error_msg FROM FailedRecreatedTriggers';
		END
		ELSE 
			DROP TABLE FailedRecreatedTriggers;
		

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
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640203', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 03'

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





