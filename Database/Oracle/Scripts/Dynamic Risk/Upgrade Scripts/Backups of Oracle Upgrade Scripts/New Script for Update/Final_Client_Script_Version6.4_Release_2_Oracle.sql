SET SERVEROUTPUT ON

DECLARE
	CNT INT;
	e_invalid_database EXCEPTION;
    stmt VARCHAR2(600);
BEGIN	

    SELECT COUNT(*) INTO CNT
    FROM all_tables
    WHERE UPPER(table_name) = UPPER('SystemPreferences');

    IF (CNT <> 0)
    THEN

        stmt := q'[SELECT COUNT(*) 
        FROM SystemPreferences sp 
        WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage']';

        EXECUTE IMMEDIATE stmt
        INTO CNT;

        IF (CNT = 0)
        THEN
            RAISE e_invalid_database;
        END IF;
    END IF;
EXCEPTION
	WHEN e_invalid_database THEN
		DBMS_OUTPUT.PUT_LINE ('The target database must be a Stage database to apply this upgrade script.');
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT INT;
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;
    
    IF dbVersion = 640105 AND dbVersionCheckPoint = 0
    THEN
    
        -- UpdateSoilType_DomainCatalogColXRef_ColumnName.sql

        SELECT COUNT(*) INTO CNT
        FROM  DomainCatalogColXRef 
        WHERE TableName = 'SoilArea' 
        AND domaincatalogid = (SELECT Id FROM domaincatalog WHERE domaindescr = 'Soil Type') 
        AND columnname <> 'SoilTypeLD';

        IF (CNT <> 0)
        THEN
            UPDATE domaincatalogcolxref 
            SET columnname = 'SoilTypeLD' 
            WHERE tablename = 'SoilArea' AND domaincatalogid = (SELECT Id FROM domaincatalog WHERE domaindescr = 'Soil Type');
        END IF;
    
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
    
    IF dbVersion = 640105 AND dbVersionCheckPoint = 1
    THEN
       	/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 2 Updates 01
        /********************************************************************************************************/

        UPDATE VersionInfo
        SET DBVersion = '640201', DBVersionComment = 'Service Pack DDL 6.4, Rel. 2, Updates 01';
        
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


