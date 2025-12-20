/*
This is a Link Database script that generates the table structure for Virtual tables

This script must be executed on the Link database
*/

DECLARE @SQL NVARCHAR(MAX)

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DRAS')
BEGIN
	SET @SQL = 'CREATE SCHEMA DRAS'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_NumTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_NumTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column Float
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_NumTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_NumTable ON DRAS.VT_NumTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_NumTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_NumTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_DateTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_DateTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column DATETIME
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_DateTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_DateTable ON DRAS.VT_DateTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_DateTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_DateTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_FlgTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_FlgTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column NUMERIC(1,0)
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_FlgTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_FlgTable ON DRAS.VT_FlgTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_FlgTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_FlgTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_IndTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_IndTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column CHAR(1)
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_IndTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_IndTable ON DRAS.VT_IndTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_IndTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_IndTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_DomainIdTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_DomainIdTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column NUMERIC(7,0)
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_DomainIdTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_DomainIdTable ON DRAS.VT_DomainIdTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_DomainIdTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_DomainIdTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name = 'VT_StringTable' AND table_schema = 'DRAS')
BEGIN
	CREATE TABLE DRAS.VT_StringTable
	(Id NUMERIC(10,0)
	,SourceId VARCHAR(50)
	,CheckSumValue INT
	,EffectiveStartDate	DATETIME
	,EffectiveEndDate DATETIME
	,LastModByUserId VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL     
	,LastModDateTime DATETIME  DEFAULT GETDATE()   NOT NULL   
	,CreatedDate DATETIME   DEFAULT GETDATE()  NOT NULL   
	,CreatedUser VARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL   
	,BeginStationSeriesId NUMERIC(10,0)   
	,BeginStationNum NUMERIC(13,5)  NOT NULL
	,EndStationSeriesId	NUMERIC(10,0) 
	,EndStationNum NUMERIC(13,5)  NOT NULL
	,VT_Column VARCHAR(512)
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'tu_VT_StringTable')
BEGIN
	SET @SQL = 'CREATE TRIGGER DRAS.tu_VT_StringTable ON DRAS.VT_StringTable FOR UPDATE AS 
	IF EXISTS(SELECT * FROM DELETED)
	BEGIN
		UPDATE DRAS.VT_StringTable
		SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
		FROM DRAS.VT_StringTable as t, DELETED as d
		WHERE t.Id=d.Id;
	END'

	EXECUTE (@SQL)
END