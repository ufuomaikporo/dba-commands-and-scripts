$SuccessLog = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\ORA19C22\Nightly\SDE.log" 
$FailLog = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temporary Backups\SDE.log"
$Log = $FailLog
$TempLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temporary Backups\"
$NightlyLoc = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$ServerName\Nightly\" 
$BuLocation = $TempLoc # SETS NIGHTLY BACKUP LOCATION
$Schema = "SDE"
"$BULocation$Schema.log"

 if(Select-String -Path "$BULocation$Schema.log" -Pattern "successfully completed")
{
		    WRITE-HOST "SUCCESSFUL BACKUP"
}
else
{
    Write-Host "Failed backup"
}