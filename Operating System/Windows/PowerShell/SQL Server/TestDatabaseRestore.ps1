$TestServer = "SQL2019DEV"
$Server = $TestServer.Substring(0,7)
$OldLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$Server\Nightly\"
$NewLocation1 = "\\EDDYFINDT.COM\DRAS-Shares\Test\DBbackupsTest\$Server\Nightly\"
$NewLocation2 = "\\dras-util01\DBBackups_Test\"
$DB = "EPCO_IRASv5_GAS_STAGE"
$File = $OldLoc + $DB + ".bak"


$GetRestoreFiles = "RESTORE FILELISTONLY FROM DISK = '$File'"

$RestoreFiles = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $GetRestoreFiles
$RestoreFiles
