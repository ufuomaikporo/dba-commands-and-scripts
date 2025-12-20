$SQLServerDBs = @(('SQL2012EXT', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2012EXT\Nightly\') `
                  ,('SQL2014', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2014\Nightly\') `
                  ,('SQL2016', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2016\Nightly\') `
                  ,('SQL2016\latin1_general', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2016_latin1_general\Nightly\') `
                  ,('SQL2017', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2017\Nightly\') `
                  ,('SQL2019', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2019\Nightly\') `
                  ,('SQLDEVPREPROD', '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQLDEVPREPROD\Nightly\') `
                )
#$SQLServerDBs = 'SQL2016\latin1_general'
$ExecutionServer = 'SQL2019'
$ExecutionDB = 'DrasInternal'
$ReportFile = 'C:\Temp\BackupRestoreValidityCheck.txt'

$RunStoredProc = "EXECUTE dbo.sp_RestoreBackupFileCheck @BULocation = '{0}', @DataFileLoc = 'D:\'"
 
if(Test-Path -Path $ReportFile)
{
    Remove-Item $ReportFile
}

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$StopWatch.Start()

foreach ($ServerName in $SQLServerDBs)
{
    Write-Host "`r`nTesting Backup Restore for Databases on $($ServerName[0])"

    $StartTime = Get-Date -Displayhint datetime

    $SQL = $RunStoredProc -f $ServerName[1]
  
    $QueryOutput = Invoke-Sqlcmd -ServerInstance $ExecutionServer -Database $ExecutionDB -Query $SQL -QueryTimeout 7200

    $EndTime = Get-Date -Displayhint datetime
    $ElapsedTime = ($EndTime - $StartTime).ToString("hh'hr:'mm'min:'ss'sec'")

    Write-Output "******************************************************************************************************" | Out-File -Append $ReportFile
    Write-Output "SERVER: $($ServerName[0]) " | Out-File -Append $ReportFile
    Write-Output "BACKUP LOCATION: $($ServerName[1])" | Out-File -Append $ReportFile
    Write-Output "Start Time - $StartTime" | Out-File -Append $ReportFile
    Write-Output "End Time - $EndTime" | Out-File -Append $ReportFile
    Write-Output "Elapsed Time - $ElapsedTime" | Out-File -Append $ReportFile
    Write-Output "`r`nThe following backups are invalid`r`n" | Out-File -Append $ReportFile
    #Write-Output "******************************************************************************************************" | Out-File -Append $ReportFile

    $QueryOutput | Sort-Object -Property DbName | Format-Table -AutoSize | Out-File -Append $ReportFile

    Write-Output "`r`n`r`n" | Out-File -Append $ReportFile

    
    #>
}

$StopWatch.Stop()

$TotalTime = $StopWatch.Elapsed

Write-Output "`r`nTotal Time to Complete Backup Restore Test: $($TotalTime.ToString("hh'hr:'mm'min:'ss'sec'"))"

#>