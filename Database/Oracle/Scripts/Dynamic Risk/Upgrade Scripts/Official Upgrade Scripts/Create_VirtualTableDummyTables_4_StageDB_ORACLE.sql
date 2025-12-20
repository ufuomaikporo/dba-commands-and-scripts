/*
This is a stage database script that creates load tables for the new Virtual tables for 6.5.1 IRAS data model
*/

ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE
	CNT INT;
	sql_stmt VARCHAR2(20000);
BEGIN

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_NumTable';

	IF CNT = 0 THEN
		sql_stmt := 'CREATE TABLE DRAS_Load_VT_NumTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column BINARY_FLOAT
		,CONSTRAINT  PK_Load_VT_NumTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_DateTable';

	IF CNT = 0 THEN
		sql_stmt := 'CREATE TABLE DRAS_Load_VT_DateTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column TIMESTAMP
		,CONSTRAINT  PK_Load_VT_DateTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_FlgTable';

	IF CNT = 0 THEN
		sql_stmt := 'CREATE TABLE DRAS_Load_VT_FlgTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column NUMBER(1,0)
		,CONSTRAINT  PK_Load_VT_FlgTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_IndTable';

	IF CNT = 0 THEN
		sql_stmt := 'CREATE TABLE DRAS_Load_VT_IndTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column CHAR(1)
		,CONSTRAINT  PK_Load_VT_IndTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_DomainIdTable';

	IF CNT = 0 THEN

		sql_stmt := 'CREATE TABLE DRAS_Load_VT_DomainIdTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column NUMBER(7,0)
		,CONSTRAINT  PK_Load_VT_DomainIdTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

	SELECT COUNT(*) INTO CNT
	FROM user_tables
	WHERE table_name = 'DRAS_Load_VT_StringTable';

	IF CNT = 0 THEN
		sql_stmt := 'CREATE TABLE DRAS_Load_VT_StringTable
		(Id NUMBER(10,0) NOT NULL
		,SourceId VARCHAR2(50) 
		,CheckSumValue INT NOT NULL
		,EffectiveStartDate	TIMESTAMP
		,EffectiveEndDate TIMESTAMP
		,LastModByUserId VARCHAR2(45) NOT NULL     
		,LastModDateTime TIMESTAMP NOT NULL   
		,CreatedDate TIMESTAMP NOT NULL   
		,CreatedUser VARCHAR2(45) NOT NULL   
		,BeginStationSeriesId NUMBER(10,0) NOT NULL 
		,BeginStationNum NUMBER(13,5) NOT NULL
		,EndStationSeriesId	NUMBER(10,0) NOT NULL
		,EndStationNum NUMBER(13,5) NOT NULL
		,VT_Column VARCHAR2(512)
		,CONSTRAINT  PK_Load_VT_StringTableSourceId PRIMARY KEY(SourceId)
		)';

		EXECUTE IMMEDIATE sql_stmt;

	END IF;

END;
/

