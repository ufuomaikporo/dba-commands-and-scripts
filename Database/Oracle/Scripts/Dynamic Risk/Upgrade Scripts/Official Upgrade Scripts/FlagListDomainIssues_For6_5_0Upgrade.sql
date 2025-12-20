SET SERVEROUTPUT ON

ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

DECLARE 
    CNT INT;
    sql_stmt VARCHAR(20000);

    CURSOR TableListCursor IS
   SELECT child.table_name AS TableName,
	   child.column_name AS ColumnName
    FROM user_constraints uc
    JOIN user_cons_columns parent
        ON uc.r_constraint_name = parent.constraint_name
    JOIN user_cons_columns child
        ON uc.constraint_name = child.constraint_name
    WHERE parent.table_name = 'ListDomain' COLLATE BINARY_CI
        AND parent.column_name = 'Id' COLLATE BINARY_CI
        AND child.table_name NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 
        'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
    UNION
    SELECT 'POECompanyLookUp', 'MetalLossTypeDomainId' FROM DUAL
    UNION
    SELECT 'POECompanyLookUp', 'ToolTypeDomainId' FROM DUAL
    UNION 
    SELECT 'Stg_ILICrackAnomaly', 'ILICADepthDomainId' FROM DUAL;
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'ListDomainTableInfo';

    IF CNT <> 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE ListDomainTableInfo';
    END IF;

    sql_stmt := 'CREATE TABLE ListDomainTableInfo (TableName VARCHAR2(100)
                                                   ,ColumnName VARCHAR2(100)
                                                   ,ListDomainDCIdCount INT)';


    EXECUTE IMMEDIATE sql_stmt;

    FOR item IN TableListCursor LOOP
        sql_stmt := 'INSERT INTO ListDomainTableInfo
                    SELECT ''' || item.TableName || ''',
                            ''' || item.ColumnName || ''',
                    COUNT(DISTINCT DomainCatalogId) 
                    FROM ListDomain 
                    WHERE Id IN (SELECT DISTINCT '|| item.ColumnName ||' FROM '|| item.TableName ||')
                    AND DomainCatalogId <> -1
                    ';

        EXECUTE IMMEDIATE sql_stmt;

        COMMIT;

    END LOOP;

END;
/