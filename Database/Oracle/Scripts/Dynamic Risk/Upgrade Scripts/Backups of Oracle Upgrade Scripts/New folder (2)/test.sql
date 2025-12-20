DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640101 AND dbVersionCheckPoint = 3
    THEN
    -- Taken From script "Script To add CheckSumValue, SourceId, CreatedDate and CreatedUser To CoatingCondition and Create Load_CoatingCondition.sql"
       
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('CheckSumValue');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingCondition ADD CheckSumValue int NULL';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('SourceId');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingCondition ADD SourceId varchar2(50) NOT NULL';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('CreatedDate');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingCondition ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('CreatedDate')
        AND data_default IS NOT NULL;

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingCondition MODIFY CreatedDate DEFAULT CURRENT_DATE';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('CreatedUser');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE CoatingCondition ADD CreatedUser varchar2(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = UPPER('CoatingCondition')
        AND column_name = UPPER('CreatedUser')
        AND data_default IS NOT NULL;

          IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE CoatingCondition MODIFY CreatedUser DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = UPPER('Load_CoatingCondition');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'CREATE TABLE Load_CoatingCondition(
                Id NUMBER(10, 0) NOT NULL,
                EffectiveStartDate DATE NOT NULL,
                EffectiveEndDate DATE NULL,
                ExcavationSiteId NUMBER(10, 0) NOT NULL,
                CoatingCondLineTypeLD NUMBER(7, 0) NOT NULL,
                CoatingCondWeldTypeLD NUMBER(7, 0) NOT NULL,
                CoatingCondLineFoundDomainId NUMBER(7, 0) NOT NULL,
                CoatingCondWeldFoundDomainId NUMBER(7, 0) NOT NULL,
                CoatingCondYearCoatingApplied DATE NULL,
                CoatingCondApplicationTypeLD NUMBER(7, 0) NOT NULL,
                CoatCondComment VARCHAR2(255) NULL,
                BeginStationSeriesId NUMBER(10, 0) NULL,
                BeginStationNum NUMBER(13, 5) NULL,
                EndStationSeriesId NUMBER(10, 0) NULL,
                EndStationNum NUMBER(13, 5) NULL,
                LastModByUserId VARCHAR2(45) NOT NULL,
                LastModDateTime DATE NOT NULL,
                BeginDistFromGirthWeld NUMBER(10, 3) NULL,
                EndDistFromGirthWeld NUMBER(10, 3) NULL,
                SourceId VARCHAR2(50) NOT NULL,
                CreatedDate DATE NOT NULL,
                CreatedUser VARCHAR2(45) NOT NULL,
                CheckSumValue INT NOT NULL,
            CONSTRAINT PK_CoatingConditionSourceId PRIMARY KEY (SourceId))';
        END IF;
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 4;
        COMMIT;
    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/