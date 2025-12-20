SET SERVEROUTPUT ON;

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 620301 AND dbVersionCheckPoint = 0
        THEN
            -- Pressure_AlterSchema.sql
            declare cnt int;  
            BEGIN
                select count(*) into cnt from USER_INDEXES where upper(INDEX_NAME) = upper('IX_FK_PressBegStationSeriesId');

                if cnt = 1
                then
                    execute IMMEDIATE 'DROP INDEX IX_FK_PRESSBEGSTATIONSERIESID';
                end if;    

                select count(*) into cnt from USER_INDEXES where upper(INDEX_NAME) = upper('IX_FK_PressEndStationSeriesId');

                if cnt = 1
                then
                    execute IMMEDIATE 'DROP INDEX IX_FK_PRESSENDSTATIONSERIESID';
                end if;    

                select count(*) into cnt from USER_INDEXES where upper(INDEX_NAME) = upper('IX_FK_PressPressureTypeDomainI');

                if cnt = 1
                then
                    execute IMMEDIATE 'DROP INDEX IX_FK_PRESSPRESSURETYPEDOMAINI';
                end if;    

                SELECT COUNT(*) INTO CNT FROM USER_CONSTRAINTS WHERE UPPER(TABLE_NAME)  = UPPER('Pressure') AND UPPER(CONSTRAINT_NAME) = UPPER('FK__Pressure__Pressu_LD');
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE DROP CONSTRAINT FK__PRESSURE__PRESSU_LD';        
                END IF;

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('PressureTypeDomainId') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY PRESSURETYPEDOMAINID NUMBER(7,0) NULL';
                END IF;

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('Pressure') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY PRESSURE NUMBER(15,4) NULL';
                END IF;                

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('PressureComment') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY PRESSURECOMMENT VARCHAR2(255) NULL';
                END IF;
                
                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('BeginStationSeriesId') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY BEGINSTATIONSERIESID number(10,0) NULL';
                END IF; 

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('BeginStationNum') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY BEGINSTATIONNUM number(13,5) NULL';
                END IF;     

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('EndStationSeriesId') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY ENDSTATIONSERIESID number(10,0) NULL';
                END IF;

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('EndStationNum') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY ENDSTATIONNUM number(13,5) NULL';
                END IF;

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('EffectiveStartDate') And nullable = 'N';
                
                IF CNT = 1 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY EFFECTIVESTARTDATE Date NULL';
                END IF;		

                SELECT COUNT(*) INTO CNT from user_tab_columns WHERE UPPER(Table_Name) = UPPER('Pressure') AND UPPER(Column_Name) = UPPER('sourceId');
                
                IF CNT = 0
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE ADD SOURCEID Varchar2(50) NULL';
                END IF;                
            END;        

            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/


DECLARE
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 620301 AND dbVersionCheckPoint = 1
    THEN
        -- Pressure_AlterSchema.sql

        SELECT COUNT(*) INTO CNT FROM USER_CONSTRAINTS WHERE UPPER(TABLE_NAME)  = UPPER('Pressure') AND UPPER(CONSTRAINT_NAME) = UPPER('FK__Pressure__Pressu_LD');

        IF CNT = 0 
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE ADD CONSTRAINT FK__PRESSURE__PRESSU_LD FOREIGN KEY (PRESSURETYPEDOMAINID) REFERENCES LISTDOMAIN(ID)';
        END IF;

        SELECT COUNT(*) INTO CNT FROM USER_IND_COLUMNS WHERE COLUMN_NAME = 'PRESSURETYPEDOMAINID' AND table_name = 'PRESSURE';                                

        if cnt = 0
        then
            execute IMMEDIATE 'CREATE INDEX IX_FK_PRESSPRESSURETYPEDOMAINI ON PRESSURE ("PRESSURETYPEDOMAINID")';
        end if;    

        SELECT COUNT(*) INTO CNT FROM USER_IND_COLUMNS WHERE COLUMN_NAME = 'BEGINSTATIONSERIESID' AND table_name = 'PRESSURE';                                
        
        if cnt = 0
        then
            execute IMMEDIATE 'CREATE INDEX IX_FK_PRESSBEGSTATIONSERIESID ON PRESSURE ("BEGINSTATIONSERIESID")';
        end if;    

        SELECT COUNT(*) INTO CNT FROM USER_IND_COLUMNS WHERE COLUMN_NAME = 'ENDSTATIONSERIESID' AND table_name = 'PRESSURE';                                

        if cnt = 0
        then
            execute IMMEDIATE 'CREATE INDEX IX_FK_PRESSENDSTATIONSERIESID ON PRESSURE ("ENDSTATIONSERIESID")';
        end if;          

        UPDATE VersionInfo SET DBVersionCheckPoint = 2;
    END IF;	
EXCEPTION
    when others then
    ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                    || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;

/                

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 620301 AND dbVersionCheckPoint = 2
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 Updates 01
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630001', DBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Updates 01';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/
