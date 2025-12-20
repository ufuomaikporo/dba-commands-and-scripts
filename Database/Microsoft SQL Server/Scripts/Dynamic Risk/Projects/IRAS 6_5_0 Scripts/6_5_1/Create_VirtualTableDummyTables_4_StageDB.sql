/*
This is a stage database script that creates load tables for the new Virtual tables for 6.5.1 IRAS data model
*/

DECLARE @SQL NVARCHAR(MAX)

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
BEGIN
	SET @SQL = 'CREATE SCHEMA DRAS'
	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_NumTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_NumTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column Float
	,CONSTRAINT  PK_Load_VT_NumTableSourceId PRIMARY KEY(SourceId)
	)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_DateTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_DateTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column DATETIME
	,CONSTRAINT  PK_Load_VT_DateTableSourceId PRIMARY KEY(SourceId)
	)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_FlgTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_FlgTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column NUMERIC(1,0)
	,CONSTRAINT  PK_Load_VT_FlgTableSourceId PRIMARY KEY(SourceId)
	)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_IndTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_IndTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column CHAR(1)
	,CONSTRAINT  PK_Load_VT_IndTableSourceId PRIMARY KEY(SourceId)
	)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_DomainIdTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_DomainIdTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column NUMERIC(7,0)
	,CONSTRAINT  PK_Load_VT_DomainIdTableSourceId PRIMARY KEY(SourceId)
	)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'Load_VT_StringTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.Load_VT_StringTable
	(Id NUMERIC(10,0) NOT NULL
	,SourceId VARCHAR(50) 
	,CheckSumValue INT NOT NULL
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) NOT NULL     
	,LastModDateTime DATETIME NOT NULL   
	,CreatedDate DATETIME NOT NULL   
	,CreatedUser VARCHAR(45) NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0) NOT NULL 
	,BeginStationNum NUMERIC(13,5) NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) NOT NULL
	,EndStationNum NUMERIC(13,5) NOT NULL
	,VT_Column VARCHAR(512)
	,CONSTRAINT  PK_Load_VT_StringTableSourceId PRIMARY KEY(SourceId)
	)
END