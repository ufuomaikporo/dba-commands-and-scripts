ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON;
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    TableName VARCHAR2(128);
    OldColumnName VARCHAR2(128);
    NewColumnName VARCHAR2(128);
    sql_stmt varchar2(1000);
    Counter NUMBER;
    CNT NUMBER;

    CURSOR RenameColumnList IS
    SELECT table_name, column_name
    FROM user_tab_columns
    WHERE column_name LIKE 'LastMod%' OR
        column_name LIKE 'Create%'
    MINUS
    SELECT table_name, column_name
    FROM user_tab_columns
    WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId');

    CURSOR AddColumnList IS
    SELECT table_name INTO CNT FROM user_tables WHERE table_name NOT IN (SELECT table_name FROM (
        SELECT table_name, COUNT(table_name) FROM user_tab_columns
        WHERE column_name IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')
        GROUP BY table_name
        HAVING COUNT(table_name) = 4
        ));

BEGIN

    -- Rename columns and remove duplicate columns
    FOR i IN RenameColumnList LOOP

        IF (i.column_name LIKE 'Create%User%') THEN
              sql_stmt := '
            DECLARE
                sql_stmt VARCHAR2(100);
                CNT INT;
            BEGIN
                SELECT COUNT(*) INTO CNT
                FROM user_tab_columns
                WHERE table_name = '''|| i.table_name ||'''
                AND column_name = ''CreatedUser'';

                IF CNT <> 0 THEN
                    sql_stmt := ''ALTER TABLE '|| i.table_name ||' DROP COLUMN '|| i.column_name||''';
                    EXECUTE IMMEDIATE sql_stmt;
                ELSE

                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' RENAME COLUMN ' || i.column_name
                        || ' TO CreatedUser'';

                    EXECUTE IMMEDIATE sql_stmt;
                        
                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' MODIFY CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')'';
                    
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
            END;';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        IF (i.column_name LIKE 'LastMod%User%') THEN
              sql_stmt := '
            DECLARE
                sql_stmt VARCHAR2(100);
                CNT INT;
            BEGIN
                SELECT COUNT(*) INTO CNT
                FROM user_tab_columns
                WHERE table_name = '''|| i.table_name ||'''
                AND column_name = ''LastModByUserId'';

                IF CNT <> 0 THEN
                    sql_stmt := ''ALTER TABLE '|| i.table_name ||' DROP COLUMN '|| i.column_name||''';
                    EXECUTE IMMEDIATE sql_stmt;
                ELSE

                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' RENAME COLUMN ' || i.column_name
                        || ' TO LastModByUserId'';

                    EXECUTE IMMEDIATE sql_stmt;
                        
                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' MODIFY LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')'';
                    
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
            END;';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        IF (i.column_name LIKE 'Last%Mod%Date%') THEN
            sql_stmt := '
            DECLARE
                sql_stmt VARCHAR2(100);
                CNT INT;
            BEGIN
                SELECT COUNT(*) INTO CNT
                FROM user_tab_columns
                WHERE table_name = '''|| i.table_name ||'''
                AND column_name = ''LastModDateTime'';

                IF CNT <> 0 THEN
                    sql_stmt := ''ALTER TABLE '|| i.table_name ||' DROP COLUMN '|| i.column_name||''';
                    EXECUTE IMMEDIATE sql_stmt;
                ELSE

                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' RENAME COLUMN ' || i.column_name
                        || ' TO LastModDateTime'';

                    EXECUTE IMMEDIATE sql_stmt;
                        
                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' MODIFY LastModDateTime DATE DEFAULT SYSDATE'';
                    
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
            END;';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        IF (i.column_name LIKE 'Create%Date%') THEN
            sql_stmt := '
            DECLARE
                sql_stmt VARCHAR2(100);
                CNT INT;
            BEGIN
                SELECT COUNT(*) INTO CNT
                FROM user_tab_columns
                WHERE table_name = '''|| i.table_name ||'''
                AND column_name = ''CreatedDate'';

                IF CNT <> 0 THEN
                    sql_stmt := ''ALTER TABLE '|| i.table_name ||' DROP COLUMN '|| i.column_name||''';
                    EXECUTE IMMEDIATE sql_stmt;
    
                ELSE
                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' RENAME COLUMN ' || i.column_name
                        || ' TO CreatedDate'';

                    EXECUTE IMMEDIATE sql_stmt;
                        
                    sql_stmt := ''ALTER TABLE ' || i.table_name || ' MODIFY CreatedDate DATE DEFAULT SYSDATE'';
                    
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;
            END;';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;
        
    END LOOP;

    -- Add missing columns
    FOR i IN AddColumnList LOOP

        sql_stmt := 'SELECT COUNT(*)
        FROM user_tab_columns
        WHERE table_name = ''' || i.table_name ||'''
        AND column_name = ''CreatedDate''';

        EXECUTE IMMEDIATE sql_stmt INTO CNT;

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE "' || i.table_name || '" ADD CreatedDate DATE DEFAULT SYSDATE';
            EXECUTE IMMEDIATE sql_stmt; 
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = i.table_name
        AND column_name = 'CreatedUser';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE "' || i.table_name || '" ADD CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
            EXECUTE IMMEDIATE sql_stmt; 
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = i.table_name
        AND column_name = 'LastModByUserId';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE "' || i.table_name || '" ADD LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
            EXECUTE IMMEDIATE sql_stmt; 
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE table_name = i.table_name
        AND column_name = 'LastModDateTime';

        IF CNT = 0 THEN
            sql_stmt := 'ALTER TABLE "' || i.table_name || '" ADD LastModDateTime DATE DEFAULT SYSDATE';
            EXECUTE IMMEDIATE sql_stmt; 
        END IF;

    END LOOP;
    
END;
/