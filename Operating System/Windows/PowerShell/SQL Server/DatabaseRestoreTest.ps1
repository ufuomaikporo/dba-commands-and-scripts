$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

$OldLocation = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2019\Nightly\"
$NewLocation = "\\EDDYFINDT.COM\DRAS-Shares\Test\DBbackupsTest\SQL2019\Nightly\"
$DB = "EEC_EA_Projects_IRASV6_STAGE"
  
  
$NewRestoreDB = "RESTORE FILELISTONLY  
FROM DISK = '$NewLocation\$DB.bak' ;"

$OldRestoreDB = "RESTORE FILELISTONLY  
FROM DISK = '$OldLocation\$DB.bak';"

$Type = 'O'

$StopWatch.Start()
if($Type -eq 'N')
{
    $Rest = Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $NewRestoreDB
    $LogicDataFile = $Rest[0].LogicalName
    $LogicLogFile = $Rest[1].LogicalName

    $NewRestoreDB = "RESTORE DATABASE $DB 
    FROM DISK = '$NewLocation\$DB.bak' 
    WITH RECOVERY,
    MOVE '$LogicDataFile' TO 'D:\SQLData\DATA\$DB`2.mdf',   
    MOVE '$LogicLogFile' TO 'L:\LogFiles\$DB`_Log.ldf';
    GO"

    $Rest = Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $NewRestoreDB
    #Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $NewRestoreDB_2
    $loc = 'New location'
}
else
{
    $Rest = Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $OldRestoreDB
    $LogicDataFile = $Rest[0].LogicalName
    $LogicLogFile = $Rest[1].LogicalName

    $OldRestoreDB = "RESTORE DATABASE $DB 
    FROM DISK = '$OldLocation\$DB.bak'
    WITH RECOVERY,
    MOVE '$LogicDataFile' TO 'D:\SQLData\DATA\$DB`2.mdf',   
    MOVE '$LogicLogFile' TO 'L:\LogFiles\$DB`_Log.ldf'; 
    GO"

    Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $OldRestoreDB

    #Invoke-Sqlcmd -ServerInstance 'SQL2019DEV' -Query $OldRestoreDB_2
    $loc = 'Old location'
}
$StopWatch.Stop()
Write-Host "`r`nTotal time to complete restore from $loc`:" $StopWatch.Elapsed "`r`n"