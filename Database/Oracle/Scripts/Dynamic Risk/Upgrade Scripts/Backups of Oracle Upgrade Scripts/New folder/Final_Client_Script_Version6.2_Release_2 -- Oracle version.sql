/********************************************************************************************************/
-- Update VersionInfo Application Version 6.2 Release 2 Updates 0
/********************************************************************************************************/

UPDATE VersionInfo
SET DBVersion = '620200', DBVersionComment = 'Service Pack DDL 6.2, Rel. 2, Updates 00'
/

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

-- CLIENT_CA_MAOPFeatureEnabled.sql

--If there is no MAOP Computation Type, add a new record

declare cnt int;                     

BEGIN        
	SELECT count(*) INTO cnt from RCComputationType WHERE Code = 'MAOP';
    
    if cnt = 0
    then
        execute IMMEDIATE 'INSERT INTO RCComputationType (Id, Code, Description, TypeEnabled) VALUES ((Select COALESCE(MAX(Id), 0) + 1 from RCComputationType), ''MAOP'', ''MAOP Scenario'', ''Y'')';
    end if;
END;
/

--Update the MAOP Senario to be enabled.
UPDATE RCComputationType SET TypeEnabled = 'Y' WHERE Code = 'MAOP'
/

UPDATE VersionInfo SET DBVersionCheckPoint = 1;
/

-- Add_V6_DesignClass_Columns.sql

declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('EffectiveStartDate') and Nullable = 'Y';
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS MODIFY EFFECTIVESTARTDATE DATE NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN 

    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('BeginStationNum') and Nullable = 'N';
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS ALTER COLUMN BEGINSTATIONNUM NUMERIC(13,5) NOT NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN 

    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('EndStationNum') and Nullable = 'N';
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS ALTER COLUMN ENDSTATIONNUM NUMERIC(13,5) NOT NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('SourceId');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS ADD SOURCEID VARCHAR2(50) NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('CreatedDate');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS ADD CREATEDDATE DATE DEFAULT SYSDATE NOT NULL';
    end if;
END;
/

declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('DesignClass') and upper(Column_Name) = upper('CreatedUser');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE DESIGNCLASS ADD CREATEDUSER VARCHAR2(45) DEFAULT USER NOT NULL';
    end if;
END;
/

UPDATE VersionInfo SET DBVersionCheckPoint = 2;
/

-- CLIENT_ILIFAC_FacNumberToVarchar.sql
-- Modify the Facility number column to be Varchar
declare cnt int;                     

BEGIN                     
    select count(*) into cnt from User_Tab_columns t 
    Where Upper(Table_Name) = upper('InlineInspectionFacility') and upper(Column_Name) = upper('ILIFacNumberTemp');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE InlineInspectionFacility ADD ILIFacNumberTemp VARCHAR2(30) NULL';
    end if;
END;
/

Update InlineInspectionFacility set ILIFacNumberTemp = ILIFacNumber;
/


Declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('InlineInspectionFacility') and upper(Column_Name) = upper('ILIFacNumber');
    
    if cnt = 1
    then
        execute IMMEDIATE 'ALTER TABLE INLINEINSPECTIONFACILITY DROP COLUMN ILIFACNUMBER';
    end if;
END;
/

declare cnt int;                     

BEGIN                     
    select count(*) into cnt from User_Tab_columns t 
    Where Upper(Table_Name) = upper('InlineInspectionFacility') and upper(Column_Name) = upper('ILIFacNumber');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE INLINEINSPECTIONFACILITY ADD ILIFACNUMBER VARCHAR2(30) NULL';
    end if;
END;
/

Update InlineInspectionFacility set ILIFacNumber = ILIFacNumberTemp;
/

declare cnt int;                     

BEGIN 
    select count(*) into cnt from user_tab_columns where upper(Table_Name) = upper('InlineInspectionFacility') and upper(Column_Name) = upper('ILIFacNumberTemp');
    
    if cnt = 0
    then
        execute IMMEDIATE 'ALTER TABLE INLINEINSPECTIONFACILITY DROP COLUMN ILIFACNUMBERTEMP';
    end if;
END;
/

UPDATE VersionInfo SET DBVersionCheckPoint = 3
/

/********************************************************************************************************/
-- Update VersionInfo Application Version 6.2 Release 2 Updates 01
/********************************************************************************************************/

UPDATE VersionInfo
SET DBVersion = '620201', DBVersionComment = 'Service Pack DDL 6.2, Rel. 2, Updates 01';

UPDATE VERSIONINFO SET DBVERSIONCHECKPOINT = 0;

/