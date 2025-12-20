ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;
SET SERVEROUTPUT ON;

DECLARE 
    CNT NUMBER;
    sql_stmt VARCHAR2(20000);

    CURSOR RenameColumnCursor IS
    SELECT 'ALTER TABLE ' || table_name || ' RENAME COLUMN ' || column_name || ' TO LastModDateTime' AS cmd
    FROM user_tab_columns
    WHERE column_name = 'LASTMODTIMESTAMP';

    CURSOR AddColumnCursor IS
    SELECT 'ALTER TABLE "LOAD_' || table_name || '" ADD ' || column_name ||
    (CASE  
        WHEN data_type = 'NUMBER' THEN ' NUMBER(' || data_precision || ', ' 
                || data_scale || ')'
        WHEN data_type LIKE '%char%' THEN ' ' || data_type || '(' || data_length || ')'
        ELSE ' ' || data_type 
    END) AS cmd
    FROM user_tab_columns tab1
    WHERE table_name IN (SELECT REPLACE(table_name, 'Load_', '') 
                        FROM user_tables WHERE table_name like 'Load_%'
                        )
     AND column_name NOT IN (SELECT column_name 
                             FROM user_tab_columns WHERE table_name = 'Load_' || tab1.table_name);                          
BEGIN

    FOR i IN RenameColumnCursor LOOP
        DBMS_OUTPUT.PUT_LINE(i.cmd);
        EXECUTE IMMEDIATE i.cmd;
    END LOOP;

    FOR i IN AddColumnCursor LOOP
        DBMS_OUTPUT.PUT_LINE(i.cmd);
        EXECUTE IMMEDIATE i.cmd;
    END LOOP;
                         
END;
/


