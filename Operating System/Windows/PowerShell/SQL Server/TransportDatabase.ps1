$ServerName = "SQL2012"

$DateFileDir = "F:\SQLDATA2\"
$LogFileDir = $DateFileDir

$BackupDir = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temporary Backups\SQL2012"
$BackupFiles = Get-ChildItem $BackupDir\*.bak
$GetFileInfo = "RESTORE FILELISTONLY  
FROM DISK = '{0}'; "
$RestoreCmd = "RESTORE DATABASE {0}  
FROM DISK = '{1}'  
WITH RECOVERY,  
MOVE '{2}' TO '{3}',   
MOVE '{4}' TO '{5}';"

$DatabasesOnServer = "Select name from sys.databases
WHERE name = '{0}'"

foreach ($File in $BackupFiles)
{
try {
    $FileName.BaseName
    $SQL = $DatabasesOnServer -f $File.BaseName
    $IfExists = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL

    if ($IfExists)
    {
        Continue
    }

    $File.BaseName
    
    # $SQL = $GetFileInfo -f $File.FullName
    # $FileInfo = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL
    # $LogiicalDataFile = $FileInfo.LogicalName[0]
    # $LogicalLogFile = $FileInfo.LogicalName[1]
    # $DataFileLoc = $DateFileDir + $File.BaseName + '_DATA.mdf'
    # $LogFileLoc = $LogFileDir + $File.BaseName + '_LOG.mdf'

    # $SQL = $RestoreCmd -f $File.BaseName, $File.FullName, $LogiicalDataFile, $DataFileLoc, $LogicalLogFile, $LogFileLoc
    # Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL
}catch {
    Write-Host $_
}

}




