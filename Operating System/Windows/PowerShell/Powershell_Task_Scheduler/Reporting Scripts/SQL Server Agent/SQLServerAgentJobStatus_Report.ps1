# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

Write-Output "`r`n***********************************************************************************************"
Write-Output "Script Executed on : $(Get-Date -Format "dddd dd MMM yyyy hh:mm:ss tt")"
write-Output "-----------------------------------------------------------------------------------------------`r`n"

$ReportFile = "B:\Scripts\Reporting Scripts\SQLServerAgentJobReport.txt" 

$MasterServer = $env:ComputerName

$SQL = "EXECUTE sp_GatherAgentJobInfo @MasterServer = '$MasterServer'"


# Get the SQL Server Agent job status for the server where this script is being ran (Assumes the script is ran on the master server for SQL Server multi-server jobs)
Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL


$SQL = "SELECT Servername, JobName, StepName, StepStatus, StepExecutionDate
FROM AgentJobStatus tab1
WHERE EXISTS (SELECT JobName FROM  AgentJobStatus tab2
                WHERE tab1.ServerName = tab2.ServerName
                AND tab1.JobName = tab2.JobName 
                AND tab1.StepStatus = tab2.StepStatus
                AND StepStatus <> 'Succeeded'
            )
AND StepExecutionDate > GETDATE() - 1"


$SQLAgentJobStatus = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL


if(Test-Path -Path $ReportFile) 
{
    remove-item $ReportFile
}

if ($SQLAgentJobStatus -ne $null)
{
    $Message = "`r`nThe following SQL Server Agent jobs completed with errors in one or more of their execution steps. Check the AgentJobStatus table"
    $Message += "`r`nlocated in the DrasInternal database on the $MasterServer server for more details on the errors listed in the attached report." 
    $Message |  Out-File -FilePath $ReportFile -Append
    $Message = $SQLAgentJobStatus | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append

    # Set the email subject line
    $EmailSubjectLine = "SQL Server Agent Jobs Error Report"
   
    $emailBody = "Some SQL Server Agent Jobs failed to complete without errors. A list of the Agent job steps that completed with errors can be found in the attached file."
    $emailBody += " Details about the error messages associated with each job step can be found in the 'message' column of the AgentJobStatus table within the DrasInternal"
    $emailBody += "database on the master server ($($MasterServer))"
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

Write-Output "`r`nScript Completed At: $(Get-Date)"
