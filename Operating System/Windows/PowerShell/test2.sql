SET SERVEROUTPUT ON
DECLARE 
    dbVersion number(10);
    dbVersionCheckPoint number(5);
    CNT NUMBER(1);
    ddl VARCHAR2(5000);

BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;

    -- IF dbVersion = 640002 AND dbVersionCheckPoint = 0
    -- THEN
        DECLARE
            counter BINARY_INTEGER := 0;

            -- table variable to store table of ddl statements
            TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
            INDEX BY BINARY_INTEGER;
            tmpListDomainForeignKeys DDL_TABLE_TYPE;

            -- Cursor to delete FK constraints
            CURSOR drop_cons_cursor IS
            SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
                    ' DROP CONSTRAINT ' || fk_name  AS drop_constraint
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
                AND ref.table_name = 'LISTDOMAIN'
                AND ref.column_name = 'ID' 
                );
            
            -- Cursor to store and add FK constraints
            CURSOR add_cons_cursor IS
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
                AND ref.table_name = 'LISTDOMAIN'
                AND ref.column_name = 'ID' 
            );

        BEGIN      
            --Store foreign key definitions in table variable
            FOR ddl IN add_cons_cursor LOOP
                counter := counter + 1;
                tmpListDomainForeignKeys(counter) := ddl.add_foreign_keys;
               
            END LOOP;

            --Drop FK constraints on listdomain table if FK definitions are saved
            IF (counter != 0)
            THEN 
                FOR ddl IN drop_cons_cursor LOOP
                    EXECUTE IMMEDIATE ddl.drop_constraint;
                END LOOP;
            END IF;

            --Check if listdomain table has an identity column
            SELECT COUNT(*) INTO CNT 
            FROM all_tab_identity_cols 
            WHERE table_name = 'LISTDOMAIN'
                AND owner = USER;

            --if there is no identity column on listdomain table, save the table data to temp table, 
            --add the identity column, and transfer the data back into table
            IF (CNT = 0)
            THEN
                -- Save listdomain table data in temp table
                SELECT COUNT(*) INTO CNT
                FROM all_tables
                WHERE table_name = UPPER('tmpListDomain_Identity')
                    AND owner = USER;

                ddl := q'[CREATE TABLE tmpListDomain_Identity
                                AS SELECT * FROM listdomain
                        ]';

                -- Copy listdomain data into tmpListDomain_Identity. drop tmpListDomain_Identity table if it already exists
                IF (CNT = 1)
                THEN
                    EXECUTE IMMEDIATE 'DROP TABLE tmpListDomain_Identity';   
                    EXECUTE IMMEDIATE ddl;
                ELSE
                    EXECUTE IMMEDIATE ddl;
                END IF;

                SELECT COUNT(*) INTO CNT
                FROM all_constraints 
                WHERE constraint_name = UPPER('pk_listdomain')
                    AND owner = USER;

                -- drop PK ON id column if it exists
                IF (CNT > 0)
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE listdomain DROP CONSTRAINT pk_listdomain';                     
                END IF;

                SELECT COUNT(*) INTO CNT
                FROM all_tab_cols
                WHERE column_name = 'ID'
                    AND table_name = 'LISTDOMAIN'
                    AND owner = USER;

                -- Drop ID column if it exists
                IF (CNT = 1)
                THEN
                    EXECUTE IMMEDIATE 'ALTER TABLE listdomain DROP COLUMN id';
                END IF;    

                -- Delete contents on listdomain table
                EXECUTE IMMEDIATE 'DROP TABLE listdomain PURGE';

                EXECUTE IMMEDIATE 'CREATE TABLE listdomain AS 
                                    SELECT * FROM tmpListDomain_Identity
                                    WHERE 1 = 0';

                EXECUTE IMMEDIATE 'ALTER TABLE listdomain DROP COLUMN id';

                -- Recreate ID column in listdomain table as identity column
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain ADD 
                            (id NUMBER(7,0) GENERATED BY DEFAULT AS IDENTITY 
                                CONSTRAINT pk_listdomain PRIMARY KEY)';
                
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain
                                    MODIFY (DomainCatalogId INVISIBLE, 
                                            Code INVISIBLE,     
                                            Descr INVISIBLE, 
                                            SourceDomainId INVISIBLE, 
                                            LastModByUserId INVISIBLE, 
                                            LastModDateTime INVISIBLE)';
                
                EXECUTE IMMEDIATE 'ALTER TABLE listdomain
                                    MODIFY (DomainCatalogId VISIBLE, 
                                            Code VISIBLE,     
                                            Descr VISIBLE, 
                                            SourceDomainId VISIBLE, 
                                            LastModByUserId VISIBLE, 
                                            LastModDateTime VISIBLE)';

                EXECUTE IMMEDIATE 'INSERT INTO listdomain (Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime)
                                        SELECT Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime
                                        FROM tmpListDomain_Identity';                        
            END IF;

            --Add foreign keys referencing listdomain backup into tables
            FOR i IN 1..counter LOOP
                ddl := tmpListDomainForeignKeys(i);
                EXECUTE IMMEDIATE ddl;
            END LOOP;
                        
------------------------------------------ Drop temp tables ---------------------------------------------
         
        --     SELECT COUNT(*) INTO CNT
        --     FROM all_tables
        --     WHERE table_name = UPPER('tmpListDomain_Identity')
        --         AND owner = USER;

        --     IF (CNT > 0)
        --     THEN
        --         EXECUTE IMMEDIATE 'DROP TABLE tmpListDomain_Identity';
        --     END IF;
        END;

------------------------Update the version checkpoint within versioninfo table if it exists------------------

        SELECT COUNT(*) INTO CNT
        FROM all_tab_cols
        WHERE column_name = UPPER('DBVersionCheckPoint')
            AND table_name = UPPER('versionInfo') 
            AND owner = USER;

        IF (CNT > 0)
        THEN
            EXECUTE IMMEDIATE 'UPDATE VersionInfo
                                SET DBVersionCheckPoint = 1';
            COMMIT;
        END IF;

    -- END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                            || ', checkpoint ' || dbVersionCheckPoint);
	    DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);
END;
/