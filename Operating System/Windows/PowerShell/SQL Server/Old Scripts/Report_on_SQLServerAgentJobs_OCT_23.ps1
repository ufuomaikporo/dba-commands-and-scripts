$ReportFile = "C:\Users\Ufuoma_Ikporo\SQLServerBackupTestingReport.txt" 

$SQL = "SELECT Servername, JobName, StepNumber, StepName, StepStatus, StepExecutionDate
FROM AgentJobStatus tab1
WHERE EXISTS (SELECT JobName FROM  AgentJobStatus tab2
WHERE tab1.ServerName = tab2.ServerName
AND tab1.JobName = tab2.JobName AND
StepExecutionDate > GETDATE() - 1
AND StepStatus <> 'Succeeded')"

$SQLAgentJobStatus = Invoke-Sqlcmd -ServerInstance "DRASSQL2022" -Database "DrasInternal" -Query $SQL

if(Test-Path -Path $ReportFile) 
{
    remove-item $ReportFile
}

if ($SQLAgentJobStatus -ne $null)
{
    $Message = "`r`nThe following SQL Server Agent jobs had errors in one or more of their execution steps. Check the AgentJobStatus table"
    $Message += "`r`nin the DrasInternal database on the SQL Server Agent master server for more details on the errors listed below." 
    $Message |  Out-File -FilePath $ReportFile -Append
    $SQLAgentJobStatus | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append
}

# Set the email subject line
$EmailSubjectLine = "SQL Server Agent Jobs Error Report"

# Check if the report file is empty
if (Test-Path $ReportFile)
{
    if ([IO.File]::ReadAllText($ReportFile))
    {

        $emailBody = "Some nightly SQL Server database backups were found to either be invalid for restores or more than a day old"
        $emailPriority = 2

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
    }
}
