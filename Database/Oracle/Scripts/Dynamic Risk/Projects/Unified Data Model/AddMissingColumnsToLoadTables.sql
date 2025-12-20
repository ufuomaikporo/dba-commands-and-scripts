 DECLARE 
    sql_stmt VARCHAR2(20000);

    CURSOR AddColumn_Cursor IS
    SELECT 'ALTER TABLE LOAD_' || table_name || ' ADD ' || column_name || ' ' || data_type || 
    CASE
        WHEN REGEXP_LIKE (data_type, 'varchar|char') THEN '(' || data_length || ')'
        WHEN column_name = 'CheckSumValue' THEN '(' || 10 || ')'
        WHEN data_type LIKE '%NUMBER%' THEN '(' || data_precision || ',' || data_scale || ')'
    END AS AddColumn
    FROM user_tab_columns tab1
    WHERE table_name IN (SELECT REPLACE(table_name, 'Load_', '') 
                        FROM user_tables 
                        WHERE table_name LIKE 'Load_%')
    AND column_name NOT IN (SELECT column_name 
                            FROM user_tab_columns
                            WHERE table_name = 'Load_' || tab1.table_name);
BEGIN

    FOR i IN AddColumn_Cursor LOOP
        EXECUTE IMMEDIATE i.AddColumn;
    END LOOP;
END;