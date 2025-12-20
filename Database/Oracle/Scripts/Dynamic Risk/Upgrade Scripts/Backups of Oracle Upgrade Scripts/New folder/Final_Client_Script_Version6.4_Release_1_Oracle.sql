SET SERVEROUTPUT ON

DECLARE
    CNT NUMBER(6);
    e_wrong_dbtype EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_wrong_dbtype, -20001);
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences  
    WHERE UPPER(ParameterName) = UPPER('DatabaseType')
        AND UPPER(Value) = UPPER('Stage');

    IF(CNT = 0)
    THEN
        raise_application_error(-20001, 'The target database must be a Stage database to apply this upgrade script.');
    END IF;
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 0
    THEN
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('CouponReading') 
            AND Column_Name = UPPER('CreatedDate');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CouponReading ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        ELSE    
            EXECUTE IMMEDIATE 'ALTER TABLE CouponReading MODIFY CreatedDate DEFAULT CURRENT_DATE';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE Table_Name = UPPER('CouponReading') 
            AND Column_Name = UPPER('CreatedUser');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE CouponReading ADD CreatedUser VARCHAR(45) DEFAULT (SYS_CONTEXT('USERENV', 'OS_USER')) NOT NULL]';
        ELSE
            EXECUTE IMMEDIATE q'[ALTER TABLE CouponReading MODIFY CreatedUser DEFAULT (SYS_CONTEXT('USERENV', 'OS_USER'))]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM all_tab_columns 
        WHERE Table_Name = UPPER('Load_CouponReading') 
            AND Column_Name = UPPER('CreatedUser');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE Load_CouponReading ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        ELSE
            EXECUTE IMMEDIATE q'[ALTER TABLE Load_CouponReading MODIFY CreatedUser DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns 
        WHERE Table_Name = UPPER('Load_CouponReading') 
            AND Column_Name = UPPER('CreatedDate');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE Load_CouponReading ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        ELSE
            EXECUTE IMMEDIATE 'ALTER TABLE Load_CouponReading MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables
        WHERE Table_Name = UPPER('StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('StructureVertex') 
            AND Column_Name = UPPER('CreatedDate');

            IF(CNT = 0)
            THEN
        	    EXECUTE IMMEDIATE 'ALTER TABLE StructureVertex ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        	ELSE
                EXECUTE IMMEDIATE 'ALTER TABLE StructureVertex MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
            END IF;
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('StructureVertex') 
            AND Column_Name = UPPER('CreatedUser');

            IF(CNT = 0)
            THEN
        	    EXECUTE IMMEDIATE q'[ALTER TABLE StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        	ELSE
                EXECUTE IMMEDIATE q'[ALTER TABLE StructureVertex MODIFY CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
            END IF;
        END IF;
 
        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('Load_StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('Load_StructureVertex') 
            AND Column_Name = UPPER('CreatedDate');

            IF(CNT =0)
            THEN
        	    EXECUTE IMMEDIATE 'ALTER TABLE Load_StructureVertex ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        	ELSE
                EXECUTE IMMEDIATE 'ALTER TABLE Load_StructureVertex MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
            END IF;
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('Load_StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('Load_StructureVertex') 
            AND Column_Name = UPPER('CreatedUser');

            IF(CNT =0)
            THEN
        	    EXECUTE IMMEDIATE q'[ALTER TABLE Load_StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        	ELSE
                EXECUTE IMMEDIATE q'[ALTER TABLE Load_StructureVertex MODIFY CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
            END IF;
        END IF;
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 1;

        COMMIT;

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);
    drop_fk VARCHAR2(1000);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 1
    THEN
        -- AlterHydroTestName_Stage.sql
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('HydroTest') 
            AND Column_Name = UPPER('HydroTestName');

        IF(CNT > 0)
        THEN
            --Store HydroTest table data in a table
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_HydroTest');
            IF(CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE tmp_HydroTest AS SELECT * FROM HydroTest';
            END IF;

            -- Create temporary tables to store foreign key constraint definitions for foreign keys on HydroTest ID column
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_add_constraint');

            IF(CNT = 0)
            THEN
            --Save foreign key constraints referencing HydroTest table the table tmp_add_constraint
            EXECUTE IMMEDIATE q'[CREATE TABLE tmp_add_constraint AS
                                SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                                ' ADD CONSTRAINT ' || fk_name || CHR(10) ||
                                ' FOREIGN KEY (' || column_name || ')' || CHR(10) ||
                                ' REFERENCES ' || ref_table || '(' || ref_column || ')' AS add_foreign_keys
                            FROM 
                            (SELECT ac.constraint_name fk_name, 
                                    ac.table_name,
                                    acc.column_name,
                                    ac.r_constraint_name,
                                    ref.table_name ref_table,
                                    ref.column_name ref_column
                            FROM user_constraints ac
                            JOIN user_cons_columns acc
                                ON (ac.constraint_name = acc.constraint_name)
                                    AND (ac.owner = acc.owner)
                            JOIN user_cons_columns ref
                                ON (ac.r_constraint_name = ref.constraint_name)
                                    AND (ac.r_owner = ref.owner)
                            WHERE ac.constraint_type = 'R'
                                AND ref.table_name = UPPER('HydroTest')
                                AND ref.column_name = 'ID' 
                            )]';
            END IF;

            DECLARE
                -- table variable to store foreign key creaion statements for dropped foreign keys
                TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
                INDEX BY BINARY_INTEGER;
                AddForeignKeys_tbl DDL_TABLE_TYPE;

                --Cursor to drop foreign keys
                CURSOR drop_cons_cursor IS
                SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                    ' DROP CONSTRAINT ' || fk_name  AS drop_foreign_key
                FROM
                (SELECT ac.constraint_name fk_name, 
                        ac.table_name,
                        acc.column_name,
                        ac.r_constraint_name,
                        ref.table_name ref_table,
                        ref.column_name ref_column
                FROM user_constraints ac
                JOIN user_cons_columns acc
                    ON (ac.constraint_name = acc.constraint_name)
                        AND (ac.owner = acc.owner)
                JOIN user_cons_columns ref
                    ON (ac.r_constraint_name = ref.constraint_name)
                        AND (ac.r_owner = ref.owner)
                WHERE ac.constraint_type = 'R'
                    AND ref.table_name = UPPER('HydroTest')
                    AND ref.column_name = 'ID' 
                    );  

            BEGIN
                --Store the foreign key definitions in a table VARIABLE
                EXECUTE IMMEDIATE q'[SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                                    ' ADD CONSTRAINT ' || fk_name || CHR(10) ||
                                    ' FOREIGN KEY (' || column_name || ')' || CHR(10) ||
                                    ' REFERENCES ' || ref_table || '(' || ref_column || ')' AS add_foreign_key
                            FROM 
                            (SELECT ac.constraint_name fk_name, 
                                    ac.table_name,
                                    acc.column_name,
                                    ac.r_constraint_name,
                                    ref.table_name ref_table,
                                    ref.column_name ref_column
                            FROM user_constraints ac
                            JOIN user_cons_columns acc
                                ON (ac.constraint_name = acc.constraint_name)
                                    AND (ac.owner = acc.owner)
                            JOIN user_cons_columns ref
                                ON (ac.r_constraint_name = ref.constraint_name)
                                    AND (ac.r_owner = ref.owner)
                            WHERE ac.constraint_type = 'R'
                                AND ref.table_name = UPPER('HydroTest')
                                AND ref.column_name = 'ID' 
                            )]'
                BULK COLLECT INTO AddForeignKeys_tbl;

                --Drop foreign key constraints referencing HydroTest table
                FOR ddl IN drop_cons_cursor LOOP
                   EXECUTE IMMEDIATE ddl.drop_foreign_key;      
                END LOOP;

                EXECUTE IMMEDIATE 'TRUNCATE TABLE HydroTest';

                EXECUTE IMMEDIATE 'ALTER TABLE HydroTest MODIFY HydroTestName VARCHAR2(50)';

                EXECUTE IMMEDIATE 'INSERT INTO HydroTest SELECT * FROM tmp_HydroTest';
             
                --Recreate foreign keys referencing HydroTest table
                FOR i IN 1..AddForeignKeys_tbl.COUNT LOOP
                    EXECUTE IMMEDIATE AddForeignKeys_tbl(i);
                END LOOP;
                
            END;

        END IF; -- End of HydroTest table modification

         SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('Load_HydroTest') 
            AND Column_Name = UPPER('HydroTestName');

        IF(CNT > 0)
        THEN
            --Store Load_HydroTest table data in a table temporarily
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_Load_HydroTest');

            IF(CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE tmp_Load_HydroTest AS SELECT * FROM Load_HydroTest';
            END IF;

            -- Trucate table to modify HydroTestName column
            EXECUTE IMMEDIATE 'TRUNCATE TABLE Load_HydroTest';

            EXECUTE IMMEDIATE 'ALTER TABLE Load_HydroTest MODIFY HydroTestName VARCHAR2(50)';

            --Insert data back into table
            EXECUTE IMMEDIATE 'INSERT INTO Load_HydroTest SELECT * FROM tmp_Load_HydroTest';     
                
        END IF; -- End of Load_HydroTest table modification

        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_Load_HydroTest');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_Load_HydroTest PURGE';
        END IF;
        
        
        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_HydroTest');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_HydroTest PURGE';
        END IF;
        
         SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_add_constraint');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_add_constraint PURGE';
        END IF;
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 2;

        COMMIT;

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(10);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 2
    THEN

    	/*
            New records to be inserted in the ListDomian table.
            List domains for excavation import anomaly type.
        */
        -- Metal Loss (Corrosion) default type
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE UPPER(Code) = UPPER('Corrosion') 
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Type'));

        IF(CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1,
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Type') AND rownum = 1), 
                    'Corrosion', 
                    'Corrosion', 
                    NULL);
        END IF;

        --Mechanical Damage (Deformation) default type
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE UPPER(Code) = UPPER('Deformation') 
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Defect Type') AND rownum = 1);
        
        IF (CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1,
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Defect Type')  AND rownum = 1), 
                    'Deformation', 
                    'Deformation', 
                    NULL);
        END IF;

        -- ESCA (CrackLike) default type
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE UPPER(Code) = UPPER('Crack-Like')
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Crack Anomaly Type') AND rownum = 1);

        IF(CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1,
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Crack Anomaly Type') AND rownum = 1), 
                    'Crack-Like', 
                    'Crack-Like', 
                    NULL);
        END IF;

        /*
            New records to be inserted in the ListDomian table.
            List domains for excavation import anomaly status.
        */
        -- Metal Loss (Corrosion) "Not Found In Field" status
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE Code = 'Not Found In Field' 
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Status') AND rownum = 1);
        
        IF(CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1, 
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Status') AND rownum = 1), 
                    'Not Found In Field',   
                    'Not Found In Field', 
                    NULL);
        END IF;

        --Mechanical Damage (Deformation) "Not Found In Field" status
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE UPPER(Code) = UPPER('Not Found In Field') 
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Status') AND rownum = 1);

        IF(CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1,
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Status') AND rownum = 1), 
                    'Not Found In Field',   
                    'Not Found In Field', 
                    NULL);
        END IF;

        -- ESCA (CrackLike) "Not Found In Field" status
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain 
        WHERE UPPER(Code) = UPPER('Not Found In Field') 
            AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Excavation Site Crack Anomaly Status') AND rownum = 1);

        IF(CNT = 0)
        THEN
            SELECT MAX(id) INTO CNT FROM ListDomain;

            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (CNT + 1,
                    (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Excavation Site Crack Anomaly Status')), 
                    'Not Found In Field',   
                    'Not Found In Field', 
                    NULL);
        END IF;

        /*
            New records to be inserted in the SystemPreferences table.
            System preferences that define the default list domains for anomalies in excavation import.
        */
        -- Metal Loss (Corrosion) type default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultMetalLossType');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultMetalLossType', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code) = UPPER('Corrosion') 
                        AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Type') AND rownum = 1) AND rownum = 1), 
                    null);
        END IF;

        -- Metal Loss (Corrosion) status default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultMetalLossStatus');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultMetalLossStatus', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code) = UPPER('Not Found In Field') AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Metal Loss Status') AND rownum = 1) AND rownum = 1), 
                    null);
        END IF;

        -- Mechanical Damage (Deformation) type default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultMechanicalDamageType');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultMechanicalDamageType', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code) = UPPER('Deformation') AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Defect Type') AND rownum = 1) AND rownum = 1),
                    null);
        END IF;

        -- Mechanical Damage (Deformation) status default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultMechanicalDamageStatus');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultMechanicalDamageStatus', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code) = UPPER('Not Found In Field') AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Mechanical Damage Status') AND rownum = 1) AND rownum = 1), 
                    null);
        END IF;

        -- ESCA (CrackLike) type default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultESCAType');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultESCAType', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code) = UPPER('Crack-Like') AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Crack Anomaly Type') AND rownum = 1) AND rownum = 1), 
                    null);
        END IF;

        -- ESCA (CrackLike) status default list domain
        SELECT COUNT(*) INTO CNT 
        FROM SystemPreferences 
        WHERE UPPER(ParameterName) = UPPER('DefaultESCAStatus');

        IF(CNT = 0)
        THEN
            INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
            VALUES ('DefaultESCAStatus', 
                    (SELECT Id FROM ListDomain WHERE UPPER(Code)= UPPER('Not Found In Field') AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE UPPER(DomainDescr) = UPPER('Excavation Site Crack Anomaly Status') AND rownum = 1) AND rownum = 1), 
                    null);
        END IF; 
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 3;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 3
    THEN
        
        --Script To Create Load LandSlideArea.sql
        --CREATE Extract_LandSlideArea TABLE AND ADD CheckSumValue TO LandSlideArea

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE TABLE_NAME = UPPER('LandSlideArea') 
            AND COLUMN_NAME = UPPER('CheckSumValue');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LandSlideArea ADD CheckSumValue NUMBER NULL';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns 
        WHERE Table_Name = UPPER('load_LandSlideArea');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[CREATE TABLE load_LandSlideArea (
                                Id NUMBER(10, 0) NOT NULL,
                                EffectiveStartDate DATE  NULL,
                                EffectiveEndDate DATE  NULL,
                                LandSlideAreaRangeLD NUMBER(7, 0) NULL,
                                LandSlideAreaMin NUMBER(10, 0) NULL,
                                LandSlideAreaMax NUMBER(10, 0) NULL,
                                BeginStationSeriesId NUMBER(10, 0) NOT NULL,
                                BeginStationNum NUMBER(13, 5) NOT NULL,
                                EndStationSeriesId NUMBER(10, 0) NOT NULL,
                                EndStationNum NUMBER(13, 5) NOT NULL,
                                LastModByUserId VARCHAR2 (45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL,
                                LastModDATE DATE DEFAULT CURRENT_DATE NOT NULL,
                                LandSlideAreaCode VARCHAR2(55) NULL,
                                LandSlideAreaLD NUMBER(7, 0) NULL,
                                SourceId VARCHAR2(50) CONSTRAINT Pk_LandSlideAreaSourceId PRIMARY KEY,
                                CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL,
                                CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL,
                                CheckSumValue NUMBER NOT NULL)]';
        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 4;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 4
    THEN
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE table_name = UPPER('EarthquakeArea') AND COLUMN_NAME = UPPER('CheckSumValue');

        IF(CNT = 0)
        THEN
        	EXECUTE IMMEDIATE 'ALTER TABLE EarthquakeArea ADD CheckSumValue NUMBER NULL';
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE table_name = UPPER('Load_EarthQuakeArea');

        IF(CNT = 0)
        THEN
        	EXECUTE IMMEDIATE q'[CREATE TABLE Load_EarthQuakeArea (
                                Id   NUMBER(10, 0) NOT NULL,
                                EffectiveStartDate  DATE  NULL,
                                EffectiveEndDate  DATE  NULL,
                                EarthQuakeAreaRangeLD   NUMBER(7, 0) NULL,
                                EarthQuakeAreaMin   NUMBER(10, 0) NULL,
                                EarthQuakeAreaMax   NUMBER(10, 0) NULL,
                                BeginStationSeriesId   NUMBER(10, 0) NOT NULL,
                                BeginStationNum   NUMBER(13, 5) NOT NULL,
                                EndStationSeriesId   NUMBER(10, 0) NOT NULL,
                                EndStationNum   NUMBER(13, 5) NOT NULL,
                                LastModByUserId   VARCHAR2(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL,
                                LastModDateTime  DATE  DEFAULT CURRENT_DATE NOT NULL,
                                SourceId   VARCHAR2(50) CONSTRAINT PK_EarthQuakeAreaSourceId PRIMARY KEY,
                                CreatedDate  DATE  DEFAULT CURRENT_DATE NOT NULL,
                                CreatedUser   VARCHAR2(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL,
                                CheckSumValue NUMBER  NOT NULL)]';
        END IF;  

        UPDATE VersionInfo SET DBVersionCheckPoint = 5;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 5
    THEN
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE Table_Name = UPPER('LOAD_EXCAVSITECRACKANOMALY');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[CREATE TABLE LOAD_EXCAVSITECRACKANOMALY(
                                    Id   NUMBER(10, 0) NOT NULL,
                                    EffectiveStartDate  DATE  NOT NULL,
                                    EffectiveEndDate  DATE  NULL,
                                    ExcavationSiteId   NUMBER(10, 0) NULL,
                                    ESCAVendorPackageCode  VARCHAR2 (50) NULL,
                                    ESCATypeDomainId   NUMBER(7, 0) NULL,
                                    ESCAAnomalyNumber  VARCHAR2 (15) NULL,
                                    ESCAAnomalyDepth  VARCHAR2 (15) NULL,
                                    ESCAGirthWeldNum  VARCHAR2 (25) NULL,
                                    ESCADistanceFromGirthWeld   NUMBER(10, 3) NULL,
                                    ESCALargestIndividualInd   NUMBER(10, 0) NULL,
                                    ESCALength   NUMBER(9, 2) NULL,
                                    ESCAWidth   NUMBER(9, 2) NULL,
                                    ESCAOrientation   NUMBER(3, 0) NULL,
                                    ESCASurfaceInd  VARCHAR2 (2) NULL,
                                    ESCADescr  VARCHAR2 (254) NULL,
                                    ESCAComment  VARCHAR2 (255) NULL,
                                    ESCAGirthWeldNumDS  VARCHAR2 (25) NULL,
                                    ESCADistanceFromGirthWeldDS   NUMBER(10, 3) NULL,
                                    AppVersion  VARCHAR2 (255) NULL,
                                    ESCALatitude   NUMBER(11, 9) NULL,
                                    ESCALongitude   NUMBER(12, 9) NULL,
                                    Escax   NUMBER(12, 3) NULL,
                                    Escay   NUMBER(12, 3) NULL,
                                    Escaz   NUMBER(10, 3) NULL,
                                    StationSeriesId   NUMBER(10, 0) NULL,
                                    StationNum   NUMBER(13, 5) NULL,
                                    LastModByUserId  VARCHAR2 (45) NOT NULL,
                                    LastModDateTime  DATE  NOT NULL,
                                    InlineInspectionCAId   NUMBER(10, 0) NULL,
                                    ESCAStatusDomainId   NUMBER(7, 0) NOT NULL,
                                    ESCADepthPct   NUMBER(8, 5) NULL,
                                    SourceId  VARCHAR2 (50) CONSTRAINT PK_EXCAVCASourceId PRIMARY KEY,
                                    CreatedDate  DATE  NOT NULL,
                                    CreatedUser  VARCHAR2 (45) NOT NULL,
                                    CheckSumValue   int  NOT NULL)]';
        END IF;    

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_EXCAVSITECRACKANOMALY'
            AND column_name = 'LastModByUserId';

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE LOAD_EXCAVSITECRACKANOMALY MODIFY LastModByUserId DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_EXCAVSITECRACKANOMALY'
            AND column_name = 'LastModDateTime';

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE LOAD_EXCAVSITECRACKANOMALY MODIFY LastModDateTime DEFAULT CURRENT_DATE]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_EXCAVSITECRACKANOMALY'
            AND column_name = 'CreatedDate';

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE LOAD_EXCAVSITECRACKANOMALY MODIFY CreatedDate DEFAULT CURRENT_DATE]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_EXCAVSITECRACKANOMALY'
            AND column_name = 'CreatedUser';

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE LOAD_EXCAVSITECRACKANOMALY MODIFY CreatedUser DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
        END IF;

        UPDATE VersionInfo SET DBVersionCheckPoint = 6;
        COMMIT;

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 6
    THEN

        UPDATE VersionInfo SET DBVersionCheckPoint = 7;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 7
    THEN

    -- Create Cursor to convert datatype from varchar2 to nvarchar2 ("Cursor to convert datatype from varchar2 to nvarchar2.sql")

        EXECUTE IMMEDIATE q'[CREATE OR REPLACE PROCEDURE alter_datatype AUTHID DEFINER AS
        table_name varchar2(500);
        column_name varchar2(500);
        data_length varchar2(500);
        sql_text VARCHAR2(4000);

        CURSOR update_data_type IS 
        SELECT table_name, column_name, data_length 
        FROM  user_tab_columns WHERE data_type LIKE 'VARCHAR%' AND
        table_name IN ('AREA', 
        'BEND',
        'CASING',
        'CLASSAREA',
        'COATING',
        'CORPORATION',
        'COUPON',
        'COUPONREADING',
        'COVERDEPTH',
        'COVERDEPTHPROFILE',
        'CPSURVEY',
        'CPSURVEYRANGE',
        'CPSURVEYREADING',
        'CROSSING',
        'CROSSINGLOCN',
        'DAMAGEPREVENTION',
        'DESIGNCLASS',
        'DISCHARGESUBSYSTEM',
        'DISTRICTDIVISION',
        'EARTHQUAKEAREA',
        'ELBOW',
        'ELEVATIONPROFILE',
        'EXCAVATIONPROJECT',
        'EXCAVATIONSITE',
        'EXCAVATIONSITECRACKANAMOLY',
        'EXPOSEDPIPE',
        'EXTRUSION',
        'FLANGE',
        'FLOODAREA',
        'GIRTHWELD',
        'HCACFR',
        'HCACFRSEG',
        'HCAPIPEGASCONSTANTFACTOR',
        'HCAPIPEPIRBUFFER',
        'HYDROTEST',
        'HYDROTESTRANGE',
        'INCIDENT',
        'INCIDENTHISTORY',
        'INLINEINSPECTION',
        'INLINEINSPECTIONCRACKANOMALY',
        'INLINEINSPECTIONFACILITY',
        'INLINEINSPECTIONFEATURE',
        'INLINEINSPECTIONJOINT',
        'INLINEINSPECTIONNONCRSNDFCT',
        'INLINEINSPECTIONRANGE',
        'INTERNALCOATING',
        'IRASCUSTOMDATA1',
        'IRASCUSTOMDATA11',
        'IRASCUSTOMDATA2',
        'IRASCUSTOMDATA3',
        'IRASCUSTOMDATA4',
        'IRASCUSTOMDATA5',
        'IRASCUSTOMDATA6',
        'IRASCUSTOMDATA7',
        'IRASCUSTOMDATA8',
        'IRASCUSTOMDATA9',
        'JOINTCOATING',
        'LANDUSE',
        'LINELOOP',
        'MAOP',
        'MARKER',
        'METALLOSS',
        'MLVCORRECTION',
        'MLVSECTION',
        'MOP',
        'OPERATINGDATA',
        'OPERATINGUNIT',
        'PIPELINESYSTEM',
        'PIPESEGMENT',
        'PRODUCTCOMPONENT',
        'RECTIFIER',
        'RECTIFIERREADING',
        'REDUCER',
        'RIGHTOFWAY',
        'SERIESCONNECTION',
        'SLEEVE',
        'SOILAREA',
        'SOILLANDUSEAREA',
        'STATIONSERIES',
        'STRUCTURE',
        'STRUCTUREVERTEX',
        'TAP',
        'TEE',
        'TESTPOSTPOINT',
        'TESTPOSTPOINTREADING',
        'VALVE',
        'VENT',
        'WEIGHT'
        )
        OR table_name LIKE 'LOAD%'
        ORDER BY table_name;

        BEGIN
        OPEN update_data_type;
        
        FETCH update_data_type INTO table_name, column_name, data_length;
        WHILE update_data_type%found LOOP

            sql_text := 'ALTER TABLE ' || table_name || ' MODIFY ' || column_name || ' nvarchar2(' || data_length || ')' ;
            EXECUTE IMMEDIATE sql_text;
            COMMIT;
            dbms_output.put_line(sql_text);
        FETCH update_data_type INTO table_name, column_name, data_length;    
        END LOOP;
        CLOSE update_data_type;
        END;]';

        UPDATE VersionInfo SET DBVersionCheckPoint = 8;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 8
    THEN

        -- SP_DX6CONFIGV5.sql

        EXECUTE IMMEDIATE q'[CREATE OR REPLACE PROCEDURE "SP_DX6CONFIGV5" 

        AS
        BEGIN

            BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE temp_Fabrication';
            EXCEPTION
            WHEN OTHERS THEN
                    NULL;
                END;
        DECLARE
            CRF_sql    VARCHAR(20000) :=null;
            INF_sql    VARCHAR(20000) :=null;
        BEGIN 

            CRF_sql  := 'CREATE TABLE temp_Fabrication
            (
                Id                               NUMBER(18, 0) NULL,
                EffectiveStartDate               DATE NULL,
                EffectiveEndDate                 DATE NULL,
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
            )';
        
        EXECUTE IMMEDIATE CRF_sql;

        BEGIN

            INF_sql := 'INSERT INTO temp_Fabrication
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
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.ElbowConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ElbowManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ElbowTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.ExtrusionConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ExtrusionManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ExtrusionTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.FlangeConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.FlangeManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.FlangeTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.ReducerConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ReducerManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ReducerTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.TeeConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.TeeManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.TeeTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.TapConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.TapManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.TapTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
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
                            LEFT JOIN ListDomain c
                                ON f.VentConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.VentManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.VentTypeDomainId = t.Id ) tbl ';
                            
        EXECUTE IMMEDIATE INF_sql;    

        END;
        
        DECLARE 
            SQL_STMT VARCHAR(20000) :=null;                     

        BEGIN

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                       AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationTypeDomainId'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                              AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationTypeDomainCode AS Code,
                                    FabricationTypeDomainDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationTypeDomainCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationTypeDomainId'') )';
                                                
            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                              AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationManufacturingTypeLd'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                                     AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationManufacturingTypeCode AS Code,
                                    FabricationManufacturingTypeDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationManufacturingTypeCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationManufacturingTypeLd'' ) )';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                          AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationConnectDomainID'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                                 AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationConnectCode AS Code,
                                    FabricationConnectDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationConnectCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationConnectDomainID'' ) )';


            EXECUTE IMMEDIATE SQL_STMT;
                
                    
            SQL_STMT := 'Update temp_Fabrication 
            set FabricationTypeDomainId = (Select max(t.Id) from ListDomain t left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = t.Code AND
                            t.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationTypeDomainId'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'Update temp_Fabrication 
            set FabricationManufacturingTypeLd = (Select max(m.Id) from ListDomain m left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = m.Code AND
                            m.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationManufacturingTypeLd'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'Update temp_Fabrication 
            set FabricationConnectDomainID = (Select max(c.Id) from ListDomain c left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = c.Code AND
                            c.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationConnectDomainID'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            EXECUTE IMMEDIATE 'UPDATE FabricationRemark SET FabricationId = NULL';
            EXECUTE IMMEDIATE 'UPDATE FacilityAlignment SET FabricationId = NULL';

            EXECUTE IMMEDIATE 'DELETE FROM Fabrication';


            SQL_STMT := 'INSERT INTO Fabrication
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
            FROM   temp_Fabrication ';

            EXECUTE IMMEDIATE SQL_STMT;
        END;

        EXECUTE IMMEDIATE 'DROP TABLE temp_Fabrication';

        COMMIT;
        END;

        END;]';

        -- Sp_TruncateTable.sql
        EXECUTE IMMEDIATE q'[create or replace PROCEDURE SP_TRUNCATETABLE (TABLENAME varchar) 
        AUTHID DEFINER
        AS 
        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || TABLENAME;
        END;]';

        UPDATE VersionInfo SET DBVersionCheckPoint = 9;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640007 AND dbVersionCheckPoint = 9
    THEN
       	/********************************************************************************************************/
		--	Update VersionInfo Application Version 6.4 Release 1 Updates 01 hotfixes
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640101', DBVersionComment = 'Service Pack DDL 6.4, Rel. 1, Updates 01 hotfixes';
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 0;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/