# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

#Stop watch to keep track of time it takes to complete a backup
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

#Start stop watch
$StopWatch.Start()

#This Function checks for the existence of directories and creates it if not found
Function CheckLocation([string] $Directory)
{
	if (!(Test-path $Directory)) {

        New-item -type directory $Directory | Out-Null
	}
}

# Get script input params
$TargetDB = HOSTNAME.EXE
$CatalogDB = 'DRASORA19C'
$Username = 'RMAN'
$Password = 'rman'

#Backup Folders
#$BULocation = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\ORA19C\Nightly\" 
$BULocation ='B:\Backups\RMAN_Testing\'
$WeeklyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$($TargetDB)\Testing\Weekly\"
$MonthlyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$($TargetDB)\Testing\Monthly\"

#Create the backup directories if not already exists
CheckLocation -Directory $BuLocation
CheckLocation -Directory $WeeklyLoc
CheckLocation -Directory $MonthlyLoc

return
# Output logfile for this script run
$BULogFile = "$BULocation\$($TargetDB)_BULog_Nightly.txt"

#Temporary Output file
$TempOutputFile = "$BULocation\Tempfile_$($TargetDB)Backup.txt"

# Command file containg RMAN commands
#$CMDFile = "B:\Scripts\RMAN_Backup_CMDFILE.rman"
  
#Save the location from where the Script file is being executed to the output logfile.
Out-File -FilePath $BuLogFile  -Force -InputObject ("Script Executed from: " + $MyInvocation.MyCommand.Path)

#Add the data of the script execution of the logfile
$CurrentDate = Get-Date  '07-28-2023 10:00:00 pm'
Out-File $BuLogFile -InputObject "Script StartTime: $($CurrentDate)" -Append

#Get the DateTime value for the last Friday (weekday value of 5) of the month
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

$StartOfWeek = ($CurrentDate).AddDays(-($CurrentDate).DayOfWeek.value__)

#$StartOfWeek = '06-29-2023'
#$StartOfWeek = [datetime]::ParseExact($StartOfWeek, 'MM-dd-yyyy', $null)

Write-Output $CurrentDate

#----------------------------------- CHECK THAT A FULL INCR BACKUP EXISTS ------------------------------------------------

$GetBackupHistory = "COL status FORMAT A10
                     COL hrs FORMAT 999.99
                     SET PAGES 9999
                     SET FEEDBACK OFF;
                    

                    SELECT session_key, 
	                        input_type, 
                            status,
	                        to_char(START_TIME,'mm/dd/yy hh24:mi') start_time,
	                        to_char(END_TIME,'mm/dd/yy hh24:mi') end_time,
	                        elapsed_seconds/3600 hrs 
                    FROM V`$RMAN_BACKUP_JOB_DETAILS
                    WHERE start_time > TO_DATE('$StartOfWeek', 'MM/DD/YYYY HH24:MI:SS')
                    AND input_type LIKE '%INCR%'
                    AND status LIKE 'COMPLETED%'
                    ORDER BY session_key;

                    EXIT"
       
$RecentIncrBackup = $GetBackupHistory | sqlplus -silent "$Username/$Password@$TargetDB as sysbackup" | Select-Object -Skip 1

$RMANCommand = "RMAN TARGET '`"$Username/$Password@$TargetDB as SYSBACKUP`"' CATALOG $Username/$Password@$CatalogDB 
{0};"

#RMAN @$CMDFile $CatalogDB "list backup"#| Out-File -FilePath $TempOutputFile  -Force

$SQL = $RMANCommand -f "DELETE OBSOLETE; `r`nLIST BACKUP"

$SQL | cmd | Out-File -FilePath $TempOutputFile  -Force
#String =  [Regex]::Escape($BULocation)

$FullBackupDates = Select-String -Path $TempOutputFile -Pattern "Tag: FULL_WEEKLY_BACKUP*" -Context 1, 1 | Select-Object -Property Line, @{Name= 'PreContext'; Expression = {$_.Context.PreContext}}
$StrLength = ($FullBackupDates.PreContext)[0].Length
$FullBackupDates = ($FullBackupDates.PreContext).Substring($StrLength - 15, 9) 

write-host "`r`nstart of the week is $StartOfWeek"

$HasRecentFullBackup = $false

foreach($DateString in $FullBackupDates)
{
    if([datetime]::ParseExact($DateString, 'dd-MMM-yy', $null) -ge $StartOfWeek -and $null -ne $RecentIncrBackup)
    {
        $HasRecentFullBackup = $true
    }
    
}

#--------------------------------- PERFROM BACKUPS ---------------------------------------------------- 

#Perform FULL database backups on Sunday (ONCE A WEEK) if the script is ran on a Sunday After 10pm
if ($CurrentDate.DayOfWeek -eq "Sunday" -and $CurrentDate.TimeOfDay.Hours -ge 22 -or $HasRecentFullBackup -eq $false)
{
#-------------------------------- FULL WEEKLY BACKUP ------------------------------------------------

    Write-Host "`r`nPerforming Weekly Full (Level 0) Database Backup`r`n"
   
    #Cleanup the backup location at the beginning of the week
    if ($CurrentDate.DayOfWeek -eq "Sunday" -and $CurrentDate.TimeOfDay.Hours -ge 22)
    {
        Get-ChildItem $BULocation | Where-Object {$_.Lastwritetime -lt (Get-date).AddDays(-2).ToString("yyyy-MM-dd")} | remove-item
    }
    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL = $RMANCommand -f "RUN {EXECUTE SCRIPT Weekly_Full_Backup;}" 
    $SQL | CMD | Out-File $BuLogFile –Append
}
elseif ($CurrentDate.DayOfWeek -eq "Wednesday" -and $CurrentDate.TimeOfDay.Hours -ge 22)
{
#---------------------------- MID-WEEK BACKUP ------------------------------------------------------

    Write-Host "`r`nPerforming Mid-Week Cumulative Database Backup`r`n"
    
    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL = $RMANCommand -f "RUN {EXECUTE SCRIPT Mid_Week_Cumulative_Backup;}" 
    $SQL | CMD | Out-File $BuLogFile –Append 
}
else
{
#----------------------------- DAILY DIFFERENTIAL BACKUP ------------------------------------------

    Write-Host "`r`nPerforming Differential Backup`r`n"

    # Execute the RMAN command file and pipe the results to the output logfile
    $SQL = $RMAN -f "RUN {EXECUTE SCRIPT Daily_Differential_Backup;}" 
    $SQL | CMD | Out-File $BULogFile -Append
}
#>
#-------------------------------- WEEKLY BACKUP ------------------------------------------------

If ($Currentdate.DayOfWeek -eq 'Friday' -and $CurrentDate.TimeOfDay.Hours -ge 18)
{
    Get-ChildItem $WeeklyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).AddDays(-60).ToString("yyyy-MM-dd")} | remove-item

    Write-Host "Archiving Files in Weekly location"

    $BuSourceList = Get-ChildItem $BULocation\* -Exclude "*.txt" | Where-Object {$_.LastWriteTime -ge $CurrentDate.AddDays(-5)}
    $BuSourceList.FullName | Out-File -FilePath $TempOutputFile 
    
    #Location of the Winrar executable file  
    $WinRar = "C:\Program Files\WinRAR\rar.exe"

    #Set FullName path for the archive file where compressed backup files will be stored
    $ArchiveFile = $WeeklyLoc + "$($TargetDB)_WeeklyBackup.rar"
    
    #Deletes the Archive file if it already exists
    if(Test-Path $ArchiveFile)
    {
        Remove-Item $ArchiveFile
    }
    
    #Execute command to compress backup files into an archive file
    & $winrar u -ibck -y $ArchiveFile @$TempOutputFile
    
    #---------------------------------- MONTHLY BACKUP --------------------------------------------

    # If the backup begins on the last friday of the month copy the compressed weekly database set to the monthly folder
    if ($Currentdate.Date -eq $LastFriday.Date)
    {
        Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt (Get-date).Adddays(-60).ToString("yyyy-MM-dd")} | remove-item
        Write-Host "Archiving Files in Monthly location"

        Copy-Item $ArchiveFile -Destination "$MonthlyLoc\$($TargetDB)_MonthlyBackup.rar"
    }	

}# end of if-block

# if (Test-Path $TempOutputFile)
# {
#     Remove-Item $TempOutputFile
# }

#Stop stop watch
$StopWatch.Stop()

$TotalTime = $StopWatch.Elapsed

#Add the total time taken to complete the backup to the logfile
Out-File -FilePath "$BuLogFile"  -Append -InputObject ("`r`nTotal Time to Complete Backup: " + ($TotalTime).ToString("hh'hr:'mm'min:'ss'sec'"))

Write-Output "`r`nThe Backup logfile file can be found at $BULogFile"
#>