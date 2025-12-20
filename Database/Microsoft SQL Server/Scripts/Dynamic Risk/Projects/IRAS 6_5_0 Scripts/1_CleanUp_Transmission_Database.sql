/*

This script deletes all tables named in the variable '@List' from the database where it is executed

*/
DECLARE @list NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @GetTableList NVARCHAR(MAX)
DECLARE @TableList TABLE (table_name NVARCHAR(100))
DECLARE @FKConstraintList TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, FK_Table NVARCHAR(100), constraint_name NVARCHAR(100))
DECLARE @GetFKConstraints NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(600)
DECLARE @FK_Table NVARCHAR(100)
DECLARE @constraint_name NVARCHAR(100)

-- List of tables to be deleted
SET @List = N'AppList
AppTableListXref
AppTables
CASurvey
CASurveyRange
CASurveyReading
CategoryDataNumXRef
CenterlineAlignment
CenterlineAlignmentDependency
CenterlineDefinition
CenterlineMapping
Classification
ClassificationRange
ClassLocationStructCtgry
CoatingDefect
CoatingThickness
Constant
CrackAnomaly
CrackAnomalyCluster
CrossingLocnMay8
CrossingMay8
DBS_Data_Dat_1
DBS_Data_Dat_2
DBS_Data_Dat_3
DBS_Data_Dat_4
DBS_Data_Dat_5
DBS_Data_Dat_6
DBS_Data_Dat_7
DBS_Data_Dat_8
DBS_Data_Ind_1
DBS_Data_Ind_10
DBS_Data_Ind_11
DBS_Data_Ind_12
DBS_Data_Ind_13
DBS_Data_Ind_14
DBS_Data_Ind_15
DBS_Data_Ind_16
DBS_Data_Ind_17
DBS_Data_Ind_18
DBS_Data_Ind_19
DBS_Data_Ind_2
DBS_Data_Ind_20
DBS_Data_Ind_3
DBS_Data_Ind_4
DBS_Data_Ind_5
DBS_Data_Ind_6
DBS_Data_Ind_7
DBS_Data_Ind_8
DBS_Data_Ind_9
DBS_Data_Int_1
DBS_Data_Int_10
DBS_Data_Int_11
DBS_Data_Int_12
DBS_Data_Int_13
DBS_Data_Int_14
DBS_Data_Int_15
DBS_Data_Int_16
DBS_Data_Int_17
DBS_Data_Int_18
DBS_Data_Int_19
DBS_Data_Int_2
DBS_Data_Int_20
DBS_Data_Int_3
DBS_Data_Int_4
DBS_Data_Int_5
DBS_Data_Int_6
DBS_Data_Int_7
DBS_Data_Int_8
DBS_Data_Int_9
DBS_Data_Num_1
DBS_Data_Num_10
DBS_Data_Num_11
DBS_Data_Num_12
DBS_Data_Num_13
DBS_Data_Num_14
DBS_Data_Num_15
DBS_Data_Num_16
DBS_Data_Num_17
DBS_Data_Num_18
DBS_Data_Num_19
DBS_Data_Num_2
DBS_Data_Num_20
DBS_Data_Num_3
DBS_Data_Num_4
DBS_Data_Num_5
DBS_Data_Num_6
DBS_Data_Num_7
DBS_Data_Num_8
DBS_Data_Num_9
DBS_Data_Str_1
DBS_Data_Str_2
DBS_Data_Str_3
DBS_Data_Str_4
DBS_Data_Str_5
DBS_Data_Str_6
DBS_Data_Str_7
DBS_Data_Str_8
DBS_Links
DynamicIntegration
EditValueisnull
FailureDetection
IdentityColumn
IdentityColumnGrouping
ILIArtifactXRef
ILIError
ILIExcavation
InlineInspectionJoint12102019
InlineInspectionRemark
InspectionData
IntegrationType
InternalInspection
IrasType
Joint
Joint2010
LineLoopStatus
Maintenance
MaintenanceProject
MAOPPipeProperties
MetaDataColumn
MetaDataForeignKey
MetaDataForeignKeyColumn
MetaDataTable
MetricfullsystemDefaultSu
MICAnalysis
MICAnalysisReading
Node
NodeConnection
NodeNetwork
NodeNetworkNodes
PCMSurvey
PCMSurveyRange
PCMSurveyReading
PointChar
PredefinedLocation
QueryStructure
RADIMClassifierCategory
RADIMP
RADIMPClassifier
RADIMPClassifierItem
RADIMPEquipmentService
RADIMPScoreTable
RADIMPVariable
RADIMPView
RADIMPViewColumn
RADIMPViewSection
RADIMPViewSectionColumnXRef
RCCategoryStructure
RCCSAClassCalc
RCCSAClassCalcFlagType
RCCSAClassCalcSeg
RCCSAClassFlags
RCCSAClassFlagType
RCDIMP
RCDIMPBaseRun
RCDIMPBucket
RCDIMPBucketCategory
RCDIMPBucketCategoryValue
RCDIMPBucketConstraint
RCDIMPBucketCount
RCDIMPBucketLeakGradeConseq
RCDIMPBucketMileage
RCDIMPEquipment
RCDIMPEquipmentCount
RCDIMPEquipmentPerBucket
RCDIMPLeakGrade
RCDIMPPromote
RCDIMPRemarks
RCDIMPScoreTableValue
RCDIMPThreat
RCDIMPVariable
RCDIMPVariableLeakGradeXRef
RCDIMPVariableValueNum_1
RCDOTClassCalc
RCDOTClassCalcFlagType
RCDOTClassCalcSeg
RCDOTClassFlags
RCDOTClassFlagType
RCMAOPCALC
RCMAOPCalcSeg
RCMAOPFlagActionType
RCMAOPFlagProcessType
RCMAOPFlagReasonType
RCMAOPFlags
RCMAOPLIMIT
RCStructureCategory
RCStructureCategoryType
RiskAlgorithm
RISKALGORITHMCHARTCATDATXREF
RISKALGORITHMCHARTCATEGORY
RISKALGORITHMCHARTCATEGORYDATA
RISKALGORITHMCOLUMBYCATEGORY
RISKALGORITHMCOLUMN
RISKALGORITHMCOLUMNCATEGORY
RiskAlgorithmConstant
RiskAlgorithmDissolve
RiskAlgorithmDissolveBase
RiskAlgorithmDissolveColumn
RiskAlgorithmMIMProgram
RiskAlgorithmMIMProgramCat
RiskAlgorithmMIMPVariable
RiskAlgorithmModel
RiskAlgorithmModelColXRef
RiskAlgorithmModelDisplay
RiskAlgorithmProgramXRef
RiskAlgorithmScoreTable
RiskAlgorithmScript
RiskAlgorithmSeries
RiskAlgorithmSeriesTable
RiskAlgorithmSeriesVarXRef
RiskAlgorithmVariable
RiskAlgorithmVirtualTable
RiskCalcModelVariableXRef
RiskCalcModelVariablHierarchy
RiskCalcScoreTableValue
RiskCalculation
RiskCalculationCaseStudy
RiskCalculationCaseStudyId
RiskCalculationCaseStudyProg
RiskCalculationCaseStudyRange
RiskCalculationCaseStudyVar
RISKCALCULATIONCOLOURING
RISKCALCULATIONCOLOURINGRANGE
RiskCalculationConstant
RiskCalculationCorporation
RiskCalculationCorrectionPos
RISKCALCULATIONDATACOLUMN
RISKCALCULATIONDATACONDITION
RISKCALCULATIONDATASOURCE
RISKCALCULATIONDATATABLE
RiskCalculationDCColXRef
RiskCalculationDischargeSubSys
RiskCalculationDomainCatalog
RiskCalculationGroup
RiskCalculationGrouping
RiskCalculationGroupingFilter
RiskCalculationHCA
RiskCalculationHCAAssesFolder
RiskCalculationHCAAssessment
RiskCalculationHCACatalog
RiskCalculationHCACatalogItem
RiskCalculationHCAFolder
RiskCalculationHCAILI
RiskCalculationHCAModel
RiskCalculationHCARankColor
RiskCalculationHCAReasons
RISKCALCULATIONHCARTGROUP
RISKCALCULATIONHCARTGRREASON
RiskCalculationHCASeg
RiskCalculationHCASetup
RiskCalculationHCASubst
RiskCalculationId
RISKCALCULATIONILICALC
RISKCALCULATIONILICALCCOND
RiskCalculationILIDefectType
RiskCalculationILIDomainIds
RISKCALCULATIONILIFEATURE
RISKCALCULATIONILIRANGE
RISKCALCULATIONILIRANGEDEFECT
RISKCALCULATIONILISEGMENT
RISKCALCULATIONILISEGMENTOVR
RiskCalculationILISetup
RiskCalculationIncident
RISKCALCULATIONINCIDENTCOND
RiskCalculationIncidentDamage
RiskCalculationIncidentGroup
RiskCalculationIncidentThreat
RiskCalculationLineGroup
RiskCalculationLineGroupSSFact
RiskCalculationLineLoop
RiskCalculationListDomain
RiskCalculationMarkerPos
RiskCalculationMatrix
RiskCalculationMatrixCell
RiskCalculationMatrixColor
RiskCalculationMatrixRange
RiskCalculationMLVCorrection
RiskCalculationMLVSection
RiskCalculationModel
RISKCALCULATIONMODELSET
RISKCALCULATIONMODELSETGROUP
RISKCALCULATIONMODELSETMODEL
RISKCALCULATIONMODELSETVAR
RiskCalculationOperatingUnit
RiskCalculationPipelineSystem
RiskCalculationRemark
RiskCalculationSectionPos
RiskCalculationSegment
RiskCalculationSegmentByGroup
RiskCalculationSegmentFull
RiskCalculationSegmentOverlap
RiskCalculationStationSeries
RiskCalculationTotalVarXRef
RiskCalculationTPSurveySetup
RiskCalculationVariable
RiskCalculationVariableDepend
RiskCalculationView
RiskCalculationViewSelection
StationSeriesAttribute
StationSeriesReplacement
Stg_ILIEventTable
Stg_ILIEventTableLD
Stg_Maintenance
SupplementalPermissions
TempTableLog
TestCustom
tmpListDomain
tmpListDomain_Identity
tmpStg_ILIAxialStrain
UnitConversion
UnitOfMeasure'

SET @List = REPLACE(@List, ' ', '')
SET @List = REPLACE(@List, CHAR(10), ' ')
SET @List = REPLACE(@List, CHAR(13), '')
SET @List = REPLACE(@List, CHAR(9), '')
SET @List = REPLACE(@List, ' ', ''', ''')
SET @List = REPLACE(@List, ''''', ', '')

SET @List = '''' + @List + ''''


-- Generate Query to get a list of all the tables that need to be dropped (results stored in a temporary table)
SET @GetTableList = 'DECLARE @result TABLE (table_name NVARCHAR(100))
INSERT INTO @Result
SELECT table_name FROM information_schema.tables
WHERE table_name in (' + @List + ') 
SELECT * FROM @Result'

INSERT INTO @TableList
EXECUTE sp_executesql @GetTableList

--DECLARE DeleteTable_Cursor CURSOR FOR
SELECT * FROM @TableList


OPEN DeleteTable_Cursor  
FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 

-- Outer While loop cycles through the tables that needs to be deleted
WHILE @@FETCH_STATUS = 0  
BEGIN 
	
	-- Generate query to get list of foreign keys referencing the table in the current iteration (store result in temp table)
	SET @GetFKConstraints = 'DECLARE @Result TABLE (FK_table NVARCHAR(100), constraint_name NVARCHAR(300))
	INSERT INTO @Result
	SELECT SubQ.table_name, SubQ.constraint_name 
	FROM
	(
	SELECT DISTINCT(rc.constraint_name), fk_info.TABLE_NAME
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
		ON rc.constraint_name = fk_info.constraint_name
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
		ON rc.unique_constraint_name = pk_info.constraint_name
	JOIN INFORMATION_SCHEMA.TABLES tab
		ON tab.TABLE_NAME = pk_info.table_name
	WHERE pk_info.table_name = ''' + @TableName + '''
	AND tab.TABLE_TYPE = ''BASE TABLE'') SubQ
	
	SELECT * FROM @Result'

	INSERT INTO @FKConstraintList
	EXECUTE sp_executesql @GetFKConstraints

	-- Check if there are any foreign key constraints on the table
	IF (SELECT COUNT(*) FROM @FKConstraintList) > 0
	BEGIN
		DECLARE @Counter INT = 1
		DECLARE @TabLength INT 
		SELECT @TabLength = MAX(id) FROM @FKConstraintList

		-- Inner loop deletes foreign keys referencing the table in the outer loop
		WHILE @Counter <= (SELECT MAX(ID) FROM @FKConstraintList)
		BEGIN
			SELECT @constraint_name = constraint_name FROM @FKConstraintList
			WHERE id = @Counter

			SELECT @FK_Table = FK_Table FROM @FKConstraintList
			WHERE id = @Counter

			IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @constraint_name) --AND parent_object_id = OBJECT_ID('' + @FK_Table + ''))
			BEGIN
				SET @SQL = 'ALTER TABLE ' + @FK_Table + ' DROP CONSTRAINT ' + @constraint_name

				-- Drops foreign key
				EXECUTE sp_executesql @SQL
			END
		
			SET @Counter += 1
		END
	END 
    
	-- Drops Table
	EXECUTE ('DROP TABLE dbo.' + @TableName )

	FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 
END 

CLOSE DeleteTable_Cursor  
DEALLOCATE DeleteTable_Cursor		
	