--SET SERVEROUTPUT ON

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630106 AND dbVersionCheckPoint = 0
    THEN
        DECLARE 
            CNT INT;
            sqlStatement varchar(4000);
            
        BEGIN
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEM');

            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE ACTIONITEM(
                                    ID NUMBER(18, 0) NOT NULL,
                                    ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                    REVISION NUMBER(18, 0) NOT NULL,
                                    CATEGORYLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    STATUSLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    ASSIGNEDTO VARCHAR2(255) NULL,
                                    DUEDATE DATE NULL,
                                    REASON VARCHAR2(4000) NULL,
                                    THREATCONSEQUENCE VARCHAR2(255) NULL,
                                    ACTIONPERFORMED VARCHAR2(4000) NULL,
                                    COMPLETIONDATE DATE NULL,
                                    EFFECTIVEENDDATE DATE NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEM PRIMARY KEY (ID)
                                )';
            ELSE
                DECLARE
                    CURSOR drop_cons_cursor IS
                    SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                            ' DROP CONSTRAINT ' || fk_name  AS drop_constraint
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
                        AND ref.table_name = 'ACTIONITEM'
                        AND ref.column_name = 'ID' 
                        );

                        -- table variable to store table of ddl statements
                    TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
                    INDEX BY BINARY_INTEGER;
                    tmpListDomainForeignKeys DDL_TABLE_TYPE;

                    CNT NUMBER;
                    DDL VARCHAR2(5000);
                        counter BINARY_INTEGER := 0;

                BEGIN

                    -- Save table data in temp table
                    SELECT COUNT(*) INTO CNT
                    FROM user_tables
                    WHERE table_name = UPPER('tmpListDomain_Identity');

                    IF (CNT = 0)
                    THEN
                        EXECUTE IMMEDIATE q'[CREATE TABLE tmpListDomain_Identity
                                        AS SELECT * FROM ACTIONITEM
                                ]';
                    END IF;

                    -- Save commands to recreate foreign keys
                    EXECUTE IMMEDIATE q'[ SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
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
                                AND ref.table_name = 'ACTIONITEM'
                                AND ref.column_name = 'ID' 
                            )]'
                    BULK COLLECT INTO tmpListDomainForeignKeys;

                    --Drop foreign key constraints referencing table
                    FOR ddl IN drop_cons_cursor LOOP
                        EXECUTE IMMEDIATE ddl.drop_constraint ;   
                    END LOOP;

                    EXECUTE IMMEDIATE 'DROP TABLE ACTIONITEM';

                    --Recreate table
                    
                    EXECUTE IMMEDIATE 'CREATE TABLE ACTIONITEM(
                                    ID NUMBER(18, 0) NOT NULL,
                                    ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                    REVISION NUMBER(18, 0) NOT NULL,
                                    CATEGORYLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    STATUSLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    ASSIGNEDTO VARCHAR2(255) NULL,
                                    DUEDATE DATE NULL,
                                    REASON VARCHAR2(4000) NULL,
                                    THREATCONSEQUENCE VARCHAR2(255) NULL,
                                    ACTIONPERFORMED VARCHAR2(4000) NULL,
                                    COMPLETIONDATE DATE NULL,
                                    EFFECTIVEENDDATE DATE NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEM PRIMARY KEY (ID)
                                )';
                    

                    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM tmpListDomain_Identity' INTO CNT;

                    IF CNT > 0
                    THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ACTIONITEM SELECT * FROM tmpListDomain_Identity';
                    END IF;

                    --Add foreign keys referencing listdomain backup into tables
                    FOR i IN 1..tmpListDomainForeignKeys.COUNT LOOP
                        EXECUTE IMMEDIATE tmpListDomainForeignKeys(i);
                    END LOOP;
                END;
            END IF;
        
            SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_ACTIONITEM');
        
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE SEQUENCE S_ACTIONITEM';
        
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
        
            sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ACTIONITEM BEFORE INSERT
                                ON ACTIONITEM FOR EACH ROW
                                DECLARE
                                    INTEGRITY_ERROR  EXCEPTION;
                                    ERRNO            INTEGER;
                                    ERRMSG           CHAR(200);
                                    DUMMY            INTEGER;
                                    FOUND            BOOLEAN;
                                
                                BEGIN
                                    SELECT S_ACTIONITEM.NEXTVAL INTO :NEW.ID FROM DUAL;
                                
                                EXCEPTION
                                    WHEN INTEGRITY_ERROR THEN
                                        RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                                END;';
            EXECUTE IMMEDIATE sqlStatement;
            
            sqlStatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEM BEFORE UPDATE
                                    ON ACTIONITEM FOR EACH ROW
                                    BEGIN
                                        :NEW.LASTMODBYUSERID := USER;
                                        :NEW.LASTMODDATETIME := SYSDATE;
                                    END;';
            
            EXECUTE IMMEDIATE sqlStatement;
    
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMRANGE');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE ACTIONITEMRANGE(
                                        ID NUMBER(18, 0) NOT NULL,
                                        ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                        LINEID NUMBER(18, 0) NOT NULL,
                                        LINENAME VARCHAR2(100) NULL,
                                        BEGINMEASURE NUMBER(18, 5) NOT NULL,
                                        ENDMEASURE NUMBER(18, 5) NOT NULL,
                                        CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                        CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                        LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                        LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                        CONSTRAINT PK_ACTIONITEMRANGE PRIMARY KEY (ID)
                                    )';

                EXECUTE IMMEDIATE sqlStatement;

                sqlStatement := 'ALTER TABLE ACTIONITEMRANGE ADD CONSTRAINT FK_ACTIONITEMRANGE_ACTIONITEM FOREIGN KEY (ACTIONITEMID) REFERENCES ACTIONITEM(ID)';
                EXECUTE IMMEDIATE sqlStatement;
        
            END IF;
    
            SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_ACTIONITEMRANGE');
        
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE SEQUENCE S_ACTIONITEMRANGE';
                EXECUTE IMMEDIATE sqlStatement;

            END IF;

            sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ACTIONITEMRANGE BEFORE INSERT
                            ON ACTIONITEMRANGE FOR EACH ROW
                            DECLARE
                                INTEGRITY_ERROR  EXCEPTION;
                                ERRNO            INTEGER;
                                ERRMSG           CHAR(200);
                                DUMMY            INTEGER;
                                FOUND            BOOLEAN;
                            
                            BEGIN
                                SELECT S_ACTIONITEMRANGE.NEXTVAL INTO :NEW.ID FROM DUAL;
                            
                            EXCEPTION
                                WHEN INTEGRITY_ERROR THEN
                                    RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                            END;';

            EXECUTE IMMEDIATE sqlStatement;

            sqlStatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMRANGE BEFORE UPDATE
                            ON ACTIONITEMRANGE FOR EACH ROW
                            BEGIN
                                :NEW.LASTMODBYUSERID := USER;
                                :NEW.LASTMODDATETIME := SYSDATE;
                            END;';

            EXECUTE IMMEDIATE sqlStatement;

           SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION');
            
            IF CNT = 0 
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE ACTIONITEMREVISION(
                                    ID NUMBER(18, 0) NOT NULL,
                                    ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                    REVISION NUMBER(18, 0) NOT NULL,
                                    CATEGORYLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    STATUSLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    ASSIGNEDTO VARCHAR2(255) NULL,
                                    DUEDATE DATE NULL,
                                    REASON VARCHAR2(4000) NULL,
                                    THREATCONSEQUENCE VARCHAR2(255) NULL,
                                    ACTIONPERFORMED VARCHAR2(4000) NULL,
                                    COMPLETIONDATE DATE NULL,
                                    EFFECTIVEENDDATE DATE NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEMREVISION PRIMARY KEY (ID)
                                )';
            ELSE
                DECLARE
                    CURSOR drop_cons_cursor IS
                    SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                            ' DROP CONSTRAINT ' || fk_name  AS drop_constraint
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
                        AND ref.table_name = 'ACTIONITEMREVISION'
                        AND ref.column_name = 'ID' 
                        );

                        -- table variable to store table of ddl statements
                    TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
                    INDEX BY BINARY_INTEGER;
                    tmpListDomainForeignKeys DDL_TABLE_TYPE;

                    CNT NUMBER;
                    DDL VARCHAR2(5000);
                        counter BINARY_INTEGER := 0;

                BEGIN

                    -- Save table data in temp table
                    SELECT COUNT(*) INTO CNT
                    FROM user_tables
                    WHERE table_name = UPPER('tmpListDomain_Identity');

                    IF (CNT = 0)
                    THEN
                        EXECUTE IMMEDIATE q'[CREATE TABLE tmpListDomain_Identity
                                        AS SELECT * FROM ACTIONITEMREVISION
                                ]';
                    END IF;

                    -- Save commands to recreate foreign keys
                    EXECUTE IMMEDIATE q'[ SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
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
                                AND ref.table_name = 'ACTIONITEMREVISION'
                                AND ref.column_name = 'ID' 
                            )]'
                    BULK COLLECT INTO tmpListDomainForeignKeys;

                    --Drop foreign key constraints referencing table
                    FOR ddl IN drop_cons_cursor LOOP
                        EXECUTE IMMEDIATE ddl.drop_constraint ;   
                    END LOOP;

                    EXECUTE IMMEDIATE 'DROP TABLE ACTIONITEMREVISION';

                    --Recreate table
                   
                    EXECUTE IMMEDIATE 'CREATE TABLE ACTIONITEMREVISION(
                                    ID NUMBER(18, 0) NOT NULL,
                                    ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                    REVISION NUMBER(18, 0) NOT NULL,
                                    CATEGORYLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    STATUSLISTDOMAINID NUMBER(18, 0) NOT NULL,
                                    ASSIGNEDTO VARCHAR2(255) NULL,
                                    DUEDATE DATE NULL,
                                    REASON VARCHAR2(4000) NULL,
                                    THREATCONSEQUENCE VARCHAR2(255) NULL,
                                    ACTIONPERFORMED VARCHAR2(4000) NULL,
                                    COMPLETIONDATE DATE NULL,
                                    EFFECTIVEENDDATE DATE NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEMREVISION PRIMARY KEY (ID)
                                )';
                   

                    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM tmpListDomain_Identity' INTO CNT;

                    IF CNT > 0
                    THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ACTIONITEMREVISION SELECT * FROM tmpListDomain_Identity';
                    END IF;

                    --Add foreign keys referencing listdomain backup into tables
                    FOR i IN 1..tmpListDomainForeignKeys.COUNT LOOP
                        EXECUTE IMMEDIATE tmpListDomainForeignKeys(i);
                    END LOOP;
                END;

            END IF;

            sqlStatement := 'ALTER TABLE ACTIONITEMREVISION ADD CONSTRAINT FK_ACTIONITEMREV_ACTIONITEM FOREIGN KEY (ACTIONITEMID) REFERENCES ACTIONITEM(ID)';

            EXECUTE IMMEDIATE sqlStatement;
            
            SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_ACTIONITEMREVISION');
        
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE SEQUENCE S_ACTIONITEMREVISION';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ACTIONITEMREVISION BEFORE INSERT
                            ON ACTIONITEMREVISION FOR EACH ROW
                            DECLARE
                                INTEGRITY_ERROR  EXCEPTION;
                                ERRNO            INTEGER;
                                ERRMSG           CHAR(200);
                                DUMMY            INTEGER;
                                FOUND            BOOLEAN;
                            
                            BEGIN
                                SELECT S_ACTIONITEMREVISION.NEXTVAL INTO :NEW.ID FROM DUAL;
                            
                            EXCEPTION
                                WHEN INTEGRITY_ERROR THEN
                                    RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                            END;';

            EXECUTE IMMEDIATE sqlStatement;

            sqlstatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMREVISION BEFORE UPDATE
                        ON ACTIONITEMREVISION FOR EACH ROW
                        BEGIN
                            :NEW.LASTMODBYUSERID := USER;
                            :NEW.LASTMODDATETIME := SYSDATE;
                        END;';
            
            EXECUTE IMMEDIATE sqlStatement;
        
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMCOMMENTS');
            
            IF CNT = 0
            THEN
                sqlstatement := 'CREATE TABLE ACTIONITEMCOMMENTS(
                                        ID NUMBER(18, 0) NOT NULL,
                                        ACTIONITEMID NUMBER(18, 0) NOT NULL,
                                        COMMENTS VARCHAR2(4000) NULL,
                                        CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                        CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                        LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                        LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                        CONSTRAINT PK_ACTIONITEMCOMMENTS PRIMARY KEY (ID)
                                    )';
                EXECUTE IMMEDIATE sqlStatement;

                sqlstatement := 'ALTER TABLE ACTIONITEMCOMMENTS ADD CONSTRAINT FK_ACTIONITEMCOMMT_ACTIONITEM FOREIGN KEY (ACTIONITEMID) REFERENCES ACTIONITEM(ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_ACTIONITEMCOMMENTS');
        
            IF CNT = 0
            THEN
                sqlstatement := 'CREATE SEQUENCE S_ACTIONITEMCOMMENTS';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ACTIONITEMCOMMENTS BEFORE INSERT
                                ON ACTIONITEMCOMMENTS FOR EACH ROW
                                DECLARE
                                    INTEGRITY_ERROR  EXCEPTION;
                                    ERRNO            INTEGER;
                                    ERRMSG           CHAR(200);
                                    DUMMY            INTEGER;
                                    FOUND            BOOLEAN;
                                
                                BEGIN
                                    --  COLUMN ID USES SEQUENCE S_ACTIONITEMCOMMENTS
                                    SELECT S_ACTIONITEMCOMMENTS.NEXTVAL INTO :NEW.ID FROM DUAL;
                                
                                --  ERRORS HANDLING
                                EXCEPTION
                                    WHEN INTEGRITY_ERROR THEN
                                        RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                                END;';
            EXECUTE IMMEDIATE sqlStatement;
            
            sqlstatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMCOMMENTS BEFORE UPDATE
                        ON ACTIONITEMCOMMENTS FOR EACH ROW
                        BEGIN
                            :NEW.LASTMODBYUSERID := USER;
                            :NEW.LASTMODDATETIME := SYSDATE;
                        END;';
            EXECUTE IMMEDIATE sqlStatement;

            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMPROPERTY');
            
            IF CNT = 0
            THEN
                sqlstatement := 'CREATE TABLE ACTIONITEMPROPERTY(
                                    ID NUMBER(18, 0) NOT NULL,
                                    NAME VARCHAR2(255) NOT NULL,
                                    DISPLAYNAME VARCHAR2(255) NOT NULL,
                                    PROPERTYTYPE NUMBER(3, 0) NOT NULL,
                                    ISREQUIRED NUMBER(1, 0) NULL,
                                    ISREADONLY NUMBER(1, 0) NULL,
                                    EFFECTIVEENDDATE DATE NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEMPROPERTY PRIMARY KEY (ID) 
                                    )';
                EXECUTE IMMEDIATE sqlStatement;

            END IF;
        
            SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_ACTIONITEMPROPERTY');
        
            IF CNT = 0
            THEN
                sqlstatement := 'CREATE SEQUENCE S_ACTIONITEMPROPERTY';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ACTIONITEMPROPERTY BEFORE INSERT
                                ON ACTIONITEMPROPERTY FOR EACH ROW
                                DECLARE
                                    INTEGRITY_ERROR  EXCEPTION;
                                    ERRNO            INTEGER;
                                    ERRMSG           CHAR(200);
                                    DUMMY            INTEGER;
                                    FOUND            BOOLEAN;
                                
                                BEGIN
                                    --  COLUMN ID USES SEQUENCE S_ACTIONITEMPROPERTY
                                    SELECT S_ACTIONITEMPROPERTY.NEXTVAL INTO :NEW.ID FROM DUAL;
                                
                                --  ERRORS HANDLING
                                EXCEPTION
                                    WHEN INTEGRITY_ERROR THEN
                                        RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                                END;';
            EXECUTE IMMEDIATE sqlStatement;
            
            sqlstatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMPROPERTY BEFORE UPDATE
                        ON ACTIONITEMPROPERTY FOR EACH ROW
                        BEGIN
                            :NEW.LASTMODBYUSERID := USER;
                            :NEW.LASTMODDATETIME := SYSDATE;
                        END;';
            EXECUTE IMMEDIATE sqlStatement;

            select COUNT(*) INTO CNT from user_constraints
            where constraint_type = 'U' AND upper(Constraint_Name) = upper('UQ_ACTIONITEMPROPERTY_NAME');
            
            IF CNT = 0
            THEN
                sqlstatement := 'ALTER TABLE ACTIONITEMPROPERTY
                                    ADD CONSTRAINT UQ_ACTIONITEMPROPERTY_NAME UNIQUE (NAME)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMPROPERTYVALUE');
            
            IF CNT = 0
            THEN
                sqlstatement := 'CREATE TABLE ACTIONITEMPROPERTYVALUE(
                                    ACTIONITEMREVISIONID NUMBER(18, 0) NOT NULL,
                                    ACTIONITEMPROPERTYID NUMBER(18, 0) NOT NULL,
                                    PROPERTYVALUE VARCHAR2(4000) NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEMPROPERTYVALUE PRIMARY KEY (ACTIONITEMREVISIONID, ACTIONITEMPROPERTYID) 
                                    )';
                EXECUTE IMMEDIATE sqlStatement;

            END IF;
            
            sqlstatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMPROPERTYVALUE BEFORE UPDATE
                        ON ACTIONITEMPROPERTYVALUE FOR EACH ROW
                        BEGIN
                            :NEW.LASTMODBYUSERID := USER;
                            :NEW.LASTMODDATETIME := SYSDATE;
                        END;';
            EXECUTE IMMEDIATE sqlStatement;

            select COUNT(*) INTO CNT from user_constraints
            where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ATNITMPRPVALUE_ACTNITMRVSN');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMPROPERTYVALUE ADD CONSTRAINT FK_ATNITMPRPVALUE_ACTNITMRVSN FOREIGN KEY (ACTIONITEMREVISIONID) REFERENCES ACTIONITEMREVISION(ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            select COUNT(*) INTO CNT from user_constraints
            where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ATNITMPRPVALUE_ACTNITMPRP');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMPROPERTYVALUE ADD CONSTRAINT FK_ATNITMPRPVALUE_ACTNITMPRP FOREIGN KEY (ACTIONITEMPROPERTYID) REFERENCES ACTIONITEMPROPERTY(ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ActionItemPropDCXRef');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE ACTIONITEMPROPDCXREF(
                                    ACTIONITEMPROPERTYID NUMBER(18, 0) NOT NULL,
                                    DOMAINCATALOGID NUMBER(7, 0) NOT NULL,
                                    CREATEBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    CREATEDATE DATE DEFAULT SYSDATE NOT NULL,
                                    LASTMODBYUSERID VARCHAR2(64) DEFAULT USER NOT NULL,
                                    LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                    CONSTRAINT PK_ACTIONITEMPROPDCXREF PRIMARY KEY(ACTIONITEMPROPERTYID,DOMAINCATALOGID)
                                    )';
                                    
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            select COUNT(*) INTO CNT from user_constraints
            where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ATNITMPROPDCXREF_DMNCTLG');
        
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMPROPDCXREF ADD CONSTRAINT FK_ATNITMPROPDCXREF_DMNCTLG FOREIGN KEY (DOMAINCATALOGID) REFERENCES DOMAINCATALOG(ID)';
            
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            select COUNT(*) INTO CNT from user_constraints
            where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ATNITMPROPDCXREF_ATNITMPRP');
        
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMPROPDCXREF ADD CONSTRAINT FK_ATNITMPROPDCXREF_ATNITMPRP FOREIGN KEY (ACTIONITEMPROPERTYID) REFERENCES ACTIONITEMPROPERTY(ID)';
            
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            sqlstatement := 'CREATE OR REPLACE TRIGGER TU_ACTIONITEMPROPDCXREF BEFORE UPDATE
                        ON ACTIONITEMPROPDCXREF FOR EACH ROW
                        BEGIN
                            :NEW.LASTMODBYUSERID := USER;
                            :NEW.LASTMODDATETIME := SYSDATE;
                        END;';
            EXECUTE IMMEDIATE sqlStatement;

            -- Setup the custom action item properties.
            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'CategoryLd', 'Category', 5 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('CategoryLd'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'StatusLd', 'Status', 5 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('StatusLd'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'AssignedTo', 'Assigned  To', 0 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('AssignedTo'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'Reason', 'Reason', 1 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('Reason'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'ThreatConsequence', 'Threat/Consequence', 0 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('ThreatConsequence'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'ActionPerformed', 'Action Performed', 1 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('ActionPerformed'))]';

            EXECUTE IMMEDIATE q'[INSERT INTO ActionItemProperty
            (Name, DisplayName, PropertyType)
            SELECT 'ProjectRunDate', 'Project Run Date', 2 FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM ActionItemProperty WHERE upper(Name) = upper('ProjectRunDate'))]';


            -- Temporary add the obsolete columns in the previous version to allow this script to run multiple time. 
            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('CATEGORYLISTDOMAINID');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD CATEGORYLISTDOMAINID NUMBER(18, 0)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('STATUSLISTDOMAINID');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD STATUSLISTDOMAINID NUMBER(18, 0)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('ASSIGNEDTO');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD ASSIGNEDTO VARCHAR2(1)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('REASON');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD REASON VARCHAR2(1)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('THREATCONSEQUENCE');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD THREATCONSEQUENCE VARCHAR2(1)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('ACTIONPERFORMED');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
                                ADD ACTIONPERFORMED VARCHAR2(1)';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEM') AND UPPER(COLUMN_NAME) = UPPER('PROJECTRUNDATE');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ACTIONITEM
                                ADD PROJECTRUNDATE DATE';
                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                
        END;

        UPDATE VersionInfo SET DBVersionCheckPoint = 1;
        
    END IF;	
EXCEPTION
    when others then
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
    DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);
    stmt NVARCHAR2(1000);
    CNT NUMBER;

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

        IF dbVersion = 630106 AND dbVersionCheckPoint = 1
        THEN
            -- Migrate the existing data to the new tables.
			DECLARE PropertyId NUMBER (18, 0);
            
            BEGIN
                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE UPPER(Name) = UPPER('CategoryLd')]'
                INTO PropertyId;
            
                SELECT COUNT(*) INTO CNT FROM user_tab_columns 
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'CategoryListDomainId';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' ||  PropertyId || ', CategoryListDomainId
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;
                
                EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropDCXRef
                (ActionItemPropertyId, DomainCatalogId)
                SELECT ' || PropertyId || ', dc.Id
                FROM DomainCatalog dc
                WHERE dc.DomainDescr = ''Action Item Category''
                AND NOT EXISTS (SELECT 1 FROM ActionItemPropDCXRef WHERE ActionItemPropertyId = ' || PropertyId || ')';

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE UPPER(Name) = UPPER('StatusLd')]'
                INTO PropertyId;

                SELECT COUNT(*) INTO CNT FROM user_tab_columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'StatusListDomainId';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' || PropertyId || ', StatusListDomainId
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;

                EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropDCXRef
                (ActionItemPropertyId, DomainCatalogId)
                SELECT ' || PropertyId || ', dc.Id
                FROM DomainCatalog dc
                WHERE dc.DomainDescr = ''Action Item Status''
                AND NOT EXISTS (SELECT 1 FROM ActionItemPropDCXRef WHERE ActionItemPropertyId = ' || PropertyId || ')';

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE Name = 'AssignedTo']'
                INTO PropertyId;

                SELECT COUNT(*) INTO CNT FROM user_tab_columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'AssignedTo';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' || PropertyId || ', AssignedTo
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE Name = 'Reason']'
                INTO PropertyId;
                
                SELECT COUNT(*) INTO CNT FROM user_tab_columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'Reason';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' || PropertyId || ', Reason
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE Name = 'ThreatConsequence']'
                INTO PropertyId;
               
                SELECT COUNT(*) INTO CNT FROM user_tab_columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'ThreatConsequence';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' || PropertyId || ', ThreatConsequence
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM Act`ionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE Name = 'ActionPerformed']'
                INTO PropertyId;

                SELECT COUNT(*) INTO CNT FROM user_tab_columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'ActionPerformed';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT Id, ' || PropertyId || ', ActionPerformed
                    FROM ActionItemRevision
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;

                EXECUTE IMMEDIATE q'[SELECT Id FROM ActionItemProperty WHERE Name = 'ProjectRunDate']'
                INTO PropertyId;

                SELECT COUNT(*) INTO CNT FROM User_Tab_Columns
                WHERE table_name = 'ActionItemRevision'
                AND column_name = 'ProjectRunDate';

                IF CNT > 0
                THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ActionItemPropertyValue
                    (ActionItemRevisionId, ActionItemPropertyId, PropertyValue)
                    SELECT ar.Id, ' || PropertyId || ', a.ProjectRunDate
                    FROM ActionItemRevision ar
                    INNER JOIN ActionItem a
                    ON ar.ActionItemId = a.Id
                    WHERE NOT EXISTS (SELECT 1 FROM ActionItemPropertyValue WHERE ActionItemRevisionId = ar.Id AND ActionItemPropertyId = ' || PropertyId || ')';
                END IF;
            END;             

			-- -- Drop the obsolete columns.
			DECLARE CNT INT;
			sqlStatement varchar(4000);
			BEGIN
				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEM') AND UPPER(COLUMN_NAME) = UPPER('PROJECTRUNDATE');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEM
									DROP COLUMN PROJECTRUNDATE';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;
				
				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('CATEGORYLISTDOMAINID');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN CATEGORYLISTDOMAINID';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;
				
				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('STATUSLISTDOMAINID');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN STATUSLISTDOMAINID';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;

				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('ASSIGNEDTO');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN ASSIGNEDTO';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;

				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('REASON');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN REASON';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;

				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('THREATCONSEQUENCE');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN THREATCONSEQUENCE';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;

				SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('ACTIONITEMREVISION') AND UPPER(COLUMN_NAME) = UPPER('ACTIONPERFORMED');
				
				IF CNT > 0
				THEN
					sqlStatement := 'ALTER TABLE ACTIONITEMREVISION
									DROP COLUMN ACTIONPERFORMED';
					
					EXECUTE IMMEDIATE sqlStatement;
				END IF;
			END;
            UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            COMMIT;
            
       END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 2
        THEN
			declare C8Trigger VARCHAR2(2000);
			CURSOR c_cursor IS
				select table_name from user_tables where upper(table_name) NOT IN ('CPRANGE','IDALLOCATION','CROSSINGLOCNMAY8','TMPVIRTUALTABLESTATIONING','RISKRESULTSRAWDATA','RISKRESULTSRAWDATA1','TESTDATA1','JOINT2010','JOINT','METRICFULLSYSTEMDEFAULTSU','FOREIGNKEYS','PRIMARYKEYS')
				AND upper(table_name) not like 'LOAD%'
				AND upper(table_name) not like '_%'
                AND upper(table_name) NOT IN (select upper(TABLE_NAME) from user_triggers WHERE triggering_event = 'UPDATE')
				AND upper(table_name) IN (SELECT Table_Name From User_Tab_Columns where upper(Column_Name) = upper('LASTMODBYUSERID'));

			MyTableName c_cursor%ROWTYPE;

			BEGIN
				OPEN c_cursor;
				
					LOOP
						FETCH  c_cursor  INTO MyTableName;
						EXIT WHEN c_cursor%NOTFOUND;

								C8Trigger :='CREATE OR REPLACE TRIGGER TU_' || MyTableName.table_name || ' BEFORE UPDATE
													ON ' || MyTableName.table_name || ' FOR EACH ROW
													BEGIN
														:NEW.LASTMODBYUSERID := USER;
														:NEW.LASTMODDATETIME := SYSDATE;
													END;';
								 
								EXECUTE IMMEDIATE C8Trigger;
					END LOOP;
				CLOSE c_cursor;
			END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 3
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(8000);
                catalogId INT;
    
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONAXIALSTRAIN');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE INLINEINSPECTIONAXIALSTRAIN
                                           (
                                                  ID NUMBER(10, 0) NOT NULL,
                                                  EFFECTIVESTARTDATE DATE NULL,
                                                  EFFECTIVEENDDATE DATE NULL,
                                                  INLINEINSPECTIONID NUMBER(10, 0) NULL,
                                                  INLINEINSPECTIONRANGEID NUMBER(10, 0) NOT NULL,
                                                  SOURCEID VARCHAR2(50) NULL,
                                                  STATIONSERIESID NUMBER(10, 0) NULL,
                                                  STATIONNUM NUMBER(13, 5) NULL,
                                                  BEGINSTATIONSERIESID NUMBER(10, 0) NULL,
                                                  BEGINSTATIONNUM NUMBER(13, 5) NULL,
                                                  ENDSTATIONSERIESID NUMBER(10, 0) NULL,
                                                  ENDSTATIONNUM NUMBER(13, 5) NULL,
                                                  ILIASFEATUREIDENTIFIER VARCHAR2(15) NULL,
                                                  ILIASODOMETER NUMBER(10,3) NULL,
                                                  ILIASSENSORP1STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP2STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP3STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP4STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP5STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP6STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP7STRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP8STRAIN NUMBER(7,3) NULL,
                                                  ILIASAXIALSTRAIN NUMBER(7,3) NULL,
                                                  ILIASSENSORP1ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP2ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP3ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP4ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP5ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP6ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP7ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASSENSORP8ORIENTATION NUMBER(6,3) NULL,
                                                  ILIASAREAOFINTEREST CHAR(1) NULL,
                                                  ILIASANALYSISDOMAINID NUMBER(7,0) NULL,
                                                  ILIASCOMMENTS VARCHAR2(255) NULL,
                                                  ILIASX NUMBER(12,3) NULL,
                                                  ILIASY NUMBER(12,3) NULL,
                                                  ILIASZ NUMBER(10,3) NULL,
                                                  ILIASLATITUDE NUMBER(12,9) NULL,
                                                  ILIASLONGITUDE NUMBER(12,9) NULL,
                                                  ILIASGIRTHWELDNUM VARCHAR2(25) NULL,
                                                  ILIASDISTANCEFROMGIRTHWELD NUMBER(10, 3) NULL,
                                                  ILIASGIRTHWELDNUMDS VARCHAR2(25) NULL,
                                                  ILIASDISTANCEFROMGIRTHWELDDS NUMBER(10, 3) NULL,
                                                  IRASCUSTOMDATE1 DATE NULL,
                                                  IRASCUSTOMDATE2 DATE NULL,
                                                  IRASCUSTOMDATE3 DATE NULL,
                                                  IRASCUSTOMDATE4 DATE NULL,
                                                  IRASCUSTOMDATE5 DATE NULL,
                                                  IRASCUSTOMNUM1 FLOAT NULL,
                                                  IRASCUSTOMNUM2 FLOAT NULL,
                                                  IRASCUSTOMNUM3 FLOAT NULL,
                                                  IRASCUSTOMNUM4 FLOAT NULL,
                                                  IRASCUSTOMNUM5 FLOAT NULL,
                                                  IRASCUSTOMSTRING1 VARCHAR2(255) NULL,
                                                  IRASCUSTOMSTRING2 VARCHAR2(255) NULL,
                                                  IRASCUSTOMSTRING3 VARCHAR2(255) NULL,
                                                  IRASCUSTOMSTRING4 VARCHAR2(255) NULL,
                                                  IRASCUSTOMSTRING5 VARCHAR2(255) NULL,
                                                  CREATEDUSER VARCHAR2(45) DEFAULT USER NOT NULL,
                                                  CREATEDDATE DATE DEFAULT SYSDATE NOT NULL,
                                                  LASTMODBYUSERID VARCHAR2(45) DEFAULT USER NOT NULL,
                                                  LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                                  CONSTRAINT PK_INLINEINSPECTIONAXIALSTRAIN PRIMARY KEY(ID)
                                           )';
                                           
                        EXECUTE IMMEDIATE sqlStatement;                                       
                    END IF;
    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ILIASINLINEINSPECTIONID');
        
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INLINEINSPECTIONAXIALSTRAIN ADD CONSTRAINT FK_ILIASINLINEINSPECTIONID FOREIGN KEY (INLINEINSPECTIONID) REFERENCES INLINEINSPECTION(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
        
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ILIASInlineInspectionRngId');
        
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INLINEINSPECTIONAXIALSTRAIN ADD CONSTRAINT FK_ILIASINLINEINSPECTIONRNGID FOREIGN KEY (INLINEINSPECTIONRANGEID) REFERENCES INLINEINSPECTIONRANGE(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
        
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ILIASAnalysisDomainId');
        
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INLINEINSPECTIONAXIALSTRAIN ADD CONSTRAINT FK_ILIASANALYSISDOMAINID FOREIGN KEY (ILIASANALYSISDOMAINID) REFERENCES LISTDOMAIN (ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
        
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ILIASBeginStationSeriesId');
        
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INLINEINSPECTIONAXIALSTRAIN ADD CONSTRAINT FK_ILIASBEGINSTATIONSERIESID FOREIGN KEY (BEGINSTATIONSERIESID) REFERENCES STATIONSERIES(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
        
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_ILIASEndStationSeriesId');
        
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INLINEINSPECTIONAXIALSTRAIN ADD CONSTRAINT FK_ILIASENDSTATIONSERIESID FOREIGN KEY (ENDSTATIONSERIESID) REFERENCES STATIONSERIES(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIAXIALSTRAIN');
                                    
                    IF CNT = 0
                    THEN
                        sqlstatement := 'CREATE TABLE STG_ILIAXIALSTRAIN
                                        (
                                                ID NUMBER(10, 0) NOT NULL,
                                                EFFECTIVESTARTDATE DATE NULL,
                                                EFFECTIVEENDDATE DATE NULL,
                                                STG_ILIID NUMBER(10, 0) NULL,
                                                STG_ILIRANGEID NUMBER(10, 0) NULL,
                                                STATIONSERIESID NUMBER(10, 0) NULL,
                                                STATIONNUM NUMBER(13, 5) NULL,
                                                BEGINSTATIONSERIESID NUMBER(10, 0) NULL,
                                                BEGINSTATIONNUM NUMBER(13, 5) NULL,
                                                ENDSTATIONSERIESID NUMBER(10, 0) NULL,
                                                ENDSTATIONNUM NUMBER(13, 5) NULL,
                                                ILIASFEATUREIDENTIFIER VARCHAR2(15) NULL,
                                                ILIASODOMETER NUMBER(10,3) NULL,
                                                ILIASSENSORP1STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP2STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP3STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP4STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP5STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP6STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP7STRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP8STRAIN NUMBER(7,3) NULL,
                                                ILIASAXIALSTRAIN NUMBER(7,3) NULL,
                                                ILIASSENSORP1ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP2ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP3ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP4ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP5ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP6ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP7ORIENTATION NUMBER(6,3) NULL,
                                                ILIASSENSORP8ORIENTATION NUMBER(6,3) NULL,
                                                ILIASAREAOFINTEREST VARCHAR2(1) NULL,
                                                ILIASANALYSISDOMAINID NUMBER(7,0) NULL,
                                                ILIASCOMMENTS VARCHAR2(255) NULL,
                                                ILIASX NUMBER(12,3) NULL,
                                                ILIASY NUMBER(12,3) NULL,
                                                ILIASZ NUMBER(10,3) NULL,
                                                ILIASLATITUDE NUMBER(12,9) NULL,
                                                ILIASLONGITUDE NUMBER(12,9) NULL,
                                                ILIASGIRTHWELDNUM VARCHAR2(25) NULL,
                                                ILIASDISTANCEFROMGIRTHWELD NUMBER(10, 3) NULL,
                                                ILIASGIRTHWELDNUMDS VARCHAR2(25) NULL,
                                                ILIASDISTANCEFROMGIRTHWELDDS NUMBER(10, 3) NULL,
                                                IRASCUSTOMDATE1 DATE NULL,
                                                IRASCUSTOMDATE2 DATE NULL,
                                                IRASCUSTOMDATE3 DATE NULL,
                                                IRASCUSTOMDATE4 DATE NULL,
                                                IRASCUSTOMDATE5 DATE NULL,
                                                IRASCUSTOMNUM1 FLOAT NULL,
                                                IRASCUSTOMNUM2 FLOAT NULL,
                                                IRASCUSTOMNUM3 FLOAT NULL,
                                                IRASCUSTOMNUM4 FLOAT NULL,
                                                IRASCUSTOMNUM5 FLOAT NULL,
                                                IRASCUSTOMSTRING1 VARCHAR2(255) NULL,
                                                IRASCUSTOMSTRING2 VARCHAR2(255) NULL,
                                                IRASCUSTOMSTRING3 VARCHAR2(255) NULL,
                                                IRASCUSTOMSTRING4 VARCHAR2(255) NULL,
                                                IRASCUSTOMSTRING5 VARCHAR2(255) NULL,
                                                CREATEDUSER VARCHAR2(45) DEFAULT USER NOT NULL,
                                                CREATEDDATE DATE DEFAULT SYSDATE NOT NULL,
                                                LASTMODBYUSERID VARCHAR2(45) DEFAULT USER NOT NULL,
                                                LASTMODDATETIME DATE DEFAULT SYSDATE NOT NULL,
                                                CONSTRAINT PK_STG_ILIAXIALSTRAIN PRIMARY KEY(ID)
                                        )';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_STG_ILIASSTG_ILIID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIAXIALSTRAIN ADD CONSTRAINT FK_STG_ILIASSTG_ILIID FOREIGN KEY (STG_ILIID) REFERENCES STG_ILI(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_STG_ILIASSTG_ILIRANGEID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIAXIALSTRAIN ADD CONSTRAINT FK_STG_ILIASSTG_ILIRANGEID FOREIGN KEY (STG_ILIRANGEID) REFERENCES STG_ILIRANGE(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_STG_ILIASANALYSISDOMAINID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIAXIALSTRAIN ADD CONSTRAINT FK_STG_ILIASANALYSISDOMAINID FOREIGN KEY (ILIASANALYSISDOMAINID) REFERENCES LISTDOMAIN (ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_STG_ILIASBEGSTATIONSERIESID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIAXIALSTRAIN ADD CONSTRAINT FK_STG_ILIASBEGSTATIONSERIESID FOREIGN KEY (BEGINSTATIONSERIESID) REFERENCES STATIONSERIES(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_constraints
                    where constraint_type = 'R' AND upper(Constraint_Name) = upper('FK_STG_ILIASENDSTATIONSERIESID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIAXIALSTRAIN ADD CONSTRAINT FK_STG_ILIASENDSTATIONSERIESID FOREIGN KEY (ENDSTATIONSERIESID) REFERENCES STATIONSERIES(ID)';
                    
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    sqlstatement := 'CREATE OR REPLACE TRIGGER TU_INLINEINSPECTIONAXIALSTRAIN BEFORE UPDATE
                                ON INLINEINSPECTIONAXIALSTRAIN FOR EACH ROW
                                BEGIN
                                    :NEW.LASTMODBYUSERID := USER;
                                    :NEW.LASTMODDATETIME := SYSDATE;
                                END;';
                                
                    EXECUTE IMMEDIATE sqlStatement;
                    
                    sqlstatement := 'CREATE OR REPLACE TRIGGER TU_STG_ILIAXIALSTRAIN BEFORE UPDATE
                                ON STG_ILIAXIALSTRAIN FOR EACH ROW
                                BEGIN
                                    :NEW.LASTMODBYUSERID := USER;
                                    :NEW.LASTMODDATETIME := SYSDATE;
                                END;';
                                
                    EXECUTE IMMEDIATE sqlStatement;                
    
                    -- Setup the Listdomain catelog for the Axial Strain Available Analysis Type Domain ids
        
                    SELECT count(*) INTO CNT FROM DomainCatalog Where DomainDescr = 'Axial Strain Available Analysis Type';
        
                    IF CNT = 0
                    THEN
                        SELECT (MAX(Id)+1) INTO catalogId FROM DomainCatalog;
                        
                        INSERT INTO DomainCatalog ( Id , DomainDescr ) VALUES (catalogId, 'Axial Strain Available Analysis Type' );
                        INSERT INTO DomainCatalogColXRef ( DomainCatalogId , TableName , ColumnName) VALUES (catalogId, 'InlineInspectionAxialStrain', 'ILIASAnalysisDomainId' );
                        INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), catalogId, 'N/A', 'Not Applicable');
                        INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), catalogId, 'Reported', 'Reported');
                    END IF;
                    
                END;
                
                UPDATE VersionInfo SET DBVersionCheckPoint = 4;
                COMMIT;
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);         
    END;
END;
/



BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 4
        THEN
            BEGIN
                -- CLIENT_SystemPreferences_InsertTableCheckerSystemOfMeasure_BL32240.sql
                /*
                    New record to be inserted in the SystemPreferences table of the STAGE DATABASE
                */
                -- Add table checker system of measure record to SystemPreferences table
                DECLARE CNT INT;
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM SystemPreferences WHERE ParameterName = 'TableChecker_SystemOfMeasure';
                    
                    IF CNT = 0
                    THEN
                        INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
                        VALUES ('TableChecker_SystemOfMeasure', 'Metric', null);
                    END IF;
                END;
                
                UPDATE VersionInfo SET DBVersionCheckPoint = 5;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

SET SERVEROUTPUT ON;

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER;

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 5
        THEN
            BEGIN
                DECLARE 
                TableName VARCHAR2(128);
                OldColumnName VARCHAR2(128);
                NewColumnName VARCHAR2(128);
                sqlStatement varchar2(1000);

                CURSOR c_cursor IS
                    select Table_Name from user_tab_columns where upper(column_name) = upper('CREATEBYUSERID');
    
                CURSOR d_cursor IS
                    select Table_Name from user_tab_columns where upper(column_name) = upper('CREATEDATE');
    
                CURSOR d2_cursor IS
                    select Table_Name from user_tab_columns where upper(column_name) = upper('CREATEDATETIME');
                
                BEGIN
                    OldColumnName := 'CREATEBYUSERID'; 
                    NewColumnName := 'CREATEDUSER'; 
                    
                    OPEN c_cursor;
                    
                        LOOP
                            FETCH  c_cursor  INTO TableName;
                            EXIT WHEN c_cursor%NOTFOUND;
    
                           sqlStatement := 'ALTER TABLE ' || TableName || ' RENAME COLUMN ' || OldColumnName || ' TO ' || NewColumnName;
                        
                            --DBMS_OUTPUT.PUT_LINE(sqlStatement);
                            
                            EXECUTE IMMEDIATE sqlStatement;
                        END LOOP;
                    CLOSE c_cursor;
    
                    OldColumnName := 'CREATEDATE'; 
                    NewColumnName := 'CREATEDDATE'; 
                    
                    OPEN d_cursor;
                    
                        LOOP
                            FETCH  d_cursor  INTO TableName;
                            EXIT WHEN d_cursor%NOTFOUND;
    
                            SELECT COUNT(*) INTO CNT FROM user_tab_columns
                            WHERE table_name = TableName
                            AND column_name = OldColumnName;

                            IF CNT > 0
                            THEN
                                sqlStatement := 'ALTER TABLE ' || TableName || ' RENAME COLUMN ' || OldColumnName || ' TO ' || NewColumnName;
                                --DBMS_OUTPUT.PUT_LINE (sqlStatement);
                                --EXECUTE IMMEDIATE sqlStatement;
                            END IF;           
                        END LOOP;
                    CLOSE d_cursor;
    
                    OldColumnName := 'CREATEDATETIME'; 
                    NewColumnName := 'CREATEDDATE'; 
                    
                    OPEN d2_cursor;
                    
                        LOOP
                            FETCH  d2_cursor  INTO TableName;
                            EXIT WHEN d2_cursor%NOTFOUND;
    
                            SELECT COUNT(*) INTO CNT FROM user_tab_columns
                            WHERE table_name = TableName
                            AND column_name = OldColumnName;   

                            IF CNT > 0 
                            THEN 
                                SELECT COUNT(*) INTO CNT FROM User_Tab_Columns
                                WHERE table_name = TableName
                                AND column_name = NewColumnName;

                                IF CNT = 0
                                THEN 
                                    sqlStatement := 'ALTER TABLE ' || TableName || ' RENAME COLUMN ' || OldColumnName || ' TO ' || NewColumnName;
                                    --DBMS_OUTPUT.PUT_LINE(sqlStatement);
                                    EXECUTE IMMEDIATE sqlStatement;
                                ELSE
                                    EXECUTE IMMEDIATE 'ALTER TABLE ' || TableName || ' DROP COLUMN ' || OldColumnName;
                                END IF;
                            END IF;
                        END LOOP;
                    CLOSE d2_cursor;
    
                END;
                
                UPDATE VersionInfo SET DBVersionCheckPoint = 6;
                COMMIT;
           END; 
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 6
        THEN
            BEGIN
                declare CNT INT;
                sqlStatement varchar2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BeginStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION ADD BEGINSTATIONSERIESID NUMBER(10, 0) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BeginStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION ADD BEGINSTATIONNUM NUMBER(13, 5) NOT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('EndStationSeriesId');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION ADD ENDSTATIONSERIESID NUMBER(10, 0) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('EndStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION ADD ENDSTATIONNUM NUMBER(13, 5) NOT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('EffectiveStartDate') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY EFFECTIVESTARTDATE DATE NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('EffectiveEndDate') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY EFFECTIVEENDDATE DATE NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeID') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLEID VARCHAR2(60) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeRepairInd') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLEREPAIRIND CHAR(1) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeFoundCoatCondDomainID') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLEFOUNDCOATCONDDOMAINID NUMBER(7,0) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeDamageTypeDomainID') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLEDAMAGETYPEDOMAINID NUMBER(7,0) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeExposedPipeLength') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLEEXPOSEDPIPELENGTH NUMBER(10,3) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('BellholeComment') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY BELLHOLECOMMENT VARCHAR2(255) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('StationSeriesId') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY STATIONSERIESID NUMBER(10, 0) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('StationNum') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY STATIONNUM NUMBER(13, 5) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('LastModByUserId') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY LASTMODBYUSERID VARCHAR2(45) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('BellHoleExcavation') and upper(column_name) = upper('LastModDateTime') and NULLABLE = 'Y';
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE BELLHOLEEXCAVATION MODIFY LASTMODDATETIME DATE NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                END;            
                UPDATE VersionInfo SET DBVersionCheckPoint = 7;
           END; 
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 7
        THEN
            BEGIN
                -- SQLQueryAddModifyColumns_FloodAreaStageDatabase.sql
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('FloodArea') and upper(column_name) = upper('BeginStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FLOODAREA ADD BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('FloodArea') and upper(column_name) = upper('EndStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FLOODAREA ADD ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                END;

                UPDATE VersionInfo SET DBVersionCheckPoint = 8;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 8
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Casing') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE CASING ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('Load_Casing');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_CASING(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            LOAD_CASINGTYPEDOMAINID NUMBER(7, 0) NULL,
                                            LOAD_CASINGINHIBITORDOMAINID NUMBER(7, 0) NULL,
                                            LOAD_CASINGCOMMENT VARCHAR2(255) NULL,
                                            LOAD_CASINGDIAMETER NUMBER(8, 5) NULL,
                                            LOAD_CASINGWALLTHICKNESS NUMBER(9, 5) NULL,
                                            LOAD_CASINGVENTEDFLG NUMBER(1, 0) NULL,
                                            LOAD_CASINGSHORTEDFLG NUMBER(1, 0) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_CASING PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 9;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 9
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('MetalLoss') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE METALLOSS ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('Load_Casing');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_METALLOSS(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            EXCAVATIONSITEID NUMBER(10, 0) NOT NULL,
                                            INLINEINSPECTIONFEATUREID NUMBER(10, 0) NULL,
                                            METALLOSSALTERNATEDEFECTID VARCHAR2(25) NULL,
                                            METALLOSSGIRTHWELDNUM NUMBER(7, 0) NULL,
                                            METALLOSSDISTANCEFROMGIRTHWELD NUMBER(10, 3) NULL,
                                            METALLOSSORIENTATION NUMBER(3, 0) NULL,
                                            METALLOSSTYPEDOMAINID NUMBER(7, 0) NULL,
                                            METALLOSSCAUSEDOMAINID NUMBER(7, 0) NULL,
                                            METALLOSSSTATUSDOMAINID NUMBER(7, 0) NULL,
                                            METALLOSSLENGTH NUMBER(9, 2) NULL,
                                            METALLOSSWIDTH NUMBER(9, 2) NULL,
                                            METALLOSSDEPTH NUMBER(4, 2) NULL,
                                            METALLOSSDEPTHPCT NUMBER(8, 5) NULL,
                                            METALLOSSSURFACEIND VARCHAR2(2) NULL,
                                            METALLOSSFAILUREPRESSURE NUMBER(15, 4) NULL,
                                            METALLOSSFAILUREPRESSALGRTHMLD NUMBER(7, 0) NULL,
                                            METALLOSSRUPTUREPRESSURERATIO NUMBER(5, 3) NULL,
                                            METALLOSSSAFEPRESSURE NUMBER(15, 4) NULL,
                                            METALLOSSSAFEPRESSALGRTHMLD NUMBER(7, 0) NULL,
                                            METALLOSSACIDSMELLTEST NUMBER(1, 0) NULL,
                                            METALLOSSACIDPRDBACTERIATEST NUMBER(1, 0) NULL,
                                            MTLLSSSULFATERDCNGBACTERIATEST NUMBER(1, 0) NULL,
                                            METALLOSSOTHERBACTERIATESTRSLT VARCHAR2(255) NULL,
                                            LINALYSISPRIMARYLENGTH NUMBER(9, 2) NULL,
                                            LINALYSISSECONDARYLENGTH NUMBER(9, 2) NULL,
                                            LINALYSISMAXDEPTH NUMBER(4, 2) NULL,
                                            LINALYSISMAXDEPTHPCT NUMBER(8, 5) NULL,
                                            LINALYSISORIENTATION NUMBER(3, 0) NULL,
                                            METALLOSSGRADING1DOMAINID NUMBER(7, 0) NULL,
                                            METALLOSSGRADING2DOMAINID NUMBER(7, 0) NULL,
                                            METALLOSSCOMMENT VARCHAR2(255) NULL,
                                            STATIONSERIESID NUMBER(10, 0) NULL,
                                            STATIONNUM NUMBER(13, 5) NULL,
                                            METALLOSSCIRCUMLENGTH NUMBER(9, 2) NULL,
                                            METALLOSSMAXWIDTH NUMBER(9, 2) NULL,
                                            METALLOSSCAOP NUMBER(5, 0) NULL,
                                            METALLOSSAXIALLENGTH NUMBER(9, 2) NULL,
                                            METALLOSSMAXDEPTH NUMBER(4, 2) NULL,
                                            METALLOSSMAXDEPTHPCT NUMBER(8, 5) NULL,
                                            METALLOSSPREVINVESTIGATE CHAR(1) NULL,
                                            METALLOSSCORROSIONACTIVEFLG NUMBER(1, 0) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            METALLOSSREPAIRMETHODDOMAINID NUMBER(7, 0) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NULL,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_METALLOSS PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('RightOfWay') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE RIGHTOFWAY ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('Load_RightOfWay');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_RIGHTOFWAY(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            ROWTYPEDOMAINID NUMBER(7, 0) NULL,
                                            ROWLANDLEGALLOCATION VARCHAR2(255) NULL,
                                            ROWOWNERDOMAINID NUMBER(7, 0) NULL,
                                            ROWWIDTH NUMBER(10, 3) NULL,
                                            ROWCOMMENT VARCHAR2(255) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_RIGHTOFWAY PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Marker') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MARKER ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('Load_RightOfWay');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_MARKER(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            LOAD_MARKERTYPEDOMAINID NUMBER(7, 0) NULL,
                                            LOAD_MARKERNAME VARCHAR2(70) NULL,
                                            LOAD_MARKEROFFSET NUMBER(4, 2) NULL,
                                            LOAD_MARKERLATITUDE NUMBER(11, 9) NULL,
                                            LOAD_MARKERLONGITUDE NUMBER(12, 9) NULL,
                                            LOAD_MARKERCOORDSYSDOMAINID NUMBER(7, 0) NULL,
                                            LOAD_MARKERX NUMBER(12, 3) NULL,
                                            LOAD_MARKERY NUMBER(12, 3) NULL,
                                            LOAD_MARKERZ NUMBER(10, 3) NULL,
                                            LOAD_MARKERENGINEERINGSTNFLG NUMBER(1, 0) NULL,
                                            STATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            STATIONNUM NUMBER(13, 5) NOT NULL,
                                            LOAD_MARKERDESCR VARCHAR2(255) NULL,
                                            LOAD_MARKERILIRUN VARCHAR2(30) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_MARKER PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 10;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 10
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(8000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('RectifierReading') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE RECTIFIERREADING ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_RECTIFIERREADING');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_RECTIFIERREADING(
                                            RECTIFIERID NUMBER(10, 0) NOT NULL,
                                            RCTFRREADINGDATE DATE NOT NULL,
                                            RCTFRREADINGVOLTAGE NUMBER(5, 2) NULL,
                                            RCTFRREADINGAMPERAGE NUMBER(5, 2) NULL,
                                            RCTFRREADINGCOMMENT VARCHAR2(255) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_RECTIFIERREADING PRIMARY KEY(SOURCEID, RCTFRREADINGDATE))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Rectifier') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE RECTIFIER ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('Load_Rectifier');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_RECTIFIER(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            RCTFRMANUFACTURERDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRSTATUSDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRACARRESTERDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRDCARRESTERDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRSTACKTYPEDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRSTACKMANUFACTURERDOMAINID NUMBER(7, 0) NULL,
                                            RCTFRMODELNUMBER VARCHAR2(50) NULL,
                                            RCTFRSERIALNUMBER VARCHAR2(12) NULL,
                                            RCTFRMAPNUMBER VARCHAR2(8) NULL,
                                            RCTFRHYDROACCTNUMBER VARCHAR2(40) NULL,
                                            RCTFRHYDRONEUTRALSEP NUMBER(1, 0) NULL,
                                            RCTFRACRATING NUMBER(4, 0) NULL,
                                            RCTFRAMPRATING NUMBER(5, 1) NULL,
                                            RCTFRKHFACTOR NUMBER(5, 1) NULL,
                                            RCTFRACFUSERATING NUMBER(4, 0) NULL,
                                            RCTFRACFUSEMANUFACT VARCHAR2(20) NULL,
                                            RCTFRDCFUSERATING NUMBER(4, 0) NULL,
                                            RCTFRDCFUSEMANUFACT VARCHAR2(20) NULL,
                                            RCTFRSURVMONITORFREQ VARCHAR2(2) NULL,
                                            RCTFRMAJSURVMONITORFREQ VARCHAR2(2) NULL,
                                            RCTFRDCFILLERVOLT NUMBER(4, 0) NULL,
                                            RCTFRDCFILLERAMP NUMBER(4, 0) NULL,
                                            RCTFRINTERNALSHUNTMV NUMBER(4, 0) NULL,
                                            RCTFRINTERNALSHUNTAMP NUMBER(4, 0) NULL,
                                            RCTFRINSTALLPROJECTID VARCHAR2(20) NULL,
                                            RCTFRMAINTENANCEPROJECTID VARCHAR2(20) NULL,
                                            RCTFRCOMMENT VARCHAR2(255) NULL,
                                            STATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            STATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_RECTIFIER PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 11;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);           
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 11
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(8000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Sleeve') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE SLEEVE ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_SLEEVE');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_SLEEVE(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            SLEEVETYPEDOMAINID NUMBER(7, 0) NULL,
                                            SLEEVECOMMENT VARCHAR2(512) NULL,
                                            SLEEVEQUANTITY NUMBER(4, 0) NULL,
                                            SLEEVEWALLTHICKNESS NUMBER(9, 5) NULL,
                                            SLEEVEGRADE NUMBER(10, 5) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_SLEEVE PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Weight') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE WEIGHT ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_WEIGHT');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_WEIGHT(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            WEIGHTLINEARPOINTIND CHAR(1) NULL,
                                            WEIGHTTYPEDOMAINID NUMBER(7, 0) NULL,
                                            WEIGHTCOMMENT VARCHAR2(255) NULL,
                                            WEIGHTQUANTITY NUMBER(4, 0) NULL,
                                            WEIGHTSPACING NUMBER(4, 1) NULL,
                                            WEIGHTEACH NUMBER(5, 1) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_WEIGHT PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Tee') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE TEE ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_TEE');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_TEE(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            TEETYPEDOMAINID NUMBER(7, 0) NULL,
                                            TEEOUTSIDEDIAMETER NUMBER(9, 5) NULL,
                                            TEENAME VARCHAR2(100) NULL,
                                            TEECOMMENT VARCHAR2(255) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            TEEMANUFACTURINGTYPELD NUMBER(7, 0) NULL,
                                            TEEOUTLETGRADE NUMBER(5, 0) NULL,
                                            TEEOUTLETWALLTHICKNESS NUMBER(9, 5) NULL,
                                            TEEINLETDIAMETER NUMBER(5, 3) NULL,
                                            TEEINLETGRADE NUMBER(5, 0) NULL,
                                            TEEINLETWALLTHICKNESS NUMBER(9, 5) NULL,
                                            TEEPRESSURERATING NUMBER(5, 0) NULL,
                                            TEEOUTLETDIAMETER NUMBER(5, 3) NULL,
                                            TEECONNECTDOMAINID NUMBER(7, 0) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_TEE PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 12;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 12
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Structure') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STRUCTURE ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_STRUCTURE');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_STRUCTURE(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            STRUCTURETYPEDOMAINID NUMBER(7, 0) NULL,
                                            STRUCTURECOMMENT VARCHAR2(255) NULL,
                                            BUILDINGCNT NUMBER(5, 0) NULL,
                                            DWELLINGUNITCNT NUMBER(6, 2) NULL,
                                            OCCUPANCYCTGRYDOMAINID NUMBER(7, 0) NULL,
                                            STRUCTURECOORDSYSDOMAINID NUMBER(7, 0) NULL,
                                            STRUCTUREAREAPOINTIND CHAR(1) NULL,
                                            STRUCTUREACTIVEFLG NUMBER(1, 0) NULL,
                                            STOREYCNT NUMBER(5, 0) NULL,
                                            DAYSPERWEEK NUMBER(3, 0) NULL,
                                            WEEKSPERYEAR NUMBER(3, 0) NULL,
                                            OCCUPANTCNT NUMBER(11, 6) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE NULL,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE NULL,
                                            CREATEDUSER VARCHAR2(45) NULL,
                                            CONSTRAINT PK_LOAD_STRUCTURE PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('JointCoating') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE JOINTCOATING ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_JOINTCOATING');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_JOINTCOATING(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            JOINTCOATINGDOMAINID NUMBER(7, 0) NULL,
                                            JOINTCOATINGCOMMENT VARCHAR2(255) NULL,
                                            JOINTCOATINGINSTALLDATE DATE NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_JOINTCOATING PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('InternalCoating') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE INTERNALCOATING ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_INTERNALCOATING');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_INTERNALCOATING(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            INTERNALCOATINGDOMAINID NUMBER(7, 0) NULL,
                                            INTERNALCOATINGCOMMENT VARCHAR2(255) NULL,
                                            INTERNALCOATINGINSTALLDATE DATE NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_INTERNALCOATING PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 13;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 13
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('StructureVertex') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STRUCTUREVERTEX ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_STRUCTUREVERTEX');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_STRUCTUREVERTEX(
                                            STRUCTUREID NUMBER(10, 0) NOT NULL,
                                            STRUCTUREVERTEXSEQ NUMBER(4, 0) NOT NULL,
                                            STRUCTUREVERTEXLATITUDE NUMBER(11, 9) NOT NULL,
                                            STRUCTUREVERTEXLONGITUDE NUMBER(12, 9) NOT NULL,
                                            STRUCTUREVERTEXX NUMBER(12, 3) NULL,
                                            STRUCTUREVERTEXY NUMBER(12, 3) NULL,
                                            STRUCTUREVERTEXZ NUMBER(10, 3) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            STRUCTUREGUID VARCHAR2(50) NULL,
                                            CONSTRAINT PK_LOAD_STRUCTUREVERTEX PRIMARY KEY(STRUCTUREID, STRUCTUREVERTEXSEQ))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 14;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 14
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(8000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Valve') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE VALVE ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VALVE');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VALVE(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            VALVETYPEDOMAINID NUMBER(7, 0) NULL,
                                            VALVENUM NUMBER(6, 1) NULL,
                                            VALVENAME VARCHAR2(50) NULL,
                                            VALVEPIGGABLEIND CHAR(1) NULL,
                                            VALVECOMMENT VARCHAR2(255) NULL,
                                            VALVEDIAMETER NUMBER(8, 5) NULL,
                                            VALVEOPERATORTYPEDOMAINID NUMBER(7, 0) NULL,
                                            VALVELATITUDE NUMBER(11, 9) NULL,
                                            VALVELONGITUDE NUMBER(12, 9) NULL,
                                            VALVECOORDSYSDOMAINID NUMBER(7, 0) NULL,
                                            VALVEX NUMBER(12, 3) NULL,
                                            VALVEY NUMBER(12, 3) NULL,
                                            VALVEZ NUMBER(10, 3) NULL,
                                            STATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            STATIONNUM NUMBER(13, 5) NOT NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            VALVECONNECTDOMAINID NUMBER(7, 0) NULL,
                                            VALVEFLOWCOEFFICIENTSLOPE NUMBER(12, 9) NULL,
                                            VALVEFLOWCOEFFICIENT NUMBER(10, 0) NULL,
                                            VALVECLOSUREPROFILELD NUMBER(7, 0) NULL,
                                            VALVEISCHECKFLG NUMBER(1, 0) NULL,
                                            VALVEWITHINFENCEIND VARCHAR2(1) NULL,
                                            VALVEQSTNRPCTFRACTION NUMBER(5, 4) NULL,
                                            VALVECONDITIONDOMAINID NUMBER(7, 0) NULL,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            VALVEMANUFACTURERDOMAINID NUMBER(7, 0) NULL,
                                            CONSTRAINT PK_LOAD_VALVE PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 15;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 15
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(8000);
                
                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Vent') and upper(column_name) = upper('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE VENT ADD CHECKSUMVALUE INT NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    

                    select COUNT(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VENT');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VENT(
                                            ID NUMBER(10, 0) NOT NULL,
                                            EFFECTIVESTARTDATE DATE NULL,
                                            EFFECTIVEENDDATE DATE NULL,
                                            VENTTYPEDOMAINID NUMBER(7, 0) NULL,
                                            VENTOUTSIDEDIAMETER NUMBER(9, 5) NULL,
                                            VENTNAME VARCHAR2(100) NULL,
                                            VENTCOMMENT VARCHAR2(255) NULL,
                                            BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            BEGINSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL,
                                            ENDSTATIONNUM NUMBER(13, 5) NOT NULL,
                                            VENTMANUFACTURINGTYPELD NUMBER(7, 0) NULL,
                                            VENTOUTLETGRADE NUMBER(5, 0) NULL,
                                            VENTOUTLETWALLTHICKNESS NUMBER(9, 5) NULL,
                                            VENTINLETDIAMETER NUMBER(5, 3) NULL,
                                            VENTINLETGRADE NUMBER(5, 0) NULL,
                                            VENTINLETWALLTHICKNESS NUMBER(9, 5) NULL,
                                            VENTPRESSURERATING NUMBER(5, 0) NULL,
                                            VENTOUTLETDIAMETER NUMBER(5, 3) NULL,
                                            VENTCONNECTDOMAINID NUMBER(7, 0) NULL,
                                            LASTMODBYUSERID VARCHAR2(45),
                                            LASTMODDATETIME DATE,
                                            SOURCEID VARCHAR2(50) NOT NULL,
                                            CREATEDDATE DATE,
                                            CREATEDUSER VARCHAR2(45),
                                            CONSTRAINT PK_LOAD_VENT PRIMARY KEY(SOURCEID))';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 16;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 16
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement VARCHAR2(2000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD SOURCEID VARCHAR2(50) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('CreatedDate');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD CREATEDDATE DATE DEFAULT SYSDATE NOT NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('CreatedUser');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD CREATEDUSER VARCHAR2(45) DEFAULT USER NOT NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('BeginStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD BEGINSTATIONSERIESID NUMBER(10, 0) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('BeginStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD BEGINSTATIONNUM NUMBER(13, 5) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('EndStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD ENDSTATIONSERIESID NUMBER(10, 0) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('EndStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD ENDSTATIONNUM NUMBER(13, 5) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('BeginStationSeriesGUID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD BEGINSTATIONSERIESGUID VARCHAR2(50) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Facility') AND UPPER(COLUMN_NAME) = UPPER('EndStationSeriesGUID');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FACILITY ADD ENDSTATIONSERIESGUID VARCHAR2(50) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 17;
            
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/



BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630106 AND dbVersionCheckPoint = 17
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 01
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630201', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 01';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630201 AND dbVersionCheckPoint = 0
        THEN
            DECLARE CNT INT;
            sqlStatement VARCHAR2(2000);
            
            BEGIN
                -- Add CPMatchOffset to alignment tables.sql
    
                -- This script is for adding CPMatchOffset column to FacilityAlignment and JointAlignment

                SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('FacilityAlignment') AND UPPER(COLUMN_NAME) = UPPER('CPMatchOffset');
                
                IF CNT = 0
                THEN
                    sqlStatement := 'ALTER TABLE FACILITYALIGNMENT ADD CPMATCHOFFSET NUMBER(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('JointAlignment') AND UPPER(COLUMN_NAME) = UPPER('CPMatchOffset');
                
                IF CNT = 0
                THEN
                    sqlStatement := 'ALTER TABLE JOINTALIGNMENT ADD CPMATCHOFFSET NUMBER(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

            END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630201 AND dbVersionCheckPoint = 1
        THEN
            DECLARE CNT INT;
            sqlStatement VARCHAR2(2000);
            
            BEGIN
                -- Add Latitude and Longitude to GirthWeld Table.sql
                -- This script is for adding the Latitude and Longitude columns to Girthweld table.

                SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Girthweld') AND UPPER(COLUMN_NAME) = UPPER('Latitude');
                
                IF CNT = 0
                THEN
                    sqlStatement := 'ALTER TABLE GIRTHWELD ADD LATITUDE NUMBER(11,9) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Girthweld') AND UPPER(COLUMN_NAME) = UPPER('Longitude');
                
                IF CNT = 0
                THEN
                    sqlStatement := 'ALTER TABLE GIRTHWELD ADD LONGITUDE NUMBER(12,9) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

            END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/



BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630201 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 02
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630202', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 02';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630202 AND dbVersionCheckPoint = 0
        THEN
			BEGIN
				DECLARE CNT INT;
					sqlStatement varchar(8000);
				BEGIN
					SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_INLINEINSPECTIONAXIALSTRAIN');

					IF CNT = 0
					THEN
						EXECUTE IMMEDIATE 'CREATE SEQUENCE S_INLINEINSPECTIONAXIALSTRAIN';
					END IF;

					sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_ILIAXIALSTRAIN BEFORE INSERT
										ON INLINEINSPECTIONAXIALSTRAIN FOR EACH ROW
										DECLARE
											INTEGRITY_ERROR  EXCEPTION;
											ERRNO            INTEGER;
											ERRMSG           CHAR(200);
											DUMMY            INTEGER;
											FOUND            BOOLEAN;

										BEGIN
											--  COLUMN ID USES SEQUENCE S_INLINEINSPECTIONAXIALSTRAIN
											SELECT S_INLINEINSPECTIONAXIALSTRAIN.NEXTVAL INTO :NEW.ID FROM DUAL;

										--  ERRORS HANDLING
										EXCEPTION
											WHEN INTEGRITY_ERROR THEN
											   RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
										END;';

					EXECUTE IMMEDIATE sqlStatement;

					SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_STG_ILIAXIALSTRAIN');

					IF CNT = 0
					THEN
						EXECUTE IMMEDIATE 'CREATE SEQUENCE S_STG_ILIAXIALSTRAIN';
					END IF;

					sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_STG_ILIAXIALSTRAIN BEFORE INSERT
									ON STG_ILIAXIALSTRAIN FOR EACH ROW
									DECLARE
										INTEGRITY_ERROR  EXCEPTION;
										ERRNO            INTEGER;
										ERRMSG           CHAR(200);
										DUMMY            INTEGER;
										FOUND            BOOLEAN;

									BEGIN
										--  COLUMN ID USES SEQUENCE S_STG_ILIAXIALSTRAIN
										SELECT S_STG_ILIAXIALSTRAIN.NEXTVAL INTO :NEW.ID FROM DUAL;

									--  ERRORS HANDLING
									EXCEPTION
										WHEN INTEGRITY_ERROR THEN
										   RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
									END;';

					EXECUTE IMMEDIATE sqlStatement;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFDEPTHTOLERANCE NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFDEPTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFLENGTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFLENGTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;    

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFWIDTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFWIDTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFDEPTHTOLERANCESTDDEV NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFDEPTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFLENGTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFLENGTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;
    
					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFWIDTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE MODIFY ILIFWIDTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;
                END;
                
				UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630202 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
				DECLARE CNT INT;
					sqlStatement varchar(8000);
				BEGIN
					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCE NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCESTDDEV NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;    

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('INLINEINSPECTIONNONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;
                END;
				UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630202 AND dbVersionCheckPoint = 2
        THEN
            BEGIN
				DECLARE CNT INT;
					sqlStatement varchar(8000);
				BEGIN
					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICADEPTHTOLERANCE NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICADEPTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICALENGTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICALENGTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICAWIDTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICAWIDTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICADEPTHTOLERANCESTDDEV NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICADEPTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICALENGTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICALENGTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICAWIDTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrackAnomaly') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrackAnomaly MODIFY ILICAWIDTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;
                END;
				UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630202 AND dbVersionCheckPoint = 3
        THEN
            BEGIN
				DECLARE CNT INT;
					sqlStatement varchar(8000);
				BEGIN
					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBDEPTHTOLERANCE NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBDEPTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBLENGTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBLENGTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBWIDTHTOLERANCE NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCE')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBWIDTHTOLERANCE NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBDEPTHTOLERANCESTDDEV NUMBER(8,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBDEPTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBLENGTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBLENGTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBWIDTHTOLERANCESTDDEV NUMBER(10,3)';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;

					SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('InlineInspectionCrsnCallBox') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCESTDDEV')
					AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
    
					IF CNT <> 1
					THEN
						sqlStatement := 'ALTER TABLE InlineInspectionCrsnCallBox MODIFY ILICBWIDTHTOLERANCESTDDEV NULL';
						EXECUTE IMMEDIATE sqlStatement;
					END IF;
				END;

				UPDATE VersionInfo SET DBVersionCheckPoint = 4;
            END;
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630202 AND dbVersionCheckPoint = 4
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 03
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630203', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 03';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630203 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFDEPTHTOLERANCE NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFDEPTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFLENGTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFLENGTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFWIDTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFWIDTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFDEPTHTOLERANCESTDDEV NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFDEPTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFLENGTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFLENGTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFWIDTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILIFEATURE') AND UPPER(COLUMN_NAME) = UPPER('ILIFWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILIFEATURE MODIFY ILIFWIDTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;    
                END;
    
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630203 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCE NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCESTDDEV NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDDEPTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDLENGTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILINONCRSNDFCT') AND UPPER(COLUMN_NAME) = UPPER('ILINCDWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILINONCRSNDFCT MODIFY ILINCDWIDTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;    
                END;            
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            END;            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM); 
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630203 AND dbVersionCheckPoint = 2
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICADEPTHTOLERANCE NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICADEPTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICALENGTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICALENGTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICAWIDTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICAWIDTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICADEPTHTOLERANCESTDDEV NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICADEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICADEPTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICALENGTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICALENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICALENGTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICAWIDTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRACKANOMALY') AND UPPER(COLUMN_NAME) = UPPER('ILICAWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRACKANOMALY MODIFY ILICAWIDTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;    
                END;
    
                UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630203 AND dbVersionCheckPoint = 3
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBDEPTHTOLERANCE NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBDEPTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBLENGTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBLENGTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBWIDTHTOLERANCE NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCE')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBWIDTHTOLERANCE NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 8 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBDEPTHTOLERANCESTDDEV NUMBER(8,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBDEPTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBDEPTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBLENGTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBLENGTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBLENGTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND DATA_PRECISION = 10 AND DATA_SCALE = 3;
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBWIDTHTOLERANCESTDDEV NUMBER(10,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('STG_ILICRSNCALLBOX') AND UPPER(COLUMN_NAME) = UPPER('ILICBWIDTHTOLERANCESTDDEV')
                    AND UPPER(DATA_TYPE) = upper('NUMBER') AND NULLABLE = 'Y';
        
                    IF CNT <> 1
                    THEN
                        sqlStatement := 'ALTER TABLE STG_ILICRSNCALLBOX MODIFY ILICBWIDTHTOLERANCESTDDEV NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;    
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 4;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630203 AND dbVersionCheckPoint = 4
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 04
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630204', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 04';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630204 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                CURSOR a_cursor IS
                    Select TABLE_NAME from  user_tables where  TABLE_NAME IN ('AREA','BEND','CASING','CLASSAREA','COATING','CORPORATION','COUPON','COUPONREADING',
                    'COVERDEPTH','COVERDEPTHPROFILE','CPSURVEY','CPSURVEYRANGE','CPSURVEYREADING','CROSSING','CROSSINGLOCN','DAMAGEPREVENTION','DESIGNCLASS','DISCHARGESUBSYSTEM',
                    'DISTRICTDIVISION','ELBOW','ELEVATIONPROFILE','EXCAVATIONPROJECT','EXCAVATIONSITE','EXPOSEDPIPE','EXTRUSION','FLANGE','GIRTHWELD','HCACFR','HCACFRSEG',
                    'HCAPIPEPIRBUFFER','HYDROTEST','HYDROTESTRANGE','INCIDENT','INCIDENTHISTORY','INTERNALCOATING','IRASCUSTOMDATA1','IRASCUSTOMDATA11',
                    'IRASCUSTOMDATA2','IRASCUSTOMDATA3','IRASCUSTOMDATA4','IRASCUSTOMDATA5','IRASCUSTOMDATA6','IRASCUSTOMDATA7','IRASCUSTOMDATA8','IRASCUSTOMDATA9','JOINTCOATING',
                    'LANDUSE','LINELOOP','MAOP','MARKER','METALLOSS','MLVSECTION','MOP','OPERATINGUNIT','PIPELINESYSTEM','PIPESEGMENT','PRODUCTCOMPONENT','RECTIFIER','RECTIFIERREADING',
                    'REDUCER','RIGHTOFWAY','SLEEVE','SOILAREA','SOILLANDUSEAREA','STATEPROVINCE','STATIONSERIES','STRUCTURE','STRUCTUREVERTEX','TAP','TEE','TESTPOSTPOINT',
                    'TESTPOSTPOINTREADING','VALVE','VENT','WEIGHT','MLVCORRECTION','SERIESCONNECTION') 
                    and Table_Name NOT IN (select Table_NAME FROM user_tab_columns where Column_Name = 'CHECKSUMVALUE');
    
                MyTableName a_cursor%ROWTYPE;
    
                CURSOR d_cursor IS
                    Select TABLE_NAME from  user_tables where  TABLE_NAME like 'LOAD%';
    
                MyTableName2 d_cursor%ROWTYPE;

                CURSOR c_cursor IS
                    Select TABLE_NAME from  user_tables where  TABLE_NAME IN ('AREA','BEND','CASING','CLASSAREA','COATING','CORPORATION','COUPON','COUPONREADING','COVERDEPTH',
                    'COVERDEPTHPROFILE','CPSURVEY','CPSURVEYRANGE','CPSURVEYREADING','CROSSING','CROSSINGLOCN','DAMAGEPREVENTION','DESIGNCLASS','DISCHARGESUBSYSTEM',
                    'DISTRICTDIVISION','ELBOW','ELEVATIONPROFILE','EXCAVATIONPROJECT','EXCAVATIONSITE','EXPOSEDPIPE','EXTRUSION','FLANGE','GIRTHWELD','HCACFR','HCACFRSEG',
                    'HCAPIPEPIRBUFFER','HYDROTEST','HYDROTESTRANGE','INCIDENT','INCIDENTHISTORY','INTERNALCOATING','IRASCUSTOMDATA1','IRASCUSTOMDATA11',
                    'IRASCUSTOMDATA2','IRASCUSTOMDATA3','IRASCUSTOMDATA4','IRASCUSTOMDATA5','IRASCUSTOMDATA6','IRASCUSTOMDATA7','IRASCUSTOMDATA8','IRASCUSTOMDATA9','JOINTCOATING',
                    'LANDUSE','LINELOOP','MAOP','MARKER','METALLOSS','MLVSECTION','MOP','OPERATINGUNIT','PIPELINESYSTEM','PIPESEGMENT','PRODUCTCOMPONENT','RECTIFIER','RECTIFIERREADING',
                    'REDUCER','RIGHTOFWAY','SLEEVE','SOILAREA','SOILLANDUSEAREA','STATEPROVINCE','STATIONSERIES','STRUCTURE','STRUCTUREVERTEX','TAP','TEE','TESTPOSTPOINT','TESTPOSTPOINTREADING',
                    'VALVE','VENT','WEIGHT','MLVCORRECTION','SERIESCONNECTION') 
                    and 'LOAD_' || Table_Name NOT IN (select Table_NAME FROM user_tables where TABLE_Name LIKE 'LOAD%');
    
                MyTableName3 c_cursor%ROWTYPE;
    
                CURSOR e_cursor IS
                    Select TABLE_NAME from  user_tables where  TABLE_NAME like 'LOAD%';
    
                MyTableName4 e_cursor%ROWTYPE;
  
                CURSOR r_cursor IS
                    Select TABLE_NAME from  user_tables where  TABLE_NAME like 'LOAD%';
    
                MyTableName5 r_cursor%ROWTYPE;

                BEGIN
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('CouponReading') and upper(column_name) = upper('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE COUPONREADING ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('SeriesConnection') and upper(column_name) = upper('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE SERIESCONNECTION ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('HCAPipeGasConstantFactor') and upper(column_name) = upper('SourceId');

                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE HCAPIPEGASCONSTANTFACTOR ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
  
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('HCAPipePIRBuffer') and upper(column_name) = upper('SourceId');

                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE HCAPIPEPIRBUFFER ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('StructureVertex') and upper(column_name) = upper('SourceId');

                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE STRUCTUREVERTEX ADD SOURCEID VARCHAR2(50) NULL';
                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    BEGIN
                        OPEN a_cursor;
                        
                            LOOP
                                FETCH  a_cursor  INTO MyTableName;
                                EXIT WHEN a_cursor%NOTFOUND;
        
                                        sqlStatement :='ALTER TABLE ' || MyTableName.table_name || ' ADD CHECKSUMVALUE INT NULL';
                                         
                                        EXECUTE IMMEDIATE sqlStatement;
                            END LOOP;
                        CLOSE a_cursor;
                    END;
                        
                    BEGIN
                        OPEN d_cursor;
                        
                            LOOP
                                FETCH  d_cursor  INTO MyTableName2;
                                EXIT WHEN d_cursor%NOTFOUND;
        
                                        sqlStatement :='DROP TABLE ' || MyTableName2.table_name;
                                         
                                        EXECUTE IMMEDIATE sqlStatement;
                            END LOOP;
                        CLOSE d_cursor;                
                    END;                   
                   
                    BEGIN
                        OPEN c_cursor;
                        
                            LOOP
                                FETCH  c_cursor  INTO MyTableName2;
                                EXIT WHEN c_cursor%NOTFOUND;
        
                                        sqlStatement :='CREATE TABLE LOAD_' || MyTableName2.table_name || ' AS (SELECT * FROM ' || MyTableName2.table_name || ' WHERE 1 = 2)';
                                        EXECUTE IMMEDIATE sqlStatement;
                                        
                            END LOOP;
                        CLOSE c_cursor;                
                    END;
                
                    BEGIN
                        OPEN e_cursor;
                        
                            LOOP
                                FETCH  e_cursor  INTO MyTableName4;
                                EXIT WHEN e_cursor%NOTFOUND;
                                        
                                    SELECT COUNT(*) INTO CNT FROM user_tab_columns
                                    WHERE table_name = MyTableName4.table_name
                                    AND column_name = 'SOURCEID';

                                    IF CNT > 0
                                    THEN
                                        sqlStatement := 'ALTER TABLE ' || MyTableName4.table_name || ' DROP COLUMN SOURCEID';
                                        EXECUTE IMMEDIATE sqlStatement;
                                    END IF;
                                        
                            END LOOP;
                        CLOSE e_cursor;                
                    END;
                
                    BEGIN
                        OPEN r_cursor;
                        
                            LOOP
                                FETCH  r_cursor  INTO MyTableName5;
                                EXIT WHEN r_cursor%NOTFOUND;
                                        
                                    SELECT COUNT(*) INTO CNT FROM user_tab_columns
                                    WHERE table_name = MyTableName5.table_name
                                    AND column_name = 'SOURCEID';

                                    IF CNT = 0
                                    THEN
                                        sqlStatement := 'ALTER TABLE ' || MyTableName5.table_name || ' ADD SOURCEID VARCHAR(50) NOT NULL';
                                        
                                        EXECUTE IMMEDIATE sqlStatement;
        
                                        sqlStatement := 'ALTER TABLE ' || MyTableName5.table_name || ' ADD CONSTRAINT PK_' || MyTableName5.table_name || ' PRIMARY KEY (SOURCEID)';
                                        EXECUTE IMMEDIATE sqlStatement;
                                    END IF;   
                            END LOOP;
                        CLOSE r_cursor;                
                    END;
                END;   
                        
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630204 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                CURSOR m_cursor IS
                    select TABLE_NAME, COLUMN_NAME from user_tab_columns where Column_Name = 'CHECKSUMVALUE' and (DATA_TYPE <> 'NUMBER' or DATA_LENGTH <> 22 or DATA_SCALE <> 0);
    
                MyTableName m_cursor%ROWTYPE;

                CURSOR c_cursor IS
                    Select TABLE_NAME from  USER_TABLES where  TABLE_NAME IN ('AREA','BEND','CASING','CLASSAREA','COATING','CORPORATION','COUPON','COUPONREADING','COVERDEPTH',
                    'COVERDEPTHPROFILE','CPSURVEY','CPSURVEYRANGE','CPSURVEYREADING','CROSSING','CROSSINGLOCN','DAMAGEPREVENTION','DESIGNCLASS','DISCHARGESUBSYSTEM',
                    'DISTRICTDIVISION','ELBOW','ELEVATIONPROFILE','EXCAVATIONPROJECT','EXCAVATIONSITE','EXPOSEDPIPE','EXTRUSION','FLANGE','GIRTHWELD','HCACFR','HCACFRSEG',
                    'HCAPIPEPIRBUFFER','HYDROTEST','HYDROTESTRANGE','INCIDENT','INCIDENTHISTORY','INTERNALCOATING','IRASCUSTOMDATA1','IRASCUSTOMDATA11',
                    'IRASCUSTOMDATA2','IRASCUSTOMDATA3','IRASCUSTOMDATA4','IRASCUSTOMDATA5','IRASCUSTOMDATA6','IRASCUSTOMDATA7','IRASCUSTOMDATA8','IRASCUSTOMDATA9','JOINTCOATING',
                    'LANDUSE','LINELOOP','MAOP','MARKER','METALLOSS','MLVSECTION','MOP','OPERATINGUNIT','PIPELINESYSTEM','PIPESEGMENT','PRODUCTCOMPONENT','RECTIFIER','RECTIFIERREADING',
                    'REDUCER','RIGHTOFWAY','SLEEVE','SOILAREA','SOILLANDUSEAREA','STATEPROVINCE','STATIONSERIES','STRUCTURE','STRUCTUREVERTEX','TAP','TEE','TESTPOSTPOINT','TESTPOSTPOINTREADING',
                    'VALVE','VENT','WEIGHT','MLVCORRECTION','SERIESCONNECTION') 
                    and Table_Name NOT IN (select Table_NAME FROM user_tab_columns where COLUMN_Name = 'CHECKSUMVALUE');
                    
                MyTableName2 c_cursor%ROWTYPE;

                BEGIN
                    BEGIN
                        OPEN m_cursor;
                        
                            LOOP
                                FETCH  m_cursor  INTO MyTableName;
                                EXIT WHEN m_cursor%NOTFOUND;
        
                                        sqlStatement :='ALTER TABLE ' || MyTableName.table_name || ' MODIFY ' || MyTableName.Column_Name || ' INT NULL';
                                         
                                        EXECUTE IMMEDIATE sqlStatement;
                            END LOOP;
                        CLOSE m_cursor;                
                    END;
                    
                    BEGIN
                        OPEN c_cursor;
                        
                            LOOP
                                FETCH  c_cursor  INTO MyTableName2;
                                EXIT WHEN c_cursor%NOTFOUND;
        
                                        sqlStatement :='ALTER TABLE ' || MyTableName2.table_name || ' ADD CHECKSUMVALUE INT NULL';
                                         
                                        EXECUTE IMMEDIATE sqlStatement;
                            END LOOP;
                        CLOSE c_cursor;                
                    END;                    
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630204 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 05
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630205', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 05';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630205 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                CURSOR c_cursor IS
                    select TABLE_NAME from USER_TAB_COLUMNS where TABLE_NAME LIKE 'LOAD_%' AND Table_Name NOT IN (select Table_NAME FROM user_tab_columns where COLUMN_Name = 'CHECKSUMVALUE');
                    
                MyTableName2 c_cursor%ROWTYPE;

                BEGIN
                    BEGIN
                        OPEN c_cursor;
                        
                            LOOP
                                FETCH  c_cursor  INTO MyTableName2;
                                EXIT WHEN c_cursor%NOTFOUND;
        
                                        sqlStatement :='ALTER TABLE ' || MyTableName2.table_name || ' ADD CHECKSUMVALUE INT NULL';
                                         
                                        EXECUTE IMMEDIATE sqlStatement;
                            END LOOP;
                        CLOSE c_cursor;                
                    END;                    
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630205 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 06
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630206', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 06';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630206 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                BEGIN
                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_SeriesConnectionSourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection drop constraint Pk_SeriesConnectionSourceId';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('PK_MLVCORRECTIONSOURCEID');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection drop constraint PK_MLVCORRECTIONSOURCEID';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Load_MLVCorrection') and upper(column_name) = upper('SourceId') AND NULLABLE = 'N';
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection MODIFY SourceId varchar(50) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Load_SeriesConnection') and upper(column_name) = upper('SourceId') AND NULLABLE = 'N';
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection MODIFY SourceId varchar(50) NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Load_MLVCorrection') and upper(column_name) = upper('CheckSumValue') AND NULLABLE = 'N';
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection MODIFY CheckSumValue INT NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    select COUNT(*) INTO CNT from user_tab_columns where upper(table_name) = upper('Load_SeriesConnection') and upper(column_name) = upper('CheckSumValue') AND NULLABLE = 'N';
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection MODIFY CheckSumValue INT NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630206 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 07
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630207', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 07';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630207 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                BEGIN
                
                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_STATIONING');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_STATIONING (
								VIRTUALTABLEID number(10, 0) NOT NULL,
								VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
								EFFECTIVESTARTDATE Date,
								EFFECTIVEENDDATE Date,
								BEGINSTATIONSERIESID number(10, 0) NOT NULL,
								BEGINSTATIONNUM number(13, 5) NOT NULL,
								ENDSTATIONSERIESID number(10, 0) NOT NULL,
								ENDSTATIONNUM number(13, 5) NOT NULL,
								LASTMODBYUSERID VARCHAR2(45) DEFAULT user NOT NULL,
								LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
								SOURCEID VARCHAR2(50),
								CREATEDDATE Date DEFAULT sysdate NOT NULL,
								CREATEDUSER VARCHAR2(45) DEFAULT user NOT NULL,
								CONSTRAINT PK_LOAD_VIRTUALTABLESTATIONING PRIMARY KEY (VIRTUALTABLESTATIONINGID, VIRTUALTABLEID)
                                )';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATASTRING');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATASTRING (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUESTRING Varchar2(512),
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATASTRING PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATANUM');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATANUM (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUENUM FLOAT,
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATANUM PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID) 
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATALISTDOMAIN');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATALISTDOMAIN (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUEDOMAINID number(7, 0),
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATALISTDOMAIN PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLESTATIONINGID, VIRTUALTABLEID)
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATAIND');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATAIND (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUEIND CHAR(1),
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATAIND PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATAFLG');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATAFLG (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUEFLG number(1, 0),
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATAFLG PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;                    

                    select count(*) INTO CNT from user_tables where upper(table_name) = upper('LOAD_VT_DATADATE');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE LOAD_VT_DATADATE (
							  VIRTUALCOLUMNID number(10, 0) NOT NULL,
							  VIRTUALTABLEID number(10, 0) NOT NULL,
							  VIRTUALTABLESTATIONINGID number(10, 0) NOT NULL,
							  DATAFIELDVALUEDATE Date,
							  LASTMODBYUSERID Varchar2(45) DEFAULT user NOT NULL,
							  LASTMODDATETIME Date DEFAULT sysdate NOT NULL,
							  SOURCEID Varchar2(50),
							  CREATEDDATE Date DEFAULT sysdate NOT NULL,
							  CREATEDUSER Varchar2(45) DEFAULT user NOT NULL,
							  CONSTRAINT PK_LOAD_DATADATE PRIMARY KEY (VIRTUALCOLUMNID, VIRTUALTABLEID, VIRTUALTABLESTATIONINGID)
							)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;          
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630207 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 08
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630208', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 08';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630208 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                BEGIN
                    SELECT count(*) INTO CNT FROM User_Procedures where Object_Type = 'PROCEDURE' and upper(Object_Name) = upper('sp_Del_VirtualTableStationing');
                
                    IF CNT > 0
                    THEN
                        sqlStatement := 'DROP PROCEDURE sp_Del_VirtualTableStationing';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630208 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                BEGIN

                    SELECT count(*) INTO CNT FROM User_Procedures where Object_Type = 'PROCEDURE' and upper(Object_Name) = upper('sp_Del_VirtualTableStationing');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE PROCEDURE sp_Del_VirtualTableStationing
                                            AS
                                            BEGIN
                                                DELETE from VIRTUALTABLESTATIONING
                                                where (VIRTUALTABLEID, VIRTUALTABLESTATIONINGID) NOT IN 
                                                (
                                                    select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from LOAD_VT_STATIONING
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATADATE
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAFLG
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAIND
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATALISTDOMAIN
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATANUM
                                                    union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATASTRING
                                                );
                                            END;
                                            ';
                            
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;           
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630208 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 09
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630209', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Hotfixes Updates 09';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/
BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630209 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                    sqlStatement varchar(8000);

                BEGIN
                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') AND upper(Column_Name) = upper('ILIBSTotalStrain')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSTotalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrain') AND NULLABLE = 'Y';

                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSTotalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;


                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') AND upper(Column_Name) = upper('ILIBSHorizontalStrain') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizontalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') AND upper(Column_Name) = upper('ILIBSHorizontalStrain') 
                    AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizontalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') AND upper(Column_Name) = upper('ILIBSVerticalStrain') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') AND upper(Column_Name) = upper('ILIBSVerticalStrain') 
                    AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrainAtPeak') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizontalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizontalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainAtPeak')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrainAtPeak')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSTotalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSTotalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalStrainDif') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxTotalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxTotalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalStrainDif') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxHorizontalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxHorizontalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalStrainDif') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxVerticalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxVerticalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizonStrainDifAtPeak')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizonStrainDifAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizonStrainDifAtPeak') AND NULLABLE = 'Y';
               
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSHorizonStrainDifAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainDifAtPeak')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrainDifAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainDifAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSVerticalStrainDifAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalPipeMove')
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxVerticalPipeMove number (7,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxVerticalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalPipeMove')
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxHorizontalPipeMove number (7,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxHorizontalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalPipeMove')
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxTotalPipeMove number (7,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSMaxTotalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainOdometer') 
                    and Data_Precision = 11 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSPeakStrainOdometer number (11,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainOdometer') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSPeakStrainOdometer NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainDifOdometer') 
                    and Data_Precision = 11 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSPeakStrainDifOdometer number (11,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('InlineInspectionBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainDifOdometer') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE InlineInspectionBendStrain MODIFY ILIBSPeakStrainDifOdometer NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrain')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSTotalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrain') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSTotalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrain')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizontalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrain') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizontalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrain') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrain number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrain') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrain NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrainAtPeak') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizontalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizontalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizontalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainAtPeak') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrainAtPeak')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSTotalStrainAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSTotalStrainAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSTotalStrainAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalStrainDif') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxTotalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxTotalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalStrainDif')
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxHorizontalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxHorizontalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalStrainDif') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxVerticalStrainDif number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalStrainDif') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxVerticalStrainDif NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizonStrainDifAtPeak') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizonStrainDifAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSHorizonStrainDifAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSHorizonStrainDifAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainDifAtPeak') 
                    and Data_Precision = 8 and Data_Scale = 6;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrainDifAtPeak number (8,6)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSVerticalStrainDifAtPeak') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSVerticalStrainDifAtPeak NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainOdometer') 
                    and Data_Precision = 11 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSPeakStrainOdometer number (11,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainOdometer') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSPeakStrainOdometer NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainDifOdometer') 
                    and Data_Precision = 11 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSPeakStrainDifOdometer number (11,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSPeakStrainDifOdometer') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSPeakStrainDifOdometer NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalPipeMove') 
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxVerticalPipeMove number (7,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxVerticalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxVerticalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalPipeMove') 
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxHorizontalPipeMove number (7,3) ';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxHorizontalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxHorizontalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalPipeMove') 
                    and Data_Precision = 7 and Data_Scale = 3;
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxTotalPipeMove number (7,3)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_tab_columns where upper(Table_Name) = upper('Stg_ILIBendStrain') 
                    AND upper(Column_Name) = upper('ILIBSMaxTotalPipeMove') AND NULLABLE = 'Y';
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Stg_ILIBendStrain MODIFY ILIBSMaxTotalPipeMove NULL';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
    
                END;         
              
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630209 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 10
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630210', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 10';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630210 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                -- Add DataExchangeLoadLock into SystemPreferences.sql
                INSERT INTO SystemPreferences (ParameterName, Value)
                SELECT 'DataExchangeLoadLock', 'False' FROM DUAL where not exists (SELECT * FROM SystemPreferences sp WHERE sp.ParameterName = 'DataExchangeLoadLock');

                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630210 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 11
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630211', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 11';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630211 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                -- Add Load_FloodArea and Load_OperatingData tables.sql
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_FloodArea');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_FloodArea(
                                    Id number(10, 0) NULL,
                                    EffectiveStartDate date NULL,
                                    EffectiveEndDate date NULL,
                                    FloodAreaRangeLD number(7, 0) NULL,
                                    FloodAreaMin number(10, 0) NULL,
                                    FloodAreaMax number(10, 0) NULL,
                                    BeginStationSeriesId number(10, 0) NULL,
                                    BeginStationNum number(13, 5) NOT NULL,
                                    EndStationSeriesId number(10, 0) NULL,
                                    EndStationNum number(13, 5) NOT NULL,
                                    LastModByUserId varchar2(45) DEFAULT user NOT NULL,
                                    LastModDateTime date DEFAULT sysdate NOT NULL,
                                    FloodAreaCode varchar2(30) NULL,
                                    FloodAreaLD number(7, 0) NULL,
                                    SourceId varchar2(50) NOT NULL,
                                    CreatedDate date DEFAULT sysdate NOT NULL,
                                    CreatedUser varchar2(45) DEFAULT user NOT NULL,
                                    BeginStationSeriesGUID varchar2(50) NULL,
                                    EndStationSeriesGUID varchar2(50) NULL,
                                    CheckSumValue int NULL,
                                    CONSTRAINT PK_Load_FloodArea PRIMARY KEY(SourceId)
                                )';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_OperatingData');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_OperatingData(
								Id number(10, 0) NULL,
								EffectiveStartDate date NULL,
								EffectiveEndDate date NULL,
								ProductDomainId number(7, 0) NULL,
								OperatingTemperature number(5, 2) NULL,
								BeginStationSeriesId number(10, 0) NULL,
								BeginStationNum number(13, 5) NOT NULL,
								EndStationSeriesId number(10, 0) NULL,
								EndStationNum number(13, 5) NOT NULL,
								LastModByUserId varchar2(45) DEFAULT user NOT NULL,
								LastModDateTime date DEFAULT sysdate NOT NULL,
								SourceId varchar2(50) NOT NULL,
								CreatedDate date DEFAULT sysdate NOT NULL,
								CreatedUser varchar2(45) DEFAULT user NOT NULL,
								BeginStationSeriesGUID varchar2(50) NULL,
								EndStationSeriesGUID varchar2(50) NULL,
								CheckSumValue int NULL,
                                CONSTRAINT PK_Load_OperatingData PRIMARY KEY(SourceId)
							)';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                    
                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630211 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 12
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630212', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 12';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            COMMIT;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630212 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('FloodArea') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'Alter table FloodArea Add CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
                COMMIT;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630212 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 13
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630213', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 13';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630213 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    -- Removing SourceId and CheckSumValue from MLVCorrectibon and SeriesConnection.sql

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE MLVCorrection DROP COLUMN SourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE MLVCorrection DROP COLUMN CheckSumValue';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE SeriesConnection DROP COLUMN SourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE SeriesConnection DROP COLUMN CheckSumValue';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection DROP COLUMN SourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection DROP COLUMN CheckSumValue';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection DROP COLUMN SourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection DROP COLUMN CheckSumValue';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630213 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 14
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630214', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 14';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630214 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    -- AlterTable_Valve_MechDmg_Stage.sql
                    -- Alter Valve Table to add ValveWithinFenceInd and ValveQstnrPctFraction columns

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Valve') AND UPPER(COLUMN_NAME) = UPPER('ValveWithinFenceInd');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Valve ADD ValveWithinFenceInd varchar2(1) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Valve') AND UPPER(COLUMN_NAME) = UPPER('ValveQstnrPctFraction');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Valve ADD ValveQstnrPctFraction number(5,4) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    -- Alter Mechanical Damage table to add Begin/End StationSeriesId and StationNum Columns, SourceId, InlineInspectionNonCrsnDfct and CreatedDate and CreatedUser

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MechanicalDamage') AND UPPER(COLUMN_NAME) = UPPER('BeginStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MechanicalDamage ADD BeginStationSeriesId number(10,0) null';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MechanicalDamage') AND UPPER(COLUMN_NAME) = UPPER('BeginStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MechanicalDamage ADD BeginStationNum number(13,5) null';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MechanicalDamage') AND UPPER(COLUMN_NAME) = UPPER('EndStationSeriesId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MechanicalDamage ADD EndStationSeriesId number(10,0) null';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MechanicalDamage') AND UPPER(COLUMN_NAME) = UPPER('EndStationNum');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MechanicalDamage ADD EndStationNum number(13,5) null';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MechanicalDamage') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MechanicalDamage ADD SourceId varchar2(50) null';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630214 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 15
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630215', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 15';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630215 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MLVCorrection ADD CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE MLVCorrection ADD SourceId Varchar(50) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE SeriesConnection ADD CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE SeriesConnection ADD SourceId Varchar(50) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_MLVCorrection');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_MLVCorrection AS 
                                            Select * from MLVCorrection WHERE 1 = 0';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_SeriesConnection');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_SeriesConnection AS 
                                            Select * from SeriesConnection WHERE 1 = 0';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630215 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection ADD CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_MLVCorrection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_MLVCorrection ADD SourceId Varchar(50) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection ADD CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_SeriesConnection') AND UPPER(COLUMN_NAME) = UPPER('SourceId');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_SeriesConnection ADD SourceId Varchar(50) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630215 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 16
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630216', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 16';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630216 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN

                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_Valve');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_Valve AS 
                                            Select * from Valve WHERE 1 = 0';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630216 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_Valve') AND UPPER(COLUMN_NAME) = UPPER('ValveWithinFenceInd');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'Alter Table Load_Valve Add ValveWithinFenceInd varchar(1) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('Load_Valve') AND UPPER(COLUMN_NAME) = UPPER('ValveQstnrPctFraction');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'Alter Table Load_Valve Add ValveQstnrPctFraction numeric(5,4) NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630216 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 17
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630217', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 17';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630217 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TAB_COLUMNS WHERE UPPER(TABLE_NAME) = UPPER('OperatingData') AND UPPER(COLUMN_NAME) = UPPER('CheckSumValue');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE OperatingData ADD CheckSumValue INT NULL';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630217 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 18
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630218', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 18';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630218 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_CrossingLocn');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_CrossingLocn AS
                                            SELECT * FROM CrossingLocn WHERE 1 = 0';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_CouponReading');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'CREATE TABLE Load_CouponReading AS
                                            SELECT * FROM CouponReading WHERE 1 = 0';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630218 AND dbVersionCheckPoint = 1
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_RectifierReadingSourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_RectifierReading
                                            DROP CONSTRAINT Pk_RectifierReadingSourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_CrossingLocnSourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CrossingLocn
                                            DROP CONSTRAINT Pk_CrossingLocnSourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_CouponReadingSourceId');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CouponReading
                                            DROP CONSTRAINT Pk_CouponReadingSourceId';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_Load_CouponReading');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CouponReading
                                            DROP CONSTRAINT Pk_Load_CouponReading';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_Load_CrossingLocn');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CrossingLocn
                                            DROP CONSTRAINT Pk_Load_CrossingLocn';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('PK_Load_RectifierReading');
                    
                    IF CNT > 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_RectifierReading
                                            DROP CONSTRAINT PK_Load_RectifierReading';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630218 AND dbVersionCheckPoint = 2
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('PK_Load_RectifierReading');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_RectifierReading ADD CONSTRAINT PK_Load_RectifierReading PRIMARY KEY (SourceId, RctfrReadingDate)';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_Load_CrossingLocn');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CrossingLocn ADD CONSTRAINT Pk_Load_CrossingLocn PRIMARY KEY (SourceId, StationSeriesId)';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('Pk_Load_CouponReading');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE Load_CouponReading ADD CONSTRAINT Pk_Load_CouponReading PRIMARY KEY (SourceId, CouponReadingDate)';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630218 AND dbVersionCheckPoint = 3
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 19
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630219', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 19';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630219 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    select count(*) INTO CNT from user_constraints
                    where constraint_type = 'P' AND upper(Constraint_Name) = upper('PK_FloodArea');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE FloodArea ADD CONSTRAINT PK_FloodArea Primary Key (Id)';
                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630219 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 20
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630220', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 20';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630220 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(8000);
                
                BEGIN
                    SELECT count(*) INTO CNT FROM User_Procedures where Object_Type = 'PROCEDURE' and upper(Object_Name) = upper('sp_Before_Load_VirtualTable');
                
                    IF CNT = 0
                    THEN
                        sqlStatement := 'Create or replace PROCEDURE sp_Before_Load_VirtualTable(VirtualTableList varchar) 
                                            AS
                                            BEGIN
                                                DECLARE sqlStatement varchar(4000);
                                            
                                                BEGIN
                                                    sqlStatement := ''DELETE FROM VirtualTableDataDate WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' ||  VirtualTableList || ''))'';
                                                
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    sqlStatement := ''DELETE FROM VirtualTableDataFlg WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' || VirtualTableList || ''))'';
                                            
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    sqlStatement := ''DELETE FROM VirtualTableDataInd WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' || VirtualTableList || ''))'';
                                            
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    sqlStatement := ''DELETE FROM VirtualTableDataNum WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' || VirtualTableList || ''))'';
                                            
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    sqlStatement := ''DELETE FROM VirtualTableDataString WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' || VirtualTableList || ''))'';
                                            
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    sqlStatement := ''DELETE FROM VirtualTableDataListDomain WHERE VirtualTableId IN (''
                                                                    || ''SELECT vt.Id FROM VirtualTable vt ''
                                                                    || ''WHERE vt.VirtualTableName IN ('' || VirtualTableList || ''))'';
                                            
                                                    EXECUTE IMMEDIATE sqlStatement;
                                            
                                                    DELETE from VIRTUALTABLESTATIONING
                                                    where (VIRTUALTABLEID, VIRTUALTABLESTATIONINGID) NOT IN 
                                                    (
                                                        select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATADATE
                                                        union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAFLG
                                                        union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATAIND
                                                        union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATALISTDOMAIN
                                                        union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATANUM
                                                        union select VIRTUALTABLEID, VIRTUALTABLESTATIONINGID from VIRTUALTABLEDATASTRING
                                                    );                                
                                                                            
                                                END;
                                            END;';
                                                                        
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;
                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630220 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 21
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630221', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 21';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630221 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    sqlStatement := 'CREATE OR REPLACE PROCEDURE sp_LoadHCAReasons
                                        AS
                                        BEGIN
                                              DELETE FROM HCAReasons;
                                        
                                              INSERT INTO HCAReasons (HCACFRSEgID, RCHCAReasonTypeId)
                                              Select ID, CASE WHEN (RCReasonTypeID IS NULL) THEN 16 ELSE RCREASONTYPEID END AS RCReasonTypeID from HCACFRSeg;
                                        END;';
                                                                     
                    EXECUTE IMMEDIATE sqlStatement;
                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630221 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 22
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630222', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 22';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630222 AND dbVersionCheckPoint = 0
        THEN
            BEGIN
                DECLARE CNT INT;
                sqlStatement varchar(4000);
                
                BEGIN
                    Select COUNT(*) INTO CNT from User_Tab_Columns Where Upper(Table_Name) = Upper('RiskResultData') AND  Upper(Column_Name) = Upper('ResultTableName');
                    
                    IF CNT = 0
                    THEN
                        sqlStatement := 'ALTER TABLE RiskResultData ADD ResultTableName VARCHAR2(100)';
                        EXECUTE IMMEDIATE sqlStatement;
                    END IF;

                END;
                UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            END;           
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630222 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 2 Updates 23
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630223', DBVersionComment = 'Service Pack DDL 6.3, Rel. 2, Updates 23';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

