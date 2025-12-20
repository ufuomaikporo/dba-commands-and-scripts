
BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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

			-- Create the new table for the action item revision.
			IF NOT EXISTS (select 1
						from  sysobjects
					   where  id = object_id('ActionItemRevision')
						and   type = 'U')
			BEGIN

			  -- create table 
			  EXECUTE sp_executesql N'
			  CREATE TABLE [dbo].[ActionItemRevision](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[ActionItemId] [numeric](18, 0) NOT NULL,
				[Revision] [numeric](18, 0) NOT NULL,
				[CategoryListDomainId] [numeric](10, 0) NOT NULL, 
				[StatusListDomainId] [numeric](10, 0) NOT NULL,
				[AssignedTo] [varchar](255) NULL,
				[DueDate] [datetime] NULL,
				[Reason] [varchar](4000) NULL,
				[ThreatConsequence] [varchar](255) NULL,
				[ActionPerformed] [varchar](4000) NULL,
				[CompletionDate] [datetime] NULL,
				[EffectiveEndDate] [datetime] NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
			 CONSTRAINT [PK_ActionItemRevision] PRIMARY KEY CLUSTERED 
			  (
				[Id] ASC
			  )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			  ) ON [PRIMARY]
			  '

			  -- add trigger
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemRevision]  WITH CHECK ADD  CONSTRAINT [FK_ActionItemRev_ActionItem] FOREIGN KEY([ActionItemId])
			  REFERENCES [dbo].[ActionItem] ([Id])
			  ') 
  
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemRevision] CHECK CONSTRAINT [FK_ActionItemRev_ActionItem]
			  ') 
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItemRevision')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItemRevision]'
	
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemRevision] ON [dbo].[ActionItemRevision] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemRevision
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemRevision as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql

			-- Create the new table for the action item comments.
			IF NOT EXISTS (select 1
						from  sysobjects
					   where  id = object_id('ActionItemComments')
						and   type = 'U')
			BEGIN

			  -- create table
			  EXEC ('
			  CREATE TABLE [dbo].[ActionItemComments](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[ActionItemId] [numeric](18, 0) NOT NULL,
				[Comments] [varchar](4000) NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
			 CONSTRAINT [PK_ActionItemComments] PRIMARY KEY CLUSTERED 
			  (
				[Id] ASC
			  )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			  ) ON [PRIMARY]
			  ')

			  -- add trigger
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemComments]  WITH CHECK ADD  CONSTRAINT [FK_ActionItemCommt_ActionItem] FOREIGN KEY([ActionItemId])
			  REFERENCES [dbo].[ActionItem] ([Id])
			  ') 
  
			  EXEC ('
			  ALTER TABLE [dbo].[ActionItemComments] CHECK CONSTRAINT [FK_ActionItemCommt_ActionItem]
			  ') 
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItemComments')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItemComments]'
	
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemComments] ON [dbo].[ActionItemComments] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemComments
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemComments as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql	

			-- ActionItemAPITables.sql

			-- Create the new tables for the action item API.
			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('ActionItemProperty')
						   AND type = 'U') 
			BEGIN
				-- The table below is not in KEY_IRASV5_UPSTREAM
			  EXECUTE sp_executesql N'
			  CREATE TABLE [dbo].[ActionItemProperty](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[Name] [varchar](255) NOT NULL,
				[DisplayName] [varchar](255) NOT NULL,
				[PropertyType] [numeric](3, 0) NOT NULL,
				[IsRequired] [numeric](1, 0) NULL,
				[IsReadOnly] [numeric](1, 0) NULL,
				[EffectiveEndDate] [datetime] NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
				CONSTRAINT [PK_ActionItemProperty] PRIMARY KEY CLUSTERED 
				(
					[Id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
				CONSTRAINT [UQ_ActionItemProperty_Name] UNIQUE(Name)
				) ON [PRIMARY]
			  '
			END
			ELSE IF NOT EXISTS (SELECT * FROM ActionItemProperty)
			BEGIN
				EXECUTE ('DROP TABLE ActionItemProperty')

				EXECUTE sp_executesql N'
			  CREATE TABLE [dbo].[ActionItemProperty](
				[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
				[Name] [varchar](255) NOT NULL,
				[DisplayName] [varchar](255) NOT NULL,
				[PropertyType] [numeric](3, 0) NOT NULL,
				[IsRequired] [numeric](1, 0) NULL,
				[IsReadOnly] [numeric](1, 0) NULL,
				[EffectiveEndDate] [datetime] NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
				CONSTRAINT [PK_ActionItemProperty] PRIMARY KEY CLUSTERED 
				(
					[Id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
				CONSTRAINT [UQ_ActionItemProperty_Name] UNIQUE(Name)
				) ON [PRIMARY]
			  '
			END

			SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''TR'' and name = ''tu_ActionItemProperty'')
						BEGIN
							DROP TRIGGER [dbo].[tu_ActionItemProperty]
						END'
						
			EXEC sp_executesql @sql


			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemProperty] ON [dbo].[ActionItemProperty] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemProperty
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemProperty as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('ActionItemPropertyValue')
						   AND type = 'U')
			BEGIN
				-- The table below is not in KEY_IRASV5_UPSTREAM
			  EXECUTE ('
			  CREATE TABLE [dbo].[ActionItemPropertyValue](
				[ActionItemRevisionId] [numeric](18, 0) NOT NULL,
				[ActionItemPropertyId] [numeric](18, 0) NOT NULL,
				[PropertyValue] [varchar](4000) NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
				CONSTRAINT [PK_ActionItemPropertyValue] PRIMARY KEY CLUSTERED 
				(
					[ActionItemRevisionId] ASC,
					[ActionItemPropertyId] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
				CONSTRAINT [FK_AtnItmPrpValue_ActnItmRvsn] FOREIGN KEY([ActionItemRevisionId]) REFERENCES [dbo].[ActionItemRevision] ([Id]),
				CONSTRAINT [FK_AtnItmPrpValue_ActnItmPrp] FOREIGN KEY([ActionItemPropertyId]) REFERENCES [dbo].[ActionItemProperty] ([Id])
				) ON [PRIMARY]
			  ')
			END

			SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''TR'' and name = ''tu_ActionItemPropertyValue'')
						BEGIN
							DROP TRIGGER [dbo].[tu_ActionItemPropertyValue]
						END'

			EXEC sp_executesql @sql

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemPropertyValue] ON [dbo].[ActionItemPropertyValue] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemPropertyValue
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemPropertyValue as t, DELETED as d
							WHERE t.ActionItemRevisionId=d.ActionItemRevisionId
							AND t.ActionItemPropertyId=d.ActionItemPropertyId;
						END'

			EXEC sp_executesql @sql

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('ActionItemPropDCXRef')
						   AND type = 'U')
			BEGIN
				--The table below is not in KEY_IRASV5_UPSTREAM
			  EXEC ('
			  CREATE TABLE [dbo].[ActionItemPropDCXRef](
				[ActionItemPropertyId] [numeric](18, 0) NOT NULL,
				[DomainCatalogId] [numeric](7, 0) NOT NULL,
				[CreateByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[CreateDate] [datetime] NOT NULL DEFAULT GETDATE(),
				[LastModByUserId] [varchar](64) NOT NULL DEFAULT SUSER_SNAME(),
				[LastModDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
				CONSTRAINT [PK_ActionItemPropDCXRef] PRIMARY KEY CLUSTERED 
				(
					[ActionItemPropertyId] ASC,
					[DomainCatalogId] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
				CONSTRAINT [FK_AtnItmPropDCXRef_DmnCtlg] FOREIGN KEY([DomainCatalogId]) REFERENCES [dbo].[DomainCatalog] ([Id]),
				CONSTRAINT [FK_AtnItmPropDCXRef_AtnItmPrp] FOREIGN KEY([ActionItemPropertyId]) REFERENCES [dbo].[ActionItemProperty] ([Id])
				) ON [PRIMARY]
			  ')
			END

			SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''TR'' and name = ''tu_ActionItemPropDCXRef'')
						BEGIN
							DROP TRIGGER [dbo].[tu_ActionItemPropDCXRef]
						END'

			EXEC sp_executesql @sql

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemPropDCXRef] ON [dbo].[ActionItemPropDCXRef] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemPropDCXRef
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemPropDCXRef as t, DELETED as d
							WHERE t.DomainCatalogId=d.DomainCatalogId
							AND t.ActionItemPropertyId=d.ActionItemPropertyId;
						END'

			EXEC sp_executesql @sql

			-- Setup the custom action item properties.
			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'CategoryLd', 'Category', 5
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'CategoryLd');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'StatusLd', 'Status', 5
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'StatusLd');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'AssignedTo', 'Assigned  To', 0
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'AssignedTo');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'Reason', 'Reason', 1
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'Reason');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'ThreatConsequence', 'Threat/Consequence', 0
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'ThreatConsequence');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'ActionPerformed', 'Action Performed', 1
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'ActionPerformed');

			INSERT INTO [ActionItemProperty]
			([Name], [DisplayName], [PropertyType])
			SELECT 'ProjectRunDate', 'Project Run Date', 2
			WHERE NOT EXISTS (SELECT 1 FROM [ActionItemProperty] WHERE Name = 'ProjectRunDate');

			-- Temporary add the obsolete columns in the previous version to allow this script to run multiple time. 
			IF NOT EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'ActionItemRevision'
								  AND COLUMN_NAME = 'CategoryListDomainId'
								  AND TABLE_SCHEMA='DBO')
			  BEGIN
				  ALTER TABLE ActionItemRevision
				  ADD CategoryListDomainId NUMERIC(18, 0);
			  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItemRevision'
									  AND COLUMN_NAME = 'StatusListDomainId'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItemRevision
					  ADD StatusListDomainId NUMERIC(18, 0);
				  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItemRevision'
									  AND COLUMN_NAME = 'AssignedTo'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItemRevision
					  ADD AssignedTo VARCHAR(1);
				  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItemRevision'
									  AND COLUMN_NAME = 'Reason'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItemRevision
					  ADD Reason VARCHAR(1);
				  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItemRevision'
									  AND COLUMN_NAME = 'ThreatConsequence'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItemRevision
					  ADD ThreatConsequence VARCHAR(1);
				  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItemRevision'
									  AND COLUMN_NAME = 'ActionPerformed'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItemRevision
					  ADD ActionPerformed VARCHAR(1);
				  END

				IF NOT EXISTS (SELECT 1
							   FROM   INFORMATION_SCHEMA.COLUMNS
							   WHERE  TABLE_NAME = 'ActionItem'
									  AND COLUMN_NAME = 'ProjectRunDate'
									  AND TABLE_SCHEMA='DBO')
				  BEGIN
					  ALTER TABLE ActionItem
					  ADD ProjectRunDate DATETIME;
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Migrate the existing data to the new tables.
			DECLARE @PropertyId AS numeric(18, 0);
			DECLARE @sql nvarchar(max)

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'CategoryListDomainId')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'CategoryLd');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
							(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
							SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', CategoryListDomainId
							FROM ActionItemRevision
							WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' 
							+ cast(@PropertyId AS varchar(30)) + ');'

				EXEC sp_executesql @sql	
			END

			SET @sql = 'INSERT INTO ActionItemPropDCXRef
						(ActionItemPropertyId, DomainCatalogId)
						SELECT ' + cast(@PropertyId AS varchar(30)) + ', dc.Id
						FROM DomainCatalog dc
						WHERE dc.DomainDescr = ''Action Item Category''
						AND NOT EXISTS (SELECT 1 FROM ActionItemPropDCXRef WHERE ActionItemPropertyId = ' 
						+ cast(@PropertyId AS varchar(30)) + ');'
			
			EXEC sp_executesql @sql	

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'StatusListDomainId')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'StatusLd');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', StatusListDomainId
				FROM ActionItemRevision
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'

				EXEC sp_executesql @sql	
			END

			SET @sql = 'INSERT INTO ActionItemPropDCXRef
			(ActionItemPropertyId, DomainCatalogId)
			SELECT ' + cast(@PropertyId AS varchar(30)) + ', dc.Id
			FROM DomainCatalog dc
			WHERE dc.DomainDescr = ''Action Item Status''
			AND NOT EXISTS (SELECT 1 FROM ActionItemPropDCXRef WHERE ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'			
			
			EXEC sp_executesql @sql	
			
			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'AssignedTo')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'AssignedTo');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', AssignedTo
				FROM ActionItemRevision
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'
				
				EXEC sp_executesql @sql	
			END

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'Reason')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'Reason');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', Reason
				FROM ActionItemRevision
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'

				EXEC sp_executesql @sql	
			END

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'ThreatConsequence')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'ThreatConsequence');
				
				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', ThreatConsequence
				FROM ActionItemRevision
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'

				EXEC sp_executesql @sql	
			END

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'ActionPerformed')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'ActionPerformed');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT Id, ' + cast(@PropertyId AS varchar(30)) + ', ActionPerformed
				FROM ActionItemRevision
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');'
				
				EXEC sp_executesql @sql	
			END

			IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE table_name = 'ActionItemProperty'
				AND column_name = 'ProjectRunDate')
			BEGIN
				SET @PropertyId = (SELECT Id FROM ActionItemProperty WHERE Name = 'ProjectRunDate');

				SET @sql = 'INSERT INTO ActionItemPropertyValue
				(ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
				SELECT ar.Id, ' + cast(@PropertyId AS varchar(30)) + ', a.ProjectRunDate
				FROM ActionItemRevision ar
				INNER JOIN ActionItem a
				ON ar.ActionItemId = a.Id
				WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = ar.Id AND ActionItemPropertyId = ' + cast(@PropertyId AS varchar(30)) + ');' 
				
				EXEC sp_executesql @sql
			END

			DECLARE @constraint VARCHAR(100)

			-- Drop the obsolete columns.
			IF EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'ActionItem'
								  AND COLUMN_NAME = 'ProjectRunDate'
								AND TABLE_SCHEMA='DBO')
			BEGIN
				ALTER TABLE ActionItem
				DROP COLUMN ProjectRunDate;
			END

			IF EXISTS (SELECT 1
			 			   FROM   INFORMATION_SCHEMA.COLUMNS
			 			   WHERE  TABLE_NAME = 'ActionItemRevision'
			 					  AND COLUMN_NAME = 'CategoryListDomainId'
								AND TABLE_SCHEMA='DBO')
			BEGIN
				IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'CategoryListDomainId')

				BEGIN
					SELECT @constraint = constraint_name
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'CategoryListDomainId'

					SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
					EXECUTE SP_EXECUTESQL @sql 
				END
				

				ALTER TABLE ActionItemRevision
				DROP COLUMN CategoryListDomainId;
			END

			IF EXISTS (SELECT 1
							FROM   INFORMATION_SCHEMA.COLUMNS
							WHERE  TABLE_NAME = 'ActionItemRevision'
									AND COLUMN_NAME = 'StatusListDomainId'
									AND TABLE_SCHEMA='DBO')
			BEGIN
				IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'StatusListDomainId')

				BEGIN
					SELECT @constraint = constraint_name
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'StatusListDomainId'

					SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
					EXECUTE SP_EXECUTESQL @sql 
				END

				ALTER TABLE ActionItemRevision
				DROP COLUMN StatusListDomainId;
			END

			IF EXISTS (SELECT 1
							FROM   INFORMATION_SCHEMA.COLUMNS
							WHERE  TABLE_NAME = 'ActionItemRevision'
									AND COLUMN_NAME = 'AssignedTo'
									AND TABLE_SCHEMA='DBO')
			BEGIN
				IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'AssignedTo')
				BEGIN
					SELECT @constraint = constraint_name
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'AssignedTo'

					SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
					EXECUTE SP_EXECUTESQL @sql 
				END

				ALTER TABLE ActionItemRevision
				DROP COLUMN AssignedTo;
			END

			IF EXISTS (SELECT 1
							FROM   INFORMATION_SCHEMA.COLUMNS
							WHERE  TABLE_NAME = 'ActionItemRevision'
									AND COLUMN_NAME = 'Reason'
									AND TABLE_SCHEMA='DBO')
			BEGIN
				IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'Reason')
				BEGIN
					SELECT @constraint = constraint_name
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'Reason'

					SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
					EXECUTE SP_EXECUTESQL @sql 
				END

				ALTER TABLE ActionItemRevision
				DROP COLUMN Reason;
			END

				IF EXISTS (SELECT 1
								FROM   INFORMATION_SCHEMA.COLUMNS
								WHERE  TABLE_NAME = 'ActionItemRevision'
										AND COLUMN_NAME = 'ThreatConsequence'
										AND TABLE_SCHEMA='DBO')
				BEGIN
					IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'ThreatConsequence')

					BEGIN
						SELECT @constraint = constraint_name
						FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
						WHERE TABLE_NAME= 'ActionItemRevision'
						AND column_name = 'ThreatConsequence'

						SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
						EXECUTE SP_EXECUTESQL @sql 
					END

					ALTER TABLE ActionItemRevision
					DROP COLUMN ThreatConsequence;
				END

				IF EXISTS (SELECT 1
								FROM   INFORMATION_SCHEMA.COLUMNS
								WHERE  TABLE_NAME = 'ActionItemRevision'
										AND COLUMN_NAME = 'ActionPerformed'
										AND TABLE_SCHEMA='DBO')
				BEGIN
					IF EXISTS (SELECT 1
					FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
					WHERE TABLE_NAME= 'ActionItemRevision'
					AND column_name = 'ActionPerformed')

					BEGIN
						SELECT @constraint = constraint_name
						FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
						WHERE TABLE_NAME= 'ActionItemRevision'
						AND column_name = 'ActionPerformed'

						SET @sql = 'ALTER TABLE ActionItemRevision DROP CONSTRAINT ' + @constraint
						EXECUTE SP_EXECUTESQL @sql 
					END

					ALTER TABLE ActionItemRevision
					DROP COLUMN ActionPerformed;
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- C8TRIGGERS_SCRIPTS.sql
			--DECLARE VARIABLES
			DECLARE @MyTableName VARCHAR(128)
			DECLARE @C8Trigger VARCHAR(2000)

			-- CREATING A TRIGGER FOR TABLES WITHOUT

			DECLARE CursorTRIGGER CURSOR  FOR SELECT NAME FROM SYS.TABLES
			--THE TABLES EXCLUDED ARE TEMPORARY TABLES AND DOESNT HAVE A PRIMARY OR UNIQUE KEY TO CREATE TRIGGER ON
			WHERE NAME NOT IN ('CPRange','IDAllocation','CrossingLocnMay8','tmpVirtualTableStationing','RiskResultsRawData','RiskResultsRawData1','TESTDATA1','Joint2010','Joint','MetricfullsystemDefaultSu','foreignkeys','primarykeys')
			AND NAME NOT LIKE 'Load%'
			AND NAME NOT IN (SELECT t.NAME AS TableName
			FROM SYS.TRIGGERS tr
			INNER JOIN sys.tables t ON t.object_id=tr.parent_id
			) AND Name IN (SELECT DISTINCT c.Table_Name FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'LastModByUserId' AND c.column_name = 'LastModDateTime')

			OPEN CursorTRIGGER

				FETCH NEXT FROM CursorTRIGGER INTO @MyTableName 
				WHILE @@FETCH_STATUS=0
				BEGIN  
					SET @C8Trigger='CREATE TRIGGER dbo.tu_' +(@MyTableName)+ ' ON dbo.'+(@MyTableName)+
					' FOR UPDATE AS'+CHAR(13)+ 'IF EXISTS(SELECT * FROM DELETED)'+CHAR(13)+'BEGIN'+CHAR(13)+'	UPDATE dbo.'+(@MyTableName)+CHAR(13)+'	SET LastModByUserId = suser_sname(), LastModDateTime = getdate() '
					 +CHAR(13)+'	FROM dbo.'+(@MyTableName)+' as t, DELETED as d'+CHAR(13)+'	WHERE t.Id=d.Id;'+CHAR(13)+'END'+CHAR(13)+CHAR(13)+

					--ENABLING THE TRIGGER STATEMENT
					 'ALTER TABLE dbo.'+ @MyTableName+' ENABLE TRIGGER TU_'+ @MyTableName+CHAR(13)


					--print @C8Trigger  
					EXECUTE (@C8Trigger)

					FETCH NEXT FROM CursorTRIGGER INTO @MyTableName 
				END 
			CLOSE CursorTRIGGER 
			DEALLOCATE CursorTRIGGER

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- CLIENT_AddILIAxialStrainTable_34421.sql

			DECLARE @sql nvarchar(max)

			-- Create the strain table
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables t Where t.Table_Name = 'InlineInspectionAxialStrain')
			BEGIN
					SET @sql = 'CREATE TABLE InlineInspectionAxialStrain
				   (
						  Id numeric(10, 0) NOT NULL,
						  EffectiveStartDate datetime NULL,
						  EffectiveEndDate datetime NULL,
						  InlineInspectionId numeric(10, 0) NULL,
						  InlineInspectionRangeId numeric(10, 0) NOT NULL,
						  SourceId varchar(50) NULL,
						  StationSeriesId numeric(10, 0) NULL,
						  StationNum numeric(13, 5) NULL,
						  BeginStationSeriesId numeric(10, 0) NULL,
						  BeginStationNum numeric(13, 5) NULL,
						  EndStationSeriesId numeric(10, 0) NULL,
						  EndStationNum numeric(13, 5) NULL,
						  ILIASFeatureIdentifier varchar(15) NULL,
						  ILIASOdometer numeric(10,3) NULL,
						  ILIASSensorP1Strain numeric(7,3) NULL,
						  ILIASSensorP2Strain numeric(7,3) NULL,
						  ILIASSensorP3Strain numeric(7,3) NULL,
						  ILIASSensorP4Strain numeric(7,3) NULL,
						  ILIASSensorP5Strain numeric(7,3) NULL,
						  ILIASSensorP6Strain numeric(7,3) NULL,
						  ILIASSensorP7Strain numeric(7,3) NULL,
						  ILIASSensorP8Strain numeric(7,3) NULL,
						  ILIASAxialStrain numeric(7,3) NULL,
						  ILIASSensorP1Orientation numeric(6,3) NULL,
						  ILIASSensorP2Orientation numeric(6,3) NULL,
						  ILIASSensorP3Orientation numeric(6,3) NULL,
						  ILIASSensorP4Orientation numeric(6,3) NULL,
						  ILIASSensorP5Orientation numeric(6,3) NULL,
						  ILIASSensorP6Orientation numeric(6,3) NULL,
						  ILIASSensorP7Orientation numeric(6,3) NULL,
						  ILIASSensorP8Orientation numeric(6,3) NULL,
						  ILIASAreaOfInterest char(1) NULL,
						  ILIASAnalysisDomainId numeric(10,0) NULL,
						  ILIASComments varchar(255) NULL,
						  ILIASX numeric(12,3) NULL,
						  ILIASY numeric(12,3) NULL,
						  ILIASZ numeric(10,3) NULL,
						  ILIASLatitude numeric(12,9) NULL,
						  ILIASLongitude numeric(12,9) NULL,
						  ILIASGirthWeldNum varchar(25) NULL,
						  ILIASDistanceFromGirthWeld numeric(10, 3) NULL,
						  ILIASGirthWeldNumDS varchar(25) NULL,
						  ILIASDistanceFromGirthWeldDS numeric(10, 3) NULL,
						  IRASCustomDate1 datetime NULL,
						  IRASCustomDate2 datetime NULL,
						  IRASCustomDate3 datetime NULL,
						  IRASCustomDate4 datetime NULL,
						  IRASCustomDate5 datetime NULL,
						  IRASCustomNum1 float NULL,
						  IRASCustomNum2 float NULL,
						  IRASCustomNum3 float NULL,
						  IRASCustomNum4 float NULL,
						  IRASCustomNum5 float NULL,
						  IRASCustomString1 varchar(255) NULL,
						  IRASCustomString2 varchar(255) NULL,
						  IRASCustomString3 varchar(255) NULL,
						  IRASCustomString4 varchar(255) NULL,
						  IRASCustomString5 varchar(255) NULL,
						  CreatedUser varchar(45) NOT NULL DEFAULT (suser_sname()),
						  CreatedDate datetime NOT NULL DEFAULT (getdate()),
						  LastModByUserId varchar(45) NOT NULL DEFAULT (suser_sname()),
						  LastModDateTime datetime NOT NULL DEFAULT (getdate())
				   )'

				EXEC sp_executesql @sql
			END
				   

			IF object_id('PK_InlineInspectionAxialStrain') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain Add CONSTRAINT PK_InlineInspectionAxialStrain PRIMARY KEY (Id)
			END

			IF object_id('FK_ILIASInlineInspectionId') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain ADD CONSTRAINT FK_ILIASInlineInspectionId FOREIGN KEY (InlineInspectionId) REFERENCES dbo.InlineInspection(Id)
			END

			IF object_id('FK_ILIASInlineInspectionRngId') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain ADD CONSTRAINT FK_ILIASInlineInspectionRngId FOREIGN KEY (InlineInspectionRangeId) REFERENCES dbo.InlineInspectionRange(Id)
			END


			IF object_id('FK_ILIASAnalysisDomainId') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain ADD CONSTRAINT FK_ILIASAnalysisDomainId FOREIGN KEY (ILIASAnalysisDomainId) REFERENCES dbo.ListDomain (Id);
			END

			IF object_id('FK_ILIASBeginStationSeriesId') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain ADD CONSTRAINT FK_ILIASBeginStationSeriesId FOREIGN KEY (BeginStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			IF object_id('FK_ILIASEndStationSeriesId') IS NULL
			BEGIN
				   ALTER TABLE InlineInspectionAxialStrain ADD CONSTRAINT FK_ILIASEndStationSeriesId FOREIGN KEY (EndStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables t Where t.Table_Name = 'Stg_ILIAxialStrain')
			BEGIN
				/*The a discrepancy with KEY_IRASV5_UPSTREAM in the column ILIASAnalysisDomainId */
				SET @sql = 'CREATE TABLE Stg_ILIAxialStrain
				   (
						  Id numeric(10, 0) NOT NULL,
						  EffectiveStartDate datetime NULL,
						  EffectiveEndDate datetime NULL,
						  Stg_ILIId numeric(10, 0) NULL,
						  Stg_ILIRangeId numeric(10, 0) NULL,
						  StationSeriesId numeric(10, 0) NULL,
						  StationNum numeric(13, 5) NULL,
						  BeginStationSeriesId numeric(10, 0) NULL,
						  BeginStationNum numeric(13, 5) NULL,
						  EndStationSeriesId numeric(10, 0) NULL,
						  EndStationNum numeric(13, 5) NULL,
						  ILIASFeatureIdentifier varchar(15) NULL,
						  ILIASOdometer numeric(10,3) NULL,
						  ILIASSensorP1Strain numeric(7,3) NULL,
						  ILIASSensorP2Strain numeric(7,3) NULL,
						  ILIASSensorP3Strain numeric(7,3) NULL,
						  ILIASSensorP4Strain numeric(7,3) NULL,
						  ILIASSensorP5Strain numeric(7,3) NULL,
						  ILIASSensorP6Strain numeric(7,3) NULL,
						  ILIASSensorP7Strain numeric(7,3) NULL,
						  ILIASSensorP8Strain numeric(7,3) NULL,
						  ILIASAxialStrain numeric(7,3) NULL,
						  ILIASSensorP1Orientation numeric(6,3) NULL,
						  ILIASSensorP2Orientation numeric(6,3) NULL,
						  ILIASSensorP3Orientation numeric(6,3) NULL,
						  ILIASSensorP4Orientation numeric(6,3) NULL,
						  ILIASSensorP5Orientation numeric(6,3) NULL,
						  ILIASSensorP6Orientation numeric(6,3) NULL,
						  ILIASSensorP7Orientation numeric(6,3) NULL,
						  ILIASSensorP8Orientation numeric(6,3) NULL,
						  ILIASAreaOfInterest char(1) NULL,
						  ILIASAnalysisDomainId numeric(10,0) NULL,
						  ILIASComments varchar(255) NULL,
						  ILIASX numeric(12,3) NULL,
						  ILIASY numeric(12,3) NULL,
						  ILIASZ numeric(10,3) NULL,
						  ILIASLatitude numeric(12,9) NULL,
						  ILIASLongitude numeric(12,9) NULL,
						  ILIASGirthWeldNum varchar(25) NULL,
						  ILIASDistanceFromGirthWeld numeric(10, 3) NULL,
						  ILIASGirthWeldNumDS varchar(25) NULL,
						  ILIASDistanceFromGirthWeldDS numeric(10, 3) NULL,
						  IRASCustomDate1 datetime NULL,
						  IRASCustomDate2 datetime NULL,
						  IRASCustomDate3 datetime NULL,
						  IRASCustomDate4 datetime NULL,
						  IRASCustomDate5 datetime NULL,
						  IRASCustomNum1 float NULL,
						  IRASCustomNum2 float NULL,
						  IRASCustomNum3 float NULL,
						  IRASCustomNum4 float NULL,
						  IRASCustomNum5 float NULL,
						  IRASCustomString1 varchar(255) NULL,
						  IRASCustomString2 varchar(255) NULL,
						  IRASCustomString3 varchar(255) NULL,
						  IRASCustomString4 varchar(255) NULL,
						  IRASCustomString5 varchar(255) NULL,
						  CreatedUser varchar(45) NOT NULL DEFAULT (suser_sname()),
						  CreatedDate datetime NOT NULL DEFAULT (getdate()),
						  LastModByUserId varchar(45) NOT NULL DEFAULT (suser_sname()),
						  LastModDateTime datetime NOT NULL DEFAULT (getdate())
				   )'

				EXEC sp_executesql @sql				   

			END

			IF object_id('PK_Stg_ILIAxialStrain') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain Add CONSTRAINT PK_Stg_ILIAxialStrain PRIMARY KEY (Id)
			END

			IF object_id('FK_Stg_ILIASStg_ILIId') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain ADD CONSTRAINT FK_Stg_ILIASStg_ILIId FOREIGN KEY (Stg_ILIId) REFERENCES dbo.Stg_ILI(Id)
			END

			IF object_id('FK_Stg_ILIASStg_ILIRangeId') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain ADD CONSTRAINT FK_Stg_ILIASStg_ILIRangeId FOREIGN KEY (Stg_ILIRangeId) REFERENCES dbo.Stg_ILIRange(Id)
			END

			IF object_id('FK_Stg_ILIASAnalysisDomainId') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain ADD CONSTRAINT FK_Stg_ILIASAnalysisDomainId FOREIGN KEY (ILIASAnalysisDomainId) REFERENCES dbo.ListDomain (Id);
			END

			IF object_id('FK_Stg_ILIASBegStationSeriesId') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain ADD CONSTRAINT FK_Stg_ILIASBegStationSeriesId FOREIGN KEY (BeginStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			IF object_id('FK_Stg_ILIASEndStationSeriesId') IS NULL
			BEGIN
				   ALTER TABLE Stg_ILIAxialStrain ADD CONSTRAINT FK_Stg_ILIASEndStationSeriesId FOREIGN KEY (EndStationSeriesId) REFERENCES dbo.StationSeries(Id)
			END

			SET @sql = 'IF object_id(''tu_InlineInspectionAxialStrain'') IS NOT NULL
			BEGIN
				DROP TRIGGER tu_InlineInspectionAxialStrain
			END'
			
			EXEC sp_executesql @sql

			SET @sql = 'CREATE TRIGGER [dbo].[tu_InlineInspectionAxialStrain] ON [dbo].[InlineInspectionAxialStrain] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.InlineInspectionAxialStrain
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.InlineInspectionAxialStrain as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

			EXEC sp_executesql @sql

			set @sql = 'ALTER TABLE [dbo].[InlineInspectionAxialStrain] ENABLE TRIGGER [tu_InlineInspectionAxialStrain]'

			EXEC sp_executesql @sql

			SET @sql = 'IF object_id(''tu_Stg_ILIAxialStrain'') IS NOT NULL
						BEGIN
							DROP TRIGGER tu_Stg_ILIAxialStrain
						END'
			
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

			-- Setup the Listdomain catelog for the Axial Strain Available Analysis Type Domain ids
			DECLARE @catalogId INT
			IF NOT EXISTS (SELECT * FROM DomainCatalog Where DomainDescr = 'Axial Strain Available Analysis Type')
			BEGIN
				Set @catalogId = (SELECT MAX(Id)+1 FROM DomainCatalog);
				INSERT INTO DomainCatalog ( Id , DomainDescr ) VALUES (@catalogId, 'Axial Strain Available Analysis Type' );
				INSERT INTO DomainCatalogColXRef ( DomainCatalogId , TableName , ColumnName) 
					VALUES (@catalogId, 'InlineInspectionAxialStrain', 'ILIASAnalysisDomainId' );
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), @catalogId, 'N/A', 'Not Applicable');
				INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), @catalogId, 'Reported', 'Reported');
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			-- CLIENT_SystemPreferences_InsertTableCheckerSystemOfMeasure_BL32240.sql
			/*
				New record to be inserted in the SystemPreferences table of the STAGE DATABASE
			*/
			-- Add table checker system of measure record to SystemPreferences table
			IF NOT EXISTS (SELECT * FROM SystemPreferences WHERE ParameterName = 'TableChecker_SystemOfMeasure')
			BEGIN
				INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
				VALUES ('TableChecker_SystemOfMeasure', 'Metric', null);
			END

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

		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN

			-- Rename row tracking columns (CreateDate, CreatedByUserId, etc) to (CreatedDate, CreatedUser, etc) and recreate associated triggers

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
			DECLARE @GetDefaultConst AS NVARCHAR(800)
			DECLARE @GetColumnList NVARCHAR(800)
			DECLARE @GetOldColList NVARCHAR(800)
			DECLARE @GetAddColumnList NVARCHAR(800)
			DECLARE @GetColModList NVARCHAR(800)
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
			INSERT INTO @SearchNReplace_tbl VALUES ('Create%User%','CreatedUser', 'VARCHAR(64)', 'SUSER_SNAME()');
			INSERT INTO @SearchNReplace_tbl VALUES ('LastMod%User%','LastModByUserId', 'VARCHAR(64)', 'SUSER_SNAME()');
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
				SELECT table_name FROM INFORMATION_SCHEMA.TABLES 
				WHERE table_name LIKE ''GDB%'' OR
					table_name LIKE ''SDE%'' OR
					table_name LIKE ''i[0-9]%''
				EXCEPT
				SELECT DISTINCT(table_name) 
				FROM INFORMATION_SCHEMA.COLUMNS isc
				WHERE column_name LIKE '+ '''' + @search_string + '''' + ';
				SELECT * FROM @result_tbl;'

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
			 			SET @set_clause_limit = SUBSTRING(@update_stmt, 0, @index_case_func)

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
			 						BREAK

			 					-- Delete duplicate column name in the SET clause
			 					SET @update_stmt = STUFF(@update_stmt, @begin_phrase_index, (@end_phrase_index - @begin_phrase_index) + 1, '');

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

			 UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 6
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @TransDBVersion varchar(10) = (SELECT cast(TransDBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(TransDBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	PRINT ERROR_MESSAGE()
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @TransDBVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			-- SQLQueryAddModifyColumns_BellHoleExcavationStageDatabase.sql
			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BellHoleExcavation' and COLUMN_NAME in ('BeginStationSeriesId', 'BeginStationNum', 'EndStationSeriesId', 'EndStationNum'))
			BEGIN
			  PRINT 'COLUMNS ALREADY EXISTS'
			END
			ELSE
			BEGIN
				PRINT 'This section of code was commented out'
			-- COMMENTED OUT - BellHoleExcavation table does not exist in KEY_IRASV5_UPSTREAM 
			-- BEGIN
			-- 	declare @sql nvarchar(max)
			-- 	SET @sql = 'Alter table [dbo].[BellHoleExcavation] ADD 
			-- 					[SourceId] [varchar] (50) NULL, 
			-- 					[BeginStationSeriesId] [numeric](10, 0) NULL,
			-- 					[BeginStationNum] [numeric](13, 5) NOT NULL,
			-- 					[EndStationSeriesId] [numeric](10, 0) NULL,
			-- 					[EndStationNum] [numeric](13, 5) NOT NULL'

			-- 	exec sp_executesql @sql
			-- END
			
			-- SET @sql = 'If object_id(''PK_BellHoleExcavation'') IS NOT NULL
			-- 			BEGIN
			-- 				ALTER TABLE BellHoleExcavation DROP CONSTRAINT PK_BellHoleExcavation
			-- 			END'

			-- EXEC sp_executesql @sql

		
			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN [Id] [numeric](10, 0) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN [EffectiveStartDate] [datetime] NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[EffectiveEndDate] [datetime] NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN [BellholeID] [varchar](60) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN [BellholeRepairInd] [char](1) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[BellholeFoundCoatCondDomainID] [numeric](7, 0) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[BellholeDamageTypeDomainID] [numeric](7, 0) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN [BellholeExposedPipeLength] [numeric](10, 3) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[BellholeComment] [varchar](255) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[StationSeriesId] [numeric](10, 0) NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[StationNum] [numeric](13, 5) NOT NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[LastModByUserId] [varchar](45) NOT NULL

			-- ALTER TABLE [dbo].[BellHoleExcavation] ALTER COLUMN	[LastModDateTime] [datetime] NOT NULL
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 7
		BEGIN
			-- SQLQueryAddModifyColumns_FloodAreaStageDatabase.sql
			DECLARE @sql nvarchar(max)

			-- COMMENTED OUT - FloodArea table does not exist in KEY_IRASV5_UPSTREAM
			-- SET @sql = 'If object_id(''PK_FloodArea'') IS NOT NULL
			-- 			BEGIN
			-- 				ALTER TABLE FloodArea DROP CONSTRAINT PK_FloodArea
			-- 			END'

			-- EXEC sp_executesql @sql

			-- ALTER TABLE [dbo].[FloodArea] ALTER COLUMN [Id] [numeric](10, 0) NULL

			-- ALTER TABLE [dbo].[FloodArea] ALTER COLUMN [BeginStationSeriesId] [numeric](10, 0) NULL

			-- ALTER TABLE [dbo].[FloodArea] ALTER COLUMN [EndStationSeriesId] [numeric](10, 0) NULL
				
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 8
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
 		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 8
 		BEGIN
 			-- New_Casing_Template.sql
 			IF NOT EXISTS (SELECT 1
 							FROM   INFORMATION_SCHEMA.COLUMNS
 							WHERE  TABLE_NAME = 'Casing'
 									AND COLUMN_NAME = 'CheckSumValue'
 									AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Casing ADD CheckSumValue int; 
	
 			END

 			IF NOT EXISTS (SELECT 1
 							FROM sysobjects
 							WHERE id = object_id('Load_Casing')
 							AND type = 'U')
 			BEGIN
 				-- Create Load_Casing table 

 				DECLARE @sql nvarchar(max)

 				SET @sql = 'CREATE TABLE [dbo].[Load_Casing](
 					[Id] [numeric](10, 0) NOT NULL,
 					[EffectiveStartDate] [datetime] NULL,
 					[EffectiveEndDate] [datetime] NULL,
 					[Load_CasingTypeDomainId] [numeric](10, 0) NULL,
 					[Load_CasingInhibitorDomainId] [numeric](10, 0) NULL,
 					[Load_CasingComment] [varchar](255) NULL,
 					[Load_CasingDiameter] [numeric](8, 5) NULL,
 					[Load_CasingWallThickness] [numeric](9, 5) NULL,
 					[Load_CasingVentedFlg] [numeric](1, 0) NULL,
 					[Load_CasingShortedFlg] [numeric](1, 0) NULL,
 					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 					[BeginStationNum] [numeric](13, 5) NOT NULL,
 					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 					[EndStationNum] [numeric](13, 5) NOT NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Casing ADD CONSTRAINT PK_Load_Casing PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql

 			END


 			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 9
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
 		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 9
 		BEGIN
 			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'MetalLoss')
			BEGIN	
				EXECUTE ('CREATE TABLE [dbo].[MetalLoss](
							[Id] [numeric](10, 0) NOT NULL,
							[EffectiveStartDate] [datetime] NULL,
							[EffectiveEndDate] [datetime] NULL,
							[ExcavationSiteId] [numeric](10, 0) NOT NULL,
							[InlineInspectionFeatureId] [numeric](10, 0) NULL,
							[MetalLossAlternateDefectId] [varchar](25) NULL,
							[MetalLossGirthWeldNum] [numeric](7, 0) NULL,
							[MetalLossDistanceFromGirthWeld] [numeric](10, 3) NULL,
							[MetalLossOrientation] [numeric](3, 0) NULL,
							[MetalLossTypeDomainId] [numeric](10, 0) NULL,
							[MetalLossCauseDomainId] [numeric](10, 0) NULL,
							[MetalLossStatusDomainId] [numeric](10, 0) NULL,
							[MetalLossLength] [numeric](9, 2) NULL,
							[MetalLossWidth] [numeric](9, 2) NULL,
							[MetalLossDepth] [numeric](4, 2) NULL,
							[MetalLossDepthPct] [numeric](8, 5) NULL,
							[MetalLossSurfaceInd] [varchar](2) NULL,
							[MetalLossFailurePressure] [numeric](15, 4) NULL,
							[MetalLossFailurePressAlgrthmLD] [numeric](10, 0) NULL,
							[MetalLossRupturePressureRatio] [numeric](5, 3) NULL,
							[MetalLossSafePressure] [numeric](15, 4) NULL,
							[MetalLossSafePressAlgrthmLD] [numeric](10, 0) NULL,
							[MetalLossAcidSmellTest] [numeric](1, 0) NULL,
							[MetalLossAcidPrdBacteriaTest] [numeric](1, 0) NULL,
							[MtlLssSulfateRdcngBacteriaTest] [numeric](1, 0) NULL,
							[MetalLossOtherBacteriaTestRslt] [varchar](255) NULL,
							[LinalysisPrimaryLength] [numeric](9, 2) NULL,
							[LinalysisSecondaryLength] [numeric](9, 2) NULL,
							[LinalysisMaxDepth] [numeric](4, 2) NULL,
							[LinalysisMaxDepthPct] [numeric](8, 5) NULL,
							[LinalysisOrientation] [numeric](3, 0) NULL,
							[MetalLossGrading1DomainId] [numeric](10, 0) NULL,
							[MetalLossGrading2DomainId] [numeric](10, 0) NULL,
							[MetalLossComment] [varchar](255) NULL,
							[StationSeriesId] [numeric](10, 0) NULL,
							[StationNum] [numeric](13, 5) NULL,
							[MetalLossCircumLength] [numeric](9, 2) NULL,
							[MetalLossMaxWidth] [numeric](9, 2) NULL,
							[MetalLossCAOP] [numeric](5, 0) NULL,
							[MetalLossAxialLength] [numeric](9, 2) NULL,
							[MetalLossMaxDepth] [numeric](4, 2) NULL,
							[MetalLossMaxDepthPct] [numeric](8, 5) NULL,
							[MetalLossPrevInvestigate] [char](1) NULL,
							[MetalLossCorrosionActiveFlg] [numeric](1, 0) NULL,
							[LastModByUserId] [varchar](45) NOT NULL,
							[LastModDateTime] [datetime] NOT NULL,
							[MetalLossRepairMethodDomainId] [numeric](10, 0) NULL,
							[BeginStationSeriesId] [numeric](10, 0) NULL,
							[BeginStationNum] [numeric](13, 5) NULL,
							[EndStationSeriesId] [numeric](10, 0) NULL,
							[EndStationNum] [numeric](13, 5) NULL,
							[SourceId] [varchar](50) NULL,
							[CreatedDate] [datetime] NOT NULL,
							[CreatedUser] [varchar](45) NOT NULL,
						 CONSTRAINT [PK_MetalLoss] PRIMARY KEY CLUSTERED 
						(
							[Id] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
						) ON [PRIMARY]')

                --EXECUTE @sql

                EXECUTE ('ALTER TABLE [dbo].[MetalLoss] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]')
						
                EXECUTE ('ALTER TABLE [dbo].[MetalLoss] ADD  DEFAULT (getdate()) FOR [LastModDateTime]')

                EXECUTE ('ALTER TABLE [dbo].[MetalLoss] ADD  DEFAULT (getdate()) FOR [CreatedDate]')
				
                EXECUTE ('ALTER TABLE [dbo].[MetalLoss] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]')
	
                EXECUTE ('ALTER TABLE [dbo].[MetalLoss]  WITH NOCHECK ADD  CONSTRAINT [FK_MetalLossBegStnSrsId] FOREIGN KEY([BeginStationSeriesId])
						REFERENCES [dbo].[STATIONSERIES] ([Id])')
		
                EXECUTE ('ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossBegStnSrsId]

						ALTER TABLE [dbo].[MetalLoss]  WITH NOCHECK ADD  CONSTRAINT [FK_MetalLossEndStnSrsId] FOREIGN KEY([EndStationSeriesId])
						REFERENCES [dbo].[STATIONSERIES] ([Id])
				
						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossEndStnSrsId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossCauseDomainId] FOREIGN KEY([MetalLossCauseDomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossCauseDomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossFailurePressAlgrthmLD] FOREIGN KEY([MetalLossFailurePressAlgrthmLD])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossFailurePressAlgrthmLD]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossGrading1DomainId] FOREIGN KEY([MetalLossGrading1DomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossGrading1DomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossGrading2DomainId] FOREIGN KEY([MetalLossGrading2DomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossGrading2DomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossRepairMethodDomainId] FOREIGN KEY([MetalLossRepairMethodDomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossRepairMethodDomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossSafePressAlgrthmLD] FOREIGN KEY([MetalLossSafePressAlgrthmLD])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossSafePressAlgrthmLD]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossStatusDomainId] FOREIGN KEY([MetalLossStatusDomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossStatusDomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MetalLossMetalLossTypeDomainId] FOREIGN KEY([MetalLossTypeDomainId])
						REFERENCES [dbo].[ListDomain] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MetalLossMetalLossTypeDomainId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MtlLssExcavationSiteId] FOREIGN KEY([ExcavationSiteId])
						REFERENCES [dbo].[ExcavationSite] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MtlLssExcavationSiteId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MtlLssILIFeatureId] FOREIGN KEY([InlineInspectionFeatureId])
						REFERENCES [dbo].[InlineInspectionFeature] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MtlLssILIFeatureId]

						ALTER TABLE [dbo].[MetalLoss]  WITH CHECK ADD  CONSTRAINT [FK_MtlLssStationSeriesId] FOREIGN KEY([StationSeriesId])
						REFERENCES [dbo].[STATIONSERIES] ([Id])

						ALTER TABLE [dbo].[MetalLoss] CHECK CONSTRAINT [FK_MtlLssStationSeriesId]')

			END

 			-- New_ML_ROW_Marker_Template.sql
 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'MetalLoss'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE MetalLoss ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_MetalLoss')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_MetalLoss table 

 				SET @sql = 'CREATE TABLE [dbo].[Load_MetalLoss](
 							[Id] [numeric](10, 0) NOT NULL,
 							[EffectiveStartDate] [datetime] NULL,
 							[EffectiveEndDate] [datetime] NULL,
 							[ExcavationSiteId] [numeric](10, 0) NOT NULL,
 							[InlineInspectionFeatureId] [numeric](10, 0) NULL,
 							[MetalLossAlternateDefectId] [varchar](25) NULL,
 							[MetalLossGirthWeldNum] [numeric](7, 0) NULL,
 							[MetalLossDistanceFromGirthWeld] [numeric](10, 3) NULL,
 							[MetalLossOrientation] [numeric](3, 0) NULL,
 							[MetalLossTypeDomainId] [numeric](10, 0) NULL,
 							[MetalLossCauseDomainId] [numeric](10, 0) NULL,
 							[MetalLossStatusDomainId] [numeric](10, 0) NULL,
 							[MetalLossLength] [numeric](9, 2) NULL,
 							[MetalLossWidth] [numeric](9, 2) NULL,
 							[MetalLossDepth] [numeric](4, 2) NULL,
 							[MetalLossDepthPct] [numeric](8, 5) NULL,
 							[MetalLossSurfaceInd] [varchar](2) NULL,
 							[MetalLossFailurePressure] [numeric](15, 4) NULL,
 							[MetalLossFailurePressAlgrthmLD] [numeric](10, 0) NULL,
 							[MetalLossRupturePressureRatio] [numeric](5, 3) NULL,
 							[MetalLossSafePressure] [numeric](15, 4) NULL,
 							[MetalLossSafePressAlgrthmLD] [numeric](10, 0) NULL,
 							[MetalLossAcidSmellTest] [numeric](1, 0) NULL,
 							[MetalLossAcidPrdBacteriaTest] [numeric](1, 0) NULL,
 							[MtlLssSulfateRdcngBacteriaTest] [numeric](1, 0) NULL,
 							[MetalLossOtherBacteriaTestRslt] [varchar](255) NULL,
 							[LinalysisPrimaryLength] [numeric](9, 2) NULL,
 							[LinalysisSecondaryLength] [numeric](9, 2) NULL,
 							[LinalysisMaxDepth] [numeric](4, 2) NULL,
 							[LinalysisMaxDepthPct] [numeric](8, 5) NULL,
 							[LinalysisOrientation] [numeric](3, 0) NULL,
 							[MetalLossGrading1DomainId] [numeric](10, 0) NULL,
 							[MetalLossGrading2DomainId] [numeric](10, 0) NULL,
 							[MetalLossComment] [varchar](255) NULL,
 							[StationSeriesId] [numeric](10, 0) NULL,
 							[StationNum] [numeric](13, 5) NULL,
 							[MetalLossCircumLength] [numeric](9, 2) NULL,
 							[MetalLossMaxWidth] [numeric](9, 2) NULL,
 							[MetalLossCAOP] [numeric](5, 0) NULL,
 							[MetalLossAxialLength] [numeric](9, 2) NULL,
 							[MetalLossMaxDepth] [numeric](4, 2) NULL,
 							[MetalLossMaxDepthPct] [numeric](8, 5) NULL,
 							[MetalLossPrevInvestigate] [char](1) NULL,
 							[MetalLossCorrosionActiveFlg] [numeric](1, 0) NULL,
 							[LastModByUserId] [varchar](45),
 							[LastModDateTime] [datetime],
 							[MetalLossRepairMethodDomainId] [numeric](10, 0) NULL,
 							[BeginStationSeriesId] [numeric](10, 0) NULL,
 							[BeginStationNum] [numeric](13, 5) NULL,
 							[EndStationSeriesId] [numeric](10, 0) NULL,
 							[EndStationNum] [numeric](13, 5) NULL,
 							[SourceId] [varchar](50) NOT NULL,
 							[CreatedDate] [datetime],
 							[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_MetalLoss ADD CONSTRAINT PK_Load_MetalLoss PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql
				
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'RightOfWay'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE RightOfWay ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_RightOfWay')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_RightOfWay table 

 				SET @sql = 'CREATE TABLE [dbo].[Load_RightOfWay](
 							[Id] [numeric](10, 0) NOT NULL,
 							[EffectiveStartDate] [datetime] NULL,
 							[EffectiveEndDate] [datetime] NULL,
 							[ROWTypeDomainId] [numeric](10, 0) NULL,
 							[ROWLandLegalLocation] [varchar](255) NULL,
 							[ROWOwnerDomainId] [numeric](10, 0) NULL,
 							[ROWWidth] [numeric](10, 3) NULL,
 							[ROWComment] [varchar](255) NULL,
 							[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 							[BeginStationNum] [numeric](13, 5) NOT NULL,
 							[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 							[EndStationNum] [numeric](13, 5) NOT NULL,
 							[LastModByUserId] [varchar](45),
 							[LastModDateTime] [datetime],
 							[SourceId] [varchar](50) NOT NULL,
 							[CreatedDate] [datetime],
 							[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_RightOfWay ADD CONSTRAINT PK_Load_RightOfWay PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql

 			END

            IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'Marker')
            BEGIN
                EXECUTE ('CREATE TABLE [dbo].[Marker](
                [Id] [numeric](10, 0) NOT NULL,
                [EffectiveStartDate] [datetime] NULL,
                [EffectiveEndDate] [datetime] NULL,
                [MarkerTypeDomainId] [numeric](10, 0) NULL,
                [MarkerName] [varchar](70) NULL,
                [MarkerOffset] [numeric](4, 2) NULL,
                [MarkerLatitude] [numeric](11, 9) NULL,
                [MarkerLongitude] [numeric](12, 9) NULL,
                [MarkerCoordSysDomainId] [numeric](10, 0) NULL,
                [MarkerX] [numeric](12, 3) NULL,
                [MarkerY] [numeric](12, 3) NULL,
                [MarkerZ] [numeric](10, 3) NULL,
                [MarkerEngineeringStnFlg] [numeric](1, 0) NULL,
                [StationSeriesId] [numeric](10, 0) NOT NULL,
                [StationNum] [numeric](13, 5) NOT NULL,
                [MarkerDescr] [varchar](255) NULL,
                [MarkerILIRun] [varchar](30) NULL,
                [LastModByUserId] [varchar](45) NOT NULL,
                [LastModDateTime] [datetime] NOT NULL,
                [BeginStationSeriesId] [numeric](10, 0) NOT NULL,
                [BeginStationNum] [numeric](13, 5) NOT NULL,
                [EndStationSeriesId] [numeric](10, 0) NOT NULL,
                [EndStationNum] [numeric](13, 5) NOT NULL,
                [SourceId] [varchar](50) NULL,
                [CreatedDate] [datetime] NOT NULL,
                [CreatedUser] [varchar](45) NOT NULL,
            CONSTRAINT [PK_Marker] PRIMARY KEY CLUSTERED 
            (
                [Id] ASC
            )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
            ) ON [PRIMARY]

            ALTER TABLE [dbo].[Marker] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

            ALTER TABLE [dbo].[Marker] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

            ALTER TABLE [dbo].[Marker] ADD  DEFAULT (getdate()) FOR [CreatedDate]

            ALTER TABLE [dbo].[Marker] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

            ALTER TABLE [dbo].[Marker]  WITH CHECK ADD  CONSTRAINT [FK__Marker__StationSeries] FOREIGN KEY([StationSeriesId])
            REFERENCES [dbo].[STATIONSERIES] ([Id])

            ALTER TABLE [dbo].[Marker] CHECK CONSTRAINT [FK__Marker__StationSeries]

            ALTER TABLE [dbo].[Marker]  WITH NOCHECK ADD  CONSTRAINT [FK_MarkerBeginStationSeriesId] FOREIGN KEY([BeginStationSeriesId])
            REFERENCES [dbo].[STATIONSERIES] ([Id])

            ALTER TABLE [dbo].[Marker] CHECK CONSTRAINT [FK_MarkerBeginStationSeriesId]

            ALTER TABLE [dbo].[Marker]  WITH NOCHECK ADD  CONSTRAINT [FK_MarkerEndStationSeriesId] FOREIGN KEY([EndStationSeriesId])
            REFERENCES [dbo].[STATIONSERIES] ([Id])

            ALTER TABLE [dbo].[Marker] CHECK CONSTRAINT [FK_MarkerEndStationSeriesId]

            ALTER TABLE [dbo].[Marker]  WITH CHECK ADD  CONSTRAINT [FK_MarkerMarkerCoordSysDomainId] FOREIGN KEY([MarkerCoordSysDomainId])
            REFERENCES [dbo].[ListDomain] ([Id])

            ALTER TABLE [dbo].[Marker] CHECK CONSTRAINT [FK_MarkerMarkerCoordSysDomainId]

            ALTER TABLE [dbo].[Marker]  WITH CHECK ADD  CONSTRAINT [FK_MarkerMarkerTypeDomainId] FOREIGN KEY([MarkerTypeDomainId])
            REFERENCES [dbo].[ListDomain] ([Id])

            ALTER TABLE [dbo].[Marker] CHECK CONSTRAINT [FK_MarkerMarkerTypeDomainId]')
            
            END

 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'Marker'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Marker ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_Marker')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_Marker table 
 				SET @sql = 'CREATE TABLE [dbo].[Load_Marker](
 					[Id] [numeric](10, 0) NOT NULL,
 					[EffectiveStartDate] [datetime] NULL,
 					[EffectiveEndDate] [datetime] NULL,
 					[Load_MarkerTypeDomainId] [numeric](10, 0) NULL,
 					[Load_MarkerName] [varchar](70) NULL,
 					[Load_MarkerOffset] [numeric](4, 2) NULL,
 					[Load_MarkerLatitude] [numeric](11, 9) NULL,
 					[Load_MarkerLongitude] [numeric](12, 9) NULL,
 					[Load_MarkerCoordSysDomainId] [numeric](10, 0) NULL,
 					[Load_MarkerX] [numeric](12, 3) NULL,
 					[Load_MarkerY] [numeric](12, 3) NULL,
 					[Load_MarkerZ] [numeric](10, 3) NULL,
 					[Load_MarkerEngineeringStnFlg] [numeric](1, 0) NULL,
 					[StationSeriesId] [numeric](10, 0) NOT NULL,
 					[StationNum] [numeric](13, 5) NOT NULL,
 					[Load_MarkerDescr] [varchar](255) NULL,
 					[Load_MarkerILIRun] [varchar](30) NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 					[BeginStationNum] [numeric](13, 5) NOT NULL,
 					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 					[EndStationNum] [numeric](13, 5) NOT NULL,
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Marker ADD CONSTRAINT PK_Load_Marker PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql

 			END

 			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 10
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
 		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 10
 		BEGIN
 			DECLARE @sql nvarchar(max)

 			-- New_Rectifier_Template.sql
 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'RectifierReading'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE RectifierReading ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_RectifierReading')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_RectifierReading table 
 				SET @sql = 'CREATE TABLE [dbo].[Load_RectifierReading](
 					[RectifierId] [numeric](10, 0) NOT NULL,
 					[RctfrReadingDate] [datetime] NOT NULL,
 					[RctfrReadingVoltage] [numeric](5, 2) NULL,
 					[RctfrReadingAmperage] [numeric](5, 2) NULL,
 					[RctfrReadingComment] [varchar](255) NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_RectifierReading ADD CONSTRAINT PK_Load_RectifierReading PRIMARY KEY (SOURCEID, RctfrReadingDate)'

 				EXEC sp_executesql @sql
	
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'Rectifier'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Rectifier ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_Rectifier')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_Rectifier table 

 				SET @sql = 'CREATE TABLE [dbo].[Load_Rectifier](
 							[Id] [numeric](10, 0) NOT NULL,
 							[EffectiveStartDate] [datetime] NULL,
 							[EffectiveEndDate] [datetime] NULL,
 							[RctfrManufacturerDomainId] [numeric](10, 0) NULL,
 							[RctfrStatusDomainId] [numeric](10, 0) NULL,
 							[RctfrACArresterDomainId] [numeric](10, 0) NULL,
 							[RctfrDCArresterDomainId] [numeric](10, 0) NULL,
 							[RctfrStackTypeDomainId] [numeric](10, 0) NULL,
 							[RctfrStackManufacturerDomainId] [numeric](10, 0) NULL,
 							[RctfrModelNumber] [varchar](50) NULL,
 							[RctfrSerialNumber] [varchar](12) NULL,
 							[RctfrMapNumber] [varchar](8) NULL,
 							[RctfrHydroAcctNumber] [varchar](40) NULL,
 							[RctfrHydroNeutralSep] [numeric](1, 0) NULL,
 							[RctfrACRating] [numeric](4, 0) NULL,
 							[RctfrAmpRating] [numeric](5, 1) NULL,
 							[RctfrKHFactor] [numeric](5, 1) NULL,
 							[RctfrACFuseRating] [numeric](4, 0) NULL,
 							[RctfrACFuseManufact] [varchar](20) NULL,
 							[RctfrDCFuseRating] [numeric](4, 0) NULL,
 							[RctfrDCFuseManufact] [varchar](20) NULL,
 							[RctfrSurvMonitorFreq] [varchar](2) NULL,
 							[RctfrMajSurvMonitorFreq] [varchar](2) NULL,
 							[RctfrDCFillerVolt] [numeric](4, 0) NULL,
 							[RctfrDCFillerAmp] [numeric](4, 0) NULL,
 							[RctfrInternalShuntMV] [numeric](4, 0) NULL,
 							[RctfrInternalShuntAmp] [numeric](4, 0) NULL,
 							[RctfrInstallProjectId] [varchar](20) NULL,
 							[RctfrMaintenanceProjectId] [varchar](20) NULL,
 							[RctfrComment] [varchar](255) NULL,
 							[StationSeriesId] [numeric](10, 0) NOT NULL,
 							[StationNum] [numeric](13, 5) NOT NULL,
 							[LastModByUserId] [varchar](45),
 							[LastModDateTime] [datetime],
 							[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 							[BeginStationNum] [numeric](13, 5) NOT NULL,
 							[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 							[EndStationNum] [numeric](13, 5) NOT NULL,
 							[SourceId] [varchar](50) NOT NULL,
 							[CreatedDate] [datetime],
 							[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Rectifier ADD CONSTRAINT PK_Load_Rectifier PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql
 			END

 			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 11
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
 		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 11
 		BEGIN
 			DECLARE @sql nvarchar(max)

            IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'Sleeve')
            BEGIN
                EXECUTE ('CREATE TABLE [dbo].[Sleeve](
                        [Id] [numeric](10, 0) NOT NULL,
                        [EffectiveStartDate] [datetime] NULL,
                        [EffectiveEndDate] [datetime] NULL,
                        [SleeveTypeDomainId] [numeric](10, 0) NULL,
                        [SleeveComment] [varchar](512) NULL,
                        [SleeveQuantity] [numeric](4, 0) NULL,
                        [SleeveWallThickness] [numeric](9, 5) NULL,
                        [SleeveGrade] [numeric](10, 5) NULL,
                        [BeginStationSeriesId] [numeric](10, 0) NOT NULL,
                        [BeginStationNum] [numeric](13, 5) NOT NULL,
                        [EndStationSeriesId] [numeric](10, 0) NOT NULL,
                        [EndStationNum] [numeric](13, 5) NOT NULL,
                        [LastModByUserId] [varchar](45) NOT NULL,
                        [LastModDateTime] [datetime] NOT NULL,
                        [SourceId] [varchar](50) NULL,
                        [CreatedDate] [datetime] NOT NULL,
                        [CreatedUser] [varchar](45) NOT NULL,
                    CONSTRAINT [PK_Sleeve] PRIMARY KEY CLUSTERED 
                    (
                        [Id] ASC
                    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
                    ) ON [PRIMARY]

                    ALTER TABLE [dbo].[Sleeve] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

                    ALTER TABLE [dbo].[Sleeve] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

                    ALTER TABLE [dbo].[Sleeve] ADD  DEFAULT (getdate()) FOR [CreatedDate]

                    ALTER TABLE [dbo].[Sleeve] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

                    ALTER TABLE [dbo].[Sleeve]  WITH CHECK ADD  CONSTRAINT [FK_SleeveBeginStationSeriesId] FOREIGN KEY([BeginStationSeriesId])
                    REFERENCES [dbo].[STATIONSERIES] ([Id])

                    ALTER TABLE [dbo].[Sleeve] CHECK CONSTRAINT [FK_SleeveBeginStationSeriesId]

                    ALTER TABLE [dbo].[Sleeve]  WITH CHECK ADD  CONSTRAINT [FK_SleeveEndStationSeriesId] FOREIGN KEY([EndStationSeriesId])
                    REFERENCES [dbo].[STATIONSERIES] ([Id])

                    ALTER TABLE [dbo].[Sleeve] CHECK CONSTRAINT [FK_SleeveEndStationSeriesId]

                    ALTER TABLE [dbo].[Sleeve]  WITH CHECK ADD  CONSTRAINT [FK_SleeveSleeveTypeDomainId] FOREIGN KEY([SleeveTypeDomainId])
                    REFERENCES [dbo].[ListDomain] ([Id])

                    ALTER TABLE [dbo].[Sleeve] CHECK CONSTRAINT [FK_SleeveSleeveTypeDomainId]')
                              
            END

            IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'Fabrication')
            BEGIN
                EXECUTE ('CREATE TABLE [dbo].[Fabrication](
                        [Id] [numeric](10, 0) NOT NULL,
                        [EffectiveStartDate] [datetime] NULL,
                        [EffectiveEndDate] [datetime] NULL,
                        [FabricationTypeDomainId] [numeric](10, 0) NULL,
                        [FabricationOutsideDiameter] [numeric](9, 5) NULL,
                        [FabricationName] [varchar](100) NULL,
                        [FabricationComment] [varchar](255) NULL,
                        [StationSeriesId] [numeric](10, 0) NOT NULL,
                        [StationNum] [numeric](13, 5) NOT NULL,
                        [FabricationManufacturingTypeLd] [numeric](10, 0) NULL,
                        [FabricationOutletGrade] [numeric](5, 0) NULL,
                        [FabricationOutletWallthickness] [numeric](9, 5) NULL,
                        [FabricationInletDiameter] [numeric](8, 5) NULL,
                        [FabricationInletGrade] [numeric](5, 0) NULL,
                        [FabricationInletWallThickness] [numeric](9, 5) NULL,
                        [FabricationPressureRating] [numeric](5, 0) NULL,
                        [FabricationOutletDiameter] [numeric](8, 5) NULL,
                        [LastModByUserId] [varchar](45) NOT NULL,
                        [LastModDateTime] [datetime] NOT NULL,
                        [FabricationConnectDomainID] [numeric](10, 0) NULL,
                        [FabricationWithinFenceInd] [varchar](1) NULL,
                        [FabricationQstnrPctFraction] [numeric](5, 4) NULL,
                        [FabricationConditionDomainID] [numeric](10, 0) NULL,
                        [BeginStationSeriesId] [numeric](10, 0) NOT NULL,
                        [BeginStationNum] [numeric](13, 5) NOT NULL,
                        [EndStationSeriesId] [numeric](10, 0) NOT NULL,
                        [EndStationNum] [numeric](13, 5) NOT NULL,
                        [SourceId] [varchar](50) NULL,
                        [CreatedDate] [datetime] NOT NULL,
                        [CreatedUser] [varchar](45) NOT NULL,
                    CONSTRAINT [PK_Fabrication] PRIMARY KEY CLUSTERED 
                    (
                        [Id] ASC
                    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
                    ) ON [PRIMARY]

                    ALTER TABLE [dbo].[Fabrication] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

                    ALTER TABLE [dbo].[Fabrication] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

                    ALTER TABLE [dbo].[Fabrication] ADD  DEFAULT (getdate()) FOR [CreatedDate]

                    ALTER TABLE [dbo].[Fabrication] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

                    ALTER TABLE [dbo].[Fabrication]  WITH NOCHECK ADD  CONSTRAINT [FK_FabricationBegStnSrsId] FOREIGN KEY([BeginStationSeriesId])
                    REFERENCES [dbo].[STATIONSERIES] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationBegStnSrsId]

                    ALTER TABLE [dbo].[Fabrication]  WITH NOCHECK ADD  CONSTRAINT [FK_FabricationEndStnSrsId] FOREIGN KEY([EndStationSeriesId])
                    REFERENCES [dbo].[STATIONSERIES] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationEndStnSrsId]

                    ALTER TABLE [dbo].[Fabrication]  WITH CHECK ADD  CONSTRAINT [FK_FabricationFabricationConditionDomainID] FOREIGN KEY([FabricationConditionDomainID])
                    REFERENCES [dbo].[ListDomain] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationFabricationConditionDomainID]

                    ALTER TABLE [dbo].[Fabrication]  WITH CHECK ADD  CONSTRAINT [FK_FabricationFabricationConnectDomainID] FOREIGN KEY([FabricationConnectDomainID])
                    REFERENCES [dbo].[ListDomain] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationFabricationConnectDomainID]

                    ALTER TABLE [dbo].[Fabrication]  WITH CHECK ADD  CONSTRAINT [FK_FabricationFabricationManufacturingTypeLd] FOREIGN KEY([FabricationManufacturingTypeLd])
                    REFERENCES [dbo].[ListDomain] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationFabricationManufacturingTypeLd]

                    ALTER TABLE [dbo].[Fabrication]  WITH CHECK ADD  CONSTRAINT [FK_FabricationFabricationTypeDomainId] FOREIGN KEY([FabricationTypeDomainId])
                    REFERENCES [dbo].[ListDomain] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabricationFabricationTypeDomainId]

                    ALTER TABLE [dbo].[Fabrication]  WITH CHECK ADD  CONSTRAINT [FK_FabStationSeriesId] FOREIGN KEY([StationSeriesId])
                    REFERENCES [dbo].[STATIONSERIES] ([Id])

                    ALTER TABLE [dbo].[Fabrication] CHECK CONSTRAINT [FK_FabStationSeriesId]')
            END

            IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'FacilityAlignment')
            BEGIN
                EXECUTE ('CREATE TABLE [dbo].[FacilityAlignment](
                        [IliFacilityId] [numeric](10, 0) NOT NULL,
                        [AlignmentType] [numeric](3, 0) NOT NULL,
                        [CPDataType] [varchar](50) NOT NULL,
                        [MPDataType] [varchar](50) NOT NULL,
                        [MPInnerDataType] [varchar](255) NULL,
                        [FacilityId] [numeric](10, 0) NULL,
                        [CasingId] [numeric](10, 0) NULL,
                        [FabricationId] [numeric](10, 0) NULL,
                        [MarkerId] [numeric](10, 0) NULL,
                        [SleeveId] [numeric](10, 0) NULL,
                        [ValveId] [numeric](10, 0) NULL,
                        [CPILIRangeId] [numeric](10, 0) NOT NULL,
                        [CreatedDate] [datetime] NOT NULL,
                        [CreatedUser] [varchar](45) NOT NULL,
                        [LastModByUserId] [varchar](45) NOT NULL,
                        [LastModDateTime] [datetime] NOT NULL,
                        [CPInnerDataType] [varchar](255) NULL,
                        [CPOdometerType] [numeric](10, 0) NOT NULL,
                        [CPMatchDifference] [numeric](13, 5) NULL,
                    CONSTRAINT [PK_FacilityAlignment] PRIMARY KEY CLUSTERED 
                    (
                        [IliFacilityId] ASC,
                        [CPOdometerType] ASC
                    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
                    ) ON [PRIMARY]
                    
                    ALTER TABLE [dbo].[FacilityAlignment] ADD  DEFAULT (getdate()) FOR [CreatedDate]

                    ALTER TABLE [dbo].[FacilityAlignment] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

                    ALTER TABLE [dbo].[FacilityAlignment] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

                    ALTER TABLE [dbo].[FacilityAlignment] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

                    ALTER TABLE [dbo].[FacilityAlignment] ADD  DEFAULT ((0)) FOR [CPOdometerType]

                    ALTER TABLE [dbo].[FacilityAlignment]  WITH CHECK ADD FOREIGN KEY([CasingId])
                    REFERENCES [dbo].[Casing] ([Id])

                    ALTER TABLE [dbo].[FacilityAlignment]  WITH CHECK ADD FOREIGN KEY([FabricationId])
                    REFERENCES [dbo].[Fabrication] ([Id])

                    ALTER TABLE [dbo].[FacilityAlignment]  WITH CHECK ADD FOREIGN KEY([MarkerId])
                    REFERENCES [dbo].[Marker] ([Id])

                    ALTER TABLE [dbo].[FacilityAlignment]  WITH CHECK ADD FOREIGN KEY([SleeveId])
                    REFERENCES [dbo].[Sleeve] ([Id])

                    ALTER TABLE [dbo].[FacilityAlignment]  WITH CHECK ADD FOREIGN KEY([ValveId])
                    REFERENCES [dbo].[VALVE] ([Id])')
            END

 			-- New_Sleeve_Weight_Tee_Template.sql
 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'Sleeve'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Sleeve ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_Sleeve')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_Sleeve table 

 				SET @sql = 'CREATE TABLE [dbo].[Load_Sleeve](
 					[Id] [numeric](10, 0) NOT NULL,
 					[EffectiveStartDate] [datetime] NULL,
 					[EffectiveEndDate] [datetime] NULL,
 					[SleeveTypeDomainId] [numeric](10, 0) NULL,
 					[SleeveComment] [varchar](512) NULL,
 					[SleeveQuantity] [numeric](4, 0) NULL,
 					[SleeveWallThickness] [numeric](9, 5) NULL,
 					[SleeveGrade] [numeric](10, 5) NULL,
 					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 					[BeginStationNum] [numeric](13, 5) NOT NULL,
 					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 					[EndStationNum] [numeric](13, 5) NOT NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Sleeve ADD CONSTRAINT PK_Load_Sleeve PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql
	
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'Weight'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Weight ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_Weight')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_Weight table 

 				SET @sql = 'CREATE TABLE [dbo].[Load_Weight](
 					[Id] [numeric](10, 0) NOT NULL,
 					[EffectiveStartDate] [datetime] NULL,
 					[EffectiveEndDate] [datetime] NULL,
 					[WeightLinearPointInd] [char](1) NULL,
 					[WeightTypeDomainId] [numeric](10, 0) NULL,
 					[WeightComment] [varchar](255) NULL,
 					[WeightQuantity] [numeric](4, 0) NULL,
 					[WeightSpacing] [numeric](4, 1) NULL,
 					[WeightEach] [numeric](5, 1) NULL,
 					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 					[BeginStationNum] [numeric](13, 5) NOT NULL,
 					[EndStationSeriesId] [numeric](10, 0) NULL,
 					[EndStationNum] [numeric](13, 5) NOT NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Weight ADD CONSTRAINT PK_Load_Weight PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql
	
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM   INFORMATION_SCHEMA.COLUMNS
 						   WHERE  TABLE_NAME = 'Tee'
 								  AND COLUMN_NAME = 'CheckSumValue'
 								  AND TABLE_SCHEMA='DBO')
 			BEGIN
 				-- Add checksum Column
 				ALTER TABLE Tee ADD CheckSumValue int; 
 			END

 			IF NOT EXISTS (SELECT 1
 						   FROM sysobjects
 						   WHERE id = object_id('Load_Tee')
 						   AND type = 'U')
 			BEGIN
 				-- Create Load_Tee table 
 				SET @sql = 'CREATE TABLE [dbo].[Load_Tee](
 					[Id] [numeric](10, 0) NOT NULL,
 					[EffectiveStartDate] [datetime] NULL,
 					[EffectiveEndDate] [datetime] NULL,
 					[TeeTypeDomainId] [numeric](10, 0) NULL,
 					[TeeOutsideDiameter] [numeric](9, 5) NULL,
 					[TeeName] [varchar](100) NULL,
 					[TeeComment] [varchar](255) NULL,
 					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
 					[BeginStationNum] [numeric](13, 5) NOT NULL,
 					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
 					[EndStationNum] [numeric](13, 5) NOT NULL,
 					[TeeManufacturingTypeLd] [numeric](10, 0) NULL,
 					[TeeOutletGrade] [numeric](5, 0) NULL,
 					[TeeOutletWallthickness] [numeric](9, 5) NULL,
 					[TeeInletDiameter] [numeric](5, 3) NULL,
 					[TeeInletGrade] [numeric](5, 0) NULL,
 					[TeeInletWallThickness] [numeric](9, 5) NULL,
 					[TeePressureRating] [numeric](5, 0) NULL,
 					[TeeOutletDiameter] [numeric](5, 3) NULL,
 					[TeeConnectDomainId] [numeric](10, 0) NULL,
 					[LastModByUserId] [varchar](45),
 					[LastModDateTime] [datetime],
 					[SourceId] [varchar](50) NOT NULL,
 					[CreatedDate] [datetime],
 					[CreatedUser] [varchar](45))'

 				EXEC sp_executesql @sql

 				SET @sql = 'ALTER TABLE Load_Tee ADD CONSTRAINT PK_Load_Tee PRIMARY KEY (SOURCEID)'

 				EXEC sp_executesql @sql
	
 			END

 			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 12
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 12
		BEGIN
			DECLARE @sql nvarchar(max)

			-- Taken from New_Structure_JointCoating_InternalCoating_Template.sql script 
			--COMMENTED OUT - Structure TABLE DOES NOT EXIST IN KEY_IRASV5_UPSTREAM
			-- IF NOT EXISTS (SELECT 1
			-- 			   FROM   INFORMATION_SCHEMA.COLUMNS
			-- 			   WHERE  TABLE_NAME = 'Structure'
			-- 					  AND COLUMN_NAME = 'CheckSumValue'
			-- 					  AND TABLE_SCHEMA='DBO')
			-- BEGIN
			-- 	-- Add checksum Column
			-- 	ALTER TABLE Structure ADD CheckSumValue int; 
			-- END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_Structure')
						   AND type = 'U')
			BEGIN
				-- Create Load_Structure table 

				SET @sql = 'CREATE TABLE [dbo].[Load_Structure](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[StructureTypeDomainId] [numeric](10, 0) NULL,
					[StructureComment] [varchar](255) NULL,
					[BuildingCnt] [numeric](5, 0) NULL,
					[DwellingUnitCnt] [numeric](6, 2) NULL,
					[OccupancyCtgryDomainId] [numeric](10, 0) NULL,
					[StructureCoordSysDomainId] [numeric](10, 0) NULL,
					[StructureAreaPointInd] [char](1) NULL,
					[StructureActiveFlg] [numeric](1, 0) NULL,
					[StoreyCnt] [numeric](5, 0) NULL,
					[DaysPerWeek] [numeric](3, 0) NULL,
					[WeeksPerYear] [numeric](3, 0) NULL,
					[OccupantCnt] [numeric](11, 6) NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime] NULL,
					[CreatedUser] [varchar](45) NULL)'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_Structure ADD CONSTRAINT PK_Load_Structure PRIMARY KEY (SOURCEID)'

				EXEC sp_executesql @sql
	
			END

			IF NOT EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'JointCoating'
								  AND COLUMN_NAME = 'CheckSumValue'
								  AND TABLE_SCHEMA='DBO')
			BEGIN
				-- Add checksum Column
				ALTER TABLE JointCoating ADD CheckSumValue int; 
			END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_JointCoating')
						   AND type = 'U')
			BEGIN
				-- Create Load_JointCoating table 

				SET @sql = 'CREATE TABLE [dbo].[Load_JointCoating](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[JointCoatingDomainId] [numeric](10, 0) NULL,
					[JointCoatingComment] [varchar](255) NULL,
					[JointCoatingInstallDate] [datetime] NULL,
					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime],
					[CreatedUser] [varchar](45))'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_JointCoating ADD CONSTRAINT PK_Load_JointCoating PRIMARY KEY (SOURCEID)'

				EXEC sp_executesql @sql
	
			END

			IF NOT EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'InternalCoating'
								  AND COLUMN_NAME = 'CheckSumValue'
								  AND TABLE_SCHEMA='DBO')
			BEGIN
				-- Add checksum Column
				ALTER TABLE InternalCoating ADD CheckSumValue int; 
			END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_InternalCoating')
						   AND type = 'U')
			BEGIN
				-- Create Load_InternalCoating table 

				SET @sql = 'CREATE TABLE [dbo].[Load_InternalCoating](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[InternalCoatingDomainId] [numeric](10, 0) NULL,
					[InternalCoatingComment] [varchar](255) NULL,
					[InternalCoatingInstallDate] [datetime] NULL,
					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime],
					[CreatedUser] [varchar](45))'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_InternalCoating ADD CONSTRAINT PK_Load_InternalCoating PRIMARY KEY (SOURCEID)'

				EXEC sp_executesql @sql
	
			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 13
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 13
		BEGIN
			DECLARE @sql nvarchar(max)

			-- COMMENTED OUT - StructureVertex TABLE DOES NOT EXIST IN KEY_IRASV5_UPSTREAM

			-- New_StructureVertex_Template.sql 
			-- IF NOT EXISTS (SELECT 1
			-- 			   FROM   INFORMATION_SCHEMA.COLUMNS
			-- 			   WHERE  TABLE_NAME = 'StructureVertex'
			-- 					  AND COLUMN_NAME = 'CheckSumValue'
			-- 					  AND TABLE_SCHEMA='DBO')
			-- BEGIN
			-- 	-- Add checksum Column
			-- 	ALTER TABLE StructureVertex ADD CheckSumValue int; 
			-- END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_StructureVertex')
						   AND type = 'U')
			BEGIN
				-- Create Load_StructureVertex table 

				SET @sql = 'CREATE TABLE [dbo].[Load_StructureVertex](
					[StructureId] [numeric](10, 0) NOT NULL,
					[StructureVertexSeq] [numeric](4, 0) NOT NULL,
					[StructureVertexLatitude] [numeric](11, 9) NOT NULL,
					[StructureVertexLongitude] [numeric](12, 9) NOT NULL,
					[StructureVertexX] [numeric](12, 3) NULL,
					[StructureVertexY] [numeric](12, 3) NULL,
					[StructureVertexZ] [numeric](10, 3) NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[StructureGUID] [varchar](50) NULL)'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_StructureVertex ADD CONSTRAINT PK_Load_StructureVertex PRIMARY KEY (STRUCTUREID, STRUCTUREVERTEXSEQ)'

				EXEC sp_executesql @sql
	
			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 14
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 14
		BEGIN
			DECLARE @sql nvarchar(max)

			-- New_Valve_Template.sql
			IF NOT EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'Valve'
								  AND COLUMN_NAME = 'CheckSumValue'
								  AND TABLE_SCHEMA='DBO')
			BEGIN
				-- Add checksum Column
				ALTER TABLE Valve ADD CheckSumValue int; 
			END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_Valve')
						   AND type = 'U')
			BEGIN
				-- Create Load_Valve table 

				SET @sql = 'CREATE TABLE [dbo].[Load_Valve](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[ValveTypeDomainId] [numeric](10, 0) NULL,
					[ValveNum] [numeric](6, 1) NULL,
					[ValveName] [varchar](50) NULL,
					[ValvePiggableInd] [char](1) NULL,
					[ValveComment] [varchar](255) NULL,
					[ValveDiameter] [numeric](8, 5) NULL,
					[ValveOperatorTypeDomainId] [numeric](10, 0) NULL,
					[ValveLatitude] [numeric](11, 9) NULL,
					[ValveLongitude] [numeric](12, 9) NULL,
					[ValveCoordSysDomainId] [numeric](10, 0) NULL,
					[ValveX] [numeric](12, 3) NULL,
					[ValveY] [numeric](12, 3) NULL,
					[ValveZ] [numeric](10, 3) NULL,
					[StationSeriesId] [numeric](10, 0) NOT NULL,
					[StationNum] [numeric](13, 5) NOT NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[ValveConnectDomainID] [numeric](10, 0) NULL,
					[ValveFlowCoefficientSlope] [numeric](12, 9) NULL,
					[ValveFlowCoefficient] [numeric](10, 0) NULL,
					[ValveClosureProfileLD] [numeric](10, 0) NULL,
					[ValveIsCheckFlg] [numeric](1, 0) NULL,
					[ValveWithinFenceInd] [varchar](1) NULL,
					[ValveQstnrPctFraction] [numeric](5, 4) NULL,
					[ValveConditionDomainID] [numeric](10, 0) NULL,
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime],
					[CreatedUser] [varchar](45),
					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL,
					[ValveManufacturerDomainId] [numeric](10, 0) NULL)'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_Valve ADD CONSTRAINT PK_Load_Valve PRIMARY KEY (SOURCEID)'

				EXEC sp_executesql @sql

			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 15
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 15
		BEGIN
			DECLARE @sql nvarchar(max)

			-- New_Vent_Template.sql
			IF NOT EXISTS (SELECT 1
						   FROM   INFORMATION_SCHEMA.COLUMNS
						   WHERE  TABLE_NAME = 'Vent'
								  AND COLUMN_NAME = 'CheckSumValue'
								  AND TABLE_SCHEMA='DBO')
			BEGIN
				-- Add checksum Column
				ALTER TABLE Vent ADD CheckSumValue int; 
			END

			IF NOT EXISTS (SELECT 1
						   FROM sysobjects
						   WHERE id = object_id('Load_Vent')
						   AND type = 'U')
			BEGIN
				-- Create Load_Vent table 

				SET @sql = 'CREATE TABLE [dbo].[Load_Vent](
					[Id] [numeric](10, 0) NOT NULL,
					[EffectiveStartDate] [datetime] NULL,
					[EffectiveEndDate] [datetime] NULL,
					[VentTypeDomainId] [numeric](10, 0) NULL,
					[VentOutsideDiameter] [numeric](9, 5) NULL,
					[VentName] [varchar](100) NULL,
					[VentComment] [varchar](255) NULL,
					[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
					[BeginStationNum] [numeric](13, 5) NOT NULL,
					[EndStationSeriesId] [numeric](10, 0) NOT NULL,
					[EndStationNum] [numeric](13, 5) NOT NULL,
					[VentManufacturingTypeLd] [numeric](10, 0) NULL,
					[VentOutletGrade] [numeric](5, 0) NULL,
					[VentOutletWallthickness] [numeric](9, 5) NULL,
					[VentInletDiameter] [numeric](5, 3) NULL,
					[VentInletGrade] [numeric](5, 0) NULL,
					[VentInletWallThickness] [numeric](9, 5) NULL,
					[VentPressureRating] [numeric](5, 0) NULL,
					[VentOutletDiameter] [numeric](5, 3) NULL,
					[VentConnectDomainId] [numeric](10, 0) NULL,
					[LastModByUserId] [varchar](45),
					[LastModDateTime] [datetime],
					[SourceId] [varchar](50) NOT NULL,
					[CreatedDate] [datetime],
					[CreatedUser] [varchar](45))'

				EXEC sp_executesql @sql

				SET @sql = 'ALTER TABLE Load_Vent ADD CONSTRAINT PK_Load_Vent PRIMARY KEY (SOURCEID)'

				EXEC sp_executesql @sql

			END

			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 16
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 16
		BEGIN

		-- COMMENTED OUT - Facility TABLE DOES NOT EXIST IN KEY_IRASV5_UPSTREAM

			-- SQLQuery_AddModifyColumns_FacilityStageDatabase.sql
			-- IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Facility' and COLUMN_NAME in ('SourceId', 'BeginStationSeriesId', 'BeginStationNum', 
			-- 'EndStationSeriesId', 'EndStationNum', 'BeginStationSeriesGUID', 'EndStationSeriesGUID'))
			-- BEGIN
			--   PRINT 'COLUMNS ALREADY EXISTS'
			-- END
			-- ELSE
			-- BEGIN 
			-- 	ALTER TABLE [dbo].[Facility] ADD  
			-- 		[SourceId] [varchar](50) NULL,
			-- 		[CreatedDate] [datetime] NOT NULL DEFAULT (getdate()),
			-- 		[CreatedUser] [varchar](45) NOT NULL DEFAULT (suser_sname()),
			-- 		[BeginStationSeriesId] [numeric](10, 0) NULL,
			-- 		[BeginStationNum] [numeric](13, 5) NOT NULL,
			-- 		[EndStationSeriesId] [numeric](10, 0) NULL,
			-- 		[EndStationNum] [numeric](13, 5) NOT NULL,
			-- 		[BeginStationSeriesGUID] [varchar](50) NULL,
			-- 		[EndStationSeriesGUID] [varchar](50) NULL

			-- END
			UPDATE dbo.VersionInfo SET TransDBVersionCheckPoint = 17
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630106 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 17
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630201', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 01'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630201 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add CPMatchOffset to alignment tables.sql

			-- This script is for adding CPMatchOffset column to FacilityAlignment and JointAlignment

			IF (NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='FacilityAlignment' AND COLUMN_NAME = 'CPMatchOffset'))
			BEGIN
				Alter table FacilityAlignment 
				Add CPMatchOffset NUMERIC(13,5)
			END

			IF (NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='JointAlignment' AND COLUMN_NAME = 'CPMatchOffset'))
			BEGIN
				Alter table JointAlignment 
				Add CPMatchOffset NUMERIC(13,5)
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630201 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Add Latitude and Longitude to GirthWeld Table.sql

			-- This script is for adding the Latitude and Longitude columns to Girthweld table.

			IF (NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Girthweld' AND COLUMN_NAME = 'Latitude'))
			BEGIN
				Alter table Girthweld 
				Add Latitude NUMERIC(11,9)
			END

			IF (NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Girthweld' AND COLUMN_NAME = 'Longitude'))
			BEGIN
				ALTER TABLE Girthweld 
				ADD Longitude NUMERIC(12,9)
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630201 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630202', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 02'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630202 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CLIENT_LengthWidthDepthToleranceAndStdev_CorrectSizesPerSpec.sql
			-- Set the column sizes to match the 6.3 spec
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFDepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFLengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFDepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFLengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionFeature ALTER COLUMN [ILIFWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630202 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDDepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDLengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDDepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDLengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionNonCrsnDfct ALTER COLUMN [ILINCDWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630202 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICADepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICALengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICAWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICADepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICALengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrackAnomaly ALTER COLUMN [ILICAWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630202 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBDepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBLengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBDepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBLengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE InlineInspectionCrsnCallBox ALTER COLUMN [ILICBWidthToleranceStdDev] [numeric](10,3) NULL
 
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630202 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630203', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 03'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630203 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFDepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFLengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFDepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFLengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILIFeature ALTER COLUMN [ILIFWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630203 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDDepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDLengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDDepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDLengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILINonCrsnDfct ALTER COLUMN [ILINCDWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630203 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICADepthTolerance] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICALengthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICAWidthTolerance] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICADepthToleranceStdDev] [numeric](8,3) NULL
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICALengthToleranceStdDev] [numeric](10,3) NULL
			 ALTER TABLE Stg_ILICrackAnomaly ALTER COLUMN [ILICAWidthToleranceStdDev] [numeric](10,3) NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630203 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			DECLARE @sql nvarchar(max)
			
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBDepthTolerance] [numeric](8,3) NULL
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBLengthTolerance] [numeric](10,3) NULL
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBWidthTolerance] [numeric](10,3) NULL
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBDepthToleranceStdDev] [numeric](8,3) NULL
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBLengthToleranceStdDev] [numeric](10,3) NULL
			ALTER TABLE Stg_ILICrsnCallBox ALTER COLUMN [ILICBWidthToleranceStdDev] [numeric](10,3) NULL

			IF object_id('FK_ActionItemPropertyValue_ActionItemRevision') IS NOT NULL
			BEGIN
				exec sp_rename 'dbo.FK_ActionItemPropertyValue_ActionItemRevision', 'FK_AtnItmPrpValue_ActnItmRvsn'
			END

			IF object_id('FK_ActionItemPropertyValue_ActionItemProperty') IS NOT NULL
			BEGIN
				exec sp_rename 'dbo.FK_ActionItemPropertyValue_ActionItemProperty', 'FK_AtnItmPrpValue_ActnItmPrp'
			END

			IF object_id('PK_ActionItemPropertyDomainCatalogXRef') IS NOT NULL
			BEGIN
				exec sp_rename 'dbo.PK_ActionItemPropertyDomainCatalogXRef', 'PK_ActionItemPropDCXRef'
			END

			IF object_id('FK_ActionItemPropertyDomainCatalogXRef_DomainCatalog') IS NOT NULL
			BEGIN
				exec sp_rename 'dbo.FK_ActionItemPropertyDomainCatalogXRef_DomainCatalog', 'FK_AtnItmPropDCXRef_DmnCtlg'
			END

			IF object_id('FK_ActionItemPropertyDomainCatalogXRef_ActionItemProperty') IS NOT NULL
			BEGIN
				exec sp_rename 'dbo.FK_ActionItemPropertyDomainCatalogXRef_ActionItemProperty', 'FK_AtnItmPropDCXRef_AtnItmPrp'
			END

			IF object_id('ActionItemPropertyDomainCatalogXRef') IS NOT NULL
			BEGIN
				SET @sql = 'exec sp_rename ''dbo.ActionItemPropertyDomainCatalogXRef'', ''ActionItemPropDCXRef'''
				EXEC sp_executesql @sql
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItemPropertyDomainCatalogXRef')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItemPropertyDomainCatalogXRef]'
				EXEC sp_executesql @sql
			END

			IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' and name = 'tu_ActionItemPropDCXRef')
			BEGIN
				SET @sql = 'DROP TRIGGER [dbo].[tu_ActionItemPropDCXRef]'
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE TRIGGER [dbo].[tu_ActionItemPropDCXRef] ON [dbo].ActionItemPropDCXRef FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.ActionItemPropDCXRef
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.ActionItemPropDCXRef as t, DELETED as d
							WHERE t.DomainCatalogId=d.DomainCatalogId
							AND t.ActionItemPropertyId=d.ActionItemPropertyId;
						END'

			EXEC sp_executesql @sql

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630203 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630204', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 04'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630204 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'CouponReading' And c.Column_Name = 'SourceId') 
			BEGIN
				SET @sql = 'ALTER TABLE dbo.CouponReading ADD SourceId varchar(50)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'SeriesConnection' And c.Column_Name = 'SourceId') 
			BEGIN
				SET @sql = 'ALTER TABLE dbo.SeriesConnection ADD SourceId varchar(50)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'HCAPipeGasConstantFactor' And c.Column_Name = 'SourceId') 
			BEGIN
				SET @sql = 'ALTER TABLE dbo.HCAPipeGasConstantFactor ADD SourceId varchar(50)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'HCAPipePIRBuffer' And c.Column_Name = 'SourceId') 
			BEGIN
				SET @sql = 'ALTER TABLE dbo.HCAPipePIRBuffer ADD SourceId varchar(50)'
				EXEC sp_executesql @sql
			END

			--COMMENTED OUT - StructureVertex TABLE DOES NOT EXIST IN KEY_IRASV5_UPSTREAM

			-- IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'StructureVertex' And c.Column_Name = 'SourceId') 
			-- BEGIN
			-- 	SET @sql = 'ALTER TABLE dbo.StructureVertex ADD SourceId varchar(50)'
			-- 	EXEC sp_executesql @sql
			-- END

			-- Cursor To Add CheckSumValue column

			Declare AddCol Cursor for
			Select TABLE_NAME
			from INFORMATION_SCHEMA.COLUMNS where  TABLE_NAME IN ('Area',
			'Bend',
			'Casing',
			'ClassArea',
			'Coating',
			'Corporation',
			'Coupon',
			'CouponReading',
			'CoverDepth',
			'CoverDepthProfile',
			'CPSurvey',
			'CPSurveyRange',
			'CPSurveyReading',
			'Crossing',
			'CrossingLocn',
			'DamagePrevention',
			'DesignClass',
			'DischargeSubsystem',
			'DistrictDivision',
			'Elbow',
			'ElevationProfile',
			'ExcavationProject',
			'ExcavationSite',
			'ExposedPipe',
			'Extrusion',
			'Flange',
			'GirthWeld',
			'HCACFR',
			'HCACFRSeg',
			'HCAPipeGasConstantFactor',
			'HCAPipePIRBuffer',
			'HydroTest',
			'HydroTestRange',
			'Incident',
			'IncidentHistory',
			'InternalCoating',
			'IRASCustomData1',
			'IRASCustomData11',
			'IRASCustomData2',
			'IRASCustomData3',
			'IRASCustomData4',
			'IRASCustomData5',
			'IRASCustomData6',
			'IRASCustomData7',
			'IRASCustomData8',
			'IRASCustomData9',
			'JointCoating',
			'LandUse',
			'LineLoop',
			'MAOP',
			'Marker',
			'MetalLoss',
			'MLVSection',
			'MOP',
			'OperatingUnit',
			--'PipelineSystem',
			'PipeSegment',
			'ProductComponent',
			'Rectifier',
			'RectifierReading',
			'Reducer',
			'RightOfWay',
			'Sleeve',
			'SoilArea',
			'SoilLandUseArea',
			'StateProvince',
			'StationSeries',
			'Structure',
			'StructureVertex',
			'Tap',
			'Tee',
			'TestPostPoint',
			'TestPostPointReading',
			'Valve',
			'Vent',
			'Weight',
			'MLVCorrection',
			'SeriesConnection')

			Declare @Table_Name1 varchar(200)
			Declare @Column_Name varchar(200)
			Declare @add varchar (max)

			Open AddCol

			FETCH NEXT FROM AddCol INTO @Table_Name1

			WHILE @@FETCH_STATUS = 0
			  BEGIN
				Set @add = Null
		
				IF Not EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME= @Table_Name1 and COLUMN_NAME = 'CheckSumValue' )
				BEGIN
					Set @add= 'Alter Table '+@Table_Name1 +' ADD CheckSumValue Int' 
					Print @add
					--Exec (@add)
				END
				ELSE
				BEGIN
					PRINT 'COLUMN EXISTS'
				END
				
				FETCH NEXT FROM AddCol INTO @Table_Name1
				END

			Close AddCol
			Deallocate AddCol

			--COMMENTED OUT The section of this block of script below which creates load tables 

			-- DECLARE DropLoadTable cursor for
			-- 	Select Table_name from INFORMATION_SCHEMA.tables where table_name like 'Load%' 

			-- DECLARE @Table_Name varchar (max)
			-- DECLARE @DropTable varchar (max)
			-- DECLARE @constraint varchar(max)
			-- DECLARE @cons_table varchar(100)

			-- Open DropLoadTable
			-- Fetch next from DropLoadTable into @Table_Name
			-- while @@FETCH_STATUS = 0
			-- Begin
			--   Set @DropTable = Null
			-- 	If  Exists (Select 1 from INFORMATION_SCHEMA.tables where table_name = @Table_Name)
			-- 	 Begin
			-- 		SELECT @constraint = name 
			-- 		FROM SYS.FOREIGN_KEYS
			-- 		WHERE OBJECT_NAME(referenced_object_id) = @Table_Name

			-- 		SELECT @cons_table = OBJECT_NAME(parent_object_id) 
			-- 		FROM SYS.FOREIGN_KEYS
			-- 		WHERE OBJECT_NAME(referenced_object_id) = @Table_Name

			-- 		SET @sql = 'ALTER TABLE ' + @cons_table + ' DROP CONSTRAINT ' + @constraint
			-- 		EXECUTE sp_executesql @sql
					

			-- 		set @DropTable =  'Drop Table ' +@Table_Name
			-- 		Print @DropTable
			-- 		Exec (@DropTable)
			-- 	 End
			-- Fetch next from DropLoadTable into @Table_Name
			-- End

			-- Close DropLoadTable
			-- Deallocate DropLoadTable

			-- -- Cursor To Create Load Table (tables without a SourceId column or that do not exist are commented out)

			-- DECLARE CreateTable cursor for
			-- Select table_name from INFORMATION_SCHEMA.TABLES
			-- where TABLE_NAME IN ('Area',
			-- 'Bend',
			-- 'Casing',
			-- 'ClassArea',
			-- 'Coating',
			-- --'Corporation',
			-- 'Coupon',
			-- 'CouponReading',
			-- 'CoverDepth',
			-- 'CoverDepthProfile',
			-- 'CPSurvey',
			-- 'CPSurveyRange',
			-- 'CPSurveyReading',
			-- 'Crossing',
			-- 'CrossingLocn',
			-- 'DamagePrevention',
			-- 'DesignClass',
			-- 'DischargeSubsystem',
			-- 'DistrictDivision',
			-- 'Elbow',
			-- 'ElevationProfile',
			-- 'ExcavationProject',
			-- 'ExcavationSite',
			-- 'ExposedPipe',
			-- 'Extrusion',
			-- 'Flange',
			-- 'GirthWeld',
			-- 'HCACFR',
			-- 'HCACFRSeg',
			-- 'HCAPipeGasConstantFactor',
			-- 'HCAPipePIRBuffer',
			-- 'HydroTest',
			-- 'HydroTestRange',
			-- 'Incident',
			-- 'IncidentHistory',
			-- 'InternalCoating',
			-- 'IRASCustomData1',
			-- 'IRASCustomData11',
			-- 'IRASCustomData2',
			-- 'IRASCustomData3',
			-- 'IRASCustomData4',
			-- 'IRASCustomData5',
			-- 'IRASCustomData6',
			-- 'IRASCustomData7',
			-- 'IRASCustomData8',
			-- 'IRASCustomData9',
			-- 'JointCoating',
			-- 'LandUse',
			-- 'LineLoop',
			-- 'MAOP',
			-- 'Marker',
			-- 'MetalLoss',
			-- 'MLVSection',
			-- 'MOP',
			-- --'OperatingUnit',
			-- --'PipelineSystem',
			-- 'PipeSegment',
			-- --'ProductComponent',
			-- --'Rectifier',
			-- --'RectifierReading',
			-- 'Reducer',
			-- 'RightOfWay',
			-- 'Sleeve',
			-- 'SoilArea',
			-- 'SoilLandUseArea',
			-- 'StateProvince',
			-- 'StationSeries',
			-- 'Structure',
			-- 'StructureVertex',
			-- 'Tap',
			-- 'Tee',
			-- --'TestPostPoint',
			-- --'TestPostPointReading',
			-- 'Valve',
			-- 'Vent',
			-- 'Weight',
			-- 'MLVCorrection',
			-- 'SeriesConnection'
			-- )

			-- Declare @TableName varchar (max)
			-- Declare @sql1 varchar (max)
			-- Declare @sql2 varchar (max)

			-- Open CreateTable
			-- Fetch next from CreateTable into @TableName
			-- while @@FETCH_STATUS = 0
			-- Begin
			--   Set @sql = Null
			--   Set @sql1 = Null
			--   Set @sql2 = Null
			-- 	If  NOT Exists (Select 1 from INFORMATION_SCHEMA.tables where table_name like 'Load%' +@TableName)
			-- 	 Begin
			-- 	   set @sql =  'SELECT * INTO Load_' +@TableName + ' from ' + @TableName +' where 1 = 2';
			-- 	   Set @sql1 = 'Alter table Load_' + @TableName + ' Alter Column SourceId varchar (50 )Not Null'
			-- 	   set @sql2 = 'Alter table Load_' + @TableName + ' Add Constraint [Pk_' + @TableName + 'SourceId] Primary Key (SourceId)'
			-- 	   Print @Sql
			-- 	   Exec (@sql)
			-- 	   Print @Sql1
			-- 	   Exec (@sql1)
			-- 		Print @Sql2
			-- 	   Exec (@sql2)

			-- 	 End
			-- 	Else
			-- 	 Begin
			-- 	   Print 'Table Already Exists'
			-- 	 End
			-- Fetch next from CreateTable into @TableName
			-- End

			-- Close CreateTable
			-- Deallocate CreateTable

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630204 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @sql nvarchar(max)

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'CheckSumValue' AND c.Data_Type <> 'INT')
			BEGIN
				DECLARE a_cursor CURSOR FOR
					SELECT 'Alter table ' + c.Table_Name + ' Alter Column ' + c.Column_Name + ' INT NULL' FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'CheckSumValue'

				OPEN a_cursor

					FETCH NEXT FROM a_cursor INTO @sql

					WHILE @@FETCH_STATUS = 0
					BEGIN
						EXEC sp_executesql @sql
						FETCH NEXT FROM a_cursor INTO @sql
					END

				CLOSE a_cursor
				DEALLOCATE a_cursor
			END

			--COMMENTED OUT - Tables that do not exist in KEY_IRASV5_UPSTREAM 

			--Adds ChecksumValue column to the tables listed 
			DECLARE add_cursor CURSOR FOR 
				SELECT 'Alter table ' + t.Table_Name + ' Add CheckSumValue INT NULL' FROM INFORMATION_SCHEMA.Tables t Where t.Table_Name IN ('Area',
				'Bend',
				'Casing',
				'ClassArea',
				'Coating',
				--'Corporation',
				'Coupon',
				'CouponReading',
				'CoverDepth',
				'CoverDepthProfile',
				'CPSurvey',
				'CPSurveyRange',
				'CPSurveyReading',
				'Crossing',
				'CrossingLocn',
				'DamagePrevention',
				'DesignClass',
				'DischargeSubsystem',
				'DistrictDivision',
				'Elbow',
				'ElevationProfile',
				'ExcavationProject',
				'ExcavationSite',
				'ExposedPipe',
				'Extrusion',
				'Flange',
				'GirthWeld',
				'HCACFR',
				'HCACFRSeg',
				'HCAPipeGasConstantFactor',
				'HCAPipePIRBuffer',
				'HydroTest',
				'HydroTestRange',
				'Incident',
				'IncidentHistory',
				'InternalCoating',
				'IRASCustomData1',
				'IRASCustomData11',
				'IRASCustomData2',
				'IRASCustomData3',
				'IRASCustomData4',
				'IRASCustomData5',
				'IRASCustomData6',
				'IRASCustomData7',
				'IRASCustomData8',
				'IRASCustomData9',
				'JointCoating',
				'LandUse',
				'LineLoop',
				'MAOP',
				'Marker',
				'MetalLoss',
				'MLVSection',
				'MOP',
				--'OperatingUnit',
				--'PipelineSystem',
				'PipeSegment',
				'ProductComponent',
				'Rectifier',
				'RectifierReading',
				'Reducer',
				'RightOfWay',
				'Sleeve',
				'SoilArea',
				'SoilLandUseArea',
				'StateProvince',
				'StationSeries',
				'Structure',
				'StructureVertex',
				'Tap',
				'Tee',
				--'TestPostPoint',
				--'TestPostPointReading',
				'Valve',
				'Vent',
				'Weight',
				'MLVCorrection',
				'SeriesConnection')
				AND t.Table_Name NOT IN (SELECT c.Table_Name FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'CheckSumValue')

			OPEN add_cursor

				FETCH NEXT FROM add_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM add_cursor INTO @sql
				END

			CLOSE add_cursor
			DEALLOCATE add_cursor

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630204 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 05
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630205', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 05'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630205 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

			--COMMENTED OUT - Load tables do not exist because they were commented out and therefore were not created
			--DECLARE @sql nvarchar(max)

			--DECLARE l_curcor CURSOR FOR
			--	SELECT 'Alter table ' + t.Table_Name + ' Add CheckSumValue INT NOT NULL' FROM INFORMATION_SCHEMA.Tables t Where t.Table_Name LIKE 'Load%'
			--	AND t.Table_Name NOT IN (SELECT c.Table_Name FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'CheckSumValue'
			--	AND c.Table_Name LIKE 'Load%')
			
			--OPEN l_curcor
			--	FETCH NEXT FROM l_curcor INTO @sql 

			--	WHILE @@FETCH_STATUS = 0
			--	BEGIN
			--		EXEC sp_executesql @sql
			--		FETCH NEXT FROM l_curcor INTO @sql 
			--	END

			--CLOSE l_curcor
			--DEALLOCATE l_curcor

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630205 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 06
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630206', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 06'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630206 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			IF object_id('Pk_SeriesConnectionSourceId') IS NOT NULL
			BEGIN
				ALTER TABLE Load_SeriesConnection drop constraint Pk_SeriesConnectionSourceId
			END

			--COMMENTED OUT - Load tables were not created

			--IF object_id('PK_MLVCORRECTIONSOURCEID') IS NOT NULL
			--BEGIN
			--	ALTER TABLE Load_MLVCorrection drop constraint PK_MLVCORRECTIONSOURCEID
			--END

			--ALTER TABLE dbo.Load_SeriesConnection ALTER COLUMN SourceId varchar(50) NULL
			--ALTER TABLE dbo.Load_SeriesConnection ALTER COLUMN CheckSumValue INT NULL
			--ALTER TABLE dbo.Load_MLVCorrection ALTER COLUMN SourceId varchar(50) NULL
			--ALTER TABLE dbo.Load_MLVCorrection ALTER COLUMN CheckSumValue INT NULL

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630206 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 07
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630207', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 07'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630207 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add Virtual Table Load tables.sql
			-- This script is for creating the load tables for Virtual tables
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_STATIONING')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_STATIONING (
								VIRTUALTABLEID numeric(10, 0) NOT NULL,
								VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
								EFFECTIVESTARTDATE DateTime,
								EFFECTIVEENDDATE DateTime,
								BEGINSTATIONSERIESID numeric(10, 0) NOT NULL,
								BEGINSTATIONNUM numeric(13, 5) NOT NULL,
								ENDSTATIONSERIESID numeric(10, 0) NOT NULL,
								ENDSTATIONNUM numeric(13, 5) NOT NULL,
								LASTMODBYUSERID VARCHAR(45) DEFAULT suser_sname() NOT NULL,
								LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
								SOURCEID VARCHAR(50),
								CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
								CREATEDUSER VARCHAR(45) DEFAULT suser_sname() NOT NULL,
								CONSTRAINT PK_LOAD_VIRTUALTABLESTATIONING PRIMARY KEY (VIRTUALTABLESTATIONINGID, VIRTUALTABLEID)
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATASTRING')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATASTRING (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUESTRING Varchar(512),
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATASTRING PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATANUM')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATANUM (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUENUM FLOAT,
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATANUM PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID) 
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATALISTDOMAIN')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATALISTDOMAIN (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUEDOMAINID numeric(10, 0),
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATALISTDOMAIN PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLESTATIONINGID, VIRTUALTABLEID)
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATAIND')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATAIND (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUEIND CHAR(1),
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATAIND PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATAFLG')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATAFLG (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUEFLG numeric(1, 0),
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATAFLG PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'LOAD_VT_DATADATE')
			BEGIN
				SET @sql = 'CREATE TABLE LOAD_VT_DATADATE (
							  VIRTUALCOLUMNID numeric(10, 0) NOT NULL,
							  VIRTUALTABLEID numeric(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID numeric(10, 0) NOT NULL,
							  DATAFIELDVALUEDATE DateTime,
							  LASTMODBYUSERID Varchar(45) DEFAULT suser_sname() NOT NULL,
							  LASTMODDATETIME DateTime DEFAULT getdate() NOT NULL,
							  SOURCEID Varchar(50),
							  CREATEDDATE DateTime DEFAULT getdate() NOT NULL,
							  CREATEDUSER Varchar(45) DEFAULT suser_sname() NOT NULL,
							  CONSTRAINT PK_LOAD_DATADATE PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)'
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630207 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 08
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630208', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 08'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630208 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add sp_Delete_VirtualTableStationing stored proc.sql
			-- This script is for removing the existing virtualtablestatioing records
			DECLARE @sql nvarchar(max)

			IF object_id('sp_Del_VirtualTableStationing') IS NOT NULL
			BEGIN
				SET @sql = 'DROP PROCEDURE sp_Del_VirtualTableStationing'
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE PROCEDURE sp_Del_VirtualTableStationing
						AS
							delete old2
							from VIRTUALTABLESTATIONING old2
							left join
							(
							select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from LOAD_VT_STATIONING
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATADATE
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAFLG
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAIND
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATALISTDOMAIN
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATANUM
							union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATASTRING
							) ss on old2.VirtualTableId = ss.VIRTUALTABLEID
							and old2.VirtualTableStationingId = ss.VIRTUALTABLESTATIONINGID
							where ss.VIRTUALTABLEID is NULL'

			EXEC sp_executesql @sql

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630208 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 09
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630209', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 09'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630209 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CLIENT_BendStrain_CorrectSizesPerSpec36258.sql

			-- Set the bend strain column sizes to match the 6.3 spec
			-- Update ILI and staging tables.
			 -- down from 5,3 to 7,6 !!! fails if any data > 9.999 in the database so using 8,6 instead.
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSTotalStrain [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSHorizontalStrain [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSVerticalStrain [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSHorizontalStrainAtPeak [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSVerticalStrainAtPeak [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSTotalStrainAtPeak [numeric](8,6) NULL -- not in spec but update to match others
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxTotalStrainDif [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxHorizontalStrainDif [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxVerticalStrainDif [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSHorizonStrainDifAtPeak [numeric](8,6) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSVerticalStrainDifAtPeak [numeric](8,6) NULL

			 -- up from 5,3
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxVerticalPipeMove [numeric](7,3) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxHorizontalPipeMove [numeric](7,3) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSMaxTotalPipeMove [numeric](7,3) NULL
 
			 -- down from 13,5 to 10,3 !!! fails if any data > 9999999.999 in the database so using 11,3 instead
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSPeakStrainOdometer [numeric](11,3) NULL
			 ALTER TABLE InlineInspectionBendStrain ALTER COLUMN ILIBSPeakStrainDifOdometer [numeric](11,3) NULL
 
			 -- staging table
			 -- down from 5,3 to 7,6 !!! fails if any data > 9.999 in the database
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSTotalStrain [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSHorizontalStrain [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSVerticalStrain [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSHorizontalStrainAtPeak [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSVerticalStrainAtPeak [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSTotalStrainAtPeak [numeric](8,6) NULL -- not in spec but update to match others
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxTotalStrainDif [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxHorizontalStrainDif [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxVerticalStrainDif [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSHorizonStrainDifAtPeak [numeric](8,6) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSVerticalStrainDifAtPeak [numeric](8,6) NULL
 
			 -- down from 13,5 to 10,3 !!! fails if any data > 9999999.999 in the database so using 11,3 instead
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSPeakStrainOdometer [numeric](11,3) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSPeakStrainDifOdometer [numeric](11,3) NULL

			 -- up from 5,3
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxVerticalPipeMove [numeric](7,3) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxHorizontalPipeMove [numeric](7,3) NULL
			 ALTER TABLE Stg_ILIBendStrain ALTER COLUMN ILIBSMaxTotalPipeMove [numeric](7,3) NULL
 
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630209 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 10
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630210', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 10'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630210 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add DataExchangeLoadLock into SystemPreferences.sql
			INSERT INTO SystemPreferences (ParameterName, Value)
			SELECT 'DataExchangeLoadLock', 'False' where not exists (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DataExchangeLoadLock')
			
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630210 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 11
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630211', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 11'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630211 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add Load_FloodArea and Load_OperatingData tables.sql
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'Load_FloodArea')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_FloodArea](
								[Id] [numeric](10, 0) NULL,
								[EffectiveStartDate] [datetime] NULL,
								[EffectiveEndDate] [datetime] NULL,
								[FloodAreaRangeLD] [numeric](10, 0) NULL,
								[FloodAreaMin] [numeric](10, 0) NULL,
								[FloodAreaMax] [numeric](10, 0) NULL,
								[BeginStationSeriesId] [numeric](10, 0) NULL,
								[BeginStationNum] [numeric](13, 5) NOT NULL,
								[EndStationSeriesId] [numeric](10, 0) NULL,
								[EndStationNum] [numeric](13, 5) NOT NULL,
								[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
								[FloodAreaCode] [varchar](30) NULL,
								[FloodAreaLD] [numeric](10, 0) NULL,
								[SourceId] [varchar](50) NOT NULL,
								[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
								[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[BeginStationSeriesGUID] [varchar](50) NULL,
								[EndStationSeriesGUID] [varchar](50) NULL,
								[CheckSumValue] [int] NULL
							) '


				EXEC sp_executesql @sql
			END

			IF object_id('PK_Load_FloodArea') IS NULL
			BEGIN
				SET @sql = 'ALTER TABLE Load_FloodArea ADD CONSTRAINT PK_Load_FloodArea PRIMARY KEY (SOURCEID)'
				EXEC sp_executesql @sql
			END


			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'Load_OperatingData')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Load_OperatingData](
								[Id] [numeric](10, 0) NULL,
								[EffectiveStartDate] [datetime] NULL,
								[EffectiveEndDate] [datetime] NULL,
								[ProductDomainId] [numeric](10, 0) NULL,
								[OperatingTemperature] [numeric](5, 2) NULL,
								[BeginStationSeriesId] [numeric](10, 0) NULL,
								[BeginStationNum] [numeric](13, 5) NOT NULL,
								[EndStationSeriesId] [numeric](10, 0) NULL,
								[EndStationNum] [numeric](13, 5) NOT NULL,
								[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
								[SourceId] [varchar](50) NOT NULL,
								[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
								[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[BeginStationSeriesGUID] [varchar](50) NULL,
								[EndStationSeriesGUID] [varchar](50) NULL,
								[CheckSumValue] [int] NULL
							)'


				EXEC sp_executesql @sql
			END

			IF object_id('PK_Load_OperatingData') IS NULL
			BEGIN
				SET @sql = 'ALTER TABLE Load_OperatingData ADD CONSTRAINT PK_Load_OperatingData PRIMARY KEY (SOURCEID)'
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630211 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 12
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630212', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 12'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630212 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			--COMMENTED OUT - FloodArea table does not exist

			-- IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'FloodArea' And c.Column_Name = 'CheckSumValue')
			-- BEGIN
			-- 	SET @sql = 'Alter table FloodArea Add CheckSumValue INT NULL'
			-- 	EXEC sp_executesql @sql
			-- END

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630212 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 13
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630213', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 13'

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

-- Removing SourceId and CheckSumValue from MLVCorrectibon and SeriesConnection.sql

BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630213 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- This script is for removing the CheckSumValue and SourceId from MLVCorrection and SeriesConnection Tables

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MLVCorrection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.MLVCorrection DROP COLUMN SourceId
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MLVCorrection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.MLVCorrection DROP COLUMN CheckSumValue
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'SeriesConnection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.SeriesConnection DROP COLUMN SourceId
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'SeriesConnection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.SeriesConnection DROP COLUMN CheckSumValue
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_MLVCorrection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.Load_MLVCorrection DROP COLUMN SourceId
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_MLVCorrection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.Load_MLVCorrection DROP COLUMN CheckSumValue
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_SeriesConnection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.Load_SeriesConnection DROP COLUMN SourceId
			END

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_SeriesConnection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.Load_SeriesConnection DROP COLUMN CheckSumValue
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630213 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 14
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630214', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 14'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630214 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- AlterTable_Valve_MechDmg_Stage.sql
			-- Alter Valve Table to add ValveWithinFenceInd and ValveQstnrPctFraction columns

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Valve' And c.Column_Name = 'ValveWithinFenceInd')
			BEGIN
			ALTER TABLE [dbo].[Valve] ADD ValveWithinFenceInd [varchar](1) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Valve' And c.Column_Name = 'ValveQstnrPctFraction')
			BEGIN
			ALTER TABLE [dbo].[Valve] ADD ValveQstnrPctFraction [numeric](5,4) NULL
			END

				IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'MechanicalDamage')
			BEGIN
				EXECUTE ('CREATE TABLE [dbo].[MechanicalDamage](
						[Id] [numeric](10, 0) NOT NULL,
						[EffectiveStartDate] [datetime] NOT NULL,
						[EffectiveEndDate] [datetime] NULL,
						[ExcavationSiteId] [numeric](10, 0) NOT NULL,
						[InlineInspectionNonCrsnDfctId] [numeric](10, 0) NULL,
						[MechDmgAlternateDefectId] [varchar](25) NULL,
						[MechDmgDefectTypeDomainId] [numeric](10, 0) NULL,
						[MechDmgStatusDomainId] [numeric](10, 0) NULL,
						[MechDmgGirthWeldNum] [numeric](7, 0) NULL,
						[MechDmgDistanceFromGirthWeld] [numeric](10, 3) NULL,
						[MechDmgOrientation] [numeric](3, 0) NULL,
						[MechDmgLength] [numeric](9, 2) NULL,
						[MechDmgWidth] [numeric](9, 2) NULL,
						[MechDmgDepthPct] [numeric](8, 5) NULL,
						[MechDmgDepthPctNPS] [numeric](5, 4) NULL,
						[MechDmgPeakToPeakDepth] [numeric](9, 2) NULL,
						[MechDmgWaveLength] [numeric](9, 2) NULL,
						[MechDmgGrading1DomainId] [numeric](10, 0) NULL,
						[MechDmgGrading2DomainId] [numeric](10, 0) NULL,
						[MechDmgComment] [varchar](255) NULL,
						[StationSeriesId] [numeric](10, 0) NULL,
						[StationNum] [numeric](13, 5) NULL,
						[LastModByUserId] [varchar](45) NOT NULL,
						[LastModDateTime] [datetime] NOT NULL,
						[MechDmgRepairMethodDomainId] [numeric](10, 0) NULL,
					 CONSTRAINT [PK_MechanicalDamage] PRIMARY KEY CLUSTERED 
					(
						[Id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
					) ON [PRIMARY]

					ALTER TABLE [dbo].[MechanicalDamage] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

					ALTER TABLE [dbo].[MechanicalDamage] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechanicalDamageMechDmgDefectTypeDomainId] FOREIGN KEY([MechDmgDefectTypeDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechanicalDamageMechDmgDefectTypeDomainId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechanicalDamageMechDmgGrading1DomainId] FOREIGN KEY([MechDmgGrading1DomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechanicalDamageMechDmgGrading1DomainId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechanicalDamageMechDmgGrading2DomainId] FOREIGN KEY([MechDmgGrading2DomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechanicalDamageMechDmgGrading2DomainId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechanicalDamageMechDmgRepairMethodDomainId] FOREIGN KEY([MechDmgRepairMethodDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechanicalDamageMechDmgRepairMethodDomainId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechanicalDamageMechDmgStatusDomainId] FOREIGN KEY([MechDmgStatusDomainId])
					REFERENCES [dbo].[ListDomain] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechanicalDamageMechDmgStatusDomainId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechDmgExcavationSiteId] FOREIGN KEY([ExcavationSiteId])
					REFERENCES [dbo].[ExcavationSite] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechDmgExcavationSiteId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechDmgILINonCrsnDfctId] FOREIGN KEY([InlineInspectionNonCrsnDfctId])
					REFERENCES [dbo].[InlineInspectionNonCrsnDfct] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechDmgILINonCrsnDfctId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [FK_MechDmgStationSeriesId] FOREIGN KEY([StationSeriesId])
					REFERENCES [dbo].[STATIONSERIES] ([Id])

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [FK_MechDmgStationSeriesId]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CK__Mechanica__MechD__17ED6F58] CHECK  (([MechDmgDepthPctNPS] IS NULL OR [MechDmgDepthPctNPS]<=(1) AND [MechDmgDepthPctNPS]>(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CK__Mechanica__MechD__17ED6F58]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CK__Mechanica__MechD__18E19391] CHECK  (([MechDmgDepthPct] IS NULL OR [MechDmgDepthPct]<=(1) AND [MechDmgDepthPct]>(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CK__Mechanica__MechD__18E19391]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CKC_MECHDMGLENGTH_MECHANIC] CHECK  (([MechDmgLength] IS NULL OR [MechDmgLength]>(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CKC_MECHDMGLENGTH_MECHANIC]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CKC_MECHDMGORIENTATIO_MECHANIC] CHECK  (([MechDmgOrientation] IS NULL OR [MechDmgOrientation]>=(0) AND [MechDmgOrientation]<(360)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CKC_MECHDMGORIENTATIO_MECHANIC]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CKC_MECHDMGPEAKTOPEAK_MECHANIC] CHECK  (([MechDmgPeakToPeakDepth] IS NULL OR [MechDmgPeakToPeakDepth]>=(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CKC_MECHDMGPEAKTOPEAK_MECHANIC]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CKC_MECHDMGWAVELENGTH_MECHANIC] CHECK  (([MechDmgWaveLength] IS NULL OR [MechDmgWaveLength]>(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CKC_MECHDMGWAVELENGTH_MECHANIC]

					ALTER TABLE [dbo].[MechanicalDamage]  WITH CHECK ADD  CONSTRAINT [CKC_MECHDMGWIDTH_MECHANIC] CHECK  (([MechDmgWidth] IS NULL OR [MechDmgWidth]>(0)))

					ALTER TABLE [dbo].[MechanicalDamage] CHECK CONSTRAINT [CKC_MECHDMGWIDTH_MECHANIC]')
			END

			-- Alter Mechanical Damage table to add Begin/End StationSeriesId and StationNum Columns, SourceId, InlineInspectionNonCrsnDfct and CreatedDate and CreatedUser

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MechanicalDamage' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
			ALTER TABLE MechanicalDamage ADD BeginStationSeriesId [numeric](10,0) null
			END
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MechanicalDamage' And c.Column_Name = 'BeginStationNum')
			BEGIN
			ALTER TABLE MechanicalDamage ADD BeginStationNum [numeric](13,5) null
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MechanicalDamage' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
			ALTER TABLE MechanicalDamage ADD EndStationSeriesId [numeric](10,0) null
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MechanicalDamage' And c.Column_Name = 'EndStationNum')
			BEGIN
			ALTER TABLE MechanicalDamage ADD EndStationNum [numeric](13,5) null
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MechanicalDamage' And c.Column_Name = 'SourceId')
			BEGIN
			ALTER TABLE MechanicalDamage ADD SourceId [varchar](50) null
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630214 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 15
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630215', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 15'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630215 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MLVCorrection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.MLVCorrection ADD CheckSumValue INT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'MLVCorrection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.MLVCorrection ADD SourceId Varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'SeriesConnection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE dbo.SeriesConnection ADD CheckSumValue INT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'SeriesConnection' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE dbo.SeriesConnection ADD SourceId Varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'Load_MLVCorrection')
			BEGIN
				SET @sql = 'Select * INTO Load_MLVCorrection from MLVCorrection WHERE 1 = 0'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_MLVCorrection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				SET @sql = 'ALTER TABLE dbo.Load_MLVCorrection ADD CheckSumValue INT NULL'
				EXEC sp_executesql @sql			
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_MLVCorrection' And c.Column_Name = 'SourceId')
			BEGIN
				SET @sql = 'ALTER TABLE dbo.Load_MLVCorrection ADD SourceId Varchar(50) NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'Load_SeriesConnection')
			BEGIN
				SET @sql = 'Select * INTO Load_SeriesConnection from SeriesConnection WHERE 1 = 0'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_SeriesConnection' And c.Column_Name = 'CheckSumValue')
			BEGIN
				SET @sql = 'ALTER TABLE dbo.Load_SeriesConnection ADD CheckSumValue INT NULL'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_SeriesConnection' And c.Column_Name = 'SourceId')
			BEGIN
				SET @sql = 'ALTER TABLE dbo.Load_SeriesConnection ADD SourceId Varchar(50) NULL'
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630215 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 16
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630216', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 16'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630216 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'Load_Valve')
			BEGIN
				SET @sql = 'Select * INTO Load_Valve from Valve WHERE 1 = 0'
				EXEC sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_Valve' And c.Column_Name = 'ValveWithinFenceInd')
			BEGIN
				set @sql = 'Alter Table Load_Valve Add ValveWithinFenceInd varchar(1) NULL'
				exec sp_executesql @sql
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'Load_Valve' And c.Column_Name = 'ValveQstnrPctFraction')
			BEGIN
				set @sql = 'Alter Table Load_Valve Add ValveQstnrPctFraction numeric(5,4) NULL'
				exec sp_executesql @sql
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630216 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 17
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630217', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 17'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630217 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'OperatingData' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE OperatingData ADD CheckSumValue INT NULL
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630217 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 18
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630218', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 18'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630218 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--COMMENTED OUT - Creation of Loading tables

			--DECLARE @sql nvarchar(max)

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'Load_CrossingLocn')
			--BEGIN
			--	SET @sql = 'SELECT * INTO Load_CrossingLocn FROM CrossingLocn WHERE 1 = 0'
			--	EXEC sp_executesql @sql
			--END

			--IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'Load_CouponReading')
			--BEGIN
			--	SET @sql = 'SELECT * INTO Load_CouponReading FROM CouponReading WHERE 1 = 0'
			--	EXEC sp_executesql @sql
			--END

			-- COMMENTED OUT - Failed to create Load_RectifierReading because load tables were not creation was commented out and RectifierReading does not have a SourceId column 
			
			--IF object_id('Pk_RectifierReadingSourceId') IS NOT NULL
			--BEGIN
			--	SET @sql = 'ALTER TABLE Load_RectifierReading
			--				DROP CONSTRAINT Pk_RectifierReadingSourceId'
	
			--	EXEC sp_executesql @sql
			--END

			--IF object_id('PK_Load_RectifierReading') IS NULL
			--BEGIN
			--	SET @sql = 'ALTER TABLE Load_RectifierReading ADD CONSTRAINT PK_Load_RectifierReading PRIMARY KEY (SourceId, RctfrReadingDate)'

			--	EXEC sp_executesql @sql
			--END

--			IF object_id('Pk_CrossingLocnSourceId') IS NOT NULL
--			BEGIN
--				SET @sql = 'ALTER TABLE Load_CrossingLocn
--							DROP CONSTRAINT Pk_CrossingLocnSourceId'
	
--				EXEC sp_executesql @sql
--			END


--			IF object_id('Pk_Load_CrossingLocn') IS NULL
--			BEGIN
--				SET @sql = 'ALTER TABLE Load_CrossingLocn ADD CONSTRAINT Pk_Load_CrossingLocn PRIMARY KEY (SourceId, StationSeriesId)'

--				EXEC sp_executesql @sql
--			END

--			IF object_id('Pk_CouponReadingSourceId') IS NOT NULL
--			BEGIN
--				SET @sql = 'ALTER TABLE Load_CouponReading
--							DROP CONSTRAINT Pk_CouponReadingSourceId'
	
--				EXEC sp_executesql @sql
--			END


--			IF object_id('Pk_Load_CouponReading') IS NULL
--			BEGIN
--				SET @sql = 'ALTER TABLE Load_CouponReading ALTER COLUMN CouponReadingDate datetime NOT NULL
--'
--				EXEC sp_executesql @sql

--				SET @sql = 'ALTER TABLE Load_CouponReading ADD CONSTRAINT Pk_Load_CouponReading PRIMARY KEY (SourceId, CouponReadingDate)'

--				EXEC sp_executesql @sql
--			END	
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630218 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 19
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630219', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 19'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630219 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--COMMENTED OUT - FloodArea table does not exist

			--ALTER TABLE [dbo].[FloodArea] ALTER COLUMN [Id] [numeric](10, 0) NOT NULL

			--DECLARE @sql nvarchar(max)
			-- SET @sql = 'If object_id(''PK_FloodArea'') IS NULL
			-- 			BEGIN
			-- 				ALTER TABLE FloodArea ADD CONSTRAINT PK_FloodArea Primary Key (Id)
			-- 			END'

			-- EXEC sp_executesql @sql

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630219 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 20
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630220', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 20'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630220 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF object_id('sp_Before_Load_VirtualTable') IS NULL
			BEGIN
				SET @sql = 'Create PROCEDURE [dbo].[sp_Before_Load_VirtualTable]
							@VirtualTableList varchar(2000)
							AS
							BEGIN
								DECLARE @sqlStatement nvarchar(4000)

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataDate WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataFlg WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataInd WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataNum WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataString WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								SET @sqlStatement = ''DELETE FROM dbo.VirtualTableDataListDomain WHERE VirtualTableId IN (
											SELECT vt.Id FROM dbo.VirtualTable vt
											WHERE vt.VirtualTableName IN ('' + @VirtualTableList + ''))''

								EXEC sp_executesql @sqlStatement

								delete old2
								from VIRTUALTABLESTATIONING old2
								left join
								(
								select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATADATE
								union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAFLG
								union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAIND
								union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATALISTDOMAIN
								union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATANUM
								union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATASTRING
								) ss on old2.VirtualTableId = ss.VIRTUALTABLEID
								and old2.VirtualTableStationingId = ss.VIRTUALTABLESTATIONINGID
								where ss.VIRTUALTABLEID is NULL

							END'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630220 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 21
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630221', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 21'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630221 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF OBJECT_ID('sp_LoadHCAReasons') IS NOT NULL
			BEGIN
				SET @sql = 'DROP PROCEDURE sp_LoadHCAReasons'
				EXEC sp_executesql @sql
			END

			SET @sql = 'CREATE PROCEDURE [dbo].[sp_LoadHCAReasons]
						AS
						BEGIN
							  DELETE FROM HCAReasons
      
							  INSERT INTO HCAReasons (HCACFRSEgID, RCHCAReasonTypeId)
							  Select ID, CASE WHEN (RCReasonTypeID IS NULL) THEN 16 ELSE RCREASONTYPEID END AS RCReasonTypeID from HCACFRSeg 
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
	ROLLBACK TRAN
END CATCH

GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630221 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 22
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630222', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 22'

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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630222 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'RiskResultData' And c.Column_Name = 'ResultTableName')
			BEGIN
				SET @sql = 'ALTER TABLE RiskResultData ADD ResultTableName VARCHAR(100)'
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
		IF (SELECT TransDBVersion FROM dbo.VersionInfo vi) = 630222 AND (SELECT TransDBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 23
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET TransDBVersion = '630223', TransDBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 23'

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