ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON;

DECLARE
    CNT INT;
    sql_stmt VARCHAR(20000);
BEGIN

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'SQLClauseTab';

    IF CNT <> 0 THEN
        sql_stmt := 'DROP TABLE SQLClauseTab';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    sql_stmt := 'CREATE TABLE SQLClauseTab (ClauseIndex INT,
                                            Type VARCHAR2(20),
                                            TableName VARCHAR(100),
                                            TableAlias VARCHAR(100),
                                            ColumnName VARCHAR(100),
                                            NewLDTableName VARCHAR(100))';

    EXECUTE IMMEDIATE sql_stmt;

END;
/

/*
    This script modifies the definition of views referencing the ListDomain table, which
    no longer exists.
*/
DECLARE
    sql_stmt VARCHAR2(20000);
    CNT INT;
    ObjectDefinition VARCHAR2(20000);
    V_ViewName VARCHAR2(100);
    StrLength INT;
    ClauseStartIndex INT;
    StartIndex INT;
    EndIndex INT;
    IsWhereClause INT;
    V_TableAlias VARCHAR2(100);
    V_TableName VARCHAR2(100);
    V_ColumnName VARCHAR2(100);
    ExemptTableList VARCHAR2(10000);

    CURSOR ViewList_Cursor IS
    SELECT view_name, text_length, text as Definition
    FROM user_views;

BEGIN

    FOR i IN ViewList_Cursor LOOP

        ObjectDefinition := i.definition;
        V_ViewName := i.view_name;
        StrLength := i.text_length;

        ExemptTableList := '''ListDomain''';

        sql_stmt := 'DELETE FROM SQLClauseTab';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

        CNT := INSTR(ObjectDefinition, 'ListDomain');

        IF CNT = 0
        THEN
            CONTINUE;
        END IF;

---------------------- REMOVE extra spacing in view definitions ---------------------------

        StartIndex := INSTR(ObjectDefinition, '  ', 1);

        FOR i IN 1..StrLength LOOP
            StartIndex := INSTR(ObjectDefinition, '  ', StartIndex);
            ObjectDefinition := REPLACE(ObjectDefinition, '  ', ' ');

            EXIT WHEN StartIndex = 0;
        END LOOP;

--------------------------- Find Table and Table Alias in FROM Clause ----------------

        StartIndex := 1;

        FOR i IN 1..StrLength LOOP

            ClauseStartIndex := INSTR(ObjectDefinition, 'FROM', startIndex);
            StartIndex := INSTR(ObjectDefinition, ' ', ClauseStartIndex) + 1;

            EXIT WHEN ClauseStartIndex = 0;

            EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);

            V_TableName := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
            V_TableName := REPLACE(REPLACE(V_TableName, CHR(10), ''), '"', '');

            StartIndex := INSTR(ObjectDefinition, ' ', EndIndex) + 1;

            CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

            IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
            THEN
                EndIndex := CNT;
            ELSE
                EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
            END IF;

            V_TableAlias := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
            V_TableAlias := REPLACE(REPLACE(V_TableAlias, CHR(10), ''), '"', '');

            sql_stmt := 'INSERT INTO SQLClauseTab
                        VALUES (' || ClauseStartIndex || ',
                            ''FROM'',
                            ''' || V_TableName || ''',
                                ''' || V_TableAlias || ''',
                                NULL,
                                NULL)';

            EXECUTE IMMEDIATE sql_stmt;

            IF (REGEXP_INSTR(ObjectDefinition, 'With |WHERE' || V_TableName) <> 0)
                AND (INSTR(ExemptTableList, V_TableName) = 0)
            THEN
                ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
            END IF;

            StartIndex := StartIndex + 1;

        END LOOP;

        COMMIT;

-------------------------------------- Find all Join Clauses -----------------------------

        StartIndex := 1;

        FOR i IN 1..StrLength LOOP

            ClauseStartIndex := INSTR(ObjectDefinition, 'JOIN ', StartIndex);

            StartIndex := ClauseStartIndex;

            EXIT WHEN StartIndex = 0;

            StartIndex := INSTR(ObjectDefinition, ' ', StartIndex) + 1;

            EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);

            V_TableName := SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex);
            V_TableName := REPLACE(REPLACE(V_TableName, CHR(10), ''), '"', '');

            StartIndex := INSTR(ObjectDefinition, ' ', EndIndex) + 1;

            CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

            IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
            THEN
                EndIndex := CNT;
            ELSE
                EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
            END IF;

            V_TableAlias := REPLACE(SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex), '"', '');
            V_TableAlias := REPLACE(REPLACE(V_TableAlias, CHR(10), ''), '"', '');

            sql_stmt := 'INSERT INTO SQLClauseTab
                        VALUES (' || ClauseStartIndex || ',
                                ''JOIN'',
                                ''' || V_TableName || ''',
                                ''' || V_TableAlias || ''',
                                NULL,
                                NULL)';

            EXECUTE IMMEDIATE sql_stmt;

            IF (REGEXP_INSTR(ObjectDefinition, 'With ' || V_TableName) <> 0)
                AND (INSTR(ExemptTableList, V_TableName) = 0)
            THEN
                ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
            END IF;

            StartIndex := StartIndex  + 1;

        END LOOP;

        COMMIT;

----------------------- Find all table-qualified columns in JOIN predicate ---------------


        DECLARE
            
            TYPE NEWTABLE_TYPE IS TABLE OF VARCHAR2(50)
                            INDEX BY BINARY_INTEGER;
                            
            ColumnList_Table  NEWTABLE_TYPE;

        BEGIN

            sql_stmt := 'SELECT DISTINCT TableAlias 
            FROM SQLClauseTab 
            WHERE TableAlias IS NOT NULL AND TableAlias <> '' ''';

            EXECUTE IMMEDIATE sql_stmt BULK COLLECT INTO ColumnList_Table;

            FOR i IN 1..ColumnList_Table.COUNT LOOP

                sql_stmt := 'SELECT MIN(ClauseIndex)
                FROM SQLClauseTab
                WHERE Type = ''JOIN''';

                EXECUTE IMMEDIATE sql_stmt INTO StartIndex;

                V_TableAlias := ColumnList_Table(i);

                FOR i IN 1..StrLength LOOP

                    IsWhereClause := 0;

                    StartIndex := INSTR(ObjectDefinition, V_TableAlias || '.', StartIndex);

                    EXIT WHEN StartIndex = 0;

                    sql_stmt := 'SELECT MAX(ClauseIndex)
                    FROM SQLClauseTab
                    WHERE ClauseIndex < '|| StartIndex ||'
                    AND Type = ''JOIN''';

                    EXECUTE IMMEDIATE sql_stmt INTO ClauseStartIndex;

                    -- Check if there is a WHERE clause nearby to prevent WHERE clause predicate from being counted as part of JOIN predicate
                    IF (INSTR(ObjectDefinition, 'WHERE', StartIndex) - StartIndex) <= 3 THEN
                        IsWhereClause := 1;
                    END IF;

                    StartIndex := INSTR(ObjectDefinition, '.', StartIndex) + 1;

                    CNT := INSTR(ObjectDefinition, CHR(10), StartIndex);

                    IF (CNT <> 0 AND CNT < INSTR(ObjectDefinition, ' ', StartIndex))
                    THEN
                        EndIndex := CNT;
                    ELSE
                        EndIndex := INSTR(ObjectDefinition, ' ', StartIndex);
                    END IF;

                    sql_stmt := 'SELECT TableName
                    FROM SQLClauseTab
                    WHERE TableAlias = ''' || V_TableAlias || '''
                    AND TableName IS NOT NULL
                    AND rownum < 2';

                    EXECUTE IMMEDIATE sql_stmt INTO V_TableName;

                    V_ColumnName := REPLACE(SUBSTR(ObjectDefinition, StartIndex, EndIndex - StartIndex), ')', '');
                    V_ColumnName := REPLACE(REPLACE(V_ColumnName, CHR(10), ''), '"', '');

                    sql_stmt := 'INSERT INTO SQLClauseTab
                                VALUES (' || CASE 
                                                WHEN IsWhereClause = 0 THEN ClauseStartIndex 
                                                ELSE INSTR(ObjectDefinition, 'WHERE', StartIndex) 
                                                END || ',
                                            '''|| CASE 
                                                WHEN IsWhereClause = 0 THEN 'JOIN CONDITION'
                                                ELSE 'WHERE'
                                            END ||''',
                                        ''' || V_TableName || ''',
                                        ''' || V_TableAlias || ''',
                                        ''' || V_ColumnName || ''',
                                        NULL)';

                    EXECUTE IMMEDIATE sql_stmt;

                    IF (REGEXP_INSTR(ObjectDefinition, 'With ' || V_TableName) <> 0)
                        AND (INSTR(ExemptTableList, V_TableName) = 0)
                    THEN
                        ExemptTableList := ExemptTableList || ', ''' || V_TableName || '''';
                    END IF;

                    StartIndex := StartIndex + 1;

                END LOOP;

            END LOOP;

            COMMIT;
        END;

--------------- Match ListDomain references in View Definition to new ListDomain table name ------------------------

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'tmpTable';

        IF CNT <> 0
        THEN
            EXECUTE IMMEDIATE 'DROP TABLE tmpTable';
        END IF;

        sql_stmt := '
        UPDATE SQLClauseTab SC
        SET NewLDTableName = (SELECT DISTINCT tmp.ListDomainTableName
        FROM SQLClauseTab SCT
        JOIN TempListDomainTable tmp
        ON tmp.ReferencedColumnName = SCT.ColumnName
        AND tmp.ReferencedTableName = SCT.TableName
        WHERE SCT.ClauseIndex IN (SELECT ClauseIndex FROM SQLClauseTab
                            WHERE TableName = ''ListDomain'')
        AND SCT.ColumnName IS NOT NULL
        AND SC.ClauseIndex = SCT.ClauseIndex
        AND SC.TableName = ''ListDomain'')';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

----------------------- Store views that contain missing tables in a tmp table --------------------

        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name = 'tmp_InvalidViews';

        IF CNT = 0
        THEN
            sql_stmt := 'CREATE TABLE tmp_InvalidViews (ViewName VARCHAR2(100),
                                                        Definition LONG,
                                                        DropCommand VARCHAR2(100))';

            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'SELECT COUNT(DISTINCT(TableName)) FROM SQLClauseTab
                    WHERE TableName NOT IN (' || ExemptTableList || ')
                    AND TableName NOT IN (SELECT table_name FROM user_tables)';


        EXECUTE IMMEDIATE sql_stmt INTO CNT;

        IF CNT <> 0
        THEN
            sql_stmt := 'SELECT COUNT(*)
            FROM tmp_InvalidViews
            WHERE ViewName = '''|| V_ViewName || '''';

            EXECUTE IMMEDIATE sql_stmt INTO CNT;

            IF CNT = 0
            THEN
                sql_stmt := 'INSERT INTO tmp_InvalidViews
                            VALUES (''' || V_ViewName || ''',
                                ''SELECT text FROM user_views WHERE view_name = '''''|| V_ViewName || ''''''',
                                ''DROP VIEW '|| V_ViewName ||''')';

                EXECUTE IMMEDIATE sql_stmt;

                COMMIT;
            END IF;
        END IF;

/*********************************************************************************************************
                                    Modify View Definiion
**********************************************************************************************************/

----------------------------------- Modify View Definition ----------------------------

        DECLARE
            TableAlias VARCHAR2(100);
            TableName VARCHAR2(100);
            NewLDTableName VARCHAR2(100);

            TYPE RECORD_TYPE IS RECORD
            (ClauseIndex INT,
                TableName VARCHAR2(100),
                TableAlias VARCHAR2(50),
                NewLDTableName VARCHAR2(100)
            );

            TYPE TABLE_VARIABLE IS TABLE OF RECORD_TYPE;

            T_SearchNReplace TABLE_VARIABLE;

        BEGIN
            -- Initialize table varaible to modify view definitions
            sql_stmt := '
            SELECT DISTINCT ClauseIndex, TableName, TableAlias, NewLDTableName
            FROM SQLClauseTab
            WHERE ClauseIndex IN (SELECT ClauseIndex
                                FROM SQLClauseTab
                                WHERE TableName = ''ListDomain'')
            AND TableName = ''ListDomain''
            AND NewLDTableName IS NOT NULL';

            EXECUTE IMMEDIATE sql_stmt BULK COLLECT INTO T_SearchNReplace;

            -- Loop through and modify view definitions (replace ListDomain table name with new LD table name)
            FOR i IN 1..T_SearchNReplace.COUNT LOOP

                TableName := T_SearchNReplace(i).TableName;
                TableAlias := T_SearchNReplace(i).TableAlias;
                NewLDTableName := T_SearchNReplace(i).NewLDTableName;

                ObjectDefinition := REGEXP_REPLACE( ObjectDefinition,
                                            TableName || ' '|| TableAlias ||'\s',
                                            NewLDTableName || ' ' ||TableAlias ||' ');
            END LOOP;
        END;

-------------------------------------- Recreate View -------------------------------------------

        sql_stmt := 'SELECT COUNT(*)
        FROM tmp_InvalidViews
        WHERE ViewName = ''' || V_ViewName ||'''';

        EXECUTE IMMEDIATE sql_stmt INTO CNT;

        IF CNT = 0
        THEN
            ObjectDefinition := 'CREATE OR REPLACE VIEW ' || V_ViewName || ' AS ' || ObjectDefinition;
            --DBMS_OUTPUT.PUT_LINE(ObjectDefinition);
            EXECUTE IMMEDIATE ObjectDefinition;
        END IF;


    END LOOP;

-------------------------------------- DROP Tables Created by Script --------------------------

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'SQLClauseTab';

    IF CNT <> 0
    THEN
        sql_stmt := 'DROP TABLE SQLClauseTab';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'tmp_InvalidViews';

    IF CNT <> 0 THEN 
        sql_stmt := 'SELECT COUNT(*) FROM tmp_InvalidViews';
        EXECUTE IMMEDIATE sql_stmt INTO CNT;
        
        IF CNT = 0 
        THEN 
            sql_stmt := 'DROP TABLE tmp_InvalidViews';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;
    END IF;

END;
/