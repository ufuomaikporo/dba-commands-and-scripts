Push-Location
Import-Module sqlps
Pop-Location

$InstanceName = "SQL2014EXT"


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

$DailyBackupList = "SELECT name, state_desc AS Status FROM sys.databases 
                    WHERE name LIKE '%IRAS%'
                    AND state_desc = 'ONLINE'
                    ORDER BY 1"

if ($LastFriday.AddDays(-5).Date -eq $CurrentDate.Date)
{
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $EOMBackupList  -QueryTimeout 0
}
else
{
    $DBBackupList = Invoke-Sqlcmd -ServerInstance $InstanceName -Database "master" -Query $DailyBackupList  -QueryTimeout 0
}

#-------------------------------------- FOLDERS AND BACKUP DIRECTORIES -----------------------------

#Nightly backup storage location
$BuLocation = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$FolderName\Nightly\"
$WeeklyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$FolderName\Weekly\"
$MonthlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$FolderName\Monthly\"

#File name for logfile that will store output of this backup script
$BuLogFile =  $BULocation + "$($FolderName)_BULog_Nightly.txt"
####################################### WEEKLY & MONTHLY BACKUP ##########################################
 $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
          
<#
If the script is being run on a Friday evening at or after 6PM, archive each database backup in a zipfile and copy the 
archive file to the weekly backup location. If it is the last Friday of the month, copy the archive file to 
the monthly backup location as well
#>

if (1 -eq 1) 
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

#Out-File -filepath "$BULogFile"  -append -inputobject ("`r`nTotal Time to Complete Backup: " + ($TotalTime).ToString("hh'hr:'mm'min:'ss'sec'"))

Write-Output "`r`nDatabase Backup Completed: $(Get-Date)     Duration: $($TotalTime.ToString("hh'hr:'mm'min:'ss'sec'"))"