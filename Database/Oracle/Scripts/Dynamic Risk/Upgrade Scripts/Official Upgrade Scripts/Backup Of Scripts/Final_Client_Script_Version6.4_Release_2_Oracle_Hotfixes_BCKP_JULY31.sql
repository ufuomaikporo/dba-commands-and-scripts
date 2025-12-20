ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE 
    CNT INT;
    sql_stmt VARCHAR2(20000);
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    e_invalid_database EXCEPTION;

    CURSOR AlterColumn_Cursor IS
    SELECT 'ALTER TABLE ' || table_name || ' MODIFY SourceId VARCHAR2(50) NULL'  AS cmd
    FROM user_tab_columns 
    WHERE column_name = 'SourceId' AND nullable = 'N' AND table_name NOT LIKE 'LOAD%';

BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences
    WHERE ParameterName =  'DatabaseType' AND Value = 'Stage';

    IF CNT = 0 THEN
        RAISE e_invalid_database;
    END IF;

    SELECT dbVersion, dbVersionCheckPoint
    INTO dbversion, dbVersionCheckPoint
    FROM VersionInfo;

    IF dbVersion = 640205 AND dbVersionCheckPoint = 0 THEN
        FOR i IN AlterColumn_Cursor LOOP
            EXECUTE IMMEDIATE i.cmd;
        END LOOP;

        UPDATE VersionInfo SET dbVersionCheckPoint = 1;
        COMMIT;
    END IF;

EXCEPTION
    WHEN e_invalid_database THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE ('The target database is not Stage database for applying this upgrade script.');
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
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/
