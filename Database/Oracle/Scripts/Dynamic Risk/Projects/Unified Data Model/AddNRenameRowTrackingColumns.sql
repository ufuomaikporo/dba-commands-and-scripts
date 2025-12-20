ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

/*
    This script adds the CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
    to tables that are missing the columns and makes sure the column names and datatypes is uniform
    across all tables
*/
DECLARE
    CNT INT;
    sql_stmt VARCHAR2(20000);

    -- Cursor to find and rename row-tracking columns that need to be renamed
    CURSOR RenameCol_Cursor IS
    SELECT table_name, 
        column_name AS OldColumnName,
        CASE
            WHEN column_name LIKE 'Create%User%' THEN 'CreatedUser'
            WHEN column_name LIKE 'Create%Date%' THEN 'CreatedDate'
            WHEN column_name LIKE 'LastMod%Date%' THEN 'LastModDateTime'
            WHEN column_name LIKE 'LastMod%User%' THEN 'LastModByUserId'
        END AS NewColumnName
    FROM user_tab_columns
    WHERE REGEXP_LIKE (column_name, '^LastMod%|^Create%Date|^Create*User')
    AND column_name NOT IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId');

    -- Cursor to add row-tracking columns to any table that is missing it
    CURSOR AddCol_Cursor IS
    SELECT table_name, 'CreatedDate TIMESTAMP DEFAULT SYSDATE' AS MissingColumn
    FROM user_tables 
    WHERE table_name NOT IN (SELECT table_name 
                            FROM user_tab_columns
                            WHERE column_name LIKE 'Create%Date%')
    UNION
    SELECT table_name, 'CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')' AS MisingColumn
    FROM user_tables 
    WHERE table_name NOT IN (SELECT table_name 
                            FROM user_tab_columns
                            WHERE column_name LIKE 'Create%User%')
    UNION
    SELECT table_name, 'LastModDateTime TIMESTAMP DEFAULT SYSDATE' AS MisingColumn
    FROM user_tables 
    WHERE table_name NOT IN (SELECT table_name 
                            FROM user_tab_columns
                            WHERE column_name LIKE 'LastMod%Date%')
    UNION
    SELECT table_name, 'LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')' AS MisingColumn
    FROM user_tables 
    WHERE table_name NOT IN (SELECT table_name 
                        FROM user_tab_columns
                        WHERE column_name LIKE 'LastMod%User%');

    --Make column datatype consistent for all row-tracking columns
    CURSOR ColumnType_Cursor IS
    SELECT table_name, 
        column_name, 
            CASE
            WHEN column_name LIKE 'Create%User%' OR column_name LIKE 'LastMod%User%' OR column_name LIKE 'LastUpgrade%User%'
                THEN 'VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')'
            WHEN column_name LIKE 'Create%Date%' OR column_name LIKE 'LastMod%Date%' OR column_name LIKE 'LastUpgrade%Time%'
                THEN 'TIMESTAMP DEFAULT SYSDATE'
        END AS NewColumnType
    FROM user_tab_columns
    WHERE REGEXP_LIKE (column_name, '^LastMod.*|^Create.*User|^Create.*Date|^LastUpgrade.*') AND
    data_type NOT IN ('TIMESTAMP(6)', 'VARCHAR2');

    -- Cursor to update trigger defintions for all triggers that include the modified row-tracking column
    CURSOR ModifyTrigger_Cursor IS
    SELECT trigger_name, table_name
    FROM user_triggers
    WHERE trigger_name LIKE 'TU_%';
                        
BEGIN
    -- Rename columns to CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
    FOR i IN RenameCol_Cursor LOOP

        sql_stmt := 'ALTER TABLE ' || i.table_name || ' RENAME COLUMN '|| i.OldColumnName || ' TO ' || i.NewColumnName;
        EXECUTE IMMEDIATE sql_stmt;

    END LOOP;

    -- Add missing CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
    FOR i IN AddCol_Cursor LOOP

        sql_stmt := 'ALTER TABLE "'|| i.table_name || '" ADD ' || i.MissingColumn;
        EXECUTE IMMEDIATE sql_stmt;

    END LOOP;

    -- Modify column datatype
    FOR i IN ColumnType_Cursor LOOP

        sql_stmt:= 'ALTER TABLE "' || i.table_name || '" MODIFY ' || i.column_name || ' ' || i.NewColumnType;
        EXECUTE IMMEDIATE sql_stmt;

    END LOOP;

    -- Modify trigger definitions
    FOR i IN ModifyTrigger_Cursor LOOP
        sql_stmt := 'CREATE OR REPLACE TRIGGER ' || i.trigger_name || CHR(10) ||
            'BEFORE UPDATE ON ' || i.table_name || CHR(10) ||
            'FOR EACH ROW
            BEGIN
                :NEW.LastModByUserId := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                :NEW.LastModDateTime := SYSDATE;
            END;' ;

        EXECUTE IMMEDIATE sql_stmt;

    END LOOP;
    END;
/