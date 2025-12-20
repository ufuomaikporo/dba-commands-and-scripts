<#
    The purpose of this script is to copy the tablespaces from a source database to a target database
#>
#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

$ServerName = HOSTNAME.EXE
$SourceDBHostName = "$ServerName.EDDYFINDT.COM"
$DBServiceName = $DBHostName
$SourceDBTNSName = $ServerName
$TargetDBTNSName = "DRASORA19C"

$User = Read-Host "`r`nEnter an Oracle username"
$SecurePassword = Read-Host -Prompt "Enter an Oracle user password" -AsSecureString
$PlainTextPass = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
Write-Host ""

$TargetDBUser = $SourceDBUser
$TargetDBPassword = $SourceDBPassword

#Set the location where the tablespace datafiles should be created in the target/destination DB (if not set a location will be picked)
$DestDataFileDirectory = ""

if ($DestDataFileDirectory -eq "")
{
    #Query to find the location of the database datafiles in the Target/Destination DB
    $sql_stmt = "SELECT SUBSTR(file_name, 0, LENGTH(file_name) - INSTR(REVERSE(file_name), '\', 1) + 1 ) FROM dba_data_files
    WHERE rownum < 2"

    $DestDataFileDirectory = $sql_stmt | sqlplus -silent "$TargetDBUser/`"$TargetDBPassword`"@$TargetDBTNSName" 
}

#PLSQL code to generate tablespace definitions from the source DB and store it in a table
$sql_stmt = "
DECLARE 
    sql_stmt VARCHAR(5000);
    CNT NUMBER;

    TYPE tabspace_record IS RECORD
    (tablespace_name dba_tablespaces.tablespace_name%TYPE,
     definition  VARCHAR2(7000),
     user_definition VARCHAR(7000));

    TYPE DDL_TABLE_TYPE IS TABLE OF tabspace_record
                INDEX BY BINARY_INTEGER;
    ddl_commands DDL_TABLE_TYPE;
BEGIN
    
    -- Deletes the table that will be created by this script to keep track of info if it already exists
    SELECT COUNT(*) INTO CNT
    FROM all_tables
    WHERE table_name = UPPER('TablespaceDefinition');

    IF CNT <> 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE TablespaceDefinition';
    END IF;

    sql_stmt := q'[CREATE TABLE TablespaceDefinition AS
                    SELECT df.tablespace_name,
                    'CREATE BIGFILE TABLESPACE ' || df.tablespace_name || CHR(10) ||
                    'DATAFILE ''{0}' || df.tablespace_name || '.dbf''' || CHR(10) ||
                    'SIZE ' || 
                    CASE 
	                    WHEN CEIL(COALESCE(seg.UsedSpace_mb, 0)/1024/1024*1.05) < 7 THEN 7
	                    ELSE CEIL(COALESCE(seg.UsedSpace_mb, 0)/1024/1024*1.05)
                    END	|| 'M ' ||
                    CASE
	                    WHEN SUM(maxbytes)/1000/1024 < 33554.416 
		                    AND SUM(maxbytes)/1024/1024 - SUM(df.bytes)/1024/1024 > 100
		                    THEN 'AUTOEXTEND ON NEXT ' || 
			                    ROUND((SUM(maxbytes)/1024/1024 - SUM(df.bytes)/1024/1024)*0.2, -1) ||
			                    'M MAXSIZE ' || SUM(maxbytes)/1024/1024 || 'M '
	                    WHEN SUM(maxbytes)/1000/1024 >= 33554.416 
		                    THEN 'AUTOEXTEND ON NEXT ' || 
		                    CASE 
			                    WHEN ROUND(SUM(df.bytes)/1024/1024*0.3) < 10 THEN 10
			                    ELSE ROUND(SUM(df.bytes)/1024/1024*0.3, -1)
		                    END|| 'M MAXSIZE UNLIMITED' 
	                    ELSE NULL
                    END	 || CHR(10) ||
                    'EXTENT MANAGEMENT LOCAL AUTOALLOCATE ' || CHR(10) ||
                    'SEGMENT SPACE MANAGEMENT AUTO' AS definition,
                    'CREATE USER ' || df.tablespace_name || ' IDENTIFIED BY ' || 
                    CASE
	                    WHEN INSTR(df.tablespace_name,'_', 1) > 0 
		                    THEN SUBSTR(df.tablespace_name, 1, INSTR(df.tablespace_name,'_', 1) - 1)
	                    ELSE df.tablespace_name
                    END || CHR(10) || 'DEFAULT TABLESPACE ' || df.tablespace_name || CHR(10) ||
                    'QUOTA UNLIMITED ON ' || df.tablespace_name AS user_definition
                    FROM dba_data_files df
                    LEFT JOIN (SELECT tablespace_name, sum(bytes) AS UsedSpace_mb
			                    FROM dba_segments
			                    GROUP BY tablespace_name) seg
	                    ON seg.tablespace_name = df.tablespace_name
                    WHERE NOT REGEXP_LIKE (df.tablespace_name, 'SYSTEM|SYSAUX|USERS|UNDO')
                    AND df.tablespace_name IN (SELECT tablespace_name FROM dba_tablespaces)
                    GROUP BY df.tablespace_name, seg.usedSpace_mb
                    ORDER BY df.tablespace_name]';

    EXECUTE IMMEDIATE sql_stmt;
   
END;
/"

$GetDefinitions = $sql_stmt -f $DestDataFileDirectory | sqlplus -silent "$SourceDBUser/`"$SourceDBPassword`"@$SourceDBTNSName" 

#Connection string that will be used to connect to Oracle Datapump utility
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$SourceDBHostName)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=$SourceDBHostName)));User Id=$SourceDBUser;Password=$SourceDBPassword;"


#PowerShell Object for setting the string used to open an Oracle database
$Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

#Create command to execute $GetSchemaQuery
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = "SELECT * FROM TablespaceDefinition"
$SQLCMD.CommandTimeout = 60 #seconds

#PowerShell object to store the results from an SQL query
$ddl_cmd = New-Object System.Data.DataTable
#$ddl_cmd = $sql_stmt | sqlplus -silent "$SourceDBUser/`"$SourceDBPassword`"@$SourceDBTNSName"

#Execute command to gather schema stats
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($ddl_cmd)

foreach ($row IN $ddl_cmd)
{
    $sql_stmt = "
    SET SERVEROUTPUT ON
    DECLARE
        CNT INT;
        sql_stmt VARCHAR(7000);
    BEGIN
        SELECT COUNT(*) INTO CNT
        FROM dba_tablespaces
        WHERE tablespace_name = UPPER('$($row.tablespace_name)');

        IF CNT = 0 THEN
            EXECUTE IMMEDIATE q'[$($row.definition)]';       
        END IF;
        
        SELECT COUNT(*) INTO CNT
        FROM dba_users
        WHERE username = UPPER('$($row.tablespace_name)');

        IF CNT = 0 THEN
            EXECUTE IMMEDIATE q'[$($row.user_definition)]';
        END IF;
        
    END;
    /"

    $sql_stmt | sqlplus -silent "$TargetDBUser/`"$TargetDBPassword`"@$TargetDBTNSName" 
    
}
