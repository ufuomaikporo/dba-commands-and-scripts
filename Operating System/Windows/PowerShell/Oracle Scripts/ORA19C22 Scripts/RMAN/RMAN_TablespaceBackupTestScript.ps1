#--------------------------------- PREREQUISITES ------------------------------------

Remove-Variable * -ErrorAction SilentlyContinue

$StartTime = Get-Date

Write-Output "`r`n############################################################################################"

Write-Output "`r`nScript StartTime: $StartTime"

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

#-------------------------------------- DELCARE FUNCTIONS -----------------------------------------

# Function to Check a directory path location (i.e. backup location). Creates the directory if it does not exist 
Function Make-DirectoryExist ([string] $Directory)
{
	If (!(Test-Path -path $Directory))  
		{ 
			New-item -type directory $Directory | Out-Null
		} 
}

#--------------------------------------------------- SET VARIABLES ---------------------------------------------

# Get script input params
$TargetDBTNS = "DRASORA19C22"
$CatalogDBTNS = 'DRASORA19C'
$Username = 'RMAN'
$Password = 'rman'
$FullBackupScript = 'ORA19C22_FULL_Weekly_Backup'
$DiffBackupScript = 'ORA19C22_Daily_Differential_Backup'
$CummulativeBackupScript = 'ORA19C22_MidWeek_Cummulative_Backup'
$WeeklyBackupTag = "WEEKLY_FULL_BACKUP"     
$DailyBackupTag = "$((Get-Date).DayOfWeek)_DIFF_BCKP".ToUpper()
$MidWeekBackupTag = "MIDWEEK_CUMULATIVE_BCKP"

#-------------------------------------------- SCRIPT FILES AND DIRECTORIES ------------------------------------------

#Backup Folders 
$BULocation ="B:\Fast Recovery Area\ORA19C22\Backups\"
$NightlyLoc = "$BULocation$(Get-Date -Format 'MM_dd_yyyy')\"
$WeeklyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\ORA19C22\Testing\Weekly\"
$MonthlyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\ORA19C22\Testing\Monthly\"
$ControlFileBackupLoc = "$($NightlyLoc)ControlFile\"

# Output logfile for this script run
$BULogFile = "$NightlyLoc$($TargetDBTNS)_BULog_Nightly_$(Get-Date -Format 'MM_dd_yyyy_HH').txt"

#Temporary Output file
$TempFileName = "Tempfile_$($TargetDBTNS)Backup.txt"
$TempOutputFile = $NightlyLoc + $TempFileName

# Create backup directories if they do not exist
Make-DirectoryExist -Directory $BULocation
Make-DirectoryExist -Directory $NightlyLoc
Make-DirectoryExist -Directory $ControlFileBackupLoc
Make-DirectoryExist -Directory $WeeklyLoc | Out-Null
Make-DirectoryExist -Directory $MonthlyLoc | Out-Null

#---------------------------------------------------------- DATE VARIABLES --------------------------------------

#Add the date of the script execution of the logfile
$CurrentDate = Get-Date 

Out-File $BuLogFile -InputObject "`r`nScript StartTime: $($CurrentDate)" -Append

#Get the DateTime value for the last Friday of the month (weekday value of 5) 
$DayOfWeek = 5

$NextMonth = $CurrentDate.AddMonths(1)
$LastDayOfCurrentMonth = $NextMonth.AddDays(-$NextMonth.Day)
if ([int]$LastDayOfCurrentMonth.DayOfWeek -ge $DayOfWeek) {
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$LastDayOfCurrentMonth.DayOfWeek + $DayofWeek)
}
else {
    $SubtractDays = [int]$LastDayOfCurrentMonth.DayOfWeek + (7 - [int]$DayofWeek)
    $LastFriday = $LastDayOfCurrentMonth.AddDays(-$SubtractDays)
}

#Date for the beginning of the week (Sunday 12:00 AM)
$StartOfWeek = $CurrentDate.AddDays(-($CurrentDate).DayOfWeek.value__).Date
$StartofMonth = $CurrentDate.AddDays(-$CurrentDate.Day + 1)

#------------------------------------------------ QUEIRIES -----------------------------------------------------

#Command to get list of tablespaces for backup

$GetTablespaceQuery = "

                    SET FEEDBACK OFF;
                    ALTER SESSION SET nls_comp = Linguistic;
                    ALTER SESSION SET nls_sort = binary_CI;
                    SET PAGES 0
						
                    SELECT tablespace_name                      
                    FROM dba_tablespaces 
                    WHERE REGEXP_LIKE (tablespace_name, 'SYSAUX|SYSTEM|^UNDO|USERS|RMAN|SDE|TEST')
                    OR tablespace_name LIKE '%IRAS%OWNR%'
                    ORDER BY 1;" 

# Get list of tablespaces for backup
$TablespaceList = $GetTablespaceQuery | sqlplus -silent $Username/$Password@$TargetDBTNS

# Remove null elements from the array
$TablespaceList = $TablespaceList | Where-Object {$_ -ne $null}

if ($TablespaceList.LENGTH -gt 1)
{
    $TablespaceList = "'" + [system.String]::Join("', '", $TablespaceList) + "'"
}


# Performs a full tablespace backup of all tablespaces within the variable '$TablespaceList'
$FullBackupCommand = "SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$($ControlFileBackupLoc)ControlFile_n_SPFile_%F.BKP';
			          ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			          ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
		              ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			          ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			          BACKUP AS COMPRESSED BACKUPSET 
			          INCREMENTAL LEVEL 0
			          TABLESPACE $TablespaceList TAG '{0}'
                      PLUS ARCHIVELOG TAG '{0}'
	                  DELETE ALL INPUT;                     
                      BACKUP AS COPY CURRENT CONTROLFILE 
                      FORMAT '$($ControlFileBackupLoc)ControlFileCopy_$(Get-Date -Format 'MM_dd_yyyy_HH').BKP';
                      VALIDATE CHECK LOGICAL TABLESPACE $TablespaceList;
			          RELEASE CHANNEL ch1;
			          RELEASE CHANNEL ch2;
			          RELEASE CHANNEL ch3;
			          RELEASE CHANNEL ch4;"

#Performs a cumulative differential backup (for faster recovery) and checks for logical and physical corruption within the tablespaces in '$TablespaceList'
$CumulativeBackupCommand = "SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$($ControlFileBackupLoc)ControlFile_n_SPFile_%F.BKP';
			                ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
		                    ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                BACKUP AS COMPRESSED BACKUPSET 
			                INCREMENTAL LEVEL 1 CUMULATIVE
			                TABLESPACE $TablespaceList TAG '{0}'             
                            PLUS ARCHIVELOG TAG '{0}'
	                        DELETE ALL INPUT;
                            BACKUP AS COPY CURRENT CONTROLFILE 
                            FORMAT '$($ControlFileBackupLoc)ControlFileCopy_$(Get-Date -Format 'MM_dd_yyyy_HH').BKP';
                            VALIDATE CHECK LOGICAL TABLESPACE $TablespaceList;
			                RELEASE CHANNEL ch1;
			                RELEASE CHANNEL ch2;
			                RELEASE CHANNEL ch3;
			                RELEASE CHANNEL ch4;"


#Performs daily differential backups for all tabespaces in the variable '$TablespaceList'
$DifferentialBackupCommand = "SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$($ControlFileBackupLoc)ControlFile_n_SPFile_%F.BKP';
			                ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
		                    ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT = '$NightlyLoc%d_%M_%D_%Y_%U.BKP' MAXPIECESIZE 10G;
			                BACKUP AS COMPRESSED BACKUPSET 
			                INCREMENTAL LEVEL 1
			                TABLESPACE $TablespaceList TAG '{0}'
                            PLUS ARCHIVELOG TAG '{0}'
	                        DELETE ALL INPUT;
                            BACKUP AS COPY CURRENT CONTROLFILE 
                            FORMAT '$($ControlFileBackupLoc)ControlFileCopy_$(Get-Date -Format 'MM_dd_yyyy_HH').BKP';
                            VALIDATE CHECK LOGICAL TABLESPACE $TablespaceList;
			                RELEASE CHANNEL ch1;
			                RELEASE CHANNEL ch2;
			                RELEASE CHANNEL ch3;
			                RELEASE CHANNEL ch4;"

#Command template for executing RMAN commands
$RMANCommand = "RMAN TARGET '`"$Username/$Password@$TargetDBTNS as SYSBACKUP`"' CATALOG $Username/$Password@$CatalogDBTNS 
                {0}"
  
#Save the location from where the Script file is being executed to the output logfile.
Out-File -FilePath $BuLogFile  -Force -InputObject ("Script Executed from: " + $MyInvocation.MyCommand.Path)

#----------------------------------- CHECK THAT A FULL INCR BACKUP EXISTS ------------------------------------------------

$SQL = "RMAN TARGET '`"$Username/$Password@$TargetDBTNS as SYSBACKUP`"' CATALOG $Username/$Password@$CatalogDBTNS 
        #CROSSCHECK ARCHIVELOG ALL; 
        #DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
        LIST BACKUPSET TAG $WeeklyBackupTag;"

$SQL | cmd | Out-File -FilePath $TempOutputFile -Force

#Get a list of backups with the "WEEKLY_FULL_BACKUP" tag (these are the weekly backups)
$ListFullWeeklyBackup = Select-String -Path $TempOutputFile -Pattern "Tag: $($WeeklyBackupTag)*" -Context 1, 1 | Select-Object -Property Line, @{Name= 'PreContext'; Expression = {$_.Context.PreContext}} -Last 1

#Get the date of the last full weekly backup
if ($null -ne $ListFullWeeklyBackup)
{
    #Store the regular expression for finding the date of the last full backup in a variable
    $Regex = [regex]'\d\d-\w*-\d\d'

    #Find and get the starting index of the date when the last full backup was ran 
    $DateStartIndex = $Regex.Match($ListFullWeeklyBackup.PreContext).Index

    $LastFullBkpDate = ($ListFullWeeklyBackup.PreContext).Substring($DateStartIndex, 9)

    $LastFullBkpDate = [datetime]::ParseExact($LastFullBkpDate, 'dd-MMM-yy', $null).Date    
}

$HasRecentFullBackup = $false

#If there are no backups with the "WEEKLY_FULL_BACKUP" tag or if the last weekly backup is too old set the $HasRecentFullBackup variable so a weekly backup will be performed
if($null -ne $LastFullBkpDate -and $LastFullBkpDate -ge $StartOfWeek)
{
    $HasRecentFullBackup = $true
}

#--------------------------------- PERFORM BACKUPS ---------------------------------------------------- 


#Perform FULL database backups on Sunday (ONCE A WEEK) if the script is ran on a Sunday After 10pm
if ($CurrentDate.DayOfWeek -eq "Sunday" -and $CurrentDate.TimeOfDay.Hours -ge 22 -or $HasRecentFullBackup -eq $false)
{
#-------------------------------- FULL WEEKLY BACKUP ------------------------------------------------

    Write-Host "`r`nPerforming Weekly Full Database Backup`r`n"
    Out-File -FilePath $BuLogFile  -Append -InputObject "`r`nPerforming Weekly FULL Database Backup`r`n" 

    # Get a list of all backup files from last week 
    $DeleteList = Get-ChildItem $BULocation -Recurse | Where-Object {$_.Lastwritetime -lt $StartOfWeek} 
        
    # Cleanup the nightly backup location by deleting files from the previous week 
    if (!([string]::IsNullOrWhitespace($DeleteList)))
    {
        Write-Host "Deleting last week's backup files"
        $DeleteList.FullName | remove-item -Recurse -Confirm:$false -Force
    }
            
    $FullBackupCommand = $FullBackupCommand -f $WeeklyBackupTag
    $SQL = $RMANCommand -f "RUN {$FullBackupCommand}" 
   
    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL | CMD | Out-File $BuLogFile –Append
}
elseif ($CurrentDate.DayOfWeek -eq "Wednesday" -and $CurrentDate.TimeOfDay.Hours -ge 18)
{
#---------------------------- MID-WEEK BACKUP ------------------------------------------------------

    Write-Host "`r`nPerforming Mid-Week Cumulative Database Backup`r`n"
    Out-File -FilePath $BuLogFile  -Append -InputObject "`r`nPerforming Mid-Week CUMULATIVE Database Backup`r`n"
    
    $CumulativeBackupCommand = $CumulativeBackupCommand -f $MidWeekBackupTag
    $SQL = $RMANCommand -f "RUN {$CumulativeBackupCommand}" 
  
    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL | CMD | Out-File $BULogFile -Append 
}
else
{
#----------------------------- DAILY DIFFERENTIAL BACKUP ------------------------------------------

    Write-Host "`r`nPerforming Daily Differential Database Backup`r`n"
    Out-File -FilePath $BuLogFile  -Append -InputObject "`r`nPerforming Daily DIFFERENTIAL Database Backup`r`n"

    $DifferentialBackupCommand = $DifferentialBackupCommand -f $DailyBackupTag
    $SQL = $RMANCommand -f "RUN {$DifferentialBackupCommand}" 
  
    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL | CMD | Out-File $BULogFile -Append
}
#>
#-------------------------------- WEEKLY BACKUP ------------------------------------------------

If ($Currentdate.DayOfWeek -eq 'Friday' -and $CurrentDate.TimeOfDay.Hours -ge 18)
{
    #Delete Old backups in the weekly backup folder (anything older than 2 months ago)
    Get-ChildItem $WeeklyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).AddDays(-30)} | Remove-Item

    Write-Host "Creating weekly compressed backups"

    $BuList = Get-ChildItem $BULocation -Exclude $TempFileName   | Where-Object {$_.LastWriteTime -ge $StartOfWeek} 

    #Location of the Winrar executable file  
    $WinRar = "C:\Program Files\WinRAR\rar.exe"

    #Set FullName path for the archive file where compressed backup files will be stored
    $ArchiveFile = $WeeklyLoc + "$($TargetDBTNS)_WeeklyBackup_$(Get-Date -Format "MMM_dd_yyyy").rar"

    if(Test-Path $ArchiveFile)
    {
        Remove-Item $ArchiveFile
    }
    
    #Execute command to compress backup files into an archive file
    & $winrar u -ibck -m4 -ep1 -y $ArchiveFile $BuList
         

}# end of if-block

#---------------------------------- MONTHLY BACKUP --------------------------------------------

# If the backup begins on the last friday of the month copy the compressed weekly database set to the monthly folder
if ($Currentdate.Date -eq $LastFriday.Date -and $CurrentDate.TimeOfDay.Hours -ge 18)
{
    
    $DeleteList = Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt $CurrentDate.Adddays(-60)} 

    if (!([string]::IsNullOrWhitespace($DeleteList)))
    {
        $DeleteList.FullName | remove-item -Recurse -Confirm:$false -Force
    } 

    Write-Host "Moving Weekly Compressed backups to Monthly backup location"

    $BUList = Get-ChildItem $WeeklyLoc | Where-Object {$_.LastWriteTime -gt $StartOfMonth} | Select-Object -ExpandProperty FullName

    # Create a new monthly subfolder for each month
       
    $NewDirectory =  "$MonthlyLoc$($CurrentDate.ToString("MMMM"))" 

    if(!(Test-Path -Path $NewDirectory))
    {
        Make-DirectoryExist -Directory $NewDirectory
    } 

    # Copy the compressed zip files from the weekly location to the monthly location
    Copy-Item $BUList -Destination $NewDirectory

    # Cleanup the weekly backup location (delet all files in the directory)
    $DeleteList = Get-ChildItem $WeeklyLoc 

    if (!([string]::IsNullOrWhitespace($DeleteList)))
    {
        $DeleteList.FullName | remove-item -Recurse -Confirm:$false -Force
    } 
}	

#Delete the temporary output file used for collecting the output of the RMAN commands
if(Test-Path -Path $TempOutputFile)
{
    Remove-Item -Path $TempOutputFile
}

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).ToString("hh'hr:'mm'min:'ss'sec'")

#Add the total time taken to complete the backup to the logfile
Out-File -FilePath $BuLogFile  -Append -InputObject ("`r`nTotal Time to Complete Backup: $Duration ")

Write-Output "`r`nThe Backup logfile file can be found at $BULogFile`r`n"
Write-Output "Script Completed: $EndTime          Duration: $Duration `r`n`r`n"

#------------------------------------------------ SEND EMAIL -----------------------------------------------------

$LogFileError = Select-String -Path $BULogFile -Pattern "Finished Control File and SPFILE Autobackup"

#If there is an error message in the logfile, send an email with appropriate instructions in the body. Otherwise, send
#a success message
if ($null -eq $LogFileError)
{
	$EmailBody = "$TargetDBTNS Backup completed with errors. Check the attached logfile for more info."
	$EmailPriority = "High" 
}
else
{
	$EmailBody = "$TargetDBTNS backup was successfully completed"
	$EmailPriority = "Low" 
}

$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net" #, "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net"

#Construct and send the email message
Send-MailMessage `
-To $EmailRecipientList `
-From "HP9000@dynamicrisk.net" `
-Subject "$TargetDBTNS RMAN Backup report." `
-Attachment $BULogFile `
-Priority $EmailPriority `
-SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
-Body $EmailBody

#>