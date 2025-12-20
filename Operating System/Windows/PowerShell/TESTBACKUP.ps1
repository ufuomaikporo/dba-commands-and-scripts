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

#Function to check for the location of a logfile and remove it if it already exists. Takes full filepath as an argument
Function CheckFileExists([string] $FilePath)
	{
		If (Test-path $FilePath ) 
			{
				remove-item $FilePath 
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

$ServerName = "ORA19C"

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
WHERE 
  UPPER (USERNAME) = 'SDE'"
# $GetSchemaQuery = "SELECT username FROM ALL_USERS 
# WHERE 
#   UPPER (USERNAME) IN('SDE',  'BPAZB_PODS5_STAGE', 'PNET', 'PNET_USER') 
#   OR UPPER(USERNAME) LIKE '%_OWNR' 
#   AND USERNAME NOT IN ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','ORDSYS','ORDPLUGINS','MDSYS','CTXSYS',
#     'XDB','ANONYMOUS','WKSYS','WKPROXY','ODM','ODM_MTR','OLAPSYS','RMAN','HR',
#     'OE','PM','SH','QS_ADM','QS','QS_WS','QS_ES','QS_OS','QS_CBADM','QS_CB','QS_CS','SCOTT',
#     'BI', 'DIP', 'MDDATA', 'TSMSYS', 'SYSMAN', 'SI_INFORMTN_SCHEMA', 'MGMT_VIEW',
#     'DMSYS', 'EXFSYS', 'IX''JAGDISH','XS$NULL','SPATIAL_WFS_ADMIN_USR','SPATIAL_CSW_ADMIN_USR','OWBSYS_AUDIT','OWBSYS','ORDDATA','FLOWS_FILES','APPQOSSYS','APEX_PUBLIC_USER','APEX_030200')
# ORDER BY USERNAME";

#Set backup, logfile, and archive locations
# $BuLocation = "B:\Backups\"
$NightlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$ServerName\Nightly\" 
$BuLocation = $NightlyLoc
$BuLogFile = $ServerName + "_BULog_Nightly.txt"
$ArchiveLoc = "\\DRAS-FILE01\DBBackups\$ServerName\"
$WeeklyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$ServerName\Weekly\"
$MonthlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$ServerName\Monthly\"

#SQL command to set the directory for Oracle Datapump operations
$SetBackupLoc = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation';
GRANT READ,WRITE ON DIRECTORY DATAPUMP TO DBBACKUPUSER;"

#Connection string that will be used to connect to the Oracle Database
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=ORA19C.cgy.dynamicrisk.net)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=ORA19C.cgy.dynamicrisk.net)));User Id=DBBACKUPUSER;Password=DBBACKUPUSER;"

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

############################################## NIGHTLY BACKUP #################################################

#Verify that the backup locations and delete logfile if it already exists
CheckLocationExists $BuLocation
CheckFileExists ($BuLocation + $BuLogFile)
CheckLocationExists $WeeklyLoc
CheckLocationExists $MonthlyLoc
CheckLocationExists $ArchiveLoc

#Save the location from where the Script file is being run to the output logfile.
Out-File -FilePath "$BuLocation$BuLogFile"  -append -inputobject ("Script Ran from: " + $myinvocation.mycommand.path)

#Check to ensure that backups are only performed on weekdays
if (1,2,3,4,5 -contains [int]$CurrentDate.DayOfWeek )
{
#Loop through all of the schemas that need to be backed up on the server and backup each one
	foreach ($Schema in $SchemaList)
	{ 
		$SchemaUser = $Schema.USERNAME
		try 
		{
			$StartTime = "Start time - " + (get-date -Displayhint datetime)
			
			#Store the backup command in a variable and execute the command
			Invoke-Command -ScriptBlock {expdp DBBACKUPUSER/DBBACKUPUSER@$ServerName schemas= "$SchemaUser" `
			DIRECTORY=DATAPUMP REUSE_DUMPFILES=Y DUMPFILE="$SchemaUser.dmp" LOGFILE="$SchemaUser.log"}
			
			$EndTime = "End time - " + (get-date -Displayhint datetime)
			
			#Writes success message and the backup start and end times to the output logfile if the backup command is successfull
			$Message = $BackupSuccessMessage -f $SchemaUser, $StartTime, $EndTime
			Out-file  -filepath "$BuLocation$BuLogFile" -append -inputobject $Message

			#Copy backup file to Nightly backup location
			#Copy-Item ($BuLocation + $SchemaUser + ".*") $NightlyLoc 
		} 
		catch 
		{
			$err=$Error[0]

			#Write an error message and redirect the server error message to the output logfile if the backup fails
			$Message = $BackupFailMessage -f $SchemaUser, $StartTime, $err
			Out-File -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message
			($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BuLocation$BuLogFile"  -append	
		}
	} #end of foreach-loop 

	#Copy the output logfile over to the nightly backup location
	#Copy-Item ($BuLocation + $BuLogFile) $NightlyLoc 

} #end of if-statement

##################################### Weekly, Monthly and Archival Backups ######################################

<#
If the script is being run on a Friday, archive each database backup and copy the archive file both to the 
weekly backup location and the Tape Drive Folder for SysAdmin storage. If it is the last Friday of 
the month copy the archive file to the monthly backup location
#>
<#
If ($Currentdate.DayOfWeek -eq 'Friday')
{
#Clean up the file locations of old files in order to minimize the disk space consumed. 
Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).Adddays(-60).ToString("yyyy-MM-dd")} | remove-item
Get-ChildItem $ArchiveLoc | Where-Object {$_.Lastwritetime -lt (Get-date).AddDays(-1).ToString("yyyy-MM-dd")} | remove-item

$BuSourceList = Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq ".dmp"}

	foreach ($BUFile in $BuSourceList)
	{
		#Location of the Winrar executable file  
		$WinRar = "C:\Program Files\WinRAR\rar.exe"

		#Set FullName path for the archive file where compressed backup files will be stored
		$ArchiveFile = $weeklyLoc + $BUFile.BaseName +".rar"

		#Deletes the Archive file if it already exists
		CheckFileExists $ArchiveFile

		#Execute command to compress backup files into an archive file
		& $winrar a -ibck -y $ArchiveFile $BUFile.FullName 	

		#Copy the compressed archvive file to DEVGIS for weekly archival. 
		Copy-Item $ArchiveFile $ArchiveLoc
        
		# If the backup begins on the last friday of the month copy the compressed weekly database set to the monthly folder
		if ($Currentdate.Date -eq $LastFriday.Date)
		{
			Copy-Item $ArchiveFile $MonthlyLoc
		}
	}
}

############################################## EMAIL DBAs #########################################################

#Checks for an error message in the logfile. Returns true at the first instance of the word 'failed' within the logfile
$LogFileError = Select-string "$BuLocation$BuLogFile" -pattern "failed" -Quiet

#If there is an error message in the logfile, send an email with appropriate instructions in the body. Otherwise, send
#a success message
if ($LogFileError -eq "True")
{
	$EmailBody = $FailEmailMessage
	$EmailPriority = "High" 
}
else
{
	$EmailBody = $SuccessEmailMessage
	$EmailPriority = "Low" 
}

#Construct and send the email message
Send-MailMessage `
-To "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net", "ufuoma_ikporo@dynamicrisk.net" `
-From "Jagdish_Chaudhary@dynamicrisk.net" `
-Subject "$servername Database Backup report." `
-attachment "$BuLocation$BuLogFile" `
-priority $EmailPriority `
-SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
-Body $EmailBody

#>