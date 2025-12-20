ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE
    NewTableName NVARCHAR2(100);
    VColumnId INT;
    VTableId INT;
    VTableName NVARCHAR2(100);
    VColumnName NVARCHAR2(100);
    sql_stmt NVARCHAR2(20000);
    CNT INT;
    DomainId INT;

    Too_Many_DomainId EXCEPTION;

    -- record variable
    TYPE list_record_type IS RECORD
    (VirtualColumnId INT,
     VirtualColumnName VARCHAR2(50),
     VirtualTableId INT,
     VirtualTableName VARCHAR2(50)
    );

    -- table variables
    TYPE List_Table_Type IS TABLE OF list_record_type
    INDEX BY BINARY_INTEGER;

    NewDomainTableList List_Table_Type;

BEGIN

    --Populate NewDomainTableList table
    SELECT DISTINCT vc.Id AS VirtualColumnId,
    vc.VirtualColumnName,
    vc.VirtualTableId,
    vt.VirtualTableName
    BULK COLLECT INTO NewDomainTableList
    FROM VirtualColumn vc
    JOIN VirtualTable vt
        ON vt.Id = vc.VirtualTableId
    WHERE VirtualColumnDataTypeInd = 'L';

-- ------------------------------ Cursor to Create new list domain virtual tables -------------------------------

    FOR i IN 1..NewDomainTableList.COUNT LOOP

        VTableId := NewDomainTableList(i).VirtualTableId;
        VTableName := NewDomainTableList(i).VirtualTableName;
        VColumnId := NewDomainTableList(i).VirtualColumnId;
        VColumnName := NewDomainTableList(i).VirtualColumnName;
        NewTableName := NULL;
        DomainId := NULL;
        
        SELECT COUNT(*) INTO CNT
        FROM DomainCatalogColXRef
        WHERE TableName = VTableName
        AND ColumnName = VColumnName;

        /* If there is an entry in the DomainCatalogColXRef table for the virtual table and column 
         use the Domain name to form the new list domain table name
        */
        IF CNT <> 0 THEN
            -- Retrieve DomainCatalogId for the virtual table and column from DomainCatalogColXRef table if it exists
            SELECT DomainCatalogId
            INTO DomainId
            FROM DomainCatalogColXRef
            WHERE TableName = VTableName
            AND ColumnName = VColumnName;

            -- Us the DomainDescr to name the new listdomain table
            SELECT REGEXP_REPLACE(DomainDescr, ' |-|_|\&|,|\.', '') 
            INTO NewTableName
            FROM DomainCatalog
            WHERE Id = DomainId;

        ELSE
            DomainId := NULL;
        END IF;
            
        -- Check if the Virtual table and column has an entry in the ListDomain table with a unique DomainCatalogId
        SELECT COUNT(DISTINCT DomainCatalogId) 
        INTO CNT 
        FROM ListDomain
        WHERE Id IN (SELECT DataFieldValueDomainId 
                    FROM VirtualTableDataListDomain
                    WHERE VirtualTableId = VTableId
                    AND VirtualColumnId = VColumnId)
        AND DomainCatalogId <> -1;
          
        /*
        If the Virtual table and column does not have an entry in the DomainCatalogColXRef table but has has an entry in the
        ListDomain table, check to see and raise an error if there are more than one unique DomainCatalogId for entries
        in the ListDomain table
        */
        IF CNT > 1 AND DomainId IS NULL THEN
            RAISE Too_Many_DomainId;
        /*
            if the virtual table and column has an entry in the ListDomain table But not in the DomainCatalogColXRef table
            use the DomainCatalogId from the ListDomain table entries to find the DomainDescr. This will be the new table name
        */
        ELSIF CNT = 1 AND DomainId IS NULL THEN

            SELECT DomainCatalogId INTO DomainId
            FROM ListDomain
            WHERE Id IN (SELECT DataFieldValueDomainId 
                        FROM VirtualTableDataListDomain
                        WHERE VirtualTableId = VTableId
                        AND VirtualColumnId = VColumnId)
            AND DomainCatalogId <> -1
            AND rownum < 2;

            SELECT REGEXP_REPLACE(DomainDescr, ' |-|_|\&|,|\.', '') INTO NewTableName
            FROM DomainCatalog
            WHERE Id = DomainId;

        --  Otherwise generate a new list domain table name based on the virtual column name
        ELSIF DomainId IS NULL THEN
            NewTableName := REGEXP_REPLACE(VColumnName, 'DomainId|Ld|LD', '');
        END IF;

        -- Add 'LD' to the end of the new table name and modify it if it is longer then 30 characters
        IF (LENGTH(NewTableName) > 28) THEN
            NewTableName := 'LD_' || SUBSTR(NewTableName, 1, 28);
        ELSE
            NewTableName := 'LD_' || NewTableName ;
        END IF;

-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------

        SELECT COUNT(*) INTO CNT 
        FROM user_tables
        WHERE table_name = NewTableName;

        IF CNT = 0 THEN
            -- Create new list domain table
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
        
-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------

        sql_stmt := '
        DECLARE
            CNT INT;
            sql_stmt VARCHAR2(20000);
        BEGIN

            SELECT COUNT(*) INTO CNT
            FROM user_tables 
            WHERE table_name = UPPER(''ListDomainInfo'');

            SELECT COUNT(*) INTO CNT
            FROM ' || NewTableName || ';
          
            IF (CNT = 0) THEN
                

                INSERT INTO ' || NewTableName || '
                (Id,
                Code,
                Descr,
                EffectiveEndDate)
                SELECT Id,
                       CASE
                        WHEN Code = '''' THEN ''None''
                        ELSE Code
                       END AS Code,
                       CASE
                        WHEN Code = '''' THEN ''None''
                        ELSE Descr
                       END As Descr,
                       CASE
                        WHEN DomainCatalogId = -1 THEN CURRENT_DATE
                        ELSE NULL
                      END AS EffectiveEndDate
                FROM ListDomain 
                WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId
                             FROM VirtualTableDataListDomain
                             WHERE VirtualTableId = ' || VTableId ||'
                             AND VirtualColumnId = ' || VColumnId || '
                            )
                AND Id NOT IN (SELECT Id FROM ' || NewTableName || ');
                 
            END IF;

            COMMIT;

        END;';

        EXECUTE IMMEDIATE sql_stmt;       

------------------------- Create and update the TempListDomainTable table in Config database ----------------

        -- Create TempListDomainTable table and drop foreign key during first loop iteration 
        IF i = 1 THEN

            --Drop the TempListDomainTable table if it exists
            SELECT COUNT(*) INTO CNT
            FROM user_tables
            WHERE table_name = 'TempListDomainTable';

            IF CNT = 1 THEN
                EXECUTE IMMEDIATE 'DROP TABLE TempListDomainTable';
            END IF;

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

            SELECT COUNT(*) INTO CNT
            FROM user_constraints  uc
            LEFT JOIN user_cons_columns ucc
                ON uc.r_constraint_name = ucc.constraint_name
            WHERE uc.constraint_type = 'R'
            AND ucc.table_name = 'ListDomain'
            AND ucc.column_name = 'Id'
            AND uc.table_name = 'VirtualTableDataListDomain';

            --Drop foreign key on VirtualTableDataListDomain referencing ListDomain table
            IF CNT = 1 THEN
                SELECT 'ALTER TABLE VirtualTableDataListDomain DROP CONSTRAINT ' || uc.constraint_name
                INTO sql_stmt
                FROM user_constraints  uc
                LEFT JOIN user_cons_columns ucc
                    ON uc.r_constraint_name = ucc.constraint_name
                WHERE uc.constraint_type = 'R'
                AND ucc.table_name = 'ListDomain'
                AND ucc.column_name = 'Id'
                AND uc.table_name = 'VirtualTableDataListDomain';

                EXECUTE IMMEDIATE sql_stmt;
            END IF;

        END IF;
        
        --Insert VirtualTable info into TempListDomainTable table
        sql_stmt := '
        DECLARE
            CNT INT;
        BEGIN
                    SELECT COUNT(*) INTO CNT
                    FROM TempListDomainTable
                    WHERE ReferencedTableName = ''' || VTableName || '''
                    AND ReferencedColumnName = ''' || VColumnName || ''';

                IF CNT = 0 THEN
                
                    INSERT INTO TempListDomainTable
                    VALUES(''Virtual'',
                            ''' || NewTableName || ''',
                            ''' || VTableName || ''',
                            ''' || VColumnName || ''',
                            ''' || DomainId || ''',
                            (SELECT DomainDescr FROM DomainCatalog WHERE Id = ''' || DomainId || '''));
                END IF;

                COMMIT;
        END;';

        EXECUTE IMMEDIATE sql_stmt;

-------------------------------- Drop Foreign key and UPDATE VirtualTableDataListDomain table ------------------------------------------------

    END LOOP;
    
EXCEPTION
    WHEN Too_Many_DomainId THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) ||'Error: There is are more than 1 domain category listed in ListDomain table for the '
                         || VTableName || ' virtual table and ' || VColumnName 
                         || ' virtual column. Insert the correct DomainCatalogId into the DomainCatalogColXRef table for this table-column combination for the script to continue.');
    
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/
