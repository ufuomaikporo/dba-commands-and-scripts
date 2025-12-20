<#

This script does the following...
1. Performs a FULL backup if the script is executed on a Monday betwen 12AM-9AM (inclusive)
2. Performs a DIFFERENTIAL backup every other day it is ran, except for the case when a base FULL backup is
   missing, whereby it will perfrom a FULL database backup
2. Compresses the backup set at the end of each week into a Winrar archivefile to be stored in a weekly backup
   location if the script is executed on a Friday evening on or after 6PM
3. Stores the last weekly backup of the month in the monthly backup location if the script is executed on 
   the last Friday of the month

This script should be... 
1. Ran ONLY on Microsoft SQL Server databases
2. Ran via Windows Task Scheduler.  
3. Designated to Run 
    i) Every Weekight (Mon-Fri) at 11PM - For a Nightly INCREMENTAL Backup
    ii) Daily at 11:59AM - For a Midday INCREMENTAL Backup
    iii) Every Monday Morning at 12AM - For Weekly FULL backup

In Task Scheduler issue the following command. 
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noninteractive -nologo <File Location where the Script is saved>

All nightly backups should be tasked to start at 11PM.
Nightly backups will be issued at 11pm Monday, Tuesday, Wednesday, Thursday and Friday.
Weekly backups will be issued at 11pm every Friday. 
Monthly backups will be issued at 11pm on the last Friday of each Month.

#>

##################################################################################################################
# FUNCTIONS
##################################################################################################################

#This Function checks for the existence of a file (log file in this instance) 
# and removes if it exists. The full file path must be entered as an argument
Function CheckFileExists([string] $File)
{
	If (Test-path $File) 
		{
			return $true
			
		}
}

#This Function checks for the existence of directories/folders and exits the script if one of the 
#neccessary directories is not found
Function CheckLocation([string] $Directory)
{
	if (!(Test-path $Directory)) {

        New-item -type directory $Directory | Out-Null
	}
}

#############################################################################################################
# VARIABLE DECLARATION
#############################################################################################################

$InstanceName = HOSTNAME.EXE


$FolderName = $InstanceName.Replace('\', '_')

#Get the data and time for the last Friday (weekday value of 5) of the month
$DayOfWeek = 5 
$CurrentDate = Get-Date 
$NextMonth = $CurrentDate.AddMonths(1)
$LastDayOfCurrentMonth = $NextMonth.AddDays(-$NextMonth.Day)
if ([int]$LastDayOfCurrentMonth.DayOfWeek -ge $DayOfWeek) {
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$LastDayOfCurrentMonth.DayOfWeek + $DayofWeek)
}
else {
    $SubtractDays = [int]$LastDayOfCurrentMonth.DayOfWeek + (7 - [int]$DayofWeek)
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$SubtractDays)
}

# Variable to store the number of days since the last FULL backup
$StartOfWeek = ($CurrentDate).Date.AddDays(-1 - ($CurrentDate).DayOfWeek.value__)
$DaySinceFullBackup = (New-TimeSpan -End $CurrentDate -Start $StartOfWeek).Days

#-------------------------------------- FOLDERS AND BACKUP DIRECTORIES -----------------------------

#Nightly backup storage location
$BuLocation = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$FolderName\Nightly\"

#Archive (for SysAdmin), Weekly, and Monthly backup locations
$ArchiveLoc = "\\DRAS-FILE01\DBBackups\$FolderName\"
$WeeklyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$FolderName\Weekly\"
$MonthlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$FolderName\Monthly\"

#File name for logfile that will store output of this backup script
$BuLogFile =  $BULocation + "$($FolderName)_BULog_Nightly.txt"

#----------------------------------- DYNAMIC QUEIRES ---------------------------------

#This function builds the backup device and executes an INCREMENTAL BACKUP
$FullBackupCommand = "BACKUP DATABASE {1}   
                        TO DISK = '{0}{1}.bak'   
                          WITH FORMAT,
                          NAME = '{1} Backupset',
                          DESCRIPTION = '{1} Full Weekly Backup'; 
                        GO"

$DiffBackupCMD = "BACKUP DATABASE {1}   
                    TO DISK = '{0}{1}.bak'  
                        WITH DIFFERENTIAL,
                        NAME = '{1} Backupset',
                         DESCRIPTION = '{1} Differential Backup';
                    GO"

$DailyBackupList = "SELECT name, state_desc AS Status FROM sys.databases 
                    WHERE name LIKE '%IRAS%'
                    ORDER BY 1"

$EOMBackupList = "SELECT name, state_desc AS Status FROM sys.databases 
                  WHERE database_id > 4
                  ORDER BY 1"


#This function builds the backup device and executes an INCREMENTAL BACKUP
$FullBackupCommand = "BACKUP DATABASE {1}   
                        TO DISK = '{0}{1}.bak'   
                          WITH FORMAT,
                          NAME = '{1} Backupset',
                          DESCRIPTION = '{1} Full Weekly Backup'; 
                        GO"

$DiffBackupCMD = "BACKUP DATABASE {1}   
                    TO DISK = '{0}{1}.bak'  
                        WITH DIFFERENTIAL,
                        NAME = '{1} Backupset',
                         DESCRIPTION = '{1} Differential Backup';
                    GO"

# Query to check that a full database backup already exists
$CheckForFullBackup = "IF EXISTS (
    SELECT 
       CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
       msdb.dbo.backupset.database_name, 
       msdb.dbo.backupset.backup_start_date, 
       msdb.dbo.backupset.backup_finish_date, 
       msdb.dbo.backupset.expiration_date, 
       CASE msdb..backupset.type 
          WHEN 'D' THEN 'Database' 
          WHEN 'L' THEN 'Log' 
          END AS backup_type, 
       msdb.dbo.backupset.backup_size, 
       msdb.dbo.backupmediafamily.logical_device_name, 
       msdb.dbo.backupmediafamily.physical_device_name, 
       msdb.dbo.backupset.name AS backupset_name, 
       msdb.dbo.backupset.description 
    FROM 
       msdb.dbo.backupmediafamily 
       INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
    WHERE 
       (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - $DaySinceFullBackup) 
       AND  msdb.dbo.backupset.database_name like '{0}'
       AND description LIKE '%Full%Backup%'
    )
    BEGIN
        SELECT 1 AS IfExists
    END
    ELSE
    BEGIN
        SELECT 0 AS IfExists
    END"

#----------------------------------------- EMAIL MESSAGE VARIABLES --------------------------------------

$EmailSubjectLine = "$InstanceName Database Backup report."

#Message written to output logfile if a backup is successful
$SuccessLogMessage = @" 

Database: {0} on Server: $InstanceName {1} Backup successful!
{2} 
{3}

"@

#Message written to output logfile if a backup fails
$FailLogMessage = 
@" 

****************************************************************************
Error 
Database: {0} on Server: $InstanceName {1} Backup failed!
{2} 

{3}
****************************************************************************

"@

#Message in email body of email that is sent to DBAs if a backup fails
$FailEmailBody = @"
Databases backup on $InstanceName occured with errors.
Please refer to attached log file for more information.
"@

#Message in the email body of the email sent to DBAs if he backup is successful
$SuccessEmailBody =  @"
Database backup on $InstanceName occured successfully.
"@

###########################################################################################################
# EXECUTION
###########################################################################################################

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

if ($LastFriday.AddDays(-5).Date -eq $CurrentDate.Date)
{
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $EOMBackupList  -QueryTimeout 200
   # write-host "end of month backup"
}
else
{
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $DailyBackupList  -QueryTimeout 200
    #Write-host "iras backup"
}

#Check for the location and existence of the backup directories and logfile (deletes the logfile if it exists)
CheckLocation -Directory $BuLocation
CheckLocation -Directory $WeeklyLoc
CheckLocation -Directory $MonthlyLoc

#Write to the output log the location of the Script file as it was run.
out-file -filepath "$BULogFile"  -Force -inputobject ("Script Ran from: " + $myinvocation.mycommand.path)

############################################## NIGHTLY BACKUP ##################################################

$StopWatch.Start()

#Perform FULL database backups on Sunday (ONCE A WEEK) if the script is ran on a Sunday after 10pm
if ($CurrentDate.DayOfWeek -eq "Sunday" -and $CurrentDate.TimeOfDay.Hours -ge 22)
{
 #loop through all of the databases on the server to backup each database
    foreach ($DB in $DBBackupList)  
    {    
        # Check the status of the database to ensure that it is online and running normally.                
        if ($DB.Status -eq "ONLINE")
        {
            try 
            {
                $EmailSubjectLine = "Full New Weekly : $InstanceName Database Backup report."

                #Call the backup function and record the start and end times for the backup operation 
                $StartTime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "FULL backup up of $($DB.Name)" 
               
                $SQL = $FullBackupCommand -f $BULocation, $DB.Name
                Invoke-Sqlcmd -ServerInstance $ServerName -Database "master" -Query $SQL -QueryTimeout 1800  
                
                #Allow Windows process some time to release the logfile
                Start-Sleep -Seconds 0.5

                $EndTime = "End time - " + (get-date -Displayhint datetime)

                #if the backup up completes successfully write the success message to the log file
                $Message = $SuccessLogMessage -f $DB.Name, 'FULL',$StartTime, $EndTime
                Out-file  -filepath "$BULogFile"  -append -inputobject $Message
            } 
            catch 
            {
                #if the backup is unsuccessfull save and write the error (with a message) to the logfile

                $err=$Error[0]

                #Add user created error message to the logfile
                $Message = $FailLogMessage -f $DB.Name, 'FULL', $StartTime, $err
                Out-File -filepath "$BULogFile"  -append -inputobject $Message

                #Add detailed error message (from SQL Sever) to the logfile
                ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BULogFile"  -append
            }
        } #end of 2nd inner if-statement
    } #end of foreach-loop
} #end of if-statment

#Perform incremental backups only if the script is ran on a weekday (Mon, Tues, Wed, Thurs, Fri) after 9AM
if (1,2,3,4,5 -contains [int]$CurrentDate.DayOfWeek -and $CurrentDate.TimeOfDay.Hours -gt 6)
{

    #loop through all of the databases on the server to backup each database
    foreach ($DB in $DBBackupList)  
    {    
        #Check if a full backup already exists 
        $SQL = $CheckForFullBackup -f $DB.name 
        $FullBackupExists = Invoke-Sqlcmd -ServerInstance $InstanceName -Database master -Query $SQL

        #Check if a backup file exists for the database with the following specified backup file name
        $File = $BuLocation + $DB.name + ".bak"
        $FileExists = (Test-Path $File -PathType Leaf)   

        # if the database status is normal, and if a full backup exists within a backup file, then perform differential backup               
        if ($DB.Status -eq "ONLINE" -and $FileExists -and $FullBackupExists.IfExists -eq 1)
        {                
            try 
            {
                #Execute the backup function and record the start and end time for backup operation 
                $StartTime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "DIFFERENTIAL backup up of $($DB.Name)" 

                $SQL = $DiffBackupCMD -f $BULocation, $DB.Name
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 1800
                
                #Allow Windows process some time to release the logfile
                Start-Sleep -Seconds 0.5

                $EndTime = "End time - " + (get-date -Displayhint datetime)

                #if the backup up completes successfully write the success message to the log file
                $Message = $SuccessLogMessage -f $DB.Name, 'DIFFERENTIAL',$StartTime, $EndTime
                Out-file  -filepath "$BULogFile"  -append -inputobject $Message
            } 
            catch 
            {
                #if the backup is unsuccessfull save and write the error with a message to the logfile

                $err=$Error[0]

                #Add user created error message to the logfile
                $Message = $FailLogMessage -f $DB.Name, 'DIFFERENTIAL', $StartTime, $err
                Out-File -filepath "$BULogFile"  -append -inputobject $Message

                #Add detailed error message (from SQL Sever) to the logfile
                ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BULogFile"  -append
            }
        }
        #If a full backup does not already exist, perform a full backup
        else 
        {          
            try 
            {
               
                $Starttime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "FULL backup of $($DB.Name)" 

                $SQL = $FullBackupCommand -f $BULocation, $DB.Name
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 1800
  
                #Allow Windows process some time to release the logfile
                Start-Sleep -Seconds 0.5

                $Endtime = "End time - " + (get-date -Displayhint datetime)

                $Message = $SuccessLogMessage -f $DB.Name, 'FULL', $StartTime, $EndTime
                Out-file  -filepath "$BULogFile"  -append -inputobject $Message
            } 
            catch 
            {
                $err=$Error[0]
                $err

                #Add user created error message to the logfile
                $Message = $FailLogMessage -f $DB.Name, 'FULL', $StartTime, $err
                Out-File -filepath "$BULogFile"  -append -inputobject $Message

                #Add detailed error message (from SQL Sever) to the logfile
                ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BULogFile"  -append
            }
        } #end of else-statement
    } #end of foreach-loop
} #end of outer if-statement
            
####################################### WEEKLY & MONTHLY BACKUP ##########################################
            
<#
If the script is being run on a Friday evening at or after 6PM, archive each database backup and copy the 
archive file both to the weekly backup location and the Tape Drive Folder for SysAdmin storage. If it is the 
last Friday of the month, copy the archive file to the monthly backup location as well
#>

if ($CurrentDate.DayOfWeek -eq "Friday" -and $CurrentDate.TimeOfDay.Hours -ge 18) 
{
    Write-Host "`r`n****************************** CREATING WEELY BACKUPS ******************************`r`n"

    #Clean up the file locations of old files in order to minimize the disk space consumed. 
    Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-60)} | remove-item
    #Get-ChildItem $ArchiveLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-7)} | remove-item
    
    #Get a list of the BackupFiles in the nightly backup location
    $BUFilesList = Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq ".bak" -and $_.LastWriteTime -ge $CurrentDate.AddDays(-5)}

    #Archive the nightly backups by adding each nightly backup file to a compressed archive file of the same name
    foreach ($BUFile in $BUFilesList)
    {   
        #Location of the Winrar executable file  
        $WinRar = "C:\Program Files\WinRAR\rar.exe"

        #Name and location of archive file where compressed backup files will be stored
        $ArchiveFile = $weeklyLoc + $BUFile.BaseName +".rar"

        #Execute command to compress backup files into an archive file
        & $winrar u -ep -ibck -y $ArchiveFile ($BuLocation + $BUFile)   	

        #If it is the last friday of the month, copy the weekly archive file to the monthly backup folder
        if ($CurrentDate.Date -eq $LastFriday.Date)
        {
            Write-Output "`r`n************** Moving archived zip file to the monthly backup location **************`r`n"
            Copy-Item $ArchiveFile $MonthlyLoc
        }
    } #end of foreach-loop
} #end of if-statement

$StopWatch.Stop()

$TotalTime = $StopWatch.Elapsed

Out-File -filepath "$BULogFile"  -append -inputobject ("`r`nTotal Time to Complete Backup: " + ($TotalTime).ToString("hh'hr:'mm'min:'ss'sec'"))


################################################# EMAIL DBAs ############################################# 

#Checks for an error message in the logfile so DBAs can be noified. Looks for first instance of the word 'failed'
$LogFileError = Select-string "$BULogFile" -pattern "failed" -Quiet

#If there is an error message in the logfile, send an email with appropriate instructions in the body. Otherwise, send
#a success message
if ($LogFileError -eq $true)
	{
        $EmailBody = $FailEmailBody
	    $EmailPriority = "High" 
	}	
else
	{
        $EmailBody = $SuccessEmailBody
		$EmailPriority = "Low" 
	}


$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net", "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 


#Construct and send the email message
Send-MailMessage `
-To $EmailRecipientList `
-From "HP9000@dynamicrisk.net" `
-Subject $EmailSubjectLine `
-attachment "$BULogFile" `
-priority $emailPriority `
-SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
-Body $emailBody

#>

