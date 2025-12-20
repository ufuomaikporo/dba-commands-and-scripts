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

$Password = "DBBackupUser" 

# List of target Servers for SQL Server Agent jobs
$SQLServerDBs = $arr = @([PSCustomObject]@{ServerName = 'PAA-SQL01'; ServerType = "Production"}
                         [PSCustomObject]@{ServerName = 'CTSQL01'; ServerType = "Production"}
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
		StepExecutionDate,
        StepDuration,
		ROW_NUMBER() OVER (PARTITION BY JobName, ServerName ORDER BY StepExecutionDate DESC, JobName, ServerName) row_num 
 FROM AgentJob tab1
 WHERE StepName = '(Job outcome)' 
) SELECT ServerName, 
         TRIM(REPLACE(JobName, '(local)', '')) JobName, 
         StepName, 
         StepStatus, 
         StepExecutionDate AS JobExecutionDate, 
         StepDuration AS Duration
INTO Temp_JobsTable
FROM CTE 
WHERE row_num = 1
AND StepExecutionDate >= DATEADD(DAY, -1, GETDATE())
ORDER BY JobName, ServerName;

-- Change SentEmail column to 0 in AgentJobEmailTracker table if a new run exists 
WITH CTE AS
(SELECT jt.JobName, 
       ISNULL(aet.SentEmail, 0) SentEmail, 
       FORMAT(jt.JobExecutionDate, 'yyyy-MM-dd HH:mm:00') AS JobExecutionDate,
       COUNT(jt.ServerName) ServerCount
FROM Temp_JobsTable jt
LEFT JOIN dbo.AgentJobEmailTracker aet
ON jt.JobName = aet.JobName
AND jt.JobExecutionDate = aet.JobExecutionDate
GROUP BY jt.JobName, FORMAT(jt.JobExecutionDate, 'yyyy-MM-dd HH:mm:00'), aet.SentEmail
)
UPDATE AgentJobEmailTracker
SET SentEmail = 0,
	JobExecutionDate = cte.JobExecutionDate
FROM AgentJobEmailTracker ajt
JOIN CTE ON ajt.JobName = cte.JobName
WHERE cte.JobExecutionDate <> ajt.JobExecutionDate

SET @SQL = 'SELECT jt.JobName, 
       ISNULL(aet.SentEmail, 0) SentEmail, 
       JobExecutionDate = CAST(FORMAT(jt.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'') AS DATETIME),
	   CAST(tab.JobDuration/10000 AS VARCHAR) + ''hr:'' + CAST((tab.JobDuration % 10000)/100 AS VARCHAR) 
				+ ''min:'' + CAST((tab.JobDuration % 100) AS VARCHAR) + ''sec'' AS Duration,
       COUNT(jt.ServerName) ServerCount
FROM Temp_JobsTable jt
LEFT JOIN dbo.AgentJobEmailTracker aet
ON jt.JobName = aet.JobName
AND FORMAT(jt.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'') = FORMAT(aet.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'')
LEFT JOIN (SELECT JobName, MAX(Duration) JobDuration 
			FROM Temp_JobsTable
			GROUP BY JobName) tab
ON tab.JobName = jt.JobName
GROUP BY jt.JobName, 
         ISNULL(aet.SentEmail, 0), 
         FORMAT(jt.JobExecutionDate, ''yyyy-MM-dd HH:mm:00''),
          tab.JobDuration'

EXECUTE (@SQL)"

if ($MasterServer -eq "CTSQL01")
{
    $SQLAgentJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
}
else
{
    $SQLAgentJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
}

$SQLAgentJobs | Format-Table

$EmailPriority = 0


foreach ($Job in $SQLAgentJobs)
{  

    # Only execute if the job is completed on all servers and an email has not already been sent for the job  
    if ($Job.SentEmail -ne 1 -and $Job.ServerCount -eq $TargetServerCount)
    {
        
        $Message = "****************************************************************************************************`r`n"
        $Message += "Job Name  : $($Job.JobName)`r`n"
        $Message += "Date      : $($Job.JobExecutionDate.ToString("ddd MMM dd yyyy"))`r`n"
        $Message += "StartTime : $($Job.JobExecutionDate.ToString("hh:mm tt"))`r`n"
        $Message += "Duration  : $($Job.Duration)"
        $Message += "`r`n****************************************************************************************************`r`n"
        $Message | Out-File -FilePath $ReportFile -Append 
        
        #Check to see if there a reference/detail table for the job
        $SQL = "SELECT ReferenceTable AS TableName FROM dbo.AgentJobsDetailProcedure WHERE JobName = '$($Job.JobName)'"


        if ($MasterServer -eq "CTSQL01")
        {
            $ReferenceTable = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
        }
        else
        {
            $ReferenceTable = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
        }
  
 
        #Use the detail table if it exists
        if(!([string]::IsNullOrWhitespace($ReferenceTable)))
        {
            # For each agent job find servers that failed to complete job or completed with error
            $SQL = "DECLARE @StoredProc NVARCHAR(100)
            DECLARE @SQL NVARCHAR(MAX)
            SELECT @StoredProc = ProcedureName FROM dbo.AgentJobsDetailProcedure WHERE JObName = '$($Job.JobName)'
            SET @SQL = 'EXECUTE ' + @StoredProc + ' @JobName = ''$($Job.JobName)'''
            
            EXECUTE (@SQL)"

            if ($MasterServer -eq "CTSQL01")
            {
                $FailedJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
            }
            else
            {
                $FailedJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
            }
        }
        else
        {
            $SQL = "SELECT * FROM Temp_JobsTable WHERE StepStatus <> 'Succeeded' AND JobName = '$($Job.JobName)'"

            if ($MasterServer -eq "CTSQL01")
            {
                $FailedJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
            }
            else
            {
                $FailedJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
            }
        }
        
        # Generate message in a file for failed Agent jobs and set email priority to high
        if (!([string]::IsNullOrWhitespace($FailedJobs)))
        {
            $Message = "The '$($Job.JobName)' Job FAILED or completed WITH ERRORS on the following Servers"
            $Message | Out-File -FilePath $ReportFile -Append 
       
            $FailedJobs | Select-Object -Property ServerName, JobExecutionDate, Duration -Unique | Out-File -FilePath $ReportFile -Append 

            if (!([string]::IsNullOrWhitespace($FailedJobs.ReportedIssue)))
            {
                $Message = "Possible Reasons for Failure:"
                $Message | Out-File -FilePath $ReportFile -Append 

                $FailedJobs | Select-Object -Property ServerName, DatabaseName, ReportedIssue, LastBackupStartDate `
                  | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append
            } 
           
            $EmailPriority = 2
        }

        # For each agent job find servers that completed successfully
        $SQL = "SELECT ServerName,
                       JobExecutionDate,
                       CAST(Duration/10000 AS VARCHAR) + 'hr:' + CAST((Duration % 10000)/100 AS VARCHAR) 
				            + 'min:' + CAST((Duration % 100) AS VARCHAR) + 'sec' AS Duration
                FROM Temp_JobsTable WHERE StepStatus = 'Succeeded' AND JobName = '$($Job.JobName)'"

        if ($MasterServer -eq "CTSQL01")
        {
            $SuccessfulJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
        }
        else
        {
            $SuccessfulJobs = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
        }

        #List the servers with successful job execution
        If(!([string]::IsNullOrWhitespace($SuccessfulJobs)))
        {
            $Message = "The '$($Job.JobName)' Job COMPLETED SUCESSFULLY on the following Servers"
            $Message | Out-File -FilePath $ReportFile -Append 
                
            $SuccessfulJobs | Select-Object -Property ServerName, JobExecutionDate, Duration | Out-File -FilePath $ReportFile -Append 
        }

        #Write a message about the job details table if one exists
        if (!([string]::IsNullOrWhitespace($ReferenceTable)))
        {
            $Message = "***NOTE***: More info on database backups can be found in the `"$($ReferenceTable.TableName)`"`r`n"
            $Message += "table on the $MasterServer server.`r`n"
            $Message | Out-File -FilePath $ReportFile -Append
        }

        #List of jobs that will be included in email
        $JobsList += "$($Job.JobName)`r`n"
        
        #Insert entry into AgentJobEmailTracker table to indicate that an email has been sent for the Agent job
        $SQL = "IF NOT EXISTS (SELECT * FROM AgentJobEmailTracker WHERE JobName = '$($Job.JobName)')
                BEGIN
                    INSERT INTO dbo.AgentJobEmailTracker (JobName, SentEmail, EmailDate, JobExecutionDate)
                    SELECT '$($Job.JobName)', 1, GETDATE(), '$(($Job.JobExecutionDate.ToString("yyyy-MM-dd HH:mm:ss")))'
                END
                ELSE
                BEGIN
                    UPDATE dbo.AgentJobEmailTracker
                    SET SentEmail = 1,
                        EmailDate = GETDATE(),
                        JobExecutionDate = '$(($Job.JobExecutionDate.ToString("yyyy-MM-dd HH:mm:ss")))'
                    WHERE JobName = '$($Job.JobName)'
                END"

        if ($MasterServer -eq "CTSQL01")
        {
            $Void = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Username "DBBackupUser" -Password $Password -Query $SQL
        }
        else
        {
            $Void = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL
        }
               
        
    }                  
}

return

#----------------------------------------------------------- SEND EMAIL -----------------------------------------------------

$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net" #, "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 

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

$EmailBody += "`r`n`r`n***NOTE***: More details about failed or successful Agent jobs can be found in the `"DrasInternal.dbo.AgentJob`" table on the $MasterServer server." 

if ($JobsList -ne $null)
{        
       
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
#>