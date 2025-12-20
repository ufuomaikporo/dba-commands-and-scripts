<#

This script does the following...
1) performs logical backups (using Oracle Datapump) for an Oracle database
2) creates compressed archive files using Winrar that are stored as weekly, archival and monthly backups

This script should be...
1) Ran only on an Oracle Server
2) Ran via Windows Task Scheduler.  
3) Designated to Run Every Night at 11pm.
In Task Scheduler issue the following command. 
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noninteractive -nologo <File Location where the Script is saved>

All backups should be tasked to start at 11PM.
Nightly backups will be issued at 11pm Monday, Tuesday, Wednesday, Thursday and Friday.
Weekly backups will be issued at 11pm every Friday and archived in archival backup location. 
Monthly backups will be issued at 11pm on the last Friday of each Month.

#>

#################################################################################################################
# PREREQUISITES
#################################################################################################################

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

#################################################################################################################
# FUNCTIONS
################################################################################################################## 

#Function to check for the location of a file. Takes full filepath as an argument
Function CheckFileExists([string] $FilePath)
	{
		If (Test-path $FilePath ) 
			{

			    Clear-Content $FilePath 
			}
	}


# Function to Check a directory path location (i.e. backup location). Creates the directory if it does not exist 
Function CheckLocationExists ([string] $Directory)
	{
		If (!(Test-Path -path $Directory))  
			{ 
				New-item -type directory $Directory
			} 
	}

##################################################################################################################
# VARIABLE DECLARATION/INITIALIZATION
################################################################################################################## 

$ServerName = HOSTNAME.EXE
$DBHostName = "$ServerName.cgy.dynamicrisk.net"
$DBServiceName = $DBHostName

$User = 'system'
$Password = 'ty^9!nm~'

$BackupSuccessMessage = @" 

Schema: "{0}" on Server: $ServerName Backup successful!
{1} 
{2}

"@

$BackupFailMessage = 
@" 

****************************************************************************
Error 
Schema: {0} on Server: $ServerName Backup failed!
{1} 

{2}
****************************************************************************

"@

$FailEmailMessage = @"
Databases backup on $servername occured with errors.
Please refer to attached log file for more information.
"@

$SuccessEmailMessage = @"
Database backup on $servername occured successfully.
"@

#Query to generate a list of Oracle users/schemas that need to be backed up.
$GetSchemaQuery = "SELECT username FROM ALL_USERS 
/* WHERE 
  UPPER (USERNAME) IN('SDE',  'BPAZB_PODS5_STAGE', 'PNET', 'PNET_USER') 
  OR UPPER(USERNAME) LIKE '%_OWNR' 
  AND USERNAME NOT IN ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','ORDSYS','ORDPLUGINS','MDSYS','CTXSYS',
    'XDB','ANONYMOUS','WKSYS','WKPROXY','ODM','ODM_MTR','OLAPSYS','RMAN','HR',
    'OE','PM','SH','QS_ADM','QS','QS_WS','QS_ES','QS_OS','QS_CBADM','QS_CB','QS_CS','SCOTT',
    'BI', 'DIP', 'MDDATA', 'TSMSYS', 'SYSMAN', 'SI_INFORMTN_SCHEMA', 'MGMT_VIEW',
    'DMSYS', 'EXFSYS', 'IX''JAGDISH','XS$NULL','SPATIAL_WFS_ADMIN_USR','SPATIAL_CSW_ADMIN_USR','OWBSYS_AUDIT','OWBSYS','ORDDATA','FLOWS_FILES','APPQOSSYS','APEX_PUBLIC_USER','APEX_030200')
*/
ORDER BY USERNAME";

#Set backup, logfile, and archive locations
$BuLocation = "B:\Backups\ALL_USER_CREATED_SCHEMAS\"
#$NightlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$ServerName\Nightly\" 
#$BuLogFile = $ServerName + "_BULog_Nightly.txt"
#$ArchiveLoc = "\\DRAS-FILE01\DBBackups\$ServerName\"
#$WeeklyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$ServerName\Weekly\"
#$MonthlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$ServerName\Monthly\"

$DataFileDir = "E:\oradata\ora12c\"

#SQL command to set the directory for Oracle Datapump operations
$SetBackupLoc = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation' "

#Connection string that will be used to connect to Oracle Datapump utility
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DBHostName)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=$user;Password=$Password;"

##################################################################################################################
# EXECUTION
##################################################################################################################

############################################### SQL QUERIES #################################################

#PowerShell Object for setting the string used to open an Oracle database
$Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

#Create command to execute $GetSchemaQuery
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $GetSchemaQuery
$SQLCMD.CommandTimeout = 60 #seconds

#PowerShell object to store the results from an SQL query
$SchemaList = New-Object System.Data.DataTable

#Connect to the database and and execute the query to fill the datatable object (i.e. get schema list)
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($SchemaList)

#Create the command to set the Oracle DataPump directory to the backup directory
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $SetBackupLoc
$SQLCMD.CommandTimeout = 60 #seconds

#Stores output of command for setting DataPump directory
$Void = New-Object System.Data.DataTable

#Execute command to set the Oracle DataPump directory to the backup location
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($Void)

#Stop watch to keep track of time it takes to complete a backup
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

#Get the DateTime value for the last Friday (weekday value of 5) of the month
$DayOfWeek = 5
$CurrentDate = get-date
$NextMonth = $CurrentDate.AddMonths(1)
$LastDayOfCurrentMonth = $NextMonth.AddDays(-$NextMonth.Day)
if ([int]$LastDayOfCurrentMonth.DayOfWeek -ge $DayOfWeek) {
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$LastDayOfCurrentMonth.DayOfWeek + $DayofWeek)
}
else {
    $SubtractDays = [int]$LastDayOfCurrentMonth.DayOfWeek + (7 - [int]$DayofWeek)
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$SubtractDays)
}


$BUFiles = (Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq '.DMP'}).BaseName
#$SchemaList = $SchemaList | Where-Object {$_ -eq 'ETPTEST'}
$BUFiles = $BUFiles | Where-Object {$_ -notin $SchemaList.Username}
$SchemaList = $BUFiles
#$SchemaList | Sort-Object


############################################## NIGHTLY BACKUP #################################################

#Verify that the backup directories/locations exist
CheckLocationExists $BuLocation
#CheckLocationExists $WeeklyLoc
#CheckLocationExists $MonthlyLoc
#CheckLocationExists $ArchiveLoc

#Save the location from where the Script file is being run to the output logfile.
#Out-File -FilePath "$BuLocation$BuLogFile"  -Force -inputobject ("Script Ran from: " + $myinvocation.mycommand.path)

#Start stop watch
$StopWatch.Start()

#Loop through all of the schemas in the directory and import each one
foreach ($Schema in $SchemaList)
{ 

		$StartTime = "Start time - " + (get-date -Displayhint datetime)
##############################################################
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DBHostName)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=$User;Password=$Password;"

#PowerShell Object for setting the string used to open an Oracle database
$Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

$Schema_2 = $Schema -replace '_OWNR'

$SQL = "DECLARE
    CNT NUMBER;
BEGIN
   
    SELECT COUNT(*) INTO CNT
    FROM dba_tablespaces
    WHERE tablespace_name = '{0}';

    IF CNT = 0 THEN
        EXECUTE IMMEDIATE ('CREATE BIGFILE TABLESPACE {0}
        DATAFILE ''{1}'' SIZE 15G REUSE
        AUTOEXTEND ON NEXT 200M MAXSIZE 20G
        EXTENT MANAGEMENT LOCAL AUTOALLOCATE
        SEGMENT SPACE MANAGEMENT AUTO');
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM ALL_USERS 
    WHERE USERNAME = '{0}';

    IF CNT = 0 THEN
        EXECUTE IMMEDIATE ('CREATE USER {0} IDENTIFIED BY {0} DEFAULT TABLESPACE {0} QUOTA UNLIMITED ON {0}');
    ELSE
        EXECUTE IMMEDIATE ('ALTER USER {0} IDENTIFIED BY {0} DEFAULT TABLESPACE {0} QUOTA UNLIMITED ON {0}');     
    END IF;

-- Create Normal User
     SELECT COUNT(*) INTO CNT
    FROM dba_tablespaces
    WHERE tablespace_name = '{2}';

    IF CNT = 0 THEN
        EXECUTE IMMEDIATE ('CREATE TABLESPACE {2}
        DATAFILE ''{3}'' SIZE 8G REUSE
        AUTOEXTEND ON NEXT 200M MAXSIZE 10G
        EXTENT MANAGEMENT LOCAL AUTOALLOCATE
        SEGMENT SPACE MANAGEMENT AUTO');
    END IF;

    SELECT COUNT(*) INTO CNT
    FROM ALL_USERS 
    WHERE USERNAME = '{2}';

    IF CNT = 0 THEN
        EXECUTE IMMEDIATE ('CREATE USER {2} IDENTIFIED BY {2} DEFAULT TABLESPACE {2} QUOTA UNLIMITED ON {2}');
    ELSE
        EXECUTE IMMEDIATE ('ALTER USER {2} IDENTIFIED BY {2} DEFAULT TABLESPACE {2} QUOTA UNLIMITED ON {2}');     
    END IF;
END;
"



#Create command to execute $GetSchemaQuery
$DataFile = $DataFileDir + $schema + ".dbf"
$DataFile_2 = $DataFileDir + $Schema_2 + ".dbf"
$Command = $SQL -f $schema, $DataFile, $Schema_2, $DataFile_2

$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $Command
$SQLCMD.CommandTimeout = 60 #seconds

#PowerShell object to store the results from an SQL query
$QueryResult = New-Object System.Data.DataTable

#Connect to the database and and execute the query to fill the datatable object (i.e. get schema list)
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($QueryResult)


###################################################################
		
		#Import Schema
		Invoke-Command -ScriptBlock {impdp $User/$Password@$ServerName schemas= "$Schema" `
		DIRECTORY=DATAPUMP DUMPFILE="$Schema.dmp" LOGFILE="$Schema.log" TABLE_EXISTS_ACTION=REPLACE}
		

} #end of foreach-loop 
#>
