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
    CNT NUMBER(6);

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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT,
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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT,
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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT,
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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT, 
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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT,
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
            INSERT INTO ListDomain (id, DomainCatalogId, Code, Descr, SourceDomainId)
            VALUES (DEFAULT,
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640007 AND dbVersionCheckPoint = 7
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