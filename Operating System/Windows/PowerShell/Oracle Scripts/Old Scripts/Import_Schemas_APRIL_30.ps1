<#

The purpose of this script is to mass import a list of schemas using Oracle Datapump. The directory for the dumpfiles must be specified
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
$DBHostName = "$ServerName.eddyfindt.com"
$DBServiceName = "ORA19C.eddyfindt.com"
$UserName = "DBBackupUser"
$Password = "DBBACKUPUSER"
$TNSName = "DRASORA19C"

#List of schemas to perform datapump export
$List = "GTM
ADNOC_GDB_SOURCE
DRAS_IRASV6_DEV_DE_DEMO_OWNR
DRAS_IRASV6_DEV_DE_DEMO
DRAS_IRASV6_DEV_DEMO_OWNR
DRAS_IRASV6_DEV_DEMO
RISKADM
PODSADM
REPORTADM
DRAS_IRASV6_DATAEXCHANGE_OWNR
DRAS_IRASV6_DATAEXCHANGE
PPL_PODS_PROD
RMAN
ADNOC_ONEGIS_AGPD
"
$List = -Split $List

#Query to generate a list of schemas that need to be imported. Checks that the schemas exists in the target database
$GetSchemaQuery = "SELECT username FROM ALL_USERS 
WHERE username IN ($List)
ORDER BY USERNAME";

#Set the dumpfile location
$BuLocation = "B:\ORA19C DUMPFILES\"

#SQL command to set the directory for Oracle Datapump operations
$SetBackupLoc = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation' "

#Connection string that will be used to connect to Oracle Datapump utility
$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DBHostName)(PORT=1521)) `
(CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=DBBACKUPUSER;Password=DBBACKUPUSER;"

##################################################################################################################
# EXECUTION
##################################################################################################################

############################################### SQL QUERIES #################################################

#PowerShell Object for setting the string used to open an Oracle database
$Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

#Create the command to set the Oracle DataPump directory to the backup directory
$SQLCMD = $Connection.CreateCommand()
$SQLCMD.CommandText = $SetBackupLoc
$SQLCMD.CommandTimeout = 60 #seconds

#Stores output of command for setting DataPump directory
$Void = New-Object System.Data.DataTable

#Execute command to set the Oracle DataPump directory to the backup location
$Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
[Void]$Adapter.Fill($Void)


#Stop watch to keep track of time it takes to complete a backup
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

#Get a list of all files in the dumpfile location
$DumpFileList = Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq '.DMP'}

# filter for the files that you want to import
$SchemaList = @()

foreach($File in $DumpFileList)
{

    #The line below is the filter and may need to be modified as needed (it tries to extract the schema name from the dumpfile name)
    $Schema = $File.BaseName.Substring(0, $File.Basename.IndexOf("_ARCHIVED"))
    
    if($Schema -in $list)
    {
        $SchemaList += @([PSCustomObject]@{ Name = $Schema; DumpFile = $File.Name; Size_MB = $File.Length/1024/1000})
    }
}

############################################## NIGHTLY BACKUP #################################################

#Start stop watch
$StopWatch.Start()


#Loop through all of the schemas that needS to be imported
foreach ($Schema in $SchemaList)
{ 
  
	try 
	{
		$StartTime = "Start time - " + (get-date -Displayhint datetime)
  
        #$ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DBHostName)(PORT=1521)) `
        #(CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=DBBACKUPUSER;Password=DBBACKUPUSER;"

        #PowerShell Object for setting the string used to open an Oracle database
        $Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

 #---------------------------------- This command creates the tablespace and user if they do not already exist -------------------------------

        $SQL = "DECLARE
            CNT NUMBER;
        BEGIN
   
            SELECT COUNT(*) INTO CNT
            FROM dba_tablespaces
            WHERE tablespace_name = '{0}';

            IF CNT = 0 THEN
                EXECUTE IMMEDIATE ('CREATE BIGFILE TABLESPACE {0}
                DATAFILE ''{1}'' SIZE {2}M REUSE
                AUTOEXTEND ON NEXT {3}M MAXSIZE {4}M
                EXTENT MANAGEMENT LOCAL AUTOALLOCATE
                SEGMENT SPACE MANAGEMENT AUTO');
            END IF;

            SELECT COUNT(*) INTO CNT
            FROM ALL_USERS 
            WHERE USERNAME = '{0}';

            IF CNT = 0 THEN
                EXECUTE IMMEDIATE ('CREATE USER {0} IDENTIFIED BY {5} DEFAULT TABLESPACE {0} QUOTA UNLIMITED ON {0}');
            ELSE
                EXECUTE IMMEDIATE ('ALTER USER {0} IDENTIFIED BY {5} DEFAULT TABLESPACE {0} QUOTA UNLIMITED ON {0}');     
            END IF;
        END;
        /"

        #Create command to execute $GetSchemaQuery
        $DataFile = $DataFileDir + $Schema.Name + ".dbf"

        if ([Math]::Round($Schema.Size_MB * 1.5) -lt 7)
        {
            $Size = 7
        }
        else
        {
           $Size =[Math]::Round($Schema.Size_MB * 2) 
        }

        if ($Size* 0.1 -lt 1)
        {
            $Increment = 1
        }
        else
        {
            $Increment = [Math]::Round($Size* 0.1)
        }

        $MaxSize = [Math]::Round($Size * 2.5)
        $Command = $SQL -f $Schema.Name, $DataFile, $Size, $Increment, $MaxSize, $Schema.Name.ToLower()

        #Execute commands to create the tables and user for te schema import
        $Command | SQLPlus -silent "$Username/$Password@$TNSName"

#-------------------------------------------- IMPORT SCHEMA  -------------------------------------------------------
		
		#Command to import schemas
		Invoke-Command -ScriptBlock {impdp $Username/$Password@$TNSName schemas= $Schema.Name `
		DIRECTORY=DATAPUMP DUMPFILE=$($Schema.DumpFile) LOGFILE="IMPORT_$($Schema.Name)_$(Get-Date -Format "dd_MMM_yyyy").log" `
        TABLE_EXISTS_ACTION=REPLACE EXCLUDE=STATISTICS PARALLEL=2 METRICS=YES}
		
		$EndTime = "End time - " + (get-date -Displayhint datetime)
		
	
		if(($FileExists | Measure-Object).Count -eq 2)
		{
			#Remove-Item ($BuLocation + $Schema + ".*")
		}
    } #end try-block
    catch 
    {
		    $err=$Error[0]

    } #end catch-block



} #end of foreach-loop 
