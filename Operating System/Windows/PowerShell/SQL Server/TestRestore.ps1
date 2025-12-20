$TestServer = "SQL2019DEV"
$Server = $TestServer.Substring(0,7)
$OldLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$Server\Nightly\"
$NewLocation1 = "\\EDDYFINDT.COM\DRAS-Shares\Test\DBbackupsTest\$Server\Nightly\"
$NewLocation2 = "\\dras-util01\DBBackups_Test\"
$DB = "EPCO_IRASv5_GAS_STAGE"
$File = $OldLoc + $DB + ".bak"

$GetRestoreFiles = "RESTORE FILELISTONLY FROM DISK = '$File'"

$RestoreFiles = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $GetRestoreFiles
$LogicalDataFile = $RestoreFiles[0].LogicalName
$LogicalLogFile = $RestoreFiles[1].LogicalName

$RestoreCmd = "RESTORE DATABASE $DB
FROM DISK '$File'
WITH RECOVERY
MOVE '$LogicalDataFile' TO "

'RESTORE DATABASE ' + @db + '
FROM DISK = ''' +  @loc + '''
WITH RECOVERY,
MOVE ''PLAINS_IRASV5_STAGE_Upg504 '' TO ''D:\SQLDATA\' + @db + '.mdf'',   
MOVE ''PLAINS_IRASV5_STAGE_Upg504_log'' TO ''L:\SQLDATA\' + @db + '_Log.ldf'''
