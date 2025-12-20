Write-Output "`r`n***********************************************************************************************"
Write-Output "Script Executed on : $(Get-Date -Format "dddd dd MMM yyyy hh:mm:ss tt")"
write-Output "-----------------------------------------------------------------------------------------------`r`n"

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

$StopWatch.Start()

$ReportFile = "B:\Scripts\Reporting Scripts\SQLServerAgentJobReport.txt" 

$null | Out-File $ReportFile -Force

$MasterServer = $env:ComputerName


# List of target Servers for SQL Server Agent jobs
$SQLServerDBs = $arr = @([PSCustomObject]@{ServerName = 'DRASSQL2012EXT'}
                         [PSCustomObject]@{ServerName = 'SQL2014EXT'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016\latin1_general'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2017'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2019'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2022'}
                         [PSCustomObject]@{ServerName = 'IRAS-PREP-SQL01'}
                     )


$TargetServerCount = $SQLServerDBs.count

$SQL = "
DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('Temp_JobsTable', 'U') IS NOT NULL
BEGIN
	DROP TABLE Temp_JobsTable
END;

WITH CTE AS
(SELECT ServerName, 
		REPLACE(JobName, '(local)', '') JobName, 
		StepName, 
		StepStatus, 
		StepExecutionTime,
        StepDuration,
		ROW_NUMBER() OVER (PARTITION BY JobName, ServerName ORDER BY StepExecutionTime DESC, JobName, ServerName) row_num 
 FROM AgentJobStatus tab1
 WHERE StepName = '(Job outcome)' 
) SELECT ServerName, 
         TRIM(REPLACE(JobName, '(local)', '')) JobName, 
         StepName, 
         StepStatus, 
         StepExecutionTime AS JobExecutionDate, 
         StepDuration AS JobDuration
INTO Temp_JobsTable
FROM CTE 
WHERE row_num = 1
ORDER BY JobName, ServerName;

-- Change SentEmail column to 0 in AgentJobEmailTracker table if a new run exists 
WITH CTE AS
(SELECT jt.JobName, 
       ISNULL(aet.SentEmail, 0) SentEmail, 
       jt.JobExecutionDate,
       COUNT(jt.ServerName) ServerCount
FROM Temp_JobsTable jt
LEFT JOIN dbo.AgentJobEmailTracker aet
ON jt.JobName = aet.JobName
GROUP BY jt.JobName, aet.SentEmail, jt.JobExecutionDate
)
UPDATE AgentJobEmailTracker
SET SentEmail = 0
FROM AgentJobEmailTracker ajt
JOIN CTE ON ajt.JobName = cte.JobName
AND cte.JobExecutionDate = ajt.JobExecutionDate
WHERE cte.JobExecutionDate <> ajt.JobExecutionDate

SET @SQL = 'SELECT jt.JobName, 
       ISNULL(aet.SentEmail, 0) SentEmail, 
       jt.JobExecutionDate,
       COUNT(jt.ServerName) ServerCount
FROM Temp_JobsTable jt
LEFT JOIN dbo.AgentJobEmailTracker aet
ON jt.JobName = aet.JobName
AND jt.JobExecutionDate = aet.JobExecutionDate
GROUP BY jt.JobName, aet.SentEmail, jt.JobExecutionDate'

EXECUTE (@SQL)"

$SQLAgentJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL

$EmailPriority = 0

foreach ($Job in $SQLAgentJobs)
{  

    # Only execute if the job is completed on all servers and an email has not already been sent for the job  
    if ($Job.SentEmail -ne 1 -and $Job.ServerCount -eq $TargetServerCount)
    {
  
       # For each agent job find servers that failed to complete job or completed with error
        $SQL = "SELECT * FROM Temp_JobsTable WHERE StepStatus <> 'Succeeded' AND JobName = '$($Job.JobName)'"

        $FailedJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL

        $Message = "************************************************************************************************`r`n"
        $Message += "Job Name: $($Job.JobName)"
        $Message += "`r`n************************************************************************************************`r`n"

        # Generate message in a file for failed Agent jobs and set email priority to high
        if (!([string]::IsNullOrWhitespace($FailedJobs)))
        {
            $Message += "`r`nThe '$($Job.JobName)' Job FAILED or completed WITH ERRORS on the following Servers"
            
            $EmailPriority = 2
        }

        $Message | Out-File -FilePath $ReportFile -Append 
       
        $FailedJobs | Select-Object -Property @{Name = "Failed Jobs"; Expression = {$_.ServerName}}, JobExecutionDate, JobDuration | Out-File -FilePath $ReportFile -Append 

        # For each agent job find servers that failed to complete job or completed with error
        $SQL = "SELECT * FROM Temp_JobsTable WHERE StepStatus = 'Succeeded' AND JobName = '$($Job.JobName)'"

        $SuccessfulJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL

        If(!([string]::IsNullOrWhitespace($SuccessfulJobs)))
        {
            $Message = "The '$($Job.JobName)' Job COMPLETED SUCESSFULLY on the following Servers"
        }

        $Message | Out-File -FilePath $ReportFile -Append 
                
        $SuccessfulJobs | Select-Object -Property @{Name = "Successful Jobs"; Expression = {$_.ServerName}}, JobExecutionDate, JobDuration | Out-File -FilePath $ReportFile -Append 


        if ($Job.JobName -match "Backup")
        {
            $Message = "***NOTE***: More info on database backups can be found in the `"DrasInternal.dbo.DatabaseBackupInfo`"`r`n"
            $Message += "table on the $MasterServer server.`r`n"
        }

        $Message | Out-File -FilePath $ReportFile -Append

        #List of jobs that will be included in email
        $JobsList += "$($Job.JobName)`r`n"
        
        #Insert entry into AgentJobEmailTracker table to indicate that an email has been sent for the Agent job
        $SQL = "IF NOT EXISTS (SELECT * FROM AgentJobEmailTracker WHERE JobName = '$($Job.JobName)' AND JobExecutionDate = '$($Job.JobExecutionDate)')
                BEGIN
                    INSERT INTO dbo.AgentJobEmailTracker (JobName, SentEmail, EmailDate, JobExecutionDate)
                    SELECT '$($Job.JobName)', 1, GETDATE(), '$(($Job.JobExecutionDate).ToString("yyyy-MM-dd HH:mm:ss"))'
                END"

               
        Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
        
    }
          
          
}

#----------------------------------------------------------- SEND EMAIL -----------------------------------------------------

$EmailSubjectLine = "SQL Server Agent Jobs"

if ($EmailPriority -eq 2)
{
    $EmailBody = "`r`n`r`nSome SQL Server Agent Jobs failed or completed with errors. The database servers`r`n"
    $EmailBody += "with failed Agent jobs are listed in the attached file."
}
elseif ($EmailPriority -eq 0)
{
    $EmailBody = "`r`n`r`nThe following SQL Server Agent Job(s) COMPLETED SUCESSFULLY.`r`n`r`n"
    $EmailBody += "JOB NAME`r`n---------------------------`r`n"
    $EmailBody += $JobsList
}

$EmailBody += "`r`n`r`n***NOTE***: More details about failed or successful Agent jobs can be found in the `"DrasInternal.dbo.AgentJobStatus`" table on the $MasterServer server." 
 
if ($JobsList -ne $null)
{        
    $EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net", "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 
       
    #Construct and send the email message
    Send-MailMessage `
    -To $EmailRecipientList `
    -From "HP9000@dynamicrisk.net" `
    -Subject $EmailSubjectLine `
    -attachment "$ReportFile" `
    -priority $emailPriority `
    -SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
    -Body $emailBody
}

$StopWatch.Stop()

Write-Output "`r`nScript Completed At: $(Get-Date)  Duration: $($StopWatch.Elapsed.ToString("hh'hr:'mm'min:'ss'sec'"))" 
