ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE
	CNT INT;
	e_invalid_database EXCEPTION;
    stmt VARCHAR2(600);
BEGIN	

    SELECT COUNT(*) INTO CNT
    FROM all_tables
    WHERE UPPER(table_name) = UPPER('SystemPreferences');

    IF (CNT <> 0)
    THEN

        stmt := q'[SELECT COUNT(*) 
        FROM SystemPreferences sp 
        WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage']';

        EXECUTE IMMEDIATE stmt
        INTO CNT;

        IF (CNT = 0)
        THEN
            RAISE e_invalid_database;
        END IF;
    END IF;
EXCEPTION
	WHEN e_invalid_database THEN
		DBMS_OUTPUT.PUT_LINE ('The target database must be a Stage database to apply this upgrade script.');
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640105 AND dbVersionCheckPoint = 0
    THEN
    
        -- UpdateSoilType_DomainCatalogColXRef_ColumnName.sql

        SELECT COUNT(*) INTO CNT
        FROM  DomainCatalogColXRef 
        WHERE TableName = 'SoilArea' 
        AND domaincatalogid = (SELECT Id FROM domaincatalog WHERE domaindescr = 'Soil Type') 
        AND columnname <> 'SoilTypeLD';

        IF (CNT <> 0)
        THEN
            UPDATE domaincatalogcolxref 
            SET columnname = 'SoilTypeLD' 
            WHERE tablename = 'SoilArea' AND domaincatalogid = (SELECT Id FROM domaincatalog WHERE domaindescr = 'Soil Type');
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
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640105 AND dbVersionCheckPoint = 1
    THEN
       	/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 01
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640201', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 01';
        
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 0
    THEN
      
        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'History_SystemPreferences';

        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE History_SystemPreferences
                    (ParameterName VARCHAR2(50),
                        Value  VARCHAR2(2000),
                        RawValue BLOB,
                        CreatedUser VARCHAR(45),
                        CreatedDate TIMESTAMP,
                        LastModByUserId VARCHAR2(2000) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                        LastModDateTime TIMESTAMP DEFAULT SYSDATE
                        )';

            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        sql_stmt := 'CREATE OR REPLACE TRIGGER tu_History_SystemPreferences
                    AFTER UPDATE OR DELETE
                    ON SystemPreferences
                    FOR EACH ROW
                    DECLARE
                    BEGIN
                        INSERT INTO History_SystemPreferences (ParameterName, Value, RawValue, CreatedUser, CreatedDate)
                        VALUES(:OLD.ParameterName,
                               :OLD.Value,
                               :OLD.RawValue,
                               :OLD.LastModByUserId,
                               :OLD.LastModDateTime
                               );
                    END;';

        EXECUTE IMMEDIATE sql_stmt;
  
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 1
    THEN
        -- Script To add BeginStationSeriesId, EndStationSeriesId, BeginStationNum, EndStationNum.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'BeginStationSeriesId';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD BeginStationSeriesId NUMBER(10, 0) NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'BeginStationNum';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD BeginStationNum NUMBER(13, 5) NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'EndStationSeriesId';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD EndStationSeriesId NUMBER(10, 0) NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'EndStationNum';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD EndStationNum NUMBER(13, 5) NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 2
    THEN
        -- Script To Add CheckSumValue Column to Node table and create Load_Node table.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'Node'
        AND column_name = 'CheckSumValue';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE Node ADD CheckSumValue INT';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Load_Node';

        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE Load_Node 
                        (Id NUMBER(10, 0) NOT NULL,
                         NodeName VARCHAR2(70) NOT NULL,
                         NodeAltName VARCHAR2(100),
                         LastModByUserId VARCHAR2(45) NOT NULL,
                         LastModDateTime DATE NOT NULL,
                         SourceId VARCHAR(50) NOT NULL,
                         CreatedDate DATE NOT NULL,
                         CreatedUser VARCHAR2(45) NOT NULL,
                         CheckSumValue INT NOT NULL,
                         CONSTRAINT PK_Load_NodeSourceId PRIMARY KEY (SourceId)
                        )';

            EXECUTE IMMEDIATE sql_stmt;
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 3
    THEN
        -- Script To Add CheckSumValue Column to NodeConnection table and create Load_NodeConnection table.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'CheckSumValue';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD CheckSumValue INT';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Load_NodeConnection';

        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE Load_NodeConnection
                        (Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE,
                        EffectiveEndDate DATE,
                        NodeId NUMBER(10, 0) NOT NULL,
                        NodeConnectionTypeDomainId NUMBER(7, 0),
                        NodeConnectionStatusDomainId NUMBER(7, 0),
                        NodeConnectionLatitude NUMBER(11, 9),
                        NodeConnectionLongitude NUMBER(12, 9),
                        NodeConnectionCoordSysLD NUMBER(7, 0),
                        NodeConnectionX NUMBER(12, 3),
                        NodeConnectionY NUMBER(12, 3),
                        NodeConnectionZ NUMBER(10, 3),
                        StationSeriesId NUMBER(10, 0) NOT NULL,
                        StationNum NUMBER(10, 3) NOT NULL,
                        LastModByUserId VARCHAR2(45) NOT NULL,
                        LastModDateTime DATE NOT NULL,
                        SourceId VARCHAR2 (50) NOT NULL,
                        CreatedDate  DATE NOT NULL,
                        CreatedUser VARCHAR2 (45) NOT NULL,
                        BeginStationSeriesId NUMBER (10,0) NOT NULL,
                        BeginStationNum NUMBER (13,5) NOT NULL,
                        EndStationSeriesId NUMBER (10,0) NOT NULL,
                        EndStationNum NUMBER (13,5) NOT NULL,
                        CheckSumValue INT,
                        CONSTRAINT PK_Load_NodeConnection PRIMARY KEY (SourceId)
                        )';

            EXECUTE IMMEDIATE sql_stmt;
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 4
    THEN
        -- Script To Add SourceId, CreatedDate, CreatedUser to Node Table.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'Node'
        AND column_name = 'SourceId';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE Node ADD SourceId VARCHAR2(50)';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'Node'
        AND column_name = 'CreatedDate';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE Node ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'Node'
        AND column_name = 'CreatedUser';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE Node ADD CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL';

            EXECUTE IMMEDIATE sql_stmt;
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 5
    THEN
        -- Script To Add SourceId, CreatedDate, CreatedUser to NodeConnection Table.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'SourceId';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD SourceId VARCHAR2(50)';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'CreatedDate';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD CreatedDate DATE DEFAULT SYSDATE';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'NodeConnection'
        AND column_name = 'CreatedUser';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE NodeConnection ADD CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';

            EXECUTE IMMEDIATE sql_stmt;
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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 6
    THEN
        -- Triggers_For_Updating_VersionInfo_Table.sql
        sql_stmt := 'CREATE OR REPLACE TRIGGER tu_versioninfo
                    BEFORE UPDATE
                    ON VersionInfo
                    FOR EACH ROW
                    DECLARE
                    BEGIN
                        :NEW.LastModByUserId := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                        :NEW.LastModDateTime := SYSDATE;                     
                    END;';

       EXECUTE IMMEDIATE sql_stmt;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'VersionInfo'
        AND column_name = 'LastUpgradeUserId';

        IF CNT <> 0 THEN
            sql_stmt := 'ALTER TABLE VersionInfo MODIFY LastUpgradeUserId DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'VersionInfo'
        AND column_name = 'LastUpgradeDateTime';

        IF CNT <> 0 THEN
            sql_stmt := 'ALTER TABLE VersionInfo MODIFY LastUpgradeDateTime DEFAULT SYSDATE';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'VersionInfo'
        AND column_name = 'LastModByUserId';

        IF CNT <> 0 THEN
            sql_stmt := 'ALTER TABLE VersionInfo MODIFY LastModByUserId DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'VersionInfo'
        AND column_name = 'LastModDateTime';

        IF CNT <> 0 THEN
            sql_stmt := 'ALTER TABLE VersionInfo MODIFY LastModDateTime DEFAULT SYSDATE';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE OR REPLACE TRIGGER th_VersionInfo
                    BEFORE UPDATE
                    ON VersionInfo
                    FOR EACH ROW
                    BEGIN
                        IF UPDATING(''DBVersion'') THEN
                        :NEW.LastUpgradeUserId :=  SYS_CONTEXT(''USERENV'', ''OS_USER'');
                        :NEW.LastUpgradeDateTime := SYSDATE;
                        END IF;  

                        IF UPDATING(''LastUpgradeuserId'') OR UPDATING(''LastUpgradeDateTime'') OR
                            UPDATING(''LastUpgradeType'') OR UPDATING(''DBVersion'') OR UPDATING(''DBVersionComment'')
                            OR UPDATING(''DBVersionCheckPoint'') THEN
                            INSERT INTO VersionHistory(DBVersion, 
                                                       DBVersionComment, 
                                                       LastModByUserId, 
                                                       LastModDateTime, 
                                                       DataExchangeLastRunDateTime,
                                                       LastUpgradeUserId,
                                                       LastUpgradeDateTime,
                                                       LastUpgradeType,
                                                       DBVersionCheckPoint)
                            VALUES(:OLD.DBVersion, 
                                   :OLD.DBVersionComment, 
                                   :OLD.LastModByUserId, 
                                   :OLD.LastModDateTime, 
                                   :OLD.DataExchangeLastRunDateTime,
                                   :OLD.LastUpgradeUserId,
                                   :OLD.LastUpgradeDateTime,
                                   :OLD.LastUpgradeType,
                                   :OLD.DBVersionCheckPoint);
                        END IF;
                    END;';

        EXECUTE IMMEDIATE sql_stmt;

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
    sql_stmt VARCHAR2(20000);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 7
    THEN
        -- UpdateColumnsNullable_CoverDepthProfile_Stage.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_COVERDEPTHPROFILE'
        AND column_name = 'Latitude'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE LOAD_COVERDEPTHPROFILE MODIFY Latitude NUMBER(11, 9) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_COVERDEPTHPROFILE'
        AND column_name = 'Longitude'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE LOAD_COVERDEPTHPROFILE MODIFY Longitude NUMBER(12, 9) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_COVERDEPTHPROFILE'
        AND column_name = 'CoordSysDomainId'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE LOAD_COVERDEPTHPROFILE MODIFY CoordSysDomainId NUMBER(7, 0) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'LOAD_COVERDEPTHPROFILE'
        AND column_name = 'CoverDepthReading'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE LOAD_COVERDEPTHPROFILE MODIFY CoverDepthReading NUMBER(8, 4) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'COVERDEPTHPROFILE'
        AND column_name = 'Latitude'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE COVERDEPTHPROFILE MODIFY Latitude NUMBER(11, 9) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'COVERDEPTHPROFILE'
        AND column_name = 'Longitude'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE COVERDEPTHPROFILE MODIFY Longitude NUMBER(12, 9) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'COVERDEPTHPROFILE'
        AND column_name = 'CoordSysDomainId'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE COVERDEPTHPROFILE MODIFY CoordSysDomainId NUMBER(7, 0) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'COVERDEPTHPROFILE'
        AND column_name = 'CoverDepthReading'
        AND nullable = 'N';

        IF CNT = 1 THEN
            sql_stmt := 'ALTER TABLE COVERDEPTHPROFILE MODIFY CoverDepthReading NUMBER(8, 4) NULL';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

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
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640201 AND dbVersionCheckPoint = 8
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 02
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640202', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 02';
        
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    TableName VARCHAR2(128);
    OldColumnName VARCHAR2(128);
    NewColumnName VARCHAR2(128);
    sql_stmt varchar2(1000);
    Counter NUMBER;
    CNT NUMBER;

    CURSOR RenameColumnList IS
    SELECT table_name, column_name
    FROM user_tab_columns
    WHERE column_name LIKE 'LastMod%' OR
        column_name LIKE 'Create%'
    MINUS
    SELECT table_name, column_name
    FROM user_tab_columns
    WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId');

    CURSOR AddColumnList IS
    SELECT table_name INTO CNT FROM user_tables WHERE table_name NOT IN (SELECT table_name FROM (
        SELECT table_name, COUNT(table_name) FROM user_tab_columns
        WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')
        GROUP BY table_name
        HAVING COUNT(table_name) = 4
        ));
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640202 AND dbVersionCheckPoint = 0
    THEN
            
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
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640202 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 03
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640203', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 03';
        
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

DECLARE 
    CNT INT;
    sql_stmt VARCHAR2(20000);
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640203 AND dbVersionCheckPoint = 0
    THEN

        SELECT COUNT(*) INTO CNT
        FROM user_constraints
        WHERE constraint_name = 'Pk_TestPostPointReadingSourceId';

        IF CNT <> 0
        THEN
            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE table_name = 'load_TEstPostpointreading';

            IF CNT <> 0
            THEN
                sql_stmt := 'ALTER TABLE load_TEstPostpointreading DROP CONSTRAINT Pk_TestPostPointReadingSourceId';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE load_TEstPostpointreading ADD CONSTRAINT Pk_TestPostPointReadingSourceId PRIMARY KEY (SourceId, TestPointReadingDate)';
                EXECUTE IMMEDIATE sql_stmt;
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
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640203 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 03
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640204', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 04';
        
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

SET DEFINE OFF;

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    LastId INT;
    NextID INT;
    CNT INT;
    sql_stmt VARCHAR(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640204 AND dbVersionCheckPoint = 0
    THEN

        SELECT COUNT(*) INTO CNT 
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coating Type - Line')
        AND NOT EXISTS (SELECT * FROM DomainCatalogColXRef
                        WHERE TableName = 'Coating' 
                        AND ColumnName = 'CoatingLineDomainId');

        IF CNT <> 0
        THEN
            SELECT MAX(Id) INTO LastId
            FROM DomainCatalog;

            NextID := LastId || 1;

            sql_stmt := 'INSERT DomainCatalog (Id, DomainDescr) 
                        VALUES (' || CAST(NextID AS VARCHAR2) || ', N''Coating Type - Line'')';
                    
            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''FBE/Powercrete'', N''FBE/Powercrete'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Unknown'', N''Unknown'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Primer & Tape'', N''Primer and Tape'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Bare'', N''Bare'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar (Hot enamel)'', N''Coal Tar (Hot enamel)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar (Reinforced Enamel)'', N''Coal Tar (Reinforced Enamel)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''FBE'', N''FBE'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar (Hot enamel)'', N''Coal Tar (Hot enamel)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar (Reinforced Enamel)'', N''Coal Tar (Reinforced Enamel)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''FBE'', N''FBE'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Pre-2000 Wax'', N''Pre-2000 Wax'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''post 2000 Wax'', N''post 2000 Wax'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Mastic'', N''Mastic'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N'' Cold Primer'', N'' Cold Primer'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Extruded Polyethylene'', N''Extruded Polyethylene'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Travel PE Tapecoat'', N''Travel PE Tapecoat'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Neoprene'', N''Neoprene'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Felt Wrap'', N''Felt Wrap'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Shorted Casing'', N''Shorted Casing'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Rock Jacket'', N''Rock Jacket'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''ARO'', N''ARO'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Asbestos Felt'', N''Asbestos Felt'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar'', N''Coal Tar'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Extruded Asphalt'', N''Extruded Asphalt'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Flakeline'', N''Flakeline'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Glass Filled Polyester'', N''Glass Filled Polyester'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Grease'', N''Grease'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''concrete'', N''concrete'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''HPCC'', N''HPCC'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Unknown (Verified)'', N''Unknown (Verified)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''ENAMEL'', N''ENAMEL'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Fusion Bonded Epoxy'', N''Fusion Bonded Epoxy'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Paper'', N''Paper'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Asphalt Enamel'', N''Asphalt Enamel'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Atmospheric'', N''Atmospheric'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''PE or 2 Layer'', N''PE or 2 Layer'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Paint'', N''Paint'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Power Crete'', N''Power Crete'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Primer'', N''Primer'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Asphalt Primer'', N''Asphalt Primer'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''SHRINK SLEEVE'', N''SHRINK SLEEVE'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Somastic'', N''Somastic'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''SP-2888 RG LIQUID EPOXY'', N''SP-2888 RG LIQUID EPOXY'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Tapecoat PE'', N''Tapecoat PE'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''TC 7000 Epoxy'', N''TC 7000 Epoxy'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Rubber (Vulcanized)'', N''Rubber (Vulcanized)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Plastic'', N''Plastic'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''WRAP'', N''WRAP'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Asphalt'', N''Asphalt'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Napcard Slick Coat'', N''Napcard Slick Coat'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Coal Tar (Cold)'', N''Coal Tar (Cold)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''NAPGUARD 2502, Rough Coat, PCF Coating'', N''NAPGUARD 2502 - Rough Coat (22 MILS, 24 MILS Avg) and 3.75" of 190 PCF Coating'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''NAPGUARD 2500 Smooth Coat FBS'', N''NAPGUARD 2500 Smooth Coat FBS (22 MILS Min, 24 MILS Avg)'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''NAPGUARD 2501 FBE, Concrete Weight Coat'', N''NAPGUARD 2501 FBE, Concrete Weight Coat'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''21 MILS EPOXY COATING AND 2.75" 190 PCF'', N''21 MILS EPOXY COATING AND 2.75" 190 PCF CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''21 MILS MIN. EPOXY COATING,2.75" 190 PCF'', N''21 MILS MIN. EPOXY COATING AND 2.75" 190 PCF CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''21 MILS MIN. EPOXY COATING,2.90" 190 PCF'', N''21 MILS MIN. EPOXY COATING AND 2.90" 190 PCF CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''21 MILS EPOXY COATING AND 2.90" 190 PCF'', N''21 MILS EPOXY COATING AND 2.90" 190 PCF CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''16-18MILS FBE,2.5" of 190 PCF Coating'', N''16-18MILS FBE with 2.5" of 190 PCF Coating'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''w/FBE AND 2.50" CONCRETE COATING'', N''w/FBE AND 2.50" CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''18 MILS TFE(SMOOTHCOAT),1.75" OF 190 PCF'', N''18 MILS THIN FILM EPOXY (SMOOTHCOAT)/ 1.75" OF 190 PCF CONCRETE COATING'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Concrete Coating to 1.1 SG'', N''Concrete Coating to 1.1 SG'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Concrete Epoxy'', N''Concrete Epoxy'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Epoxy'', N''Epoxy'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''NAPGUARD 2502, Rough Coat, PCF Coating'', N''NAPGUARD 2502 - Rough Coat (22 MILS, 24 MILS Avg) and 4.00" of 190 PCF Coating'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''FBE'', N''FBE'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Tape Wrap'', N''Tape Wrap'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''AF - 7'', N''AF - 7'', NULL)
			INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), N''Update'', N''MyTestList Domain'', NULL)

			INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS Numeric(7, 0)), ''Coating'', ''CoatingLineDomainId'')';
			
            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        SELECT COUNT(*) INTO CNT
        FROM  DomainCatalog 
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coating Condition - Weld Type')
        AND NOT EXISTS (SELECT * FROM DomainCatalogColXRef 
                        WHERE TableName = 'CoatingCondition' AND ColumnName = 'CoatingCondWeldTypeLD');

        IF CNT <> 0
        THEN
            SELECT MAX(Id) INTO LastID FROM DomainCatalog;
            NextID := LastID + 1;

            sql_stmt := 'INSERT INTO DomainCatalog (Id,DomainDescr) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Coating Condition - Weld Type'')';
                
            EXECUTE IMMEDIATE sql_stmt;
                
            sql_stmt := 'INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''OTHER'', N''OTHER'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Unknown'', N''Unknown'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Poly Tape'', N''Poly Tape'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Coal Tar'', N''Coal Tar'', NULL);

            INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), ''CoatingCondition'', ''CoatingCondWeldTypeLD'')';
            
            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        SELECT COUNT(*) INTO CNT
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM  DomainCatalog WHERE DomainDescr = N'Coating Condition - Line Found')
        AND NOT EXISTS(SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CoatingCondition' 
                        AND ColumnName = 'CoatingCondLineFoundDomainId');
                    

        IF CNT <> 0
        THEN
            SELECT MAX(Id) INTO LastID FROM DomainCatalog;
            NextID := LastID + 1;

            sql_stmt := 'INSERT INTO DomainCatalog (Id,DomainDescr) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Coating Condition - Line Found'')';
            
            EXECUTE IMMEDIATE sql_stmt;
            
            sql_stmt := 'INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''OTHER'', N''OTHER'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Not Available'', N''Not Available'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Good'', N''Good'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Fair'', N''Fair'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Unknown'', N''Unknown'', NULL)
            INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), ''CoatingCondition'', ''CoatingCondLineFoundDomainId'')';
            
            EXECUTE IMMEDIATE sql_stmt;

        END IF;
                    
        SELECT COUNT(*) INTO CNT
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM  DomainCatalog WHERE DomainDescr = N'Coating Condition - Weld Found')
        AND NOT EXISTS(SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CoatingCondition' 
                        AND ColumnName = 'CoatingCondWeldFoundDomainId');

        IF CNT <> 0
        THEN
            SELECT MAX(Id) INTO LastID FROM DomainCatalog;
            NextID := LastID + 1;

            sql_stmt := 'INSERT INTO DomainCatalog (Id,DomainDescr) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Coating Condition - Weld Found'')';
            
            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'INSERT ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Unknown'', N''Unknown'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''OTHER'', N''OTHER'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Good'', N''Good'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Well Bonded'', N''Well Bonded'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Fair'', N''Fair'', NULL)

            INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), ''CoatingCondition'', ''CoatingCondWeldFoundDomainId'')';
        
            EXECUTE IMMEDIATE sql_stmt;
        END IF;
                    
        SELECT COUNT(*) INTO CNT
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM  DomainCatalog WHERE DomainDescr = N'Coating Condition - Application Type') 
        AND NOT EXISTS(SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CoatingCondition' 
                        AND ColumnName = 'CoatingCondApplicationTypeLD');
                    
        IF CNT <> 0
        THEN
            SELECT MAX(Id) INTO LastID FROM DomainCatalog;
            NextID := LastID + 1;

            sql_stmt := 'INSERT DomainCatalog (Id,DomainDescr) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Coating Condition - Application Type'')';
            
            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'INSERT ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Unknown'', N''Unknown'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''OTHER'', N''OTHER'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Hand'', N''Hand'', NULL)
            INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), N''Line'', N''Line'', NULL)

            INSERT INTO DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName) VALUES (CAST(' || CAST(NextID AS VARCHAR2) || ' AS NUMBER(7, 0)), ''CoatingCondition'', ''CoatingCondApplicationTypeLD'')';
            
            EXECUTE IMMEDIATE sql_stmt;

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
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640204 AND dbVersionCheckPoint = 1
    THEN
        -- This section removes the 'Enable' command from trigger definitions on SQL Server databases
        
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
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640204 AND dbVersionCheckPoint = 2
    THEN
       	/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 05
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640205', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 05';
        
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