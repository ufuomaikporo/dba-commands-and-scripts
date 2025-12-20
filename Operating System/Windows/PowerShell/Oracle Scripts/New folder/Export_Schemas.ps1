<#

This script does the following...
-Uses Oracle datapump to EXPORT non-oracle maintained schemas to dumpfiles within a specified directory 

#>

#################################################################################################################
# FUNCTIONS
################################################################################################################## 

# Function to Check if a directory path location (i.e. backup location) exists. Creates the directory if it does not exist 
Function CheckLocationExists ([string] $Directory)
	{
		If (!(Test-Path -path $Directory))  
			{ 
				New-item -type directory $Directory
			} 
	}

##################################################################################################################
# VARIABLE DECLARATION/INITIALIZATION
################################################################################################################## 

# Set the following Variables
$ServerName = HOSTNAME.EXE
$DBHostName = $ServerName
$TNSName = "ORA19C22"

#Dumpfile Location (Location for export) - If using a network drive location you can map the drive on the server where the script is being executed
$BuLocation = "B:\Archive\2023\ATCO_UPDM_JULY_ARCHIVED_20_OCT_2023\"

#List of schemas to be exported
$List = "ATCO_UPDM"

#################################################################################################################

$List = $List.Replace(" ", "") 
$List = "'" + $List.Replace("`r`n", "', '") + "'"
$List = $List.Replace(", ''", "") 

#Script report/log file
$Logfile = $BuLocation + "ExportSchemas_Logfile.txt"

##################################################################################################################
# EXECUTION
##################################################################################################################

############################################### SQL QUERIES #################################################

# --------------------------------------- CONFIGURE ORACLE CONNECTION ---------------------------------

$User = Read-Host "`r`nEnter an Oracle username"
$SecurePassword = Read-Host -Prompt "Enter an Oracle user password" -AsSecureString
$PlainTextPass = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
Write-Host ""

#----------------------------------------------- Get a list of target schemas for export --------------------------------------

$SQL = "SET FEEDBACK OFF
SET PAGES 0
SELECT username FROM all_users 
WHERE username IN ($LIst)
ORDER BY username;"

$SchemaList = $SQL | SQLPLUS -silent "$User/`"$PlainTextPass`"@$TNSName"

#---------------------------------------- Set the location of the Oracle datapump dumpfile -----------------------------------------------------

$SQL = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation';"

$Void = $SQL | SQLPLUS -silent  "$User/`"$PlainTextPass`"@$TNSName"

############################################## DATAPUMP EXPORT #################################################

#Stop watch to keep track of time it takes to complete a backup
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

#Verify that the backup directories/locations exist
CheckLocationExists $BuLocation

#Start stop watch
$StopWatch.Start()

$CompletedExports = @()

#Loop through all of the schemas in the directory and import each one
:schema foreach ($Schema in $SchemaList)
{ 

	$StartTime = "Start time - " + (get-date -Displayhint datetime)

    #Estimate the dumpfile size
    Invoke-Command -ScriptBlock {expdp $User/$PlainTextPass@$TNSName `
                                        SCHEMAS=$($Schema) `
                                        DIRECTORY=datapump  `
                                        LOGFILE="ExportEstimate.log" `
                                        ESTIMATE_ONLY=y `
                                        ESTIMATE=blocks
                                 }

    $SearchedString = Select-String -Path "$($BULocation)ExportEstimate.log" -Pattern "Total estimation using BLOCKS method:*" `
    | Select-Object -Property Line
	
    #Get the units for the estimated dumpfile size 
    $StartIndex = $SearchedString.Line.IndexOf("B", 40) - 1
    $DumpFileSizeUnits = $SearchedString.Line.Substring($StartIndex, 2)

    #Get the dumpfile size in GB
    $StartIndex = $SearchedString.Line.IndexOf(":") + 2
    $SubstrLength = $SearchedString.Line.IndexOf("B", 40) - $StartIndex - 2

    if($DumpFileSizeUnits -eq 'KB')
    {
        $EstDumpFileSize = [double]$SearchedString.Line.Substring($StartIndex, $SubstrLength)/1000/1000
    }
    elseif($DumpFileSizeUnits -eq 'MB')
    {
        $EstDumpFileSize = [double]$SearchedString.Line.Substring($StartIndex, $SubstrLength)/1000
    }
    elseif($DumpFileSizeUnits -eq 'GB')
    {
        $EstDumpFileSize = [double]$SearchedString.Line.Substring($StartIndex, $SubstrLength)
    }

    #Find how much disk spaceis left on drive (this assumes the BULocation is set to location on disk)
    $BULocationDiskInfo = Get-PSDrive | Where-Object {$_.Root -like "$($BULocation.Substring(0, 2))*"}

    #$EstDumpFileSize | Get-Member
    $FreeSpace = $BULocationDiskInfo.Free/1024/1024/1024 
   
    #If there is enough space plus 500MB on the disk then perform the export
    if($FreeSpace -gt $EstDumpFileSize + .500)
    {
        $DumpFileName = "$($Schema)_ARCHIVED_$(Get-Date -Format "dd_MMM_yyyy")"
        

        #Export Schema
	    Invoke-Command -ScriptBlock {expdp $User/$PlainTextPass@$TNSName `
        SCHEMAS= "$($Schema)" `
	    DIRECTORY=DATAPUMP `
        DUMPFILE="$DumpFileName.dmp" `
        LOGFILE="$DumpFileName.log" `
        REUSE_DUMPFILES=Y `
        EXCLUDE=STATISTICS `
        METRICS=YES `
        PARALLEL=2 `
        FLASHBACK_TIME=SYSTIMESTAMP `
        COMPRESSION=ALL
        }
        
        $CompletedExports += $Schema

	}

} #end of foreach-loop 


#Delete contents in $Logfile
Write-Output "" | Out-File $Logfile -Force


if ($CompletedExports.Length -ne 0)
{
    Write-Output "################################## COMPLETED SCHEMA EXPORTS ##################################" | Out-File $Logfile -Append
    Write-Output "`r`nThe following schemas were successfully exported`r`n" | Out-File $Logfile -Append
    $CompletedExports | Out-File -FilePath $Logfile -Append
}


# Get a list of schemas that were not exported
$IncompleteExports = $SchemaList | Where-Object {$_.Username -notin $CompletedExports.Username}

if($IncompleteExports.Length -ne 0)
{
    Write-Output "################################## INCOMPLETE SCHEMA EXPORTS ##################################" | Out-File $Logfile -Append
    Write-Output "`r`nThe following schemas could not be exported possibly due to a lack of disk space`r`n" | Out-File $Logfile -Append
    $IncompleteExports | Out-File -FilePath $Logfile -Append
   
}

$ErrorLogFiles = @()

foreach ($Schema in $SchemaList)
{
    $ExpDPLogfile = Get-ChildItem -Path "$BuLocation*.log" | Where-Object {$_.Name -like "*$()*"}
    
    if ($ExpDPLogfile -ne $null)
    {
        if (!(Select-String -Path $ExpDPLogfile -Pattern "successfully completed"))
        {
            if($Schema -notin $ErrorLogFiles)
            {
                $ErrorLogFiles += $ExpDPLogfile.FullName
            }
        
       }
    }  
}

if($ErrorLogFiles.Length -ne 0)
{
    Write-Output "`r`n################################## DATAPUMP EXPORT WITH ERRORS ##################################" | Out-File $Logfile -Append
    Write-Output "The following datapump export logfiles contain errors`r`n" | Out-File $Logfile -Append
    Write-Output $ErrorLogFiles | Out-File $Logfile -Append
}

if($ErrorLogFiles.Length -eq 0 -and $IncompleteExports.Length -eq 0)
{
    Write-Output "`r`n`r`nThe schema exports were successfully completed!" | Out-File $Logfile -Append
}

########################################### CLEANUP ###################################################

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

if (Test-Path "$($BULocation)ExportEstimate.log" )
{
    Remove-Item -"$($BULocation)ExportEstimate.log"
}
#>
