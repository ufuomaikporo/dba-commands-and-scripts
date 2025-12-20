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