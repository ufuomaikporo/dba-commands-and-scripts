<#

The purpose of this script is to export a list of schemas using Oracle datapump 
 
#>

#################################################################################################################
# PREREQUISITES
#################################################################################################################

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

#################################################################################################################
# FUNCTIONS
################################################################################################################## 

#Function to check for the location of a file. Takes full filepath as an argument
Function CheckFileExists([string] $FilePath)
	{
		If (Test-path $FilePath ) 
			{

			    Clear-Content $FilePath 
			}
	}


# Function to Check a directory path location (i.e. backup location). Creates the directory if it does not exist 
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

$ServerName = HOSTNAME.EXE
$DBHostName = "$ServerName.EDDYFINDT.COM"
$DBServiceName = $DBHostName

#List of schemas to perform datapump export
$List = "ARAMCO_UPDM_PROD
ATCO_UPDM_JULY
ATLAS
CORROSIONCONTROL
ENTERPRISE
ETP_IRASV6_TEST
ETP_IRASV6_TEST_OWNR
ETP_IRASV6_UAT
ETP_IRASV6_UAT_OWNR
ETPTEST
ETPTEST_OWNR
INTEGRITY
MOBILE
ONECALL
PEFORMS
PROACTIVE
PROACTIVEFGT
PROACTIVEINTER
PROACTIVEINTRA
PROACTIVELIQUID
PROACTIVEPEPL
PROACTIVESR
PROACTIVETGC
RISK
"
$List = $List.Replace(" ", "") 
$List = "'" + $List.Replace("`r`n", "', '") + "'"
$List = $List.Replace(", ''", "") 

#Query to generate a list of Oracle users/schemas that need to be backed up.
$GetSchemaQuery = "SELECT username FROM all_users
WHERE username IN ($List)
ORDER BY username"

#Dumpfile Location
$BuLocation = "B:\Archive\"

#Script report/log file
$Logfile = $BuLocation + "ExportSchemas_Logfile.txt"

#SQL command to set the directory for Oracle Datapump operations
$SetBackupLoc = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation' "

##################################################################################################################
# EXECUTION
##################################################################################################################

############################################### SQL QUERIES #################################################

# --------------------------------------- CONFIGURE ORACLE CONNECTION ----------------------------------

$User = Read-Host "`r`nEnter an Oracle username"
$SecurePassword = Read-Host -Prompt "Enter an Oracle user password" -AsSecureString
$PlainTextPass = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
Write-Host ""


#Connection string that will be used to connect to Oracle Datapump utility
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DBHostName)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=$user;Password=$PlainTextPass;"

#-------------------------------------------------------- Get a list of target schemas --------------------------------------

#PowerShell Object for setting the string used to open an Oracle database
$Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

#$GetSchemaQuery | sqlplus "$User/`"$PlainTextPass`"@$ServerName"
#break

#Create command to execute $GetSchemaQuery to generate the list of target schemas
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $GetSchemaQuery
$SQLCMD.CommandTimeout = 60 #seconds

#PowerShell object to store the results from an $GetSchemaQuery query
$SchemaList = New-Object System.Data.DataTable

#Connect to the database and and execute the query to fill the datatable object (i.e. get schema list)
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($SchemaList)

#---------------------------------------- Set the location of the Oracle datapump dumpfile -----------------------------------------------------

#Create the command to set the Oracle DataPump directory to the backup directory
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $SetBackupLoc
$SQLCMD.CommandTimeout = 60 #seconds

#Stores output of command for setting DataPump directory
$Void = New-Object System.Data.DataTable

#Execute command to set the Oracle DataPump directory to the backup location
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($Void)

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
    Invoke-Command -ScriptBlock {expdp $User/$PlainTextPass@$ServerName `
                                        SCHEMAS=$($Schema.Username) `
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

    #Find how much disk spaceis left on drive
    $BULocationDiskInfo = Get-PSDrive | Where-Object {$_.Root -like "$($BULocation.Substring(0, 2))*"}

    #$EstDumpFileSize | Get-Member
    $FreeSpace = $BULocationDiskInfo.Free/1024/1024/1024 

    #If there is enough space plus 500MB on the disk then perform the export
    if($FreeSpace -gt $EstDumpFileSize + .500)
    {
        $DumpFileName = "$($Schema.Username)_ARCHIVED_$(Get-Date -Format "dd_MMM_yyyy")"

        #Export Schema
	    Invoke-Command -ScriptBlock {expdp $User/$PlainTextPass@$ServerName `
        SCHEMAS= "$($Schema.UserName)" `
	    DIRECTORY=DATAPUMP `
        DUMPFILE="$DumpFileName.dmp" `
        LOGFILE="$DumpFileName.log" `
        REUSE_DUMPFILES=Y `
        EXCLUDE=STATISTICS `
        METRICS=YES `
        PARALLEL=2 `
        FLASHBACK_TIME=SYSTIMESTAMP
        }

        $CompletedExports += $Schema.Username
	}

} #end of foreach-loop 
#>

# Get a list of schemas that were not exported
$IncompleteExports = $SchemaList | Where-Object {$_.Username -notin $CompletedExports}

Write-Output "" | Out-File $Logfile -Force

if($IncompleteExports.Length -ne 0)
{
    Write-Output "################################## INCOMPLETE SCHEMA EXPORTS ##################################" | Out-File $Logfile -Append
    Write-Output "`r`nThe following schemas could not be exported`r`n" | Out-File $Logfile -Append
    $IncompleteExports | Select-Object -Property @{Name= 'IncompleteSchemas'; Expression = {$_.Username}} | Out-File -FilePath $Logfile -Append
}

$ErrorLogFiles = @()

foreach ($Schema in $SchemaList)
{
    $ExpDPLogfile = Get-ChildItem -Path "$BuLocation*.log" | Where-Object {$_.Name -like "*$($Schema.username)*"}
   
    if (!(Select-String -Path $ExpDPLogfile.FullName -Pattern "successfully completed"))
    {
        if($Schema -notin $ErrorLogFiles)
        {
            $ErrorLogFiles += $ExpDPLogfile.FullName
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
    Write-Output "The schema exports were successfully completed!" | Out-File $Logfile -Append
}

########################################### CLEANUP ###################################################
<#
# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

if (Test-Path "$($BULocation)ExportEstimate.log" )
{
    Remove-Item -"$($BULocation)ExportEstimate.log"
}
#>
