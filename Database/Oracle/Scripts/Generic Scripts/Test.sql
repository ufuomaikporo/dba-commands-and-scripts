

CREATE TABLE Load_ACVGSurvey(
	Id NUMBER(10, 0) NOT NULL,
	ACVGSurveyTypeDomainid NUMBER(7, 0) NULL,
	ACVGSurveyEquipmentDomainId NUMBER(7, 0) NULL,
	ACVGSurveyContractorDomainId NUMBER(7, 0) NULL,
	ACVGSurveySpacing NUMBER(10, 3) NULL,
	ACVGSurveyComment VARCHAR2(255) NULL,
	ACVGSurveyDate TIMESTAMP NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedDate TIMESTAMP NULL,
	CreatedUser VARCHAR2(45) NULL,
 CONSTRAINT PK_ACVGSurveySourceId PRIMARY KEY (SourceId)
);

CREATE TABLE Load_ACVGSurveyAnomaly(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	ACVGSurveyRangeId NUMBER(10, 0) NOT NULL,
	ACVGAnomalySeverityTypeLD NUMBER(7, 0) NULL,
	ACVGAnomalyIndicationTypeLD NUMBER(7, 0) NULL,
	ACVGAnomalyIRDrop NUMBER(3, 2) NULL,
	ACVGAnomalyVoltageDrop NUMBER(6, 4) NULL,
	ACVGAnomalyMaxGradient NUMBER(6, 4) NULL,
	ACVGAnomalyMaxOn NUMBER(6, 4) NULL,
	ACVGAnomalyMaxOff NUMBER(6, 4) NULL,
	ACVGAnomalyComment VARCHAR2(255) NULL,
	StationSeriesId NUMBER(10, 0) NOT NULL,
	StationNum NUMBER(10, 3) NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedDate TIMESTAMP NULL,
	CreatedUser VARCHAR2(45) NULL,
 CONSTRAINT PK_ACVGAnomalySourceId PRIMARY KEY (SourceId) 
);


CREATE TABLE Load_ACVGSurveyRange(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	ACVGSurveyId NUMBER(10, 0) NOT NULL,
	BeginStationSeriesId NUMBER(10, 0) NOT NULL,
	BeginStationNum NUMBER(10, 3) NOT NULL,
	EndStationSeriesId NUMBER(10, 0) NOT NULL,
	EndStationNum NUMBER(10, 3) NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedDate TIMESTAMP NULL,
	CreatedUser VARCHAR2(45) NULL,
 CONSTRAINT PK_ACVGRangeSourceId PRIMARY KEY (SourceId) 
);


CREATE TABLE Load_ACVGSurveyReading(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	ACVGSurveyRangeId NUMBER(10, 0) NOT NULL,
	ACVGReadingAdjustedCurrent NUMBER(6, 4) NULL,
	ACVGReadingCurrent NUMBER(6, 4) NULL,
	ACVGReadingCurrentLoss NUMBER(6, 4) NULL,
	ACVGReadingCurrentDirection NUMBER(7, 0) NULL,
	ACVGReadingDepthOfCover NUMBER(10, 3) NULL,
	ACVGReadingCoatingConductance NUMBER(7, 0) NULL,
	ACVGReadingCoatingResistance NUMBER(7, 0) NULL,
	ACVGReadingSevClassification NUMBER(7, 0) NULL,
	ACVGReadingComment VARCHAR2(255) NULL,
	StationSeriesId NUMBER(10, 0) NOT NULL,
	StationNum NUMBER(10, 3) NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedDate TIMESTAMP NULL,
	CreatedUser VARCHAR2(45) NULL,
	BeginStationSeriesId NUMBER(10, 0) NULL,
	BeginStationNum NUMBER(10, 3) NULL,
	EndStationSeriesId NUMBER(10, 0) NULL,
	EndStationNum NUMBER(10, 3) NULL,
 CONSTRAINT PK_ACVGReadingSourceId PRIMARY KEY (SourceId) 
);


CREATE TABLE Load_DCVGSurvey(
	Id NUMBER(10, 0) NOT NULL,
	DCVGSurveyTypeDomainId NUMBER(7, 0) NULL,
	DCVGSurveyEquipmentDomainId NUMBER(7, 0) NULL,
	DCVGSurveyContractorDomainId NUMBER(7, 0) NULL,
	DCVGSurveySpacing NUMBER(10, 3) NULL,
	DCVGSurveyComment VARCHAR2(255) NULL,
	DCVGSurveyDate TIMESTAMP NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedUser VARCHAR2(45) NULL,
	CreatedDate TIMESTAMP NULL,
 CONSTRAINT PK_DCVGSurveySourceId PRIMARY KEY (SourceId) 
);


CREATE TABLE Load_DCVGSurveyAnomaly(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	DCVGSurveyRangeId NUMBER(10, 0) NOT NULL,
	DCVGAnomalySeverityTypeLD NUMBER(7, 0) NULL,
	DCVGAnomalyIndicationTypeLD NUMBER(7, 0) NULL,
	DCVGAnomalyIRDrop NUMBER(3, 2) NULL,
	DCVGAnomalyVoltageDrop NUMBER(6, 4) NULL,
	DCVGAnomalyMaxGradient NUMBER(6, 4) NULL,
	DCVGAnomalyMaxOn NUMBER(6, 4) NULL,
	DCVGAnomalyMaxOff NUMBER(6, 4) NULL,
	DCVGAnomalyComment VARCHAR2(255) NULL,
	StationSeriesId NUMBER(10, 0) NOT NULL,
	StationNum NUMBER(10, 3) NOT NULL,
	CVGAnomlayMaxOff NUMBER(6, 4) NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	BeginStationSeriesId NUMBER(10, 0) NULL,
	BeginStationNum NUMBER(13, 5) NULL,
	EndStationSeriesId NUMBER(10, 0) NULL,
	EndStationNum NUMBER(13, 5) NULL,
	CheckSumValue int NULL,
 CONSTRAINT PK_DCVGAnomalySourceId PRIMARY KEY (SourceId) 
);

CREATE TABLE Load_DCVGSurveyRange(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	DCVGSurveyId NUMBER(10, 0) NOT NULL,
	BeginStationSeriesId NUMBER(10, 0) NOT NULL,
	BeginStationNum NUMBER(10, 3) NOT NULL,
	EndStationSeriesId NUMBER(10, 0) NOT NULL,
	EndStationNum NUMBER(10, 3) NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	CheckSumValue int NULL,
	CreatedUser VARCHAR2(45) NULL,
	CreatedDate TIMESTAMP NULL,
 CONSTRAINT PK_DCVGRangeSourceId PRIMARY KEY (SourceId) 
);


CREATE TABLE Load_DCVGSurveyReading(
	Id NUMBER(10, 0) NOT NULL,
	EffectiveStartDate TIMESTAMP NULL,
	EffectiveEndDate TIMESTAMP NULL,
	DCVGSurveyRangeId NUMBER(10, 0) NOT NULL,
	DCVGSurveyReadingOn NUMBER(8, 4) NULL,
	DCVGSurveyReadingOff NUMBER(8, 4) NULL,
	DCVGSurveyReadingNatural NUMBER(8, 4) NULL,
	DCVGSurveyReadingComment VARCHAR2(255) NULL,
	StationSeriesId NUMBER(10, 0) NOT NULL,
	StationNum NUMBER(10, 3) NOT NULL,
	LastModByUserId VARCHAR2(45) NOT NULL,
	LastModTIMESTAMP TIMESTAMP NOT NULL,
	SourceId VARCHAR2(50) NOT NULL,
	BeginStationSeriesId NUMBER(10, 0) NULL,
	BeginStationNum NUMBER(13, 5) NULL,
	EndStationSeriesId NUMBER(10, 0) NULL,
	EndStationNum NUMBER(13, 5) NULL,
	CheckSumValue int NULL,
 CONSTRAINT PK_DCVGReadingSourceId PRIMARY KEY (SourceId) 
);

