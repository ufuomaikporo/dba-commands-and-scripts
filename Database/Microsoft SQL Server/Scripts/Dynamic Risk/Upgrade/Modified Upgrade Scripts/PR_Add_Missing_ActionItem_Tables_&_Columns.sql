-- Add CheckSumValue column to tables that are missing them
BEGIN
	
	IF COL_LENGTH('DischargeSubsystem','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE DischargeSubsystem ADD CheckSumValue INT NULL')

	IF COL_LENGTH('LineLoop','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE LineLoop ADD CheckSumValue INT NULL')

	IF COL_LENGTH('StationSeries','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE StationSeries ADD CheckSumValue INT NULL')

	IF COL_LENGTH('MLVSection','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE MLVSection ADD CheckSumValue INT NULL')

	IF COL_LENGTH('SeriesConnection','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE SeriesConnection ADD CheckSumValue INT NULL')

	IF COL_LENGTH('Pipelinesystem','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE Pipelinesystem ADD CheckSumValue INT NULL')

	IF COL_LENGTH('OperatingUnit','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE OperatingUnit ADD CheckSumValue INT NULL')

	IF COL_LENGTH('Corporation','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE Corporation ADD CheckSumValue INT NULL')

	IF COL_LENGTH('Corporation','CheckSumValue') IS NULL
		EXECUTE ('ALTER TABLE Corporation ADD CheckSumValue INT NULL')
END

-- Add Primary Key constraint to ActionItemRevision table if it's missing
IF NOT EXISTS (SELECT 1 from sys.key_constraints
	WHERE parent_object_id = OBJECT_ID('ActionItemRevision')
	AND type = 'PK') 
BEGIN
	EXECUTE ('ALTER TABLE dbo.ActionItemRevision ADD CONSTRAINT PK_ActionItemRevision PRIMARY KEY (Id)')
END

--Create ActionItemProperty table if it does not exist
IF OBJECT_ID('ActionItemProperty', 'U') IS NULL
BEGIN
	EXECUTE ('CREATE TABLE [dbo].[ActionItemProperty](
			[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
			[Name] [varchar](255) NOT NULL,
			[DisplayName] [varchar](255) NOT NULL,
			[PropertyType] [numeric](3, 0) NOT NULL,
			[IsRequired] [numeric](1, 0) NULL,
			[IsReadOnly] [numeric](1, 0) NULL,
			[EffectiveEndDate] [datetime] NULL,
			[CreatedUser] [varchar](64) NOT NULL,
			[CreatedDate] [datetime] NOT NULL,
			[LastModByUserId] [varchar](64) NOT NULL,
			[LastModDateTime] [datetime] NOT NULL,
		 CONSTRAINT [PK_ActionItemProperty] PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
		 CONSTRAINT [UQ_ActionItemProperty_Name] UNIQUE NONCLUSTERED 
		(
			[Name] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]
		GO

		ALTER TABLE [dbo].[ActionItemProperty] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
		GO

		ALTER TABLE [dbo].[ActionItemProperty] ADD  DEFAULT (getdate()) FOR [CreatedDate]
		GO

		ALTER TABLE [dbo].[ActionItemProperty] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
		GO

		ALTER TABLE [dbo].[ActionItemProperty] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

		')

		IF OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL AND OBJECT_ID('FK_AtnItmPropDCXRef_AtnItmPrp', 'F') IS NULL
		BEGIN
			ALTER TABLE dbo.ActionItemPropDCXRef WITH CHECK ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
			FOREIGN KEY(ActionItemPropertyId) REFERENCES dbo.ActionItemProperty(Id)
		END

		IF OBJECT_ID('ActionItemPropertyValue', 'U') IS NOT NULL AND OBJECT_ID('FK_AtnItmPrpValue_ActnItmPrp', 'F') IS NULL
		BEGIN
			ALTER TABLE dbo.ActionItemPropertyValue WITH CHECK ADD CONSTRAINT FK_AtnItmPrpValue_ActnItmPrp 
			FOREIGN KEY(ActionItemPropertyId) REFERENCES dbo.ActionItemProperty(Id)
		END
END

--IF OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL AND OBJECT_ID('FK_AtnItmPropDCXRef_AtnItmPrp', 'F') IS NULL
--BEGIN
--	ALTER TABLE dbo.ActionItemPropDCXRef WITH CHECK ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
--	FOREIGN KEY(ActionItemPropertyId) REFERENCES dbo.ActionItemProperty(Id);
--END

--IF OBJECT_ID('ActionItemPropertyValue', 'U') IS NOT NULL AND OBJECT_ID('FK_AtnItmPrpValue_ActnItmPrp', 'F') IS NULL
--BEGIN
--	ALTER TABLE dbo.ActionItemPropertyValue WITH CHECK ADD CONSTRAINT FK_AtnItmPrpValue_ActnItmPrp 
--	FOREIGN KEY(ActionItemPropertyId) REFERENCES dbo.ActionItemProperty(Id);
--END
