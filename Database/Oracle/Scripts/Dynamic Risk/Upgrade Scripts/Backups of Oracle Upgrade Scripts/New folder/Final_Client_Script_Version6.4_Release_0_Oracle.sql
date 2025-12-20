SET SERVEROUTPUT ON

DECLARE dbVersion number(10);
dbVersionCheckPoint number(5);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 0
    THEN
        INSERT INTO SystemPreferences (ParameterName,Value)
        SELECT 'DatabaseType', 'Stage' FROM dual WHERE NOT Exists (SELECT * FROM SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType');
        
        -- AlterSchemaDigTables_ExcavationSiteCrackAnomaly_Stage.sql
        --Script To Run On Stage Database

        -- Alter Table ExcavationSiteCrackAnomaly in Stage database
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('SourceId');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD SOURCEID VARCHAR(50)  NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('EffectiveStartDate') AND NULLABLE = 'Y';
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY MODIFY EFFECTIVESTARTDATE DATE NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                

            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('ExcavationSiteId') AND NULLABLE = 'Y';
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY MODIFY EXCAVATIONSITEID NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                
            
            -- Add Begin/End StationSeriesId, StationNum and GUID columns
            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD BEGINSTATIONSERIESID NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('BeginStationNum');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD BEGINSTATIONNUM NUMBER(13,5) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD ENDSTATIONSERIESID NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('EndStationNum');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD ENDSTATIONNUM NUMBER(13,5) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('CreatedDate');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD CREATEDDATE DATE DEFAULT SYSDATE NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM User_Tab_Columns WHERE UPPER(Table_Name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('CreatedUser');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD CREATEDUSER VARCHAR(45) DEFAULT USER NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            SELECT COUNT(*) INTO CNT FROM user_constraints
            WHERE constraint_type = 'R' AND UPPER(Constraint_Name) = UPPER('FK_EXSITECRCKANO_BEGSSID');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD CONSTRAINT FK_EXSITECRCKANO_BEGSSID FOREIGN KEY(BEGINSTATIONSERIESID) REFERENCES STATIONSERIES (ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints
            WHERE constraint_type = 'R' AND UPPER(Constraint_Name) = UPPER('FK_ExSiteCrckAno_EndSSId');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD CONSTRAINT FK_EXSITECRCKANO_ENDSSID FOREIGN KEY(ENDSTATIONSERIESID) REFERENCES STATIONSERIES (ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            sqlStatement := 'UPDATE ExcavationSiteCrackAnomaly SET CreatedDate = sysdate WHERE CreatedDate IS NULL';
            EXECUTE IMMEDIATE sqlStatement;
            
            sqlStatement := 'UPDATE ExcavationSiteCrackAnomaly SET CreatedUser = user WHERE CreatedUser IS NULL';
            EXECUTE IMMEDIATE sqlStatement;

        END;
        
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

 
DECLARE dbVersion number(10);
dbVersionCheckPoint number(5);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 1
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            
            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('CreatedDate') AND NULLABLE = 'Y';
        
            IF CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly MODIFY CreatedDate date NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(Column_Name) = UPPER('CreatedUser') AND NULLABLE = 'Y';
        
            IF CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly MODIFY CreatedUser varchar2(45) NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            -- AlterTable_PipeCond_Stage.sql
            -- Alter PipeCondition table Drop Primary Key on Id Column 

            SELECT COUNT(*) INTO CNT FROM USER_CONSTRAINTS 
            WHERE CONSTRAINT_TYPE = 'P'
            AND UPPER(CONSTRAINT_NAME) = UPPER('PK_PipeCondition');

            IF CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition DROP CONSTRAINT PK_PipeCondition';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            -- Alter PipeCondition table to add SourceId, ExcavationSiteGUID, CreatedDate and CreatedUser
            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('PipeCondition') AND UPPER(Column_Name) = UPPER('SourceId');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition ADD SourceId varchar2(50)  null';
                EXECUTE IMMEDIATE sqlStatement;
            END  IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('PipeCondition') AND UPPER(Column_Name) = UPPER('CreatedDate');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition ADD CreatedDate date DEFAULT sysdate NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('PipeCondition') AND UPPER(Column_Name) = UPPER('CreatedUser');
            
            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition ADD CreatedUser varchar2(45) DEFAULT user NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;
        
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
    CNT INT;
    sqlStatement VARCHAR(4000);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 2
    THEN
        
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE Table_name = UPPER('ExcavationGirthWeld') 
            AND Column_Name = UPPER('BeginStationSeriesId');
        
        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE Table_name = UPPER('ExcavationGirthWeld') 
            AND Column_Name = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') 
            AND UPPER(Column_Name) = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('MechanicalDamage') 
            AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('MechanicalDamage') 
            AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('MechanicalDamage') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('MechanicalDamage') 
            AND UPPER(Column_Name) = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;
        
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') 
            AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') 
            AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('ExcavationSiteCrackAnomaly') 
            AND UPPER(Column_Name) = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;
        
        SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('PipeSoilPotentialPipe') AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('PipeSoilPotentialPipe') AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('PipeSoilPotentialPipe') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('PipeSoilPotentialPipe') 
            AND UPPER(Column_Name) = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CoatingDefect') 
            AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CoatingDefect') 
            AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CoatingDefect') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CoatingDefect') 
            AND UPPER(Column_Name) = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CorrosionDeposit') 
            AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD BeginStationSeriesId number(10,0) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CorrosionDeposit') 
            AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD BeginStationNum NUMBER(13,5) NULL';
        END  IF;
    
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE UPPER(Table_name) = UPPER('CorrosionDeposit') 
            AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD EndStationSeriesId NUMBER(10,0) NULL';
        END  IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns 
        WHERE Table_name = UPPER('CorrosionDeposit') 
            AND Column_Name = UPPER('EndStationNum');
        
        IF CNT = 0
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD EndStationNum NUMBER(13,5) NULL';
        END  IF;
    
    
    
        EXECUTE IMMEDIATE 'UPDATE ExcavationGirthWeld 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';

        EXECUTE IMMEDIATE 'UPDATE MechanicalDamage 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';

        EXECUTE IMMEDIATE 'UPDATE ExcavationSiteCrackAnomaly 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';

        EXECUTE IMMEDIATE 'UPDATE PipeSoilPotentialPipe 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';

        EXECUTE IMMEDIATE 'UPDATE CoatingDefect 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';

        EXECUTE IMMEDIATE 'UPDATE CorrosionDeposit 
            SET BeginStationSeriesId = StationSeriesId, 
            EndStationSeriesId = StationSeriesId, 
            BeginStationNum = StationNum, 
            EndStationNum = StationNum';


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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 3
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationGirthWeld')
            AND UPPER(FK_Column) = UPPER('BeginStationSeriesId');
            
            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld  
                                    ADD CONSTRAINT FK_ExcavationGWBegStnSrsId FOREIGN KEY(BeginStationSeriesId)
                                    REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationGirthWeld')
            AND UPPER(FK_Column) = UPPER('EndStationSeriesId');
            
            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ExcavationGirthWeld  
                                        ADD  CONSTRAINT FK_ExcavationGWEndStnSrsId FOREIGN KEY(EndStationSeriesId) 
                                        REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('MechanicalDamage')
            AND UPPER(FK_Column) = UPPER('BeginStationSeriesId');
            
            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage  
                                    ADD  CONSTRAINT FK_MechanicalDamageBegStnSrsId FOREIGN KEY(BeginStationSeriesId) 
                                    REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('MechanicalDamage')
            AND UPPER(FK_Column) = UPPER('EndStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE MechanicalDamage  ADD  CONSTRAINT FK_MechanicalDamageEndStnSrsId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationSiteCrackAnomaly')
            and UPPER(FK_Column) = UPPER('BeginStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly  
                                    ADD  CONSTRAINT FK_ExcavationCABegStnSrsId FOREIGN KEY(BeginStationSeriesId) 
                                    REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationSiteCrackAnomaly')
            AND UPPER(FK_Column) = UPPER('EndStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ExcavationSiteCrackAnomaly ADD  CONSTRAINT FK_ExcavationCAEndStnSrsId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('PipeSoilPotentialPipe')
            AND UPPER(FK_Column) = UPPER('BeginStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD  CONSTRAINT FK_PSPPipeBegStnSrsId FOREIGN KEY(BeginStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('PipeSoilPotentialPipe')
            and UPPER(FK_Column) = UPPER('EndStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE PipeSoilPotentialPipe ADD  CONSTRAINT FK_PSPPipeEndStnSrsId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('CoatingDefect')
            and UPPER(FK_Column) = UPPER('BeginStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD  CONSTRAINT FK_CoatingDefectBegStnSrsId FOREIGN KEY(BeginStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('CoatingDefect')
            and UPPER(FK_Column) = UPPER('EndStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CoatingDefect ADD  CONSTRAINT FK_CoatingDefectEndStnSrsId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('CorrosionDeposit')
            AND UPPER(FK_Column) = UPPER('BeginStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD  CONSTRAINT FK_CorrosionDepositBegStnSrsId FOREIGN KEY(BeginStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('CorrosionDeposit')
            AND UPPER(FK_Column) = UPPER('EndStationSeriesId');

            -- Set the values of the newly added fields and add the field constraints
            IF CNT = 0
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CorrosionDeposit ADD  CONSTRAINT FK_CorrosionDepositEndStnSrsId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
            END IF;
        END;
        
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 4
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN

            -- CLIENT_Remove_Excavation_Constraints35196.sql
            -- Drop old database constraints for Excavation table
            -- NOTE only the orientation and percent have actual range checks now, the rest are simply checked that they can be saved to the database.
            
            SELECT COUNT(*) INTO CNT 
            FROM user_constraints 
            WHERE UPPER(constraint_name) = UPPER('CKC_MECHDMGORIENTATIO_MECHANIC');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGORIENTATIO_MECHANIC';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_MECHDMGLENGTH_MECHANIC');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGLENGTH_MECHANIC';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_MECHDMGWIDTH_MECHANIC');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGWIDTH_MECHANIC';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CK__Mechanica__MechD__18E19391');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CK__Mechanica__MechD__18E19391';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CK__Mechanica__MechD__17ED6F58');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CK__Mechanica__MechD__17ED6F58';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
                
            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_MECHDMGPEAKTOPEAK_MECHANIC');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGPEAKTOPEAK_MECHANIC';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
                
            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_MECHDMGWAVELENGTH_MECHANIC');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE MechanicalDamage DROP CONSTRAINT CKC_MECHDMGWAVELENGTH_MECHANIC';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
                
            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CK_ESCA_ESCAS_SurfInd');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CK_ESCA_ESCAS_SurfInd';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_ESCALENGTH_ESCA');
            
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CKC_ESCALENGTH_ESCA';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CK_ESCA_ESCAWidth');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CK_ESCA_ESCAWidth';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_ESCAORIENTATION_ESCA');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationSiteCrackAnomaly DROP CONSTRAINT CKC_ESCAORIENTATION_ESCA';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_GIRTHWELDREFERENC_EXCAVATI');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld DROP CONSTRAINT CKC_GIRTHWELDREFERENC_EXCAVATI';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_PIPECONDOUTSIDEDI_PIPECOND');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDOUTSIDEDI_PIPECOND';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_PIPECONDWALLTHICK_PIPECOND');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDWALLTHICK_PIPECOND';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_PIPECONDGRADE_PIPECOND');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDGRADE_PIPECOND';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints WHERE UPPER(constraint_name) = UPPER('CKC_PIPECONDWELDBEADH_PIPECOND');
                
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PipeCondition DROP CONSTRAINT CKC_PIPECONDWELDBEADH_PIPECOND';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;
        
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 5
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            --ExcavationGirthWeld_Stage.sql
            -- Alter Table ExcavationGirthWeld in Stage database

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('SourceId');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD SourceId varchar2(50) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
            
            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('EffectiveStartDate') AND NULLABLE ='N';
        
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld MODIFY EffectiveStartDate date NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;
        
            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('ExcavationSiteId') AND NULLABLE ='N';
        
            if CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld MODIFY ExcavationSiteId NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            -- Add Begin/End StationSeriesId, StationNum and GUID columns
            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('BeginStationSeriesId');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD BeginStationSeriesId NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('BeginStationNum');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD BeginStationNum NUMBER(13,5) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('EndStationSeriesId');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD EndStationSeriesId NUMBER(10,0) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('EndStationNum');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD EndStationNum NUMBER(13,5) NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('CreatedDate');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_tab_columns WHERE UPPER(Table_name) = UPPER('ExcavationGirthWeld') AND UPPER(Column_Name) = UPPER('CreatedUser');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD CreatedUser varchar2(45) DEFAULT USER NOT NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;
        
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 630223 AND dbVersionCheckPoint = 6
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            --ExcavationGirthWeld_Stage.sql
        
            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationGirthWeld')
            and UPPER(FK_Column) = UPPER('BeginStationSeriesId');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD  CONSTRAINT FK_ExcGirthWld_BegStnSeriesId FOREIGN KEY(BeginStationSeriesId) REFERENCES StationSeries (Id)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationGirthWeld')
            and UPPER(FK_Column) = UPPER('EndStationSeriesId');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD CONSTRAINT FK_ExcGirthWld_EndStnSeriesId FOREIGN KEY(EndStationSeriesId) REFERENCES StationSeries (Id)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM (
            SELECT distinct c.CONSTRAINT_NAME as FK_Name, a.table_name as FK_Table, a.column_name as FK_Column, uc.table_name as PK_Table, uc.column_name as PK_Column
            FROM user_cons_columns a
            JOIN user_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN user_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            JOIN user_CONS_COLUMNS uc on uc.constraint_name = c.r_constraint_name) tmp
            WHERE UPPER(FK_Table) = UPPER('ExcavationGirthWeld')
            and UPPER(FK_Column) = UPPER('ExcavationSiteId');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE ExcavationGirthWeld ADD  CONSTRAINT FK_ExcGirthWld_ExcvSiteId FOREIGN KEY(ExcavationSiteId) REFERENCES ExcavationSite (Id)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;
        
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
    IF dbVersion = 630223 AND dbVersionCheckPoint = 7
    THEN
            /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 0 Updates 01
        /********************************************************************************************************/
        UPDATE VersionInfo
        SET DBVersion = '640001', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 01';
        
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640001 AND dbVersionCheckPoint = 0
    THEN
        DECLARE 
            CNT INT;
            sqlStatement VARCHAR(8000);
        BEGIN
            -- AddLoadLITables_ILICheckSumValue_Stage.sql
            -- Create Load_ILI tables and CheckSumValue columns for the ILI tables.

            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_InlineInspection');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE Load_InlineInspection(
                        Id NUMBER(10, 0) NOT NULL,
                        MaintenanceId NUMBER(10, 0) NULL,
                        ILIName VARCHAR2(50) NULL,
                        ILICompanyDomainId NUMBER(7, 0) NULL,
                        ILICallBoxInteractRuleDomainId NUMBER(7, 0) NULL,
                        ILIReportReceivedDate DATE NULL,
                        ILIStartDate DATE NULL,
                        ILIEndDate DATE NULL,
                        ILIDescr VARCHAR2(255) NULL,
                        ILIStatusDomainId NUMBER(7, 0) NULL,
                        ILITypeDomainId NUMBER(7, 0) NULL,
                        ILIBaselineAssessmentFlg NUMBER(1, 0) NULL,
                        ILIDummyToolFlg NUMBER(1, 0) NULL,
                        ILIBenchMarkFlg NUMBER(1, 0) NULL,
                        ILIStartDate2 DATE NULL,
                        ILIEndDate2 DATE NULL,
                        SpecVersion VARCHAR2(20) NULL,
                        AppVersion VARCHAR2(255) NULL,
                        Stg_ILIId NUMBER(10, 0) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        MeasuredFROM VARCHAR2(50) NULL,
                        SystemOfMeasure VARCHAR2(25) NULL,
                        AlignmentType VARCHAR2(15) NULL,
                        DscvryDt DATE NULL,
                        BaseIliId NUMBER(10, 0) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILISourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
        END IF;
        
        SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_ILICrackAnomaly');
            
        IF CNT = 0
        THEN
            sqlStatement := 'CREATE TABLE Load_ILICrackAnomaly(
                    Id NUMBER(10, 0) NOT NULL,
                    EffectiveStartDate DATE NULL,
                    EffectiveEndDate DATE NULL,
                    InlineInspectionRangeId NUMBER(10, 0) NULL,
                    ILICAVendorPackageCode VARCHAR2(50) NULL,
                    ILICATypeDomainId NUMBER(7, 0) NULL,
                    ILICAAnomalyNumber VARCHAR2(15) NULL,
                    ILICAOdometer NUMBER(10, 3) NULL,
                    ILICAAnomalyDepth VARCHAR2(15) NULL,
                    ILICAGirthWeldNum VARCHAR2(25) NULL,
                    ILICADistanceFROMGirthWeld NUMBER(10, 3) NULL,
                    ILICALargestIndividualInd NUMBER(10, 3) NULL,
                    ILICALength NUMBER(10, 3) NULL,
                    ILICAWidth NUMBER(10, 3) NULL,
                    ILICAOrientation NUMBER(6, 3) NULL,
                    ILICAFailPressAlgthmDomainId NUMBER(7, 0) NULL,
                    ILICAFailurePressure NUMBER(16, 4) NULL,
                    ILICARupturePressureRatio NUMBER(5, 3) NULL,
                    ILICACAOP NUMBER(5, 0) NULL,
                    ILICASurfaceInd VARCHAR2(2) NULL,
                    ILICADescr VARCHAR2(254) NULL,
                    ILICAComment VARCHAR2(255) NULL,
                    ILICAGrading1DomainId NUMBER(7, 0) NULL,
                    ILICAGrading2DomainId NUMBER(7, 0) NULL,
                    ILICAX NUMBER(12, 3) NULL,
                    ILICAY NUMBER(12, 3) NULL,
                    ILICAZ NUMBER(10, 3) NULL,
                    StationSeriesId NUMBER(10, 0) NULL,
                    StationNum NUMBER(13, 5) NULL,
                    ILICAFPRtc NUMBER(10, 3) NULL,
                    ILICAFPR NUMBER(10, 3) NULL,
                    ILICAGirthWeldNumDS VARCHAR2(25) NULL,
                    ILICADistanceFROMGirthWeldDS NUMBER(10, 3) NULL,
                    ILICALatitude NUMBER(11, 9) NULL,
                    ILICALongitude NUMBER(12, 9) NULL,
                    AppVersion VARCHAR2(255) NULL,
                    LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                    LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                    ILICAStatusDomainId NUMBER(7, 0) NULL,
                    ILICAAnomalyType char(1) NULL,
                    POE NUMBER(15, 14) NULL,
                    ResponseTime DATE NULL,
                    RelativePosition VARCHAR2(10) NULL,
                    CalcLatitude NUMBER(11, 9) NULL,
                    CalcLongitude NUMBER(12, 9) NULL,
                    UpdateAudit VARCHAR2(255) NULL,
                    DscvryDt DATE NULL,
                    UpdtDscvryDt DATE NULL,
                    OperatorComment VARCHAR2(255) NULL,
                    DscvryDtUpdReasonDomainId NUMBER(7, 0) NULL,
                    GrowthRate NUMBER(9, 7) NULL,
                    ILICADepthDomainID NUMBER(7, 0) NULL,
                    ILICADepthPct NUMBER(8, 5) NULL,
                    SentencedResponseTime DATE NULL,
                    BeginStationSeriesId NUMBER(10, 0) NULL,
                    BeginStationNum NUMBER(13, 5) NULL,
                    EndStationSeriesId NUMBER(10, 0) NULL,
                    EndStationNum NUMBER(13, 5) NULL,
                    SourceId VARCHAR2(50) NOT NULL,
                    CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                    CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                    InlineInspectionId NUMBER(10, 0) NULL,
                    GrowthRateLength NUMBER(9, 7) NULL,
                    IRASCustomDate1 DATE NULL,
                    IRASCustomDate2 DATE NULL,
                    IRASCustomDate3 DATE NULL,
                    IRASCustomDate4 DATE NULL,
                    IRASCustomDate5 DATE NULL,
                    IRASCustomNum1 float NULL,
                    IRASCustomNum2 float NULL,
                    IRASCustomNum3 float NULL,
                    IRASCustomNum4 float NULL,
                    IRASCustomNum5 float NULL,
                    IRASCustomString1 VARCHAR2(255) NULL,
                    IRASCustomString2 VARCHAR2(255) NULL,
                    IRASCustomString3 VARCHAR2(255) NULL,
                    IRASCustomString4 VARCHAR2(255) NULL,
                    IRASCustomString5 VARCHAR2(255) NULL,
                    ILICAGrowthRateDepth NUMBER(6, 4) NULL,
                    ILICAGrowthRateLength NUMBER(6, 4) NULL,
                    ILICAESF NUMBER(6, 4) NULL,
                    ILICADepthTolerance NUMBER(8, 3) NULL,
                    ILICALengthTolerance NUMBER(10, 3) NULL,
                    ILICAWidthTolerance NUMBER(10, 3) NULL,
                    ILICADepthToleranceStdDev NUMBER(8, 3) NULL,
                    ILICALengthToleranceStdDev NUMBER(10, 3) NULL,
                    ILICAWidthToleranceStdDev NUMBER(10, 3) NULL,
                    CheckSumValue int NOT NULL,
                    CONSTRAINT PK_ILICASourceId PRIMARY KEY (SourceId)
                )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF; 

        SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_ILICrsnCallBox');
            
        IF CNT = 0
        THEN
            sqlStatement := 'CREATE TABLE Load_ILICrsnCallBox(
                        Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE NULL,
                        EffectiveEndDate DATE NULL,
                        InlineInspectionRangeId NUMBER(10, 0) NOT NULL,
                        InlineInspectionFeatureId NUMBER(10, 0) NULL,
                        ILICBStatusDomainId NUMBER(7, 0) NULL,
                        ILICBOdometer NUMBER(10, 3) NULL,
                        ILICBCrsnCallBoxNumber VARCHAR2(15) NULL,
                        ILICBDepthPct NUMBER(8, 5) NULL,
                        ILICBLength NUMBER(10, 3) NULL,
                        ILICBWidth NUMBER(10, 3) NULL,
                        ILICBOrientation NUMBER(6, 3) NULL,
                        ILICBFailPressAlgthmDomainId NUMBER(7, 0) NULL,
                        ILICBFailurePressure NUMBER(16, 4) NULL,
                        ILICBRupturePressureRatio NUMBER(7, 3) NULL,
                        ILICBManualSizedInd char(1) NULL,
                        ILICBSurfaceInd VARCHAR2(2) NULL,
                        ILICBComment VARCHAR2(255) NULL,
                        StationSeriesId NUMBER(10, 0) NULL,
                        StationNum NUMBER(13, 5) NULL,
                        ILICBLatitude NUMBER(11, 9) NULL,
                        ILICBLongitude NUMBER(12, 9) NULL,
                        ILICBCoordSysDomainId NUMBER(7, 0) NULL,
                        ILICBX NUMBER(12, 3) NULL,
                        ILICBY NUMBER(12, 3) NULL,
                        ILICBZ NUMBER(10, 3) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        ILICBVendorPackageCode VARCHAR2(10) NULL,
                        ILICBGirthWeldNumUS VARCHAR2(25) NULL,
                        ILICBDistanceFROMGirthWeldUS NUMBER(10, 3) NULL,
                        ILICBGirthWeldNumDS VARCHAR2(25) NULL,
                        ILICBDistanceFROMGirthWeldDS NUMBER(10, 3) NULL,
                        ILICBFPR NUMBER(5, 3) NULL,
                        ILICBFPRtc NUMBER(5, 3) NULL,
                        MetalLossType VARCHAR2(50) NULL,
                        CalcLatitude NUMBER(11, 9) NULL,
                        CalcLongitude NUMBER(12, 9) NULL,
                        UpdateAudit VARCHAR2(255) NULL,
                        DscvryDt DATE NULL,
                        UpdtDscvryDt DATE NULL,
                        OperatorComment VARCHAR2(255) NULL,
                        DscvryDtUpdReasonDomainId NUMBER(7, 0) NULL,
                        GrowthRate NUMBER(9, 7) NULL,
                        BeginStationSeriesId NUMBER(10, 0) NULL,
                        BeginStationNum NUMBER(13, 5) NULL,
                        EndStationSeriesId NUMBER(10, 0) NULL,
                        EndStationNum NUMBER(13, 5) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        InlineInspectionId NUMBER(10, 0) NULL,
                        IRASCustomDate1 DATE NULL,
                        IRASCustomDate2 DATE NULL,
                        IRASCustomDate3 DATE NULL,
                        IRASCustomDate4 DATE NULL,
                        IRASCustomDate5 DATE NULL,
                        IRASCustomNum1 float NULL,
                        IRASCustomNum2 float NULL,
                        IRASCustomNum3 float NULL,
                        IRASCustomNum4 float NULL,
                        IRASCustomNum5 float NULL,
                        IRASCustomString1 VARCHAR2(255) NULL,
                        IRASCustomString2 VARCHAR2(255) NULL,
                        IRASCustomString3 VARCHAR2(255) NULL,
                        IRASCustomString4 VARCHAR2(255) NULL,
                        IRASCustomString5 VARCHAR2(255) NULL,
                        ILICBERF NUMBER(6, 4) NULL,
                        ILICBDepthTolerance NUMBER(8, 3) NULL,
                        ILICBLengthTolerance NUMBER(10, 3) NULL,
                        ILICBWidthTolerance NUMBER(10, 3) NULL,
                        ILICBDepthToleranceStdDev NUMBER(8, 3) NULL,
                        ILICBLengthToleranceStdDev NUMBER(10, 3) NULL,
                        ILICBWidthToleranceStdDev NUMBER(10, 3) NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILICBSourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF; 

        SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_InlineInspectionFacility');
            
        IF CNT = 0
        THEN
            sqlStatement := 'CREATE TABLE Load_InlineInspectionFacility(
                        Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE NULL,
                        EffectiveEndDate DATE NULL,
                        InlineInspectionRangeId NUMBER(10, 0) NOT NULL,
                        ILIFacTypeDomainId NUMBER(7, 0) NULL,
                        ILIFacStatusDomainId NUMBER(7, 0) NULL,
                        ILIFacOdometer NUMBER(10, 3) NULL,
                        ILIFacGirthWeldNum VARCHAR2(25) NULL,
                        ILIFacDistanceFROMGirthWeld NUMBER(10, 3) NULL,
                        ILIFacOrientation NUMBER(6, 3) NULL,
                        ILIFacDescr VARCHAR2(255) NULL,
                        StationSeriesId NUMBER(10, 0) NULL,
                        StationNum NUMBER(13, 5) NULL,
                        ILIFacNumber VARCHAR2(30) NULL,
                        ILIFacLatitude NUMBER(11, 9) NULL,
                        ILIFacLongitude NUMBER(12, 9) NULL,
                        ILIFacCoordSysDomainId NUMBER(7, 0) NULL,
                        ILIFacX NUMBER(12, 3) NULL,
                        ILIFacY NUMBER(12, 3) NULL,
                        ILIFacZ NUMBER(10, 3) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        ILIFToolSpeed NUMBER(7, 3) NULL,
                        CalcLatitude NUMBER(11, 9) NULL,
                        CalcLongitude NUMBER(12, 9) NULL,
                        OperatorComment VARCHAR2(255) NULL,
                        BeginStationSeriesId NUMBER(10, 0) NULL,
                        BeginStationNum NUMBER(13, 5) NULL,
                        EndStationSeriesId NUMBER(10, 0) NULL,
                        EndStationNum NUMBER(13, 5) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        InlineInspectionId NUMBER(10, 0) NULL,
                        IRASCustomDate1 DATE NULL,
                        IRASCustomDate2 DATE NULL,
                        IRASCustomDate3 DATE NULL,
                        IRASCustomDate4 DATE NULL,
                        IRASCustomDate5 DATE NULL,
                        IRASCustomNum1 float NULL,
                        IRASCustomNum2 float NULL,
                        IRASCustomNum3 float NULL,
                        IRASCustomNum4 float NULL,
                        IRASCustomNum5 float NULL,
                        IRASCustomString1 VARCHAR2(255) NULL,
                        IRASCustomString2 VARCHAR2(255) NULL,
                        IRASCustomString3 VARCHAR2(255) NULL,
                        IRASCustomString4 VARCHAR2(255) NULL,
                        IRASCustomString5 VARCHAR2(255) NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILIFacSourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF; 
            
        SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_InlineInspectionFeature');
            
        IF CNT = 0
        THEN
            sqlStatement := 'CREATE TABLE Load_InlineInspectionFeature(
                        Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE NULL,
                        EffectiveEndDate DATE NULL,
                        InlineInspectionRangeId NUMBER(10, 0) NOT NULL,
                        ILIFTypeDomainId NUMBER(7, 0) NULL,
                        ILIFStatusDomainId NUMBER(7, 0) NULL,
                        ILIFOdometer NUMBER(10, 3) NULL,
                        ILIFFeatureNumber VARCHAR2(15) NULL,
                        ILIFPeakDepthPct NUMBER(8, 5) NULL,
                        ILIFGirthWeldNum VARCHAR2(25) NULL,
                        ILIFDistanceFROMGirthWeld NUMBER(10, 3) NULL,
                        ILIFLength NUMBER(10, 3) NULL,
                        ILIFWidth NUMBER(10, 3) NULL,
                        ILIFLAPALength NUMBER(10, 3) NULL,
                        ILIFLAPADepthPct NUMBER(8, 5) NULL,
                        ILIFOrientation NUMBER(6, 3) NULL,
                        ILIFFailPressAlgthmDomainId NUMBER(7, 0) NULL,
                        ILIFFailurePressure NUMBER(16, 4) NULL,
                        ILIFRupturePressureRatio NUMBER(5, 3) NULL,
                        ILIFCAOP NUMBER(5, 0) NULL,
                        ILIFSurfaceInd VARCHAR2(2) NULL,
                        ILIFComment VARCHAR2(255) NULL,
                        ILIFGrading1DomainId NUMBER(7, 0) NULL,
                        ILIFGrading2DomainId NUMBER(7, 0) NULL,
                        ILIFResponseTime DATE NULL,
                        ILIFFPRtc NUMBER(10, 3) NULL,
                        ILIFPOERupture NUMBER(20, 18) NULL,
                        ILIFPOELeak NUMBER(20, 18) NULL,
                        ILIFFPR NUMBER(10, 3) NULL,
                        AppVersion VARCHAR2(255) NULL,
                        ILIFVendorPackageCode VARCHAR2(10) NULL,
                        ILIFBoxCOUNT NUMBER(4, 0) NULL,
                        ILIFGirthWeldNumDS VARCHAR2(25) NULL,
                        ILIFDistanceFROMGirthWeldDS NUMBER(10, 3) NULL,
                        ILIFERF NUMBER(10, 3) NULL,
                        CFRGrading1DomainID NUMBER(7, 0) NULL,
                        CFRGrading2DomainID NUMBER(7, 0) NULL,
                        ILIFLatitude NUMBER(11, 9) NULL,
                        ILIFLongitude NUMBER(12, 9) NULL,
                        ILIFCoordSysDomainId NUMBER(7, 0) NULL,
                        ILIFX NUMBER(12, 3) NULL,
                        ILIFY NUMBER(12, 3) NULL,
                        ILIFZ NUMBER(10, 3) NULL,
                        StationSeriesId NUMBER(10, 0) NULL,
                        StationNum NUMBER(13, 5) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        MetalLossType VARCHAR2(50) NULL,
                        CalcLatitude NUMBER(11, 9) NULL,
                        CalcLongitude NUMBER(12, 9) NULL,
                        FprB31G NUMBER(10, 3) NULL,
                        FprTcB31G NUMBER(10, 3) NULL,
                        FprModB31G NUMBER(10, 3) NULL,
                        FprTcModB31G NUMBER(10, 3) NULL,
                        FprSentencing NUMBER(10, 3) NULL,
                        UpdateAudit VARCHAR2(255) NULL,
                        DscvryDt DATE NULL,
                        UpdtDscvryDt DATE NULL,
                        OperatorComment VARCHAR2(255) NULL,
                        DscvryDtUpdReasonDomainId NUMBER(7, 0) NULL,
                        GrowthRate NUMBER(9, 7) NULL,
                        GrowthRateStdDev NUMBER(9, 7) NULL,
                        SentencedResponseTime DATE NULL,
                        BeginStationSeriesId NUMBER(10, 0) NULL,
                        BeginStationNum NUMBER(13, 5) NULL,
                        EndStationSeriesId NUMBER(10, 0) NULL,
                        EndStationNum NUMBER(13, 5) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        InlineInspectionId NUMBER(10, 0) NULL,
                        IRASCustomDate1 DATE NULL,
                        IRASCustomDate2 DATE NULL,
                        IRASCustomDate3 DATE NULL,
                        IRASCustomDate4 DATE NULL,
                        IRASCustomDate5 DATE NULL,
                        IRASCustomNum1 float NULL,
                        IRASCustomNum2 float NULL,
                        IRASCustomNum3 float NULL,
                        IRASCustomNum4 float NULL,
                        IRASCustomNum5 float NULL,
                        IRASCustomString1 VARCHAR2(255) NULL,
                        IRASCustomString2 VARCHAR2(255) NULL,
                        IRASCustomString3 VARCHAR2(255) NULL,
                        IRASCustomString4 VARCHAR2(255) NULL,
                        IRASCustomString5 VARCHAR2(255) NULL,
                        ILIFDepthTolerance NUMBER(8, 3) NULL,
                        ILIFLengthTolerance NUMBER(10, 3) NULL,
                        ILIFWidthTolerance NUMBER(10, 3) NULL,
                        ILIFDepthToleranceStdDev NUMBER(8, 3) NULL,
                        ILIFLengthToleranceStdDev NUMBER(10, 3) NULL,
                        ILIFWidthToleranceStdDev NUMBER(10, 3) NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILIFSourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                
            
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_InlineInspectionJoint');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE Load_InlineInspectionJoint(
                            Id NUMBER(10, 0) NOT NULL,
                            EffectiveStartDate DATE NULL,
                            EffectiveEndDate DATE NULL,
                            InlineInspectionRangeId NUMBER(10, 0) NOT NULL,
                            ILIJointGirthWeldNum VARCHAR2(25) NULL,
                            ILIJointGirthWeldOdometer NUMBER(10, 3) NULL,
                            ILIJointSpoolLength NUMBER(10, 3) NULL,
                            ILIJointDiameter NUMBER(9, 5) NULL,
                            ILIJointWallThickness NUMBER(9, 5) NULL,
                            ILIJointGrade NUMBER(10, 5) NULL,
                            ILIJointSeamOrientation NUMBER(6, 3) NULL,
                            ILIJointSpiralAngle NUMBER(3, 0) NULL,
                            ILIJointComment VARCHAR2(255) NULL,
                            StationSeriesId NUMBER(10, 0) NULL,
                            StationNum NUMBER(13, 5) NULL,
                            ILIJointLatitude NUMBER(11, 9) NULL,
                            ILIJointLongitude NUMBER(12, 9) NULL,
                            ILIJointCoordSysDomainId NUMBER(7, 0) NULL,
                            ILIJointX NUMBER(12, 3) NULL,
                            ILIJointY NUMBER(12, 3) NULL,
                            ILIJointZ NUMBER(10, 3) NULL,
                            LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                            LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                            ILIJointGirthWeldNumPrevious VARCHAR2(25) NULL,
                            CalcLatitude NUMBER(11, 9) NULL,
                            CalcLongitude NUMBER(12, 9) NULL,
                            UpdateAudit VARCHAR2(255) NULL,
                            MOP NUMBER(9, 4) NULL,
                            DPP NUMBER(9, 4) NULL,
                            DPPUpdateDate DATE NULL,
                            DPPUpdateReason VARCHAR2(255) NULL,
                            OperatorComment VARCHAR2(255) NULL,
                            SeamType char(1) NULL,
                            BeginStationSeriesId NUMBER(10, 0) NULL,
                            BeginStationNum NUMBER(13, 5) NULL,
                            EndStationSeriesId NUMBER(10, 0) NULL,
                            EndStationNum NUMBER(13, 5) NULL,
                            SourceId VARCHAR2(50) NOT NULL,
                            CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                            CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                            InlineInspectionId NUMBER(10, 0) NULL,
                            IRASCustomDate1 DATE NULL,
                            IRASCustomDate2 DATE NULL,
                            IRASCustomDate3 DATE NULL,
                            IRASCustomDate4 DATE NULL,
                            IRASCustomDate5 DATE NULL,
                            IRASCustomNum1 float NULL,
                            IRASCustomNum2 float NULL,
                            IRASCustomNum3 float NULL,
                            IRASCustomNum4 float NULL,
                            IRASCustomNum5 float NULL,
                            IRASCustomString1 VARCHAR2(255) NULL,
                            IRASCustomString2 VARCHAR2(255) NULL,
                            IRASCustomString3 VARCHAR2(255) NULL,
                            IRASCustomString4 VARCHAR2(255) NULL,
                            IRASCustomString5 VARCHAR2(255) NULL,
                            ILIJToolSpeed NUMBER(8, 4) NULL,
                            ILIJDetectableLength NUMBER(8, 4) NULL,
                            ILIJointMeasuredWallThickness NUMBER(9, 5) NULL,
                            CheckSumValue int NOT NULL,
                            CONSTRAINT PK_ILIJSourceId PRIMARY KEY (SourceId)
                        )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                                
            
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_ILINonCrsnDfct');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE Load_ILINonCrsnDfct(
                        Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE NULL,
                        EffectiveEndDate DATE NULL,
                        InlineInspectionRangeId NUMBER(10, 0) NOT NULL,
                        ILINCDTypeDomainId NUMBER(7, 0) NULL,
                        ILINCDStatusDomainId NUMBER(7, 0) NULL,
                        ILINCDOdometer NUMBER(10, 3) NULL,
                        ILINCDFeatureNumber VARCHAR2(15) NULL,
                        ILINCDLength NUMBER(10, 3) NULL,
                        ILINCDWidth NUMBER(10, 3) NULL,
                        ILINCDOrientation NUMBER(6, 3) NULL,
                        ILINCDDepthPct NUMBER(8, 5) NULL,
                        ILINCDDepthPctNPS NUMBER(8, 5) NULL,
                        ILINCDGirthWeldNum VARCHAR2(25) NULL,
                        ILINCDDistanceFROMGirthWeld NUMBER(10, 3) NULL,
                        ILINCDComment VARCHAR2(255) NULL,
                        ILINCDGrading1DomainId NUMBER(7, 0) NULL,
                        ILINCDGrading2DomainId NUMBER(7, 0) NULL,
                        ILINCDResponseTime DATE NULL,
                        ILINCDStrain NUMBER(4, 4) NULL,
                        ILINCDVendorPackageCode VARCHAR2(10) NULL,
                        ILINCDGirthWeldNumDS VARCHAR2(25) NULL,
                        ILINCDDistanceFROMGirthWeldDS NUMBER(10, 3) NULL,
                        ILINCDSurfaceInd VARCHAR2(2) NULL,
                        CFRGrading1DomainID NUMBER(7, 0) NULL,
                        CFRGrading2DomainID NUMBER(7, 0) NULL,
                        ILINCDLatitude NUMBER(11, 9) NULL,
                        ILINCDLongitude NUMBER(12, 9) NULL,
                        ILINCDCoordSysDomainId NUMBER(7, 0) NULL,
                        ILINCDX NUMBER(12, 3) NULL,
                        ILINCDY NUMBER(12, 3) NULL,
                        ILINCDZ NUMBER(10, 3) NULL,
                        StationSeriesId NUMBER(10, 0) NULL,
                        StationNum NUMBER(13, 5) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        CalcLatitude NUMBER(11, 9) NULL,
                        CalcLongitude NUMBER(12, 9) NULL,
                        UpdateAudit VARCHAR2(255) NULL,
                        DscvryDt DATE NULL,
                        UpdtDscvryDt DATE NULL,
                        OperatorComment VARCHAR2(255) NULL,
                        DscvryDtUpdReasonDomainId NUMBER(7, 0) NULL,
                        SentencedResponseTime DATE NULL,
                        BeginStationSeriesId NUMBER(10, 0) NULL,
                        BeginStationNum NUMBER(13, 5) NULL,
                        EndStationSeriesId NUMBER(10, 0) NULL,
                        EndStationNum NUMBER(13, 5) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        InlineInspectionId NUMBER(10, 0) NULL,
                        IRASCustomDate1 DATE NULL,
                        IRASCustomDate2 DATE NULL,
                        IRASCustomDate3 DATE NULL,
                        IRASCustomDate4 DATE NULL,
                        IRASCustomDate5 DATE NULL,
                        IRASCustomNum1 float NULL,
                        IRASCustomNum2 float NULL,
                        IRASCustomNum3 float NULL,
                        IRASCustomNum4 float NULL,
                        IRASCustomNum5 float NULL,
                        IRASCustomString1 VARCHAR2(255) NULL,
                        IRASCustomString2 VARCHAR2(255) NULL,
                        IRASCustomString3 VARCHAR2(255) NULL,
                        IRASCustomString4 VARCHAR2(255) NULL,
                        IRASCustomString5 VARCHAR2(255) NULL,
                        ILINCDHardness NUMBER(8, 4) NULL,
                        ILINCDDepthTolerance NUMBER(8, 3) NULL,
                        ILINCDLengthTolerance NUMBER(10, 3) NULL,
                        ILINCDWidthTolerance NUMBER(10, 3) NULL,
                        ILINCDDepthToleranceStdDev NUMBER(8, 3) NULL,
                        ILINCDLengthToleranceStdDev NUMBER(10, 3) NULL,
                        ILINCDWidthToleranceStdDev NUMBER(10, 3) NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILINCDSourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                
            
            SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('Load_InlineInspectionRange');
            
            IF CNT = 0
            THEN
                sqlStatement := 'CREATE TABLE Load_InlineInspectionRange(
                        Id NUMBER(10, 0) NOT NULL,
                        EffectiveStartDate DATE NULL,
                        EffectiveEndDate DATE NULL,
                        InlineInspectionId NUMBER(10, 0) NOT NULL,
                        ILIRToolDomainId NUMBER(7, 0) NULL,
                        ILIRStatusDomainId NUMBER(7, 0) NULL,
                        ILIRFailPressAlgthmDomainId NUMBER(7, 0) NULL,
                        ILIRDescr VARCHAR2(255) NULL,
                        ILIRStartOdometer NUMBER(10, 3) NULL,
                        ILIREndOdometer NUMBER(10, 3) NULL,
                        ILIRStartDate DATE NULL,
                        ILIREndDate DATE NULL,
                        BeginStationSeriesId NUMBER(10, 0) NULL,
                        BeginStationNum NUMBER(13, 5) NULL,
                        EndStationSeriesId NUMBER(10, 0) NULL,
                        EndStationNum NUMBER(13, 5) NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT USER NOT NULL,
                        LastModDateTime DATE DEFAULT SYSDATE NOT NULL,
                        ILIStartDate2 DATE NULL,
                        ILIEndDate2 DATE NULL,
                        ILIRStartDate2 DATE NULL,
                        ILIREndDate2 DATE NULL,
                        ILIReportDate DATE NULL,
                        ILIRCoordProj VARCHAR2(50) NULL,
                        ILIRCoordDatum VARCHAR2(25) NULL,
                        ILIRHeightDatum VARCHAR2(50) NULL,
                        UndercallFactorDepthPct NUMBER(7, 3) NULL,
                        ILIRStatusUpdateDate DATE NULL,
                        ILIRStatusUpdateUserId VARCHAR2(45) NULL,
                        ILIRStatusUpdateComment VARCHAR2(255) NULL,
                        ILIRToolMean NUMBER(8, 7) NULL,
                        ILIRToolStdDeviation NUMBER(8, 7) NULL,
                        SourceId VARCHAR2(50) NOT NULL,
                        CreatedDate DATE DEFAULT SYSDATE NOT NULL,
                        CreatedUser VARCHAR2(45) DEFAULT USER NOT NULL,
                        CheckSumValue int NOT NULL,
                        CONSTRAINT PK_ILIRSourceId PRIMARY KEY (SourceId)
                    )';
                                
                EXECUTE IMMEDIATE sqlStatement;
            END IF;                                   
            
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspection') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTION ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionRange') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONRANGE ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionFacility') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONFACILITY ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionFeature') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONFEATURE ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionNonCrsnDfct') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONNONCRSNDFCT ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionJoint') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONJOINT ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('InlineInspectionCrackAnomaly') 
                AND UPPER(Column_Name) = UPPER('CheckSumValue');
        
            if CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE INLINEINSPECTIONCRACKANOMALY ADD CheckSumValue int NULL';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;           
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
    IF dbVersion = 640001 AND dbVersionCheckPoint = 1
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            SELECT COUNT(*) INTO CNT 
            FROM user_constraints
            WHERE constraint_type = 'R' 
                AND UPPER(Constraint_Name) = UPPER('FK_Pressure_BeginStnSrs');

            IF CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PRESSURE DROP CONSTRAINT FK_Pressure_BeginStnSrs';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_constraints
            WHERE constraint_type = 'R' 
                AND UPPER(Constraint_Name) = UPPER('FK_Pressure_EndStnSrs');

            IF CNT = 1
            THEN
                sqlStatement := 'ALTER TABLE PRESSURE DROP CONSTRAINT FK_Pressure_EndStnSrs';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('Pressure') 
                AND UPPER(Column_Name) = UPPER('BeginStationSeriesId') AND NULLABLE = 'Y';

            IF CNT = 1
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY BeginStationSeriesId NUMBER(10, 0) NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY BeginStationSeriesId NUMBER(10, 0) NOT NULL';

            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('Pressure') 
                AND UPPER(Column_Name) = UPPER('BeginStationNum') AND NULLABLE = 'Y';
        
            IF CNT = 1
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY BeginStationNum NUMBER(13, 5) NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY BeginStationNum NUMBER(13, 5) NOT NULL';

            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('Pressure') 
                AND UPPER(Column_Name) = UPPER('EndStationSeriesId') AND NULLABLE = 'Y';
        
            IF CNT = 1
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY EndStationSeriesId NUMBER(10, 0) NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY EndStationSeriesId NUMBER(10, 0) NOT NULL';

            END IF;

            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE UPPER(Table_name) = UPPER('Pressure') 
                AND UPPER(Column_Name) = UPPER('EndStationNum') AND NULLABLE = 'Y';
        
            IF CNT = 1
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY EndStationNum NUMBER(13, 5) NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE Pressure MODIFY EndStationNum NUMBER(13, 5) NOT NULL';

            END IF;

        END;           
        
        UPDATE VersionInfo 
        SET DBVersionCheckPoint = 2;
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
    IF dbVersion = 640001 AND dbVersionCheckPoint = 2
    THEN
        DECLARE CNT INT;
                sqlStatement VARCHAR(4000);
        BEGIN
            SELECT COUNT(*) INTO CNT FROM user_constraints
            WHERE constraint_type = 'R' AND UPPER(Constraint_Name) = UPPER('FK_Pressure_BeginStnSrs');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE Pressure ADD CONSTRAINT FK_Pressure_BeginStnSrs FOREIGN KEY(BEGINSTATIONSERIESID) REFERENCES STATIONSERIES (ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

            SELECT COUNT(*) INTO CNT FROM user_constraints
            WHERE constraint_type = 'R' AND UPPER(Constraint_Name) = UPPER('FK_Pressure_EndStnSrs');

            IF CNT = 0
            THEN
                sqlStatement := 'ALTER TABLE Pressure ADD CONSTRAINT FK_Pressure_EndStnSrs FOREIGN KEY(ENDSTATIONSERIESID) REFERENCES STATIONSERIES (ID)';
                EXECUTE IMMEDIATE sqlStatement;
            END IF;

        END;           
        
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 640001 AND dbVersionCheckPoint = 3
    THEN
        -- SP_ENABLE_TIB_LISTDOMAIN.sql
        DECLARE sqlStatement varchar(4000);

        BEGIN
            sqlStatement := 'create or replace PROCEDURE SP_ENABLE_TIB_LISTDOMAIN 
                                    AUTHID DEFINER
                                    AS 
                                    BEGIN
                                        EXECUTE IMMEDIATE ''ALTER TRIGGER TIB_LISTDOMAIN ENABLE'';
                                    END;';
            EXECUTE IMMEDIATE sqlStatement;
        END;
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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640001 AND dbVersionCheckPoint = 4
    THEN
        -- SP_DISABLE_TIB_LISTDOMAIN.sql

        DECLARE sqlStatement varchar(4000);

        BEGIN
            sqlStatement := 'create or replace PROCEDURE SP_DISABLE_TIB_LISTDOMAIN 
                                    AUTHID DEFINER
                                    AS 
                                    BEGIN
                                        EXECUTE IMMEDIATE ''ALTER TRIGGER TIB_LISTDOMAIN DISABLE'';
                                    END;';
            EXECUTE IMMEDIATE sqlStatement;

        END;

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

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640001 AND dbVersionCheckPoint = 5
    THEN
            /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 0 Updates 02
        /********************************************************************************************************/
        UPDATE VersionInfo
        SET DBVersion = '640002', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 02';
        
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
    CNT NUMBER(1);
    ddl VARCHAR2(5000);

BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640002 AND dbVersionCheckPoint = 0
    THEN
        DECLARE
            counter BINARY_INTEGER := 0;

            -- table variable to store table of ddl statements
            TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
            INDEX BY BINARY_INTEGER;
            tmpListDomainForeignKeys DDL_TABLE_TYPE;

            -- Cursor to delete FK constraints
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
                AND ref.table_name = 'LISTDOMAIN'
                AND ref.column_name = 'ID' 
                );
            
            -- Cursor to store and add FK constraints
            CURSOR add_cons_cursor IS
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
                AND ref.table_name = 'LISTDOMAIN'
                AND ref.column_name = 'ID' 
            );

        BEGIN      
            --Store foreign key definitions in table variable
            FOR ddl IN add_cons_cursor LOOP
                counter := counter + 1;
                tmpListDomainForeignKeys(counter) := ddl.add_foreign_keys;
               
            END LOOP;

            --Drop FK constraints on listdomain table if FK definitions are saved
            IF (counter != 0)
            THEN 
                FOR ddl IN drop_cons_cursor LOOP
                    EXECUTE IMMEDIATE ddl.drop_constraint;
                END LOOP;
            END IF;

            --Check if listdomain table has an identity column
            SELECT COUNT(*) INTO CNT 
            FROM all_tab_identity_cols 
            WHERE table_name = 'LISTDOMAIN'
                AND owner = USER;

            /*if there is no identity column on the listdomain table, save the table data to a temp table, 
                add an identity column, and transfer the data back into table
            */
            IF (CNT = 0)
            THEN
                -- Save listdomain table data in temp table
                SELECT COUNT(*) INTO CNT
                FROM all_tables
                WHERE table_name = UPPER('tmpListDomain_Identity')
                    AND owner = USER;

                ddl := q'[CREATE TABLE tmpListDomain_Identity
                                AS SELECT * FROM listdomain
                        ]';

                -- Copy listdomain data into tmpListDomain_Identity table
                IF (CNT = 1)
                THEN
                    EXECUTE IMMEDIATE 'DROP TABLE tmpListDomain_Identity';   
                    EXECUTE IMMEDIATE ddl;
                ELSE
                    EXECUTE IMMEDIATE ddl;
                END IF;

                -- Drop the listdomain table
                EXECUTE IMMEDIATE 'DROP TABLE listdomain PURGE';

                --Recreate listdomain table based on the table structure of tmpListDomain_Identity
                EXECUTE IMMEDIATE 'CREATE TABLE listdomain AS 
                                    SELECT * FROM tmpListDomain_Identity
                                    WHERE 1 = 0';

                -- Drop the id column so it can be modified
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain DROP COLUMN id';

                -- Recreate id column in listdomain table as an identity column
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain ADD 
                            (id NUMBER(7,0) GENERATED BY DEFAULT ON NULL AS IDENTITY 
                                START WITH 1 INCREMENT BY 1 NOCYCLE
                                CONSTRAINT pk_listdomain PRIMARY KEY)';
                
                -- Make the id column the first column in the table
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain
                                    MODIFY (DomainCatalogId INVISIBLE, 
                                            Code INVISIBLE,     
                                            Descr INVISIBLE, 
                                            SourceDomainId INVISIBLE, 
                                            LastModByUserId INVISIBLE, 
                                            LastModDateTime INVISIBLE)';
                
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain
                                    MODIFY (DomainCatalogId VISIBLE, 
                                            Code VISIBLE,     
                                            Descr VISIBLE, 
                                            SourceDomainId VISIBLE, 
                                            LastModByUserId VISIBLE, 
                                            LastModDateTime VISIBLE)';

                -- Insert the listdomain data back into the listdomain table
                EXECUTE IMMEDIATE 'INSERT INTO listdomain (Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime)
                                        SELECT Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime
                                        FROM tmpListDomain_Identity';                        
            END IF;

            --Add foreign keys referencing listdomain backup into tables
            FOR i IN 1..counter LOOP
                ddl := tmpListDomainForeignKeys(i);
                EXECUTE IMMEDIATE ddl;
            END LOOP;
                        
------------------------------------------ Drop temp tables ---------------------------------------------
         
            SELECT COUNT(*) INTO CNT
            FROM all_tables
            WHERE table_name = UPPER('tmpListDomain_Identity')
                AND owner = USER;

            IF (CNT > 0)
            THEN
                EXECUTE IMMEDIATE 'DROP TABLE tmpListDomain_Identity';
            END IF;
        END;

------------------------Update the version checkpoint within versioninfo table if it exists------------------

        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                SET DBVersionCheckPoint = 1';
            COMMIT;
        END IF;

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
    dbVersion NUMBER(10);
    dbVersionCheckPoint NUMBER(5); 
    CNT NUMBER(2);
BEGIN
    SELECT DBVersion INTO dbVersion 
    FROM VersionInfo vi;

    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint 
    FROM VersionInfo vi;

    IF dbVersion = 640002 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
                -- Update VersionInfo Application Version 6.4 Release 0 Updates 03
        /********************************************************************************************************/

        UPDATE versionInfo
        SET DBVersion = '640003', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 03';
        
        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                                SET DBVersionCheckPoint = 0';
            COMMIT;
        END IF;
       
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
    ddl VARCHAR2(5000);
    CNT NUMBER(7);
BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
   
    IF dbVersion = 640003 AND dbVersionCheckPoint = 0
    THEN
        BEGIN
            SELECT COUNT(*) INTO CNT
            FROM all_tables 
            WHERE table_name = UPPER('SimCalcFeatureLeak')
                AND owner = USER;

            -- Create table if it does not exist
            IF (CNT = 0)
            THEN
                ddl := q'[CREATE TABLE  SimCalcFeatureLeak (ID  NUMBER(10, 0) GENERATED ALWAYS AS IDENTITY 
						START WITH 1 INCREMENT BY 1 NOCYCLE
						CONSTRAINT PK_SimCalcFeatureLeak PRIMARY KEY,
					 InlineInspectionID    NUMBER (10, 0) NOT NULL,
					 InlineInspectionRangeID    NUMBER (10, 0) NOT NULL,
					 ILIFeatureID    NUMBER (10, 0) NOT NULL,
					 SimulationYear    NUMBER (4, 0) NOT NULL,
					 LastCalcYear    NUMBER (4, 0) NOT NULL,
					 NumberOfIterations    NUMBER (10, 0) NOT NULL,
					 yr0     NUMBER (20, 18) NOT NULL,
					 yr1     NUMBER (20, 18) NOT NULL,
					 yr2     NUMBER (20, 18) NOT NULL,
					 yr3     NUMBER (20, 18) NOT NULL,
					 yr4     NUMBER (20, 18) NOT NULL,
					 yr5     NUMBER (20, 18) NOT NULL,
					 yr6     NUMBER (20, 18) NOT NULL,
					 yr7     NUMBER (20, 18) NOT NULL,
					 yr8     NUMBER (20, 18) NOT NULL,
					 yr9     NUMBER (20, 18) NOT NULL,
					 yr10    NUMBER (20, 18) NOT NULL,
					 yr11    NUMBER (20, 18) NOT NULL,
					 yr12    NUMBER (20, 18) NOT NULL,
					 yr13    NUMBER (20, 18) NOT NULL,
					 yr14    NUMBER (20, 18) NOT NULL,
					 yr15    NUMBER (20, 18) NOT NULL,
					 yr16    NUMBER (20, 18) NOT NULL,
					 yr17    NUMBER (20, 18) NOT NULL,
					 yr18    NUMBER (20, 18) NOT NULL,
					 yr19    NUMBER (20, 18) NOT NULL,
					 CalculationDate   TIMESTAMP  NULL,
					 CreatedDate   TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL,
					 CreatedUser   VARCHAR2 (45) DEFAULT (SYS_CONTEXT( 'userenv','os_user')) NOT NULL,
					 LastModByUserID   VARCHAR2 (45) DEFAULT (SYS_CONTEXT( 'userenv','os_user')) NOT NULL,
					 LastModDateTime   TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL
				)]';

                EXECUTE IMMEDIATE ddl;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM all_triggers
            WHERE trigger_name = UPPER('tu_SimCalcFeatureLeak')
                AND owner = USER;

            ddl := q'[CREATE OR REPLACE TRIGGER tu_SimCalcFeatureLeak 
                        BEFORE UPDATE OR DELETE
                        ON SimCalcFeatureLeak
                        FOR EACH ROW
                        DECLARE
                        BEGIN
                            :NEW.LastModByUserID := SYS_CONTEXT('userenv','os_user');
                            :NEW.LastModDateTime := CURRENT_DATE;       
                        END;
                    ]';

            -- Create trigger if it doesn't already exist
            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE ddl;
            END IF;

            -- enable trigger
            EXECUTE IMMEDIATE 'ALTER TRIGGER tu_SimCalcFeatureLeak ENABLE';

            SELECT COUNT(*) INTO CNT
            FROM all_tables 
            WHERE table_name = UPPER('SimCalcFeatureTotal')
                AND owner = USER;

            ddl := q'[CREATE TABLE SimCalcFeatureTotal (ID    NUMBER (10, 0) GENERATED ALWAYS AS IDENTITY 
						START WITH 1 INCREMENT BY 1 NOCYCLE
						CONSTRAINT PK_SimCalcFeatureTotal PRIMARY KEY,
					 InlineInspectionID    NUMBER (10, 0) NOT NULL,
					 InlineInspectionRangeID    NUMBER (10, 0) NOT NULL,
					 ILIFeatureID    NUMBER (10, 0) NOT NULL,
					 SimulationYear    NUMBER (4, 0) NOT NULL,
					 LastCalcYear    NUMBER (4, 0) NOT NULL,
					 NumberOfIterations    NUMBER (10, 0) NOT NULL,
					 yr0     NUMBER (20, 18) NOT NULL,
					 yr1     NUMBER (20, 18) NOT NULL,
					 yr2     NUMBER (20, 18) NOT NULL,
					 yr3     NUMBER (20, 18) NOT NULL,
					 yr4     NUMBER (20, 18) NOT NULL,
					 yr5     NUMBER (20, 18) NOT NULL,
					 yr6     NUMBER (20, 18) NOT NULL,
					 yr7     NUMBER (20, 18) NOT NULL,
					 yr8     NUMBER (20, 18) NOT NULL,
					 yr9     NUMBER (20, 18) NOT NULL,
					 yr10    NUMBER (20, 18) NOT NULL,
					 yr11    NUMBER (20, 18) NOT NULL,
					 yr12    NUMBER (20, 18) NOT NULL,
					 yr13    NUMBER (20, 18) NOT NULL,
					 yr14    NUMBER (20, 18) NOT NULL,
					 yr15    NUMBER (20, 18) NOT NULL,
					 yr16    NUMBER (20, 18) NOT NULL,
					 yr17    NUMBER (20, 18) NOT NULL,
					 yr18    NUMBER (20, 18) NOT NULL,
					 yr19    NUMBER (20, 18) NOT NULL,
					 CalculationDate   TIMESTAMP  NULL,
					 CreatedDate   TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL,
					 CreatedUser   VARCHAR2 (45) DEFAULT (SYS_CONTEXT('userenv', 'os_user' )) NOT NULL,
					 LastModByUserID   VARCHAR2 (45) DEFAULT (SYS_CONTEXT('userenv', 'os_user' )) NOT NULL,
					 LastModDateTime   TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL
					)
                    ]';

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE ddl;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM all_triggers
            WHERE trigger_name = UPPER('tu_SimCalcFeatureTotal')
                AND owner = USER;

            ddl := q'[CREATE OR REPLACE TRIGGER tu_SimCalcFeatureTotal 
                        BEFORE UPDATE OR DELETE
                        ON SimCalcFeatureTotal
                        FOR EACH ROW
                        DECLARE
                        BEGIN
                            :NEW.LastModByUserID := SYS_CONTEXT('userenv','os_user');
                            :NEW.LastModDateTime := CURRENT_DATE;       
                        END;
                    ]';

            -- Create trigger if it doesn't already exist
            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE ddl;
            END IF;

            EXECUTE IMMEDIATE 'ALTER TRIGGER tu_SimCalcFeatureTotal ENABLE';

            SELECT COUNT(*) INTO CNT
            FROM all_tables
            WHERE table_name = UPPER('SimCalcFeatureRupture')
                AND owner = USER;

            ddl := q'[CREATE TABLE  SimCalcFeatureRupture (ID    NUMBER (10, 0) GENERATED ALWAYS AS IDENTITY 
						START WITH 1 INCREMENT BY 1 NOCYCLE
						CONSTRAINT PK_SimCalcFeatureRupture PRIMARY KEY,
				 InlineInspectionID    NUMBER (10, 0) NOT NULL,
				 InlineInspectionRangeID    NUMBER (10, 0) NOT NULL,
				 ILIFeatureID    NUMBER (10, 0) NOT NULL,
				 SimulationYear    NUMBER (4, 0) NOT NULL,
				 LastCalcYear    NUMBER (4, 0) NOT NULL,
				 NumberOfIterations    NUMBER (10, 0) NOT NULL,
				 yr0    NUMBER (20, 18) NOT NULL,
				 yr1    NUMBER (20, 18) NOT NULL,
				 yr2    NUMBER (20, 18) NOT NULL,
				 yr3    NUMBER (20, 18) NOT NULL,
				 yr4    NUMBER (20, 18) NOT NULL,
				 yr5    NUMBER (20, 18) NOT NULL,
				 yr6    NUMBER (20, 18) NOT NULL,
				 yr7    NUMBER (20, 18) NOT NULL,
				 yr8    NUMBER (20, 18) NOT NULL,
				 yr9    NUMBER (20, 18) NOT NULL,
				 yr10    NUMBER (20, 18) NOT NULL,
				 yr11    NUMBER (20, 18) NOT NULL,
				 yr12    NUMBER (20, 18) NOT NULL,
				 yr13    NUMBER (20, 18) NOT NULL,
				 yr14    NUMBER (20, 18) NOT NULL,
				 yr15    NUMBER (20, 18) NOT NULL,
				 yr16    NUMBER (20, 18) NOT NULL,
				 yr17    NUMBER (20, 18) NOT NULL,
				 yr18    NUMBER (20, 18) NOT NULL,
				 yr19    NUMBER (20, 18) NOT NULL,
				 CalculationDate    TIMESTAMP  NULL,
				 CreatedDate    TIMESTAMP  DEFAULT ( CURRENT_DATE) NOT NULL,
				 CreatedUser    VARCHAR2 (45) DEFAULT (SYS_CONTEXT('userenv', 'os_user')) NOT NULL,
				 LastModByUserID    VARCHAR2 (45) DEFAULT (SYS_CONTEXT('userenv', 'os_user')) NOT NULL,
				 LastModDateTime    TIMESTAMP  DEFAULT ( CURRENT_DATE) NOT NULL
		       )
                     ]';
            
            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE ddl;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM all_triggers
            WHERE trigger_name = UPPER('tu_SimCalcFeatureRupture')
                AND owner = USER;

            ddl := q'[CREATE OR REPLACE TRIGGER tu_SimCalcFeatureRupture 
                        BEFORE UPDATE OR DELETE
                        ON SimCalcFeatureRupture
                        FOR EACH ROW
                        DECLARE
                        BEGIN
                            :NEW.LastModByUserID := SYS_CONTEXT('userenv','os_user');
                            :NEW.LastModDateTime := CURRENT_DATE;       
                        END;
                    ]';

            -- Create trigger if it doesn't already exist
            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE ddl;
            END IF;

            EXECUTE IMMEDIATE 'ALTER TRIGGER tu_SimCalcFeatureRupture ENABLE';
        END;

------------------------Update the version checkpoint within versioninfo table if it exists------------------

        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                SET DBVersionCheckPoint = 1';
            COMMIT;
        END IF;
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
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
	/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 04
    /********************************************************************************************************/

    IF dbVersion = 640003 AND dbVersionCheckPoint = 1
    THEN
        UPDATE versionInfo
        SET DBVersion = '640004', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 04';
        
        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                                SET DBVersionCheckPoint = 0';
            COMMIT;
        END IF;
       
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE sp_Dx6ConfigV5
IS
    CNT NUMBER(6);
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM all_tables
    WHERE table_name = UPPER('temp_Fabrication')
        AND owner = USER;

    IF (CNT = 0)
    THEN
        EXECUTE IMMEDIATE q'[CREATE GLOBAL TEMPORARY TABLE temp_Fabrication
                            (Id                                 NUMBER (18, 0) NULL,
                            EffectiveStartDate                 TIMESTAMP  NULL,
                            EffectiveEndDate                   TIMESTAMP  NULL,
                            FabricationTypeDomainId            NUMBER (7, 0) NULL,
                            FabricationTypeDomainCode          VARCHAR2 (40) NULL,
                            FabricationTypeDomainDesc          VARCHAR2 (255) NULL,
                            FabricationOutsideDiameter         NUMBER (8, 4) NULL,
                            FabricationName                    VARCHAR2 (100) NULL,
                            FabricationComment                 VARCHAR2 (255) NULL,
                            StationSeriesId                    NUMBER (10, 0) NULL,
                            StationNum                         NUMBER (10, 3) NULL,
                            FabricationManufacturingTypeLd     NUMBER (7, 0) NULL,
                            FabricationManufacturingTypeCode   VARCHAR2 (40) NULL,
                            FabricationManufacturingTypeDesc   VARCHAR2 (255) NULL,
                            FabricationOutletGrade             NUMBER (5, 0) NULL,
                            FabricationOutletWallthickness     NUMBER (9, 5) NULL,
                            FabricationInletDiameter           NUMBER (5, 3) NULL,
                            FabricationInletGrade              NUMBER (5, 0) NULL,
                            FabricationInletWallThickness      NUMBER (9, 5) NULL,
                            FabricationPressureRating          NUMBER (5, 0) NULL,
                            FabricationOutletDiameter          NUMBER (5, 3) NULL,
                            FabricationConnectDomainID         NUMBER (7, 0) NULL,
                            FabricationConnectCode             VARCHAR2 (40) NULL,
                            FabricationConnectDesc             VARCHAR2 (255) NULL,
                            ) ON COMMIT PRESERVE ROWS
                            ]';
    END IF;
   
    EXECUTE IMMEDIATE q'[INSERT INTO temp_Fabrication
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
                        FabricationConnectDesc
                        )
                        SELECT  ROWNUM,
                                OVER (
                                    ORDER BY BeginStationSeriesId, BeginStationNum
                                    ) AS id,
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
                                    FROM    Elbow f
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
                                                ON f.VentTypeDomainId = t.Id ) tbl
                    ]';                      

    EXECUTE IMMEDIATE q'[INSERT INTO ListDomain
                            (DomainCatalogId,
                            Code,
                            Descr,
                            SourceDomainId)
                        SELECT ( SELECT DomainCatalogId
                                FROM   DomainCatalogColXRef
                                WHERE  TableName = UPPER('Fabrication') AND
                                    ColumnName = UPPER('FabricationTypeDomainId') ) AS DomainCatalogId,
                            tbl.Code,
                            tbl.Descr,
                            NULL AS SourceDomainId
                        FROM   ( SELECT DISTINCT FabricationTypeDomainCode AS Code,
                                                FabricationTypeDomainDesc AS Descr
                                FROM   temp_Fabrication
                                WHERE  FabricationTypeDomainCode IS NOT NULL ) tbl
                        WHERE  tbl.Code NOT IN ( SELECT Code
                                FROM   ListDomain
                                WHERE  DomainCatalogId =
                                    ( SELECT DomainCatalogId
                                        FROM   DomainCatalogColXRef
                                        WHERE  TableName = UPPER('Fabrication') AND
                                                ColumnName = UPPER('FabricationTypeDomainId')
                                    ) 
                                )
                        ]';
                        
    EXECUTE IMMEDIATE q'[INSERT INTO ListDomain
                            (DomainCatalogId,
                            Code,
                            Descr,
                            SourceDomainId)
                        SELECT ( SELECT DomainCatalogId
                                    FROM   DomainCatalogColXRef
                                    WHERE  TableName = UPPER('Fabrication') AND
                                        ColumnName = UPPER('FabricationManufacturingTypeLd') ) AS DomainCatalogId,
                                tbl.Code,
                                tbl.Descr,
                                NULL AS SourceDomainId
                        FROM   ( SELECT DISTINCT FabricationManufacturingTypeCode AS Code,
                                                    FabricationManufacturingTypeDesc AS Descr
                                    FROM   temp_Fabrication
                                    WHERE  FabricationManufacturingTypeCode IS NOT NULL ) tbl
                        WHERE  tbl.Code NOT IN ( SELECT Code
                                            FROM   ListDomain
                        WHERE  DomainCatalogId =
                                    ( SELECT DomainCatalogId
                                        FROM   DomainCatalogColXRef
                                        WHERE  TableName = UPPER('Fabrication') AND
                                            ColumnName = UPPER('FabricationManufacturingTypeLd') ) )
                        ]';

    EXECUTE IMMEDIATE q'[INSERT INTO ListDomain
                            (DomainCatalogId,
                            Code,
                            Descr,
                            SourceDomainId)
                        SELECT ( SELECT DomainCatalogId
                                    FROM   DomainCatalogColXRef
                                    WHERE  TableName = UPPER('Fabrication') AND
                                        ColumnName = UPPER('FabricationConnectDomainID') ) AS DomainCatalogId,
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
                                        WHERE  TableName = UPPER('Fabrication') AND
                                                ColumnName = UPPER('FabricationConnectDomainID')))
                        ]';

    EXECUTE IMMEDIATE q'[UPDATE f
                        SET    FabricationTypeDomainId = t.Id,
                                FabricationManufacturingTypeLd = m.Id,
                                FabricationConnectDomainID = c.Id
                        FROM   temp_Fabrication f
                            LEFT JOIN ListDomain t
                                    ON f.FabricationTypeDomainCode = t.Code AND
                                        t.DomainCatalogId =
                                        ( SELECT DomainCatalogId
                                        FROM   DomainCatalogColXRef
                                        WHERE  TableName = UPPER('Fabrication') AND
                                                ColumnName = UPPER('FabricationTypeDomainId') )
                            LEFT JOIN ListDomain m
                                    ON f.FabricationManufacturingTypeCode = m.Code AND
                                        m.DomainCatalogId =
                                        ( SELECT DomainCatalogId
                                        FROM   DomainCatalogColXRef
                                        WHERE  TableName = UPPER('Fabrication') AND
                                                ColumnName = UPPER('FabricationManufacturingTypeLd') )
                            LEFT JOIN ListDomain c
                                    ON f.FabricationConnectCode = c.Code AND
                                        c.DomainCatalogId =
                                        ( SELECT DomainCatalogId
                                        FROM    DomainCatalogColXRef
                                        WHERE  TableName = UPPER('Fabrication') AND
                                                ColumnName = UPPER('FabricationConnectDomainID') )
                            ]';

    EXECUTE IMMEDIATE 'DELETE FROM Fabrication';

    EXECUTE IMMEDIATE q'[INSERT INTO Fabrication
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
                        FROM   temp_Fabrication
                        ]';
                    

    EXECUTE IMMEDIATE 'DROP TABLE temp_Fabrication';

END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);

BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640004 AND dbVersionCheckPoint = 0
    THEN
          SELECT COUNT(*) INTO CNT
            FROM all_tab_cols
            WHERE column_name = UPPER('DBVersionCheckPoint')
                AND table_name = UPPER('versionInfo') 
                AND owner = USER;

            IF (CNT = 1)
            THEN
                EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                    SET DBVersionCheckPoint = 1';
                
            END IF;  

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
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
    /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 0 Updates 05
    /********************************************************************************************************/

    IF dbVersion = 640004 AND dbVersionCheckPoint = 1
    THEN
        UPDATE versionInfo
        SET DBVersion = '640005', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 05';
        
        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                                SET DBVersionCheckPoint = 0';
        END IF;

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
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640005 AND dbVersionCheckPoint = 0
    THEN
        BEGIN
            SELECT COUNT(*) INTO CNT
            FROM all_tables
            WHERE table_name = UPPER('tmpStg_ILIAxialStrain')
             AND owner = USER;

            -- If temp table does not exist, create temp table. Or else drop and create temp table to save table contents
            IF (CNT = 0)
            THEN
                -- Check if Stg_ILIAxialStrain table exists
                SELECT COUNT(*) INTO CNT
                FROM all_tables
                WHERE table_name = UPPER('Stg_ILIAxialStrain')
                AND owner = USER;

                -- If Stg_ILIAxialStrain table exists, save contents in temp table 
                IF (CNT = 1)
                THEN
                    EXECUTE IMMEDIATE 'CREATE TABLE tmpStg_ILIAxialStrain AS SELECT * FROM Stg_ILIAxialStrain';
                END IF;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM all_tab_identity_cols
            WHERE table_name = UPPER('Stg_ILIAxialStrain')
                AND OWNER = USER; 

            -- Drop table if it does not have an identity column 
            IF (CNT = 0)
            THEN
                SELECT COUNT(*) INTO CNT
                FROM all_tab_identity_cols
                WHERE table_name = UPPER('Stg_ILIAxialStrain')
                AND OWNER = USER; 

                IF (CNT = 1)
                THEN
                    EXECUTE IMMEDIATE 'DROP TABLE Stg_ILIAxialStrain';
                END IF;
            END IF;

            -- Check if Stg_ILIAxialStrain table exists
            SELECT COUNT(*) INTO CNT
            FROM all_tables
            WHERE table_name = UPPER('Stg_ILIAxialStrain')
            AND owner = USER;
            
            -- Recreate Stg_ILIAxialStrain if it has been dropped
            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE q'[CREATE TABLE Stg_ILIAxialStrain (Id   NUMBER (10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY 
                                                                    START WITH 1 INCREMENT BY 1 NOCYCLE
                                                                    CONSTRAINT PK_Stg_ILIAxialStrain PRIMARY KEY,
                                                                    EffectiveStartDate    TIMESTAMP  NULL,
                                                                    EffectiveEndDate    TIMESTAMP  NULL,
                                                                    Stg_ILIId    NUMBER (10, 0) NULL,
                                                                    Stg_ILIRangeId    NUMBER (10, 0) NULL,
                                                                    StationSeriesId    NUMBER (10, 0) NULL,
                                                                    StationNum    NUMBER (13, 5) NULL,
                                                                    BeginStationSeriesId    NUMBER (10, 0) NULL,
                                                                    BeginStationNum    NUMBER (13, 5) NULL,
                                                                    EndStationSeriesId    NUMBER (10, 0) NULL,
                                                                    EndStationNum    NUMBER (13, 5) NULL,
                                                                    ILIASFeatureIdentifier    VARCHAR2 (15) NULL,
                                                                    ILIASOdometer    NUMBER (10, 3) NULL,
                                                                    ILIASSensorP1Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP2Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP3Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP4Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP5Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP6Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP7Strain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP8Strain    NUMBER (7, 3) NULL,
                                                                    ILIASAxialStrain    NUMBER (7, 3) NULL,
                                                                    ILIASSensorP1Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP2Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP3Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP4Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP5Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP6Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP7Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASSensorP8Orientation    NUMBER (6, 3) NULL,
                                                                    ILIASAreaOfInterest   char (1) NULL,
                                                                    ILIASAnalysisDomainId    NUMBER (7, 0) NULL,
                                                                    ILIASComments    VARCHAR2 (255) NULL,
                                                                    ILIASX    NUMBER (12, 3) NULL,
                                                                    ILIASY    NUMBER (12, 3) NULL,
                                                                    ILIASZ    NUMBER (10, 3) NULL,
                                                                    ILIASLatitude    NUMBER (12, 9) NULL,
                                                                    ILIASLongitude    NUMBER (12, 9) NULL,
                                                                    ILIASGirthWeldNum    VARCHAR2 (25) NULL,
                                                                    ILIASDistanceFROMGirthWeld    NUMBER (10, 3) NULL,
                                                                    ILIASGirthWeldNumDS    VARCHAR2 (25) NULL,
                                                                    ILIASDistanceFROMGirthWeldDS    NUMBER (10, 3) NULL,
                                                                    IRASCustomDate1    TIMESTAMP  NULL,
                                                                    IRASCustomDate2    TIMESTAMP  NULL,
                                                                    IRASCustomDate3    TIMESTAMP  NULL,
                                                                    IRASCustomDate4    TIMESTAMP  NULL,
                                                                    IRASCustomDate5    TIMESTAMP  NULL,
                                                                    IRASCustomNum1   NUMBER  NULL,
                                                                    IRASCustomNum2   NUMBER  NULL,
                                                                    IRASCustomNum3   NUMBER  NULL,
                                                                    IRASCustomNum4   NUMBER  NULL,
                                                                    IRASCustomNum5   NUMBER  NULL,
                                                                    IRASCustomString1    VARCHAR2 (255) NULL,
                                                                    IRASCustomString2    VARCHAR2 (255) NULL,
                                                                    IRASCustomString3    VARCHAR2 (255) NULL,
                                                                    IRASCustomString4    VARCHAR2 (255) NULL,
                                                                    IRASCustomString5    VARCHAR2 (255) NULL,
                                                                    CreatedUser    VARCHAR2 (45) DEFAULT (SYS_CONTEXT( 'userenv','os_user')) NOT NULL,
                                                                    CreatedDate    TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL,
                                                                    LastModByUserId    VARCHAR2 (45) DEFAULT (SYS_CONTEXT( 'userenv','os_user')) NOT NULL,
                                                                    LastModDateTime    TIMESTAMP  DEFAULT (CURRENT_DATE) NOT NULL
                                                                )]';
            END IF;           

------------------------------------------------ Create and Enable Foreign keys --------------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM all_constraints
            WHERE constraint_name = UPPER('FK_Stg_ILIASAnalysisDomainId')
                AND owner = USER;

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Stg_ILIAxialStrain 
                                    ADD CONSTRAINT FK_Stg_ILIASAnalysisDomainId FOREIGN KEY (ILIASAnalysisDomainId) 
                                    REFERENCES ListDomain(id) ENABLE VALIDATE'; 
            END IF;
         

            SELECT COUNT(*) INTO CNT
            FROM all_constraints
            WHERE constraint_name = UPPER('FK_Stg_ILIASBegStationSeriesId')
                AND owner = USER;

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Stg_ILIAxialStrain
                                    ADD CONSTRAINT  FK_Stg_ILIASBegStationSeriesId FOREIGN KEY ( BeginStationSeriesId )
                                    REFERENCES StationSeries ( Id ) ENABLE VALIDATE';
            END IF;
           

            SELECT COUNT(*) INTO CNT
            FROM all_constraints
            WHERE constraint_name = UPPER('FK_Stg_ILIASEndStationSeriesId')
                AND owner = USER;

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Stg_ILIAxialStrain 
                                    ADD CONSTRAINT  FK_Stg_ILIASEndStationSeriesId FOREIGN KEY ( EndStationSeriesId )
                                    REFERENCES StationSeries ( Id ) ENABLE VALIDATE';
            END IF;	 
            
			 SELECT COUNT(*) INTO CNT
            FROM all_constraints
            WHERE constraint_name = UPPER('FK_Stg_ILIASStg_ILIId')
                AND owner = USER;

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Stg_ILIAxialStrain     
                                    ADD CONSTRAINT FK_Stg_ILIASStg_ILIId  FOREIGN KEY ( Stg_ILIId )
                                    REFERENCES Stg_ILI ( Id ) ENABLE VALIDATE';	
            END IF;	 
            			 
             SELECT COUNT(*) INTO CNT
            FROM all_constraints
            WHERE constraint_name = UPPER('FK_Stg_ILIASStg_ILIRangeId')
                AND owner = USER;

            IF (CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'ALTER TABLE Stg_ILIAxialStrain     
                                    ADD  CONSTRAINT FK_Stg_ILIASStg_ILIRangeId FOREIGN KEY ( Stg_ILIRangeId )
                                    REFERENCES Stg_ILIRange ( Id ) ENABLE VALIDATE';
            END IF;
            
				 				 
            -- Create trigger to update column that tracks table row modification
            EXECUTE IMMEDIATE q'[CREATE OR REPLACE TRIGGER tu_Stg_ILIAxialStrain  
                                    BEFORE UPDATE   
                                    ON Stg_ILIAxialStrain  
                                    FOR EACH ROW 
                                BEGIN
                                    :NEW.LastModByUserId := SYS_CONTEXT('userenv', 'os_user');
                                    :NEW.LastModDateTime := CURRENT_DATE;
                                END;
                                ]';        
        END;

------------------------Update the version checkpoint within versioninfo table if it exists------------------

             SELECT COUNT(*) INTO CNT
            FROM all_tab_cols
            WHERE column_name = UPPER('DBVersionCheckPoint')
                AND table_name = UPPER('versionInfo') 
                AND owner = USER;

            IF (CNT = 1)
            THEN
                EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                    SET DBVersionCheckPoint = 1';
            END IF;  

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
    CNT2 NUMBER(6);
    CNT3 NUMBER(6);

BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640005 AND dbVersionCheckPoint = 1
    THEN
        BEGIN
            SELECT COUNT(*) INTO CNT
            FROM Stg_ILIAxialStrain;

            SELECT COUNT(*) INTO CNT3
            FROM user_tables
            WHERE table_name = UPPER('tmpStg_ILIAxialStrain');
                      
            IF(CNT3 = 1)
            THEN
                EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM tmpStg_ILIAxialStrain'
                INTO CNT2;
            END IF;
            
            IF (CNT != CNT2 AND CNT3 = 1)
            THEN
                EXECUTE IMMEDIATE q'[INSERT INTO Stg_ILIAxialStrain
                                        (Id,
                                        EffectiveStartDate,
                                        EffectiveEndDate,
                                        Stg_ILIId,
                                        Stg_ILIRangeId,
                                        StationSeriesId,
                                        StationNum,
                                        BeginStationSeriesId,
                                        BeginStationNum,
                                        EndStationSeriesId,
                                        EndStationNum,
                                        ILIASFeatureIdentifier,
                                        ILIASOdometer,
                                        ILIASSensorP1Strain,
                                        ILIASSensorP2Strain,
                                        ILIASSensorP3Strain,
                                        ILIASSensorP4Strain,
                                        ILIASSensorP5Strain,
                                        ILIASSensorP6Strain,
                                        ILIASSensorP7Strain,
                                        ILIASSensorP8Strain,
                                        ILIASAxialStrain,
                                        ILIASSensorP1Orientation,
                                        ILIASSensorP2Orientation,
                                        ILIASSensorP3Orientation,
                                        ILIASSensorP4Orientation,
                                        ILIASSensorP5Orientation,
                                        ILIASSensorP6Orientation,
                                        ILIASSensorP7Orientation,
                                        ILIASSensorP8Orientation,
                                        ILIASAreaOfInterest,
                                        ILIASAnalysisDomainId,
                                        ILIASComments,
                                        ILIASX,
                                        ILIASY,
                                        ILIASZ,
                                        ILIASLatitude,
                                        ILIASLongitude,
                                        ILIASGirthWeldNum,
                                        ILIASDistanceFROMGirthWeld,
                                        ILIASGirthWeldNumDS,
                                        ILIASDistanceFROMGirthWeldDS,
                                        IRASCustomDate1,
                                        IRASCustomDate2,
                                        IRASCustomDate3,
                                        IRASCustomDate4,
                                        IRASCustomDate5,
                                        IRASCustomNum1,
                                        IRASCustomNum2,
                                        IRASCustomNum3,
                                        IRASCustomNum4,
                                        IRASCustomNum5,
                                        IRASCustomString1,
                                        IRASCustomString2,
                                        IRASCustomString3,
                                        IRASCustomString4,
                                        IRASCustomString5,
                                        CreatedUser,
                                        CreatedDate,
                                        LastModByUserId,
                                        LastModDateTime)
							        SELECT  Id,
                                            EffectiveStartDate,
                                            EffectiveEndDate,
                                            Stg_ILIId,
                                            Stg_ILIRangeId,
                                            StationSeriesId,
                                            StationNum,
                                            BeginStationSeriesId,
                                            BeginStationNum,
                                            EndStationSeriesId,
                                            EndStationNum,
                                            ILIASFeatureIdentifier,
                                            ILIASOdometer,
                                            ILIASSensorP1Strain,
                                            ILIASSensorP2Strain,
                                            ILIASSensorP3Strain,
                                            ILIASSensorP4Strain,
                                            ILIASSensorP5Strain,
                                            ILIASSensorP6Strain,
                                            ILIASSensorP7Strain,
                                            ILIASSensorP8Strain,
                                            ILIASAxialStrain,
                                            ILIASSensorP1Orientation,
                                            ILIASSensorP2Orientation,
                                            ILIASSensorP3Orientation,
                                            ILIASSensorP4Orientation,
                                            ILIASSensorP5Orientation,
                                            ILIASSensorP6Orientation,
                                            ILIASSensorP7Orientation,
                                            ILIASSensorP8Orientation,
                                            ILIASAreaOfInterest,
                                            ILIASAnalysisDomainId,
                                            ILIASComments,
                                            ILIASX,
                                            ILIASY,
                                            ILIASZ,
                                            ILIASLatitude,
                                            ILIASLongitude,
                                            ILIASGirthWeldNum,
                                            ILIASDistanceFROMGirthWeld,
                                            ILIASGirthWeldNumDS,
                                            ILIASDistanceFROMGirthWeldDS,
                                            IRASCustomDate1,
                                            IRASCustomDate2,
                                            IRASCustomDate3,
                                            IRASCustomDate4,
                                            IRASCustomDate5,
                                            IRASCustomNum1,
                                            IRASCustomNum2,
                                            IRASCustomNum3,
                                            IRASCustomNum4,
                                            IRASCustomNum5,
                                            IRASCustomString1,
                                            IRASCustomString2,
                                            IRASCustomString3,
                                            IRASCustomString4,
                                            IRASCustomString5,
                                            CreatedUser,
                                            CreatedDate,
                                            LastModByUserId,
                                            LastModDateTime
							        FROM tmpStg_ILIAxialStrain
                                    ]';
            END IF;
        END;

        -----------------------Update the version checkpoint within versioninfo table if it exists------------------

        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                SET DBVersionCheckPoint = 2';
        END IF;

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
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
	/********************************************************************************************************/
    -- Update VersionInfo Application Version 6.4 Release 0 Updates 06
    /********************************************************************************************************/

    IF dbVersion = 640005 AND dbVersionCheckPoint = 2
    THEN
        UPDATE versionInfo
        SET DBVersion = '640006', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 06';
        
        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                                SET DBVersionCheckPoint = 0';
        END IF;

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
      dbVersion NUMBER(10);
      dbVersionCheckPoint NUMBER(5);
      CNT NUMBER(6);
      CatID NUMBER;
      LDID NUMBER;
      LDCodeDesc VARCHAR2(20);

      e_missing_field EXCEPTION;
      PRAGMA EXCEPTION_INIT(e_missing_field, -20001);

BEGIN
    -- Ensure required listdomains exist for 6.4 rel 0 Import site. Note expect to not require these any more in subsequent release.

    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640006 AND dbVersionCheckPoint = 0
    THEN

        EXECUTE IMMEDIATE q'[ALTER TABLE listdomain MODIFY (lastmodbyuserid VARCHAR2(45) DEFAULT SYS_CONTEXT( 'userenv','os_user'))]';
        EXECUTE IMMEDIATE q'[ALTER TABLE listdomain MODIFY (lastmoddatetime DATE DEFAULT CURRENT_DATE)]';

        -- Add the default (field value not found) LD for excavation site anomaly types
        SELECT 'OTHER' INTO LDCodeDesc FROM DUAL;

        SELECT DomainCatalogId INTO CatId 
        FROM DomainCatalogColXRef 
        WHERE UPPER(TableName) = UPPER('MetalLoss' )
        AND UPPER(ColumnName) = UPPER('MetalLossTypeDomainId');

        SELECT COUNT(Id) INTO CNT 
        FROM ListDomain 
        WHERE DomainCatalogId = CatID 
        AND Code = LDCodeDesc;

        IF (CNT = 0 AND CatID IS NOT NULL)
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 INTO LDID FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) 
            VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        SELECT DomainCatalogId INTO CatID 
        FROM DomainCatalogColXRef 
        WHERE TableName = 'MechanicalDamage' 
        AND ColumnName = 'MechDmgDefectTypeDomainId';

        SELECT COUNT(Id) INTO CNT
        FROM ListDomain 
        WHERE DomainCatalogId = CatID 
        AND Code = LDCodeDesc;

        IF CNT = 0 AND CatID IS NOT NULL
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 INTO LDID FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) 
            VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        SELECT '25' INTO LDCodeDesc FROM DUAL;

        SELECT DomainCatalogId INTO CatID 
        FROM DomainCatalogColXRef 
        WHERE TableName = 'ExcavationSiteCrackAnomaly' 
        AND ColumnName = 'ESCATypeDomainId';

        SELECT COUNT(Id) INTO CNT
        FROM ListDomain 
        WHERE DomainCatalogId = CatID AND Code = LDCodeDesc;

        IF (CNT = 0 AND CatID IS NOT NULL)
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 INTO LDID FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) 
            VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        --Verify LDs exist
        SELECT COUNT(*) INTO CNT 
        FROM ListDomain ld 
        JOIN DomainCatalogColXRef x ON x.DomainCatalogId = ld.DomainCatalogId   
            AND UPPER(ld.Code) IN  ('25', 'OTHER')
        WHERE UPPER(x.TableName )IN (UPPER('ExcavationSiteCrackAnomaly'), UPPER('MechanicalDamage'), UPPER('metalloss')) 
            AND UPPER(x.ColumnName) LIKE UPPER('%TypeDomainId');

        IF(CNT != 3)     
        THEN
        --raise e_missing_field;
        raise_application_error (-20001, 'Script failed. Missing DomainCatalog or LISTDOMAIN for ExcavationSite anomaly *TypeDomainId fields');
        END IF;

        --Create missing excavation site anomaly status default (field value not found) list domains
        SELECT 'Unknown' INTO  LDCodeDesc FROM DUAL;

        SELECT DomainCatalogId INTO CatID 
        FROM DomainCatalogColXRef 
        WHERE UPPER(TableName) = UPPER('MetalLoss') AND UPPER(ColumnName) = UPPER('MetalLossStatusDomainId');

        SELECT COUNT(Id) INTO CNT
        FROM ListDomain 
        WHERE DomainCatalogId = CatID AND Code = LDCodeDesc;

        IF CNT = 0 AND CatID IS NOT NULL
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 
            INTO LDID 
            FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        SELECT DomainCatalogId INTO CatID
        FROM DomainCatalogColXRef 
        WHERE UPPER(TableName) = UPPER('MechanicalDamage') AND UPPER(ColumnName) = UPPER('MechDmgStatusDomainId');

        SELECT COUNT(Id) INTO CNT
        FROM ListDomain 
        WHERE DomainCatalogId = CatID AND Code = LDCodeDesc;

        IF (CNT = 0 AND CatID IS NOT NULL)
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 
            INTO LDID
            FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        SELECT DomainCatalogId INTO CatID
        FROM DomainCatalogColXRef 
        WHERE UPPER(TableName) = UPPER('ExcavationSiteCrackAnomaly') AND UPPER(ColumnName) = UPPER('ESCAStatusDomainId');

        SELECT COUNT(Id) INTO CNT
        FROM ListDomain 
        WHERE DomainCatalogId = CatID AND Code = LDCodeDesc;

        IF (CNT = 0 AND CatID IS NOT NULL)
        THEN
            SELECT COALESCE(MAX(ID), 0) + 1 
            INTO LDID 
            FROM ListDomain;

            INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr) VALUES (LDID, CatID, LDCodeDesc, LDCodeDesc);
        END IF;

        -- Verify LDs exist
        SELECT Count(*) INTO CNT
        FROM ListDomain ld 
        Join DomainCatalogColXRef x on x.DomainCatalogId = ld.DomainCatalogId AND ld.Code in  ('Unknown')
        WHERE UPPER(x.TableName) in (UPPER('ExcavationSiteCrackAnomaly'), UPPER('MechanicalDamage'), UPPER('metalloss')) 
            AND UPPER(x.ColumnName) LIKE UPPER('%StatusDomainId');

        IF(CNT != 3) 
        THEN
        Raise_application_error (-20001,'Script failed. Missing DomainCatalog or LISTDOMAIN for ExcavationSite anomaly *StatusDomainId fields');
        END IF;

        EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                        SET DBVersionCheckPoint = 1';
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
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
    /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 07
    /********************************************************************************************************/
    IF dbVersion = 640006 AND dbVersionCheckPoint = 1
    THEN
        UPDATE versionInfo
        SET DBVersion = '640007', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 07';
        
        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo 
                                SET DBVersionCheckPoint = 0';
        END IF;

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