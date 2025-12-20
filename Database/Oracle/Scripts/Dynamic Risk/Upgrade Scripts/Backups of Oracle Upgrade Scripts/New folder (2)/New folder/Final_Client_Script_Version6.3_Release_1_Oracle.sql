DECLARE
   -- cursor
  CURSOR s_cursor IS

select 'declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper(''S_' || Table_Name || ''');
    
    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate(''CREATE SEQUENCE S_' || Table_Name || ' START WITH ''||seqval||'' INCREMENT BY 1'');
    END IF;
END;' as script from user_tables Where Table_Name in ('ACTIONITEM',
'ACTIONITEMCOMMENTS',
'ACTIONITEMRANGE',
'ACTIONITEMREVISION',
'ACVGSURVEY',
'ACVGSURVEYANOMALY',
'ACVGSURVEYRANGE',
'ACVGSURVEYREADING',
'BELLHOLEEXCAVATION',
'BEND',
'BENDREMARK',
'CALCCLASSAREA',
'CALCLEAKTIMEPROFILE',
'CALCOUTFLOWLEAKPROFILE',
'CALCOUTFLOWSTATISTICS',
'CALCOUTFLOWSTATISTICSTYPE',
'CALCOUTFLOWVALVEPROFILE',
'CALCOVERLANDLEAKPROFILE',
'CALCULATOR',
'CALCULATORKIND',
'CALCULATORPROJECT',
'CALCULATORTYPE',
'CASING',
'CASINGREMARK',
'CATEGORY',
'CATEGORYDATALISTDOMAINXREF',
'CATEGORYDATANUMXREF',
'CENTERLINEALIGNMENT',
'CENTERLINEDEFINITION',
'CENTERLINEMAPPING',
'CLASSAREA',
'CLASSIFICATION',
'CLASSIFICATIONRANGE',
'COATING',
'COATINGCONDITION',
'COATINGDEFECT',
'COATINGTHICKNESS',
'COLOCATECLUSTER',
'COLOCATECRACK',
'COLOCATEGIRTHWELD',
'COLOCATENCD',
'COLOCATESITE',
'CONSTANT',
'CORPORATION',
'CORROSIONDEPOSIT',
'COUPON',
'COVERDEPTH',
'CPSURVEY',
'CPSURVEYRANGE',
'CPSURVEYREADING',
'CRACKANOMALY',
'CRACKANOMALYCLUSTER',
'CROSSING',
'DAMAGEPREVENTION',
'DATAMANAGERCATEGORY',
'DATAMANAGERFIELD',
'DATAMANAGERTABLE',
'DCVGSURVEY',
'DCVGSURVEYANOMALY',
'DCVGSURVEYRANGE',
'DCVGSURVEYREADING',
'DESIGNCLASS',
'DISCHARGESUBSYSTEM',
'DISTBUSINESSDISTRICT',
'DISTINSIDEMETER',
'DISTPOPULATIONDENSITY',
'DISTSERVICEHEADSUSCEPT',
'DOMAINCATALOG',
'EARTHQUAKEAREA',
'ELBOW',
'ELECTROLYTEPH',
'ELEVATIONPROFILE',
'EXCAVATIONGIRTHWELD',
'EXCAVATIONPROJECT',
'EXCAVATIONSITE',
'EXCAVATIONSITECRACKANOMALY',
'EXPOSEDPIPE',
'EXTRUSION',
'FABRICATION',
'FABRICATIONREMARK',
'FACILITY',
'FACILITYFLOWGROUP',
'FACILITYFLOWGROUPCOMPONENT',
'FACILITYFLOWOPERATOR',
'FAILUREDETECTION',
'FAULTAREA',
'FLANGE',
'FLOODAREA',
'FROSTAREA',
'GIRTHWELD',
'HCACFR',
'HCACFRSEG',
'HCAPIPEGASCONSTANTFACTOR',
'HCAPIPEPIRBUFFER',
'HCAREASONS',
'HURRICANEAREA',
'HYDROTEST',
'HYDROTESTRANGE',
'IDENTITYCOLUMN',
'ILIERROR',
'ILIEXCAVATION',
'IMAGE',
'INCIDENT',
'INCIDENTHISTORY',
'INLINEINSPECTION',
'INLINEINSPECTIONBENDSTRAIN',
'INLINEINSPECTIONCRACKANOMALY',
'INLINEINSPECTIONCRSNCALLBOX',
'INLINEINSPECTIONFACILITY',
'INLINEINSPECTIONFEATURE',
'INLINEINSPECTIONJOINT',
'INLINEINSPECTIONNONCRSNDFCT',
'INLINEINSPECTIONRANGE',
'INLINEINSPECTIONREMARK',
'INLINEINSPECTIONSTRAIN',
'INSPECTIONDATA',
'INTERNALCOATING',
'INTERNALINSPECTION',
'JOINTCOATING',
'LANDSLIDEAREA',
'LANDUSE',
'LIGHTNINGSTRIKEAREA',
'LINELOOP',
'LINELOOPSTATUS',
'LISTDOMAIN',
'MAINTENANCE',
'MAINTENANCEPROJECT',
'MAOP',
'MAOPPIPEPROPERTIES',
'MARKER',
'MARKERREMARK',
'MATRIXCOLORTEMPLATE',
'MECHANICALDAMAGE',
'METALLOSS',
'MICANALYSIS',
'MILEPOST',
'MLVCORRECTION',
'MLVSECTION',
'MOP',
'NODE',
'NODECONNECTION',
'NODENETWORK',
'OPERATINGDATA',
'OPERATINGUNIT',
'OUTSIDEFORCES',
'PCMSURVEY',
'PCMSURVEYRANGE',
'PCMSURVEYREADING',
'PIPECONDITION',
'PIPELINESYSTEM',
'PIPESEGMENT',
'PIPESEGMENTREMARK',
'PIPESOILPOTENTIALPIPE',
'PIPESOILPOTENTIALSURFACE',
'PIPEWALLTHICKNESS',
'PREDEFINEDLOCATION',
'PRESSURE',
'QUERYSTRUCTURE',
'RADIMCLASSIFIERCATEGORY',
'RADIMP',
'RADIMPCLASSIFIER',
'RADIMPCLASSIFIERITEM',
'RADIMPEQUIPMENTSERVICE',
'RADIMPSCORETABLE',
'RADIMPVARIABLE',
'RADIMPVIEW',
'RADIMPVIEWCOLUMN',
'RADIMPVIEWSECTION',
'RCCATEGORYSTRUCTURE',
'RCCOMPUTATIONTYPE',
'RCCSACLASSCALC',
'RCCSACLASSCALCFLAGTYPE',
'RCCSACLASSCALCSEG',
'RCCSACLASSFLAGS',
'RCCSACLASSFLAGTYPE',
'RCDIMP',
'RCDIMPBUCKET',
'RCDIMPBUCKETCATEGORY',
'RCDIMPBUCKETCONSTRAINT',
'RCDIMPEQUIPMENT',
'RCDIMPLEAKGRADE',
'RCDIMPPROMOTE',
'RCDIMPREMARKS',
'RCDIMPTHREAT',
'RCDOTCLASSCALC',
'RCDOTCLASSCALCFLAGTYPE',
'RCDOTCLASSCALCSEG',
'RCDOTCLASSFLAGS',
'RCDOTCLASSFLAGTYPE',
'RCHCACALC',
'RCHCACALCSEG',
'RCHCAFLAGS',
'RCHCAFLAGTYPE',
'RCHCAREASONS',
'RCHCAREASONTYPE',
'RCMAOPCALC',
'RCMAOPCALCSEG',
'RCMAOPFLAGACTIONTYPE',
'RCMAOPFLAGPROCESSTYPE',
'RCMAOPFLAGREASONTYPE',
'RCMAOPFLAGS',
'RCPROJECT',
'RCSCENARIO',
'RCSCENARIOCATEGORYSTRUCTURE',
'RCSCENARIOSTRUCTURE',
'RCSTRUCTURECATEGORY',
'RCSTRUCTURECATEGORYTYPE',
'RECTIFIER',
'REDUCER',
'RIGHTOFWAY',
'RISKALGORITHM',
'RISKALGORITHMCHARTCATEGORY',
'RISKALGORITHMCOLUMN',
'RISKALGORITHMCOLUMNCATEGORY',
'RISKALGORITHMCONSTANT',
'RISKALGORITHMMIMPROGRAM',
'RISKALGORITHMMIMPROGRAMCAT',
'RISKALGORITHMMODEL',
'RISKALGORITHMPROGRAMXREF',
'RISKALGORITHMSCORETABLE',
'RISKALGORITHMSCRIPT',
'RISKALGORITHMSERIES',
'RISKALGORITHMSERIESTABLE',
'RISKALGORITHMSERIESVARXREF',
'RISKALGORITHMVARIABLE',
'RISKCALCULATIONCASESTUDY',
'RISKCALCULATIONCASESTUDYPROG',
'RISKCALCULATIONCOLOURING',
'RISKCALCULATIONCORPORATION',
'RISKCALCULATIONCORRECTIONPOS',
'RISKCALCULATIONDATACOLUMN',
'RISKCALCULATIONDATACONDITION',
'RISKCALCULATIONDATASOURCE',
'RISKCALCULATIONDATATABLE',
'RISKCALCULATIONDOMAINCATALOG',
'RISKCALCULATIONGROUP',
'RISKCALCULATIONGROUPING',
'RISKCALCULATIONHCA',
'RISKCALCULATIONHCACATALOG',
'RISKCALCULATIONHCAFOLDER',
'RISKCALCULATIONHCARANKCOLOR',
'RISKCALCULATIONHCAREASONS',
'RISKCALCULATIONHCARTGROUP',
'RISKCALCULATIONHCARTGRREASON',
'RISKCALCULATIONHCASEG',
'RISKCALCULATIONILICALC',
'RISKCALCULATIONILICALCCOND',
'RISKCALCULATIONILISEGMENT',
'RISKCALCULATIONINCIDENTCOND',
'RISKCALCULATIONINCIDENTGROUP',
'RISKCALCULATIONLINELOOP',
'RISKCALCULATIONLISTDOMAIN',
'RISKCALCULATIONMATRIX',
'RISKCALCULATIONMATRIXCELL',
'RISKCALCULATIONMATRIXCOLOR',
'RISKCALCULATIONMATRIXRANGE',
'RISKCALCULATIONMLVCORRECTION',
'RISKCALCULATIONMLVSECTION',
'RISKCALCULATIONMODELSET',
'RISKCALCULATIONMODELSETGROUP',
'RISKCALCULATIONOPERATINGUNIT',
'RISKCALCULATIONREMARK',
'RISKCALCULATIONSECTIONPOS',
'RISKCALCULATIONSEGMENT',
'RISKCALCULATIONSEGMENTFULL',
'RISKCALCULATIONSTATIONSERIES',
'RISKCALCULATIONVIEW',
'RISKRESULTDATA',
'RISKRESULTLINES',
'RISKRESULTMODULE',
'RISKRESULTMODULEGROUP',
'RISKRESULTS',
'SERIESCONNECTION',
'SLEEVE',
'SLEEVEREMARK',
'SOILANALYSIS',
'SOILAREA',
'SOILCONDITION',
'SOILENVIRONMENT',
'SOILLANDUSEAREA',
'SOILRESISTIVITYGRADE',
'SOILRESISTIVITYPIPE',
'STATIONSERIES',
'STATIONSERIESATTRIBUTE',
'STG_ILI',
'STG_ILIBENDSTRAIN',
'STG_ILICRACKANOMALY',
'STG_ILICRSNCALLBOX',
'STG_ILIEVENTTABLE',
'STG_ILIFACILITY',
'STG_ILIFEATURE',
'STG_ILIJOINT',
'STG_ILINONCRSNDFCT',
'STG_ILIRANGE',
'STG_MAINTENANCE',
'STRUCTURE',
'SUPPLEMENTALPERMISSIONS',
'TANK',
'TAP',
'TBLCHKERRCENTERLINE',
'TBLCHKERRINVALIDRECORD',
'TBLCHKERROVERLAP',
'TBLCHKERRSTATIONGAP',
'TEE',
'TESTPOSTPOINT',
'TORNADODENSITYAREA',
'VALVE',
'VALVEREMARK',
'VENT',
'VERSIONHISTORY',
'VERSIONINFO',
'VIRTUALCOLUMN',
'VIRTUALTABLE',
'WATERANALYSIS',
'WATERTESTING',
'WEIGHT');  
  
   -- record    
   r_script s_cursor%ROWTYPE;
BEGIN

  OPEN s_cursor;

  LOOP
    FETCH  s_cursor  INTO r_script;
    EXIT WHEN s_cursor%NOTFOUND;
    
    EXECUTE IMMEDIATE r_script.script;
    --DBMS_OUTPUT.PUT_LINE(r_script.script);

  END LOOP;

  CLOSE s_cursor;
END;

/

declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_CENTERLINEALIGNDEPENDENCY');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_CENTERLINEALIGNDEPENDENCY START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_ILICRACKANOMALY');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_ILICRACKANOMALY START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_ILICRSNCALLBOX');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_ILICRSNCALLBOX START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_ILINONCRSNDFCT');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_ILINONCRSNDFCT START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RCSCENARIOCATSTRUCTURE');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RCSCENARIOCATSTRUCTURE START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKALGORITHMCHARTCATDATA');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKALGORITHMCHARTCATDATA START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKALGORITHMCOLUMNCAT');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKALGORITHMCOLUMNCAT START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCCASESTUDYPROG');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCCASESTUDYPROG START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCCASESTUDYRANGE');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCCASESTUDYRANGE START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCCOLOURINGRANGE');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCCOLOURINGRANGE START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCCORRECTIONPOS');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCCORRECTIONPOS START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCDATACONDITION');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCDATACONDITION START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCDISCHARGESUBSYS');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCDISCHARGESUBSYS START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCDOMAINCATALOG');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCDOMAINCATALOG START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCHCACATALOGITEM');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCHCACATALOGITEM START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCHCARANKCOLOR');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCHCARANKCOLOR START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCHCARTGRREASON');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCHCARTGRREASON START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCINCIDENTCOND');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCINCIDENTCOND START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCINCIDENTGROUP');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCINCIDENTGROUP START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCMLVCORRECTION');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCMLVCORRECTION START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCMODELSETGROUP');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCMODELSETGROUP START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCOPERATINGUNIT');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCOPERATINGUNIT START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCPIPELINESYSTEM');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCPIPELINESYSTEM START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCSEGMENTOVERLAP');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCSEGMENTOVERLAP START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/
declare cnt int;
seqval NUMBER;  
BEGIN
    select count(*) INTO CNT from user_sequences where upper(Sequence_Name) = upper('S_RISKCALCSTATIONSERIES');

    IF CNT = 0 
    THEN
        SELECT nvl(MAX(Id + 1),1) INTO seqval FROM ClassArea;
        execute immediate('CREATE SEQUENCE S_RISKCALCSTATIONSERIES START WITH '||seqval||' INCREMENT BY 1');
    END IF;
END;
/



DECLARE
   -- cursor
  CURSOR s_cursor IS
select 'create or replace TRIGGER TIB_' || Table_Name || ' before insert
on ' || Table_Name || ' for each row
declare
    integrity_error  exception;
    errno            integer;
    errmsg           char(200);
    dummy            integer;
    found            boolean;

begin
    --  Column Id uses sequence S_' || Table_Name || '
    select S_' || Table_Name || '.NEXTVAL INTO :new.Id from dual;

--  Errors handling
exception
    when integrity_error then
       raise_application_error(errno, errmsg);
end;

' as script 
from user_tables Where Table_Name in ('ACTIONITEM',
'ACTIONITEMCOMMENTS',
'ACTIONITEMRANGE',
'ACTIONITEMREVISION',
'ALIGNMENTRANGE',
'CALCOVERLANDLEAKPROFILE',
'COLOCATECLUSTER',
'COLOCATECRACK',
'COLOCATEGIRTHWELD',
'COLOCATENCD',
'EXCAVATIONATTACHMENTFILE',
'EXCAVATIONATTACHMENTURL',
'HCAREASONS',
'ILIERROR',
'MONTECARLOPOE',
'MONTECARLOPOECALC',
'MONTECARLOPOEYEAR',
'RCCATEGORYSTRUCTURE',
'RCCSACLASSCALC',
'RCCSACLASSFLAGS',
'RCDIMPPROMOTE',
'RCDOTCLASSCALC',
'RCDOTCLASSFLAGS',
'RCHCACALC',
'RCHCAFLAGS',
'RCHCAREASONS',
'RCMAOPCALC',
'RCMAOPFLAGS',
'RCPROJECT',
'RCSCENARIO',
'REMEMBEREDLISTDOMAINVALUES',
'RISKRESULTDATA',
'RISKRESULTLINES',
'RISKRESULTMODULE',
'RISKRESULTMODULEGROUP',
'RISKRESULTS',
'SUPPLEMENTALPERMISSIONS',
'VERSIONHISTORY');  
  
   -- record    
   r_script s_cursor%ROWTYPE;
BEGIN

  OPEN s_cursor;

  LOOP
    FETCH  s_cursor  INTO r_script;
    EXIT WHEN s_cursor%NOTFOUND;
    
    EXECUTE IMMEDIATE r_script.script;
    --DBMS_OUTPUT.PUT_LINE(r_script.script);

  END LOOP;

  CLOSE s_cursor;
END;

/


create or replace TRIGGER TIB_RCSCENARIOCATSTRUCTURE before insert
on RCSCENARIOCATEGORYSTRUCTURE for each row
declare
    integrity_error  exception;
    errno            integer;
    errmsg           char(200);
    dummy            integer;
    found            boolean;

begin
    --  Column Id uses sequence S_RCSCENARIOCATSTRUCTURE
    select S_RCSCENARIOCATSTRUCTURE.NEXTVAL INTO :new.Id from dual;

--  Errors handling
exception
    when integrity_error then
       raise_application_error(errno, errmsg);
end;
/

SET SERVEROUTPUT ON
BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 0
        THEN
 
			-- Adding V6 columns.sql
			-- This script is for adding the V6 columns into CoverDepthProfile
            DECLARE CNT INT;
                is_null user_tab_columns.nullable%type;
				sqlStatement varchar(4000);
            BEGIN
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('BeginStationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD BeginStationSeriesId NUMBER(10, 0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('CoverDepthProfile') AND UPPER(UCC.COLUMN_NAME) = UPPER('BeginStationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD CONSTRAINT FK_CoverDepthProfileBeginSSId FOREIGN KEY (BeginStationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('BeginStationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD BeginStationNum NUMBER(13, 5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('EndStationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD EndStationSeriesId NUMBER(10, 0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('CoverDepthProfile') AND UPPER(UCC.COLUMN_NAME) = UPPER('EndStationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD CONSTRAINT FK_CoverDepthProfileEndSSId FOREIGN KEY (EndStationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('EndStationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD EndStationNum NUMBER(13, 5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD CreatedUser varchar2(45) default USER NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD CreatedDate DATE default SysDATE NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('CoverDepthProfile') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE CoverDepthProfile ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('STATIONNUM');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE COVERDEPTHPROFILE MODIFY (STATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE STRUCTURE MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if;    
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistBusinessDistrict') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistBusinessDistrict ADD CreatedUser Varchar2(45) DEFAULT USER NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistBusinessDistrict') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistBusinessDistrict ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistBusinessDistrict') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistBusinessDistrict ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistBusinessDistrict')
                and upper(column_name) = upper('BeginStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTBUSINESSDISTRICT MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistBusinessDistrict')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTBUSINESSDISTRICT MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistBusinessDistrict')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE DISTBUSINESSDISTRICT MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if;   
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistInsideMeter') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistInsideMeter ADD CreatedUser Varchar2(45) DEFAULT USER NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistInsideMeter') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistInsideMeter ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistInsideMeter') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistInsideMeter ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistInsideMeter')
                and upper(column_name) = upper('BeginStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTINSIDEMETER MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistInsideMeter')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTINSIDEMETER MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DistInsideMeter')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE DISTINSIDEMETER MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if;   
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistServiceHeadSuscept') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistServiceHeadSuscept ADD CreatedUser Varchar2(45) DEFAULT USER NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistServiceHeadSuscept') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistServiceHeadSuscept ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('DistServiceHeadSuscept') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE DistServiceHeadSuscept ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DISTSERVICEHEADSUSCEPT')
                and upper(column_name) = upper('BeginStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTSERVICEHEADSUSCEPT MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DISTSERVICEHEADSUSCEPT')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE DISTSERVICEHEADSUSCEPT MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('DISTSERVICEHEADSUSCEPT')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE DISTSERVICEHEADSUSCEPT MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if;      
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE IncidentHistory ADD CreatedUser Varchar2(45) DEFAULT USER NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE IncidentHistory ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('IncidentHistory') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE IncidentHistory ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('INCIDENTHISTORY')
                and upper(column_name) = upper('BeginStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE INCIDENTHISTORY MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('INCIDENTHISTORY')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE INCIDENTHISTORY MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('INCIDENTHISTORY')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE INCIDENTHISTORY MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if;      
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Pressure') and upper(Column_Name) = upper('CreatedUser');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE Pressure ADD CreatedUser Varchar2(45) DEFAULT USER NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Pressure') and upper(Column_Name) = upper('CreatedDate');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE Pressure ADD CreatedDate DATE DEFAULT SYSDATE NOT NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Pressure') and upper(Column_Name) = upper('SourceId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE Pressure ADD SourceId Varchar2(50) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
                select nullable into is_null 
                from user_tab_columns
                where upper(table_name) = upper('PRESSURE')
                and upper(column_name) = upper('BeginStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE PRESSURE MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NULL)';
					execute immediate sqlStatement;
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)'
                end if;
                
                select nullable into is_null 
                from user_tab_columns
                where upper(table_name) = upper('PRESSURE')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE PRESSURE MODIFY (ENDSTATIONNUM NUMBER(13, 5) NULL)';
					execute immediate sqlStatement;
                    EXECUTE IMMEDIATE 'ALTER TABLE PRESSURE MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('PRESSURE')
                and upper(column_name) = upper('EFFECTIVESTARTDATE');
                
                if is_null = 'N' 
                then
					sqlStatement := 'ALTER TABLE PRESSURE MODIFY (EFFECTIVESTARTDATE DATE NULL)';
					execute immediate sqlStatement;
                end if; 
                
            END;
            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            COMMIT;
            
        END IF;	
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
        END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 1
        THEN
			UPDATE CoverDepthProfile
			SET BeginStationSeriesId = StationSeriesId, EndStationSeriesId = StationSeriesId,
			BeginStationNum = StationNum, EndStationNum = StationNum;

            DECLARE CNT INT;
                    is_null user_tab_columns.nullable%type;
					sqlStatement varchar(4000);
            BEGIN

                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('BEGINSTATIONSERIESID');

                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE COVERDEPTHPROFILE MODIFY (BEGINSTATIONSERIESID NUMBER(10, 0) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('ENDSTATIONSERIESID');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE COVERDEPTHPROFILE MODIFY (ENDSTATIONSERIESID NUMBER(10, 0) NOT NULL)';
					execute immediate sqlStatement;
                end if;

                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('BEGINSTATIONNUM');

                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE COVERDEPTHPROFILE MODIFY (BEGINSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;
                
                select nullable into is_null from user_tab_columns
                where upper(table_name) = upper('COVERDEPTHPROFILE')
                and upper(column_name) = upper('EndStationNum');
                
                if is_null = 'Y' 
                then
					sqlStatement := 'ALTER TABLE COVERDEPTHPROFILE MODIFY (ENDSTATIONNUM NUMBER(13, 5) NOT NULL)';
					execute immediate sqlStatement;
                end if;                

                -- CLIENT_ADD_ILIJointMeasuredWallThickness.sql
                -- Add the new ILIJointMeasuredWallThickness field to the InlineInspection and Stg_ILI Joint tables
    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('InlineInspectionJoint') and upper(Column_Name) = upper('ILIJointMeasuredWallThickness');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE INLINEINSPECTIONJOINT ADD ILIJOINTMEASUREDWALLTHICKNESS Number(9,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                    
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('STG_ILIJOINT') and upper(Column_Name) = upper('ILIJOINTMEASUREDWALLTHICKNESS');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE STG_ILIJOINT ADD ILIJOINTMEASUREDWALLTHICKNESS Number(9,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
            END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);
	sqlStatement varchar(4000);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 2
        THEN
            -- Adding_CasingReading_Table.sql
            
            DECLARE CNT INT;
            sqlStatement varchar(4000);
            
            BEGIN
                SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('CasingReading');
  
                IF CNT = 0
                THEN
                
                sqlStatement := 'CREATE TABLE CasingReading
                                (
                                            Id number(10,0) NOT NULL,
                                            CasingId number(10,0) NOT NULL,
                                            CasingReadingDate date NOT NULL,
                                            USPipeToSoilOn number(5,0) NULL,
                                            USPipeToSoilOff number(5,0) NULL,
                                            USCasingToSoilOn number(5,0) NULL,
                                            USCasingToSoilOff number(5,0) NULL,
                                            DSPipeToSoilOn number(5,0) NULL,
                                            DSPipeToSoilOff number(5,0) NULL,
                                            DSCasingToSoilOn number(5,0) NULL,
                                            DSCasingToSoilOff number(5,0) NULL,
                                            CasingReadingComment varchar2(255) NULL,
                                            LastModByUserId varchar2(45) DEFAULT USER NOT NULL,
                                            LastModDateTime date DEFAULT Sysdate NOT NULL,
                                            SourceId varchar2(50) NULL,
                                            CreatedDate date DEFAULT Sysdate NOT NULL,
                                            CreatedUser varchar2(45) DEFAULT USER NOT NULL,
                                            CONSTRAINT PK_CasingReading PRIMARY KEY(CasingId, CasingReadingDate)
                                        )';
                
                    EXECUTE IMMEDIATE sqlStatement;

					sqlStatement := 'ALTER TABLE CASINGREADING ADD CONSTRAINT FK_CASINGREADINGCASINGID FOREIGN KEY (CASINGID) REFERENCES CASING(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                    
					sqlStatement := 'CREATE OR REPLACE TRIGGER TU_CASINGREADING BEFORE UPDATE
                                        ON CASINGREADING FOR EACH ROW
                                        BEGIN
                                            :NEW.LASTMODBYUSERID := USER;
                                            :NEW.LASTMODDATETIME := SYSDATE;
                                        END;';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 3
        THEN
            -- CLIENT_ColocateTables_AddStationingColumns_BL27743.sql
            
            DECLARE CNT INT;
            sqlStatement varchar(4000);
            
            BEGIN
                -- This scripts adds stationing columns, including respective foreign keys, to tables ColocateSite, ColocateCluster, ColocateCrack, ColocateGirthWeld, ColocateNCD

                -- Changes to ColocateSite table

                -- Add BeginStationSeriesId column to ColocateSite table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateSite') and upper(Column_Name) = upper('BeginStationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATESITE ADD BEGINSTATIONSERIESID Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Add BeginStationNum column to ColocateSite table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateSite') and upper(Column_Name) = upper('BeginStationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATESITE ADD BEGINSTATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add EndStationSeriesId column to ColocateSite table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateSite') and upper(Column_Name) = upper('EndStationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATESITE ADD ENDSTATIONSERIESID Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add EndStationNum column to ColocateSite table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateSite') and upper(Column_Name) = upper('EndStationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATESITE ADD ENDSTATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add foreign key for BeginStationSeriesId
                
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateSite') AND UPPER(UCC.COLUMN_NAME) = UPPER('BeginStationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE ColocateSite ADD CONSTRAINT FK_ColocateSiteBeginSSId FOREIGN KEY (BeginStationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Add foreign key for EndStationSeriesId
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateSite') AND UPPER(UCC.COLUMN_NAME) = UPPER('EndStationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE ColocateSite ADD CONSTRAINT FK_ColocateSiteEndSSId FOREIGN KEY (EndStationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Changes to ColocateCluster table

                -- Add StationSeriesId column to ColocateCluster table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateCluster') and upper(Column_Name) = upper('StationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATECLUSTER ADD STATIONSERIESID Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Add StationNum column to ColocateCluster table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateCluster') and upper(Column_Name) = upper('StationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATECLUSTER ADD STATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Add foreign key for StationSeriesId
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateCluster') AND UPPER(UCC.COLUMN_NAME) = UPPER('StationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE ColocateCluster ADD CONSTRAINT FK_ColocateClusterStnSerId FOREIGN KEY (StationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Changes to ColocateCrack table

                -- Add StationSeriesId column to ColocateCrack table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateCrack') and upper(Column_Name) = upper('StationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATECRACK ADD STATIONSERIESID Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add StationNum column to ColocateCrack table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateCrack') and upper(Column_Name) = upper('StationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATECRACK ADD STATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add foreign key for StationSeriesId
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateCrack') AND UPPER(UCC.COLUMN_NAME) = UPPER('StationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATECRACK ADD CONSTRAINT FK_ColocateCrackStnSerId FOREIGN KEY (StationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Changes to ColocateGirthWeld table

                -- Add StationSeriesId column to ColocateGirthWeld table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateGirthWeld') and upper(Column_Name) = upper('StationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATEGIRTHWELD ADD StationSeriesId Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add StationNum column to ColocateGirthWeld table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateGirthWeld') and upper(Column_Name) = upper('StationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATEGIRTHWELD ADD STATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add foreign key for StationSeriesId
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateGirthWeld') AND UPPER(UCC.COLUMN_NAME) = UPPER('StationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATEGIRTHWELD ADD CONSTRAINT FK_ColocateGWStnSerId FOREIGN KEY (StationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Changes to ColocateNCD table

                -- Add StationSeriesId column to ColocateNCD table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateNCD') and upper(Column_Name) = upper('StationSeriesId');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATENCD ADD StationSeriesId Number(10,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;

                -- Add StationNum column to ColocateNCD table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ColocateNCD') and upper(Column_Name) = upper('StationNum');
    
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATENCD ADD STATIONNUM Number(13,5) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
                
                -- Add foreign key for StationSeriesId
                SELECT COUNT(*) INTO CNT FROM USER_CONS_COLUMNS UCC 
                INNER JOIN USER_CONSTRAINTS UC ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
                WHERE UPPER(UC.CONSTRAINT_TYPE) = UPPER('R') AND UPPER(UCC.TABLE_NAME) = UPPER('ColocateNCD') AND UPPER(UCC.COLUMN_NAME) = UPPER('StationSeriesId');
                   
                IF CNT = 0 
                THEN
					sqlStatement := 'ALTER TABLE COLOCATENCD ADD CONSTRAINT FK_ColocateNCDStnSerId FOREIGN KEY (StationSeriesId) REFERENCES StationSeries(ID)';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
            END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 4;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);
    dcId Number(7,0);
    
    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 4
        THEN
            -- CLIENT_PMMTypeColumn.sql
            --- BL item: 30747
            
            Insert into DomainCatalog (Id, DomainDescr)
            select COALESCE(max(Id) + 1, 1), 'PMM Type' from DomainCatalog where Not Exists (Select * From Domaincatalog where DomainDescr = 'PMM Type');
            
            SELECT Id INTO dcId FROM DOMAINCATALOG WHERE DomainDescr = 'PMM Type';
            
            Insert into ListDomain (Id, DomainCatalogId, Code, Descr)
            select Coalesce(max(id) + 1, 1), dcId, 'Monitoring', 'Monitoring' From ListDomain Where Not Exists (Select * from ListDomain Where DomainCatalogId = dcId and Code = 'Monitoring');
            
            Insert into ListDomain (Id, DomainCatalogId, Code, Descr)
            select Coalesce(max(id) + 1, 1), dcId, 'Mitigation', 'Mitigation' From ListDomain Where Not Exists (Select * from ListDomain Where DomainCatalogId = dcId and Code = 'Mitigation');

            Insert into ListDomain (Id, DomainCatalogId, Code, Descr)
            select Coalesce(max(id) + 1, 1), dcId, 'Prevention', 'Prevention' From ListDomain Where Not Exists (Select * from ListDomain Where DomainCatalogId = dcId and Code = 'Prevention');
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 5;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630003 AND dbVersionCheckPoint = 5
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 01
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630101', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 01';
            
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
        IF dbVersion = 630101 AND dbVersionCheckPoint = 0
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 02
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630102', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 02';
            
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
        IF dbVersion = 630102 AND dbVersionCheckPoint = 0
        THEN
			-- Add JointAlignment.PipesegmentId index.sql
			declare cnt int;
				sqlstatement varchar(4000);
			BEGIN
				select Count(*) into CNT from user_indexes where upper(index_name) = upper('IX_JointAlignment_PipeSegId');
    
				IF CNT = 0
				THEN
					sqlstatement := 'CREATE INDEX IX_JOINTALIGNMENT_PIPESEGID ON JOINTALIGNMENT (PIPESEGMENTID)';
					execute immediate sqlstatement;
				END IF;
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630102 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 03
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630103', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 03';
            
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
        IF dbVersion = 630103 AND dbVersionCheckPoint = 0
        THEN
			-- Add JointAlignment.PipesegmentId index.sql
			declare CNT int;
				sqlstatement varchar(4000);
			BEGIN
                -- Add StationNum column to ColocateNCD table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('Valve') and upper(Column_Name) = upper('ValveConditionDomainID');
    
                IF CNT = 0 
                THEN
					sqlstatement := 'ALTER TABLE VALVE ADD VALVECONDITIONDOMAINID Number(7,0) NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                || ', checkpoint ' || dbVersionCheckPoint);
            DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630103 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 04
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630104', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 04';
            
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
        IF dbVersion = 630104 AND dbVersionCheckPoint = 0
        THEN
			-- ScriptTracker.sql
			declare CNT int;
				sqlstatement varchar(4000);
			BEGIN
                SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE UPPER(TABLE_NAME) = UPPER('ScriptTracker');
  
                IF CNT = 0
                THEN
                
                    sqlStatement := 'CREATE TABLE ScriptTracker
                    (Id number(10,0),
                    ScriptName varchar2(100),
                    ScriptDetails varchar2(255),
                    Reason varchar2(255),
                    ClientSpecific varchar2(10), 
                    ScriptedByUser varchar2 (45),
                    ScriptCreateDate date,
                    ScriptDeliveredDate date,
                    Version varchar2(20),
                    CreatedDate date DEFAULT SYSDATE NOT NULL,
                    CreatedUser varchar2(45) DEFAULT USER NOT NULL,
                    LastModByUserId varchar2(45) DEFAULT USER NOT NULL,
                    LastModDateTime date DEFAULT SYSDATE NOT NULL,
                    CONSTRAINT PK_ScriptTracker PRIMARY KEY(Id)
                    )';
                
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630104 AND dbVersionCheckPoint = 1
        THEN
			-- ScriptTracker.sql
			declare CNT int;
				sqlstatement varchar(4000);
			BEGIN
                sqlStatement := 'CREATE OR REPLACE TRIGGER TU_SCRIPTTRACKER BEFORE UPDATE
                                    ON CASINGREADING FOR EACH ROW
                                    BEGIN
                                        :NEW.LASTMODBYUSERID := USER;
                                        :NEW.LASTMODDATETIME := SYSDATE;
                                    END;';
                EXECUTE IMMEDIATE sqlStatement;
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 2;
            
        END IF;	
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630104 AND dbVersionCheckPoint = 2
        THEN
			-- ScriptTracker.sql
			declare CNT int;
				sqlstatement varchar(4000);
			BEGIN
                SELECT COUNT(*) INTO CNT FROM USER_SEQUENCES WHERE UPPER(SEQUENCE_NAME) = UPPER('S_SCRIPTTRACKER');
                
                IF CNT = 0
                THEN
                    sqlStatement := 'CREATE SEQUENCE S_SCRIPTTRACKER';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
    
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 3;
            
        END IF;	
       EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/


BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630104 AND dbVersionCheckPoint = 3
        THEN
			-- ScriptTracker.sql
			declare sqlstatement varchar(4000);
			BEGIN
                sqlStatement := 'CREATE OR REPLACE TRIGGER TIB_SCRIPTTRACKER BEFORE INSERT
                                    ON SCRIPTTRACKER FOR EACH ROW
                                    DECLARE
                                        INTEGRITY_ERROR  EXCEPTION;
                                        ERRNO            INTEGER;
                                        ERRMSG           CHAR(200);
                                        DUMMY            INTEGER;
                                        FOUND            BOOLEAN;
                                    
                                    BEGIN
                                        --  COLUMN ID USES SEQUENCE S_SCRIPTTRACKER
                                        SELECT S_SCRIPTTRACKER.NEXTVAL INTO :NEW.ID FROM DUAL;
                                    
                                    --  ERRORS HANDLING
                                    EXCEPTION
                                        WHEN INTEGRITY_ERROR THEN
                                           RAISE_APPLICATION_ERROR(ERRNO, ERRMSG);
                                    END;';
                EXECUTE IMMEDIATE sqlStatement;    
			END;

            UPDATE VersionInfo SET DBVersionCheckPoint = 4;
            
        END IF;	
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630104 AND dbVersionCheckPoint = 4
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 05
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630105', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 05';
            
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
        IF dbVersion = 630105 AND dbVersionCheckPoint = 0
        THEN
			declare CNT int;
				sqlstatement varchar(4000);
			BEGIN
                -- Add StationNum column to ColocateNCD table
                select count(*) INTO CNT from user_tab_columns
                where upper(Table_Name) = upper('ActionItem') and upper(Column_Name) = upper('ProjectRunDate');
    
                IF CNT = 0 
                THEN
					sqlstatement := 'ALTER TABLE ACTIONITEM ADD PROJECTRUNDATE DATE NULL';
                    EXECUTE IMMEDIATE sqlStatement;
                END IF;
			END;
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 1;
            
        END IF;	
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                                    || ', checkpoint ' || dbVersionCheckPoint);
                DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
    END;
END;
/

BEGIN 
    declare dbVersion number(10);
    dbVersionCheckPoint number(5);

    BEGIN
        SELECT DBVersion into dbVersion FROM VersionInfo vi;
        SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
        IF dbVersion = 630105 AND dbVersionCheckPoint = 1
        THEN
			 /********************************************************************************************************/
			-- Update VersionInfo Application Version 6.3 Release 1 Updates 06
			/********************************************************************************************************/
			UPDATE VersionInfo
			SET DBVersion = '630106', DBVersionComment = 'Service Pack DDL 6.3, Rel. 1, Hotfixes Updates 06';
            
            UPDATE VersionInfo SET DBVersionCheckPoint = 0;
            
        END IF;	
        EXCEPTION
            when others then
            ROLLBACK;
    END;
END;
/
