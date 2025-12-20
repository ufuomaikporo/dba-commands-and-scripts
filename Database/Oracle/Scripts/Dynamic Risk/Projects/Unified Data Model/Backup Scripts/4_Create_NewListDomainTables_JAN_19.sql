ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

----------------------- Create NewDomainTableList table & Validate ListDomain Data -----------------

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
                    THEN ''LD_'' || SUBSTR(REGEXP_REPLACE(DomainDescr, '' |-|_|\&'', ''''), 1, 27) 
                ELSE ''LD_'' || REGEXP_REPLACE(DomainDescr, '' |-|_|\&'', '''') 
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
        AND uc.table_name NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'')';

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


    CURSOR NewDomainTableList_Cursor IS
    SELECT * FROM NewDomainTableList
    WHERE NewListDomainTable IS NULL;

BEGIN

    --Populate table variable
    SELECT * 
    BULK COLLECT INTO DomainTableList
    FROM NewDomainTableList;
--     WHERE FKTableName IN ('POECOATINGPROPERTY', 'COATING')
-- OR FkColumnName LIKE 'FIELD_2_DOMAINID%';
    
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

        --DBMS_OUTPUT.PUT_LINE('BEFORE'||' '||Tabname||' '||ColName||' '||NewTablename);

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

                    --DBMS_OUTPUT.PUT_LINE('CASE 1'||' '||Tabname||' '||ColName||' '||NewTablename);

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

                --DBMS_OUTPUT.PUT_LINE('CASE 2'||' '||Tabname||' '||ColName||' '||NewTablename);

            -- Use the 'Coordinate System' DomainCatalog Id, Descr and tablename for columns with 'CoordSys' in the name
            ELSIF (DomainId IS NULL AND ColName LIKE '%CoordSys%') THEN
            SELECT DomainCatalogId, DomainDescr, NewListDomainTable
            INTO DomainId, Domain, NewTableName
            FROM NewDomainTableList
            WHERE DomainDescr = 'Coordinate System'
                AND FKTableName IS NULL;

                    --DBMS_OUTPUT.PUT_LINE('CASE 3'||' '||Tabname||' '||ColName||' '||NewTablename);

            -- Make the IRASCustomData easier to distinguish by adding the table name
            ELSIF (TabName LIKE 'IRASCustomData%' AND DomainId IS NULL) THEN
                NewTableName := 'LD_' || TabName || REGEXP_REPLACE(ColName, '_DomainId', '');

                        --DBMS_OUTPUT.PUT_LINE('CASE 4'||' '||Tabname||' '||ColName||' '||NewTablename);

            -- For rows with null DomainCatalogId match Column names with DomainDescr in DomainCatalog table by removing 'DomainId'/'LD' suffix
            ELSIF (ColName LIKE '%DomainId' OR ColName LIKE '%Ld') THEN
                
                    --DBMS_OUTPUT.PUT_LINE('CASE 5'||' '||Tabname||' '||ColName||' '||NewTablename);

                SELECT COUNT(*) INTO CNT
                FROM NewDomainTableList 
                WHERE REGEXP_REPLACE(ColName, 'DomainId', '') 
                    IN (SELECT REGEXP_REPLACE(DomainDescr, ' |\d', '') FROM DomainCatalog)
                OR REGEXP_REPLACE(ColName, 'Ld', '') 
                    IN (SELECT REGEXP_REPLACE(DomainDescr, ' |\d', '') FROM DomainCatalog);

                IF (CNT <> 0) THEN
                    SELECT NewListDomainTable, 
                           DomainCatalogId, 
                           DomainDescr
                    INTO NewTableName, DomainId, Domain
                    FROM NewDomainTableList 
                    WHERE (REGEXP_REPLACE(ColName, 'DomainId', '') 
                        IN (SELECT REGEXP_REPLACE(DomainDescr, ' |\d', '') FROM DomainCatalog)
                    OR REGEXP_REPLACE(ColName, 'Ld', '') 
                        IN (SELECT REGEXP_REPLACE(DomainDescr, ' |\d', '') FROM DomainCatalog))
                        AND FKColumnName = ColName;

                -- Use the Column name as the new list domain table name if the column name cannot be matched to DomainDescr in DomainCatalog  
                ELSE
                    NewTableName := 'LD_' || REGEXP_REPLACE(ColName, 'DomainId|Ld', '');  

                        --DBMS_OUTPUT.PUT_LINE('CASE 7'||' '||Tabname||' '||ColName||' '||NewTablename);


                END IF; 
            -- If all-else fails use the column name as the new list domain table name
            ELSIF (Colname IS NOT NULL) THEN
                    NewTableName := 'LD_' || REGEXP_REPLACE(ColName, 'DomainId|Ld', '');      
                                      
                    --DBMS_OUTPUT.PUT_LINE('CASE 7'||' '||Tabname||' '||ColName||' '||NewTablename);

            END  IF;
        END IF;

        UPDATE NewDomainTableList
        SET NewListDomainTable = NewTableName,
            DomainCatalogId = DomainId,
            DomainDescr = Domain
            WHERE FKTableName = TabName
                AND FKColumnName = ColName;

       COMMIT;


        -- Set the name for the new list domain table
        -- SELECT NewListDomainTable
        -- INTO NewTableName 
        -- FROM NewDomainTableList
        -- WHERE FKTableName = TabName
        --     AND FKColumnName = ColName;

-------------------------------------- CREATE New ListDomain tables ---------------------------------------

--         SELECT COUNT(*) INTO CNT
--         FROM user_tables
--         WHERE table_name = NewTableName;

--         IF CNT = 0 THEN
--             sql_stmt := 'CREATE TABLE '|| NewTableName ||'
--                         (Id NUMBER(10, 0) GENERATED BY DEFAULT AS IDENTITY,
--                         Code VARCHAR2(60) NOT NULL,
--                         Descr VARCHAR2(255) NOT NULL,
--                         EffectiveEndDate TIMESTAMP,
--                         CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
--                         CreatedDate TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
--                         LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
--                         LastModDateTime TIMESTAMP DEFAULT CURRENT_DATE NOT NULL, 
--                         CONSTRAINT PK_'|| NewTableName || ' PRIMARY KEY (Id)
--                         )';

--            EXECUTE IMMEDIATE sql_stmt;

--             exit;
--         END IF;

--         -- Create update/delete trigger on table
--         sql_stmt := 'CREATE OR REPLACE TRIGGER tu_' || NewTableName || '
--                     AFTER UPDATE OR DELETE
--                     ON ' || NewTableName || '
--                     FOR EACH ROW
--                     BEGIN
--                         UPDATE ' || NewTableName || ' 
--                             SET LastModByUserId = SYS_CONTEXT(''USERENV'', ''OS_USER''),
--                                 LastModDateTime = CURRENT_DATE;
--                     END;';

--         EXECUTE IMMEDIATE sql_stmt;

-- -------------------------------- Populate the New List Domain Table ----------------------------------

--         IF (ColName IS NOT NULL) THEN
--             sql_stmt := 'INSERT INTO ' || NewTableName || ' (Id, Code, Descr, EffectiveEndDate)
--                         WITH tmpQuery AS
--                         (SELECT Id,
--                             DomainCatalogId,
--                             Code,
--                             Descr
--                         FROM ListDomain
--                         WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName || ')
--                         UNION
--                         SELECT Id,
--                                 DomainCatalogId,
--                                 Code,
--                                 Descr
--                         FROM ListDomain WHERE DomainCatalogId = ' || DomainId || '
--                         )
--                         SELECT Id,
--                             CASE 
--                                 WHEN Code = '''' THEN ''<None>''
--                                 ELSE Code
--                                 END AS Code,
--                             CASE 
--                                 WHEN Code = '''' THEN ''<None>''
--                                 ELSE Descr
--                                 END AS Descr,
--                             CASE 
--                                     WHEN DomainCatalogId = -1 THEN CURRENT_DATE
--                                     ELSE NULL
--                                 END AS EffectiveEndDate
--                         FROM tmpQuery
--                         WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
--                         ORDER BY 1';

--             EXECUTE IMMEDIATE sql_stmt;
--             --DBMS_OUTPUT.PUT_LINE(sql_stmt);

--             COMMIT;
--         END IF;

---------------------------- UPDATE TempListDomainTable IN CONFIG DB ---------------------------------------

        -- Create TempListDomainTable table and drop foreign key during first loop iteration 
        -- IF i = DomainTableList.COUNT THEN

        --     SELECT COUNT(*) INTO CNT
        --     FROM user_tables
        --     WHERE table_name = 'TempListDomainTable';
            
        --     --Recreate the TempListDomainTable table
        --     IF CNT = 0 THEN
        --         sql_stmt := 'CREATE TABLE TempListDomainTable (TableType VARCHAR(50),
        --                                                         ListDomainTableName VARCHAR(50),
        --                                                         ReferencedTableName VARCHAR(50),
        --                                                         ReferencedColumnName VARCHAR(50),
        --                                                         DomainCatalogId INT,
        --                                                         DomainDescr VARCHAR(255)
        --                                                         )';
                                            
        --         EXECUTE IMMEDIATE sql_stmt;
               
        --     END IF;

        --     SELECT COUNT(*) INTO CNT
        --     FROM TempListDomainTable
        --     WHERE ReferencedTableName = TabName
        --         AND ReferencedColumnName = ColName
        --         AND TableType = 'Real';

        --     MERGE INTO TempListDomainTable s1
        --     USING (SELECT 'Real' Type,
        --               NewListDomainTable,
        --               FKTableName,
        --               FKColumnName,
        --               DomainCatalogId,
        --               DomainDescr
        --      FROM NewDomainTableList
        --      WHERE FKColumnName = ColName
        --         AND FKTableName = TabName) s2
        --     ON (s1.ReferencedColumnName = s2.FKColumnName
        --         AND ReferencedTableName = s2.FKTableName)
        --     WHEN MATCHED THEN UPDATE
        --     SET s1.ListDomainTableName = s2.NewListDomainTable,
        --         s1.DomainCatalogId = s2.DomainCatalogId,
        --         s1.DomainDescr = s2.DomainDescr
        --     WHEN NOT MATCHED THEN INSERT
        --     VALUES(s2.Type, s2.NewListDomainTable, s2.FKTableName, s2.FKColumnName, s2.DomainCatalogId, s2.DomainDescr);
            
        --     COMMIT;

        -- END IF;


    END LOOP;


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
        'Replace the values in the column ''' || ColName || ''' of table ''' || TabName || 'with Ids from ' 
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

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SOLUTION: A reference could not be found in the DomainCatalogColXRef table for'
        || 'column ''' || ColName || ''' of table ''' || TabName || '''. Talk to the BA assigned to the client '
        || 'for this database. You may need to set some values in the ' || ColName || ''' column of the ''' 
        || TabName || ''' table to NULL');

END;
/



