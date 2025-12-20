# Get script input params
$TargetDB = HOSTNAME.EXE
$CatalogDB = 'ORA19C'
$Username = 'RMAN'
$Password = 'rman'
$FullBackupScript = 'ORA19C22_FULL_Weekly_Backup'
$DiffBackupScript = 'ORA19C22_Daily_Differential_Backup'
$CummulativeBackupScript = 'ORA19C22_MidWeek_Cummulative_Backup'
$WeeklyBackupTag = "WEEKLY_FULL_BACKUP"     
$DailyBackupTag = "$((Get-Date).DayOfWeek)_DIFF_BCKP"
$MidWeekBackupTag = "MIDWEEK_CUMULATIVE_BCKP"

#Backup Folders 
$BULocation ="B:\Fast Recovery Area\ORA19C22\Backups\"
$NightlyLoc = "$BULocation$(Get-Date -Format 'MM_dd_yyyy')\"
$WeeklyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\ORA19C22\Testing\Weekly\"
$MonthlyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\ORA19C22\Testing\Monthly\"
$ControlFileBackupLoc = "$($NightlyLoc)ControlFile\"

# Output logfile for this script run
$BULogFile = "$NightlyLoc$($TargetDB)_BULog_Nightly_$(Get-Date -Format 'MM_dd_yyyy_HH').txt"

#Temporary Output file
$TempFileName = "Tempfile_$($TargetDB)Backup.txt"
$TempOutputFile = $NightlyLoc + $TempFileName

$BuList = Get-ChildItem $BULocation -Recurse -Exclude $TempFileName  | Where-Object {$_.LastWriteTime -ge $StartOfWeek }#-and $_.Mode -eq '-a----'} 
$BUList