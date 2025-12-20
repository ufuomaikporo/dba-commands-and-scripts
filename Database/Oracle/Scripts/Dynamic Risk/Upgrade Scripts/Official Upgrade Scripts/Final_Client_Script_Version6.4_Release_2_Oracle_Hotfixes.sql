ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE 
    CNT INT;
    e_Wrong_Database EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences  
    WHERE ParameterName = 'DatabaseType' AND Value = 'Stage';
    
    IF CNT = 0 THEN
        RAISE e_Wrong_Database;
    END IF;
    
EXCEPTION
    WHEN e_Wrong_Database THEN 
        DBMS_OUTPUT.PUT_LINE('The target database is not Stage database for applying this upgrade script.');
END;
/

DECLARE 
    CNT INT;
    sql_stmt VARCHAR2(20000);
    dbVersion number(10);
    dbVersionCheckPoint number(5);

    CURSOR AlterColumn_Cursor IS
    SELECT 'ALTER TABLE ' || table_name || ' MODIFY SourceId VARCHAR2(50) NULL'  AS cmd
    FROM user_tab_columns 
    WHERE column_name = 'SourceId' AND nullable = 'N' AND table_name NOT LIKE 'LOAD%';

BEGIN
    SELECT dbVersion, dbVersionCheckPoint
    INTO dbversion, dbVersionCheckPoint
    FROM VersionInfo;

    -- Change SourceId to nullable
    IF dbVersion = 640205 AND dbVersionCheckPoint = 0 THEN
        FOR i IN AlterColumn_Cursor LOOP
            EXECUTE IMMEDIATE i.cmd;
        END LOOP;

        UPDATE VersionInfo SET dbVersionCheckPoint = 1;
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640205 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 06 hotfixes
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640206', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 06 hotfixes';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0;
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640206 AND dbVersionCheckPoint = 0
    THEN
        SELECT COUNT(*) INTO CNT
        FROM user_constraints
        WHERE constraint_name = 'FK_FloodArea_FloodAreaLD';

        IF CNT = 0 THEN

            sql_stmt := 'ALTER TABLE FloodArea ADD CONSTRAINT FK_FloodArea_FloodAreaLD FOREIGN KEY(FloodAreaLD)
			REFERENCES ListDomain (Id)';

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
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
    sql_stmt  VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640206 AND dbVersionCheckPoint = 1
    THEN
        -- Overlays_ListDomain.sql

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_FrostAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_FrostAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_FrostAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := '
        BEGIN
            DELETE FROM Temp_FrostAreaRange;

            INSERT ALL
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''2.032-2.286m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''0-0.127m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''0.127-0.254m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES(''1.778-2.032m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''1.27-1.524m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''2.54--99.999m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''1.016-1.27m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''0.254-0.508m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''1.524-1.778m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''0.762-1.016m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''0.508-0.762m'')
            INTO Temp_FrostAreaRange (ListDomain) VALUES (''2.286-2.54m'')
            SELECT 1 FROM DUAL;

            COMMIT;
        
        END;';

        EXECUTE IMMEDIATE sql_stmt;    

        COMMIT;
    
        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FROST AREA RANGE'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'FrostArea', 'FrostAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'FROST AREA RANGE'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FrostArea' AND ColumnName = 'FrostAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''FrostArea'' AND ColumnName = ''FrostAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_FrostAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''FrostArea'' AND ColumnName = ''FrostAreaRangeLD''))
        ';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_LandUseType';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_LandUseType PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_LandUseType (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_LandUseType (ListDomain) VALUES (''Wetlands'')
		INTO Temp_LandUseType (ListDomain) VALUES (''Agricultural'')
		INTO Temp_LandUseType (ListDomain) VALUES (''Low Density Residential'')
		INTO Temp_LandUseType (ListDomain) VALUES (''Commercial/Industrial'')
		INTO Temp_LandUseType (ListDomain) VALUES (''High Density Residential'')
		INTO Temp_LandUseType (ListDomain) VALUES (''Remote'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Land Use Type'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Land Use Type');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'LandUse', 'LandUseDomainId'
        FROM DomainCatalog 
        WHERE DomainDescr = 'Land Use Type'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LandUse' AND ColumnName = 'LandUseDomainId');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
               (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''LandUse'' AND ColumnName = ''LandUseDomainId'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_LandUseType f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''LandUse'' AND ColumnName = ''LandUseDomainId''))
        ';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_SoilType';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_SoilType PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_SoilType (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_SoilType (ListDomain)	VALUES (''High Clay Content'')
        INTO Temp_SoilType (ListDomain)	VALUES (''Other'')
        INTO Temp_SoilType (ListDomain)	VALUES (''Rocky Soil'')
        INTO Temp_SoilType (ListDomain)	VALUES (''Sandy Loam'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Soil Type'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Type');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'SoilArea', 'SoilTypeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'Soil Type'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'SoilArea' AND ColumnName = 'SoilTypeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
               (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''SoilArea'' AND ColumnName = ''SoilTypeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_SoilType f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''SoilArea'' AND ColumnName = ''SoilTypeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_FaultAreaSlipRate';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_FaultAreaSlipRate PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_FaultAreaSlipRate (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''< 0.2 mm/year'')
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''<0.2 mm/year'')
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''0.2 - 1 mm/year'')
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''>5 mm/year'')
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''unknown'')
        INTO Temp_FaultAreaSlipRate (ListDomain) VALUES (''1-5 mm/year'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA DIP DIRECTION'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'FaultArea', 'FaultAreaSlipRateLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'FAULT AREA DIP DIRECTION'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaSlipRateLD');
        
        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaSlipRateLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_FaultAreaSlipRate f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaSlipRateLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_FaultAreaSlipSense';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_FaultAreaSlipSense PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_FaultAreaSlipSense (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_FaultAreaSlipSense (ListDomain) VALUES (''Normal'')
		INTO Temp_FaultAreaSlipSense (ListDomain) VALUES (''unknown'')
		INTO Temp_FaultAreaSlipSense (ListDomain) VALUES (''Thrust'')
		INTO Temp_FaultAreaSlipSense (ListDomain) VALUES (''Reverse'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA SLIP SENSE'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA SLIP SENSE');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'FaultArea', 'FaultAreaSlipSenseLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'FAULT AREA SLIP SENSE'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaSlipSenseLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaSlipSenseLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_FaultAreaSlipSense f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaSlipSenseLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_FaultAreaDipDirection';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_FaultAreaDipDirection PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_FaultAreaDipDirection (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_FaultAreaDipDirection (ListDomain) VALUES (''North'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''Vertical'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES (''East'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES (''Northeast'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES (''Center'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''Southwest'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''South'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''Unspecified'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''Northwest'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''Southeast'')
		INTO Temp_FaultAreaDipDirection (ListDomain) VALUES(''West'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'FAULT AREA DIP DIRECTION'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'FaultArea', 'FaultAreaDipDirectionLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'FAULT AREA DIP DIRECTION'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FaultArea' AND ColumnName = 'FaultAreaDipDirectionLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaDipDirectionLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_FaultAreaDipDirection f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''FaultArea'' AND ColumnName = ''FaultAreaDipDirectionLD''))
        ';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_TornadoDensityRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_TornadoDensityRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_TornadoDensityRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_TornadoDensityRange (ListDomain) VALUES (''0.500001 - 0.9999'')
		INTO Temp_TornadoDensityRange (ListDomain) VALUES (''0 - 0.01'')
		INTO Temp_TornadoDensityRange (ListDomain) VALUES (''0.010001 - 0.500'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Tornado Area Ranking'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tornado Area Ranking');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'TornadoDensityArea', 'TornadoDensityRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'Tornado Area Ranking'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'TornadoDensityArea' AND ColumnName = 'TornadoDensityRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''TornadoDensityArea'' AND ColumnName = ''TornadoDensityRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_TornadoDensityRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''TornadoDensityArea'' AND ColumnName = ''TornadoDensityRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_HurricaneAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_HurricaneAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_HurricaneAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_HurricaneAreaRange (ListDomain) VALUES (''0-84'')
		INTO Temp_HurricaneAreaRange (ListDomain) VALUES(''85-100'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Hurricane Ranking'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'HurricaneArea', 'HurricaneAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'OF Hurricane Ranking'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'HurricaneArea' AND ColumnName = 'HurricaneAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''HurricaneArea'' AND ColumnName = ''HurricaneAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_HurricaneAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''HurricaneArea'' AND ColumnName = ''HurricaneAreaRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_SoilLandUse';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_SoilLandUse PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_SoilLandUse (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_SoilLandUse (ListDomain) VALUES (''Agricultural'')
		INTO Temp_SoilLandUse (ListDomain) VALUES(''Salt/Tidal Flats'')
		INTO Temp_SoilLandUse (ListDomain) VALUES(''Others'')
		INTO Temp_SoilLandUse (ListDomain) VALUES(''Wetlands'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Soil Land Use'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Land Use');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'SoilLandUseArea', 'SoilLandUseLd'
        FROM DomainCatalog 
        WHERE DomainDescr = 'Soil Land Use'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'SoilLandUseArea' AND ColumnName = 'SoilLandUseLd');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''SoilLandUseArea'' AND ColumnName = ''SoilLandUseLd'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_SoilLandUse f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''SoilLandUseArea'' AND ColumnName = ''SoilLandUseLd''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_LightningStrikeAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_LightningStrikeAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_LightningStrikeAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES (''3-4'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''7-8'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''4-5'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''8-9'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''5-6'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''2-3'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''0-1'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''1-2'')
		INTO Temp_LightningStrikeAreaRange (ListDomain) VALUES(''6-7'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'Lightning Strike Density'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Lightning Strike Density');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'LightningStrikeArea', 'LightningStrikeAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'Lightning Strike Density'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LightningStrikeArea' 
                        AND ColumnName = 'LightningStrikeAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''LightningStrikeArea'' AND ColumnName = ''LightningStrikeAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_LightningStrikeAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''LightningStrikeArea'' AND ColumnName = ''LightningStrikeAreaRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_FloodAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_FloodAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_FloodAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_FloodAreaRange (ListDomain) VALUES (''85-100'')
		INTO Temp_FloodAreaRange (ListDomain) VALUES (''70-84'')
		INTO Temp_FloodAreaRange (ListDomain) VALUES (''0-69'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Flood Ranking'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'FloodArea', 'FloodAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'OF Flood Ranking'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'FloodArea' AND ColumnName = 'FloodAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''FloodArea'' AND ColumnName = ''FloodAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_FloodAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''FloodArea'' AND ColumnName = ''FloodAreaRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_LandSlideAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_LandSlideAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_LandSlideAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_LandSlideAreaRange (ListDomain) VALUES (''85-100'')
		INTO Temp_LandSlideAreaRange (ListDomain) VALUES (''70-84'')
		INTO Temp_LandSlideAreaRange (ListDomain) VALUES (''0-69'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'LANDSLIDE AREA RANGE'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'LANDSLIDE AREA RANGE');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'LandSlideArea', 'LandSlideAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'LANDSLIDE AREA RANGE'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'LandSlideArea' AND ColumnName = 'LandSlideAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''LandSlideArea'' AND ColumnName = ''LandSlideAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_LandSlideAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''LandSlideArea'' AND ColumnName = ''LandSlideAreaRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'Temp_EarthQuakeAreaRange';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_EarthQuakeAreaRange PURGE';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_EarthQuakeAreaRange (ListDomain VARCHAR2(40))';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'INSERT ALL
        INTO Temp_EarthQuakeAreaRange (ListDomain) VALUES (''85-100'')
		INTO Temp_EarthQuakeAreaRange (ListDomain) VALUES (''70-84'')
		INTO Temp_EarthQuakeAreaRange (ListDomain) VALUES (''0-69'')
        SELECT 1 FROM DUAL';

        EXECUTE IMMEDIATE sql_stmt;

        INSERT INTO DomainCatalog (Id, DomainDescr)
        SELECT DISTINCT (SELECT MAX(Id) + 1 FROM DomainCatalog) ,  'OF Seismic Ranking'
        FROM DomainCatalog
        WHERE NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking');

        INSERT INTO DomainCatalogColXRef(DomainCatalogId, TableName, ColumnName)
        SELECT Id, 'EarthQuakeArea', 'EarthQuakeAreaRangeLD'
        FROM DomainCatalog 
        WHERE DomainDescr = 'OF Seismic Ranking'
        AND NOT EXISTS (SELECT 1 FROM DomainCatalogColXRef WHERE TableName = 'EarthQuakeArea' AND ColumnName = 'EarthQuakeAreaRangeLD');

        sql_stmt := 'INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1 FROM DUAL)) + (SELECT MAX(Id) FROM ListDomain),
                (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                WHERE TableName = ''EarthQuakeArea'' AND ColumnName = ''EarthQuakeAreaRangeLD'') AS DomainCatalogId,
                f.ListDomain,
                f.ListDomain
        FROM Temp_EarthQuakeAreaRange f
        WHERE NOT EXISTS (SELECT * FROM ListDomain ld
                      WHERE ld.code = f.ListDomain
                      AND ld.DomainCatalogId = (SELECT DomainCatalogId FROM DomainCatalogColXRef 
                                                WHERE TableName = ''EarthQuakeArea'' AND ColumnName = ''EarthQuakeAreaRangeLD''))';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;
        
        UPDATE VersionInfo SET DBVersionCheckPoint = 2;
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
     
    IF dbVersion = 640206 AND dbVersionCheckPoint = 2
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 07 hotfixes
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640207', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 07 hotfixes';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0;
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

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
    sql_stmt VARCHAR2(20000);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640207 AND dbVersionCheckPoint = 0
    THEN
        -- StageDB_FixColumnType_Bug50293.sql
        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = 'Stg_ILIFacility'
        AND column_name = 'ILIFacNumber'
        AND data_type LIKE 'varchar%'
        AND data_length = 30;

        IF CNT = 0 THEN
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'temp_Stg_ILIFacility';

            IF CNT <> 0 THEN
                sql_stmt := 'DROP TABLE temp_Stg_ILIFacility PURGE';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            sql_stmt := 'CREATE TABLE temp_Stg_ILIFacility AS 
                          SELECT  ID,
                                EFFECTIVESTARTDATE,
                                EFFECTIVEENDDATE,
                                STG_ILIID,
                                STG_ILIRANGEID,
                                ILIFACTYPEDOMAINID,
                                ILIFACODOMETER,
                                ILIFACGIRTHWELDNUM,
                                ILIFACDISTANCEFROMGIRTHWELD,
                                ILIFACORIENTATION,
                                CAST(ILIFACNUMBER AS VARCHAR2(30)) AS ILIFACNUMBER,
                                ILIFACLATITUDE,
                                ILIFACLONGITUDE,
                                ILIFTOOLSPEED,
                                ILIFACDESCR,
                                ILIFACREMARK,
                                ILIFACX,
                                ILIFACY,
                                ILIFACZ,
                                STATIONSERIESID,
                                STATIONNUM,
                                LASTMODBYUSERID,
                                LASTMODDATETIME,
                                MATCHED,
                                CALCLATITUDE,
                                CALCLONGITUDE,
                                OFFSET,
                                REVERSEDODOMETER
                        FROM Stg_ILIFacility';

            EXECUTE IMMEDIATE sql_stmt;

            DELETE FROM Stg_ILIFacility;

            sql_stmt := 'ALTER TABLE Stg_ILIFacility MODIFY ILIFacNumber VARCHAR2(30)';

            EXECUTE IMMEDIATE sql_stmt;

            sql_stmt := 'INSERT INTO Stg_ILIFacility (ID,
                                EFFECTIVESTARTDATE,
                                EFFECTIVEENDDATE,
                                STG_ILIID,
                                STG_ILIRANGEID,
                                ILIFACTYPEDOMAINID,
                                ILIFACODOMETER,
                                ILIFACGIRTHWELDNUM,
                                ILIFACDISTANCEFROMGIRTHWELD,
                                ILIFACORIENTATION,
                                ILIFACNUMBER,
                                ILIFACLATITUDE,
                                ILIFACLONGITUDE,
                                ILIFTOOLSPEED,
                                ILIFACDESCR,
                                ILIFACREMARK,
                                ILIFACX,
                                ILIFACY,
                                ILIFACZ,
                                STATIONSERIESID,
                                STATIONNUM,
                                LASTMODBYUSERID,
                                LASTMODDATETIME,
                                MATCHED,
                                CALCLATITUDE,
                                CALCLONGITUDE,
                                OFFSET,
                                REVERSEDODOMETER)
                        SELECT * FROM temp_Stg_ILIFacility';

            EXECUTE IMMEDIATE sql_stmt;

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'temp_Stg_ILIFacility';

            IF CNT <> 0 THEN
                EXECUTE IMMEDIATE 'DROP TABLE temp_Stg_ILIFacility PURGE';
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
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640207 AND dbVersionCheckPoint = 1
    THEN
        /********************************************************************************************************/
        -- Update VersionInfo Application Version 6.4 Release 2 Updates 08 hotfixes
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640208', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 08 hotfixes';

        UPDATE VersionInfo SET DBVersionCheckPoint = 0;
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