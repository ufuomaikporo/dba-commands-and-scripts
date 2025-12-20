ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

--------------------- Create NewDomainTableList table & Validate ListDomain Data -----------------

DECLARE
    NewTableName VARCHAR2(100);
    ConstraintName VARCHAR2(100);
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

    sql_stmt := 'CREATE TABLE NewDomainTableList
                (Id INT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
                FKConstraint VARCHAR2(100),
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
    AND uc.table_name NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
    ';

    EXECUTE IMMEDIATE sql_stmt;

    -- Tables that are missing a foreign key reference to the ListDomain table
    sql_stmt := '
    BEGIN
        INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
        VALUES (''FK_POECompLookup_MetalLossTypeDomain'', ''POECompanyLookUp'', ''MetalLossTypeDomainId'');

        INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
        VALUES (''FK_POECompLookup_ToolTypeDomain'', ''POECompanyLookUp'', ''ToolTypeDomainId'');

        INSERT INTO NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
        VALUES (''FK_StgILICA_ILICADepthDomain'', ''Stg_ILICrackAnomaly'', ''ILICADepthDomainId'');
    END;';

    EXECUTE IMMEDIATE sql_stmt;


    -- LD tables that will not have a foreign key referencing them but are necessary for App function
    sql_stmt := 'INSERT INTO NewDomainTableList (DomainDescr, DomainCatalogId, NewListDomainTable)
            SELECT DISTINCT dc.DomainDescr, 
                            dc.Id,
                            ldi."LDTableName"
            FROM dbo.ListDomainTableInfo@SQL2019 ldi
            JOIN DomainCatalog dc
                ON ldi."DomainDescr" = dc.DomainDescr
            WHERE NOT EXISTS (SELECT * FROM NewDomainTableList WHERE DomainCatalogId = dc.Id)';

    EXECUTE IMMEDIATE sql_stmt;


    sql_stmt := '
    BEGIN
        -- Get the new ListDomain table name from SQL2019.DrasInternal.dbo.ListDomainTableInfo (match tableName and columnName)
        UPDATE NewDomainTableList tab1
        SET NewListDomainTable = (SELECT DISTINCT tab2."LDTableName" 
                                    FROM dbo.ListDomainTableInfo@SQL2019 tab2
                                    WHERE tab1.FKColumnName = tab2."ColumnName"
                                    AND tab1.FKTableName = tab2."TableName"
                                    AND rownum < 2)
        WHERE EXISTS (SELECT 1 FROM dbo.ListDomainTableInfo@SQL2019 tab2
                        WHERE tab1.FKColumnName = tab2."ColumnName"
                        AND tab1.FKTableName = tab2."TableName");

        -- Get the new ListDomain table name from SQL2019.DrasInternal.dbo.ListDomainTableInfo (match only column name if there are no tablename matches)
        UPDATE NewDomainTableList tab1
        SET NewListDomainTable = (SELECT DISTINCT tab2."LDTableName"
                                    FROM dbo.ListDomainTableInfo@SQL2019 tab2
                                    WHERE tab1.FKColumnName = tab2."ColumnName")
        WHERE EXISTS (SELECT 1 FROM dbo.ListDomainTableInfo@SQL2019 tab2
                        WHERE tab1.FKColumnName = tab2."ColumnName")
        AND NewListDomainTable IS NULL;
            
        --Generate an LD table name for tables that could not be matched with an LD table name in the SQL2019.DrasInternal.dbo.ListDomainTableInfo table
        UPDATE NewDomainTableList tab1
        SET NewListDomainTable = (SELECT CASE 
                                            WHEN FKTableName LIKE ''IRASCustom%''
                                                THEN ''LD_'' || FKTableName || ''_'' || REPLACE(FKColumnName, ''_DomainId'', '''')
                                            WHEN INSTR(FKColumnName, ''DomainId'') > 0
                                                THEN ''LD_'' || REPLACE(REPLACE(FKColumnName, ''_DomainId'', ''''), ''DomainId'', '''') 
                                            WHEN INSTR(FKColumnName, ''Ld'') > 0
                                                THEN ''LD_'' || REPLACE(FKColumnName, ''Ld'', '''')
                                            ELSE ''LD_'' || FKColumnName
                                        END
                                FROM NewDomainTableList tab2
                                WHERE tab1.FKTableName = tab2.FKTableName
                                AND tab1.FKColumnName = tab2.FKColumnName)
        WHERE EXISTS (SELECT 1 FROM NewDomainTableList tab2
                        WHERE tab1.FKTableName = tab2.FKTableName
                        AND tab1.FKColumnName = tab2.FKColumnName)
        AND NewListDomainTable IS NULL;
    END;';

    EXECUTE IMMEDIATE sql_stmt;

                          
    -- Update the DomainCatalogId and DomainDescr columns using the DomainCataogColXRef table
    sql_stmt := 'UPDATE NewDomainTableList nldt
                SET (DomainCatalogId, DomainDescr) = (SELECT dccxr.DomainCatalogId, dc.DomainDescr
                                                        FROM DomainCatalogColXRef dccxr
                                                        JOIN DomainCatalog dc
                                                        ON dc.Id = dccxr.DomainCatalogId
                                                        WHERE dccxr.TableName = nldt.FKTableName
                                                        AND dccxr.ColumnName = nldt.FKColumnName
                                                    )
                WHERE EXISTS (SELECT 1 FROM DomainCatalogColXRef dccxr
                            WHERE dccxr.TableName = nldt.FKTableName
                            AND dccxr.ColumnName = nldt.FKColumnName)';
                                          
    EXECUTE IMMEDIATE sql_stmt;

    COMMIT;
END; 
/


DECLARE
   NewTableName VARCHAR2(100);
   ConstraintName VARCHAR2(100);
   sql_stmt VARCHAR2(20000);
   sql_stmt2 VARCHAR2(20000);
   CNT INT;
   CatalogIdCount INT;
   DomainId INT;
   Domain VARCHAR2(100);
   ColName VARCHAR2(100);
   TabName VARCHAR2(100);

   --User defined errors
   Too_Many_DomainId_1 EXCEPTION;
   Too_Many_DomainId_2 EXCEPTION;

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
   SELECT FKConstraint, 
          FKTableName, 
          FKColumnName, 
          NewListDomainTable, 
          DomainCatalogId, 
          DomainDescr
   BULK COLLECT INTO DomainTableList
   FROM NewDomainTableList;

    sql_stmt := 'SELECT COUNT(*) FROM NewDomainTableList';
    EXECUTE IMMEDIATE sql_stmt INTO CNT;

    IF CNT <= 3 THEN
        DBMS_OUTPUT.PUT_LINE('Missing or too few entries in table "NewDomainTableList". Restore the Database and retry the upgrade');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef');

    IF CNT <> 3 THEN
        DBMS_OUTPUT.PUT_LINE('One of the ListDomain, DomainCatalog or DomainCatalogColXRef tables are missing.');
        RETURN;
    END IF;

    FOR i IN 1..DomainTableList.COUNT LOOP

------------------------------- VALIDATE LISTDOMAIN DATA --------------------------------

       CatalogIdCount := NULL;
  
       ColName := DomainTableList(i).FKColumnName;
       Tabname := DomainTableList(i).FKTableName;
       DomainId := DomainTableList(i).DomainCatalogId;
       Domain := DomainTableList(i).DomainDescr;
       NewTableName := DomainTableList(i).NewTableName;
       ConstraintName := DomainTableList(i).FKConstraint;

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
       IF (CatalogIdCount > 1 AND Domainid IS NOT NULL ) THEN
           RAISE Too_Many_DomainId_1;
       /*
           if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
           table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
           then throw an error to force user to manually fix the issue
       */
       ELSIF (DomainId IS NULL AND CatalogIdCount > 1) THEN
           RAISE Too_Many_DomainId_2; 
       /*
           If the table and column in the current loop has no entry in the DomainCatalogColXRef table
           and has entries in the ListDomain table with a single distinct DomainCatalogId other than -1,
           then use the DomainCatalogId from the ListDomain table.
       */	
       ELSIF (DomainId IS NULL AND CatalogIdCount = 1) THEN             

           sql_stmt := 'SELECT DISTINCT DomainCatalogId 
                       FROM ListDomain
                       WHERE Id IN (SELECT DISTINCT ' || ColName || ' FROM ' || TabName ||' )
                           AND DomainCatalogId <> -1';
                           
           EXECUTE IMMEDIATE sql_stmt INTO DomainId;
       END IF;
       

       sql_stmt := 'UPDATE NewDomainTableList
       SET DomainCatalogId = ''' ||DomainId || ''',
           DomainDescr = (SELECT DomainDescr FROM DomainCatalog WHERE Id = '''||DomainId||''')
       WHERE FKTableName = '''|| TabName || '''
       AND FKColumnName = '''||ColName || '''
       AND DomainDescr IS NULL';

       EXECUTE IMMEDIATE sql_stmt;

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
                       CreatedDate TIMESTAMP DEFAULT SYSDATE NOT NULL,
                       LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER'') NOT NULL,
                       LastModDateTime TIMESTAMP DEFAULT SYSDATE NOT NULL, 
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
                               LastModDateTime = SYSDATE;
                   END;';

       EXECUTE IMMEDIATE sql_stmt;

-------------------------------- Populate the New List Domain Table ----------------------------------

       IF (ColName IS NOT NULL) THEN
           sql_stmt := 'SELECT COUNT(*) FROM ListDomain WHERE Id IN (SELECT DISTINCT '|| ColName || ' FROM '|| TabName || ') ';

           EXECUTE IMMEDIATE sql_stmt INTO CNT;
       END IF;

       -- If a table-column pair an entry in the ListDomain table, populate using ListDomain data
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
                                   WHEN DomainCatalogId = -1 THEN SYSDATE
                                   ELSE NULL
                               END AS EffectiveEndDate
                       FROM tmpQuery
                       WHERE Id NOT IN (SELECT Id FROM ' || NewTableName || ')
                       ORDER BY 1';

          EXECUTE IMMEDIATE sql_stmt;
          
       -- If the Table and Column are null but DomainId is not null, then populate using DomainCatalogId from ListDomain table
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

------------------------------ UPDATE TempListDomainTable ---------------------------------------

       --Create TempListDomainTable table and drop foreign key during first loop iteration 
       SELECT COUNT(*) INTO CNT
       FROM user_tables
       WHERE table_name = 'TempListDomainTable';
       
       --Create the TempListDomainTable table f it does not already exist
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

       -- Update entry in TempListDomainTable table
       sql_stmt := '
       DECLARE 
           CNT INT;
       BEGIN
       IF ('''||ColName||''' IS NOT NULL) THEN
           SELECT COUNT(*) INTO CNT
           FROM TempListDomainTable
           WHERE ReferencedTableName = '''|| TabName ||'''
           AND ReferencedColumnName = '''|| ColName ||'''
           AND ListDomainTableName = '''|| NewTableName ||'''
           AND TableType = ''Real'';

           IF CNT = 0 THEN

               DELETE FROM TempListDomainTable 
               WHERE ReferencedTableName = '''|| TabName ||'''
               AND ReferencedColumnName = '''|| ColName ||''';

               INSERT INTO TempListDomainTable
               SELECT ''Real'',
                   '''|| NewTableName ||''',
                   '''|| TabName ||''',
                   '''|| ColName ||''',
                   '''|| DomainId ||''',
                   '''|| Domain ||'''
               FROM DUAL;


           END IF;

           
       ELSE
           CNT := NULL;
           SELECT COUNT(*) INTO CNT
           FROM TempListDomainTable
           WHERE ListDomainTableName = '''|| NewTableName ||'''
           AND TableType = ''Real'';

           IF CNT = 0 THEN
               INSERT INTO TempListDomainTable
               SELECT ''Real'',
                       '''|| NewTableName ||''',
                       NULL,
                       NULL, 
                       '''|| DomainId ||''',
                       '''|| Domain ||'''
               FROM DUAL;

           END IF;

       END IF;

       COMMIT;
       
       END;';

       EXECUTE IMMEDIATE sql_stmt;

	--------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------

       IF TabName IS NOT NULL THEN
           SELECT COUNT(*) INTO CNT
           FROM user_constraints uc1
           JOIN user_constraints uc2
               ON uc1.r_constraint_name = uc2.constraint_name
           WHERE uc1.constraint_name = ConstraintName
           AND uc2.table_name = 'ListDomain';

           IF CNT = 1 THEN
               sql_stmt := 'ALTER TABLE ' || TabName || ' DROP CONSTRAINT ' || ConstraintName;
               EXECUTE IMMEDIATE sql_stmt;
           END IF;
           
-------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------

           SELECT COUNT(*) INTO CNT
           FROM user_constraints
           WHERE constraint_name = ConstraintName;

           IF CNT = 0 THEN
               sql_stmt := 'ALTER TABLE ' || TabName || ' ADD CONSTRAINT '
                           || ConstraintName || ' FOREIGN KEY ('|| ColName ||')'
                           || ' REFERENCES ' || NewTableName || ' (Id)' ;

               EXECUTE IMMEDIATE sql_stmt;

           END IF;
       END IF;

   END LOOP;

   ----------------------------- DROP all LD/GLD tables that do not have a foreign key referencing them ----------------- 
   
   -- Check to see if there are any LD tables without a foreign key constraint that should be dropped (except for PMM table, 
   sql_stmt := 'SELECT COUNT(*)
   FROM user_tables
   WHERE (table_name like ''LD_%'' OR table_name like ''GLD_%'')
   AND table_name NOT IN (SELECT parent.table_name 
                           FROM user_constraints parent 
                           JOIN user_constraints child
                           ON parent.constraint_name = child.r_constraint_name)
   AND table_name NOT LIKE ''%PMM%Type%''
   AND table_name NOT IN (SELECT NewListDomainTable FROM NewDomainTableList
                          WHERE DomainCatalogId IN (SELECT DomainCatalogId FROM RememberedListDomainValues
                                                  UNION
                                                  SELECT DomainCatalogId FROM ActionItemPropDCXRef) 
                        )
   AND table_name NOT IN (SELECT ListDomainTableName FROM TempListDomainTable WHERE TableType = ''Virtual'')';
   
   EXECUTE IMMEDIATE sql_stmt INTO CNT;
  
   IF CNT > 0 THEN
    
        sql_stmt := '
        DECLARE
            CURSOR Delete_Cursor IS
            SELECT ''DROP TABLE '' || table_name  AS droptable
            FROM user_tables
            WHERE (table_name like ''LD_%'' OR table_name like ''GLD_%'')
            AND table_name NOT IN (SELECT parent.table_name 
                                    FROM user_constraints parent 
                                    JOIN user_constraints child
                                    ON parent.constraint_name = child.r_constraint_name)
            AND table_name NOT LIKE ''%PMM%Type%''
            AND table_name NOT IN (SELECT NewListDomainTable FROM NewDomainTableList
                                    WHERE DomainCatalogId IN (SELECT DomainCatalogId FROM RememberedListDomainValues
                                                            UNION
                                                            SELECT DomainCatalogId FROM ActionItemPropDCXRef) 
                                    )
            AND table_name NOT IN (SELECT ListDomainTableName FROM TempListDomainTable WHERE TableType = ''Virtual'');

        BEGIN
            FOR i IN Delete_Cursor LOOP
                EXECUTE IMMEDIATE i.droptable;
            END LOOP; 
        
        END;';

        EXECUTE IMMEDIATE sql_stmt;

   END IF;
   
   /*************************************************************************************************
                       CREATE New Tables for CategoryDataListDomainXRef Table
   **************************************************************************************************/

    SELECT COUNT(*) INTO CNT
    FROM user_tab_columns
    WHERE table_name = 'CategoryDataListDomainXRef'
    AND column_name = 'ListDomainTableName';
   
    IF CNT = 0 THEN

        -- Add column to store New Listdomain table name
        sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef ADD (ListDomainTableName VARCHAR2(50))';
            
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'UPDATE CategoryDataListDomainXRef cdl
        SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                FROM NewDomainTableList
                                WHERE DomainCatalogId = (SELECT DomainCatalogId FROM ListDomain WHERE Id = cdl.ValueDomainId)
                                )';
                    
        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

    END IF;

    -- Modify Table column order and add default constraints
    sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY (CreatedUser INVISIBLE,
                                                                CreatedDate INVISIBLE,
                                                                LastModBYUserId INVISIBLE,
                                                                LastModDateTime INVISIBLE)';
                                            
    EXECUTE IMMEDIATE sql_stmt;
        
    SELECT COUNT(*) INTO CNT
    FROM user_tab_columns
    WHERE table_name = 'CategoryDataListDomainXRef'
    AND column_name = 'ListDomainTableName'
    AND nullable = 'Y';

    IF CNT <> 0 THEN
        sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY (ListDomainTableName NOT NULL)';
        
        EXECUTE IMMEDIATE sql_stmt;

    END IF;
                                                                    
    sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY (LastModBYUserId VISIBLE,
                                                                LastModDateTime VISIBLE,
                                                                CreatedUser VISIBLE
                                                                )';
                                                                    
    EXECUTE IMMEDIATE sql_stmt;
    
    sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY (CreatedDate VISIBLE)';
    
    EXECUTE IMMEDIATE sql_stmt;
                                                            
    -- Modify Defaults on change tracking columns                                              
    sql_stmt := 'ALTER TABLE CategoryDataListDomainXRef MODIFY (LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''), 
                                                                CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                                LastModDateTime TIMESTAMP DEFAULT SYSDATE,
                                                                CreatedDate TIMESTAMP DEFAULT SYSDATE
                                                                )';
                                                                
    EXECUTE IMMEDIATE sql_stmt;
    
    -- Modify trigger definition on CategoryDataListDomainXRef table
    sql_stmt := 'CREATE TRIGGER TU_CategoryDataListDomainXRef
                BEFORE UPDATE ON CategoryDataListDomainXRef
                FOR EACH ROW
                BEGIN
                    :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                    :new.LastModDateTime := SYSDATE;
                END;';
                
    EXECUTE IMMEDIATE sql_stmt;
   
   /*****************************************************************************************
                   Modify RememberedListDomainValues and ActionItemPropDCXRef tables
   **********************************************************************************************/

   ----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------
   
   SELECT COUNT(*) INTO CNT
   FROM user_tab_columns
   WHERE table_name = 'RememberedListDomainValues'
   AND column_name = 'ListDomainTableName';

    IF CNT = 0 THEN
        --Add new column to RememberedListDomainValues table
        sql_stmt := 'ALTER TABLE RememberedListDomainValues ADD (ListDomainTableName VARCHAR2(50))';
        
        EXECUTE IMMEDIATE sql_stmt;

        --Update RememberedListDomainValues with values for new column
        sql_stmt := 'UPDATE RememberedListDomainValues rldv
                    SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                                FROM NewDomainTableList
                                                WHERE DomainCatalogId =  rldv.DomainCatalogId)';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

    END IF;
        
    SELECT COUNT(*) INTO CNT
    FROM user_tab_columns 
    WHERE table_name = 'RememberedListDomainValues'
    AND column_name = 'DomainCatalogId';

    IF CNT <> 0 THEN

        sql_stmt:= 'ALTER TABLE RememberedListDomainValues DROP COLUMN DomainCatalogId CASCADE CONSTRAINTS';
        
        EXECUTE IMMEDIATE sql_stmt;
    END IF;
    
    sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId INVISIBLE,
                                                                LastModDateTime INVISIBLE,
                                                                CreatedUser INVISIBLE,
                                                                CreatedDate INVISIBLE )';


                                                                
    EXECUTE IMMEDIATE sql_stmt;
                                                        
    sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId VISIBLE,
                                                                LastModDateTime VISIBLE
                                                                )';
    
    EXECUTE IMMEDIATE sql_stmt;
            
    sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (CreatedUser VISIBLE,
                                                                CreatedDate VISIBLE)';
    
    EXECUTE IMMEDIATE sql_stmt;
    
            
    -- Modify Defaults on change tracking columns                                              
    sql_stmt := 'ALTER TABLE RememberedListDomainValues MODIFY (LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''), 
                                                                CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                                LastModDateTime TIMESTAMP DEFAULT SYSDATE,
                                                                CreatedDate TIMESTAMP DEFAULT SYSDATE)';
                                                                
    EXECUTE IMMEDIATE sql_stmt;

    -- Modify trigger definition on CategoryDataListDomainXRef table
    sql_stmt := 'CREATE OR REPLACE TRIGGER tu_RememberedListDomainValues
                BEFORE UPDATE ON RememberedListDomainValues
                FOR EACH ROW
                BEGIN
                    :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                    :new.LastModDateTime := SYSDATE;
                END;';
                
    EXECUTE IMMEDIATE sql_stmt; 

   -------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------

   SELECT COUNT(*) INTO CNT
   FROM user_tab_columns
   WHERE column_name = 'ListDomainTableName'
   AND table_name = 'ActionItemPropDCXRef';

    IF CNT = 0 THEN

        -- Add new column to store ListDomain table name
        sql_stmt := 'ALTER TABLE ActionItemPropDCXRef ADD ListDomainTableName VARCHAR2(50)';
        
        EXECUTE IMMEDIATE sql_stmt;  

        --Update ActionItemPropDCXRef with values for new column
        sql_stmt := 'UPDATE ActionItemPropDCXRef aip
                    SET ListDomainTableName = (SELECT DISTINCT NewListDomainTable  
                                            FROM NewDomainTableList
                                            WHERE DomainCatalogId =  aip.DomainCatalogId)';

        EXECUTE IMMEDIATE sql_stmt;
    
    COMMIT;
    END IF;
       


    SELECT COUNT(*) INTO CNT
    FROM user_tab_columns 
    WHERE table_name = 'ActionItemPropDCXRef'
    AND column_name = 'DomainCatalogId';

    IF CNT <> 0 THEN

        sql_stmt:= 'ALTER TABLE ActionItemPropDCXRef DROP COLUMN DomainCatalogId CASCADE CONSTRAINTS';
        
        EXECUTE IMMEDIATE sql_stmt;
    END IF;
                
    sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (CreatedUser INVISIBLE,
                                                            CreatedDate INVISIBLE,
                                                            LastModByUserId INVISIBLE,
                                                            LastModDateTime INVISIBLE)';
                                                                
    EXECUTE IMMEDIATE sql_stmt;
    
                
    sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (LastModByUserId VISIBLE,
                                                          LastModDateTime VISIBLE)';
    
    EXECUTE IMMEDIATE sql_stmt;
    
    
    sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (CreatedUser VISIBLE,
                                                            CreatedDate VISIBLE
                                                            )';
    
    EXECUTE IMMEDIATE sql_stmt;
            
    -- Modify Defaults on change tracking columns                                              
    sql_stmt := 'ALTER TABLE ActionItemPropDCXRef MODIFY (LastModByUserId VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''), 
                                                            CreatedUser VARCHAR2(45) DEFAULT SYS_CONTEXT(''USERENV'', ''OS_USER''),
                                                            LastModDateTime TIMESTAMP DEFAULT SYSDATE,
                                                            CreatedDate TIMESTAMP DEFAULT SYSDATE)';
                                                                
    EXECUTE IMMEDIATE sql_stmt;

    sql_stmt := 'CREATE OR REPLACE TRIGGER tu_ActionItemPropDCXRef
                BEFORE UPDATE ON ActionItemPropDCXRef
                FOR EACH ROW
                BEGIN
                    :new.LastModByUserid := SYS_CONTEXT(''USERENV'', ''OS_USER'');
                    :new.LastModDateTime := SYSDATE;
                END;';
                
    EXECUTE IMMEDIATE sql_stmt; 


   /*********************************************************************************************
                                   DELETE OBSELETE TABLES 
   *********************************************************************************************/

    -- Save data from and Delete ListDomain, DomainCatalog, DomainCatalogColXRef
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'Temp_ListDomain';

    IF CNT = 0 THEN
        sql_stmt := 'CREATE TABLE Temp_ListDomain AS SELECT * FROM ListDomain';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'DROP TABLE ListDomain CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'Temp_DomainCatalog';

    IF CNT = 0 THEN
        sql_stmt := 'CREATE TABLE Temp_DomainCatalog AS SELECT * FROM DomainCatalog';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'DROP TABLE DomainCatalog CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'Temp_DomainCatalogColXRef';

    IF CNT = 0 THEN
        sql_stmt := 'CREATE TABLE Temp_DomainCatalogColXRef AS SELECT * FROM DomainCatalogColXRef';
        EXECUTE IMMEDIATE sql_stmt;

        sql_stmt := 'DROP TABLE DomainCatalogColXRef CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE sql_stmt;    
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'NewDomainTableList';

    IF CNT <> 0 THEN
        sql_stmt := 'DROP TABLE NewDomainTableList CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE sql_stmt;  
    END IF;

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

