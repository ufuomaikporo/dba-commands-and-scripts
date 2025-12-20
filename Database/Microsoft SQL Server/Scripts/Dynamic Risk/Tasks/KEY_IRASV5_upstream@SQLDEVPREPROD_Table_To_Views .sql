----------------------------------------------	DROP VIEWS IF THEY ALREADY EXIST---------------------------------------------

IF OBJECT_ID('dbo.InternalCoating', 'V') IS NOT NULL
	DROP VIEW dbo.InternalCoating;
GO

IF OBJECT_ID('dbo.OperatingData', 'V') IS NOT NULL
	DROP VIEW dbo.OperatingData;
GO

IF OBJECT_ID('dbo.MOP', 'V') IS NOT NULL
	DROP VIEW dbo.MOP;
GO

--------------------------------------------------CREATE TABLES--------------------------------------------------------------

-- Create dbo.InternalCoating Table
IF OBJECT_ID('dbo.InternalCoating', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[InternalCoating](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[InternalCoatingDomainId] [numeric](7, 0) NULL,
		[InternalCoatingComment] [varchar](255) NULL,
		[InternalCoatingInstallDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[CheckSumValue] [int] NULL,
		CONSTRAINT [PK_InternalCoating] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[InternalCoating] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[InternalCoating] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[InternalCoating] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[InternalCoating] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
END
GO

-- Create dbo.MOP Table
IF OBJECT_ID('dbo.MOP', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[MOP](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[DesignPressure] [numeric](15, 4) NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[CheckSumValue] [int] NULL,
		CONSTRAINT [PK_MOP] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[MOP] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[MOP] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[MOP] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[MOP] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
END
GO

-- Create dbo.OperatingData Table
IF OBJECT_ID('dbo.OperatingData', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[OperatingData](
		[Id] [numeric](10, 0) NOT NULL,
		[Oid] [varchar](40) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[ProductDomainId] [numeric](7, 0) NULL,
		[OperatingTemperature] [numeric](5, 2) NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[CheckSumValue] [int] NULL,
		CONSTRAINT [PK_OperatingData] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[OperatingData] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[OperatingData] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[OperatingData] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[OperatingData] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
END
GO

----------------------------------------------LOAD TABLES WITH STORED PROCEDURE-----------------------------------------------

-- Drop the stored procedure for loading tables if it already exists
IF OBJECT_ID('sp_LoadTables', 'P') IS NOT NULL
DROP PROCEDURE sp_LoadTables
GO

-- Create stored procedure to load tables
CREATE PROCEDURE sp_LoadTables
AS

-- Delete data from tables
DELETE FROM dbo.Internalcoating;
DELETE FROM dbo.MOP;
DELETE FROM dbo.OperatingData

-- Insert into tables
INSERT INTO dbo.Internalcoating
			(Id,
			EffectiveStartDate,
			EffectiveEndDate,
			InternalCoatingDomainId,
			InternalCoatingComment,
			InternalCoatingInstallDate,
			BeginStationSeriesId,
			BeginStationNum,
			EndStationSeriesId,
			EndStationNum,
			LastModByUserId,
			LastModDateTime,
			SourceId,
			CreatedDate,
			CreatedUser)
SELECT  p.Id, 
		GETDATE() AS EffectiveStartDate, 
		CAST(NULL AS datetime) AS EffectiveEndDate,
        (SELECT        Id
        FROM            dbo.ListDomain AS ld
        WHERE        (DomainCatalogId =
                                        (SELECT        Id
                                        FROM            dbo.DomainCatalog
                                        WHERE        (DomainDescr = 'Internal Coating Type'))) AND (Code =
                                        (SELECT        Code
                                        FROM            dbo.PL100InternalProtection
                                        WHERE        (Id = p.PL100InternalProtectionLd)))) AS InternalCoatingDomainId, 
		CAST(NULL AS varchar(255)) AS InternalCoatingComment, 
		CAST(NULL AS datetime) AS InternalCoatingInstallDate, 
		ss.Id AS BeginStationSeriesId, 
		ss.BeginStationNum, 
		ss.Id AS EndStationSeriesId, 
		ss.EndStationNum, 
		SUSER_SNAME() AS LastModByUserId, 
		GETDATE() AS LastModDateTime, 
		CAST(NULL AS varchar(50)) AS SourceId, 
		GETDATE() AS CreatedDate, 
		SUSER_SNAME() AS CreatedUser
FROM  dbo.Pl100 AS p INNER JOIN
          dbo.STATIONSERIES AS ss ON p.LineId = ss.LineId

INSERT INTO	dbo.MOP
			(Id,
			EffectiveStartDate,
			EffectiveEndDate,
			DesignPressure,
			BeginStationSeriesId,
			BeginStationNum,
			EndStationSeriesId,
			EndStationNum,
			LastModByUserId,
			LastModDateTime,
			SourceId,
			CreatedDate,
			CreatedUser)
SELECT  Id, 
		EffectiveStartDate, 
		EffectiveEndDate, 
		UPSDesignOperatingPressure AS DesignPressure,
		StationSeriesId AS BeginStationSeriesId, 
		BeginStationNum, 
		StationSeriesId AS EndStationSeriesId, 
		EndStationNum, 
        LastModByUserId, 
		LastModDate AS LastModDateTime, 
		CAST(NULL AS varchar(50)) AS SourceId, 
		CreateDate AS CreatedDate, 
		CreateByUserId AS CreatedUser	
FROM            dbo.UpstreamPipeSegment AS ups

INSERT INTO [dbo].[OperatingData]
           ([Id],
		    [Oid],
			[EffectiveStartDate],
			[EffectiveEndDate],
			[ProductDomainId],
			[OperatingTemperature],
			[BeginStationSeriesId],
			[BeginStationNum],
			[EndStationSeriesId],
			[EndStationNum],
			[LastModByUserId],
			[LastModDateTime],
			[SourceId],
			[CreatedDate],
			[CreatedUser])
SELECT   p.Id, 
		(newid()) AS Oid, 
		minDate AS EffectiveStartDate, 
		cast(NULL AS datetime) AS EffectiveEndDate, 
		(SELECT        Id
         FROM            dbo.ListDomain AS ld
         WHERE        (DomainCatalogId =
                (SELECT        Id
                FROM            dbo.DomainCatalog
                WHERE        (DomainDescr = 'Product Type'))) AND (Code =
                (SELECT        Code
                FROM            PL100Substance
                WHERE        (Id = p.PL100SubStanceALd)))) AS ProductDomainId,
		cast(NULL AS numeric(5, 2)) AS OperatingTemperature, 
		ss.Id AS BeginStationSeriesId, 
		ss.BeginStationNum, 
        ss.Id AS EndStationSeriesId, 
		ss.EndStationNum, 
		suser_sname() AS LastModByUserId,
		getdate() AS LastModDateTime,
		cast(NULL AS varchar(50)) AS SourceId,
		getdate() AS CreatedDate,  
		suser_sname() AS CreatedUser                       
FROM  dbo.Pl100 p CROSS APPLY
    (SELECT        min(d) AS minDate
     FROM            (VALUES (p.PL100PermitApprovalDate), (p.PL100PermitExpiryDate), (p.PL100LicenceApprovalDate)) AS a(d)) a INNER JOIN
StationSeries ss ON ss.LineId = p.LineId

GO

-- Load Tables
BEGIN TRANSACTION
EXECUTE sp_LoadTables
COMMIT;

-------------------------------------------------CREATE TABLE TRIGGERS-----------------------------------------------------
IF OBJECT_ID('dbo.tu_InternalCoating', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_InternalCoating] ON [dbo].[InternalCoating] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.InternalCoating
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.InternalCoating as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[InternalCoating] ENABLE TRIGGER [tu_InternalCoating]
GO

IF OBJECT_ID('dbo.tu_mop', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_mop] ON [dbo].[MOP] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.MOP
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.MOP as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[MOP] ENABLE TRIGGER [tu_mop]
GO

IF OBJECT_ID('dbo.tu_operatingdata', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_operatingdata] ON [dbo].[OperatingData] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.OperatingData
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.OperatingData as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[OperatingData] ENABLE TRIGGER [tu_operatingdata]
GO

