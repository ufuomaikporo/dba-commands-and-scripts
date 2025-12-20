SET SERVEROUTPUT ON;
ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

DECLARE
    Substr VARCHAR2(4000);
    Char_Index INT;
    sql_stmt VARCHAR2(20000);
    StoredProcName VARCHAR2(100);
    DBName VARCHAR2(100);
    ServerName VARCHAR2(100);
    DefTabColCount INT;
    CNT INT;

    -- Create cursor to loop through specified schemas
    CURSOR schema_cursor IS
    SELECT username 
    FROM all_users
    WHERE username LIKE '%IRAS%OWNR%'
    AND username NOT LIKE '%TEST%';

BEGIN
    -- Name of stored procedure being checked
    StoredProcName := 'sp_Dx6ConfigV5';

    -- Create table to store list of schemas that fit the criteria (containing custom stored proc)
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'DBList';

    IF CNT <> 0 THEN
        sql_stmt := 'DROP TABLE DBList';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'DBList';

    IF CNT = 0 THEN
        sql_stmt := 'CREATE TABLE DBList (Schema_name VARCHAR2(100))';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;
    
    -- Loop through each IRAS_OWNR schema
    FOR schema_name IN schema_cursor LOOP

        -- Get a count of the number of columns in the table storing the stored proc definition
        SELECT COUNT(*) INTO CNT
        FROM (SELECT text
              FROM all_source
              WHERE name = 'sp_Dx6ConfigV5'	
              AND type = 'PROCEDURE'	
              AND owner = Schema_name.username
              AND REGEXP_LIKE (text,'UPDATE|INSERT') 
            )
        WHERE NOT REGEXP_LIKE(text,'Listdomain')
        AND NOT REGEXP_LIKE(text,'temp_Fabrication') 
        AND  NOT REGEXP_LIKE(text,'FabricationRemark') 
        AND  NOT REGEXP_LIKE(text,'FacilityAlignment')
        AND  NOT REGEXP_LIKE(text,'Fabrication');


        IF CNT <> 0 THEN
            sql_stmt := 'INSERT INTO DBList 
                        VALUES (''' || Schema_name.username || ''')';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

    END LOOP;

END;
/

SELECT * FROM DBList;

DECLARE
    CNT INT;
    sql_stmt VARCHAR2(10000);
BEGIN
  SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'DBList';

    IF CNT <> 0 THEN
        sql_stmt := 'DROP TABLE DBList';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;
END;
/