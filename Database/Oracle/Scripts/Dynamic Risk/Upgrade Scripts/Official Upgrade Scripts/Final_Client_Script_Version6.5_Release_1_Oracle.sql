ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

SET SERVEROUTPUT ON

DECLARE 
    CNT INT;
    e_Wrong_Database EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO CNT
    FROM SystemPreferences  
    WHERE ParameterName = 'DatabaseType' AND Value = 'Stage';
    
    IF CNT = 0 THEN
        RAISE e_Wrong_Database;
    END IF;
    
EXCEPTION
    WHEN e_Wrong_Database THEN 
        DBMS_OUTPUT.PUT_LINE('The target database is not Stage database for applying this upgrade script.');
END;
/

DECLARE
    dbVersion NUMBER(10);
    dbVersionCheckPoint NUMBER(5);
    -- VirtualTableName NVARCHAR2(100);
    -- VirtualColumnName NVARCHAR2(100);
    -- VirtualTableId INT;
    -- VCDataTypeTable NVARCHAR2(100);
    -- VCDataTypeColumn NVARCHAR2(100);
    -- ForeignKeyName NVARCHAR2(100);
    sql_stmt NVARCHAR2(20000);
    -- ColumnList NVARCHAR2(MAX);
    -- JoinList NVARCHAR2(MAX);
    -- Counter INT;
    CNT INT;
    e_missingTables EXCEPTION;

    CURSOR l_cursor IS
    SELECT ListDomainTableName  
    FROM TempListDomainTable
    WHERE TableType = 'Virtual'
    AND ListDomainTableName IN (SELECT table_name FROM user_tables);

BEGIN
    SELECT DBVersion INTO dbVersion FROM VersionInfo vi;
    SELECT DBVersionCheckPoint INTO dbVersionCheckPoint FROM VersionInfo vi;
    IF dbVersion = 650013 AND dbVersionCheckPoint = 0
    THEN

        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = 'temp_VirtualColumn';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE temp_VirtualColumn';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;


        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = 'TempVirtualTableInfo';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE TempVirtualTableInfo';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = 'TempVirtualTableInfo';

		-- Table to store virtual table info (i.e. schema, name)
        IF CNT = 0 THEN
            sql_stmt := 'CREATE TABLE TempVirtualTableInfo (SchemaName VARCHAR2(100), VirtualTableName VARCHAR2(100))';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;


        /*
            Create temporary table to store the VirtualColumn values and the table name for the table associated with the 
            VirtualColumnDataTypeInd column
		*/
        SELECT COUNT(*) INTO CNT
        FROM user_tables
        WHERE table_name IN ('VirtualTable', 'VirtualColumn');

        IF CNT <> 2 THEN
            RAISE e_missingTables;
        END IF;

        SELECT COUNT(*) INTO CNT
        FROM user_tables 
        WHERE table_name = 'Temp_VirtualColumn';

        IF CNT <> 0 THEN
            sql_stmt := 'DROP TABLE Temp_VirtualColumn';
            EXECUTE IMMEDIATE sql_stmt;
        END IF;

        sql_stmt := 'CREATE TABLE Temp_VirtualColumn
        AS 
        				SELECT Id, 
						VirtualTableId, 
						VirtualColumnName,
						CASE 
							WHEN VirtualColumnDataTypeInd = ''N'' THEN ''VirtualTableDataNum''
							WHEN VirtualColumnDataTypeInd = ''D'' THEN ''VirtualTableDataDate''
							WHEN VirtualColumnDataTypeInd = ''I'' THEN ''VirtualTableDataInd''
							WHEN VirtualColumnDataTypeInd = ''L'' THEN ''VirtualTableDataListDomain''
							WHEN VirtualColumnDataTypeInd = ''F'' THEN ''VirtualTableDataFlg''
							WHEN VirtualColumnDataTypeInd = ''S'' THEN ''VirtualTableDataString''
						END AS VCDataTypeTable,
						CASE 
							WHEN VirtualColumnDataTypeInd = ''N'' THEN ''DataFieldValueNum''
							WHEN VirtualColumnDataTypeInd = ''D'' THEN ''DataFieldValueDate''
							WHEN VirtualColumnDataTypeInd = ''I'' THEN ''DataFieldValueInd''
							WHEN VirtualColumnDataTypeInd = ''L'' THEN ''DataFieldValueDomainId''
							WHEN VirtualColumnDataTypeInd = ''F'' THEN ''DataFieldValueFlg''
							WHEN VirtualColumnDataTypeInd = ''S'' THEN ''DataFieldValueString'' 
						END AS VCDataTypeColumn,
						VirtualColumnComment
				FROM VirtualColumn';

        EXECUTE IMMEDIATE sql_stmt;   

        FOR tableName IN l_cursor LOOP
            sql_stmt := 'RENAME ' || tableName.ListDomainTableName || ' TO DRAS_' || tableName.ListDomainTableName;
            EXECUTE IMMEDIATE sql_stmt;
        END LOOP;

		------------------------------------- Convert Virtual tables to flat tables ---------------------------------------

        DECLARE
            Counter INT := 1;
            ColumnList VARCHAR2(20000);
            JoinList VARCHAR2(20000);

            CURSOR VirtualTable_Cursor IS
            SELECT Id AS VirtualTableId, VirtualTableName FROM VirtualTable;

        BEGIN
            FOR i IN VirtualTable_Cursor LOOP

                ColumnList := 'SELECT ROW_NUMBER() OVER (ORDER BY VTS.VirtualTableStationingId) AS Id';

                JoinList := 'FROM VirtualTableStationing VTS';

                DECLARE
                    CURSOR VirtualColumns_Cursor IS
                    SELECT VirtualColumnName,
                            VCDataTypeTable,
                            VCDataTypeColumn
                    FROM Temp_VirtualColumn
                    WHERE VirtualTableId = i.VirtualTableId
                    AND VirtualColumnName NOT IN ('DO NOT USE');
                BEGIN

                    FOR j IN VirtualColumns_Cursor LOOP

                        ColumnList := ColumnList || CHR(10) || ', T' || Counter || '.' || j.VCDataTypeColumn || ' AS ' || j.VirtualColumnName || ', ';
                        JoinList := JoinList || CHR(10) || 'LEFT JOIN ' || j.VCDataTypeTable || ' T' || Counter || CHR(10)
                                    || ' ON T' || Counter || '.VirtualTableId = VTS.VirtualTableId'
                                    || CHR(10) || ' AND T' || Counter || '.VirtualTableStationingId = VTS.VirtualTableStationingId';
                    
                        Counter := Counter + 1;

                    END LOOP;
                END;

                -- Drop temporary virtualtable
                SELECT COUNT(*) INTO CNT
                FROM user_tables
                WHERE table_name = 'tmp_VirtualTableData';

                IF CNT <> 0 THEN
                    sql_stmt := 'DROP TABLE tmp_VirtualTableData';
                    EXECUTE IMMEDIATE sql_stmt;
                END IF;

                --Store data for each virtual table in a temporary table
                sql_stmt := 'CREATE TABLE tmp_VirtualTableData AS ' || CHR(10) || ColumnList || 'VTS.EffectiveStartDate, 
					VTS.EffectiveEndDate,
					VTS.BeginStationSeriesId,
					VTS.BeginStationNum,
					VTS.EndStationSeriesId,
					VTS.EndStationNum,
					VTS.SourceId,
					VTS.CreatedUser,
					VTS.CreatedDate,
					VTS.LastModByUserId,
					VTS.LastModDateTime' || CHR(10) || JoinList || CHR(10) 
                    || 'WHERE VTS.VirtualTableId = ' || i.VirtualTableId;
                

                EXECUTE IMMEDIATE sql_stmt;

                -- ColumnList := NULL;

                -- Get the list of columns that will be used to create the new virtual table
                --SELECT 

            END LOOP;
        END;


        -- UPDATE VersionInfo SET DBVersionCheckPoint = 1,
        --                         LastUpgradeDateTime = SYSDATE, 
        --                         LastUpgradeUserId = SYS_CONTEXT('USERENV', 'OS_USER'), 
        --                         LastUpgradeType = 'FULL';

        -- COMMIT;

        -- DBMS_OUTPUT.PUT_LINE ('SUCCESSFULLY Completed Upgrade Version ' || dbVersion || ' Checkpoint ' || dbVersionCheckPoint);

    END IF;
EXCEPTION
    WHEN e_missingTables THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'The VirtualTable and VirtualColumn tables are missing');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || 'An error occured while applying upgrade at version ' || dbVersion 
                        || ', checkpoint ' || dbVersionCheckPoint);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || CHR(10) ||SQLERRM);
END;
/

