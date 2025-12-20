ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

--------------------- Create NewDomainTableList table & Validate ListDomain Data -----------------

DECLARE
    NewTableName VARCHAR2(100);
    FKConstraintName VARCHAR2(100);
    FKTableName VARCHAR2(100);
    FKColumnName VARCHAR2(100);
    sql_stmt NVARCHAR2(20000);
    CNT INT;
    DomainCatalogId INT;

BEGIN

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'NewDomainTableList';

    IF CNT <> 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE NewDomainTableList';
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'NewDomainTableList';

    IF CNT = 0 THEN
        sql_stmt := 'CREATE TABLE NewDomainTableList
                    (FKConstraint VARCHAR2(100),
                    FKTableName VARCHAR2(100),
                    FKColumnName VARCHAR2(100),
                    NewListDomainTable VARCHAR2(100),
                    DomainCatalogId INT,
                    DomainDescr VARCHAR2(100)
                    )';
        
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := '
            INSERT INTO NewDomainTableList (FKConstraint, 
                                            FKTableName, 
                                            FKColumnName, 
                                            NewListDomainTable, 
                                            DomainCatalogId, 
                                            DomainDescr)
            SELECT NULL AS FKconstraint,
                    NULL FKTableName,
                    NULL FKColumnName,
            CASE
                WHEN LENGTH(REGEXP_REPLACE(DomainDescr, '' |-|_'')) > 27
                    THEN ''LD_'' || SUBSTR(REGEXP_REPLACE(DomainDescr, '' |-|_|\&|,|\.'', ''''), 1, 27) 
                ELSE ''LD_'' || REGEXP_REPLACE(DomainDescr, '' |-|_|\&|,|\.'', '''') 
            END AS NewListDomainTable,
            Id AS DomainCatalogId,
            DomainDescr
        FROM DomainCatalog
        WHERE Id <> -1
        UNION
        SELECT uc.constraint_name,
            uc.table_name,
                ucc2.column_name,
                NULL,
                NULL,
                NULL
        FROM user_constraints uc
        JOIN user_cons_columns ucc
            ON uc.r_constraint_name = ucc.constraint_name
        JOIN user_cons_columns ucc2
            ON uc.constraint_name = ucc2.constraint_name
        WHERE ucc.table_name = ''ListDomain''
        AND ucc.column_name = ''Id''
        AND uc.table_name NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')';

        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := '
        BEGIN
                UPDATE NewDomainTableList
                SET NewListDomainTable = SUBSTR(NewListDomainTable, 1, REGEXP_INSTR(NewLIstDomainTable, ''\('') - 1)
                WHERE REGEXP_LIKE(NewListDomainTable, ''\('');
                
                DELETE FROM NewDomainTableList
                WHERE REGEXP_LIKE(NewListDomainTable, ''yes/'');

                UPDATE NewDomainTableList
                SET NewListDomainTable = CASE
                    WHEN REGEXP_LIKE(NewListDomainTable, ''N/A'')
                        THEN ''LD_NotApplicable''
                    ELSE REGEXP_REPLACE(NewListDomainTable, ''/'', '''')
                    END;
        END;';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

    END IF;
END;
/

DECLARE
    NewTableName VARCHAR2(100);
    FKConstraintName VARCHAR2(100);
    FKTableName VARCHAR2(100);
    FKColumnName VARCHAR2(100);
    sql_stmt NVARCHAR2(20000);
    CNT INT;
    CatalogIdCount INT;
    IfExists INT;
    DomainId INT;
    ColName VARCHAR2(100);
    TabName VARCHAR2(100);
    Domain VARCHAR2(100);
    Constraint VARCHAR2(100);

    --User defined errors
    Too_Many_DomainId_1 EXCEPTION;
    Too_Many_DomainId_2 EXCEPTION;
    Too_Many_DomainId_3 EXCEPTION;

    -- Record variable
    TYPE fk_record_type IS RECORD
    (FKConstraint VARCHAR2(100),
     FKTableName VARCHAR2(100),
     FKColumnName VARCHAR2(100),
     NewTableName VARCHAR2(100),
     DomainCatalogId INT,
     DomainDescr VARCHAR2(255)
    );

    -- Table variables
    TYPE fk_Table_Type IS TABLE OF fk_record_type
    INDEX BY BINARY_INTEGER;

    DomainTableList fk_Table_Type;

BEGIN

    --Populate table variable
    SELECT * 
    BULK COLLECT INTO DomainTableList
    FROM NewDomainTableList;
    
    FOR i IN 1..DomainTableList.COUNT LOOP

------------------------------- VALIDATE LISTDOMAIN DATA --------------------------------

        IfExists := NULL;
        CatalogIdCount := NULL;
   
        ColName := DomainTableList(i).FKColumnName;
        Tabname := DomainTableList(i).FKTableName;
        Constraint := DomainTableList(i).FKConstraint;
        DomainId := DomainTableList(i).DomainCatalogId;
        Domain := DomainTableList(i).DomainDescr;
        NewTableName := DomainTableList(i).NewTableName;
        FKConstraintName := DomainTableList(i).FKConstraint;

        SELECT COUNT(*) INTO IfExists
        FROM DomainCatalogColXRef
        WHERE TableName = TabName
        AND ColumnName = ColName;

        --Find the DomainCatalogId for the table and column in current loop if it exists in DomainCatalogColXRef table
        IF IfExists <> 0 THEN

            SELECT DomainCatalogId
            INTO DomainId 
            FROM DomainCatalogColXRef
            WHERE TableName = TabName
                AND ColumnName = ColName;

        END IF;

        -- Find the number of distinct DomainCatalogIds for current table and column combo in ListDomain table 
        IF (ColName IS NOT NULL AND TabName IS NOT NULL) THEN

            sql_stmt := 'SELECT COUNT(DISTINCT DomainCatalogId)
            FROM ListDomain
            WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ')
            AND DomainCatalogId <> -1';

            EXECUTE IMMEDIATE sql_stmt INTO CatalogIdCount;

        END IF;

        /*
            If the table and column in the current loop has an entry in the DomainCatalogColXRef table
            and more than 1 distinct DomainCatalogIds (other than -1) in it's ListDomain table entries,
            throw an error and force the user to fix the issue manually
        */
        IF (CatalogIdCount > 1 AND IfExists <> 0 ) THEN
            RAISE Too_Many_DomainId_1;
        /*
            if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
            table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
            then throw an error to force user to manually fix the issue
        */
        ELSIF (IfExists = 0 AND CatalogIdCount > 1) THEN
            RAISE Too_Many_DomainId_2; 
        /*
            If the table and column in the current loop has an entry in the DomainCatalogColXRef table
            or has entries in the ListDomain table with a single distinct DomainCatalogId other than -1
            Then the new list domain table name should be one of the tables already in the temporary table ##NewDomainTableList
        */	
        ELSIF (IfExists <> 0 OR CatalogIdCount = 1) THEN             

            IF (DomainId IS NULL) THEN
                sql_stmt := 'SELECT DISTINCT DomainCatalogId 
                            FROM ListDomain
                            WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName ||' )
                                AND DomainCatalogId <> -1';

                EXECUTE IMMEDIATE sql_stmt INTO DomainId;

            END IF;

            SELECT NewListDomainTable, DomainDescr
            INTO NewTableName, Domain
            FROM NewDomainTableList
            WHERE DomainCatalogId = DomainId
                AND rownum < 2;

        ELSE

            SELECT COUNT(*)
            INTO CNT
            FROM NewDomainTableList nt
            JOIN DomainCatalogColXRef dc
                ON dc.ColumnName = nt.FKColumnName
            WHERE FKColumnName = ColName
                AND (nt.DomainCatalogId IS NOT NULL OR dc.DomainCatalogId IS NOT NULL);

            /*
                If the current table and column has the same name as another table and column 
                that already has a Domainid, Domaindescr, and new list domain table name, then 
                use that new list domain table name
            */
            IF CNT <> 0 THEN
              
                SELECT (SELECT NewListDomainTable FROM NewDomainTableList WHERE DomainCatalogId = dc.DomainCatalogId AND rownum < 2), 
                        dc.DomainCatalogId,
                        (SELECT DomainDescr FROM DomainCatalog WHERE Id = dc.DomainCatalogId)
                INTO NewTableName, DomainId, Domain
                FROM NewDomainTableList nt
                JOIN DomainCatalogColXRef dc
                    ON dc.ColumnName = nt.FKColumnName
                WHERE FKColumnName = ColName
                    AND (nt.DomainCatalogId IS NOT NULL OR dc.DomainCatalogId IS NOT NULL)
                    AND rownum < 2;

            -- Use the 'Coordinate System' DomainCatalog Id, Descr and tablename for columns with 'CoordSys' in the name
            ELSIF (DomainId IS NULL AND ColName LIKE '%CoordSys%') THEN
                SELECT DomainCatalogId, DomainDescr, NewListDomainTable
                INTO DomainId, Domain, NewTableName
                FROM NewDomainTableList
                WHERE DomainDescr = 'Coordinate System'
                    AND FKTableName IS NULL;

            -- Make the IRASCustomData easier to distinguish by adding the table name
            ELSIF (TabName LIKE 'IRASCustomData%' AND DomainId IS NULL) THEN
                NewTableName := 'LD_' || TabName || REGEXP_REPLACE(ColName, '_DomainId', '');

            -- For rows with null DomainCatalogId match Column names with DomainDescr in DomainCatalog table by removing 'DomainId'/'LD' suffix
            ELSIF (ColName LIKE '%DomainId' OR ColName LIKE '%Ld') THEN
                
                SELECT COUNT(*) INTO CNT
                FROM DomainCatalog 
                WHERE REGEXP_REPLACE(DomainDescr, ' |\d', '') IN (REGEXP_REPLACE(ColName, 'DomainId', ''), REGEXP_REPLACE(ColName, 'Ld', ''));            

                IF (CNT <> 0) THEN
                    SELECT NewListDomainTable, 
                           DomainCatalogId, 
                           DomainDescr
                    INTO NewTableName, DomainId, Domain
                    FROM NewDomainTableList 
                    WHERE DomainCatalogId = (SELECT Id FROM DomainCatalog 
                                             WHERE REGEXP_REPLACE(DomainDescr, ' |\d', '') 
                                             IN (REGEXP_REPLACE(ColName, 'DomainId', ''), REGEXP_REPLACE(ColName, 'Ld', '')) 
                                             )
                    AND rownum < 2;

                -- Use the Column name as the new list domain table name if the column name cannot be matched to DomainDescr in DomainCatalog  
                ELSE
                    IF(LENGTH(ColName) > 27) THEN
                            NewTableName := 'LD_' || SUBSTR(REGEXP_REPLACE(ColName, 'DomainId|Ld', ''), 1, 27);  
                    ELSE
                        NewTableName := 'LD_' || REGEXP_REPLACE(ColName, 'DomainId|Ld', '');  

                    END IF;

                END IF; 
            -- If all-else fails use the column name as the new list domain table name
            ELSIF (Colname IS NOT NULL) THEN
                IF(LENGTH(ColName) > 27) THEN
                        NewTableName := 'LD_' || SUBSTR(REGEXP_REPLACE(ColName, 'DomainId|Ld', ''), 1, 27);  
                ELSE
                    NewTableName := 'LD_' || REGEXP_REPLACE(ColName, 'DomainId|Ld', '');  

                END IF;
            END  IF;
        END IF;

        UPDATE NewDomainTableList
        SET NewListDomainTable = NewTableName,
            DomainCatalogId = DomainId,
            DomainDescr = Domain
            WHERE FKTableName = TabName
                AND FKColumnName = ColName;

       COMMIT;

-------------------------------------- CREATE New ListDomain tables ---------------------------------------

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = NewTableName;

        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE '|| NewTableName ||'
                        (Id NUMBER(10, 0) GENERATED BY DEFAULT AS IDENTITY,
                        Code VARCHAR2(60) NOT NULL,
                        Descr VARCHAR2(255) NOT NULL,
                        EffectiveEndDate TIMESTAMP,
                        CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                        CreatedDate TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
                        LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                        LastModDateTime TIMESTAMP DEFAULT CURRENT_DATE NOT NULL, 
                        CONSTRAINT PK_'|| NewTableName || ' PRIMARY KEY (Id)
                        )';

            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        -- Create update/delete trigger on table
        sql_stmt := 'CREATE OR REPLACE TRIGGER tu_' || NewTableName || '
                    AFTER UPDATE OR DELETE
                    ON ' || NewTableName || '
                    FOR EACH ROW
                    BEGIN
                        UPDATE ' || NewTableName || ' 
                            SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                LastModDateTime = CURRENT_DATE;
                    END;';

        EXECUTE IMMEDIATE sql_stmt;

-------------------------------- Populate the New List Domain Table ----------------------------------

        IF (ColName IS NOT NULL) THEN
            sql_stmt := 'SELECT COUNT(*) FROM ListDomain WHERE Id IN (SELECT DISTINCT '|| ColName || ' FROM '|| TabName || ') ';

            EXECUTE IMMEDIATE sql_stmt INTO CNT;
        END IF;

        IF (ColName IS NOT NULL AND CNT > 0) THEN
            sql_stmt := 'INSERT INTO ' || NewTableName || ' (Id, Code, Descr, EffectiveEndDate)
                        WITH tmpQuery AS
                        (SELECT Id,
                            DomainCatalogId,
                            Code,
                            Descr
                        FROM ListDomain
                        WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName || ')
                        UNION
                        SELECT Id,
                                DomainCatalogId,
                                Code,
                                Descr
                        FROM ListDomain WHERE DomainCatalogId = ' || DomainId || '
                        )
                        SELECT Id,
                            CASE 
                                WHEN Code = '''' OR Code IS NULL THEN ''<None>''
                                ELSE Code
                                END AS Code,
                            CASE 
                                WHEN Descr = '''' OR Descr IS NULL THEN ''<None>''
                                ELSE Descr
                                END AS Descr,
                            CASE 
                                    WHEN DomainCatalogId = -1 THEN CURRENT_DATE
                                    ELSE NULL
                                END AS EffectiveEndDate
                        FROM tmpQuery
                        WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
                        ORDER BY 1';

           EXECUTE IMMEDIATE sql_stmt;

        ELSIF (DomainId IS NOT NULL) THEN
            sql_stmt := 'INSERT INTO ' || NewTableName || ' (Id, Code, Descr)
                        WITH tmpQuery AS
                        (SELECT Id,
                                DomainCatalogId,
                                Code,
                                Descr
                        FROM ListDomain WHERE DomainCatalogId = ' || DomainId || '
                        )
                        SELECT Id,
                            CASE 
                                WHEN Code = '''' OR Code IS NULL THEN ''<None>''
                                ELSE Code
                                END AS Code,
                            CASE 
                                WHEN Descr = '''' OR Descr IS NULL THEN ''<None>''
                                ELSE Descr
                                END AS Descr
                        FROM tmpQuery
                        WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
                        ORDER BY 1';

            EXECUTE IMMEDIATE sql_stmt;

        END IF;

        COMMIT;

---------------------------- UPDATE TempListDomainTable ---------------------------------------

        --Create TempListDomainTable table and drop foreign key during first loop iteration 
        IF i = DomainTableList.COUNT THEN

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'TempListDomainTable';
            
            --Recreate the TempListDomainTable table
            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE TempListDomainTable (TableType VARCHAR(50),
                                                                ListDomainTableName VARCHAR(50),
                                                                ReferencedTableName VARCHAR(50),
                                                                ReferencedColumnName VARCHAR(50),
                                                                DomainCatalogId INT,
                                                                DomainDescr VARCHAR(255)
                                                                )';
                                            
                EXECUTE IMMEDIATE sql_stmt;
               
            END IF;

        END IF;

        -- Update entry in TempListDomainTable table
        IF (ColName IS NOT NULL) THEN
            SELECT COUNT(*) INTO CNT
            FROM TempListDomainTable
            WHERE ReferencedTableName = TabName
            AND ReferencedColumnName = ColName
            AND ListDomainTableName = NewTableName
            AND TableType = 'Real';

            IF CNT = 0 THEN
                INSERT INTO TempListDomainTable
                SELECT 'Real',
                        NewTableName,
                        TabName,
                        ColName,
                        DomainId,
                        Domain
                FROM DUAL;

            END IF;

        ELSE
            CNT := NULL;
            SELECT COUNT(*) INTO CNT
            FROM TempListDomainTable
            WHERE ListDomainTableName = NewTableName
            AND TableType = 'Real';

            IF CNT = 0 THEN
                INSERT INTO TempListDomainTable
                SELECT 'Real',
                        NewTableName,
                        NULL,
                        NULL, 
                        DomainId,
                        Domain
                FROM DUAL;

            END IF;

        END IF;

        COMMIT;

	--------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------

        IF FKTableName IS NOT NULL THEN
            SELECT COUNT(*) INTO CNT
            FROM user_constraints uc1
            JOIN user_constraints uc2
                ON uc1.r_constraint_name = uc2.constraint_name
            WHERE uc1.constraint_name = FKConstraintName
            AND uc2.table_name = 'ListDomain';

            IF CNT = 1 THEN
                sql_stmt := 'ALTER TABLE ' || FKTableName || ' DROP CONSTRAINT ' || FKConstraintName;
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

-------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_constraints
            WHERE constraint_name = FKConstraintName;

            IF CNT = 0 THEN
                sql_stmt := 'ALTER TABLE ' || FKTableName || ' ADD CONSTRAINT '
                            || FKConstraintName || ' FOREIGN KEY ('|| FKColumnName ||')'
                            || ' REFERENCES ' || NewTableName || ' (Id)' ;

                EXECUTE IMMEDIATE sql_stmt;
            END IF;
        END IF;

    END LOOP;

    /*************************************************************************************************
                        CREATE New Tables for CategoryDataListDomainXRef Table
    **************************************************************************************************/

    DECLARE
        NewTableName VARCHAR2(100);
        FKConstraintName VARCHAR2(100);
        FKTableName VARCHAR2(100);
        FKColumnName VARCHAR2(100);
        sql_stmt NVARCHAR2(20000);
        CNT INT;
        CatalogIdCount INT;
        IfExists INT;
        DomainId INT;
        ColName VARCHAR2(100);
        TabName VARCHAR2(100);
        Domain VARCHAR2(100);
        Constraint VARCHAR2(100);
        CategoryId INT;

        -- record variable
        TYPE list_record_type IS RECORD
        (CategoryId INT,
        NewTableName VARCHAR2(100)
        );

        -- table variables
        TYPE List_Table_Type IS TABLE OF list_record_type
        INDEX BY BINARY_INTEGER;

        NewDomainTableList List_Table_Type;

        CURSOR DropFK_Cursor IS
        SELECT uc1.constraint_name,
                uc1.table_name
        FROM user_constraints uc1
        JOIN user_constraints uc2
            ON uc1.r_constraint_name = uc2.constraint_name
        WHERE uc2.table_name IN ('Category', 'CategoryDataListDomainXRef');

    BEGIN

        WITH tmpQuery AS
        (SELECT ROW_NUMBER() OVER (PARTITION BY CategoryId ORDER BY CategoryId) row_num,
                ValueDomainId, 
                CategoryId, 
                CASE 
                        WHEN LENGTH(REGEXP_REPLACE(CategoryCode, ' |-|\.|/', '')) > 24
                            THEN 'LD_CD_' || SUBSTR(REGEXP_REPLACE(CategoryCode, ' |-|\.|/|\(|\)|,|>|<|\%|\@|\=|\&', ''), 1, 24) 
                        ELSE 'LD_CD_' || REGEXP_REPLACE(CategoryCode, ' |-|\.|/|\(|\)|,|>|<|\%|\@|\=|\&', '')
                    END AS new_table_name, 
                CategoryDescr 
        FROM CategoryDataListDomainXRef cdldx
        JOIN Category c
            ON c.Id = cdldx.CategoryId
        )
        SELECT CategoryId, new_table_name
        BULK COLLECT INTO NewDomainTableList
        FROM tmpQuery
        WHERE row_num = 1;

        FOR i IN 1..NewDomainTableList.COUNT LOOP
            NewTableName := NewDomainTableList(i).NewTableName;
            CategoryId := NewDomainTableList(i).CategoryId;

    --------------------------------------- CREATE New ListDomain tables ---------------------------------------

            SELECT COUNT(*) INTO CNT 
            FROM user_tables
            WHERE table_name = NewTableName;

            IF CNT = 0 THEN
                -- Create new list domain table
                sql_stmt := 'CREATE TABLE '|| NewTableName ||'
                            (Id NUMBER(10, 0) GENERATED BY DEFAULT AS IDENTITY,
                            CategoryCode VARCHAR2(60) NOT NULL,
                            CategoryDescr VARCHAR2(255) NOT NULL,
                            EffectiveEndDate TIMESTAMP,
                            CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                            CreatedDate TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
                            LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                            LastModDateTime TIMESTAMP DEFAULT CURRENT_DATE NOT NULL, 
                            CONSTRAINT PK_'|| NewTableName || ' PRIMARY KEY (Id)
                            )';

            EXECUTE IMMEDIATE sql_stmt;

            
                -- Create update/delete trigger on table
                sql_stmt := 'CREATE OR REPLACE TRIGGER tu_' || NewTableName || '
                            AFTER UPDATE OR DELETE
                            ON ' || NewTableName || '
                            FOR EACH ROW
                            BEGIN
                                UPDATE ' || NewTableName || ' 
                                    SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                        LastModDateTime = CURRENT_DATE;
                            END;';

                EXECUTE IMMEDIATE sql_stmt;
                
            END IF;
            
    ---------------------------------- Populate the New List Domain Table ----------------------------------

            sql_stmt := '
                        INSERT INTO ' || NewTableName || '(Id, CategoryCode, CategoryDescr)
                        SELECT DISTINCT ValueDomainId,
                            CategoryCode,
                            CategoryDescr
                        FROM CategoryDataListDomainXRef cdldx
                        JOIN Category c
                            ON c.Id = cdldx.CategoryId 
                        WHERE CategoryId = ' || CategoryId || '
                        AND ValueDomainId NOT IN (SELECT Id FROM ' || NewTableName || ')';

            EXECUTE IMMEDIATE sql_stmt;

    ------------------------------ UPDATE TempListDomainTable IN CONFIG DB ---------------------------------------

            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'TempListDomainTable';

            --Create the TempListDomainTable table if it does not exist
            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE TempListDomainTable (TableType VARCHAR(50),
                                                                ListDomainTableName VARCHAR(50),
                                                                ReferencedTableName VARCHAR(50),
                                                                ReferencedColumnName VARCHAR(50),
                                                                DomainCatalogId INT,
                                                                DomainDescr VARCHAR(255)
                                                                )';
                                            
                EXECUTE IMMEDIATE sql_stmt;
                
            END IF;

            -- Delete and re-insert entries for table and column in current loop iteration into TempListDomainTable
            SELECT COUNT(*) INTO CNT
            FROM TempListDomainTable
            WHERE ListDomainTablename = NewTableName
                AND TableType = 'Real';
            
            IF CNT = 0 THEN
                sql_stmt := 'INSERT INTO TempListDomainTable (TableType, 
                                                            ListDomainTableName, 
                                                            ReferencedTableName, 
                                                            ReferencedColumnName,
                                                            DomainCatalogId,
                                                            DomainDescr)
                            SELECT ''Real'',
                                    ''' || NewTableName || ''',
                                    NULL,
                                    NULL,
                                    (SELECT MAX(NVL(DomainCatalogId, 0)) + 1 FROM TempListDomainTable),
                                    (SELECT CategoryCode FROM Category WHERE Id = ' || CategoryId || ')
                                    FROM DUAL';
            
                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;

            END IF;

        END LOOP;

    --------------------------------- DROP CategoryDataListDomainXRef, and Category tables -------------------

        FOR rec IN DropFK_Cursor LOOP
            FKConstraintName := rec.constraint_name;
            FKTableName := rec.table_name;

            sql_stmt := 'ALTER TABLE ' || FKTablename || ' DROP CONSTRAINT ' || FKConstraintName ||'';

            EXECUTE IMMEDIATE sql_stmt;

        END LOOP;

        sql_stmt := 'DROP TABLE Category';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'DROP TABLE CategoryDataListDomainXRef';
        EXECUTE IMMEDIATE sql_stmt;

    END;


    /*****************************************************************************************
                    Modify RememberedListDomainValues and ActionItemPropDCXRef tables
    **********************************************************************************************/

    DECLARE
        sql_stmt VARCHAR2(20000);
        CNT INT;
        FKConstraintName VARCHAR2(100);

    BEGIN
    ----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------
        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE NOT EXISTS (SELECT * FROM user_tab_columns
        WHERE table_name = 'RememberedListDomainValues'
        AND column_name = 'ListDomainTableName')
        AND table_name = 'RememberedListDomainValues';

        IF CNT <> 0 THEN
            -- Delete temporary table if it already exists
            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE EXISTS (SELECT 1 FROM user_tables WHERE table_name = 'temp_RememberedListDomainValues')
            AND table_name = 'RememberedListDomainValues';

            IF CNT = 1 THEN
                sql_stmt := 'DROP TABLE temp_RememberedListDomainValues';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            --Copy contents of RememberedListDomainValues to a temporary table
            sql_stmt := 'CREATE TABLE temp_RememberedListDomainValues
                        AS
                        SELECT Id,
                                DomainValue,
                                ListDomainId,
                                (SELECT NewListDomainTable FROM NewDomainTableList
                                WHERE DomainCatalogId = rldv.DomainCatalogId AND rownum < 2) AS ListDomainTableName,
                                CreatedUser,
                                CreatedDate,
                                LastModByUserId,
                                LastModDateTime
                        FROM RememberedListDomainValues rldv';

            EXECUTE IMMEDIATE sql_stmt;

            SELECT COUNT(*) INTO CNT
            FROM user_constraints uc1
            JOIN user_constraints uc2
                ON uc1.r_constraint_name = uc2.constraint_name
            WHERE uc1.table_name = 'RememberedListDomainValues'
                AND uc2.table_name = 'ListDomain';

            --Drop constraint on RememberedListDomainValues table
            IF CNT <> 0 THEN

                SELECT uc1.constraint_name INTO FKConstraintName
                FROM user_constraints uc1
                JOIN user_constraints uc2
                    ON uc1.r_constraint_name = uc2.constraint_name
                WHERE uc1.table_name = 'RememberedListDomainValues'
                    AND uc2.table_name = 'ListDomain';

                sql_stmt := 'ALTER TABLE RememberedListDomainValues DROP CONSTRAINT ' || FKConstraintName;
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_constraints uc1
            JOIN user_constraints uc2
                ON uc1.r_constraint_name = uc2.constraint_name
            WHERE uc1.table_name = 'RememberedListDomainValues'
                AND uc2.table_name = 'DomainCatalog';

            --Drop constraint on RememberedListDomainValues table
            IF CNT <> 0 THEN
                SELECT uc1.constraint_name INTO FKConstraintName
                FROM user_constraints uc1
                JOIN user_constraints uc2
                    ON uc1.r_constraint_name = uc2.constraint_name
                WHERE uc1.table_name = 'RememberedListDomainValues'
                    AND uc2.table_name = 'DomainCatalog';

                sql_stmt := 'ALTER TABLE RememberedListDomainValues DROP CONSTRAINT ' || FKConstraintName;
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE EXISTS (SELECT 1 FROM user_tables WHERE table_name = 'RememberedListDomainValues')
            AND table_name = 'temp_RememberedListDomainValues';

            --Drop RememberedListDomainValues table
            IF CNT <> 0 THEN
                sql_stmt := 'DROP TABLE RememberedListDomainValues';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE table_name = 'RememberedListDomainValues';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE RememberedListDomainValues
                AS
                SELECT * FROM temp_RememberedListDomainValues';

                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY CreatedUser DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY LastModByUserId DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY CreatedDate DEFAULT CURRENT_DATE';
                EXECUTE IMMEDIATE sql_stmt;
                
                sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY LastModDateTime DEFAULT CURRENT_DATE';
                EXECUTE IMMEDIATE sql_stmt;
        
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_triggers
            WHERE trigger_name = 'tu_RememberedListDomainValues';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE OR REPLACE TRIGGER tu_RememberedListDomainValues
                                    AFTER UPDATE OR DELETE
                                    ON RememberedListDomainValues
                                    FOR EACH ROW
                                    BEGIN
                                        UPDATE RememberedListDomainValues
                                            SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                LastModDateTime = CURRENT_DATE;
                                    END;'; 

                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            -- Delete temporary table if it already exists
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE EXISTS (SELECT * FROM user_tab_columns
            WHERE table_name = 'RememberedListDomainValues'
            AND column_name = 'ListDomainTableName')
            AND table_name = 'temp_RememberedListDomainValues';

            IF CNT = 1 THEN
                sql_stmt := 'DROP TABLE temp_RememberedListDomainValues';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

        END IF;

    -------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE NOT EXISTS (SELECT * FROM user_tab_columns
        WHERE table_name = 'ActionItemPropDCXRef'
        AND column_name = 'ListDomainTableName')
        AND table_name = 'ActionItemPropDCXRef';

        IF CNT <> 0 THEN
            -- Delete temporary table if it already exists
            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE EXISTS (SELECT 1 FROM user_tables WHERE table_name = 'temp_ActionItemPropDCXRef')
            AND table_name = 'ActionItemPropDCXRef';

            IF CNT = 1 THEN
                sql_stmt := 'DROP TABLE temp_ActionItemPropDCXRef';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            --Copy contents of ActionItemPropDCXRef to a temporary table
            sql_stmt := 'CREATE TABLE temp_ActionItemPropDCXRef
            AS
            SELECT ActionItemPropertyId,
                    (SELECT ListDomainTablename FROM TempListDomainTable
                    WHERE DomainCatalogId = aip.DomainCatalogId AND rownum < 2) AS ListDomainTableName,
                    CreatedUser,
                    CreatedDate,
                    LastModByUserId,
                    LastModDateTime
            FROM ActionItemPropDCXRef aip';

            EXECUTE IMMEDIATE sql_stmt;

            SELECT COUNT(*) INTO CNT
            FROM user_constraints uc1
            JOIN user_constraints uc2
                ON uc1.r_constraint_name = uc2.constraint_name
            WHERE uc1.table_name = 'ActionItemPropDCXRef'
                AND uc2.table_name = 'DomainCatalog';

            --Drop constraint on RememberedListDomainValues table
            IF CNT <> 0 THEN

                SELECT uc1.constraint_name INTO FKConstraintName
                FROM user_constraints uc1
                JOIN user_constraints uc2
                    ON uc1.r_constraint_name = uc2.constraint_name
                WHERE uc1.table_name = 'ActionItemPropDCXRef'
                    AND uc2.table_name = 'DomainCatalog';

                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef DROP CONSTRAINT ' || FKConstraintName;
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE EXISTS (SELECT 1 FROM user_tables WHERE table_name = 'ActionItemPropDCXRef')
            AND table_name = 'temp_ActionItemPropDCXRef';

            --Drop RememberedListDomainValues table
            IF CNT <> 0 THEN
                sql_stmt := 'DROP TABLE ActionItemPropDCXRef';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE table_name = 'ActionItemPropDCXRef';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE TABLE ActionItemPropDCXRef
                AS
                SELECT * FROM temp_ActionItemPropDCXRef';

                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY CreatedUser DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY LastModByUserId DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'')';
                EXECUTE IMMEDIATE sql_stmt;

                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY CreatedDate DEFAULT CURRENT_DATE';
                EXECUTE IMMEDIATE sql_stmt;
                
                sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY LastModDateTime DEFAULT CURRENT_DATE';
                EXECUTE IMMEDIATE sql_stmt;
        
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM user_triggers
            WHERE trigger_name = 'tu_ActionItemPropDCXRef';

            IF CNT = 0 THEN
                sql_stmt := 'CREATE OR REPLACE TRIGGER tu_ActionItemPropDCXRef
                                    AFTER UPDATE OR DELETE
                                    ON ActionItemPropDCXRef
                                    FOR EACH ROW
                                    BEGIN
                                        UPDATE ActionItemPropDCXRef
                                            SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                LastModDateTime = CURRENT_DATE;
                                    END;'; 

                EXECUTE IMMEDIATE sql_stmt;
            END IF;

            -- Delete temporary table if it already exists
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE NOT EXISTS (SELECT * FROM user_tab_columns
            WHERE table_name = 'ActionItemPropDCXRef'
            AND column_name = 'ListDomainTableName')
            AND table_name = 'temp_ActionItemPropDCXRef';

            IF CNT = 1 THEN
                sql_stmt := 'DROP TABLE temp_ActionItemPropDCXRef';
                EXECUTE IMMEDIATE sql_stmt;
            END IF;


        END IF;

    END;


    /*********************************************************************************************
                                    DELETE OBSELETE TABLES 
    *********************************************************************************************/

    -- Delete ListDomain, DomainCatalog, DomainCatalogColXRef
    DECLARE
        List NVARCHAR2(20000);
        sql_stmt NVARCHAR2(20000);

        TYPE Constraint_Record_Type IS RECORD
        (fk_table NVARCHAR2(100),
        constraint_name NVARCHAR2(100));

        TYPE Constraint_Table_Type IS TABLE OF Constraint_Record_Type
        INDEX BY BINARY_INTEGER;

        ConstraintList Constraint_Table_Type;

        TYPE List_Table_Type IS TABLE OF NVARCHAR2(100)
            INDEX BY BINARY_INTEGER;

        TableList List_Table_Type;
    
    BEGIN
        List :=  q'[ListDomain
                    DomainCatalog
                    DomainCatalogColXRef
                    NewDomainTableList]';
    -- Turn string list of tables into a format to be used in an sql query
        List := '''' || REPLACE(UPPER(List), ' ', '');
        List := REPLACE(List, CHR(10), ''', ''') || '''';

        -- Get the list of tables within 'List' variable that exist in the database
        sql_stmt := 'SELECT table_name FROM all_tables
                    WHERE table_name IN (' || List || ')';

        -- store table list in table variable
        EXECUTE IMMEDIATE sql_stmt
        BULK COLLECT INTO TableList;

        -- Loop through and delete each table in TableList
        FOR i IN 1..TableList.COUNT LOOP
            
            -- Generate a list of all foreign key constraints on current table that is to be deleted
            sql_stmt := 'SELECT DISTINCT uc.table_name, uc.constraint_name 
                        FROM user_constraints uc
                        JOIN user_cons_columns ucc
                            ON uc.r_constraint_name = ucc.constraint_name
                        WHERE uc.constraint_type = ''R''
                            AND ucc.table_name = ''' || TableList(i) || ''' COLLATE BINARY_CI';
            
            EXECUTE IMMEDIATE sql_stmt
            BULK COLLECT INTO ConstraintList;

            -- Deletes all foreign keys referencing the table in current loop iteration
            FOR j IN 1..ConstraintList.COUNT LOOP

                sql_stmt := 'ALTER TABLE ' || ConstraintList(j).fk_table || ' DROP CONSTRAINT '
                            || ConstraintList(j).constraint_name ;

            EXECUTE IMMEDIATE sql_stmt;

            END LOOP;

            -- Delete the table in the current loop iteration
            sql_stmt := 'DROP TABLE ' || TableList(i);
            EXECUTE IMMEDIATE sql_stmt;

        END LOOP;

    END;


EXCEPTION
    WHEN Too_Many_DomainId_1 THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ERROR**: More then 1 distinct DomainCatalogId was found in the '
        || 'ListDomain table for column ''' || ColName || ''' of table ''' 
        || TabName || '''. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is ' ||
        ' required for the script to continue.');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'The query below shows all ' ||
        'the ListDomain table entries for the table-column combination mentioned.');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || CHR(10) || 'QUERY: SELECT Id, DomainCatalogId, Code, Descr'
        || CHR(10) || CHR(9) || 'FROM ListDomain');
        DBMS_OUTPUT.PUT_LINE(CHR(9) || 'WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ');');
        
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SOLUTION: An entry was found in the DomainCatalogColXRef table. ' ||
        'Replace the values in the column ''' || ColName || ''' of table ''' || TabName || ' with Ids from ' 
        || ' from the ListDomain table that have the appropriate Code, Descr, and DomainCatalogId of '
        || DomainId );
   
    WHEN Too_Many_DomainId_2 THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ERROR**: More than 1 distinct DomainCatalogId was found '
        || ' in the ListDomain table for column ''' || ColName || ''' of table ''' || TabName || '''.'
        || 'ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
        || ' The query below shows all the ListDomain table entries for the table-column combination mentioned');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'QUERY: SELECT Id, DomainCatalogId, Code, Descr'
        || CHR(10) || CHR(9) || 'FROM ListDomain');
        DBMS_OUTPUT.PUT_LINE(CHR(9) || 'WHERE Id IN (SELECT ' || ColName || ' FROM ' || TabName || ');');

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SOLUTION: A reference could not be found in the DomainCatalogColXRef table for '
        || 'column ''' || ColName || ''' of table ''' || TabName || '''. Talk to the BA assigned to the client '
        || 'for this database. You may need to set some values in the ' || ColName || ''' column of the ''' 
        || TabName || ''' table to NULL');

END;
/

