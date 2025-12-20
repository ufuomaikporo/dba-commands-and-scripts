ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE 
    CNT INT;
    e_Wrong_Database EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences  
    WHERE ParameterName = 'DatabaseType' AND Value = 'Stage';
    
    IF CNT = 0 THEN
        RAISE e_Wrong_Database;
    END IF;
    
EXCEPTION
    WHEN e_Wrong_Database THEN 
        DBMS_OUTPUT.PUT_LINE('The target database is not Stage database for applying this upgrade script.');
END;
/

DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 0
    THEN

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

-- 1_CleanUp_Transmission_Database_ORACLE.sql 
DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 1
    THEN
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

            CNT INT;
        
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
            List := '''' || REPLACE(REPLACE(UPPER(List), ' ', ''), CHR(9), '');
            List := REPLACE(List, CHR(10), ''', ''') || '''';

            -- Get the list of tables within 'List' variable that exist in the database
            sql_stmt := 'SELECT table_name FROM all_tables
                        WHERE table_name IN (' || List || ')';

            -- store table list in table variable
            EXECUTE IMMEDIATE sql_stmt
            BULK COLLECT INTO TableList;

            -- Loop through and delete each table in TableList
            FOR i IN 1..TableList.COUNT LOOP

                SELECT COUNT(*) INTO CNT
                FROM user_tables 
                WHERE table_name = TableList(i);

                -- Delete the table in the current loop iteration
                IF CNT <> 0 THEN
                    sql_stmt := 'DROP TABLE ' || TableList(i) || ' CASCADE CONSTRAINTS';
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;

            END LOOP;
        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 2,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
    DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
 
END;
/


-- 2_Modify_ListDomain_ColumnDefinition_ORACLE.sql
DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 2
    THEN
        /*
            This script modifies the length of the Listdomain 'Id' column as well as the length of all other table columns
            referencing ListDomain 'Id' column to a precision of 10 and scale 0. 

            This script must be executed on the target database
        */
        DECLARE
            sql_stmt NVARCHAR2(20000);
            FKTableName NVARCHAR2(100);
            FKColumnName NVARCHAR2(100);
            ColumnName NVARCHAR2(100);
            IndexName NVARCHAR2(100);
            CNT INT;
            Counter INT;

            TargetTable NVARCHAR2(100) := 'ListDomain';
            TargetColumn NVARCHAR2(100) := 'Id';

            TYPE Constraint_Record_Type IS RECORD
            (constraint_name NVARCHAR2(100),
            fk_table NVARCHAR2(100),
            fk_column NVARCHAR2(100)    
            );

            TYPE Constraint_Table_Type IS TABLE OF Constraint_Record_Type
            INDEX BY BINARY_INTEGER;

            ChildTableList Constraint_Table_Type;

        BEGIN

            sql_stmt := 'WITH tmpQuery AS
                        (SELECT ucc2.constraint_name,
                                ucc2.table_name FKTableName,
                                ucc2.column_name FKColumnName,
                                ucc.table_name PKTableName,
                                ucc.column_name PKColumnName
                        FROM user_constraints uc
                        JOIN user_cons_columns ucc
                            ON uc.r_constraint_name = ucc.constraint_name
                        JOIN user_cons_columns ucc2
                            ON ucc2.constraint_name = uc.constraint_name
                        WHERE ucc.table_name = ''' || TargetTable || '''
                        AND ucc.column_name = ''' || TargetColumn || '''
                        UNION
                        SELECT NULL AS constraint_name,
                            table_name AS FKTableName,
                            column_name AS FKColumnName,
                            NULL AS PKTableName,
                            NULL AS PKColumnName
                        FROM user_tab_columns
                        WHERE column_name LIKE ''%DOMAINID''
                        AND table_name NOT IN (SELECT view_name FROM user_views)
                        )
                        SELECT COUNT(*)
                        FROM user_tab_columns utc
                        JOIN tmpQuery tmp
                            ON tmp.FKTableName = utc.table_name
                            AND tmp.FKColumnName = utc.column_name
                        WHERE data_precision <> 0
                        AND data_scale <> 0';

            EXECUTE IMMEDIATE sql_stmt INTO CNT;

            -- Store Info on columns referencing the TargetColumn whose column definitions need to be modified
            IF CNT <> 0 THEN

                sql_stmt := 'WITH tmpQuery AS
                        (SELECT ucc2.constraint_name,
                                ucc2.table_name FKTableName,
                                ucc2.column_name FKColumnName,
                                ucc.table_name PKTableName,
                                ucc.column_name PKColumnName
                        FROM user_constraints uc
                        JOIN user_cons_columns ucc
                            ON uc.r_constraint_name = ucc.constraint_name
                        JOIN user_cons_columns ucc2
                            ON ucc2.constraint_name = uc.constraint_name
                        WHERE ucc.table_name = ''' || TargetTable || '''
                        AND ucc.column_name = ''' || TargetColumn || '''
                        UNION
                        SELECT NULL AS constraint_name,
                            table_name AS FKTableName,
                            column_name AS FKColumnName,
                            NULL AS PKTableName,
                            NULL AS PKColumnName
                        FROM user_tab_columns utc
                        WHERE column_name LIKE ''%DOMAINID''
                        AND table_name NOT IN (SELECT view_name FROM user_views)
                        )
                        SELECT DISTINCT tmp.FKTableName,
                                tmp.FKColumnName
                        FROM user_tab_columns utc
                        JOIN tmpQuery tmp
                            ON tmp.FKTableName = utc.table_name
                            AND tmp.FKColumnName = utc.column_name
                        WHERE data_precision <> 0
                        AND data_scale <> 0';

                EXECUTE IMMEDIATE sql_stmt
                BULK COLLECT INTO ChildTableList;

                -- Loop through each column that needs to be modified
                FOR i IN 1..ChildTableList.COUNT LOOP

                    FKTableName := ChildTableList(i).fk_table;
                    FKColumnName := ChildTableList(i).fk_column;

            -------------------------------------- MODIFY THE COLUMN DEFINITION ------------------------------------------

                    -- Modify the column definition for the column in the current loop iteration
                    sql_stmt := 'ALTER TABLE ' || FKTableName || ' MODIFY ' || FKColumnName || ' NUMBER(10, 0)';

                    EXECUTE IMMEDIATE sql_stmt;

                END LOOP;

            END IF;

        -------------------------------------- MODIFY TARGET TABLE COLUMN DEFINITION ---------------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_tab_columns
            WHERE table_name = TargetTable
            AND column_name = TargetColumn
            AND data_precision = 10
            AND data_scale = 0;

            IF CNT = 0 THEN
                sql_stmt := 'ALTER TABLE ' || TargetTable || ' MODIFY ' || TargetColumn || ' NUMBER(10,0)';

                EXECUTE IMMEDIATE sql_stmt;
            END IF;

        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 3,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
    DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


-- 3_Create_VirtualTableListDomainTables_ORACLE.sql
DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);

    -- User defined exceptions
    Too_Many_DomainId EXCEPTION;

    VTableName NVARCHAR2(100);
    VColumnName NVARCHAR2(100);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 3
    THEN

        DECLARE
            NewTableName NVARCHAR2(100);
            VColumnId INT;
            VTableId INT;
            sql_stmt NVARCHAR2(20000);
            CNT INT;
            DomainId INT;

            -- record variable
            TYPE list_record_type IS RECORD
            (VirtualColumnId INT,
            VirtualColumnName VARCHAR2(50),
            VirtualTableId INT,
            VirtualTableName VARCHAR2(50)
            );

            -- table variables
            TYPE List_Table_Type IS TABLE OF list_record_type
            INDEX BY BINARY_INTEGER;

            NewDomainTableList List_Table_Type;

        BEGIN

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef');

            IF CNT <> 3 THEN
                DBMS_OUTPUT.PUT_LINE('One of the ListDomain, DomainCatalog or DomainCatalogColXRef tables are missing.');
                RETURN;
            END IF;

            --Populate NewDomainTableList table
            SELECT DISTINCT vc.Id AS VirtualColumnId,
            vc.VirtualColumnName,
            vc.VirtualTableId,
            vt.VirtualTableName
            BULK COLLECT INTO NewDomainTableList
            FROM VirtualColumn vc
            JOIN VirtualTable vt
                ON vt.Id = vc.VirtualTableId
            WHERE VirtualColumnDataTypeInd = 'L';

        -- ------------------------------ Cursor to Create new list domain virtual tables -------------------------------

            FOR i IN 1..NewDomainTableList.COUNT LOOP

                VTableId := NewDomainTableList(i).VirtualTableId;
                VTableName := NewDomainTableList(i).VirtualTableName;
                VColumnId := NewDomainTableList(i).VirtualColumnId;
                VColumnName := NewDomainTableList(i).VirtualColumnName;
                NewTableName := NULL;
                DomainId := NULL;   

                sql_stmt := 'SELECT COUNT(*)
                FROM DomainCatalogColXRef
                WHERE TableName = ''' ||VTableName || '''
                AND ColumnName = ''' || VColumnName || '''' ;

                EXECUTE IMMEDIATE sql_stmt INTO CNT;

                /* If there is an entry in the DomainCatalogColXRef table for the virtual table and column 
                use the Domain name to form the new list domain table name
                */
                IF CNT <> 0 THEN
                    -- Retrieve DomainCatalogId for the virtual table and column from DomainCatalogColXRef table if it exists
                    sql_stmt := 'SELECT DomainCatalogId
                    FROM DomainCatalogColXRef
                    WHERE TableName = ''' || VTableName || '''
                    AND ColumnName = ''' || VColumnName || '''';

                    EXECUTE IMMEDIATE sql_stmt INTO DomainId;

                ELSE
                    DomainId := NULL;
                END IF;
                    
                -- Check if the Virtual table and column has an entry in the ListDomain table with a unique DomainCatalogId
                sql_stmt := 'SELECT COUNT(DISTINCT DomainCatalogId) 
                FROM ListDomain
                WHERE Id IN (SELECT DataFieldValueDomainId 
                            FROM VirtualTableDataListDomain
                            WHERE VirtualTableId = ' || VTableId || '
                            AND VirtualColumnId = ' || VColumnId ||')
                AND DomainCatalogId <> -1';

                EXECUTE IMMEDIATE sql_stmt INTO CNT;
                
                /*
                If the Virtual table and column does not have an entry in the DomainCatalogColXRef table but has has an entry in the
                ListDomain table, check to see and raise an error if there are more than one unique DomainCatalogId for entries
                in the ListDomain table
                */
                IF CNT > 1 AND DomainId IS NULL THEN
                    RAISE Too_Many_DomainId;
                /*
                    if the virtual table and column has an entry in the ListDomain table But not in the DomainCatalogColXRef table
                    use the DomainCatalogId from the ListDomain table entries to find the DomainDescr. This will be the new table name
                */
                ELSIF CNT = 1 AND DomainId IS NULL THEN

                    sql_stmt := 'SELECT DomainCatalogId 
                    FROM ListDomain
                    WHERE Id IN (SELECT DataFieldValueDomainId 
                                FROM VirtualTableDataListDomain
                                WHERE VirtualTableId = ' || VTableId || '
                                AND VirtualColumnId = ' || VColumnId || ')
                    AND DomainCatalogId <> -1
                    AND rownum < 2';

                    EXECUTE IMMEDIATE sql_stmt INTO DomainId;

                END IF;

                NewTableName := 'LD_' || REPLACE(REPLACE(REGEXP_REPLACE(VColumnName, 'DomainId|Ld|LD', ''), 'Remediation', 'Remed'), 'Reinforcement', 'Reinforce');

        -------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------

                SELECT COUNT(*) INTO CNT 
                FROM user_tables
                WHERE table_name = NewTableName;

                IF CNT = 0 THEN
                    -- Create new list domain table
                    sql_stmt := 'CREATE TABLE '|| NewTableName ||'
                                (Id NUMBER(10, 0) GENERATED BY DEFAULT AS IDENTITY,
                                Code VARCHAR2(60) NOT NULL,
                                Descr VARCHAR2(255) NOT NULL,
                                EffectiveEndDate TIMESTAMP,
                                CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                                CreatedDate TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
                                LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                                LastModDateTime TIMESTAMP DEFAULT CURRENT_DATE NOT NULL, 
                                CONSTRAINT PK_'|| NewTableName || ' PRIMARY KEY (Id)
                                )';

                EXECUTE IMMEDIATE sql_stmt;
                
                END IF;

                -- Create update/delete trigger on table
                sql_stmt := 'CREATE OR REPLACE TRIGGER tu_' || NewTableName || '
                            AFTER UPDATE OR DELETE
                            ON ' || NewTableName || '
                            FOR EACH ROW
                            BEGIN
                                UPDATE ' || NewTableName || ' 
                                    SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                        LastModDateTime = SYSDATE;
                            END;';

                EXECUTE IMMEDIATE sql_stmt;
                
        --------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------

                sql_stmt := '
                DECLARE
                    CNT INT;
                    sql_stmt VARCHAR2(20000);
                BEGIN

                    SELECT COUNT(*) INTO CNT
                    FROM user_tables 
                    WHERE table_name = UPPER(''ListDomainInfo'');

                    SELECT COUNT(*) INTO CNT
                    FROM ' || NewTableName || ';
                
                    IF (CNT = 0) THEN
                        

                        INSERT INTO ' || NewTableName || '
                        (Id,
                        Code,
                        Descr,
                        EffectiveEndDate)
                        SELECT Id,
                            CASE
                                WHEN Code = '''' THEN ''None''
                                ELSE Code
                            END AS Code,
                            CASE
                                WHEN Code = '''' THEN ''None''
                                ELSE Descr
                            END As Descr,
                            CASE
                                WHEN DomainCatalogId = -1 THEN CURRENT_DATE
                                ELSE NULL
                            END AS EffectiveEndDate
                        FROM ListDomain 
                        WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId
                                    FROM VirtualTableDataListDomain
                                    WHERE VirtualTableId = ' || VTableId || '
                                    AND VirtualColumnId = ' || VColumnId || '
                                    )
                        AND Id NOT IN (SELECT Id FROM ' || NewTableName || ');
                        
                    END IF;

                    COMMIT;

                END;';

                EXECUTE IMMEDIATE sql_stmt;       

        ------------------------- Create and update the TempListDomainTable table in Config database ----------------

                -- Create TempListDomainTable table and drop foreign key during first loop iteration 
                IF i = 1 THEN

                    --Drop the TempListDomainTable table if it exists
                    SELECT COUNT(*) INTO CNT
                    FROM user_tables
                    WHERE table_name = 'TempListDomainTable';

                    IF CNT = 1 THEN
                        EXECUTE IMMEDIATE 'DROP TABLE TempListDomainTable';
                    END IF;

                    SELECT COUNT(*) INTO CNT
                    FROM user_tables
                    WHERE table_name = 'TempListDomainTable';
                    
                    --Recreate the TempListDomainTable table
                    IF CNT = 0 THEN
                        sql_stmt := 'CREATE TABLE TempListDomainTable (TableType VARCHAR(50),
                                                                        ListDomainTableName VARCHAR(50),
                                                                        ReferencedTableName VARCHAR(50),
                                                                        ReferencedColumnName VARCHAR(50),
                                                                        DomainCatalogId INT,
                                                                        DomainDescr VARCHAR(255)
                                                                        )';
                                                    
                        EXECUTE IMMEDIATE sql_stmt;
                    
                    END IF;

                END IF;
                
                --Insert VirtualTable info into TempListDomainTable table
                sql_stmt := '
                DECLARE
                    CNT INT;
                BEGIN

                    SELECT COUNT(*) INTO CNT
                    FROM TempListDomainTable
                    WHERE ReferencedTableName = ''' || VTableName || '''
                    AND ReferencedColumnName = ''' || VColumnName || ''';

                    IF CNT = 0 THEN
                    
                        INSERT INTO TempListDomainTable
                        VALUES(''Virtual'',
                                ''' || NewTableName || ''',
                                ''' || VTableName || ''',
                                ''' || VColumnName || ''',
                                ''' || DomainId || ''',
                                (SELECT DomainDescr FROM DomainCatalog WHERE Id = ''' || DomainId || '''));
                    END IF;

                    COMMIT;
                END;';

                EXECUTE IMMEDIATE sql_stmt;

            END LOOP;
            
        -------------------------------- Drop VirtualTableDataListDomain table ------------------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_constraints  uc
            LEFT JOIN user_cons_columns ucc
                ON uc.r_constraint_name = ucc.constraint_name
            WHERE uc.constraint_type = 'R'
            AND ucc.table_name = 'ListDomain'
            AND ucc.column_name = 'Id'
            AND uc.table_name = 'VirtualTableDataListDomain';

            --Drop foreign key on VirtualTableDataListDomain referencing ListDomain table
            IF CNT = 1 THEN

                SELECT 'ALTER TABLE VirtualTableDataListDomain DROP CONSTRAINT ' || uc.constraint_name
                INTO sql_stmt
                FROM user_constraints  uc
                LEFT JOIN user_cons_columns ucc
                    ON uc.r_constraint_name = ucc.constraint_name
                WHERE uc.constraint_type = 'R'
                AND ucc.table_name = 'ListDomain'
                AND ucc.column_name = 'Id'
                AND uc.table_name = 'VirtualTableDataListDomain';

                EXECUTE IMMEDIATE sql_stmt;

            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'temp_VirtualTableDataListDomain';

            -- Create a table to temporarily store VirtualTableDataListDomain data
            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE temp_VirtualTableDataListDomain AS SELECT * FROM VirtualTableDataListDomain';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'VirtualTableDataListDomain';

            IF CNT <> 0 THEN
                -- Drop VirtualTableDataListDomain table
                sql_stmt := 'DROP TABLE VirtualTableDataListDomain';

                EXECUTE IMMEDIATE sql_stmt;
            END IF;

        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 4,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN Too_Many_DomainId THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) ||'Error: There are more than 1 domain category listed in ListDomain table for the '
                        || VTableName || ' virtual table and ' || VColumnName 
                        || ' virtual column. Insert the correct DomainCatalogId into the DomainCatalogColXRef table for this table-column combination for the script to continue.');
        
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


--4_Create_NewListDomainTables_ORACLE.sql
DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    ColName VARCHAR2(100);
    TabName VARCHAR2(100);
    DomainId INT;
    sql_stmt VARCHAR(20000);

    --User defined errors
    Too_Many_DomainId_1 EXCEPTION;
    Too_Many_DomainId_2 EXCEPTION;

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 4
    THEN
        /*
            This script takes the ListDomain data for virtual tables and seperates them into various ListDomain 
            tables with names prefixed by 'LD_'. The LD tables are named based on the column names of the virtual 
            tables referencing them. 

            This script also 
            1) Creates (or delete and recreates) the TempListdomainTable table.
            2) Creates a copy of the VirtualTableDataListDomain table prefixed with 'temp_' then drops the 
                VirtualTableDataListDomain table
            
            This script must be executed on the target stage database
        */

        DECLARE
            NewTableName VARCHAR2(100);
            ConstraintName VARCHAR2(100);
            FKTableName VARCHAR2(100);
            FKColumnName VARCHAR2(100);
            sql_stmt NVARCHAR2(20000);
            CNT INT;
            DomainCatalogId INT;

        BEGIN

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'NewDomainTableList';

            IF CNT <> 0 THEN
                EXECUTE IMMEDIATE 'DROP TABLE NewDomainTableList';
            END IF;

            sql_stmt := 'CREATE TABLE NewDomainTableList
                        (Id INT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
                        FKConstraint VARCHAR2(100),
                        FKTableName VARCHAR2(100),
                        FKColumnName VARCHAR2(100),
                        NewListDomainTable VARCHAR2(100),
                        DomainCatalogId INT,
                        DomainDescr VARCHAR2(100)
                        )';
            
            EXECUTE IMMEDIATE sql_stmt;
                   
            sql_stmt := '
            INSERT INTO NewDomainTableList (FKConstraint, 
                                            FKTableName, 
                                            FKColumnName, 
                                            NewListDomainTable, 
                                            DomainCatalogId, 
                                            DomainDescr)
            SELECT uc.constraint_name,
                uc.table_name,
                    ucc2.column_name,
                    NULL,
                    NULL,
                    NULL
            FROM user_constraints uc
            JOIN user_cons_columns ucc
                ON uc.r_constraint_name = ucc.constraint_name
            JOIN user_cons_columns ucc2
                ON uc.constraint_name = ucc2.constraint_name
            WHERE ucc.table_name = ''ListDomain''
            AND ucc.column_name = ''Id''
            AND uc.table_name NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
            ';

            EXECUTE IMMEDIATE sql_stmt;

            -- Tables that are missing a foreign key reference to the ListDomain table
            sql_stmt := '
            BEGIN
                INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
                VALUES (''FK_POECompLookup_MetalLossTypeDomain'', ''POECompanyLookUp'', ''MetalLossTypeDomainId'');

                INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
                VALUES (''FK_POECompLookup_ToolTypeDomain'', ''POECompanyLookUp'', ''ToolTypeDomainId'');

                INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
                VALUES (''FK_StgILICA_ILICADepthDomain'', ''Stg_ILICrackAnomaly'', ''ILICADepthDomainId'');
            END;';

            EXECUTE IMMEDIATE sql_stmt;

            -- LD tables that will not have a foreign key referencing them but are necessary for App function
            sql_stmt := 'INSERT INTO NewDomainTableList (DomainDescr, DomainCatalogId, NewListDomainTable)
                    SELECT DISTINCT dc.DomainDescr, 
                                    dc.Id,
                                    ldi."LDTableName"
                    FROM ListDomainTableInfo@DRASORA19C22 ldi
                    RIGHT JOIN DomainCatalog dc
                        ON REPLACE(ldi."DomainDescr", CHR(32), '''') = REPLACE(dc.DomainDescr, CHR(32), '''')
                        AND ldi."TableName" NOT LIKE ''%IRASCustom%''
                    ';

            EXECUTE IMMEDIATE sql_stmt;

            COMMIT;

            sql_stmt := '
            BEGIN
                -- Get the new ListDomain table name from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo (match tableName and columnName)
                UPDATE NewDomainTableList tab1
                SET NewListDomainTable = (SELECT DISTINCT tab2."LDTableName" 
                                            FROM ListDomainTableInfo@DRASORA19C22 tab2
                                            WHERE tab1.FKColumnName = tab2."ColumnName"
                                            AND tab1.FKTableName = tab2."TableName"
                                            AND rownum < 2)
                WHERE EXISTS (SELECT 1 FROM ListDomainTableInfo@DRASORA19C22 tab2
                                WHERE tab1.FKColumnName = tab2."ColumnName"
                                AND tab1.FKTableName = tab2."TableName");

                -- Get the new ListDomain table name from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo (match only column name if there are no tablename matches)
                UPDATE NewDomainTableList tab1
                SET NewListDomainTable = (SELECT DISTINCT tab2."LDTableName"
                                            FROM ListDomainTableInfo@DRASORA19C22 tab2
                                            WHERE tab1.FKColumnName = tab2."ColumnName")
                WHERE EXISTS (SELECT 1 FROM ListDomainTableInfo@DRASORA19C22 tab2
                                WHERE tab1.FKColumnName = tab2."ColumnName")
                AND NewListDomainTable IS NULL;

                --Generate an LD name based on the DomainDescr
                UPDATE NewDomainTableList tab1
                SET NewListDomainTable = (SELECT DISTINCT tab2."LDTableName"
                                            FROM ListDomainTableInfo@DRASORA19C22 tab2
                                            WHERE tab1.DomainDescr = tab2."DomainDescr")
                WHERE EXISTS (SELECT 1 FROM ListDomainTableInfo@DRASORA19C22 tab2
                              WHERE tab1.DomainDescr = tab2."DomainDescr") 
                AND NewListDomainTable IS NULL;

                --Generate an LD table name for tables that could not be matched with an LD table name in the DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo table
                UPDATE NewDomainTableList tab1
                SET NewListDomainTable = (SELECT CASE 
                                                    WHEN FKTableName LIKE ''IRASCustom%''
                                                        THEN ''LD_'' || FKTableName || ''_'' || REPLACE(FKColumnName, ''_DomainId'', '''')
                                                    WHEN INSTR(FKColumnName, ''DomainId'') > 0
                                                        THEN ''LD_'' || REPLACE(REPLACE(FKColumnName, ''_DomainId'', ''''), ''DomainId'', '''') 
                                                    WHEN INSTR(FKColumnName, ''Ld'') > 0
                                                        THEN ''LD_'' || REPLACE(FKColumnName, ''Ld'', '''')
                                                    ELSE ''LD_'' || FKColumnName
                                                END
                                        FROM NewDomainTableList tab2
                                        WHERE tab1.FKTableName = tab2.FKTableName
                                        AND tab1.FKColumnName = tab2.FKColumnName)
                WHERE EXISTS (SELECT 1 FROM NewDomainTableList tab2
                                WHERE tab1.FKTableName = tab2.FKTableName
                                AND tab1.FKColumnName = tab2.FKColumnName)
                AND NewListDomainTable IS NULL;
            END;';

            EXECUTE IMMEDIATE sql_stmt;

            COMMIT;

            -- Update the DomainCatalogId and DomainDescr columns using the DomainCataogColXRef table
            sql_stmt := 'UPDATE NewDomainTableList nldt
                        SET (DomainCatalogId, DomainDescr) = (SELECT dccxr.DomainCatalogId, dc.DomainDescr
                                                                FROM DomainCatalogColXRef dccxr
                                                                JOIN DomainCatalog dc
                                                                ON dc.Id = dccxr.DomainCatalogId
                                                                WHERE dccxr.TableName = nldt.FKTableName
                                                                AND dccxr.ColumnName = nldt.FKColumnName
                                                                AND nldt.FKTableName IS NOT NULL
                                                            )
                        WHERE EXISTS (SELECT 1 FROM DomainCatalogColXRef dccxr
                                    WHERE dccxr.TableName = nldt.FKTableName
                                    AND dccxr.ColumnName = nldt.FKColumnName)';

                                                
            EXECUTE IMMEDIATE sql_stmt;                       

        END; 

        DECLARE
            NewTableName VARCHAR2(100);
            ConstraintName VARCHAR2(100);
            sql_stmt VARCHAR2(20000);
            sql_stmt2 VARCHAR2(20000);
            CNT INT;
            CatalogIdCount INT;
            Domain VARCHAR2(100);

            -- Record variable
            TYPE fk_record_type IS RECORD
            (FKConstraint VARCHAR2(100),
                FKTableName VARCHAR2(100),
                FKColumnName VARCHAR2(100),
                NewTableName VARCHAR2(100),
                DomainCatalogId INT,
                DomainDescr VARCHAR2(255)
            );

            -- Table variables
            TYPE fk_Table_Type IS TABLE OF fk_record_type
            INDEX BY BINARY_INTEGER;

            DomainTableList fk_Table_Type;

        BEGIN

            --Populate table variable   
            sql_stmt := 'SELECT FKConstraint, 
                    FKTableName, 
                    FKColumnName, 
                    NewListDomainTable, 
                    DomainCatalogId, 
                    DomainDescr    
            FROM NewDomainTableList
            WHERE FKTablename IS NOT NULL';

            EXECUTE IMMEDIATE sql_stmt 
            BULK COLLECT INTO DomainTableList;

            sql_stmt := 'SELECT COUNT(*) FROM NewDomainTableList';
            EXECUTE IMMEDIATE sql_stmt INTO CNT;

            IF CNT <= 3 THEN
                DBMS_OUTPUT.PUT_LINE('Missing or too few entries in table "NewDomainTableList". Restore the Database and retry the upgrade');
                RETURN;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef');

            IF CNT <> 3 THEN
                DBMS_OUTPUT.PUT_LINE('One of the ListDomain, DomainCatalog or DomainCatalogColXRef tables are missing.');
                RETURN;
            END IF;

            FOR i IN 1..DomainTableList.COUNT LOOP

        ------------------------------- VALIDATE LISTDOMAIN DATA --------------------------------

            CatalogIdCount := NULL;
        
            ColName := DomainTableList(i).FKColumnName;
            Tabname := DomainTableList(i).FKTableName;
            DomainId := DomainTableList(i).DomainCatalogId;
            Domain := DomainTableList(i).DomainDescr;
            NewTableName := DomainTableList(i).NewTableName;
            ConstraintName := DomainTableList(i).FKConstraint;

            -- Find the number of distinct DomainCatalogIds for current table and column combo in ListDomain table 
            IF (ColName IS NOT NULL AND TabName IS NOT NULL) THEN

                sql_stmt := 'SELECT COUNT(DISTINCT DomainCatalogId)
                FROM ListDomain
                WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ')
                AND DomainCatalogId <> -1';

                EXECUTE IMMEDIATE sql_stmt INTO CatalogIdCount;

            END IF;

            /*
                If the table and column in the current loop has an entry in the DomainCatalogColXRef table
                and more than 1 distinct DomainCatalogIds (other than -1) in it's ListDomain table entries,
                throw an error and force the user to fix the issue manually
            */
            IF (CatalogIdCount > 1 AND Domainid IS NOT NULL ) THEN
                RAISE Too_Many_DomainId_1;
            /*
                if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
                table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
                then throw an error to force user to manually fix the issue
            */
            ELSIF (DomainId IS NULL AND CatalogIdCount > 1) THEN
                RAISE Too_Many_DomainId_2; 
            /*
                If the table and column in the current loop has no entry in the DomainCatalogColXRef table
                and has entries in the ListDomain table with a single distinct DomainCatalogId other than -1,
                then use the DomainCatalogId from the ListDomain table.
            */	
            ELSIF (DomainId IS NULL AND CatalogIdCount = 1) THEN             

                sql_stmt := 'SELECT DISTINCT DomainCatalogId 
                            FROM ListDomain
                            WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName ||' )
                                AND DomainCatalogId <> -1';
                                
                EXECUTE IMMEDIATE sql_stmt INTO DomainId;
            END IF;
            

            sql_stmt := 'UPDATE NewDomainTableList
            SET DomainCatalogId = ''' ||DomainId || ''',
                DomainDescr = (SELECT DomainDescr FROM DomainCatalog WHERE Id = '''||DomainId||''')
            WHERE FKTableName = '''|| TabName || '''
            AND FKColumnName = '''||ColName || '''
            AND DomainDescr IS NULL';

            EXECUTE IMMEDIATE sql_stmt;

        -------------------------------------- CREATE New ListDomain tables ---------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = NewTableName;

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE '|| NewTableName ||'
                            (Id NUMBER(10, 0) GENERATED BY DEFAULT AS IDENTITY,
                            Code VARCHAR2(60) NOT NULL,
                            Descr VARCHAR2(255) NOT NULL,
                            EffectiveEndDate TIMESTAMP,
                            CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                            CreatedDate TIMESTAMP DEFAULT SYSDATE NOT NULL,
                            LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                            LastModDateTime TIMESTAMP DEFAULT SYSDATE NOT NULL, 
                            CONSTRAINT PK_'|| NewTableName || ' PRIMARY KEY (Id)
                            )';

                EXECUTE IMMEDIATE sql_stmt;

            END IF;

            -- Create update/delete trigger on table
            sql_stmt := 'CREATE OR REPLACE TRIGGER tu_' || NewTableName || '
                        AFTER UPDATE OR DELETE
                        ON ' || NewTableName || '
                        FOR EACH ROW
                        BEGIN
                            UPDATE ' || NewTableName || ' 
                                SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                    LastModDateTime = SYSDATE;
                        END;';

            EXECUTE IMMEDIATE sql_stmt;

        -------------------------------- Populate the New List Domain Table ----------------------------------

            IF (ColName IS NOT NULL) THEN
                sql_stmt := 'SELECT COUNT(*) FROM ListDomain WHERE Id IN (SELECT DISTINCT '|| ColName || ' FROM '|| TabName || ') ';

                EXECUTE IMMEDIATE sql_stmt INTO CNT;
            END IF;

            -- If a table-column pair an entry in the ListDomain table, populate using ListDomain data
            IF (ColName IS NOT NULL AND CNT > 0) THEN
                sql_stmt := 'INSERT INTO ' || NewTableName || ' (Id, Code, Descr, EffectiveEndDate)
                            WITH tmpQuery AS
                            (SELECT Id,
                                DomainCatalogId,
                                Code,
                                Descr
                            FROM ListDomain
                            WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName || ')
                            UNION
                            SELECT Id,
                                    DomainCatalogId,
                                    Code,
                                    Descr
                            FROM ListDomain WHERE DomainCatalogId = ' || DomainId || '
                            )
                            SELECT Id,
                                CASE 
                                    WHEN Code = '''' OR Code IS NULL THEN ''<None>''
                                    ELSE Code
                                    END AS Code,
                                CASE 
                                    WHEN Descr = '''' OR Descr IS NULL THEN ''<None>''
                                    ELSE Descr
                                    END AS Descr,
                                CASE 
                                        WHEN DomainCatalogId = -1 THEN SYSDATE
                                        ELSE NULL
                                    END AS EffectiveEndDate
                            FROM tmpQuery
                            WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
                            ORDER BY 1';

                EXECUTE IMMEDIATE sql_stmt;
                
            -- If the Table and Column are null but DomainId is not null, then populate using DomainCatalogId from ListDomain table
            ELSIF (DomainId IS NOT NULL) THEN
                sql_stmt := 'INSERT INTO ' || NewTableName || ' (Id, Code, Descr)
                            WITH tmpQuery AS
                            (SELECT Id,
                                    DomainCatalogId,
                                    Code,
                                    Descr
                            FROM ListDomain WHERE DomainCatalogId = ' || DomainId || '
                            )
                            SELECT Id,
                                CASE 
                                    WHEN Code = '''' OR Code IS NULL THEN ''<None>''
                                    ELSE Code
                                    END AS Code,
                                CASE 
                                    WHEN Descr = '''' OR Descr IS NULL THEN ''<None>''
                                    ELSE Descr
                                    END AS Descr
                            FROM tmpQuery
                            WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
                            ORDER BY 1';

                EXECUTE IMMEDIATE sql_stmt;

            END IF;

            COMMIT;

        ------------------------------ UPDATE TempListDomainTable ---------------------------------------

            --Create TempListDomainTable table and drop foreign key during first loop iteration 
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'TempListDomainTable';
            
            --Create the TempListDomainTable table f it does not already exist
            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE TempListDomainTable (TableType VARCHAR(50),
                                                                ListDomainTableName VARCHAR(50),
                                                                ReferencedTableName VARCHAR(50),
                                                                ReferencedColumnName VARCHAR(50),
                                                                DomainCatalogId INT,
                                                                DomainDescr VARCHAR(255)
                                                                )';
                                            
                EXECUTE IMMEDIATE sql_stmt;
                
            END IF;

            -- Update entry in TempListDomainTable table
            sql_stmt := '
            DECLARE 
                CNT INT;
            BEGIN
            IF ('''||ColName||''' IS NOT NULL) THEN
                SELECT COUNT(*) INTO CNT
                FROM TempListDomainTable
                WHERE ReferencedTableName = '''|| TabName ||'''
                AND ReferencedColumnName = '''|| ColName ||'''
                AND ListDomainTableName = '''|| NewTableName ||'''
                AND TableType = ''Real'';

                IF CNT = 0 THEN

                    DELETE FROM TempListDomainTable 
                    WHERE ReferencedTableName = '''|| TabName ||'''
                    AND ReferencedColumnName = '''|| ColName ||''';

                    INSERT INTO TempListDomainTable
                    SELECT ''Real'',
                        '''|| NewTableName ||''',
                        '''|| TabName ||''',
                        '''|| ColName ||''',
                        '''|| DomainId ||''',
                        '''|| Domain ||'''
                    FROM DUAL;


                END IF;

                
            ELSE
                CNT := NULL;
                SELECT COUNT(*) INTO CNT
                FROM TempListDomainTable
                WHERE ListDomainTableName = '''|| NewTableName ||'''
                AND TableType = ''Real'';

                IF CNT = 0 THEN
                    INSERT INTO TempListDomainTable
                    SELECT ''Real'',
                            '''|| NewTableName ||''',
                            NULL,
                            NULL, 
                            '''|| DomainId ||''',
                            '''|| Domain ||'''
                    FROM DUAL;

                END IF;

            END IF;

            COMMIT;
            
            END;';

            EXECUTE IMMEDIATE sql_stmt;

            --------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------

            IF TabName IS NOT NULL THEN
                SELECT COUNT(*) INTO CNT
                FROM user_constraints uc1
                JOIN user_constraints uc2
                    ON uc1.r_constraint_name = uc2.constraint_name
                WHERE uc1.constraint_name = ConstraintName
                AND uc2.table_name = 'ListDomain';

                IF CNT = 1 THEN
                    sql_stmt := 'ALTER TABLE ' || TabName || ' DROP CONSTRAINT ' || ConstraintName;
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
                
        -------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------

                SELECT COUNT(*) INTO CNT
                FROM user_constraints
                WHERE constraint_name = ConstraintName;

                IF CNT = 0 THEN
                    sql_stmt := 'ALTER TABLE ' || TabName || ' ADD CONSTRAINT '
                                || ConstraintName || ' FOREIGN KEY ('|| ColName ||')'
                                || ' REFERENCES ' || NewTableName || ' (Id)' ;

                    EXECUTE IMMEDIATE sql_stmt;

                END IF;
            END IF;

        END LOOP;

        ----------------------------- DROP all LD/GLD tables that do not have a foreign key referencing them ----------------- 
        
        -- Check to see if there are any LD tables without a foreign key constraint that should be dropped (except for PMM table, 
        sql_stmt := 'SELECT COUNT(*)
        FROM user_tables
        WHERE (table_name like ''LD_%'' OR table_name like ''GLD_%'')
        AND table_name NOT IN (SELECT parent.table_name 
                                FROM user_constraints parent 
                                JOIN user_constraints child
                                ON parent.constraint_name = child.r_constraint_name)
        AND table_name NOT LIKE ''%PMM%Type%''
        AND table_name NOT IN (SELECT NewListDomainTable FROM NewDomainTableList
                                WHERE DomainCatalogId IN (SELECT DomainCatalogId FROM RememberedListDomainValues
                                                        UNION
                                                        SELECT DomainCatalogId FROM ActionItemPropDCXRef) 
                                )
        AND table_name NOT IN (SELECT ListDomainTableName FROM TempListDomainTable WHERE TableType = ''Virtual'')';
        
        EXECUTE IMMEDIATE sql_stmt INTO CNT;
        
        IF CNT > 0 THEN
            
                sql_stmt := '
                DECLARE
                    CURSOR Delete_Cursor IS
                    SELECT ''DROP TABLE '' || table_name  AS droptable
                    FROM user_tables
                    WHERE (table_name like ''LD_%'' OR table_name like ''GLD_%'')
                    AND table_name NOT IN (SELECT parent.table_name 
                                            FROM user_constraints parent 
                                            JOIN user_constraints child
                                            ON parent.constraint_name = child.r_constraint_name)
                    AND table_name NOT LIKE ''%PMM%Type%''
                    AND table_name NOT IN (SELECT NewListDomainTable FROM NewDomainTableList
                                            WHERE DomainCatalogId IN (SELECT DomainCatalogId FROM RememberedListDomainValues
                                                                    UNION
                                                                    SELECT DomainCatalogId FROM ActionItemPropDCXRef) 
                                            )
                    AND table_name NOT IN (SELECT ListDomainTableName FROM TempListDomainTable WHERE TableType = ''Virtual'');

                BEGIN
                    FOR i IN Delete_Cursor LOOP
                        EXECUTE IMMEDIATE i.droptable;
                    END LOOP; 
                
                END;';

                EXECUTE IMMEDIATE sql_stmt;

        END IF;
        

        /*************************************************************************************************
                            CREATE New Tables for CategoryDataListDomainXRef Table
        **************************************************************************************************/

            SELECT COUNT(*) INTO CNT
            FROM user_tab_columns
            WHERE table_name = 'CategoryDataListDomainXRef'
            AND column_name = 'ListDomainTableName';
        
            IF CNT = 0 THEN

                -- Add column to store New Listdomain table name
                sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef ADD (ListDomainTableName VARCHAR2(50))';
                    
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'UPDATE CategoryDataListDomainXRef cdl
                SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                           FROM NewDomainTableList
                                           WHERE DomainCatalogId = (SELECT DISTINCT DomainCatalogId 
                                                                    FROM ListDomain 
                                                                    WHERE Id = cdl.ValueDomainId)
                                            AND NewListDomainTable IS NOT NULL
                                        )';
                            
                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;

            END IF;

            -- Modify Table column order and add default constraints
            SELECT LISTAGG(column_name || ' INVISIBLE' , ',') WITHIN GROUP (ORDER BY 1)
            INTO sql_stmt
            FROM user_tab_columns 
            WHERE table_name = 'CategoryDataListDomainXRef'
            AND REGEXP_LIKE(column_name, 'Create|LastMod');

            sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY ('|| sql_stmt||')';

            EXECUTE IMMEDIATE sql_stmt;

            SELECT LISTAGG(column_name || ' VISIBLE' , ',') WITHIN GROUP (ORDER BY 1)
            INTO sql_stmt
            FROM user_tab_columns 
            WHERE table_name = 'CategoryDataListDomainXRef'
            AND REGEXP_LIKE(column_name, 'Create|LastMod');
                                                                            
            sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY ('|| sql_stmt||')';
                                                                            
            EXECUTE IMMEDIATE sql_stmt;

            SELECT LISTAGG(column_name || CASE WHEN column_name LIKE '%Date%' THEN 'TIMESTAMP DEFAULT SYSDATE'
                                               WHEN column_name LIKE '%User%' THEN 'VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')'
                                          END , ',') WITHIN GROUP (ORDER BY 1)
            INTO sql_stmt
            FROM user_tab_columns 
            WHERE table_name = 'CategoryDataListDomainXRef'
            AND REGEXP_LIKE(column_name, 'Create|LastMod');

            sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY ('|| sql_stmt||')';
                                                                    
            sql_stmt := 'CREATE OR REPLACE TRIGGER TU_CategoryDataListDomainXRef
                        BEFORE UPDATE ON CategoryDataListDomainXRef
                        FOR EACH ROW
                        BEGIN
                            :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                            :new.LastModDateTime := SYSDATE;
                        END;';
                        
            EXECUTE IMMEDIATE sql_stmt;
        
        /*****************************************************************************************
                        Modify RememberedListDomainValues and ActionItemPropDCXRef tables
        **********************************************************************************************/
        ----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------
        
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'RememberedListDomainValues'
        AND column_name = 'ListDomainTableName';

            IF CNT = 0 THEN
                --Add new column to RememberedListDomainValues table
                sql_stmt := 'ALTER TABLE RememberedListDomainValues ADD (ListDomainTableName VARCHAR2(50))';
                
                EXECUTE IMMEDIATE sql_stmt;

                --Update RememberedListDomainValues with values for new column
                sql_stmt := 'UPDATE RememberedListDomainValues rldv
                            SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                                        FROM NewDomainTableList
                                                        WHERE DomainCatalogId =  rldv.DomainCatalogId
                                                        AND NewListDomainTable IS NOT NULL)';

                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;


            END IF;
                
            SELECT COUNT(*) INTO CNT
            FROM user_tab_columns 
            WHERE table_name = 'RememberedListDomainValues'
            AND column_name = 'DomainCatalogId';

            IF CNT <> 0 THEN

                sql_stmt:= 'ALTER TABLE RememberedListDomainValues DROP COLUMN DomainCatalogId CASCADE CONSTRAINTS';
                
                EXECUTE IMMEDIATE sql_stmt;
            END IF;
            
            sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId INVISIBLE,
                                                                        LastModDateTime INVISIBLE,
                                                                        CreatedUser INVISIBLE,
                                                                        CreatedDate INVISIBLE )';


                                                                        
            EXECUTE IMMEDIATE sql_stmt;
                                                                
            sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId VISIBLE,
                                                                        LastModDateTime VISIBLE
                                                                        )';
            
            EXECUTE IMMEDIATE sql_stmt;
                    
            sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (CreatedUser VISIBLE,
                                                                        CreatedDate VISIBLE)';
            
            EXECUTE IMMEDIATE sql_stmt;
            
                    
            -- Modify Defaults on change tracking columns                                              
            sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''), 
                                                                        CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                                        LastModDateTime TIMESTAMP DEFAULT SYSDATE,
                                                                        CreatedDate TIMESTAMP DEFAULT SYSDATE)';
                                                                        
            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'CREATE OR REPLACE TRIGGER tu_RememberedListDomainValues
                        BEFORE UPDATE ON RememberedListDomainValues
                        FOR EACH ROW
                        BEGIN
                            :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                            :new.LastModDateTime := SYSDATE;
                        END;';
                        
            EXECUTE IMMEDIATE sql_stmt; 

        -------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE column_name = 'ListDomainTableName'
        AND table_name = 'ActionItemPropDCXRef';

            IF CNT = 0 THEN

                -- Add new column to store ListDomain table name
                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef ADD ListDomainTableName VARCHAR2(50)';
                
                EXECUTE IMMEDIATE sql_stmt;  

                --Update ActionItemPropDCXRef with values for new column
                sql_stmt := 'UPDATE ActionItemPropDCXRef aip
                            SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                                    FROM NewDomainTableList
                                                    WHERE DomainCatalogId =  aip.DomainCatalogId
                                                    AND NewListDomainTable IS NOT NULL)';

                EXECUTE IMMEDIATE sql_stmt;
            
            COMMIT;
            END IF;
            


            SELECT COUNT(*) INTO CNT
            FROM user_tab_columns 
            WHERE table_name = 'ActionItemPropDCXRef'
            AND column_name = 'DomainCatalogId';

            IF CNT <> 0 THEN

                sql_stmt:= 'ALTER TABLE ActionItemPropDCXRef DROP COLUMN DomainCatalogId CASCADE CONSTRAINTS';
                
                EXECUTE IMMEDIATE sql_stmt;
            END IF;
                        
            sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (CreatedUser INVISIBLE,
                                                                    CreatedDate INVISIBLE,
                                                                    LastModByUserId INVISIBLE,
                                                                    LastModDateTime INVISIBLE)';
                                                                        
            EXECUTE IMMEDIATE sql_stmt;
            
                        
            sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (LastModByUserId VISIBLE,
                                                                LastModDateTime VISIBLE)';
            
            EXECUTE IMMEDIATE sql_stmt;
            
            
            sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (CreatedUser VISIBLE,
                                                                    CreatedDate VISIBLE
                                                                    )';
            
            EXECUTE IMMEDIATE sql_stmt;
                    
            -- Modify Defaults on change tracking columns                                              
            sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''), 
                                                                    CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                                    LastModDateTime TIMESTAMP DEFAULT SYSDATE,
                                                                    CreatedDate TIMESTAMP DEFAULT SYSDATE)';
                                                                        
            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'CREATE OR REPLACE TRIGGER tu_ActionItemPropDCXRef
                        BEFORE UPDATE ON ActionItemPropDCXRef
                        FOR EACH ROW
                        BEGIN
                            :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                            :new.LastModDateTime := SYSDATE;
                        END;';
                        
            EXECUTE IMMEDIATE sql_stmt; 

        /*********************************************************************************************
                                        DELETE OBSELETE TABLES 
        *********************************************************************************************/

            -- Save data from and Delete ListDomain, DomainCatalog, DomainCatalogColXRef
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'Temp_ListDomain';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE Temp_ListDomain AS SELECT * FROM ListDomain';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'DROP TABLE ListDomain CASCADE CONSTRAINTS';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'Temp_DomainCatalog';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE Temp_DomainCatalog AS SELECT * FROM DomainCatalog';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'DROP TABLE DomainCatalog CASCADE CONSTRAINTS';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'Temp_DomainCatalogColXRef';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE Temp_DomainCatalogColXRef AS SELECT * FROM DomainCatalogColXRef';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'DROP TABLE DomainCatalogColXRef CASCADE CONSTRAINTS';
                EXECUTE IMMEDIATE sql_stmt;    
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'NewDomainTableList';

            IF CNT <> 0 THEN
                sql_stmt := 'DROP TABLE NewDomainTableList CASCADE CONSTRAINTS';
                EXECUTE IMMEDIATE sql_stmt;  
            END IF;

        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 5,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;

EXCEPTION
    WHEN Too_Many_DomainId_1 THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ERROR**: More then 1 distinct DomainCatalogId was found in the '
        || 'ListDomain table for column ''' || ColName || ''' of table ''' 
        || TabName || '''. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is ' ||
        ' required for the script to continue.');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'The query below shows all ' ||
        'the ListDomain table entries for the table-column combination mentioned.');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || CHR(10) || 'QUERY: SELECT Id, DomainCatalogId, Code, Descr'
        || CHR(10) || CHR(9) || 'FROM ListDomain');
        DBMS_OUTPUT.PUT_LINE(CHR(9) || 'WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ');');
        
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SOLUTION: An entry was found in the DomainCatalogColXRef table. ' ||
        'Replace the values in the column ''' || ColName || ''' of table ''' || TabName || ' with Ids from ' 
        || ' from the ListDomain table that have the appropriate Code, Descr, and DomainCatalogId of '
        || DomainId );

    WHEN Too_Many_DomainId_2 THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ERROR**: More than 1 distinct DomainCatalogId was found '
        || ' in the ListDomain table for column ''' || ColName || ''' of table ''' || TabName || '''.'
        || 'ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
        || ' The query below shows all the ListDomain table entries for the table-column combination mentioned');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'QUERY: SELECT Id, DomainCatalogId, Code, Descr'
        || CHR(10) || CHR(9) || 'FROM ListDomain');
        DBMS_OUTPUT.PUT_LINE(CHR(9) || 'WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ');');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SOLUTION: A reference could not be found in the DomainCatalogColXRef table for '
        || 'column ''' || ColName || ''' of table ''' || TabName || '''. Talk to the BA assigned to the client '
        || 'for this database. You may need to set some values in the ' || ColName || ''' column of the ''' 
        || TabName || ''' table to NULL');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
        DBMS_OUTPUT.PUT_LINE(sql_stmt);
END;
/


-- ChangeOrientaionFieldTypeToAddDeciamalPrecisionsForDigImport.sql
DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640208 AND dbVersionCheckPoint = 5
    THEN
        -- ChangeOrientaionFieldTypeToAddDeciamalPrecisionsForDigImport.sql
        sql_stmt := 'ALTER TABLE MetalLoss MODIFY MetalLossOrientation NUMERIC(6,3)';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'ALTER TABLE MechanicalDamage MODIFY MechDmgOrientation NUMERIC(6,3)';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'ALTER TABLE ExcavationSiteCrackAnomaly MODIFY ESCAOrientation NUMERIC(6,3)';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'ALTER TABLE PipeSoilPotentialPipe MODIFY PSPPipeOrientation NUMERIC(6,3)';
        EXECUTE IMMEDIATE sql_stmt;

        UPDATE VersionInfo SET DBVersionCheckPoint = 6,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';

        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
    DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640208 AND dbVersionCheckPoint = 6
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 01
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650001', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 01';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650001 AND dbVersionCheckPoint = 0
    THEN


        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650001 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 02
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650002', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 02';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

-- POC_Rename_HCAType_Descr_Column.sql AND Rename the RCHCAReasonType.Description column to Descr. 
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650002 AND dbVersionCheckPoint = 0
    THEN
        -- POC_Rename_HCAType_Descr_Column.sql
        -- Rename the RCHCAReasonType.Description column to Descr.
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'RCHCAReasonType'
        AND column_name = 'Descr';

        IF CNT = 0 THEN
            SELECT COUNT(*) INTO CNT
            FROM user_tab_columns
            WHERE table_name = 'RCHCAReasonType'
            AND column_name = 'Description';

            IF CNT <> 0 THEN
                sql_stmt := 'ALTER TABLE RCHCAReasonType RENAME COLUMN Description TO Descr';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;
        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650002 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 03
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650003', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 03';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

-- Rename CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650003 AND dbVersionCheckPoint = 0
    THEN
        /*
            This script adds the CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
            to tables that are missing the columns and makes sure the column names and datatypes is uniform
            across all tables
        */
        DECLARE
            CNT INT;
            sql_stmt VARCHAR2(20000);

            -- Cursor to find and rename row-tracking columns that need to be renamed
            CURSOR RenameCol_Cursor IS
            SELECT table_name, 
                column_name AS OldColumnName,
                CASE
                    WHEN column_name LIKE 'Create%User%' THEN 'CreatedUser'
                    WHEN column_name LIKE 'Create%Date%' THEN 'CreatedDate'
                    WHEN column_name LIKE 'LastMod%Date%' THEN 'LastModDateTime'
                    WHEN column_name LIKE 'LastMod%User%' THEN 'LastModByUserId'
                END AS NewColumnName
            FROM user_tab_columns
            WHERE REGEXP_LIKE (column_name, '^LastMod.*|^Create%Date|^Create.*User')  
            AND column_name NOT IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')
            AND table_name NOT IN (SELECT view_name FROM user_views);

            -- Cursor to add row-tracking columns to any table that is missing it
            CURSOR AddCol_Cursor IS
            SELECT table_name, 'CreatedDate TIMESTAMP DEFAULT SYSDATE' AS MissingColumn
            FROM user_tables 
            WHERE table_name NOT IN (SELECT table_name 
                                    FROM user_tab_columns
                                    WHERE column_name LIKE 'Create%Date%')
            AND table_name NOT IN (SELECT view_name FROM user_views)
            UNION
            SELECT table_name, 'CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')' AS MisingColumn
            FROM user_tables 
            WHERE table_name NOT IN (SELECT table_name 
                                    FROM user_tab_columns
                                    WHERE column_name LIKE 'Create%User%')
            AND table_name NOT IN (SELECT view_name FROM user_views)
            UNION
            SELECT table_name, 'LastModDateTime TIMESTAMP DEFAULT SYSDATE' AS MisingColumn
            FROM user_tables 
            WHERE table_name NOT IN (SELECT table_name 
                                    FROM user_tab_columns
                                    WHERE column_name LIKE 'LastMod%Date%')
            AND table_name NOT IN (SELECT view_name FROM user_views)
            UNION
            SELECT table_name, 'LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')' AS MisingColumn
            FROM user_tables 
            WHERE table_name NOT IN (SELECT table_name 
                                FROM user_tab_columns
                                WHERE column_name LIKE 'LastMod%User%')
            AND table_name NOT IN (SELECT view_name FROM user_views);

            --Make column datatype consistent for all row-tracking columns
            CURSOR ColumnType_Cursor IS
            SELECT table_name, 
                column_name, 
                    CASE
                    WHEN column_name LIKE 'Create%User%' OR column_name LIKE 'LastMod%User%' OR column_name LIKE 'LastUpgrade%User%'
                        THEN 'VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')'
                    WHEN column_name LIKE 'Create%Date%' OR column_name LIKE 'LastMod%Date%' OR column_name LIKE 'LastUpgrade%Time%'
                        THEN 'TIMESTAMP DEFAULT SYSDATE'
                END AS NewColumnType
            FROM user_tab_columns
            WHERE REGEXP_LIKE (column_name, '^LastMod.*|^Create.*User|^Create.*Date|^LastUpgrade.*') AND
            data_type NOT IN ('TIMESTAMP(6)', 'VARCHAR2', 'NVARCHAR2')
            AND table_name NOT IN (SELECT view_name FROM user_views)
            AND table_name NOT IN ('Temp_Table');

            -- Cursor to update trigger defintions for all triggers that include the modified row-tracking column
            CURSOR ModifyTrigger_Cursor IS
            SELECT trigger_name, table_name
            FROM user_triggers
            WHERE trigger_name LIKE 'TU_%';
                                
        BEGIN

            -- Rename columns to CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
            FOR i IN RenameCol_Cursor LOOP

                sql_stmt := 'ALTER TABLE ' || i.table_name || ' RENAME COLUMN '|| i.OldColumnName || ' TO ' || i.NewColumnName;
                EXECUTE IMMEDIATE sql_stmt;

            END LOOP;

            -- Add missing CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
            FOR i IN AddCol_Cursor LOOP

                sql_stmt := 'ALTER TABLE "'|| i.table_name || '" ADD ' || i.MissingColumn;

                EXECUTE IMMEDIATE sql_stmt;

            END LOOP;

            -- Modify column datatype for consistency across all row-tracking columns
            FOR i IN ColumnType_Cursor LOOP

                sql_stmt:= 'ALTER TABLE "' || i.table_name || '" MODIFY ' || i.column_name || ' ' || i.NewColumnType;
                
                EXECUTE IMMEDIATE sql_stmt;

            END LOOP;

            -- Modify trigger definitions
            FOR i IN ModifyTrigger_Cursor LOOP

                sql_stmt := 'CREATE OR REPLACE TRIGGER ' || i.trigger_name || CHR(10) ||
                    'BEFORE UPDATE ON ' || i.table_name || CHR(10) ||
                    'FOR EACH ROW
                    BEGIN
                        :NEW.LastModByUserId := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                        :NEW.LastModDateTime := SYSDATE;
                    END;' ;

                EXECUTE IMMEDIATE sql_stmt;

            END LOOP;
        END;


        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
       
END;
/

--5_Modify_View_Definitions_ORACLE.sql
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650003 AND dbVersionCheckPoint = 1
    THEN

        DECLARE
            CNT INT;
            sql_stmt VARCHAR(20000);
        BEGIN

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'SQLClauseTab';

            IF CNT <> 0 THEN
                sql_stmt := 'DROP TABLE SQLClauseTab';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            sql_stmt := 'CREATE TABLE SQLClauseTab (ClauseIndex INT,
                                                    Type VARCHAR2(20),
                                                    TableName VARCHAR(100),
                                                    TableAlias VARCHAR(100),
                                                    ColumnName VARCHAR(100),
                                                    NewLDTableName VARCHAR(100))';

            EXECUTE IMMEDIATE sql_stmt;

        END;

        /*
            This script modifies the definition of views referencing the ListDomain table, which
            no longer exists.
        */
        DECLARE
            sql_stmt VARCHAR2(20000);
            CNT INT;
            ObjectDefinition VARCHAR2(20000);
            V_ViewName VARCHAR2(100);
            StrLength INT;
            ClauseStartIndex INT;
            StartIndex INT;
            EndIndex INT;
            IsWhereClause INT;
            V_TableAlias VARCHAR2(100);
            V_TableName VARCHAR2(100);
            V_ColumnName VARCHAR2(100);
            ExemptTableList VARCHAR2(10000);

            CURSOR ViewList_Cursor IS
            SELECT view_name, text_length, text as Definition
            FROM user_views;

        BEGIN

            FOR i IN ViewList_Cursor LOOP

                ObjectDefinition := i.definition;
                V_ViewName := i.view_name;
                StrLength := i.text_length;

                ExemptTableList := '''ListDomain''';

                sql_stmt := 'DELETE FROM SQLClauseTab';

                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;

                CNT := INSTR(ObjectDefinition, 'ListDomain');

                IF CNT = 0
                THEN
                    CONTINUE;
                END IF;

        ---------------------- REMOVE extra spacing in view definitions ---------------------------

                StartIndex := INSTR(ObjectDefinition, '  ', 1);

                FOR i IN 1..StrLength LOOP
                    StartIndex := INSTR(ObjectDefinition, '  ', StartIndex);
                    ObjectDefinition := REPLACE(ObjectDefinition, '  ', ' ');

                    EXIT WHEN StartIndex = 0;
                END LOOP;

        --------------------------- Find Table and Table Alias in FROM Clause ----------------

                StartIndex := 1;

                FOR i IN 1..StrLength LOOP

                    ClauseStartIndex := INSTR(ObjectDefinition, 'FROM', startIndex);
                    StartIndex := INSTR(ObjectDefinition, ' ', ClauseStartIndex) + 1;

                    EXIT WHEN ClauseStartIndex = 0;

                    EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);

                    V_TableName := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
                    V_TableName := REPLACE(REPLACE(V_TableName, CHR(10), ''), '"', '');

                    StartIndex := INSTR(ObjectDefinition, ' ', EndIndex) + 1;

                    CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

                    IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
                    THEN
                        EndIndex := CNT;
                    ELSE
                        EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
                    END IF;

                    V_TableAlias := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
                    V_TableAlias := REPLACE(REPLACE(V_TableAlias, CHR(10), ''), '"', '');

                    sql_stmt := 'INSERT INTO SQLClauseTab
                                VALUES (' || ClauseStartIndex || ',
                                    ''FROM'',
                                    ''' || V_TableName || ''',
                                        ''' || V_TableAlias || ''',
                                        NULL,
                                        NULL)';

                    EXECUTE IMMEDIATE sql_stmt;

                    IF (REGEXP_INSTR(ObjectDefinition, 'With |WHERE' || V_TableName) <> 0)
                        AND (INSTR(ExemptTableList, V_TableName) = 0)
                    THEN
                        ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
                    END IF;

                    StartIndex := StartIndex + 1;

                END LOOP;

                COMMIT;

        -------------------------------------- Find all Join Clauses -----------------------------

                StartIndex := 1;

                FOR i IN 1..StrLength LOOP

                    ClauseStartIndex := INSTR(ObjectDefinition, 'JOIN ', StartIndex);

                    StartIndex := ClauseStartIndex;

                    EXIT WHEN StartIndex = 0;

                    StartIndex := INSTR(ObjectDefinition, ' ', StartIndex) + 1;

                    EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);

                    V_TableName := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
                    V_TableName := REPLACE(REPLACE(V_TableName, CHR(10), ''), '"', '');

                    StartIndex := INSTR(ObjectDefinition, ' ', EndIndex) + 1;

                    CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

                    IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
                    THEN
                        EndIndex := CNT;
                    ELSE
                        EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
                    END IF;

                    V_TableAlias := REPLACE(SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex), '"', '');
                    V_TableAlias := REPLACE(REPLACE(V_TableAlias, CHR(10), ''), '"', '');

                    sql_stmt := 'INSERT INTO SQLClauseTab
                                VALUES (' || ClauseStartIndex || ',
                                        ''JOIN'',
                                        ''' || V_TableName || ''',
                                        ''' || V_TableAlias || ''',
                                        NULL,
                                        NULL)';

                    EXECUTE IMMEDIATE sql_stmt;

                    IF (REGEXP_INSTR(ObjectDefinition, 'With ' || V_TableName) <> 0)
                        AND (INSTR(ExemptTableList, V_TableName) = 0)
                    THEN
                        ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
                    END IF;

                    StartIndex := StartIndex  + 1;

                END LOOP;

                COMMIT;

        ----------------------- Find all table-qualified columns in JOIN predicate ---------------
    
  
                DECLARE
                    
                    TYPE NEWTABLE_TYPE IS TABLE OF VARCHAR2(50)
                                    INDEX BY BINARY_INTEGER;
                                    
                    ColumnList_Table  NEWTABLE_TYPE;

                BEGIN

                    sql_stmt := 'SELECT DISTINCT TableAlias 
                    FROM SQLClauseTab 
                    WHERE TableAlias IS NOT NULL AND TableAlias <> '' ''';

                    EXECUTE IMMEDIATE sql_stmt BULK COLLECT INTO ColumnList_Table;

                    FOR i IN 1..ColumnList_Table.COUNT LOOP

                        sql_stmt := 'SELECT MIN(ClauseIndex)
                        FROM SQLClauseTab
                        WHERE Type = ''JOIN''';

                        EXECUTE IMMEDIATE sql_stmt INTO StartIndex;

                        V_TableAlias := ColumnList_Table(i);

                        FOR i IN 1..StrLength LOOP

                            IsWhereClause := 0;

                            StartIndex := INSTR(ObjectDefinition, V_TableAlias || '.', StartIndex);

                            EXIT WHEN StartIndex = 0;

                            sql_stmt := 'SELECT MAX(ClauseIndex)
                            FROM SQLClauseTab
                            WHERE ClauseIndex < '|| StartIndex ||'
                            AND Type = ''JOIN''';

                            EXECUTE IMMEDIATE sql_stmt INTO ClauseStartIndex;

                            -- Check if there is a WHERE clause nearby to prevent WHERE clause predicate from being counted as part of JOIN predicate
                            IF (INSTR(ObjectDefinition, 'WHERE', StartIndex) - StartIndex) <= 3 THEN
                                IsWhereClause := 1;
                            END IF;

                            StartIndex := INSTR(ObjectDefinition, '.', StartIndex) + 1;

                            CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

                            IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
                            THEN
                                EndIndex := CNT;
                            ELSE
                                EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
                            END IF;

                            sql_stmt := 'SELECT TableName
                            FROM SQLClauseTab
                            WHERE TableAlias = ''' || V_TableAlias || '''
                            AND TableName IS NOT NULL
                            AND rownum < 2';

                            EXECUTE IMMEDIATE sql_stmt INTO V_TableName;

                            V_ColumnName := REPLACE(SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex), ')', '');
                            V_ColumnName := REPLACE(REPLACE(V_ColumnName, CHR(10), ''), '"', '');

                            sql_stmt := 'INSERT INTO SQLClauseTab
                                        VALUES (' || CASE 
                                                        WHEN IsWhereClause = 0 THEN ClauseStartIndex 
                                                        ELSE INSTR(ObjectDefinition, 'WHERE', StartIndex) 
                                                     END || ',
                                                 '''|| CASE 
                                                        WHEN IsWhereClause = 0 THEN 'JOIN CONDITION'
                                                        ELSE 'WHERE'
                                                    END ||''',
                                                ''' || V_TableName || ''',
                                                ''' || V_TableAlias || ''',
                                                ''' || V_ColumnName || ''',
                                                NULL)';

                            EXECUTE IMMEDIATE sql_stmt;

                            IF (REGEXP_INSTR(ObjectDefinition, 'With ' || V_TableName) <> 0)
                                AND (INSTR(ExemptTableList, V_TableName) = 0)
                            THEN
                                ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
                            END IF;

                            StartIndex := StartIndex + 1;

                        END LOOP;

                    END LOOP;

                    COMMIT;
                END;

        --------------- Match ListDomain references in View Definition to new ListDomain table name ------------------------

                SELECT COUNT(*) INTO CNT
                FROM user_tables
                WHERE table_name = 'tmpTable';

                IF CNT <> 0
                THEN
                    EXECUTE IMMEDIATE 'DROP TABLE tmpTable';
                END IF;

                sql_stmt := '
                UPDATE SQLClauseTab SC
                SET NewLDTableName = (SELECT DISTINCT tmp.ListDomainTableName
                FROM SQLClauseTab SCT
                JOIN TempListDomainTable tmp
                ON tmp.ReferencedColumnName = SCT.ColumnName
                AND tmp.ReferencedTableName = SCT.TableName
                WHERE SCT.ClauseIndex IN (SELECT ClauseIndex FROM SQLClauseTab
                                    WHERE TableName = ''ListDomain'')
                AND SCT.ColumnName IS NOT NULL
                AND SC.ClauseIndex = SCT.ClauseIndex
                AND SC.TableName = ''ListDomain'')';

                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;

        ----------------------- Store views that contain missing tables in a tmp table --------------------

                SELECT COUNT(*) INTO CNT
                FROM user_tables
                WHERE table_name = 'tmp_InvalidViews';

                IF CNT = 0
                THEN
                    sql_stmt := 'CREATE TABLE tmp_InvalidViews (ViewName VARCHAR2(100),
                                                                Definition LONG,
                                                                DropCommand VARCHAR2(100))';

                    EXECUTE IMMEDIATE sql_stmt;
                END IF;

                sql_stmt := 'SELECT COUNT(DISTINCT(TableName)) FROM SQLClauseTab
                            WHERE TableName NOT IN (' || ExemptTableList || ')
                            AND TableName NOT IN (SELECT table_name FROM user_tables)';


                EXECUTE IMMEDIATE sql_stmt INTO CNT;

                IF CNT <> 0
                THEN
                    sql_stmt := 'SELECT COUNT(*)
                    FROM tmp_InvalidViews
                    WHERE ViewName = '''|| V_ViewName || '''';

                    EXECUTE IMMEDIATE sql_stmt INTO CNT;

                    IF CNT = 0
                    THEN
                        sql_stmt := 'INSERT INTO tmp_InvalidViews
                                    VALUES (''' || V_ViewName || ''',
                                        ''SELECT text FROM user_views WHERE view_name = '''''|| V_ViewName || ''''''',
                                        ''DROP VIEW '|| V_ViewName ||''')';

                        EXECUTE IMMEDIATE sql_stmt;

                        COMMIT;
                    END IF;
                END IF;

        /*********************************************************************************************************
        		                            Modify View Definiion
        **********************************************************************************************************/

        ----------------------------------- Modify View Definition ----------------------------

                DECLARE
                    TableAlias VARCHAR2(100);
                    TableName VARCHAR2(100);
                    NewLDTableName VARCHAR2(100);

                    TYPE RECORD_TYPE IS RECORD
                    (ClauseIndex INT,
                     TableName VARCHAR2(100),
                     TableAlias VARCHAR2(50),
                     NewLDTableName VARCHAR2(100)
                    );

                    TYPE TABLE_VARIABLE IS TABLE OF RECORD_TYPE;

                    T_SearchNReplace TABLE_VARIABLE;

                BEGIN
                    -- Initialize table varaible to modify view definitions
                    sql_stmt := '
                    SELECT DISTINCT ClauseIndex, TableName, TableAlias, NewLDTableName
                    FROM SQLClauseTab
                    WHERE ClauseIndex IN (SELECT ClauseIndex
                                        FROM SQLClauseTab
                                        WHERE TableName = ''ListDomain'')
                    AND TableName = ''ListDomain''
                    AND NewLDTableName IS NOT NULL';

                    EXECUTE IMMEDIATE sql_stmt BULK COLLECT INTO T_SearchNReplace;

                    -- Loop through and modify view definitions (replace ListDomain table name with new LD table name)
                    FOR i IN 1..T_SearchNReplace.COUNT LOOP

                        TableName := T_SearchNReplace(i).TableName;
                        TableAlias := T_SearchNReplace(i).TableAlias;
                        NewLDTableName := T_SearchNReplace(i).NewLDTableName;

                        ObjectDefinition := REGEXP_REPLACE( ObjectDefinition,
                                                    TableName || ' '|| TableAlias ||'\s',
                                                    NewLDTableName || ' ' ||TableAlias ||' ');
                    END LOOP;
                END;

        -------------------------------------- Recreate View -------------------------------------------

                sql_stmt := 'SELECT COUNT(*)
                FROM tmp_InvalidViews
                WHERE ViewName = ''' || V_ViewName ||'''';

                EXECUTE IMMEDIATE sql_stmt INTO CNT;

                IF CNT = 0
                THEN
                    ObjectDefinition := 'CREATE OR REPLACE VIEW ' || V_ViewName || ' AS ' || ObjectDefinition;
                    --DBMS_OUTPUT.PUT_LINE(ObjectDefinition);
                    EXECUTE IMMEDIATE ObjectDefinition;
                END IF;


            END LOOP;

        -------------------------------------- DROP Tables Created by Script --------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'SQLClauseTab';

            IF CNT <> 0
            THEN
                sql_stmt := 'DROP TABLE SQLClauseTab';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'tmp_InvalidViews';

            IF CNT <> 0 THEN 
                sql_stmt := 'SELECT COUNT(*) FROM tmp_InvalidViews';
                EXECUTE IMMEDIATE sql_stmt INTO CNT;
             
                IF CNT = 0 
                THEN 
                    sql_stmt := 'DROP TABLE tmp_InvalidViews';
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
            END IF;

        END;
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 2,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650003 AND dbVersionCheckPoint = 2
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 04
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650004', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 04';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


-- Drop ListDomain table and create Temp_ListDomain table
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650004 AND dbVersionCheckPoint = 0
    THEN
        -- Save data from and Delete ListDomain, DomainCatalog, DomainCatalogColXRef
        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_ListDomain';

        IF CNT = 0 THEN
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'ListDomain';

            IF CNT <> 0 THEN
                sql_stmt := 'CREATE TABLE Temp_ListDomain AS SELECT * FROM ListDomain';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'DROP TABLE ListDomain CASCADE CONSTRAINTS';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650004 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 05
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650005', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 05';


        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


--Modify EarthQuakeArea table definition
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650005 AND dbVersionCheckPoint = 0
    THEN
        sql_stmt := 'ALTER TABLE EarthQuakeArea MODIFY EarthQuakeAreaMin NUMBER(12,2)';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'ALTER TABLE EarthQuakeArea MODIFY EarthQuakeAreaMax NUMBER(12,2)';
        EXECUTE IMMEDIATE sql_stmt;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650005 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 06
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650006', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 06';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


-- 50033_CreateILIComments_StageDBScript.sql
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650006 AND dbVersionCheckPoint = 0
    THEN
        -- 50033_CreateILIComments_StageDBScript.sql
        /*******************************************
        * For Backlog Item 50033: Creating Inline Inspection Comments Column in Inline Inspection Table
        *
        * This stage DB script will be adding a new column for adding comments to the InlineInspection table.
        *******************************************/

        -- Check if the column exists in the table before we add it.
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'InlineInspection'
        AND column_name = 'ILIComments';

        IF CNT <> 0 THEN
            sql_stmt := 'ALTER TABLE InlineInspection MODIFY ILIComments VARCHAR2(500)';
            EXECUTE IMMEDIATE sql_stmt;
        ELSE
            sql_stmt := 'ALTER TABLE InlineInspection ADD ILIComments VARCHAR2(500)';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650006 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 07
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650007', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 07';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


-- Modify HCAVw View
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650007 AND dbVersionCheckPoint = 0
    THEN

        sql_stmt := 'CREATE OR REPLACE VIEW HCAVw AS
			  SELECT LL.Id AS LineLoopId,
			  LL.LineName,
			  S1.MLVSectionName                                                           AS StartMLVSectionName,
			  S2.MLVSectionName                                                           AS EndMLVSectionName,
			  CAST(TT.BeginStationNum * C1.MultiplierNum + C1.FactorNum AS NUMERIC(13,3)) AS StartDisplayChainage,
			  CAST (TT.EndStationNum  * C2.MultiplierNum + C2.FactorNum AS NUMERIC(13,3)) AS EndDisplayChainage,
			  TT.BeginStationSeriesId,
			  TT.BeginStationNum,
			  TT.EndStationSeriesId,
			  TT.EndStationNum,
			  R.RCHCAReasonTypeId AS HCATypeDomainID,
			  RT.Descr      AS HCAType,
			  TT.HCAName,
			  TT.HCAConfirmDate,
			  TT1.RCHCACALCSEGPIR AS HCAImpactDistance,
			  TT.HCAComment
			FROM HCACFR TT
			JOIN HCACFRSeg TT1 ON TT.BeginStationSeriesId = TT1.BeginStationSeriesId AND TT.EndStationSeriesId  = TT1.EndStationSeriesId AND ((TT.BeginStationNum BETWEEN TT1.BeginStationNum AND TT1.EndStationNum) OR (TT.BeginStationNum BETWEEN TT1.EndStationNum AND TT1.BeginStationNum))
			JOIN HCAReasons R ON R.HCACFRSEGID        = TT1.ID AND R.RCHCAReasonTypeId > 0 
			JOIN RCHCAREASONTYPE RT ON R.RCHCAREASONTYPEID = RT.ID
			JOIN (SELECT StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum,
				MIN(FactorNum)     AS FactorNum,
				MIN(MultiplierNum) AS MultiplierNum,
				MIN(MLVSectionId)  AS MLVSectionId
			  FROM StationSeries ss
			  INNER JOIN MLVCorrection mlv
			  ON mlv.StationSeriesId = ss.Id
			  GROUP BY StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum) C1 ON TT.BeginStationSeriesId = C1.StationSeriesId AND ((TT.BeginStationNum BETWEEN C1.BeginStationNum AND C1.EndStationNum) OR (TT.BeginStationNum BETWEEN C1.EndStationNum AND C1.BeginStationNum))
			JOIN (SELECT StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum,
				MIN(FactorNum)     AS FactorNum,
				MIN(MultiplierNum) AS MultiplierNum,
				MIN(MLVSectionId)  AS MLVSectionId
			  FROM StationSeries ss
			  INNER JOIN MLVCorrection mlv
			  ON mlv.StationSeriesId = ss.Id
			  GROUP BY StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum) C2 ON TT.EndStationSeriesId = C2.StationSeriesId AND ((TT.EndStationNum BETWEEN C2.BeginStationNum AND C2.EndStationNum) OR (TT.EndStationNum BETWEEN C2.EndStationNum AND C2.BeginStationNum))
			JOIN MLVSection S1  ON C1.MLVSectionId = S1.Id
			JOIN MLVSection S2 ON C2.MLVSectionId = S2.Id
			JOIN StationSeries SS ON TT.BeginStationSeriesId = SS.Id
			JOIN LineLoop LL ON SS.LineLoopId           = LL.ID
			WHERE TT.EffectiveEndDate IS NULL';

        EXECUTE IMMEDIATE sql_stmt;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


--AddingMissingColumnsToLoadTables.sql
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650007 AND dbVersionCheckPoint = 1
    THEN

        DECLARE 
            sql_stmt VARCHAR2(20000);

            CURSOR AddColumn_Cursor IS
            SELECT 'ALTER TABLE LOAD_' || table_name || ' ADD ' || column_name || ' ' || data_type || 
            CASE
                WHEN REGEXP_LIKE (data_type, 'VARCHAR|CHAR') THEN '(' || data_length || ')'
                WHEN column_name = 'CheckSumValue' THEN '(' || 10 || ')'
                WHEN data_type LIKE '%NUMBER%' THEN '(' || data_precision || ',' || data_scale || ')'
            END AS AddColumn
            FROM user_tab_columns tab1
            WHERE table_name IN (SELECT REPLACE(table_name, 'Load_', '') 
                                FROM user_tables 
                                WHERE table_name LIKE 'Load_%')
            AND column_name NOT IN (SELECT column_name 
                                    FROM user_tab_columns
                                    WHERE table_name = 'Load_' || tab1.table_name);
        BEGIN

            FOR i IN AddColumn_Cursor LOOP
                EXECUTE IMMEDIATE i.AddColumn;
            END LOOP;
        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 2,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650007 AND dbVersionCheckPoint = 2
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 08
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650008', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 08';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650008 AND dbVersionCheckPoint = 0
    THEN
        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'StageFKeysInfo';

        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE StageFKeysInfo
                        (fk_name NVARCHAR2(128) NOT NULL,
                         TableName NVARCHAR2(128) NOT NULL,
                         ColumnName NVARCHAR2(128) NULL,
                         ReferencedTable NVARCHAR2(128) NOT NULL,
					     ReferencedColumn NVARCHAR2(128) NULL            
                        )';
            
            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/


DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650008 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 09
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650009', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 09';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(32000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650009 AND dbVersionCheckPoint = 0
    THEN

        sql_stmt := 'CREATE OR REPLACE PROCEDURE sp_Dx6ConfigV5
                    AS
                        CNT INT;
                        sql_stmt VARCHAR2(20000);
                    BEGIN
                        SELECT COUNT(*) INTO CNT
                        FROM user_tables 
                        WHERE table_name = ''temp_Fabrication'';

                        IF CNT <> 0 THEN
                            sql_stmt := ''DROP TABLE temp_Fabrication PURGE'';
                            EXECUTE IMMEDIATE sql_stmt;
                        END IF;

                        sql_stmt := ''CREATE TABLE temp_Fabrication
                                (
                                    Id                               NUMBER(18, 0) NULL,
                                    EffectiveStartDate               TIMESTAMP NULL,
                                    EffectiveEndDate                 TIMESTAMP NULL,
                                    FabricationTypeDomainId          NUMBER(7, 0) NULL,
                                    FabricationTypeDomainCode        VARCHAR2(40) NULL,
                                    FabricationTypeDomainDesc        VARCHAR2(255) NULL,
                                    FabricationOutsideDiameter       NUMBER(8, 4) NULL,
                                    FabricationName                  VARCHAR2(100) NULL,
                                    FabricationComment               VARCHAR2(255) NULL,
                                    StationSeriesId                  NUMBER(10, 0) NULL,
                                    StationNum                       NUMBER(10, 3) NULL,
                                    FabricationManufacturingTypeLd   NUMBER(7, 0) NULL,
                                    FabricationManufacturingTypeCode VARCHAR2(40) NULL,
                                    FabricationManufacturingTypeDesc VARCHAR2(255) NULL,
                                    FabricationOutletGrade           NUMBER(5, 0) NULL,
                                    FabricationOutletWallthickness   NUMBER(9, 5) NULL,
                                    FabricationInletDiameter         NUMBER(5, 3) NULL,
                                    FabricationInletGrade            NUMBER(5, 0) NULL,
                                    FabricationInletWallThickness    NUMBER(9, 5) NULL,
                                    FabricationPressureRating        NUMBER(5, 0) NULL,
                                    FabricationOutletDiameter        NUMBER(5, 3) NULL,
                                    FabricationConnectDomainID       NUMBER(7, 0) NULL,
                                    FabricationConnectCode           VARCHAR2(40) NULL,
                                    FabricationConnectDesc           VARCHAR2(255) NULL
                                )'';
                                
                        EXECUTE IMMEDIATE sql_stmt;

                        sql_stmt := ''INSERT INTO temp_Fabrication
                            (Id,
                                EffectiveStartDate,
                                EffectiveEndDate,
                                FabricationTypeDomainCode,
                                FabricationTypeDomainDesc,
                                FabricationOutsideDiameter,
                                FabricationName,
                                FabricationComment,
                                StationSeriesId,
                                StationNum,
                                FabricationManufacturingTypeCode,
                                FabricationManufacturingTypeDesc,
                                FabricationOutletGrade,
                                FabricationOutletWallthickness,
                                FabricationInletDiameter,
                                FabricationInletGrade,
                                FabricationInletWallThickness,
                                FabricationPressureRating,
                                FabricationOutletDiameter,
                                FabricationConnectCode,
                                FabricationConnectDesc)
                        SELECT Row_number( )
                            OVER (
                            ORDER BY BeginStationSeriesId, BeginStationNum) AS Id,
                        EffectiveStartDate,
                        EffectiveEndDate,
                        ElbowTypeCode,
                        ElbowTypeDescr,
                        ElbowOutsideDiameter,
                        ElbowName,
                        ElbowComment,
                        BeginStationSeriesId,
                        BeginStationNum,
                        ElbowManufacturingTypeCode,
                        ElbowManufacturingTypeDescr,
                        ElbowOutletGrade,
                        ElbowOutletWallthickness,
                        ElbowInletDiameter,
                        ElbowInletGrade,
                        ElbowInletWallThickness,
                        ElbowPressureRating,
                        ElbowOutletDiameter,
                        ElbowConnectCode,
                        ElbowConnectDescr
                        FROM   ( SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS ElbowTypeCode,
                                t.Descr AS ElbowTypeDescr,
                                ElbowOutsideDiameter,
                                ElbowName,
                                ElbowComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS ElbowManufacturingTypeCode,
                                m.Descr AS ElbowManufacturingTypeDescr,
                                ElbowOutletGrade,
                                ElbowOutletWallthickness,
                                ElbowInletDiameter,
                                ElbowInletGrade,
                                ElbowInletWallThickness,
                                ElbowPressureRating,
                                ElbowOutletDiameter,
                                c.Code  AS ElbowConnectCode,
                                c.Descr AS ElbowConnectDescr
                            FROM   Elbow f
                                LEFT JOIN LD_ElbowConnect c
                                        ON f.ElbowConnectDomainId = c.Id
                                LEFT JOIN LD_ElbowManufacturingType m
                                        ON f.ElbowManufacturingTypeLd = m.Id
                                LEFT JOIN LD_ElbowType t
                                        ON f.ElbowTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS ExtrusionTypeCode,
                                t.Descr AS ExtrusionTypeDescr,
                                ExtrusionOutsideDiameter,
                                ExtrusionName,
                                ExtrusionComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS ExtrusionManufacturingTypeCode,
                                m.Descr AS ExtrusionManufacturingTypeDescr,
                                ExtrusionOutletGrade,
                                ExtrusionOutletWallthickness,
                                ExtrusionInletDiameter,
                                ExtrusionInletGrade,
                                ExtrusionInletWallThickness,
                                ExtrusionPressureRating,
                                ExtrusionOutletDiameter,
                                c.Code  AS ExtrusionConnectCode,
                                c.Descr AS ExtrusionConnectDescr
                            FROM   Extrusion f
                                LEFT JOIN LD_ExtrusionConnect c
                                        ON f.ExtrusionConnectDomainId = c.Id
                                LEFT JOIN LD_ExtrusionManufacturingType m
                                        ON f.ExtrusionManufacturingTypeLd = m.Id
                                LEFT JOIN LD_ExtrusionType t
                                        ON f.ExtrusionTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS FlangeTypeCode,
                                t.Descr AS FlangeTypeDescr,
                                FlangeOutsideDiameter,
                                FlangeName,
                                FlangeComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS FlangeManufacturingTypeCode,
                                m.Descr AS FlangeManufacturingTypeDescr,
                                FlangeOutletGrade,
                                FlangeOutletWallthickness,
                                FlangeInletDiameter,
                                FlangeInletGrade,
                                FlangeInletWallThickness,
                                FlangePressureRating,
                                FlangeOutletDiameter,
                                c.Code  AS FlangeConnectCode,
                                c.Descr AS FlangeConnectDescr
                            FROM   Flange f
                                LEFT JOIN LD_FlangeConnect c
                                        ON f.FlangeConnectDomainId = c.Id
                                LEFT JOIN LD_FlangeManufacturingType m
                                        ON f.FlangeManufacturingTypeLd = m.Id
                                LEFT JOIN LD_FlangeType t
                                        ON f.FlangeTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS ReducerTypeCode,
                                t.Descr AS ReducerTypeDescr,
                                ReducerOutsideDiameter,
                                ReducerName,
                                ReducerComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS ReducerManufacturingTypeCode,
                                m.Descr AS ReducerManufacturingTypeDescr,
                                ReducerOutletGrade,
                                ReducerOutletWallthickness,
                                ReducerInletDiameter,
                                ReducerInletGrade,
                                ReducerInletWallThickness,
                                ReducerPressureRating,
                                ReducerOutletDiameter,
                                c.Code  AS ReducerConnectCode,
                                c.Descr AS ReducerConnectDescr
                            FROM   Reducer f
                                LEFT JOIN LD_ReducerConnect c
                                        ON f.ReducerConnectDomainId = c.Id
                                LEFT JOIN LD_ReducerManufacturingType m
                                        ON f.ReducerManufacturingTypeLd = m.Id
                                LEFT JOIN LD_ReducerType t
                                        ON f.ReducerTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS TeeTypeCode,
                                t.Descr AS TeeTypeDescr,
                                TeeOutsideDiameter,
                                TeeName,
                                TeeComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS TeeManufacturingTypeCode,
                                m.Descr AS TeeManufacturingTypeDescr,
                                TeeOutletGrade,
                                TeeOutletWallthickness,
                                TeeInletDiameter,
                                TeeInletGrade,
                                TeeInletWallThickness,
                                TeePressureRating,
                                TeeOutletDiameter,
                                c.Code  AS TeeConnectCode,
                                c.Descr AS TeeConnectDescr
                            FROM   Tee f
                                LEFT JOIN LD_TeeConnect c
                                        ON f.TeeConnectDomainId = c.Id
                                LEFT JOIN LD_TeeManufacturingType m
                                        ON f.TeeManufacturingTypeLd = m.Id
                                LEFT JOIN LD_TeeType t
                                        ON f.TeeTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS TeeTypeCode,
                                t.Descr AS TeeTypeDescr,
                                TapOutsideDiameter,
                                TapName,
                                TapComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS TapManufacturingTypeCode,
                                m.Descr AS TapManufacturingTypeDescr,
                                TapOutletGrade,
                                TapOutletWallthickness,
                                TapInletDiameter,
                                TapInletGrade,
                                TapInletWallThickness,
                                TapPressureRating,
                                TapOutletDiameter,
                                c.Code  AS TapConnectCode,
                                c.Descr AS TapConnectDescr
                            FROM   Tap f
                                LEFT JOIN LD_TapConnect c
                                        ON f.TapConnectDomainId = c.Id
                                LEFT JOIN LD_TapManufacturingType m
                                        ON f.TapManufacturingTypeLd = m.Id
                                LEFT JOIN LD_TapType t
                                        ON f.TapTypeDomainId = t.Id
                            UNION
                            SELECT f.Id,
                                EffectiveStartDate,
                                f.EffectiveEndDate,
                                t.Code  AS VentTypeCode,
                                t.Descr AS VentTypeDescr,
                                VentOutsideDiameter,
                                VentName,
                                VentComment,
                                BeginStationSeriesId,
                                BeginStationNum,
                                m.Code  AS VentManufacturingTypeCode,
                                m.Descr AS VentManufacturingTypeDescr,
                                VentOutletGrade,
                                VentOutletWallthickness,
                                VentInletDiameter,
                                VentInletGrade,
                                VentInletWallThickness,
                                VentPressureRating,
                                VentOutletDiameter,
                                c.Code  AS VentConnectCode,
                                c.Descr AS VentConnectDescr
                            FROM   Vent f
                                LEFT JOIN LD_VentConnect c
                                        ON f.VentConnectDomainId = c.Id
                                LEFT JOIN LD_VentManufacturingType m
                                        ON f.VentManufacturingTypeLd = m.Id
                                LEFT JOIN LD_VentType t
                                        ON f.VentTypeDomainId = t.Id ) tbl'';
                                        
                        EXECUTE IMMEDIATE sql_stmt;

                        sql_stmt := ''INSERT INTO LD_FabricationType(Code,Descr)
                        SELECT DISTINCT FabricationTypeDomainCode AS Code, FabricationTypeDomainDesc AS Descr
                        FROM   temp_Fabrication
                        WHERE  FabricationTypeDomainCode IS NOT NULL AND FabricationTypeDomainCode NOT IN (SELECT Code FROM LD_FabricationType)'';
                        
                        EXECUTE IMMEDIATE sql_stmt;

                        sql_stmt := ''INSERT INTO LD_FabManufacturingType(Code,Descr)
                        SELECT DISTINCT FabricationManufacturingTypeCode AS Code, FabricationManufacturingTypeDesc AS Descr
                        FROM   temp_Fabrication
                        WHERE  FabricationManufacturingTypeCode IS NOT NULL AND FabricationManufacturingTypeCode NOT IN (SELECT Code FROM LD_FabManufacturingType)'';
                        
                        EXECUTE IMMEDIATE sql_stmt;

                        sql_stmt := ''INSERT INTO LD_FabricationConnect(Code,Descr)
                        SELECT DISTINCT FabricationConnectCode AS Code, FabricationConnectDesc AS Descr
                        FROM   temp_Fabrication
                        WHERE  FabricationConnectCode IS NOT NULL AND FabricationConnectCode NOT IN (SELECT Code FROM LD_FabricationConnect)'';
                        
                        EXECUTE IMMEDIATE sql_stmt;

                        sql_stmt := ''UPDATE temp_Fabrication targ
                        SET (FabricationTypeDomainId, 
                            FabricationManufacturingTypeLd, 
                            FabricationConnectDomainID) = (SELECT t.Id, m.Id, c.Id
                                                            FROM   temp_Fabrication f
                                                            LEFT JOIN LD_FabricationType t ON f.FabricationTypeDomainCode = t.Code
                                                            LEFT JOIN LD_FabManufacturingType m ON f.FabricationManufacturingTypeCode = m.Code
                                                            LEFT JOIN LD_FabricationConnect c ON f.FabricationConnectCode = c.Code
                                                            WHERE targ.Id = f.Id
                                                            )
                        WHERE EXISTS (SELECT * 
                                    FROM   temp_Fabrication f
                                    LEFT JOIN LD_FabricationType t ON f.FabricationTypeDomainCode = t.Code
                                    LEFT JOIN LD_FabManufacturingType m ON f.FabricationManufacturingTypeCode = m.Code
                                    LEFT JOIN LD_FabricationConnect c ON f.FabricationConnectCode = c.Code
                                    WHERE targ.Id = f.Id)'';
                                    
                        EXECUTE IMMEDIATE sql_stmt;

                        DELETE FROM Fabrication;

                        sql_stmt := ''INSERT INTO Fabrication
                            (Id,
                                EffectiveStartDate,
                                EffectiveEndDate,
                                FabricationTypeDomainId,
                                FabricationOutsideDiameter,
                                FabricationName,
                                FabricationComment,
                                StationSeriesId,
                                StationNum,
                                FabricationManufacturingTypeLd,
                                FabricationOutletGrade,
                                FabricationOutletWallthickness,
                                FabricationInletDiameter,
                                FabricationInletGrade,
                                FabricationInletWallThickness,
                                FabricationPressureRating,
                                FabricationOutletDiameter,
                                FabricationConnectDomainID,
                                BeginStationSeriesId,
                                BeginStationNum,
                                EndStationSeriesId,
                                EndStationNum)
                        SELECT Id,
                        EffectiveStartDate,
                        EffectiveEndDate,
                        FabricationTypeDomainId,
                        FabricationOutsideDiameter,
                        FabricationName,
                        FabricationComment,
                        StationSeriesId,
                        StationNum,
                        FabricationManufacturingTypeLd,
                        FabricationOutletGrade,
                        FabricationOutletWallthickness,
                        FabricationInletDiameter,
                        FabricationInletGrade,
                        FabricationInletWallThickness,
                        FabricationPressureRating,
                        FabricationOutletDiameter,
                        FabricationConnectDomainID,
                        StationSeriesId,
                        StationNum,
                        StationSeriesId,
                        StationNum
                        FROM   temp_Fabrication'';
                        
                        EXECUTE IMMEDIATE sql_stmt;
                        
                        SELECT COUNT(*) INTO CNT
                        FROM user_tables
                        WHERE table_name = ''temp_Fabrication'';

                        IF CNT <> 0 THEN
                            sql_stmt := ''DROP TABLE temp_Fabrication PURGE'';
                            EXECUTE IMMEDIATE sql_stmt;
                        END IF;
                    END;';

        EXECUTE IMMEDIATE sql_stmt;
    
        UPDATE VersionInfo SET DBVersionCheckPoint = 1,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 650009 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.5 Release 0 Updates 10
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '650010', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 10';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0,
                                LastUpgradeDateTime = SYSDATE, 
                                LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
                                LastUpgradeType = 'FULL';
                                
        COMMIT;

        DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/