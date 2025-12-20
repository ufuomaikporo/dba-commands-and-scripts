<#

This script does the following...
1. Performs a base FULL backup once a week if the script is executed on a Sunday betwen 10 PM - 11:59 PM (inclusive)
2. Performs a daily DIFFERENTIAL backup every other time it is executed, except for the case when a base FULL backup is
   missing, or an invalid backupis is found. IF an invalid differential backup is found it will append a FULL database backup 
   to the backup media. If the backup media is invalid or no base FULL backup is found, it will perform a new base FULL backup.
2. If executed on a Friday evening after 6PM, it compresses the backup media at the end of each week into a Winrar zip file 
    to be stored in a weekly backup location 
3. If executed on the last Friday of the month after 6 PM, it stores the last weekly backup of the month in the monthly backup location 
4. Performs regular daily and weekly backups for IRAS databases (Daily, Weekly, Monthly) 
5. ONLY performs mothly backups of non-IRAS databases (i.e. source databases) on the last friday of each month

**NOTES**
- This script checks for and automatically fixes breaks in the backup LSN chain, which may be caused by a database restore, and relaces invalid backups 
  with a new FULL backup. The fix will occur on the next script execution.
- The backup media repair only works if the backup media (backup file) is named after the database from which the backup was taken
- The Sunday night backup overwrites all previous backups and resets the backup media. 
- The weekly backup should contains all backups from Sunday - Friday
- The monthly backup only contains the last weekly backup for the month

This script should be...
1. Executed ONLY on Microsoft SQL Server host machines
2. Automated to run via Windows Task Scheduler.  
3. Set to Run 
    i) Every Weekight (Mon-Fri) at or after 10 PM - For a Nightly DIFFERENTIAL Backup
    ii) Daily at around noon - For a Mid-day DIFFERENTIAL Backup
    iii) Every Sunday night at or after 10 PM - For a fresh new weekly FULL backup 

#>

##################################################################################################################
# FUNCTIONS
##################################################################################################################

Push-Location

Import-Module sqlps #Needed to run invoke-sqlcmd 

Pop-Location

#This Function checks for the existence of a file (log file in this instance) 
# and removes if it exists. The full file path must be entered as an argument
Function CheckFileExists([string] $File)
{
	If (Test-path $File) 
		{
			return $true
			
		}
}

#This Function checks for the existence of directories and creates it if not found
Function CheckLocation([string] $Directory)
{
	if (!(Test-path $Directory)) {

        New-item -type directory $Directory | Out-Null
	}
}

#############################################################################################################
# VARIABLE DECLARATION
#############################################################################################################

$InstanceName = (HOSTNAME.EXE).ToUpper()


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
$BuLocation = "\\dras-dbbkp02\P_DB_Backups_Nightly\$FolderName\Nightly\"
$WeeklyLoc = "\\dras-dbbkp02\P_DB_Backups_Monthly\$FolderName\Weekly\"
$MonthlyLoc = "\\dras-dbbkp02\P_DB_Backups_Monthly\$FolderName\Monthly\"

#File name for logfile that will store output of this backup script
$BuLogFile =  $BULocation + "$($FolderName)_BULog_Nightly.txt"

#----------------------------------- SQL QUEIRES AND COMMANDS ---------------------------------

#Create the list of databases for daily backups
$DailyBackupList = "SELECT name, state_desc AS Status FROM sys.databases 
                    WHERE name LIKE '%IRAS%'
                    AND state_desc = 'ONLINE'
                    ORDER BY 1"

#Create the list of databases for end of month backups
$EOMBackupList = "SELECT name, state_desc AS Status FROM sys.databases 
                  WHERE database_id > 4
                  AND state_desc = 'ONLINE'
                  ORDER BY 1"


#This command executes an Full backup
$FullBackupCommand = "BACKUP DATABASE {0}   
                        TO DISK = '{1}'   
                          WITH {2},
                          NAME = '{0} Backupset',
                          DESCRIPTION = '{0} Full Backup';
                      GO"

#This command executes an differential backup
$DiffBackupCMD = "BACKUP DATABASE {0}   
                    TO DISK = '{1}'  
                        WITH DIFFERENTIAL,
                        NAME = '{0} Backupset',
                         DESCRIPTION = '{0} Differential Backup';
                  GO"

#This checks a backup file to see if the lastest differential backup is invalid
$CheckForInvalidBackups = "DECLARE @SQL NVARCHAR(MAX)
DECLARE @DBName NVARCHAR(100) 
DECLARE @BULocation NVARCHAR(500)
DECLARE @BUFile NVARCHAR(500) 
DECLARE @FileName NVARCHAR(100)
DECLARE @FullbkpFile INT
DECLARE @BackupPosition INT
DECLARE @DBList NVARCHAR(MAX)
DECLARE @LastValidBackup INT
DECLARE @LastBackup INT

SET @BUFile = '{0}'

IF OBJECT_ID('tempdb..##BackupSetInfo') IS NOT NULL
BEGIN
	DROP TABLE ##BackupSetInfo;
END;

IF OBJECT_ID('tempdb..##BackupSetInfo') IS NULL
BEGIN
	-- Table to store info on a single backupset
	SET @SQL = 'CREATE TABLE ##BackupSetInfo (Name NVARCHAR(100),
								 Descripion NVARCHAR(255),
								 BackupType SMALLINT,
								 ExpirationDate DATETIME,
								 Compressed INT,
								 Position SMALLINT,
								 Device INT,
								 UserName NVARCHAR(100),
								 ServerName NVARCHAR(100),
								 DatabaseName NVARCHAR(100),
								 DatabaseVersion INT,
								 DBCreationDate DATETIME,
								 BackupSize BIGINT,
								 FirstLSN NUMERIC(30),
								 LastLSN NUMERIC(30),
								 CheckPointLSN NUMERIC(30),
								 DatabaseBackupLSN NUMERIC(30),
								 BackupStartDate DATETIME,
								 BackupFinishDate DATETIME,
								 SortOrder INT,
								 CodePage INT,
								 UniCodeLocaleId INT,
								 UnicodeComparisonStyle INT,
								 CompatibilityLevel INT,
								 SoftwareVendorId INT,
								 SoftwareVersionMajor INT,
								 SoftwareVersionMinor INT,
								 SoftwareVersionBuild INT,
								 MachineName NVARCHAR(100),
								 Flags INT,
								 BindingId NVARCHAR(100),
								 RecoveryFokId NVARCHAR(100),
								 Collation NVARCHAR(100),
								 FamilyGUID NVARCHAR(100),
								 HasBulkLoggedData INT,
								 IsSnapshot INT,
								 IsReadOnly INT,
								 IsSingleUser INT,
								 HasBackupChecksums INT,
								 IsDamaged INT,
								 BeginsLogChain INT,
								 HasIncompleteMetaData INT,
								 IsForceOffline INT,
								 IsCopyOnly INT,
								 FirstRecoveryForkId NVARCHAR(100),
								 ForkPointLSN NUMERIC(30),
								 RecoveryModel NVARCHAR(50),
								 DifferentialLSN NUMERIC(30),
								 DifferentialBaseGUID NVARCHAR(100),
								 BackupTypeDescription NVARCHAR(50),
								 BackupSetGUID NVARCHAR(100),
								 CompressedBackupSize BIGINT,
								 Containment INT,	--SQL2014'

	IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) >= 2014 AND 
	   CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) <= 2019
	BEGIN
		SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
		'				KeyAlgorithm NVARCHAR(100),
								EncryptorThumbprint NVARCHAR(100),
								EncryptorType NVARCHAR(100)			--SQL2014, SQL2016, SQL2017, SQL2019'

	END
	ELSE IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) > 2019
	BEGIN
		SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
		'				KeyAlgorithm NVARCHAR(100),
								EncryptorThumbprint NVARCHAR(100),
								EncryptorType NVARCHAR(100),		--SQL2016, SQL2017, SQL2019
								LastValidRestoreTime DATETIME,
								TimeZone INT,
								CompressionAlgorithm NVARCHAR(100)'
	END

	SET @SQL += CHAR(10) + '								);'

	EXECUTE (@SQL)						
END;

-- Backup backup SET header info in table
INSERT INTO ##BackupSetInfo
EXECUTE ('RESTORE HEADERONLY FROM DISK = '''+ @BUFile + '''')

-- SET the name that the database will be restored as to the default name in the backup file if no name was entered by script user	
SELECT @DBName = DatabaseName
FROM ##BackupSetInfo;
	
--Find the latest valid backup 
SELECT @LastBackup = MAX(Position) 
FROM ##BackupSetInfo

-- Find the latest Full backup
SELECT @FullbkpFile = MAX(Position)
FROM ##BackupSetInfo
WHERE BackupType = 1

SET @LastValidBackup = NULL

-- Find the most recent valid backup based on the LSN chain 
IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 5 AND @LastBackup <> 1
BEGIN
	SELECT @LastValidBackup = MAX(Position)
	FROM ##BackupSetInfo
	WHERE BackupType = 5
	AND (DatabaseBackupLSN = ANY (SELECT CheckPointLSN FROM ##BackupSetInfo
								WHERE BackupType = 1)
	OR DatabaseBackupLSN = ALL (SELECT DatabaseBackupLSN FROM ##BackupSetInfo
							WHERE Position >= @FullbkpFile)	
		)
	AND DifferentialLSN = (SELECT DifferentialLSN FROM ##BackupSetInfo WHERE Position = 2)

END
ELSE IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 1
BEGIN
	SET @LastValidBackup = @LastBackup
END

BEGIN TRY
	EXECUTE ('RESTORE VERIFYONLY FROM DISK = ''' + @BUFile + '''')
END TRY
BEGIN CATCH
	SET @LastValidBackup = NULL
END CATCH

-- Return 1 if the last differential backup in th ebackup media is invalid for restores
IF (@LastValidBackup != @LastBackup) 
BEGIN
	SELECT 1 AS HasInvalidBackup
END
-- Return 2 if the backup media fails the validation test 'VERIFYONLY' 
ELSE IF (@LastValidBackup IS NULL OR @FullbkpFile IS NULL)
BEGIN
	SELECT 2 AS HasInvalidBackup
END
ELSE
-- Return 0 if the last backup on the backup media is valid for restores
BEGIN
	SELECT 0 AS HasInvalidBackup
END
"
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
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $EOMBackupList  -QueryTimeout 0
}
else
{
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $DailyBackupList  -QueryTimeout 0
}

#Check for the location and existence of the backup directories and logfile (deletes the logfile if it exists)
CheckLocation -Directory $BuLocation
CheckLocation -Directory $WeeklyLoc
CheckLocation -Directory $MonthlyLoc

#Write to the output log the location of the Script file as it was run.
Out-File -filepath "$BULogFile"  -Force -inputobject ("Script Ran from: " + $myinvocation.mycommand.path)

############################################## NIGHTLY BACKUP ##################################################

$StopWatch.Start()

Write-Output "`r`n***********************************************************************************************"
Write-Output "Script Executed on : $(Get-Date -Format "dddd dd MMM yyyy hh:mm:ss tt")"
write-Output "-----------------------------------------------------------------------------------------------`r`n"

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
                $EmailSubjectLine = "Full New Weekly $InstanceName Database Backup Report."

                #Call the backup function and record the start and end times for the backup operation 
                $StartTime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "FULL backup of $($DB.Name)" 
             
                $BUFile = $BULocation + $DB.Name + ".bak"

                $WeeklyLocFile = Get-ChildItem -Path $WeeklyLoc | Where-Object {$_.BaseName -eq  $DB.Name -and $_.LastWriteTime -gt (Get-Date).AddDays(-3)}

                #Delete the backup file if it's been copied over to the weekly folder (Sometimes SQL Server failes to create a new backup on top of the old file)
                if ((Test-Path $BUFile -PathType Leaf) -and $WeeklyLocFile -ne $null)
                {          
                    $BUFile | Remove-Item -Recurse
                }
               
                $SQL = $FullBackupCommand -f $DB.Name, $BUFile, "FORMAT, INIT, COMPRESSION"
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 0  #Query doesn't timeout when set to 0
                
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

#Perform incremental backups only if the script is ran on a weekday (Mon, Tues, Wed, Thurs, Fri) after midnight
if (1,2,3,4,5 -contains [int]$CurrentDate.DayOfWeek -and $CurrentDate.TimeOfDay.Hours -gt 0)
{
    #loop through all of the databases on the server to backup each database
    foreach ($DB in $DBBackupList)  
    {    
        $BUFile = $BULocation + $DB.Name + ".bak"

        #Check if a backup file exists for the database with the following specified backup file name
        $FileExists = (Test-Path $BUFile -PathType Leaf)  

        #If a backup file exists, check if the latest differential backup is invalid
        if($FileExists)
        {            
            $SQL = $CheckForInvalidBackups -f "$BULocation$($DB.Name).bak"
            $InvalidBackupExists = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 0
        }

        # if the database status is normal, and if a full backup exists within a backup file, then perform differential backup               
        if ($FileExists -and $InvalidBackupExists.HasInvalidBackup -eq 0)
        {                
            try 
            {
                #Execute the backup function and record the start and end time for backup operation 
                $StartTime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "DIFFERENTIAL backup up of $($DB.Name)" 
              
                $SQL = $DiffBackupCMD -f $DB.Name, $BUFile          
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 0
                
                #Allow Windows process some time to release the logfile
                Start-Sleep -Seconds 1

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
        #If a full backup does not already exist or if the last differential backup is invalid, then perform a full backup
        else
        {   
       
            try 
            {
                if ($FileExists -and $InvalidBackupExists.HasInvalidBackup -eq 1)    
                {
                    $SQL = $FullBackupCommand -f $DB.Name, $BUFile, "NOFORMAT, NOINIT"
                } 
                else
                {
                    $SQL = $FullBackupCommand -f $DB.Name, $BUFile, "FORMAT, INIT, COMPRESSION"
                }
               
                $Starttime = "Start time - " + (get-date -Displayhint datetime)
                
                Write-Output "FULL backup of $($DB.Name)" 
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $SQL -QueryTimeout 0
  
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
If the script is being run on a Friday evening at or after 6PM, archive each database backup in a zipfile and copy the 
archive file to the weekly backup location. If it is the last Friday of the month, copy the archive file to 
the monthly backup location as well
#>

if ($CurrentDate.DayOfWeek -eq "Friday" -and $CurrentDate.TimeOfDay.Hours -ge 18) 
{
    Write-Host "`r`n****************************** CREATING WEELY BACKUPS ******************************`r`n"

    #Clean up the file locations of old files in order to minimize the disk space consumed. 
    Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-60)} | remove-item -Recurse
    Get-ChildItem $BuLocation | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-14)} | remove-item -Recurse
    Get-ChildItem $WeeklyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).adddays(-21)} | remove-item -Recurse

    #Get a list of the BackupFiles in the nightly backup location
    $BUFilesList = Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq ".bak" -and $_.LastWriteTime -ge $CurrentDate.AddDays(-5)}

    #Archive the nightly backups by adding each nightly backup file to a compressed archive file of the same name
    foreach ($BUFile in $BUFilesList)
    {   
        #Location of the Winrar executable file  
        $WinRar = "C:\Program Files\WinRAR\rar.exe"

        #Name and location of archive file where compressed backup files will be stored
        $ArchiveFile = $WeeklyLoc + $BUFile.BaseName +".rar"
        
        #Delete Archive zipfile if it already exists (causes an erorr if archivefile already exists)
        if(Test-Path -Path $ArchiveFile)
        {
            Remove-Item $ArchiveFile
        }
        
        #Execute command to compress backup files into an archive file
        & $winrar u -ep -ibck -df -y $ArchiveFile ($BuLocation + $BUFile)   	

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

Write-Output "`r`nDatabase Backup Completed: $(Get-Date)     Duration: $($TotalTime.ToString("hh'hr:'mm'min:'ss'sec'"))"

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


$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net" #, "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 

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

