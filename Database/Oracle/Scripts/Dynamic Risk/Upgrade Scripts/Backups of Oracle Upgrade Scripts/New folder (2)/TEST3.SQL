DECLARE
    CNT NUMBER(6);
    e_wrong_dbtype EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_wrong_dbtype, -20001);
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences  
    WHERE UPPER(ParameterName) = UPPER('DatabaseType')
        AND UPPER(Value) = UPPER('Stage');

    IF(CNT = 0)
    THEN
        raise_application_error(-20001, 'The target database must be a Stage database to apply this upgrade script.');
    END IF;
END;
/

DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(6);
BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 0
    THEN
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('CouponReading') 
            AND Column_Name = UPPER('CreatedDate');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE CouponReading ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        ELSE    
            EXECUTE IMMEDIATE 'ALTER TABLE CouponReading MODIFY CreatedDate DEFAULT CURRENT_DATE';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns
        WHERE Table_Name = UPPER('CouponReading') 
            AND Column_Name = UPPER('CreatedUser');

        IF (CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE CouponReading ADD CreatedUser VARCHAR(45) DEFAULT (SYS_CONTEXT('USERENV', 'OS_USER')) NOT NULL]';
        ELSE
            EXECUTE IMMEDIATE q'[ALTER TABLE CouponReading MODIFY CreatedUser DEFAULT (SYS_CONTEXT('USERENV', 'OS_USER'))]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM all_tab_columns 
        WHERE Table_Name = UPPER('Load_CouponReading') 
            AND Column_Name = UPPER('CreatedUser');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE q'[ALTER TABLE Load_CouponReading ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        ELSE
            EXECUTE IMMEDIATE q'[ALTER TABLE Load_CouponReading MODIFY CreatedUser DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tab_columns 
        WHERE Table_Name = UPPER('Load_CouponReading') 
            AND Column_Name = UPPER('CreatedDate');

        IF(CNT = 0)
        THEN
            EXECUTE IMMEDIATE 'ALTER TABLE Load_CouponReading ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        ELSE
            EXECUTE IMMEDIATE 'ALTER TABLE Load_CouponReading MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables
        WHERE Table_Name = UPPER('StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('StructureVertex') 
            AND Column_Name = UPPER('CreatedDate');

            IF(CNT = 0)
            THEN
        	    EXECUTE IMMEDIATE 'ALTER TABLE StructureVertex ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        	ELSE
                EXECUTE IMMEDIATE 'ALTER TABLE StructureVertex MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
            END IF;
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('StructureVertex') 
            AND Column_Name = UPPER('CreatedUser');

            IF(CNT = 0)
            THEN
        	    EXECUTE IMMEDIATE q'[ALTER TABLE StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        	ELSE
                EXECUTE IMMEDIATE q'[ALTER TABLE StructureVertex MODIFY CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
            END IF;
        END IF;
 
        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('Load_StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('Load_StructureVertex') 
            AND Column_Name = UPPER('CreatedDate');

            IF(CNT =0)
            THEN
        	    EXECUTE IMMEDIATE 'ALTER TABLE Load_StructureVertex ADD CreatedDate DATE DEFAULT CURRENT_DATE NOT NULL';
        	ELSE
                EXECUTE IMMEDIATE 'ALTER TABLE Load_StructureVertex MODIFY CreatedDate DATE DEFAULT CURRENT_DATE';
            END IF;
        END IF;

        SELECT COUNT(*) INTO CNT 
        FROM user_tables 
        WHERE Table_Name = UPPER('Load_StructureVertex');

        IF (CNT = 1)
        THEN
            SELECT COUNT(*) INTO CNT 
            FROM user_tab_columns 
            WHERE Table_Name = UPPER('Load_StructureVertex') 
            AND Column_Name = UPPER('CreatedUser');

            IF(CNT =0)
            THEN
        	    EXECUTE IMMEDIATE q'[ALTER TABLE Load_StructureVertex ADD CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL]';
        	ELSE
                EXECUTE IMMEDIATE q'[ALTER TABLE Load_StructureVertex MODIFY CreatedUser VARCHAR(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')]';
            END IF;
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
    CNT NUMBER(6);
    drop_fk VARCHAR2(1000);

BEGIN
    SELECT DBVersion into dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint into dbVersionCheckPoint FROM VersionInfo vi;

    IF dbVersion = 640007 AND dbVersionCheckPoint = 1
    THEN
        -- AlterHydroTestName_Stage.sql
        SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('HydroTest') 
            AND Column_Name = UPPER('HydroTestName');

        IF(CNT > 0)
        THEN
            --Store HydroTest table data in a table
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_HydroTest');
            IF(CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE tmp_HydroTest AS SELECT * FROM HydroTest';
            END IF;

            -- Create temporary tables to store foreign key constraint definitions for foreign keys on HydroTest ID column
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_add_constraint');

            IF(CNT = 0)
            THEN
            --Save foreign key constraints referencing HydroTest table the table tmp_add_constraint
            EXECUTE IMMEDIATE q'[CREATE TABLE tmp_add_constraint AS
                                SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                                ' ADD CONSTRAINT ' || fk_name || CHR(10) ||
                                ' FOREIGN KEY (' || column_name || ')' || CHR(10) ||
                                ' REFERENCES ' || ref_table || '(' || ref_column || ')' AS add_foreign_keys
                            FROM 
                            (SELECT ac.constraint_name fk_name, 
                                    ac.table_name,
                                    acc.column_name,
                                    ac.r_constraint_name,
                                    ref.table_name ref_table,
                                    ref.column_name ref_column
                            FROM user_constraints ac
                            JOIN user_cons_columns acc
                                ON (ac.constraint_name = acc.constraint_name)
                                    AND (ac.owner = acc.owner)
                            JOIN user_cons_columns ref
                                ON (ac.r_constraint_name = ref.constraint_name)
                                    AND (ac.r_owner = ref.owner)
                            WHERE ac.constraint_type = 'R'
                                AND ref.table_name = UPPER('HydroTest')
                                AND ref.column_name = 'ID' 
                            )]';
            END IF;

            DECLARE
                -- table variable to store foreign key creaion statements for dropped foreign keys
                TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
                INDEX BY BINARY_INTEGER;
                AddForeignKeys_tbl DDL_TABLE_TYPE;

                --Cursor to drop foreign keys
                CURSOR drop_cons_cursor IS
                SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                    ' DROP CONSTRAINT ' || fk_name  AS drop_foreign_key
                FROM
                (SELECT ac.constraint_name fk_name, 
                        ac.table_name,
                        acc.column_name,
                        ac.r_constraint_name,
                        ref.table_name ref_table,
                        ref.column_name ref_column
                FROM user_constraints ac
                JOIN user_cons_columns acc
                    ON (ac.constraint_name = acc.constraint_name)
                        AND (ac.owner = acc.owner)
                JOIN user_cons_columns ref
                    ON (ac.r_constraint_name = ref.constraint_name)
                        AND (ac.r_owner = ref.owner)
                WHERE ac.constraint_type = 'R'
                    AND ref.table_name = UPPER('HydroTest')
                    AND ref.column_name = 'ID' 
                    );  

            BEGIN
                --Store the foreign key definitions in a table VARIABLE
                EXECUTE IMMEDIATE q'[SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                                    ' ADD CONSTRAINT ' || fk_name || CHR(10) ||
                                    ' FOREIGN KEY (' || column_name || ')' || CHR(10) ||
                                    ' REFERENCES ' || ref_table || '(' || ref_column || ')' AS add_foreign_key
                            FROM 
                            (SELECT ac.constraint_name fk_name, 
                                    ac.table_name,
                                    acc.column_name,
                                    ac.r_constraint_name,
                                    ref.table_name ref_table,
                                    ref.column_name ref_column
                            FROM user_constraints ac
                            JOIN user_cons_columns acc
                                ON (ac.constraint_name = acc.constraint_name)
                                    AND (ac.owner = acc.owner)
                            JOIN user_cons_columns ref
                                ON (ac.r_constraint_name = ref.constraint_name)
                                    AND (ac.r_owner = ref.owner)
                            WHERE ac.constraint_type = 'R'
                                AND ref.table_name = UPPER('HydroTest')
                                AND ref.column_name = 'ID' 
                            )]'
                BULK COLLECT INTO AddForeignKeys_tbl;

                --Drop foreign key constraints referencing HydroTest table
                FOR ddl IN drop_cons_cursor LOOP
                   EXECUTE IMMEDIATE ddl.drop_foreign_key;      
                END LOOP;

                EXECUTE IMMEDIATE 'TRUNCATE TABLE HydroTest';

                EXECUTE IMMEDIATE 'ALTER TABLE HydroTest MODIFY HydroTestName VARCHAR2(50)';

                EXECUTE IMMEDIATE 'INSERT INTO HydroTest SELECT * FROM tmp_HydroTest';
             
                --Recreate foreign keys referencing HydroTest table
                FOR i IN 1..AddForeignKeys_tbl.COUNT LOOP
                    EXECUTE IMMEDIATE AddForeignKeys_tbl(i);
                END LOOP;
                
            END;

        END IF; -- End of HydroTest table modification

         SELECT COUNT(*) INTO CNT 
        FROM user_tab_columns
        WHERE Table_Name = UPPER('Load_HydroTest') 
            AND Column_Name = UPPER('HydroTestName');

        IF(CNT > 0)
        THEN
            --Store Load_HydroTest table data in a table temporarily
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = UPPER('tmp_Load_HydroTest');

            IF(CNT = 0)
            THEN
                EXECUTE IMMEDIATE 'CREATE TABLE tmp_Load_HydroTest AS SELECT * FROM Load_HydroTest';
            END IF;

            -- Trucate table to modify HydroTestName column
            EXECUTE IMMEDIATE 'TRUNCATE TABLE Load_HydroTest';

            EXECUTE IMMEDIATE 'ALTER TABLE Load_HydroTest MODIFY HydroTestName VARCHAR2(50)';

            --Insert data back into table
            EXECUTE IMMEDIATE 'INSERT INTO Load_HydroTest SELECT * FROM tmp_Load_HydroTest';     
                
        END IF; -- End of Load_HydroTest table modification

        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_Load_HydroTest');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_Load_HydroTest PURGE';
        END IF;
        
        
        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_HydroTest');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_HydroTest PURGE';
        END IF;
        
         SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = UPPER('tmp_add_constraint');

        IF(CNT = 1)
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmp_add_constraint PURGE';
        END IF;
        
        --UPDATE VersionInfo SET DBVersionCheckPoint = 2;

    END IF;	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/