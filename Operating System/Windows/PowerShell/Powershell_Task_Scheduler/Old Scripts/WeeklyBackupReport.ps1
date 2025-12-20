# This script generates a backup report on nightly backups for all database servers specified

# This function generates the backup report for a single database server
function Get-ServerBackupReport {
	param  ($DBtype, $ServerName, $ReportType, $Username, $Password)

	$CurrentDate = Get-Date 
    $DBFolder = $ServerName.Replace('\', '_')

	if ($ReportType -ieq 'N')
	{
         $CutOffDate = $CurrentDate.AddDays(-0.75)
		$DaysSinceLastBackup = 0.75 # 18hours
		$TypeDesc = 'Nightly'
        $BackupDir = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$DBFolder\Nightly\"
	}
	elseif ($ReportType -ieq 'W')
	{
		# Get date for the previous Friday when the last weekly backup was taken

		if($CurrentDate.DayOfWeek.value__ -lt 5)
		{
			$LastFriday = $CurrentDate.AddDays(-($CurrentDate.DayOfWeek.value__ % 5 + 2) )
		}
		else{
			$LastFriday = $CurrentDate.AddDays(-($CurrentDate.DayOfWeek.value__ % 5))
		}

        $CutOffDate = $LastFriday           
		$DaysSinceLastBackup = (New-TimeSpan -Start $LastFriday -End (get-date)).Days

		$TypeDesc = 'Weekly'
        $BackupDir = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$DBFolder\Weekly\"
	}
	elseif ($ReportType -ieq 'M')
	{
		#Get the date of the last Friday of the previous month (Date of previous monthly backup)

		$DayOfWeek = 5
		$LastDayOfPreviousMonth = $CurrentDate.AddDays(-$CurrentDate.Day)
		if ([int]$LastDayOfPreviousMonth.DayOfWeek -ge $DayOfWeek) {
			$LastFriday = $LastDayOfPreviousMonth.AddDays(-$LastDayOfPreviousMonth.DayOfWeek + $DayofWeek)
		}
		else {
			$SubtractDays = [int]$LastDayOfPreviousMonth.DayOfWeek + (7 - [int]$DayofWeek)
			$LastFriday = $LastDayOfPreviousMonth.AddDays(-$SubtractDays)
		}

        $CutOffDate = $LastFriday
		$DaysSinceLastBackup = (New-TimeSpan -Start $LastFriday -End (get-date)).Days

		$TypeDesc = 'Monthly'
        $BackupDir = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\$DBFolder\Monthly\"
	}

	# Creates a new directory for the report output files if it does not already exist

	$ReportDir = "C:\Users\Ufuoma_Ikporo\Documents\Backup_Reports\" + $TypeDesc + "_Backup_Report"

	if ((Test-Path -Path $ReportDir) -eq $false){
		New-Item $ReportDir -ItemType directory
	}

	$OutFile =  "$ReportDir\" + $ServerName.Replace('\', '_') + "_$TypeDesc" + "_Backup_Report.txt"

    ###########################################################################################################
	###########################################################################################################
	#FOR SQL SERVER
	############################################################################################################
    ############################################################################################################

	# This if-block is only executed if it is specified that the database is a SQL Server database

	if ($DBType -eq 'M' -or $DBType -eq 'm') 
	{ #start of SQL Server if-block

	####################################################################################################
	#Variables for storing SQL queries
	##################################################################################################

		# Query to find backup info from the database backup history  

		$DBBackupQuery = "SELECT msdb.dbo.backupset.database_name, 
						msdb.dbo.backupset.backup_finish_date,
						REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 5,
									CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 5 
										)
								) AS physical_file_name
					FROM 
						msdb.dbo.backupmediafamily 
						INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
						INNER JOIN (
							SELECT  msdb.dbo.backupset.database_name,
								MAX(msdb.dbo.backupset.backup_finish_date) AS last_backup_date
							FROM 
								msdb.dbo.backupmediafamily 
								INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
							WHERE 
								(CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - {0})
							GROUP BY database_name) dbs
						ON dbs.database_name = msdb.dbo.backupset.database_name 
						AND dbs.last_backup_date = msdb.dbo.backupset.backup_finish_date
					ORDER BY 1"

		# Query to check if a disk backup file is associated with a database on the server

		$FileCheck = "SELECT DISTINCT(msdb.dbo.backupset.database_name),
							REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 5,
							CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 5)
									) AS file_name 
				FROM 
					msdb.dbo.backupmediafamily 
					INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
				WHERE REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 5,
								CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 5 
									)
							) IN ({0})
					AND 
						(CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - {1})"

		# Query to find which databases are not being backed-up

		$GetDBList = "SELECT name FROM sys.databases
					WHERE database_id > 4
                    AND state_desc ='ONLINE'
					ORDER BY 1"

	###########################################################################################
	# Excutes SQL Queries 
	###########################################################################################

		#Get list of all databases currentlu existing on the server

		$DBList = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $GetDBList

		#Get list of Database backup files from the backup history tables in msdb database

		$SQL = $DBBackupQuery -f $DaysSinceLastBackup

		$DBBackupList = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL 

		if ($null -eq $DBBackupList)
		{
			$SQL = $DBBackupQuery -f ($DaysSinceLastBackup + 2)

			$DBBackupList = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL 
		}
		# Get list of disk backup files that are within the date range (nightly, weekly, monthly) for the backup report 

		$DiskBackupList = (Get-ChildItem -Path "$BackupDir*.bak" -Recurse) | Where-Object {
				$_.LastWriteTime -ge $CutOffDate #(Get-Date).AddDays(-$DaysSinceLastBackup)
		} 

        if ($ReportType -ieq 'W' -or $ReportType -ieq 'M')
        {
            $DiskBackupList = (Get-ChildItem -Path "$BackupDir*.rar" -Recurse) | Where-Object {
				$_.LastWriteTime -ge $CutOffDate #(Get-Date).AddDays(-$DaysSinceLastBackup)
		    } 
        }

    
		# Gets list of databases that do not have a history of backups

		$ExcludedDBsList = $DBList.name | Where-Object {$DBBackupList.database_name -notcontains $_} | Sort-Object
			
		# Creates a list of missing files (database backup files that are not on disk)

        $MissingFiles = $null
        $MissingDBs = $null

		if ($null -eq $DiskBackupList){
			$MissingFiles = $DBBackupList.physical_file_name | Sort-Object
		}
		else{
			
			$MissingFiles = $DBBackupList.physical_file_name | Where-Object {$DiskBackupList.BaseName -notcontains $_}
			$MissingFiles = $MissingFiles | Where-Object {$DBList -contains $_} | Sort-Object

			# Converts $MissingFiles array into a string variable that is a comma-seperated list as follows ('item1', 'item2'...)
			if ($null -ne $MissingFiles) {

				$StringList = "'" + [system.String]::Join("', '", $MissingFiles) + "'"

			# Get the database names associated with the files on the $MissingFiles list

				$MissingDBs = $DBBackupList | Select-Object -Expand database_name -Unique | Sort-Object
			} #end of inner if-statement
        } #end of else-statement

	# Files older than the specified date for the backup report are possible candidates for the orphaned files list

		$OldFiles = Get-ChildItem -Path "$BackupDir*.bak" -Recurse | Where-Object {
		    $_.LastWriteTime -lt $CutOffDate #(Get-date).AddDays(-$DaysSinceLastBackup)
		} 

	# Creates list of orphaned backup files

		$OrphanFiles = $null

		if ($null -eq $OldFiles) 
		{
			$OrphanFiles = $null
		} # End of if statement
		else {

			# Get list of orphaned backup files that are not associated with any databases on the server
            
            $OrphanFiles = $OldFiles.BaseName | Where-Object {$DBList.name -notcontains $_} | Sort-Object
                        
		 } # End of 'else' statment

	} # end of SQL Server if-block

	#########################################################################################################################
	#########################################################################################################################
	#FOR ORACLE DATABASE
	#########################################################################################################################
	#########################################################################################################################

	# The code within this if-block is executed only if it is specified that the database is an oracle database

	if ($DBType -eq 'O' -or $DBType -eq 'o') 
	{

	# Get database login username and password to connect to database
 
		#Write-Host ""
		#$Username = Read-Host -Prompt "Enter the username for an Oracle database user"
		#$SecurePassword = Read-Host -Prompt "Enter the password for the database user" -AsSecureString
		#Write-Host ""

		# Converts Secure-Password back to plain text
		#$PlainTextPassword = [System.Net.NetworkCredential]::new("", $SecurePassword).Password

	###############################################################################
	# Queries
	###############################################################################

	#List of all schemas that exist on the database server

		$GetSchemaList = "SET HEADING OFF
						SET FEEDBACK OFF
						SET UNDERLINE OFF
						SET PAGESIZE 1000
						SELECT username FROM all_users
						ORDER BY 1;
						exit"
	# This query specifies the list of databases that are supposed to be backed-up

		$GetBkpSchemaList = "SET HEADING OFF
					SET FEEDBACK OFF
					SET UNDERLINE OFF
					SELECT username FROM all_users
					WHERE username LIKE '%OWNR%' OR
							username LIKE '%SDE%';
					exit"

	# This query checks if a file is within the list genereated from the $GetBkpSchemaList query above

		$FileCheck = "SET HEADING OFF
				SET FEEDBACK OFF
				SET UNDERLINE OFF
				SELECT username 
			FROM (
			SELECT username FROM all_users
			WHERE username LIKE '%OWNR%' OR
				username LIKE '%SDE%'
				)
			WHERE username IN ({0});"

	######################################################################################
	#Execute Queries and compare disk schema backup files to database schemas
	#######################################################################################

	
		# Execute query to get list f all schemas on the database server 

		$DBSchemaList = $GetSchemaList | sqlplus -silent $Username/$Password@$ServerName | Select-Object -Skip 1

		# Execute query to get a list of database schemas that are supposed to be backed-up

		$DBBackupList = $GetBkpSchemaList | sqlplus -silent $Username/$Password@$ServerName | Select-Object -Skip 1

		# Get list of disk backup files that are within the date range (nightly, weekly, monthly) for the backup report 

		$DiskBackupList = (Get-ChildItem -Path "$BackupDir*.dmp" -Recurse) | Where-Object {
				$_.LastWriteTime -ge $CutOffDate #(Get-date).AddDays(-$DaysSinceLastBackup)
		} 

        if($ReportType -ieq 'w' -or $ReportType -ieq 'm')
        {
            $DiskBackupList = (Get-ChildItem -Path "$BackupDir*.rar" -Recurse) | Where-Object {
				$_.LastWriteTime -ge $CutOffDate #(Get-date).AddDays(-$DaysSinceLastBackup)
		    } 
        }

	    # Creates a list of missing files

		$MissingFiles = $null
		$MissingDBs = $null

		if ($null -eq $DiskBackupList){
			$MissingFiles = $DBBackupList | Sort-Object
		}
		else{

			$MissingFiles = $DBBackupList | Where-Object {$DiskBackupList.BaseName -notcontains $_} | Sort-Object
		}

	# Files older than the specified date for the backup report are possible candidates for the orphaned files list

		$OldFiles = (Get-ChildItem -Path "$BackupDir*.dmp" -Recurse) | Where-Object {
				$_.LastWriteTime -lt $CutOffDate #(Get-date).AddDays(-$DaysSinceLastBackup)
		} 

	# Creates list of orphaned backup files

		$OrphanFiles = $null

		if ($null -eq $OldFiles) {
			$OrphanFiles = $null
		} # End of if statement
		else {

			# Get list of orphaned backup files that are not associated with any databases on the server

            $OrphanFiles = $OldFiles.BaseName | Where-Object {$DBSchemaList -notcontains $_} | Sort-Object
		} # End of else-block

		#List of databases that were not included in the last weekly backup

		$ExcludedDBsList = $DBSchemaList | Where-Object {$DBBackupList -notcontains $_} | Sort-Object

	} # End of Oracle database if-block

	############################################################################################################
	# Output
	#############################################################################################################

	# Deletes the output file if it already exists

	if ((Test-Path -Path $OutFile) -eq $true){
		Remove-Item -Path $OutFile
	}

	# Resets emailpriority variable

	$EmailPriority = $null
    

	# This if block is executed only if there are missing files
	Write-Output "`r`n******** $($TypeDesc.TOUPPER()) BACKUP REPORT FOR $ServerName SERVER********" | Out-File $OutFile
	if ([string]::IsNullOrWhiteSpace($MissingFiles) -eq $false){
		Write-Output "`r`n######################################################################################" | Add-Content $OutFile
		Write-Output "MISSING FILES: The following database BACKUP FILES are either OUTDATED or NOT ON DISK" |  Add-Content $OutFile
		Write-Output "######################################################################################`r`n" | Add-Content $OutFile
		Write-Output $MissingFiles | Add-Content $OutFile
		if ($DBType -eq 'M' -or $DBType -eq 'm'){
			Write-Output "`r`n######################################################################################" | Add-Content $OutFile
			Write-Output "MISSING FILES DB: The following DATABASES have backup files that are either OUTDATED" | Add-Content $OutFile
			Write-Output "or MISSING" | Add-Content $OutFile
			Write-Output "######################################################################################`r`n" | Add-Content $OutFile
			Write-Output $MissingDBs | Add-Content $OutFile
		}

		$EmailPriority = 2

	}

	# This if-block executes only if there are orphaned files

	If ([string]::IsNullOrWhiteSpace($OrphanFiles) -eq $false){
		Write-Output "`r`n######################################################################################" | Add-Content $OutFile
		Write-Output "ORPHANED FILES: The following on-disk backup files are old and may have been ORPHANED " |  Add-Content $OutFile
		Write-Output "on the $ServerName server." |  Add-Content $OutFile
		Write-Output "######################################################################################`r`n" | Add-Content $OutFile
		Write-Output $OrphanFiles | Add-Content $OutFile

		if ($null -eq $EmailPriority)
		{
			$EmailPriority = 1
		}	
	}

	# This if-block executes only if there are no missing or orphaned files

	if ([string]::IsNullOrWhiteSpace($MissingFiles) -eq $true -and [string]::IsNullOrWhiteSpace($OrphanFiles) -eq $true )
	{
		Write-Output "`r`n######################################################################################" | Add-Content $OutFile
		Write-Output "All backup files from the scheduled $TypeDesc database backups are on disk." | Add-Content $OutFile
		Write-Output "There are no orphaned backup files." | Add-Content $OutFile
		Write-Output "######################################################################################" | Add-Content $OutFile
		
		if ($null -eq $EmailPriority)
		{
			$EmailPriority = 0
		}	
	}

	# This if-block executes only if there a databases on the server that do not have a history of being backed-up

	if ([string]::IsNullOrWhiteSpace($ExcludedDBsList) -eq $false)
	{
		Write-Output "`r`n######################################################################################" | Add-Content $OutFile
		Write-Output "NO-BACKUP DBs: The following DATABASES currently exist on the server and were not " | Add-Content $OutFile
		Write-Output "included in the last $TypeDesc backup" | Add-Content $OutFile
		Write-Output "######################################################################################`r`n" | Add-Content $OutFile
		Write-Output $ExcludedDBsList| Add-Content $OutFile
	} # End of 'if' block
	
	Write-Host "`r`nThe $TypeDesc report for $ServerName server is completed!"

	return $ReportDir, $EmailPriority, $TypeDesc

} # End of Get-ServerBackupReport function-block

#$test = Get-ServerBackupReport -DBtype 'O' -ServerName 'ORA19C' -ReportType 'n' -Username 'DRAS_IRASV6_DEV_DE_DEMO' -Password 'dras'

#write-host "$([system.String]::Join("`r`n", $test))"

# #Import Mailkit module to allow the use of the Send-MailkitMessage cmdlet
# Import-Module Send-MailKitMessage


# arrays containing th list of all SQL Server and Oracle databases that a report will be generated for
$SQLServerDBs=$null
$OracleDBs=$null
$SQLServerDBs = 'SQL2012EXT', 'SQL2014', 'SQL2016', 'SQL2017', 'SQL2019', 'SQLDEVPREPROD', 'SQL2016\latin1_general'
$OracleDBs = @(('ORA12C','ORA19C','ORA19C22'), ('DBBACKUPUSER', 'DRAS_IRASV6_DEV_DE_DEMO', 'ETP_IRASV6_STAGE_OWNR'), ('DBBACKUPUSER','dras','etp'))

#Function to send email
function Send-Email {
    param (
        $Message,
        $EmailPrioriry,
        $BackupType
    )

	#Set some of the email parameters
	$EmailSender = 'Ufuoma.Ikporo@gmail.com'
	$SenderPassword = ConvertTo-SecureString -AsPlainText "assdzkrdcyqvpmty" -Force
	$Credential = [System.Management.Automation.PSCredential]::new( $EmailSender, $SenderPassword )
	$RecipientList = 'ufuoma_ikporo@dynamicrisk.net' #, 'Daniel_Cheung@dynamicrisk.net', 'Jagdish_Chaudhary@dynamicrisk.net'

	$AttachmentList = [System.Collections.Generic.List[string]]::new()

	#Create a list of all database servers that a report is being generated for
	$DBServerList = @()
	if ($null -ne $SQLServerDBs) {
		foreach($Server in $SQLServerDBs)
		{
			$DBServerList += $Server.Replace('\', '_')
		}
	}

	if($null -ne $OracleDBs)
	{
		foreach($Server in $OracleDBs[0])
		{

			$DBServerList += $Server

		}
	}

	#Get a list of all files in the report directory
	$DirectoryFiles = Get-ChildItem -Path $ReportDir

	#Add the files associated with the database servers in $DBServerList to the email file attachment list
	ForEach ($Server in $DBServerList)
	{
        $AttachmentFiles = $DirectoryFiles | Where-Object {$_.Name -Like "$($Server)_$BackupType*"} 
			
		$AttachmentList.Add($AttachmentFiles.FullName)

	} 

   $SMTPParams = @{
   SmtpServer = 'smtp.gmail.com'
   Port       = 587
   Credential = $Credential
   UseSsl     = $true
   From       = $EmailSender
   To         = $RecipientList
   Subject    = "$BackupType Backup Report"
   Body       = $Message
   priority   = $EmailPrioriry
   Attachments = $AttachmentList
   }

    Send-MailMessage @SMTPParams
}

# This function calls the Get-ServerBackupReport to generate a backup report for all the Oracle and SQL Server 
# databases in the $SQLServerDBs and $OracleDBs arrays. It then calls the Send-Email function to send an email
function Get-BackupReport {

    param ($Type)

	# Loop that generates the backup reports for Oracle databases

	if ($null -ne $OracleDBs) {
		For ($i = 0; $i -lt $OracleDBs[0].Count; $i++) {

			$DB = $OracleDBs[0][$i]
			$ReportDir, $emailpriority, $TypeDesc = Get-ServerBackupReport -DBtype 'O' -ServerName $OracleDBs[0][$i] -Username $OracleDBs[1][$i] `
			-Password $OracleDBs[2][$i] -ReportType $Type #-FileLocation "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$DB\Nightly" 
			
			if ($emailpriority -eq 2)
			{
				$HighPriorityList += @($DB)
			}
			elseif ($emailpriority -eq 1)
			{
				$ModeratePriorityList += @($DB) 
			}
			elseif ($emailpriority -eq 0) {
				$LowPriorityList += @($DB)
			}
		}
	}
    
	# Loop that generates the backup reports for SQL server databases
	if ($null -ne $SQLServerDBs) {
		ForEach ($DB in $SQLServerDBs) 
		{
			$DBFolder = $DB.Replace('\', '_')
			$ReportDir, $emailpriority, $TypeDesc = Get-ServerBackupReport -DBtype 'M' -ServerName $DB -ReportType $Type `
			#-FileLocation "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$DBFolder\Nightly" 
	
			if ($emailpriority -eq 2)
			{
				$HighPriorityList += @($DB)
			}
			elseif ($emailpriority -eq 1)
			{
				$ModeratePriorityList += @($DB) 
			}
			elseif ($emailpriority -eq 0) {
				$LowPriorityList += @($DB)
			}
		} #End of ForEach Loop
	}

	# outputs location of output files to screen

	Write-Host ""
	Write-Host "The output file generated for each report can be found at $ReportDir" 
	Write-Host ""
	
	# Constructs email message
	$Message = $null
	if ($null -ne $HighPriorityList)
	{
		$Message = "The following database servers have one or more backup files that are outdated or missing.`r`n`r`n" `
		            + [system.String]::Join("`r`n", ($HighPriorityList | Sort-Object)) + "`r`n"
	}

	if ($null -ne $ModeratePriorityList)
	{
		$Message += "`r`nThe following database servers completed their $($TypeDesc.ToLower()) backups but have one or more orphaned files.`r`n`r`n" `
					+ [system.String]::Join("`r`n", ($ModeratePriorityList | Sort-Object)) + "`r`n"
	}

	if ($null -ne $LowPriorityList)
	{
		$Message += "`r`nThe following database servers completed their $($TypeDesc.ToLower()) backups and do not have any orphaned file.`r`n`r`n" `
		+ [system.String]::Join("`r`n", ($LowPriorityList | Sort-Object))
	}

	$Message += "`r`n `r`nSee the attached files for more details"

	# Sends email with the approriate priority notificatation

	if ($null -ne $HighPriorityList) 
	{
		Send-Email -Message $Message -EmailPrioriry 2 -BackupType $TypeDesc 
	}
	elseif ($null -ne $ModeratePriorityList -and $null -eq $HighPriorityList)
	{
		Send-Email -Message $Message -EmailPrioriry 1 -BackupType $TypeDesc
	}
	elseif ($null -eq $HighPriorityList -and $null -eq $ModeratePriorityList) {
		Send-Email -Message $Message -EmailPrioriry 0 -BackupType $TypeDesc
	}
 
} #End of Get-BackupReport function

Get-BackupReport -Type 'W'
#>