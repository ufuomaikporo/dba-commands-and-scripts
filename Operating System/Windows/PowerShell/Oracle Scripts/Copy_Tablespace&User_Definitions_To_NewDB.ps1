<#
    The purpose of this script is to copy the tablespaces from a source database to a target database
#>

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

$ServerName = HOSTNAME.EXE

################################################################################################################

#Set the folowing variables

#$SourceDBHostName = "DRASORA19C.EDDYFINDT.COM"
$SourceDBTNSName = "ORA19C22"
$TargetDBTNSName = "DRASORA19C22"

# Specify the location of the output file containing the tablespace and user creation commands
$OutputFile = "D:\Scripts\Export_TableSpace_Definition.sql"

#Set mode to "manual" if you want to generate a script file that will be manually executed on the target database to create the tablespaces and users.
# Otherwise, set it to "auto" to allow this script to automatically attempt to create tablespaces and users on the target db 
$mode = "auto"

#Set the location where the tablespace datafiles should be created in the target/destination DB (if not set a known datafile directory will be picked)
$DestDataFileDirectory = "E:\Oracle\oradata\DRASORA19C22\DATA\"

#################################################################################################################
#$SourceDBUser=""
#$SourceDBPassword = ""


$SourceDBUser = Read-Host "`r`nEnter a non-SYS Oracle username for the Source Database"
$SecurePassword = Read-Host -Prompt "Enter the Oracle user password for the Source Database user" -AsSecureString
$SourceDBPassword = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password

if ([string]::IsNullOrWhitespace($TargetDBTNSName) -eq $false)
{
    $TargetDBUser = Read-Host "`r`nEnter a non-SYS Oracle username for the Target Database"
    $SecurePassword = Read-Host -Prompt "Enter the Oracle user password for the Target Database user" -AsSecureString
    $TargetDBPassword = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
}
#>

if ([string]::IsNullOrWhitespace($DestDataFileDirectory) -eq $true -and $mode -ne "manual")
{
    #Query to find the location of the database datafiles in the Target/Destination DB
    $SQL = "SET PAGES 0
                SET FEEDBACK OFF;
    SELECT SUBSTR(file_name, 0, LENGTH(file_name) - INSTR(REVERSE(file_name), '\', 1) + 1 ) AS directory
    FROM dba_data_files
    WHERE rownum < 2;"

   $DestDataFileDirectory = $SQL | sqlplus -silent "$TargetDBUser/`"$TargetDBPassword`"@$TargetDBTNSName" 
}


#PLSQL code to takes tablespace definitions from the source DB and stores it in a table (TablespaceDefinition)
$SQL = "
SET SERVEROUTPUT ON
DECLARE 
    sql_stmt VARCHAR(5000);
    CNT NUMBER;
    blksize INT;
BEGIN
    
    -- Deletes the table that will be created by this script to keep track of info if it already exists
    SELECT COUNT(*) INTO CNT
    FROM all_tables
    WHERE table_name = UPPER('TablespaceDefinition');

    IF CNT <> 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE TablespaceDefinition';
    END IF;

    SELECT value INTO blksize FROM v`$parameter WHERE name = 'db_block_size';

    sql_stmt := 'CREATE TABLE TablespaceDefinition AS
                    SELECT df.tablespace_name,
                    ''CREATE ''|| CASE WHEN dt.bigfile = ''YES'' THEN ''BIGFILE '' END|| ''TABLESPACE '' || df.tablespace_name || CHR(10) ||
                    ''DATAFILE ''''{0}''|| df.tablespace_name|| ''.DBF'''''' || CHR(10) ||
                    ''SIZE '' ||
                    CASE 
	                    WHEN CEIL((nvl(hwm,1)*'|| blksize ||')/1024/1024) < 10 THEN 10
	                    ELSE CEIL((nvl(hwm,1)*'|| blksize ||')/1024/1024)
                    END
                    || ''M REUSE '' ||
                     (SELECT CASE
                                    WHEN ROUND(SUM(m.maxbytes)) <= (nvl(hwm,1)*'|| blksize ||') OR ROUND(SUM(m.maxbytes)) >= 33554431
                                        THEN ''AUTOEXTEND ON NEXT '' || 
                                            CASE 
                                                WHEN CEIL((nvl(hwm,1)*'|| blksize ||')/1024/1024) < 10 THEN 10
                                                ELSE CEIL((nvl(hwm,1)*'|| blksize ||')/1024/1024*0.1)
                                            END|| ''M MAXSIZE UNLIMITED'' 
                                    WHEN CEIL(SUM(m.maxbytes)/1024/1024) <= 33554431
                                         THEN ''AUTOEXTEND ON NEXT '' || 
                                        CEIL(SUM(m.maxbytes)/1024/1024*0.1)||
                                        ''M MAXSIZE '' || CEIL(SUM(m.maxbytes)/1024/1024) || ''M ''
                                    ELSE TO_CHAR(CEIL(SUM(m.maxbytes)/1024/1024)) 
                                END
                       FROM dba_data_files m WHERE m.tablespace_name = df.tablespace_name) 
                    || CHR(10) ||
                    ''EXTENT MANAGEMENT ''|| dt.extent_management || 
                    CASE WHEN dt.allocation_type = ''SYSTEM'' THEN '' AUTOALLOCATE''
	                    WHEN dt.allocation_type = ''UNIFORM'' THEN '' UNIFORM SIZE ''|| dt.initial_extent/1024/1024 || ''M''
                    END ||	CHR(10) ||
                    ''SEGMENT SPACE MANAGEMENT '' || dt.segment_space_management 
                        || CHR(10) || ''/'' || CHR(10) AS tablespace_definition,
                    ''CREATE USER '' || df.tablespace_name || '' IDENTIFIED BY '' || 
                    CASE
	                    WHEN INSTR(df.tablespace_name,''_'', 1) > 0 
		                    THEN SUBSTR(LOWER(df.tablespace_name), 1, INSTR(df.tablespace_name,''_'', 1) - 1)
	                    ELSE LOWER(df.tablespace_name)
                    END || CHR(10) || ''DEFAULT TABLESPACE '' || df.tablespace_name || CHR(10) ||
                    ''QUOTA UNLIMITED ON '' || df.tablespace_name || CHR(10) || ''/'' || CHR(10) AS user_definition
                   FROM dba_data_files df
                   RIGHT JOIN
                         ( SELECT file_id, max(block_id+blocks-1) hwm
                             FROM dba_extents
                            GROUP by file_id ) b
                    ON df.file_id = b.file_id
                    JOIN dba_tablespaces dt 
                    ON dt.Tablespace_name = df.tablespace_name
                    WHERE NOT REGEXP_LIKE(df.tablespace_name, ''SYSTEM|SYSAUX|UNDO|USER'')
                    ORDER BY df.tablespace_name';


    EXECUTE IMMEDIATE sql_stmt;
   
END;
/"

#Run the annonymous stored proc in the target source database and generate the TablespaceDefinition table
$GetDefinitions = $SQL -f $DestDataFileDirectory | SQLPLUS -silent "$SourceDBUser/`"$SourceDBPassword`"@$SourceDBTNSName" 

#Connection string that will be used to connect to Oracle Datapump utility
$ConnectionString = "User Id=$SourceDBUser;Password=$SourceDBPassword; Data Source=$SourceDBTNSName"

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

# Generate script with commands to create tablespaces and users
Write-Output $ddl_cmd.Tablespace_Definition  | Out-File -FilePath $OutputFile  -Force
Write-Output $ddl_cmd.User_Definition | Out-File -FilePath $OutputFile  -Append

#Create the tablespaces and users in the target database if the mode is set to auto
if ($mode -eq "auto")
{
    # loop to create each user and tablespace definition taken from the source database in the target database 
    foreach ($row IN $ddl_cmd)
    {

        $TablespaceName = $row.Tablespace_Name
        $TablespaceDefinition = ($row.Tablespace_Definition).Replace("/", "")
        $UserDefinition = ($row.User_Definition).Replace("/", "")

        $SQL = "
        SET SERVEROUTPUT ON
        DECLARE
            CNT INT;
            sql_stmt VARCHAR(7000);
        BEGIN
            SELECT COUNT(*) INTO CNT
            FROM dba_tablespaces
            WHERE tablespace_name = UPPER('$TablespaceName');

            IF CNT = 0 THEN
                EXECUTE IMMEDIATE q'[$TablespaceDefinition]';       
            END IF;
        
            SELECT COUNT(*) INTO CNT
            FROM dba_users
            WHERE username = UPPER('$TablespaceName');

            IF CNT = 0 THEN
                EXECUTE IMMEDIATE q'[$UserDefinition]';
            END IF;
        
        END;
        /"

        $SQL | sqlplus -silent "$TargetDBUser/`"$TargetDBPassword`"@$TargetDBTNSName" 
    
    }
}