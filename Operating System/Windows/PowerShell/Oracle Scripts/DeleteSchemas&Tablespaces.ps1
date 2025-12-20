<#
    This script was created to delete a list of schemas and tablespaces with the same name as the schema name excluding the 
    Users and system tablespaces
#>
#Load the OracleClient Assembly
#[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

$ServerName = HOSTNAME.EXE
$DBHostName = "$ServerName.EDDYFINDT.COM"
$DBServiceName = $DBHostName
$TNSServiceName = $ServerName

$User = Read-Host "`r`nEnter an Oracle username"
$SecurePassword = Read-Host -Prompt "Enter an Oracle user password" -AsSecureString
$PlainTextPass = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
Write-Host ""


$List = "ARAMCO_UPDM_PROD
ATCO_UPDM_JULY
ATLAS
CORROSIONCONTROL
ENTERPRISE
ETP_IRASV6_TEST
ETP_IRASV6_TEST_OWNR
ETP_IRASV6_UAT
ETP_IRASV6_UAT_OWNR
ETPTEST
ETPTEST_OWNR
INTEGRITY
MOBILE
ONECALL
PEFORMS
PROACTIVE
PROACTIVEFGT
PROACTIVEINTER
PROACTIVEINTRA
PROACTIVELIQUID
PROACTIVEPEPL
PROACTIVESR
PROACTIVETGC
RISK                                                                                                                                                          
"

$List = $List.Replace(" ", "") 
$List = "'" + $List.Replace("`r`n", "', '") + "'"
$List = $List.Replace(", ''", "")

# Construct command to drop tablespaces named after users that are to be deleted
$GetDropCmd = " 
SET SERVEROUTPUT ON;
DECLARE
    sql_stmt VARCHAR2(4000);
    CNT INT;

    TYPE DDL_TABLE_TYPE IS TABLE OF VARCHAR2(5000)
                INDEX BY BINARY_INTEGER;
    ddl_commands DDL_TABLE_TYPE;
BEGIN

    ------------------------------------------- DROP DOMAIN INDEXES -----------------------------
    
    --Check number of domain indexes referencing tablespaces to be dropped
    SELECT COUNT(*) INTO CNT
    FROM all_indexes
    WHERE index_type='DOMAIN' 
        AND table_owner IN ($List);

    --Drop all domain indexes if any exist within tablespaces to be dropped
    IF CNT <> 0 THEN

        SELECT 'DROP INDEX ' || table_owner || '.' || index_name  AS ddl_stmt
        BULK COLLECT INTO ddl_commands
        FROM all_indexes
        WHERE index_type='DOMAIN' 
            AND table_owner IN ($List);
        
        FOR i IN 1..ddl_commands.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(ddl_commands(i));
           EXECUTE IMMEDIATE ddl_commands(i);
        END LOOP;
    
    END IF;

    --------------------------------- DROP MATERIALIZED VIEWS ----------------------------------

    -- Check number of materialized views within tablespaces to be dropped
    SELECT COUNT(*) INTO CNT
    FROM dba_mviews
    WHERE owner IN ($List);


    -- dropped materialized views if there are any
    IF CNT <> 0 THEN
        
        ddl_commands.DELETE;

        SELECT 'DROP MATERIALIZED VIEW ' || owner || '.' || mview_name AS ddl_stmt
        BULK COLLECT INTO ddl_commands
        FROM dba_mviews
        WHERE owner IN ($List);
 
        FOR i IN 1..ddl_commands.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(ddl_commands(i));
            EXECUTE IMMEDIATE ddl_commands(i);
        END LOOP;
        
    END IF;
 
    -------------------------------------------- DROP TABLESPACE ------------------------------
              
    --Check that the tablespaces to be dropped exist
    SELECT COUNT(*) INTO CNT
    FROM dba_tablespaces
    WHERE tablespace_name IN ($List)
        AND NOT REGEXP_LIKE (tablespace_name, '^SYSTEM|^SYSAUX|^USER');

    --Dropped tablespaces if they exist
    IF CNT <> 0 THEN
        
        ddl_commands.DELETE;

        SELECT 'DROP TABLESPACE ' || tablespace_name || ' INCLUDING CONTENTS AND DATAFILES' AS ddl_stmt
        BULK COLLECT INTO ddl_commands
        FROM dba_tablespaces
        WHERE tablespace_name IN ($List)
        AND NOT REGEXP_LIKE (tablespace_name, '^SYSTEM|^SYSAUX|^USER');
        
        FOR i IN 1..ddl_commands.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(ddl_commands(i));
            EXECUTE IMMEDIATE ddl_commands(i);
        END LOOP;   
        
    END IF;
  
    ------------------------------------------ DROP USER -------------------------------------

    -- Check number of users to be dropped that still exist
    SELECT COUNT(*) INTO CNT
    FROM all_users 
    WHERE username IN ($List);
 
    IF CNT <> 0 THEN
    
        ddl_commands.DELETE;

        SELECT 'DROP USER ' || username || ' CASCADE' AS ddl_stmt
        BULK COLLECT INTO ddl_commands
        FROM dba_users
        WHERE username IN ($List);
        
        FOR i IN 1..ddl_commands.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(ddl_commands(i));
            EXECUTE IMMEDIATE ddl_commands(i);
        END LOOP;
     
    END IF;
   
END;
/
"

$ddl_cmd = $GetDropCmd | sqlplus -silent "$User/`"$PlainTextPass`"@$TNSServiceName" 

$ddl_cmd
