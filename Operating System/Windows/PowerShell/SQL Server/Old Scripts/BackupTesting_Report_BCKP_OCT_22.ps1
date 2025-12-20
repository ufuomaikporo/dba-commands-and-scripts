$SQL = "SELECT ServerName, 
	   DatabaseName, 
	   FileName, 
	   FilePosition, 
	   BackupType,
	   BackupFileStatus,
	   DaysSinceLastBackup,
	   BackupStartDate
FROM InvalidBackupReport
WHERE BackupFileStatus = 'INVALID'
OR DaysSinceLastBackup > 1
"

$ReportFile = "C:\Users\Ufuoma_Ikporo\SQLServerBackupTestingReport.txt" 
$BUFolder = (Hostname.exe).Replace("\", "_")
$BULocation = "\\dras-dbbkp02\P_DB_Backups_Nightly\$BUFolder\Nightly"

$BULocation
return

$SQLServerDBs = $arr = @([PSCustomObject]@{ServerName = 'DRASSQL2012EXT'}
                         [PSCustomObject]@{ServerName = 'SQL2014EXT'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016\latin1_general'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2017'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2019'}
                         [PSCustomObject]@{ServerName = 'IRAS-PREP-SQL01'}
                     )
            

"" | Out-File -FilePath $ReportFile -Force 

foreach ($ServerName in $SQLServerDBs.ServerName)
{
    #$ServerName
    $Message = "`r`n******************************************** $ServerName ********************************************`r`n"
    $Message += "`r`nThe following database backups from the $ServerName server are either invalid or more than a day old."
    $Message += "`r`n`r`nBackup Directory: \\dras-dbbkp02\P_DB_Backups_Nightly\$($ServerName.Replace("\", "_"))\Nightly"
    $FlaggedBackups = Invoke-Sqlcmd -ServerInstance "DRASSQL2022" -Database "DrasInternal" -Query $SQL | Where-Object {$_.ServerName -eq $ServerName}

   
    if ($FlaggedBackups -ne $null)
    {
        $Message | Out-File -FilePath $ReportFile -Append 
        $FlaggedBackups | Where-Object {$_.ServerName -eq $ServerName} | Select-Object -Property  FileName, DatabaseName, BackupFileStatus, DaysSinceLastBackup `
        | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append
    }
}

$SQL = "SELECT Servername, JobName, StepStatus, StepExecutionDate
FROM AgentJobStatus 
WHERE StepExecutionDate > GETDATE() - 1.0/24
AND StepStatus <> 'Succeeded'"

$SQLAgentJobStatus = Invoke-Sqlcmd -ServerInstance "DRASSQL2022" -Database "DrasInternal" -Query $SQL


if ($SQLAgentJobStatus -ne $null)
{
    $Message = "`r`nThere were some errors in the SQL Server Agent job execution. Check the AgentJobStatus table in the DrasInternal"
    $Message += "`r`ndatabase on the DRASSQL2022 server for more information on the error." 
    $Message |  Out-File -FilePath $ReportFile -Append
    $SQLAgentJobStatus | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append
}


# Set the email subject line
$EmailSubjectLine = "SQL Server Nightly Database Backup Report"

# Check if the report file is empty
if ([IO.File]::ReadAllText($ReportFile))
{

    $emailBody = "Some nightly SQL Server database backups were found to either be invalid for restores or more than a day old"
    $emailPriority = 2
}
else
{
    $emailBody = "All nightly backups from non-production servers are valid and up to date"
    $emailPriority = 0
}


$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net" #, "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 

#Construct and send the email message
Send-MailMessage `
-To $EmailRecipientList `
-From "HP9000@dynamicrisk.net" `
-Subject $EmailSubjectLine `
-attachment "$ReportFile" `
-priority $emailPriority `
-SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
-Body $emailBody
#>