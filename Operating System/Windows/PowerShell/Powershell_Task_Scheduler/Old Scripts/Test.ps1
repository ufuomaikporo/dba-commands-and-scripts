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
# PREREQUISITES
##################################################################################################################

#Add all of the neccessary SQL Server Snapins for Powershell if they aren't already present
if ( Get-PSSnapin -Registered | Where-Object {$_.name -eq 'SqlServerProviderSnapin100'} )
{ 
    if( !(Get-PSSnapin | Where-Object {$_.name -eq 'SqlServerProviderSnapin100'})) 
    {  
        Add-PSSnapin SqlServerProviderSnapin100 | Out-Null 
    } ;  
    if( !(Get-PSSnapin | Where-Object {$_.name -eq 'SqlServerCmdletSnapin100'})) 
    {  
        Add-PSSnapin SqlServerCmdletSnapin100 | Out-Null 
    } 
} 
else 
{ 
    if( !(Get-Module | Where-Object {$_.name -eq 'sqlps'})) 
    {  
        Import-Module 'sqlps' –DisableNameChecking 
    } 
} 

#Set the default hardrive location
Set-Location B:

#Load the following assemblies to access the SQL server framework. Should work in SQL server 2005,SQL2008 and 2008R2
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

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

        New-item -type directory $Directory
	}
}

<#
Refer to the following website for the source of this code that preforms the actual Backup.
http://cyrilgupta.com/?p=441
http://codeblog.theg2.net/2010/06/powershell-backup-all-databases-locally.html
#>

#This function builds the backup device and executes an INCREMENTAL BACKUP
Function Backup-SqlDBDiff( [String]$DB, $servername)
	{
        $smoBackup = New-Object("Microsoft.SqlServer.Management.Smo.Backup")
		$smoBackup.Action = "Database"
		$smoBackup.BackupSetDescription = "Differential backup of " + $DB
		$smoBackup.BackupSetName = $DB + " Backup"
		$smoBackup.Database = $DB
		$smoBackup.MediaDescription = "Disk"
		$smoBackup.Initialize = $FALSE
        $Device = $BuLocation+$DB +".bak"
		$smoBackup.Devices.AddDevice($Device, "File")
		$smoBackup.Incremental = $TRUE
        $smoBackup.FormatMedia = $FALSE
        $smoBackup.NoRewind = $TRUE
        $smoBackup.SqlBackup($Server) #Make the backup
        
	}

#This function builds the backup device and executes a FULL BACKUP
Function Backup-SqlDBFull( [String]$DB, $servername)
	{
        $smoBackup = New-Object("Microsoft.SqlServer.Management.Smo.Backup")
		$smoBackup.Action = "Database"
		$smoBackup.BackupSetDescription = "Full backup of " + $DB
		$smoBackup.BackupSetName = $DB + " Backup"
		$smoBackup.Database = $DB
		$smoBackup.MediaDescription = "Disk"
        $Device = $BuLocation+$DB +".bak"
		$smoBackup.Devices.AddDevice($Device, "File")
		$smoBackup.Incremental = $FALSE
        $smoBackup.FormatMedia = $TRUE
        $smoBackup.Initialize = $TRUE
        $smoBackup.SkipTapeHeader = $TRUE
        $smoBackup.NoRewind = $TRUE
        $smoBackup.SqlBackup($Server) #Make the backup
        
	}

###########################################################################################################
# VARIABLE DECLARATION/INITIALIZATION
###########################################################################################################

#Create a new object to store database properties/information
$Server = New-Object ("Microsoft.SqlServer.Management.Smo.Server")
$Server.ConnectionContext.StatementTimeout = 0
$ServerName = $Server.name 

#PSObject that stores properties of all databases on the server
$Databases = $Server.Databases 

#List of databases that will be excluded from backups
$ExcludeDB = @("tempdb",  "master", "msdb", "model" ,"ReportServer" ,"ReportServerTempDB")

#An object made up of database properties for all databases that will be backed-up
$BackupDBsList = $Databases | Where-Object {$ExcludeDB -NotContains $_.Name}

#Nightly backup storage location
$BuLocation = "B:\Database_Backups\DB_Backups_Nightly\$ServerName\Nightly\"

#Archive (for SysAdmin), Weekly, and Monthly backup locations
#$ArchiveLoc = "\\DRAS-FILE01\DBBackups\$ServerName\"
$WeeklyLoc = "B:\Database_Backups\DB_Backups_Monthly\$ServerName\Weekly\"
$MonthlyLoc = "B:\Database_Backups\DB_Backups_Monthly\$ServerName\Monthly\"

#File name for logfile that will store output of this backup script
$BuLogFile = $servername + "_BULog_Nightly.txt"

#Message written to output logfile if a backup is successful
$SuccessLogMessage = @" 

Database: {0} on Server: $ServerName {1} Backup successful!
{2} 
{3}

"@

#Message written to output logfile if a backup fails
$FailLogMessage = 
@" 

****************************************************************************
Error 
Database: {0} on Server: $ServerName {1} Backup failed!
{2} 

{3}
****************************************************************************

"@

#Message in email body of email that is sent to DBAs if a backup fails
$FailEmailBody = @"
Databases backup on $ServerName occured with errors.
Please refer to attached log file for more information.
"@

#Message in the email body of the email sent to DBAs if he backup is successful
$SuccessEmailBody =  @"
Database backup on $ServerName occured successfully.
"@

$EmailSubjectLine = "$ServerName Database Backup report."

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

#Get the DATETIME value for the last Friday (weekday value of 5) of the month
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

#################################################################################################################
# EXECUTION
#################################################################################################################

#Check for the location and existence of the backup directories and logfile (deletes the logfile if it exists)
CheckLocation -Directory $BuLocation
CheckLocation -Directory $WeeklyLoc
CheckLocation -Directory $MonthlyLoc

#Write to the output log the location of the Script file as it was run.
out-file -filepath "$BuLocation$BuLogFile"  -Force -inputobject ("Script Ran from: " + $myinvocation.mycommand.path)

############################################## NIGHTLY BACKUP ##################################################

$StopWatch.Start()

#Perform FULL database backups on Sunday morning (ONCE A WEEK) if the script is ran on a Sunday after 11pm
if ($CurrentDate.DayOfWeek -eq "Sunday" -and $CurrentDate.TimeOfDay.Hours -ge 23)
{
 #loop through all of the databases on the server to backup each database
    foreach ($DB in $BackupDBsList)  
    {     
        # Check the status of the database to ensure that it is online and running normally.                
        if ($DB.Status -eq "Normal")
        {
            try 
            {
                $EmailSubjectLine = "Full New Weekly : $ServerName Database Backup report."

                #Call the backup function and record the start and end times for the backup operation 
                $StartTime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "FULL backup up of $DB" 
                Backup-SqlDBFull $DB.Name $ServerName    

                $EndTime = "End time - " + (get-date -Displayhint datetime)

                #if the backup up completes successfully write the success message to the log file
                $Message = $SuccessLogMessage -f $DB.Name, 'FULL',$StartTime, $EndTime
                Out-file  -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message
            } 
            catch 
            {
                #if the backup is unsuccessfull save and write the error (with a message) to the logfile

                $err=$Error[0]

                #Add user created error message to the logfile
                $Message = $FailLogMessage -f $DB.Name, 'FULL', $StartTime, $err
                Out-File -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message

                #Add detailed error message (from SQL Sever) to the logfile
                ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BuLocation$BuLogFile"  -append
            }
        } #end of 2nd inner if-statement
    } #end of foreach-loop
} #end of if-statment

#Perform incremental backups only if the script is ran on a weekday (Mon, Tues, Wed, Thurs, Fri) after 9AM
if (1,2,3,4,5 -contains [int]$CurrentDate.DayOfWeek -and $CurrentDate.TimeOfDay.Hours -gt 9)
{
    #loop through all of the databases on the server to backup each database
    foreach ($DB in $BackupDBsList)  
    {     
        # Check the status of the database to ensure that is online and running normally.                
        if ($DB.Status -eq "Normal")
        {
            $File = $BuLocation + $DB.name + ".bak"
            $FileExists = (Test-Path $File -PathType Leaf) 

            #If a full backup already exist, perform a differential backup                    
            If ($FileExists) 
            {           
                try 
                {
                    #Execute the backup function and record the start and end time for backup operation 
                    $StartTime = "Start time - " + (get-date -Displayhint datetime)
                    
                    Write-Output "DIFFERENTIAL backup up of $DB" 
                    Backup-SqlDBDiff $DB.Name $ServerName    

                    $EndTime = "End time - " + (get-date -Displayhint datetime)

                    #if the backup up completes successfully write the success message to the log file
                    $Message = $SuccessLogMessage -f $DB.Name, 'DIFFERENTIAL',$StartTime, $EndTime
                    Out-file  -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message
                } 
                catch 
                {
                    #if the backup is unsuccessfull save and write the error with a message to the logfile

                    $err=$Error[0]

                    #Add user created error message to the logfile
                    $Message = $FailLogMessage -f $DB.Name, 'DIFFERENTIAL', $StartTime, $err
                    Out-File -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message

                    #Add detailed error message (from SQL Sever) to the logfile
                    ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BuLocation$BuLogFile"  -append
                }
            } #end of 2nd inner if-statement
            #If a full backup does not already exist, perform a full backup
            else 
            {           
                try 
                {
                   # $EmailSubjectLine = "Full New Weekly : $ServerName Database Backup report."

                    $starttime = "Start time - " + (get-date -Displayhint datetime)
                    
                    Write-Output "FULL backup of $DB" 
                    Backup-SqlDBFull $DB.Name $ServerName    

                    $endtime = "End time - " + (get-date -Displayhint datetime)

                    $Message = $SuccessLogMessage -f $DB.Name, 'FULL', $StartTime, $EndTime
                    Out-file  -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message
                } 
                catch 
                {
                    $err=$Error[0]
                    $err

                    #Add user created error message to the logfile
                    $Message = $FailLogMessage -f $DB.Name, 'FULL', $StartTime, $err
                    Out-File -filepath "$BuLocation$BuLogFile"  -append -inputobject $Message

                    #Add detailed error message (from SQL Sever) to the logfile
                    ($Error[0]|format-list -force -GroupBy name) | Out-File -filepath "$BuLocation$BuLogFile"  -append
                }
            } #end of else-statment to the 2nd inner if-statement 
        } #end of 1st inner if-statement
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
    #Clean up the file locations of old files in order to minimize the disk space consumed. 
    Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-60)} | remove-item
    Get-ChildItem $ArchiveLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-7)} | remove-item
    
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
        Write-Output "`r`n*********** Compressed and moved nightly backup files to the weekly backup location *************`r`n"

        #If it is the last friday of the month, copy the weekly archive file to the monthly backup folder
        if ($CurrentDate.Date -eq $LastFriday.Date)
        {
            Copy-Item $ArchiveFile $MonthlyLoc
            Write-Output "`r`n************** Moved archive files to the monthly backup location **************`r`n"

        }
    } #end of foreach-loop
} #end of if-statement

$StopWatch.Stop()

$TotalTime = $StopWatch.Elapsed

Out-File -filepath "$BuLocation$BuLogFile"  -append -inputobject ("`r`nTotal Time to Complete Backup: " + ($TotalTime).ToString("hh'hr:'mm'min:'ss'sec'"))

#>
################################################# EMAIL DBAs ############################################# 

#Checks for an error message in the logfile so DBAs can be noified. Looks for first instance of the word 'failed'
$LogFileError = Select-string "$BuLocation$BuLogFile" -pattern "failed" -Quiet

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


#Construct and send the email message
Send-MailMessage `
-To "ufuoma_ikporo@dynamicrisk.net", "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" `
-From "HP9000@dynamicrisk.net" `
-Subject $EmailSubjectLine `
-attachment "$BuLocation$BuLogFile" `
-priority $emailPriority `
-SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
-Body $emailBody
#>