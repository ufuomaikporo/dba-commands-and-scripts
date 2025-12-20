ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE
    CNT INT;
    sql_stmt VARCHAR2(20000);
    disable_cmds VARCHAR(32000);
    
    CURSOR DeleteTable_Cursor IS
    SELECT 'TRUNCATE TABLE "' || table_name || '"' AS cmd
    FROM user_tables;
    -- WHERE table_name NOT IN ('ActionItemProperty',
    --                         'AppList',
    --                         'AppTableListXref',
    --                         'AppTables',
    --                         'CenterpriseSequence',
    --                         'ClusterSettings',
    --                         'Connection',
    --                         'ConnectionType',
    --                         'DEParentChildIdCols',
    --                         'RCComputationType',
    --                         'RCHCAReasonType',
    --                         'RiskResultModuleGroup',
    --                         'Role',
    --                         'ServerProfile',
    --                         'SystemPreferences',
    --                         'tmpListDomain_Identity',
    --                         'User',
    --                         'VersionHistory',
    --                         'VersionInfo',
    --                         'VirtualTable',
    --                         'VirtualColumn');

    
    
    CURSOR DisableFK_Cursor IS
    SELECT 'ALTER TABLE "' || child.table_name || '" DISABLE NOVALIDATE CONSTRAINT ' || uc.constraint_name  AS cmd
    FROM user_constraints uc
    JOIN user_cons_columns parent
        ON uc.r_constraint_name = parent.constraint_name
    JOIN user_cons_columns child
        ON uc.constraint_name = child.constraint_name
    WHERE uc.status = 'ENABLED';   
                                
    CURSOR EnableFK_Cursor IS
    SELECT 'ALTER TABLE "' || child.table_name || '" ENABLE VALIDATE CONSTRAINT ' || uc.constraint_name  AS cmd
    FROM user_constraints uc
    JOIN user_cons_columns parent
        ON uc.r_constraint_name = parent.constraint_name
    JOIN user_cons_columns child
        ON uc.constraint_name = child.constraint_name
    WHERE uc.status = 'DISABLED';   
BEGIN
    
    -- Disables foreign keys
    FOR row_item IN DisableFK_Cursor LOOP
        EXECUTE IMMEDIATE row_item.cmd; 

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('...Foreign Keys have been disabled' || CHR(10));

                                
    -- Deletes data from tables                            
    FOR row_item IN DeleteTable_Cursor LOOP            
       EXECUTE IMMEDIATE(row_item.cmd);
        
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('...Table data has been deleted' || CHR(10));

    -- Enables foreign keys
    FOR row_item IN EnableFK_Cursor LOOP
        EXECUTE IMMEDIATE row_item.cmd; 
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('...Foreign keys have been enabled' || CHR(10));

                
END;
/