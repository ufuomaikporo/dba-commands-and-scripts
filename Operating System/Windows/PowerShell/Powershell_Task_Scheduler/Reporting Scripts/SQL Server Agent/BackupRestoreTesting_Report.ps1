Write-Output "`r`n***********************************************************************************************"
Write-Output "Script Executed on : $(Get-Date -Format "dddd dd MMM yyyy hh:mm:ss tt")"
write-Output "-----------------------------------------------------------------------------------------------`r`n"

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

$StopWatch.Start()

$MasterServer = Hostname.exe

# Set email recipients
$EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net", "daniel_cheung@dynamicrisk.net", "Jagdish_Chaudhary@dynamicrisk.net" 

$ReportFile = "B:\Scripts\Reporting Scripts\SQLServerBackupTestingReport.txt" 

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
            

"" | Out-File -FilePath $ReportFile -Force 

if ((Get-Date).Hour -ge 11 -and (Get-Date).Hour -lt 15)
{
  
    foreach ($ServerName in $SQLServerDBs.ServerName)
    {
 
        if ($ServerName -ne $MasterServer)
        {
            $SQL= "SELECT ServerName, 
			       tab2.Name AS DatabaseName,
	               CASE	WHEN LastBackupMessage <> 'SUCCESSFUL' THEN 'Failed Backup'
			            WHEN RestoreStatus <> 'VALID' THEN 'Invalid For Restore'
			            WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + ' Days Since Last Backup'
                        ELSE 'No Recent Backup'
	               END AS ReportedIssue,
	               FileName,
	               FilePosition, 
	               CASE WHEN LastBackupType LIKE '%Differential%' THEN 'Differential'
					    WHEN LastBackupType LIKE '%Full%' THEN 'Full'
			       END AS LastBackupType,
	               LastBackupStartDate
            FROM DatabaseBackupInfo tab1
		    RIGHT JOIN (SELECT * FROM OPENQUERY( [$ServerName], 'SELECT * FROM master.sys.databases')) tab2
		    ON tab1.ServerName = '$ServerName' 
		    AND tab1.DatabaseName = tab2.Name COLLATE DATABASE_DEFAULT 
		    WHERE tab2.name LIKE '%IRAS%' AND tab2.state_desc = 'ONLINE' 
		    AND (tab1.LastBackupStartDate < FORMAT(GETDATE(), 'yyyy-MM-dd 10:00:00')
		    OR tab1.LastBackupStartDate IS NULL)"
        }
        else
        {
            $SQL= "SELECT ServerName, 
			       tab2.Name AS DatabaseName,
	               CASE	WHEN LastBackupMessage <> 'SUCCESSFUL' THEN 'Failed Backup'
			            WHEN RestoreStatus <> 'VALID' THEN 'Invalid For Restore'
			            WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + ' Days Since Last Backup'
                        ELSE 'No Recent Backup'
	               END AS ReportedIssue,
	               FileName,
	               FilePosition, 
	               CASE WHEN LastBackupType LIKE '%Differential%' THEN 'Differential'
					    WHEN LastBackupType LIKE '%Full%' THEN 'Full'
			       END AS LastBackupType,
	               LastBackupStartDate
            FROM DatabaseBackupInfo tab1
		    JOIN sys.databases tab2
		    ON tab1.ServerName = '$ServerName' 
		    AND tab1.DatabaseName = tab2.Name  
		    WHERE tab2.name LIKE '%IRAS%' AND tab2.state_desc = 'ONLINE' 
		    AND (tab1.LastBackupStartDate < FORMAT(GETDATE(), 'yyyy-MM-dd 10:00:00')
		    OR tab1.LastBackupStartDate IS NULL)"
        }
    
        $Message = "`r`n*************************************************** $ServerName ***************************************************`r`n"
        $Message += "`r`nThe following database backups from the $ServerName server have some reported issues "
        $Message += "`r`n`r`nBackup Directory: \\dras-dbbkp02\P_DB_Backups_Nightly\$($ServerName.Replace("\", "_"))\Nightly"
        $FlaggedBackups = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL | Where-Object {$_.ServerName -eq $ServerName}
   
     
        if ($FlaggedBackups -ne $null)
        {
            $Message | Out-File -FilePath $ReportFile -Append 

            $FlaggedBackups | Where-Object {$_.ServerName -eq $ServerName} | `
            Select-Object -Property DatabaseName, ReportedIssue, `
             LastBackupType, LastBackupStartDate  `
            | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append
        }

    } #end of foreach loop
}
else
{

    foreach ($ServerName in $SQLServerDBs.ServerName)
    {
        if ($ServerName -ne $MasterServer)
        {
            $SQL = "SELECT ServerName, 
			       tab2.Name AS DatabaseName,
	               CASE	WHEN LastBackupMessage <> 'SUCCESSFUL' THEN 'Failed Backup'
			            WHEN RestoreStatus <> 'VALID' THEN 'Invalid For Restore'
			            WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + ' Days Since Last Backup'
	               END AS ReportedIssue,
	               FileName,
	               FilePosition, 
	               CASE WHEN LastBackupType LIKE '%Differential%' THEN 'Differential'
					    WHEN LastBackupType LIKE '%Full%' THEN 'Full'
			       END AS LastBackupType,
	               LastBackupStartDate
            FROM DatabaseBackupInfo tab1
		    RIGHT JOIN (SELECT * FROM OPENQUERY( [$ServerName], 'SELECT * FROM master.sys.databases')) tab2
		    ON tab1.ServerName = '$ServerName' 
		    AND tab1.DatabaseName = tab2.name COLLATE DATABASE_DEFAULT 
		    WHERE tab2.name LIKE '%IRAS%' AND tab2.state_desc = 'ONLINE'
			AND (LastBackupMessage <> 'SUCCESSFUL' OR RestoreStatus <> 'VALID' OR DaysSinceLastBackup > 1)"
        }
        else
        {
            $SQL = "SELECT ServerName, 
			       tab2.Name AS DatabaseName,
	               CASE	WHEN LastBackupMessage <> 'SUCCESSFUL' THEN 'Failed Backup'
			            WHEN RestoreStatus <> 'VALID' THEN 'Invalid For Restore'
			            WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + ' Days Since Last Backup'
	               END AS ReportedIssue,
	               FileName,
	               FilePosition, 
	               CASE WHEN LastBackupType LIKE '%Differential%' THEN 'Differential'
					    WHEN LastBackupType LIKE '%Full%' THEN 'Full'
			       END AS LastBackupType,
	               LastBackupStartDate
            FROM DatabaseBackupInfo tab1
		    JOIN sys.databases tab2
		    ON tab1.ServerName = '$ServerName' 
		    AND tab1.DatabaseName = tab2.name 
		    WHERE tab2.name LIKE '%IRAS%' AND tab2.state_desc = 'ONLINE'
			AND (LastBackupMessage <> 'SUCCESSFUL' OR RestoreStatus <> 'VALID' OR DaysSinceLastBackup > 1)"
        }
    
        $Message = "`r`n*************************************************** $ServerName ***************************************************`r`n"
        $Message += "`r`nThe following database backups from the $ServerName server either failed to complete, "
        $Message += "`r`n(and or) is invalid for restores, (and or) is more than a day old."
        $Message += "`r`n`r`nBackup Directory: \\dras-dbbkp02\P_DB_Backups_Nightly\$($ServerName.Replace("\", "_"))\Nightly"
        $FlaggedBackups = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL | Where-Object {$_.ServerName -eq $ServerName}
   
        if ($FlaggedBackups -ne $null)
        {
            $Message | Out-File -FilePath $ReportFile -Append 

            $FlaggedBackups | Where-Object {$_.ServerName -eq $ServerName} | Select-Object -Property  DatabaseName, ReportedIssue,`
                    LastBackupType, LastBackupStartDate  `
            | Format-Table -AutoSize | Out-File -FilePath $ReportFile -Append             
        }  

    }#end of foreach loop
}

# Check if the DatabaseBackupInfo has any data. If no data is found the backup folders may be empty
$SQL = "SELECT * FROM DatabaseBackupInfo"

$NoBackupFilesFound = Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL

# Set the email subject line
$EmailSubjectLine = "SQL Server Nightly Backup Restore Testing"

# Get a list of the servers that backup testing was performed on
$StringList = "'" + [system.String]::Join("', '", $SQLServerDBs.ServerName) + "'"

$SQL = "SELECT DISTINCT Servername 
        FROM DatabaseBackupInfo
        WHERE ServerName IN ($StringList) 
        ORDER BY 1"


$ServerList = "" + (Invoke-Sqlcmd -ServerInstance $MasterServer -Database "DrasInternal" -Query $SQL).ServerName
$ServerList = $ServerList.Replace(" ", "`r`n")

# Get server domain for the server where the script is being run
$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain

# Create the email message body if the report file contains invalid or old backups 
if ($NoBackupFilesFound -eq $null)
{
    $emailBody = "Please check that backups were performed for all SQL Server Instances."

    $emailPriority = 2
}
elseif ([String]::IsNullOrWhiteSpace([IO.File]::ReadAllText($ReportFile)))
{

    if ($DomainName -ieq 'EDDYFINDT.COM')
    {
        $ServerType = "non-production"
    }
    elseif ($DomainName -ieq 'DRAS.LOCAL')
    {
        $ServerType = "production"
    }



    $emailBody = "All IRAS database backups from the SQL Server $ServerType servers are up to date and valid for restore. "
    $emailBody += "Restore testing was performed on the following servers.`r`n`r`n$ServerList"

    $emailPriority = 0    
}
else
{
    $emailBody = "Some SQL Server databases either failed to complete a backup, have invalid backups for restores, or have backups that are more than a day old. "
    $emailBody += "The email file attachment contains a list of all servers with failed or outdated database backups. All other servers listed below have successully performed backups that are up to date and valid for restore.`r`n`r`n$ServerList"

    $emailPriority = 2
}

$emailBody += "`r`n`r`n***NOTE*** The backup restore test did not execute a full database restore but instead performed a VERIFYONLY check and a check for any breaks within the differental backup LSN chain. "
$emailBody += "A more detailed report of database backups is available in the 'DrasInternal.dbo.DatabaseBackupInfo' table on the $MasterServer server."

if ([String]::IsNullOrWhiteSpace([IO.File]::ReadAllText($ReportFile)))
{
     #Construct and send the email message
    Send-MailMessage `
    -To $EmailRecipientList `
    -From "HP9000@dynamicrisk.net" `
    -Subject $EmailSubjectLine `
    -priority $emailPriority `
    -SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
    -Body $emailBody
}
else
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