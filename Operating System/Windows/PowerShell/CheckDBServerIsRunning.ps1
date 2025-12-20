
#################################################################################################################
# PREREQUISITES
#################################################################################################################

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

# This function sends an email when given the parameters of email message body, and email priority 
#Function to send email
function Send-Email {
    param (
        $SubjectLine,
        $Message,
        $EmailPrioriry
    )

	#Set some of the email parameters
	$EmailSender = 'Ufuoma.Ikporo@gmail.com'
	$SenderPassword = ConvertTo-SecureString -AsPlainText "assdzkrdcyqvpmty" -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($EmailSender, $SenderPassword )
	$RecipientList = 'ufuoma_ikporo@dynamicrisk.net' #, 'Daniel_Cheung@dynamicrisk.net', 'Jagdish_Chaudhary@dynamicrisk.net'

   $SMTPParams = @{
   SmtpServer = 'smtp.gmail.com'
   Port       = 587
   Credential = $Credential
   UseSsl     = $true
   From       = $EmailSender
   To         = $RecipientList
   Subject    = $SubjectLine
   Body       = $Message
   priority   = $EmailPrioriry
 
   }

    Send-MailMessage @SMTPParams
}

$StartTime = Get-Date

Write-Output "`r`nScript Executed on: $StartTime`r`n"

############################################# SQL SERVER  ##########################################################

#List of SQL Server database servers
$ServerList = @('SQL2012EXT', 'SQL2014', 'SQL2016', 'SQL2017', 'SQL2019', 'SQLDEVPREPROD')

#Check if each server is up and running and send an email if the server is down
foreach ($Server in $ServerList)
{
    $StoppedServices = $null
    $StoppedServicesList = $null
    $Message = $null
    $SubjectLine = $null

    $Result = Ping $Server

    if ($result -match "Request timed out*")
    {
        $SubjectLine = "**URGENT** $Server Server Connection Test Failed"
        $Message = "`r`nThe $Server server failed a connection test. Database users and applications may currently be unable to connect to the database(s) located on this server. "
        $Message += "This might be due to a network connectivity issue or the server could be down.`r`n`r`nContact your System Administrator to resolve the issue.`r`n"

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
        continue
    }

    
    #List of database services that are stopped but should be running
    try{
    $StoppedServices = Get-Service -ComputerName $Server | `
    Where-Object {$_.DisplayName -like "SQL Server (MSSQLSERVER)" -or $_.DisplayName -like "SQL*CEIP*" -or $_.DisplayName -like "SQL*Writer*" -and $_.Status -eq "Stopped"} | Select-Object DisplayName
    }
    catch {
    }
    #Convert Object List into a string
    if ($null -ne $StoppedServices)
    {
        $StoppedServicesList = $StringList = [system.String]::Join("`r`n", $StoppedServices.DisplayName) + "`r`n"
    }

    #Check if database service is running
    if ("SQL Server (MSSQLSERVER)" -in $StoppedServices.DisplayName)
    {    
       $SubjectLine = "**URGENT** $Server DATABASE is DOWN"
        $Message = "`r`nThe $Server Database is down. Database users and applications are currently unable to connect to the $Server database(s) or access database resources. "
        $Message += "`r`n`r`nPossible Fixes:`r`n`r`n1. The Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
    }
    elseif ($null -ne $StoppedServices)
    {
    
        $SubjectLine = "**URGENT** $Server Service(s) is Down"
        $Message = "`r`nOne or more vital database services for the $Server database server is down. Database users and applications may not be able to connect to the $Server database(s) or obtain to certain database resources. "
        $Message += "`r`n`r`nPossible Fixes:`r`n`r`n1. The Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
    }


}#end of foreach-loop

######################################################### FOR ORACLE SERVER ##################################################

<#
    This Portion of the script only works correctly if 
    1) the servername and database server name are entered correctly
    2) there is a user on each database with username = DBBACKUPUSER and password = DBBACKUPUSER
#>

$ServerList = $arr = @(
    [PSCustomObject]@{ServerName = 'ORA12C.eddyfindt.com';  DBName = 'ORA12C.eddyfindt.com'}
    [PSCustomObject]@{ServerName = 'ORA19C.eddyfindt.com';  DBName = 'ORA19C.eddyfindt.com'}
    [PSCustomObject]@{ServerName = 'ORA19C22.eddyfindt.com';  DBName = 'ORA19C22.eddyfindt.com'}
    [PSCustomObject]@{ServerName = 'ORA12CMT.eddyfindt.com';  DBName = 'etp.eddyfindt.com'}

)

foreach ($item in $ServerList)
{
    $StoppedServices = $null
    $StoppedServicesList = $null
    $Message = $null
    $SubjectLine = $null
    $OracleDBProcess = $null
    $CheckDBMode = 0

    $FullServerName = $item.ServerName
    $DBServiceName = $Item.DBName
    $Server = $item.ServerName.Substring(0, $item.ServerName.IndexOf("."))
    $SID = $DBServiceName.Substring(0, $DBServiceName.IndexOf("."))

     $Result = Ping $Server

    if ($result -match "Request timed out*")
    {
        $SubjectLine = "**URGENT** $Server Server Connection Test Failed"
        $Message = "`r`nAn attempt to connect to the $Server server failed. Database users and applications may currently be unable to connect to the database(s) located on this server. "
        $Message += "This might be due to a network connectivity issue or the server coud be down.`r`n`r`nContact your System Administrator to resolve the issue.`r`n"

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
        continue
    }
    
    #Get a list of the essential Oracle database services that are stopped. 
    try{
        $StoppedServices = Get-Service -ComputerName $Server | `
        Where-Object {$_.DisplayName -like "OracleService*" -or $_.DisplayName -like "OracleOraDB*Home*" -or $_.DisplayName -like "Oracle*Writer*" -and $_.Status -eq "Stopped"} | Select-Object DisplayName
    }
    catch{
       
    }

    #Convert Object List into a string
    if ($null -ne $StoppedServices)
    {
        $StoppedServicesList = $StringList = [system.String]::Join("`r`n", $StoppedServices.DisplayName) + "`r`n"
    }

    #Check if database service is running
    if ($StoppedServices.DisplayName -like "OracleService*")
    {
    
        $SubjectLine = "**URGENT** $SID Database Server is Down"
        $Message = "`r`nThe $SID Database server is down. Database users and applications are currently unable to connect to the $SID database or access database resources. "
        $Message += "`r`n`r`nPossble Fixes:`r`n`r`n1. The Service(s) listed below are currently stopped but need to be running for normal database operations. Connect to the $SID Server, go to Windows Services, and start up the following services.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
    }
    elseif ($StoppedServices.DisplayName -like "Oracle*TNS*")
    {
            $SubjectLine = "**URGENT** $SID Database LISTENER is Down"
        $Message = "`r`nThe $SID Database listener is down. Database users and applications are currently unable to connect to the $SID database or access database resources. "
        $Message += "`r`n`r`nPossble Fix:`r`n`r`n1. The Service(s) listed below are currently stopped but need to be running for normal database operations. Connect to the $Server Server, go to Windows Services, and start up the following services.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
    }
    elseif ($null -ne $StoppedServices)
    {
    
        $SubjectLine = "**URGENT** $Server Database Service(s) NOT Running"
        $Message = "`r`nOne or more vital Oracle database services are currently not running on the $Server server. Database users and applications may not be able to connect to the $SID database or perform certain database operations. "
        $Message += "`r`n`r`nPossble Fix:`r`n`r`nThe Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
    } #end of elseif-statement
    
    if (($StoppedServices.DisplayName -like "OracleService*" -or $StoppedServices.DisplayName -like "Oracle*TNS*") -eq $false)
    {
    
        $ConnectionString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$FullServerName)(PORT=1521)) `
        (CONNECT_DATA=(SERVICE_NAME=$DBServiceName)));User Id=DBBACKUPUSER;Password=DBBACKUPUSER;"

        try
        {
            #PowerShell Object for setting the string used to open an Oracle database
            $Connection = New-Object System.Data.OracleClient.OracleConnection($ConnectionString);

            #Create command to execute $GetSchemaQuery
            $SQLCMD = $Connection.CreateCommand()
            $SQLCMD.CommandText = 'SELECT 1 AS result FROM DUAL'
            $SQLCMD.CommandTimeout = 60 #seconds

            #PowerShell object to store the results from an SQL query
            $CheckDBMode = New-Object System.Data.DataTable

            #Connect to the database and and execute the query to fill the datatable object (i.e. get schema list)
            $Adapter = New-Object System.Data.OracleClient.OracleDataAdapter ($SQLCMD)
            [Void]$Adapter.Fill($CheckDBMode)
        }
        catch
        {
            $CheckDBMode = 0
          
        }
        
        if($CheckDBMode -eq 0)
        {
            $SubjectLine = "**URGENT** The $SID Database is Down"
            $Message = "`r`nThe $SID database is currently shut down or not in open mode. Database users and applications cannot connect to the $SID database. "
            $Message += "`r`n`r`nPossble Fix: "
            $Message += "`r`n`r`n1. Check that the $Server server is still up and running"
            $Message += "`r`n`r`n2. Connect to the database with 'SYSDBA' privileges from the $Server server. Then use the command line to either startup the database, or set the database to open mode."
            $Message += "`r`n`r`n3. Make sure the database service is registered with the listener. Set the database service to dynamically register with the listener.`r`n"
            
            if ($StoppedServicesList -ne $null)
            {
                $Message += "`r`n`r`nThe Services listed below are currently stopped but need to be running for normal database operations.`r`n"
                $Message += "`r`n" + $StoppedServicesList
            }

            Send-Email -SubjectLine $SubjectLine -Message $Message -EmailPrioriry 2
        }
    
    } #end of if-statement
    
} #end of foreach-loop

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).ToString("hh'hr:'mm'min:'ss'sec'")

Write-Host "The script was sucessfully completed"
Write-Host "Duration: $Duration"  
