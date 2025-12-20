declare cnt int;                     

BEGIN                     
    select count(*) into cnt from User_Tab_columns t 
    Where Upper(Table_Name) = upper('VersionInfo') and upper(Column_Name) = upper('DBVersionCheckPoint');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE VERSIONINFO ADD DBVERSIONCHECKPOINT number(5) NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN                     
    select count(*) into cnt from User_Tab_columns t 
    Where Upper(Table_Name) = upper('VersionHistory') and upper(Column_Name) = upper('DBVersionCheckPoint');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE VERSIONHISTORY ADD DBVERSIONCHECKPOINT number(5) NULL';

		UPDATE VERSIONINFO SET DBVERSIONCHECKPOINT = 0;
    end if;
END;
/

create or replace TRIGGER "TH_VERSIONINFO" 
    BEFORE UPDATE
    OF DBVersion,DBVersionComment,LastUpgradeUserId,LastUpgradedateTime,LastUpgradeType, DBVERSIONCHECKPOINT
    ON VERSIONINFO
    FOR EACH ROW
BEGIN
    -- Update time stamp and user.
    :new.LastModByUserid := USER;
    :new.LastModdateTime := SYSDATE;

INSERT INTO VersionHistory (DBVersion, DBVersionComment, LastModByUserId, LastModdateTime, DATAEXCHANGELASTRUNDATETIME,LastUpgradeUserId,LastUpgradedateTime,LastUpgradeType, DBVERSIONCHECKPOINT)
values
(:old.DBVersion, :old.DBVersionComment, :old.LastModByUserId, :old.LastModdateTime, :old.DATAEXCHANGELASTRUNDATETIME,:old.LastUpgradeUserId,:old.LastUpgradedateTime,:old.LastUpgradeType, :old.DBVERSIONCHECKPOINT
);
end;
/
BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 620201 AND dbVersionCheckPoint = 0
        THEN
            -- AddDepthPctToExcavationSiteCA26151.sql
            /* Add Depth percent field to ExcavationSiteCrackAnamaly */
            declare cnt int;  
            BEGIN
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('ExcavationSiteCrackAnomaly') and upper(Column_Name) = upper('ESCADepthPct');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE EXCAVATIONSITECRACKANOMALY ADD ESCADEPTHPCT NUMBER(8,5) NULL';
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
        IF dbVersion = 620201 AND dbVersionCheckPoint = 1
        THEN
   			-- CLIENT_AlignmentRange_AddAxialAlignment.sql
			-- Adding axial alignment column to AlignmentRange table
            declare cnt int;  
            BEGIN
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('AlignmentRange') and upper(Column_Name) = upper('AxialAlignment');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE AlignmentRange ADD AxialAlignment NUMBER(1,0) DEFAULT 0 NULL';
                end if;    
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
        IF dbVersion = 620201 AND dbVersionCheckPoint = 2
        THEN
			-- CLIENT_Girthweld_AddOrientation.sql
			-- Adding seam orientation column to GirthWeld table
            declare cnt int;  
            BEGIN
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('GirthWeld') and upper(Column_Name) = upper('SeamOrientation');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE GirthWeld ADD SeamOrientation NUMBER(5,2) NULL';
                end if;    
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
        IF dbVersion = 620201 AND dbVersionCheckPoint = 3
        THEN
			-- alterIncidentHistorySTAGE.sql
            declare cnt int;                     
            
            BEGIN 
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') 
                and upper(Column_Name) = upper('DamageTypeDomainId') and Nullable = 'Y';
                
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY MODIFY DAMAGETYPEDOMAINID NUMBER(7,0) NULL';
                end if;

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') 
                and upper(Column_Name) = upper('ThreatTypeDomainId') and Nullable = 'Y';
                
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY MODIFY THREATTYPEDOMAINID NUMBER(7,0) NULL';
                end if;

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') 
                and upper(Column_Name) = upper('DamageCount') and Nullable = 'Y';
                
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY MODIFY DAMAGECOUNT FLOAT NULL';
                end if;

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') 
                and upper(Column_Name) = upper('EffectiveStartDate') and Nullable = 'Y';
                
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY MODIFY EFFECTIVESTARTDATE DATE NULL';
                end if;

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('SourceId');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE IncidentHistory ADD SOURCEID VARCHAR2(50) NULL';
                end if;    

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('CreatedUser');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY ADD CREATEDUSER VARCHAR2(45) DEFAULT user NOT NULL';
                end if;    

                cnt := 0;
                select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('CreatedDate');
    
                if cnt = 0
                then
                    execute IMMEDIATE 'ALTER TABLE INCIDENTHISTORY ADD CREATEDDATE DATE DEFAULT SYSDATE NOT NULL';
                end if;    
            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 4;
            
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
        IF dbVersion = 620201 AND dbVersionCheckPoint = 4
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.2 Release 3 Updates 01
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '620301', DBVersionComment = 'Service Pack DDL 6.2, Rel. 3, Updates 01';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/

