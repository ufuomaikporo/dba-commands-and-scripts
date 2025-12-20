/* This script is meant specifically for HESM_IRASV5_UPSTREAM @ SQLDEVPREPROD and it does the following...
   1. Adds IRASCustomData# tables as well as the triggers for the tables
   2. Creates a ScriptTracker table if one does not already exist in the database
*/
-----------------------------------------------------Create Tables---------------------------------------------------------

IF OBJECT_ID('dbo.IRASCustomData1') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData1](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData1] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData1] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData1] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData1] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData1] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData1]  WITH CHECK ADD  CONSTRAINT [FK_CD1_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData1] CHECK CONSTRAINT [FK_CD1_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData1]  WITH CHECK ADD  CONSTRAINT [FK_CD1_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData1] CHECK CONSTRAINT [FK_CD1_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData1]  WITH CHECK ADD  CONSTRAINT [FK_CD1_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData1] CHECK CONSTRAINT [FK_CD1_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData1]  WITH CHECK ADD  CONSTRAINT [FK_CD1_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData1] CHECK CONSTRAINT [FK_CD1_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData1]  WITH CHECK ADD  CONSTRAINT [FK_CD1_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData1] CHECK CONSTRAINT [FK_CD1_Field_5_DomainID];
END
GO

IF OBJECT_ID('dbo.IRASCustomData2') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData2](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData2] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData2] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData2] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData2] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData2] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData2]  WITH CHECK ADD  CONSTRAINT [FK_CD2_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData2] CHECK CONSTRAINT [FK_CD2_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData2]  WITH CHECK ADD  CONSTRAINT [FK_CD2_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData2] CHECK CONSTRAINT [FK_CD2_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData2]  WITH CHECK ADD  CONSTRAINT [FK_CD2_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData2] CHECK CONSTRAINT [FK_CD2_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData2]  WITH CHECK ADD  CONSTRAINT [FK_CD2_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData2] CHECK CONSTRAINT [FK_CD2_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData2]  WITH CHECK ADD  CONSTRAINT [FK_CD2_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData2] CHECK CONSTRAINT [FK_CD2_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData3') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData3](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData3] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData3] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData3] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData3] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData3] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData3]  WITH CHECK ADD  CONSTRAINT [FK_CD3_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData3] CHECK CONSTRAINT [FK_CD3_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData3]  WITH CHECK ADD  CONSTRAINT [FK_CD3_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData3] CHECK CONSTRAINT [FK_CD3_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData3]  WITH CHECK ADD  CONSTRAINT [FK_CD3_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData3] CHECK CONSTRAINT [FK_CD3_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData3]  WITH CHECK ADD  CONSTRAINT [FK_CD3_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData3] CHECK CONSTRAINT [FK_CD3_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData3]  WITH CHECK ADD  CONSTRAINT [FK_CD3_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData3] CHECK CONSTRAINT [FK_CD3_Field_5_DomainID]
END 
GO

IF OBJECT_ID('dbo.IRASCustomData4') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData4](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData4] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData4] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData4] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData4] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData4] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData4]  WITH CHECK ADD  CONSTRAINT [FK_CD4_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData4] CHECK CONSTRAINT [FK_CD4_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData4]  WITH CHECK ADD  CONSTRAINT [FK_CD4_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData4] CHECK CONSTRAINT [FK_CD4_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData4]  WITH CHECK ADD  CONSTRAINT [FK_CD4_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData4] CHECK CONSTRAINT [FK_CD4_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData4]  WITH CHECK ADD  CONSTRAINT [FK_CD4_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData4] CHECK CONSTRAINT [FK_CD4_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData4]  WITH CHECK ADD  CONSTRAINT [FK_CD4_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData4] CHECK CONSTRAINT [FK_CD4_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData5') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData5](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData5] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData5] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData5] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData5] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData5] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData5]  WITH CHECK ADD  CONSTRAINT [FK_CD5_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData5] CHECK CONSTRAINT [FK_CD5_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData5]  WITH CHECK ADD  CONSTRAINT [FK_CD5_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData5] CHECK CONSTRAINT [FK_CD5_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData5]  WITH CHECK ADD  CONSTRAINT [FK_CD5_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData5] CHECK CONSTRAINT [FK_CD5_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData5]  WITH CHECK ADD  CONSTRAINT [FK_CD5_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData5] CHECK CONSTRAINT [FK_CD5_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData5]  WITH CHECK ADD  CONSTRAINT [FK_CD5_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData5] CHECK CONSTRAINT [FK_CD5_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData6') IS NULL
BEGIN 
	CREATE TABLE [dbo].[IRASCustomData6](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData6] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData6] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData6] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData6] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData6] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData6]  WITH CHECK ADD  CONSTRAINT [FK_CD6_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData6] CHECK CONSTRAINT [FK_CD6_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData6]  WITH CHECK ADD  CONSTRAINT [FK_CD6_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData6] CHECK CONSTRAINT [FK_CD6_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData6]  WITH CHECK ADD  CONSTRAINT [FK_CD6_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData6] CHECK CONSTRAINT [FK_CD6_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData6]  WITH CHECK ADD  CONSTRAINT [FK_CD6_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData6] CHECK CONSTRAINT [FK_CD6_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData6]  WITH CHECK ADD  CONSTRAINT [FK_CD6_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData6] CHECK CONSTRAINT [FK_CD6_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData7') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData7](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [date] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData7] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData7] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData7] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData7] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData7] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData7]  WITH CHECK ADD  CONSTRAINT [FK_CD7_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData7] CHECK CONSTRAINT [FK_CD7_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData7]  WITH CHECK ADD  CONSTRAINT [FK_CD7_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData7] CHECK CONSTRAINT [FK_CD7_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData7]  WITH CHECK ADD  CONSTRAINT [FK_CD7_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData7] CHECK CONSTRAINT [FK_CD7_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData7]  WITH CHECK ADD  CONSTRAINT [FK_CD7_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData7] CHECK CONSTRAINT [FK_CD7_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData7]  WITH CHECK ADD  CONSTRAINT [FK_CD7_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData7] CHECK CONSTRAINT [FK_CD7_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData8') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData8](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [date] NULL,
		[Field_2_Date] [date] NULL,
		[Field_3_Date] [date] NULL,
		[Field_4_Date] [date] NULL,
		[Field_5_Date] [date] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData8] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData8] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData8] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData8] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData8] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData8]  WITH CHECK ADD  CONSTRAINT [FK_CD8_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData8] CHECK CONSTRAINT [FK_CD8_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData8]  WITH CHECK ADD  CONSTRAINT [FK_CD8_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData8] CHECK CONSTRAINT [FK_CD8_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData8]  WITH CHECK ADD  CONSTRAINT [FK_CD8_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData8] CHECK CONSTRAINT [FK_CD8_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData8]  WITH CHECK ADD  CONSTRAINT [FK_CD8_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData8] CHECK CONSTRAINT [FK_CD8_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData8]  WITH CHECK ADD  CONSTRAINT [FK_CD8_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData8] CHECK CONSTRAINT [FK_CD8_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData9') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData9](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [date] NULL,
		[Field_2_Date] [date] NULL,
		[Field_3_Date] [date] NULL,
		[Field_4_Date] [date] NULL,
		[Field_5_Date] [date] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData9] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData9] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData9] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData9] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData9] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData9]  WITH CHECK ADD  CONSTRAINT [FK_CD9_Field_1_DomainID] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData9] CHECK CONSTRAINT [FK_CD9_Field_1_DomainID]

	ALTER TABLE [dbo].[IRASCustomData9]  WITH CHECK ADD  CONSTRAINT [FK_CD9_Field_2_DomainID] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData9] CHECK CONSTRAINT [FK_CD9_Field_2_DomainID]

	ALTER TABLE [dbo].[IRASCustomData9]  WITH CHECK ADD  CONSTRAINT [FK_CD9_Field_3_DomainID] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData9] CHECK CONSTRAINT [FK_CD9_Field_3_DomainID]

	ALTER TABLE [dbo].[IRASCustomData9]  WITH CHECK ADD  CONSTRAINT [FK_CD9_Field_4_DomainID] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData9] CHECK CONSTRAINT [FK_CD9_Field_4_DomainID]

	ALTER TABLE [dbo].[IRASCustomData9]  WITH CHECK ADD  CONSTRAINT [FK_CD9_Field_5_DomainID] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData9] CHECK CONSTRAINT [FK_CD9_Field_5_DomainID]
END
GO

IF OBJECT_ID('dbo.IRASCustomData11') IS NULL
BEGIN
	CREATE TABLE [dbo].[IRASCustomData11](
		[Id] [numeric](10, 0) NOT NULL,
		[EffectiveStartDate] [datetime] NULL,
		[EffectiveEndDate] [datetime] NULL,
		[BeginStationSeriesId] [numeric](10, 0) NOT NULL,
		[BeginStationNum] [numeric](13, 5) NOT NULL,
		[EndStationSeriesId] [numeric](10, 0) NOT NULL,
		[EndStationNum] [numeric](13, 5) NOT NULL,
		[Field_1_Date] [datetime] NULL,
		[Field_2_Date] [datetime] NULL,
		[Field_3_Date] [datetime] NULL,
		[Field_4_Date] [datetime] NULL,
		[Field_5_Date] [datetime] NULL,
		[Field_6_Date] [datetime] NULL,
		[Field_7_Date] [datetime] NULL,
		[Field_8_Date] [datetime] NULL,
		[Field_9_Date] [datetime] NULL,
		[Field_10_Date] [datetime] NULL,
		[Field_11_Date] [datetime] NULL,
		[Field_12_Date] [datetime] NULL,
		[Field_13_Date] [datetime] NULL,
		[Field_14_Date] [datetime] NULL,
		[Field_15_Date] [datetime] NULL,
		[Field_16_Date] [datetime] NULL,
		[Field_17_Date] [datetime] NULL,
		[Field_18_Date] [datetime] NULL,
		[Field_19_Date] [datetime] NULL,
		[Field_20_Date] [datetime] NULL,
		[Field_1_Float] [float] NULL,
		[Field_2_Float] [float] NULL,
		[Field_3_Float] [float] NULL,
		[Field_4_Float] [float] NULL,
		[Field_5_Float] [float] NULL,
		[Field_6_Float] [float] NULL,
		[Field_7_Float] [float] NULL,
		[Field_8_Float] [float] NULL,
		[Field_9_Float] [float] NULL,
		[Field_10_Float] [float] NULL,
		[Field_11_Float] [float] NULL,
		[Field_12_Float] [float] NULL,
		[Field_13_Float] [float] NULL,
		[Field_14_Float] [float] NULL,
		[Field_15_Float] [float] NULL,
		[Field_16_Float] [float] NULL,
		[Field_17_Float] [float] NULL,
		[Field_18_Float] [float] NULL,
		[Field_19_Float] [float] NULL,
		[Field_20_Float] [float] NULL,
		[Field_1_Ind] [char](1) NULL,
		[Field_2_Ind] [char](1) NULL,
		[Field_3_Ind] [char](1) NULL,
		[Field_4_Ind] [char](1) NULL,
		[Field_5_Ind] [char](1) NULL,
		[Field_6_Ind] [char](1) NULL,
		[Field_7_Ind] [char](1) NULL,
		[Field_8_Ind] [char](1) NULL,
		[Field_9_Ind] [char](1) NULL,
		[Field_10_Ind] [char](1) NULL,
		[Field_11_Ind] [char](1) NULL,
		[Field_12_Ind] [char](1) NULL,
		[Field_13_Ind] [char](1) NULL,
		[Field_14_Ind] [char](1) NULL,
		[Field_15_Ind] [char](1) NULL,
		[Field_16_Ind] [char](1) NULL,
		[Field_17_Ind] [char](1) NULL,
		[Field_18_Ind] [char](1) NULL,
		[Field_19_Ind] [char](1) NULL,
		[Field_20_Ind] [char](1) NULL,
		[Field_1_DomainId] [numeric](10, 0) NULL,
		[Field_2_DomainId] [numeric](10, 0) NULL,
		[Field_3_DomainId] [numeric](10, 0) NULL,
		[Field_4_DomainId] [numeric](10, 0) NULL,
		[Field_5_DomainId] [numeric](10, 0) NULL,
		[Field_6_DomainId] [numeric](10, 0) NULL,
		[Field_7_DomainId] [numeric](10, 0) NULL,
		[Field_8_DomainId] [numeric](10, 0) NULL,
		[Field_9_DomainId] [numeric](10, 0) NULL,
		[Field_10_DomainId] [numeric](10, 0) NULL,
		[Field_11_DomainId] [numeric](10, 0) NULL,
		[Field_12_DomainId] [numeric](10, 0) NULL,
		[Field_13_DomainId] [numeric](10, 0) NULL,
		[Field_14_DomainId] [numeric](10, 0) NULL,
		[Field_15_DomainId] [numeric](10, 0) NULL,
		[Field_16_DomainId] [numeric](10, 0) NULL,
		[Field_17_DomainId] [numeric](10, 0) NULL,
		[Field_18_DomainId] [numeric](10, 0) NULL,
		[Field_19_DomainId] [numeric](10, 0) NULL,
		[Field_20_DomainId] [numeric](10, 0) NULL,
		[Field_1_String] [varchar](512) NULL,
		[Field_2_String] [varchar](512) NULL,
		[Field_3_String] [varchar](512) NULL,
		[Field_4_String] [varchar](512) NULL,
		[Field_5_String] [varchar](512) NULL,
		[Field_6_String] [varchar](512) NULL,
		[Field_7_String] [varchar](512) NULL,
		[Field_8_String] [varchar](512) NULL,
		[Field_9_String] [varchar](512) NULL,
		[Field_10_String] [varchar](512) NULL,
		[Field_11_String] [varchar](512) NULL,
		[Field_12_String] [varchar](512) NULL,
		[Field_13_String] [varchar](512) NULL,
		[Field_14_String] [varchar](512) NULL,
		[Field_15_String] [varchar](512) NULL,
		[Field_16_String] [varchar](512) NULL,
		[Field_17_String] [varchar](512) NULL,
		[Field_18_String] [varchar](512) NULL,
		[Field_19_String] [varchar](512) NULL,
		[Field_20_String] [varchar](512) NULL,
		[LastModByUserId] [varchar](45) NOT NULL,
		[LastModDateTime] [datetime] NOT NULL,
		[SourceId] [varchar](50) NULL,
		[CreatedDate] [datetime] NOT NULL,
		[CreatedUser] [varchar](45) NOT NULL,
		[CheckSumValue] [int] NULL,
	 CONSTRAINT [PK_IRASCustomData11] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[IRASCustomData11] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]

	ALTER TABLE [dbo].[IRASCustomData11] ADD  DEFAULT (getdate()) FOR [LastModDateTime]

	ALTER TABLE [dbo].[IRASCustomData11] ADD  DEFAULT (getdate()) FOR [CreatedDate]

	ALTER TABLE [dbo].[IRASCustomData11] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_1_DomainId] FOREIGN KEY([Field_1_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_1_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_10_DomainId] FOREIGN KEY([Field_10_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_10_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_11_DomainId] FOREIGN KEY([Field_11_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_11_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_12_DomainId] FOREIGN KEY([Field_12_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_12_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_13_DomainId] FOREIGN KEY([Field_13_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_13_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_14_DomainId] FOREIGN KEY([Field_14_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_14_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_15_DomainId] FOREIGN KEY([Field_15_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_15_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_2_DomainId] FOREIGN KEY([Field_2_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_2_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_3_DomainId] FOREIGN KEY([Field_3_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_3_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_4_DomainId] FOREIGN KEY([Field_4_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_4_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_5_DomainId] FOREIGN KEY([Field_5_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_5_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_6_DomainId] FOREIGN KEY([Field_6_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_6_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_7_DomainId] FOREIGN KEY([Field_7_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_7_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_8_DomainId] FOREIGN KEY([Field_8_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_8_DomainId]

	ALTER TABLE [dbo].[IRASCustomData11]  WITH CHECK ADD  CONSTRAINT [FK_CD11_Field_9_DomainId] FOREIGN KEY([Field_9_DomainId])
	REFERENCES [dbo].[ListDomain] ([Id])

	ALTER TABLE [dbo].[IRASCustomData11] CHECK CONSTRAINT [FK_CD11_Field_9_DomainId]
END
GO

-----------------------------------------------Create Table Triggers---------------------------------------------------------

IF OBJECT_ID('tu_IRASCustomData1', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData1] ON [dbo].[IRASCustomData1] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData1
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData1 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData1] ENABLE TRIGGER [tu_IRASCustomData1]'
END
GO

IF OBJECT_ID('tu_IRASCustomData2', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData2] ON [dbo].[IRASCustomData2] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData2
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData2 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData2] ENABLE TRIGGER [tu_IRASCustomData2]'
END
GO

IF OBJECT_ID('tu_IRASCustomData3', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData3] ON [dbo].[IRASCustomData3] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData3
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData3 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData3] ENABLE TRIGGER [tu_IRASCustomData3]'
END
GO

IF OBJECT_ID('tu_IRASCustomData4', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData4] ON [dbo].[IRASCustomData4] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData4
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData4 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData4] ENABLE TRIGGER [tu_IRASCustomData4]'
END
GO

IF OBJECT_ID('tu_IRASCustomData5', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData5] ON [dbo].[IRASCustomData5] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData5
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData5 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData5] ENABLE TRIGGER [tu_IRASCustomData5]'
END
GO

IF OBJECT_ID('tu_IRASCustomData6', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData6] ON [dbo].[IRASCustomData6] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData6
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData6 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData6] ENABLE TRIGGER [tu_IRASCustomData6]'
END
GO

IF OBJECT_ID('tu_IRASCustomData7', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData7] ON [dbo].[IRASCustomData7] FOR UPDATE
	AS
	BEGIN

		UPDATE IRASCustomData7
		SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
		FROM IRASCustomData7 AS t, DELETED AS d
		WHERE t.Id=d.Id;

	END;

	ALTER TABLE [dbo].[IRASCustomData7] ENABLE TRIGGER [tu_IRASCustomData7]'
END
GO

IF OBJECT_ID('tu_IRASCustomData8', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData8] ON [dbo].[IRASCustomData8] FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE dbo.IRASCustomData8
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM dbo.IRASCustomData9 as t, DELETED as d
		WHERE t.Id=d.Id;
	END

	ALTER TABLE [dbo].[IRASCustomData8] ENABLE TRIGGER [tu_IRASCustomData8]'
END
GO

IF OBJECT_ID('tu_IRASCustomData9', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData9] ON [dbo].[IRASCustomData9] FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE dbo.IRASCustomData9
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM dbo.IRASCustomData9 as t, DELETED as d
		WHERE t.Id=d.Id;
	END

	ALTER TABLE [dbo].[IRASCustomData9] ENABLE TRIGGER [tu_IRASCustomData9]'
END
GO

IF OBJECT_ID('tu_IRASCustomData11', 'TR') IS NULL
BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[tu_IRASCustomData11] ON [dbo].[IRASCustomData11] FOR UPDATE AS
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE dbo.IRASCustomData11
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM dbo.IRASCustomData11 as t, DELETED as d
		WHERE t.Id=d.Id;
	END

	ALTER TABLE [dbo].[IRASCustomData11] ENABLE TRIGGER [tu_IRASCustomData11]'
END
GO

---------------------------------------------------Script Tracking--------------------------------------------------------------

-- Create ScriptTracker Table if it does not already exist
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name= 'ScriptTracker')
BEGIN

	CREATE TABLE ScriptTracker
	(Id numeric(10) IDENTITY,
	ScriptName varchar(100),
	ScriptDetails varchar(255),
	Reason varchar(255),
	ClientSpecific varchar(10), --yes, no
	ScriptedByUser varchar (45),
	ScriptCreateDate datetime,
	ScriptDeliveredDate datetime,
	Version varchar(20),
	CreatedDate datetime NOT NULL,
	CreatedUser varchar(45) NOT NULL,
	LastModByUserId varchar(45) NOT NULL,
	LastModDateTime datetime NOT NULL,
	CONSTRAINT PK_ScriptTracker PRIMARY KEY CLUSTERED
	(
	Id ASC)
	);

	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (suser_sname()) FOR LastModByUserId;

	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (getdate()) FOR LastModDateTime;

	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (getdate()) FOR CreatedDate;

	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (suser_sname()) FOR CreatedUser;


END;
GO

--Create trigger for the ScriptTracker table
IF EXISTS (SELECT * FROM sys.objects WHERE TYPE = 'TR' AND NAME = 'tu_ScriptTracker')
	DROP TRIGGER [dbo].[tu_ScriptTracker]
GO

CREATE TRIGGER dbo.tu_ScriptTracker ON dbo.ScriptTracker FOR UPDATE AS
IF EXISTS(SELECT * FROM DELETED)
	BEGIN   UPDATE dbo.ScriptTracker   
			SET LastModByUserId = suser_sname(), 
				LastModDateTime = getdate()    
			FROM dbo.ScriptTracker as t, DELETED as d    
			WHERE t.Id=d.Id;
END
GO

ALTER TABLE dbo.ScriptTracker ENABLE TRIGGER tu_ScriptTracker
GO

-- Add a new entry into ScriptTracker table
INSERT INTO dbo.ScriptTracker
(ScriptName,   
 ScriptDetails,    
 Reason,    
 ClientSpecific,    
 ScriptedByUser,    
 ScriptCreateDate,    
 ScriptDeliveredDate,    
 Version
)
SELECT  'Add_IRASCustomData_Tables_To_HESM_IRASV5_UPSTREAM.sql', 
		'Adds IRASCustomData# tables to HESM_IRASV5_UPSTREAM@SQLDEVPREPROD database and creates triggers on the tables', 
		'For adding IRASCustomData# tables to HESM_IRASV5_UPSTREAM@SQLDEVPREPROD database',
		'Yes', 
		'Ufuoma Ikporo',
		'November 15, 2022',
		getdate(), 
		1
WHERE NOT EXISTS (SELECT * FROM dbo.ScriptTracker st 
				  WHERE st.ScriptName = 'Add_IRASCustomData_Tables_To_HESM_IRASV5_UPSTREAM.sql' 
				  AND Version = 1)
GO