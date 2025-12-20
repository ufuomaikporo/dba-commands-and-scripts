-- Drop Views if they exist

IF OBJECT_ID('dbo.DischargeSubSystem', 'V') IS NOT NULL
	DROP VIEW dbo.DischargeSubSystem;
GO

IF OBJECT_ID('dbo.LineLoop', 'V') IS NOT NULL
	DROP VIEW dbo.LineLoop;
GO

IF OBJECT_ID('dbo.MLVCorrection', 'V') IS NOT NULL
	DROP VIEW dbo.MLVCorrection;
GO

IF OBJECT_ID('dbo.MLVSection', 'V') IS NOT NULL
	DROP VIEW dbo.MLVSection;
GO

-- Create dbo.DischargeSubSystem Table

IF OBJECT_ID('dbo.DischargeSubsystem', 'U') IS NULL
CREATE TABLE [dbo].[DischargeSubsystem](
	[Id] [numeric](10, 0) NOT NULL,
	[PipelineSystemId] [numeric](10, 0) NOT NULL,
	[DischargeSubsystemName] [varchar](70) NOT NULL,
	[DischargeSubsystemAltName] [varchar](100) NULL,
	[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
	[SourceId] [varchar](50) NULL,
	[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
	[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[CheckSumValue] [int] NULL,
 CONSTRAINT [PK_DischargeSubsystem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Create dbo.LineLoop Table

IF OBJECT_ID('dbo.LineLoop', 'U') IS NULL
CREATE TABLE [dbo].[LineLoop](
	[Id] [numeric](10, 0) NOT NULL,
	[PipelineSystemId] [numeric](10, 0) NOT NULL,
	[LineName] [varchar](70) NOT NULL,
	[LineAltName] [varchar](100) NULL,
	[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
	[LineLoopTypeLd] [numeric](7, 0) NULL,
	[LineLoopStatusLd] [numeric](7, 0) NULL,
	[LineLoopProdTypeLd] [numeric](7, 0) NULL,
	[LineLoopLiquidInd] [char](1) DEFAULT ('U') NULL,
	[LineLoopReverseFlowInd] [char](1) DEFAULT ('U') NULL,
	[SourceId] [varchar](50) NULL,
	[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
	[CreatedUser] [varchar](45) DEFAULT(suser_sname()) NOT NULL,
	[CheckSumValue] [int] NULL,
 CONSTRAINT [PK_LineLoopTBL] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Create dbo.MLVCorrection Table

IF OBJECT_ID('dbo.MLVCorrection', 'U') IS NULL
CREATE TABLE [dbo].[MLVCorrection](
	[Id] [numeric](10, 0) NOT NULL,
	[EffectiveStartDate] [datetime] NULL,
	[EffectiveEndDate] [datetime] NULL,
	[MultiplierNum] [numeric](5, 3) DEFAULT ((1)) NOT NULL,
	[FactorNum] [numeric](13, 5) NOT NULL,
	[MLVSectionId] [numeric](10, 0) NOT NULL,
	[StateProvinceDomainId] [numeric](7, 0) NOT NULL,
	[DistrictDivisionDomainId] [numeric](7, 0) NOT NULL,
	[AreaDomainId] [numeric](7, 0) NOT NULL,
	[StationSeriesId] [numeric](10, 0) NOT NULL,
	[BeginStationNum] [numeric](13, 5) NOT NULL,
	[EndStationNum] [numeric](13, 5) NOT NULL,
	[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
	[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
	[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[CheckSumValue] [int] NULL,
	[SourceId] [varchar](50) NULL,
 CONSTRAINT [PK_MLVCorrection] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Create dbo.MLVSection Table

IF OBJECT_ID('dbo.MLVSection', 'U') IS NULL
CREATE TABLE [dbo].[MLVSection](
	[Id] [numeric](10, 0) NOT NULL,
	[MLVSectionName] [varchar](70) NOT NULL,
	[UpstreamCompressorName] [varchar](100) NULL,
	[DownstreamCompressorName] [varchar](100) NULL,
	[ValveSectionNumberDomainId] [numeric](7, 0) NULL,
	[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
	[SourceId] [varchar](50) NULL,
	[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
	[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
	[CheckSumValue] [int] NULL,
 CONSTRAINT [PK_MLVSection] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Create Procedure to load tables

IF OBJECT_ID('sp_LoadTables', 'P') IS NULL
EXECUTE dbo.sp_executesql @statement = N'
CREATE PROCEDURE sp_LoadTables
AS
DELETE FROM dbo.DischargeSubsystem;
DELETE FROM dbo.LineLoop;
DELETE FROM dbo.MLVCorrection;
DELETE FROM dbo.MLVSection;

INSERT INTO dbo.DischargeSubsystem
       ([Id]
      ,[PipelineSystemId]
      ,[DischargeSubsystemName]
      ,[DischargeSubsystemAltName]
      ,[LastModByUserId]
      ,[LastModDateTime]
      ,[SourceId]
      ,[CreatedDate]
      ,[CreatedUser])
SELECT Id, 
       HierarchyId AS PipelineSystemId, 
       LineName AS DischargeSubsystemName, 
	   LineAltName AS DischargeSubsystemAltName, 
	   LastModByUserId,
	   LastModDate AS LastModDateTime,
	   CAST(NULL AS varchar(50)) AS SourceId, 
	   CreateDate AS CreatedDate, 
       CreateByUserId AS CreatedUser 
FROM          dbo.Line AS l;

INSERT INTO dbo.LineLoop
       ([Id]
      ,[PipelineSystemId]
      ,[LineName]
      ,[LineAltName]
      ,[LastModByUserId]
      ,[LastModDateTime]
      ,[LineLoopTypeLd]
      ,[LineLoopStatusLd]
      ,[LineLoopProdTypeLd]
      ,[LineLoopLiquidInd]
      ,[LineLoopReverseFlowInd]
      ,[SourceId]
      ,[CreatedDate]
      ,[CreatedUser])
SELECT DISTINCT(l.Id), 
       l.HierarchyId AS PipelineSystemId, 
       l.LineName, 
	   s.Remarks AS LineAltName,
	   l.LastModByUserId,
	   l.LastModDate AS LastModDateTime, 
       (SELECT        Id
        FROM            dbo.ListDomain AS ld
        WHERE        (DomainCatalogId =
                      (SELECT        Id
                       FROM            dbo.DomainCatalog AS dc
                       WHERE        (DomainDescr = ''LineLoopType''))) AND (Code =
                                                              (SELECT        Code
                                                               FROM            dbo.LineType AS lt
                                                               WHERE        (Id = l.LineTypeLd)))) AS LineLoopTypeLd,
        (SELECT        Id
         FROM            dbo.ListDomain AS ld
         WHERE        (DomainCatalogId =
                                    (SELECT        Id
                                     FROM            dbo.DomainCatalog AS dc
                                     WHERE        (DomainDescr = ''LineLoopStatus''))) AND (Code =
                                                             (SELECT        Code
                                                               FROM            dbo.GLdStatus AS gs
                                                               WHERE        (Id = l.LineStatusGLd)))) AS LineLoopStatusLd, 
	     CAST(NULL AS NUMERIC(7, 0)) AS LineLoopProdTypeLd, 
		 CAST(NULL AS CHAR(1)) AS LineLoopLiquidInd,
		 CAST(NULL AS CHAR(1)) AS LineLoopReverseFlowInd, 
		 CAST(NULL AS VARCHAR(50)) AS SourceId, 
		 l.CreateDate AS CreatedDate, 
		 l.CreateByUserId AS CreatedUser
FROM            dbo.Line AS l INNER JOIN
                         dbo.STATIONSERIES AS s ON l.Id = s.LineId

INSERT INTO [dbo].[MLVCorrection]
           ([Id]
		   ,[EffectiveStartDate]
           ,[EffectiveEndDate]
           ,[MultiplierNum]
           ,[FactorNum]
           ,[MLVSectionId]
           ,[StateProvinceDomainId]
           ,[DistrictDivisionDomainId]
           ,[AreaDomainId]
           ,[StationSeriesId]
           ,[BeginStationNum]
           ,[EndStationNum]
           ,[LastModByUserId]
           ,[LastModDateTime]
           ,[CreatedDate]
           ,[CreatedUser]
           ,[SourceId])
SELECT     Row_Number() OVER (ORDER BY s.Id) AS Id, 
		   s.EffectiveStartDate, 
		   s.EffectiveEndDate,
		   s.MultiplierNum,
		   s.FactorNum, 
		   s.Id AS MLVSectionId,
		   (SELECT        ld.Id
            FROM            dbo.ListDomain ld
            WHERE        ld.DomainCatalogId =
                                    (SELECT        dc.Id
                                      FROM            dbo.DomainCatalog dc
                                      WHERE        dc.DomainDescr = ''State / Province Name'') AND ld.Code = ''Unknown'') AS StateProvinceDomainId,
           (SELECT        ld.Id
            FROM            dbo.ListDomain ld
            WHERE        ld.DomainCatalogId =
                                    (SELECT        dc.Id
                                      FROM            dbo.DomainCatalog dc
                                      WHERE        dc.DomainDescr = ''District / Division Name'') AND ld.Code = ''Unknown'') AS DistrictDivisionDomainId,
		   (SELECT        ld.Id
            FROM            dbo.ListDomain ld
		    WHERE        ld.DomainCatalogId =
                                    (SELECT        dc.Id
                                      FROM            dbo.DomainCatalog dc
                                      WHERE        dc.DomainDescr = ''Area Name'') AND ld.Code = ''Unknown'') AS AreaDomainId,
		   s.Id AS StationSeriesId,  
		   s.BeginStationNum, 
		   s.EndStationNum,
		   s.LastModByUserId,
		   s.LastModDate AS LastModDateTime,
		   s.CreateDate AS CreatedDate, 
		   s.CreateByUserId AS CreatedUser,
		   cast(NULL AS varchar(50)) AS SourceId
            
FROM            dbo.STATIONSERIES s

INSERT INTO [dbo].[MLVSection]
           ([Id]
           ,[MLVSectionName]
           ,[UpstreamCompressorName]
           ,[DownstreamCompressorName]
           ,[ValveSectionNumberDomainId]
           ,[LastModByUserId]
           ,[LastModDateTime]
           ,[SourceId]
           ,[CreatedDate]
           ,[CreatedUser])
SELECT      Id, 
            StationSeriesName AS MLVSectionName, 
			CAST(NULL AS varchar(100)) AS UpstreamCompressorName, 
			CAST(NULL AS varchar(100)) AS DownstreamCompressorName, 
			CAST(NULL AS numeric(7, 0)) AS ValveSectionNumberDomainId, 
			LastModByUserId,
			LastModDate AS LastModDateTime, 
			CAST(NULL AS varchar(50)) AS SourceId,
			CreateDate AS CreatedDate,
			CreateByUserId AS CreatedUser		
FROM            dbo.STATIONSERIES AS s'
GO

-- Load Tables

EXECUTE sp_LoadTables;

-- Recreate Table Triggers

IF OBJECT_ID('dbo.tu_dischargesubsystem', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_dischargesubsystem] ON [dbo].[DischargeSubsystem] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.DischargeSubsystem
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.DischargeSubsystem as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[DischargeSubsystem] ENABLE TRIGGER [tu_dischargesubsystem]
GO

IF OBJECT_ID('dbo.tu_lineloop', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_lineloop] ON [dbo].[LineLoop] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.LineLoop
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.LineLoop as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[LineLoop] ENABLE TRIGGER [tu_lineloop]
GO

IF OBJECT_ID('dbo.tu_mlvcorrection', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_mlvcorrection] ON [dbo].[MLVCorrection] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.MLVCorrection
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.MLVCorrection as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[MLVCorrection] ENABLE TRIGGER [tu_mlvcorrection]
GO

IF OBJECT_ID('dbo.tu_mlvsection', 'TR') IS NULL
EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_mlvsection] ON [dbo].[MLVSection] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
    UPDATE dbo.MLVSection
    SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
    FROM dbo.MLVSection as t, DELETED as d
    WHERE t.Id=d.Id;
END'
GO

ALTER TABLE [dbo].[MLVSection] ENABLE TRIGGER [tu_mlvsection]
GO

