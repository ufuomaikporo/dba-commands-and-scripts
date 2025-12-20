# This script generates a backup report on nightly backups for all database servers specified

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

$StartTime = Get-Date
Write-Host "Script Execution Start time: $StartTime"

# This function generates the backup report for a single database server
function Get-ServerBackupReport {
	param  ($DBtype, $ServerName, $ReportType, $Username, $Password, $TNSAlias)

	$CurrentDate = Get-Date 
    $DBFolder = $ServerName.Replace('\', '_')

    # Set variables that are specfic to each report type
	if ($ReportType -ieq 'N')
	{
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

    Write-Host "Generating the $TypeDesc backup report for the $ServerName server!"

	###########################################################################################################
	#FOR SQL SERVER
	############################################################################################################

	# This if-block is only executed if it is specified that the database is a SQL Server database

	if ($DBType -eq 'M' -or $DBType -eq 'm') 
	{ #start of SQL Server if-block

	#------------------------------------ Variables for storing SQL queries ------------------------------------

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

		# # Query to check if a disk backup file is associated with a database on the server

		# $FileCheck = "SELECT DISTINCT(msdb.dbo.backupset.database_name),
		# 					REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 5,
		# 					CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 5)
		# 							) AS file_name 
		# 		FROM 
		# 			msdb.dbo.backupmediafamily 
		# 			INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
		# 		WHERE REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 5,
		# 						CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 5 
		# 							)
		# 					) IN ({0})
		# 			AND 
		# 				(CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - {1})"

		# Query to find which databases are not being backed-up

		$GetDBList = "SELECT name FROM sys.databases
					WHERE database_id > 4
                    AND state_desc ='ONLINE'
					ORDER BY 1"

        # Server that will be used for executing all backup testing
        if ($ServerName -like '*2022*')
        {
            $ExecutionServer = 'DRASSQL2022'
        }
        else
        {
            $ExecutionServer = 'SQL2019'
        }

        # Database that holds the stored procedure for executing the backup restore test
        $ExecutionDB = 'DrasInternal'

        # Command to execute the already exsiting stored procedure 'dbo.sp_BackupRestoreTest' for testing restore of SQL Server backups
        $RunStoredProc = "EXECUTE dbo.sp_BackupRestoreTest @BULocation = '{0}'"

	#------------------------------------- Excutes SQL Queries ------------------------------------- 

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
				$_.LastWriteTime -ge (Get-Date).AddDays(-$DaysSinceLastBackup)
		} 

        if ($ReportType -ieq 'W' -or $ReportType -ieq 'M')
        {
            $DiskBackupList = (Get-ChildItem -Path "$BackupDir*.rar" -Recurse) | Where-Object {
				$_.LastWriteTime -ge (Get-Date).AddDays(-$DaysSinceLastBackup)
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
			if ($null -ne $MissingFiles) 
            {
			    # Get the database names associated with the files on the $MissingFiles list
				$MissingDBs = $DBBackupList | Select-Object -Expand database_name -Unique | Sort-Object
			} #end of inner if-statement
        } #end of else-statement

	# Files older than the specified date for the backup report are possible candidates for the orphaned files list

		$OldFiles = Get-ChildItem -Path "$BackupDir*.bak" -Recurse | Where-Object {
		    $_.LastWriteTime -lt (Get-date).AddDays(-$DaysSinceLastBackup)
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


    #------------------------------------ CHECK THAT BACKUP FILES ARE VALID FOR RESTORE --------------------------------------------

        # Tests restore on all backupfiles in the current backup location using stored procedure. All backup testing is executed on the same server
        if ($ReportType -ieq 'N')
        {
            $SQL = $RunStoredProc -f $BackupDir
            $InvalidFiles = $null
            $InvalidFiles = Invoke-Sqlcmd -ServerInstance $ExecutionServer -Database $ExecutionDB -Query $SQL -QueryTimeout 10800
        }

	} # end of SQL Server if-block

	#########################################################################################################################
	#FOR ORACLE DATABASE
	#########################################################################################################################

	# The code within this if-block is executed only if it is specified that the database is an oracle database

	if ($DBType -eq 'O' -or $DBType -eq 'o') 
	{

	#-------------------------------- Store Queries in Variables  ---------------------------------------
	

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
	
	#----------- Execute Queries and compare disk schema backup files to database schemas ----------------
	

	
		# Execute query to get list f all schemas on the database server 

		$DBSchemaList = $GetSchemaList | sqlplus -silent $Username/$Password@$TNSAlias | Select-Object -Skip 1

		# Execute query to get a list of database schemas that are supposed to be backed-up

		$DBBackupList = $GetBkpSchemaList | sqlplus -silent $Username/$Password@$TNSAlias | Select-Object -Skip 1

		# Get list of disk backup files that are within the date range (nightly, weekly, monthly) for the backup report 

		$DiskBackupList = (Get-ChildItem -Path "$BackupDir*.dmp" -Recurse) | Where-Object {
				$_.LastWriteTime -ge (Get-date).AddDays(-$DaysSinceLastBackup)
		} 

        if($ReportType -ieq 'w' -or $ReportType -ieq 'm')
        {
            $DiskBackupList = (Get-ChildItem -Path "$BackupDir*.rar" -Recurse) | Where-Object {
				$_.LastWriteTime -ge (Get-date).AddDays(-$DaysSinceLastBackup)
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
				$_.LastWriteTime -lt (Get-date).AddDays(-$DaysSinceLastBackup)
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


      #------------------------------------- CHECK IF THE ORACLE DATAPUMP EXPORT LOGFILE HAS ERRORS -------------------------------------------- 
    
        if ($ReportType -ieq 'N')
        {
            foreach ($Schema in $DBBackupList)
            {                
                $ExpDPLogfile = Get-ChildItem -Path "$BackupDir*.log" | Where-Object {$_.Name -like "*$Schema*"}
             
                if ($null -ne $ExpDPLogfile)
                {
                    if (!(Select-String -Path $ExpDPLogfile.FullName -Pattern "successfully completed"))
                    {
                        if($Schema -notin $MissingFiles)
                        {
                            $MissingFiles += $Schema
                        }
                    }
                }
        
            }
        }

	} # End of Oracle database if-block

#write-output $MissingFiles
    
	############################################################################################################
	# Output
	#############################################################################################################

	# Deletes the output file if it already exists

	if ((Test-Path -Path $OutFile) -eq $true){
		Remove-Item -Path $OutFile
	}

	# This if block is executed only if there are missing files
	Write-Output "`r`n******** $($TypeDesc.TOUPPER()) BACKUP REPORT FOR $ServerName SERVER********" | Out-File $OutFile
	if ([string]::IsNullOrWhiteSpace($MissingFiles) -eq $false){
		Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
		Write-Output "MISSING FILES: The following databases have backup files that are either OUTDATED, NOT ON DISK," |  Add-Content $OutFile
        Write-Output "or COMPLETED WITH ERROR" |  Add-Content $OutFile		
        Write-Output "###################################################################################################`r`n" | Add-Content $OutFile
		Write-Output $MissingFiles | Add-Content $OutFile
		if ($DBType -eq 'M' -or $DBType -eq 'm'){
			Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
			Write-Output "MISSING FILES DB: The following DATABASES have backup files that are either OUTDATED" | Add-Content $OutFile
			Write-Output "or MISSING" | Add-Content $OutFile
			Write-Output "###################################################################################################`r`n" | Add-Content $OutFile
			Write-Output $MissingDBs | Add-Content $OutFile
		}

		$HasMissingFiles = 1
	}

    # This if-block executes only if there are backup files with invalid backups

    If($null -ne $InvalidFiles)
    {
        Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
		Write-Output "FILES WITH INVALID BACKUPS: The following on-disk $ServerName backup files may contain  " |  Add-Content $OutFile
		Write-Output "backups that are not valid for a restore." |  Add-Content $OutFile
        Write-Output "`r`nBACKUPFILE LOCATION: $BackupDir" |  Add-Content $OutFile
		Write-Output "###################################################################################################`r`n" | Add-Content $OutFile
		$InvalidFiles | Sort-Object -Property DbName | Format-Table -AutoSize | Out-File -Append $OutFile

        $HasInvalidFiles = 1
    }

	# This if-block executes only if there are orphaned files

	If ([string]::IsNullOrWhiteSpace($OrphanFiles) -eq $false){
		Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
		Write-Output "ORPHANED FILES: The following on-disk backup files are old and may have been ORPHANED " |  Add-Content $OutFile
		Write-Output "on the $ServerName server." |  Add-Content $OutFile
		Write-Output "###################################################################################################`r`n" | Add-Content $OutFile
		Write-Output $OrphanFiles | Add-Content $OutFile

        $HasOrphanFiles = 1
	}

	# This if-block executes only if there are no missing or orphaned files

	if ([string]::IsNullOrWhiteSpace($MissingFiles) -eq $true -and [string]::IsNullOrWhiteSpace($OrphanFiles) -eq $true )
	{
		Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
		Write-Output "All backup files from the scheduled $TypeDesc database backups are on disk." | Add-Content $OutFile
		Write-Output "There are no orphaned backup files." | Add-Content $OutFile
		Write-Output "###################################################################################################" | Add-Content $OutFile
    }

	# This if-block executes only if there are databases on the server that do not have a history of being backed-up

	if ([string]::IsNullOrWhiteSpace($ExcludedDBsList) -eq $false)
	{
		Write-Output "`r`n###################################################################################################" | Add-Content $OutFile
		Write-Output "NO-BACKUP DBs: The following DATABASES currently exist on the server and were not " | Add-Content $OutFile
		Write-Output "included in the last $TypeDesc backup" | Add-Content $OutFile
		Write-Output "###################################################################################################`r`n" | Add-Content $OutFile
		Write-Output $ExcludedDBsList| Add-Content $OutFile
	} # End of 'if' block
	
	return $ReportDir, $TypeDesc, $HasMissingFiles, $HasInvalidFiles, $HasOrphanFiles

} # End of Get-ServerBackupReport function-block

# arrays containing th list of all SQL Server and Oracle databases that a report will be generated for
$SQLServerDBs=$null
$OracleDBs=$null
#$SQLServerDBs = 'SQL2012EXT', 'SQL2014EXT', 'SQL2016', 'SQL2016\latin1_general', 'SQL2017', 'SQL2019', 'SQLDEVPREPROD', 'IRAS-PREP-SQL01', 'DRASSQL2022'
$SQLServerDBs = 'DRASSQL2022'
#$OracleDBs = @(('ORA12CEXT','ORA19C','ORA19C22'), ('DBBACKUPUSER', 'DBBACKUPUSER', 'DBBACKUPUSER'), ('DBBACKUPUSER','DBBACKUPUSER','DBBACKUPUSER'))

#$OracleDBs = $arr = @([PSCustomObject]@{ServerName = 'DRASORA12CEXT'; TNSAlias = 'DRASORA12CEXT'; UserName= 'DBBACKUPUSER'; Pass = 'DBBACKUPUSER'}
#    [PSCustomObject]@{ServerName = 'ORA19C'; TNSAlias = 'ORA19C'; UserName= 'DBBACKUPUSER'; Pass = 'DBBACKUPUSER'}
#    [PSCustomObject]@{ServerName = 'ORA19C22'; TNSAlias = 'ORA19C22'; UserName= 'DBBACKUPUSER'; Pass = 'DBBACKUPUSER'}
#)

#Function to send email
function Send-Email {
    param (
        $Message,
        $EmailPriority,
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
		foreach($Server in $OracleDBs.ServerName)
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
   priority   = $EmailPriority
   Attachments = $AttachmentList
   }

    Send-MailMessage @SMTPParams
}

# This function calls the Get-ServerBackupReport to generate a backup report for all the Oracle and SQL Server 
# databases in the $SQLServerDBs and $OracleDBs arrays. It then calls the Send-Email function to send an email
function Get-BackupReport 
{
    param ($Type)

    Write-Host ""
    $ServerListMissing = $null

    # Loop that generates the backup reports for Oracle databases
	if ($null -ne $OracleDBs) {
		Foreach ($DB in $OracleDBs) 
        { 
			$Server = $DB.ServerName
			$ReportDir, $TypeDesc, $MissingFiles, $InvalidFiles, $OrphanFiles = Get-ServerBackupReport -DBtype 'O' -ServerName $DB.ServerName -Username $DB.UserName `
			-Password $DB.Pass -TNSAlias $DB.TNSAlias -ReportType $Type #-FileLocation "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$DB\Nightly" 
			
			if ($MissingFiles -eq 1)
			{
				$ServerListMissing += @($Server)
			}
            
            if ($InvalidFiles -eq 1)
            {
                $ServerListInvalid += @($Server)
            }
			
            if ($OrphanFiles -eq 1)
			{
				$ServerListOrphaned += @($Server) 
			}
			
            if ($null -eq $MissingFiles -and $null -eq $OrphanFiles -and $null -eq $InvalidFiles)
            {
				$ServerListOther += @($Server)
			}
		}
	}
    
	# Loop that generates the backup reports for SQL server databases
	if ($null -ne $SQLServerDBs) {
		ForEach ($Server in $SQLServerDBs) 
		{
			#$DBFolder = $Server.Replace('\', '_')
            $ReportDir, $TypeDesc, $MissingFiles, $InvalidFiles, $OrphanFiles = Get-ServerBackupReport -DBtype 'M' -ServerName $Server -ReportType $Type `
			#-FileLocation "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\$DBFolder\Nightly" 
	
            if ($MissingFiles -eq 1)
			{
				$ServerListMissing += @($Server)
			}
            
            if ($InvalidFiles -eq 1)
            {
                $ServerListInvalid += @($Server)
            }
			
            if ($OrphanFiles -eq 1)
			{
				$ServerListOrphaned += @($Server) 
			}
			
            if ($null -eq $MissingFiles -and $null -eq $OrphanFiles -and $null -eq $InvalidFiles)
            {
				$ServerListOther += @($Server)
			}
		} #End of ForEach Loop
	}

    
	# print location of output files to screen
    $EndTime = Get-Date
	Write-Host ""
    Write-Host "Script completed at $EndTime"
	Write-Host "The output file generated for each report can be found at $ReportDir" 
	Write-Host ""
    Write-Host "------------------------------------------------------------------------------------------------"
	
    $EmailPriority = $null

	# Constructs email message
	$Message = "BACKUP REPORT SUMMARY`r`n`r`n"
	if ($null -ne $ServerListMissing)
	{
		$Message += "The following servers have one or more backup files that are OUTDATED, MISSING or that completed with ERRORS.`r`n`r`n" `
		            + [system.String]::Join("`r`n", ($ServerListMissing | Sort-Object)) + "`r`n`r`n"
        
        $EmailPriority = 2
	}

	if ($null -ne $ServerListInvalid)
	{
		$Message += "`r`nThe following servers have backup files which contain backups that may be INVALID for a restore.`r`n`r`n" `
		            + [system.String]::Join("`r`n", ($ServerListInvalid | Sort-Object)) + "`r`n`r`n"
                    
        $EmailPriority = 2
    }

	if ($null -ne $ServerListOrphaned)
	{
		$Message += "`r`nThe following servers have one or more possibly ORPHANED files in their $($TypeDesc.ToLower()) backup folder.`r`n`r`n" `
					+ [system.String]::Join("`r`n", ($ServerListOrphaned | Sort-Object)) + "`r`n`r`n"

        if ($null -eq $EmailPriority)
        {
            $EmailPriority = 1
        }
	}


    if ($null -eq $ServerListOrphaned -and $null -eq $ServerListMissing -and $null -eq $ServerListInvalid)
	{
		$Message += "`r`nThere are no missing, orphaned, or invalid $($TypeDesc.ToLower()) backups.`r`n`r`n"
	
        if ($null -eq $EmailPriority)
        {
            $EmailPriority = 0
        }	
    }

    $Message += "`r`n***Note: Backup restore testing was performed on SQL Server nightly backups ONLY.`r`n`r`n" 
	$Message += "`r`n `r`nSee the attached files for more details"

	# Sends email with the approriate priority notificatation
    Send-Email -Message $Message -EmailPriority $EmailPriority -BackupType $TypeDesc 
 
} #End of Get-BackupReport function

Get-BackupReport -Type 'N'
#>