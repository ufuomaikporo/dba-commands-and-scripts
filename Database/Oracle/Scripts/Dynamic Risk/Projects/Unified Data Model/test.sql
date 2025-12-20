ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE 
    CNT INT;
    e_Wrong_Database EXCEPTION;
    sql_stmt VARCHAR2(20000);

    CURSOR TableList_cursor IS
    SELECT * FROM NewDomainTableList
    WHERE FKTableName IS NOT NULL;
BEGIN
    FOR i IN TableList_cursor LOOP
        sql_stmt := 'SELECT COUNT(DISTINCT DomainCatalogId)
                    FROM ListDomain
                    WHERE Id IN (SELECT ' || i.FKColumnName || ' FROM ' || i.FKTableName || ')
                    ';
  -- DBMS_OUTPUT.PUT_LINE(sql_stmt);
        EXECUTE IMMEDIATE sql_stmt INTO CNT;

        IF CNT > 1 THEN
            DBMS_OUTPUT.PUT_LINE('SELECT ' || i.FKColumnName || ' FROM ' || i.FKTableName );
        END IF;
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
 
END;
/