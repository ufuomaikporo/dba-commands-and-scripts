DECLARE
    CNT NUMBER;
    DDL VARCHAR2(5000);
        counter BINARY_INTEGER := 0;

    -- table variable to store table of ddl statements
    TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
    INDEX BY BINARY_INTEGER;
    tmpListDomainForeignKeys DDL_TABLE_TYPE;

    -- Cursor to drop FK constraints
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
    
BEGIN
    -- Save listdomain table data in temp table
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = UPPER('tmpListDomain_Identity');

    IF (CNT = 0)
    THEN
        EXECUTE IMMEDIATE q'[CREATE TABLE tmpListDomain_Identity
                        AS SELECT * FROM listdomain
                ]';
    END IF;

    --Save foreign key creation commands in a table temporarily (This is a backup JUST IN CASE)
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'tmp_add_constraints';

    IF (CNT = 0)
    THEN
        EXECUTE IMMEDIATE q'[CREATE TABLE tmp_add_constraints AS
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
                            )]';
    END IF;

    --Save the ddl for FK constraints referencing the listdomain table in a table variable (will be deleted after script execution)
    EXECUTE IMMEDIATE q'[ SELECT 'ALTER TABLE ' || table_name || CHR(10) ||
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
                            )]'
    BULK COLLECT INTO tmpListDomainForeignKeys;

    -- Drop the listdomain table
    EXECUTE IMMEDIATE 'DROP TABLE listdomain CASCADE CONSTRAINTS PURGE';

    --Recreate listdomain table based on the table structure of tmpListDomain_Identity
    EXECUTE IMMEDIATE 'CREATE TABLE listdomain AS 
                        SELECT * FROM tmpListDomain_Identity
                        WHERE 1 = 0';

    -- Drop the id column so it can be modified
    EXECUTE IMMEDIATE 'ALTER TABLE listdomain DROP (Id, LastModByUserId, LastModDateTime)';

    -- Recreate id column in listdomain table as an identity column
    EXECUTE IMMEDIATE q'[ALTER TABLE listdomain ADD 
                (id NUMBER(7,0) GENERATED BY DEFAULT ON NULL AS IDENTITY 
                    START WITH 1 INCREMENT BY 1 NOCYCLE
                    CONSTRAINT pk_listdomain PRIMARY KEY,
                LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL,
                LastModDateTime DATE DEFAULT CURRENT_DATE NOT NULL
                )]';

    -- Make the id column the first column in the table
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

    -- Insert the listdomain data back into the listdomain table
    EXECUTE IMMEDIATE 'INSERT INTO listdomain (Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime)
                            SELECT Id, DomainCatalogId, Code, Descr, SourceDomainId, LastModByUserId, LastModDateTime
                            FROM tmpListDomain_Identity';     

    --Add foreign keys referencing listdomain backup into tables
    FOR i IN 1..tmpListDomainForeignKeys.COUNT LOOP
        EXECUTE IMMEDIATE tmpListDomainForeignKeys(i);
    END LOOP;
                            
    ------------------------------------------ Drop temp tables ---------------------------------------------
            
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = UPPER('tmpListDomain_Identity');

    IF (CNT > 0)
    THEN
        EXECUTE IMMEDIATE 'DROP TABLE tmpListDomain_Identity';
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = UPPER('tmp_add_constraints');
        

    IF (CNT > 0)
    THEN
        EXECUTE IMMEDIATE 'DROP TABLE tmp_add_constraints';
    END IF;

    --COMMIT;
END;
/