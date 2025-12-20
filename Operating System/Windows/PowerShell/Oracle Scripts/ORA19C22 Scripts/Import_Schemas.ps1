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
$TNSName = "ORA19C22"

#Set the dumpfile location
$BuLocation = "B:\Archive\2023\ATCO_UPDM_JULY_ARCHIVED_20_OCT_2023\"


#List of schemas to be imported. If the list is empty or set to null, all dumpfiles in the dumpfile location will be imported
$ImportList = "ATCO_UPDM_JULY"

#########################################################################################################################

$UserName = Read-Host "`r`nEnter an Oracle username"
$SecurePassword = Read-Host -Prompt "Enter an Oracle user password" -AsSecureString
$PlainTextPass = (New-Object PSCredential 0, $SecurePassword).GetNetworkCredential().Password
Write-Host ""


$ImportList = -Split $ImportList

##################################################################################################################
# EXECUTION
##################################################################################################################

#---------------------------------------- Set the location of the Oracle datapump dumpfile -----------------------------------------------------

$SQL = "CREATE OR REPLACE DIRECTORY `"DATAPUMP`" AS '$BuLocation';"

$Void = $SQL | SQLPLUS -silent  "$UserName/`"$PlainTextPass`"@$TNSName"

#----------------------------------------------------------------------------------------------------------------------------------------------

#Get a list of all files in the dumpfile location
$DumpFileList = Get-ChildItem $BuLocation | Where-Object {$_.Extension -eq '.DMP'}

# filter for the files that you want to import
$SchemaList = @()

if([string]::IsNullOrWhiteSpace($ImportList))
{
    foreach($File in $DumpFileList)
    {

        #The line below is the filter and may need to be modified as needed (it tries to extract the schema name from the dumpfile name)
        $Schema = $File.BaseName.Substring(0, $File.Basename.IndexOf("_ARCHIVED"))
    

        $SchemaList += @([PSCustomObject]@{ Name = $Schema; DumpFile = $File.Name; Size_MB = $File.Length/1024/1000})

    }
}
else
{
    foreach($File in $DumpFileList)
    {

        #The line below is the filter and may need to be modified as needed (it tries to extract the schema name from the dumpfile name)
        $Schema = $File.BaseName.Substring(0, $File.Basename.IndexOf("_ARCHIVED"))
    
        if($Schema -in $ImportList)
        {
            $SchemaList += @([PSCustomObject]@{ Name = $Schema; DumpFile = $File.Name; Size_MB = $File.Length/1024/1000})
        }
    }
}

############################################## NIGHTLY BACKUP #################################################


#Loop through all of the schemas that needS to be imported
foreach ($Schema in $SchemaList)
{ 
  
	try 
	{
		$StartTime = "Start time - " + (get-date -Displayhint datetime)

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
        $Command | SQLPlus -silent "$UserName/`"$PlainTextPass`"@$TNSName"

#-------------------------------------------- IMPORT SCHEMA  -------------------------------------------------------
		
		#Command to import schemas
		Invoke-Command -ScriptBlock {impdp $UserName/$PlainTextPass@$TNSName `
                                            SCHEMAS= $Schema.Name `
		                                    DIRECTORY=DATAPUMP DUMPFILE=$($Schema.DumpFile) `
                                            LOGFILE="IMPORT_$($Schema.Name)_$(Get-Date -Format "dd_MMM_yyyy").log" `
                                            TABLE_EXISTS_ACTION=REPLACE `
                                            PARALLEL=2 `
                                            METRICS=YES}
		
		$EndTime = "End time - " + (get-date -Displayhint datetime)
		
    } #end try-block
    catch 
    {
		    $Error[0]

    } #end catch-block

} #end of foreach-loop 
