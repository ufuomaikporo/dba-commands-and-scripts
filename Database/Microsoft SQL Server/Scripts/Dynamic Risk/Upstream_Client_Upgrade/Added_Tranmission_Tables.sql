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

IF OBJECT_ID('SoilArea', 'U') IS NULL
BEGIN 
	EXECUTE('CREATE TABLE [dbo].[SoilArea](
			[Id] [numeric](10, 0) NOT NULL,
			[EffectiveStartDate] [datetime] NULL,
			[EffectiveEndDate] [datetime] NULL,
			[SoilTypeLD] [numeric](10, 0) NULL,
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
		 CONSTRAINT [PK_SoilArea] PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]

		ALTER TABLE [dbo].[SoilArea] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

		ALTER TABLE [dbo].[SoilArea] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

		ALTER TABLE [dbo].[SoilArea] ADD  DEFAULT (getdate()) FOR [CreatedDate]

		ALTER TABLE [dbo].[SoilArea] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

		ALTER TABLE [dbo].[SoilArea]  WITH CHECK ADD  CONSTRAINT [FK_SlAr_BgnSttnSrsId] FOREIGN KEY([BeginStationSeriesId])
		REFERENCES [dbo].[StationSeries] ([Id])

		ALTER TABLE [dbo].[SoilArea] CHECK CONSTRAINT [FK_SlAr_BgnSttnSrsId]

		ALTER TABLE [dbo].[SoilArea]  WITH CHECK ADD  CONSTRAINT [FK_SlAr_EndSttnSrsId] FOREIGN KEY([EndStationSeriesId])
		REFERENCES [dbo].[StationSeries] ([Id])

		ALTER TABLE [dbo].[SoilArea] CHECK CONSTRAINT [FK_SlAr_EndSttnSrsId]

		ALTER TABLE [dbo].[SoilArea]  WITH CHECK ADD  CONSTRAINT [FK_SlAr_SlTpLD] FOREIGN KEY([SoilTypeLD])
		REFERENCES [dbo].[ListDomain] ([Id])

		ALTER TABLE [dbo].[SoilArea] CHECK CONSTRAINT [FK_SlAr_SlTpLD]')
END

IF OBJECT_ID('tu_soilarea', 'TR') IS NULL
BEGIN
	EXECUTE('CREATE TRIGGER [dbo].[tu_soilarea] ON [dbo].[SoilArea] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.SoilArea
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.SoilArea as t, DELETED as d
				WHERE t.Id=d.Id;
			END

			ALTER TABLE [dbo].[SoilArea] ENABLE TRIGGER [tu_soilarea]')
END

IF OBJECT_ID('BellHoleExcavation', 'U') IS NULL
BEGIN
	EXECUTE('CREATE TABLE [dbo].[BellHoleExcavation](
			[Id] [numeric](10, 0) NULL,
			[EffectiveStartDate] [datetime] NULL,
			[EffectiveEndDate] [datetime] NULL,
			[BellholeID] [varchar](60) NULL,
			[BellholeRepairInd] [char](1) NULL,
			[BellholeFoundCoatCondDomainID] [numeric](10, 0) NULL,
			[BellholeDamageTypeDomainID] [numeric](10, 0) NULL,
			[BellholeExposedPipeLength] [numeric](10, 3) NULL,
			[BellholeComment] [varchar](255) NULL,
			[StationSeriesId] [numeric](10, 0) NULL,
			[StationNum] [numeric](13, 5) NOT NULL,
			[LastModByUserId] [varchar](45) NOT NULL,
			[LastModDateTime] [datetime] NOT NULL,
			[SourceId] [varchar](50) NULL,
			[BeginStationSeriesId] [numeric](10, 0) NULL,
			[BeginStationNum] [numeric](13, 5) NOT NULL,
			[EndStationSeriesId] [numeric](10, 0) NULL,
			[EndStationNum] [numeric](13, 5) NOT NULL
		) ON [PRIMARY]

		ALTER TABLE [dbo].[BellHoleExcavation] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
		
		ALTER TABLE [dbo].[BellHoleExcavation] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

		ALTER TABLE [dbo].[BellHoleExcavation]  WITH CHECK ADD  CONSTRAINT [FK_BellHoleExcn_SSId] FOREIGN KEY([StationSeriesId])
		REFERENCES [dbo].[StationSeries] ([Id])

		ALTER TABLE [dbo].[BellHoleExcavation] CHECK CONSTRAINT [FK_BellHoleExcn_SSId]
		
		ALTER TABLE [dbo].[BellHoleExcavation]  WITH CHECK ADD  CONSTRAINT [FK_BHI_DmgTyp] FOREIGN KEY([BellholeDamageTypeDomainID])
		REFERENCES [dbo].[ListDomain] ([Id])

		ALTER TABLE [dbo].[BellHoleExcavation] CHECK CONSTRAINT [FK_BHI_DmgTyp]

		ALTER TABLE [dbo].[BellHoleExcavation]  WITH CHECK ADD  CONSTRAINT [FK_BHI_FndCtngCndtn] FOREIGN KEY([BellholeFoundCoatCondDomainID])
		REFERENCES [dbo].[ListDomain] ([Id])

		ALTER TABLE [dbo].[BellHoleExcavation] CHECK CONSTRAINT [FK_BHI_FndCtngCndtn]')
END

IF OBJECT_ID('tu_bellholeexcavation', 'TR') IS NULL
BEGIN
	EXECUTE('CREATE TRIGGER [dbo].[tu_bellholeexcavation] ON [dbo].[BellHoleExcavation] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.BellHoleExcavation
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.BellHoleExcavation as t, DELETED as d
				WHERE t.Id=d.Id;
			END

			ALTER TABLE [dbo].[BellHoleExcavation] ENABLE TRIGGER [tu_bellholeexcavation]')
END

IF OBJECT_ID('FloodArea', 'U') IS NULL
BEGIN
	EXECUTE('CREATE TABLE [dbo].[FloodArea](
			[Id] [numeric](10, 0) NOT NULL,
			[EffectiveStartDate] [datetime] NULL,
			[EffectiveEndDate] [datetime] NULL,
			[FloodAreaRangeLD] [numeric](10, 0) NULL,
			[FloodAreaMin] [numeric](10, 0) NULL,
			[FloodAreaMax] [numeric](10, 0) NULL,
			[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
			[BeginStationNum] [numeric](13, 5) NOT NULL,
			[EndStationSeriesId] [numeric](10, 0) NOT NULL,
			[EndStationNum] [numeric](13, 5) NOT NULL,
			[LastModByUserId] [varchar](45) NOT NULL,
			[LastModDateTime] [datetime] NOT NULL,
			[FloodAreaCode] [varchar](30) NULL,
			[FloodAreaLD] [numeric](10, 0) NULL,
			[SourceId] [varchar](50) NULL,
			[CreatedDate] [datetime] NOT NULL,
			[CreatedUser] [varchar](45) NOT NULL,
			CONSTRAINT [PK_FloodArea] PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]

		ALTER TABLE [dbo].[FloodArea] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

		ALTER TABLE [dbo].[FloodArea] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

		ALTER TABLE [dbo].[FloodArea] ADD  DEFAULT (getdate()) FOR [CreatedDate]

		ALTER TABLE [dbo].[FloodArea] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

		ALTER TABLE [dbo].[FloodArea]  WITH CHECK ADD  CONSTRAINT [FK_FA_BeginStationSeriesId] FOREIGN KEY([BeginStationSeriesId])
		REFERENCES [dbo].[StationSeries] ([Id])

		ALTER TABLE [dbo].[FloodArea] CHECK CONSTRAINT [FK_FA_BeginStationSeriesId]
		
		ALTER TABLE [dbo].[FloodArea]  WITH CHECK ADD  CONSTRAINT [FK_FA_EndStationSeriesId] FOREIGN KEY([EndStationSeriesId])
		REFERENCES [dbo].[StationSeries] ([Id])
		
		ALTER TABLE [dbo].[FloodArea] CHECK CONSTRAINT [FK_FA_EndStationSeriesId]

		ALTER TABLE [dbo].[FloodArea]  WITH CHECK ADD  CONSTRAINT [FK_FA_FloodAreaRange] FOREIGN KEY([FloodAreaRangeLD])
		REFERENCES [dbo].[ListDomain] ([Id])

		ALTER TABLE [dbo].[FloodArea] CHECK CONSTRAINT [FK_FA_FloodAreaRange]

		ALTER TABLE [dbo].[FloodArea]  WITH CHECK ADD  CONSTRAINT [FK_FloodArea_FloodAreaLD] FOREIGN KEY([FloodAreaLD])
		REFERENCES [dbo].[ListDomain] ([Id])

		ALTER TABLE [dbo].[FloodArea] CHECK CONSTRAINT [FK_FloodArea_FloodAreaLD]')
END

IF OBJECT_ID('tu_floodarea','TR') IS NULL
BEGIN
	EXECUTE('CREATE TRIGGER [dbo].[tu_floodarea] ON [dbo].[FloodArea] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.FloodArea
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.FloodArea as t, DELETED as d
				WHERE t.Id=d.Id;
			END

			ALTER TABLE [dbo].[FloodArea] ENABLE TRIGGER [tu_floodarea]')
END