
########################################################################################################
# Functions
########################################################################################################

# This function creates a list of databases that do not have any current active sessions
function Get-NoSessionDBs {

    $SQL = $GetNoSessionsDBs -f $ExemptList
    Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL
}

# Function to get the list of databases that are offline
function Get-OfflineDBs {

   Get-NoSessionDBs | Where-Object {$_.Status -eq 'OFFLINE'}
}

# Function to get the list of databases that do not have a SIMPLE recovery model
function Get-WrongRecoveryModeDBs {

   Get-NoSessionDBs | Where-Object {$_.RecoveryModel -ne 'SIMPLE'}
}

# This function creates a list of databases that are suitable for a index-rebuild operation out of all the databases 
# that are not system databases and are not on the exempt list
function Get-CandidateDBs {
 $OfflineDBs = Get-OfflineDBs
 $WrongRecoveryMode = Get-WrongRecoveryModeDBs
 $NoSessionDBs = Get-NoSessionDBs
  # Remove databases that are offline or that do not have a SIMPLE recovery model from the candidate list
  $NoSessionDBs | Where-Object {$OfflineDBs.DBName -notcontains $_.DBName `
      -and $WrongRecoveryMode.DBName -notcontains $_.DBName `
      -and $Completed.DBName -notcontains $_.DBName}
  
} # End of Get-CandidateDBs function

#Function to send email when given arguments for Message and EmailPriority
function Send-Email 
{
    param 
    (
        $SubjectLine,
        $Message,
        $EmailPriority,
        $Directory
    )

 	$EmailSender = 'Ufuoma.Ikporo@gmail.com'
	$SenderPassword = ConvertTo-SecureString -AsPlainText "assdzkrdcyqvpmty" -Force
	$Credential = New-Object System.Management.Automation.PSCredential ($EmailSender, $SenderPassword )
	$RecipientList = 'ufuoma_ikporo@dynamicrisk.net'#, 'Daniel_Cheung@dynamicrisk.net'

	$AttachmentList = New-Object System.Collections.Generic.List[string]

    if($null -ne $Directory)
    {
        #Get a list of all files in the report directory
        $DirectoryFiles = Get-ChildItem -Path $Directory
    
        #Add the files associated with the database servers in $DBServerList to the email file attachment list
        ForEach ($File in $DirectoryFiles)
        {
            $Server = $File.BaseName.SUBSTRING(0, $IndxOfInstName)
           
            if ($ServerInstanceFile -eq $Server) 
            {
                $AttachmentList.Add($File.FullName)
                $File.FullName
            }
        } 
    }
    
    #$AttachmentList
    if ($null -ne $AttachmentList)
    {
        $SMTPParams = @{
        SmtpServer = 'smtp.gmail.com'
        Port       = 587
        Credential = $Credential
        UseSsl     = $true
        From       = $EmailSender
        To         = $RecipientList
        Subject    = $SubjectLine
        Body       = $Message
        priority   = $EmailPriority
        Attachments = $AttachmentList}
    }
    else 
    {
        $SMTPParams = @{
        SmtpServer = 'smtp.gmail.com'
        Port       = 587
        Credential = $Credential
        UseSsl     = $true
        From       = $EmailSender
        To         = $RecipientList
        Subject    = $SubjectLine
        Body       = $Message
        priority   = $EmailPriority
        }
    }
        
    Send-MailMessage @SMTPParams

} #End of Send-Email function


    $ServerInstance = HOSTNAME.EXE

    $SplitIndex = $ServerInstance.IndexOf('\')

    if($SplitIndex -gt 0)
    {
        $ServerName = $ServerInstance.Substring(0, $SplitIndex)
        $InstNameLength = $ServerInstance.Length - $ServerName.Length - 1
        $InstanceName = $ServerInstance.Substring($SplitIndex + 1,  $InstNameLength)
        $IndxOfInstName = $filename.IndexOf("$InstanceName") + $InstanceName.Length
    }
    else {
        $IndxOfInstName = $ServerInstance.Length 
    }

    $ServerName = HOSTNAME.EXE

    ########################################################################################################
    # Variables to Store Queries 
    ########################################################################################################

    $GetFreeSpaceReport = "SELECT DB_NAME() AS DbName, 
    name AS FileName, 
    type_desc,
    ROUND((size*8.0/1000.0), 2) AS CurrentSizeMB,  
    ROUND((size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT))*8.0/1000.0, 2) AS FreeSpaceMB
    FROM sys.database_files
    WHERE type IN (0,1);
    GO"

    # Get a list of databases with no current active sessions
    $GetNoSessionsDBs = "SELECT sd.database_id as DBID, name AS DBName, state_desc AS Status, recovery_model_desc As RecoveryModel
    FROM sys.databases sd
    JOIN 
    (SELECT name AS DBName, database_id
    FROM sys.databases sd2
    WHERE name NOT IN ({0})
    EXCEPT
    SELECT
    DISTINCT(DB_NAME(dbid)) as DBName, dbid
    FROM sys.sysprocesses
    WHERE status <> 'sleeping') subq
    ON subq.database_id = sd.database_id
    WHERE sd.database_id > 4;
    GO"

    $GetPerms = "DECLARE @SQL NVARCHAR(MAX)

    DECLARE grant_cursor CURSOR FOR
    SELECT 'GRANT ALTER ON SCHEMA :: ' + tmp.schemas + ' TO [' + SYSTEM_USER + ']'
    FROM
    (
    SELECT DISTINCT(table_schema) AS schemas
    FROM INFORMATION_SCHEMA.tables
    WHERE table_schema NOT LIKE '%\%') tmp
    
    OPEN grant_cursor
    FETCH NEXT FROM grant_cursor INTO @SQL
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE(@SQL)
        FETCH NEXT FROM grant_cursor INTO @SQL
    END
    
    CLOSE grant_cursor
    DEALLOCATE grant_cursor"

    # Command to shrink a database. 10 percent free space will be left over after the shrinking operation
    $ShrinkCommand = "DBCC SHRINKDATABASE ({0}, 10)"

    # Command to get Index statistics
    $GetIndexStats = " SELECT S.name as 'SchemaName',
    T.name as 'TableName',
    I.name as 'IndexName',
    I.type_desc AS 'IndexType',
    DDIPS.avg_fragmentation_in_percent AS FragmentationPercentage,
    DDIPS.avg_page_space_used_in_percent AS 'PageDensity',
    DDIPS.page_count,
    allow_page_locks,
    allow_row_locks
    FROM sys.dm_db_index_physical_stats (DB_ID(), default, default, default, 'SAMPLED') AS DDIPS
    INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
    INNER JOIN sys.schemas S on T.schema_id = S.schema_id
    INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
		AND DDIPS.index_id = I.index_id
    WHERE DDIPS.database_id = DB_ID()
    AND DDIPS.avg_fragmentation_in_percent > {0}"

    # Command to rebuild an index based on the index fragmentation percentage
    # $IndexRebuildCommand = "ALTER INDEX {1} ON {2} REBUILD WITH(ONLINE=OFF);"

    $IndexRebuildCommand = "DECLARE @table NVARCHAR(100)
    DECLARE @index_name NVARCHAR(100)
    DECLARE @sql NVARCHAR(MAX)
    
    DECLARE index_cursor CURSOR FOR
    SELECT S.name as 'SchemaName',
    T.name as 'TableName',
    I.name as 'IndexName',
    I.type_desc AS 'IndexType',
    DDIPS.avg_fragmentation_in_percent AS FragmentationPercentage,
    DDIPS.avg_page_space_used_in_percent AS 'PageDensity',
    DDIPS.page_count,
    allow_page_locks,
    allow_row_locks
    FROM sys.dm_db_index_physical_stats (DB_ID(), default, default, default, 'SAMPLED') AS DDIPS
    INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
    INNER JOIN sys.schemas S on T.schema_id = S.schema_id
    INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
		AND DDIPS.index_id = I.index_id
    WHERE DDIPS.database_id = DB_ID()
    AND DDIPS.avg_fragmentation_in_percent > 10
    
    OPEN index_cursor
    FETCH NEXT FROM index_cursor INTO @table, @index_name
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @table, @index_name
        EXECUTE ('ALTER INDEX ' + @index_name + ' ON ' + @table + ' REBUILD WITH(ONLINE=OFF);')
        EXECUTE ('ALTER INDEX ' + @index_name + ' ON ' + @table + ' SET(ALLOW_PAGE_LOCKS=ON);')
        EXECUTE ('ALTER INDEX ' + @index_name + ' ON ' + @table + ' REORGANIZE;')
        EXECUTE ('ALTER INDEX ' + @index_name + ' ON ' + @table + ' SET(ALLOW_PAGE_LOCKS=OFF);')
        FETCH NEXT FROM index_cursor INTO @table, @index_name
    END
    CLOSE index_cursor
    DEALLOCATE index_cursor"

    $IndexRebuildCommand ="
    BEGIN TRY
        EXECUTE ('ALTER INDEX {0} ON {1} REBUILD WITH(ONLINE=OFF);')
        EXECUTE ('ALTER INDEX {0} ON {1} SET(ALLOW_PAGE_LOCKS=ON);')
        EXECUTE ('ALTER INDEX {0} ON {1} REORGANIZE;')
        EXECUTE ('ALTER INDEX {0} ON {1} SET(ALLOW_PAGE_LOCKS=OFF);')
    END TRY
	BEGIN CATCH
		PRINT CHAR(9) + 'Failed to Rebuild Index {0} on Table {1}' + CHAR(10)
		PRINT ERROR_MESSAGE()
	END CATCH"

    # Command to re-organize index
    #$ReOrganizeCommand = "ALTER INDEX {0} ON {1} REORGANIZE"

    #$SetPageLock = "ALTER INDEX {0} ON {1} SET ( ALLOW_PAGE_LOCKS = {2} )"

    # The total duration for the index-rebuild operations(hr:min:sec). the script will stop performing index rebuild
    # operations when this time is reached, or when all target databases have completed their rebuild operations
    $TotalRebuildTime = '06:00:00'

    # Maximum allowed time for a single database index-rebuild operation in minutes (Set for)
    $MaxRebuildTime = 30

    # Databases that are exemptd from index-rebuild operations
    $ExemptList = @($MaintenanceDBName, 
                    'DATASHARE_UPSTREAM', 
                    'DATASHARE'
                    )

    # turn the $ExempList array into a comma-seperated string list 
    $ExemptList = "'" + [system.String]::Join("', '", $ExemptList) + "'"

    # The target duration for the shrinking operation(hr:min:sec). Database shrinking will stop when this time is reached,
    # or when all target databases (non-system, and non-exempt databases) have completed their shinking operation
    $TargetEndTime = '02:00:00'

    $ReportDir = "B:\Scripts\Report\"
    $ServerInstanceFile =  $ServerName.Replace('\', '_')
    $ReportFile =  $ReportDir + $ServerInstanceFile + "_Shrink&ReindexReport.txt"

    ########################################################################################################
    # Execution
    ########################################################################################################

    $ScriptStartTime = Get-Date -DisplayHint DateTime

    # Clear content of output file
    Clear-Content -Path $ReportFile

    #Create report directory if it doesn't exist
    if($false -eq (Test-Path $ReportDir))
    {
        New-Item $ReportDir -ItemType Directory | Out-Null
    }

    # Binary counter to make sure email is only sent once within loop
    $count = 1

    # Start the timer
    $StopWatch.Start()

    $ShrinkReportBefore = @()
    $ShrinkReportAfter = @()
    $CompletedDBs = @()

    # Perform shrink on all eligible databases until all databases slated for shrinking have been completed or the
    # target time is exceeded

    # Databases that are eligible for shrinking operations
    $EligibleDBs = Get-CandidateDBs | Sort-Object -Property DBName
    $list = @('GISGDO') #, 'EEC_US_TRANS_IRASv6_IRASP_STAGE', 'EEC_US_TRANS_IRASv6_QRA_STAGE')
    $eligibledbs = $EligibleDBs | Where-Object {$_.DbName -in $List}
    #$EligibleDBs
 
#######################################################################################################
# SHRINK DATABASE 
#######################################################################################################

    # Creates a stop watch variable that will keep track of the time for the shrinking operation
    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $StopWatch.Start()
    $ShrinkStartTime = Get-Date -DisplayHint DateTime

    Write-Host ""
    foreach ($DB in $EligibleDBs)
    {
        Write-Host "Shrinking" $DB.DBName "Database"

        #Add the current database free space statistics to report ouput file before shrinking
        $ShrinkReportBefore += Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query $GetFreeSpaceReport

        # Perform shrink operation for a given database
        $SQL = $ShrinkCommand -f $DB.DBID
        Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $SQL -QueryTimeout 3600 | Out-null

        #Add the current database free space statistics to report ouput file after shrinking
        $ShrinkReportAfter += Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query $GetFreeSpaceReport

        # Datebases that have completed their shrinking operation
        $CompletedDBs += $DB.DBName

        # Stop shrinkin operations if the target script run-time is reached
        if ($StopWatch.Elapsed -ge $TargetEndTime) {
            $StopWatch.Stop()
            break
        }

    }#end of foreach-loop for shrinking

    Write-Output "#####################################################################################" | Out-File -Append $ReportFile
    Write-Output "# Before Shrinking Operation"  | Out-File -Append $ReportFile
    Write-Output "#####################################################################################`r`n`r`n" | Out-File -Append $ReportFile

    $ShrinkReportBefore | Sort-Object -Descending -Property CurrentSizeMB, DbName  | Format-Table -AutoSize | Out-File -Append $ReportFile
    
    Write-Output "#####################################################################################" | Out-File -Append $ReportFile
    Write-Output "# After Shrinking Operation"  | Out-File -Append $ReportFile
    Write-Output "#####################################################################################`r`n`r`n" | Out-File -Append $ReportFile
    
    $ShrinkReportAfter | Sort-Object -Descending -Property CurrentSizeMB, DbName |  Format-Table -AutoSize | Out-File -Append $ReportFile

    #Calculate the total amount of space reclaimed from shrinking and add it to the output file
    $SizeBefore = ($ShrinkReportBefore.CurrentSizeMB | Measure-Object -Sum).Sum
    $SizeAfter = ($ShrinkReportAfter.CurrentSizeMB | Measure-Object -Sum).Sum
    $SpaceGainMB = $SizeBefore - $SizeAfter
    $SpaceGainGB = [math]::Round($SpaceGainMB/1000.0, 2)
    $SpaceGainMB = [math]::Round(($SizeBefore - $SizeAfter), 2)

    if ($null -eq $SpaceGainMB)
    {
        $SpaceGainMB = 0
    }

    Write-Output "`r`nTotal Amount of Space Reclaimed:  MB ($SpaceGainGB GB)" | Out-File -Append $ReportFile
    $ShrinkEndTime = Get-Date -DisplayHint datetime

    #Add total time to complete shrinking operation to the ouput file
    $TotalShrinkTime = $StopWatch.Elapsed.ToString("hh'hr:'mm'min:'ss'sec'")
    Write-Output "Start Time: $ShrinkStartTime" | Out-File -Append $ReportFile
    Write-Output "End Time: $ShrinkEndTime" | Out-File -Append $ReportFile
    Write-OutPut "Duration of Completed Shrinking Operations: $TotalShrinkTime`r`n" | Out-File -Append $ReportFile

    Write-Host "`r`nDuration of Completed Shrinking Operations: $TotalShrinkTime`r`n"

    #>
        
    #########################################################################################################
    # RE-INDEXING 
    #########################################################################################################
       
#------------------------------------------- Execution -------------------------------------------------
    
    # Binary counter to make sure email is only sent once within the while loop below
    $count = 1

    # Start the timer
    $StopWatch.Reset()
    $StopWatch.Start()

    $BeforeReindex = New-Object System.Collections.ArrayList
    $AfterReindex = New-Object System.Collections.ArrayList
    $CompletedDBs = @()
    
    #$EligibleDBs = $EligibleDBs | Where-Object {$_.DBName -in @('GISGDO', 'GISLND')}
#------------------------------------------- DEFRAGMENT INDEX AND UPDATE STATISTICS ---------------------------------------

    $ReindexStartTime = Get-Date -DisplayHint datetime

    # Perform index-rebuild on all eligible databases until completed or until the target script run-time is exceeded
    foreach ($DB in $EligibleDBs)
    {
        Write-Host "Re-indexing" $DB.DBName "Database"

        Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query $GetPerms #| Out-Null

        # Get index statistics for the database
        $IndexStats = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query ($GetIndexStats -f 0) -QueryTimeout 300

        $FragPercentage = ($IndexStats | Measure-Object -Property FragmentationPercentage -Average -Maximum)
        $PageCount = ($IndexStats | Measure-Object -Property page_count -Average -Maximum)
        $PageDensity = ($IndexStats | Measure-Object -Property PageDensity -Average -Minimum)
        
        $Before = New-Object System.Object

        if ($null -eq $FragPercentage) 
        {
            $Before | Add-Member -MemberType NoteProperty -Name "DBName" -Value $DB.DBName
            #$Before | Add-Member -MemberType NoteProperty -Name "MaxFrag" -Value 0
            $Before | Add-Member -MemberType NoteProperty -Name "AvgFrag" -Value 0
            $Before | Add-Member -MemberType NoteProperty -Name "MinPageDensity" -Value 'N/A'
            $Before | Add-Member -MemberType NoteProperty -Name "AvgPageDensity" -Value 'N/A'
            $Before | Add-Member -MemberType NoteProperty -Name "AvgPageCount" -Value 'N/A'
        }
        else 
        {
            $Before | Add-Member -MemberType NoteProperty -Name "DBName" -Value $DB.DBName
            #$Before | Add-Member -MemberType NoteProperty -Name "MaxFrag" -Value ([math]::Round($FragPercentage.Maximum, 2))
            $Before | Add-Member -MemberType NoteProperty -Name "AvgFrag" -Value ([math]::Round($FragPercentage.Average, 2))
            $Before | Add-Member -MemberType NoteProperty -Name "MinPageDensity" -Value ([math]::Round($PageDensity.Minimum, 2))
            $Before | Add-Member -MemberType NoteProperty -Name "AvgPageDensity" -Value ([math]::Round($PageDensity.Average, 2))
            $Before | Add-Member -MemberType NoteProperty -Name "AvgPageCount" -Value ([math]::Round($PageCount.Average, 2))
        }

        $BeforeReindex.Add($Before) | Out-Null 

        # Rebuild indexes for a given database. Index-rebuild for any particular index stops if it takes
        # longer the the $MaxRebuildTime time to rebuild the index
        $IndexStats = $IndexStats | Where-Object {$_.FragmentationPercentage -gt 10}

        foreach ($Index in $IndexStats)
        {
            $SQL = $IndexRebuildCommand -f $index.IndexName, $Index.TableName
            Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query $SQL -QueryTimeout ($MaxRebuildTime * 60)    
        }

        # Get the index statistics after index re-oganization operation
        $IndexStats = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query ($GetIndexStats -f 0) -QueryTimeout 300 

        $FragPercentage = ($IndexStats | Measure-Object -Property FragmentationPercentage -Average -Maximum)
        $PageCount = ($IndexStats | Measure-Object -Property page_count -Average -Maximum)
        $PageDensity = ($IndexStats | Measure-Object -Property PageDensity -Average -Minimum)
        
        if ( $FragPercentage.Maximum -le 10)
        {
            $CompletedDBs += $DB.DBName
        }

        $After = New-Object System.Object

        if ($null -eq $FragPercentage) 
        {
            $After | Add-Member -MemberType NoteProperty -Force -Name "DBName" -Value $DB.DBName
            #$After | Add-Member -MemberType NoteProperty -Force -Name "MaxFrag" -Value 0
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgFrag" -Value 0
            $After | Add-Member -MemberType NoteProperty -Force -Name "MinPageDensity" -Value 'N/A'
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgPageDensity" -Value 'N/A'
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgPageCount" -Value 'N/A'
        }
        else 
        {
            $After | Add-Member -MemberType NoteProperty -Force -Name "DBName" -Value $DB.DBName
            #$AFter | Add-Member -MemberType NoteProperty -Force -Name "MaxFrag" -Value ([math]::Round($FragPercentage.Maximum, 2))
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgFrag" -Value ([math]::Round($FragPercentage.Average, 2))
            $After | Add-Member -MemberType NoteProperty -Force -Name "MinPageDensity" -Value ([math]::Round($PageDensity.Minimum, 2))
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgPageDensity" -Value ([math]::Round($PageDensity.Average, 2))
            $After | Add-Member -MemberType NoteProperty -Force -Name "AvgPageCount" -Value ([math]::round($PageCount.Average))
        }

        $AfterReindex.Add($After) | Out-Null 
        #$AfterReindex
        
        #Update statistics
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB.DBName -Query "exec sp_updatestats" -QueryTimeout 500 | Out-Null
        
        # Stop index-rebuild operations if the target script run-time is reached
        if ($StopWatch.Elapsed -ge $TotalRebuildTime) {
            $StopWatch.Stop()
            break
        }
    }#End of foreach-loop for re-indexing
   #>
    Write-Output "#####################################################################################" | Out-File -Append $ReportFile
    Write-Output "# Before Index Defragmentation"  | Out-File -Append $ReportFile
    Write-Output "#####################################################################################`r`n" | Out-File -Append $ReportFile

    $BeforeReindex | Sort-Object -Descending -Property AvgFrag, DBName | Format-Table -AutoSize | Out-File -Append $ReportFile

    Write-Output "#####################################################################################" | Out-File -Append $ReportFile
    Write-Output "# After Index Defragmentation" | Out-File -Append $ReportFile
    Write-Output "#####################################################################################`r`n" | Out-File -Append $ReportFile

    $AfterReindex | Sort-Object -Descending -Property AvgFrag, DBName | Format-Table -AutoSize | Out-File -Append $ReportFile

    # Databases that are offline
    $OfflineDBs = Get-OfflineDBs
    if($null -ne $OfflineDBs)
    {
        $OfflineDBs = $OfflineDBs.DBName
 
    }

    # Databases that do not have a SIMPLE recovery model
    $WrongRecoveryMode = Get-WrongRecoveryModeDBs 
    if($null -ne $WrongRecoveryMode)
    {
        $WrongRecoveryMode =  $WrongRecoveryMode.DBName
    }

    $Message = "The Database shrink and index maintenance operations have been completed.`r`n"
    $Message += "`r`nDatabase Shrinking and index rebuild can not be performed on OFFLINE databases, databases in READ-ONLY mode, or databases without a SIMPLE recovery model`r`n"

    # Send an email if any databases are in offline mode or is not in a SIMPLE recovery model
    if ($null -ne $WrongRecoveryMode -or $null -ne $OfflineDBs -and $count -eq 1) 
    {
        $SubjectLine = "$ServerInstance Failed Shrink & Index Rebuild Operations"

        if($null -ne $OfflineDBs)
        {
            #$StringList = [system.String]::Join("`r`n", $OfflineDBs) + "`r`n"
            $Message += "`r`nThe following databases are OFFLINE: `r`n`r`n" `
            + [system.String]::Join("`r`n", ($OfflineDBs | Sort-Object)) 
        }

        if($null -ne $WrongRecoveryMode)
        {
            $Message += "`r`n`The following databases do not have a SIMPLE recovery model:`r`n`r`n" `
            + [system.String]::Join("`r`n", ($WrongRecoveryMode | Sort-Object))
        }

        #Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPriority 2 -Directory $null

        $count = 0
    }

    # Stop the stopwatch
    $StopWatch.Stop()

    # Time at the end of the Re-indexing operation
    $ReindexEndTime = Get-Date -Displayhint DateTime

    # Get the time for end of script run
    $ScriptEndTime = Get-Date -DisplayHint DateTime

    #Add the total time taken to complete the re-indexing operations to the output file
    $TotalReindexTime = $StopWatch.Elapsed.ToString("hh'hr:'mm'min:'ss'sec'")
    $ScriptRunDuration = ($ScriptEndTime - $ScriptStartTime).ToString("hh'hr:'mm'min:'ss'sec'")

    Write-Output "Start Time: $ReindexStartTime" | Out-File -Append $ReportFile
    Write-OutPut "End Time: $ReindexEndTime" | Out-File -Append $ReportFile
    Write-Output "Duration of Completed Re-indexing Operations: $TotalReindexTime" | Out-File -Append $ReportFile
    Write-Output "`r`nTotal Duration for script Run: $ScriptRunDuration" | Out-File -Append $ReportFile

    Write-Host "`r`nDuration of Completed Re-indexing Operations: $TotalReindexTime"
    Write-Host "`r`n`Total Duration for script Run: $ScriptRunDuration `r`n"


    $SubjectLine = "$ServerInstance Database Shrink and Re-index Report"

    $Message += "`r`n`r`nA report of the shrink and index maintenance operation can be viewed in the attached files."

    #Send email of report 
    Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPriority 1 -Directory $ReportDir

  
    #>
   