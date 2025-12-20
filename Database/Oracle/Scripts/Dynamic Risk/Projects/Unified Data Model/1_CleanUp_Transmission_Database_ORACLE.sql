SET SERVEROUTPUT ON
/*
	This script deletes all tables named in the variable 'List' from the database where it is executed
*/
DECLARE

    List NVARCHAR2(20000);
    sql_stmt NVARCHAR2(20000);

    TYPE Constraint_Record_Type IS RECORD
    (fk_table NVARCHAR2(100),
     constraint_name NVARCHAR2(100));

    TYPE Constraint_Table_Type IS TABLE OF Constraint_Record_Type
    INDEX BY BINARY_INTEGER;

    ConstraintList Constraint_Table_Type;

    TYPE List_Table_Type IS TABLE OF NVARCHAR2(100)
        INDEX BY BINARY_INTEGER;

    TableList List_Table_Type;
   
BEGIN
    List :=  q'[AppList
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
			UnitOfMeasure]';

    -- Turn string list of tables into a format to be used in an sql query
    List := '''' || REPLACE(UPPER(List), ' ', '');
    List := REPLACE(List, CHR(10), ''', ''') || '''';

    -- Get the list of tables within 'List' variable that exist in the database
    sql_stmt := 'SELECT table_name FROM all_tables
                WHERE table_name IN (' || List || ')';

    -- store table list in table variable
    EXECUTE IMMEDIATE sql_stmt
    BULK COLLECT INTO TableList;

    -- Loop through and delete each table in TableList
    FOR i IN 1..TableList.COUNT LOOP
        
        -- Generate a list of all foreign key constraints on current table that is to be deleted
        sql_stmt := 'SELECT DISTINCT uc.table_name, uc.constraint_name 
                       FROM user_constraints uc
                       JOIN user_cons_columns ucc
                        ON uc.r_constraint_name = ucc.constraint_name
                       WHERE uc.constraint_type = ''R''
                        AND ucc.table_name = ''' || TableList(i) || ''' COLLATE BINARY_CI';
        
        EXECUTE IMMEDIATE sql_stmt
        BULK COLLECT INTO ConstraintList;

        -- Deletes all foreign keys referencing the table in current loop iteration
        FOR j IN 1..ConstraintList.COUNT LOOP

            sql_stmt := 'ALTER TABLE ' || ConstraintList(j).fk_table || ' DROP CONSTRAINT '
                        || ConstraintList(j).constraint_name ;

           EXECUTE IMMEDIATE sql_stmt;

        END LOOP;

        -- Delete the table in the current loop iteration
        sql_stmt := 'DROP TABLE ' || TableList(i);
        EXECUTE IMMEDIATE sql_stmt;

    END LOOP;
END;
/