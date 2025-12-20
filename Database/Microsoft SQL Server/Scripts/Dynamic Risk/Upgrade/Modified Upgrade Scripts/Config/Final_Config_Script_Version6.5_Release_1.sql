/********************************* SET THE STAGE DB NAME *********************************/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @flag INT
DECLARE @StageDatabaseName NVARCHAR(100) 
DECLARE @ErrorMsg NVARCHAR(600)

SET @StageDatabaseName = ''

/******************************************************************************************/

-- Check User input
BEGIN
	IF (SELECT COUNT(*) FROM sys.databases WHERE name = @StageDatabaseName) = 0
	BEGIN
		SET @ErrorMsg = 'Stage database not found. Please enter a correct stage database name before running this script.' + CHAR(10);
		THROW 51001, @ErrorMsg, 1;  
	END
	ELSE IF SUBSTRING(DB_NAME(), 0, CHARINDEX('_IRAS', DB_NAME())) <>  SUBSTRING(@StageDatabaseName, 0, CHARINDEX('_IRAS', @StageDatabaseName)) 
	BEGIN
		SET @ErrorMsg = 'The stage and config database client names do not appear to match' + CHAR(10);
		THROW 51000, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		EXEC sp_set_session_context N'StageDatabaseName', @StageDatabaseName;
	END

	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @StageDatabaseName + '.dbo.SystemPreferences 
				WHERE ParameterName = ''DatabaseType'' AND Value <> ''Stage'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag = 1
	BEGIN
		SET @ErrorMsg = 'The selected stage database appears to be either a link or a config database.' + CHAR(10);
		THROW 51000, @ErrorMsg, 1;   
	END

	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @StageDatabaseName + '.dbo.VersionInfo 
				WHERE DBVersion < 650100'

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag = 1 
	BEGIN
		SET @ErrorMsg = 'The stage database needs to be upgraded to the latest 6.5.1 version of IRAS before upgrading the config database.' + CHAR(10);
		THROW 51000, @ErrorMsg, 1
	END

	IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Config')
	BEGIN
		SET @ErrorMsg = 'The target database is not a config database. This script must be executed on a config database.' + CHAR(10)
		RAISERROR(@ErrorMsg, 11, 0)
	END
END

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			-- CONFIG_FixVariableMetaData_Bug51023.sql
			UPDATE [VariableMetadata] SET DecimalPlaceCount = 5 
			WHERE VariableId = (SELECT Id From [Variable] WHERE Name = 'COM_LENGTH') AND UnitCodeId = (SELECT Id From UnitOfMeasure WHERE Code = 'Feet')

			UPDATE [VariableMetadata] SET DecimalPlaceCount = 5 
			WHERE VariableId = (SELECT Id From [Variable] WHERE Name = 'COM_BEGIN_MEASURE') AND UnitCodeId = (SELECT Id From UnitOfMeasure WHERE Code = 'Feet')

			UPDATE [VariableMetadata] SET DecimalPlaceCount = 5 
			WHERE VariableId = (SELECT Id From [Variable] WHERE Name = 'COM_END_MEASURE') AND UnitCodeId = (SELECT Id From UnitOfMeasure WHERE Code = 'Feet')

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	SET @ErrorMsg = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- AddDataSourceSchemaTable.sql
			declare @sql nvarchar(max)

			-- Create a new DataSourceSchema table.
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DataSourceSchema]') AND type = 'U')
			BEGIN
				SET  @sql = 'CREATE TABLE DataSourceSchema (
					[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
					[Name] [varchar](255) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					CONSTRAINT [PK_DataSourceSchema] PRIMARY KEY (Id),
					CONSTRAINT UK_DataSourceSchema_Name UNIQUE (Name)
					)'

				EXEC sp_executesql @sql

				SET @SQL = 'CREATE TRIGGER dbo.tu_DataSourceSchema ON dbo.DataSourceSchema FOR UPDATE AS 
				IF EXISTS(SELECT * FROM DELETED)
				BEGIN
					UPDATE dbo.DataSourceSchema
					SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
					FROM dbo.DataSourceSchema as t, DELETED as d
					WHERE t.Id=d.Id;
				END'
			
				EXECUTE (@SQL) 
					
			END
			
			-- Add the 'DataSourceSchemaId' column if it does not already exist in the 'DataSourceTable' table.
			IF NOT EXISTS (
				SELECT * 
				FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE TABLE_NAME = 'DataSourceTable' 
				AND COLUMN_NAME = 'DataSourceSchemaId'
			)
			BEGIN
				-- Add a new column 'DataSourceSchemaId' to 'DataSourceTable' table
				ALTER TABLE DataSourceTable
				ADD DataSourceSchemaId numeric(18, 0) NULL;

				-- Add a foreign key constraint to the 'DataSourceSchemaId' column
				ALTER TABLE DataSourceTable
				ADD CONSTRAINT FK_DataSourceTable_DataSourceSchema
				FOREIGN KEY (DataSourceSchemaId) REFERENCES DataSourceSchema(Id);
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 1
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650101', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 1', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @StageDatabaseName NVARCHAR(100)

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			IF NOT EXISTS (SELECT * FROM DataSourceSchema WHERE name = 'DRAS')
			BEGIN
				INSERT INTO DataSourceSchema (Name)
				VALUES ('DRAS')
			END

			-- Add a foreign on the DataSourceSchema table referencing the DataSourceTable table
			IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DataSourceTableSchema')
			BEGIN
				ALTER TABLE DataSourceTable WITH CHECK ADD CONSTRAINT FK_DataSourceTableSchema
				FOREIGN KEY (DataSourceSchemaId) REFERENCES DataSourceSchema (Id)
			END

			SET @SQL = 'UPDATE DataSourceTable
			SET DataSourceSchemaId = CASE 
									WHEN rs.name = ''DRAS'' THEN (SELECT Id FROM DataSourceSchema WHERE Name = ''DRAS'')
								 END
			FROM DataSourceTable dst
			JOIN ' + @StageDatabaseName + '.sys.tables rt
			ON rt.name = dst.name
			JOIN ' + @StageDatabaseName + '.sys.schemas rs
			ON rt.schema_id = rs.schema_id'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650101 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 2
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650102', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 2', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			-- AddDataSourceSchemaTable.sql
			-- Create a new DataSourceSchema table.
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DataSourceSchema]') AND type = 'U')
				BEGIN
					CREATE TABLE DataSourceSchema (
					[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
					[Name] [varchar](255) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					CONSTRAINT [PK_DataSourceSchema] PRIMARY KEY (Id),
					CONSTRAINT UQ_DataSourceSchema_Name UNIQUE (Name)
					)

					SET @SQL = 'CREATE TRIGGER dbo.tu_DataSourceSchema ON dbo.DataSourceSchema FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE 
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM dbo.DataSourceSchema as t, DELETED as d
						WHERE t.Id=d.Id;
					END'	
			
					EXECUTE (@SQL)
					
				END

			-- Add the 'DataSourceSchemaId' column if it does not already exist in the 'DataSourceTable' table.
			IF NOT EXISTS (
				SELECT * 
				FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE TABLE_NAME = 'DataSourceTable' 
				AND COLUMN_NAME = 'DataSourceSchemaId'
			)
			BEGIN
				-- Add a new column 'DataSourceSchemaId' to 'DataSourceTable' table
				ALTER TABLE DataSourceTable
				ADD DataSourceSchemaId numeric(18, 0) NULL;

				-- Add a foreign key constraint to the 'DataSourceSchemaId' column
				ALTER TABLE DataSourceTable
				ADD CONSTRAINT FK_DataSourceTable_DataSourceSchema
				FOREIGN KEY (DataSourceSchemaId) REFERENCES DataSourceSchema(Id);
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650102 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN

			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 3
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650103', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 3', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @StageDatabaseName NVARCHAR(100)

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			SET @SQL = 'UPDATE DataSourceTable
			SET name = tld.LDTableName,
				Description = tld.DomainDescr,
				DisplayName = tld.LDTableName,
				DataSourceSchemaId = (SELECT Id FROM DataSourceSchema
									  WHERE name = (SELECT table_schema FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.tables
													WHERE table_name = tld.LDTableName)
									 )
			FROM DataSourceTable dt
			JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
			ON dt.name = REPLACE(tld.LDTableName, ''_VT'', '''')
			WHERE tld.LDTableName LIKE ''%[_]VT''
				AND REPLACE(tld.LDTableName, ''_VT'', '''') NOT IN (SELECT LDTableName FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable
															WHERE TableType = ''Real'')'

			EXECUTE (@SQL)

			SET @SQL = 'UPDATE DataSourceTable
			SET DisplayName = dt.name,
				Description = (SELECT VirtualTableComment 
							   FROM ' + @StageDatabaseName + '.dbo.VirtualTable_bkp 
							   WHERE VirtualTableName = tld.TableName)
			FROM DataSourceTable dt
			JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
			ON dt.name = tld.TableName
			WHERE DisplayName IS NULL'

			EXECUTE (@SQL)
		
			-- Add missing ListDomain parent and child tables to the DataSourceTable table 
			SET @SQL = 'WITH CTE AS	
					  (SELECT DISTINCT 1 AS DataSourceId, 
							   tld.TableName, 
							   (SELECT VirtualTableComment FROM ' + @StageDatabaseName + '.dbo.VirtualTable_bkp
							    WHERE VirtualTableName = tld.TableName) AS Description, 
							   CASE WHEN tld.TableType = ''Virtual'' THEN 3 ELSE NULL END AS TableType,
							   tld.TableName AS DisplayName,
							   (SELECT dss.Id FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.tables tab 
								JOIN DataSourceSchema dss ON tab.table_schema = dss.name  
								WHERE table_name = tld.TableName) AS DataSourceSchemaId,
								ROW_NUMBER() OVER (PARTITION BY tld.LDTableName ORDER BY tld.DomainDescr) RowId
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dt 
							ON dt.Name = tld.TableName
						WHERE dt.Id IS NULL AND tld.TableName IS NOT NULL
						UNION
						SELECT DISTINCT 1 AS DataSourceId 
							   ,tld.LDTableName
							   ,tld.DomainDescr AS Description
							   ,0 AS TableType
							   ,tld.LDTableName AS DisplayName
							   ,(SELECT dss.Id FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.tables tab 
								JOIN DataSourceSchema dss ON tab.table_schema = dss.name  
								WHERE table_name = tld.LDTableName) AS DataSourceSchemaId
								,ROW_NUMBER() OVER (PARTITION BY tld.LDTableName ORDER BY tld.DomainDescr) RowId
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dt
							ON dt.Name = tld.LDTableName
						WHERE dt.Id IS NULL
						)
						INSERT INTO DataSourceTable (DataSourceId, name, Description, TableType, DisplayName, DataSourceSchemaId)
						SELECT DataSourceId, TableName, Description, TableType, DisplayName, DataSourceSchemaId
						FROM CTE
						WHERE RowId = 1'
	
			EXECUTE (@SQL)
		
			-- Add ListDomain table parent and child fields to DataSourceField table
			SET @SQL = 'INSERT INTO DataSourceField (FieldName, DataTypeId, Description, TableId)
						SELECT tld.ColumnName,
								5 AS DataTypeId,
								(SELECT vc.VirtualColumnComment 
								FROM ' + @StageDatabaseName + '.dbo.VirtualColumn_bkp vc 
								JOIN ' + @StageDatabaseName + '..VirtualTable_bkp vt 
								ON vt.Id = vc.VirtualTableId 
								WHERE VirtualTableName = tld.TableName AND VirtualColumnName = tld.ColumnName) Description,
								dt.Id AS TableId
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dt 
							ON dt.Name = tld.TableName
						LEFT JOIN DataSourceField df 
							ON df.FieldName = tld.ColumnName AND df.TableId = dt.Id
						WHERE df.Id IS NULL AND tld.ColumnName IS NOT NULL
						UNION
						SELECT DISTINCT ''Id'' AS ColumnName, 
								2 AS DataTypeId,
								NULL Description,
								dt.Id AS TableId
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						LEFT JOIN DataSourceTable dt
							ON dt.Name = tld.LDTableName
						LEFT JOIN DataSourceField df 
							ON df.FieldName = ''Id'' AND df.TableId = dt.Id
						WHERE df.Id IS NULL'

			EXECUTE (@SQL)

			-- Update the DataRelation table for new virtual LD table names
			SET @SQL = 'WITH CTE AS (
						SELECT DISTINCT dtp.Name ParentTableName,
										dfp.Id ParentFieldId,
										dfc.Id ChildFieldId, 
										dtc.Name ChildTableName
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						JOIN DataSourceTable dtc 
							ON dtc.Name = tld.TableName
						JOIN DataSourceField dfc 
							ON dfc.FieldName = tld.ColumnName AND dfc.TableId = dtc.Id
						JOIN DataSourceTable dtp ON dtp.Name = tld.LDTableName
						JOIN DataSourceField dfp ON dfp.FieldName = ''Id'' AND dfp.TableId = dtp.Id
						)
						UPDATE DataRelation
						SET ParentFieldId = cte.ParentFieldId,
							Comments = cte.ParentTableName + '' -> '' + cte.ChildTablename
						FROM DataRelation dr
						JOIN CTE 
						ON dr.ChildFieldId = cte.ChildFieldId
						WHERE cte.ParentTableName like ''%[_]VT%'''

			EXECUTE (@SQL)

			-- Add missing LD table parent-child relationships in DataRelation table
			SET @SQL = 'WITH CTE AS (
						SELECT DISTINCT dtp.Name ParentTableName,
										dfp.Id ParentFieldId,
										dfc.Id ChildFieldId, 
										dfc.FieldName AS ChildFieldName,
										dtc.Name ChildTableName
						FROM ' + @StageDatabaseName + '.dbo.TempListdomainTable tld
						JOIN DataSourceTable dtc 
							ON dtc.Name = tld.TableName
						JOIN DataSourceField dfc 
							ON dfc.FieldName = tld.ColumnName AND dfc.TableId = dtc.Id
						JOIN DataSourceTable dtp ON dtp.Name = tld.LDTableName
						JOIN DataSourceField dfp ON dfp.FieldName = ''Id'' AND dfp.TableId = dtp.Id
						)
						INSERT INTO DataRelation (Id, ChildFieldId, ParentFieldId, Comments)
						SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) + (SELECT MAX(Id) FROM DataRelation),
							   ChildFieldId,
							   ParentFieldId,
							   ParentTableName + '' -> '' + ChildTableName 
						FROM CTE 
						WHERE NOT EXISTS (SELECT * FROM DataRelation dr 
										  WHERE dr.ParentFieldId = cte.ParentFieldId AND dr.ChildFieldId = cte.ChildFieldId)'
			EXECUTE (@SQL)

			-- Add missing entry for ListDomain child tables parent tables in DataSourceFieldMetaData
			SET @SQL = 'INSERT INTO DataSourceFieldMetaData (FieldId, FieldAppRole)
			SELECT df.Id, 
					CASE WHEN tld.TableType = ''Virtual'' THEN 17920
						 WHEN df.FieldName IS NOT NULL THEN 16896
					END 
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			LEFT JOIN DataSourceTable dt ON tld.TableName = dt.name
			LEFT JOIN DataSourceField df ON tld.ColumnName = df.FieldName
				AND df.TableId = dt.Id
			LEFT JOIN DataSourceFieldMetaData dmd ON df.Id = dmd.FieldId
			WHERE dmd.FieldId IS NULL AND tld.TableName IS NOT NULL
			UNION
			SELECT df.Id, 
				   8193		
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			LEFT JOIN DataSourceTable dt ON tld.LDTableName = dt.name
			LEFT JOIN DataSourceField df ON ''Id'' = df.FieldName
				AND df.TableId = dt.Id
			LEFT JOIN DataSourceFieldMetaData dmd ON df.Id = dmd.FieldId
			WHERE dmd.FieldId IS NULL '

			EXECUTE (@SQL)
				 
			SELECT @SQL = 'ALTER TABLE ' + OBJECT_NAME(i.object_id) + ' DROP CONSTRAINT '+  i.name
			FROM sys.indexes i
			WHERE i.is_primary_key = 1
			AND OBJECT_NAME(i.object_id) = 'DataSourceTableDomainCatalog'

			EXECUTE (@SQL)

			SET @SQL = 'UPDATE DataSourceTableDomainCatalog
			SET DomainCatalogSourceId = dc.Id, 
				DomainCatalog = dc.DomainDescr
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			JOIN ' + @StageDatabaseName + '.dbo.DomainCatalog_bkp dc 
				ON dc.DomainDescr = tld.DomainDescr
			JOIN DataSourceTableDomainCatalog dtc
			ON dtc.DataSourceTableId = dt.Id AND dtc.DomainCatalog = dc.DomainDescr
			WHERE dtc.DomainCatalog <> dc.DomainDescr OR dtc.DomainCatalogSourceId <> dc.Id'

			EXECUTE (@SQL)
			
			SET @SQL = 'INSERT INTO DataSourceTableDomainCatalog (DataSourceTableId, DomainCatalog, DomainCatalogSourceId)
			SELECT DISTINCT dt.Id, dc.DomainDescr, dc.Id
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			LEFT JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			JOIN ' + @StageDatabaseName + '.dbo.DomainCatalog_bkp dc 
				ON dc.DomainDescr = tld.DomainDescr
			LEFT JOIN DataSourceTableDomainCatalog dtc
			ON dtc.DataSourceTableId = dt.Id AND dtc.DomainCatalog = dc.DomainDescr
			WHERE dtc.DataSourceTableId IS NULL	AND tld.TableName NOT LIKE ''IRASCus%'''
		
			EXECUTE (@SQL);
	
			-- Remove duplicates from DataSourceTableDomainCatalog based on PK
			WITH duplicates AS  
			( SELECT *,
			  ROW_NUMBER() OVER (PARTITION BY DataSourceTableId, DomainCatalogSourceId ORDER BY CreatedDate DESC ) row_num 
			  FROM DataSourceTableDomainCatalog  
			)  
			DELETE FROM duplicates WHERE row_num > 1; 

			-- Recreate primary key
			IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_NAME(object_id) = 'DataSourceTableDomainCatalog'
							AND is_primary_key = 1)
			BEGIN
				ALTER TABLE DataSourceTableDomainCatalog WITH CHECK ADD CONSTRAINT PK_DataSourceTableDomainCatalog 
				PRIMARY KEY CLUSTERED (DataSourceTableId ASC, DomainCatalogSourceId ASC);
			END

			If object_id('DummyTablesList') is null
			BEGIN
				SET @sql = 'Create table DummyTablesList
							(
								VirtualTable varchar(8000),
								VirtualColumn varchar(8000),
								DataType1 varchar(50),
								DataType2 varchar(14),
								LDTableName varchar(100)
							)'
				EXEC sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650103 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 4
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650104', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 4', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

		/*
			Virtual tables that exist in some configuration tables (i.e DataSourceTable) that contain no data and no longer 
			exist in the stage db may still be required by the apps.
		.
			Create dummy tables for the aforementioned virtual tables
		*/
			DECLARE @ColumnList NVARCHAR(MAX)
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @VirtualTableName NVARCHAR(100)
			DECLARE @VirtualColumnName NVARCHAR(100)
			DECLARE @StageDatabaseName NVARCHAR(100) 
			DECLARE @ErrorMsg NVARCHAR(MAX)
			DECLARE @flag INT

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			-- Create a dummy LD table for virtual tables in DataSourceTable that do not exists in stage db
			SET @SQL = 'USE  ' + @StageDatabaseName + '
			IF OBJECT_ID(''DRAS.LD_DummyTable_VT'', ''U'') IS NULL
			BEGIN
				CREATE TABLE [DRAS].[LD_DummyTable_VT] (
				[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
				[Code] varchar(60) NOT NULL,
				[Descr] varchar(255) NOT NULL,
				[EffectiveEndDate] Datetime,
				[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
				[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
				[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
				[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
				CONSTRAINT [PK_LD_DummyTable_VT] PRIMARY KEY (Id ASC)
				)
			END'


			EXECUTE (@SQL)

			-- Add the LD dummy table to the DataSourceTable table
			SET @SQL = 'INSERT INTO DataSourceTable (DataSourceId, name, Description, TableType, DisplayName, DataSourceSchemaId)
			SELECT 1, ''LD_DummyTable_VT'', ''Dummy table for unused virtual tables required by app'', 4, ''LD_DummyTable_VT'', 1
			WHERE NOT EXISTS (SELECT * FROM DataSourceTable WHERE name = ''LD_DummyTable_VT'')'

			EXECUTE (@SQL)

			-- Add an entry for 'Id' column of the LD dummy table to the DataSourceField table
			INSERT INTO DataSourceField (FieldName, DataTypeId, Description, TableId)
			SELECT 'Id', 2, 'Id', Id
			FROM DataSourceTable dt 
			WHERE name = 'LD_DummyTable_VT'
			AND NOT EXISTS (SELECT * FROM DataSourceField WHERE TableId = dt.Id AND FieldName = 'Id')

			-- Add an entry for the LD dummy table in the DataSourceFieldMetaData table
			INSERT INTO DataSourceFieldMetaData (FieldId, FieldAppRole)
			SELECT df.Id, 8193
			FROM DataSourceTable dt 
			JOIN DataSourceField df ON dt.Id = df.TableId
			WHERE dt.name = 'LD_DummyTable_VT' AND df.FieldName = 'Id'
			AND NOT EXISTS (SELECT * FROM DataSourceFieldMetaData dm WHERE dm.FieldId = df.Id)

			SET @SQL = 'INSERT INTO DummyTablesList (VirtualTable, VirtualColumn, DataType1, DataType2, LDTableName)
							SELECT DISTINCT REPLACE(dt.name, CHAR(32), '''') AS VirtualTable, 
							   REPLACE(df.FieldName, CHAR(32), '''') VirtualColumn, 
							   dtype.name DataType1,
							   CASE WHEN dtype.name = ''Lookup'' THEN ''NUMERIC(10, 0)''
							   	 WHEN dtype.name = ''Number'' THEN ''INT''
							   	 WHEN dtype.name = ''Date'' THEN ''DATETIME''
							   	 WHEN dtype.name = ''Indicator'' OR dtype.name = ''Boolean'' THEN ''CHAR(1)''
							   	 WHEN dtype.name = ''SurfaceIndicator'' THEN ''VARCHAR(2)''
							   	 WHEN dtype.name = ''HcaReason'' THEN ''NUMERIC(10, 0)''
							   	ELSE ''NVARCHAR(255)''
							   END AS DataType2,
							   CASE WHEN tld.LDTableName IS NULL AND dtype.name = ''Lookup'' THEN ''LD_DummyTable_VT''
							   	WHEN dtype.name = ''Lookup'' THEN tld.LDTableName 
							   END AS LDTableName
			FROM DataSourceTable dt
			JOIN DataSourceField df 
			ON dt.Id = df.TableId
			JOIN DataType dtype ON dtype.Id = df.DataTypeId
			LEFT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
			ON tld.ColumnName = df.FieldName
			WHERE dt.TableType = 3
			AND NOT EXISTS (SELECT table_name FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns c
							WHERE c.table_name = dt.name AND c.column_name = df.FieldName)'

			EXECUTE (@SQL)
	
			-- Remove odd spaces in table and column names in DataSourceTable and DataSourceFieldTable
			UPDATE DataSourceTable 
			SET name = REPLACE(name, CHAR(32), '')
			FROM DataSourceTable tab1
			WHERE CHARINDEX(CHAR(32), name) <> 0
			AND (SELECT COUNT(*) FROM DataSourceTable tab2 
					WHERE REPLACE(tab1.name, CHAR(32), '') = REPLACE(tab2.name, CHAR(32), '')) = 1

			UPDATE DataSourceField
			SET FieldName = REPLACE(FieldName, CHAR(32), '')
			WHERE CHARINDEX(CHAR(32), FieldName) <> 0

			DECLARE VirtualTable_Cursor CURSOR FOR
			SELECT DISTINCT VirtualTable , VirtualColumn
			FROM DummyTablesList
			
			OPEN VirtualTable_Cursor
			FETCH NEXT FROM VirtualTable_Cursor INTO @VirtualTableName, @VirtualColumnName

			WHILE @@FETCH_STATUS = 0
			BEGIN

				SET @ColumnList = NULL

				SET @SQL = 'SET @Result = NULL

				SELECT @Result = COALESCE(@Result + '', '', '''') + VirtualColumn + '' '' + DataType2
				FROM DummyTablesList dt
				WHERE VirtualTable = ''' + @VirtualTableName + '''
				AND VirtualColumn NOT IN (SELECT column_name FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns
										 WHERE table_name = ''' + @VirtualTableName + ''')'

				EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(1000) OUTPUT', @ColumnList OUTPUT

				SET @SQL = '		
				IF OBJECT_ID (''' + @StageDatabaseName + '.DRAS.' + @VirtualTableName + ''', ''U'') IS NULL
				BEGIN
					USE ' + @StageDatabaseName + '

					CREATE TABLE DRAS.' + @VirtualTableName + 
					'(Id NUMERIC (10, 0) IDENTITY(1,1) NOT NULL,
					' + @ColumnList +  
					+ ',EffectiveStartDate DATETIME, 
					EffectiveEndDate DATETIME,
					BeginStationSeriesId NUMERIC(10, 0),
					BeginStationNum NUMERIC(13, 5),
					EndStationSeriesId NUMERIC(10, 0),
					EndStationNum NUMERIC(13, 5),
					SourceId VARCHAR(50),
					CreatedUser VARCHAR(45) DEFAULT (suser_sname()) NOT NULL,
					CreatedDate DATETIME DEFAULT (getdate()) NOT NULL,
					LastModByUserId VARCHAR(45) DEFAULT (suser_sname()) NOT NULL,
					LastModDateTime DATETIME DEFAULT (getdate()) NOT NULL)
				END
				ELSE IF EXISTS (SELECT * FROM DummyTablesList WHERE VirtualTable = ''' + @VirtualTableName + '''
								AND VirtualColumn NOT IN (SELECT column_name FROM INFORMATION_SCHEMA.columns))
				BEGIN
					USE ' + @StageDatabaseName + '

					ALTER TABLE DRAS.' + @VirtualTableName + ' ADD ' + @ColumnList + '
				END'		

				EXECUTE (@SQL)

				---------------------------------- Add a Primary Key to Newly Created Virtual Table ------------------------------------

				SET @SQL = ' USE ' + @StageDatabaseName + '
				IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE type = ''PK'' 
								AND OBJECT_NAME(parent_object_id) = ''' + @VirtualTableName + ''' AND SCHEMA_NAME(schema_id) = ''DRAS'')
				BEGIN
					
					ALTER TABLE [DRAS].[' + @VirtualTableName + '] ALTER COLUMN Id NUMERIC(10, 0) NOT NULL
					ALTER TABLE [DRAS].[' + @VirtualTableName + '] ADD CONSTRAINT PK_' + @VirtualTableName + ' PRIMARY KEY CLUSTERED (Id)
		
				END'

				EXECUTE (@SQL)

				-- Update TempListDomainTable table
				SELECT @SQL = 'INSERT INTO ' + @StageDatabaseName + '.dbo.TempListDomainTable 
				(TableType, LDTableSchema, LDTableName, TableSchema, TableName, ColumnName)
				SELECT ''Virtual'', ''DRAS'', LDTableName, ''DRAS'', VirtualTable, VirtualColumn 
				FROM DummyTablesList dl 
				WHERE VirtualTable =  ''' + @VirtualTableName + '''
				AND NOT EXISTS (SELECT * FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
									WHERE tld.TableName = dl.VirtualTable AND tld.ColumnName = dl.VirtualColumn)
				AND dl.DataType1 = ''Lookup'''

				EXECUTE (@SQL)

				------------------------------------ Create Foreign Keys ----------------------------------

				SELECT @SQL = 'USE ' + @StageDatabaseName 
				FROM DummyTablesList
				WHERE DataType1 = 'Lookup' AND VirtualTable = @VirtualTableName
				AND VirtualColumn = @VirtualColumnName

				-- Create foreign key referencing LD tables
				SELECT @SQL = COALESCE(@SQL + CHAR(10), '') +
				'IF NOT EXISTS (SELECT * FROM ' + @StageDatabaseName + '.sys.foreign_key_columns
								WHERE OBJECT_NAME(parent_object_id) = ''' + VirtualTable + '''
								AND COL_NAME(parent_object_id, parent_column_id) = ''' + VirtualColumn + '''
								AND OBJECT_NAME(referenced_object_id) = ''' + LDTableName + ''')' + CHAR(10) +
				'BEGIN 
					ALTER TABLE DRAS.' + VirtualTable + ' WITH CHECK ADD CONSTRAINT ' +
				'FK_' + CASE 
							WHEN VirtualTable = VirtualColumn THEN REPLACE(VirtualColumn, 'DomainId', '') 
							ELSE CASE WHEN LEN(VirtualColumn) + LEN(VirtualTable) < 24 THEN VirtualColumn + VirtualTable 
									  ELSE SUBSTRING(REPLACE(VirtualColumn, 'DomainId', ''), 1, 12) + SUBSTRING(LDTableName, 1, 10) + CAST(ROUND(RAND() * 1000, 0) AS VARCHAR)
								 END
						END	+ 'LD'	
										+ ' FOREIGN KEY (' + VirtualColumn + ')
												REFERENCES DRAS.'  + LDTableName + '(Id)' + CHAR(10) +
				'END' + CHAR(10)
				FROM DummyTablesList 
				WHERE DataType1 = 'Lookup'
				AND VirtualTable = @VirtualTableName
				AND VirtualColumn = @VirtualColumnName

				EXECUTE (@SQL)

				--Create foreign key referening the StationSeries table
				SELECT @SQL = 'USE ' + @StageDatabaseName + CHAR(10) +
				'IF NOT EXISTS (SELECT * FROM sys.foreign_key_columns 
								WHERE OBJECT_NAME(parent_object_id) = ''' + VirtualTable + '''
								AND COL_NAME(parent_object_id, parent_column_id) = ''BeginStationSeriesId''
								AND OBJECT_NAME(referenced_object_id) = ''StationSeries'')
				BEGIN 
					ALTER TABLE DRAS.' + VirtualTable + ' WITH CHECK ADD CONSTRAINT ' 
				+ 'FK_' + VirtualTable + '_BgnStnId FOREIGN KEY(BeginStationSeriesId) REFERENCES dbo.StationSeries(Id)
				END' 
				+ CHAR(10)	
				+ 'IF NOT EXISTS (SELECT * FROM sys.foreign_key_columns 
								  WHERE OBJECT_NAME(parent_object_id) = ''' + VirtualTable + '''
								  AND COL_NAME(parent_object_id, parent_column_id) = ''EndStationSeriesId''
								  AND OBJECT_NAME(referenced_object_id) = ''StationSeries'')
				BEGIN
					ALTER TABLE DRAS.' + VirtualTable + ' WITH CHECK ADD CONSTRAINT '
				+ 'FK_' + VirtualTable + '_EndStnId FOREIGN KEY(EndStationSeriesId) REFERENCES dbo.StationSeries(Id)
				END' + CHAR(10)
				FROM DummyTablesList
				WHERE VirtualTable = @VirtualTableName

				EXECUTE (@SQL)
						
				-------------------------------------- Create Triggers on Newly Created Virtual Tables --------------------------------------
		
				SET @SQL = 'USE ' + @StageDatabaseName + '
				IF OBJECT_ID(''[DRAS].[tu_' + @VirtualTableName + ']'' , ''TR'') IS NULL
				BEGIN
		
					DECLARE @SQL NVARCHAR(MAX)
		
					SET @SQL = ''CREATE TRIGGER [DRAS].[tu_' + @VirtualTableName + '] ON [DRAS].[' + @VirtualTableName+ '] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE DRAS.' + @VirtualTableName + '
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM DRAS.' + @VirtualTableName + ' as t, DELETED as d
						WHERE t.Id=d.Id;
					END''

					EXECUTE (@SQL)

				END'


				EXECUTE (@SQL)

				FETCH NEXT FROM VirtualTable_Cursor INTO  @VirtualTableName, @VirtualColumnName

			END 

			CLOSE VirtualTable_Cursor
			DEALLOCATE VirtualTable_Cursor

			-- Update schema info to 'DRAS' schema for all virtual tables 
			SET @SQL = 'UPDATE DataSourceTable
			SET DataSourceSchemaId = (SELECT Id FROM DataSourceSchema WHERE name = ''DRAS'')
			WHERE name IN (SELECT VirtualTable FROM DummyTablesList)'

			EXECUTE (@SQL)
			
			-- Add new virtual LD table to Child table relationship in DataRelation table
			SET @SQL = 'WITH CTE AS (
						SELECT DISTINCT dtp.Name ParentTableName,
										dfp.Id ParentFieldId,
										dfc.Id ChildFieldId, 
										dfc.FieldName AS ChildFieldName,
										dtc.Name ChildTableName
						FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
						JOIN DataSourceTable dtc 
							ON dtc.Name = tld.TableName
						JOIN DataSourceField dfc 
							ON dfc.FieldName = tld.ColumnName AND dfc.TableId = dtc.Id
						JOIN DataSourceTable dtp ON dtp.Name = tld.LDTableName
						JOIN DataSourceField dfp ON dfp.FieldName = ''Id'' AND dfp.TableId = dtp.Id
						)
						INSERT INTO DataRelation (Id, ChildFieldId, ParentFieldId, Comments)
						SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) + (SELECT MAX(Id) FROM DataRelation),
							   ChildFieldId,
							   ParentFieldId,
							   ParentTableName + '' -> '' + ChildTableName 
						FROM CTE 
						WHERE NOT EXISTS (SELECT * FROM DataRelation dr 
										  WHERE dr.ParentFieldId = cte.ParentFieldId AND dr.ChildFieldId = cte.ChildFieldId)'

			EXECUTE (@SQL)

			SET @SQL = 'INSERT INTO DataSourceTableDomainCatalog (DataSourceTableId, DomainCatalog, DomainCatalogSourceId)
			SELECT DISTINCT dt.Id, tld.DomainDescr, tld.DomainCatalogId
			FROM ' + @StageDatabaseName + '..TempListDomainTable tld
			JOIN DataSourceTable dt ON dt.name = tld.LDTableName
			LEFT JOIN DataSourceTableDomainCatalog dtdc ON dtdc.DataSourceTableId = dt.Id 
			AND dtdc.DomainCatalog = tld.DomainDescr
			WHERE dtdc.DataSourceTableId IS NULL AND tld.DomainDescr IS NOT NULL'
			
			EXECUTE (@SQL)
			
			-- Add entry for child tables of LD dummy table into DataSourceFieldMetaData table
			SET @SQL = 'INSERT INTO DataSourceFieldMetaData (FieldId, FieldAppRole)
			SELECT df.Id, 
					CASE WHEN tld.TableType = ''Virtual'' THEN 17920
						 WHEN df.FieldName IS NOT NULL THEN 16896
					END 
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			LEFT JOIN DataSourceTable dt ON tld.TableName = dt.name
			LEFT JOIN DataSourceField df ON tld.ColumnName = df.FieldName
				AND df.TableId = dt.Id
			LEFT JOIN DataSourceFieldMetaData dmd ON df.Id = dmd.FieldId
			WHERE dmd.FieldId IS NULL AND tld.TableName IS NOT NULL
			AND df.Id NOT IN (SELECT FieldId FROM DataSourceFieldMetaData)'

			EXECUTE (@SQL)

			SET @SQL = 'UPDATE DataSourceField 
			SET Description = vc.VirtualColumnComment 
			FROM DataSourceField df 
			JOIN DataSourceTable dt ON dt.Id = df.TableId
			JOIN ' + @StageDatabaseName + '..VirtualColumn_bkp vc ON vc.VirtualColumnName = df.FieldName
			JOIN ' + @StageDatabaseName + '..VirtualTable_bkp vt ON vc.VirtualTableId = vt.Id'

			EXECUTE (@SQL)

			/**************************************************************************************************
													SANITY CHECK
			**************************************************************************************************/

			--------------- Check that all virtual columns in the DataSourceField table exist ---------------------

			SET @SQL = 'SELECT @Result = COUNT(*) FROM DataSourceTable dt
			JOIN DataSourceField df
			ON dt.Id = df.TableId
			WHERE NOT EXISTS (SELECT * FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
								WHERE col.table_name = REPLACE(dt.name, CHAR(32), '''')
								AND col.column_name = df.FieldName)
			AND TableType = 3'

			EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

			IF @flag <> 0
			BEGIN
				SET @SQL = 'SELECT dt.name TableName, 
								   df.FieldName ColumnName, 
								   TableType,
								   dt.Description TableDescription,
								   df.Description ColumnDescription
				FROM DataSourceTable dt
				JOIN DataSourceField df
				ON dt.Id = df.TableId
				WHERE NOT EXISTS (SELECT * FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns col
									WHERE col.table_name = REPLACE(dt.name, CHAR(32), '''')
									AND col.column_name = df.FieldName)
				AND TableType = 3';


				EXECUTE (@SQL);

				SET @ErrorMsg = 'The tables listed is the Results tab are missing from the stage database';
			
				THROW 51001, @ErrorMsg, 1
			END

			--------- Check that an entry exists in DataRelation table for all LD child tables -------------

			SET @SQL = 'SELECT @Result = COUNT(*) 
			FROM DataRelation dr
			JOIN DataSourceField dfp ON dfp.Id = dr.ParentFieldId
			JOIN DataSourceField dfc ON dfc.Id = dr.ChildFieldId
			JOIN DataSourceTable dtp ON dtp.Id = dfp.TableId
			JOIN DataSourceTable dtc ON dtc.Id = dfc.TableId
			RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
			ON tld.TableName = dtc.name AND tld.ColumnName = dfc.FieldName
			WHERE dr.ParentFieldId IS NULL AND tld.TableName IS NOT NULL'

			EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

			IF @flag <> 0
			BEGIN
				SET @SQL = 'SELECT tld.LDTableName ParentTable, 
								   ''Id'' ParentColumn,
								   tld.TableName AS ChildTable, 
								   tld.ColumnName 
				FROM DataRelation dr
				JOIN DataSourceField dfp ON dfp.Id = dr.ParentFieldId
				JOIN DataSourceField dfc ON dfc.Id = dr.ChildFieldId
				JOIN DataSourceTable dtp ON dtp.Id = dfp.TableId
				JOIN DataSourceTable dtc ON dtc.Id = dfc.TableId
				RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
				ON tld.TableName = dtc.name AND tld.ColumnName = dfc.FieldName
				WHERE dr.ParentFieldId IS NULL AND tld.TableName IS NOT NULL'

				EXECUTE (@SQL)

				SET @ErrorMsg = 'There are missing DataRelation table entries for the parent-child tables listed in the Results tab';

				THROW 51001, @ErrorMsg, 1;
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	SET @ErrorMsg = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650104 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 5
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650105', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 5', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			Declare @sql nvarchar(max)

			--Add variable for ExcavationSiteCrackAnomaly Table and ESCATypeDomainId Column
			EXEC sp_CreateVariable 
				'Exacavation_Site_Crack_Anomaly_Type',
				'Exacavation Site Crack_Anomaly Type',
				'Excavation Site Crack Anomaly Details',
				'Excavations', 
				'Lookup',
				null,
				0,
				'ESCATypeDomainId',
				'ExcavationSiteCrackAnomaly'

			--Add variable for ExcavationSiteCrackAnomaly Table and ESCAStatusDomainId Column
			EXEC sp_CreateVariable 
				'Exacavation_Site_Crack_Anomaly_Status',
				'Exacavation Site Crack_Anomaly Status',
				'Excavation Site Crack Anomaly Details',
				'Excavations', 
				'Lookup',
				null,
				0,
				'ESCAStatusDomainId',
				'ExcavationSiteCrackAnomaly'

			UPDATE ImportField 
			  SET VariableId = (SELECT ID FROM Variable WHERE Name = 'Exacavation_Site_Crack_Anomaly_Status')
			  WHERE ColumnDescription = 'ExcavationSiteCrackAnomaly Status';
 
			UPDATE ImportField 
			  SET VariableId = (SELECT ID FROM Variable WHERE Name = 'Exacavation_Site_Crack_Anomaly_Type')
			  WHERE ColumnDescription = 'ExcavationSiteCrackAnomaly Type';

			If object_id('DummyTablesList') is not null
			BEGIN
				SET @sql = 'Drop table DummyTablesList'
				Exec sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650105 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 6
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650106', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 6', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			UPDATE DataSourceTable
			SET TableType = 1
			WHERE TableType = 3;

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650106 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 7
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650107', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 7', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650107 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			
			UPDATE DataSourceTable
			SET TableType = 4
			WHERE name LIKE 'LD[_]%' AND TableType <> 4

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650107 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 8
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650108', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 8', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650108 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add missing tables and columns to the DataSourceTable and DataSourceField tables

			DECLARE @TableName VARCHAR(200)
			DECLARE @ColumnName VARCHAR(200)
			DECLARE @StageTableSchema VARCHAR(200)
			DECLARE @ConfigTableSchema VARCHAR(200)
			DECLARE @StageDatabaseName VARCHAR(200) 
			DECLARE @SQL NVARCHAR(MAX)

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			SET @SQL = 'DECLARE AddMissingTable_Cur CURSOR FOR
			SELECT tld.TableName, 
				   tld.ColumnName,
				   tld.TableSchema, 
				   COALESCE(dss.name, ''dbo'') 
			FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable tld
			LEFT JOIN DatasourceTable dst ON dst.name = tld.TableName
			LEFT JOIN DataSourceField df ON df.TableId = dst.Id
			LEFT JOIN DataSourceSchema dss ON dss.Id = dst.DataSourceSchemaId
			WHERE (COALESCE(dss.name, ''dbo'') <> tld.TableSchema 
			OR dst.name IS NULL OR df.FieldName IS NULL) AND tld.TableSchema IS NOT NULL
			UNION
			SELECT DISTINCT ListDomainTableName,
				   tab.column_name,
				   table_schema,
				   table_schema
			FROM ' + @StageDatabaseName + '.dbo.RememberedListDomainValues rld
			JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab ON tab.table_name = rld.ListDomainTableName
			LEFT JOIN DatasourceTable dst ON dst.name = tab.table_name
			LEFT JOIN DataSourceField df ON df.TableId = dst.Id
			WHERE tab.column_name IN (''Id'', ''Code'', ''Descr'') AND (dst.name IS NULL OR df.FieldName IS NULL)
			UNION
			SELECT DISTINCT ListDomainTableName,
				   tab.column_name,
				   table_schema,
				   table_schema
			FROM ' + @StageDatabaseName + '.dbo.CategoryDataListDomainXRef cld
			JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab ON tab.table_name = cld.ListDomainTableName
			LEFT JOIN DatasourceTable dst ON dst.name = tab.table_name
			LEFT JOIN DataSourceField df ON df.TableId = dst.Id
			WHERE tab.column_name IN (''Id'', ''Code'', ''Descr'') AND (dst.name IS NULL OR df.FieldName IS NULL)
			UNION
			SELECT DISTINCT ListDomainTableName,
				   tab.column_name,
				   table_schema,
				   table_schema
			FROM ' + @StageDatabaseName + '.dbo.ActionItemPropDCXRef aip
			JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab ON tab.table_name = aip.ListDomainTableName
			LEFT JOIN DatasourceTable dst ON dst.name = tab.table_name
			LEFT JOIN DataSourceField df ON df.TableId = dst.Id
			WHERE tab.column_name IN (''Id'', ''Code'', ''Descr'') AND (dst.name IS NULL OR df.FieldName IS NULL)'

			EXECUTE(@SQL)

			OPEN AddMissingTable_Cur
			FETCH NEXT FROM AddMissingTable_Cur INTO @TableName, @ColumnName, @StageTableSchema, @ConfigTableSchema

			WHILE @@FETCH_STATUS = 0
			BEGIN

				-- Add the missing table and schema info to the DataSourceTable. Rename the table if it already exists as a non-virtual table
				IF EXISTS (SELECT * FROM DataSourceTable WHERE name = @TableName AND COALESCE(DataSourceSchemaId, 0) <> COALESCE((SELECT Id FROM DataSourceSchema WHERE name = @StageTableSchema), 0))
				BEGIN

					SET @TableName = @TableName + '_VT'

					-- Rename Table if it already exists in the DataSourceTable table
					SET @SQL = 'IF EXISTS (SELECT * FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.tables WHERE table_name = ''' + REPLACE(@TableName, '_VT', '') + ''' AND table_schema = ''' + @StageTableSchema + ''')
					AND NOT EXISTS (SELECT * FROM ' + @StageDatabaseName + '.INFORMATION_SCHEMA.tables WHERE table_name = ''' + @TableName + ''' AND table_schema = ''' + @StageTableSchema + ''')
					BEGIN
						EXECUTE ' + @StageDatabaseName + '.dbo.sp_rename ''' + @StageTableSchema + '.' + REPLACE(@TableName, '_VT', '') + ''', ''' + REPLACE(@TableName, '_VT', '') + '_VT''
					END

					UPDATE ' + QUOTENAME(@StageDatabaseName) + '.dbo.TempListDomainTable
					SET TableName = ''' + @TableName + '''
					WHERE TableName = ''' + REPLACE(@TableName, '_VT', '') + ''' AND ColumnName = ''' + @ColumnName + '''

					INSERT INTO DataSourceTable (DataSourceId, Name, TableType, DisplayName, DataSourceSchemaId, Description)
					SELECT DISTINCT 1, ''' + @TableName + ''', 1, ''' + @TableName + ''', (SELECT Id FROM DataSourceSchema WHERE name = ''' + @StageTableSchema + '''),
					   CASE WHEN EXISTS (SELECT * FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.TempListDomainTable WHERE TableName = ''' + REPLACE(@TableName, '_VT', '') + '''
										AND ColumnName = ''' + @ColumnName + ''' AND TableType = ''Virtual'') 
											THEN (SELECT VirtualTableComment FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.VirtualTable_BKP WHERE VirtualTableName = ''' + REPLACE(@TableName, '_VT', '') + ''')
						   ELSE NULL
						   END
					WHERE NOT EXISTS (SELECT * FROM DataSourceTable WHERE name = ''' + @TableName  + ''')'

					EXECUTE(@SQL)

				END
				ELSE IF NOT EXISTS (SELECT * FROM DataSourceTable WHERE name = @TableName)
				BEGIN
					SET @SQL = 'INSERT INTO DataSourceTable (DataSourceId, Name, TableType, DisplayName, DataSourceSchemaId, Description)
					SELECT 1, 
						  ''' + @TableName + ''', 
						  1 , 
						  ''' + @TableName + ''', 
						  (SELECT Id FROM DataSourceSchema WHERE name = ''' + @StageTableSchema + '''), 
					   CASE WHEN EXISTS (SELECT * FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.TempListDomainTable WHERE TableName = ''' + REPLACE(@TableName, '_VT', '') + '''
										AND ColumnName = ''' + @ColumnName + ''' AND TableType = ''Virtual'') 
											THEN (SELECT VirtualTableComment FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.VirtualTable_BKP WHERE VirtualTableName = ''' + REPLACE(@TableName, '_VT', '') + ''')
						   ELSE NULL
						   END
					WHERE NOT EXISTS (SELECT * FROM DataSourceTable WHERE name = ''' + @TableName + ''')'
					
					EXECUTE(@SQL)

				END

				-- Add the missing column to the DataSourceField table
				SET @SQL = 'IF EXISTS (SELECT * FROM DataSourceTable dt JOIN DataSourceField df ON dt.Id = df.TableId 
							WHERE dt.name = REPLACE(''' + @TableName + ''', ''_VT'', '''') AND df.FieldName = ''' + @ColumnName + ''' AND 
							COALESCE(DataSourceSchemaId, 0) <> (SELECT COALESCE(Id, 0) FROM DataSourceSchema WHERE name = ''' + @StageTableSchema + ''')
							) AND NOT EXISTS (SELECT * FROM DataSourceTable dt JOIN DataSourceField df ON dt.Id = df.TableId 
							WHERE dt.name = ''' + @TableName + ''' AND df.FieldName = ''' + @ColumnName + ''')
				BEGIN
					UPDATE DataSourceField
					SET TableId = (SELECT Id FROM DataSourceTable WHERE name = ''' + @TableName + ''')
					FROM DataSourceField df
					JOIN DataSourceTable dt ON dt.name = ''' + REPLACE(@TableName, '_VT', '') + '''
					WHERE FieldName = ''' + @ColumnName + '''
				END
				ELSE IF NOT EXISTS (SELECT * FROM DataSourceTable dt JOIN DataSourceField df ON dt.Id = df.TableId 
							WHERE dt.name = ''' + @TableName + ''' AND df.FieldName = ''' + @ColumnName + ''')
				BEGIN
					IF (''' + @TableName + ''' LIKE ''LD[_]%'')
					BEGIN
						INSERT INTO DataSourceField (FieldName, DataTypeId, Description, TableId)
						SELECT ''' + @ColumnName + ''', 
							   CASE WHEN ''' + @ColumnName + ''' = ''Id'' THEN 2
									WHEN ''' + @ColumnName + ''' IN (''Code'', ''Descr'') THEN 1
							   END, 
							   ''' + @ColumnName + ''',
							   (SELECT Id FROM DataSourceTable WHERE name = ''' + @TableName + ''')

					END
					ELSE
					BEGIN
						INSERT INTO DataSourceField (FieldName, DataTypeId, Description, TableId)
						SELECT ''' + @ColumnName + ''', 
							   5, 
							   CASE WHEN TableType = ''Virtual'' THEN (SELECT VirtualColumnComment FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.VirtualColumn_BKP WHERE VirtualColumnName = ''' + @ColumnName + ''')
							   ELSE NULL
							   END,
							   (SELECT Id FROM DataSourceTable WHERE name = ''' + @TableName + ''')
						FROM ' + QUOTENAME(@StageDatabaseName) + '.dbo.TempListDomainTable 
						WHERE TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + '''
					END

				END'
				
				EXECUTE (@SQL)

				FETCH NEXT FROM AddMissingTable_Cur INTO @TableName, @ColumnName, @StageTableSchema, @ConfigTableSchema
			END

			CLOSE AddMissingTable_Cur
			DEALLOCATE AddMissingTable_Cur

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650108 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 9
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650109', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 9', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650109 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Update the variables that are HCA Reason to be Lookups.
			UPDATE Variable SET DataTypeId = (select Id from DataType where Name = 'Lookup') WHERE DataTypeId = (select Id from DataType where Name = 'HcaReason');
			-- Update the data source fields that are HCA Reason to be Lookups.
			UPDATE DataSourceField SET DataTypeId = (select Id from DataType where Name = 'Lookup') WHERE DataTypeId = (select Id from DataType where Name = 'HcaReason');

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650109 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 10
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650110', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 10', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650110 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- sp_CreateVariableForDE.sql
			declare @sql nvarchar(max)

			SET @sql = 'Alter PROC [dbo].[sp_CreateVariable] 
					@TableName                NVARCHAR(30),
					@ColumnName               NVARCHAR(30),
					@DataType                 VARCHAR(50),
					@DataLength               NUMERIC(10, 0),
					@DataPrecision            NUMERIC(10, 0),
					@VariableName             NVARCHAR(100),
					@DisplayText              NVARCHAR(max),
					@Units                    NVARCHAR(30),
					@VariableGroup            NVARCHAR(30),
					@VariableGroupId          NUMERIC(10, 0),
					@DecimalCount             NUMERIC(10, 0),
					@VariableCategory         NVARCHAR(50),
					@VariableCategoryId       NUMERIC(10, 0),
					@VariableParentCategory   NVARCHAR(30),
					@VariableParentCategoryId NUMERIC(10, 0),
					@TableType                NVARCHAR(30),
					@TableTypeId              NUMERIC(10, 0),
					@LoadMetaData             NVARCHAR(1),
					@StageDatabase			  NVARCHAR(500),
					@sql1		              NVARCHAR(max),
					@sql2		              NVARCHAR(max),
					@Length                   NVARCHAR(30),
					@Precision                NVARCHAR(30)
		
			AS

			SET @sql1 = N''
				SELECT @Length = CHARACTER_MAXIMUM_LENGTH
				FROM '' + QUOTENAME(@StageDatabase) + ''.INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName'';

				EXEC sp_executesql @sql1

				SET @sql2 = N''
				SELECT @Precision = NUMERIC_SCALE
				FROM '' + QUOTENAME(@StageDatabase) + ''.INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName'';

				EXEC sp_executesql @sql2
	
			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.DataSourceTable
					 WHERE  NAME = @TableName ) AND
			   @TableName IS NOT NULL BEGIN
				  INSERT INTO dbo.DataSourceTable
							  (DataSourceId,
							   NAME,
							   Description,
							   TableType, 
							   DisplayName,
							   DataSourceSchemaId)
				  VALUES      ( 1,
								@TableName,
								@TableName,
							   (Select id from TableType where Name = @TableType ),
								@TableName,
								(Select id from DataSourceSchema))

				  PRINT N''Created DataSourceTable '' + @TableName
			  END

			IF NOT EXISTS
				   ( SELECT *
					 FROM   dbo.DataSourceField
					 WHERE  FieldName = @ColumnName AND
							TableId IN
							( SELECT Id
							  FROM   dbo.DataSourceTable
							  WHERE  NAME = @TableName ) ) AND
			   @ColumnName IS NOT NULL BEGIN
				  INSERT INTO dbo.DataSourceField
							  (FieldName,
							   DataTypeId,
							   Description,
							   TableId)
				  VALUES      ( @ColumnName,
							   (SELECT id FROM dbo.DataType WHERE Name = @DataType),
								NULL,
								( SELECT TOP 1 Id
								  FROM   dbo.DataSourceTable
								  WHERE  NAME = @TableName ) 
				  )

				  PRINT N''Created DataSourceField '' + @ColumnName
			  END

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.DataSourceFieldMetaData
					 WHERE  FieldId IN
							( SELECT Id
							  FROM   dbo.DataSourceField
							  WHERE  FieldName = @ColumnName AND
									 TableId IN
									 ( SELECT Id
									   FROM   dbo.DataSourceTable
									   WHERE  NAME = @TableName ) ) ) BEGIN
				  INSERT INTO dbo.DataSourceFieldMetaData
							  (FieldId,
							   UnitId,
							   Length,
							   PRECISION,
							   MaxValue,
							   MinValue,
							   FieldAppRole)
				  VALUES      ( ( SELECT Id
								  FROM   dbo.DataSourceField
								  WHERE  FieldName = @ColumnName AND
										 TableId IN
										 ( SELECT Id
										   FROM   dbo.DataSourceTable
										   WHERE  NAME = @TableName ) ),
								CASE
								  WHEN @Units IS NULL AND
									   (SELECT ID FROM dbo.DataType where Name = @DataType) =
									   ( SELECT Id
										 FROM   dbo.DataType dt
										 WHERE  NAME = ''Number'' ) THEN ( SELECT Id
																		 FROM   dbo.UnitOfMeasure
																		 WHERE  Code = ''Unitless'' )
								  WHEN @Units IS NULL AND
									   (SELECT ID FROM dbo.DataType where Name = @DataType) =
									   ( SELECT Id
										 FROM   dbo.DataType dt
										 WHERE  NAME = ''Number'' ) THEN ( SELECT Id
																		 FROM   dbo.UnitOfMeasure
																		 WHERE  Code = ''Unitless'' )
								  ELSE ( SELECT Id
										 FROM   dbo.UnitOfMeasure
										 WHERE  Code = @Units )
								END,
								@Length ,
								@Precision, 
								NULL,
								NULL,
								CASE
								  WHEN ''Linear'' = ''Virtual'' THEN 1024
								  WHEN ''Sulphur'' = ''StationSeriesId'' THEN 2
								  WHEN ''Sulphur'' = ''BeginStationSeriesId'' THEN 2
								  WHEN ''Sulphur'' = ''EndStationSeriesId'' THEN 8
								  WHEN ''Sulphur'' = ''StationNum'' THEN 4
								  WHEN ''Sulphur'' = ''BeginStationNum'' THEN 4
								  WHEN ''Sulphur'' = ''EndStationNum'' THEN 16
								  ELSE 0
								END 
				  )

				  PRINT N''Created DataSourceFieldMetaData ''
						+ @ColumnName
			  END

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.VariableGroup
					 WHERE  NAME = @VariableGroup ) AND
			   @VariableGroup IS NOT NULL BEGIN
				  INSERT INTO dbo.VariableGroup
							  (NAME,
							   Description)
				  VALUES      ( @VariableGroup,
								@VariableGroup 
				  )

				  PRINT N''Inserted new group '' + @VariableGroup
			  END

			SET @VariableGroupId = ( SELECT Id
									 FROM   VariableGroup
									 WHERE  NAME = @VariableGroup )

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.VariableCategory
					 WHERE  NAME = @VariableParentCategory ) AND
			   @VariableParentCategory IS NOT NULL BEGIN
				  INSERT INTO dbo.VariableCategory
							  (NAME,
							   Description,
							   ParentCategoryId)
				  VALUES      ( @VariableParentCategory,
								@VariableParentCategory,
								NULL 
				  )

				  PRINT N''Inserted new parent category ''
						+ @VariableParentCategory
			  END

			SET @VariableParentCategoryId = ( SELECT Id
											  FROM   VariableCategory
											  WHERE  NAME = @VariableParentCategory )

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.VariableCategory
					 WHERE  NAME = @VariableCategory ) AND
			   @VariableCategory IS NOT NULL BEGIN
				  INSERT INTO dbo.VariableCategory
							  (NAME,
							   Description,
							   ParentCategoryId)
				  VALUES      ( @VariableCategory,
								@VariableCategory,
								@VariableParentCategoryId 
				  )

				  PRINT N''Inserted new category ''
						+ @VariableCategory
			  END

			IF EXISTS 
			   ( SELECT Id
				 FROM   dbo.VariableCategory
				 WHERE  NAME = @VariableCategory ) AND
			   @VariableParentCategory IS NOT NULL BEGIN
				  UPDATE dbo.VariableCategory
				  SET    ParentCategoryId = @VariableParentCategoryId
				  WHERE  NAME = @VariableCategory

				  PRINT N''Updated category '' + @VariableCategory
			  END

			SET @VariableCategoryId = ( SELECT Id
										FROM   VariableCategory
										WHERE  NAME = @VariableCategory )

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.Variable
					 WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) ) AND
			   @VariableName IS NOT NULL BEGIN
				  INSERT INTO dbo.Variable
							  (CategoryId,
							   NAME,
							   DisplayText,
							   DataTypeId,
							   Description,
							   GroupId)
				  VALUES      ( @VariableCategoryId,
								Replace( @VariableName, '' '', ''_'' ),
								@VariableName,
							   (SELECT id FROM dbo.DataType WHERE Name = @DataType),
								NULL,
								@VariableGroupId 
				  )

				  PRINT N''Inserted new variable '' + @VariableName
			  END

			ELSE BEGIN 
				UPDATE dbo.Variable
				SET    CategoryId = @VariableCategoryId,
					   DataTypeId = (SELECT id FROM dbo.DataType WHERE Name = @DataType),
					   GroupId = @VariableGroupId
				WHERE  NAME = Replace( @VariableName, '' '', ''_'' )

				PRINT N''Updated variable '' + @VariableName
			END

			IF NOT EXISTS
				   ( SELECT *
					 FROM   dbo.VariableMetadata
					 WHERE  VariableId IN
							( SELECT Id
							  FROM   dbo.Variable
							  WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) ) AND
							( UnitCodeId =
							  ( SELECT Id
								FROM   dbo.UnitOfMeasure
								WHERE  Code = ( CASE
												  WHEN @Units IS NULL AND
													   (SELECT ID FROM dbo.DataType where Name = @DataType) =
													   ( SELECT Id
														 FROM   DataType
														 WHERE  NAME IN ( ''Number'' ) ) THEN ''Unitless''
												  WHEN @Units IS NULL AND
													   (SELECT ID FROM dbo.DataType where Name = @DataType) =
													   ( SELECT Id
														 FROM   DataType
														 WHERE  NAME IN ( ''Number'' ) ) THEN ''Unitless''
												  ELSE NULL
												END ) )  OR
							  UnitCodeId IS NULL ) ) AND
			   ( @LoadMetaData = ''Y''  OR
				 @LoadMetaData IS NULL ) BEGIN
				  INSERT INTO dbo.VariableMetadata
							  (VariableId,
							   UnitCodeId,
							   DecimalPlaceCount,
							   MinValue,
							   MaxValue)
				  VALUES      ( ( SELECT Id
								  FROM   dbo.Variable
								  WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) ),
								CASE
								  WHEN @Units IS NULL AND
									   (SELECT ID FROM dbo.DataType where Name = @DataType) = 
									   ( SELECT Id
										 FROM   DataType
										 WHERE  NAME IN ( ''Number'' ) ) THEN ( SELECT Id
																			  FROM   dbo.UnitOfMeasure
																			  WHERE  Code = ''Unitless'' )
								  WHEN @Units IS NULL AND
									  (SELECT ID FROM dbo.DataType where Name = @DataType) =
									   ( SELECT Id
										 FROM   DataType
										 WHERE  NAME IN ( ''Number'' ) ) THEN ( SELECT Id
																			  FROM   dbo.UnitOfMeasure
																			  WHERE  Code = ''Unitless'' )
								  ELSE ( SELECT Id
										 FROM   dbo.UnitOfMeasure
										 WHERE  Code = NULL )
								END,
								CASE
									WHEN @DecimalCount IS NULL AND ((SELECT ID FROM dbo.DataType where Name = @DataType) =
											( SELECT Id
											FROM   DataType
											WHERE  NAME IN ( ''Number'' ) ) OR (SELECT ID FROM dbo.DataType where Name = @DataType) =
											( SELECT Id
											FROM   DataType
											WHERE  NAME IN ( ''Number'' ) ) ) THEN 2
									WHEN @DecimalCount IS NULL AND ((SELECT ID FROM dbo.DataType where Name = @DataType) <>
											( SELECT Id
											FROM   DataType
											WHERE  NAME IN ( ''Number'' ) ) OR (SELECT ID FROM dbo.DataType where Name = @DataType)  <>
											( SELECT Id
											FROM   DataType
											WHERE  NAME IN ( ''Number'' ) ) ) THEN 0
									ELSE @DecimalCount
								END,
								NULL,
								NULL 
				  )

				  PRINT N''Inserted new VariableMetadata''
			  END

			ELSE BEGIN 
				UPDATE dbo.VariableMetadata
				SET    DecimalPlaceCount = CASE
												WHEN @DecimalCount IS NULL AND ((SELECT ID FROM dbo.DataType where Name = @DataType) =
														( SELECT Id
														FROM   DataType
														WHERE  NAME IN ( ''Number'' ) ) OR (SELECT ID FROM dbo.DataType where Name = @DataType) =
														( SELECT Id
														FROM   DataType
														WHERE  NAME IN ( ''Number'' ) ) ) THEN 2
												WHEN @DecimalCount IS NULL AND ((SELECT ID FROM dbo.DataType where Name = @DataType) <>
														( SELECT Id
														FROM   DataType
														WHERE  NAME IN ( ''Number'' ) ) OR (SELECT ID FROM dbo.DataType where Name = @DataType) <>
														( SELECT Id
														FROM   DataType
														WHERE  NAME IN ( ''Number'' ) ) ) THEN 0
												ELSE @DecimalCount
										   END
				WHERE  VariableId =
					   ( SELECT Id
						 FROM   dbo.Variable
						 WHERE  NAME = Replace( @DecimalCount, '' '', ''_'' ) ) AND
					   UnitCodeId =
					   ( SELECT Id
						 FROM   dbo.UnitOfMeasure
						 WHERE  Code = @Units )

				PRINT N''Updated VariableMetadata''
			END

			IF NOT EXISTS
				   ( SELECT Id
					 FROM   dbo.VariableFieldXRef
					 WHERE  VariableId IN
							( SELECT Id
							  FROM   dbo.Variable
							  WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) ) ) BEGIN
				  INSERT INTO dbo.VariableFieldXRef
							  (VariableId,
							   DataSourceFieldId,
							   DataSourceId)
				  VALUES      ( ( SELECT Id
								  FROM   dbo.Variable
								  WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) ),
								( SELECT Id
								  FROM   dbo.DataSourceField
								  WHERE  TableId IN
										 ( SELECT Id
										   FROM   dbo.DataSourceTable
										   WHERE  NAME = @TableName ) AND
										 FieldName = @ColumnName ),
								1 
				  )

				  PRINT N''Inserted new VariableFieldXRef''
			  END

			ELSE BEGIN
				UPDATE dbo.VariableFieldXRef
				SET    DataSourceFieldId = ( SELECT Id
											 FROM   dbo.DataSourceField
											 WHERE  TableId IN
													( SELECT Id
													  FROM   dbo.DataSourceTable
													  WHERE  NAME = @TableName ) AND
													FieldName = @ColumnName )
				WHERE  VariableId =
					   ( SELECT Id
						 FROM   dbo.Variable
						 WHERE  NAME = Replace( @VariableName, '' '', ''_'' ) )

				PRINT N''Update VariableFieldXRef''
			END

			IF EXISTS 
			   ( SELECT d.Id
				 FROM   dbo.DataSourceField d
						INNER JOIN dbo.DataSourceTable t
								ON d.TableId = t.Id
				 WHERE  d.FieldName = @ColumnName AND
						t.NAME = @TableName ) BEGIN
				  UPDATE dbo.DataSourceField
				  SET    DataTypeId = CASE WHEN
									  (SELECT id FROM dbo.DataType WHERE Name = @DataType) IS NULL THEN (SELECT id FROM dbo.DataType WHERE Name = @DataType)
									  ELSE (SELECT id FROM dbo.DataType WHERE Name = @DataType)
									  END
						  
                          
				  WHERE  Id =
						 ( SELECT Id
						   FROM   dbo.DataSourceField
						   WHERE  TableId IN
								  ( SELECT Id
									FROM   dbo.DataSourceTable
									WHERE  NAME = @TableName) AND
								  FieldName = @ColumnName )

				  PRINT N''Updated DataSourceField DataType''
			  END'

			Exec sp_executesql @sql


			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650110 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 1 Updates 11
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650111', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 1, Updates 11', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


/*
	Everything below this should remain at the end of this script. Any added code should be placed above
	this section and the @FinalDBVersion variable should be changed to the last DBVersion within this script
*/
BEGIN
	DECLARE @FinalDBVersion INT 
	DECLARE @DBVersion INT 
	DECLARE @CheckPoint INT
	DECLARE @ErrorMsg NVARCHAR(600)

	SET @FinalDBVersion = 650111

	SELECT @DBVersion = DBVersion, @CheckPoint = DBVersionCheckPoint
	FROM Versioninfo

	IF EXISTS (SELECT * FROM dbo.VersionInfo WHERE DBVersion BETWEEN 650006 AND @FinalDBVersion)
		AND @DBVersion <> @FinalDBVersion AND @CheckPoint <> 0
	BEGIN

		SET @ErrorMsg = 'The database upgrade did not complete. The database is currently at DBVersion ' 
		+ CAST(@DBVersion AS NVARCHAR) + ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR);
		
		THROW 51001, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		PRINT 'This database is currently at DBVersion ' + CAST(@DBVersion AS NVARCHAR) 
		+ ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR) + '.'
		+ CHAR(10) + 'This script upgrades IRAS databases from DBVersion 650006 to ' + CAST(@FinalDBVersion AS NVARCHAR);	
	END
END
GO