SET SERVEROUTPUT ON;
/*
    This script modifies the length of the Listdomain 'Id' column as well as the length of all other table columns
    referencing ListDomain 'Id' column to a precision of 10 and scale 0. 

    This script must be executed on the target database
*/
DECLARE
    sql_stmt NVARCHAR2(20000);
    FKTableName NVARCHAR2(100);
    FKColumnName NVARCHAR2(100);
    ColumnName NVARCHAR2(100);
    IndexName NVARCHAR2(100);
    CNT INT;
    Counter INT;

    TargetTable NVARCHAR2(100) := 'ListDomain';
    TargetColumn NVARCHAR2(100) := 'Id';

    TYPE Constraint_Record_Type IS RECORD
    (constraint_name NVARCHAR2(100),
     fk_table NVARCHAR2(100),
     fk_column NVARCHAR2(100)    
     );

    TYPE Constraint_Table_Type IS TABLE OF Constraint_Record_Type
    INDEX BY BINARY_INTEGER;

    ChildTableList Constraint_Table_Type;

BEGIN

    sql_stmt := 'WITH tmpQuery AS
                (SELECT ucc2.constraint_name,
                        ucc2.table_name FKTableName,
                        ucc2.column_name FKColumnName,
                        ucc.table_name PKTableName,
                        ucc.column_name PKColumnName
                FROM user_constraints uc
                JOIN user_cons_columns ucc
                    ON uc.r_constraint_name = ucc.constraint_name
                JOIN user_cons_columns ucc2
                    ON ucc2.constraint_name = uc.constraint_name
                WHERE ucc.table_name = ''' || TargetTable || '''
                AND ucc.column_name = ''' || TargetColumn || '''
                UNION
                SELECT NULL AS constraint_name,
                       table_name AS FKTableName,
                       column_name AS FKColumnName,
                       NULL AS PKTableName,
                       NULL AS PKColumnName
                FROM user_tab_columns
                WHERE column_name LIKE ''%DOMAINID''
                AND table_name NOT IN (SELECT view_name FROM user_views)
                )
                SELECT COUNT(*)
                FROM user_tab_columns utc
                JOIN tmpQuery tmp
                    ON tmp.FKTableName = utc.table_name
                    AND tmp.FKColumnName = utc.column_name
                WHERE data_precision <> 0
                AND data_scale <> 0';

    EXECUTE IMMEDIATE sql_stmt INTO CNT;

    -- Store Info on columns referencing the TargetColumn whose column definitions need to be modified
    IF CNT <> 0 THEN

        sql_stmt := 'WITH tmpQuery AS
                (SELECT ucc2.constraint_name,
                        ucc2.table_name FKTableName,
                        ucc2.column_name FKColumnName,
                        ucc.table_name PKTableName,
                        ucc.column_name PKColumnName
                FROM user_constraints uc
                JOIN user_cons_columns ucc
                    ON uc.r_constraint_name = ucc.constraint_name
                JOIN user_cons_columns ucc2
                    ON ucc2.constraint_name = uc.constraint_name
                WHERE ucc.table_name = ''' || TargetTable || '''
                AND ucc.column_name = ''' || TargetColumn || '''
                UNION
                SELECT NULL AS constraint_name,
                       table_name AS FKTableName,
                       column_name AS FKColumnName,
                       NULL AS PKTableName,
                       NULL AS PKColumnName
                FROM user_tab_columns utc
                WHERE column_name LIKE ''%DOMAINID''
                AND table_name NOT IN (SELECT view_name FROM user_views)
                )
                SELECT DISTINCT tmp.FKTableName,
                        tmp.FKColumnName
                FROM user_tab_columns utc
                JOIN tmpQuery tmp
                    ON tmp.FKTableName = utc.table_name
                    AND tmp.FKColumnName = utc.column_name
                WHERE data_precision <> 0
                AND data_scale <> 0';

        EXECUTE IMMEDIATE sql_stmt
        BULK COLLECT INTO ChildTableList;

        -- Loop through each column that needs to be modified
        FOR i IN 1..ChildTableList.COUNT LOOP

            FKTableName := ChildTableList(i).fk_table;
            FKColumnName := ChildTableList(i).fk_column;

    -------------------------------------- MODIFY THE COLUMN DEFINITION ------------------------------------------

            -- Modify the column definition for the column in the current loop iteration
            sql_stmt := 'ALTER TABLE ' || FKTableName || ' MODIFY ' || FKColumnName || ' NUMBER(10, 0)';

            EXECUTE IMMEDIATE sql_stmt;

        END LOOP;

    END IF;

-------------------------------------- MODIFY TARGET TABLE COLUMN DEFINITION ---------------------------------------------

    SELECT COUNT(*) INTO CNT
    FROM user_tab_columns
    WHERE table_name = TargetTable
    AND column_name = TargetColumn
    AND data_precision = 10
    AND data_scale = 0;

    IF CNT = 0 THEN
        sql_stmt := 'ALTER TABLE ' || TargetTable || ' MODIFY ' || TargetColumn || ' NUMBER(10,0)';

        EXECUTE IMMEDIATE sql_stmt;
    END IF;

END;
/