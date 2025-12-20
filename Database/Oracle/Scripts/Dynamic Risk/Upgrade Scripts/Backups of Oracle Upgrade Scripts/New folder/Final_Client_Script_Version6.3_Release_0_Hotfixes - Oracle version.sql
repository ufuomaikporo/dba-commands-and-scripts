BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630001 AND dbVersionCheckPoint = 0
        THEN
 
			/*
				New record to be inserted in the SystemPreferences table of the LINK DATABASE
			*/
			-- Add maximum sequential virtual table processes record to SystemPreferences table
            declare cnt int;  
            BEGIN
                SELECT count(*) into cnt FROM SystemPreferences WHERE ParameterName = 'MaxSequentialVTProcesses';
                
                if cnt = 1
                then
                    INSERT INTO SystemPreferences (ParameterName, Value, RawValue)
                    VALUES ('MaxSequentialVTProcesses', 5, null);
                end if;    

            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
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
        IF dbVersion = 630001 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 Updates 02
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630002', DBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfixes Updates 02';
            
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
        IF dbVersion = 630002 AND dbVersionCheckPoint = 0
        THEN
            DECLARE CNT INT;
            CONSTRAINTNAME VARCHAR(200);
            BEGIN
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('StructureVertex') and upper(Column_Name) = upper('StructureGUID');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTUREVERTEX ADD STRUCTUREGUID varchar2(50) NULL';
                END IF;
            
                EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STOREYCNT DEFAULT NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY LASTMODBYUSERID DEFAULT NULL';
                EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY LASTMODDATETIME DEFAULT NULL';
                
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('STRUCTURE') and upper(Column_Name) = upper('CREATEDDATE');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CREATEDDATE DATE';
                ELSE
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY CREATEDDATE DEFAULT NULL';
                END IF;
                
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('STRUCTURE') and upper(Column_Name) = upper('CREATEDUSER');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CREATEDUSER varchar(45)';
                ELSE
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY CREATEDUSER DEFAULT NULL';
                END IF;
                
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('STRUCTURECOORDSYSDOMAINID');
               
                IF CNT > 0 
                THEN
                    SELECT UCC.CONSTRAINT_NAME INTO CONSTRAINTNAME FROM USER_CONS_COLUMNS UCC 
                    INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                    WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('STRUCTURECOORDSYSDOMAINID');
                    
                    IF CONSTRAINTNAME IS NOT NULL
                    THEN
                        EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE DROP  CONSTRAINT ' || CONSTRAINTNAME;
                    END IF;
                END IF;
            
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('OccupancyCtgryDomainId');
               
                IF CNT > 0 
                THEN
                    SELECT UCC.CONSTRAINT_NAME INTO CONSTRAINTNAME FROM USER_CONS_COLUMNS UCC 
                    INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                    WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('OccupancyCtgryDomainId');
                    
                    IF CONSTRAINTNAME IS NOT NULL
                    THEN
                        EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE DROP  CONSTRAINT ' || CONSTRAINTNAME;
                    END IF;
                END IF;

                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureTypeDomainId');
               
                IF CNT > 0 
                THEN
                    SELECT UCC.CONSTRAINT_NAME INTO CONSTRAINTNAME FROM USER_CONS_COLUMNS UCC 
                    INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                    WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureTypeDomainId');
                    
                    IF CONSTRAINTNAME IS NOT NULL
                    THEN
                        EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE DROP  CONSTRAINT ' || CONSTRAINTNAME;
                    END IF;
                END IF;
            
                DECLARE
                   -- cursor
                  CURSOR c_cursor IS
                
                    SELECT UCC.CONSTRAINT_NAME FROM USER_CONS_COLUMNS UCC 
                    INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                    WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('C') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') 
                    AND (UPPER(UCC.COLUMN_NAME) = UPPER('StructureActiveFlg') OR UPPER(UCC.COLUMN_NAME) = UPPER('StructureAreaPointInd'));  
                  
                   -- record    
                   r_conName c_cursor%ROWTYPE;
                   script varchar(2000);
                
                BEGIN
                
                  OPEN c_cursor;
                
                  LOOP
                    FETCH  c_cursor  INTO r_conName;
                    EXIT WHEN c_cursor%NOTFOUND;
                    
                    script := 'ALTER TABLE STRUCTURE DROP  CONSTRAINT ' || r_conName.CONSTRAINT_NAME;
                    
                    EXECUTE IMMEDIATE script;
                    --DBMS_OUTPUT.PUT_LINE(script);
                
                  END LOOP;
                
                  CLOSE c_cursor;
                END;
            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
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
        IF dbVersion = 630002 AND dbVersionCheckPoint = 1
        THEN
            DECLARE CNT INT;
            BEGIN
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('EffectiveStartDate') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY EFFECTIVESTARTDATE DATE NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('StructureTypeDomainId') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STRUCTURETYPEDOMAINID NUMBER(7,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('BuildingCnt') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY BUILDINGCNT NUMBER(5,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('OccupancyCtgryDomainId') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY OCCUPANCYCTGRYDOMAINID NUMBER(7,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('StructureCoordSysDomainId') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STRUCTURECOORDSYSDOMAINID NUMBER(7,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('StructureAreaPointInd') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STRUCTUREAREAPOINTIND CHAR(1) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('StructureActiveFlg') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STRUCTUREACTIVEFLG NUMBER(1,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('StoreyCnt') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STOREYCNT NUMBER(5,0) NULL';
                END IF;

                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Structure') and upper(Column_Name) = upper('SourceId') and NULLABLE = 'N';
               
                IF CNT > 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY SOURCEID varchar(50) NULL';
                END IF;
            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 2;
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
        IF dbVersion = 630002 AND dbVersionCheckPoint = 2
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY STOREYCNT DEFAULT 0';
            EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY CREATEDUSER DEFAULT USER';
            EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY CREATEDDATE DEFAULT SYSDATE';
            EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY LASTMODBYUSERID DEFAULT USER';
            EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE MODIFY LASTMODDATETIME DEFAULT SYSDATE';

            DECLARE CNT INT;
            BEGIN
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureCoordSysDomainId');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CONSTRAINT FK_STRUCTCOORDSYSDOMAINID FOREIGN KEY (STRUCTURECOORDSYSDOMAINID) REFERENCES LISTDOMAIN(ID)';
                END IF;

                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('OccupancyCtgryDomainId');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CONSTRAINT FK_STRUCTOCCUPCTGRYDOMAINID FOREIGN KEY (OCCUPANCYCTGRYDOMAINID) REFERENCES LISTDOMAIN(ID)';
                END IF;

                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureTypeDomainId');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CONSTRAINT FK_STRUCTTYPEDOMAINID FOREIGN KEY (STRUCTURETYPEDOMAINID) REFERENCES LISTDOMAIN(ID)';
                END IF;

                SELECT Count(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('C') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') 
                AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureActiveFlg') AND upper(UCC.CONSTRAINT_NAME) = upper('CKC_STRUCTUREACTIVEFL_STRUCTUR');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE STRUCTURE ADD CONSTRAINT CKC_STRUCTUREACTIVEFL_STRUCTUR CHECK (STRUCTUREACTIVEFLG IN (1 , 0))';
                END IF;

                SELECT Count(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('C') AND UPPER(UCC.TABLE_NAME) = UPPER('STRUCTURE') 
                AND UPPER(UCC.COLUMN_NAME) = UPPER('StructureAreaPointInd') AND upper(UCC.CONSTRAINT_NAME) = upper('CKC_STRUCTUREAREAPOIN_STRUCTUR');
               
                IF CNT = 0 
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE Structure ADD CONSTRAINT CKC_STRUCTUREAREAPOIN_STRUCTUR CHECK (StructureAreaPointInd IN (''P'', ''A''))';
                END IF;
            END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 3;
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
        IF dbVersion = 630002 AND dbVersionCheckPoint = 3
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 0 Updates 03
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630003', DBVersionComment = 'Service Pack DDL 6.3, Rel. 0, Hotfixes Updates 03';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/
