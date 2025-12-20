<#
    The purpose of this script is to copy the tablespaces from a source database to a target database
#>

$ServerName = HOSTNAME.EXE

################################################################################################################

#Set the folowing variables

#$SourceDBHostName = "DRASORA19C.EDDYFINDT.COM"
$SourceDBTNSName = "DRASORA19C"
$TargetDBTNSName = ""

# Specify the location of the output file containing the tablespace and user creation commands
$OutputFile = "B:\Scripts\Export_TableSpace_Definition.sql"

#Set mode to "manual" if you want to this script to generate a file containing the tablespaces and users that need to be created on the target database. 
# Otherwise this script will attemp to create tablespaces and users on the target db 
$mode = "manual"

#Set the location where the tablespace datafiles should be created in the target/destination DB (if not set a known datafile directory will be picked)
$DestDataFileDirectory = "E:\app\Oracle\ORA12CEXT\oradata\"

#################################################################################################################

$SourceDBUser = Read-Host "`r`nEnter a non-SYS Oracle username for the Source Database"
$SecurePassword = Read-Host -Prompt "Enter the Oracle user password for the Source Database user" -AsSecureString
$SourceDBPassword = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password

if ([string]::IsNullOrWhitespace($TargetDBTNSName) -eq $false)
{
    $TargetDBUser = Read-Host "`r`nEnter a non-SYS Oracle username for the Target Database"
    $SecurePassword = Read-Host -Prompt "Enter the Oracle user password for the Target Database user" -AsSecureString
    $TargetDBPassword = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
}

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
#>

#PLSQL code to takes tablespace definitions from the source DB and stores it in a table (TablespaceDefinition)
$SQL = "
DECLARE 
    sql_stmt VARCHAR(5000);
    CNT NUMBER;
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
                    'CREATE '|| CASE WHEN dt.bigfile = 'YES' THEN 'BIGFILE ' END|| 'TABLESPACE ' || df.tablespace_name || CHR(10) ||
                    'DATAFILE ''{0}'|| df.tablespace_name|| '.DBF''' || CHR(10) ||
                    'SIZE ' ||
                    CASE 
	                    WHEN CEIL(COALESCE(seg.UsedSpace_mb, 0)/1024/1024) < 10 THEN 10
	                    ELSE CEIL(COALESCE(seg.UsedSpace_mb, 0)/1024/1024)
                    END
                    || 'M ' ||
                    CASE
	                    WHEN SUM(maxbytes)/1000/1024 < 33554.416 
		                    THEN 'AUTOEXTEND ON NEXT ' || 
			                    ROUND((SUM(maxbytes)/1024/1024)*0.2)||
			                    'M MAXSIZE ' || SUM(maxbytes)/1024/1024 || 'M '
	                    WHEN SUM(maxbytes)/1000/1024 >= 33554.416 
		                    THEN 'AUTOEXTEND ON NEXT ' || 
		                    CASE 
			                    WHEN ROUND(SUM(df.bytes)/1024/1024*0.3) < 10 THEN 10
			                    ELSE ROUND(SUM(df.bytes)/1024/1024*0.3)
		                    END|| 'M MAXSIZE UNLIMITED' 
	                    ELSE NULL
                    END	
                    || CHR(10) ||
                    'EXTENT MANAGEMENT '|| dt.extent_management || 
                    CASE WHEN dt.allocation_type = 'SYSTEM' THEN ' AUTOALLOCATE'
	                    WHEN dt.allocation_type = 'UNIFORM' THEN ' UNIFORM SIZE '|| dt.initial_extent/1024/1024 || 'M'
                    END ||	CHR(10) ||
                    'SEGMENT SPACE MANAGEMENT ' || dt.segment_space_management AS tablespace_definition,
                    'CREATE USER ' || df.tablespace_name || ' IDENTIFIED BY ' || 
                    CASE
	                    WHEN INSTR(df.tablespace_name,'_', 1) > 0 
		                    THEN SUBSTR(LOWER(df.tablespace_name), 1, INSTR(df.tablespace_name,'_', 1) - 1)
	                    ELSE LOWER(df.tablespace_name)
                    END || CHR(10) || 'DEFAULT TABLESPACE ' || df.tablespace_name || CHR(10) ||
                    'QUOTA UNLIMITED ON ' || df.tablespace_name AS user_definition
                    FROM dba_data_files df
                    LEFT JOIN dba_tablespaces dt
                    ON df.tablespace_name = dt.tablespace_name
                    LEFT JOIN (SELECT tablespace_name, sum(bytes) AS UsedSpace_mb
			                    FROM dba_segments
			                    GROUP BY tablespace_name) seg
	                    ON seg.tablespace_name = df.tablespace_name
                    WHERE NOT REGEXP_LIKE (df.tablespace_name, 'SYSTEM|SYSAUX|USERS|UNDO')
                    GROUP BY df.tablespace_name, 
                             dt.bigfile,
		                     df.file_name, 
		                     dt.segment_space_management, 
		                     dt.extent_management,
		                     dt.initial_extent, 
		                     dt.allocation_type,
		                     seg.usedSpace_mb
                    ORDER BY 1]';

    EXECUTE IMMEDIATE sql_stmt;
   
END;
/"

#Run the annonymous stored proc in the target source database and generate the TablespaceDefinition table
$GetDefinitions = $SQL -f $DestDataFileDirectory | SQLPLUS -silent "$SourceDBUser/`"$SourceDBPassword`"@$SourceDBTNSName" 

$SQL = "SET FEEDBACK OFF
SET PAGES 0
SELECT tablespace_definition || ';' || CHR(10) || CHR(10) || user_definition || ';'
FROM TablespaceDefinition;"

$Output = $SQL | SQLPLUS -silent "$SourceDBUser/`"$SourceDBPassword`"@$SourceDBTNSName"

Write-Output $Output | Out-File -FilePath $OutputFile  -Force


if ($mode -ne "manual")
{
    # loop to create each user and tablespace definition taken from the source database in the target database 
    foreach ($row IN $ddl_cmd)
    {
        $SQL = "
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

        $SQL | sqlplus -silent "$TargetDBUser/`"$TargetDBPassword`"@$TargetDBTNSName" 
    
    }
}